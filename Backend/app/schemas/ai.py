from typing import Literal

from pydantic import BaseModel, Field


class SplitTaskRequest(BaseModel):
    # The raw task text from the user.
    user_input: str = Field(..., min_length=1, description="The task that should be split into smaller steps.")


class SplitTaskResponse(BaseModel):
    # The clean task list returned by the LLM after JSON parsing.
    tasks: list[str]


class SuggestNextActionTask(BaseModel):
    # The frontend selects one target task before calling the backend.
    # `type` tells the skill whether the task is a fresh start, in progress,
    # overdue reminder, paused fallback, or no task at all.
    title: str = ""
    type: Literal["in_progress", "todo", "overdue", "paused", "none"]


class SuggestNextActionRequest(BaseModel):
    # The frontend sends one selected task and its strategy type here.
    task: SuggestNextActionTask


class SuggestNextActionResponse(BaseModel):
    # The skill returns one short suggestion sentence.
    message: str
