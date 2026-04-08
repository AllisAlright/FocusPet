import Foundation

enum DateDisplayFormatter {
    static let zhLocale = Locale(identifier: "zh_CN")
    static let zhCalendar = Calendar(identifier: .gregorian)

    private static let zhTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = zhLocale
        formatter.calendar = zhCalendar
        formatter.dateFormat = "HH:mm"
        return formatter
    }()

    private static let zhMonthDayTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = zhLocale
        formatter.calendar = zhCalendar
        formatter.dateFormat = "M月d日 HH:mm"
        return formatter
    }()

    private static let zhYearMonthDayTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = zhLocale
        formatter.calendar = zhCalendar
        formatter.dateFormat = "yyyy年M月d日 HH:mm"
        return formatter
    }()

    private static let zhWeekdayTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = zhLocale
        formatter.calendar = zhCalendar
        formatter.dateFormat = "EEEE HH:mm"
        return formatter
    }()

    private static let zhMonthDay: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = zhLocale
        formatter.calendar = zhCalendar
        formatter.dateFormat = "M月d日"
        return formatter
    }()

    private static let zhYearMonthDay: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = zhLocale
        formatter.calendar = zhCalendar
        formatter.dateFormat = "yyyy年M月d日"
        return formatter
    }()

    static func relativeChineseDateTime(from date: Date, now: Date = .now) -> String {
        let calendar = zhCalendar
        let seconds = Int(now.timeIntervalSince(date))

        if seconds >= 0 && seconds < 60 {
            return "刚刚"
        }

        if seconds >= 60 && seconds < 3_600 {
            return "\(seconds / 60)分钟前"
        }

        if calendar.isDate(date, inSameDayAs: now) {
            return zhTime.string(from: date)
        }

        if let yesterday = calendar.date(byAdding: .day, value: -1, to: now),
           calendar.isDate(date, inSameDayAs: yesterday) {
            return "昨天 \(zhTime.string(from: date))"
        }

        let dayDistance = calendar.dateComponents([.day], from: calendar.startOfDay(for: date), to: calendar.startOfDay(for: now)).day ?? 0
        if dayDistance >= 0 && dayDistance < 7 {
            let weekday = zhWeekdayTime.string(from: date)
                .replacingOccurrences(of: "星期", with: "周")
            return weekday
        }

        if calendar.component(.year, from: date) == calendar.component(.year, from: now) {
            return zhMonthDayTime.string(from: date)
        }

        return zhYearMonthDayTime.string(from: date)
    }

    static func memoTimestamp(from date: Date, now: Date = .now) -> String {
        relativeChineseDateTime(from: date, now: now)
    }

    static func memoEditorUpdatedText(from date: Date, now: Date = .now) -> String {
        "\(editorBaseText(from: date, now: now)) 更新"
    }

    static func deletedMemoText(from date: Date, now: Date = .now) -> String {
        "删除于 \(editorBaseText(from: date, now: now))"
    }

    static func taskDueText(from dueDate: Date, now: Date = .now) -> String {
        let calendar = zhCalendar
        let startOfToday = calendar.startOfDay(for: now)
        let startOfDueDate = calendar.startOfDay(for: dueDate)
        let dayOffset = calendar.dateComponents([.day], from: startOfToday, to: startOfDueDate).day ?? 0

        if dayOffset < 0 {
            return "已逾期"
        }
        if dayOffset == 0 {
            return "今天截止"
        }
        if dayOffset == 1 {
            return "明天截止"
        }
        if dayOffset <= 7 {
            return "\(dayOffset)天后截止"
        }
        if calendar.component(.year, from: dueDate) == calendar.component(.year, from: now) {
            return "\(zhMonthDay.string(from: dueDate))截止"
        }
        return "\(zhYearMonthDay.string(from: dueDate))截止"
    }

    static func fullChineseDate(from date: Date) -> String {
        zhYearMonthDay.string(from: date)
    }

    static func chineseTime(from date: Date) -> String {
        zhTime.string(from: date)
    }

    static func fullChineseDateTime(from date: Date) -> String {
        zhYearMonthDayTime.string(from: date)
    }

    static func focusStartText(from date: Date) -> String {
        "开始于 \(zhTime.string(from: date))"
    }

    private static func editorBaseText(from date: Date, now: Date) -> String {
        let calendar = zhCalendar

        if calendar.isDate(date, inSameDayAs: now) {
            return "今天 \(zhTime.string(from: date))"
        }

        if let yesterday = calendar.date(byAdding: .day, value: -1, to: now),
           calendar.isDate(date, inSameDayAs: yesterday) {
            return "昨天 \(zhTime.string(from: date))"
        }

        let dayDistance = calendar.dateComponents([.day], from: calendar.startOfDay(for: date), to: calendar.startOfDay(for: now)).day ?? 0
        if dayDistance >= 0 && dayDistance < 7 {
            return zhWeekdayTime.string(from: date)
                .replacingOccurrences(of: "星期", with: "周")
        }

        return zhYearMonthDayTime.string(from: date)
    }
}
