# 06 — Catalog completeness guard (optional)

**What to build:** A developer who adds a user-facing string in some future feature and forgets to translate it gets a failing test, rather than shipping English to Turkish users without noticing.

This is the guard that makes the draft-then-review copy workflow safe. It is marked **optional** — it is a genuinely new test seam, and the maintainer may prefer to carry the risk rather than the seam.

**It must land last.** If this guard is added when the catalog is created, it fails immediately for every screen not yet translated. It is only satisfiable once every string has a Turkish value, which is why it is blocked by the translation work rather than bundled with the infrastructure.

**Blocked by:** 05.

**Status:** ready-for-agent

- [ ] A test reads the String Catalog and fails if any key lacks a Turkish value, or has one still in an untranslated or stale state.
- [ ] The failure message names the offending keys, so the fix is obvious without opening the catalog editor.
- [ ] Any key that is deliberately identical across both languages — Sıra, Gonga, Okey, Gösterge, Çifte, the bare Variant numbers — passes rather than being reported as missing. Deliberate non-translation is distinguishable from forgotten translation.
- [ ] The test asserts catalog completeness only. It does not assert that a particular key exists, that a particular string has particular content, or that a particular formatter was used — those are implementation details, and this feature's other tests already assert what a user would see.
- [ ] The test runs in the existing test target alongside the rest of `siraTests`, with no new dependency.
