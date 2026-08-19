import SwiftUI

/// The keypad Round Entry screen (Survival, Fixed Rounds): every still-in
/// Entrant renders as a row at once; tapping one makes it "active," and the
/// shared keypad plus quick-entry shortcuts always write into whichever row
/// is active. Pushed full-screen from Play, matching the prototype's Entry
/// screen chrome (`docs/adr/0003`).
struct RoundEntryView: View {
    let entrants: [Entrant]
    /// This round's number, shown in the top bar ("Round 3").
    let roundNumber: Int
    /// Each still-in Entrant's current total, for the "now 34" meta line.
    let totals: [Entrant.ID: Int]
    /// Each Entrant's dot-badge color index from the full Match roster (not
    /// just the still-in ones shown here), so a badge's color always matches
    /// the same Entrant's badge on Standings, even after others have gone Out.
    let badgeIndices: [Entrant.ID: Int]
    /// The keypad's "never laid down" quick-entry shortcut value (Okey 101:
    /// 101). `nil` hides that shortcut for Variants that don't offer it.
    var neverLaidDownValue: Int? = nil
    /// Whether to offer the Çifte doubling toggle. Okey only — Gonga has no
    /// Çifte concept, so its entry screen hides the chip entirely.
    var supportsCifte: Bool = true
    let onSave: ([Entrant.ID: Int], Bool) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.theme) private var theme
    @State private var state: RoundEntryState

    /// - Parameter initialState: Seeds the screen's interactive state directly —
    ///   used by snapshot tests to capture a specific in-progress state (a
    ///   partial value, Çifte on) without driving the view through taps.
    ///   Production callers omit it and get the prototype's default: the
    ///   first still-in Entrant active, nothing entered.
    init(
        entrants: [Entrant],
        roundNumber: Int,
        totals: [Entrant.ID: Int],
        badgeIndices: [Entrant.ID: Int],
        neverLaidDownValue: Int? = nil,
        supportsCifte: Bool = true,
        initialState: RoundEntryState? = nil,
        onSave: @escaping ([Entrant.ID: Int], Bool) -> Void
    ) {
        self.entrants = entrants
        self.roundNumber = roundNumber
        self.totals = totals
        self.badgeIndices = badgeIndices
        self.neverLaidDownValue = neverLaidDownValue
        self.supportsCifte = supportsCifte
        self.onSave = onSave
        _state = State(initialValue: initialState ?? RoundEntryState(entrants: entrants))
    }

    private var entryTitle: String {
        neverLaidDownValue != nil ? "Count everyone\u{2019}s tiles" : "Count the cards left"
    }

    /// Çifte only counts where the Variant supports it — guarding the read as
    /// well as the chip keeps a seeded `cifteOn` from doubling a Gonga Round.
    private var isCifteOn: Bool { supportsCifte && state.cifteOn }

    private var entryHint: String {
        isCifteOn
            ? "\u{c7}ifte on \u{2014} every score doubles when you save."
            : "Winner takes 0. Tap a name, then type."
    }

    var body: some View {
        VStack(spacing: 0) {
            EntryTopBar(
                roundNumber: roundNumber,
                isReadyToSave: state.isReadyToSave,
                onCancel: { dismiss() },
                onSave: save
            )

            VStack(alignment: .leading, spacing: 6) {
                Text(entryTitle)
                    .siraStyle(.displayTitle)
                Text(entryHint)
                    .siraStyle(.body)
                    .foregroundStyle(theme.ink.opacity(0.55))
            }
            .padding(.horizontal, 22)
            .padding(.top, 16)
            .frame(maxWidth: .infinity, alignment: .leading)

            ScrollView {
                VStack(spacing: 7) {
                    ForEach(entrants) { entrant in
                        EntryRow(
                            entrant: entrant,
                            badgeIndex: badgeIndex(for: entrant.id),
                            isActive: state.activeEntrantID == entrant.id,
                            total: totals[entrant.id] ?? 0,
                            enteredValue: state.enteredValue(for: entrant.id),
                            doubledPreview: state.doubledPreview(for: entrant.id)
                        ) {
                            state.selectActive(entrant.id)
                        }
                    }
                }

                quickEntryChips
                    .padding(.top, 14)
            }
            .padding(.horizontal, 22)
            .padding(.top, 14)

            keypad
                .padding(11)
                .background(theme.track)
                .overlay(alignment: .top) {
                    Rectangle().fill(theme.line).frame(height: 1)
                }
        }
        .background(theme.background)
        .foregroundStyle(theme.ink)
    }

    private var quickEntryChips: some View {
        HStack(spacing: 7) {
            EntryChip(label: "Won the round \u{b7} 0") {
                state.applyQuickEntry(0)
            }
            if let neverLaidDownValue {
                EntryChip(label: "Never laid down \u{b7} \(neverLaidDownValue)") {
                    state.applyQuickEntry(neverLaidDownValue)
                }
            }
            if supportsCifte {
                EntryChip(label: "\u{c7}ifte \u{2014} double all \u{d7}2", isOn: state.cifteOn) {
                    state.cifteOn.toggle()
                }
            }
        }
        // Left-aligned so a Variant with only one chip (Gonga, which has no
        // Çifte) still lines up with the rows and title above it rather than
        // floating in the middle of the screen.
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var keypad: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 7), count: 3), spacing: 7) {
            ForEach(1...9, id: \.self) { digit in
                KeypadTile(label: "\(digit)") { state.appendDigit(Character("\(digit)")) }
            }
            KeypadTile(label: "C", isControl: true) { state.clearActive() }
            KeypadTile(label: "0") { state.appendDigit("0") }
            KeypadTile(label: "\u{232b}", isControl: true) { state.backspace() }
        }
    }

    private func badgeIndex(for id: Entrant.ID) -> Int {
        badgeIndices[id] ?? 0
    }

    private func save() {
        guard state.isReadyToSave else { return }
        // Raw counts plus the Çifte flag — the Engine applies the doubling.
        onSave(state.rawDeltas, isCifteOn)
    }
}

/// One Entry-screen row: dot badge, name, current total (plus the doubled
/// preview when Çifte is on), and the entered value — highlighted when active.
private struct EntryRow: View {
    let entrant: Entrant
    let badgeIndex: Int
    let isActive: Bool
    let total: Int
    let enteredValue: Int?
    let doubledPreview: Int?
    let onTap: () -> Void

    @Environment(\.theme) private var theme

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                DotBadge(text: entrant.initial, index: badgeIndex, size: 34)

                VStack(alignment: .leading, spacing: 5) {
                    Text(entrant.name)
                        .siraStyle(.headline)
                        .lineLimit(1)
                    Text(sira: .monoLabel, metaText)
                        .foregroundStyle(doubledPreview != nil ? theme.accent2 : theme.ink.opacity(0.42))
                }

                Spacer(minLength: 0)

                Text(valueText)
                    .font(.custom(FontFamily.mono, size: isActive ? 27 : 20, relativeTo: .title2).weight(.semibold))
                    .foregroundStyle(valueText == "\u{2014}" ? theme.ink.opacity(0.3) : theme.ink)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background {
                RoundedRectangle(cornerRadius: 19, style: .continuous)
                    .fill(isActive ? theme.surface : Color.clear)
            }
            .overlay {
                if isActive {
                    RoundedRectangle(cornerRadius: 19, style: .continuous)
                        .stroke(theme.line, lineWidth: 1)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private var metaText: String {
        guard let doubledPreview else { return "now \(total)" }
        return "now \(total)   \u{d7}2 \u{2192} \(doubledPreview)"
    }

    private var valueText: String {
        if let enteredValue {
            return "\(enteredValue)"
        }
        return isActive ? "" : "\u{2014}"
    }
}

#Preview("No row active") {
    let a = Entrant(name: "Alice")
    let b = Entrant(name: "Bob")
    return RoundEntryView(
        entrants: [a, b],
        roundNumber: 3,
        totals: [a.id: 34, b.id: 12],
        badgeIndices: [a.id: 0, b.id: 1]
    ) { _, _ in }
    .themed()
}

#Preview("Okey 101") {
    let a = Entrant(name: "Alice")
    let b = Entrant(name: "Bob")
    return RoundEntryView(
        entrants: [a, b],
        roundNumber: 3,
        totals: [a.id: 34, b.id: 12],
        badgeIndices: [a.id: 0, b.id: 1],
        neverLaidDownValue: 101
    ) { _, _ in }
    .themed()
}
