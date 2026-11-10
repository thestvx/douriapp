# DOURI Design System — Overrides (source of truth over MASTER.md)

The generated MASTER.md came from generic search output. The rules below are
the user's explicit brand decisions and **override** MASTER.md wherever they
conflict. Page files in `design-system/douri/pages/` override both.

## Brand overrides

- **Accent is lime `#C8F078`** — never the gold `#A16207` in MASTER.md.
  No brown, no orange, no gold anywhere. Lime is strategic only: primary
  actions, active states, progress, selected elements, key queue numbers.
  Never a large lime background fill.
- **Fonts are Nexa (EN) + IBM Plex Sans Arabic (AR)** from the local font
  files already in the repo — never Bodoni Moda / Jost.
- **Palette (dark identity):** bg `#111111`, secondary `#171717`,
  card `#1B1B1B`, elevated `#222222`/`#242424`, text `#FFFFFF` / `#999999` /
  `#686868`, borders `#2A2A2A`, success `#8DDC8A`, warning `#F3C969`,
  error `#EF7777`. Light theme uses the existing `DouriColors.light` palette
  (bg `#F5F5F0`, surfaces white, text `#111111`).
- **Style:** dark luxury minimalist, not "Liquid Glass". Surfaces are solid
  (no translucency that blurs hierarchy), hairline borders, restrained
  shadows. Motion 9/10, density 5/10, variance 7/10 per the brief.

## Implementation rules (from the redesign work)

- All colors through `context.douriColors` or `Theme.of(context)` inside
  build methods. Never dark constants directly in widgets; never a runtime
  theme color inside a `const` constructor.
- Never use `context` inside a top-level or static helper without a
  `BuildContext` parameter (this broke a build on 2026-11-09).
- Motion tokens live in `lib/core/theme/app_tokens.dart`
  (`DouriDuration`, `DouriCurves`, `staggerDelay`). Shared motion widgets
  live in `lib/core/widgets/douri_motion.dart`.
- Every new user-facing string gets AR + EN keys in
  `lib/core/localization/app_localizations.dart` — never hardcoded text.
- Touch targets ≥ 48dp; press feedback via color/opacity/elevation, never
  layout-shifting transforms; respect reduced motion
  (`MediaQuery.disableAnimations` / `DouriMotion.reduced`) by rendering the
  final state immediately.
- Booking rule (unchanged): a booking starts PENDING; no queue number is
  shown before the barber accepts. The success screen shows the live queue
  number the moment acceptance arrives via Realtime.
- **Theme-aware accent (Phase 9 QA):** brand lime `#C8F078` on a light
  surface is ~1.5:1 (unreadable). Any lime TEXT or meaningful ICON must
  use `DouriTextStyles.accent(context)` — lime in dark, deep lime
  `#4E7416` (~5.5:1 on white) in light. Never raw
  `AppColors.primaryAccent` for text/icons. Lime fills, borders and
  progress indicators may stay brand lime (state is never conveyed by
  border colour alone). `DouriQueueNumber` uses the theme-aware
  `queueNumber` style.
- No mock data, no new packages unless truly needed
  (`flutter_animate` is already a dependency — prefer it + native Flutter
  animation). No schema changes, no Firestore, no secrets in code.
