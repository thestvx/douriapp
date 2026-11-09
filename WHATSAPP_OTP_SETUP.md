# تسجيل الدخول عبر واتساب — WhatsApp OTP (Cloud API)

> **ملاحظة (2026-11-09): التسجيل برقم الهاتف متوقف مؤقتاً** — Meta رفض
> إكمال تسجيل رقم الإنتاج (خطأ سياسات #2494070) ولا توجد وثائق رسمية
> لتوثيق النشاط التجاري. التطبيق الآن يسجّل الدخول بالإيميل وكلمة
> المرور عبر Firebase Auth. هذا المستند والـ Edge Function
> `send-whatsapp-otp` يبقيان في الريبو للعودة إلى واتساب لاحقاً عند
> توفر الوثائق.

التطبيق الآن يرسل رمز التحقق إلى **واتساب** المستخدم بدل SMS.

## كيف يعمل

```
المستخدم يدخل رقمه في التطبيق
        ↓
Supabase Auth ينشئ رمز OTP من 6 أرقام ويحفظه
        ↓
Supabase يرسل الرمز إلى Edge Function ‏(send-whatsapp-otp)‏
عبر "Send SMS hook"
        ↓
الـ Function ترسل الرمز برسالة واتساب عبر Meta Cloud API
باستخدام قالب Authentication معتمد (زر "نسخ الرمز")
        ↓
المستخدم يدخل الرمز → Supabase يتحقّق منه ويسجّل دخوله
```

- **Firebase Auth لم يعد يُستخدم للدخول** (بقي Firebase فقط للإشعارات FCM).
- الدخول الآن عبر **Supabase Auth**، وهذا يصلح أيضاً مشكلة قديمة:
  معرّف المستخدم أصبح هو نفسه في Supabase Auth وقاعدة البيانات
  (`auth.uid()`)، فسياسات RLS تعمل كما يجب.
- Supabase هو من ينشئ الرمز ويتحقّق منه؛ الـ Function مهمتها
  **الإرسال فقط** ولا تحفظ الرمز.

## 1) إعداد Meta (واتساب) — خطواتك أنت

1. ادخل إلى [Meta Developers](https://developers.facebook.com/) وأنشئ تطبيقاً،
   وأضف منتج **WhatsApp**.
2. في **WhatsApp > API Setup**:
   - أنشئ / اربط **WhatsApp Business Account (WABA)**.
   - سجّل رقم هاتف المُرسِل (رقم واتساب بزنس خاص بدوري).
     الرقم التجريبي الذي تعطيه Meta يعمل فقط مع أرقام اختبار مسجّلة —
     للإنتاج سجّل رقمك الخاص.
   - انسخ **Phone Number ID** (رقم تعريفي، ليس رقم الهاتف نفسه).
3. أنشئ قالب **Authentication**:
   - في **WhatsApp Manager > Message Templates > Create Template**.
   - الفئة: **Authentication**، الاسم مثلاً `douri_otp`، اللغة `en_US`
     (ويمكن إضافة نسخة `ar` بنفس الاسم).
   - اختر قالب كلمة المرور لمرة واحدة الجاهز من مكتبة القوالب
     (جسم فيه متغير الرمز + زر **Copy code** + مدة الصلاحية 5 دقائق).
   - قوالب المصادقة تُعتمَد عادةً خلال دقائق.
4. أنشئ **توكن دائم** (Permanent token):
   - في **Business Settings > Users > System Users** أنشئ System User
     بصلاحية `whatsapp_business_messaging`.
   - ولّد توكن من هذا المستخدم (التوكن المؤقت من لوحة API Setup
     ينتهي خلال 24 ساعة — لا تستخدمه للإنتاج).
5. **الفوترة**: اربط طريقة دفع في Meta Business — رسائل المصادقة
   تُحاسَب لكل رسالة (سعر رسالة المصادقة في أمريكا ~0.005$؛
   تحقّق من سعر الجزائر في بطاقة أسعار Meta قبل الإطلاق).

## 2) نشر الـ Edge Function وإعداد Supabase — خطواتك أنت

من مجلد المشروع على جهازك (مثبّت فيه Supabase CLI):

```bash
supabase login
supabase link --project-ref qfkgftydtmgixikqgzcp

# أسرار واتساب (لا تضعها في الكود أبداً)
supabase secrets set WHATSAPP_ACCESS_TOKEN="<التوكن الدائم>"
supabase secrets set WHATSAPP_PHONE_NUMBER_ID="<Phone Number ID>"
supabase secrets set WHATSAPP_TEMPLATE_NAME="douri_otp"
supabase secrets set WHATSAPP_TEMPLATE_LANGUAGE="en_US"

supabase functions deploy send-whatsapp-otp
```

ثم في لوحة Supabase:

1. **Authentication > Providers > Phone**: فعّل **Phone**.
   لا حاجة لإدخال بيانات مزوّد SMS — الـ Hook يتولّى الإرسال.
2. **Authentication > Hooks > Send SMS hook**:
   - النوع: **HTTPS**.
   - الرابط: `https://qfkgftydtmgixikqgzcp.supabase.co/functions/v1/send-whatsapp-otp`
   - اضغط **Generate secret** وانسخ القيمة (`v1,whsec_...`)، ثم احفظ.
   - ضع نفس القيمة سرّاً في الـ Function:
     ```bash
     supabase secrets set SEND_SMS_HOOK_SECRET="v1,whsec_..."
     supabase functions deploy send-whatsapp-otp
     ```
     (بهذا تتحقّق الـ Function من توقيع Supabase وترفض أي طلب آخر.)
3. **للتجربة بدون تكلفة**: في **Authentication > Providers > Phone >
   Test Phone Numbers** أضف رقم اختبار ورمزاً ثابتاً — عندها لا يُستدعى
   الـ Hook ولا تُرسَل رسالة واتساب.

## 3) تشغيل التطبيق

```bash
git pull origin main
flutter pub get
flutter run
```

> ملاحظة: قبل أن يعمل الدخول فعلياً يجب تشغيل الـ migrations في
> Supabase SQL Editor (`001_init.sql` ثم `002_functions.sql`) — بدونها
> لا توجد جداول الملفات الشخصية بعد تسجيل الدخول.

## حدود مهمة

- المستخدم **يجب أن يكون لديه واتساب** على نفس الرقم، وإلا لن يصله الرمز.
  لا يوجد حالياً رجوع تلقائي إلى SMS — إذا احتجته لاحقاً نضيف زر
  "أرسل عبر SMS بدلاً من ذلك".
- رسائل واتساب ليست مجانية: Meta تحاسب على كل رسالة مصادقة تُرسَل.
  الـ 1000 المجانية شهرياً هي لرسائل الخدمة (ردود)، وليست لرسائل OTP.
- رقم المُرسِل يجب أن يبقى متصلاً بـ WABA، والتوكن الدائم يجب
  تجديده إذا ألغيته أو غيّرت صلاحيات System User.
- قالب المصادقة له صيغة ثابتة من Meta: الرمز في الجسم + زر نسخ الرمز.
  لا يمكن إرسال نص حر كـ OTP.

## الملفات ذات العلاقة

- `supabase/functions/send-whatsapp-otp/index.ts` — الـ Edge Function.
- `lib/features/authentication/auth_repository.dart` — الدخول عبر Supabase Auth.
- `lib/features/authentication/auth_screen.dart` — شاشة الدخول (نصوص واتساب).
- `lib/features/authentication/auth_providers.dart` — حالة الدخول.
- `pubspec.yaml` — أُزيلت حزمة `firebase_auth`.
