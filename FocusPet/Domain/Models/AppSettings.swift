import Foundation

struct AppSettings: Codable, Hashable, Sendable {
    var defaultPet: PetType
    var defaultScene: SceneType
    var defaultTimerMode: TimerMode
    var defaultCountdownMinutes: Int
    var soundEnabled: Bool
    var reminderEnabled: Bool

    init(
        defaultPet: PetType = .rabbit,
        defaultScene: SceneType = .rainyWindow,
        defaultTimerMode: TimerMode = .countDown,
        defaultCountdownMinutes: Int = 25,
        soundEnabled: Bool = true,
        reminderEnabled: Bool = false
    ) {
        self.defaultPet = defaultPet
        self.defaultScene = defaultScene
        self.defaultTimerMode = defaultTimerMode
        self.defaultCountdownMinutes = defaultCountdownMinutes
        self.soundEnabled = soundEnabled
        self.reminderEnabled = reminderEnabled
    }
}

extension AppSettings {
    var defaultCountdownText: String {
        "\(defaultCountdownMinutes) 分钟"
    }
}
