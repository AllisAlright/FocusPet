from typing import Optional

from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from app.db.database import get_db
from app.schemas.tasks import DeleteResponse, TaskCreate, TaskItem, TaskListResponse, TaskStatus, TaskUpdate
from app.services.task_service import task_service

router = APIRouter(prefix="/tasks", tags=["tasks"])


@router.get("", response_model=TaskListResponse)
def list_tasks(
    status: Optional[TaskStatus] = Query(
        default=None,
        description="Optional task status filter: todo, in_progress, paused, completed.",
    ),
    db: Session = Depends(get_db),
) -> TaskListResponse:
    return TaskListResponse(items=task_service.list_tasks(db, status=status))


@router.get("/deleted", response_model=TaskListResponse)
def list_deleted_tasks(db: Session = Depends(get_db)) -> TaskListResponse:
    return TaskListResponse(items=task_service.list_deleted_tasks(db))


@router.get("/{task_id}", response_model=TaskItem)
def get_task(task_id: str, db: Session = Depends(get_db)) -> TaskItem:
    # Read one task by its id.
    return task_service.get_task(db, task_id)


@router.post("", response_model=TaskItem, status_code=201)
def create_task(payload: TaskCreate, db: Session = Depends(get_db)) -> TaskItem:
    return task_service.create_task(db, payload)


@router.patch("/{task_id}", response_model=TaskItem)
def update_task(task_id: str, payload: TaskUpdate, db: Session = Depends(get_db)) -> TaskItem:
    # PATCH updates only the fields included in the request body.
    return task_service.update_task(db, task_id, payload)


@router.delete("/{task_id}", response_model=DeleteResponse)
def delete_task(task_id: str, db: Session = Depends(get_db)) -> DeleteResponse:
    task_service.delete_task(db, task_id)
    return DeleteResponse(message="Task soft deleted successfully.")


@router.post("/{task_id}/restore", response_model=TaskItem)
def restore_task(task_id: str, db: Session = Depends(get_db)) -> TaskItem:
    return task_service.restore_task(db, task_id)
