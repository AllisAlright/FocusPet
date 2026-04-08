# FocusPet 
AI驱动的任务管理与专注陪伴应用

## 项目简介
FocusPet 是一个 AI Agent 驱动的任务推进系统，帮助用户从“拖延”走向“行动”。

核心能力：
- 任务拆解（split_task）
- 下一步建议（suggest_next_action）
- 轻量陪伴式 AI

---

## 核心功能

### 1. AI任务拆解
输入一个模糊目标 → 输出3-5个可执行步骤

### 2. 下一步行动建议
基于任务状态，生成一个“此刻最适合做的动作”

### 3. 陪伴式AI气泡
非聊天式AI，低打扰、可解释

---

## AI架构设计

- Agent + Skill 架构
- Context Engine
- User Memory（预留）
- Orchestrator 决策层

详细设计见：
docs/portfolio_case.md

---

## 技术栈

- 前端：SwiftUI
- 后端：FastAPI（Python）
- 数据库：SQLite
- AI：DeepSeek API
- AI工程：Prompt Engineering + Skill架构


---

## 本地运行

### 后端

```bash
cd backend
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
uvicorn app.main:app --reload
访问http://127.0.0.1:8000/docs

### 前端

Xcode打开ios/FocusPet.xcodeproj
