from typing import Dict, List, Optional

from pydantic import (
    BaseModel,
    Field,
)


class DetectionItem(BaseModel):

    class_id: int

    class_name: str

    confidence: float = Field(
        ge=0.0,
        le=1.0,
    )

    box: List[float] = Field(
        description=(
            "Coordenadas [x1, y1, x2, y2]"
        ),
        min_length=4,
        max_length=4,
    )


class AnalysisData(BaseModel):

    result_id: Optional[int] = None

    sample_id: str

    total_particles: int = Field(
        ge=0
    )

    confidence: float = Field(
        ge=0.0,
        le=1.0,
    )

    breakdown: Dict[str, int]

    detections: List[
        DetectionItem
    ] = Field(
        default_factory=list
    )

    processing_time_ms: float = Field(
        ge=0.0
    )

    original_image_url: Optional[
        str
    ] = None

    annotated_image_url: Optional[
        str
    ] = None


class AnalysisResponse(BaseModel):

    success: bool = True

    message: str

    data: AnalysisData