import unittest
from pathlib import Path

from app.agents.pet_personas import PET_PERSONAS
from app.skills.suggest_next_action.prompt import SUGGEST_NEXT_ACTION_PROMPT
from app.skills.split_task.fallback import fallback_tasks
from app.skills.split_task.prompt import SPLIT_TASK_PROMPT, build_split_task_user_prompt
from app.skills.weekly_review.prompt import WEEKLY_REVIEW_PROMPT


class PersonaPromptTests(unittest.TestCase):
    def test_all_personas_have_profile_style_sections(self) -> None:
        self.assertEqual(set(PET_PERSONAS.keys()), {"rabbit", "cat", "dog", "hamster"})

        for persona in PET_PERSONAS.values():
            prompt = persona.to_prompt()
            self.assertIn("风格定义", prompt)
            self.assertIn("对话特点", prompt)
            self.assertIn("说话示例", prompt)
            self.assertIn("禁止事项", prompt)
            self.assertIn("只输出宠物说出口的话", prompt)
            self.assertIn("不输出第三人称动作旁白", prompt)
            self.assertGreaterEqual(len(persona.example_lines), 5)

    def test_split_task_skill_prompt_is_separated_from_fallback(self) -> None:
        self.assertIn("split_task Skill", SPLIT_TASK_PROMPT)
        self.assertIn("只返回严格 JSON", SPLIT_TASK_PROMPT)
        self.assertIn("用户目标：准备面试", build_split_task_user_prompt("准备面试"))

        tasks = fallback_tasks("准备面试")
        self.assertGreaterEqual(len(tasks), 3)
        self.assertTrue(all(task for task in tasks))

    def test_formal_skills_have_standard_folder_contract(self) -> None:
        skills_root = Path(__file__).resolve().parents[1] / "app" / "skills"

        for skill_name in ("split_task", "suggest_next_action", "weekly_review"):
            skill_dir = skills_root / skill_name
            self.assertTrue((skill_dir / "SKILL.md").exists(), skill_name)
            self.assertTrue((skill_dir / "prompt.py").exists(), skill_name)
            self.assertTrue((skill_dir / "fallback.py").exists(), skill_name)
            self.assertTrue((skill_dir / "skill.py").exists(), skill_name)

    def test_all_skill_prompts_keep_structured_output_rules(self) -> None:
        self.assertIn("只返回严格 JSON", SPLIT_TASK_PROMPT)
        self.assertIn("只返回严格 JSON", SUGGEST_NEXT_ACTION_PROMPT)
        self.assertIn("只返回严格 JSON", WEEKLY_REVIEW_PROMPT)


if __name__ == "__main__":
    unittest.main()
