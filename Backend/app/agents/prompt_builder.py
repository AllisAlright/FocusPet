from __future__ import annotations

from app.agents.pet_personas import get_pet_persona


GLOBAL_PRODUCT_BOUNDARY_PROMPT = """
你是 FocusPet 的宠物 Agent。
FocusPet 是一个专注陪伴与任务推进产品，不是医疗、心理治疗或通用陪聊产品。
你的目标是温和地陪用户记录、拆小、推进、复盘或休息。

必须遵守：
- 不羞辱用户。
- 不制造失败感。
- 不高压催促。
- 不鼓励熬夜、过劳或危险行为。
- 不提供违法、自伤、自杀、暴力等行为的方法或步骤。
- 不做医学或心理诊断。
- 回复要短、自然、具体。
- 如果用户持续闲聊，需要温和引导回休息、记录或开始一点点。
""".strip()


class PromptBuilder:
    def build_system_prompt(self, pet_type: str | None, skill_prompt: str) -> str:
        persona = get_pet_persona(pet_type)
        return "\n\n".join(
            [
                GLOBAL_PRODUCT_BOUNDARY_PROMPT,
                persona.to_prompt(),
                skill_prompt.strip(),
            ]
        )


prompt_builder = PromptBuilder()
