# Okey 101 ends by table decision

Okey 101 tables decide when to stop and may keep playing beyond any conventional Round count. Okey 101 therefore takes no Setup parameter, has no Round target or milestone, and uses the Lowest Total Win Condition: existing scoring and ties are preserved, but only an explicit End action declares the result. This supersedes [ADR 0008](0008-variants-carry-shape-matches-carry-values.md) only where it requires every Match to store exactly one Setup number; Gonga and Okey keep their parameters and automatic endings.

An Okey 101 Match's ending must be persisted rather than inferred from its Rounds. End requires at least one currently scored Round and both ends and archives the Match; those states remain distinct because a live Match may also be Archived. An Ended Match is read-only until Resume, which reopens and unarchives it with all scores preserved, rather than creating or Starting another Match. This favors an explicit, reversible result over implicit reopening when scores change.

Existing Okey 101 Matches that met their old Round target become Ended, retaining their prior archive visibility; unfinished Matches simply lose the target. Determine old completion before discarding the target during the V2 migration. Automatic archiving applies to new End actions, preserving the visibility of existing results when the app updates.

The agreed screen flow, implementation order and acceptance checks are recorded in the [feature plan](../../.scratch/okey101-manual-ending/spec.md). This session covers planning; app implementation has not started.
