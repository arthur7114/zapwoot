---
target: kanban board
total_score: 25
p0_count: 1
p1_count: 2
timestamp: 2026-07-21T13-08-08Z
slug: app-javascript-dashboard-routes-dashboard-kanban
---
Method: dual-agent (A: design-review · B: detector+browser) · ⚠️ Browser visualization unavailable (localhost:3001 origin gate + Chrome extension offline) — no live overlay; review is source + deterministic detector only.

## Design Health Score

| # | Heuristic | Score | Key Issue |
|---|-----------|-------|-----------|
| 1 | Visibility of System Status | 3 | Loading/count/status dots good; a drag-move gives no in-flight/pending feedback. |
| 2 | Match System / Real World | 3 | Funnel-as-columns is the right model; status-dot colors have no legend. |
| 3 | User Control and Freedom | 2 | Move is fire-and-forget: no undo, no drag-cancel, no non-drag move path. |
| 4 | Consistency and Standards | 3 | Two near-duplicate add-stage forms; `!w-40`/`!mb-0` overrides fight base styles. |
| 5 | Error Prevention | 2 | Nothing prevents a wrong-stage drop; no confirm/undo. Empty-title add is guarded. |
| 6 | Recognition Rather Than Recall | 3 | Board is visible; status-dot semantics must be recalled (no key). |
| 7 | Flexibility and Efficiency | 1 | No keyboard move, no bulk-select, no shortcuts, no quick-add. Worst axis. |
| 8 | Aesthetic and Minimalist Design | 4 | On-brief: flat bordered surfaces, one accent, no ornament. |
| 9 | Error Recovery | 2 | Move-failure toast fires after the card already moved; rollback not evident. |
| 10 | Help and Documentation | 2 | Good empty-state copy, but no draggable hint, no legend, no funnel onboarding. |
| **Total** | | **25/40** | **Acceptable — visual layer ~30+, interaction layer drags it into the mid-20s** |

## Anti-Patterns Verdict

**LLM assessment:** Not slop. Reads as a competent, restrained board a Linear/Notion-fluent user would trust. No side-stripe borders (stage identity is a color dot), no gradient text, no hero, no eyebrows, no needless modal (add-stage is inline — the right call). Cards carry real information scent, not filler. The one thing keeping it below "crafted" is not cosmetic: the board *looks* trustworthy but the primary verb (move a lead between stages) is drag-only with no keyboard/menu path.

**Deterministic scan:** `detect.mjs` over the kanban markup dir → `[]`, exit 0, **0 findings**. Verified meaningful (not a no-op): the detector parses `.vue`, each file independently returned `[]`, and a synthetic bounce-easing/overused-font `.vue` correctly produced 2 findings + exit 2. Scope caveat: the detector reads template/inline markup tells only — it does not evaluate compiled Tailwind visual output (that's Assessment A's remit). LLM and detector agree: no markup-level anti-patterns.

**Visual overlays:** Unavailable. Both browser surfaces refused (in-app pane origin gate on `localhost:3001` won't clear; Chrome extension not connected). No user-visible overlay exists; no live/injected detector evidence.

## Overall Impression

The visual layer is genuinely on-brief — restrained, dense, WhatsApp-familiar, zero ornament. But craft was spent on the wrong moment: the rare, low-stakes add-stage flow got loving autofocus-inline treatment, while the money-critical, 100×-a-day action (moving a lead) has the least feedback, no undo, and no keyboard path. Biggest opportunity: make "move a lead" universally operable and reassuring.

## What's Working

1. **Inline-form-over-modal discipline.** Both add-stage entry points avoid a modal, autofocus the input (`nextTick`), submit-on-enter, guard empty/whitespace titles, and expose loading/disabled state. Exactly the restrained, fast interaction the north star demands.
2. **Card keyboard-open + focus scaffolding is real.** `role="button"`, `tabindex="0"`, `keydown.enter/space.prevent`, and a proper `focus-visible:outline-2 offset-2 outline-n-brand` ring. Someone thought about keyboard entry and AA focus visibility.
3. **Palette contract respected.** Status uses semantic tokens; green reserved for hover/active/brand; arbitrary user stage color quarantined to the dot with a brand fallback (`stage.color || var(--color-n-brand)`).

## Priority Issues

**[P0] Keyboard users cannot move a card between stages.** Movement is exclusively `vuedraggable` drag; cards are keyboard-openable but not keyboard-movable, no context menu / "move to stage" dropdown / arrow-key shift. *Why:* moving a lead is the board's primary verb; WCAG 2.1.1 requires keyboard operability of core functions. A keyboard/AT/trackpad-averse user cannot do the main job. *Fix:* per-card overflow (kebab) or context menu with "Mover para → [stages]" emitting the existing `move` event; bonus `Ctrl/Cmd+←/→` on a focused card. *Command:* `harden`.

**[P1] Optimistic move has no in-flight or rollback feedback.** `onChange` emits `move`; `onMove` only toasts on catch, but `localConversations` already moved the card — on failure it stays visually in the wrong column. *Why:* silent state divergence on the money-critical action erodes trust. *Fix:* revert local list (or refetch) on failure; subtle confirmation on success; short-lived "Desfazer/Undo" on the toast. *Command:* `harden`.

**[P1] Column-header double-emphasis (the count badge overshoots).** The bolder pass pushed the count to `text-sm font-medium tabular-nums text-n-slate-12` on a filled `bg-n-slate-3` pill — two promotions stacked (darkest ink *and* a filled container), so it competes head-to-head with the `.text-heading-3` title. *Why:* two co-equal focal points per column × N columns multiplies scan ping-pong. *Fix:* demote one dimension — keep the pill but drop the number to `slate-11`, or keep slate-12 and drop the pill to a bare number. Let the title win the header. *Command:* `quieter` (or `typeset`).

**[P2] Empty column reads as an ambiguous void.** An empty stage renders a bare `min-h-[80px]` drop area with no text — empty vs broken vs loading is indistinguishable, and it wastes the perfect spot to teach drag. *Fix:* muted centered hint ("Nenhuma conversa" + faint "arraste para cá"), `text-n-slate-10`. *Command:* `onboard`.

**[P2] Duplicated add-stage form markup.** The add-stage `<form>` is copy-pasted in the empty state and the column loop, differing only in width classes; `!important` overrides signal fighting base select/input styles. *Fix:* extract an `AddStageForm` child with a layout prop; use a DS field wrapper so the `!` overrides disappear. *Command:* `distill`.

## Persona Red Flags

**Sam (a11y / keyboard / contrast) — most damaged.** Cannot move a card at all (P0). `text-n-slate-10` on the `#id` and the "unassigned" label is a likely AA fail for normal-size text on a white card — both are real info, should be `slate-11`+. Arbitrary user stage color dot has no contrast guarantee and is the *only* stage-identity cue. Status dots convey open/pending/snoozed by color alone, no legend (SC 1.4.1).

**Alex (power user) — efficiency 1/4.** No shortcuts, no bulk-select/bulk-move, no quick-add-card, no non-drag move. On a multi-stage board an agent triaging 100 leads/day has zero accelerators; every move is a mouse drag across a horizontally scrolling board — slow and error-prone when the target column is off-screen.

**Riley (stress / edge cases).** Move-failure strands the card in the wrong column (P1). Horizontal scroll + off-screen drop target has no auto-scroll evidence — a drag dead-zone. Long stage title + loud count pill will crowd the header. Empty-column ambiguity (P2).

## Minor Observations

- Filter selects have `aria-label`s (good) but reuse the "All X" option text, so a screen reader reads "All inboxes, combobox, All inboxes" — name the control ("Filtrar por inbox") distinctly from its default option.
- Cards' only draggable signal is `cursor-grab`; pair with the empty-column hint to teach the affordance.
- `firstStageId` buckets null-stage conversations into the first stage; fine, but `undefined` if `stages` is briefly empty — verify no flicker.
- `min-h-[80px]` is the one arbitrary magic number; consider a token.
- Status-dot color map has a redundant `|| 'bg-n-slate-9'` fallback identical to the `snoozed` value.
- `text-heading-1` page title is defensible as the route ceiling, but confirm it doesn't dwarf the board it labels.

## Questions to Consider

1. If a keyboard user can open a card but not move it, is this a kanban board — or a read-only funnel visualization with drag as a mouse-only Easter egg?
2. You promoted the count to the darkest ink in the product (slate-12) — is the number of leads in a stage really more important than which stage it is? The emphasis and the top-right muted-pill placement disagree.
3. For a sales team whose commission rides on funnel accuracy, why does the most consequential action (moving money-bearing leads) have the least feedback and no undo, while adding a stage (rare, low-stakes) got the autofocus-inline-form love?
