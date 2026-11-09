import 'package:flutter/material.dart';

class AppLocalizations {
  const AppLocalizations(this.locale);

  final Locale locale;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  bool get isArabic => locale.languageCode == 'ar';

  String _t(String key) => _strings[locale.languageCode]?[key] ?? _strings['en']![key] ?? key;

  String get appName => _t('appName');
  String get slogan => _t('slogan');
  String get getStarted => _t('getStarted');
  String get signIn => _t('signIn');
  String get signUp => _t('signUp');
  String get phone => _t('phone');
  String get otp => _t('otp');
  String get verify => _t('verify');
  String get home => _t('home');
  String get explore => _t('explore');
  String get bookings => _t('bookings');
  String get profile => _t('profile');
  String get dashboard => _t('dashboard');
  String get bookingRequests => _t('bookingRequests');
  String get queueManagement => _t('queueManagement');
  String get shopManagement => _t('shopManagement');
  String get settings => _t('settings');
  String get startWorkingDay => _t('startWorkingDay');
  String get nextCustomer => _t('nextCustomer');
  String get approve => _t('approve');
  String get reject => _t('reject');
  String get cancel => _t('cancel');
  String get confirm => _t('confirm');
  String get loading => _t('loading');
  String get empty => _t('empty');
  String get error => _t('error');
  String get retry => _t('retry');
  String get queueNumber => _t('queueNumber');
  String get yourTurn => _t('yourTurn');
  String get customersAhead => _t('customersAhead');
  String get estimatedWait => _t('estimatedWait');
  String get bookNow => _t('bookNow');
  String get selectDate => _t('selectDate');
  String get selectTime => _t('selectTime');
  String get fullName => _t('fullName');
  String get phoneNumber => _t('phoneNumber');
  String get bookingPending => _t('bookingPending');
  String get bookingConfirmed => _t('bookingConfirmed');
  String get bookingRejected => _t('bookingRejected');
  String get bookingCancelled => _t('bookingCancelled');
  String get bookingCompleted => _t('bookingCompleted');

  static const Map<String, Map<String, String>> _strings = {
    'ar': {
      'appName': 'دوري',
      'slogan': 'دورك. أسلوبك.',
      'getStarted': 'ابدأ',
      'signIn': 'تسجيل الدخول',
      'signUp': 'إنشاء حساب',
      'phone': 'رقم الهاتف',
      'otp': 'رمز التحقق',
      'verify': 'تحقق',
      'home': 'الرئيسية',
      'explore': 'استكشف',
      'bookings': 'حجوزاتي',
      'profile': 'حسابي',
      'dashboard': 'لوحة التحكم',
      'bookingRequests': 'طلبات الحجز',
      'queueManagement': 'إدارة الطابور',
      'shopManagement': 'إدارة الصالون',
      'settings': 'الإعدادات',
      'startWorkingDay': 'بدء يوم العمل',
      'nextCustomer': 'العميل التالي',
      'approve': 'قبول',
      'reject': 'رفض',
      'cancel': 'إلغاء',
      'confirm': 'تأكيد',
      'loading': 'جارٍ التحميل...',
      'empty': 'لا توجد بيانات',
      'error': 'حدث خطأ',
      'retry': 'إعادة المحاولة',
      'queueNumber': 'رقم الدور',
      'yourTurn': 'دورك الآن',
      'customersAhead': 'عملاء أمامك',
      'estimatedWait': 'وقت الانتظار التقريبي',
      'bookNow': 'احجز الآن',
      'selectDate': 'اختر التاريخ',
      'selectTime': 'اختر الوقت',
      'fullName': 'الاسم الكامل',
      'phoneNumber': 'رقم الهاتف',
      'bookingPending': 'قيد الانتظار',
      'bookingConfirmed': 'مؤكد',
      'bookingRejected': 'مرفوض',
      'bookingCancelled': 'ملغى',
      'bookingCompleted': 'مكتمل',
    },
    'en': {
      'appName': 'DOURI',
      'slogan': 'YOUR TURN. YOUR STYLE.',
      'getStarted': 'Get Started',
      'signIn': 'Sign In',
      'signUp': 'Sign Up',
      'phone': 'Phone Number',
      'otp': 'Verification Code',
      'verify': 'Verify',
      'home': 'Home',
      'explore': 'Explore',
      'bookings': 'My Bookings',
      'profile': 'Profile',
      'dashboard': 'Dashboard',
      'bookingRequests': 'Booking Requests',
      'queueManagement': 'Queue Management',
      'shopManagement': 'Shop Management',
      'settings': 'Settings',
      'startWorkingDay': 'Start Working Day',
      'nextCustomer': 'Next Customer',
      'approve': 'Approve',
      'reject': 'Reject',
      'cancel': 'Cancel',
      'confirm': 'Confirm',
      'loading': 'Loading...',
      'empty': 'No data',
      'error': 'Something went wrong',
      'retry': 'Retry',
      'queueNumber': 'Queue Number',
      'yourTurn': 'Your Turn',
      'customersAhead': 'Customers ahead',
      'estimatedWait': 'Estimated wait',
      'bookNow': 'Book Now',
      'selectDate': 'Select date',
      'selectTime': 'Select time',
      'fullName': 'Full name',
      'phoneNumber': 'Phone number',
      'bookingPending': 'Pending',
      'bookingConfirmed': 'Confirmed',
      'bookingRejected': 'Rejected',
      'bookingCancelled': 'Cancelled',
      'bookingCompleted': 'Completed',
    },
  };
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['ar', 'en'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async => AppLocalizations(locale);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
