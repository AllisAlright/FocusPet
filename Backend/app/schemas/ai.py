from typing import Literal, Optional

from pydantic import BaseModel, Field

PetType = Literal["rabbit", "cat", "dog", "hamster"]


class SplitTaskRequest(BaseModel):
    # The raw task text from the user.
    user_input: str = Field(..., min_length=1, description="The task that should be split into smaller steps.")
    pet_type: PetType = "rabbit"


class SplitTaskResponse(BaseModel):
    # The clean task list returned by the LLM after JSON parsing.
    tasks: list[str]


class SuggestNextActionTask(BaseModel):
    # The frontend selects one target task before calling the backend.
    # `type` tells the skill whether the task is a fresh start, in progress,
    # overdue reminder, paused fallback, or no task at all.
    title: str = ""
    type: Literal["in_progress", "todo", "overdue", "paused", "none"]
    id: Optional[str] = None
    progress: float = 0.0
    due_date: Optional[str] = None
    updated_at: Optional[str] = None


class SuggestNextActionRequest(BaseModel):
    # The frontend sends one selected task and its strategy type here.
    task: SuggestNextActionTask
    pet_type: PetType = "rabbit"


class SuggestNextActionResponse(BaseModel):
    # The skill returns one short suggestion sentence.
    message: str


class NextActionRecommendation(BaseModel):
    task_id: Optional[str] = None
    action: str
    reason: str
    suggested_focus_minutes: int = 15


class WeeklyReviewStats(BaseModel):
    total_focus_minutes: int = 0
    session_count: int = 0
    late_night_session_count: int = 0
    most_active_time_bucket: Optional[str] = None
    top_task_title: Optional[str] = None
    longest_session_minutes: int = 0


class WeeklyReviewRequest(BaseModel):
    pet_type: PetType = "rabbit"
    period_days: int = Field(default=7, ge=1, le=31)
    stats: WeeklyReviewStats


class WeeklyReviewResponse(BaseModel):
    summary: str
    observation: str
    pet_comment: str


class AgentTaskSummary(BaseModel):
    id: str
    title: str
    status: Literal["active", "in_progress", "todo", "paused", "overdue", "completed"]
    progress: float = 0.0
    due_date: Optional[str] = None
    updated_at: Optional[str] = None


class AgentMessageRequest(BaseModel):
    user_input: str = Field(..., min_length=1)
    pet_type: PetType = "rabbit"
    conversation_turn_count: int = Field(default=0, ge=0)
    tasks: list[AgentTaskSummary] = []
    review_stats: Optional[WeeklyReviewStats] = None
    today_focus_minutes: int = 0


class AgentMessageResponse(BaseModel):
    intent: str
    safety_level: str
    should_call_skill: bool
    skill: Optional[str] = None
    requires_confirmation: bool = False
    message: str
    tasks: list[str] = []
    recommendation: Optional[NextActionRecommendation] = None
    review: Optional[WeeklyReviewResponse] = None
