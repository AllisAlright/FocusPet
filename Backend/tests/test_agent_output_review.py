import unittest

from tools.agent_output_review import OutputReviewIssue, render_review_markdown, review_samples
from tools.agent_sample_matrix import AgentSample, build_sample_matrix


class AgentOutputReviewTests(unittest.TestCase):
    def test_local_sample_matrix_has_no_failed_boundary_checks(self) -> None:
        issues = review_samples(build_sample_matrix())
        failed = [issue for issue in issues if issue.severity == "fail"]

        self.assertEqual(failed, [])

    def test_review_catches_unconfirmed_action_claims(self) -> None:
        sample = AgentSample(
            pet_type="rabbit",
            case_name="split_task",
            intent="split_task_candidate",
            skill="split_task",
            requires_confirmation=True,
            message="我已经创建待办了。",
            structured_summary="3 task candidates",
        )

        issues = review_samples([sample])

        self.assertTrue(any(issue.rule == "no_unconfirmed_action_claim" for issue in issues))

    def test_review_catches_action_narration(self) -> None:
        sample = AgentSample(
            pet_type="cat",
            case_name="casual_chat_long_turn",
            intent="casual_chat",
            skill=None,
            requires_confirmation=False,
            message="猫猫摇了摇尾巴，先休息。",
            structured_summary="none",
        )

        issues = review_samples([sample])

        self.assertTrue(any(issue.rule == "no_action_or_body_narration" for issue in issues))

    def test_review_catches_stiff_safety_redirect(self) -> None:
        sample = AgentSample(
            pet_type="rabbit",
            case_name="unsafe_guard",
            intent="unsafe_or_off_topic",
            skill=None,
            requires_confirmation=False,
            message="我们换个安全的小事吧。",
            structured_summary="none",
        )

        issues = review_samples([sample])

        self.assertTrue(any(issue.rule == "no_stiff_safety_redirect" for issue in issues))

    def test_review_markdown_summarizes_issue_counts(self) -> None:
        issue = OutputReviewIssue(
            severity="warn",
            pet_type="dog",
            case_name="persona_coverage",
            rule="dog_bright_marker",
            detail="missing bright marker",
        )

        output = render_review_markdown([], [issue])

        self.assertIn("style warnings: 1", output)
        self.assertIn("| warn | dog | persona_coverage | dog_bright_marker | missing bright marker |", output)


if __name__ == "__main__":
    unittest.main()
