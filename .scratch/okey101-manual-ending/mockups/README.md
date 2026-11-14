# Approved Okey 101 screen mockups

These references were approved in the planning conversation. [Open the interactive flow](flow.html) to explore the picker, Setup, live Play, End confirmation, final result and Home history. Use ordinary actions to follow End → review → Resume; the Screen selector jumps directly between the illustrated states.

| Reference | Relevant tickets |
| --- | --- |
| [Variant picker, Paper](variant-picker-paper.png) | 02 |
| [Setup, Paper](setup-paper.png) | 02 |
| [Live Play, Paper](live-play-paper.png) | 02, 04 |
| [Zero-Round eligibility, Paper](zero-rounds-paper.png) | 02, 03 |
| [End confirmation, Paper](end-confirmation-paper.png) | 03 |
| [Final result and Resume, Paper](final-result-paper.png) | 01 (destination reference), 03, 04 |
| [Tied result, Felt](tied-result-felt.png) | 03, 04 |
| [Home history, Paper](home-history-paper.png) | 01 (destination reference), 03, 04 |
| [Compact 104-Round Scoresheet, Paper](long-scoresheet-paper.png) | 05 |

Preserve the incumbent Paper/Felt palette, Bricolage Grotesque and IBM Plex Mono, stable Seat badges, and native navigation and touch behavior. The browser mockups establish hierarchy, copy and interactions; the implementation remains native and must respect Dynamic Type and Reduce Motion. Illustrative names and scores are sample content, not new scoring rules or required production fixtures.

Home opens with its result card fully readable. Swiping or revealing its action exposes Resume; the whole main card opens read-only review. In long history, player headers stay visible and “Total” stays on one line. These are the reviewed fixes, not optional alternate designs.

The screenshots show the complete feature. Ticket-specific scope notes identify controls supplied by later tickets, so preparatory work need not implement future actions. Simplified supporting score-entry interactions in the preview do not authorize a Round-entry redesign.

The original mockup passed 27 browser checks and an independent finish review with no remaining material findings. Those checks validate the mockup only; native implementation still needs the tests and verification described by the spec and each ticket.
