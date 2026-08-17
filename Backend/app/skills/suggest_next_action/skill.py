from __future__ import annotations

import json

from openai import OpenAI

from app.agents.prompt_builder import prompt_builder
from app.core.config import settings
from app.schemas.ai import NextActionRecommendation, SuggestNextActionTask
from app.skills.base import SkillMetadata
from app.skills.suggest_next_action.fallback import (
    default_reason,
    empty_task_recommendation,
    fallback_recommendation,
    strip_wrapping_quotes,
)
from app.skills.suggest_next_action.prompt import (
    SUGGEST_NEXT_ACTION_PROMPT,
    build_suggest_next_action_user_prompt,
)


class SuggestNextActionSkill:
    metadata = SkillMetadata(
        name="suggest_next_action",
        description="Suggest one short, low-friction next action from the user's unfinished tasks.",
    )

    def __init__(self) -> None:
        self.client: OpenAI | None = None

    @property
    def name(self) -> str:
        return self.metadata.name

    @property
    def description(self) -> str:
        return self.metadata.description

    def run(self, task: SuggestNextActionTask, pet_type: str = "rabbit") -> str:
        return self.recommend(task, pet_type).action

    def recommend(
        self,
        task: SuggestNextActionTask,
        pet_type: str = "rabbit",
        reason: str | None = None,
        suggested_focus_minutes: int = 15,
    ) -> NextActionRecommendation:
        if task.type == "none" or not task.title.strip():
            return empty_task_recommendation(task, suggested_focus_minutes)

        if not settings.deepseek_api_key:
            return fallback_recommendation(task, reason, suggested_focus_minutes)

        if self.client is None:
            self.client = OpenAI(
                api_key=settings.deepseek_api_key,
                base_url="https://api.deepseek.com",
            )

        system_prompt = prompt_builder.build_system_prompt(pet_type, SUGGEST_NEXT_ACTION_PROMPT)
        user_prompt = build_suggest_next_action_user_prompt(task.title, task.type, reason)

        try:
            response = self.client.chat.completions.create(
                model="deepseek-chat",
                messages=[
                    {
                        "role": "system",
                        "content": system_prompt,
                    },
                    {
                        "role": "user",
                        "content": user_prompt,
                    },
                ],
                temperature=0.3,
                response_format={"type": "json_object"},
            )

            content = response.choices[0].message.content if response.choices else None
            if not content:
                return fallback_recommendation(task, reason, suggested_focus_minutes)

            parsed_message = self._parse_response(content)
            action = self._ensure_corner_quoted_title(parsed_message, task.title)
            return NextActionRecommendation(
                task_id=task.id,
                action=action,
                reason=reason or default_reason(task),
                suggested_focus_minutes=suggested_focus_minutes,
            )
        except Exception:
            return fallback_recommendation(task, reason, suggested_focus_minutes)

    def _parse_response(self, content: str) -> str:
        try:
            payload = json.loads(content)
        except json.JSONDecodeError as exc:
            raise ValueError("DeepSeek returned invalid JSON.") from exc

        message = payload.get("message")
        if not isinstance(message, str):
            raise ValueError("DeepSeek JSON must contain a 'message' string.")

        cleaned_message = message.strip()
        if not cleaned_message:
            raise ValueError("DeepSeek returned an empty message.")

        return cleaned_message

    def _ensure_corner_quoted_title(self, message: str, title: str) -> str:
        normalized_title = strip_wrapping_quotes(title.strip())
        if not normalized_title:
            return message.strip()

        quoted_title = f"「{normalized_title}」"
        normalized_message = message.strip()

        if quoted_title in normalized_message:
            return normalized_message

        return normalized_message.replace(normalized_title, quoted_title)


suggest_next_action_skill = SuggestNextActionSkill()
