import uuid

from fastapi import APIRouter, Depends, File, Form, HTTPException, UploadFile
from sqlalchemy.orm import Session

from app.core.security import get_current_user
from app.db.session import get_db
from app.models.user import Usuario
from app.schemas.analysis import AnalysisResponse
from app.services.history_service import save_analysis
from app.services.inference import InvalidImageError, inference_service

router = APIRouter(tags=["Analysis"])

MAX_UPLOAD_BYTES = 10 * 1024 * 1024  # 10 MB

# Clientes como Flutter pueden enviar el archivo sin tipo MIME específico.
# En ese caso se valida el contenido real con OpenCV más abajo.
CONTENT_TYPES_SIN_MIME = {"application/octet-stream", "binary/octet-stream"}


@router.post("/analyze", response_model=AnalysisResponse)
async def analyze_sample(
    file: UploadFile = File(..., description="Imagen microscópica en JPG/PNG"),
    sample_id: str | None = Form(default=None, description="ID opcional de la muestra"),
    db: Session = Depends(get_db),
    usuario: Usuario = Depends(get_current_user),
):
    """
    Procesa una imagen con YOLOv8n, la guarda en el historial del usuario
    y devuelve la detección de microplásticos.
    Acepta multipart/form-data con campo 'file' (imagen) y 'sample_id' opcional.
    """
    if not sample_id:
        sample_id = f"MUESTRA-{uuid.uuid4().hex[:8].upper()}"

    if (
        file.content_type
        and not file.content_type.startswith("image/")
        and file.content_type not in CONTENT_TYPES_SIN_MIME
    ):
        raise HTTPException(
            status_code=400,
            detail="El archivo debe ser una imagen (JPG o PNG).",
        )

    image_bytes = await file.read()

    if not image_bytes:
        raise HTTPException(status_code=400, detail="El archivo está vacío.")

    if len(image_bytes) > MAX_UPLOAD_BYTES:
        raise HTTPException(
            status_code=413,
            detail="La imagen supera el tamaño máximo permitido (10 MB).",
        )

    try:
        result = inference_service.predict(
            image_bytes=image_bytes,
            original_filename=file.filename or "sample.jpg",
            sample_id=sample_id,
        )
    except InvalidImageError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc

    registro = save_analysis(
        db,
        result=result,
        filename=file.filename,
        user_id=usuario.id_usuario,
    )
    result.result_id = registro.id_resultado

    return AnalysisResponse(
        success=True,
        message=f"Análisis completado. Se detectaron {result.total_particles} partículas.",
        data=result,
    )

