# الأثيوبي للعقارات | Al-Ethiopi Real Estate

منصة عقارية يمنية — تطبيق أندرويد حقيقي وجاهز للنشر على Google Play، مبني بـ
**Flutter + Firebase** (بدون أي سيرفر خاص).

A production-ready Yemeni real-estate marketplace: Flutter mobile app +
Firebase backend (Auth, Firestore, Storage, FCM). No VPS needed.

---

## ✨ المميزات | Features

**للمستخدمين | Users**

- تصفح العقارات: شقق ومنازل وفلل وأراضٍ ومحلات ومكاتب وعمارات (بيع/إيجار)
- بحث فوري يدعم العربية + فلاتر متقدمة (السعر، المساحة، الغرف، المدينة، المنطقة، الحالة، الترتيب)
- بطاقات عقارات عصرية + صفحة تفاصيل كاملة (معرض صور، مواصفات، مميزات، خريطة معلومات المعلن)
- معرض صور بملء الشاشة مع التقريب (Pinch-to-zoom)
- اتصال مباشر `tel:` + واتساب مباشر `wa.me`
- مفضلة (Firestore للمسجلين + تخزين محلي للضيوف)
- مشاركة عبر تطبيقات أندرويد + نسخ الرابط
- تعليقات + تقييم بالنجوم (1-5) + إعجابات + إبلاغ عن التعليقات المسيئة
- إشعارات (FCM push + صندوق إشعارات داخل التطبيق)
- دعم عدم الاتصال (Offline persistence + مؤشرات واضحة)
- واجهة عربية RTL كاملة بخط Cairo

**للإدارة (مدير واحد) | Admin**

- لوحة تحكم بإحصائيات (العقارات، البيع/الإيجار، المميزة، المباعة/المؤجرة، التعليقات، البلاغات، المستخدمون)
- إضافة/تعديل/حذف العقارات + رفع صور متعددة + اختيار الرئيسية + نشر/إخفاء + تمييز + حالة (متاح/مؤجر/مباع/غير متاح)
- إدارة الأنواع والمدن والمناطق والمميزات
- إدارة التعليقات (إخفاء/حذف) + مراجعة البلاغات + صندوق رسائل التواصل
- إرسال إشعارات + إعدادات التطبيق (بيانات التواصل + عن التطبيق/الشروط/الخصوصية)
- صلاحيات المدير عبر `admin` custom claim + قواعد أمان صارمة (لا تعتمد على إخفاء الأزرار)

## 🛠 التقنيات | Stack

| الطبقة | التقنية |
|---|---|
| التطبيق | Flutter + Dart (Material 3, RTL) |
| الحالة | Riverpod 2 |
| المصادقة | Firebase Authentication (بريد + Google) |
| قاعدة البيانات | Cloud Firestore (Offline persistence) |
| الصور | Firebase Storage (ضغط تلقائي قبل الرفع) |
| الإشعارات | FCM + Cloud Functions + Local notifications |
| الأمان | Custom claims + Firestore/Storage Security Rules + App Check |
| مهام الخلفية | Cloud Functions (serverless — بدون VPS) |

## 🚀 التشغيل السريع | Quick start

```bash
flutter pub get
flutter run
```

> بدون `google-services.json` يعمل التطبيق في **وضع العرض** (Demo mode) ببيانات
> يمنية تجريبية كاملة — جرّب الدخول بـ `admin@alethiopi.com` (أي كلمة مرور)
> لاستكشاف لوحة الإدارة.

**للتشغيل الحقيقي على Firebase:** اتبع الدليل خطوة بخطوة:

- 📖 [دليل إعداد Firebase (عربي)](docs/FIREBASE_SETUP_AR.md)
- 📖 [Firebase setup (English)](docs/FIREBASE_SETUP_EN.md)
- 🚀 [دليل النشر على Google Play](docs/GOOGLE_PLAY_RELEASE.md)

## 📁 البنية | Structure

```
lib/
  main.dart, app.dart          # bootstrap + root widget (Arabic RTL)
  core/                        # constants, errors, utils, shared widgets
  theme/                       # emerald+gold Material 3 theme (Cairo font)
  l10n/                        # Arabic strings catalog (EN-ready)
  models/                      # Firestore models (fromMap/toMap, Equatable)
  firebase/                    # collection paths + Riverpod Firebase providers
  repositories/                # Firestore/Storage/Auth access (+ demo branches)
  demo/                        # demo-mode store + Yemeni seed data
  providers/                   # Riverpod state (auth, filters, lists, admin…)
  services/                    # FCM/local notifications, cache
  screens/                     # splash, home, properties, search, auth,
                               # profile, contact, notifications, admin/…
  routes/                      # named routes + typed arguments
test/                          # unit tests (validators, formatters, models…)
android/                       # Play-ready native shell (API 23–35)
functions/                     # Cloud Functions: counters + push
scripts/                       # seed_demo_data.js, make_admin.js
firestore.rules / storage.rules / firestore.indexes.json
```

## 🔐 الأمان | Security

- القراءة العامة للمحتوى المنشور فقط؛ الكتابة الإدارية تتطلب `request.auth.token.admin == true`.
- المستخدم يعدّل/يحذف **تعليقاته فقط**؛ تقييم واحد لكل مستخدم لكل عقار (`ratings/{propertyId}_{uid}`).
- المفضلة في `users/{uid}/favorites` — لا يستطيع أحد رؤية مفضلة غيره.
- العدّادات (`ratingAvg`, `commentsCount`…) تحدّثها Cloud Functions — العميل لا يكتبها أبداً.
- التحقق من المدخلات (هاتف، سعر، مساحة، طول التعليق، نوع/حجم الصور) في التطبيق **وفي القواعد**.

## 💰 التكلفة | Costs

يعمل التطبيق ضمن الحدود المجانية لـ Firebase في البداية (Spark)، ما عدا
Cloud Functions من الجيل الثاني التي تتطلب خطة Blaze (الدفع حسب الاستخدام —
غالباً 0$ مع الحدود المجانية: 2M استدعاء/شهر). التفاصيل في دليل الإعداد.

## 🧪 الجودة | Quality

```bash
flutter analyze --no-fatal-infos   # static analysis
flutter test                       # unit tests
flutter build apk --debug          # compile check
flutter build appbundle --release  # Play Store artifact
```

CI (GitHub Actions): ملف `ci/flutter_ci.yml` جاهز — انسخه إلى `.github/workflows/flutter_ci.yml` ليُشغَّل التحليل + الاختبارات + بناء APK تلقائياً عند كل دفع.

## 📄 الترخيص

حقوق الملكية محفوظة لصاحب المشروع. الخط المستخدم Cairo (SIL OFL) — انظر
[assets/fonts/ATTRIBUTION.md](assets/fonts/ATTRIBUTION.md).
