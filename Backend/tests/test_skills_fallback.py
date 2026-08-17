import unittest

from app.core.config import settings
from app.schemas.ai import SuggestNextActionTask, WeeklyReviewStats
from app.skills.registry import skill_registry
from app.skills.weekly_review.skill import WeeklyReviewSkill


class SkillFallbackTests(unittest.TestCase):
    def setUp(self) -> None:
        self.original_api_key = settings.deepseek_api_key
        settings.deepseek_api_key = ""

    def tearDown(self) -> None:
        settings.deepseek_api_key = self.original_api_key

    def test_registry_contains_current_mvp_skills(self) -> None:
        self.assertEqual(
            set(skill_registry.list_names()),
            {"split_task", "suggest_next_action", "weekly_review"},
        )

    def test_split_task_fallback_returns_small_actionable_list(self) -> None:
        tasks = skill_registry.get("split_task").run("帮我拆一下完成作品集", pet_type="rabbit")

        self.assertGreaterEqual(len(tasks), 3)
        self.assertLessEqual(len(tasks), 5)
        self.assertTrue(all(task.strip() for task in tasks))

    def test_split_task_refuses_oversized_goal_even_without_api_key(self) -> None:
        with self.assertRaises(ValueError):
            skill_registry.get("split_task").run("帮我拆任务怎么才能赚到一百万", pet_type="rabbit")

    def test_split_task_refuses_adult_or_circumvention_input_even_without_api_key(self) -> None:
        for user_input in ("帮我拆任务怎么才能翻墙看片", "帮我拆任务怎么才能看黄片"):
            with self.assertRaises(ValueError):
                skill_registry.get("split_task").run(user_input, pet_type="rabbit")

    def test_split_task_refuses_relationship_outcome_even_without_api_key(self) -> None:
        for user_input in ("帮我拆任务 如何三步喜欢上一个人", "帮我拆任务 怎么追到一个人"):
            with self.assertRaises(ValueError):
                skill_registry.get("split_task").run(user_input, pet_type="rabbit")

    def test_suggest_next_action_fallback_is_structured(self) -> None:
        recommendation = skill_registry.get("suggest_next_action").recommend(
            SuggestNextActionTask(
                id="task-2",
                title="复习数据库",
                type="paused",
                progress=0.2,
            ),
            pet_type="hamster",
            reason="它暂停过一阵子，可以先恢复一点点。",
            suggested_focus_minutes=10,
        )

        self.assertEqual(recommendation.task_id, "task-2")
        self.assertIn("「复习数据库」", recommendation.action)
        self.assertEqual(recommendation.suggested_focus_minutes, 10)

    def test_weekly_review_fallback_returns_all_sections(self) -> None:
        review = skill_registry.get("weekly_review").run(
            WeeklyReviewStats(
                total_focus_minutes=90,
                session_count=3,
                top_task_title="准备面试",
                longest_session_minutes=40,
            ),
            pet_type="cat",
            period_days=7,
        )

        self.assertIn("90", review.summary)
        self.assertIn("准备面试", review.observation)
        self.assertTrue(review.pet_comment)

    def test_weekly_review_parser_removes_action_calls(self) -> None:
        review = WeeklyReviewSkill()._parse_response(
            '{"summary":"这周专注了 3 次。","observation":"没有下一步压力。","pet_comment":"明天再战也不迟。"}'
        )

        combined_text = " ".join([review.summary, review.observation, review.pet_comment])
        self.assertNotIn("下一步", combined_text)
        self.assertNotIn("再战", combined_text)
        self.assertIn("休息也很重要", combined_text)


if __name__ == "__main__":
    unittest.main()
