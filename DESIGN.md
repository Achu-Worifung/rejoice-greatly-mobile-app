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
    fontFamily: "Roboto (Android) / SF Pro (iOS) — Material 3 platform default"
    fontSize: "28"
    fontWeight: 700
    lineHeight: 1.2
    letterSpacing: "1"
  headline:
    fontFamily: "Platform default"
    fontSize: "17"
    fontWeight: 700
    lineHeight: 1.25
    letterSpacing: "-0.2"
  title:
    fontFamily: "Platform default"
    fontSize: "16"
    fontWeight: 700
    lineHeight: 1.25
    letterSpacing: "0"
  body:
    fontFamily: "Platform default"
    fontSize: "15"
    fontWeight: 400
    lineHeight: 1.4
    letterSpacing: "0"
  label:
    fontFamily: "Platform default"
    fontSize: "13"
    fontWeight: 500
    lineHeight: 1.3
    letterSpacing: "0"
rounded:
  sm: "8px"
  md: "12px"
  lg: "14px"
  xl: "16px"
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
    rounded: "{rounded.lg}"
    height: "52px"
  button-secondary:
    backgroundColor: "{colors.candlelight-cream}"
    textColor: "{colors.ink}"
    rounded: "{rounded.md}"
    height: "60px"
  card:
    backgroundColor: "{colors.candlelight-cream}"
    textColor: "{colors.ink}"
    rounded: "{rounded.xl}"
    padding: "14px"
  input:
    backgroundColor: "{colors.sanctuary-white}"
    textColor: "{colors.ink}"
    rounded: "{rounded.md}"
  input-focused:
    backgroundColor: "{colors.sanctuary-white}"
    textColor: "{colors.ink}"
    rounded: "{rounded.lg}"
  error-callout:
    backgroundColor: "{colors.error-surface}"
    textColor: "{colors.error-ink}"
    rounded: "{rounded.sm}"
    padding: "12px"
---

# Design System: Rejoice Greatly

## 1. Overview

**Creative North Star: "The Warm Welcome"**

Rejoice Greatly is the front porch of the church. Opening it should feel like
being greeted at the door by name: warm candlelight cream, grounded roasted-cocoa
brown, and generous white space that never rushes you. The system is
**light-first and unhurried** — a clean white sanctuary floor, warm cream cards
that hold content like a shared table, and a single deep-brown voice for every
action worth taking. It serves a broad, non-technical congregation, so legibility
and calm always win over density or cleverness.

The visual job is load-bearing but quiet: get a member to *play this sermon* or
*know when the next event is* in a tap or two, and let the warmth carry the rest.
Warmth here is structural, not decorative — it lives in the palette, the spacing,
and the copy, never in ornament. Components are **clean and grounded**: clear
edges, comfortable radii, low-contrast borders, and only a whisper of brown
shadow to lift a card off the floor.

This system explicitly rejects three things. It is **not cold corporate SaaS** —
no sterile blue/gray chrome, no spreadsheet density, no enterprise dashboard
energy. It is **not dated megachurch kitsch** — no clip-art crosses, no glowing
stock-photo sunsets, no cheesy multi-stop gradients or heavy drop shadows. And it
is **not cluttered or busy** — no walls of near-identical cards, no screens with
three competing calls-to-action.

**Key Characteristics:**
- Light-first: white floor, warm cream surfaces, deep-brown as the single accent.
- Unhurried: generous spacing, comfortable type, calm hierarchy.
- One-voice color: roasted cocoa is the only action color across the app.
- Warmth through restraint: no ornament; warmth is the palette and the copy.
- Legible for everyone: strong contrast, plain labels, mobile-first tap targets.

## 2. Colors

A warm-neutral palette built on a true-white floor, candlelight cream surfaces,
and one grounding brown — the warmth carried by the cream-and-cocoa relationship,
not by tinting everything.

### Primary
- **Roasted Cocoa** (#633A02): The single action and identity color. Every
  primary button, active nav item, link, focused input border, icon accent, and
  play affordance. Its scarcity is deliberate — one voice for "do this."

### Neutral
- **Sanctuary White** (#FFFFFF): The scaffold background and app-bar surface. The
  calm floor everything sits on. Keeps screens from ever feeling heavy.
- **Candlelight Cream** (#FFF7EB): Card and secondary-surface fill. The warmth of
  the whole system lives here — content sits on cream, chrome sits on white.
- **Ink** (#1A1A1A): Primary body and heading text. Near-black, ~15:1 on both
  white and cream — the workhorse for legibility.
- **Weathered Wood** (#6B5C4D): Muted secondary text, captions, input labels,
  placeholder icons. A warm brown-gray, ~5.6:1 on white — passes AA for body.
- **Warm Sand** (#E8DFD0): Dividers and card borders (usually at ~40% alpha).
  Barely-there structure; separates without drawing a line.

### Tertiary (functional only)
- **Error Surface / Border / Ink** (#FFF1EE / #E1B0A9 / #8A2C1F): The inline
  error callout — warm rose-tinted, never a harsh system red block. Used only for
  validation and failure messages.

### Named Rules
**The One Voice Rule.** Roasted Cocoa (#633A02) is the *only* action color in the
app. If something is tappable and primary, it is cocoa; if it is not, it is not.
Never introduce a second accent hue to "add interest" — interest comes from
spacing and copy.

**The Cream-on-White Rule.** Content lives on Candlelight Cream cards; chrome
(scaffold, app bar, nav) lives on Sanctuary White. Never invert this into cream
chrome with white cards — the warmth belongs to the content, not the frame.

## 3. Typography

**Display / Body Font:** Material 3 platform default — Roboto on Android, SF Pro
on iOS. No custom font family is bundled; the app inherits the native system face
for maximum legibility and zero-cost rendering.

**Character:** Neutral, familiar, and legible by design. The personality comes
from *weight and space*, not from a distinctive typeface — appropriate for a
broad, non-technical congregation who should never have to work to read.

### Hierarchy
- **Display** (w700, 28px, line-height 1.2, letter-spacing 1): Page-opening
  greetings — "Let's Get Started!". One per screen, top of the flow.
- **Headline** (w700, 17px, letter-spacing −0.2): App-bar titles and section
  headers. Tight tracking keeps them crisp and centered.
- **Title** (w700, 16px, line-height 1.25): Card titles — sermon and event names.
  Capped at 2 lines with ellipsis so cards stay uniform height.
- **Body** (w400–w500, 15–16px, line-height ~1.4): Running text, button labels,
  list content. The default reading size; keep it at 15px or larger, never below.
- **Label** (w400–w500, 12–13px): Dates, captions, input labels, "Forgot
  Password?". Always in Weathered Wood, never smaller than 12px.

### Named Rules
**The 12px Floor Rule.** No user-facing text below 12px, ever. This congregation
skews broad and non-technical; sub-12px "elegance" is illegible here.

**The Weight-Not-Color Rule.** Emphasis comes from weight (w400 → w700) and size,
not from coloring text with the accent. Only genuinely tappable text may be cocoa.

## 4. Elevation

Nearly flat. The system conveys depth through **tonal layering** (cream content on
a white floor) far more than through shadow. The one shadow in the vocabulary is
soft, warm, and diffuse — a whisper that lifts a card, never a hard drop shadow
that screams "2014 app."

### Shadow Vocabulary
- **Card lift** (`color: #633A02 @ 8% alpha, blur 20, offset (0, 8)`): The default
  card shadow — a warm brown glow, not a gray drop shadow. Tinting the shadow with
  the brand brown is what keeps it feeling warm rather than generic.
- **Secondary-button lift** (Material elevation 2): Social/secondary buttons sit
  slightly proud of the surface; primary buttons stay flat (elevation 0) because
  color already carries their weight.

### Named Rules
**The Warm-Shadow Rule.** Shadows are tinted with Roasted Cocoa at low alpha,
never neutral black. A gray drop shadow on a warm surface reads cold and dated —
if a card looks like it's floating on a spreadsheet, the shadow is wrong.

**The Flat-Primary Rule.** The primary button is flat (elevation 0). Its color is
its elevation. Only secondary/neutral surfaces earn a lift, to signal "also
tappable, but not the main thing."

## 5. Components

Components are **clean and grounded**: clear edges, comfortable radii, restrained
borders, and depth used only to signal interactivity.

### Buttons
- **Shape:** Gently rounded — 14px (lg) on primary, 12px (md) on secondary.
- **Primary:** Roasted Cocoa fill, Sanctuary White text (w600, 15px), full-width,
  52px tall, flat (elevation 0). The one unmistakable "do this" affordance.
- **Secondary / Social:** Candlelight Cream fill, Ink text/icon, 1px Warm Sand
  border, 60px tall, Material elevation 2. Used for Google/Apple sign-in and other
  non-primary actions.
- **States:** Loading swaps the label for a 20–22px CircularProgressIndicator
  (white on primary, cocoa on secondary). Disabled keeps the same background
  (`disabledBackgroundColor` matches) so the button never visually collapses.

### Cards / Containers
- **Corner Style:** 16px (xl) — the softest radius in the system, reserved for
  content containers.
- **Background:** Candlelight Cream (#FFF7EB).
- **Shadow Strategy:** The warm "Card lift" from Elevation.
- **Border:** 1px Warm Sand at ~40% alpha — present but nearly invisible.
- **Internal Padding:** 14px. Thumbnails inside cards use a 12px radius, 72×72px.

### Inputs / Fields
- **Style:** OutlineInputBorder, 12px radius, 1px Warm Sand stroke, Weathered Wood
  label and prefix icon, on a white field.
- **Focus:** Border shifts to Roasted Cocoa and radius grows to 14px — a subtle,
  warm "you're here now" signal.
- **Error:** Border → red accent; the inline Error Callout (warm rose surface,
  #8A2C1F text, 8px radius) carries the message above the form.

### Navigation
- **App bar:** Sanctuary White, transparent surface tint, elevation 0, centered
  17px/w700 Ink title, cocoa icons. Never a tinted or colored bar.
- **Bottom nav:** Fixed, white, top hairline border (grey ~200). Selected item
  Roasted Cocoa; unselected grey 400. 12px labels, 22px SVG icons. The primary
  wayfinding for Dashboard · Sermons · Events · Café.

### Signature Component — Sermon Card
The recurring hero pattern: a cream card holding a 72px rounded thumbnail, a
2-line title (w700, 16px) + date (Weathered Wood, 13px), and a circular play
button (cocoa at 12% alpha behind the play icon). This is the shortest path to the
app's core job — protect its clarity above all else.

## 6. Do's and Don'ts

### Do:
- **Do** keep Roasted Cocoa (#633A02) as the single action color — one voice for
  every primary tap (The One Voice Rule).
- **Do** put content on Candlelight Cream cards and chrome on Sanctuary White
  (The Cream-on-White Rule).
- **Do** tint card shadows with brown at low alpha (#633A02 @ 8%), never neutral
  black (The Warm-Shadow Rule).
- **Do** convey emphasis with weight and size, not by coloring text (The
  Weight-Not-Color Rule).
- **Do** keep the sermon/event path — card → play, or card → remind — the shortest
  and most obvious action on any screen.
- **Do** hold body text at 15px+ and never drop any label below 12px (The 12px
  Floor Rule).

### Don't:
- **Don't** design cold corporate SaaS: no sterile blue/gray chrome, no
  spreadsheet density, no enterprise-dashboard energy.
- **Don't** slip into dated megachurch kitsch: no clip-art crosses, no glowing
  stock-photo sunsets, no cheesy multi-stop gradients, no heavy gray drop shadows.
- **Don't** clutter: no walls of near-identical cards, no screen with three
  competing calls-to-action. Give the primary action room to breathe.
- **Don't** introduce a second accent hue "for interest" — interest is spacing and
  copy, not a new color.
- **Don't** invert the surface roles into cream chrome with white cards; the
  warmth belongs to the content.
- **Don't** use gamified pressure — no streak-shaming, badge spam, or aggressive
  confetti. Nudge, never nag.
