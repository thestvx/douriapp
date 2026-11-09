# رفع صور الصالون عبر Cloudinary

الحلاق يقدر يرفع **لوغو** و **صورة غلاف** لصالونه من شاشة إدارة
الصالون (`/barber/shop`): زر رفع بجانب كل حقل، يختار صورة من
المعرض، تُرفع إلى Cloudinary، ويظهر الرابط في الحقل مع معاينة —
ويُحفظ نهائياً عند الضغط على **حفظ التغييرات**.

## كيف يعمل

- الرفع يستخدم **Unsigned Upload Preset** — التطبيق يحتاج فقط اسم
  السحابة (Cloud name) واسم الـ preset. **لا يوجد أي مفتاح سري في
  التطبيق**، والـ API secret يبقى في لوحة Cloudinary فقط ولا يُشارك
  مع أحد.
- القيم في الكود (`lib/core/constants/app_config.dart`):
  - `cloudinaryCloudName = 'r3bgsz17'`
  - `cloudinaryUploadPreset = 'douri_unsigned'`
- الصور تُرفع إلى مجلدات `douri/logos` و `douri/covers`، وتُحفظ
  روابطها في `barber_shops.logo_url` و `cover_image_url`.

## خطوة واحدة بقيت عليك: إنشاء الـ Upload Preset

1. ادخل إلى [Cloudinary Console](https://console.cloudinary.com/)
   واختر **Settings** (الترس) ثم **Upload** من القائمة.
2. انزل إلى **Upload presets** واضغط **Add upload preset**.
3. املأ:
   - **Preset name:** `douri_unsigned` (بالضبط كما في الكود)
   - **Signing mode:** `Unsigned`
   - **Folder:** `douri` (اختياري)
4. اضغط **Save**.

بدون هذه الخطوة، الرفع يفشل برسالة `Upload preset not found` —
والتطبيق يعرض لك هذه الرسالة بوضوح بدل خطأ عام.

## ملاحظات

- الصور المرفوعة تظهر في مكتبة Cloudinary Media Library، وتقدر
  تحذفها أو تستبدلها من هناك.
- حدّ حجم الصورة في التطبيق: 1600px وجودة 85% (تقليل استهلاك
  البيانات والتخزين).
- إذا غيّرت اسم الـ preset لاحقاً، غيّره في `app_config.dart`
  بنفس الاسم.

## الملفات ذات العلاقة

- `lib/core/services/cloudinary_service.dart` — الرفع إلى Cloudinary.
- `lib/features/barber/shop_management/shop_management_screen.dart`
  — أزرار الرفع والمعاينة.
- `lib/core/constants/app_config.dart` — اسم السحابة والـ preset.
