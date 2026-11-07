from collections.abc import Sequence
from datetime import datetime

from sqlalchemy.exc import SQLAlchemyError
from sqlalchemy.orm import Session

from app.models.notification import Notificacion
from app.models.preference import PreferenciaUsuario
from app.schemas.notification import NotificationItem


def notifications_enabled(
    db: Session,
    user_id: int,
) -> bool:

    preference = (
        db.query(PreferenciaUsuario)
        .filter(PreferenciaUsuario.id_usuario == user_id)
        .first()
    )

    if preference is None:
        return True

    return bool(preference.notificaciones_activas)


def get_preference(
    db: Session,
    user_id: int,
) -> bool:

    return notifications_enabled(
        db,
        user_id,
    )


def set_preference(
    db: Session,
    user_id: int,
    enabled: bool,
) -> bool:

    preference = (
        db.query(PreferenciaUsuario)
        .filter(PreferenciaUsuario.id_usuario == user_id)
        .first()
    )

    if preference is None:
        preference = PreferenciaUsuario(
            id_usuario=user_id,
            notificaciones_activas=enabled,
        )

        db.add(preference)

    else:
        preference.notificaciones_activas = enabled

    db.commit()
    db.refresh(preference)

    return bool(preference.notificaciones_activas)


def create_analysis_notification(
    db: Session,
    user_id: int,
    result_id: int,
    sample_id: str,
    total_particles: int,
    confidence: float,
) -> Notificacion | None:

    if not notifications_enabled(db, user_id):
        return None

    notification = Notificacion(
        id_usuario=user_id,
        tipo="analysis",
        titulo="Análisis completado",
        mensaje=(
            f"Muestra {sample_id} · "
            f"{total_particles} partículas · "
            f"{round(confidence * 100)}% de confianza"
        ),
        id_resultado=result_id,
        leida=False,
    )

    try:
        db.add(notification)
        db.commit()
        db.refresh(notification)

    except SQLAlchemyError:
        db.rollback()
        return None

    return notification


def list_notifications(
    db: Session,
    user_id: int,
    limit: int = 20,
    offset: int = 0,
    only_unread: bool = False,
) -> tuple[Sequence[Notificacion], int, int]:

    query = db.query(Notificacion).filter(Notificacion.id_usuario == user_id)

    if only_unread:
        query = query.filter(Notificacion.leida.is_(False))

    total = query.count()

    unread_count = (
        db.query(Notificacion)
        .filter(
            Notificacion.id_usuario == user_id,
            Notificacion.leida.is_(False),
        )
        .count()
    )

    items = (
        query.order_by(
            Notificacion.fecha_creacion.desc(),
            Notificacion.id_notificacion.desc(),
        )
        .offset(offset)
        .limit(limit)
        .all()
    )

    return items, total, unread_count


def unread_count(
    db: Session,
    user_id: int,
) -> int:

    return (
        db.query(Notificacion)
        .filter(
            Notificacion.id_usuario == user_id,
            Notificacion.leida.is_(False),
        )
        .count()
    )


def mark_as_read(
    db: Session,
    user_id: int,
    notification_id: int,
) -> Notificacion | None:

    notification = (
        db.query(Notificacion)
        .filter(
            Notificacion.id_notificacion == notification_id,
            Notificacion.id_usuario == user_id,
        )
        .first()
    )

    if notification is None:
        return None

    if not notification.leida:
        notification.leida = True
        db.commit()
        db.refresh(notification)

    return notification


def mark_all_as_read(
    db: Session,
    user_id: int,
) -> int:

    updated = (
        db.query(Notificacion)
        .filter(
            Notificacion.id_usuario == user_id,
            Notificacion.leida.is_(False),
        )
        .update(
            {
                Notificacion.leida: True,
            },
            synchronize_session=False,
        )
    )

    db.commit()

    return int(updated)


def to_notification_item(
    notification: Notificacion,
) -> NotificationItem:

    created_at: datetime | None = notification.fecha_creacion

    return NotificationItem(
        id=notification.id_notificacion,
        type=notification.tipo,
        title=notification.titulo,
        message=notification.mensaje,
        result_id=notification.id_resultado,
        is_read=bool(notification.leida),
        created_at=created_at,
    )


def to_notification_payload(
    notification: Notificacion,
) -> dict:

    return to_notification_item(notification).model_dump(mode="json")
