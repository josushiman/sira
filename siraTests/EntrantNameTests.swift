import XCTest
@testable import sira

/// The name validator, exercised as the pure function it is: a candidate and
/// the Entrants already in the Match, with no Match, store or view involved —
/// the same way `VariantParameterTests` drives its struct.
final class EntrantNameTests: XCTestCase {

    private func entrant(_ name: String, seat: Int = 0) -> Entrant {
        Entrant(name: name).withSequence(seat)
    }

    // MARK: - Uniqueness within the Match

    func test_aNameNobodyElseHoldsIsAccepted() {
        let existing = [entrant("Ali", seat: 0), entrant("Veli", seat: 1)]

        let resolution = EntrantName("Cem", seat: 2, mode: .players).resolved(against: existing)

        XCTAssertEqual(resolution, .accepted("Cem"))
    }

    /// The rejection names the clash rather than reporting that one happened,
    /// so the player can fix it without guessing which of the names on screen
    /// the app objected to.
    func test_aNameAnotherEntrantHoldsIsRejectedAndNamesTheClash() {
        let existing = [entrant("Ali", seat: 0), entrant("Veli", seat: 1)]

        let resolution = EntrantName("Veli", seat: 2, mode: .players).resolved(against: existing)

        XCTAssertEqual(resolution, .duplicate("Veli"))
        XCTAssertNil(resolution.name)
        XCTAssertEqual(
            resolution.rejection,
            "Veli is already in this Match. Pick another name."
        )
    }

    /// The clash is reported under the name as it is already held, not as it
    /// was just typed — that is the one on screen for the player to look for.
    func test_theRejectionNamesTheHeldNameRatherThanTheTypedOne() {
        let existing = [entrant("Ali", seat: 0)]

        let resolution = EntrantName("ali", seat: 1, mode: .players).resolved(against: existing)

        XCTAssertEqual(resolution, .duplicate("Ali"))
    }

    // MARK: - Turkish folding

    /// `İ` folds to `i` in Turkish, so `ALİ` and `ali` are the same name.
    func test_dottedCapitalIFoldsToDottedLowercaseI() {
        let existing = [entrant("ali", seat: 0)]

        let resolution = EntrantName("ALİ", seat: 1, mode: .players).resolved(against: existing)

        XCTAssertEqual(resolution, .duplicate("ali"))
    }

    /// `I` folds to `ı` in Turkish, so `ALI` and `alı` are the same name.
    func test_dotlessCapitalIFoldsToDotlessLowercaseI() {
        let existing = [entrant("alı", seat: 0)]

        let resolution = EntrantName("ALI", seat: 1, mode: .players).resolved(against: existing)

        XCTAssertEqual(resolution, .duplicate("alı"))
    }

    /// The case the pinned locale exists for. `ALI` lowercases to `ali` under
    /// the default folding and to `alı` under Turkish, so an unpinned check
    /// would call these the same name and refuse a name a Turkish speaker
    /// reads as different.
    func test_dotlessCapitalIIsNotTheSameNameAsDottedLowercaseI() {
        let existing = [entrant("Ali", seat: 0)]

        let resolution = EntrantName("ALI", seat: 1, mode: .players).resolved(against: existing)

        XCTAssertEqual(resolution, .accepted("ALI"))
    }

    /// The folding is pinned to Turkish rather than inherited from the device,
    /// so a Turkish-speaking table gets the same answer on an English phone.
    ///
    /// What makes this an assertion rather than a restatement is the host it
    /// runs on: on any non-Turkish host, `Locale.current` folds `I` to `i`, so
    /// the Turkish answer below can only come from a locale the code named
    /// itself. A Turkish host cannot tell the two apart — both foldings agree
    /// there — so it is skipped rather than allowed to pass for no reason.
    func test_foldingIsPinnedToTurkishRatherThanTheDevicesOwnLocale() throws {
        try XCTSkipIf(
            Locale.current.language.languageCode?.identifier == "tr",
            "A Turkish host folds this way anyway, so it cannot tell a pinned locale from an inherited one."
        )
        // The wrong answer this rule exists to avoid, stated rather than
        // implied — and the right one beside it.
        XCTAssertEqual("ALI".lowercased(with: Locale.current), "ali")
        XCTAssertEqual("ALI".lowercased(with: Locale(identifier: "tr_TR")), "alı")

        XCTAssertEqual(EntrantName.folded("ALI"), "alı")
        XCTAssertEqual(EntrantName.folded("ALİ"), "ali")
        XCTAssertEqual(
            EntrantName("ALI", seat: 1, mode: .players).resolved(against: [entrant("Ali", seat: 0)]),
            .accepted("ALI")
        )
    }

    // MARK: - Trimming

    func test_surroundingWhitespaceDoesNotMakeADistinctName() {
        let existing = [entrant("Ali", seat: 0)]

        let resolution = EntrantName("  Ali  ", seat: 1, mode: .players).resolved(against: existing)

        XCTAssertEqual(resolution, .duplicate("Ali"))
    }

    func test_anAcceptedNameIsStoredTrimmed() {
        let resolution = EntrantName("  Cem\n", seat: 0, mode: .players).resolved(against: [])

        XCTAssertEqual(resolution, .accepted("Cem"))
    }

    /// A name already held with whitespace around it — nothing stores one
    /// today, but a Match made before the trim did — is compared trimmed too,
    /// so the check is symmetric.
    func test_aHeldNameIsComparedTrimmedAsWell() {
        let existing = [entrant(" Ali ", seat: 0)]

        let resolution = EntrantName("Ali", seat: 1, mode: .players).resolved(against: existing)

        XCTAssertEqual(resolution, .duplicate(" Ali "))
    }

    // MARK: - Renaming

    /// Re-saving an Entrant under the name they already hold is a no-op, not
    /// a clash with themselves.
    func test_anEntrantMayBeResavedUnderTheirOwnName() {
        let ali = entrant("Ali", seat: 0)
        let existing = [ali, entrant("Veli", seat: 1)]

        let resolution = EntrantName("Ali", seat: 0, mode: .players, renaming: ali.id)
            .resolved(against: existing)

        XCTAssertEqual(resolution, .accepted("Ali"))
    }

    func test_renamingAnEntrantOntoSomeoneElsesNameIsStillRejected() {
        let ali = entrant("Ali", seat: 0)
        let existing = [ali, entrant("Veli", seat: 1)]

        let resolution = EntrantName("Veli", seat: 0, mode: .players, renaming: ali.id)
            .resolved(against: existing)

        XCTAssertEqual(resolution, .duplicate("Veli"))
    }

    // MARK: - Legacy duplicates

    /// A Match started before this rule can hold two Alis. Validation runs on
    /// the candidate at the point of editing and never as a sweep over stored
    /// data, so that Match stays openable and scorable.
    func test_aMatchAlreadyHoldingDuplicatesStillAcceptsAnUnrelatedName() {
        let existing = [entrant("Ali", seat: 0), entrant("Ali", seat: 1)]

        let resolution = EntrantName("Cem", seat: 2, mode: .players).resolved(against: existing)

        XCTAssertEqual(resolution, .accepted("Cem"))
    }

    /// Editing either of those two Alis is where the clash has to be resolved:
    /// the Entrant being renamed is excluded from the check, but their
    /// namesake is not.
    func test_editingOneOfTwoIdenticalEntrantsMustResolveTheClash() {
        let first = entrant("Ali", seat: 0)
        let existing = [first, entrant("Ali", seat: 1)]

        let resolution = EntrantName("Ali", seat: 0, mode: .players, renaming: first.id)
            .resolved(against: existing)

        XCTAssertEqual(resolution, .duplicate("Ali"))
    }

    // MARK: - The seat-derived fallback

    /// The name a candidate becomes before anyone is asked whether it clashes.
    /// Setup takes this directly — it is naming Entrants who are not in a
    /// Match yet — so it has to produce the same name a blank field produces
    /// in the rename sheet.
    func test_materialisingANameTrimsItOrFallsBackToTheSeat() {
        XCTAssertEqual(EntrantName("  Cem ", seat: 0, mode: .players).materialised, "Cem")
        XCTAssertEqual(EntrantName("", seat: 2, mode: .players).materialised, "Player 3")
        XCTAssertEqual(EntrantName("   ", seat: 1, mode: .teams).materialised, "Team 2")
    }

    /// Numbered from the seat rather than from a position in a list: seats are
    /// unique and never renumbered, so two Entrants who both left the field
    /// blank can never land on the same fallback.
    func test_anEmptyNameMaterialisesTheSeatDerivedFallback() {
        let resolution = EntrantName("", seat: 4, mode: .players).resolved(against: [])

        XCTAssertEqual(resolution, .accepted("Player 5"))
    }

    func test_theFallbackTakesTheMatchesEntrantNoun() {
        let resolution = EntrantName("", seat: 1, mode: .teams).resolved(against: [])

        XCTAssertEqual(resolution, .accepted("Team 2"))
    }

    func test_aWhitespaceOnlyNameMaterialisesTheFallbackToo() {
        let resolution = EntrantName("   ", seat: 0, mode: .players).resolved(against: [])

        XCTAssertEqual(resolution, .accepted("Player 1"))
    }

    /// The fallback is baked into the name at creation, so nothing afterwards
    /// tells it from a hand-typed one — and two Entrants rendering identically
    /// in Standings is the exact outcome the uniqueness rule exists to
    /// prevent.
    func test_aHandTypedNameCollidingWithAnExistingFallbackIsRejected() {
        let existing = [entrant("Ali", seat: 0), entrant("Player 2", seat: 1)]

        let resolution = EntrantName("player 2", seat: 2, mode: .players).resolved(against: existing)

        XCTAssertEqual(resolution, .duplicate("Player 2"))
    }

    /// And the fallback itself is not exempt: leaving the field blank on a
    /// seat whose fallback someone has already typed by hand clashes like any
    /// other name.
    func test_theFallbackIsNotExemptFromUniqueness() {
        let existing = [entrant("Player 3", seat: 0)]

        let resolution = EntrantName("", seat: 2, mode: .players).resolved(against: existing)

        XCTAssertEqual(resolution, .duplicate("Player 3"))
    }
}
