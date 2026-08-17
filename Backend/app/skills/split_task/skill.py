from __future__ import annotations

import json
from typing import List

from openai import OpenAI

from app.agents.input_guard import input_guard
from app.agents.prompt_builder import prompt_builder
from app.core.config import settings
from app.skills.base import SkillMetadata
from app.skills.split_task.fallback import fallback_tasks
from app.skills.split_task.prompt import SPLIT_TASK_PROMPT, build_split_task_user_prompt


DISALLOWED_TASK_PARTS = (
    "一百万",
    "100万",
    "百万",
    "财富自由",
    "暴富",
    "总统",
    "首富",
    "明星",
    "网红",
    "翻墙",
    "代理",
    "绕过",
    "破解",
    "黄片",
    "a片",
    "成人视频",
    "色情",
    "约炮",
    "裸聊",
    "杀人",
    "打人",
    "爆炸",
    "放火",
    "自杀",
    "轻生",
    "不睡觉",
    "通宵一周",
    "绝食",
    "喜欢一个人",
    "喜欢上一个人",
    "让他喜欢我",
    "让她喜欢我",
    "让对方喜欢我",
    "追到",
    "表白",
    "脱单",
    "挽回",
)


class SplitTaskSkill:
    metadata = SkillMetadata(
        name="split_task",
        description="Break a user goal into 3 to 5 small, actionable task steps.",
    )

    def __init__(self) -> None:
        self.client: OpenAI | None = None

    @property
    def name(self) -> str:
        return self.metadata.name

    @property
    def description(self) -> str:
        return self.metadata.description

    def run(self, user_input: str, pet_type: str = "rabbit") -> List[str]:
        guard_result = input_guard.check(user_input)
        if not guard_result.can_call_skill:
            raise ValueError(guard_result.message or "这个内容暂时不适合拆成任务。")

        if not settings.deepseek_api_key:
            return fallback_tasks(user_input)

        if self.client is None:
            self.client = OpenAI(
                api_key=settings.deepseek_api_key,
                base_url="https://api.deepseek.com",
            )

        system_prompt = prompt_builder.build_system_prompt(pet_type, SPLIT_TASK_PROMPT)
        user_prompt = build_split_task_user_prompt(user_input)

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
                return fallback_tasks(user_input)

            return self._parse_response(content)
        except Exception:
            return fallback_tasks(user_input)

    def _parse_response(self, content: str) -> List[str]:
        try:
            payload = json.loads(content)
        except json.JSONDecodeError as exc:
            raise ValueError("DeepSeek returned invalid JSON.") from exc

        tasks = payload.get("tasks")
        if not isinstance(tasks, list):
            raise ValueError("DeepSeek JSON must contain a 'tasks' list.")

        cleaned_tasks: List[str] = []
        for item in tasks:
            if not isinstance(item, str):
                continue

            cleaned_item = item.strip()
            if cleaned_item:
                cleaned_tasks.append(cleaned_item)

        if not cleaned_tasks:
            raise ValueError("DeepSeek returned an empty task list.")

        if len(cleaned_tasks) < 3 or len(cleaned_tasks) > 5:
            raise ValueError("DeepSeek must return between 3 and 5 tasks.")

        self._validate_generated_tasks(cleaned_tasks)
        return cleaned_tasks

    def _validate_generated_tasks(self, tasks: List[str]) -> None:
        joined_tasks = "\n".join(tasks).lower()
        for phrase in DISALLOWED_TASK_PARTS:
            if phrase.lower() in joined_tasks:
                raise ValueError("Generated tasks contain content that should not be taskified.")


split_task_skill = SplitTaskSkill()
