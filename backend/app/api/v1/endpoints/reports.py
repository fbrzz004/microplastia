from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.core.security import get_current_user
from app.db.session import get_db
from app.models.user import Usuario
from app.schemas.report import ReportData, ReportRequest, ReportResponse
from app.services.history_service import get_results_by_ids
from app.services.report_service import generate_report


router = APIRouter(
    prefix="/reports",
    tags=["Reports"],
)


@router.post(
    "",
    response_model=ReportResponse,
    status_code=status.HTTP_201_CREATED,
)
def create_report(
    data: ReportRequest,
    db: Session = Depends(get_db),
    usuario: Usuario = Depends(get_current_user),
):
    """Generate a PDF report for the selected analyses of the user."""

    result_ids = list(dict.fromkeys(data.result_ids))

    registros = get_results_by_ids(
        db,
        result_ids=result_ids,
        user_id=usuario.id_usuario,
    )

    if len(registros) != len(result_ids):
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=(
                "Uno o más análisis no existen o no pertenecen "
                "al usuario"
            ),
        )

    path = generate_report(registros, usuario)

    return ReportResponse(
        message=(
            "Reporte generado con "
            f"{len(registros)} análisis."
        ),
        data=ReportData(
            filename=path.name,
            report_url=f"/static/reports/{path.name}",
            total_analyses=len(registros),
            generated_at=datetime.now(timezone.utc),
        ),
    )
