# 07 — Bad data never blocks launch

**What to build:** Sıra opens even when its stored data cannot be read, and nothing it fails to understand is ever destroyed. A player whose store is corrupt gets a working, empty app rather than one that won't start, and their old data is still on the device.

Demoable by corrupting the store by hand and launching.

**Blocked by:** 06

**Status:** ready-for-agent

- [ ] The container is built explicitly rather than through the convenience that crashes the app on failure
- [ ] A store that cannot be opened is moved aside under a timestamped name and a fresh one opened; the app launches normally
- [ ] Data that could not be read is never deleted — after recovery it is still present under its moved-aside name
- [ ] There is no silent in-memory fallback: the app must never look like it is working while saving nothing
- [ ] A stored Match naming a Variant id that resolves to nothing is skipped, and its stored data is left untouched
- [ ] Skipping one such Match leaves every other Match loading and scoring normally
- [ ] Tests cover both recovery paths: an unopenable store yields a working empty store with the old data still present, and an unknown Variant id is skipped with its data still on disk
