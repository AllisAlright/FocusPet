Agents.md
1. Project Overview
Product Name
暂定：FocusPet / 专注伴侣
Product Vision
打造一款面向轻度拖延、任务分散、专注效率不足用户的 AI陪伴专注 + 任务推进 应用。
它不是传统待办清单，也不是纯番茄钟，而是一个把 碎片记录、任务推进、专注陪伴、进度管理、温和督促 融合在一起的产品。
Core Problem
用户的任务分散在备忘录、提醒事项、聊天记录等多个地方，容易遗漏；很多任务不是“一次完成”，而是需要多次投入逐步推进，但现有工具通常只支持“完成 / 未完成”二元状态，无法自然表达“今天做了30%，明天继续”。
此外，用户往往：
- 不清楚某项任务到底还差多少才能完成
- 无法合理预估和拆分时间
- 在专注过程中容易分心
- 面对堆积的未完成事项时产生压力和逃避
Core Value Proposition
本产品通过以下方式解决问题：
- 用 进度条任务模型 替代单纯的勾选式待办
- 用 可恢复、可延续 的任务机制降低中途暂停的心理负担
- 用 AI虚拟动物陪伴 增强情感联结与持续使用意愿
- 用 场景化专注空间 帮助用户快速进入沉浸状态
- 用 轻量规划建议 帮助用户在截止日期前安排投入节奏

---
2. Product Positioning
Target Users
优先面向以下用户：
- 学生 / 研究生
- 初入职场的白领
- 自由职业者 / 创作者
- 有轻度拖延、容易分心、任务切换频繁的人
- 希望被温柔提醒，而不是被强压管理的人
Product Tone
- 清新
- 淡雅
- 简约
- 有陪伴感
- 温柔但不啰嗦
- 可爱但不幼稚
- 治愈但不影响效率
Emotional Keywords
- “有人陪我做完它”
- “任务没做完也没关系，可以继续”
- “我不是被催促，而是被温柔地拉回正轨”

---
3. Core Design Principles
1. 进度比完成更重要
  - 用户的真实工作状态是“逐步推进”，不是简单的完成/未完成。
2. 减压优先于施压
  - 产品需要制造适度紧迫感，但不能制造压迫感。
3. 陪伴服务于专注
  - 虚拟角色的存在是为了增强留存、温和提醒和情绪稳定，不能喧宾夺主。
4. 可爱但克制
  - 视觉要萌、统一、有记忆点，但信息结构必须清晰，避免过度装饰。
5. 低门槛记录，高质量推进
  - 用户可以快速记录碎片想法，也可以在后续把它转化为可推进的事项。
6. 任务永远可续做
  - 用户不应因“一次没做完”而产生失败感。

---
4. MVP Scope (Phase 1)
Must Have
1. 首页入口
2. 备忘录模块
3. 待办事项模块
4. 历史事项模块
5. 专注模块
6. AI虚拟动物选择与基础陪伴
7. 进度条任务机制
8. 预估耗时与自动换算进度
9. 截止日期与倒计时展示
10. 本地数据持久化
Won’t Do in Phase 1
1. 账号系统
2. 云同步
3. 多端同步
4. 网络请求
5. 社交功能
6. 真正的大模型联网能力
7. 复杂统计图表
8. App内购买 / 订阅
9. Siri / 日历 / 提醒事项系统集成

---
5. Information Architecture
App Main Modules
- 首页 Home
- 备忘录 Memo
- 待办事项 Tasks
- 专注 Focus
- 历史事项 History
- 设置 Settings
Suggested Navigation
推荐采用：
- 首页作为世界观入口
- 配合底部轻量导航栏或隐藏式跳转
建议底部导航：
- 首页
- 待办
- 专注
- 历史
- 设置
其中“备忘录”可以在首页强入口展示，也可以在待办页上方通过 Tab 切换进入。
原因：
- 你希望首页有强场景感和角色互动感
- 但实际开发和可用性上，仍需要稳定、可预期的导航结构

---
6. Core User Flow
Flow A: 快速记录碎片想法
1. 用户打开 App
2. 进入首页
3. 点击“备忘录”入口
4. 新建一条记录
5. 可选择：仅保存为备忘 / 转为待办
6. 若转为待办，则补充：标题、截止日期、预估耗时、是否启用专注
Flow B: 创建待办并逐步推进
1. 用户进入待办事项页
2. 新建待办
3. 输入标题、备注、截止时间、预估耗时
4. 选择AI角色（可选）
5. 选择是否立即开始专注
6. 若暂不专注，则任务进入“未完成事项”列表
7. 用户后续可继续补充进度，直到100%
8. 达到100%后自动移入“历史成功完成”
Flow C: 从待办进入专注
1. 用户点击首页“专注”
2. 系统弹出底部面板：
  - 创建新事项并专注
  - 从待办中选择事项
  - 仅开启自由专注
3. 用户选择事项
4. 选择角色、场景、计时模式（正计时/倒计时）
5. 进入专注界面
6. 专注结束后：
  - 记录本次专注时长
  - 自动换算任务进度
  - 用户可手动修正本次增加的进度
  - 角色给予一句简短反馈
Flow D: 恢复未完成事项
1. 用户在待办页或历史页查看未完成事项
2. 点击某个未完成任务
3. 查看当前进度、剩余预估时间、最近一次投入记录
4. 选择继续专注 / 手动补充进度 / 编辑任务
5. 持续推进直至100%

---
7. Refined Feature Definition
7.1 Memo Module
Goal
快速承接随手记下的小思考，避免信息散落。
Features
- 新建备忘
- 编辑 / 删除备忘
- 标记为重要
- 转换为待办
- 支持创建时间展示
- 支持搜索
UX Notes
- 输入成本要极低
- 默认优先文本记录
- 不在 Phase 1 支持图片/附件

---
7.2 Task Module
Goal
把任务从“是否完成”升级为“推进到什么程度”。
Task Fields
每个待办建议包含：
- id
- 标题 title
- 备注 notes
- 创建时间 createdAt
- 更新时间 updatedAt
- 截止时间 dueDate（可选）
- 是否有截止时间 hasDeadline
- 预估总耗时 estimatedMinutes（可选）
- 已投入时长 spentMinutes
- 当前进度 progress（0~1）
- 状态 status
- 是否启用专注 enableFocus
- 关联角色 preferredPet（可选）
- 标签 tags（Phase 1 可选简化）
Task Status Definition
建议不要只用 completed / incomplete，建议拆分：
- active：未完成、正常推进中
- paused：暂时搁置
- overdue：已过截止日期且未完成
- completed：已完成
- archived：历史归档（可选）
Progress Rules
- 支持用户手动设置进度
- 若填写预估耗时，则系统可根据专注时长自动换算进度
- 自动换算公式：
  - autoProgress = spentMinutes / estimatedMinutes
  - 最终 progress 需要 clamp 到 0...1
- 若用户修改 estimatedMinutes，则 progress 需重新计算
- 若任务没有 estimatedMinutes，则系统不自动换算，只记录专注时长，进度需用户手动调整
Important Product Decision
手动进度优先于自动进度，但两者都要可追溯。
建议设计：
- 保存 manualProgressOverride（可选）
- 保存 spentMinutes
- UI展示当前最终进度 displayProgress
- 当用户手动修改后，提示：
  - “已按手动进度记录，本次专注时长仍会保留在投入记录中。”
这样更贴近真实使用，不会让用户感觉“被算法绑架”。

---
7.3 Deadline & Countdown
Goal
为有时限的任务提供适度紧迫感。
Features
- 可选设置截止日期
- 任务卡片展示倒计时
- 文案示例：
  - 距离提交还有 2 天
  - 今天截止
  - 已超时 1 天
UX Notes
- 红色等高压视觉要克制使用
- 优先通过文案和轻提示营造紧迫感
- 对逾期任务可提升排序，但不要频繁弹窗打扰

---
7.4 Focus Module
Goal
将任务推进与沉浸式专注结合。
Entry Types
- 从首页进入专注
- 从待办详情进入专注
- 从任务卡片直接进入专注
- 自由专注（不绑定任务）
Focus Mode Types
- 正计时：适合开放式投入
- 倒计时：适合番茄钟 / 目标时长专注
Focus Session Fields
- id
- taskId（可选）
- petType
- sceneType
- startedAt
- endedAt（可选）
- durationSeconds
- timerMode
- plannedDurationSeconds（倒计时模式下可选）
- soundMix
- sessionStatus（running / paused / finished / cancelled）
End of Focus
专注结束时：
- 记录专注时长
- 若关联待办且填写了预估耗时，自动更新进度
- 角色显示一句反馈
- 可选择：
  - 继续下一轮专注
  - 返回任务详情
  - 结束并回首页

---
7.5 History Module
Goal
让完成与积累可见，同时让未完成事项也可以被重新唤起。
Suggested Structure
历史页建议拆成两个分段：
- 已完成
- 未完成记录 / 已搁置
Why
你原本的想法里，未做完的也可以在历史里被“捞起来”。为了避免与待办页重叠，建议这样定义：
- 待办页：当前正在推进的事项
- 历史页：已完成 + 已暂停/搁置/逾期事项
这样信息层级更清楚。

---
8. AI Pet System
Pet Types
- 猫：安静、冷淡一点、可靠、少说话
- 狗：阳光、鼓励型、充满行动力
- 兔子：温柔、细腻、安抚型
- 仓鼠：可爱、轻快、活泼一点
Pet Design Rules
1. 画风统一
2. 都必须是卡通萌系
3. 线条干净，色彩柔和
4. 不要过度细节化，避免抢走专注注意力
5. 场景和角色需高度适配
Pet Responsibilities
在 Phase 1 中，角色主要承担：
- 欢迎用户
- 轻量提醒
- 专注开始前一句引导
- 专注结束后一条反馈
- 在首页展示任务摘要
- 根据截止日期和剩余进度给出简单规划建议
Dialogue Principles
- 少说话
- 一次只说一句
- 避免连续弹出
- 文案温和自然
- 不使用命令式语气
- 不制造羞耻感
Example Lines
Cat
- 开始吧，我会陪你安静做完。
- 先推进一点，也算前进。
- 今天已经比刚才更靠近完成了。
Dog
- 好耶，我们动起来！
- 先冲十分钟也很好！
- 又完成一小段，超棒！
Rabbit
- 没关系，我们慢慢来也可以。
- 先做一点点，心就会安稳很多。
- 你已经认真投入过了，很不错。
Hamster
- 嗖一下开始吧！
- 一点点也能堆出大进展！
- 今天又往前滚了一小格！

---
9. Focus Scene System
Scene 1: Rainy Window
Visual
下雨天窗边，雨滴从窗上滑落，小动物在壁炉旁看电脑，室内暖光偏暗，电脑有微弱光感。
Ambient Sound
- 壁炉声
- 雷雨声
- 两种声音独立调节
Emotional Goal
适合夜晚、补作业、深度投入、情绪想稳定下来时使用。
Scene 2: Dusk Park Bench
Visual
黄昏公园长椅，小动物坐着听歌，微风吹动树叶，叶片轻轻飘落。
Ambient Sound
- 风声
- 树叶沙沙声
- 两种声音独立调节
Emotional Goal
适合傍晚整理思绪、轻度推进任务。
Scene 3: Morning Cafe
Visual
清晨阳光洒在桌面，小动物在咖啡厅喝咖啡看书，整体明亮、柔和、清醒。
Ambient Sound
- 咖啡厅环境音
- 冰块碰撞声
- 两种声音独立调节
Emotional Goal
适合晨间计划、写作、学习启动。
Shared UI Requirements
每个专注场景都应有：
- 显眼但不突兀的时钟/闹钟挂件
- 点击后可查看当前专注时长
- 结束专注按钮
- 返回继续专注按钮
- 白噪音调节入口
- 当前绑定事项名称
- 当前角色头像/动作状态
Motion Principles
- 动画必须慢而轻
- 背景元素只允许低频率变化
- 不允许炫目效果
- 不允许强烈颜色闪烁

---
10. Home Page Design Strategy
Goal
一进入 App 就感到清新、淡雅、轻松、愿意开始。
Home Page Requirements
首页要有四个醒目的交互入口：
- 历史事项
- 备忘录
- 待办事项
- 专注
Important Recommendation
不要让首页完全依赖非常复杂的插画映射关系，否则开发和后期维护成本高。
建议采用：
- 场景化插画首页 + 明确可点击区域卡片
- 也就是：插画服务氛围，按钮服务交互
Example Mapping
可以这样设计：
- 备忘录：毛线团标签 / 小桌便签本
- 待办事项：电视机 / 小黑板 / 电脑屏幕
- 历史事项：书架上的相册 / 收纳盒
- 专注：闹钟 / 台灯 / 沙漏
Why
这样既满足世界观，也不会让用户不知道哪里能点。
Home Summary Area
首页顶部/中部可以加一个轻摘要区：
- 今日待办数量
- 今日已专注时长
- 最临近截止事项
- AI角色一句总结
示例：
- 你还有 3 项任务在推进中。
- 距离“产品原型整理”截止还有 2 天。
- 今天已经专注 45 分钟啦。

---
11. Product Logic Details
Progress Calculation Logic
Case A: 有预估耗时
- 任务创建时填写 estimatedMinutes
- 每次完成专注后累加 spentMinutes
- 系统自动计算 progress
- progress = min(spentMinutes / estimatedMinutes, 1.0)
Case B: 无预估耗时
- 专注时长只记录，不自动换算进度
- 用户自行手动设置 progress
Case C: 修改预估耗时
- 若 estimatedMinutes 改变，则自动重新计算 progress
- 若此前存在 manualProgressOverride，则弹出确认：
  - 是否继续使用手动进度
  - 是否改为按投入时长重新计算
这是一个很关键的设计点，建议在MVP中先做成简化版本：
- 默认按投入时长重新计算
- 若用户手动修改过进度，则提示一次即可
Completion Logic
- progress >= 1.0 时自动标记 completed
- completed 任务从待办页主列表隐藏
- 在历史页可查看
- 可查看总投入时长、完成日期
Restore Logic
- completed 任务默认不可再编辑进度
- paused / overdue 任务可一键恢复到 active

---
12. MVP Screens
12.1 Launch / Home
内容：
- 角色主视觉
- 四大入口
- 今日摘要
- 最近任务概览
12.2 Memo List
内容：
- 备忘列表
- 搜索
- 新建
- 转为待办
12.3 Task List
内容：
- active / paused / overdue 分段
- 任务卡片
- 进度条
- 倒计时
- 快速开始专注
12.4 Task Detail
内容：
- 标题
- 备注
- 当前进度
- 已投入时长
- 预估总耗时
- 截止时间
- 最近专注记录
- 编辑按钮
- 开始专注按钮
- 手动更新进度
12.5 Create / Edit Task
内容：
- 标题
- 备注
- 截止日期
- 预估耗时
- 是否启用专注
- 首选角色
12.6 Focus Setup Sheet
内容：
- 选择新建事项 / 选择已有事项 / 自由专注
- 选择角色
- 选择场景
- 选择正计时 / 倒计时
- 设置倒计时时长
12.7 Focus Session Screen
内容：
- 场景主视觉
- 当前角色
- 当前事项名
- 专注计时
- 音量调节
- 结束专注
- 返回继续专注
12.8 History Screen
内容：
- 已完成事项
- 搁置 / 逾期事项
- 重新激活入口
12.9 Settings
内容：
- 默认角色
- 默认专注场景
- 提醒开关
- 声音设置
- 数据清理

---
13. Local Architecture (SwiftUI / iOS 17+)
Tech Stack
- SwiftUI
- Observation / Observable
- SwiftData（优先推荐）或 Core Data
- AVFoundation（音频播放）
- Timer / TimelineView（计时）
Why SwiftData
对于 Phase 1 本地原型，SwiftData 更适合：
- 开发快
- 与 SwiftUI 集成自然
- 适合本地模型与模拟数据
Suggested Layers
- App
- Features
  - Home
  - Memo
  - Tasks
  - Focus
  - History
  - Settings
- Domain
  - Models
  - Enums
  - Services
- Shared
  - Components
  - Theme
  - Utilities
Suggested Folder Structure
App/
Features/
  Home/
  Memo/
  Tasks/
  Focus/
  History/
  Settings/
Domain/
  Models/
  Enums/
  Services/
Shared/
  Components/
  Theme/
  Extensions/
Resources/

---
14. Suggested Data Models
enum PetType: String, Codable, CaseIterable {
    case cat
    case dog
    case rabbit
    case hamster
}

enum SceneType: String, Codable, CaseIterable {
    case rainyWindow
    case duskPark
    case morningCafe
}

enum TaskStatus: String, Codable, CaseIterable {
    case active
    case paused
    case overdue
    case completed
}

enum TimerMode: String, Codable, CaseIterable {
    case countUp
    case countDown
}
struct Task {
    var id: UUID
    var title: String
    var notes: String
    var createdAt: Date
    var updatedAt: Date
    var dueDate: Date?
    var estimatedMinutes: Int?
    var spentMinutes: Int
    var manualProgress: Double?
    var status: TaskStatus
    var enableFocus: Bool
    var preferredPet: PetType?
}
extension Task {
    var computedProgress: Double {
        if let manualProgress {
            return min(max(manualProgress, 0), 1)
        }
        guard let estimatedMinutes, estimatedMinutes > 0 else { return 0 }
        return min(max(Double(spentMinutes) / Double(estimatedMinutes), 0), 1)
    }
}
struct FocusSession {
    var id: UUID
    var taskId: UUID?
    var petType: PetType
    var sceneType: SceneType
    var startedAt: Date
    var endedAt: Date?
    var durationSeconds: Int
    var timerMode: TimerMode
}
struct MemoItem {
    var id: UUID
    var content: String
    var createdAt: Date
    var updatedAt: Date
    var isPinned: Bool
}

---
15. Agent Definitions
说明：这里的 Agent 指本地产品逻辑层面的“智能行为角色”，Phase 1 不接真实联网大模型，可先通过规则、模板文案、模拟数据和轻量策略实现。
15.1 Home Summary Agent
Goal
在首页生成简短、温和、有陪伴感的今日摘要。
Inputs
- 今日待办数量
- 最近截止日期
- 今日累计专注时长
- 最近完成事项
- 当前角色类型
Outputs
- 一句首页摘要文案
Example
- 猫：你还有 2 项任务在推进，先做最临近的那个。
- 狗：今天已经专注 35 分钟啦，再来一点就更棒！
- 兔子：还有 1 件快到截止的事，我们慢慢把它推进。
- 仓鼠：已经有进展啦，今天再滚一小格也很好！

---
15.2 Task Planning Agent
Goal
当任务设置了截止日期和预估耗时后，生成简单的推进建议。
Inputs
- estimatedMinutes
- spentMinutes
- dueDate
- currentDate
Outputs
- 每天建议投入时长
- 剩余可用天数
- 一句提示文案
Logic
- remainingMinutes = max(estimatedMinutes - spentMinutes, 0)
- remainingDays = max(daysBetween(currentDate, dueDate), 1)
- dailyTarget = ceil(remainingMinutes / remainingDays)
Example Output
- 还剩 180 分钟，距离截止还有 3 天。
- 建议每天投入 60 分钟，会更容易按时完成。

---
15.3 Focus Encouragement Agent
Goal
在专注开始、结束、暂停时给出极简反馈。
Trigger
- 开始专注
- 完成专注
- 中途结束
- 任务完成
Constraints
- 每次仅 1 句
- 不超过 20 字为佳
- 不能连续高频出现

---
15.4 Task Recovery Agent
Goal
当用户长时间没有推进某个任务时，提供温和的恢复建议。
Trigger
- 超过 N 天未更新
- 已逾期但仍未完成
Example
- 这件事已经放了几天，要不要先推进 10 分钟？
- 不用一次做完，我们先把这一小格补上。

---
16. Non-Functional Requirements
Performance
- 首页首屏加载流畅
- 专注界面动画稳定
- 计时误差尽量低
- 音频切换不突兀
Accessibility
- 文本字号支持动态字体
- 色彩对比度足够
- 按钮热区清晰
- 不能仅靠颜色表达状态
Usability
- 三步内进入专注
- 新建待办不超过 1 分钟
- 任何页面都能快速回到当前专注状态

---
17. App Store Readiness Considerations
Phase 1 先按可上架思路设计，但不在当前版本实现全部能力。
Need to Consider Early
1. 不能误导用户为医疗/心理治疗产品
2. 不要夸大 AI 能力
3. 若未来接入提醒推送，需要权限说明文案
4. 若未来接入音频资源，需要注意版权
5. UI 需有完整的隐私说明入口（后续版本）
App Store Positioning Suggestion
更适合定位为：
- 生产力工具
- 专注陪伴工具
- 任务管理与时间投入记录工具
不建议定位为：
- 心理治疗
- 医疗改善
- 临床注意力干预工具

---
18. Visual Style Guide
Style Keywords
- 淡彩
- 柔和光感
- 奶油感
- 低饱和
- 扁平 + 轻微质感
- 简洁留白
UI Principles
- 主界面信息密度中低
- 卡片边角圆润
- 阴影很轻
- 插画为主，控件不浮夸
- 统一图标语言
Color Suggestion
- 米白
- 浅灰蓝
- 奶油黄
- 鼠尾草绿
- 雾霾粉
避免：
- 高饱和荧光色
- 大面积纯黑纯红
- 过多拟物材质

---
19. Development Priorities
Milestone 1: Data & Core Logic
- 完成本地模型
- 完成任务 CRUD
- 完成备忘录 CRUD
- 完成进度与耗时逻辑
- 完成历史归档逻辑
Milestone 2: Focus Flow
- 完成专注设置页
- 完成计时器
- 完成专注记录
- 完成自动进度换算
- 完成基础白噪音切换
Milestone 3: Pet Experience
- 完成角色系统
- 完成首页摘要Agent
- 完成开始/结束专注文案
- 完成基本场景动画
Milestone 4: Polish
- 优化首页世界观
- 优化微交互
- 加入空状态页
- 加入引导页
- 完成App图标与启动页

---
20. Open Questions
以下问题建议在正式编码前继续确认：
1. 首页四入口是否保留底部 Tab 作为辅助导航？
2. 备忘录和待办是否要支持互相转换？
3. 手动进度修改后，自动进度是否永久失效？
4. 逾期任务默认放在待办页还是历史页？
5. 自由专注是否也需要进入历史记录？
6. 白噪音资源先用本地音频还是占位符？
7. 四种动物是否都需要分别配三套场景插画？
8. MVP 是否只先做一个角色 + 一个场景验证流程？

---
21. Recommended MVP Simplification
为了更快用 Codex 和 SwiftUI 做出可运行版本，建议第一版再收敛一层：
v0.1 建议只做
- 1 个首页
- 备忘录
- 待办
- 历史
- 专注
- 1 个角色（先兔子）
- 1 个场景（先雨天窗边）
- 基础进度条
- 预估耗时换算
- 本地存储
v0.2 再加入
- 全部4个角色
- 全部3个场景
- 更多角色文案
- 截止日期规划建议
- 更丰富首页摘要
这是最有利于你作为产品经理边做边验证的路径。

---
22. Final Product Statement
这不是一个“催你完成所有事情”的工具。
它更像一个温柔、可靠、可以陪你把事情一点点做完的空间。
用户打开它，不该感到压力，而应该感到：
- 我知道接下来做什么
- 我就先做一点点
- 没做完也没关系，可以继续
- 有它陪着，我更容易进入状态
这就是本产品最重要的体验目标。
