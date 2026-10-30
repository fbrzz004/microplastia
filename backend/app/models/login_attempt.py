from sqlalchemy import (
    Column,
    DateTime,
    Integer,
    String,
    func,
)

from app.db.session import Base


class LoginAttempt(Base):

    __tablename__ = "login_attempt"

    id_login_attempt = Column(
        Integer,
        primary_key=True,
        index=True,
    )

    identifier_hash = Column(
        String(64),
        unique=True,
        nullable=False,
        index=True,
    )

    failed_attempts = Column(
        Integer,
        nullable=False,
        default=0,
    )

    window_started_at = Column(
        DateTime(timezone=True),
        nullable=True,
    )

    blocked_until = Column(
        DateTime(timezone=True),
        nullable=True,
    )

    updated_at = Column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now(),
        nullable=False,
    )