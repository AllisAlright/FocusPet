from datetime import datetime
from typing import Optional
from uuid import uuid4

from sqlalchemy import DateTime, ForeignKey, Integer, String
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base


class FocusSession(Base):
    __tablename__ = "focus_sessions"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=lambda: str(uuid4()))
    task_id: Mapped[Optional[str]] = mapped_column(String(36), ForeignKey("tasks.id"), nullable=True)
    duration_seconds: Mapped[int] = mapped_column(Integer, nullable=False)
    timer_mode: Mapped[str] = mapped_column(String(32), default="countUp")
    session_status: Mapped[str] = mapped_column(String(32), default="finished")
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)
