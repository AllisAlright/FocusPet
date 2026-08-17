# FocusPet 内部 Skills

这个目录存放 FocusPet 后端 Pet Agent 使用的内部产品能力。

这里的 skill 不是 Codex skill。Codex skill 通常是带 `SKILL.md` 的工具包；FocusPet skill 是后端业务模块，由宠物 Agent 在完成安全判断和意图识别后按需调用。

## 这里的 Skill 是什么

在当前产品里，用户不应该直接看到一堆“工具按钮”。用户看到的是宠物。

宠物可以在合适的时候调用内部 skill，例如：

- 用户提出一个具体、可执行、合规的目标时，调用任务拆分。
- 用户不知道先做什么时，调用下一步建议。
- 用户想复盘最近专注情况时，调用周复盘。

skill 的职责是给出建议，不是替用户改数据。

## 标准结构

每个正式 skill 建议包含：

- `SKILL.md`：给人看的 skill 合约，说明触发条件、输入输出、执行流程和产品边界。
- `metadata`：一个 `SkillMetadata` 值，包含稳定的 `name` 和简短 `description`。
- 清晰的公开入口方法，通常是 `run(...)`。
- LLM 调用前的确定性输入校验，通常通过 `input_guard` 完成。
- 独立提示词文件。skill 变复杂后，提示词放到对应的 `prompt.py`。
- 严格的返回解析。使用 LLM 时，不能随便相信自由文本。
- 本地兜底逻辑。只要分支稍微复杂，就放到 `fallback.py`，确保没有 API Key 或余额不足时 App 仍可用。
- 不直接写用户数据。

推荐目录结构：

```text
skills/
  split_task/
    SKILL.md
    prompt.py
    fallback.py
    skill.py
  suggest_next_action/
    SKILL.md
    prompt.py
    fallback.py
    skill.py
  weekly_review/
    SKILL.md
    prompt.py
    fallback.py
    skill.py
```

旧的 `*_skill.py` 文件可以暂时保留为兼容包装。等旧接口完全迁移后，再单独清理。

## 当前 Skills

- `split_task`：把一个具体、安全、可执行的目标拆成 3 到 5 个小步骤。
- `suggest_next_action`：根据任务摘要推荐一个低压力下一步。
- `weekly_review`：根据聚合后的专注数据生成近期复盘。

## 产品边界

skill 可以返回结构化建议，但不能直接创建、编辑、删除、暂停、恢复或完成用户任务。

真实数据变化必须由 iOS App 在用户明确确认后执行。

这些输入不能进入任务拆分或下一步规划：

- 自伤、自杀、伤害自己
- 暴力伤害他人
- 违法或规避限制
- 成人内容
- 高风险医疗或健康操作
- 过大且不可直接执行的目标
- 操纵他人情感或关系结果的目标

这个边界很重要：FocusPet 是陪用户推进真实生活里的小事，不是帮用户规划危险、违法或不适合产品承担的事情。
