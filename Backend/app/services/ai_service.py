from typing import List
from app.agents.pet_agent import pet_agent
from app.orchestrator.simple_orchestrator import simple_orchestrator
from app.schemas.ai import (
    AgentMessageRequest,
    AgentMessageResponse,
    SuggestNextActionTask,
    WeeklyReviewResponse,
    WeeklyReviewStats,
)


class AIService:
    # The service stays very small.
    # It now delegates AI work to a tiny orchestrator layer.
    #
    # This keeps today's code simple, while also preparing for future
    # agent evolution without changing the API routes.
    def __init__(self) -> None:
        self.orchestrator = simple_orchestrator

    def split_task_with_llm(self, user_input: str, pet_type: str = "rabbit") -> List[str]:
        return self.orchestrator.run_split_task(user_input, pet_type=pet_type)

    def suggest_next_action_with_llm(self, task: SuggestNextActionTask, pet_type: str = "rabbit") -> str:
        return self.orchestrator.run_suggest_next_action(task, pet_type=pet_type)

    def weekly_review_with_llm(
        self,
        stats: WeeklyReviewStats,
        pet_type: str = "rabbit",
        period_days: int = 7,
    ) -> WeeklyReviewResponse:
        return self.orchestrator.dispatch("weekly_review", stats, pet_type=pet_type)

    def handle_agent_message(self, payload: AgentMessageRequest) -> AgentMessageResponse:
        return pet_agent.handle_message(payload)


ai_service = AIService()
