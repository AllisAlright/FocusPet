import json
from typing import List

from openai import OpenAI

from app.core.config import settings


class SplitTaskSkill:
    # A Skill is a small, clearly-defined AI ability.
    # Here the ability is: take one user goal and break it into small tasks.
    #
    # This is useful because later an orchestrator can choose between many skills,
    # but today we keep it simple and call this skill directly.
    name = "split_task"
    description = "Break a user goal into 3 to 5 small, actionable task steps."

    def __init__(self) -> None:
        self.client: OpenAI | None = None

    def run(self, user_input: str) -> List[str]:
        # Fail early with a clear message if the API key is missing.
        if not settings.deepseek_api_key:
            raise ValueError("DEEPSEEK_API_KEY is missing. Please set it in your .env file.")

        # Create the client only when we really need it.
        # This keeps local startup simple even before the user adds the API key.
        if self.client is None:
            self.client = OpenAI(
                api_key=settings.deepseek_api_key,
                base_url="https://api.deepseek.com",
            )

        # The prompt is strict on purpose:
        # 1. output must be Chinese
        # 2. output must be JSON only
        # 3. task count must stay in the 3-5 range
        system_prompt = """
你是 FocusPet 的任务拆解助手。
你的风格是温和、具体、轻量，帮助用户“先开始一点点”，而不是给宏观建议。

你的任务是把一个目标拆成 3 到 5 个可以直接放进待办列表的小步骤。

必须遵守这些规则：
1. 只输出中文。
2. 只返回严格 JSON，格式必须是 {"tasks":["任务1","任务2"]}。
3. tasks 必须是 3 到 5 条。
4. 每一条都必须是一句完整的话。
5. 每一条都要具体、容易立刻开始，最好是低门槛的小动作。
6. 优先写“打开、整理、列出、写下、查找、确认、完成初稿”这类可执行动作。
7. 不要写空泛策略，不要写抽象建议，不要写总结性鼓励。
8. 不要写“研究公司产品、文化和面试流程”这种过大的动作。
9. 不要写“获取反馈并调整表现”这种模糊动作。
10. 每一步尽量只做一件事，避免一句里塞太多动作。

好的拆解应该让用户看到后马上知道第一步能做什么。

示例 1：
用户输入：准备前端开发面试
输出：
{"tasks":["列出这次面试可能会被问到的 5 个前端基础题。","打开简历，补上最近一个项目的结果和数据。","整理 2 个最想重点讲的项目经历，并各写下 3 个要点。","用 20 分钟练习一遍自我介绍和项目介绍。"]}

示例 2：
用户输入：完成毕业论文开题报告
输出：
{"tasks":["打开开题报告模板，先写下论文题目和研究方向。","整理 3 篇最相关的参考文献，并记下每篇的核心观点。","写出研究背景和研究意义的初稿。","列出论文计划使用的研究方法和大致步骤。","检查格式和缺失内容，再补齐需要提交的信息。"]}
""".strip()

        user_prompt = f"""
请把下面这个目标拆成适合 FocusPet 待办列表的小步骤。

要求：
- 从最容易开始的动作优先拆起
- 每一步都要能马上执行
- 避免空泛、抽象、战略层面的表达
- 输出 3 到 5 步
- 只返回 JSON，不要解释

用户目标：{user_input}
""".strip()

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
            raise ValueError("DeepSeek returned an empty response.")

        return self._parse_response(content)

    def _parse_response(self, content: str) -> List[str]:
        # Parse JSON carefully so the API returns a clean, predictable shape.
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

        return cleaned_tasks


split_task_skill = SplitTaskSkill()
