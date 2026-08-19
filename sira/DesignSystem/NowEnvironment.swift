import SwiftUI

/// The date treated as "today" when formatting Match dates — Home drops the
/// year from a Match started this year. Defaults to the real clock; snapshot
/// tests override it so their output doesn't change when the year rolls over.
private struct NowKey: EnvironmentKey {
    static let defaultValue: Date = Date()
}

extension EnvironmentValues {
    var now: Date {
        get { self[NowKey.self] }
        set { self[NowKey.self] = newValue }
    }
}
