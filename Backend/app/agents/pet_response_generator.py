from __future__ import annotations

from typing import TYPE_CHECKING

from app.agents.prompt_builder import GLOBAL_PRODUCT_BOUNDARY_PROMPT
from app.agents.pet_personas import get_pet_persona
from app.core.config import settings
from app.schemas.ai import NextActionRecommendation, WeeklyReviewResponse

if TYPE_CHECKING:
    from openai import OpenAI


class PetResponseGenerator:
    """Generate the final pet-facing sentence without letting the LLM execute actions."""

    def __init__(self) -> None:
        self.client: OpenAI | None = None

    def chat(
        self,
        user_input: str,
        pet_type: str,
        conversation_turn_count: int,
        fallback: str,
    ) -> str:
        prompt = f"""
用户刚才说：
{user_input}

请用当前宠物的人设回复用户。

要求：
- 最多 2 句话。
- 不要调用或承诺任何工具能力。
- 不要说自己是 AI 或模型。
- 如果用户只是闲聊，可以自然回应。
- 如果已经聊了 {conversation_turn_count} 轮或更多，需要温和引导回“休息 / 记录 / 开始一点点”。
- 不要编造用户没有提供的事实。
- 不要使用“正事”“喜欢不重要”这类生硬或否定用户感受的表达。
""".strip()
        return self._generate(pet_type, prompt, fallback, temperature=0.6)

    def safety_response(
        self,
        user_input: str,
        safety_level: str,
        recommended_action: str,
        pet_type: str,
        fallback: str,
    ) -> str:
        prompt = f"""
用户输入被安全层判定为：{safety_level}
推荐处理方向：{recommended_action}
用户原始输入：
{user_input}

请用当前宠物的人设回复用户。

要求：
- 只回复 1 到 2 句话。
- 必须明确不能帮助规划危险、违法、自伤或不适合任务推进的内容。
- 不要提供任何步骤、方法、清单、材料或可执行建议来完成危险行为。
- 如果是自伤相关，要温和建议用户先远离即时危险，并联系身边可信的人或当地紧急帮助。
- 如果是 oversized_goal，要明确说明“直接拆会变得不真实/不可验证”，只邀请用户先缩小到最近一周能验证的范围，不要给赚钱、成名、上位或宏大成功路径。
- 如果是 relationship_emotional，要说明感情不能拆成保证结果的步骤，可以陪用户聊清楚感受和边界；不要安排约会、表白、追求、靠近等行动步骤。
- 如果不是自伤相关，要说明“这件事不适合放进待办推进”，再温和带回学习、工作或生活里的一个具体任务。
- 不要使用“真正需要处理”“真正想推进”这类带评判感的表达。
- 不要使用“换个安全的事”“安全的小事”“正事”这类生硬表达。
- 不要羞辱用户，不要说教，不要复述危险细节。
""".strip()
        return self._generate(pet_type, prompt, fallback, temperature=0.35)

    def split_task_message(self, user_input: str, tasks: list[str], pet_type: str, fallback: str) -> str:
        task_lines = "\n".join(f"- {task}" for task in tasks)
        prompt = f"""
用户想拆的目标：
{user_input}

已经拆出的待办步骤：
{task_lines}

请用当前宠物的人设说一句确认前的提示。

要求：
- 只说 1 句话。
- 需要表达“已经拆好了/可以选要放进待办的内容”。
- 不要重复完整任务列表。
- 不要说已经帮用户创建待办，因为还需要用户确认。
""".strip()
        return self._generate(pet_type, prompt, fallback, temperature=0.45)

    def next_action_message(
        self,
        recommendation: NextActionRecommendation,
        pet_type: str,
        fallback: str,
    ) -> str:
        prompt = f"""
后端已经选出的下一步建议：
- 动作：{recommendation.action}
- 推荐理由：{recommendation.reason}
- 建议专注时长：{recommendation.suggested_focus_minutes} 分钟

请用当前宠物的人设把它组织成一条给用户看的消息。

要求：
- 最多 2 句话。
- 必须包含推荐理由。
- 可以温和询问是否要开始 {recommendation.suggested_focus_minutes} 分钟。
- 不要给出第二个任务选择。
""".strip()
        return self._generate(pet_type, prompt, fallback, temperature=0.45)

    def weekly_review_message(self, review: WeeklyReviewResponse, pet_type: str, fallback: str) -> str:
        prompt = f"""
后端已经生成的 7 天复盘：
- 总结：{review.summary}
- 观察：{review.observation}
- 宠物想法：{review.pet_comment}

请用当前宠物的人设整理成一段给用户看的复盘话术。

        要求：
        - 2 到 3 句话。
        - 不要新增下一步行动建议。
        - 不要使用“开始”“再战”“下一轮”“先做”“要不要”“留一点时间”“白天做”这类行动召唤。
        - 可以保留一点宠物视角。
        - 如果提到熬夜，只能温柔提醒早点休息。
""".strip()
        return self._generate(pet_type, prompt, fallback, temperature=0.5)

    def _generate(self, pet_type: str, user_prompt: str, fallback: str, temperature: float) -> str:
        if not settings.deepseek_api_key:
            return fallback

        if self.client is None:
            from openai import OpenAI

            self.client = OpenAI(
                api_key=settings.deepseek_api_key,
                base_url="https://api.deepseek.com",
            )

        system_prompt = self._system_prompt(pet_type)
        try:
            response = self.client.chat.completions.create(
                model="deepseek-chat",
                messages=[
                    {"role": "system", "content": system_prompt},
                    {"role": "user", "content": user_prompt},
                ],
                temperature=temperature,
                max_tokens=180,
            )
        except Exception:
            return fallback

        content = response.choices[0].message.content if response.choices else None
        if not content:
            return fallback

        cleaned = self._clean_text(content)
        return cleaned or fallback

    def _system_prompt(self, pet_type: str) -> str:
        persona = get_pet_persona(pet_type)
        final_response_rules = """
你只负责生成宠物最后说出口的话，不负责执行工具、不负责写入数据、不负责删除或修改用户内容。
如果上下文里有 skill 结果，你只能转述和包装，不要新增未经确认的执行结果。
回复必须简短、自然、中文。
""".strip()
        return "\n\n".join(
            [
                GLOBAL_PRODUCT_BOUNDARY_PROMPT,
                persona.to_prompt(),
                final_response_rules,
            ]
        )

    def _clean_text(self, content: str) -> str:
        cleaned = content.strip()
        if cleaned.startswith(("“", "\"")) and cleaned.endswith(("”", "\"")):
            cleaned = cleaned[1:-1].strip()
        return cleaned


pet_response_generator = PetResponseGenerator()
