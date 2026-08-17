from __future__ import annotations

from dataclasses import dataclass
import re
from typing import Literal


SafetyLevel = Literal[
    "safe",
    "oversized_goal",
    "off_topic",
    "self_harm",
    "unsafe",
    "illegal",
    "health_risk",
    "adult_content",
    "relationship_emotional",
]


@dataclass(frozen=True)
class GuardResult:
    safety_level: SafetyLevel
    can_call_skill: bool
    category: str
    recommended_action: str
    message: str | None = None


class InputGuard:
    split_task_intent_keywords = (
        "帮我拆",
        "拆一下",
        "拆解",
        "分成几步",
        "怎么做",
        "怎么才能",
        "如何",
    )
    self_harm_keywords = (
        "自杀",
        "轻生",
        "不想活",
        "结束生命",
        "伤害自己",
        "死掉",
        "寻死",
    )
    illegal_keywords = (
        "诈骗",
        "偷钱",
        "盗窃",
        "洗钱",
        "制毒",
        "贩毒",
        "翻墙",
        "绕过封锁",
        "破解",
    )
    unsafe_keywords = (
        "杀人",
        "打人",
        "放火",
        "爆炸",
        "吃屎",
    )
    adult_content_keywords = (
        "黄片",
        "黄片",
        "a片",
        "成人视频",
        "色情",
        "约炮",
        "裸聊",
    )
    health_risk_keywords = (
        "三天不睡",
        "不睡觉",
        "通宵一周",
        "绝食",
        "过劳",
    )
    oversized_keywords = (
        "赚一百万",
        "赚到一百万",
        "赚到100万",
        "赚100万",
        "一百万",
        "100万",
        "百万",
        "财富自由",
        "一夜暴富",
        "暴富",
        "改变人生",
        "人生规划",
        "当总统",
        "做总统",
        "成为总统",
    )
    oversized_patterns = (
        re.compile(r"(赚|挣|搞|拿|获得|实现).{0,8}(一百万|100万|百万|千万|一个亿|1个亿)"),
        re.compile(r"(当|做|成为).{0,6}(总统|主席|首富|明星|网红|老板|ceo|CEO)"),
    )
    relationship_keywords = (
        "喜欢一个人",
        "喜欢上一个人",
        "喜欢上了一个人",
        "让他喜欢我",
        "让她喜欢我",
        "让对方喜欢我",
        "追到",
        "表白",
        "脱单",
        "挽回",
    )

    def check(self, text: str) -> GuardResult:
        normalized = text.strip().lower()

        if not normalized:
            return GuardResult(
                safety_level="off_topic",
                can_call_skill=False,
                category="empty",
                recommended_action="ask_for_input",
                message="先写下一件你想说的事吧。",
            )

        if self._contains_any(normalized, self.self_harm_keywords):
            return GuardResult(
                safety_level="self_harm",
                can_call_skill=False,
                category="self_harm",
                recommended_action="safety_response",
                message="我不能帮你规划伤害自己的事情。但我会认真陪你待在这里。如果你现在有马上伤害自己的冲动，请先联系身边可信的人，或立刻寻求当地紧急帮助。",
            )

        if self._contains_any(normalized, self.illegal_keywords):
            return GuardResult(
                safety_level="illegal",
                can_call_skill=False,
                category="illegal",
                recommended_action="redirect_to_safe_goal",
                message="这类内容不适合放进待办推进。我们先停在这里，换回学习、工作或生活里真的要处理的一小步。",
            )

        if self._contains_any(normalized, self.unsafe_keywords):
            return GuardResult(
                safety_level="unsafe",
                can_call_skill=False,
                category="unsafe_or_off_topic",
                recommended_action="redirect_to_product_goal",
                message="这类内容不适合拆成任务。我们先停一下，回到眼前真正需要处理的事情。",
            )

        if self._contains_any(normalized, self.adult_content_keywords):
            return GuardResult(
                safety_level="adult_content",
                can_call_skill=False,
                category="adult_or_off_topic",
                recommended_action="redirect_to_product_goal",
                message="这类内容不适合在这里推进。我们先把注意力放回学习、工作或生活里的一件小事。",
            )

        if self._contains_any(normalized, self.health_risk_keywords):
            return GuardResult(
                safety_level="health_risk",
                can_call_skill=False,
                category="health_risk",
                recommended_action="suggest_safer_plan",
                message="这个计划可能太透支了。我们换成更稳的一小段安排，好吗？",
            )

        if self._is_oversized_goal(normalized):
            return GuardResult(
                safety_level="oversized_goal",
                can_call_skill=False,
                category="oversized_goal",
                recommended_action="clarify_or_shrink_goal",
                message="这个目标太大、太远，直接拆会变得不真实。先把范围缩小到最近一周能验证的一件事。",
            )

        if self._is_relationship_emotional_goal(normalized):
            return GuardResult(
                safety_level="relationship_emotional",
                can_call_skill=False,
                category="relationship_emotional",
                recommended_action="support_or_clarify",
                message="感情里的事不能拆成保证结果的步骤。我们可以先聊聊你在意的是什么，也照顾好自己和对方的边界。",
            )

        return GuardResult(
            safety_level="safe",
            can_call_skill=True,
            category="normal",
            recommended_action="route_to_intent_detector",
        )

    def _contains_any(self, text: str, keywords: tuple[str, ...]) -> bool:
        return any(keyword in text for keyword in keywords)

    def _is_oversized_goal(self, text: str) -> bool:
        if self._contains_any(text, self.oversized_keywords):
            return True
        return any(pattern.search(text) for pattern in self.oversized_patterns)

    def _is_relationship_emotional_goal(self, text: str) -> bool:
        if not self._contains_any(text, self.split_task_intent_keywords):
            return False
        return self._contains_any(text, self.relationship_keywords)


input_guard = InputGuard()
