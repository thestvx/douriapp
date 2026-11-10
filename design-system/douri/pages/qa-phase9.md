# Phase 9 — RTL / Responsive / QA Audit

> Audit of the Phase 6–8 redesign (customer screens, booking journey,
> auth/onboarding/splash/profile). Fixes applied in the same push batch.
> Lime `#C8F078` only; Nexa (EN) + IBM Plex Sans Arabic (AR); dark palette
> bg `#111111` / card `#1B1B1B` / borders `#2A2A2A`; light theme via
> `DouriColors.light`.

## Automated checks (all passed)

- No `AsyncValue.valueOrNull` anywhere; `CustomTransitionPage` used only
  in `transitions.dart` (go_router imported); `app_router.dart` untouched
  in this range; `pubspec.yaml` unchanged (no new packages).
- No top-level/static helper uses `context` without a `BuildContext`
  parameter (same scan as Phase 5); no emoji in `lib/` outside
  localizations; no hardcoded user-facing text except the `DOURI`
  wordmark on splash.
- Every `Douri*` / `AppColors` / `AppLocalizations` symbol in changed
  files resolves to an imported file (symbol→file index check).
- All 12 new l10n keys present as getter + AR + EN
  (`noOpenShops*`, `noUpcoming/Pending/Completed/CancelledBookings*`,
  `stepAccountType`, `stepYourDetails`).
- Hero tag `'shop-image-<id>'` appears once per route (shop card,
  details hero, booking cover) — never duplicated on one route.
- Brace/paren/bracket balance 0 in every touched file.
- No `DouriEntrance` remains in any redesigned screen (kept only in
  `douri_feedback.dart` for unredesigned screens).

## Light-theme lime contrast fix (the one real finding)

Brand lime on white is ~1.5:1. A grep over all changed files found lime
used as TEXT or meaningful ICON colour in 15+ places. Fix: new public
`DouriTextStyles.accent(context)` (lime dark / deep lime `#4E7416`
~5.5:1 light) and all lime text/icons switched to it:

- Text: service/shop price labels, queue numbers (`#n` chips, now-serving,
  status colours), total price on the booking review, location-status
  text, auth wordmark + links, signup "already have account" link,
  onboarding wordmark + language-chip label, confirm-dialog button label.
- Icons: selected check icons (day pills, time slots, explore chips,
  service cards), role icons, chairs stepper +/-, success check,
  empty-state / cover-fallback icons, profile check, splash logo icon.
- Also fixed: `DouriQueueNumber` (was dead code with hardcoded lime;
  now uses theme-aware `queueNumber` style) and one unused
  `app_colors` import in the details screen.

Deliberately left as brand lime: fills (`accentSoft`), borders
(selection/step-indicator/onboarding dots — state is redundantly
conveyed by check/number/bold), progress indicators, switch thumbs,
decorative glows/rings. Those are not text and do not carry meaning
by colour alone.

## RTL / responsive notes

- Numbers, times, prices and phone values are LTR-marked
  (`textDirection: TextDirection.ltr` or `ltrValue`) in booking,
  confirmation, ticket, details and profile screens; chevrons use
  `Icons.arrow_forward` (mirrors in RTL); step slides and bottom-nav
  pill are direction-aware.
- Fixed heights in changed screens are design heights only (hero 320,
  cover 110, horizontal list 250, 48dp touch targets, 2dp dividers) —
  no clipping heights; lists scroll; long labels ellipsised.
- 116dp bottom inset above the floating pill nav on all tab screens
  (Phase 8 fixed the profile screen, which had been missing it).

## Not verifiable on this VM (needs the user's run)

- `flutter analyze` / `flutter run` (no Flutter/Dart here).
- 375px small-phone and landscape rendering; largest system text size
  (Dynamic Type); reduced-motion behaviour on device (code paths are
  gated on `DouriMotion.reduced` but untested live).
- Switch thumb/track contrast in the light theme (pre-existing
  `activeColor: primaryAccent` switches, untouched by this pass).
