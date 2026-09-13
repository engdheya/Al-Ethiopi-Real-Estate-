# دليل إعداد Firebase — الأثيوبي للعقارات

> هذا الدليل يشرح **بالضبط** ما يجب فعله لتشغيل التطبيق على Firebase الحقيقي.
> لا حاجة لأي سيرفر خاص (VPS) — كل شيء يعمل على البنية السحابية لـ Firebase.

**المتطلبات:** حساب Google + تثبيت Flutter (الإصدار المستقر 3.24 أو أحدث).

---

## 1. إنشاء مشروع Firebase

1. ادخل إلى [Firebase Console](https://console.firebase.google.com/).
2. اضغط **Add project** (إضافة مشروع).
3. اسم المشروع مثلاً: `alethiopi-real-estate`.
4. عطّل Google Analytics (اختياري) ثم اضغط **Create project**.

## 2. إضافة تطبيق أندرويد

1. من لوحة المشروع اضغط أيقونة **Android**.
2. **Android package name** (يجب أن يطابق التطبيق حرفياً):
   ```
   com.alethiopi.realestate
   ```
   > إذا غيّرت هذا الاسم لاحقاً، يجب تغييره في
   > `android/app/build.gradle.kts` و`AndroidManifest` واسم الحزمة في `MainActivity.kt`.
3. App nickname: `الأثيوبي للعقارات`.
4. **SHA-1 (مهم لتسجيل الدخول عبر Google):**
   - من مجلد المشروع نفّذ:
     ```bash
     cd android && ./gradlew signingReport
     ```
   - انسخ قيمة `SHA1` الخاصة بـ `debug` وأضفها، ثم أضف `SHA1` مفتاح النشر لاحقاً (انظر دليل النشر).

## 3. تحميل `google-services.json`

1. بعد تسجيل التطبيق، حمّل ملف **`google-services.json`**.
2. ضعه في هذا المسار **بالضبط**:
   ```
   android/app/google-services.json
   ```
3. بدونه يعمل التطبيق في **وضع العرض** (بيانات تجريبية) ولن يتصل بـ Firebase.

## 4. تفعيل Authentication

1. من القائمة: **Build > Authentication > Get started**.
2. فعّل **Email/Password** (البريد وكلمة المرور).
3. (مستحسن) فعّل **Google** كطريقة دخول إضافية:
   - اختر بريد الدعم الخاص بالمشروع ثم **Save**.

## 5. إنشاء قاعدة بيانات Firestore

1. من القائمة: **Build > Firestore Database > Create database**.
2. اختر **Start in production mode** (سنضيف القواعد الصحيحة بعد قليل).
3. اختر المنطقة الأقرب (مثلاً `europe-west1`) — لا يمكن تغييرها لاحقاً.

## 6. تفعيل Storage

1. من القائمة: **Build > Storage > Get started**.
2. ابدأ في **production mode** بنفس المنطقة.

## 7. تفعيل Cloud Messaging (للإشعارات)

1. خدمة FCM تكون متاحة تلقائياً مع مشروع Firebase.
2. لا حاجة لأي مفتاح إضافي في التطبيق — التطبيق يستخدم `google-services.json` تلقائياً.

## 8. نشر قواعد الأمان والفهارس

ثبّت Firebase CLI مرة واحدة:

```bash
npm install -g firebase-tools
firebase login
firebase use --add        # اختر مشروعك
```

ثم من جذر المشروع:

```bash
firebase deploy --only firestore:rules,firestore:indexes,storage
```

> ملفات القواعد: `firestore.rules` و`storage.rules` و`firestore.indexes.json`.
> بناء الفهارس المركبة قد يستغرق دقائق — تابع حالتها من تبويب **Indexes**.

## 9. نشر Cloud Functions (العدّادات + الإشعارات الفورية)

مجلد `functions/` يحتوي دوالاً serverless (بدون سيرفر) لتحديث العدّادات
(التعليقات/التقييمات/المفضلة) وإرسال الإشعارات الفورية:

```bash
cd functions && npm install && cd ..
firebase deploy --only functions
```

> تحتاج خطة **Blaze** (الدفع حسب الاستخدام) لنشر Functions من الجيل الثاني،
> لكن ضمن الحدود المجانية السخية غالباً لن تدفع شيئاً في البداية.
> بدون نشرها: يعمل التطبيق كاملاً ما عدا (تحديث العدّادات تلقائياً + Push).
> صندوق الإشعارات داخل التطبيق يعمل دائماً لأنه يقرأ من Firestore.

## 10. تعبئة البيانات التجريبية (اختياري)

```bash
cd scripts && npm install
```

1. من Firebase Console: **Project settings > Service accounts > Generate new private key**.
2. نفّذ:
   ```bash
   GOOGLE_APPLICATION_CREDENTIALS=/path/to/key.json node seed_demo_data.js
   ```
3. سيضيف: 8 أنواع عقارات، 8 مدن، ~30 منطقة، 12 ميزة، 5 عقارات، وإعدادات التطبيق.

## 11. إنشاء حساب المدير الوحيد

1. شغّل التطبيق وسجّل حساباً جديداً ببريدك (هذا سيكون حساب المدير).
2. نفّذ سكربت منح الصلاحية:
   ```bash
   cd scripts
   GOOGLE_APPLICATION_CREDENTIALS=/path/to/key.json node make_admin.js you@example.com
   ```
3. سجّل الخروج من التطبيق ثم سجّل الدخول مرة أخرى.
4. ستظهر بطاقة **لوحة الإدارة** في تبويب الحساب.

> الأمان يعتمد على `admin` custom claim فقط — لا يوجد أي زر أو حقل في التطبيق
> يمكن أن يمنح صلاحيات المدير، وقواعد Firestore ترفض أي كتابة إدارية بدونه.

## 12. تشغيل التطبيق

```bash
flutter pub get
flutter run
```

## 13. إدارة المحتوى

- من لوحة الإدارة: أضف العقارات (مع الصور)، وأدر المدن والمناطق والأنواع والمميزات.
- راقب التعليقات والبلاغات والرسائل من تبويبات اللوحة.
- عدّل بيانات التواصل وصفحات (عن التطبيق/الشروط/الخصوصية) من **إعدادات التطبيق**.

## 14. التكاليف (باختصار)

| الخدمة | الاستخدام المجاني (Spark) | متى تدفع؟ |
|---|---|---|
| Authentication | 50 ألف مستخدم شهرياً | بعد تجاوز الحد |
| Firestore | 50 ألف قراءة + 20 ألف كتابة يومياً | عند النمو الكبير |
| Storage | 5GB تخزين + 1GB تحميل/يوم | مع كثرة الصور |
| FCM | مجاني بالكامل | — |
| Functions | 2 مليون استدعاء شهرياً (Blaze) | نادراً في البداية |

**نصائح لتقليل التكلفة:** التطبيق يستخدم ترقيم الصفحات (Pagination)، وتخزين
الصور مؤقتاً (Cache)، واستعلامات خفيفة — لا تغيّر ذلك. راقب الاستهلاك من
**Firebase Console > Usage**.

---

## استكشاف الأخطاء

| المشكلة | الحل |
|---|---|
| التطبيق يعرض "وضع العرض" | تأكد من وجود `android/app/google-services.json` الصحيح ثم أعد البناء |
| `permission-denied` | انشر القواعد من الخطوة 8، وتأكد من تسجيل الدخول |
| لوحة الإدارة لا تظهر | نفّذ سكربت `make_admin.js` ثم سجّل الخروج والدخول |
| الدخول عبر Google يفشل | تأكد من إضافة SHA-1 (debug + release) في إعدادات المشروع |
| خطأ `failed-precondition` (فهرس ناقص) | انسخ رابط الفهرس من رسالة الخطأ وافتحه، أو انشر `firestore.indexes.json` |
| الصور لا تُرفع | تأكد من تفعيل Storage ونشر `storage.rules` |
