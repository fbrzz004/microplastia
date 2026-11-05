from datetime import datetime

from pydantic import BaseModel


class ModelLatestResponse(BaseModel):
    id_modelo: int

    nombre: str
    version: str

    storage_path: str | None = None
    download_url: str | None = None
    sha256: str | None = None

    input_size: int
    output_shape: list[int] | None = None

    clases: dict[str, str] | None = None

    confidence_threshold: float
    iou_threshold: float

    min_app_version: str | None = None

    precision: float | None = None
    recall: float | None = None
    map50: float | None = None
    tiempo_inferencia: float | None = None

    fecha_publicacion: datetime | None = None