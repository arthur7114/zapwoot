---
name: Chatwoot WhatsApp Fork
description: A WhatsApp-familiar reskin of the Chatwoot support dashboard — green, wallpapered, unshowy.
colors:
  whatsapp-green: "#008069"
  outgoing-mint: "#D9FDD3"
  header-whisper-mint: "#F3FBF9"
  bot-lavender: "#E6E7FF"
  chat-wallpaper-tan: "#E5DDD5"
  surface-white: "#FEFEFE"
  ink-slate: "#1C2024"
  ink-slate-muted: "#60646C"
  border-hairline: "#EAEAEA"
  warning-amber: "#FFC53D"
  error-ruby: "#E54666"
typography:
  display:
    fontFamily: "Inter, -apple-system, system-ui, sans-serif"
    fontSize: "1.125rem"
    fontWeight: 520
    lineHeight: "24px"
    letterSpacing: "-0.27px"
  headline:
    fontFamily: "Inter, -apple-system, system-ui, sans-serif"
    fontSize: "1rem"
    fontWeight: 500
    lineHeight: "24px"
    letterSpacing: "-0.27px"
  title:
    fontFamily: "Inter, -apple-system, system-ui, sans-serif"
    fontSize: "0.875rem"
    fontWeight: 500
    lineHeight: "21px"
    letterSpacing: "-0.27px"
  body:
    fontFamily: "Inter, -apple-system, system-ui, sans-serif"
    fontSize: "0.875rem"
    fontWeight: 420
    lineHeight: "21px"
    letterSpacing: "-0.28px"
  label:
    fontFamily: "Inter, -apple-system, system-ui, sans-serif"
    fontSize: "0.75rem"
    fontWeight: 440
    lineHeight: "16px"
    letterSpacing: "-0.24px"
rounded:
  sm: "6px"
  md: "8px"
  lg: "12px"
  xl: "16px"
  full: "9999px"
spacing:
  xs: "4px"
  sm: "8px"
  md: "16px"
  lg: "24px"
components:
  button-primary:
    backgroundColor: "{colors.whatsapp-green}"
    textColor: "#FFFFFF"
    rounded: "{rounded.md}"
    padding: "0 16px"
    height: "40px"
  button-primary-hover:
    backgroundColor: "{colors.whatsapp-green}"
    textColor: "#FFFFFF"
  button-faded:
    backgroundColor: "{colors.whatsapp-green}"
    textColor: "{colors.whatsapp-green}"
    rounded: "{rounded.md}"
    padding: "0 16px"
    height: "40px"
  message-bubble-outgoing:
    backgroundColor: "{colors.outgoing-mint}"
    textColor: "{colors.ink-slate}"
    rounded: "{rounded.xl}"
    padding: "12px 16px"
  message-bubble-incoming:
    backgroundColor: "#F0F0F1"
    textColor: "{colors.ink-slate}"
    rounded: "{rounded.xl}"
    padding: "12px 16px"
  conversation-header:
    backgroundColor: "{colors.header-whisper-mint}"
    textColor: "{colors.ink-slate}"
    height: "48px"
---

# Design System: Chatwoot WhatsApp Fork

## 1. Overview

**Creative North Star: "The WhatsApp Familiar"**

Every decision in this system is tested against one question: *would this feel native inside WhatsApp Web?* This is a Chatwoot fork built for a commercial support team, and the entire reskin exists to erase the feeling of "enterprise support software." The base app (Rails + Vue, radix-style token scales, a `components-next/` component library) stays untouched in structure — routing, state management, permissions all remain pure Chatwoot. What changes is surface: a green accent lifted directly from WhatsApp's own palette, a tan-speckled chat wallpaper behind every conversation, rounded message bubbles with a WhatsApp-shaped tail corner, and delivery ticks that match WhatsApp's own gray-single / gray-double / blue-double-read sequence exactly.

This is explicitly **not** a marketing surface — it's a product register, and the system optimizes for density, clarity of state, and fast repeated actions (reply, move a lead through the funnel, fire off a quick reply) over visual flourish. The system rejects the stock Chatwoot look (neutral blue, denser chrome, more enterprise-neutral palette) and rejects generic SaaS-dashboard tropes — over-built empty states, unnecessary confirmation ceremony, exhaustive configuration UI for what is functionally a two-field entity (a kanban stage is just a name and a color).

**Key Characteristics:**
- Green (`#008069`) as the single brand accent, reserved for primary actions and the outgoing-message state — never sprayed across the whole UI.
- A warm, textured wallpaper (`#E5DDD5`) behind every message thread — the one deliberately decorative surface in an otherwise restrained system.
- Flat, bordered surfaces at rest; shadow appears only when something floats above the page (dropdown, modal, popover).
- Typography is a tight, numeric weight scale (420/440/460/520/620) rather than the usual 400/500/600/700 jumps — built for legibility at small sizes across a dense dashboard, not for dramatic display type.
- No hero sections, no marketing scale-up. The largest heading in the entire system (`text-heading-1`, 18px/520) is a page title, not a headline.

## 2. Colors

A restrained palette: one committed green accent, a small set of role-specific neutrals, and the semantic trio (amber/ruby/lavender) inherited from Chatwoot's existing status vocabulary. The wallpaper tan is the only place warmth is allowed to be decorative rather than functional.

### Primary
- **WhatsApp Green** (`#008069`): the brand accent. Solid buttons, active nav state, the sidebar's collapsible-toggle hover ring, links. Used sparingly — this is a product surface, not a canvas for the accent.
- **Outgoing Mint** (`#D9FDD3`): the background of every outgoing (agent) message bubble. This is WhatsApp's own outgoing-bubble green, reused verbatim rather than approximated.

### Secondary
- **Header Whisper Mint** (`#F3FBF9`): the conversation header's background tint — a barely-there wash that separates the header bar from the wallpapered message list below without introducing a second saturated color.

### Tertiary
- **Bot Lavender** (`#E6E7FF`): reserved for bot/automation and template message bubbles — the one place the system steps outside the green/neutral story, precisely because those messages are not human-authored and should read as visually distinct.

### Neutral
- **Surface White** (`#FEFEFE`): the default app background outside the chat surface (settings pages, sidebars, panels).
- **Ink Slate** (`#1C2024`): primary text color, body copy and headings alike.
- **Ink Slate Muted** (`#60646C`): secondary text — timestamps, helper copy, disabled labels.
- **Border Hairline** (`#EAEAEA`): the default 1px border/outline color for cards, inputs, and dividers in a flat, bordered-not-shadowed system.
- **Chat Wallpaper Tan** (`#E5DDD5`): the message-list background, rendered as a repeating dotted SVG pattern, not a flat fill.
- **Warning Amber** (`#FFC53D`) / **Error Ruby** (`#E54666`): inherited Chatwoot semantic colors for private notes / warnings and destructive or failed states respectively. Not part of the WhatsApp reskin — kept as-is because they're functional, not decorative.

### Named Rules
**The One Accent Rule.** WhatsApp Green is the only saturated color used for interactive intent (buttons, active states, links). Everything else — including the tertiary lavender and the wallpaper tan — is either semantic (status) or purely atmospheric (wallpaper). If a new screen wants a second "brand-feeling" color, that's a sign it should be reaching for green, not inventing one.

## 3. Typography

**Body & UI Font:** Inter (with `-apple-system, system-ui, BlinkMacSystemFont, "Segoe UI", Roboto` fallback stack)
**Rare Display Font:** InterDisplay — reserved for one-off celebratory moments (the Year in Review modal, onboarding feature cards). It is not part of the everyday hierarchy below.

**Character:** A single-family system built on fractional font weights (420/440/460/520/620) instead of the usual 400/500/600 jumps — the goal is legibility at 12-14px across a dense dashboard, not typographic drama. There is no "hero" scale; the largest role in the system is a page title.

### Hierarchy
- **Display** (weight 520, 18px / `text-heading-1`, line-height 24px, letter-spacing -0.27px): page titles and panel headers. The ceiling of the whole type scale.
- **Headline** (weight 500, 16px / `text-heading-2`, line-height 24px, letter-spacing -0.27px): section headings, card titles.
- **Title** (weight 500, 14px / `text-heading-3`, line-height 21px, letter-spacing -0.27px): card headings, breadcrumbs, subsections.
- **Body** (weight 420, 14px / `text-body-main`, line-height 21px, letter-spacing -0.28px): default paragraph and UI text. Body copy (`text-body-para`) uses the same size/weight with slightly looser letter-spacing (-0.21px) for longer text blocks.
- **Label** (weight 440, 12px / `text-label-small`, line-height 16px, letter-spacing -0.24px): footnotes, tags, badges, captions, timestamps.

Button text has its own two-step scale: `text-button` (14px, weight 460) and `text-button-small` (12px, weight 440) — distinct from Label so button copy always reads slightly heavier than a caption at the same size.

### Named Rules
**The No-Display Rule.** This is a product register: there is no marketing-scale display type anywhere in the system. If a screen wants a 32px+ headline, that's a sign it's drifted into brand register and needs a different set of rules.

## 4. Elevation

Flat by default. Surfaces (cards, list rows, the message list itself) are distinguished with a 1px border (`Border Hairline`, `#EAEAEA`) or a Tailwind `outline`, not a shadow. Shadow is reserved entirely for content that floats above the page in its own stacking context: dropdown menus, modals, popovers, tooltips. At rest, nothing in the dashboard casts a shadow.

### Shadow Vocabulary
- **Floating-sm** (`box-shadow: 0 4px 6px -1px rgb(0 0 0 / 0.1), 0 2px 4px -2px rgb(0 0 0 / 0.1)` — Tailwind `shadow-md`): the default for dropdowns and small popovers.
- **Floating-lg** (`box-shadow: 0 10px 15px -3px rgb(0 0 0 / 0.1), 0 4px 6px -4px rgb(0 0 0 / 0.1)` — Tailwind `shadow-lg`): modals and larger overlays.

### Named Rules
**The Grounded Rule.** If an element is part of the page's normal flow — even a card, even a message bubble — it does not get a shadow. Shadow is the visual signal that something has left the document flow to float above it; using it anywhere else dilutes that signal.

## 5. Components

Components are unshowy by design: efficient, quiet, built to cede visual weight to the content (a message, a conversation, a name) rather than to themselves.

### Buttons
- **Shape:** `rounded-md` (8px) at every size — the system's base control radius.
- **Sizes:** height scales in 8px steps — xs 24px, sm 32px, md 40px, lg 48px — with matching horizontal padding (8/12/16/20px).
- **Primary (solid):** `#008069` background, white text; hover/focus brighten the fill slightly rather than shifting hue.
- **Faded:** brand color at ~10% background opacity, brand color text; hover moves to ~20% opacity. This is the default secondary action style — more common in this system than a bordered "outline" button.
- **Outline / Ghost / Link:** outline uses a 1px brand-colored ring on a transparent fill; ghost drops the ring and shows a neutral hover wash; link is text-only with an underline on hover. All three exist per semantic color (blue/brand, ruby, amber, slate, teal), not just the primary.

### Cards / Containers
- **Corner Style:** `rounded-lg` (12px) for panels and popovers; `rounded-2xl` (16px) for message bubbles specifically — the one place the radius steps up, deliberately, to read as "bubble" rather than "panel."
- **Background:** `Surface White` (`#FEFEFE`) for panels; the message bubble colors described in Colors for chat content.
- **Shadow Strategy:** none at rest (see Elevation). A card sitting in the page flow is bordered, not lifted.
- **Border:** 1px `Border Hairline` (`#EAEAEA`), the default definition mechanism for any flat surface.

### Message Bubbles (signature component)
The one component that most carries the WhatsApp identity. Outgoing (agent) bubbles are mint (`#D9FDD3`), right-aligned; incoming (contact) bubbles are near-white gray (`bg-n-slate-4`), left-aligned. Both use `rounded-2xl` (16px) with one corner pulled down to `rounded-sm` (2px) on the side nearest the sender's own edge — the subtle "tail" cue that reads as bubble-with-direction rather than a generic rounded rectangle. Delivery status renders as a small (14px) tick icon inline with the timestamp: single gray check (sent), double gray check (delivered), double blue check `#53BDEB` (read) — WhatsApp's exact sequence, not a Chatwoot-invented equivalent.

### Inputs / Fields
- **Style:** `rounded-lg` (8px), a near-transparent-black background wash (`bg-n-alpha-black2`) rather than a pure white fill, with a 1px neutral outline that darkens slightly on hover.
- **Focus:** the outline switches to the brand green (`focus:outline-n-brand`) — the input's only use of the accent color.
- **Error:** outline switches to `Error Ruby`; disabled drops to 50% opacity with the neutral outline retained.

### Navigation
- **Style:** a narrow icon-rail-plus-label sidebar, collapsible via a hover-revealed chevron toggle at its resize edge. Active items get a filled brand-tinted background, not just a color change on the icon. Typography uses the same Title-weight (500, 14px) as elsewhere in the system — the nav doesn't get its own heavier type.

### Conversation Header (signature component)
Tinted with `Header Whisper Mint` (`#F3FBF9`) — a background wash distinct from both the panel white and the wallpapered chat surface below it, so the three-layer stack (header / message list / composer) reads as three tiers without needing borders between all of them.

## 6. Do's and Don'ts

### Do:
- **Do** use `#008069` (WhatsApp Green) as the only saturated accent for interactive intent — buttons, links, active nav state.
- **Do** keep outgoing bubbles at `#D9FDD3` and incoming bubbles neutral gray/white — the color is the direction cue, don't invert it or introduce a third bubble color for a normal message.
- **Do** use a 1px `Border Hairline` (`#EAEAEA`) or outline to define any surface at rest. That is the system's default elevation mechanism.
- **Do** reserve shadow (`shadow-md` / `shadow-lg`) exclusively for content that floats above the page in its own stacking context — dropdowns, modals, popovers, tooltips.
- **Do** use `rounded-2xl` (16px) specifically for message bubbles and `rounded-lg` (8px) for controls/panels — the radius jump is what makes a bubble read as a bubble.
- **Do** ship every new UI string in `pt_BR` alongside `en` in the same commit; this fork's primary users are Portuguese-speaking and translations are not deferred to Crowdin.

### Don't:
- **Don't** build toward the stock Chatwoot look (neutral blue, denser enterprise chrome) — that is this fork's explicit anti-reference. If a new screen defaults to Chatwoot's original blue instead of the green accent, that's regression, not a stylistic choice.
- **Don't** add shadow to anything sitting in normal page flow — cards, list rows, message bubbles. Shadow signals "floating," not "important."
- **Don't** introduce a marketing-scale display heading (32px+) anywhere in this dashboard. The type ceiling is `text-heading-1` at 18px/520 weight — this is a product register, not a landing page.
- **Don't** over-build empty states or configuration screens for genuinely small entities (a kanban stage is a name + a color; it doesn't need a wizard).
- **Don't** use `border-left`/`border-right` as a colored accent stripe on cards or list items — full borders, background tints, or leading icons instead.
- **Don't** use gradient text (`background-clip: text` with a gradient) anywhere — a single solid ink or brand color, with weight/size for emphasis.
