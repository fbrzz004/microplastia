from sqlalchemy import (
    Boolean,
    Column,
    DateTime,
    Integer,
    JSON,
    Numeric,
    String,
    Text,
)

from app.db.session import Base


class ModeloIA(Base):
    """Modelo de inteligencia artificial disponible para la aplicación móvil."""

    __tablename__ = "modelo_ia"

    id_modelo = Column(
        Integer,
        primary_key=True,
        index=True,
    )

    nombre = Column(
        String,
        nullable=False,
    )

    version = Column(
        String,
        nullable=False,
    )

    precision = Column(
        Numeric,
        nullable=True,
    )

    recall = Column(
        Numeric,
        nullable=True,
    )

    map50 = Column(
        Numeric,
        nullable=True,
    )

    tiempo_inferencia = Column(
        Numeric,
        nullable=True,
    )

    estado = Column(
        Boolean,
        nullable=False,
        default=False,
    )

    storage_path = Column(
        Text,
        nullable=True,
    )

    sha256 = Column(
        String(64),
        nullable=True,
    )

    input_size = Column(
        Integer,
        nullable=False,
        default=320,
    )

    output_shape = Column(
        JSON,
        nullable=True,
    )

    clases = Column(
        JSON,
        nullable=True,
    )

    confidence_threshold = Column(
        Numeric,
        nullable=False,
        default=0.25,
    )

    iou_threshold = Column(
        Numeric,
        nullable=False,
        default=0.70,
    )

    min_app_version = Column(
        String,
        nullable=True,
    )

    fecha_publicacion = Column(
        DateTime(timezone=True),
        nullable=True,
    )