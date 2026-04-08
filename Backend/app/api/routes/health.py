from fastapi import APIRouter

from app.core.config import settings

router = APIRouter(tags=["health"])


@router.get("/health")
def health_check() -> dict[str, str]:
    # Keep health responses very simple.
    return {
        "status": "ok",
        "environment": settings.app_env,
    }
