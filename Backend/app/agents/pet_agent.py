from app.agents.input_guard import input_guard
from app.agents.intent_detector import IntentResult, intent_detector
from app.agents.pet_personas import normalize_pet_type
from app.agents.pet_response_generator import pet_response_generator
from app.agents.skill_router import skill_router
from app.schemas.ai import (
    AgentMessageRequest,
    AgentMessageResponse,
    AgentTaskSummary,
    NextActionRecommendation,
    SuggestNextActionTask,
    WeeklyReviewResponse,
    WeeklyReviewStats,
)
from app.skills.registry import skill_registry


class PetAgent:
    def handle_message(self, payload: AgentMessageRequest) -> AgentMessageResponse:
        pet_type = normalize_pet_type(payload.pet_type)
        guard_result = input_guard.check(payload.user_input)

        if not guard_result.can_call_skill:
            fallback_message = guard_result.message or self._safe_fallback_message(pet_type)
            return AgentMessageResponse(
                intent=guard_result.category,
                safety_level=guard_result.safety_level,
                should_call_skill=False,
                skill=None,
                requires_confirmation=False,
                message=pet_response_generator.safety_response(
                    user_input=payload.user_input,
                    safety_level=guard_result.safety_level,
                    recommended_action=guard_result.recommended_action,
                    pet_type=pet_type,
                    fallback=fallback_message,
                ),
            )

        intent = intent_detector.detect(payload.user_input)
        selected_skill = skill_router.choose_skill(intent)

        if intent.requires_confirmation or selected_skill is None:
            return AgentMessageResponse(
                intent=intent.intent,
                safety_level=guard_result.safety_level,
                should_call_skill=False,
                skill=intent.skill,
                requires_confirmation=intent.requires_confirmation,
                message=self._reply_for_non_skill(
                    intent,
                    pet_type,
                    payload.conversation_turn_count,
                    payload.user_input,
                ),
            )

        if selected_skill == "split_task":
            tasks = skill_registry.get("split_task").run(payload.user_input, pet_type=pet_type)
            fallback_message = self._split_done_message(pet_type)
            return AgentMessageResponse(
                intent=intent.intent,
                safety_level=guard_result.safety_level,
                should_call_skill=True,
                skill=selected_skill,
                requires_confirmation=True,
                message=pet_response_generator.split_task_message(
                    payload.user_input,
                    tasks,
                    pet_type,
                    fallback_message,
                ),
                tasks=tasks,
            )

        if selected_skill == "suggest_next_action":
            recommendation = self._build_next_action_recommendation(payload, pet_type)
            fallback_message = self._format_next_action_message(recommendation, pet_type)
            return AgentMessageResponse(
                intent=intent.intent,
                safety_level=guard_result.safety_level,
                should_call_skill=True,
                skill=selected_skill,
                message=pet_response_generator.next_action_message(
                    recommendation,
                    pet_type,
                    fallback_message,
                ),
                recommendation=recommendation,
            )

        if selected_skill == "weekly_review":
            review = self._build_weekly_review(payload, pet_type)
            fallback_message = " ".join([review.summary, review.observation, review.pet_comment]).strip()
            return AgentMessageResponse(
                intent=intent.intent,
                safety_level=guard_result.safety_level,
                should_call_skill=True,
                skill=selected_skill,
                message=pet_response_generator.weekly_review_message(
                    review,
                    pet_type,
                    fallback_message,
                ),
                review=review,
            )

        return AgentMessageResponse(
            intent=intent.intent,
            safety_level=guard_result.safety_level,
            should_call_skill=False,
            message=self._safe_fallback_message(pet_type),
        )

    def _build_next_action_recommendation(
        self,
        payload: AgentMessageRequest,
        pet_type: str,
    ) -> NextActionRecommendation:
        task, reason = self._choose_task(payload.tasks)
        skill = skill_registry.get("suggest_next_action")
        return skill.recommend(
            task,
            pet_type=pet_type,
            reason=reason,
            suggested_focus_minutes=self._suggested_focus_minutes(task),
        )

    def _build_weekly_review(
        self,
        payload: AgentMessageRequest,
        pet_type: str,
    ) -> WeeklyReviewResponse:
        stats = payload.review_stats or WeeklyReviewStats(
            total_focus_minutes=0,
            session_count=0,
            late_night_session_count=0,
            most_active_time_bucket=None,
            top_task_title=None,
            longest_session_minutes=0,
        )
        skill = skill_registry.get("weekly_review")
        return skill.run(stats, pet_type=pet_type, period_days=7)

    def _choose_task(self, tasks: list[AgentTaskSummary]) -> tuple[SuggestNextActionTask, str]:
        unfinished = [task for task in tasks if task.status != "completed"]
        if not unfinished:
            return SuggestNextActionTask(title="写下一件你最想推进的事", type="none"), "当前没有可推进的待办。"

        active = [task for task in unfinished if task.status in ("active", "in_progress", "todo")]
        in_progress = [task for task in active if task.progress > 0 or task.status == "in_progress"]
        if in_progress:
            selected = sorted(in_progress, key=lambda task: (-task.progress, task.updated_at or ""))[0]
            return self._to_suggest_task(selected, "in_progress"), "它已经有一点进展，继续成本更低。"

        due_tasks = [task for task in active if task.due_date]
        if due_tasks:
            selected = sorted(due_tasks, key=lambda task: task.due_date or "")[0]
            return self._to_suggest_task(selected, "todo"), "它离截止更近，适合先看一眼。"

        if active:
            selected = sorted(active, key=lambda task: (len(task.title), task.updated_at or ""))[0]
            return self._to_suggest_task(selected, "todo"), "它看起来更容易从一个小开头开始。"

        overdue = [task for task in unfinished if task.status == "overdue"]
        if overdue:
            selected = sorted(overdue, key=lambda task: task.due_date or "")[0]
            return self._to_suggest_task(selected, "overdue"), "它已经逾期，适合先轻轻捡回来。"

        paused = [task for task in unfinished if task.status == "paused"]
        if paused:
            selected = sorted(paused, key=lambda task: task.updated_at or "")[0]
            return self._to_suggest_task(selected, "paused"), "它暂停过一阵子，可以先恢复一点点。"

        selected = unfinished[0]
        return self._to_suggest_task(selected, "todo"), "当前可以先从一个小动作开始。"

    def _to_suggest_task(self, task: AgentTaskSummary, task_type: str) -> SuggestNextActionTask:
        return SuggestNextActionTask(
            id=task.id,
            title=task.title,
            type=task_type,
            progress=task.progress,
            due_date=task.due_date,
            updated_at=task.updated_at,
        )

    def _suggested_focus_minutes(self, task: SuggestNextActionTask) -> int:
        if task.type in ("overdue", "paused"):
            return 10
        if task.progress >= 0.75:
            return 15
        return 15

    def _format_next_action_message(self, recommendation: NextActionRecommendation, pet_type: str) -> str:
        suffix = f"要不要来 {recommendation.suggested_focus_minutes} 分钟？"
        if pet_type == "cat":
            suffix = f"先 {recommendation.suggested_focus_minutes} 分钟就够。"
        elif pet_type == "dog":
            suffix = f"我们先来 {recommendation.suggested_focus_minutes} 分钟吧！"
        elif pet_type == "hamster":
            suffix = f"先 {recommendation.suggested_focus_minutes} 分钟，勉强很合适。"
        return f"{recommendation.action} {recommendation.reason} {suffix}"

    def _reply_for_non_skill(
        self,
        intent: IntentResult,
        pet_type: str,
        conversation_turn_count: int,
        user_input: str,
    ) -> str:
        if conversation_turn_count >= 8:
            fallback = self._closing_chat_message(pet_type)
        else:
            fallback = self._local_non_skill_reply(intent, pet_type)
        return pet_response_generator.chat(
            user_input=user_input,
            pet_type=pet_type,
            conversation_turn_count=conversation_turn_count,
            fallback=fallback,
        )

    def _split_done_message(self, pet_type: str) -> str:
        if pet_type == "cat":
            return "拆好了，先挑真正要放进待办的几步。"
        if pet_type == "dog":
            return "拆好啦！先选几步放进待办，我们一点点动起来。"
        if pet_type == "hamster":
            return "哼，拆好了。先选要放进待办的，别一口气塞太多。"
        return "我帮你拆成几步了，先选想放进待办里的就好。"

    def _local_non_skill_reply(self, intent: IntentResult, pet_type: str) -> str:
        if intent.intent == "emotional_support":
            if pet_type == "cat":
                return "先停一下也可以。等心稳了，再看一件小事。"
            if pet_type == "dog":
                return "累了就先缓一缓，我在这里等你。"
            if pet_type == "hamster":
                return "哼，那就先休息一下，电量太低也跑不动。"
            return "那就先歇一小会儿，我陪你安静待着。"

        if intent.intent == "rest_request":
            if pet_type == "cat":
                return "可以休息。回来时先看最小的一件。"
            if pet_type == "dog":
                return "好呀，先休息一下，回来我们再做一小轮。"
            if pet_type == "hamster":
                return "行吧，先充电。回来再滚一小格。"
            return "可以先休息一下，等你愿意了我们再继续。"

        if intent.intent == "memo_candidate":
            if pet_type == "cat":
                return "先记下来。之后再决定它要不要变成任务。"
            if pet_type == "dog":
                return "先记下来很好！这样就不会跑丢了。"
            if pet_type == "hamster":
                return "先记下吧，我帮你看着这一小条。"
            return "可以先记下来，之后再慢慢整理成任务。"

        if intent.reply and pet_type == "rabbit":
            return intent.reply

        return self._safe_fallback_message(pet_type)

    def _closing_chat_message(self, pet_type: str) -> str:
        if pet_type == "cat":
            return "聊到这里也够了。接下来可以休息，或者先整理一件最小的事。"
        if pet_type == "dog":
            return "我还想陪你，但也可以先休息一下，或者来一个 5 分钟小开始。"
        if pet_type == "hamster":
            return "哼，已经聊不少了。要么休息，要么先写下一件小事，我都行。"
        return "我还在这里。等你愿意的时候，我们可以休息一下，或者只记下一件小事。"

    def _safe_fallback_message(self, pet_type: str) -> str:
        if pet_type == "cat":
            return "先把眼前这一点放清楚。"
        if pet_type == "dog":
            return "我陪你，我们先看一小步。"
        if pet_type == "hamster":
            return "哼，我听着呢，先找个小起点吧。"
        return "没关系，我们慢慢来。"


pet_agent = PetAgent()
