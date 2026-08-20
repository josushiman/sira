import Foundation

/// How a Match is named wherever one is shown: by when it was started, which
/// is what Home sorts by and never changes. Shared by the Home card and the
/// delete confirmation, so the Match named in the confirmation is spelled
/// exactly as the card the player pressed.
enum MatchDateTitle {
    /// "14th March 2026 · 9pm" — the minutes are only shown when there are
    /// any, so the common on-the-hour case stays short.
    static func text(for date: Date) -> String {
        let day = Calendar.current.component(.day, from: date)
        let ordinalDay = ordinalDayFormatter.string(from: NSNumber(value: day)) ?? "\(day)"
        let monthAndYear = date.formatted(.dateTime.month(.wide).year())
        return "\(ordinalDay) \(monthAndYear) · \(time(for: date))"
    }

    /// 12-hour clock, lowercase, minutes elided on the hour: "9pm", "9:15pm".
    private static func time(for date: Date) -> String {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        let minute = calendar.component(.minute, from: date)
        let suffix = hour < 12 ? "am" : "pm"
        let hour12 = hour % 12 == 0 ? 12 : hour % 12
        return minute == 0
            ? "\(hour12)\(suffix)"
            : String(format: "%d:%02d%@", hour12, minute, suffix)
    }

    private static let ordinalDayFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .ordinal
        return formatter
    }()
}
