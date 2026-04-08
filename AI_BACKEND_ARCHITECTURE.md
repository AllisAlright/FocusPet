//
//  AI_BACKEND_ARCHITECTURE.md
//  FocusPet
//
//  Created by xsy on 2026/3/24.
//

FocusPet AI 后端架构设计（Agent + LLM）
本文件定义 FocusPet 从本地 MVP 升级为完整 AI Agent 系统后的后端架构。
目标：
- 支持多端数据同步
- 支持长期用户记忆（Memory）
- 支持 AI Agent 编排
- 支持 LLM 接入（表达增强 + 轻量对话）
- 保持低打扰、可控、安全

---
1. 架构总览
iOS App (SwiftUI)
↓
API Gateway
↓
Agent Service（核心）
↓
├── Context Builder
├── Orchestrator
├── Agent Layer
├── Memory Service
├── Template / Prompt Builder
↓
LLM Service（可选）
↓
Database

---
2. 前后端职责划分
前端（App）
- UI 展示
- 用户操作
- 本地缓存
- 简单状态判断
- 降级逻辑（无网时）
后端（Server）
- 数据持久化
- Context 构建
- Agent 决策
- Memory 更新
- Prompt 生成
- LLM 调用

---
3. 核心服务拆分
3.1 API Gateway
负责：
- 鉴权
- 请求分发
- 限流

---
3.2 Agent Service（核心服务）
职责
- 接收用户事件
- 构建 Context
- 调用 Orchestrator
- 执行 Agent
- 返回消息
输入
{
  "userId": "123",
  "event": "focus_ended",
  "timestamp": 1710000000
}
输出
{
  "message": "又推进一小格！",
  "agent": "FocusEncouragementAgent"
}

---
3.3 Context Builder
从数据库读取：
- tasks
- focusSessions
- memory
构建 AIContext

---
3.4 Orchestrator
职责：
- 选择 Agent
- 控制优先级
- 控制频率

---
3.5 Agent Layer
包含：
- HomeSummaryAgent
- TaskPlanningAgent
- FocusEncouragementAgent
- TaskRecoveryAgent
输出：结构化意图（不是最终文案）

---
3.6 Memory Service
负责：
- 更新用户偏好
- 统计行为
示例：
- 平均专注时长
- 常用时间段

---
3.7 Prompt Builder
将：
- Context
- Memory
- AgentType
转换为 LLM Prompt

---
3.8 LLM Service
职责：
- 文案重写
- 个性化表达
- 轻量对话生成
原则：
- 不参与决策
- 只负责表达

---
4. 数据库设计（简化）
4.1 Users
- id
- createdAt
4.2 Tasks
- id
- userId
- title
- status
- progress
- estimatedMinutes
- spentMinutes
- dueDate
4.3 FocusSessions
- id
- userId
- taskId
- duration
- createdAt
4.4 Memory
- userId
- preferredPet
- averageFocusDuration
- favoriteScene

---
5. 请求流程示例
场景：结束专注
用户点击结束
↓
App 发送 event: focus_ended
↓
Agent Service
↓
Context Builder
↓
Orchestrator
↓
FocusEncouragementAgent
↓
Prompt Builder
↓
LLM（可选）
↓
返回 message
↓
App 展示

---
6. LLM 接入策略
使用场景
- 文案优化
- 个性化表达
- 轻量对话
不使用场景
- 任务状态判断
- 频率控制
- 页面逻辑

---
7. 降级策略
如果 LLM 不可用：
- 使用本地模板
- 保证功能可用

---
8. 技术选型建议
- 后端：Node.js / Python FastAPI
- 数据库：PostgreSQL
- 缓存：Redis
- LLM：OpenAI / Claude

---
9. 一句话总结
FocusPet 后端不是“聊天系统”，而是：
一个用规则控制行为、用 LLM 提升表达的 AI Agent 系统
