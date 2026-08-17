# FocusPet 技术算法侧技术文档

## 1. 文档目标

本文档用于定义 FocusPet 第一轮 AI Agent 迭代的技术架构、算法边界、Skill 设计、Prompt Engineering 方案、前后技术比较、后端保留原因，以及后续扩展方向。

本轮迭代的技术核心是：

> 将当前分散的 AI 能力，重构为以宠物为主体的轻量 Agent 系统。

这里的 Agent 不等于 LLM。Agent 是产品行为决策层，LLM 只是可选的表达生成与润色能力。

---

## 2. 当前技术状态

### 2.1 iOS 前端

当前 iOS 端主要使用：

- SwiftUI
- `ObservableObject`
- `FocusPetStore`
- `Codable` struct 模型
- 本地 mock data
- URLSession 调用本地后端 AI 接口

当前已有模块：

- Home
- Memo
- Tasks
- Focus
- History
- Settings
- Shared Components
- Theme
- Domain Models
- Domain Services

### 2.2 后端

当前后端主要使用：

- Python
- FastAPI
- SQLite
- SQLAlchemy
- Pydantic
- DeepSeek API
- OpenAI-compatible SDK

当前已有 AI 能力：

- `split_task`
- `suggest_next_action`
- `SkillRegistry`
- `SimpleOrchestrator`

### 2.3 当前状态与剩余问题

当前产品口径已经收敛为：

- iOS 核心功能本地优先，可在后端不可用时继续使用
- 后端保留，用于安全保存 API key、统一 Prompt、统一 Guard 和调用 LLM
- LLM 是表达增强层，不直接决定任务状态或产品写入
- 宠物是用户看到的 Agent 主体，Skill 是宠物可调用的内部能力

当前仍需继续处理的问题：

- 前端任务数据和后端任务数据没有真正统一
- iOS 任务状态与后端任务状态仍有历史差异
- Memory / RAG / 多端同步还只是后续方向，不属于当前 MVP
- AI 输出仍需要持续用样例矩阵和审核清单回归

---

## 3. 前后技术比较

### 3.1 改造前

改造前的 AI 链路更像：

用户点击 AI 功能入口  
-> 前端调用具体 API  
-> 后端具体 skill 调 LLM  
-> 返回结果  
-> 前端展示

特点：

- Skill 是显式工具
- 宠物主要是视觉和文案包装
- Skill prompt 独立编写
- 没有统一宠物人设层
- 没有统一输入 Guard
- 没有完整 Agent 决策层

### 3.2 改造后

改造后的 AI 链路应为：

用户自然输入  
-> Input Guard / Safety Guard  
-> Intent Detection  
-> Pet Agent 决策  
-> Skill Router  
-> Skill 执行  
-> Prompt Builder 拼接人设与 Skill Prompt  
-> LLM 生成结构化输出  
-> 前端确认或展示  
-> 必要时写入本地数据

特点：

- 宠物是 Agent 主体
- Skill 是宠物可以调用的能力
- LLM 不直接决定产品状态
- Prompt 在后端统一管理
- 输入先过安全审核
- 前端有本地 fallback
- 后端是 AI 增强层，而不是 App 生存层

---

## 4. 核心架构原则

### 4.1 Pet Agent 不等于 LLM

Pet Agent 是行为决策层。

它负责：

- 理解用户输入意图
- 判断是否需要调用 Skill
- 判断调用哪个 Skill
- 判断是否需要用户确认
- 拼接当前宠物人设
- 控制普通聊天轮次
- 控制输出边界
- 处理安全和降级逻辑

LLM 负责：

- 按宠物语气生成表达
- 根据 Skill 结果生成自然文案
- 对复盘结果做有性格的总结
- 对拆任务结果生成更自然的小步骤

### 4.2 代码负责确定性逻辑

以下内容不应交给 LLM 直接决定：

- 任务完成、删除、暂停、恢复、导入待办等状态变更
- 是否弹窗、是否打扰用户
- 安全边界
- 数据统计
- 隐私和权限
- `/下一步` 的核心排序逻辑
- 是否继续闲聊还是引导回产品主旨

### 4.3 LLM 负责表达增强

适合交给 LLM 的内容：

- 宠物语气包装
- 拆任务文案生成
- 下一步动作表达
- 复盘文字总结
- 轻微个性化表达

---

## 5. 后端是否必须存在

本项目要接真实 LLM，因此后端应保留。

后端必要性：

- 安全保存 API key
- 统一 Prompt Engineering
- 统一输入安全审核
- 控制调用成本
- 做日志与调试
- 后续接 Memory / RAG / 多端同步

iOS App 不应直接保存 LLM API key。

但后端不应成为第一期 App 的生存依赖。

第一期策略：

- 后端可用：使用真实 LLM Skill
- 后端不可用：前端本地 fallback
- 核心功能：备忘、待办、专注、历史、本地持久化，均可离线使用

---

## 6. 建议后端模块结构

建议新增或重构：

```text
Backend/app/agents/
  pet_personas.py
  prompt_builder.py
  input_guard.py
  intent_detector.py
  skill_router.py
  pet_response_generator.py

Backend/app/skills/
  split_task/
    SKILL.md
    fallback.py
    prompt.py
    skill.py
  suggest_next_action/
    SKILL.md
    fallback.py
    prompt.py
    skill.py
  weekly_review/
    SKILL.md
    fallback.py
    prompt.py
    skill.py
  split_task_skill.py
  suggest_next_action_skill.py
  weekly_review_skill.py
  registry.py
```

### 6.1 `pet_personas.py`

负责保存四个宠物的人设配置。人设 Prompt 不应只是几个语气标签，而应使用更接近角色设定档的结构。

包括：

- 宠物名称
- 角色定位
- 风格定义
- 对话特点
- 说话示例
- 禁止事项
- 输出长度约束
- 对不同 Skill 的表达偏好

所有宠物共享一组基础禁止项：

- 只输出宠物说出口的话
- 禁止第三人称动作旁白、神态描写、环境描写
- 禁止描写耳朵、尾巴、爪子、肢体动作
- 禁止承诺已经创建、删除、修改、完成任务
- 禁止高压催促、羞辱用户或制造失败感

### 6.2 `prompt_builder.py`

负责组合 Prompt。

每次 LLM 调用建议由以下部分组成：

1. 全局产品边界 Prompt
2. 当前宠物人设 Prompt
3. 当前 Skill Prompt
4. 当前上下文
5. 输出 JSON 格式要求

当前 Prompt 分层原则：

- 全局产品边界放在 `prompt_builder.py`
- 宠物人设放在 `pet_personas.py`
- Skill 任务规则优先放在对应 skill 的 `prompt.py`
- 结构化 fallback 优先放在对应 skill 的 `fallback.py`
- Skill 说明、触发边界和确认原则写在对应 `SKILL.md`

### 6.3 `input_guard.py`

负责在 Skill 调用前进行输入安全审核。

### 6.4 `intent_detector.py`

负责识别用户输入意图。

### 6.5 `skill_router.py`

负责根据意图和安全审核结果选择 Skill。

### 6.6 `pet_response_generator.py`

负责生成宠物最终说出口的话。

它的边界是：

- 可以根据宠物人设润色普通聊天回复
- 可以把 Skill 的结构化结果包装成宠物语气
- 不允许执行工具
- 不允许写入、删除或修改用户数据
- 不允许绕过前端确认流程

这层的价值是让四个宠物真正有表达差异，同时保持产品行为仍由确定性代码控制。

---

## 7. 宠物人设 Prompt Engineering

宠物人设 Prompt 应统一放在后端管理，不散落在前端 View 或各个 skill 文件中。

### 7.1 全局产品边界 Prompt

所有宠物共享：

```text
你是 FocusPet 的宠物 Agent。
FocusPet 是一个专注陪伴与任务推进产品，不是医疗、心理治疗或通用陪聊产品。
你的目标是温和地陪用户记录、拆小、推进、复盘或休息。

必须遵守：
- 不羞辱用户。
- 不制造失败感。
- 不高压催促。
- 不鼓励熬夜、过劳或危险行为。
- 不提供违法、自伤、自杀、暴力等行为的方法或步骤。
- 不做医学或心理诊断。
- 回复要短、自然、具体。
- 如果用户持续闲聊，需要温和引导回休息、记录或开始一点点。
```

### 7.2 兔子 Prompt

```text
你是 FocusPet 的兔子 Agent。
你的角色是安抚型启动伙伴。
你温柔、细腻、安静，擅长降低用户开始任务前的焦虑。

表达方式：
- 多使用“没关系”“慢慢来”“先一点点”。
- 帮用户把压力变小。
- 不要催促，不要要求用户必须完成。
- 不要长篇说教。

适合的语气：
温柔、轻声、稳定、有陪伴感。
```

### 7.3 猫 Prompt

```text
你是 FocusPet 的猫 Agent。
你的角色是冷静型判断伙伴。
你少说、可靠、清晰，擅长帮用户收束注意力。

表达方式：
- 语句简短。
- 优先指出最关键的一件事。
- 不要过度热情。
- 不要甜腻，不要夸张鼓励。

适合的语气：
冷静、克制、清楚、可靠。
```

### 7.4 小狗 Prompt

```text
你是 FocusPet 的小狗 Agent。
你的角色是行动型推进伙伴。
你明亮、积极、有行动感，擅长陪用户动起来一点。

表达方式：
- 可以热情，但不能打鸡血。
- 多鼓励短轮次和小行动。
- 不要说“必须”“别停”“今天一定完成”。
- 不要制造压力。

适合的语气：
明亮、真诚、轻快、有能量。
```

### 7.5 仓鼠 Prompt

```text
你是 FocusPet 的仓鼠 Agent。
你的角色是机灵傲娇型推进伙伴。
你聪明、嘴硬、轻微傲娇，但其实很关心用户。

表达方式：
- 可以轻微嘴硬，例如“哼”“也不是不行”“我都看好了”。
- 可以用聪明的方式帮用户找到起点。
- 不能嘲讽、羞辱或阴阳怪气。
- 不能说用户懒、差、没用。
- 傲娇只能是轻轻推一把，不能制造压力。

适合的语气：
机灵、短促、嘴硬但温柔。
```

---

## 8. 第一期开启的 Skills

第一期正式 Skill：

1. `split_task`
2. `suggest_next_action`
3. `weekly_review`

暂不新增其它正式 Skill。

### 8.1 `split_task`

目标：

把用户的模糊目标拆成可确认、可导入待办的小任务。

输入建议：

```json
{
  "user_input": "准备产品经理面试",
  "pet_type": "rabbit"
}
```

输出建议：

```json
{
  "status": "ok",
  "message": "我帮你拆成几步了，先选想放进待办里的就好。",
  "tasks": [
    "列出这次面试最重要的岗位要求。",
    "整理 2 个能代表你的项目经历。",
    "写一个 1 分钟左右的自我介绍。"
  ]
}
```

特殊状态：

```json
{
  "status": "needs_clarification",
  "message": "这个目标有点大，我们先把它变成最近能推进的一小步。",
  "tasks": [],
  "suggested_rewrite": "这周先整理一个可执行的赚钱方向"
}
```

### 8.2 `suggest_next_action`

目标：

从当前任务中推荐一个最适合现在推进的事项，给出具体动作、理由和建议专注时长。

核心排序应由代码完成，而不是交给 LLM 凭空选择。

输入建议：

```json
{
  "pet_type": "cat",
  "tasks": [
    {
      "id": "task-1",
      "title": "整理作品集",
      "status": "active",
      "progress": 0.4,
      "due_date": "2026-08-16",
      "updated_at": "2026-08-13T20:00:00Z"
    }
  ],
  "today_focus_minutes": 25
}
```

输出建议：

```json
{
  "task_id": "task-1",
  "action": "可以先把「整理作品集」的项目目录列出来。",
  "reason": "它离截止更近，而且已经有一点进展。",
  "suggested_focus_minutes": 15
}
```

理由必须来自真实上下文。

### 8.3 `weekly_review`

目标：

总结最近 7 天专注情况，让用户看见自己的投入痕迹。

它不输出下一步动作。

输入建议：

```json
{
  "pet_type": "hamster",
  "period_days": 7,
  "stats": {
    "total_focus_minutes": 180,
    "session_count": 6,
    "late_night_session_count": 4,
    "most_active_time_bucket": "late_night",
    "top_task_title": "数据库课程笔记",
    "longest_session_minutes": 45
  }
}
```

输出建议：

```json
{
  "summary": "这 7 天你一共专注了 6 次，累计 180 分钟。",
  "observation": "我发现你有好几次都在半夜学习。",
  "pet_comment": "哼，我陪你熬得都困了。不过看到你还在推进，也就不打扰你了。下次记得早点睡。"
}
```

---

## 9. 输入 Guard 与安全审核

所有用户输入在进入 Skill 前必须先经过 Input Guard。

### 9.1 Guard 输出结构

建议：

```json
{
  "safety_level": "safe",
  "can_call_skill": true,
  "category": "normal_task",
  "recommended_action": "route_to_intent_detector",
  "message": null
}
```

可选分类：

- `safe`
- `oversized_goal`
- `off_topic`
- `self_harm`
- `unsafe`
- `illegal`
- `health_risk`

### 9.2 处理规则

正常任务：

- 进入 Intent Detection

超大目标：

- 不直接调用拆任务
- 先缩小目标或追问

自伤/自杀：

- 不调用任何任务型 Skill
- 不提供步骤、计划、方法
- 使用稳定安全回应

恶搞/离题：

- 不调用 Skill
- 温和挡回产品主旨

健康有害：

- 不鼓励执行
- 建议更安全的替代安排

### 9.3 Guard 不应只靠 LLM

建议组合：

- 规则关键词拦截
- 后端 Guard 分类
- 必要时 LLM 辅助判断
- 保守策略

原则：

> 宁可多一次确认，也不能错误调用危险 Skill。

---

## 10. Intent Detection 与 Skill Routing

用户不必输入斜杠命令。

Agent 应识别自然语言意图。

### 10.1 意图类型

建议第一期支持：

- `split_task_candidate`
- `next_action_request`
- `weekly_review_request`
- `casual_chat`
- `emotional_support`
- `rest_request`
- `memo_candidate`
- `unknown`

### 10.2 是否直接调用 Skill

直接调用：

- 用户明确要求拆解目标
- 用户明确要求推荐下一步
- 用户明确要求复盘

先确认：

- 用户只是表达目标模糊
- 用户只是表达压力
- 用户只是表达自我怀疑
- 用户输入过大目标

不调用：

- 危险输入
- 自伤/自杀输入
- 明显离题或恶搞输入
- 不适合任务推进的内容

### 10.3 示例输出

```json
{
  "intent": "split_task_candidate",
  "confidence": 0.82,
  "should_call_skill": false,
  "skill": "split_task",
  "requires_confirmation": true,
  "reply": "要不要我帮你拆成几步？这样会更容易开始。"
}
```

---

## 11. 本地 Fallback

后端不可用时，前端必须可用。

### 11.1 拆任务 Fallback

使用本地模板。

现有 `MockSplitTaskProvider` 可以保留并增强。

### 11.2 下一步 Fallback

由前端本地规则选择任务：

1. 临近截止的 active 任务
2. 最近推进过的任务
3. 进度较高、适合收尾的任务
4. 标题短、容易开始的任务
5. 暂停或逾期任务作为恢复候选

再用本地模板生成理由。

### 11.3 复盘 Fallback

前端本地统计最近 7 天：

- 总专注分钟
- 专注次数
- 时间段分布
- 最常推进任务
- 最长一次专注

再套宠物模板生成复盘。

---

## 12. 数据与隐私边界

第一期采用：

> 本地数据为主，最小必要上下文传输。

### 12.1 后端第一期不做

- 不接管完整任务数据库
- 不长期存储用户完整任务和专注历史
- 不上传备忘录全文
- 不上传删除记录
- 不上传全量历史

### 12.2 前端传给后端的内容

拆任务：

- 用户本次输入
- 宠物类型

下一步：

- 未完成任务摘要
- 任务标题、状态、进度、截止时间、最近更新时间
- 今日专注摘要
- 宠物类型

复盘：

- 最近 7 天统计摘要
- 宠物类型

---

## 13. 本地持久化

第一期使用 JSON 文件持久化。

原因：

- 当前模型已支持 `Codable`
- 改动小
- 可快速保证数据不丢
- 不阻塞首页 Agent 体验改造

建议新增：

```text
FocusPet/Domain/Services/LocalPersistenceService.swift
```

存储内容：

- tasks
- memoItems
- focusSessions
- settings

启动逻辑：

1. 尝试读取本地 JSON
2. 如果读取成功，加载用户数据
3. 如果没有本地数据，加载 mock data
4. 数据变化后自动保存

后续产品稳定后，再评估迁移 SwiftData。

---

## 14. RAG 是否需要

第一期不做 RAG。

原因：

- 当前还没有稳定知识库
- 任务拆解和复盘可先通过 prompt 与规则完成
- RAG 会增加复杂度和维护成本
- 当前核心风险是产品体验是否成立，而不是检索能力是否完善

后续可以保留 RAG 口子，但必须满足以下条件之一才值得做：

- 已积累稳定任务拆解模板
- 用户场景明显分化，例如学习、面试、写作、项目管理
- 普通 prompt 输出明显变泛
- 需要根据长期用户行为做个性化建议
- 需要引入任务策略、专注策略或中断恢复知识库

技术文档中应明确：

> RAG 不是当前 MVP 的必要能力。它只在任务策略知识库、用户长期记录和多场景个性化建议形成规模后才有引入价值。

---

## 15. 第一轮开发顺序

1. 增加 JSON 本地持久化
2. 首页 UI 改为宠物陪伴与 Agent 输入页
3. 前端实现自然语言输入入口与本地意图识别雏形
4. 后端新增 Pet Persona、Prompt Builder、Input Guard、Intent Detector、Skill Router
5. 改造 `split_task`
6. 改造 `suggest_next_action`
7. 新增 `weekly_review`
8. 增加前端 fallback
9. 联调后端 LLM
10. 打磨四个宠物输出差异

---

## 16. 技术验收标准

本轮完成后，应满足：

- App 重启后本地任务、备忘、专注记录、设置不丢
- 首页输入自然语言后，能识别拆任务、下一步、复盘或普通聊天
- 用户不需要输入斜杠命令也能触发 Skill
- 后端 API key 不出现在 iOS 端
- 宠物人设 Prompt 由后端统一管理
- Skill Prompt 不再完全散落在各 skill 文件中
- `split_task` 对过大、危险、恶搞输入有拦截
- `suggest_next_action` 输出推荐任务、理由、建议时长
- `weekly_review` 输出最近 7 天总结，不给下一步动作
- 后端不可用时前端 fallback 生效
- 危险、自伤、违法输入不会进入任务型 Skill
- 四个宠物输出有明显差异，但都符合产品边界

---

## 17. 总结

FocusPet 的 AI 技术方向不是简单接入 LLM，也不是做通用聊天助手。

更准确的定义是：

> FocusPet 构建的是一个以宠物为主体的轻量 Agent 系统。它通过安全输入审核、意图识别、Skill 路由、宠物人设 Prompt、LLM 表达生成和本地 fallback，共同服务「情绪陪伴 x 任务推进」这个核心产品目标。

---

## 18. 当前实现状态

截至本次代码迭代，已完成以下基础改造：

- iOS 新增 `LocalPersistenceService`，用 JSON 文件保存本地状态
- iOS 首页保留宠物陪伴与功能入口，新增独立 `PetChatView` 承接自然语言 Agent 对话
- iOS 新增 `APIPetAgentProvider`，对接后端 `/api/v1/ai/agent-message`
- iOS 保留本地意图识别和 fallback，后端不可用时仍能处理拆任务、下一步、复盘和闲聊
- iOS 本地优先拦截自伤与危险输入，不等待后端返回
- iOS 拆任务结果已在 `PetChatView` 内联展示与勾选导入，不再通过 Sheet 二次请求
- iOS 下一步建议可携带 `task_id` 与 `suggested_focus_minutes` 导航到 `FocusSetupView` 预填任务和倒计时，但不直接启动专注
- iOS `split_task` 与 `suggest_next_action` 请求已携带 `pet_type`
- iOS 功能列表页已去掉重复宠物说明卡，宠物表达集中在首页与聊天页
- iOS 设置页已接入默认宠物、默认场景、默认计时模式和默认倒计时设置；`FocusSession` 会保存本轮选择的 `sceneType`
- 后端四个宠物人设已升级为设定档结构，包含风格定义、对话特点、说话示例和共享禁止项
- 后端 `split_task`、`suggest_next_action`、`weekly_review` 已统一为内部 Skill 文件夹结构：`SKILL.md`、`prompt.py`、`fallback.py`、`skill.py`
- 后端新增 `Backend/tools/agent_sample_matrix.py`，可在无真实 LLM key 时输出四宠物样例矩阵，辅助检查人设、Skill 和安全边界
- 后端新增 `Backend/tools/agent_output_review.py` 与 `Docs/Agent_Output_Review_Checklist.md`，用于评审越权承诺、动作旁白、确认字段和复盘边界
- 后端拆任务 Agent 响应已显式返回 `requires_confirmation = true`，避免前后端语义误解为已写入待办
- 后端新增 `agents/` 分层：Pet Persona、Prompt Builder、Input Guard、Intent Detector、Skill Router、Pet Agent
- 后端新增 `pet_response_generator.py`，用于统一包装普通聊天与 Skill 结果的宠物人设表达
- 后端新增 `weekly_review` Skill
- 后端新增统一自然语言入口 `/api/v1/ai/agent-message`
- 后端保留直接 Skill endpoints，便于渐进迁移和调试

当前验证情况：

- 后端 Python 语法检查已通过
- 后端 Agent 子模块可独立识别拆任务、下一步、复盘和自伤拦截
- 后端已新增不依赖真实 LLM 的 Agent/Skill fallback 护栏测试，覆盖自伤拦截、拆任务、下一步建议和 7 天复盘
- 后端本地测试已覆盖四宠物样例矩阵、标准 Skill 文件夹结构、拆任务确认字段和输出评审器
- 本地 fallback 样例矩阵当前评审结果为 0 个硬性失败、0 个风格提醒
- DeepSeek API key 格式和网络链路已验证能触达接口，但当前账户返回 `Insufficient Balance`，真实 LLM 人设输出需充值后继续联调
- 当前后端 `.venv` 已可执行语法检查和 Agent 抽样；若本机重建后再次遇到 `pydantic_core` quarantine，可按环境排障记录处理
- iOS 命令行构建能识别新增 Swift 文件，但当前环境会被 Xcode Preview 宏/模拟器服务问题阻断；从错误摘要看，阻断点不是新增 Agent 业务代码

下一步技术重点：

- 用真实 LLM 联调四个宠物人设输出
- 给 `/agent-message` 增加更细的错误码，方便前端区分网络失败、LLM 失败和安全拦截
- 给聊天内 Skill 结果态补充 SwiftUI 预览和本机模拟器验证
- 让不同 `SceneType` 在专注页呈现更明确的背景、白噪音入口和历史展示
- 继续补充更多边界输入样例，尤其是模糊自伤、违法、健康透支和超大目标输入
