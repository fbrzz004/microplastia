import uuid

from fastapi import (
    APIRouter,
    Depends,
    File,
    Form,
    HTTPException,
    UploadFile,
    status,
)
from sqlalchemy.orm import Session
from starlette.concurrency import run_in_threadpool

from app.core.file_validation import (
    InvalidUploadError,
    validate_content_type,
    validate_image_size,
    validate_sample_id,
)
from app.core.security import (
    get_current_user,
)
from app.db.session import get_db
from app.models.user import Usuario
from app.schemas.analysis import (
    AnalysisResponse,
)
from app.services.history_service import (
    save_analysis,
)
from app.services.inference import (
    inference_service,
)
from app.services.storage_service import (
    StorageError,
)


router = APIRouter(
    tags=["Analysis"]
)


@router.post(
    "/analyze",
    response_model=AnalysisResponse,
)
async def analyze_sample(

    file: UploadFile = File(
        ...,
        description=(
            "Imagen microscópica "
            "en JPG, PNG, WEBP, HEIC o HEIF"
        ),
    ),

    sample_id: str | None = Form(
        default=None,
        description=(
            "Identificador opcional "
            "de la muestra"
        ),
    ),

    db: Session = Depends(
        get_db
    ),

    usuario: Usuario = Depends(
        get_current_user
    ),

):

    # ------------------------------------------------------
    # VALIDAR METADATOS
    # ------------------------------------------------------

    try:

        validate_content_type(
            file.content_type
        )

        sample_id = validate_sample_id(
            sample_id
        )

    except InvalidUploadError as exc:

        raise HTTPException(
            status_code=(
                status.HTTP_400_BAD_REQUEST
            ),
            detail=str(exc),
        ) from exc


    # ------------------------------------------------------
    # GENERAR ID
    # ------------------------------------------------------

    if not sample_id:

        sample_id = (
            "MUESTRA-"
            f"{uuid.uuid4().hex[:8].upper()}"
        )


    # ------------------------------------------------------
    # GUARDAR NOMBRE ORIGINAL
    # ------------------------------------------------------

    original_filename = (
        file.filename
        or "sample.jpg"
    )


    # ------------------------------------------------------
    # LEER ARCHIVO
    # ------------------------------------------------------

    image_bytes = await file.read()

    await file.close()


    # ------------------------------------------------------
    # VALIDAR TAMAÑO
    # ------------------------------------------------------

    try:

        validate_image_size(
            image_bytes
        )

    except InvalidUploadError as exc:

        message = str(exc)

        status_code = (
            status.HTTP_413_REQUEST_ENTITY_TOO_LARGE
            if "tamaño máximo"
            in message
            else status.HTTP_400_BAD_REQUEST
        )

        raise HTTPException(
            status_code=status_code,
            detail=message,
        ) from exc


    # ------------------------------------------------------
    # INFERENCIA
    # ------------------------------------------------------
    #
    # IMPORTANTE:
    #
    # YOLO + PyTorch ejecutan procesamiento pesado y síncrono.
    #
    # Si ejecutamos inference_service.predict() directamente
    # dentro de este endpoint async, podemos bloquear el event
    # loop de FastAPI.
    #
    # En Render eso puede provocar que /health no responda
    # durante la inferencia y Render considere que la instancia
    # dejó de estar saludable.
    #
    # run_in_threadpool permite ejecutar YOLO fuera del event
    # loop principal.
    # ------------------------------------------------------

    try:

        result = await run_in_threadpool(
            inference_service.predict,
            image_bytes,
            original_filename,
            sample_id,
        )

    except InvalidUploadError as exc:

        raise HTTPException(
            status_code=(
                status.HTTP_400_BAD_REQUEST
            ),
            detail=str(exc),
        ) from exc

    except StorageError as exc:

        raise HTTPException(
            status_code=(
                status.HTTP_503_SERVICE_UNAVAILABLE
            ),
            detail=(
                "No se pudo almacenar "
                "la imagen temporalmente. "
                "Inténtalo nuevamente."
            ),
        ) from exc


    # ------------------------------------------------------
    # PERSISTENCIA
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
            "Análisis completado. "
            f"Se detectaron "
            f"{result.total_particles} "
            "partículas."
        ),
        data=result,
    )