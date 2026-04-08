from app.skills.suggest_next_action_skill import suggest_next_action_skill
from app.skills.split_task_skill import split_task_skill


class SkillRegistry:
    # A registry is a small lookup table for skills.
    # It lets the rest of the backend ask for a skill by name
    # instead of importing each skill in many places.
    #
    # This is helpful now because we already have multiple skills,
    # and later an orchestrator can use the same registry to choose tools.
    def __init__(self) -> None:
        self._skills = {
            split_task_skill.name: split_task_skill,
            suggest_next_action_skill.name: suggest_next_action_skill,
        }

    def get(self, skill_name: str):
        skill = self._skills.get(skill_name)
        if skill is None:
            raise ValueError(f"Unknown skill: {skill_name}")
        return skill

    def list_names(self) -> list[str]:
        return list(self._skills.keys())


skill_registry = SkillRegistry()
