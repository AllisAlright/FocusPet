from app.schemas.ai import SuggestNextActionTask
from app.skills.registry import skill_registry


class SimpleOrchestrator:
    # The orchestrator decides which skill to run.
    # This version is intentionally tiny:
    # it uses explicit method calls instead of natural-language routing.
    #
    # Later, more decision logic can be added here without changing routes.
    def __init__(self) -> None:
        self.registry = skill_registry

    def dispatch(self, skill_name: str, payload, pet_type: str = "rabbit"):
        skill = self.registry.get(skill_name)

        # Each skill exposes a focused run(...) method.
        # dispatch keeps the call site uniform.
        if skill_name == "split_task":
            return skill.run(payload, pet_type=pet_type)
        if skill_name == "suggest_next_action":
            return skill.run(payload, pet_type=pet_type)
        if skill_name == "weekly_review":
            return skill.run(payload, pet_type=pet_type)

        raise ValueError(f"Unsupported skill: {skill_name}")

    def run_split_task(self, user_input: str, pet_type: str = "rabbit") -> list[str]:
        return self.dispatch("split_task", user_input, pet_type=pet_type)

    def run_suggest_next_action(self, task: SuggestNextActionTask, pet_type: str = "rabbit") -> str:
        return self.dispatch("suggest_next_action", task, pet_type=pet_type)


simple_orchestrator = SimpleOrchestrator()
