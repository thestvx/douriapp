# DOURI Setup

## Flutter
1. Install Flutter SDK and Android Studio.
2. Run `flutter pub get`.

## Fonts
Fonts are already in `fonts/en` and `fonts/ar`.

## Firebase
1. Create a Firebase project.
2. Enable Phone Authentication.
3. Add an Android app with package name `com.douri.douri` (or your chosen applicationId).
4. Download `google-services.json` and place it in `android/app/`.
5. Configure Firebase Cloud Messaging.

## Supabase
1. Create a Supabase project.
2. Run SQL migrations in `supabase/migrations`.
3. Deploy Edge Functions in `supabase/functions`.
4. Configure Firebase as a Third-Party Auth provider.
5. Set `SUPABASE_URL` and `SUPABASE_ANON_KEY` in `lib/core/constants/app_config.dart`.

## Framer Design Reference
https://framer.com/projects/Groat-copy--jGhnF5ZJeObRHyMpYiSf-75GGT?node=augiA20Il
