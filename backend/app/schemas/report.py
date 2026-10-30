from datetime import datetime
from typing import List

from pydantic import BaseModel, Field


class ReportRequest(BaseModel):
    result_ids: List[int] = Field(
        min_length=1,
        max_length=50,
        description="Análisis seleccionados para el reporte",
    )


class ReportData(BaseModel):
    filename: str
    report_url: str
    total_analyses: int
    generated_at: datetime


class ReportResponse(BaseModel):
    success: bool = True
    message: str
    data: ReportData
