from datetime import datetime
from typing import Optional

from fastapi import HTTPException
from sqlalchemy.orm import Session

from app.models.task import Task
from app.schemas.tasks import TaskCreate, TaskItem, TaskStatus, TaskUpdate


class TaskService:
    def list_tasks(self, db: Session, status: Optional[TaskStatus] = None) -> list[TaskItem]:
        query = db.query(Task).filter(Task.is_deleted.is_(False))

        if status is not None:
            query = query.filter(Task.status == status.value)

        tasks = query.order_by(Task.created_at.desc()).all()
        return [self._to_schema(task) for task in tasks]

    def list_deleted_tasks(self, db: Session) -> list[TaskItem]:
        tasks = (
            db.query(Task)
            .filter(Task.is_deleted.is_(True))
            .order_by(Task.deleted_at.desc(), Task.created_at.desc())
            .all()
        )
        return [self._to_schema(task) for task in tasks]

    def get_task(self, db: Session, task_id: str) -> TaskItem:
        task = self._get_task_or_404(db, task_id)
        return self._to_schema(task)

    def create_task(self, db: Session, payload: TaskCreate) -> TaskItem:
        task = Task(
            title=payload.title,
            notes=payload.notes,
            estimated_minutes=payload.estimated_minutes,
        )
        self.sync_progress_and_status(task)
        db.add(task)
        db.commit()
        db.refresh(task)
        return self._to_schema(task)

    def update_task(self, db: Session, task_id: str, payload: TaskUpdate) -> TaskItem:
        task = self._get_task_or_404(db, task_id)

        update_data = payload.model_dump(exclude_unset=True)

        # We only overwrite fields that the client actually sent.
        for field_name, value in update_data.items():
            if field_name == "status" and value is not None:
                value = value.value
            setattr(task, field_name, value)

        self.sync_progress_and_status(task)
        db.commit()
        db.refresh(task)
        return self._to_schema(task)

    def delete_task(self, db: Session, task_id: str) -> None:
        task = self._get_task_or_404(db, task_id)
        task.is_deleted = True
        task.deleted_at = datetime.utcnow()
        db.commit()

    def restore_task(self, db: Session, task_id: str) -> TaskItem:
        task = self._get_deleted_task_or_404(db, task_id)
        task.is_deleted = False
        task.deleted_at = None
        self.sync_progress_and_status(task)
        db.commit()
        db.refresh(task)
        return self._to_schema(task)

    def sync_progress_and_status(self, task: Task) -> None:
        estimated_minutes = task.estimated_minutes
        spent_minutes = task.spent_minutes or 0

        if estimated_minutes is None or estimated_minutes <= 0:
            task.progress = 0.0
            return

        progress = spent_minutes / estimated_minutes
        task.progress = max(0.0, min(progress, 1.0))

        if task.progress >= 1.0 and task.status != TaskStatus.paused.value:
            task.status = TaskStatus.completed.value

    def _to_schema(self, task: Task) -> TaskItem:
        # Convert the database row into the API response shape.
        return TaskItem(
            id=task.id,
            title=task.title,
            notes=task.notes,
            status=task.status,
            progress=task.progress,
            estimated_minutes=task.estimated_minutes,
            spent_minutes=task.spent_minutes,
            created_at=task.created_at,
            is_deleted=task.is_deleted,
            deleted_at=task.deleted_at,
        )

    def _get_task_or_404(self, db: Session, task_id: str) -> Task:
        task = (
            db.query(Task)
            .filter(Task.id == task_id, Task.is_deleted.is_(False))
            .first()
        )
        if task is None:
            raise HTTPException(status_code=404, detail="Task not found.")
        return task

    def _get_deleted_task_or_404(self, db: Session, task_id: str) -> Task:
        task = (
            db.query(Task)
            .filter(Task.id == task_id, Task.is_deleted.is_(True))
            .first()
        )
        if task is None:
            raise HTTPException(status_code=404, detail="Deleted task not found.")
        return task


task_service = TaskService()
