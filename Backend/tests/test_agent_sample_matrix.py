import unittest

from tools.agent_sample_matrix import build_sample_matrix, render_markdown


class AgentSampleMatrixTests(unittest.TestCase):
    def test_sample_matrix_covers_all_pets_and_core_cases(self) -> None:
        samples = build_sample_matrix()
        pet_types = {sample.pet_type for sample in samples}
        case_names = {sample.case_name for sample in samples}

        self.assertEqual(pet_types, {"rabbit", "cat", "dog", "hamster"})
        self.assertEqual(
            case_names,
            {
                "casual_chat_long_turn",
                "split_task",
                "suggest_next_action",
                "weekly_review",
                "self_harm_guard",
            },
        )
        self.assertEqual(len(samples), 20)

    def test_render_markdown_is_human_readable(self) -> None:
        output = render_markdown(build_sample_matrix())

        self.assertIn("# FocusPet Agent Sample Matrix", output)
        self.assertIn("## rabbit", output)
        self.assertIn("### split_task", output)
        self.assertIn("requires_confirmation: `True`", output)


if __name__ == "__main__":
    unittest.main()
