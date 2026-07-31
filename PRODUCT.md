# Product

## Register

product

## Users

Support agents and admins on a commercial/sales team using this Chatwoot fork day-to-day inside the dashboard (conversations, kanban funnel, settings). Their context: fast-paced WhatsApp-driven customer contact and lead follow-up, often on a single screen for long stretches, switching between conversations, funnel stages, and quick replies. The job to be done on any given screen is almost always one of: reply to a customer fast, move a lead through the funnel, or configure the small set of entities (pipeline stages, canned responses, scheduled messages) that make the first two fast.

## Product Purpose

Reskin and extend the open-source Chatwoot dashboard so it feels like WhatsApp Web for commercial support: a customizable kanban funnel over conversations, scheduled messages, quick replies (canned responses), and a WhatsApp-styled chat surface (green theme, wallpaper, rounded bubbles, familiar ticks). Success looks like an agent never noticing they're using "enterprise support software" — the tool should disappear into the same muscle memory as WhatsApp itself, while still running on Chatwoot's existing data model and permissions.

## Brand Personality

Leve, rápido, familiar (light, fast, familiar) — like WhatsApp itself: minimal chrome, immediate feedback, no ceremony between "I have a message" and "it's sent." Explicitly NOT dense, generic enterprise SaaS — the default upstream Chatwoot look (heavier chrome, more enterprise-neutral palette) is the anti-reference. Every new surface should read as an extension of WhatsApp's visual language, not a bolt-on admin panel.

## Anti-references

- The stock/default Chatwoot dashboard aesthetic (neutral blue, dense settings chrome) — this fork deliberately departs from it toward WhatsApp's green + wallpaper + rounded-bubble language.
- Generic SaaS dashboard tropes applied without reason (over-built empty states, unnecessary confirmation ceremony, exhaustive configuration screens for a two-field entity).

## Design Principles

- **WhatsApp familiarity over enterprise convention.** When a Chatwoot-default pattern and a WhatsApp-native pattern both work, prefer the WhatsApp one (green outgoing bubbles, rounded corners, tinted header bar, wallpaper background, check/double-check ticks).
- **Reuse before inventing.** New features are built by mirroring the closest existing Chatwoot pattern (Labels settings page, ApiClient conventions, Conversations::FilterService) rather than introducing parallel abstractions. Consistency with the host app's existing conventions is a feature, not a compromise.
- **Simple over exhaustive.** Scope new features (e.g. the kanban funnel) to what's genuinely useful today — one funnel per account, automatic sort, no manual card ordering — rather than building for hypothetical future flexibility (multiple boards, complex permission matrices) that hasn't been asked for.
- **Independence from core mechanics.** New product concepts (e.g. a pipeline stage) stay orthogonal to Chatwoot's existing state machines (conversation status) rather than overloading or coupling to them, so the core product's SLA/automation/reporting logic is never put at risk.
- **Portuguese-first for this fork.** UI strings ship in pt_BR alongside English from the same commit — this fork's primary users are Portuguese-speaking, so translations are not deferred to the upstream Crowdin flow.

## Accessibility & Inclusion

Standard WCAG AA, matching the bar the upstream Chatwoot project already targets. No additional project-specific accessibility requirements beyond that at this time.
