# 📚 دليل إدارة الاشتراكات - Accountant Touch

## 📖 المحتويات
1. [نظرة عامة على نظام الاشتراكات](#نظرة-عامة)
2. [إنشاء حساب جديد](#إنشاء-حساب-جديد)
3. [إدارة المدة التجريبية](#إدارة-المدة-التجريبية)
4. [إنشاء اشتراكات مدفوعة](#إنشاء-اشتراكات-مدفوعة)
5. [تعديل الاشتراكات](#تعديل-الاشتراكات)
6. [تعطيل/تفعيل الاشتراكات](#تعطيلتفعيل-الاشتراكات)
7. [معلمات Remote Config](#معلمات-remote-config)

---

## 🎯 نظرة عامة

### هيكل نظام الاشتراكات

```
┌─────────────────────────────────────────────────────────┐
│                    Firebase Console                     │
│  ┌──────────────────────────┐  ┌────────────────────┐  │
│  │   Firestore Database     │  │  Remote Config     │  │
│  │  Collection:             │  │  - trial_period    │  │
│  │  "subscriptions"         │  │  - auto_activate   │  │
│  │                          │  │  - max_devices     │  │
│  └──────────────────────────┘  └────────────────────┘  │
└─────────────────────────────────────────────────────────┘
                        ↓
         ┌──────────────────────────────┐
         │   Flutter App (Client)        │
         │  - SubscriptionService        │
         │  - ActivationStatusService    │
         │  - Local Cache (Offline)      │
         └──────────────────────────────┘
```

### الخدمات المستخدمة

1. **SubscriptionService**: إدارة الاشتراكات عبر Firebase
2. **ActivationStatusService**: عرض حالة التفعيل في القائمة الجانبية
3. **Remote Config**: التحكم في الإعدادات عن بعد

---

## 📝 إنشاء حساب جديد

### الخطوة 1: التسجيل في التطبيق

عندما يقوم المستخدم بالتسجيل في التطبيق، يحدث ما يلي تلقائياً:

```dart
// في RegisterScreen
Future<void> _register() async {
  // 1️⃣ إنشاء حساب Firebase Auth
  await FirebaseAuth.instance.createUserWithEmailAndPassword(
    email: email,
    password: password,
  );

  // 2️⃣ إنشاء اشتراك تجريبي تلقائي (إذا كان مُفعّلاً)
  if (autoActivateTrialEnabled) {
    await _createTrialSubscription(email, displayName);
  }
}
```

### الخطوة 2: بنية الاشتراك التجريبي

يتم إنشاء document في Firestore تحت collection `subscriptions`:

```javascript
// Document ID = email المستخدم
{
  // معلومات المستخدم
  "email": "user@example.com",
  "displayName": "اسم المستخدم",

  // معلومات الخطة
  "plan": "trial",              // نوع الاشتراك
  "status": "active",           // الحالة
  "isActive": true,

  // التواريخ
  "startDate": Timestamp,       // تاريخ البداية
  "endDate": Timestamp,         // تاريخ الانتهاء (startDate + trial_period_days)
  "createdAt": Timestamp,
  "updatedAt": Timestamp,

  // الأجهزة
  "maxDevices": 3,              // عدد الأجهزة المسموحة
  "currentDevices": [],         // قائمة الأجهزة المسجلة

  // الميزات
  "features": {
    "canCreateSubUsers": true,
    "maxSubUsers": 3,
    "canExportData": true,
    "canUseAdvancedReports": false,
    "supportPriority": "basic"
  },

  // السجل
  "paymentHistory": [
    {
      "amount": 0,
      "currency": "USD",
      "method": "auto_trial",
      "paidAt": Timestamp,
      "receiptUrl": null
    }
  ],

  // ملاحظات
  "notes": "تفعيل تجريبي تلقائي - 14 يوم"
}
```

---

## ⏱️ إدارة المدة التجريبية

### 1️⃣ التحكم في المدة من Remote Config

في Firebase Console → Remote Config → `trial_period_days`:

```json
{
  "trial_period_days": {
    "defaultValue": { "value": "14" },
    "description": "عدد أيام الفترة التجريبية",
    "valueType": "NUMBER"
  }
}
```

**لتغيير المدة:**
- افتح Firebase Console
- اذهب إلى Remote Config
- عدل قيمة `trial_period_days` (مثلاً: 7, 14, 30)
- انشر التغييرات

⚠️ **مهم**: هذا يؤثر فقط على المستخدمين الجدد. المستخدمون الحاليون يحتفظون بمدتهم القديمة.

### 2️⃣ تمديد المدة لمستخدم موجود

#### الطريقة الأولى: من Firebase Console (يدوياً)

1. اذهب إلى Firestore Database
2. افتح collection `subscriptions`
3. ابحث عن document الإيميل
4. عدل حقل `endDate`:

```javascript
// مثال: تمديد 7 أيام إضافية
{
  "endDate": "2025-12-22T14:58:03.000Z"  // بدلاً من 2025-12-15
}
```

#### الطريقة الثانية: باستخدام Cloud Functions (أوتوماتيكية)

أنشئ Cloud Function لتمديد الاشتراكات:

```javascript
// functions/index.js
const functions = require('firebase-functions');
const admin = require('firebase-admin');

exports.extendTrialSubscription = functions.https.onCall(async (data, context) => {
  const { email, additionalDays } = data;

  // التحقق من الصلاحيات (admin فقط)
  if (!context.auth || !context.auth.token.admin) {
    throw new functions.https.HttpsError('permission-denied', 'Admin only');
  }

  const db = admin.firestore();
  const subscriptionRef = db.collection('subscriptions').doc(email);
  const doc = await subscriptionRef.get();

  if (!doc.exists) {
    throw new functions.https.HttpsError('not-found', 'Subscription not found');
  }

  const currentEndDate = doc.data().endDate.toDate();
  const newEndDate = new Date(currentEndDate.getTime() + (additionalDays * 24 * 60 * 60 * 1000));

  await subscriptionRef.update({
    endDate: admin.firestore.Timestamp.fromDate(newEndDate),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    notes: `تم تمديد الاشتراك ${additionalDays} يوم إضافية`
  });

  return { success: true, newEndDate: newEndDate.toISOString() };
});
```

### 3️⃣ تقليل المدة

نفس الطريقتين أعلاه، لكن:
- يدوياً: ضع تاريخ أقرب في `endDate`
- Cloud Function: استخدم `additionalDays` سالب (مثلاً: -7)

---

## 💳 إنشاء اشتراكات مدفوعة

### أنواع الاشتراكات المتاحة

```javascript
const SUBSCRIPTION_PLANS = {
  // خطة تجريبية
  trial: {
    duration: 14,        // أيام
    price: 0,
    features: {
      maxSubUsers: 3,
      canExportData: true,
      canUseAdvancedReports: false,
      supportPriority: 'basic'
    }
  },

  // خطة شهرية
  monthly: {
    duration: 30,
    price: 9.99,
    currency: 'USD',
    features: {
      maxSubUsers: 10,
      canExportData: true,
      canUseAdvancedReports: true,
      supportPriority: 'standard'
    }
  },

  // خطة سنوية
  yearly: {
    duration: 365,
    price: 99.99,
    currency: 'USD',
    features: {
      maxSubUsers: 'unlimited',
      canExportData: true,
      canUseAdvancedReports: true,
      supportPriority: 'priority'
    }
  },

  // خطة دائمة (Lifetime)
  lifetime: {
    duration: null,      // لا نهاية
    price: 299.99,
    currency: 'USD',
    features: {
      maxSubUsers: 'unlimited',
      canExportData: true,
      canUseAdvancedReports: true,
      supportPriority: 'vip'
    }
  }
};
```

### الخطوة 1: إنشاء اشتراك شهري (30 يوم)

```javascript
// في Firebase Console → Firestore
// أو باستخدام Cloud Function

{
  "email": "customer@example.com",
  "displayName": "العميل المدفوع",
  "plan": "monthly",              // 🆕 شهري
  "status": "active",
  "isActive": true,

  // التواريخ
  "startDate": "2025-12-01T00:00:00.000Z",
  "endDate": "2025-12-31T23:59:59.000Z",    // 🆕 +30 يوم

  // الأجهزة
  "maxDevices": 10,               // 🆕 أكثر من التجريبي

  // الميزات المحسّنة
  "features": {
    "canCreateSubUsers": true,
    "maxSubUsers": 10,            // 🆕 بدلاً من 3
    "canExportData": true,
    "canUseAdvancedReports": true, // 🆕 ميزة جديدة
    "supportPriority": "standard"  // 🆕 دعم أفضل
  },

  // السجل
  "paymentHistory": [
    {
      "amount": 9.99,              // 🆕 مدفوع
      "currency": "USD",
      "method": "credit_card",     // 🆕 طريقة الدفع
      "paidAt": "2025-12-01T10:00:00.000Z",
      "receiptUrl": "https://example.com/receipt/12345"
    }
  ],

  "notes": "اشتراك شهري مدفوع - بطاقة ائتمان"
}
```

### الخطوة 2: إنشاء اشتراك سنوي (365 يوم)

نفس الشيء، لكن:
```javascript
{
  "plan": "yearly",
  "endDate": "2026-12-01T23:59:59.000Z",  // +365 يوم
  "paymentHistory": [{
    "amount": 99.99,
    "method": "yearly_subscription"
  }]
}
```

### الخطوة 3: إنشاء اشتراك دائم (Lifetime)

```javascript
{
  "plan": "lifetime",
  "endDate": null,                  // 🆕 لا يوجد تاريخ انتهاء!
  "isActive": true,
  "status": "active",

  "features": {
    "maxSubUsers": -1,              // -1 = unlimited
    "canExportData": true,
    "canUseAdvancedReports": true,
    "supportPriority": "vip"
  },

  "paymentHistory": [{
    "amount": 299.99,
    "method": "lifetime_purchase"
  }]
}
```

---

## ✏️ تعديل الاشتراكات

### 1️⃣ ترقية الاشتراك (Upgrade)

**من تجريبي إلى مدفوع:**

```javascript
// في Firestore
db.collection('subscriptions').doc('user@example.com').update({
  // تغيير الخطة
  plan: 'monthly',

  // تحديث التواريخ
  startDate: admin.firestore.Timestamp.now(),
  endDate: admin.firestore.Timestamp.fromDate(
    new Date(Date.now() + 30 * 24 * 60 * 60 * 1000)
  ),

  // تحديث الميزات
  'features.maxSubUsers': 10,
  'features.canUseAdvancedReports': true,
  'features.supportPriority': 'standard',
  maxDevices: 10,

  // إضافة سجل الدفع
  paymentHistory: admin.firestore.FieldValue.arrayUnion({
    amount: 9.99,
    currency: 'USD',
    method: 'upgrade_from_trial',
    paidAt: admin.firestore.Timestamp.now(),
    receiptUrl: 'https://...'
  }),

  // تحديث التوقيت
  updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  notes: 'تمت الترقية من تجريبي إلى شهري'
});
```

### 2️⃣ تجديد الاشتراك (Renewal)

```javascript
// عند انتهاء الاشتراك الشهري، تجديد لشهر آخر
const currentEndDate = subscription.endDate.toDate();
const newEndDate = new Date(currentEndDate.getTime() + 30 * 24 * 60 * 60 * 1000);

await db.collection('subscriptions').doc(email).update({
  endDate: admin.firestore.Timestamp.fromDate(newEndDate),

  paymentHistory: admin.firestore.FieldValue.arrayUnion({
    amount: 9.99,
    currency: 'USD',
    method: 'renewal',
    paidAt: admin.firestore.Timestamp.now()
  }),

  updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  notes: `تجديد تلقائي - ${new Date().toISOString()}`
});
```

### 3️⃣ تخفيض الاشتراك (Downgrade)

```javascript
// من شهري إلى تجريبي (نادر، لكن ممكن)
await db.collection('subscriptions').doc(email).update({
  plan: 'trial',

  // تقليل الميزات
  'features.maxSubUsers': 3,
  'features.canUseAdvancedReports': false,
  'features.supportPriority': 'basic',
  maxDevices: 3,

  updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  notes: 'تخفيض إلى خطة تجريبية'
});
```

---

## 🚫 تعطيل/تفعيل الاشتراكات

### 1️⃣ تعطيل اشتراك (Suspend)

**الأسباب الشائعة:**
- عدم دفع الفواتير
- انتهاك الشروط
- طلب المستخدم

```javascript
// تعطيل مؤقت
await db.collection('subscriptions').doc(email).update({
  status: 'suspended',          // ⛔️
  isActive: false,              // ⛔️

  suspensionReason: 'عدم دفع الفاتورة',
  suspendedAt: admin.firestore.Timestamp.now(),

  updatedAt: admin.firestore.FieldValue.serverTimestamp()
});
```

**النتيجة في التطبيق:**
- المستخدم لا يستطيع تسجيل الدخول
- تظهر رسالة: "تم إيقاف الاشتراك - يرجى التواصل مع الدعم"

### 2️⃣ إعادة تفعيل اشتراك

```javascript
await db.collection('subscriptions').doc(email).update({
  status: 'active',             // ✅
  isActive: true,               // ✅

  suspensionReason: admin.firestore.FieldValue.delete(),
  suspendedAt: admin.firestore.FieldValue.delete(),
  reactivatedAt: admin.firestore.Timestamp.now(),

  updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  notes: 'تمت إعادة التفعيل'
});
```

### 3️⃣ حذف اشتراك نهائياً

⚠️ **احذر:** هذا لا يمكن التراجع عنه!

```javascript
// حذف الاشتراك
await db.collection('subscriptions').doc(email).delete();

// (اختياري) نقل إلى أرشيف
await db.collection('subscriptions_archive').doc(email).set({
  ...oldSubscriptionData,
  deletedAt: admin.firestore.Timestamp.now(),
  deletedReason: 'طلب من المستخدم'
});
```

---

## ⚙️ معلمات Remote Config

### القائمة الكاملة

```json
{
  "parameters": {
    // ══════════════════════════════════════
    // 🎯 التفعيل والتطبيق
    // ══════════════════════════════════════

    "app_is_active": {
      "defaultValue": { "value": "true" },
      "description": "تفعيل التطبيق (لإيقاف التطبيق كلياً)",
      "valueType": "BOOLEAN"
    },

    "app_maintenance_mode": {
      "defaultValue": { "value": "false" },
      "description": "تمكين وضع الصيانة",
      "valueType": "BOOLEAN"
    },

    "app_maintenance_message_ar": {
      "defaultValue": {
        "value": "التطبيق متوقف مؤقتاً للصيانة. نعتذر عن الإزعاج"
      },
      "description": "رسالة الصيانة العربية",
      "valueType": "STRING"
    },

    "app_maintenance_message_en": {
      "defaultValue": {
        "value": "App is under maintenance. Sorry for the inconvenience"
      },
      "description": "English maintenance message",
      "valueType": "STRING"
    },

    // ══════════════════════════════════════
    // 📆 الاشتراكات
    // ══════════════════════════════════════

    "trial_period_days": {
      "defaultValue": { "value": "14" },
      "description": "عدد أيام الفترة التجريبية",
      "valueType": "NUMBER",
      "notes": "القيمة الافتراضية: 14 يوم. يمكن تغييرها إلى 7، 30، إلخ"
    },

    "auto_activate_trial": {
      "defaultValue": { "value": "true" },
      "description": "التحكم في التفعيل التلقائي للاشتراكات التجريبية",
      "valueType": "BOOLEAN",
      "notes": "إذا كان false، لن يتم إنشاء اشتراكات تلقائية"
    },

    "max_trial_devices": {
      "defaultValue": { "value": "3" },
      "description": "عدد الأجهزة المسموحة في الاشتراك التجريبي",
      "valueType": "NUMBER"
    },

    "max_sub_users_trial": {
      "defaultValue": { "value": "3" },
      "description": "عدد الموظفين للخطة التجريبية",
      "valueType": "STRING"
    },

    "max_sub_users_professional": {
      "defaultValue": { "value": "10" },
      "description": "عدد الموظفين للخطة الاحترافية",
      "valueType": "STRING"
    },

    // ══════════════════════════════════════
    // 🔄 التحقق والمزامنة
    // ══════════════════════════════════════

    "subscription_check_interval_hours": {
      "defaultValue": { "value": "24" },
      "description": "كل كم ساعة يتم التحقق من الاشتراك أونلاين",
      "valueType": "STRING",
      "notes": "يُستخدم للتحقق الدوري من صلاحية الاشتراك"
    },

    "offline_grace_period_days": {
      "defaultValue": { "value": "7" },
      "description": "كم يوم يمكن العمل Offline بدون تحقق",
      "valueType": "STRING",
      "notes": "بعد 7 أيام بدون إنترنت، يُطلب من المستخدم الاتصال"
    },

    // ══════════════════════════════════════
    // 🔔 التحديثات
    // ══════════════════════════════════════

    "app_min_version": {
      "defaultValue": { "value": "1.0.0" },
      "description": "رقم الاصدار - الإصدار الأدنى المطلوب",
      "valueType": "STRING"
    },

    "app_force_update": {
      "defaultValue": { "value": "false" },
      "description": "فرض التحديث",
      "valueType": "BOOLEAN"
    },

    "app_critical_update_required": {
      "defaultValue": { "value": "false" },
      "description": "فرض التحديث لتصحيحات الأمان الحرجة",
      "valueType": "BOOLEAN"
    },

    // ══════════════════════════════════════
    // 📞 الدعم
    // ══════════════════════════════════════

    "support_email": {
      "defaultValue": { "value": "sinan@denlandiq.com" },
      "description": "إيميل الدعم الفني",
      "valueType": "STRING"
    },

    "support_whatsapp": {
      "defaultValue": { "value": "+9647700270555" },
      "description": "رقم واتساب للدعم",
      "valueType": "STRING"
    }
  }
}
```

### كيفية تغيير القيم

1. **Firebase Console → Remote Config**
2. اختر المعامل الذي تريد تعديله
3. عدل القيمة
4. انقر "Publish changes"
5. ⏰ التطبيق سيحصل على القيمة الجديدة خلال دقائق

---

## 🔍 سيناريوهات عملية

### سيناريو 1: منح مستخدم فترة تجريبية ممتدة (30 يوم)

```javascript
// في Firebase Firestore
await db.collection('subscriptions').doc('special@example.com').set({
  email: 'special@example.com',
  displayName: 'عميل مميز',
  plan: 'trial',
  status: 'active',
  isActive: true,

  startDate: admin.firestore.Timestamp.now(),
  endDate: admin.firestore.Timestamp.fromDate(
    new Date(Date.now() + 30 * 24 * 60 * 60 * 1000)  // 30 يوم بدلاً من 14
  ),

  maxDevices: 5,  // أكثر من الافتراضي

  features: {
    canCreateSubUsers: true,
    maxSubUsers: 5,
    canExportData: true,
    canUseAdvancedReports: true,  // ميزة إضافية
    supportPriority: 'standard'    // دعم أفضل
  },

  notes: 'فترة تجريبية ممتدة - عميل مميز'
});
```

### سيناريو 2: تحويل مستخدم من تجريبي إلى مدفوع

```javascript
// الخطوة 1: جلب البيانات الحالية
const currentSub = await db.collection('subscriptions')
  .doc('user@example.com')
  .get();

// الخطوة 2: التحديث
await db.collection('subscriptions').doc('user@example.com').update({
  plan: 'yearly',

  startDate: admin.firestore.Timestamp.now(),
  endDate: admin.firestore.Timestamp.fromDate(
    new Date(Date.now() + 365 * 24 * 60 * 60 * 1000)
  ),

  maxDevices: 'unlimited',
  'features.maxSubUsers': -1,  // unlimited
  'features.supportPriority': 'priority',

  paymentHistory: admin.firestore.FieldValue.arrayUnion({
    amount: 99.99,
    currency: 'USD',
    method: 'bank_transfer',
    paidAt: admin.firestore.Timestamp.now(),
    receiptUrl: 'https://drive.google.com/file/...'
  }),

  notes: 'تمت الترقية إلى اشتراك سنوي مدفوع'
});
```

### سيناريو 3: إيقاف جميع الاشتراكات التجريبية المنتهية

```javascript
// Cloud Function تعمل يومياً
exports.expireTrials = functions.pubsub
  .schedule('0 0 * * *')  // كل يوم في منتصف الليل
  .onRun(async (context) => {
    const now = admin.firestore.Timestamp.now();

    const expiredTrials = await db.collection('subscriptions')
      .where('plan', '==', 'trial')
      .where('endDate', '<', now)
      .where('isActive', '==', true)
      .get();

    const batch = db.batch();

    expiredTrials.forEach(doc => {
      batch.update(doc.ref, {
        status: 'expired',
        isActive: false,
        expiredAt: now,
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      });
    });

    await batch.commit();

    console.log(`تم إيقاف ${expiredTrials.size} اشتراك منتهي`);
  });
```

---

## 📊 لوحة تحكم مقترحة

### استعلامات Firestore مفيدة

```javascript
// 1️⃣ جميع الاشتراكات النشطة
db.collection('subscriptions')
  .where('isActive', '==', true)
  .get()

// 2️⃣ الاشتراكات التي ستنتهي خلال 7 أيام
const sevenDaysFromNow = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000);
db.collection('subscriptions')
  .where('endDate', '<', sevenDaysFromNow)
  .where('isActive', '==', true)
  .get()

// 3️⃣ جميع الاشتراكات التجريبية
db.collection('subscriptions')
  .where('plan', '==', 'trial')
  .get()

// 4️⃣ الاشتراكات المدفوعة فقط
db.collection('subscriptions')
  .where('plan', 'in', ['monthly', 'yearly', 'lifetime'])
  .get()

// 5️⃣ الاشتراكات الموقوفة
db.collection('subscriptions')
  .where('status', '==', 'suspended')
  .get()
```

---

## ❓ أسئلة شائعة

### س1: كيف أغير المدة التجريبية لجميع المستخدمين الجدد؟

**ج:** عدل `trial_period_days` في Remote Config. المستخدمون الحاليون لن يتأثروا.

### س2: كيف أعطي مستخدم محدد وقتاً أطول؟

**ج:** عدل `endDate` في Firestore مباشرة لهذا المستخدم.

### س3: كيف أوقف التفعيل التلقائي للاشتراكات؟

**ج:** غير `auto_activate_trial` إلى `false` في Remote Config.

### س4: ماذا يحدث عندما ينتهي الاشتراك؟

**ج:** المستخدم لا يستطيع تسجيل الدخول، ويرى رسالة "انتهى الاشتراك".

### س5: كيف أتتبع الإيرادات؟

**ج:** راجع حقل `paymentHistory` في كل subscription.

---

## 🚀 نصائح للإنتاج

1. **استخدم Cloud Functions** للأتمتة
2. **راقب الاشتراكات المنتهية** يومياً
3. **أرسل تنبيهات** قبل انتهاء الاشتراك بـ 7 أيام
4. **احفظ نسخة احتياطية** من Firestore يومياً
5. **راجع Remote Config** بانتظام
6. **استخدم Firebase Analytics** لتتبع معدلات التحويل

---

## 📞 الدعم

إذا كان لديك أي سؤال:
- Email: sinan@denlandiq.com
- WhatsApp: +9647700270555

---

**آخر تحديث:** 2025-12-11
**الإصدار:** 1.0.0
