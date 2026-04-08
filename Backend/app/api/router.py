from fastapi import APIRouter

from app.api.routes.ai import router as ai_router
from app.api.routes.focus_sessions import router as focus_sessions_router
from app.api.routes.health import router as health_router
from app.api.routes.tasks import router as tasks_router

api_router = APIRouter()

# Health is kept at the top level because it is commonly checked by tools.
api_router.include_router(health_router)

# Versioned API routes go under /api/v1.
api_v1_router = APIRouter(prefix="/api/v1")
api_v1_router.include_router(tasks_router)
api_v1_router.include_router(focus_sessions_router)
api_v1_router.include_router(ai_router)

api_router.include_router(api_v1_router)
