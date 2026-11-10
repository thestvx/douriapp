# Customer Discovery — Design Decisions (Phase 6a)

> Overrides `design-system/douri/MASTER.md` + `OVERRIDES.md` for these
> pages. Same premium language as the barber dashboard
> (`pages/barber-dashboard.md`) and barber screens
> (`pages/barber-screens.md`): lime `#C8F078` only (never
> gold/brown/orange); Nexa (EN) + IBM Plex Sans Arabic (AR); dark palette
> bg `#111111` / card `#1B1B1B` / elevated `#222222` / borders `#2A2A2A`;
> light theme via existing `DouriColors.light`. All data flow, providers,
> repository calls, RPC names, routes and navigation destinations are
> unchanged — this phase is presentation only.

## Shared language (all three screens)

- **Entrances:** `DouriStagger` (indices 0–6, 40ms steps, capped at 8 by
  `staggerDelay`) replaces the older `DouriEntrance` on these screens, so
  they match the dashboard. `DouriStagger` respects reduced motion;
  `DouriEntrance` did not.
- **State transitions:** loading / error / empty / data states are keyed
  (`ValueKey('loading' | 'error' | 'empty' | 'results' | 'shops' | 'no-open')`)
  inside an `AnimatedSwitcher` (fade, `DouriDuration.normal`, zero under
  reduced motion), so a reload cross-fades instead of swapping abruptly.
- **Hero:** the shop cover flies between Home/Explore and the details
  screen on the shared tag `'shop-image-<shopId>'` (renamed from
  `'shop-cover-<id>'` in both `DouriShopCard` and the details screen, so
  the two ends always agree). The tag is unique per shop.
- **Bottom inset:** tab screens use 116dp bottom padding so nothing hides
  behind the floating pill nav (same value as the dashboard). The details
  screen keeps its own bottom Book bar (a fixed `Column` child above the
  scroll area, not a floating nav) — no extra inset there.
- **Touch targets:** ≥ 48dp everywhere — `DouriPressable` (48dp minimum),
  `DouriButton` (15dp vertical padding), `DouriIconButton` 44dp box,
  filter chips ≥ 48dp via `DouriPressable`.
- **RTL/LTR:** phone numbers, queue numbers and prices are wrapped in
  `Directionality(TextDirection.ltr)` (phone + queue number on the
  details screen; service price inside `DouriServiceCard`, which also
  benefits the booking and shop-management screens). The chevron uses
  `Icons.arrow_forward` (mirrors in RTL); the back button uses
  `Icons.arrow_back_ios_new` as before.
- **Overflow:** no fixed heights that clip (the 250dp horizontal carousel
  viewport and the 320dp hero are container heights, not text-clipping
  heights); `Flexible`/`Expanded`, 1–2 line caps with ellipsis on names,
  addresses and descriptions.

## Home (`home_screen.dart`)

- **Header (unchanged structure):** greeting + display name (1 line,
  ellipsis) + 48dp `DouriAvatar`; `DouriStagger` index 0.
- **Search entry:** same `DouriSearchField` + `onSubmitted` → writes
  `exploreQueryProvider` and switches to the Explore tab (index 1);
  `DouriStagger` index 1.
- **Active booking:** same section, same providers, same navigation
  (`/queue/<n>?bookingId=<id>` or `/booking-success/<id>`); entrances
  swapped to `DouriStagger`.
- **Promo banner:** the first open shop as a `DouriPromoBanner` (real
  rating, real cover, Book Now pill → `/booking/<id>`), `DouriStagger`
  index 2. The banner deliberately has **no Hero**: the same shop also
  appears in the carousel below, and two Heroes sharing a tag on one
  route would break the transition. No promo is invented — the banner
  only exists when at least one open shop exists.
- **Open-now chip:** the existing `FilterChip` is kept as-is.
- **Nearest to you carousel:** open shops in a horizontal list
  (`ShopRatingCard`, `ValueKey(shop.id)` on the card, `DouriStagger`
  index `i`); section header with View all → Explore tab.
- **Recommended:** closed shops only, vertical list with stable
  `ValueKey(shop.id)` on the list-level `Padding`. **The old fallback
  that re-rendered the featured (open) shops vertically when the
  recommended list was empty is removed**: it duplicated every featured
  shop — and its Hero tag — on the same route, which broke the
  shared-element transition. When every visible shop is open, the
  section is simply omitted; the carousel already shows them all.
- **New empty state:** when shops exist but the Open-now filter hides
  all of them, a distinct `noOpenShops` / `noOpenShopsMessage` state is
  shown (with an `All` action that clears the filter) instead of the
  misleading "no shops" message.

## Explore (`explore_screen.dart`)

- **Search with focus behaviour:** the field keeps the theme's lime
  focus border; on top of that an `AnimatedContainer` fades in a soft
  lime glow while focused, and a Cancel button slides in beside the
  field (`AnimatedSwitcher` + `SizeTransition`, horizontal axis) — the
  field shrinks smoothly with it, never jumping. Cancel clears the
  query (provider + controller) and unfocuses. This needed an optional
  `focusNode` parameter on the shared `DouriSearchField` (backward
  compatible; Home is unaffected).
- **Filter chips:** the All / Open now `FilterChip`s are replaced by
  custom animated pills (`DouriPressable` + `AnimatedContainer`):
  selected = lime-soft fill + lime border + lime check icon + bold lime
  label — selection is border + icon + weight, never colour alone. The
  check slot is always laid out and only its opacity animates, so
  selecting a chip never shifts the label or the row. Criteria are
  unchanged (All / Open now only); the Filters sheet (sort by name /
  open-first, open-now switch, apply/reset) is untouched.
- **Results:** `AnimatedSwitcher` keyed by state (loading / error /
  empty / results) cross-fades state changes, while result changes reuse
  the same `'results'` key and stable `ValueKey(shop.id)` rows, so
  typing or toggling a filter updates rows in place with no layout
  jump. Pull-to-refresh, filtering and both sorts are unchanged.

## Shop details (`barber_details_screen.dart`)

- **Hero:** 320dp cover (kept — already taller than the 140dp card
  covers), tag `'shop-image-<shopId>'` matching `DouriShopCard`. No
  sliver/collapsing header was added: the existing full-bleed hero +
  scroll already reads as a collapsing hero, and a `SliverAppBar`
  rebuild risked the overlay gradient and the positioned name/rating.
- **Identity:** shop name + open/closed badge overlaid on the hero
  gradient; the badge is now wrapped in `DouriAnimatedBadge` keyed by
  `shop.isOpen` so open/closed changes cross-fade. Rating (real, or
  `noReviews` when none) unchanged.
- **Info grouped:** address / description / phone now sit under a
  `DouriSectionHeader` (`shopDetails`, reused key) instead of bare rows;
  phone is LTR-wrapped.
- **Current queue:** unchanged data (`getTodayQueue`), same skeleton /
  not-started / now-serving states; the `#n` number is LTR-wrapped.
- **Services:** the screen is now a `ConsumerStatefulWidget` holding a
  local `_selectedServiceId`. Tapping a service toggles its selection
  in `DouriServiceCard` (lime border + filled check circle — border +
  icon, never colour alone). **Selection is local visual state only:**
  the booking screen already owns the real service choice
  (`booking_screen.dart` `_service` + `selectService`), and the Book
  action still navigates to `/booking/<id>` unchanged, so this screen
  deliberately does not pass the selection on.
- **States:** loading is now a skeleton (320dp hero block + text lines +
  `DouriSkeletonList`) instead of a bare spinner. Error and
  shop-not-found now include a back button (`_stateWithBack`) — the
  previous states had no way back off the route.
- **Book action:** same bottom bar, same `DouriButton`, same
  `/booking/<id>` destination.

## What is deliberately NOT shown

- **Promos / featured badges / discounts:** no promo data exists; the
  banner is just the first open shop, labelled with its real name,
  address and rating.
- **Distance ("Nearest to you"):** no distance data exists on
  `BarberShop` (same as Phase 5 — no fake barbers/favorites/distance).
  The existing section title is kept verbatim.
- **Rating when there are no reviews:** `DouriRating` is only rendered
  when `shopRatingProvider` returns a value; otherwise `noReviews`.
- **Service selection carried into booking:** see Services above — the
  booking screen re-asks; passing a query parameter would change the
  `/booking/:id` navigation this phase must not touch.
- **Working hours on the details screen:** `BarberShop` exposes no
  working-hours field (same finding as Phase 5); nothing invented.

## Motion

- `DouriStagger` entrances (indices 0–6 per screen, 40ms steps, capped)
  for headers, banner, chips, sections and list rows.
- `DouriAnimatedBadge` for the open/closed badge; `AnimatedContainer`
  for filter chips and the search glow; `AnimatedSwitcher` for state
  transitions and the search Cancel button; `AnimatedOpacity` for chip
  check icons.
- All motion renders its final state immediately under reduced motion
  (`DouriMotion.reduced` / `DouriMotion.scaled`); entrances are short
  (250ms) and interruptible.

## Data flow (unchanged)

- `shopsProvider`, `shopByIdProvider`, `shopServicesProvider`,
  `shopRatingProvider`, `customerBookingsProvider`,
  `exploreQueryProvider`, `currentProfileProvider`,
  `authStateProvider` — same providers, same repository calls, same
  routes (`/shop/:id`, `/booking/:id`, `/queue/:n`,
  `/booking-success/:id`). No new packages, no mock data.
- New l10n keys (AR + EN): `noOpenShops`, `noOpenShopsMessage`.
  Reused existing keys: `shopDetails` (info section header), `cancel`
  (search Cancel), `all` (clear-filter action).

## Known caveats

- The home carousel viewport is a fixed 250dp `SizedBox` height (a
  scroll-viewport height, not a clipping height): the card content
  inside is ~210dp, so nothing clips, but the value is fixed.
- `DouriServiceCard`'s duration line still hardcodes `'min'` (pre-existing;
  the `min` l10n key exists but the card predates this phase and is shared
  with the booking and shop-management screens — left untouched).
- The details-screen service selection is visual only (see Services
  above); if the booking flow ever accepts a pre-selected service, this
  screen is the place to wire it through.
