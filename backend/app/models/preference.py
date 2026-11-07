from sqlalchemy import (
    Boolean,
    Column,
    DateTime,
    ForeignKey,
    Integer,
    func,
)

from app.db.session import Base


class PreferenciaUsuario(Base):
    __tablename__ = "preferencia_usuario"

    id_preferencia = Column(
        Integer,
        primary_key=True,
        index=True,
    )

    id_usuario = Column(
        Integer,
        ForeignKey(
            "usuario.id_usuario",
            ondelete="CASCADE",
        ),
        nullable=False,
        unique=True,
        index=True,
    )

    notificaciones_activas = Column(
        Boolean,
        nullable=False,
        default=True,
        server_default="true",
    )

    fecha_actualizacion = Column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now(),
        nullable=False,
    )
