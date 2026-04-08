from fastapi import FastAPI

from app.api.router import api_router
from app.core.config import settings
from app.db.init_db import create_db_and_tables


# This is the main FastAPI application object.
# Uvicorn will import `app.main:app` when the server starts.
app = FastAPI(
    title=settings.app_name,
    debug=settings.app_debug,
    version="0.1.0",
    description="Local backend MVP scaffold for FocusPet.",
)


@app.on_event("startup")
def on_startup() -> None:
    # Create the local SQLite file and tables when the app starts.
    create_db_and_tables()


@app.get("/")
def root() -> dict[str, str]:
    # A tiny root endpoint so beginners can confirm the server is alive.
    return {
        "message": "FocusPet backend is running.",
        "docs": "/docs",
    }


app.include_router(api_router)
