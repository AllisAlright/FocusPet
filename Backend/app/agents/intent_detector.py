from __future__ import annotations

from dataclasses import dataclass
from typing import Literal


IntentType = Literal[
    "split_task_candidate",
    "next_action_request",
    "weekly_review_request",
    "casual_chat",
    "emotional_support",
    "rest_request",
    "memo_candidate",
    "unknown",
]


@dataclass(frozen=True)
class IntentResult:
    intent: IntentType
    confidence: float
    should_call_skill: bool
    skill: str | None = None
    requires_confirmation: bool = False
    reply: str | None = None


class IntentDetector:
    def detect(self, text: str) -> IntentResult:
        normalized = text.strip().lower()

        if self._contains_any(normalized, ("复盘", "总结最近", "最近状态", "这周怎么样", "这一周怎么样")):
            return IntentResult(
                intent="weekly_review_request",
                confidence=0.88,
                should_call_skill=True,
                skill="weekly_review",
            )

        if self._contains_any(normalized, ("先做哪个", "下一步", "不知道先", "先干什么", "先做什么")):
            return IntentResult(
                intent="next_action_request",
                confidence=0.86,
                should_call_skill=True,
                skill="suggest_next_action",
            )

        if self._contains_any(normalized, ("帮我拆", "拆一下", "拆解", "分成几步")):
            return IntentResult(
                intent="split_task_candidate",
                confidence=0.9,
                should_call_skill=True,
                skill="split_task",
            )

        if self._contains_any(normalized, ("怎么准备", "怎么做", "不知道怎么")):
            return IntentResult(
                intent="split_task_candidate",
                confidence=0.82,
                should_call_skill=False,
                skill="split_task",
                requires_confirmation=True,
                reply="要不要我帮你拆成几步？这样会更容易开始。",
            )

        if self._contains_any(normalized, ("累", "烦", "不想", "没力气", "焦虑", "压力")):
            return IntentResult(
                intent="emotional_support",
                confidence=0.76,
                should_call_skill=False,
                reply="我听见啦。我们可以先不急着做，慢慢把眼前这一点放清楚。",
            )

        if self._contains_any(normalized, ("休息", "歇一会", "放空")):
            return IntentResult(
                intent="rest_request",
                confidence=0.78,
                should_call_skill=False,
                reply="可以先休息一下。等你愿意的时候，我们再回来做一点点。",
            )

        if self._contains_any(normalized, ("记一下", "备忘", "先记", "记下来")):
            return IntentResult(
                intent="memo_candidate",
                confidence=0.72,
                should_call_skill=False,
                reply="可以先记下来，之后再慢慢整理成任务。",
            )

        return IntentResult(
            intent="casual_chat",
            confidence=0.55,
            should_call_skill=False,
            reply="我在听。我们可以先聊一会儿，也可以把它变成一件小事。",
        )

    def _contains_any(self, text: str, keywords: tuple[str, ...]) -> bool:
        return any(keyword in text for keyword in keywords)


intent_detector = IntentDetector()
