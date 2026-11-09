# Barber Screens — Design Decisions (Phase 5)

> Overrides `design-system/douri/MASTER.md` + `OVERRIDES.md` for these
> pages. Same premium language as the dashboard (`pages/barber-dashboard.md`):
> lime `#C8F078` only (never gold/brown/orange); Nexa (EN) + IBM Plex Sans
> Arabic (AR); dark palette bg `#111111` / card `#1B1B1B` / elevated
> `#222222` / borders `#2A2A2A`; light theme via existing `DouriColors.light`.
> All data flow, repository calls, RPC names, routes and providers are
> unchanged — this phase is presentation only.

## Shared language (all four screens)

- **Entrances:** `DouriStagger` (indices 0–6, 40ms steps, capped at 8) for
  sections and list rows, replacing the older `DouriEntrance` on these
  screens so the four screens match the dashboard.
- **Motion:** `DouriAnimatedCounter` for queue numbers, `DouriAnimatedBadge`
  (keyed child) for status cross-fades, `DouriPressable` for press feedback
  (scale/opacity only, never a layout shift). All render their final state
  immediately under reduced motion (`DouriMotion.reduced`).
- **Chrome:** `DouriCard` shells, `DouriSectionHeader` for grouped sections,
  `DouriProgress` for queue progress, `DouriEmptyState` / `DouriErrorState` /
  `DouriSkeletonList` for states. Material Icons only, no emoji.
- **Bottom inset:** tab screens use 116dp bottom padding so nothing hides
  behind the floating pill nav (same value as the dashboard). The queue and
  booking screens are also reachable as standalone routes (`/barber/queue/:id`,
  `/barber/requests/:id`); there the extra bottom space is just whitespace.
- **Touch targets:** ≥ 48dp everywhere — `DouriButton` (15dp vertical
  padding), `DouriPressable` (48dp minimum), service delete wrapped in a
  48×48 box around the 44dp `DouriIconButton`.
- **RTL/LTR:** phone numbers, booking times, queue numbers and prices are
  wrapped in `Directionality(TextDirection.ltr)`; the chevron uses
  `Icons.arrow_forward`, which mirrors in RTL.
- **Overflow:** no fixed heights that clip (cover hero is 160dp by design,
  not a clipping height); `Flexible`/`Expanded`, 1–2 line caps with
  ellipsis on names, addresses and descriptions.

## Queue management (`queue_management_screen.dart`)

- **Current-customer hero:** one `DouriCard` — `nowServing` label, big
  number via `DouriAnimatedCounter` with the now theme-aware
  `DouriTextStyles.queueNumber` (zero-padded), customer name, booking time
  (LTR), and a status pill via `_statusBadge` (`DouriAnimatedBadge` with a
  `ValueKey(status)` pill so status changes cross-fade + scale).
  Replaces the old `DouriQueueNumber` (lime `displayLarge`, illegible in
  light theme) and `DouriQueueCard` (lime number on light elevated surface).
- **Next-up strip:** `Next customer` header + the next waiting entry as a
  `_queueRow`. When nobody is being served yet, a `queueNoCurrent` caption
  explains the strip is the next in queue.
- **Waiting list:** `_queueRow` cards — lime-tinted (`accentSoft`) 52dp
  number chip with the number in primary text (readable in both themes),
  name, booking time with clock icon, status badge. Each row is a
  `DouriPressable` (≥48dp) opening a **read-only detail sheet** (name,
  queue number, booking time, status, Close) — the press affordance with
  no new data or action. Stable keys: `ValueKey(entry.id)` on the
  list-level `Padding` (and on the pressable), so Realtime inserts/removals
  reuse the row element in place instead of rebuilding the list.
- **Progress:** `DouriProgress` (completed / total) with a `done / total ·
  completed` count line (LTR digits).
- **Day-ended banner:** when the queue is not ACTIVE but entries exist, a
  card with flag icon + `queueDayEnded` / `queueDayEndedMessage` sits above
  the list, and the Start day button returns at the bottom.
- **Empty states (three, distinct):** day not started → `noQueueToday`
  (with Start day action, as before); day started but nobody queued →
  new `queueEmpty` / `queueEmptyMessage` (`hourglass_empty` icon, no
  action); queue active is implied by the second. Completed/skipped
  entries are counted in progress only — no separate "done" list was added.
- **Actions unchanged:** start-day (`startTodayQueue`), end-day
  (`endTodayQueue`), advance (`advance_queue` RPC, both confirm variants),
  skip (client-side `queue_entries` update to SKIPPED, best-effort under
  RLS as before), all with the same confirm dialogs, `_busyAction`
  loading states and real-error snackbars. Buttons keep their original
  show/hide conditions (Call next only when someone is current or waiting,
  Complete/Skip only when someone is current).
- **PENDING rule preserved:** queue numbers only ever come from
  `QueueEntry.queueNumber` (assigned on acceptance); nothing is invented
  or pre-assigned here.

## Booking requests (`booking_requests_screen.dart`)

- **Cards:** `DouriBookingCard` kept — title = customer name, subtitle =
  phone (or `—` when empty; `customerPhone` is required but can be an
  empty string), date + time labels, queue-number chip only when
  `booking.queueNumber` is non-null (PENDING rule: no number before
  acceptance).
- **Actions:** Approve stays lime primary with in-button loading
  (`_busyId == booking.id`); Reject changed from secondary to
  `DouriButtonVariant.danger` (danger-tinted ghost-danger look) **and**
  now also shows in-button loading while its RPC runs. Both still call
  the same RPCs (`approve_booking`, `reject_booking` with the optional
  reason from the unchanged `_RejectReasonSheet`).
- **Feedback:** `AnimatedSwitcher` kept, now keyed by
  `'${booking.id}_${booking.status}'` so an approve/reject cross-fades
  the card in place; the list-level `Padding` carries
  `ValueKey(booking.id)` for stable Realtime updates. A true exit
  animation on removal would need an `AnimatedList`; the stream-driven
  `ListView.builder` is kept deliberately, so a removed card disappears
  with the next stream emission.
- **Empty states:** the pending tab gets its own `noPendingRequests` /
  `noPendingRequestsMessage`; the other five tabs keep the generic
  `noRequests` / `noRequestsMessage`. Tabs, `TabController` (held in state
  so stream emissions never reset the tab) and filters are unchanged.
- **Not shown — service name:** `Booking` has no service field (and the
  queue select only joins `bookings(customer_name, booking_time)`), so no
  service is displayed. Not shown — customer avatar: no avatar field on
  `Booking`.

## Shop management (`shop_management_screen.dart`)

- **Grouped sections** (all `DouriSectionHeader` + `DouriStagger`):
  1. **Shop photos** — cover hero first: full-width 160dp preview
     (image or lime `image_outlined` fallback on elevated surface) with
     the Upload cover button overlaid at the bottom-end
     (`PositionedDirectional`, RTL-safe); logo as a 72dp circle beside
     its upload button, with a store-icon fallback. URL text fields stay
     below each preview, editable as before.
  2. **Shop details** — name, description (3 lines), address, phone.
  3. **Working settings** — appointment duration + max daily bookings
     (side-by-side `Expanded` fields) and the open/closed `Switch` card.
  4. **Save** — same button, same `_save` (upsert via
     `barberShopRepositoryProvider.upsertShop`, same field map,
     `currentShopProvider` invalidated, `saved` snackbar).
  5. **Services** — header with Add action, cards with name, duration
     (clock icon), price in theme-aware `DouriTextStyles.price` (LTR),
     description line when present (a real `ShopService` field), and
     delete in a 48dp hit area. Add sheet and delete confirm + reload
     logic unchanged.
- **Logic preserved verbatim:** `_prefill`, `_loadServices`
  (`listAllServices`), `_uploadShopImage` (gallery pick →
  `CloudinaryService.uploadImage` to `douri/logos` / `douri/covers` →
  URL into the field, saved only on Save), `_save` validation
  (name required), `_showAddService` / `_deleteService`.
- **Keyboard:** `SingleChildScrollView` (no fixed heights),
  `keyboardDismissBehavior: onDrag`, Scaffold keeps its default
  `resizeToAvoidBottomInset`, so the keyboard never covers the field
  being edited; 32dp bottom padding.
- **Deliberately NOT done — working-hours editor:** the `BarberShop`
  model exposes no working-hours field (the signup wizard's
  `working_hours` JSON is not on the model), so no hours UI was invented;
  the section is honestly named "Working settings" and holds the real
  settings that exist.
- **Deliberately NOT done — service edit:** there is no update method on
  `ShopServiceRepository` (only `addService` / `deleteService`) and
  repositories are outside this phase's file list, so no edit affordance
  was added — an edit button with no save path would be fake. Add +
  delete cover the real CRUD surface.

## Barber profile (`barber_profile_screen.dart`)

- **Grouped sections** with `DouriSectionHeader`: My shop, Account,
  Language, Appearance, then actions.
- **Profile hero:** shop card (avatar from `shop.logoUrl`, name, address,
  open/closed badge via `DouriAnimatedBadge` keyed by `shop.isOpen`) is
  now tappable (`DouriCard.onTap: onManageShop`) with a forward chevron.
  No-shop state keeps the Create shop button.
- **Account card:** owner avatar (from real `Profile.avatarUrl`) + full
  name as the header, then phone and — new, real `Profile.email` field —
  email rows, both LTR. The old duplicate full-name row is gone.
- **Language:** same two buttons, same `localeProvider` writes, now in a
  card under a section header instead of a titled card.
- **Appearance:** `DouriThemePicker` untouched (it renders its own
  "Appearance" title, so no second header was added above it).
- **Actions:** Shop management (secondary) and Logout (danger) buttons,
  same `onManageShop` navigation and `_logout` (`signOut` → `/auth`).
- **Rows:** `_ProfileRow` keeps `DouriTextStyles.statLabel` (now
  theme-aware) for labels; phone/email values stay LTR.

## Typography fix (`app_typography.dart`)

All `DouriTextStyles` methods keep their signatures, sizes, weights and
line-heights; only colours changed to resolve via the `BuildContext` they
already receive (`context.douriColors` / `Theme.of(context)`):

- `display`, `screenTitle`, `sectionTitle`, `body`, `label`, `statValue`:
  white → `context.douriColors.text` (white dark / `#111111` light).
- `bodySecondary`, `caption`, `statLabel`: `#999999` → 
  `context.douriColors.textSecondary` (`#999999` dark / `#666666` light;
  `#999999` on white was ~2.9:1, `#666666` on white is ~5.7:1).
- `price`, `queueNumber`: lime `#C8F078` in dark theme, **deep lime
  `#4E7416`** in light theme. Contrast reasoning (WCAG relative
  luminance): `#4E7416` has L ≈ 0.142, so on white it is
  (1.05)/(0.142+0.05) ≈ **5.48:1**, and ≈ 4.7:1 on the light elevated
  surface `#EDEDE7` — both ≥ 4.5:1. The constant lives only in
  `app_typography.dart` as `_deepLimeLight`, documented there.
- `button`: unchanged `#111111` (text on lime, correct in both themes).
- Callers verified: dashboard `queueNumber` (hero number now readable in
  light theme — resolves that page's known caveat) and `statLabel`,
  profile `statLabel`, queue hero `queueNumber`, service-row `price`.
  Same method names/signatures, so every caller still compiles.

## New l10n keys (AR + EN)

`queueEmpty`, `queueEmptyMessage`, `queueDayEnded`,
`queueDayEndedMessage`, `queueNoCurrent`, `noPendingRequests`,
`noPendingRequestsMessage`, `shopDetails`, `shopPhotos`, `shopSettings`,
`myShop` — all with getter + AR + EN entries in
`app_localizations.dart`. No hardcoded user-facing text was added.

## Known caveats

- Queue rows count up from 0 on first mount (`DouriAnimatedCounter`
  starts at 0); under reduced motion they render immediately. This
  matches the dashboard's stat counters.
- `DouriQueueCard` / `DouriQueueNumber` are no longer used on the queue
  screen (their lime-on-light contrast); both widgets still exist and are
  used elsewhere untouched.
- The queue screen's standalone routes (`/barber/queue/:id`,
  `/barber/requests/:id`) have no bottom nav, so the 116dp bottom inset
  is extra whitespace there — accepted for consistency with the tab usage.
