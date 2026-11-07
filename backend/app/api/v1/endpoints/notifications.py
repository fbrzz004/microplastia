import asyncio

from fastapi import (
    APIRouter,
    Depends,
    HTTPException,
    Query,
    WebSocket,
    WebSocketDisconnect,
    status,
)
from sqlalchemy.orm import Session

from app.core.security import (
    get_current_user,
    get_user_from_token,
)
from app.db.session import get_db
from app.models.user import Usuario
from app.schemas.notification import (
    NotificationItemResponse,
    NotificationListData,
    NotificationListResponse,
    NotificationReadAllData,
    NotificationReadAllResponse,
)
from app.services.notification_events import (
    notification_events,
)
from app.services.notification_service import (
    list_notifications,
    mark_all_as_read,
    mark_as_read,
    to_notification_item,
    unread_count,
)

router = APIRouter(
    prefix="/notifications",
    tags=["Notifications"],
)


@router.get(
    "",
    response_model=NotificationListResponse,
)
def get_notifications(
    limit: int = Query(
        default=20,
        ge=1,
        le=100,
    ),
    offset: int = Query(
        default=0,
        ge=0,
    ),
    only_unread: bool = Query(
        default=False,
    ),
    db: Session = Depends(get_db),
    usuario: Usuario = Depends(get_current_user),
):

    items, total, unread = list_notifications(
        db,
        user_id=usuario.id_usuario,
        limit=limit,
        offset=offset,
        only_unread=only_unread,
    )

    return NotificationListResponse(
        data=NotificationListData(
            items=[to_notification_item(item) for item in items],
            total=total,
            unread_count=unread,
            limit=limit,
            offset=offset,
        )
    )


@router.get(
    "/unread-count",
    response_model=NotificationListData,
)
def get_unread_count(
    db: Session = Depends(get_db),
    usuario: Usuario = Depends(get_current_user),
):

    return NotificationListData(
        total=unread_count(
            db,
            usuario.id_usuario,
        ),
        unread_count=unread_count(
            db,
            usuario.id_usuario,
        ),
    )


@router.post(
    "/read-all",
    response_model=NotificationReadAllResponse,
)
def read_all_notifications(
    db: Session = Depends(get_db),
    usuario: Usuario = Depends(get_current_user),
):

    updated = mark_all_as_read(
        db,
        usuario.id_usuario,
    )

    return NotificationReadAllResponse(
        data=NotificationReadAllData(
            updated=updated,
            unread_count=unread_count(
                db,
                usuario.id_usuario,
            ),
        )
    )


@router.post(
    "/{notification_id}/read",
    response_model=NotificationItemResponse,
)
def read_notification(
    notification_id: int,
    db: Session = Depends(get_db),
    usuario: Usuario = Depends(get_current_user),
):

    notification = mark_as_read(
        db,
        user_id=usuario.id_usuario,
        notification_id=notification_id,
    )

    if notification is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Notificación no encontrada",
        )

    return NotificationItemResponse(data=to_notification_item(notification))


@router.websocket("/ws")
async def notifications_websocket(
    websocket: WebSocket,
    token: str = Query(...),
    db: Session = Depends(get_db),
):

    try:
        usuario = get_user_from_token(
            token,
            db,
        )

    except HTTPException:
        await websocket.close(code=status.WS_1008_POLICY_VIOLATION)
        return

    if usuario is None:
        await websocket.close(code=status.WS_1008_POLICY_VIOLATION)
        return

    queue = await notification_events.connect(
        usuario.id_usuario,
        websocket,
    )

    async def send_notifications() -> None:
        while True:
            payload = await queue.get()
            await websocket.send_json(payload)

    sender = asyncio.create_task(send_notifications())

    try:
        while True:
            await websocket.receive_text()

    except WebSocketDisconnect:
        pass

    finally:
        sender.cancel()
        notification_events.disconnect(
            usuario.id_usuario,
            websocket,
        )
