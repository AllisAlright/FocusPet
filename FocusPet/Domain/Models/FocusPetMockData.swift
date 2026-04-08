import Foundation

enum FocusPetMockData {
    static let now = Date()

    static let appSettings = AppSettings()

    static let tasks: [TaskItem] = [
        TaskItem(
            id: UUID(uuidString: "11111111-1111-1111-1111-111111111111") ?? UUID(),
            title: "整理产品原型",
            notes: "先把首页和待办流程串起来。",
            createdAt: now.addingTimeInterval(-86_400 * 2),
            updatedAt: now.addingTimeInterval(-3_600),
            dueDate: now.addingTimeInterval(86_400 * 2),
            estimatedMinutes: 180,
            spentMinutes: 60,
            status: .active,
            enableFocus: true,
            preferredPet: .rabbit
        ),
        TaskItem(
            id: UUID(uuidString: "22222222-2222-2222-2222-222222222222") ?? UUID(),
            title: "补完数据库课程笔记",
            notes: "还有事务和索引两节。",
            createdAt: now.addingTimeInterval(-86_400 * 4),
            updatedAt: now.addingTimeInterval(-86_400),
            dueDate: now.addingTimeInterval(86_400),
            estimatedMinutes: 120,
            spentMinutes: 25,
            manualProgress: 0.3,
            status: .active,
            enableFocus: true,
            preferredPet: .rabbit
        ),
        TaskItem(
            id: UUID(uuidString: "33333333-3333-3333-3333-333333333333") ?? UUID(),
            title: "联系房东确认续租",
            notes: "需要发消息并整理问题清单。",
            createdAt: now.addingTimeInterval(-86_400 * 5),
            updatedAt: now.addingTimeInterval(-86_400 * 2),
            dueDate: now.addingTimeInterval(-86_400),
            estimatedMinutes: 30,
            spentMinutes: 10,
            status: .overdue,
            enableFocus: false,
            preferredPet: .cat
        ),
        TaskItem(
            id: UUID(uuidString: "34343434-3434-3434-3434-343434343434") ?? UUID(),
            title: "整理面试作品集素材",
            notes: "截图和案例说明已经找了一半，先放着等今晚继续。",
            createdAt: now.addingTimeInterval(-86_400 * 6),
            updatedAt: now.addingTimeInterval(-86_400 * 2),
            dueDate: now.addingTimeInterval(86_400 * 4),
            estimatedMinutes: 150,
            spentMinutes: 55,
            manualProgress: 0.4,
            status: .paused,
            enableFocus: true,
            preferredPet: .dog
        ),
        TaskItem(
            id: UUID(uuidString: "44444444-4444-4444-4444-444444444444") ?? UUID(),
            title: "写完周报",
            notes: "已提交。",
            createdAt: now.addingTimeInterval(-86_400 * 3),
            updatedAt: now.addingTimeInterval(-86_400 / 2),
            dueDate: now.addingTimeInterval(-86_400 / 2),
            estimatedMinutes: 45,
            spentMinutes: 50,
            status: .completed,
            enableFocus: true,
            preferredPet: .rabbit
        )
    ]

    static let memoItems: [MemoItem] = [
        MemoItem(
            id: UUID(uuidString: "55555555-5555-5555-5555-555555555555") ?? UUID(),
            content: "想到一个首页摘要文案：先做最临近截止的那件事。",
            createdAt: now.addingTimeInterval(-4_000),
            updatedAt: now.addingTimeInterval(-4_000),
            isPinned: true
        ),
        MemoItem(
            id: UUID(uuidString: "66666666-6666-6666-6666-666666666666") ?? UUID(),
            content: "把雨天窗边场景先做成静态背景，后续再补轻动画。",
            createdAt: now.addingTimeInterval(-9_000),
            updatedAt: now.addingTimeInterval(-7_200),
            isPinned: false
        )
    ]

    static let focusSessions: [FocusSession] = [
        FocusSession(
            id: UUID(uuidString: "77777777-7777-7777-7777-777777777777") ?? UUID(),
            taskID: tasks[0].id,
            petType: .rabbit,
            sceneType: .rainyWindow,
            startedAt: now.addingTimeInterval(-5_400),
            endedAt: now.addingTimeInterval(-3_600),
            durationSeconds: 1_800,
            timerMode: .countDown,
            plannedDurationSeconds: 1_800,
            sessionStatus: .finished
        ),
        FocusSession(
            id: UUID(uuidString: "88888888-8888-8888-8888-888888888888") ?? UUID(),
            taskID: tasks[1].id,
            petType: .rabbit,
            sceneType: .morningCafe,
            startedAt: now.addingTimeInterval(-86_400),
            endedAt: now.addingTimeInterval(-85_200),
            durationSeconds: 1_200,
            timerMode: .countUp,
            sessionStatus: .finished
        ),
        FocusSession(
            id: UUID(uuidString: "99999999-9999-9999-9999-999999999999") ?? UUID(),
            taskID: nil,
            petType: .rabbit,
            sceneType: .rainyWindow,
            startedAt: now.addingTimeInterval(-2_400),
            endedAt: now.addingTimeInterval(-1_800),
            durationSeconds: 600,
            timerMode: .countUp,
            sessionStatus: .finished
        )
    ]

    static let homeSummary = HomeSummary(
        petType: .rabbit,
        activeTaskCount: tasks.filter { $0.resolvedStatus() == .active }.count,
        overdueTaskCount: tasks.filter { $0.resolvedStatus() == .overdue }.count,
        todayFocusMinutes: focusSessions
            .filter { Calendar.current.isDateInToday($0.startedAt) }
            .map(\.durationMinutes)
            .reduce(0, +),
        nearestDueTaskTitle: tasks
            .filter { !$0.isCompleted }
            .sorted { ($0.dueDate ?? .distantFuture) < ($1.dueDate ?? .distantFuture) }
            .first?
            .title,
        message: "先推进一点，也算前进。"
    )
}

enum FocusPetSampleFactory {
    static func makeTaskItems() -> [TaskItem] {
        FocusPetMockData.tasks
    }

    static func makeMemoItems() -> [MemoItem] {
        FocusPetMockData.memoItems
    }

    static func makeFocusSessions() -> [FocusSession] {
        FocusPetMockData.focusSessions
    }

    static func makeAppSettings() -> AppSettings {
        FocusPetMockData.appSettings
    }

    static func makeHomeSummary() -> HomeSummary {
        FocusPetMockData.homeSummary
    }
}
