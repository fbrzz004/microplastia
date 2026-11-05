from fastapi import (
    APIRouter,
    Depends,
    HTTPException,
    status,
)
from sqlalchemy.orm import Session

from app.core.config import settings
from app.db.session import get_db
from app.models.model_ai import ModeloIA
from app.schemas.model_ai import ModelLatestResponse


router = APIRouter(
    prefix="/models",
    tags=["Models"],
)


@router.get(
    "/latest",
    response_model=ModelLatestResponse,
)
def obtener_modelo_actual(
    db: Session = Depends(get_db),
):
    """
    Devuelve los metadatos del modelo de IA actualmente activo.

    El backend NO descarga ni ejecuta el modelo.

    Flutter utiliza esta información para conocer:
    - versión disponible
    - ubicación del archivo
    - SHA256
    - configuración de inferencia
    """

    modelo = (
        db.query(ModeloIA)
        .filter(
            ModeloIA.estado.is_(True)
        )
        .order_by(
            ModeloIA.fecha_publicacion.desc(),
            ModeloIA.id_modelo.desc(),
        )
        .first()
    )

    if modelo is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="No existe un modelo de IA activo.",
        )

    # ==========================================
    # URL PÚBLICA DEL MODELO
    # ==========================================

    download_url = None

    if modelo.storage_path:

        supabase_url = (
            settings.supabase_url
            .strip()
            .rstrip("/")
        )

        bucket = (
            settings.supabase_models_bucket
            .strip()
        )

        storage_path = (
            modelo.storage_path
            .strip()
            .lstrip("/")
        )

        download_url = (
            f"{supabase_url}"
            f"/storage/v1/object/public/"
            f"{bucket}/"
            f"{storage_path}"
        )

    # ==========================================
    # RESPUESTA
    # ==========================================

    return ModelLatestResponse(
        id_modelo=modelo.id_modelo,

        nombre=modelo.nombre,
        version=modelo.version,

        storage_path=modelo.storage_path,
        download_url=download_url,

        sha256=modelo.sha256,

        input_size=modelo.input_size,
        output_shape=modelo.output_shape,

        clases=modelo.clases,

        confidence_threshold=float(
            modelo.confidence_threshold
        ),

        iou_threshold=float(
            modelo.iou_threshold
        ),

        min_app_version=modelo.min_app_version,

        precision=(
            float(modelo.precision)
            if modelo.precision is not None
            else None
        ),

        recall=(
            float(modelo.recall)
            if modelo.recall is not None
            else None
        ),

        map50=(
            float(modelo.map50)
            if modelo.map50 is not None
            else None
        ),

        tiempo_inferencia=(
            float(modelo.tiempo_inferencia)
            if modelo.tiempo_inferencia is not None
            else None
        ),

        fecha_publicacion=modelo.fecha_publicacion,
    )