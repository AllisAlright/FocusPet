from __future__ import annotations

from typing import Optional

from app.schemas.ai import NextActionRecommendation, SuggestNextActionTask


EMPTY_TASKS_FALLBACK = "先写下一件你最想推进的事吧"


def strip_wrapping_quotes(title: str) -> str:
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


def default_reason(task: SuggestNextActionTask) -> str:
    if task.type == "in_progress":
        return "它已经有一点进展，继续成本更低。"
    if task.type == "overdue":
        return "它已经逾期，适合先轻轻捡回来。"
    if task.type == "paused":
        return "它暂停过一阵子，可以先恢复一点点。"
    if task.type == "todo":
        return "它现在适合从一个小开头开始。"
    return "当前没有更明确的任务上下文。"


def empty_task_recommendation(
    task: SuggestNextActionTask,
    suggested_focus_minutes: int,
) -> NextActionRecommendation:
    return NextActionRecommendation(
        task_id=task.id,
        action=EMPTY_TASKS_FALLBACK,
        reason="当前没有可推进的待办。",
        suggested_focus_minutes=suggested_focus_minutes,
    )


def fallback_recommendation(
    task: SuggestNextActionTask,
    reason: Optional[str],
    suggested_focus_minutes: int,
) -> NextActionRecommendation:
    title = strip_wrapping_quotes(task.title.strip())
    quoted_title = f"「{title}」"

    if task.type == "in_progress":
        action = f"可以先把{quoted_title}往前推进一点点。"
    elif task.type == "overdue":
        action = f"可以先把逾期的{quoted_title}轻轻捡回来。"
    elif task.type == "paused":
        action = f"可以先把暂停的{quoted_title}重新捡起来。"
    else:
        action = f"可以先从{quoted_title}开一个小头。"

    return NextActionRecommendation(
        task_id=task.id,
        action=action,
        reason=reason or default_reason(task),
        suggested_focus_minutes=suggested_focus_minutes,
    )
