from sqlalchemy import Boolean, Column, Integer, String

from app.db.session import Base


class Usuario(Base):
    __tablename__ = "usuario"

    id_usuario = Column(
        Integer,
        primary_key=True,
        index=True
    )

    nombre = Column(
        String(100),
        nullable=False
    )

    apellido = Column(
        String(100),
        nullable=True
    )

    correo = Column(
        String(150),
        unique=True,
        nullable=False,
        index=True
    )

    password_hash = Column(
        String(255),
        nullable=False
    )

    rol = Column(
        String(30),
        nullable=False,
        default="usuario"
    )

    estado = Column(
        Boolean,
        default=True
    )