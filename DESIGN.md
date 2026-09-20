---
name: Rejoice Greatly
description: The warm, unhurried front porch of the church — a Flutter app that helps members never miss a sermon or event.
colors:
  roasted-cocoa: "#633A02"
  candlelight-cream: "#FFF7EB"
  sanctuary-white: "#FFFFFF"
  ink: "#1A1A1A"
  weathered-wood: "#6B5C4D"
  warm-sand: "#E8DFD0"
  error-surface: "#FFF1EE"
  error-border: "#E1B0A9"
  error-ink: "#8A2C1F"
typography:
  display:
    fontFamily: "Source Serif 4"
    fontSize: "28"
    fontWeight: 600
    lineHeight: 1.15
    letterSpacing: "-0.3"
  headline:
    fontFamily: "Source Serif 4"
    fontSize: "20"
    fontWeight: 600
    lineHeight: 1.2
    letterSpacing: "-0.2"
  title:
    fontFamily: "Source Serif 4"
    fontSize: "17"
    fontWeight: 600
    lineHeight: 1.25
    letterSpacing: "0"
  body:
    fontFamily: "IBM Plex Sans"
    fontSize: "15"
    fontWeight: 400
    lineHeight: 1.45
    letterSpacing: "0"
  label:
    fontFamily: "IBM Plex Sans"
    fontSize: "13"
    fontWeight: 500
    lineHeight: 1.3
    letterSpacing: "0"
  eyebrow:
    fontFamily: "IBM Plex Mono"
    fontSize: "12"
    fontWeight: 500
    lineHeight: 1.2
    letterSpacing: "0.14em"
  data:
    fontFamily: "IBM Plex Mono"
    fontSize: "28"
    fontWeight: 600
    lineHeight: 1.2
    letterSpacing: "-0.5"
rounded:
  sm: "3px"
  md: "6px"
  lg: "8px"
spacing:
  xs: "4px"
  sm: "8px"
  md: "14px"
  lg: "20px"
  xl: "32px"
components:
  button-primary:
    backgroundColor: "{colors.roasted-cocoa}"
    textColor: "{colors.sanctuary-white}"
    rounded: "{rounded.md}"
    height: "52px"
  button-secondary:
    backgroundColor: "{colors.candlelight-cream}"
    textColor: "{colors.ink}"
    border: "1px solid {colors.warm-sand}"
    rounded: "{rounded.md}"
    height: "50px"
  card:
    backgroundColor: "{colors.candlelight-cream}"
    textColor: "{colors.ink}"
    border: "1px solid {colors.warm-sand}"
    rounded: "{rounded.lg}"
    padding: "14px"
  input:
    backgroundColor: "{colors.sanctuary-white}"
    textColor: "{colors.ink}"
    border: "1px solid {colors.warm-sand}"
    rounded: "{rounded.md}"
  input-focused:
    backgroundColor: "{colors.sanctuary-white}"
    textColor: "{colors.ink}"
    border: "1.5px solid {colors.roasted-cocoa}"
    rounded: "{rounded.md}"
  page-hero:
    backgroundColor: "transparent"
    borderBottom: "double 4px {colors.ink}/60"
  stat-card:
    backgroundColor: "{colors.candlelight-cream}"
    border: "1px solid {colors.warm-sand}"
    rounded: "{rounded.lg}"
  error-callout:
    backgroundColor: "{colors.error-surface}"
    textColor: "{colors.error-ink}"
    rounded: "{rounded.md}"
    padding: "12px"
---

# Design System: Rejoice Greatly — "The Register", on the Warm Welcome palette

## 1. Overview

**Creative North Star: "The Warm Welcome, written into The Register"**

Rejoice Greatly is the front porch of the church. Opening it should feel like
being greeted at the door by name: warm candlelight cream, grounded roasted-cocoa
brown, and generous white space that never rushes you. That palette is
unchanged. What changed is the *hand* the app is written in: the same visual
language as the admin site ("The Register" — see the admin repo's `DESIGN.md`),
grounded in the physical objects a church runs on — the attendance ledger, the
ruled register, the rubber date-stamp.

So the app now reads like pages from a register: a serif for the one headline
on a screen, a mono face with tabular figures for every number and micro-label,
a plain sans for everything else; crisp low-radius edges instead of soft rounded
cards; 1px ruled borders and a signature double rule instead of shadows; and no
icon-in-a-box stat tiles — a number's weight carries its meaning.

It is still **not cold corporate SaaS**, **not dated megachurch kitsch**, and
**not cluttered**. Warmth is structural: it lives in the palette, the spacing
and the copy, never in ornament.

**Key Characteristics:**
- Light-first: white floor, warm cream surfaces, deep-brown as the single accent.
- Ruled, not shadowed: 1px sand rules separate; a double ink rule closes a hero.
- Three faces, one job each: serif headings, mono data and labels, sans body.
- Crisp edges: 3 / 6 / 8px radii. Nothing is a pill except an avatar.
- One-voice color: roasted cocoa is the only action color across the app.
- Legible for everyone: 15px body, nothing below 12px, 44px tap targets.

## 2. Colors

Unchanged. A warm-neutral palette built on a true-white floor, candlelight
cream surfaces, and one grounding brown.

### Primary
- **Roasted Cocoa** (#633A02): The single action and identity color. Primary
  buttons, active nav item, focused input rule, the stamp badge's outline and
  ink, the play affordance, and — sparingly — the ink of one focal number.

### Neutral
- **Sanctuary White** (#FFFFFF): Scaffold, app bar and input fill.
- **Candlelight Cream** (#FFF7EB): Card and secondary-surface fill.
- **Ink** (#1A1A1A): Primary text, and the ink a double rule is drawn in (at 60%).
- **Weathered Wood** (#6B5C4D): Secondary text, captions, eyebrows, input labels.
- **Warm Sand** (#E8DFD0): The register's rule — every card border, input
  border, hairline divider and the line above the bottom nav. Full strength now,
  not 40% alpha: a rule is meant to be seen.

### Tertiary (functional only)
- **Error Surface / Border / Ink** (#FFF1EE / #E1B0A9 / #8A2C1F): The inline
  error callout.

### Named Rules
**The One Voice Rule.** Roasted Cocoa is the only action color. Never introduce
a second accent hue — this port deliberately did *not* bring the admin site's
violet or its green/amber status inks across.

**The Cream-on-White Rule.** Content lives on cream cards; chrome lives on white.
The admin site inverts this (white forms on cream paper); the app does not.

## 3. Typography

Bundled in `assets/fonts/` and declared in `pubspec.yaml`; tokens in
`lib/theme/church_type.dart` (`ChurchType`). The app theme sets IBM Plex Sans as
the default family, so an inline `TextStyle` without a family inherits it.

**Three faces, one job each:**
- **Source Serif 4** — headings only: `display` (28, w600) for the one page
  headline, `headline` (20) for app-bar and sheet titles, `title` (17) for card
  titles. Record-book gravitas for the one or two headline moments per screen.
- **IBM Plex Mono** — numbers and micro-labels: `data` (28, w600, tabular) for a
  focal number, `dataSmall` (13) for dates, times and inline counts, `eyebrow`
  (12, uppercase, 0.14em tracking) for section labels and the line above a hero.
- **IBM Plex Sans** — everything else: `body` (15), `bodyStrong`, `button` (15,
  w600), `label` (13, muted), `caption` (12, muted).

### Named Rules
**The 12px Floor Rule.** No user-facing text below 12px. The admin site's 11px
eyebrow is 12px here on purpose.

**The One Headline Rule.** Each screen gets exactly one serif `display`, inside
its page hero (`ChurchPageHero`, the dashboard app bar, or `ChurchTabPageHeader`).

**Numbers Are Mono Rule.** Any rendered count, streak, date or duration uses a
mono style with tabular figures. Headings never use mono; data never uses serif.

**The Weight-Not-Color Rule.** Emphasis comes from face, weight and size. Only
genuinely tappable text — and at most one focal number per view — may be cocoa.

## 4. Elevation

Flat. Depth is tonal (cream on white) and *ruled*, never cast. The old warm
card shadow is gone; `ChurchColors.cardDecoration()` now draws a 1px sand rule
and no shadow. The one "drawn line" motif is the **double rule**
(`ChurchDoubleRule`: two 1px ink lines, 2px apart) under a page hero — the
structural boundary that a shadow used to signal.

### Named Rules
**The Rule-Not-Shadow Rule.** If a surface needs to look separate, give it a
rule. A shadow is reserved for something genuinely floating over content
(a sheet, a banner), never for a card at rest.

**The Flat-Primary Rule.** The primary button is flat; its color is its
elevation. The secondary button is flat too, ruled in sand.

## 5. Components

Tokens: `ChurchRadius.sm` (3, chips and tags), `.md` (6, inputs, buttons,
thumbnails), `.lg` (8, cards and sheets).

### Buttons (`lib/widgets/church_buttons.dart`)
- **Primary:** cocoa fill, white `button` text, 52px, 6px radius, elevation 0.
- **Secondary:** cream fill, ink text, 1px sand rule, 50px, 6px radius, flat.
- **Danger:** outlined red, 6px radius. **Social:** cream, ruled, flat.
- **States:** loading swaps the label for a 20–22px spinner; disabled keeps the
  same fill.

### Cards
- Cream, 1px sand rule, 8px radius, no shadow, 14px padding. Thumbnails inside
  use a 6px radius.

### Stat card
- A mono `eyebrow` label over a large mono `data` number. **No icon tile** —
  the profile's `_StatTile` and the streak sheet's `_RegisterStat` are the
  reference implementations. One focal stat per view may take cocoa ink.

### Page hero
- `ChurchPageHero`: mono eyebrow, serif display title, optional muted
  description, optional `ChurchStampBadge`, closed by a double rule. The
  dashboard builds the same shape into its app bar; Sermons and Events use
  `ChurchTabPageHeader` (eyebrow + serif title + ruled search field).

### Stamp badge
- `ChurchStampBadge`: mono uppercase, 2px cocoa outline at 70%, rotated -1 degree.
  Used for a detail page's category — the rubber stamp on the record.

### Inputs
- White fill, 1px sand rule, 6px radius; 1.5px cocoa rule on focus. Set once in
  the theme's `inputDecorationTheme`; call sites pass only label and icon.

### Chips / filters
- White, ruled, 3px radius; selected fills cocoa. No elevation, no pill.

### Navigation
- **App bar:** white, elevation 0, serif `headline` title, cocoa icons.
- **Bottom nav:** white, a 1px sand rule on top, cocoa selected item.

### Signature component — Sermon card
- A cream ruled card holding a 72px 6px-radius thumbnail, a 2-line serif
  `title`, a mono `dataSmall` date, and a circular play button (cocoa at 12%
  alpha behind the play icon). Protect its clarity above all else.

## 6. Do's and Don'ts

### Do:
- **Do** keep Roasted Cocoa as the single action color.
- **Do** put content on cream cards and chrome on white.
- **Do** render every number in mono, every heading in serif, everything else
  in the default sans — via `ChurchType`, not a literal `TextStyle`.
- **Do** separate with a rule; close a hero with the double rule.
- **Do** use `ChurchRadius` tokens; nothing rounder than 8px except an avatar.
- **Do** hold body at 15px and never drop any label below 12px.

### Don't:
- **Don't** put a shadow on a card at rest, or bring the warm 16px card back.
- **Don't** put an icon tile next to a stat — the number's ink is the signal.
- **Don't** introduce a second accent hue, including the admin site's violet or
  its status greens and ambers.
- **Don't** use mono for a heading or serif for a number; **don't** add a
  fourth typeface.
- **Don't** design cold corporate SaaS, dated megachurch kitsch, or clutter.
- **Don't** use gamified pressure — nudge, never nag.
