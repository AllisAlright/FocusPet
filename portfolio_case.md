# FocusPet：AI陪伴专注与任务推进系统

## 一、项目简介

FocusPet 是一款面向“轻度拖延 / 任务分散 / 难以启动”的用户群体设计的 AI 产品，核心目标是：

> 帮助用户从「不知道从哪开始」→「可以立即行动」

不同于传统待办工具或番茄钟，FocusPet 将：

- 任务管理（Task）
- 专注行为（Focus）
- AI 行动建议（AI）
- 情绪陪伴（Companion）

整合为一个 **AI驱动的任务推进系统**。

产品核心定位为：

> 一个“低打扰、可解释、可持续”的 AI Agent，而不是聊天机器人 :contentReference[oaicite:0]{index=0}

---

## 二、核心问题定义

在用户调研与产品分析中，发现核心问题集中在三点：

### 1. 启动困难（Start Problem）
- 任务目标过大，不知道如何拆解
- 缺乏明确的第一步

### 2. 决策成本高（Decision Cost）
- 待办很多，但不知道先做哪一个
- 每次都要重新思考“现在该做什么”

### 3. 持续推进难（Continuation Problem）
- 任务中断后难以恢复
- 缺乏轻量但有效的外部推动

---

## 三、解决方案：AI Agent + Skills 架构

### 3.1 整体 AI 架构设计

构建三层 AI 系统：

- **User Memory（用户记忆）**
- **Context Engine（上下文引擎）**
- **Orchestrator（编排层）**

由 Orchestrator 决策调用具体 Skill：

> Skills 决定“AI 能做什么”，RAG 决定“AI 知道什么” :contentReference[oaicite:1]{index=1}

---

### 3.2 Skill 体系设计（核心亮点）

#### 1️⃣ split_task（任务拆解）

将模糊目标转化为结构化步骤：

- 输入：用户自然语言目标
- 输出：3–5 个可执行子任务
- 结合 Prompt Engineering 约束结构

👉 解决：
> “我不知道怎么开始”

👉 产品价值：
> 降低启动门槛

:contentReference[oaicite:2]{index=2}

---

#### 2️⃣ suggest_next_action（下一步建议）

基于任务状态生成**唯一、最容易开始的一步**：

- 不提供多个选项（降低决策成本）
- 强约束：一句话、可执行、低摩擦
- 引入任务优先级 + 状态分布策略

👉 解决：
> “我现在该做什么”

👉 产品价值：
> 从“停滞”→“行动”

:contentReference[oaicite:3]{index=3}

---

### 3.3 Agent 系统设计（非聊天式 AI）

设计 Rule-based Agent 系统：

- HomeSummaryAgent
- TaskRecoveryAgent
- FocusEncouragementAgent
- TaskPlanningAgent

核心原则：

> AI 先判断“该不该说话”，再决定“说什么” :contentReference[oaicite:4]{index=4}

关键能力：

- 频率控制（避免打扰）
- 优先级决策
- 去重机制
- 单条输出策略

---

## 四、AI 关键能力设计

### 4.1 行动建议策略（核心设计）

设计任务优先级 + 概率分发模型：

- in_progress > todo > overdue > paused
- 引入随机扰动，避免重复推荐
- 增加“去重机制 + 多轮兜底”

👉 解决问题：
- 避免 AI 每次都推荐同一个任务
- 保证“既稳定又有变化”

---

### 4.2 情绪陪伴系统（差异化设计）

构建四类 AI 人格：

- 🐱 猫：冷静克制
- 🐶 狗：积极鼓励
- 🐰 兔：温柔治愈
- 🐹 仓鼠：轻快活泼

统一约束：

- 不说教
- 不施压
- 不制造羞耻感
- 一次只说一句

👉 实现：
- 情绪态（打开 App）
- 建议态（生成行动）
- 动画过渡（弱干扰）

---

### 4.3 轻量 AI 交互设计（非 Chat）

核心设计决策：

> 不做聊天框，而是做“嵌入式 AI”

具体实现：

- 首页气泡建议
- bottom sheet（任务拆解）
- 单句建议输出
- 可勾选结构化结果

👉 优势：

- 不打断用户流程
- 更符合任务工具场景
- 控制 AI 复杂度

:contentReference[oaicite:5]{index=5}

---

## 五、技术实现（端到端落地）

### 5.1 前端（iOS）

- SwiftUI
- 状态驱动 UI
- 动画系统（陪伴感设计）
- 本地数据管理（Task / Focus / Memo）

---

### 5.2 后端（AI + API）

- Python + FastAPI
- SQLite + SQLAlchemy
- REST API 设计：
  - `/ai/split-task`
  - `/ai/suggest-next-action`

---

### 5.3 AI 架构实现

后端采用：

- Agent Service（核心）
- Context Builder
- Orchestrator
- Memory Service
- Prompt Builder
- LLM Service（DeepSeek）

👉 明确分层：

- 决策：规则系统
- 表达：LLM

:contentReference[oaicite:6]{index=6}

---

### 5.4 AI Engineering（关键亮点）

本项目采用：

- Prompt Engineering（结构约束）
- Skill 化设计（模块化 AI）
- Codex CLI + vibe coding

实现：

- 前后端快速迭代
- AI 能力闭环开发
- 人机协同开发流程

---

## 六、数据驱动与验证

### 灰度测试

- 邀请 10+ 用户体验
- 收集反馈维度：
  - 建议相关性
  - 可执行性
  - 重复率
  - 打扰感

### 核心优化方向

- Prompt 优化（减少泛化输出）
- 建议策略调整（降低重复）
- UI 动效优化（降低干扰感）

---

## 七、AI 系统演进路线

### Phase 1（当前）
- Rule-based Agent
- 2 个核心 Skill
- 本地 + 简单后端

---

### Phase 2（规划）
- 引入 RAG（任务拆解知识库）
- 引入动物人格知识库
- 增强 Prompt

---

### Phase 3（进阶）

#### 1️⃣ RAG 能力
- 任务拆解模板库
- 专注策略库
- 用户行为数据

👉 提升：
- 输出稳定性
- 可执行性

---

#### 2️⃣ MCP（Model Context Protocol）

在 AI 决策中引入：

- 实时任务状态
- 用户行为上下文
- 专注历史

👉 实现：
> 更强上下文感知能力

---

#### 3️⃣ Skill 扩展

新增：

- plan_focus_session
- weekly_reflection
- routine_building

👉 构建完整 AI Agent 系统

---

## 八、项目总结（面试表达版）

> FocusPet 不是一个“聊天 AI”，而是一个“行动型 AI”。

我在这个项目中的核心工作是：

- 从 0 设计 AI Agent 架构（Memory / Context / Orchestrator）
- 将 AI 能力拆解为可复用 Skill（split_task / suggest_next_action）
- 设计 AI 行为策略（优先级 / 概率 / 去重 / 频控）
- 完成前后端闭环落地（SwiftUI + FastAPI + LLM）
- 基于用户反馈持续优化 AI 输出质量

最终实现：

> 一个在“用户最容易停下来的地方”，轻轻推一把的 AI 系统。
