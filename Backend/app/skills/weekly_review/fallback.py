from __future__ import annotations

from app.schemas.ai import WeeklyReviewResponse, WeeklyReviewStats


def fallback_review(
    stats: WeeklyReviewStats,
    pet_type: str,
    period_days: int,
) -> WeeklyReviewResponse:
    if stats.session_count <= 0:
        summary = f"最近 {period_days} 天还没有专注记录。"
        observation = "现在从一小段开始也来得及。"
    else:
        summary = f"最近 {period_days} 天你专注了 {stats.session_count} 次，累计 {stats.total_focus_minutes} 分钟。"
        if stats.top_task_title:
            observation = f"你主要在推进「{stats.top_task_title}」。"
        elif stats.late_night_session_count >= 2:
            observation = "我看到你有几次很晚还在投入。"
        else:
            observation = "这些小段投入都已经留下来了。"

    if pet_type == "cat":
        pet_comment = "节奏不用吵，稳一点就好。"
    elif pet_type == "dog":
        pet_comment = "这已经是很好的前进啦。"
    elif pet_type == "hamster":
        pet_comment = "哼，不是完全没动嘛。记得别把电量耗空。"
    else:
        pet_comment = "没关系，我们继续慢慢来。"

    return WeeklyReviewResponse(
        summary=summary,
        observation=observation,
        pet_comment=pet_comment,
    )
