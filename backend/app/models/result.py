from sqlalchemy import (
    JSON,
    Column,
    DateTime,
    Float,
    ForeignKey,
    Integer,
    String,
    func,
)
from sqlalchemy.orm import relationship

from app.db.session import Base


class ResultadoAnalisis(Base):
    """Resultado de inferencia asociado a una muestra."""

    __tablename__ = "resultado_analisis"

    id_resultado = Column(Integer, primary_key=True, index=True)
    id_muestra = Column(
        Integer,
        ForeignKey("muestra.id_muestra"),
        nullable=False,
        index=True,
    )
    total_particulas = Column(Integer, nullable=False, default=0)
    confianza_promedio = Column(Float, nullable=False, default=0.0)
    desglose = Column(JSON, nullable=False, default=dict)
    detecciones = Column(JSON, nullable=False, default=list)
    tiempo_procesamiento_ms = Column(Float, nullable=False, default=0.0)
    imagen_anotada_url = Column(String(255), nullable=True)
    fecha_creacion = Column(
        DateTime(timezone=True),
        server_default=func.now(),
        nullable=False,
    )

    muestra = relationship("Muestra", back_populates="resultados")
