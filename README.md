# FocusPet / 专注伴侣

FocusPet 是一款 SwiftUI iOS 应用，核心是“宠物陪伴 + 任务推进 + 专注记录”。它不是传统待办清单，也不是一个裸露的 AI 工具页，而是让用户在宠物陪伴下，把分散的想法、待办和专注时间慢慢接起来。

产品希望解决的问题很朴素：很多事情不是一次做完的，而是今天推进一点、明天继续一点。FocusPet 用进度、投入时长和温和提醒，帮助用户重新开始，而不是逼用户立刻完成所有事情。

## 当前项目状态

当前项目是一个“本地优先 MVP + 可选本地 AI 后端”。

也就是说：iOS App 本身可以独立使用，任务、备忘录、专注记录、历史记录和聊天记录都优先保存在本地。后端主要负责 Pet Agent、DeepSeek 调用、安全拦截和内部 skill 调度。

### 已完成

- 宠物作为首页主角的 Home 页面
- 首页四个入口：备忘录、历史事项、待办事项、专注
- 点击首页宠物后切换气泡文案
- 底部导航：Home、Tasks、Focus、History、Settings
- 备忘录模块：搜索、置顶、软删除、恢复、转为待办
- 待办模块：进度、预估耗时、已投入时长、截止日期、状态
- 专注模块：专注设置、计时、结束反馈、绑定任务或自由专注
- 历史模块：已完成、未完成记录、专注记录
- 设置模块：默认宠物、默认场景、默认计时模式
- 本地数据持久化
- 宠物聊天记录本地持久化
- 后端 Pet Agent
- DeepSeek 兼容的 LLM 调用
- 输入安全拦截、意图识别、skill 路由
- 任务拆分、下一步建议、周复盘三个内部 skill
- LLM 不可用时的本地兜底回复

### 还没做

- 账号系统
- 云同步
- 多端同步
- 生产环境部署
- 推送通知
- 真实白噪音音频资源
- RAG 检索增强
- 长期记忆服务
- 订阅或 App 内购买
- 日历、提醒事项等系统集成

MVP 先验证“宠物陪伴是否能帮助用户重新进入任务”。

## 产品口径

FocusPet 的首页已经从“功能入口页”调整为“宠物陪伴与 Agent 输入页”。

关键点：

- 宠物是首页主角，不是装饰物。
- 首页入口服务于快速进入常用场景，增强宠物的存在感。
- 用户和宠物聊天时，宠物可以理解意图、温和回应、必要时调用内部能力。
- 对用户危险、违法、成人、医疗风险、过大目标、操纵关系结果等请求，先安全判断，再决定是否拒绝、转向或陪伴。

## 当前 Agent 形态

当前链路是：

```text
用户在 iOS 宠物聊天里输入
-> 后端 Pet Agent 接收
-> 输入安全拦截
-> 意图识别
-> 判断是否需要调用 skill
-> 可选执行 skill
-> 生成宠物口吻回复
-> iOS 展示
-> 涉及任务写入时由用户明确确认
```

目前后端有三个内部 skill：

- `split_task`：把适合拆解的具体任务拆成 3 到 5 个小步骤。
- `suggest_next_action`：根据当前上下文建议一个低压力下一步。
- `weekly_review`：基于最近专注数据做简短复盘。

重要边界：

- LLM 可以润色宠物语气，但不能决定产品状态。
- LLM 不能直接创建、删除、暂停、完成或恢复任务。
- 安全拦截、skill 路由、数据写入必须由代码控制。
- 任务写入必须经过 iOS 端明确用户操作。

## 为什么这样设计

这个产品不是要把 AI 变成万能助手，而是要把 AI 放进一个温和、可控、能陪用户推进事情的产品形态里。

所以现在采用这几个原则：

- App 本地可用，后端只是增强层。
- DeepSeek API Key 只放后端，不进入 iOS App。
- 安全问题先由确定性逻辑判断，不能完全交给 LLM 即兴发挥。
- 宠物负责表达、陪伴和轻引导。
- 任务系统负责真实数据和状态变化。
- skill 只返回建议，不直接替用户改数据。

## 仓库目录说明

```text
.
├── FocusPet.xcodeproj
├── FocusPet/
├── Backend/
├── Docs/
├── Agents.md
├── README.md
├── portfolio_case.md
└── .gitignore
```

### 根目录文件

- `README.md`：当前文件，说明项目整体状态、目录结构、运行方式和产品口径。
- `Agents.md`：当前产品和 Pet Agent 的统一口径。
- `portfolio_case.md`：作品集/案例展示稿，适合对外介绍项目亮点；具体实现口径仍以 `README.md` 和 `Agents.md` 为准。
- `.gitignore`：忽略本地密钥、虚拟环境、本地数据库、Python 缓存和 Xcode 构建产物。

### iOS App

- `FocusPet/ContentView.swift`：App 外壳和底部主导航。
- `FocusPet/FocusPetApp.swift`：App 入口和共享的 `FocusPetStore`。
- `FocusPet/Domain/Enums/`：宠物、场景、任务状态、计时模式等枚举。
- `FocusPet/Domain/Models/`：本地数据模型和 `FocusPetStore`。
- `FocusPet/Domain/Services/`：本地持久化、任务逻辑、专注逻辑。
- `FocusPet/Features/Home/`：首页、宠物场景、宠物聊天、宠物选择、首页物件入口。
- `FocusPet/Features/Home/AI/`：iOS 侧 AI 请求模型和 API Provider。
- `FocusPet/Features/Memo/`：备忘录列表、编辑、恢复、转待办。
- `FocusPet/Features/Tasks/`：待办列表、任务编辑、最近删除任务。
- `FocusPet/Features/Focus/`：专注设置、计时页面、完成页面。
- `FocusPet/Features/History/`：完成历史、未完成记录、专注记录。
- `FocusPet/Features/Settings/`：设置页。
- `FocusPet/Shared/`：通用 UI 组件、主题、工具方法。
- `FocusPet/Assets.xcassets/`：App 图片资源。

### 后端

- `Backend/README.md`：后端启动、接口、文件结构和安全策略说明。
- `Backend/requirements.txt`：Python 依赖。
- `Backend/.env.example`：环境变量模板。
- `Backend/app/main.py`：FastAPI 入口。
- `Backend/app/api/`：接口路由。
- `Backend/app/agents/`：Pet Agent、安全拦截、意图识别、人格设定和回复生成。
- `Backend/app/skills/`：内部 skill 模块和 skill 合约。
- `Backend/app/orchestrator/`：轻量编排层。
- `Backend/app/services/`：任务、专注记录、AI 调用等服务。
- `Backend/app/models/`：数据库模型。
- `Backend/app/schemas/`：请求和响应数据结构。
- `Backend/tests/`：后端测试。
- `Backend/tools/`：用于抽样检查 AI 输出的本地工具。

### Docs

- `Docs/Product_Iteration_Plan.md`：当前产品迭代方向。
- `Docs/Technical_Agent_Architecture.md`：当前 Pet Agent 技术方案。
- `Docs/Agent_Output_Review_Checklist.md`：Agent 输出检查清单。

旧的根目录 Agent v2、RAG、单独拆任务、单独下一步建议、早期后端架构草稿已经删除，因为它们和现在的产品形态不一致。仍有价值的判断已经合并进 `Agents.md`、本 README 和 `Docs/` 下的当前文档。

## 本地运行 iOS

打开 Xcode 工程：

```bash
open FocusPet.xcodeproj
```

选择 `FocusPet` scheme，在 iOS 模拟器或真机上运行。

iOS 端通过 `LocalPersistenceService` 保存本地数据。删除 App 本地容器或对应数据文件后，本地状态会重置。

## 本地运行后端

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
DEEPSEEK_API_KEY=你的真实 key
```

启动服务：

```bash
uvicorn app.main:app --reload
```

接口文档地址：

```text
http://127.0.0.1:8000/docs
```

运行后端测试：

```bash
python -m pytest tests
```

## Git 注意事项

不要提交这些本地文件：

- `Backend/.env`
- `Backend/.venv/`
- `Backend/data/`
- `.DerivedData/`
- `.DS_Store`

这些都是本地环境、密钥、本地数据库或构建产物。仓库里应该只保留源码、文档、测试和模板。
