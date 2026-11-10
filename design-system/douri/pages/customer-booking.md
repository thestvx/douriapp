# Customer Booking Journey — Design Decisions (Phase 6b+7)

> Overrides `design-system/douri/MASTER.md` + `OVERRIDES.md` for these
> pages. Same premium language as the barber dashboard
> (`pages/barber-dashboard.md`), barber screens (`pages/barber-screens.md`)
> and customer discovery (`pages/customer-discovery.md`): lime `#C8F078`
> only (never gold/brown/orange); Nexa (EN) + IBM Plex Sans Arabic (AR);
> dark palette bg `#111111` / card `#1B1B1B` / elevated `#222222` /
> borders `#2A2A2A`; light theme via existing `DouriColors.light`. All
> data flow, providers, repository calls, RPC names, routes and navigation
> destinations are unchanged — this phase is presentation only.

## Shared language (all four screens)

- **Entrances:** `DouriStagger` (indices 0–6, 40ms steps, capped at 8 by
  `staggerDelay`) replaces the older `DouriEntrance` on these screens, so
  they match the dashboard and discovery screens. `DouriStagger` respects
  reduced motion; `DouriEntrance` did not. The confirmation screen keeps
  its one flutter_animate scale+fade chain on the success circle only —
  the celebratory pop — everything else on that screen is `DouriStagger`.
- **Motion:** `DouriAnimatedCounter` for queue numbers (counts up from the
  previous value, renders immediately under reduced motion),
  `DouriAnimatedBadge` (keyed child) for status cross-fades,
  `DouriPressable` for press feedback (scale/opacity only, never a layout
  shift), `AnimatedSwitcher` (fade, `DouriDuration.normal`, zero under
  reduced motion) for state swaps.
- **State transitions:** loading / error / empty / data states are skeletons
  or designed states, never a bare spinner on the confirmation and ticket
  screens; state swaps cross-fade instead of jumping.
- **RTL/LTR:** phone numbers, booking times, queue numbers, dates and
  prices are wrapped in `Directionality(TextDirection.ltr)`; the chevron
  uses `Icons.arrow_forward` (mirrors in RTL); the back button uses
  `Icons.arrow_back_ios_new` as before.
- **Overflow:** no fixed heights that clip (the 110dp shop header and the
  120dp success circle are container sizes, not text-clipping heights);
  `Flexible`/`Expanded`, 1-line caps with ellipsis on names, addresses,
  shop names and summary values.
- **Touch targets:** ≥ 48dp everywhere — `DouriPressable` (48dp minimum),
  `DouriButton` (15dp vertical padding), day/time pills ≥ 48dp via
  `DouriPressable`.

## Booking (`booking_screen.dart`)

- **Step progression (direction-aware).** The step body is keyed by step
  inside an `AnimatedSwitcher`: forward slides in from the end side
  (right in LTR, left in RTL), back reverses. Direction is tracked in a
  `_forward` field set at all four step-change sites (`_next`, app-bar
  back, bottom Back, and the phone-sheet "edit number" jump back to
  step 3). Each step gets a fresh `SingleChildScrollView` (keyed by step),
  so the scroll position resets to the top of the new step. Entered data
  lives in state fields (`_service`, `_date`, `_timeSlot`, controllers)
  and is never lost when moving between steps. Under reduced motion the
  switch is a plain fade (zero-duration slide).
- **Step indicator.** The numbered circles keep their `AnimatedContainer`
  (lime for current/completed, muted outline for upcoming); the circle
  content now cross-fades between number and check (`AnimatedSwitcher`
  with a 150ms fade+scale, keyed `'done'` / `'number'`), the connector
  lines animate their colour (`AnimatedContainer`), and the
  `n / 5 — label` line cross-fades on every step change
  (`AnimatedSwitcher` keyed by step).
- **Services.** `DouriServiceCard` kept — it already owns press feedback
  (InkWell ripple), tap semantics, and the animated border + check
  selection (border + icon, never colour alone). It is deliberately NOT
  wrapped in `DouriPressable`: a second tap handler would fire the
  selection twice. Rows are `DouriStagger` (index `i`) with a stable
  `ValueKey(service.id)` on the list-level `Padding`.
- **Dates.** The `ChoiceChip`s are replaced by custom `_DayPill`s
  (`DouriPressable` + `AnimatedContainer`): selected = lime-soft fill +
  lime border + lime check icon + bold lime label — selection is border +
  icon + weight, never colour alone. The check slot is always laid out
  and only its opacity animates, so selecting a day never shifts the
  label or the row (same pattern as the Explore filter chips). Labels use
  the existing `MaterialLocalizations.formatMediumDate`. The calendar
  button is unchanged (same `showDatePicker`, same 60-day window). The
  selected date line is LTR-wrapped and cross-fades on change
  (`AnimatedSwitcher` keyed by the ISO date).
- **Time slots.** The `ChoiceChip`s are replaced by custom `_TimeSlotChip`s
  with the same selected treatment as the day pills. Taken slots (real
  `_bookedTimesProvider` data) and past slots for today are muted
  (elevated surface, `textMuted`, struck-through time) and untappable
  (`DouriPressable` with `onTap: null`) — booked slots stay visibly
  disabled, never selectable. The `timeSlotTaken` note below the grid is
  unchanged.
- **Contact.** Fields unchanged (`DouriTextField` + `DouriPhoneField`,
  same validators); only the entrances changed to `DouriStagger`.
- **Review (grouped cards).** The single summary card is now two grouped
  cards: details (shop / service / date / time / duration) and price +
  pending state. The total price value is lime-accented. The plain
  `pendingApproval` line is now a soft-warning banner (hourglass icon +
  `pendingApproval` + `queueNumberAfterApproval`), mirroring the
  confirmation screen's pending state. `_SummaryRow` gained an optional
  `valueColor`, an `ltrValue` flag (date / time / price are LTR-wrapped),
  and ellipsis on both label and value (`Flexible` label + `Expanded`
  value, 1 line each).
- **Phone-confirm sheet.** Same confirm / edit-number behaviour
  (`pop(true)` / `pop(false)`), same PENDING creation on confirm. Polished
  only: `DouriStagger` entrances (indices 0–6), a `DouriSectionHeader`
  (`bookingSummary`) grouping the summary rows, LTR date/time rows.
- **Hero continuity.** The shop header cover shares the
  `'shop-image-<id>'` Hero tag with the details screen (same tag as
  `DouriShopCard`), so the cover flies in from the details hero the user
  just saw. Only the image is hero-wrapped — the name overlay stays
  outside the Hero — and only when a real cover URL exists (the icon
  fallback has no Hero). The tag appears once on this route, so it can
  never duplicate. The flight crosses a radius change (details hero is
  square, this header is clipped to 20dp), so corners square off briefly
  mid-flight and settle clipped — accepted.
- **Submit.** In-button loading (`_submitting`) and the error snackbar are
  unchanged; `_submit`, `_confirmAndSubmit`, `_next`/`_canContinue`,
  `_slots`, `_bookedTimesProvider` and the `ref.read(authStateProvider)
  .value?.uid ?? 'test_customer'` line are verbatim.

## Confirmation (`booking_confirmation_screen.dart`)

- **Entrances unified.** All `DouriEntrance` swapped to `DouriStagger`
  (indices 0–6). The success circle keeps its flutter_animate
  scale+fade chain — the one celebratory pop on this screen — and the
  import stays for it.
- **Pending vs confirmed, distinct at a glance.** A status pill sits
  above the details card: warning-soft + hourglass + `bookingPending`
  while waiting, success-soft + check + `bookingConfirmed` once accepted.
  It is a `DouriAnimatedBadge` keyed by `confirmed`, so it cross-fades
  the moment the live stream delivers the number. The old Status row was
  removed from the details card (the pill now owns the status) — the card
  keeps reference / shop / date / time / phone.
- **Queue-number reveal.** The number card and the pending banner are the
  two children of an `AnimatedSwitcher` (keyed `'number'` / `'pending'`,
  fade + slight rise), so acceptance cross-fades the banner into the
  number card. The number itself is a `DouriAnimatedCounter` with the
  theme-aware `DouriTextStyles.queueNumber` (96dp, lime dark / deep lime
  light), zero-padded — it counts in when acceptance arrives live.
  Counts from 0 on first mount (same documented caveat as the barber
  screens); under reduced motion it renders immediately.
- **PENDING rule preserved.** The `StreamBuilder` on
  `watchEntryForBooking` and the `queueNumber == null` gating are
  untouched: no number is shown before acceptance, and the Track button
  stays disabled until a number exists.
- **Loading / empty.** The bare spinner is now a skeleton matching the
  loaded layout (120dp circle + title/message lines + two card blocks);
  the booking-not-found empty state gets a `DouriStagger` entrance.
- **Rows.** `_Row` gained an optional `ltrValue` flag; reference, date,
  time and phone values are LTR-wrapped (the `+213…` phone used to be
  able to flip its `+` to the wrong end in RTL). Values have 1-line
  ellipsis.

## Queue ticket (`queue_ticket_screen.dart`)

- **Live-queue feel.** The ticket number is a `DouriAnimatedCounter`
  (theme-aware `queueNumber` style, LTR-wrapped, zero-padded) instead of
  the old `AnimatedSwitcher` + `DouriQueueNumber`. The hero card is an
  `AnimatedContainer`, so the approaching/current lime tint and border
  animate in when the status flips to `APPROACHING` / `CURRENT` instead
  of swapping abruptly.
- **Status badge.** The plain pill is now a `DouriAnimatedBadge` keyed by
  `ValueKey(status)`, so every status change cross-fades + scales.
  `_statusLabelColor` still takes `BuildContext` (as before — never
  `context` in a top-level helper without the parameter).
- **Position updates animate in place.** The now-serving, people-ahead
  and estimated-wait values are each wrapped in an `AnimatedSwitcher`
  keyed by their value (fade, `DouriDuration.normal`, zero under reduced
  motion), so Realtime updates fade the number rather than jumping it.
  `DouriProgress` already animates its fill. The `_loadQueueInfo` future
  and its call sites are unchanged.
- **Loading / empty.** Both bare spinners are now a `_TicketSkeleton`
  (hero block + info card, matching the loaded layout's shapes); the
  no-active-queue empty states get a `DouriStagger` entrance.
- **Shop name** on the hero is now 1 line with ellipsis.
- **Leave queue** flow, cancel confirm, and navigation are unchanged.

## My bookings (`my_bookings_screen.dart`)

- **Per-tab empty states.** `_BookingsList` now takes `emptyTitle` /
  `emptyMessage` and each tab shows its own state (new l10n keys below)
  instead of the same generic "no bookings" everywhere.
- **Pull-to-refresh on empty tabs.** Empty states are wrapped in a
  `RefreshIndicator` + `CustomScrollView` with `SliverFillRemaining`
  (always-scrollable), so an empty tab can be pulled to check for new
  bookings, matching the non-empty lists.
- **Cards.** Rows keep `DouriBookingCard` (pressable via its InkWell) with
  a stable `ValueKey(booking.id)` on the list-level `DouriStagger` and an
  `AnimatedSwitcher` keyed by `'${booking.id}_${booking.status}'` around
  the row — the same pattern as the barber requests screen — so a status
  change arriving live cross-fades the card in place. `_BookingRow` now
  accepts `super.key` to carry that key.
- **Tabs.** The default `TabBar` indicator is unchanged (it already
  animates smoothly with the `TabController`); the title and tab bar got
  `DouriStagger` entrances (indices 0–1). Filters, tab order and the
  PENDING/CONFIRMED → upcoming, PENDING → pending, COMPLETED →
  completed, CANCELLED/REJECTED → cancelled split are unchanged.
- **Cancel / open.** `_cancel` (confirm dialog, `cancelBooking`,
  `actionFailed` snackbar) and `_open` (`/queue/<n>?bookingId=<id>` when
  a number exists, otherwise `/booking-success/<id>`) are verbatim.

## What is deliberately NOT shown

- **Service name on the ticket / my bookings:** `Booking` has no service
  field (same finding as Phases 4–6a), so no service is displayed
  anywhere except the booking flow itself, where the service is chosen.
- **Queue number before acceptance:** nowhere — the PENDING rule is
  sacred on all four screens.
- **Working hours / distance / ratings on these screens:** no data source
  on the models used here; nothing invented.
- **Service selection carried from the details screen:** the booking
  screen still re-asks (Phase 6a decision — passing a query parameter
  would change the `/booking/:id` navigation).
- **Exit animation on removed booking cards:** would need an
  `AnimatedList`; the stream-driven `ListView.separated` is kept, so a
  removed card disappears with the next stream emission (same as Phase 5).

## Motion

- `DouriStagger` entrances (indices 0–6 per screen, 40ms steps, capped)
  for headers, sections, cards and list rows.
- Direction-aware step slide on the booking screen (`_forward` flag,
  RTL-aware sign, zero-duration slide under reduced motion);
  `DouriAnimatedCounter` for ticket/confirmation numbers;
  `DouriAnimatedBadge` for status pills; `AnimatedContainer` for
  day/time selection, step-indicator connectors and the ticket hero tint;
  `AnimatedSwitcher` for step labels, number/pending swaps, position
  values and booking-card status changes; `AnimatedOpacity` for the
  always-laid-out check slots on day/time pills.
- All motion renders its final state immediately under reduced motion
  (`DouriMotion.reduced` / `DouriMotion.scaled`); entrances are short
  (250ms) and interruptible.

## Data flow (unchanged)

- `shopByIdProvider`, `shopServicesProvider`, `shopRatingProvider`,
  `customerBookingsProvider`, `currentProfileProvider`,
  `authStateProvider`, `_bookedTimesProvider`, `_entryProvider` — same
  providers, same repository calls, same routes (`/booking/:id`,
  `/booking-success/:id`, `/queue/:n`), same RPCs. No new packages, no
  mock data, no schema changes.
- New l10n keys (AR + EN): `noUpcomingBookings`,
  `noUpcomingBookingsMessage`, `noPendingBookings`,
  `noPendingBookingsMessage`, `noCompletedBookings`,
  `noCompletedBookingsMessage`, `noCancelledBookings`,
  `noCancelledBookingsMessage`. Reused existing keys: `bookingSummary`
  (sheet section header), `pendingApproval` /
  `queueNumberAfterApproval` (review-step banner), `bookingPending` /
  `bookingConfirmed` (confirmation status pill), `timeSlotTaken`.

## Known caveats

- `DouriAnimatedCounter` counts up from 0 on first mount on the ticket
  and confirmation screens (same as the barber screens); under reduced
  motion both render the final number immediately.
- The booking-header Hero flight crosses a corner-radius change (square
  details hero → 20dp-clipped header), so corners square off briefly
  mid-flight; the flight itself is 350ms and settles clipped.
- Day/time pills are 48dp tall (the `DouriPressable` minimum) — chunkier
  than the old `ChoiceChip`s, by design: touch targets ≥ 48dp.
- The confirmation screen's success circle is the only remaining
  flutter_animate chain in these four files; everything else uses the
  shared `DouriStagger` / `DouriAnimated*` widgets.
