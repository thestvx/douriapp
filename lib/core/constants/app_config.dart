class AppConfig {
  const AppConfig._();

  // Supabase project qfkgftydtmgixikqgzcp — publishable (anon) key only.
  // Never put a service_role key here.
  static const String supabaseUrl = 'https://qfkgftydtmgixikqgzcp.supabase.co';
  static const String supabaseAnonKey = 'sb_publishable_Cr3g4hGMjb3TfXA9Hv2UUg_rhEMy8_I';

  // Firebase is configured via google-services.json / firebase_options.dart.

  // Cloudinary (shop logo + cover uploads). Only the public cloud name
  // and the UNSIGNED upload preset live here — uploads need no key or
  // secret in the app. The API secret must never be put in client code;
  // it stays in the Cloudinary dashboard only.
  static const String cloudinaryCloudName = 'r3bgsz17';
  static const String cloudinaryUploadPreset = 'douri_unsigned';
}
