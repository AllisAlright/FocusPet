from __future__ import annotations

from typing import List


def fallback_tasks(user_input: str) -> List[str]:
    if "面试" in user_input:
        return [
            "列出这次面试最重要的岗位要求。",
            "整理 2 到 3 个能代表你的项目经历。",
            "写一个 1 分钟左右的自我介绍。",
            "挑 5 个常见问题做一轮简短练习。",
        ]

    if "作品集" in user_input:
        return [
            "确认这次作品集要放进哪些项目。",
            "给每个项目补一段背景、目标和结果。",
            "整理项目过程图和最终展示图。",
            "统一一版排版、封面和导出格式。",
        ]

    if "考试" in user_input or "复习" in user_input:
        return [
            "圈出这次最需要补的章节。",
            "把重点概念整理成一页提纲。",
            "挑 2 到 3 组题目做一轮练习。",
            "把做错的地方单独记下来再看一遍。",
        ]

    return [
        "先写下这件事想达到的结果。",
        "列出需要准备的资料或材料。",
        "完成最容易开始的第一小步。",
        "留一点时间检查还有没有漏掉的内容。",
    ]
