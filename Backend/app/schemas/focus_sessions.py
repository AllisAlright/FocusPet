from datetime import datetime
from typing import Optional, Union
from uuid import UUID, uuid4

from pydantic import BaseModel, Field


class FocusSessionCreate(BaseModel):
    task_id: Optional[UUID] = None
    duration_seconds: int = Field(..., ge=1)
    timer_mode: str = "countUp"


class FocusSessionItem(BaseModel):
    id: Union[str, UUID] = Field(default_factory=uuid4)
    task_id: Optional[Union[str, UUID]] = None
    duration_seconds: int
    timer_mode: str
    session_status: str = "finished"
    created_at: datetime = Field(default_factory=datetime.utcnow)


class FocusSessionListResponse(BaseModel):
    items: list[FocusSessionItem]
