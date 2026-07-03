# CLAUDE.md

Guidance for AI agents working in this repository.

## Project

**Rejoice Greatly** — a Flutter mobile app (iOS/Android, `name: church_app`) for
the Rejoice Greatly church congregation. Core job: help members **never miss a
sermon or event** (sermons + audio, events, a café/community tab, streaks &
attendance, reminders/push, profile, and admin/moderation tooling).

## Design Context

Strategic product/design context lives in [`PRODUCT.md`](PRODUCT.md). Read it
before designing or changing any UI. In short:

- **Register:** product (app UI serving the product, not a marketing surface).
- **Audience:** existing congregation members; broad, non-technical, mobile.
- **Feel:** warm, welcoming, unhurried — "greeted at the door," never corporate.
- **Anti-references:** cold corporate SaaS; dated megachurch kitsch; cluttered
  and busy screens.
- **Principles:** sermon/event come first · warmth through restraint · nudge,
  never nag · greeted, not processed · unhurried and legible (WCAG AA contrast).

Visual tokens live in `lib/theme/church_colors.dart` (cream card `#FFF7EB`,
deep-brown action `#633A02`, 16px card radius). A `DESIGN.md` at the root
captures the full visual system when present.
