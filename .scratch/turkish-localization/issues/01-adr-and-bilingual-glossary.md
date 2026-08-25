# 01 — ADR and bilingual glossary

**What to build:** A developer opening the repo can read why a Turkish-domain app has an English source language, and can look up the canonical Turkish term for any domain concept next to its English counterpart. Nothing user-visible ships.

This lands first because the Turkish glossary is the least-verified part of the design — it was proposed from game convention rather than derived from the codebase. It is free to change now and expensive to change once the catalog is keyed against it.

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

- [ ] An ADR records the source-language decision and the Domain-seam decision together, as one decision with two halves: English stays the development language with source text as keys, and display strings leave the Domain layer. It states the alternatives considered (Turkish as development language; abstract keys with neither language privileged) and why they were rejected, and names the accepted cost — calque risk in the Turkish column, managed by treating Turkish as copywriting rather than translation.
- [ ] The ADR notes that revisiting the source-language decision is the lever if the Turkish build ever starts reading as translated rather than written.
- [ ] No ADR is written for the String Catalog choice itself — it is the obvious default at this deployment target and no future reader will wonder about it.
- [ ] `CONTEXT.md` gains a Turkish term alongside each existing English term: Game/Oyun, Match/Parti, Round/El, Out/Yandı, Rejoin/Yeniden gir, Archived/Arşiv, Leader/Önde, Gap/Fark, Room left/Kalan, Rounds left/Kalan el.
- [ ] `CONTEXT.md` records that **Entrant deliberately has no Turkish UI term** — English needs the umbrella because Entrant spans player-and-team, but a Match is never mixed since the Variant fixes the mode, so the concrete kind (Oyuncu or Takım) is always known at render time. "Entrant" survives as an English-only code and domain word.
- [ ] `CONTEXT.md` records that Gösterge and Çifte remain untranslated, consistent with how it already describes them, and adds Sıra, Gonga, Okey and the bare Variant numbers to the same untranslated set.
- [ ] `CONTEXT.md` stays a glossary — no implementation detail, no catalog mechanics, no delivery plan.
- [ ] The maintainer has reviewed the Turkish terms with a native ear before this merges. `Parti`, `Yandı` and `Yeniden gir` in particular are flagged for that review.
