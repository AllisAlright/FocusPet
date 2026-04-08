from fastapi import HTTPException
from sqlalchemy.orm import Session

from app.models.focus_session import FocusSession
from app.models.task import Task
from app.schemas.focus_sessions import FocusSessionCreate, FocusSessionItem
from app.services.task_service import task_service


class FocusSessionService:
    def list_sessions(self, db: Session) -> list[FocusSessionItem]:
        sessions = db.query(FocusSession).order_by(FocusSession.created_at.desc()).all()
        return [self._to_schema(session) for session in sessions]

    def create_session(self, db: Session, payload: FocusSessionCreate) -> FocusSessionItem:
        linked_task = None

        if payload.task_id is not None:
            # If the client links this focus session to a task,
            # we first make sure that task really exists.
            linked_task = (
                db.query(Task)
                .filter(Task.id == str(payload.task_id), Task.is_deleted.is_(False))
                .first()
            )
            if linked_task is None:
                raise HTTPException(status_code=404, detail="Task not found for this focus session.")

        session = FocusSession(
            task_id=str(payload.task_id) if payload.task_id else None,
            duration_seconds=payload.duration_seconds,
            timer_mode=payload.timer_mode,
        )
        db.add(session)

        if linked_task is not None:
            added_minutes = payload.duration_seconds // 60
            linked_task.spent_minutes += added_minutes
            task_service.sync_progress_and_status(linked_task)

        db.commit()
        db.refresh(session)
        return self._to_schema(session)

    def _to_schema(self, session: FocusSession) -> FocusSessionItem:
        return FocusSessionItem(
            id=session.id,
            task_id=session.task_id,
            duration_seconds=session.duration_seconds,
            timer_mode=session.timer_mode,
            session_status=session.session_status,
            created_at=session.created_at,
        )


focus_session_service = FocusSessionService()
