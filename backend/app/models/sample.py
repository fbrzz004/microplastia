from sqlalchemy import Column, DateTime, ForeignKey, Integer, String, func
from sqlalchemy.orm import relationship

from app.db.session import Base


class Muestra(Base):
    """Imagen microscópica enviada al backend para su análisis."""

    __tablename__ = "muestra"

    id_muestra = Column(Integer, primary_key=True, index=True)
    codigo = Column(String(50), nullable=False, index=True)
    nombre_archivo = Column(String(255), nullable=True)
    id_usuario = Column(
        Integer,
        ForeignKey("usuario.id_usuario"),
        nullable=True,
        index=True,
    )
    fecha_creacion = Column(
        DateTime(timezone=True),
        server_default=func.now(),
        nullable=False,
    )

    resultados = relationship(
        "ResultadoAnalisis",
        back_populates="muestra",
        cascade="all, delete-orphan",
    )
