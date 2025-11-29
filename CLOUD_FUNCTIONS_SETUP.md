# 🚀 دليل تنصيب Cloud Functions للتفعيل التلقائي

## ⚠️ متطلبات مهمة

### 1. الترقية لـ Blaze Plan
- ✅ **حالياً**: أنت على Spark Plan (مجاني) - التفعيل التلقائي يعمل عبر Flutter
- ⚡ **للترقية**: Cloud Functions تتطلب Blaze Plan (Pay as you go)
- 💰 **التكلفة**: شبه مجانية للاستخدام المتوسط (أول 2 مليون استدعاء مجاناً شهرياً)

### 2. تنصيب Firebase CLI
```bash
# تنصيب Firebase CLI عالمياً
npm install -g firebase-tools

# تسجيل الدخول
firebase login

# التحقق من النجاح
firebase projects:list
```

---

## 📋 خطوات التنصيب

### الخطوة 1: تهيئة المشروع

```bash
# الانتقال لمجلد المشروع
cd /home/user/accounting_app

# تهيئة Firebase Functions
firebase init functions
```

**اختيارات التهيئة:**
- Select project: اختر مشروعك الحالي
- Language: **JavaScript**
- ESLint: **Yes** (للجودة)
- Install dependencies: **Yes**

### الخطوة 2: نسخ الكود

الملفات جاهزة في مجلد `functions/`:
- ✅ `functions/index.js` - Cloud Functions الرئيسية
- ✅ `functions/package.json` - Dependencies

لا حاجة لنسخ شيء - الملفات موجودة بالفعل!

### الخطوة 3: تنصيب Dependencies

```bash
cd functions
npm install
cd ..
```

### الخطوة 4: الترقية لـ Blaze Plan

1. افتح [Firebase Console](https://console.firebase.google.com)
2. اختر مشروعك
3. Settings (الإعدادات) > Usage and billing
4. Upgrade to Blaze Plan
5. أدخل بيانات بطاقة الائتمان
6. قم بتفعيل الخطة

⚠️ **ملاحظة**: لن يتم تحصيل رسوم إلا عند تجاوز الحد المجاني (نادر للتطبيقات الصغيرة)

### الخطوة 5: نشر Cloud Functions

```bash
# نشر جميع Cloud Functions
firebase deploy --only functions

# أو نشر function واحدة فقط
firebase deploy --only functions:createTrialSubscription
```

**النتيجة المتوقعة:**
```
✔  functions[createTrialSubscription(us-central1)] Successful create operation.
✔  functions[checkExpiringTrials(us-central1)] Successful create operation.
✔  functions[deactivateExpiredSubscriptions(us-central1)] Successful create operation.

✔  Deploy complete!
```

### الخطوة 6: التحقق من النشر

```bash
# عرض قائمة Functions المنشورة
firebase functions:list

# عرض Logs
firebase functions:log --only createTrialSubscription
```

---

## 🧪 اختبار Cloud Function

### اختبار محلي (Emulator)

```bash
# تشغيل Firebase Emulator
firebase emulators:start --only functions,auth,firestore

# في terminal آخر، اختبار عبر curl
curl -X POST http://localhost:5001/YOUR_PROJECT_ID/us-central1/createTrialSubscription
```

### اختبار حقيقي

1. افتح التطبيق
2. سجل حساب جديد بإيميل اختباري
3. تحقق من Firestore Console:
   - Collection: `subscriptions`
   - Document: `email@test.com`
   - يجب أن يظهر الاشتراك التجريبي تلقائياً

---

## 🔧 Cloud Functions المتاحة

### 1. `createTrialSubscription`
**الغرض**: إنشاء اشتراك تجريبي 14 يوم تلقائياً عند التسجيل

**Trigger**: Firebase Auth - onCreate
```javascript
exports.createTrialSubscription = functions.auth.user().onCreate(...)
```

**المزايا**:
- ✅ آمنة (server-side)
- ✅ لا تحتاج تحديث التطبيق
- ✅ مركزية (كل المنطق في مكان واحد)

---

### 2. `checkExpiringTrials`
**الغرض**: إرسال تنبيهات للاشتراكات القريبة من الانتهاء (خلال 3 أيام)

**Trigger**: مجدولة يومياً الساعة 9 صباحاً
```javascript
exports.checkExpiringTrials = functions.pubsub.schedule('0 9 * * *')...
```

**الاستخدام**:
```bash
# تشغيل يدوي للاختبار
firebase functions:shell
> checkExpiringTrials()
```

---

### 3. `deactivateExpiredSubscriptions`
**الغرض**: تعطيل الاشتراكات المنتهية تلقائياً

**Trigger**: مجدولة يومياً منتصف الليل
```javascript
exports.deactivateExpiredSubscriptions = functions.pubsub.schedule('0 0 * * *')...
```

---

## 📊 مراقبة الأداء

### عرض Logs في Console

1. Firebase Console > Functions
2. اختر Function
3. Logs > View in Cloud Logging

### عرض Logs عبر CLI

```bash
# Logs لجميع Functions
firebase functions:log

# Logs لـ function محددة
firebase functions:log --only createTrialSubscription

# Streaming logs (real-time)
firebase functions:log --follow
```

### استعلامات مفيدة

```bash
# الأخطاء فقط
firebase functions:log --only createTrialSubscription --filter "severity=ERROR"

# آخر 100 سجل
firebase functions:log --limit 100
```

---

## 🔄 التحديث بعد التعديل

```bash
# تعديل الكود في functions/index.js
nano functions/index.js

# إعادة النشر
firebase deploy --only functions

# تحديث function واحدة فقط (أسرع)
firebase deploy --only functions:createTrialSubscription
```

---

## 💰 تقدير التكلفة

### Blaze Plan - الاستخدام المجاني الشهري:
- ✅ **2 مليون استدعاء** مجاناً
- ✅ **400,000 GB-seconds** مجاناً
- ✅ **200,000 CPU-seconds** مجاناً

### السيناريو المتوقع لتطبيقك:
- **تسجيل جديد**: ~10 مستخدمين/يوم = 300/شهر
- **checkExpiringTrials**: 30 استدعاء/شهر
- **deactivateExpiredSubscriptions**: 30 استدعاء/شهر

**المجموع**: ~360 استدعاء/شهر = **0.018%** من الحد المجاني

**التكلفة المتوقعة**: **$0.00/شهر** (ضمن الحد المجاني)

---

## ⚙️ إعدادات متقدمة

### تغيير المنطقة (Region)

```javascript
exports.createTrialSubscription = functions
  .region('europe-west1') // أو 'asia-east1' للسعودية
  .auth.user().onCreate(...)
```

### تعيين Timeout أطول

```javascript
exports.createTrialSubscription = functions
  .runWith({ timeoutSeconds: 300 }) // 5 دقائق
  .auth.user().onCreate(...)
```

### زيادة الذاكرة

```javascript
exports.createTrialSubscription = functions
  .runWith({ memory: '1GB' })
  .auth.user().onCreate(...)
```

---

## 🐛 حل المشاكل

### خطأ: "Billing account not configured"
**الحل**: قم بالترقية لـ Blaze Plan أولاً

### خطأ: "Function deployment failed"
**الحل**: تحقق من:
```bash
cd functions
npm install
npm run deploy
```

### خطأ: "Permission denied"
**الحل**: تأكد من تسجيل الدخول:
```bash
firebase login --reauth
```

### Function لا تعمل
**التحقق**:
```bash
# هل تم النشر؟
firebase functions:list

# ما هي الأخطاء؟
firebase functions:log --only createTrialSubscription --filter "severity=ERROR"

# اختبر يدوياً
firebase functions:shell
> createTrialSubscription({ uid: 'test', email: 'test@test.com' })
```

---

## 🔄 الانتقال من Flutter إلى Cloud Functions

### الحالة الحالية (Flutter-based)
✅ يعمل على Spark Plan
✅ لا يحتاج Cloud Functions
❌ أقل أماناً (client-side)

### بعد نشر Cloud Function
1. **تعطيل Flutter-based activation**:
   ```dart
   // في register_screen.dart - سطر 69
   final autoActivate = false; // تعطيل Flutter solution
   ```

2. **تفعيل Cloud Function**:
   - سيعمل تلقائياً عند تسجيل المستخدم الجديد
   - لا حاجة لتعديل التطبيق

3. **تحديث Remote Config**:
   ```
   auto_activate_trial = false  // تعطيل Flutter-based
   ```

---

## 📚 مصادر إضافية

- [Firebase Functions Docs](https://firebase.google.com/docs/functions)
- [Firebase Pricing](https://firebase.google.com/pricing)
- [Cloud Functions Best Practices](https://firebase.google.com/docs/functions/best-practices)
- [Firebase Emulator Suite](https://firebase.google.com/docs/emulator-suite)

---

## ✅ خلاصة

### قبل Cloud Functions (حالياً):
- ✅ Spark Plan (مجاني)
- ✅ Flutter-based activation (يعمل)
- ⚠️ أقل أماناً

### بعد Cloud Functions:
- ⚡ Blaze Plan (مطلوب)
- ✅ Server-side activation (أكثر أماناً)
- ✅ لا يحتاج تحديث التطبيق
- 💰 تكلفة شبه معدومة

---

**ملاحظة**: يمكنك الاستمرار باستخدام Flutter-based solution حالياً، ونشر Cloud Functions لاحقاً عند الحاجة.
