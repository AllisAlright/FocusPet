import SwiftUI

struct HomePlaceholderView: View {
    @EnvironmentObject private var store: FocusPetStore

    var body: some View {
        NavigationStack {
            List {
                Section("今天") {
                    LabeledContent("进行中事项", value: "\(store.homeSummary.activeTaskCount)")
                    LabeledContent("今日专注", value: "\(todayFocusedMinutes) 分钟")
                    LabeledContent("当前陪伴", value: store.settings.defaultPet.displayName)
                }

                Section("接下来") {
                    Text(nextTaskTitle)
                }

                Section("专注") {
                    NavigationLink("开始自由专注") {
                        FocusSetupView()
                    }

                    if let nextTask = nextTask {
                        NavigationLink("围绕“\(nextTask.title)”专注") {
                            FocusSetupView(preselectedTaskID: nextTask.id)
                        }
                    }
                }
            }
            .navigationTitle("首页")
        }
    }

    private var todayFocusedMinutes: Int {
        let calendar = Calendar.current
        return store.focusSessions
            .filter { calendar.isDateInToday($0.startedAt) }
            .map(\.durationMinutes)
            .reduce(0, +)
    }

    private var nextTask: Task? {
        store.tasks
            .filter { $0.resolvedStatus() == .active }
            .sorted { ($0.dueDate ?? .distantFuture) < ($1.dueDate ?? .distantFuture) }
            .first
    }

    private var nextTaskTitle: String {
        nextTask?.title ?? "暂时没有进行中的事项"
    }
}
