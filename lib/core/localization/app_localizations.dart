import 'package:flutter/material.dart';

/// Bilingual strings (Arabic RTL / English LTR). No widget in the app
/// should hardcode user-facing text — add a key here first.
/// Missing Arabic keys fall back to English via [_t].
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

  // --- Existing keys (preserved) ---
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

  // --- General ---
  String get open => _t('open');
  String get closed => _t('closed');
  String get save => _t('save');
  String get edit => _t('edit');
  String get delete => _t('delete');
  String get close => _t('close');
  String get back => _t('back');
  String get next => _t('next');
  String get skip => _t('skip');
  String get done => _t('done');
  String get search => _t('search');
  String get viewAll => _t('viewAll');
  String get today => _t('today');
  String get date => _t('date');
  String get time => _t('time');
  String get name => _t('name');
  String get status => _t('status');
  String get price => _t('price');
  String get minutes => _t('minutes');
  String get min => _t('min');
  String get required => _t('required');
  String get logout => _t('logout');
  String get language => _t('language');
  String get notifications => _t('notifications');
  String get account => _t('account');
  String get preferences => _t('preferences');
  String get all => _t('all');
  String get upcoming => _t('upcoming');
  String get pending => _t('pending');
  String get completed => _t('completed');
  String get cancelled => _t('cancelled');
  String get rejected => _t('rejected');
  String get confirmed => _t('confirmed');
  String get services => _t('services');
  String get service => _t('service');
  String get reviews => _t('reviews');
  String get address => _t('address');
  String get description => _t('description');
  String get available => _t('available');
  String get unavailable => _t('unavailable');
  String get noResults => _t('noResults');
  String get noResultsMessage => _t('noResultsMessage');
  String get tryAgain => _t('tryAgain');

  // --- Home / Explore ---
  String get hello => _t('hello');
  String get searchHint => _t('searchHint');
  String get featuredShops => _t('featuredShops');
  String get recommendedShops => _t('recommendedShops');
  String get nearbyShops => _t('nearbyShops');
  String get openNow => _t('openNow');
  String get activeBooking => _t('activeBooking');
  String get viewQueue => _t('viewQueue');
  String get noShops => _t('noShops');
  String get noShopsMessage => _t('noShopsMessage');
  String get discoverShops => _t('discoverShops');
  String get sortBy => _t('sortBy');
  String get nearest => _t('nearest');
  String get highestRated => _t('highestRated');
  String get noReviews => _t('noReviews');
  String get noReviewsMessage => _t('noReviewsMessage');

  // --- Onboarding / splash ---
  String get splashTagline => _t('splashTagline');
  String get onboarding1Title => _t('onboarding1Title');
  String get onboarding1Desc => _t('onboarding1Desc');
  String get onboarding2Title => _t('onboarding2Title');
  String get onboarding2Desc => _t('onboarding2Desc');
  String get onboarding3Title => _t('onboarding3Title');
  String get onboarding3Desc => _t('onboarding3Desc');

  // --- Auth ---
  String get loginTitle => _t('loginTitle');
  String get loginSubtitle => _t('loginSubtitle');
  String get enterPhone => _t('enterPhone');
  String get phoneHint => _t('phoneHint');
  String get sendCode => _t('sendCode');
  String get enterOtp => _t('enterOtp');
  String get otpSentTo => _t('otpSentTo');
  String get resendCode => _t('resendCode');
  String get resendIn => _t('resendIn');
  String get didntGetCode => _t('didntGetCode');
  String get invalidPhone => _t('invalidPhone');
  String get invalidOtp => _t('invalidOtp');
  String get loginFailed => _t('loginFailed');
  String get roleTitle => _t('roleTitle');
  String get roleSubtitle => _t('roleSubtitle');
  String get iamCustomer => _t('iamCustomer');
  String get iamBarber => _t('iamBarber');
  String get enterName => _t('enterName');
  String get saveProfile => _t('saveProfile');

  // --- Shop details / booking ---
  String get openingHours => _t('openingHours');
  String get contact => _t('contact');
  String get gallery => _t('gallery');
  String get currentQueue => _t('currentQueue');
  String get bookAppointment => _t('bookAppointment');
  String get bookingTitle => _t('bookingTitle');
  String get selectService => _t('selectService');
  String get selectDateTime => _t('selectDateTime');
  String get contactInfo => _t('contactInfo');
  String get reviewBooking => _t('reviewBooking');
  String get submitBooking => _t('submitBooking');
  String get bookingSummary => _t('bookingSummary');
  String get totalPrice => _t('totalPrice');
  String get duration => _t('duration');
  String get confirmBooking => _t('confirmBooking');
  String get bookingSuccess => _t('bookingSuccess');
  String get bookingSuccessMessage => _t('bookingSuccessMessage');
  String get bookingReference => _t('bookingReference');
  String get pendingApproval => _t('pendingApproval');
  String get queueNumberAfterApproval => _t('queueNumberAfterApproval');
  String get backToHome => _t('backToHome');
  String get trackQueue => _t('trackQueue');
  String get bookedSuccessfully => _t('bookedSuccessfully');
  String get chooseServiceFirst => _t('chooseServiceFirst');
  String get noServices => _t('noServices');
  String get noServicesMessage => _t('noServicesMessage');
  String get timeSlotTaken => _t('timeSlotTaken');

  // --- Queue ---
  String get queueTitle => _t('queueTitle');
  String get queueWaiting => _t('queueWaiting');
  String get queueApproaching => _t('queueApproaching');
  String get queueCurrent => _t('queueCurrent');
  String get queueCompleted => _t('queueCompleted');
  String get queueSkipped => _t('queueSkipped');
  String get queueCancelled => _t('queueCancelled');
  String get nowServing => _t('nowServing');
  String get yourPosition => _t('yourPosition');
  String get peopleAhead => _t('peopleAhead');
  String get waitTime => _t('waitTime');
  String get noActiveQueue => _t('noActiveQueue');
  String get noActiveQueueMessage => _t('noActiveQueueMessage');
  String get queueEnded => _t('queueEnded');
  String get leaveQueue => _t('leaveQueue');
  String get confirmLeaveQueue => _t('confirmLeaveQueue');
  String get confirmLeaveQueueMsg => _t('confirmLeaveQueueMsg');

  // --- My bookings / profile ---
  String get myBookings => _t('myBookings');
  String get noBookings => _t('noBookings');
  String get noBookingsMessage => _t('noBookingsMessage');
  String get editProfile => _t('editProfile');
  String get bookingHistory => _t('bookingHistory');
  String get favoriteShops => _t('favoriteShops');
  String get favoritesComingSoon => _t('favoritesComingSoon');
  String get themeSettings => _t('themeSettings');
  String get darkThemeOnly => _t('darkThemeOnly');
  String get memberSince => _t('memberSince');

  // --- Barber ---
  String get todaysBookings => _t('todaysBookings');
  String get waitingCustomers => _t('waitingCustomers');
  String get currentCustomer => _t('currentCustomer');
  String get completedToday => _t('completedToday');
  String get quickActions => _t('quickActions');
  String get noShopYet => _t('noShopYet');
  String get noShopMessage => _t('noShopMessage');
  String get createShop => _t('createShop');
  String get startDay => _t('startDay');
  String get endDay => _t('endDay');
  String get callNext => _t('callNext');
  String get markCompleted => _t('markCompleted');
  String get skipCustomer => _t('skipCustomer');
  String get confirmCallNext => _t('confirmCallNext');
  String get confirmCallNextMsg => _t('confirmCallNextMsg');
  String get confirmComplete => _t('confirmComplete');
  String get confirmCompleteMsg => _t('confirmCompleteMsg');
  String get confirmSkip => _t('confirmSkip');
  String get confirmSkipMsg => _t('confirmSkipMsg');
  String get noQueueToday => _t('noQueueToday');
  String get noQueueTodayMessage => _t('noQueueTodayMessage');
  String get queueNotStarted => _t('queueNotStarted');
  String get pendingRequests => _t('pendingRequests');
  String get todayBookings => _t('todayBookings');
  String get allBookings => _t('allBookings');
  String get noRequests => _t('noRequests');
  String get noRequestsMessage => _t('noRequestsMessage');
  String get rejectionReason => _t('rejectionReason');
  String get reasonOptional => _t('reasonOptional');
  String get shopName => _t('shopName');
  String get shopDescription => _t('shopDescription');
  String get shopAddress => _t('shopAddress');
  String get shopPhone => _t('shopPhone');
  String get appointmentDuration => _t('appointmentDuration');
  String get maxDailyBookings => _t('maxDailyBookings');
  String get saveChanges => _t('saveChanges');
  String get saved => _t('saved');
  String get servicesManagement => _t('servicesManagement');
  String get addService => _t('addService');
  String get serviceName => _t('serviceName');
  String get servicePrice => _t('servicePrice');
  String get serviceDuration => _t('serviceDuration');
  String get deleteService => _t('deleteService');
  String get confirmDelete => _t('confirmDelete');
  String get confirmDeleteMsg => _t('confirmDeleteMsg');
  String get coverImageUrl => _t('coverImageUrl');
  String get logoImageUrl => _t('logoImageUrl');
  String get workingHours => _t('workingHours');
  String get shopOpen => _t('shopOpen');
  String get shopClosed => _t('shopClosed');
  String get openShop => _t('openShop');
  String get closeShop => _t('closeShop');
  String get actionFailed => _t('actionFailed');
  String get queueAdvanced => _t('queueAdvanced');

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
      'open': 'مفتوح',
      'closed': 'مغلق',
      'save': 'حفظ',
      'edit': 'تعديل',
      'delete': 'حذف',
      'close': 'إغلاق',
      'back': 'رجوع',
      'next': 'التالي',
      'skip': 'تخطي',
      'done': 'تم',
      'search': 'بحث',
      'viewAll': 'عرض الكل',
      'today': 'اليوم',
      'date': 'التاريخ',
      'time': 'الوقت',
      'name': 'الاسم',
      'status': 'الحالة',
      'price': 'السعر',
      'minutes': 'دقيقة',
      'min': 'دقيقة',
      'required': 'مطلوب',
      'logout': 'تسجيل الخروج',
      'language': 'اللغة',
      'notifications': 'الإشعارات',
      'account': 'الحساب',
      'preferences': 'التفضيلات',
      'all': 'الكل',
      'upcoming': 'القادمة',
      'pending': 'قيد الانتظار',
      'completed': 'مكتملة',
      'cancelled': 'ملغاة',
      'rejected': 'مرفوضة',
      'confirmed': 'مؤكدة',
      'services': 'الخدمات',
      'service': 'الخدمة',
      'reviews': 'التقييمات',
      'address': 'العنوان',
      'description': 'الوصف',
      'available': 'متاح',
      'unavailable': 'غير متاح',
      'noResults': 'لا توجد نتائج',
      'noResultsMessage': 'جرّب كلمة بحث مختلفة أو أزل بعض الفلاتر.',
      'tryAgain': 'حاول مجدداً',
      'hello': 'مرحباً',
      'searchHint': 'ابحث عن صالون أو خدمة...',
      'featuredShops': 'صالونات مميزة',
      'recommendedShops': 'صالونات ننصح بها',
      'nearbyShops': 'صالونات قريبة منك',
      'openNow': 'مفتوح الآن',
      'activeBooking': 'حجزك النشط',
      'viewQueue': 'عرض الدور',
      'noShops': 'لا توجد صالونات بعد',
      'noShopsMessage': 'لم يتم العثور على أي صالون مسجّل. عُد لاحقاً.',
      'discoverShops': 'اكتشف الصالونات',
      'sortBy': 'ترتيب حسب',
      'nearest': 'الأقرب',
      'highestRated': 'الأعلى تقييماً',
      'noReviews': 'لا توجد تقييمات بعد',
      'noReviewsMessage': 'كن أول من يقيّم هذا الصالون بعد زيارتك.',
      'splashTagline': 'دورك. أسلوبك.',
      'onboarding1Title': 'اكتشف الصالونات القريبة',
      'onboarding1Desc': 'اعثر على أفضل صالونات الحلاقة حولك، وشاهد التقييمات والخدمات قبل أن تختار.',
      'onboarding2Title': 'احجز وقتك المفضل',
      'onboarding2Desc': 'اختر الخدمة والتاريخ والوقت المناسب لك في خطوات بسيطة، بدون انتظار على الهاتف.',
      'onboarding3Title': 'تابع دورك مباشرة',
      'onboarding3Desc': 'استلم رقم دورك وتابع تقدّم الطابور لحظة بلحظة، وتوجّه للصالون عندما يقترب دورك.',
      'loginTitle': 'أهلاً بك في دوري',
      'loginSubtitle': 'سجّل دخولك برقم هاتفك لمتابعة حجوزاتك ودورك.',
      'enterPhone': 'أدخل رقم هاتفك',
      'phoneHint': '5XX XXX XXX',
      'sendCode': 'إرسال رمز التحقق',
      'enterOtp': 'أدخل رمز التحقق',
      'otpSentTo': 'أرسلنا رمزاً إلى',
      'resendCode': 'إعادة إرسال الرمز',
      'resendIn': 'إعادة الإرسال خلال',
      'didntGetCode': 'لم يصلك الرمز؟',
      'invalidPhone': 'أدخل رقم هاتف صحيح (9 أرقام).',
      'invalidOtp': 'رمز التحقق غير صحيح، حاول مجدداً.',
      'loginFailed': 'تعذّر تسجيل الدخول، حاول مجدداً.',
      'roleTitle': 'كيف ستستخدم دوري؟',
      'roleSubtitle': 'اختر نوع حسابك لإكمال ملفك الشخصي.',
      'iamCustomer': 'أنا عميل',
      'iamBarber': 'أنا حلاق',
      'enterName': 'اكتب اسمك الكامل',
      'saveProfile': 'حفظ الملف الشخصي',
      'openingHours': 'أوقات العمل',
      'contact': 'التواصل',
      'gallery': 'المعرض',
      'currentQueue': 'الدور الحالي',
      'bookAppointment': 'احجز موعداً',
      'bookingTitle': 'احجز موعدك',
      'selectService': 'اختر الخدمة',
      'selectDateTime': 'اختر التاريخ والوقت',
      'contactInfo': 'بيانات التواصل',
      'reviewBooking': 'مراجعة الحجز',
      'submitBooking': 'إرسال الحجز',
      'bookingSummary': 'ملخص الحجز',
      'totalPrice': 'الإجمالي',
      'duration': 'المدة',
      'confirmBooking': 'تأكيد الحجز',
      'bookingSuccess': 'تم إرسال حجزك!',
      'bookingSuccessMessage': 'طلبك قيد الانتظار. سيصلك رقم الدور فور قبول الحلاق لحجزك.',
      'bookingReference': 'مرجع الحجز',
      'pendingApproval': 'بانتظار قبول الحلاق',
      'queueNumberAfterApproval': 'يظهر رقم دورك هنا بعد قبول الحلاق للحجز.',
      'backToHome': 'العودة للرئيسية',
      'trackQueue': 'تتبّع الدور',
      'bookedSuccessfully': 'تم الحجز بنجاح',
      'chooseServiceFirst': 'اختر خدمة أولاً للمتابعة.',
      'noServices': 'لا توجد خدمات بعد',
      'noServicesMessage': 'لم يضف هذا الصالون خدماته بعد. تواصل مع الصالون مباشرة.',
      'timeSlotTaken': 'هذا الوقت محجوز بالفعل، اختر وقتاً آخر.',
      'queueTitle': 'دورك',
      'queueWaiting': 'بانتظار الدور',
      'queueApproaching': 'دورك يقترب',
      'queueCurrent': 'دورك الآن',
      'queueCompleted': 'مكتمل',
      'queueSkipped': 'تم تخطيه',
      'queueCancelled': 'ملغى',
      'nowServing': 'يُخدم الآن',
      'yourPosition': 'موقعك في الطابور',
      'peopleAhead': 'أشخاص أمامك',
      'waitTime': 'وقت الانتظار',
      'noActiveQueue': 'لا يوجد دور نشط',
      'noActiveQueueMessage': 'ليس لديك حجز مؤكد برقم دور حالياً. احجز موعداً وسيظهر دورك هنا بعد القبول.',
      'queueEnded': 'انتهى الطابور',
      'leaveQueue': 'مغادرة الطابور',
      'confirmLeaveQueue': 'مغادرة الطابور؟',
      'confirmLeaveQueueMsg': 'سيتم إلغاء حجزك ولن تتمكن من استعادة رقم الدور.',
      'myBookings': 'حجوزاتي',
      'noBookings': 'لا توجد حجوزات',
      'noBookingsMessage': 'لم تقم بأي حجز بعد. اكتشف الصالونات واحجز موعدك الأول.',
      'editProfile': 'تعديل الملف الشخصي',
      'bookingHistory': 'سجل الحجوزات',
      'favoriteShops': 'الصالونات المفضلة',
      'favoritesComingSoon': 'المفضلة غير متوفرة بعد في قاعدة البيانات.',
      'themeSettings': 'المظهر',
      'darkThemeOnly': 'دوري يعمل بالوضع الداكن الفاخر فقط حالياً.',
      'memberSince': 'عضو',
      'todaysBookings': 'حجوزات اليوم',
      'waitingCustomers': 'عملاء بالانتظار',
      'currentCustomer': 'العميل الحالي',
      'completedToday': 'مكتملة اليوم',
      'quickActions': 'إجراءات سريعة',
      'noShopYet': 'لا يوجد صالون بعد',
      'noShopMessage': 'أنشئ صالونك من إدارة الصالون لتبدأ باستقبال الحجوزات.',
      'createShop': 'إنشاء صالون',
      'startDay': 'بدء اليوم',
      'endDay': 'إنهاء اليوم',
      'callNext': 'استدعاء التالي',
      'markCompleted': 'إنهاء العميل الحالي',
      'skipCustomer': 'تخطي العميل',
      'confirmCallNext': 'استدعاء العميل التالي؟',
      'confirmCallNextMsg': 'سيتم إنهاء العميل الحالي واستدعاء التالي في الطابور.',
      'confirmComplete': 'إنهاء العميل الحالي؟',
      'confirmCompleteMsg': 'سيتم وضع علامة مكتمل على العميل الحالي واستدعاء التالي.',
      'confirmSkip': 'تخطي هذا العميل؟',
      'confirmSkipMsg': 'سيتم وضع علامة تم تخطيه على هذا العميل واستدعاء التالي. لا يمكن التراجع.',
      'noQueueToday': 'لا يوجد طابور اليوم',
      'noQueueTodayMessage': 'ابدأ يوم العمل ليتمكن العملاء من الحجز واستلام أرقام الدور.',
      'queueNotStarted': 'لم يبدأ الطابور بعد',
      'pendingRequests': 'طلبات معلّقة',
      'todayBookings': 'حجوزات اليوم',
      'allBookings': 'كل الحجوزات',
      'noRequests': 'لا توجد طلبات',
      'noRequestsMessage': 'لا توجد طلبات حجز مطابقة لهذا التبويب حالياً.',
      'rejectionReason': 'سبب الرفض',
      'reasonOptional': 'السبب (اختياري)',
      'shopName': 'اسم الصالون',
      'shopDescription': 'وصف الصالون',
      'shopAddress': 'عنوان الصالون',
      'shopPhone': 'هاتف الصالون',
      'appointmentDuration': 'مدة الموعد (دقيقة)',
      'maxDailyBookings': 'أقصى حجوزات يومية',
      'saveChanges': 'حفظ التغييرات',
      'saved': 'تم الحفظ',
      'servicesManagement': 'إدارة الخدمات',
      'addService': 'إضافة خدمة',
      'serviceName': 'اسم الخدمة',
      'servicePrice': 'السعر',
      'serviceDuration': 'المدة (دقيقة)',
      'deleteService': 'حذف الخدمة',
      'confirmDelete': 'حذف؟',
      'confirmDeleteMsg': 'سيتم حذف هذا العنصر نهائياً.',
      'coverImageUrl': 'رابط صورة الغلاف',
      'logoImageUrl': 'رابط الشعار',
      'workingHours': 'أوقات العمل',
      'shopOpen': 'الصالون مفتوح',
      'shopClosed': 'الصالون مغلق',
      'openShop': 'فتح الصالون',
      'closeShop': 'إغلاق الصالون',
      'actionFailed': 'تعذّر تنفيذ الإجراء، حاول مجدداً.',
      'queueAdvanced': 'تم تقديم الطابور',
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
      'open': 'Open',
      'closed': 'Closed',
      'save': 'Save',
      'edit': 'Edit',
      'delete': 'Delete',
      'close': 'Close',
      'back': 'Back',
      'next': 'Next',
      'skip': 'Skip',
      'done': 'Done',
      'search': 'Search',
      'viewAll': 'View all',
      'today': 'Today',
      'date': 'Date',
      'time': 'Time',
      'name': 'Name',
      'status': 'Status',
      'price': 'Price',
      'minutes': 'min',
      'min': 'min',
      'required': 'Required',
      'logout': 'Log out',
      'language': 'Language',
      'notifications': 'Notifications',
      'account': 'Account',
      'preferences': 'Preferences',
      'all': 'All',
      'upcoming': 'Upcoming',
      'pending': 'Pending',
      'completed': 'Completed',
      'cancelled': 'Cancelled',
      'rejected': 'Rejected',
      'confirmed': 'Confirmed',
      'services': 'Services',
      'service': 'Service',
      'reviews': 'Reviews',
      'address': 'Address',
      'description': 'Description',
      'available': 'Available',
      'unavailable': 'Unavailable',
      'noResults': 'No results',
      'noResultsMessage': 'Try a different search term or clear some filters.',
      'tryAgain': 'Try again',
      'hello': 'Hello',
      'searchHint': 'Search shops or services...',
      'featuredShops': 'Featured shops',
      'recommendedShops': 'Recommended for you',
      'nearbyShops': 'Shops near you',
      'openNow': 'Open now',
      'activeBooking': 'Your active booking',
      'viewQueue': 'View queue',
      'noShops': 'No shops yet',
      'noShopsMessage': 'No registered shops were found. Check back later.',
      'discoverShops': 'Discover shops',
      'sortBy': 'Sort by',
      'nearest': 'Nearest',
      'highestRated': 'Highest rated',
      'noReviews': 'No reviews yet',
      'noReviewsMessage': 'Be the first to review this shop after your visit.',
      'splashTagline': 'Your turn. Your style.',
      'onboarding1Title': 'Discover nearby barbershops',
      'onboarding1Desc': 'Find the best barbershops around you and check ratings and services before you choose.',
      'onboarding2Title': 'Book your preferred time',
      'onboarding2Desc': 'Pick a service, date and time in a few simple steps — no phone calls, no waiting.',
      'onboarding3Title': 'Track your turn live',
      'onboarding3Desc': 'Get your queue number and follow the queue in real time, then head over when your turn is near.',
      'loginTitle': 'Welcome to DOURI',
      'loginSubtitle': 'Sign in with your phone number to follow your bookings and your turn.',
      'enterPhone': 'Enter your phone number',
      'phoneHint': '5XX XXX XXX',
      'sendCode': 'Send verification code',
      'enterOtp': 'Enter the verification code',
      'otpSentTo': 'We sent a code to',
      'resendCode': 'Resend code',
      'resendIn': 'Resend in',
      'didntGetCode': "Didn't get the code?",
      'invalidPhone': 'Enter a valid phone number (9 digits).',
      'invalidOtp': 'The verification code is incorrect, try again.',
      'loginFailed': 'Sign-in failed, please try again.',
      'roleTitle': 'How will you use DOURI?',
      'roleSubtitle': 'Choose your account type to complete your profile.',
      'iamCustomer': 'I am a customer',
      'iamBarber': 'I am a barber',
      'enterName': 'Type your full name',
      'saveProfile': 'Save profile',
      'openingHours': 'Opening hours',
      'contact': 'Contact',
      'gallery': 'Gallery',
      'currentQueue': 'Current queue',
      'bookAppointment': 'Book appointment',
      'bookingTitle': 'Book your appointment',
      'selectService': 'Select a service',
      'selectDateTime': 'Select date & time',
      'contactInfo': 'Contact details',
      'reviewBooking': 'Review booking',
      'submitBooking': 'Submit booking',
      'bookingSummary': 'Booking summary',
      'totalPrice': 'Total',
      'duration': 'Duration',
      'confirmBooking': 'Confirm booking',
      'bookingSuccess': 'Your booking was sent!',
      'bookingSuccessMessage': 'Your request is pending. You will receive your queue number as soon as the barber accepts your booking.',
      'bookingReference': 'Booking reference',
      'pendingApproval': 'Waiting for barber approval',
      'queueNumberAfterApproval': 'Your queue number will appear here once the barber accepts the booking.',
      'backToHome': 'Back to home',
      'trackQueue': 'Track queue',
      'bookedSuccessfully': 'Booked successfully',
      'chooseServiceFirst': 'Choose a service first to continue.',
      'noServices': 'No services yet',
      'noServicesMessage': 'This shop has not added any services yet. Contact the shop directly.',
      'timeSlotTaken': 'This time is already booked, pick another one.',
      'queueTitle': 'Your turn',
      'queueWaiting': 'Waiting in queue',
      'queueApproaching': 'Your turn is near',
      'queueCurrent': 'Your turn now',
      'queueCompleted': 'Completed',
      'queueSkipped': 'Skipped',
      'queueCancelled': 'Cancelled',
      'nowServing': 'Now serving',
      'yourPosition': 'Your position in the queue',
      'peopleAhead': 'People ahead of you',
      'waitTime': 'Wait time',
      'noActiveQueue': 'No active queue',
      'noActiveQueueMessage': 'You have no confirmed booking with a queue number right now. Book an appointment and your turn will appear here after acceptance.',
      'queueEnded': 'Queue ended',
      'leaveQueue': 'Leave queue',
      'confirmLeaveQueue': 'Leave the queue?',
      'confirmLeaveQueueMsg': 'Your booking will be cancelled and your queue number cannot be restored.',
      'myBookings': 'My bookings',
      'noBookings': 'No bookings',
      'noBookingsMessage': 'You have not booked anything yet. Discover shops and book your first appointment.',
      'editProfile': 'Edit profile',
      'bookingHistory': 'Booking history',
      'favoriteShops': 'Favorite shops',
      'favoritesComingSoon': 'Favorites are not available in the database yet.',
      'themeSettings': 'Appearance',
      'darkThemeOnly': 'DOURI currently runs in the premium dark theme only.',
      'memberSince': 'Member',
      'todaysBookings': "Today's bookings",
      'waitingCustomers': 'Waiting customers',
      'currentCustomer': 'Current customer',
      'completedToday': 'Completed today',
      'quickActions': 'Quick actions',
      'noShopYet': 'No shop yet',
      'noShopMessage': 'Create your shop from Shop Management to start receiving bookings.',
      'createShop': 'Create shop',
      'startDay': 'Start day',
      'endDay': 'End day',
      'callNext': 'Call next',
      'markCompleted': 'Finish current customer',
      'skipCustomer': 'Skip customer',
      'confirmCallNext': 'Call the next customer?',
      'confirmCallNextMsg': 'The current customer will be finished and the next in queue will be called.',
      'confirmComplete': 'Finish the current customer?',
      'confirmCompleteMsg': 'The current customer will be marked completed and the next will be called.',
      'confirmSkip': 'Skip this customer?',
      'confirmSkipMsg': 'This customer will be marked as skipped and the next will be called. This cannot be undone.',
      'noQueueToday': 'No queue today',
      'noQueueTodayMessage': 'Start the working day so customers can book and receive queue numbers.',
      'queueNotStarted': 'Queue has not started yet',
      'pendingRequests': 'Pending requests',
      'todayBookings': "Today's bookings",
      'allBookings': 'All bookings',
      'noRequests': 'No requests',
      'noRequestsMessage': 'There are no booking requests matching this tab right now.',
      'rejectionReason': 'Rejection reason',
      'reasonOptional': 'Reason (optional)',
      'shopName': 'Shop name',
      'shopDescription': 'Shop description',
      'shopAddress': 'Shop address',
      'shopPhone': 'Shop phone',
      'appointmentDuration': 'Appointment duration (min)',
      'maxDailyBookings': 'Max daily bookings',
      'saveChanges': 'Save changes',
      'saved': 'Saved',
      'servicesManagement': 'Services management',
      'addService': 'Add service',
      'serviceName': 'Service name',
      'servicePrice': 'Price',
      'serviceDuration': 'Duration (min)',
      'deleteService': 'Delete service',
      'confirmDelete': 'Delete?',
      'confirmDeleteMsg': 'This item will be permanently deleted.',
      'coverImageUrl': 'Cover image URL',
      'logoImageUrl': 'Logo image URL',
      'workingHours': 'Working hours',
      'shopOpen': 'Shop is open',
      'shopClosed': 'Shop is closed',
      'openShop': 'Open shop',
      'closeShop': 'Close shop',
      'actionFailed': 'Action failed, please try again.',
      'queueAdvanced': 'Queue advanced',
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
