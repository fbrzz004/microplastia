from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.core.security import get_current_user
from app.db.session import get_db
from app.models.user import Usuario
from app.schemas.history import ResultResponse
from app.services.history_service import get_result, to_history_detail


router = APIRouter(
    prefix="/results",
    tags=["Results"],
)


@router.get("/{result_id}", response_model=ResultResponse)
def get_result_detail(
    result_id: int,
    db: Session = Depends(get_db),
    usuario: Usuario = Depends(get_current_user),
):
    """Devuelve el detalle de un análisis del usuario autenticado."""

    registro = get_result(
        db,
        result_id=result_id,
        user_id=usuario.id_usuario,
    )

    if registro is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Resultado no encontrado",
        )

    return ResultResponse(data=to_history_detail(registro))
