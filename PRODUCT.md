# Product

## Register

product

## Users

Members of the Rejoice Greatly congregation — people who already belong to the
church and attend regularly. They open the app on their phones in the moments
around their week: catching up on a sermon they missed, checking when the next
event is, tapping through from a reminder. They are not power users and are not
looking for a tool to master; they want the app to quietly help them stay
connected to church life without friction. Assume a broad, non-technical
audience and a mobile-first (Flutter, iOS/Android) context.

## Product Purpose

Rejoice Greatly keeps members close to the life of the church between Sundays.
Its core job is simple and load-bearing: **never miss a sermon or event.**
Everything else — the streaks, attendance, café/community tab, reminders and
push notifications, the profile ("Me") and admin/moderation tooling — serves
that spine of *access + timely reminding*. Success looks like a member opening
the app and, within a tap or two, either playing the sermon they wanted or
knowing exactly what's coming up and being reminded in time to show up.

## Brand Personality

Warm and welcoming — the feeling of being greeted at the door by name. The voice
is gentle, human, and encouraging, never institutional or salesy. Three words:
**warm, welcoming, unhurried.** The interface should feel like it was made by
people who know you, not by a corporation. Reminders nudge; they never nag or
shame. The existing cream-and-deep-brown palette (`lib/theme/church_colors.dart`)
is the anchor for this warmth and should be preserved.

## Anti-references

- **Cold corporate SaaS.** No sterile enterprise dashboards, generic blue/gray
  chrome, or spreadsheet energy. This is a community, not a CRM.
- **Dated megachurch kitsch.** No clip-art crosses, glowing stock-photo sunsets,
  cheesy multi-stop gradients, or heavy drop shadows. Warmth comes from
  restraint, not decoration.
- **Cluttered & busy.** No dense feeds, no walls of near-identical cards, no
  screens with three competing calls-to-action. Calm and focused wins; give the
  primary action room to breathe.

## Design Principles

- **The sermon and the event come first.** On any screen, the path to "play this"
  or "when is this / remind me" should be the shortest, most obvious one. Protect
  that spine; everything else is secondary.
- **Warmth through restraint.** The brand feels warm because of the palette,
  generous spacing, and human copy — not because of decoration. When in doubt,
  remove rather than add.
- **Nudge, never nag.** Streaks, reminders, and notifications encourage gently.
  No shame mechanics, no badge spam, no gamified pressure.
- **Greeted, not processed.** Copy and empty states speak to a person by name in
  plain, kind language — the app should feel like being welcomed, not onboarded.
- **Unhurried and legible.** Calm layouts, comfortable type sizes, and strong
  contrast so a broad, non-technical congregation can use it effortlessly.

## Accessibility & Inclusion

No special accessibility mandates were called out for this audience, so hold to
sensible defaults: meet WCAG AA contrast (≥4.5:1 body text, ≥3:1 large text)
throughout, keep tap targets comfortable, and respect reduced-motion preferences
for any animation. Because the congregation is broad and non-technical, favor
legible type sizes and clear labels over dense, compact layouts.
