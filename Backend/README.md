# FocusPet 后端说明

这个后端是 FocusPet 的本地 AI 与数据服务。它包含 FastAPI、SQLite、本地任务接口、DeepSeek 兼容的 LLM 调用、Pet Agent、安全拦截、意图识别、skill 路由和测试。

iOS App 仍然是本地优先。后端是 AI 增强层，不是备忘录、待办、专注、历史这些基础功能的必需条件。

## 后端现在做什么

### 已实现

- FastAPI 应用和版本化 API 路由
- 健康检查接口
- 本地 SQLite 数据库
- 任务增删改查
- 任务软删除和恢复
- 专注记录创建和查询
- 根据专注时长更新任务进度
- 通过 OpenAI SDK 调用 DeepSeek 兼容接口
- Pet Agent 对话接口
- skill 路由前的输入安全拦截
- 意图识别
- skill 注册表
- 简单编排层
- `split_task`：任务拆分
- `suggest_next_action`：下一步建议
- `weekly_review`：周复盘
- LLM 失败或 API Key 缺失时的本地兜底
- 安全拦截、宠物人格提示词、skill 兜底、样例输出测试

### 暂未实现

- 登录鉴权
- 生产环境部署
- Redis
- 云同步
- RAG
- 长期用户记忆服务
- 计费或限流系统

这些不是当前 MVP 的重点。当前重点是验证 Pet Agent 能否在安全边界内帮助用户重新进入任务。

## 为什么保留后端

后端存在有四个主要原因：

1. DeepSeek API Key 不能放在 iOS App 里。
2. 提示词、安全规则和模型调用需要集中管理。
3. Pet Agent 在调用 LLM 前需要先做确定性安全判断和路由。
4. 未来如果做记忆、统计、多端同步，会自然需要服务端能力。

即使后端不可用，iOS App 仍然可以继续使用本地备忘录、待办、专注和历史功能。

## 当前 AI 链路

```text
iOS 宠物聊天输入
-> POST /api/v1/ai/pet-agent
-> input_guard 安全拦截
-> intent_detector 意图识别
-> skill_router 判断是否调用 skill
-> 可选执行 skill
-> pet_response_generator 生成宠物口吻回复
-> 返回结构化响应给 iOS
```

LLM 可以负责：

- 宠物语气
- 简短解释
- 任务步骤措辞
- 复盘总结措辞

代码必须负责：

- 安全分类
- skill 路由
- 任务状态变化
- 数据库写入
- 兜底行为

## 本地启动

进入后端目录：

```bash
cd Backend
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
cp .env.example .env
```

把 DeepSeek Key 填到 `Backend/.env`：

```env
DEEPSEEK_API_KEY=你的真实 deepseek key
```

启动服务：

```bash
uvicorn app.main:app --reload
```

接口文档地址：

```text
http://127.0.0.1:8000/docs
```

运行测试：

```bash
python -m pytest tests
```

## 环境文件

- `Backend/.env.example`：环境变量模板，可以提交。
- `Backend/.env`：本地真实密钥文件，不能提交。
- `Backend/data/`：本地 SQLite 数据，不能提交。
- `Backend/.venv/`：本地 Python 虚拟环境，不能提交。

## 常用接口

- `GET /health`：健康检查。
- `GET /api/v1/tasks`：获取任务列表。
- `POST /api/v1/tasks`：创建任务。
- `GET /api/v1/tasks/{id}`：获取任务详情。
- `PATCH /api/v1/tasks/{id}`：更新任务。
- `DELETE /api/v1/tasks/{id}`：软删除任务。
- `GET /api/v1/tasks/deleted`：获取已删除任务。
- `POST /api/v1/tasks/{id}/restore`：恢复任务。
- `GET /api/v1/focus-sessions`：获取专注记录。
- `POST /api/v1/focus-sessions`：创建专注记录。
- `POST /api/v1/ai/split-task`：旧的拆任务接口，保留兼容。
- `POST /api/v1/ai/pet-agent`：当前宠物 Agent 主接口。

准确的请求和响应结构请看 `/docs`。

## 文件说明

```text
Backend/
  app/
    main.py
    api/
    agents/
    core/
    db/
    models/
    orchestrator/
    schemas/
    services/
    skills/
  tests/
  tools/
  .env.example
  requirements.txt
  README.md
```

### `app/main.py`

FastAPI 入口。负责创建应用、初始化数据库、挂载主路由。

### `app/api/`

HTTP 路由层。

- `router.py`：主 API 路由。
- `routes/health.py`：健康检查。
- `routes/tasks.py`：任务接口。
- `routes/focus_sessions.py`：专注记录接口。
- `routes/ai.py`：AI 接口，包括旧拆任务接口和当前 Pet Agent 接口。

### `app/agents/`

Pet Agent 层。

- `pet_agent.py`：Agent 主入口。
- `input_guard.py`：skill 执行前的安全与范围判断。
- `intent_detector.py`：把自然语言映射为产品意图。
- `skill_router.py`：判断是否需要执行某个 skill。
- `pet_personas.py`：兔兔、猫猫、狗狗、仓仓的语气设定。
- `prompt_builder.py`：通用提示词构造。
- `pet_response_generator.py`：宠物口吻回复生成和兜底。

### `app/skills/`

内部产品 skill。它们不是 Codex skill，而是后端 Pet Agent 可以调用的业务模块。

- `base.py`：skill 元信息和通用接口。
- `registry.py`：稳定 skill 注册表。
- `README.md`：skill 约定说明。
- `split_task/`：任务拆分 skill，包含提示词、兜底和合约。
- `suggest_next_action/`：下一步建议 skill，包含提示词、兜底和合约。
- `weekly_review/`：周复盘 skill，包含提示词、兜底和合约。
- `*_skill.py`：兼容旧调用的包装文件，等旧接口完全迁移后可再清理。

skill 可以返回建议，但不能直接写入用户数据。

### `app/db/`、`app/models/`、`app/schemas/`、`app/services/`

标准后端数据层：

- `db/`：SQLite 连接和初始化。
- `models/`：SQLAlchemy 数据表。
- `schemas/`：Pydantic 请求和响应结构。
- `services/`：任务、专注记录、AI 调用等服务。

### `app/orchestrator/`

轻量编排层。当前编排刻意保持简单，因为这个产品更需要可预测行为，而不是复杂自治。

### `tests/`

后端测试，包括：

- Agent 安全拦截
- skill 兜底行为
- 宠物人格提示词约束
- 样例输出检查

### `tools/`

本地检查工具，用来生成和审查 AI 输出样例。

## 安全策略

这些输入不能进入任务 skill：

- 自伤或自杀意图
- 暴力伤害他人
- 违法行为或规避限制
- 成人内容
- 高风险健康或医疗操作
- “赚一百万”“当总统”这类过大目标
- “让某人喜欢我”这类关系结果操纵

遇到这些输入时，后端应该返回宠物口吻的拒绝或转向。措辞可以由 LLM 生成，但“是否拦截”的决定必须由代码控制。

## 设计原则

后端在这些地方要保持稳定、朴素、可测试：

- 安全判断
- 路由判断
- 结构化解析
- 数据写入
- 兜底逻辑

LLM 适合用在这些地方：

- 宠物语气
- 简短解释
- 小步骤措辞
- 复盘总结
