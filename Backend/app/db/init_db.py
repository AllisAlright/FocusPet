from sqlalchemy import inspect, text

from app.db.base import Base
from app.db.database import engine
from app.models import focus_session, task  # noqa: F401


def create_db_and_tables() -> None:
    # Importing the model modules registers the tables with SQLAlchemy.
    Base.metadata.create_all(bind=engine)
    _migrate_task_table()


def _migrate_task_table() -> None:
    inspector = inspect(engine)

    if "tasks" not in inspector.get_table_names():
        return

    existing_columns = {column["name"] for column in inspector.get_columns("tasks")}

    with engine.begin() as connection:
        if "is_deleted" not in existing_columns:
            connection.execute(
                text("ALTER TABLE tasks ADD COLUMN is_deleted BOOLEAN NOT NULL DEFAULT 0")
            )

        if "deleted_at" not in existing_columns:
            connection.execute(
                text("ALTER TABLE tasks ADD COLUMN deleted_at DATETIME")
            )

        connection.execute(
            text(
                """
                UPDATE tasks
                SET status = 'todo'
                WHERE status IS NULL
                   OR status NOT IN ('todo', 'in_progress', 'paused', 'completed')
                """
            )
        )

        connection.execute(
            text(
                """
                UPDATE tasks
                SET progress = CASE
                    WHEN estimated_minutes IS NOT NULL AND estimated_minutes > 0
                        THEN MIN(CAST(spent_minutes AS FLOAT) / estimated_minutes, 1.0)
                    ELSE 0.0
                END
                """
            )
        )

        connection.execute(
            text(
                """
                UPDATE tasks
                SET status = 'completed'
                WHERE status != 'paused'
                  AND estimated_minutes IS NOT NULL
                  AND estimated_minutes > 0
                  AND CAST(spent_minutes AS FLOAT) / estimated_minutes >= 1.0
                """
            )
        )
