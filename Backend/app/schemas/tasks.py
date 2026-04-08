from datetime import datetime
from enum import Enum
from typing import Optional, Union
from uuid import UUID, uuid4

from pydantic import BaseModel, Field


class TaskStatus(str, Enum):
    todo = "todo"
    in_progress = "in_progress"
    paused = "paused"
    completed = "completed"


class TaskCreate(BaseModel):
    title: str = Field(..., min_length=1, max_length=120)
    notes: str = ""
    estimated_minutes: Optional[int] = Field(default=None, ge=1)


class TaskUpdate(BaseModel):
    # All fields are optional for PATCH.
    # Only the fields sent by the client will be updated.
    title: Optional[str] = Field(default=None, min_length=1, max_length=120)
    notes: Optional[str] = None
    status: Optional[TaskStatus] = None
    estimated_minutes: Optional[int] = Field(default=None, ge=1)
    spent_minutes: Optional[int] = Field(default=None, ge=0)


class TaskItem(BaseModel):
    id: Union[str, UUID] = Field(default_factory=uuid4)
    title: str
    notes: str
    status: TaskStatus = TaskStatus.todo
    progress: float = 0.0
    estimated_minutes: Optional[int] = None
    spent_minutes: int = 0
    created_at: datetime = Field(default_factory=datetime.utcnow)
    is_deleted: bool = False
    deleted_at: Optional[datetime] = None


class TaskListResponse(BaseModel):
    items: list[TaskItem]


class DeleteResponse(BaseModel):
    message: str
