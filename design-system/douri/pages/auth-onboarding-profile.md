# Auth / Onboarding / Splash / Customer Profile — Design Decisions (Phase 8)

> Overrides `design-system/douri/MASTER.md` + `OVERRIDES.md` for these
> pages. Same premium language as the barber dashboard
> (`pages/barber-dashboard.md`), barber screens (`pages/barber-screens.md`),
> customer discovery (`pages/customer-discovery.md`) and the booking
> journey (`pages/customer-booking.md`): lime `#C8F078` only (never
> gold/brown/orange); Nexa (EN) + IBM Plex Sans Arabic (AR); dark palette
> bg `#111111` / card `#1B1B1B` / elevated `#222222` / borders `#2A2A2A`;
> light theme via existing `DouriColors.light`. All data flow, providers,
> repository calls, validation, routes and navigation destinations are
> unchanged — this phase is presentation only.

## Shared language (all seven screens)

- **Entrances:** `DouriStagger` (indices 0–8, 40ms steps, capped at 8 by
  `staggerDelay`) replaces the older `DouriEntrance` on every screen in
  this phase, so they match the dashboard, discovery and booking
  screens. `DouriStagger` respects reduced motion; `DouriEntrance`
  did not. The now-unused `douri_feedback.dart` import was removed
  from the five files that only used it for `DouriEntrance`.
- **Error feedback:** every error line on these screens is now the same
  soft-danger banner — `dangerSoft` fill, danger border at 35% alpha,
  `error_outline` icon, the original error text verbatim — inside an
  `AnimatedSwitcher` (fade, `DouriDuration.normal`, zero under reduced
  motion) keyed by the error string, with a `SizedBox.shrink`
  `'no-error'` child when there is no error. The message content,
  validation and when errors appear are unchanged.
- **Step progression:** the numbered step indicator from the booking
  screen is reused verbatim as a file-private widget (`_SignupStepIndicator`
  on signup, `_WizardStepIndicator` on the wizard): 30dp lime circles
  for reached steps, muted outline for upcoming, the circle content
  cross-fading between number and check (`AnimatedSwitcher`, 150ms
  fade+scale, keyed `'done'` / `'number'`), animated connector lines,
  and the `n / N — label` line cross-fading on every step change
  (`AnimatedSwitcher` keyed by step).
- **RTL/LTR:** phone numbers, emails, times and step counts are wrapped
  in `Directionality(TextDirection.ltr)`; chevrons use
  `Icons.arrow_forward` (mirrors in RTL). The wizard's step slide is
  direction-aware (same `_forward` flag + RTL sign as the booking
  screen, plain fade under reduced motion).
- **Overflow:** no fixed heights that clip; `Flexible`/`Expanded`,
  1-line caps with ellipsis on names, phones and emails.
- **Touch targets:** ≥ 48dp everywhere — the chairs stepper buttons
  sit in explicit 48×48 boxes, the day pills use `DouriPressable`
  (48dp minimum), and the "no account" / "already have an account"
  text links gained 14dp vertical padding (≈48dp tap height).
- **Keyboard:** every form screen keeps its `SingleChildScrollView`
  with the Scaffold's default `resizeToAvoidBottomInset`, so no field
  hides behind the keyboard.

## Customer profile (`customer_profile_screen.dart`)

- **Hero:** the avatar now sits in a lime ring (1.5dp border,
  `primaryAccent` at 45% alpha); name is 1 line with ellipsis; phone
  is LTR-wrapped with ellipsis; a real `Profile.email` line was added
  below the phone (LTR, `bodySmall`, secondary text) when the profile
  has one — the same account rows the barber profile already shows.
  The edit affordance (`DouriIconButton`, `_editName` sheet) and the
  sheet itself are verbatim.
- **Bottom inset:** the scroll view now uses the 116dp bottom inset
  (same value as the other customer tab screens) so the Logout button
  clears the floating pill nav — the old 20dp padding could hide it
  behind the nav.
- **Language rows:** the trailing check icon is now an
  `AnimatedSwitcher` keyed `'on'` / `'off'` (fade+scale), so switching
  language cross-fades the check instead of swapping it.
- **Unchanged:** grouped sections + `DouriSectionHeader`s,
  `DouriThemePicker`, notifications `Switch` (local state, as before),
  Booking history button (`onShowBookings`), the honest
  `favoritesComingSoon` empty state (no favorites feature exists),
  Logout (`signOut` → `/auth`).

## Auth (`auth_screen.dart`)

- **Focus feedback:** each field is wrapped in a new `_FocusGlow`
  (an `AnimatedContainer` fading a soft lime glow — 18% alpha,
  16dp blur — in while focused) driven by a `Focus` widget's
  `onFocusChange`. The field widget itself (`DouriTextField`) is
  untouched: it still owns the theme's lime focus border, and the
  glow is layered around it. Same focus-glow language as the Explore
  search field.
- **Error:** the plain centered error text is now the shared
  danger-soft banner (see above); the raw exception text is unchanged.
- **Links:** the "no account" link gained the 48dp tap padding above.
- **Kept exactly:** validation, `_signIn` routing (no profile →
  `/role/:uid`, barber → `/barber`, customer → `/customer`), loading
  button, hero panel, and the test-only ghost skip-login button
  (`l10n.skipLogin` → `/customer`) — its removal before release is a
  separate decision, not this phase.

## Signup (`signup_screen.dart`)

- **Step indicator:** a 2-step `_SignupStepIndicator` sits under the
  subtitle — step 1 Account type (role choice), step 2 Your details
  (customer form) — in the booking indicator's language. New l10n
  keys below.
- **Role cards:** the icons now sit in 56dp lime-soft circles
  (`accentSoft`), matching the role-selection cards.
- **Form grouping:** the customer form is grouped under
  `DouriSectionHeader`s — `fullName` above the first/last-name row,
  `accountInfo` above email/password — reusing existing keys.
- **Error + link:** shared danger banner; the "already have an
  account" link gained the 48dp tap padding.
- **Unchanged:** role choice, form fields, validators,
  `_createCustomerAccount` (Firebase sign-up + profile upsert +
  `/customer`), back-to-role-choice, pop-or-`/auth` on the link.

## Barber wizard (`barber_signup_screen.dart`)

- **Step indicator:** the 4dp progress dots are replaced by the
  5-step numbered `_WizardStepIndicator` (same titles list as before:
  account / password / salon / working hours / owner). Its
  `n / N — label` line replaces the old subtitle text, which said
  the same thing — no information was lost.
- **Step transitions:** the step body is keyed by `_step` inside an
  `AnimatedSwitcher` with the booking screen's direction-aware slide
  (`_forward` set at `_next` and at Back; RTL-aware sign; plain fade
  under reduced motion). Entered data lives in the controllers/state
  fields and is never lost between steps.
- **Step bodies:** each step's fields are wrapped in `DouriStagger`
  (indices 0–3 per step) so a new step staggers in.
- **Chairs stepper:** the `+/-` buttons sit in explicit 48×48 boxes
  and the number cross-fades on change (`AnimatedSwitcher` keyed by
  `_chairs`, fade+scale). Bounds (1–20) unchanged.
- **Working days:** the `FilterChip`s are replaced by custom
  `_WizardDayPill`s (`DouriPressable` + `AnimatedContainer`) in the
  booking day-pill language: selected = lime-soft fill + lime border
  + lime check icon + bold lime label — selection is border + icon +
  weight, never colour alone. The check slot is always laid out and
  only its opacity animates, so toggling a day never shifts the label
  or the row.
- **Error:** shared danger banner.
- **Unchanged, step by step:** step order and fields, `_validateStep`,
  GPS detect (`_detectLocation`, lat/lng only — address stays manual),
  open/close `showTimePicker`s, `_finish` (Firebase sign-up, profile
  + `barber_shops` upsert with `working_hours` JSON and
  `chairs_count`, `/barber`).

## Role selection (`role_selection_screen.dart`)

- **Grouping:** a `DouriSectionHeader` (`chooseAccountType`, reused
  key) now heads the two role cards; the name field keeps its
  `fullName` header.
- **Role cards:** icon chips use the lime-soft (`accentSoft`) fill
  instead of the plain elevated fill, matching the signup role cards;
  the chevron is now `Icons.arrow_forward` (mirrors in RTL) instead
  of `chevron_right`.
- **Error:** shared danger banner; saving spinner unchanged.
- **Unchanged:** `_choose` (profile upsert, placeholder shop row for
  barbers, `/barber` vs `/customer`), the `My Barber Shop` placeholder
  name, name validation.

## Onboarding (`onboarding_screen.dart`)

- **Page content:** title/desc entrances are now keyed `DouriStagger`s
  (`ValueKey('title-$index')` / `'desc-$index'`), so each page's
  content staggers in when the page lands and renders its final state
  under reduced motion.
- **Language chips:** the inner container is now an
  `AnimatedContainer`, so the lime-soft fill and border animate on
  selection instead of swapping instantly.
- **Unchanged:** the `PageView`, the animated dot indicator, the round
  lime arrow CTA, skip (pages 1–2 only), `_finish` (persists the
  onboarding-seen flag, then `/auth`). The dots already animated via
  `AnimatedContainer` and were left as they were.

## Splash (`splash_screen.dart`)

- **Brand entrance:** the logo mark now sits inside a lime ring
  (136dp circle, `primaryAccent` at 30% alpha) — the ring the file's
  doc comment already promised but the code never drew. The ring
  scales/fades in with the mark.
- **Reduced motion:** all four flutter_animate chains (logo
  scale+fade, wordmark fade+slide, tagline fade, progress fade) are
  now gated on `DouriMotion.reduced(context)` — under reduced motion
  every element renders in its final state immediately. The entrance
  stays short and interruptible (the route still leaves after the
  auth check, min 1900ms).
- **Routing logic untouched:** `_route` is verbatim — auth check with
  3s timeout, signed-in → profile lookup → `/barber` / `/customer` /
  `/role/:uid`, signed-out → onboarding (first launch) or `/auth`.

## What is deliberately NOT shown

- **Favorites on the profile:** no favorites feature or data exists;
  the honest `favoritesComingSoon` empty state is kept.
- **Member-since / account age on the profile:** `Profile` has no
  creation timestamp; nothing invented.
- **Password reset / forgot-password on login:** no such flow exists
  in the app; no dead link was added.
- **Working-hours editor on the wizard's behalf / service editing:**
  out of scope (same as Phase 5 — no model/repository surface).
- **Onboarding swipe hint:** the round arrow CTA and the animated
  dots already communicate paging; no extra caption was added.
- **Splash progress percentage:** the indeterminate lime bar is kept;
  no fake percentage is shown.

## Motion

- `DouriStagger` entrances (indices 0–8 per screen, 40ms steps,
  capped) for headers, heroes, cards, sections and list rows.
- `DouriAnimatedBadge`-style `AnimatedSwitcher` cross-fades for the
  profile language check, the chairs number and the error banners;
  `AnimatedContainer` for the focus glow, language chips, step
  connectors and day pills; `AnimatedOpacity` for the always-laid-out
  check slots on day pills; direction-aware `AnimatedSwitcher` slide
  for wizard steps (zero-duration slide under reduced motion).
- All motion renders its final state immediately under reduced motion
  (`DouriMotion.reduced` / `DouriMotion.scaled`); entrances are short
  (250ms) and interruptible.

## Data flow (unchanged)

- `currentProfileProvider`, `authStateProvider`,
  `profileRepositoryProvider`, `barberShopRepositoryProvider`,
  `authRepositoryProvider`, `notificationServiceProvider`,
  `localeProvider`, `themeModeProvider`, `AppPrefs` — same providers,
  same repository calls, same routes (`/auth`, `/signup`,
  `/signup/barber`, `/role/:uid`, `/onboarding`, `/customer`,
  `/barber`). No new packages, no mock data, no schema changes.
- New l10n keys (AR + EN): `stepAccountType`, `stepYourDetails`.
  Reused existing keys: `fullName`, `accountInfo`,
  `chooseAccountType` (section headers), `dangerSoft` banner uses
  the existing error strings verbatim.

## Known caveats

- The wizard's old subtitle line (`Step n / 5 — title`) was removed
  because the new indicator's label line says exactly the same thing;
  the `step` l10n key is still used by the booking screen.
- The auth/signup error banners always render their container slot:
  with no error they are a zero-height `SizedBox.shrink`, but the
  16dp gap above the banner stays, so the no-error gap between the
  last field and the submit button is 40dp instead of 24dp — accepted
  as breathing room, not a bug.
- `DouriEntrance` still exists in `douri_feedback.dart` and is still
  used by screens outside this phase; only these seven files were
  migrated to `DouriStagger`.
