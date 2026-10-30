import json
import uuid
from typing import Dict, List, Optional

import cv2
import numpy as np
from fastapi import (
    APIRouter,
    Depends,
    File,
    Form,
    HTTPException,
    UploadFile,
    status,
)
from pydantic import BaseModel, Field
from sqlalchemy.orm import Session

from app.core.file_validation import (
    InvalidUploadError,
    validate_sample_id,
)
from app.core.security import get_current_user
from app.db.session import get_db
from app.models.user import Usuario
from app.schemas.analysis import (
    AnalysisData,
    AnalysisResponse,
    DetectionItem,
)
from app.services.history_service import save_analysis
from app.services.storage_service import (
    StorageError,
    storage_service,
)


router = APIRouter(
    tags=["Analysis"]
)


# ==========================================================
# MODELOS PARA RESULTADOS GENERADOS EN EL MÓVIL
# ==========================================================

class MobileDetection(BaseModel):
    class_id: int = Field(
        ge=0,
        le=3,
    )

    class_name: str = Field(
        min_length=1,
        max_length=100,
    )

    confidence: float = Field(
        ge=0.0,
        le=1.0,
    )

    box: List[float] = Field(
        min_length=4,
        max_length=4,
    )


class MobileAnalysisRequest(BaseModel):
    sample_id: Optional[str] = None

    total_particles: int = Field(
        ge=0,
    )

    confidence: float = Field(
        ge=0.0,
        le=1.0,
    )

    breakdown: Dict[str, int]

    detections: List[MobileDetection]

    processing_time_ms: float = Field(
        ge=0.0,
    )


# ==========================================================
# ANÁLISIS MÓVIL
# ==========================================================

@router.post(
    "/analyze/mobile",
    response_model=AnalysisResponse,
)
async def save_mobile_analysis(
    payload: str = Form(...),

    annotated_file: UploadFile | None = File(
        default=None,
    ),

    db: Session = Depends(get_db),

    usuario: Usuario = Depends(
        get_current_user
    ),
):
    """
    Recibe resultados generados por TFLite/LiteRT en Flutter.

    El backend NO ejecuta modelos de inteligencia artificial.

    El backend únicamente:
    - valida los resultados
    - almacena la imagen anotada
    - guarda el análisis en la base de datos
    - permite consultarlo desde historial y reportes
    """

    # ------------------------------------------------------
    # PAYLOAD JSON
    # ------------------------------------------------------

    try:
        payload_json = json.loads(
            payload
        )

        mobile_result = (
            MobileAnalysisRequest
            .model_validate(
                payload_json
            )
        )

    except (
        json.JSONDecodeError,
        ValueError,
    ) as exc:
        raise HTTPException(
            status_code=(
                status.HTTP_400_BAD_REQUEST
            ),
            detail=(
                "Los resultados enviados "
                "por el dispositivo no son válidos."
            ),
        ) from exc


    # ------------------------------------------------------
    # SAMPLE ID
    # ------------------------------------------------------

    sample_id = (
        mobile_result.sample_id
    )

    if sample_id:
        try:
            sample_id = (
                validate_sample_id(
                    sample_id
                )
            )

        except InvalidUploadError as exc:
            raise HTTPException(
                status_code=(
                    status.HTTP_400_BAD_REQUEST
                ),
                detail=str(exc),
            ) from exc

    if not sample_id:
        sample_id = (
            "MUESTRA-"
            f"{uuid.uuid4().hex[:8].upper()}"
        )


    # ------------------------------------------------------
    # CONSISTENCIA DE DETECCIONES
    # ------------------------------------------------------

    if (
        mobile_result.total_particles
        != len(mobile_result.detections)
    ):
        raise HTTPException(
            status_code=(
                status.HTTP_400_BAD_REQUEST
            ),
            detail=(
                "total_particles no coincide "
                "con la cantidad de detecciones."
            ),
        )


    # ------------------------------------------------------
    # IMAGEN ANOTADA
    # ------------------------------------------------------

    annotated_image_url = None

    if annotated_file is not None:
        annotated_bytes = (
            await annotated_file.read()
        )

        await annotated_file.close()

        if annotated_bytes:
            if (
                len(annotated_bytes)
                > 10 * 1024 * 1024
            ):
                raise HTTPException(
                    status_code=(
                        status.HTTP_413_REQUEST_ENTITY_TOO_LARGE
                    ),
                    detail=(
                        "La imagen anotada supera "
                        "el tamaño máximo permitido."
                    ),
                )

            image_array = np.frombuffer(
                annotated_bytes,
                dtype=np.uint8,
            )

            image_bgr = cv2.imdecode(
                image_array,
                cv2.IMREAD_COLOR,
            )

            if image_bgr is None:
                raise HTTPException(
                    status_code=(
                        status.HTTP_400_BAD_REQUEST
                    ),
                    detail=(
                        "La imagen anotada "
                        "no es válida."
                    ),
                )

            try:
                annotated_image_url = (
                    storage_service
                    .save_annotated_image(
                        image_bgr
                    )
                )

            except StorageError as exc:
                raise HTTPException(
                    status_code=(
                        status.HTTP_503_SERVICE_UNAVAILABLE
                    ),
                    detail=(
                        "No se pudo almacenar "
                        "la imagen anotada."
                    ),
                ) from exc


    # ------------------------------------------------------
    # DETECCIONES
    # ------------------------------------------------------

    detections = [
        DetectionItem(
            class_id=detection.class_id,

            class_name=(
                detection.class_name
            ),

            confidence=round(
                detection.confidence,
                4,
            ),

            box=[
                round(
                    float(value),
                    2,
                )
                for value
                in detection.box
            ],
        )

        for detection
        in mobile_result.detections
    ]


    # ------------------------------------------------------
    # RESULTADO
    # ------------------------------------------------------

    result = AnalysisData(
        sample_id=sample_id,

        total_particles=(
            mobile_result.total_particles
        ),

        confidence=round(
            mobile_result.confidence,
            4,
        ),

        breakdown=dict(
            mobile_result.breakdown
        ),

        detections=detections,

        processing_time_ms=round(
            mobile_result.processing_time_ms,
            2,
        ),

        annotated_image_url=(
            annotated_image_url
        ),
    )


    # ------------------------------------------------------
    # BASE DE DATOS
    # ------------------------------------------------------

    registro = save_analysis(
        db,
        result=result,
        user_id=usuario.id_usuario,
    )

    result.result_id = (
        registro.id_resultado
    )


    # ------------------------------------------------------
    # RESPUESTA
    # ------------------------------------------------------

    return AnalysisResponse(
        success=True,

        message=(
            "Análisis móvil guardado. "
            f"Se detectaron "
            f"{result.total_particles} "
            "partículas."
        ),

        data=result,
    )