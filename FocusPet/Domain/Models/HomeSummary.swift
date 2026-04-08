import Foundation

struct HomeSummary: Codable, Hashable, Sendable {
    var petType: PetType
    var activeTaskCount: Int
    var overdueTaskCount: Int
    var todayFocusMinutes: Int
    var nearestDueTaskTitle: String?
    var message: String

    init(
        petType: PetType,
        activeTaskCount: Int,
        overdueTaskCount: Int,
        todayFocusMinutes: Int,
        nearestDueTaskTitle: String?,
        message: String
    ) {
        self.petType = petType
        self.activeTaskCount = activeTaskCount
        self.overdueTaskCount = overdueTaskCount
        self.todayFocusMinutes = todayFocusMinutes
        self.nearestDueTaskTitle = nearestDueTaskTitle
        self.message = message
    }
}

extension HomeSummary {
    var activeTaskText: String {
        "进行中 \(activeTaskCount) 项"
    }

    var focusTimeText: String {
        "今天专注 \(todayFocusMinutes) 分钟"
    }

    var urgencyText: String {
        if overdueTaskCount > 0 {
            return "还有 \(overdueTaskCount) 项需要尽快处理"
        }
        return nearestDueTaskTitle ?? "今天先慢慢开始也可以"
    }
}
