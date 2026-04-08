FocusPet AI Agent v2 设计文档
本文件定义 FocusPet 的 AI 陪伴专注与任务推进系统。
它不仅描述产品逻辑，也定义当前 MVP 可落地的 Rule-based Agent 体系，并为未来接入 LLM 做结构预留。
当前版本目标：
- 本地运行
- 规则驱动
- 低打扰
- 可解释
- 可迭代
未来版本目标：
- 接入 LLM 提升表达自然度与长期陪伴感
- 保留规则系统作为安全底层与触发控制层
- 支持更强的个性化与轻量对话能力

---
1. 文档目标
本文件用于统一以下内容：
1. FocusPet 中 AI Agent 系统的职责边界
2. 当前 MVP 阶段的可实现方案
3. Agent 的触发、决策、输出与频率控制逻辑
4. User Memory、Context Engine、Orchestrator 等模块的关系
5. 未来接入后端、数据库、LLM、轻量对话能力的升级路径
本文件面向：
- 产品设计
- 工程实现
- Codex / AI coding 协作
- 面试与项目讲解

---
2. 系统定位
FocusPet 不是聊天型 AI 产品，也不是通用问答助手。
FocusPet 的 AI 更像一个：
在合适的时候，用合适的语气，轻轻把用户带回任务的陪伴式 Agent 系统。
它的核心不是“聊很多”，而是：
- 理解用户当前状态
- 在正确时机做低打扰干预
- 帮助用户从“拖着不动”变成“先推进一点”
2.1 产品关键词
- 温和
- 陪伴
- 专注
- 推进
- 少打扰
- 可持续
2.2 非目标
本系统不追求：
- 高频提醒
- 聊天陪聊
- 强施压监督
- 长文本分析
- 情绪说教
- “替用户做决定”的自动化强代理

---
3. 系统目标
构建一个长期陪伴用户推进任务的 AI 系统。
AI 的职责不是催促用户，也不是代替用户行动，而是：
- 帮助用户记录想法
- 帮助用户推进任务
- 帮助用户进入专注
- 帮助用户维持节奏
- 帮助用户减少拖延
- 在用户容易中断、放下或犹豫的时候，给出最小打扰的支持
3.1 最终体验目标
用户打开 App 时，应该感受到：
- 我知道接下来做什么
- 先做一点也很好
- 有人在陪我一起推进
- 没做完也没关系，还可以继续
而不是：
- 我还有很多没完成
- 我又被催了
- 这个 App 一直打断我
- 我必须立刻完成所有事情

---
4. 系统总览
AI 系统由以下模块组成：
- Agent Orchestrator
- Context Engine
- User Memory 
- Behavior Loop
- Message Policy
- Specific Agents
- Template Layer
4.1 系统流转结构
User Action / System Event
↓
Context Engine
↓
Agent Orchestrator
↓
Specific Agent
↓
Template Layer / LLM Rewriter（未来）
↓
Message / Suggestion / Silent
4.2 核心设计原则
1. 先判断是否应该说话，再决定说什么
2. 先决定触发哪个 Agent，再决定用哪句文案
3. 优先保持安静，而不是频繁输出
4. 规则系统负责安全与节奏控制
5. LLM 未来只增强表达，不替代底层触发逻辑

---
5. 模块职责边界
5.1 Agent Orchestrator
Orchestrator 是决策层。基于User Memory + Context Engine，我现在该干嘛？
它的职责是：
- 理解当前页面与当前事件
- 判断是否需要触发 AI
- 多个 Agent 冲突时决定优先级
- 控制频率与去重
- 输出本次应该展示的唯一消息，或者保持沉默
5.2 Context Engine
Context Engine 负责把任务、专注、时间、用户行为、偏好等多源数据整理成统一上下文。
它不负责决策，只负责提供当前状态快照。
5.3 User Memory
User Memory 负责记录用户长期偏好与行为模式。
它不直接生成提示，但会影响：
- 语气选择
- 场景推荐
- 提示时机
- 个性化表达
5.4 Specific Agents
Specific Agents 负责完成某一类明确任务，例如：
- 首页摘要
- 任务规划
- 专注鼓励
- 任务恢复
5.5 Template Layer
Template Layer 负责将 Agent 决策结果转成一句可展示文案。
当前版本：
- 使用本地模板
未来版本：
- 可使用 LLM 对模板进行重写
5.6 Message Policy
Message Policy 负责：
- 控制频率
- 限制长度
- 避免重复
- 控制不同页面的消息密度

---
6. 当前版本与未来版本
6.1 当前版本（MVP）
当前版本为：
Rule-based AI Agent（本地运行）
实现方式：
- 规则逻辑
- 模板文案
- 本地 Memory
- 本地 Context Engine
- 可解释的 Agent 触发系统
6.2 当前版本的优势
- 可控
- 稳定
- 易调试
- 成本低
- 非联网也能运行
- 适合先验证产品体验
6.3 未来版本
未来可升级为：
LLM 驱动的 AI Companion System
LLM 的职责建议只用于：
- 文案自然度增强
- 长周期总结
- 个性化表达重写
- 更细腻的轻量对话
不建议让 LLM 直接接管：
- 触发逻辑
- 页面频率控制
- 删除 / 恢复 / 完成等产品状态机

---
7. Agent Orchestrator
Orchestrator 是 AI 系统的大脑。
7.1 职责
- 判断当前用户状态
- 读取当前上下文
- 选择最适合触发的 Agent
- 控制提示频率
- 防止 AI 过度打扰
- 在冲突场景下只保留一条消息
7.2 输入信息
- 当前页面
- 最近系统事件
- 最近专注记录
- 当前任务状态
- 当前时间
- User Memory
- 最近一次 AI 提示时间
- 最近一次 AI 提示内容类型
7.3 输出
- no_message
- trigger(agentType)
- messagePayload
7.4 示例逻辑
if focusSessionEnded:
  → FocusEncouragementAgent
else if overdueTasksCount > 0 and no progress for 3 days:
  → TaskRecoveryAgent
else if page == home:
  → HomeSummaryAgent
else:
  → no_message
7.5 原则
- AI 不应该频繁说话
- 同一时刻最多输出一条消息
- 有更高优先级消息时，低优先级消息静默
- 没必要说的时候就不说

---
8. Context Engine
Context Engine 负责整理 AI 可用的数据。
8.1 输入来源
- 任务系统
- 专注系统
- 用户行为系统
- 时间系统
- 本地偏好设置
- Memory 系统
8.2 输出目标
将分散数据整合为统一的 AIContext
8.3 AIContext 建议字段
{
  "page": "home",
  "activeTasksCount": 3,
  "pausedTasksCount": 1,
  "overdueTasksCount": 1,
  "nearDeadlineTaskTitle": "论文整理",
  "focusTodayMinutes": 45,
  "lastFocusSessionMinutes": 25,
  "recentCompletedTaskTitle": "产品文档",
  "preferredPet": "rabbit",
  "favoriteScene": "rainy_window",
  "currentHourBucket": "evening",
  "isFocusRunning": false,
  "currentTaskTitle": "整理产品原型",
  "allowFocusTaskCount": 2
}
8.4 建议字段说明
- page：当前页面
- activeTasksCount：进行中任务数量
- pausedTasksCount：暂停任务数量
- overdueTasksCount：逾期任务数量
- nearDeadlineTaskTitle：最临近截止任务
- focusTodayMinutes：今日累计专注时长
- lastFocusSessionMinutes：最近一轮专注时长
- recentCompletedTaskTitle：最近完成任务
- preferredPet：偏好宠物
- favoriteScene：偏好场景
- currentHourBucket：时间分段（morning / afternoon / evening / lateNight）
- isFocusRunning：是否正在专注中
- currentTaskTitle：当前绑定任务
- allowFocusTaskCount：可专注任务数量

---
9. User Memory
User Memory 用于记录用户长期偏好和行为模式，让 AI 更自然。
9.1 Memory 结构示例
{
  "preferredPet": "rabbit",
  "preferredFocusTime": "evening",
  "averageFocusDuration": 32,
  "completionRate": 0.64,
  "favoriteScene": "rainy_window",
  "mostUsedFocusMode": "countdown",
  "averageTasksCompletedPerWeek": 4,
  "focusStreakDays": 3
}
9.2 建议字段
- preferredPet
- preferredFocusTime
- averageFocusDuration
- completionRate
- favoriteScene
- mostUsedFocusMode
- averageTasksCompletedPerWeek
- focusStreakDays
- lastRecoveredTaskAt
9.3 Memory 的作用
- 个性化提示
- 默认宠物推荐
- 默认场景推荐
- 更自然的陪伴表达
- 长期节奏识别
9.4 示例输出
你通常晚上更容易专注，要不要先推进一点？

---
10. Behavior Loop
AI 行为遵循统一循环：
Observe
↓
Decide
↓
Act
↓
Observe again
10.1 Observe
收集当前状态：
- 当前页面
- 当前任务状态
- 当前时间
- 今日专注情况
- 最近完成 / 暂停 / 逾期情况
- 最近一次 AI 提示
10.2 Decide
判断：
- 是否应该触发
- 触发哪个 Agent
- 优先级是否足够
- 是否因频率控制而取消输出
10.3 Act
输出一句提示、建议、摘要，或保持安静。
10.4 示例
Observe:
任务 3 天未推进

Decide:
触发 TaskRecoveryAgent

Act:
“要不要先推进10分钟？”

---
11. 事件系统（Event Layer）
为了让 Agent 可工程化，系统建议采用事件驱动。
11.1 核心事件
- app_opened
- home_opened
- task_page_opened
- memo_page_opened
- history_page_opened
- focus_page_opened
- focus_started
- focus_ended
- focus_cancelled
- task_created
- task_completed
- task_reactivated
- task_overdue_detected
- memo_created
- memo_deleted
- memo_converted_to_task
11.2 事件流
Event
↓
Context Engine rebuild context
↓
Orchestrator decision
↓
Agent output or silent
11.3 事件的意义
通过事件系统，Agent 不需要自己“轮询”页面，而是：
- 在明确事件发生时重新判断
- 降低性能开销
- 降低逻辑耦合
- 便于调试和日志记录

---
12. Message Policy
Message Policy 负责 AI 提示节奏与去重。
12.1 频率规则
- 专注中：不主动打断
- 首页：最多一条
- 任务页：最多一条
- 编辑页：默认不主动插入额外消息
- 连续提示间隔：至少 30 分钟
- 同类提醒一天内不超过 2 次
12.2 优先级规则
若多个 Agent 同时满足条件，优先级建议为：
1. FocusEncouragementAgent
2. TaskRecoveryAgent
3. TaskPlanningAgent
4. HomeSummaryAgent
12.3 去重规则
- 30 分钟内不重复输出相近语义
- 同一任务 24 小时内只触发一次恢复提醒
- 同一页面打开后，不连续多次输出相同摘要
12.4 文案限制
- 单条提示尽量不超过 20 字
- 首页提示尽量 1 句
- 不连续出现多段文案

---
13. Agent 列表
当前系统包含以下 Agent：
- HomeSummaryAgent
- TaskPlanningAgent
- FocusEncouragementAgent
- TaskRecoveryAgent
未来可扩展：
- SceneRecommendationAgent
- WeeklyReflectionAgent
- RoutineBuildingAgent
- LightConversationAgent

---
14. Agent 详细定义
14.1 HomeSummaryAgent
目标
生成首页的一句摘要或陪伴提示。
输入
- activeTasksCount
- focusTodayMinutes
- nearDeadlineTaskTitle
- preferredPet
输出
一句首页提示。
示例
- 猫：先推进最临近的那个任务吧。
- 狗：今天已经专注40分钟啦！
- 兔子：我们可以慢慢把它做完。
- 仓鼠：今天再滚一小格也很好！
触发时机
- 首页打开时
- 满足频率限制时
- 没有更高优先级消息时

---
14.2 TaskPlanningAgent
目标
帮助用户理解一项任务还需要投入多少时间。
输入
- estimatedMinutes
- spentMinutes
- dueDate
计算
- remainingMinutes = max(estimatedMinutes - spentMinutes, 0)
- remainingDays
- recommendedDailyMinutes
输出
每日建议投入时间。
示例
剩余 180 分钟
剩余 3 天
建议每天 60 分钟
使用位置
- 编辑事项页
- 事项详情页
- 未来首页轻规划提示

---
14.3 FocusEncouragementAgent
目标
在专注开始、结束、完成时提供一句轻量鼓励。
触发时机
- 开始专注
- 结束专注
- 完成任务
- 连续专注多轮时
输出限制
- 每次只说一句
- 尽量不超过 20 字
- 不说教
- 不施压
示例
- 猫：我们安静地继续。
- 狗：太棒了，继续冲！
- 兔子：一点点也很好。
- 仓鼠：又推进一小格！

---
14.4 TaskRecoveryAgent
目标
帮助用户把已经放下的事项重新捡起来。
触发条件
- 任务超过 3 天未推进
- 任务已暂停
- 任务已逾期且未重新激活
输出示例
- 要不要先推进10分钟？
- 先补一点点进度也很好。
- 这件事还可以慢慢捡起来。
使用位置
- 首页
- 历史页未完成记录
- 任务详情页

---
15. 角色系统
15.1 当前角色
- 猫
- 狗
- 兔子
- 仓鼠
15.2 性格定义
- 猫：安静、冷静、克制
- 狗：阳光、鼓励、外向
- 兔子：温柔、治愈、慢节奏
- 仓鼠：活泼、可爱、轻快
15.3 对话原则
- 不打扰
- 不说教
- 不批评
- 不制造羞耻感
- 优先鼓励
- 少说话
15.4 输出差异
同样的事件，不同角色可以用不同语气表达，但不改变底层逻辑。

---
16. 文案系统（Template Layer）
为了方便后续接入 LLM，应将“触发逻辑”和“文案模板”分开。
16.1 模板结构示例
{
  "agent": "FocusEncouragementAgent",
  "pet": "rabbit",
  "tone": "gentle",
  "templates": [
    "一点点也很好。",
    "慢慢来，我们在这里。",
    "先推进一小格就很好。"
  ]
}
16.2 输出规则
- 先由 Agent 决定“该说什么类型”
- 再由模板层决定“具体说哪一句”
- 未来可替换为 LLM 重写，但保留长度和语气约束
16.3 当前建议
第一版先不做复杂生成，只做：
- 多模板随机
- 同义句去重
- 角色差异化模板

---
17. 轻量对话能力（未来可扩展）
FocusPet 不做强聊天系统，但可以做轻量对话。
17.1 定义
轻量对话不是连续聊天，而是：
- AI 主动一句
- 用户轻回应一下
- 不展开长对话
17.2 示例
首页：
- 兔子：我们可以慢慢把它做完。
- 用户点一下小对话框
- 展开一句补充说明
专注结束：
- 仓鼠：又推进一小格！
- 用户选择：再来一轮 / 先休息
17.3 边界
- 不做开放输入聊天框
- 不做长链问答
- 不抢走专注注意力
17.4 后续实现方向
可通过：
- 本地模板 + 状态
- 未来接入 LLM 重写表达
来实现更自然的轻对话。

---
18. 数据与工程建议
18.1 当前版本不需要后端
MVP 阶段建议：
- 本地存储
- 本地 Memory
- 本地 Agent 决策
- 本地模板文案
18.2 何时需要后端
只有当你需要以下能力时再考虑：
- 跨设备同步
- 多端数据一致
- 云端长期记忆
- 更复杂的推荐模型
- LLM API 调用
18.3 当前最合适的技术路径
阶段 1：
- Rule-based Agent
- 本地 Memory
- 模板文案
阶段 2：
- 轻交互
- 更丰富的 Agent 模板
阶段 3：
- LLM 文案增强
- 后端与数据库

---
19. 未来 LLM 接入方案
未来版本可以接入：
- GPT
- Claude
- 本地模型
19.1 LLM 的角色
LLM 不直接接管所有逻辑。
推荐只用于：
- 更自然的陪伴文案
- 长周期周总结 / 日总结
- 更个性化的任务恢复建议
- 轻量对话中的表达增强
19.2 LLM 输入
- AIContext
- UserMemory
- TaskData
- AgentType
- Tone constraints
- Length constraints
19.3 Prompt 结构示例
Role: focus companion
Tone: calm, gentle, encouraging
Goal: encourage task progress without pressure
Limit: under 20 Chinese characters
Context:
- preferred pet: rabbit
- focus today: 45 minutes
- current task: 产品文档
19.4 接入原则
- LLM 负责“表达增强”
- Rule-based System 负责“安全触发与节奏控制”

---
20. MVP 可交付实现
第一版不接入真实 AI。
实现方式
- 规则逻辑
- 模板文案
- 简单计算
- 本地上下文
- 本地记忆
可实现功能
- 首页摘要
- 任务恢复提醒
- 专注开始 / 结束鼓励
- 任务规划建议
- 基于角色的语气差异

---
21. 系统成功标准
如果 AI 系统设计正确，用户应该感受到：
- 我被理解了
- 我没有被催
- 我知道接下来做什么
- 我还能继续做下去
- 这个小动物像是在陪我，而不是管我
如果设计错误，用户会感受到：
- 它总在打扰我
- 它总在说重复的话
- 它像在催我
- 它只是一个会说话的按钮

---
22. 后续扩展方向
22.1 SceneRecommendationAgent
根据时间段、用户偏好、当前情绪状态推荐专注场景。
22.2 WeeklyReflectionAgent
每周生成一句回顾，例如：
- 你这周推进了 4 件事
- 晚上依然是你最容易进入状态的时候
22.3 CompanionMoodState
让角色不只说话，还能通过轻微动作状态反馈：
- 安静陪伴
- 鼓励点头
- 完成时开心
- 放下时温柔等待
22.4 LightConversationAgent
未来扩展轻量对话：
- 不做聊天界面
- 只做小范围、短回应、状态型互动

---
23. 一句话总结
FocusPet 的 AI 不是“聊天机器人”。
它更像：
一个会感知状态、会选择时机、会轻轻说一句话的小动物陪伴系统。
它存在的目的，不是说很多，而是：
在用户最容易停下来的地方，陪他再往前走一点。

