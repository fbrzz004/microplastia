from sqlalchemy import (
    Column,
    DateTime,
    ForeignKey,
    Integer,
    String,
    Text,
    func,
)
from sqlalchemy.orm import relationship

from app.db.session import Base


class Muestra(Base):
    __tablename__ = "muestra"

    id_muestra = Column(
        Integer,
        primary_key=True,
        index=True
    )

    id_usuario = Column(
        Integer,
        ForeignKey("usuario.id_usuario"),
        nullable=False,
        index=True
    )

    fecha_registro = Column(
        DateTime,
        server_default=func.now(),
        nullable=True
    )

    imagen_url = Column(
        String(255),
        nullable=True
    )

    descripcion = Column(
        Text,
        nullable=True
    )

    estado = Column(
        String(50),
        nullable=True
    )

    resultados = relationship(
        "ResultadoAnalisis",
        back_populates="muestra",
        cascade="all, delete-orphan"
    )