import json
from typing import Optional

from openai import OpenAI

from app.core.config import settings
from app.schemas.ai import SuggestNextActionTask


class SuggestNextActionSkill:
    # This Skill suggests only one next action.
    # It is different from split_task:
    # - split_task breaks one big goal into multiple steps
    # - suggest_next_action picks one current task and suggests one gentle next move
    name = "suggest_next_action"
    description = "Suggest one short, low-friction next action from the user's unfinished tasks."
    empty_tasks_fallback = "先写下一件你最想推进的事吧"

    def __init__(self) -> None:
        self.client: OpenAI | None = None

    def run(self, task: SuggestNextActionTask) -> str:
        # The frontend already picked one strategy target.
        # If there is no usable task, return a gentle fallback immediately.
        if task.type == "none":
            return self.empty_tasks_fallback

        if not task.title.strip():
            return self.empty_tasks_fallback

        if not settings.deepseek_api_key:
            raise ValueError("DEEPSEEK_API_KEY is missing. Please set it in your .env file.")

        if self.client is None:
            self.client = OpenAI(
                api_key=settings.deepseek_api_key,
                base_url="https://api.deepseek.com",
            )

        # We first choose the task in backend code, then ask the LLM for
        # one sentence only. This keeps the behavior simple and predictable.
        system_prompt = """
你是 FocusPet 的下一步建议助手。
你的语气温和、简短、不施压，像在轻轻提醒用户先推进一点点。

你的任务是根据给定的单个任务和任务类型，输出一句下一步建议。

必须遵守这些规则：
1. 只输出中文。
2. 只返回严格 JSON，格式必须是 {"message":"..."}。
3. 只返回一句话。
4. 这句话必须具体、容易开始、低门槛、长度尽量短。
5. 语气必须温和、像陪伴式建议，不要像命令。
6. 优先使用“可以先...”或“要不要先...”这类柔和表达。
7. 不要使用“请”、不要直接下指令，不要使用命令式开头。
8. 不要使用强人格表达，比如“兔兔觉得”“我建议你”“你应该”。
9. 不要解释原因，不要给多个选项。
10. 不要写空泛建议，比如“继续努力”或“做好规划”。
11. 不要把整件事都塞进一句话里。
12. 任务标题在输出里必须始终用中文角引号包裹，写成「任务标题」。
13. 不要省略角引号，也不要改用书名号、双引号或其他括号。

当 task.type == "in_progress"：
- 重点是“继续推进一点点”
- 例子：要不要继续把「项目案例整理」推进一点点
- 例子：可以先把「项目案例整理」往前做一步

当 task.type == "todo"：
- 重点是“开始一点点”
- 例子：要不要开始做「准备自我介绍」
- 例子：可以先从「准备自我介绍」开始一点点

当 task.type == "overdue"：
- 重点是“它已经逾期了，但只需要先捡起来一点点”
- 必须明确提到“逾期”
- 例子：要不要把逾期的「复习数据库」重新捡起来
- 例子：可以先把逾期的「复习数据库」继续一点点

当 task.type == "paused"：
- 重点是“重新捡起来”
- 必须明确提到“暂停”
- 例子：要不要把「复习数据库」重新捡起来
- 例子：可以先把暂停的「复习数据库」继续一点点

当 task.type == "none"：
- 直接输出：先写下一件你最想推进的事吧

示例 1：
输入任务：标题=整理项目案例，类型=in_progress
输出：
{"message":"可以先把「整理项目案例」往前做一步。"}

示例 2：
输入任务：标题=准备自我介绍，类型=todo
输出：
{"message":"要不要开始做「准备自我介绍」。"}

示例 3：
输入任务：标题=补交周报，类型=overdue
输出：
{"message":"要不要把逾期的「补交周报」重新捡起来。"}

示例 4：
输入任务：标题=复习数据库，类型=paused
输出：
{"message":"可以先把暂停的「复习数据库」继续一点点。"}
""".strip()

        user_prompt = f"""
请根据下面这个任务，给出一句适合 FocusPet 的下一步建议。

要求：
- 只给一句话
- 要具体到马上能做
- 语气温和
- 更像轻轻建议，不像命令
- 尽量用“可以先...”或“要不要先...”
- 不要出现“请”或“你应该”
- 任务标题在输出时必须写成「{task.title}」这种格式
- 只返回 JSON

任务标题：{task.title}
任务类型：{task.type}
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

        parsed_message = self._parse_response(content)
        return self._ensure_corner_quoted_title(parsed_message, task.title)

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
        normalized_title = self._strip_wrapping_quotes(title.strip())
        if not normalized_title:
            return message.strip()

        quoted_title = f"「{normalized_title}」"
        normalized_message = message.strip()

        if quoted_title in normalized_message:
            return normalized_message

        return normalized_message.replace(normalized_title, quoted_title)

    def _strip_wrapping_quotes(self, title: str) -> str:
        if len(title) >= 2:
            wrapping_pairs = {
                ("「", "」"),
                ("“", "”"),
                ("\"", "\""),
                ("'", "'"),
                ("《", "》"),
            }
            for opening, closing in wrapping_pairs:
                if title.startswith(opening) and title.endswith(closing):
                    return title[1:-1].strip()

        return title


suggest_next_action_skill = SuggestNextActionSkill()
