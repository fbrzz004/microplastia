from typing import Dict, List, Optional
from pydantic import BaseModel, Field


class DetectionItem(BaseModel):
    class_id: int
    class_name: str
    confidence: float
    box: List[float] = Field(description="Coordenadas [x1, y1, x2, y2]")


class AnalysisData(BaseModel):
    result_id: Optional[int] = None
    sample_id: str
    total_particles: int
    confidence: float
    breakdown: Dict[str, int]
    detections: List[DetectionItem] = []
    processing_time_ms: float
    annotated_image_url: Optional[str] = None


class AnalysisResponse(BaseModel):
    success: bool = True
    message: str
    data: AnalysisData
