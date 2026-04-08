from typing import List
from app.orchestrator.simple_orchestrator import simple_orchestrator
from app.schemas.ai import SuggestNextActionTask


class AIService:
    # The service stays very small.
    # It now delegates AI work to a tiny orchestrator layer.
    #
    # This keeps today's code simple, while also preparing for future
    # agent evolution without changing the API routes.
    def __init__(self) -> None:
        self.orchestrator = simple_orchestrator

    def split_task_with_llm(self, user_input: str) -> List[str]:
        return self.orchestrator.run_split_task(user_input)

    def suggest_next_action_with_llm(self, task: SuggestNextActionTask) -> str:
        return self.orchestrator.run_suggest_next_action(task)


ai_service = AIService()
