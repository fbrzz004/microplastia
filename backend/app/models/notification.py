from sqlalchemy import (
    Boolean,
    Column,
    DateTime,
    ForeignKey,
    Integer,
    String,
    func,
)

from app.db.session import Base


class Notificacion(Base):
    __tablename__ = "notificacion"

    id_notificacion = Column(
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
        index=True,
    )

    tipo = Column(
        String(30),
        nullable=False,
        default="analysis",
    )

    titulo = Column(
        String(150),
        nullable=False,
    )

    mensaje = Column(
        String(500),
        nullable=False,
    )

    id_resultado = Column(
        Integer,
        ForeignKey(
            "resultado_analisis.id_resultado",
            ondelete="SET NULL",
        ),
        nullable=True,
        index=True,
    )

    leida = Column(
        Boolean,
        nullable=False,
        default=False,
        index=True,
    )

    fecha_creacion = Column(
        DateTime(timezone=True),
        server_default=func.now(),
        nullable=False,
    )
