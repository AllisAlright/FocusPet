from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.db.database import get_db
from app.schemas.focus_sessions import (
    FocusSessionCreate,
    FocusSessionItem,
    FocusSessionListResponse,
)
from app.services.focus_session_service import focus_session_service

router = APIRouter(prefix="/focus-sessions", tags=["focus-sessions"])


@router.get("", response_model=FocusSessionListResponse)
def list_focus_sessions(db: Session = Depends(get_db)) -> FocusSessionListResponse:
    return FocusSessionListResponse(items=focus_session_service.list_sessions(db))


@router.post("", response_model=FocusSessionItem, status_code=201)
def create_focus_session(
    payload: FocusSessionCreate,
    db: Session = Depends(get_db),
) -> FocusSessionItem:
    return focus_session_service.create_session(db, payload)
