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
    /// Whether to offer the Çifte chip. Okey only — Gonga has no Çifte
    /// concept, so its entry screen hides the chip entirely.
    var supportsCifte: Bool = true
    /// The Match's Game, which chooses the Okey atmak chip's label: Okey
    /// players say "Okey attı", Gonga players "Jokeri attı".
    var game: Game = .okey
    let onSave: (_ deltas: [Entrant.ID: Int], _ cifteCallers: Set<Entrant.ID>, _ okeyAtanID: Entrant.ID?) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.theme) private var theme
    @State private var state: RoundEntryState

    /// - Parameter initialState: Seeds the screen's interactive state directly —
    ///   used by snapshot tests to capture a specific in-progress state (a
    ///   partial value, a Çifte caller) without driving the view through taps.
    ///   Production callers omit it and get the prototype's default: the
    ///   first still-in Entrant active, nothing entered.
    init(
        entrants: [Entrant],
        roundNumber: Int,
        totals: [Entrant.ID: Int],
        badgeIndices: [Entrant.ID: Int],
        neverLaidDownValue: Int? = nil,
        supportsCifte: Bool = true,
        game: Game = .okey,
        initialState: RoundEntryState? = nil,
        onSave: @escaping (_ deltas: [Entrant.ID: Int], _ cifteCallers: Set<Entrant.ID>, _ okeyAtanID: Entrant.ID?) -> Void
    ) {
        self.entrants = entrants
        self.roundNumber = roundNumber
        self.totals = totals
        self.badgeIndices = badgeIndices
        self.neverLaidDownValue = neverLaidDownValue
        self.supportsCifte = supportsCifte
        self.game = game
        self.onSave = onSave
        _state = State(
            initialValue: initialState ?? RoundEntryState(entrants: entrants, supportsCifte: supportsCifte)
        )
    }

    private var entryTitle: String {
        neverLaidDownValue != nil ? "Count everyone\u{2019}s tiles" : "Count the cards left"
    }

    /// Çifte's asymmetry means no one sentence describes what a Round is about
    /// to score, so once a modifier is on the hint points at the rows, where
    /// each Entrant's own multiplier is spelled out.
    private var entryHint: String {
        state.hasModifiers
            ? "Each row shows what it\u{2019}ll score."
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
                let previews = state.previews()
                VStack(spacing: 7) {
                    ForEach(entrants) { entrant in
                        EntryRow(
                            entrant: entrant,
                            badgeIndex: badgeIndex(for: entrant.id),
                            isActive: state.activeEntrantID == entrant.id,
                            total: totals[entrant.id] ?? 0,
                            enteredValue: state.enteredValue(for: entrant.id),
                            preview: previews[entrant.id],
                            roleNote: roleNote(for: entrant.id)
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
            // Gated on the state's own flag, not the view's: those two can
            // only disagree if a seeded state says otherwise, and the one that
            // decides what gets recorded should decide what gets shown.
            if state.supportsCifte {
                EntryChip(label: "\u{c7}ifte", isOn: state.isActiveCifteCaller) {
                    state.toggleCifteForActive()
                }
            }
            EntryChip(label: game.okeyAtmakLabel, isOn: state.isActiveOkeyAtan) {
                state.toggleOkeyAtanForActive()
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

    /// What this row is marked as, for its meta line — so the record of who
    /// called is legible from the rows themselves and not only from whichever
    /// chip happens to be lit for the active row. The labels are the view's
    /// business; which rows carry the marks is the state's.
    private func roleNote(for id: Entrant.ID) -> String? {
        var parts: [String] = []
        if state.isCifteCaller(id) { parts.append("\u{c7}ifte") }
        if state.isOkeyAtan(id) { parts.append(game.okeyAtmakLabel) }
        return parts.isEmpty ? nil : parts.joined(separator: " \u{b7} ")
    }

    private func badgeIndex(for id: Entrant.ID) -> Int {
        badgeIndices[id] ?? 0
    }

    private func save() {
        guard state.isReadyToSave else { return }
        // Raw counts plus the facts of who did what — the Engine derives every
        // multiplier from them (`docs/adr/0005`).
        onSave(state.rawDeltas, state.cifteCallers, state.okeyAtanID)
    }
}

/// One Entry-screen row: dot badge, name, a meta line carrying the current
/// total, whatever modifiers this Entrant is marked with and what their value
/// will actually score, and the entered value — highlighted when active.
private struct EntryRow: View {
    let entrant: Entrant
    let badgeIndex: Int
    let isActive: Bool
    let total: Int
    let enteredValue: Int?
    /// What this Entrant's value will actually score and the multiplier that
    /// gets it there, or `nil` when nothing scales it.
    let preview: RoundEntryState.ScaledPreview?
    /// This Entrant's modifiers, already labelled for the Match's Game.
    let roleNote: String?
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
                        .foregroundStyle(isMarked ? theme.accent2 : theme.ink.opacity(0.42))
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

    private var isMarked: Bool { roleNote != nil || preview != nil }

    /// `now 34` on its own, growing to `now 34   Çifte   ×4 → 136` as the
    /// Round's modifiers reach this Entrant.
    private var metaText: String {
        var parts = ["now \(total)"]
        if let roleNote { parts.append(roleNote) }
        if let preview {
            parts.append("\u{d7}\(preview.multiplier) \u{2192} \(preview.value)")
        }
        return parts.joined(separator: "   ")
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
        badgeIndices: [a.id: 0, b.id: 1],
        game: .gonga
    ) { _, _, _ in }
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
    ) { _, _, _ in }
    .themed()
}
