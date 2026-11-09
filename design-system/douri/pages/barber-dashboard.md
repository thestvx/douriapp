# Barber Dashboard — Design Decisions (Phase 4)

> Overrides `design-system/douri/MASTER.md` + `OVERRIDES.md` for this page.
> Lime `#C8F078` only (never gold/brown/orange); Nexa (EN) + IBM Plex Sans
> Arabic (AR); dark palette bg `#111111` / card `#1B1B1B` / elevated
> `#222222` / borders `#2A2A2A`; light theme via existing `DouriColors.light`.

## Shell (unchanged)

- `Scaffold` + `IndexedStack` with the same 4 tabs and the same
  `DouriBottomNav` items/labels (Dashboard, Queue, Bookings, Profile).
  Tab switching, `RefreshIndicator`, skeleton / error / no-shop states are
  untouched. Content bottom padding is 116dp so nothing hides behind the
  floating pill nav.

## Layout (top to bottom, single scroll)

1. **Header (compact).** Greeting (`l10n.hello`) + shop name
   (`headlineMedium`, 1 line, ellipsis) + date line with the
   `DouriStatusBadge` inline beside it. A 48dp shop avatar (logo or
   initials via `DouriAvatar`) sits at the end; tapping it switches to the
   existing profile tab — no notifications affordance was added because no
   notifications screen exists.
2. **Workday status hero.** One `DouriCard`: animated dot (lime/success
   ring when open, muted when closed, `AnimatedContainer`) +
   Open/Closed label cross-fading via `DouriAnimatedBadge` (keyed by
   `isOpen`) + a one-line summary (`{appointmentDuration} min` — a real
   `BarberShop` field) + the original `Switch` with the original
   `_toggleOpen` logic (upsert `is_open`, invalidate provider, snackbar
   on failure). No chairs count is shown: `BarberShop` has no chairs
   field (migration 003's `chairs_count` column is not exposed on the
   model), so nothing is invented.
3. **Live queue hero (new, central).** Section header `Live queue` with a
   `View queue` action; the card itself taps through to the queue tab,
   which owns start / advance / end — the dashboard never assigns queue
   numbers (PENDING rule preserved).
   - Number being served huge in lime (`DouriAnimatedCounter` +
     `DouriTextStyles.queueNumber`, zero-padded), with the customer's
     real name + booking time beside it when the bookings join provides
     them. When nobody is being served yet, the next number is shown
     with the `Next customer` label instead.
   - Next-customer strip (`#n · name`) only when a current customer
     exists and someone is waiting behind them.
   - Progress: `DouriProgress` (completed / total entries today) with a
     `completed/total` count, plus an estimated wait (`~waiting ×
     appointmentDuration min`) — computed only from real data, labelled
     as an estimate, omitted when nobody is waiting.
   - Empty state inside the card when no queue entries exist today
     (icon, `No customers yet`, message, secondary `Start day` button
     that goes to the queue tab where the day is actually started).
4. **Statistics.** Same 4 KPIs and same `_loadStats` repository calls
   (`getShopBookings` + `listTodayEntries`): today's bookings, waiting,
   current customer (`#n` or `—`), completed. Restyled as a 2×2 grid of
   refined cards: lime-tinted icon chip, animated counter
   (`DouriAnimatedCounter`), label beneath (2 lines max).
5. **Quick actions.** Same 4 actions, same destinations (Start day →
   queue tab, Queue management → queue tab, Booking requests →
   bookings tab, Shop management → `/barber/shop`). 2×2 grid of
   `DouriPressable` + `DouriCard` with icon chip + label. No action
   without a destination was added.

## What is deliberately NOT shown

- **Service name:** no service field exists on `Booking`, `QueueEntry`,
  or anywhere in the queue select (`bookings(customer_name,
  booking_time)` only). The hero shows name + booking time, never a
  service.
- **Chairs count:** not on the `BarberShop` model (see above).
- **Rating / revenue / customer counts beyond the 4 KPIs:** no data
  source for them on this screen; nothing invented.
- **Notifications entry point:** no notifications screen exists.

## Motion

- Staggered entrances via `DouriStagger` (indices 0–6, 40ms steps,
  capped) for header, status hero, queue header, queue hero, stats,
  quick-actions header, quick-actions grid.
- `DouriAnimatedCounter` for the hero queue number and all four stat
  values (counts up/down from the previous value).
- `DouriAnimatedBadge` for the Open/Closed label; `AnimatedContainer`
  for the status dot colour; `DouriProgress` animates its fill.
- All motion widgets render their final state immediately under reduced
  motion (`DouriMotion.reduced`); entrances are short (250ms) and
  interruptible.

## Responsive / overflow

- No fixed heights that clip. Grids use `LayoutBuilder`: under ~360dp
  content width the stat grid uses `childAspectRatio` 1.0 and the
  quick-actions grid 1.9 (taller cells for two-line labels); otherwise
  1.15 / 2.2. Stat labels allow 2 lines; quick-action labels 2 lines;
  shop name, customer names and times are single-line with ellipsis.
- `Flexible`/`Expanded` throughout; RTL (AR) and LTR (EN) both
  supported — the chevron uses `Icons.arrow_forward`, which mirrors in
  RTL, and the bottom-nav pill is already direction-aware.
- Touch targets ≥ 48dp (avatar 48dp, `DouriPressable` minimum 48dp,
  `Switch` native). Press feedback is scale/opacity only, never a
  layout shift. Material Icons only, no emoji.

## Data flow (unchanged)

- `currentShopProvider` drives the shell; `_DayStats` is extended with
  `total`, current/next name + booking time (derived from the same
  `listTodayEntries` call — no new repository calls). `_loadStats`,
  `_refresh`, `_toggleOpen`, `_isToday` logic preserved verbatim.
- New l10n keys (AR + EN): `liveQueue`, `noCustomersYet`,
  `noCustomersYetMessage`, `queueProgress`, `minutesShort`.
  `viewQueue` and `estimatedWait` already existed and were reused.

## Known caveat

- `DouriTextStyles.queueNumber` hardcodes lime `#C8F078` (and
  `statValue` hardcodes white); the hero number therefore has weak
  contrast on the light theme's white card. The brief mandates the
  token for the queue number, so it is used as specified; the stat
  values instead use theme-aware `headlineMedium` so they stay readable
  in both themes. A future pass could make `queueNumber` theme-aware.
