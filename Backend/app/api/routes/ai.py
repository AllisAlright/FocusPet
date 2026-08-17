from fastapi import APIRouter, HTTPException, status

from app.schemas.ai import (
    AgentMessageRequest,
    AgentMessageResponse,
    SplitTaskRequest,
    SplitTaskResponse,
    SuggestNextActionRequest,
    SuggestNextActionResponse,
    WeeklyReviewRequest,
    WeeklyReviewResponse,
)
from app.services.ai_service import ai_service

router = APIRouter(prefix="/ai", tags=["ai"])


@router.post("/split-task", response_model=SplitTaskResponse)
def split_task(payload: SplitTaskRequest) -> SplitTaskResponse:
    # Keep the route thin:
    # it receives the request, calls the service, and converts errors
    # into HTTP responses that are easy to debug in /docs.
    try:
        tasks = ai_service.split_task_with_llm(payload.user_input, pet_type=payload.pet_type)
        return SplitTaskResponse(tasks=tasks)
    except ValueError as exc:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(exc),
        ) from exc
    except Exception as exc:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="DeepSeek request failed. Please check your API key and server logs.",
        ) from exc


@router.post("/suggest-next-action", response_model=SuggestNextActionResponse)
def suggest_next_action(payload: SuggestNextActionRequest) -> SuggestNextActionResponse:
    # This route uses the second formal Skill.
    # The frontend sends one selected task strategy target,
    # and the backend returns one small suggested next action.
    try:
        message = ai_service.suggest_next_action_with_llm(payload.task, pet_type=payload.pet_type)
        return SuggestNextActionResponse(message=message)
    except ValueError as exc:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(exc),
        ) from exc
    except Exception as exc:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="DeepSeek request failed. Please check your API key and server logs.",
        ) from exc


@router.post("/weekly-review", response_model=WeeklyReviewResponse)
def weekly_review(payload: WeeklyReviewRequest) -> WeeklyReviewResponse:
    try:
        return ai_service.weekly_review_with_llm(
            payload.stats,
            pet_type=payload.pet_type,
            period_days=payload.period_days,
        )
    except ValueError as exc:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(exc),
        ) from exc
    except Exception as exc:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="DeepSeek request failed. Please check your API key and server logs.",
        ) from exc


@router.post("/agent-message", response_model=AgentMessageResponse)
def agent_message(payload: AgentMessageRequest) -> AgentMessageResponse:
    try:
        return ai_service.handle_agent_message(payload)
    except ValueError as exc:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(exc),
        ) from exc
    except Exception as exc:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Pet Agent request failed. Please check your API key and server logs.",
        ) from exc
