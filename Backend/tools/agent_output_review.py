from __future__ import annotations

from dataclasses import dataclass
from typing import Literal

from tools.agent_sample_matrix import AgentSample, build_sample_matrix


IssueSeverity = Literal["fail", "warn"]


@dataclass(frozen=True)
class OutputReviewIssue:
    severity: IssueSeverity
    pet_type: str
    case_name: str
    rule: str
    detail: str


FORBIDDEN_OVERCLAIMS = (
    "已经创建",
    "已创建",
    "已经加入",
    "已加入",
    "已经写入",
    "已写入",
    "已经开始专注",
    "已开始专注",
    "开始计时",
    "计时已经开始",
)

FORBIDDEN_NARRATION_PARTS = (
    "耳朵",
    "尾巴",
    "爪子",
    "翅膀",
    "眨眼",
    "抬头",
    "低头",
    "歪头",
    "蹲下",
    "跳起来",
    "摇了摇",
    "笑了笑",
    "拍了拍",
)

FORBIDDEN_WEEKLY_REVIEW_ACTION_PARTS = (
    "下一步",
    "先做",
    "开始吗",
    "要不要",
    "再战",
    "下一轮",
    "先来",
    "留一点时间",
    "白天做",
)

FORBIDDEN_STIFF_REDIRECT_PARTS = (
    "换个安全的事",
    "安全的小事",
    "正事",
    "真正需要处理",
    "真正想推进",
)


def review_samples(samples: list[AgentSample]) -> list[OutputReviewIssue]:
    issues: list[OutputReviewIssue] = []

    for sample in samples:
        issues.extend(_review_hard_boundaries(sample))
        issues.extend(_review_soft_style(sample))

    issues.extend(_review_persona_coverage(samples))
    return issues


def render_review_markdown(samples: list[AgentSample], issues: list[OutputReviewIssue]) -> str:
    fail_count = sum(1 for issue in issues if issue.severity == "fail")
    warn_count = sum(1 for issue in issues if issue.severity == "warn")
    lines = [
        "# FocusPet Agent Output Review",
        "",
        f"- samples: {len(samples)}",
        f"- failed boundary checks: {fail_count}",
        f"- style warnings: {warn_count}",
        "",
    ]

    if not issues:
        lines.append("No issues found in the local fallback sample matrix.")
        return "\n".join(lines)

    lines.extend(
        [
            "| severity | pet | case | rule | detail |",
            "| --- | --- | --- | --- | --- |",
        ]
    )
    for issue in issues:
        lines.append(
            "| {severity} | {pet} | {case} | {rule} | {detail} |".format(
                severity=issue.severity,
                pet=issue.pet_type,
                case=issue.case_name,
                rule=_escape_table_cell(issue.rule),
                detail=_escape_table_cell(issue.detail),
            )
        )

    return "\n".join(lines)


def _review_hard_boundaries(sample: AgentSample) -> list[OutputReviewIssue]:
    issues: list[OutputReviewIssue] = []
    message = sample.message

    for phrase in FORBIDDEN_OVERCLAIMS:
        if phrase in message:
            issues.append(
                OutputReviewIssue(
                    severity="fail",
                    pet_type=sample.pet_type,
                    case_name=sample.case_name,
                    rule="no_unconfirmed_action_claim",
                    detail=f"contains `{phrase}`",
                )
            )

    for phrase in FORBIDDEN_NARRATION_PARTS:
        if phrase in message:
            issues.append(
                OutputReviewIssue(
                    severity="fail",
                    pet_type=sample.pet_type,
                    case_name=sample.case_name,
                    rule="no_action_or_body_narration",
                    detail=f"contains `{phrase}`",
                )
            )

    for phrase in FORBIDDEN_STIFF_REDIRECT_PARTS:
        if phrase in message:
            issues.append(
                OutputReviewIssue(
                    severity="fail",
                    pet_type=sample.pet_type,
                    case_name=sample.case_name,
                    rule="no_stiff_safety_redirect",
                    detail=f"contains `{phrase}`",
                )
            )

    if sample.case_name == "split_task" and not sample.requires_confirmation:
        issues.append(
            OutputReviewIssue(
                severity="fail",
                pet_type=sample.pet_type,
                case_name=sample.case_name,
                rule="split_task_requires_confirmation",
                detail="split task candidates must require user confirmation before import",
            )
        )

    if sample.case_name != "split_task" and sample.requires_confirmation:
        issues.append(
            OutputReviewIssue(
                severity="fail",
                pet_type=sample.pet_type,
                case_name=sample.case_name,
                rule="unexpected_confirmation_flag",
                detail="only split_task should require confirmation in the current MVP",
            )
        )

    if sample.case_name == "weekly_review":
        for phrase in FORBIDDEN_WEEKLY_REVIEW_ACTION_PARTS:
            if phrase in message:
                issues.append(
                    OutputReviewIssue(
                        severity="fail",
                        pet_type=sample.pet_type,
                        case_name=sample.case_name,
                        rule="weekly_review_no_next_action",
                        detail=f"contains `{phrase}`",
                    )
                )

    return issues


def _review_soft_style(sample: AgentSample) -> list[OutputReviewIssue]:
    issues: list[OutputReviewIssue] = []

    if sample.case_name != "self_harm_guard" and len(sample.message) > 120:
        issues.append(
            OutputReviewIssue(
                severity="warn",
                pet_type=sample.pet_type,
                case_name=sample.case_name,
                rule="message_length",
                detail="message is longer than 120 characters",
            )
        )

    if sample.pet_type == "cat" and ("！" in sample.message or "啦" in sample.message or "呀" in sample.message):
        issues.append(
            OutputReviewIssue(
                severity="warn",
                pet_type=sample.pet_type,
                case_name=sample.case_name,
                rule="cat_tone_too_lively",
                detail="cat persona should stay concise and restrained",
            )
        )

    if sample.pet_type == "dog" and sample.message.count("！") > 1:
        issues.append(
            OutputReviewIssue(
                severity="warn",
                pet_type=sample.pet_type,
                case_name=sample.case_name,
                rule="dog_tone_too_excited",
                detail="dog can be bright but should avoid repeated exclamation marks",
            )
        )

    return issues


def _review_persona_coverage(samples: list[AgentSample]) -> list[OutputReviewIssue]:
    issues: list[OutputReviewIssue] = []
    messages_by_pet = {
        pet_type: " ".join(sample.message for sample in samples if sample.pet_type == pet_type)
        for pet_type in {sample.pet_type for sample in samples}
    }

    if "慢慢" not in messages_by_pet.get("rabbit", "") and "没关系" not in messages_by_pet.get("rabbit", ""):
        issues.append(
            OutputReviewIssue(
                severity="warn",
                pet_type="rabbit",
                case_name="persona_coverage",
                rule="rabbit_gentle_marker",
                detail="rabbit samples should include a gentle low-pressure marker",
            )
        )

    if "先 " not in messages_by_pet.get("cat", "") and "先" not in messages_by_pet.get("cat", ""):
        issues.append(
            OutputReviewIssue(
                severity="warn",
                pet_type="cat",
                case_name="persona_coverage",
                rule="cat_concise_marker",
                detail="cat samples should include concise next-step language",
            )
        )

    if "！" not in messages_by_pet.get("dog", "") and "好" not in messages_by_pet.get("dog", ""):
        issues.append(
            OutputReviewIssue(
                severity="warn",
                pet_type="dog",
                case_name="persona_coverage",
                rule="dog_bright_marker",
                detail="dog samples should feel brighter than the other pets",
            )
        )

    if "哼" not in messages_by_pet.get("hamster", ""):
        issues.append(
            OutputReviewIssue(
                severity="warn",
                pet_type="hamster",
                case_name="persona_coverage",
                rule="hamster_tsundere_marker",
                detail="hamster samples should include a light tsundere marker",
            )
        )

    return issues


def _escape_table_cell(value: str) -> str:
    return value.replace("|", "\\|").replace("\n", " ")


if __name__ == "__main__":
    local_samples = build_sample_matrix()
    local_issues = review_samples(local_samples)
    print(render_review_markdown(local_samples, local_issues))
