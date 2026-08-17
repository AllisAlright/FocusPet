from __future__ import annotations

import json

from openai import OpenAI

from app.agents.prompt_builder import prompt_builder
from app.core.config import settings
from app.schemas.ai import WeeklyReviewResponse, WeeklyReviewStats
from app.skills.base import SkillMetadata
from app.skills.weekly_review.fallback import fallback_review
from app.skills.weekly_review.prompt import WEEKLY_REVIEW_PROMPT, build_weekly_review_user_prompt


FORBIDDEN_ACTION_REVIEW_PARTS = (
    "明天再战也不迟",
    "明天再战",
    "再战也不迟",
    "再战",
    "下一轮",
    "下一步",
    "先做",
    "要不要",
    "留一点时间",
    "白天做",
)


class WeeklyReviewSkill:
    metadata = SkillMetadata(
        name="weekly_review",
        description="Summarize the user's last 7 days of focus activity with pet persona.",
    )

    def __init__(self) -> None:
        self.client: OpenAI | None = None

    @property
    def name(self) -> str:
        return self.metadata.name

    @property
    def description(self) -> str:
        return self.metadata.description

    def run(
        self,
        stats: WeeklyReviewStats,
        pet_type: str = "rabbit",
        period_days: int = 7,
    ) -> WeeklyReviewResponse:
        if not settings.deepseek_api_key:
            return fallback_review(stats, pet_type, period_days)

        if self.client is None:
            self.client = OpenAI(
                api_key=settings.deepseek_api_key,
                base_url="https://api.deepseek.com",
            )

        system_prompt = prompt_builder.build_system_prompt(pet_type, WEEKLY_REVIEW_PROMPT)
        user_prompt = build_weekly_review_user_prompt(
            period_days=period_days,
            total_focus_minutes=stats.total_focus_minutes,
            session_count=stats.session_count,
            late_night_session_count=stats.late_night_session_count,
            most_active_time_bucket=stats.most_active_time_bucket,
            top_task_title=stats.top_task_title,
            longest_session_minutes=stats.longest_session_minutes,
        )

        try:
            response = self.client.chat.completions.create(
                model="deepseek-chat",
                messages=[
                    {"role": "system", "content": system_prompt},
                    {"role": "user", "content": user_prompt},
                ],
                temperature=0.4,
                response_format={"type": "json_object"},
            )

            content = response.choices[0].message.content if response.choices else None
            if not content:
                return fallback_review(stats, pet_type, period_days)

            return self._parse_response(content)
        except Exception:
            return fallback_review(stats, pet_type, period_days)

    def _parse_response(self, content: str) -> WeeklyReviewResponse:
        try:
            payload = json.loads(content)
        except json.JSONDecodeError as exc:
            raise ValueError("DeepSeek returned invalid JSON.") from exc

        summary = payload.get("summary")
        observation = payload.get("observation")
        pet_comment = payload.get("pet_comment")

        if not isinstance(summary, str) or not summary.strip():
            raise ValueError("DeepSeek JSON must contain a non-empty 'summary'.")
        if not isinstance(observation, str) or not observation.strip():
            raise ValueError("DeepSeek JSON must contain a non-empty 'observation'.")
        if not isinstance(pet_comment, str) or not pet_comment.strip():
            raise ValueError("DeepSeek JSON must contain a non-empty 'pet_comment'.")

        return WeeklyReviewResponse(
            summary=self._clean_review_text(summary),
            observation=self._clean_review_text(observation),
            pet_comment=self._clean_review_text(pet_comment),
        )

    def _clean_review_text(self, text: str) -> str:
        cleaned = text.strip()
        for phrase in FORBIDDEN_ACTION_REVIEW_PARTS:
            cleaned = cleaned.replace(phrase, "休息也很重要")
        return cleaned.strip()


weekly_review_skill = WeeklyReviewSkill()
