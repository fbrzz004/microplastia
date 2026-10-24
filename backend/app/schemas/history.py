from datetime import datetime
from typing import Dict, List, Optional

from pydantic import BaseModel, Field

from app.schemas.analysis import DetectionItem


class HistoryItem(BaseModel):
    """Resumen de un análisis para la lista del historial."""

    id: int
    sample_id: str
    filename: Optional[str] = None
    created_at: datetime
    total_particles: int
    confidence: float
    annotated_image_url: Optional[str] = None


class HistoryDetail(HistoryItem):
    """Detalle completo de un análisis guardado."""

    breakdown: Dict[str, int] = Field(default_factory=dict)
    detections: List[DetectionItem] = Field(default_factory=list)
    processing_time_ms: float = 0.0


class HistoryData(BaseModel):
    items: List[HistoryItem] = Field(default_factory=list)
    total: int = 0
    limit: int = 20
    offset: int = 0


class HistoryResponse(BaseModel):
    success: bool = True
    data: HistoryData


class ResultResponse(BaseModel):
    success: bool = True
    data: HistoryDetail
