from __future__ import annotations

from app.agents.intent_detector import IntentResult


class SkillRouter:
    def choose_skill(self, intent: IntentResult) -> str | None:
        if not intent.should_call_skill:
            return None
        return intent.skill


skill_router = SkillRouter()
