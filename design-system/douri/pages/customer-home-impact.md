# Customer Home — Visual Impact Pass (2026-11-10)

User feedback: after phases 3–10 the app still read as unchanged. Diagnosis:
the home composition was identical (greeting → search → banner → carousel →
list, same dark palette), and the 40ms staggers were easy to miss. This pass
recomposes the home screen and makes motion unmistakable. It overrides the
per-page customer-discovery doc where they conflict.

## What changed

- **Full-bleed hero (new composition):** the first open shop is now a 340dp
  edge-to-edge cover at the very top of the screen, with a dark gradient,
  display-size shop name (displayMedium, 40px), rating + open badge on the
  image, an eyebrow label (`featuredShops`) and a large lime "Book now" pill
  ON the image. Tap → `/shop/:id`; Book → `/booking/:id` (both through the
  existing go_router routes, so the slide+fade page transition applies).
  Fallbacks, all real data, never mock: no open shop → no hero, the greeting
  header is the top of the screen as before; no cover image → gradient panel
  with a large scissors mark; while shops load → a 340dp shimmer block in
  the same shape so the screen never looks blank.
- **Hero has no Hero tag** (deliberate): the same shop also appears in the
  carousel below, and two Heroes sharing a tag on one route would break the
  transition. The carousel card keeps the `'shop-image-<id>'` tag, so the
  shared-element transition into details still works from there.
- **Image-first, larger shop cards:** `DouriShopCard` gained a `coverHeight`
  parameter (default 140, unchanged elsewhere). Home carousel cards are now
  300×300 with a 190dp cover; recommended list cards use a 170dp cover;
  Explore result cards use a 170dp cover. `ShopRatingCard` passes the height
  through.
- **Visible press feedback:** `DouriShopCard` is now wrapped in
  `DouriPressable` (0.96 scale). The tap is handled by the pressable only —
  the inner `DouriCard` no longer takes an `onTap`, so a tap can never fire
  twice (nested GestureDetector + InkWell would both recognise it).
- **Animated counters:** the queue number on `DouriBookingCard` now counts
  up via `DouriAnimatedCounter` (starts at 0 on mount, tweens on change).
- **Stronger greeting:** name is now `headlineLarge` (was `headlineMedium`),
  "Hello," is a small secondary label, avatar is 26dp with a 1.5dp lime ring.
- **Entrance choreography (once per app session, ~750ms):** greeting slides
  up (0.05–0.45), search follows (0.30–0.65), sections fade in (0.55–1.0),
  driven by one `AnimationController` in `_HomeBodyState`. The hero has its
  own entrance — scale 1.06 → 1 + fade over 550ms (`_HeroEntrance`,
  `TweenAnimationBuilder`) when the shop data first arrives, and it replays
  when the featured shop changes (keyed by shop id). Both render their final
  state immediately under reduced motion.
- **Shop details hero:** cover 320 → 400dp, name `headlineMedium` →
  `headlineLarge`, loading skeleton height matched (400dp).
- **Contrast fix found on the way:** the Book pill text in `DouriPromoBanner`
  used `douriColors.background` — near-white on lime in the light theme
  (unreadable). It now uses `AppColors.accentOnDark` (dark text on lime in
  both themes), the same token `DouriButton` primary uses.

## What did NOT change

- No backend, repository, model, provider, route, booking logic or PENDING
  rule change. Search, active-booking section, open-now filter,
  pull-to-refresh, 116dp bottom inset above the pill nav, and all navigation
  targets are exactly as before. No new packages, no new l10n keys (only
  existing keys reused: `featuredShops`, `bookNow`, `hello`, `searchHint`).
- No new colours outside the palette (lime accent only).

## Diagnostic note (do NOT change this behaviour)

`DouriMotion.reduced` reads `MediaQuery.disableAnimations`. If the emulator
has animations switched off (Developer options → animator scale off, or
Accessibility → Remove animations), EVERY animation in the app renders its
final state immediately and the app looks static — that is correct
accessibility behaviour, and the gating must stay. If motion still feels
absent after this pass, the first thing to check is the emulator's animator
scale setting.
