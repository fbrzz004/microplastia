from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from app.core.security import get_current_user
from app.db.session import get_db
from app.models.user import Usuario
from app.schemas.history import HistoryData, HistoryResponse
from app.services.history_service import list_results, to_history_item


router = APIRouter(
    prefix="/history",
    tags=["History"],
)


@router.get("", response_model=HistoryResponse)
def get_history(
    q: str | None = Query(
        default=None,
        description="Busca por código de muestra o nombre de archivo",
    ),
    limit: int = Query(default=20, ge=1, le=100),
    offset: int = Query(default=0, ge=0),
    db: Session = Depends(get_db),
    usuario: Usuario = Depends(get_current_user),
):
    """Lista los análisis del usuario autenticado, del más reciente al más antiguo."""

    registros, total = list_results(
        db,
        user_id=usuario.id_usuario,
        query=q,
        limit=limit,
        offset=offset,
    )

    return HistoryResponse(
        data=HistoryData(
            items=[to_history_item(registro) for registro in registros],
            total=total,
            limit=limit,
            offset=offset,
        )
    )
