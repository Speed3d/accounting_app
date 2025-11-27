# 🔥 دليل إعداد Firebase للنظام الجديد v3.0

## 📋 جدول المحتويات
1. [ملخص التغييرات](#ملخص-التغييرات)
2. [إعداد Firebase Console](#إعداد-firebase-console)
3. [Remote Config الجديد](#remote-config-الجديد)
4. [Firestore Database](#firestore-database)
5. [اختبار النظام](#اختبار-النظام)
6. [الأسئلة الشائعة](#الأسئلة-الشائعة)

---

## ✅ ملخص التغييرات

### **ما تم تعديله:**
1. ✅ إضافة **Firebase Auth** و **Cloud Firestore** إلى `build.gradle.kts`
2. 🔄 Remote Config يحتاج تحديث (الشرح أدناه)
3. 🆕 Firestore Collections جديدة

### **ما لا يزال صالحاً:**
- ✅ ملف `google-services.json` (لا يحتاج تغيير)
- ✅ Package name: `com.accountant.touch`
- ✅ Firebase Core configuration

---

## 🎯 إعداد Firebase Console

### **الخطوة 1: تفعيل Firebase Authentication**

1. اذهب إلى: https://console.firebase.google.com/project/accountant-touch
2. من القائمة اليسرى → **Authentication**
3. اضغط على **"Get Started"** (إذا لم يكن مفعل)
4. اذهب إلى تبويب **"Sign-in method"**
5. فعّل **"Email/Password"**:
   ```
   Status: Enabled ✅
   Email link (passwordless sign-in): Disabled ❌
   ```
6. احفظ التغييرات

### **الخطوة 2: تفعيل Cloud Firestore**

1. من القائمة اليسرى → **Firestore Database**
2. اضغط **"Create database"**
3. اختر **Production mode** (سنضيف rules لاحقاً)
4. اختر الموقع: `eur3 (europe-west)` (أو الأقرب لك)
5. اضغط **"Enable"**

---

## 🔐 Firestore Security Rules

بعد إنشاء Firestore، اذهب إلى تبويب **"Rules"** واستبدل الكود بهذا:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // 🔹 Collection: subscriptions
    // يحتوي على بيانات الاشتراكات لكل Owner (Email-based)
    match /subscriptions/{email} {

      // ✅ القراءة: فقط المالك نفسه
      allow read: if request.auth != null &&
                     request.auth.token.email == email;

      // ❌ الكتابة: ممنوعة للجميع (Admin only via Console)
      allow write: if false;
    }

    // 🔹 Collection: audit_logs (اختياري - للتتبع)
    match /audit_logs/{logId} {
      allow read: if false;  // Admin only
      allow write: if false; // Admin only
    }
  }
}
```

**ملاحظات مهمة:**
- ✅ المستخدم يمكنه قراءة اشتراكه فقط
- ❌ لا يمكن للمستخدم تعديل اشتراكه (أنت فقط عبر Console)
- 🔒 أمان عالي ضد التلاعب

---

## 📊 Firestore Collections Structure

### **1. Collection: `subscriptions`**

#### مثال: اشتراك تجريبي
```javascript
Document ID: test@example.com

{
  email: "test@example.com",
  displayName: "Ahmed Tester",

  // معلومات الاشتراك
  plan: "trial",                    // trial | 6months | yearly | lifetime
  status: "active",                 // active | expired | suspended | cancelled
  isActive: true,

  // التواريخ
  startDate: Timestamp(2025-11-27 12:00:00),
  endDate: Timestamp(2025-12-11 12:00:00),  // +14 يوم للتجريبي
  createdAt: Timestamp(2025-11-27 12:00:00),
  updatedAt: Timestamp(2025-11-27 12:00:00),

  // إدارة الأجهزة
  maxDevices: 3,                    // Professional: 3, Enterprise: -1 (unlimited)
  currentDevices: [
    {
      deviceId: "abc123...",
      deviceName: "Samsung Galaxy S23",
      firstLoginAt: Timestamp(2025-11-27 12:00:00),
      lastLoginAt: Timestamp(2025-11-27 15:30:00),
      isActive: true
    }
  ],

  // المميزات
  features: {
    canCreateSubUsers: true,
    maxSubUsers: 10,                // Professional: 10, Enterprise: -1 (unlimited)
    canExportData: true,
    canUseAdvancedReports: true,
    supportPriority: "standard"     // standard | priority | vip
  },

  // الدفع
  paymentHistory: [
    {
      amount: 0,                    // تجريبي مجاني
      currency: "USD",
      method: "trial",
      paidAt: Timestamp(2025-11-27 12:00:00),
      receiptUrl: null
    }
  ],

  // ملاحظات (اختياري)
  notes: "اشتراك تجريبي - يجب التفعيل قبل 2025-12-11"
}
```

#### مثال: اشتراك احترافي (6 أشهر)
```javascript
Document ID: owner@company.com

{
  email: "owner@company.com",
  displayName: "Mohamed Ali",

  plan: "6months",
  status: "active",
  isActive: true,

  startDate: Timestamp(2025-11-27 12:00:00),
  endDate: Timestamp(2026-05-27 12:00:00),  // +6 أشهر
  createdAt: Timestamp(2025-11-27 12:00:00),
  updatedAt: Timestamp(2025-11-27 12:00:00),

  maxDevices: 3,
  currentDevices: [],               // سيتم ملؤها عند تسجيل الدخول

  features: {
    canCreateSubUsers: true,
    maxSubUsers: 10,
    canExportData: true,
    canUseAdvancedReports: true,
    supportPriority: "priority"
  },

  paymentHistory: [
    {
      amount: 199.00,
      currency: "USD",
      method: "bank_transfer",
      paidAt: Timestamp(2025-11-27 10:00:00),
      receiptUrl: "https://example.com/receipt-123.pdf",
      transactionId: "BANK-20251127-001"
    }
  ],

  notes: "تم الدفع عبر تحويل بنكي - رقم الفاتورة: INV-2025-001"
}
```

#### مثال: اشتراك مؤسسي (سنوي)
```javascript
Document ID: enterprise@bigcompany.com

{
  email: "enterprise@bigcompany.com",
  displayName: "Big Company Ltd",

  plan: "yearly",
  status: "active",
  isActive: true,

  startDate: Timestamp(2025-11-27 12:00:00),
  endDate: Timestamp(2026-11-27 12:00:00),  // سنة كاملة
  createdAt: Timestamp(2025-11-27 12:00:00),
  updatedAt: Timestamp(2025-11-27 12:00:00),

  maxDevices: -1,                   // ✨ Unlimited
  currentDevices: [],

  features: {
    canCreateSubUsers: true,
    maxSubUsers: -1,                // ✨ Unlimited
    canExportData: true,
    canUseAdvancedReports: true,
    supportPriority: "vip"
  },

  paymentHistory: [
    {
      amount: 599.00,
      currency: "USD",
      method: "bank_transfer",
      paidAt: Timestamp(2025-11-27 10:00:00),
      receiptUrl: "https://example.com/receipt-456.pdf",
      transactionId: "BANK-20251127-002"
    }
  ],

  notes: "عقد سنوي - أجهزة وموظفين غير محدودة"
}
```

#### مثال: اشتراك مدى الحياة
```javascript
Document ID: lifetime@vip.com

{
  email: "lifetime@vip.com",
  displayName: "VIP Customer",

  plan: "lifetime",
  status: "active",
  isActive: true,

  startDate: Timestamp(2025-11-27 12:00:00),
  endDate: null,                    // ✨ Lifetime = no end date
  createdAt: Timestamp(2025-11-27 12:00:00),
  updatedAt: Timestamp(2025-11-27 12:00:00),

  maxDevices: -1,                   // Unlimited
  currentDevices: [],

  features: {
    canCreateSubUsers: true,
    maxSubUsers: -1,
    canExportData: true,
    canUseAdvancedReports: true,
    supportPriority: "vip"
  },

  paymentHistory: [
    {
      amount: 1499.00,
      currency: "USD",
      method: "bank_transfer",
      paidAt: Timestamp(2025-11-27 10:00:00),
      receiptUrl: "https://example.com/receipt-789.pdf",
      transactionId: "BANK-20251127-003"
    }
  ],

  notes: "اشتراك مدى الحياة - بدون حد زمني"
}
```

---

## 🔄 Remote Config: التوصيات الجديدة

### **ما يجب الاحتفاظ به:**
```json
{
  "app_is_active": {
    "value": "true",
    "description": "تفعيل التطبيق (لإيقاف التطبيق كلياً)"
  },
  "app_maintenance_mode": {
    "value": "false",
    "description": "وضع الصيانة"
  },
  "app_maintenance_message_ar": {
    "value": "التطبيق متوقف مؤقتاً للصيانة. نعتذر عن الإزعاج",
    "description": "رسالة الصيانة بالعربية"
  },
  "app_maintenance_message_en": {
    "value": "App is under maintenance. Sorry for the inconvenience",
    "description": "رسالة الصيانة بالإنجليزية"
  },
  "app_min_version": {
    "value": "1.0.0",
    "description": "الإصدار الأدنى المطلوب"
  },
  "app_force_update": {
    "value": "false",
    "description": "فرض التحديث"
  },
  "app_critical_update_required": {
    "value": "false",
    "description": "تحديث أمني حرج مطلوب"
  },
  "backup_magic_number": {
    "value": "LxwJtAU9bgXI3oH15B8zFfKWNamYuO7R",
    "description": "التحقق من صحة ملف النسخ الاحتياطي"
  }
}
```

### **ما يمكن إزالته (للنظام القديم فقط):**
```json
{
  "activation_secret": "...",           // ❌ لم يعد يُستخدم (كان للـ Device-based)
  "time_validation_secret": "...",      // ❌ لم يعد يُستخدم
  "pbkdf2_iterations": "...",           // ❌ لم يعد يُستخدم
  "app_blocked_devices": "...",         // ❌ (يمكن إدارته من Firestore بدلاً)
  "app_allowed_versions": "...",        // ❌ تكرار لـ app_min_version
  "trial_period_days": "..."            // ❌ (أصبح في Firestore الآن)
}
```

### **معايير جديدة مقترحة (اختياري):**
```json
{
  "subscription_check_interval_hours": {
    "value": "24",
    "description": "كل كم ساعة يتم التحقق من الاشتراك أونلاين"
  },
  "offline_grace_period_days": {
    "value": "7",
    "description": "كم يوم يمكن العمل Offline بدون تحقق"
  },
  "max_sub_users_trial": {
    "value": "3",
    "description": "عدد الموظفين للخطة التجريبية"
  },
  "max_sub_users_professional": {
    "value": "10",
    "description": "عدد الموظفين للخطة الاحترافية"
  },
  "support_email": {
    "value": "support@accountant-touch.com",
    "description": "إيميل الدعم الفني"
  },
  "support_whatsapp": {
    "value": "+1234567890",
    "description": "رقم واتساب للدعم"
  }
}
```

---

## 🧪 اختبار النظام

### **Test 1: إنشاء حساب جديد** ✅

1. **في Firebase Console:**
   ```
   Firestore → subscriptions → Add document

   Document ID: test@example.com

   {
     email: "test@example.com",
     displayName: "Test User",
     plan: "trial",
     status: "active",
     isActive: true,
     startDate: [الآن],
     endDate: [+14 يوم],
     maxDevices: 3,
     currentDevices: [],
     features: {
       canCreateSubUsers: true,
       maxSubUsers: 10
     }
   }
   ```

2. **في التطبيق:**
   ```
   1. افتح التطبيق
   2. اضغط "إنشاء حساب"
   3. أدخل:
      - Email: test@example.com
      - Password: Test123!
      - Full Name: Test User
   4. اضغط "إنشاء الحساب"

   ✅ النتيجة المتوقعة: رسالة نجاح + طلب التواصل للتفعيل
   ```

### **Test 2: تسجيل دخول المالك** ✅

```
1. افتح التطبيق
2. اضغط "تسجيل دخول المالك"
3. أدخل:
   - Email: test@example.com
   - Password: Test123!
4. اضغط "تسجيل الدخول"

✅ النتيجة المتوقعة:
   - Firebase Auth: ✅ نجح
   - Firestore Check: ✅ Subscription Active
   - Device Registration: ✅ تم تسجيل الجهاز
   - التوجه إلى الشاشة الرئيسية ✅
```

### **Test 3: Multi-Device Login** ✅

```
1. سجل دخول من جهاز آخر بنفس الإيميل
2. تحقق من Firestore:

   subscriptions/test@example.com/currentDevices

   ✅ يجب أن ترى جهازين:
   [
     {
       deviceId: "device1...",
       deviceName: "Samsung Galaxy S23",
       ...
     },
     {
       deviceId: "device2...",
       deviceName: "Google Pixel 8",
       ...
     }
   ]
```

### **Test 4: Device Limit** ❌→✅

```
1. سجل دخول من 4 أجهزة (الحد الأقصى 3)
2. عند الجهاز الرابع:

   ❌ النتيجة المتوقعة:
   "تم الوصول للحد الأقصى من الأجهزة (3).
   يرجى إلغاء تفعيل جهاز آخر أو ترقية الخطة."
```

### **Test 5: Offline Mode** ✅

```
1. سجل دخول (مع إنترنت) ← ✅
2. قطع الإنترنت تماماً
3. أغلق التطبيق وافتحه مرة أخرى
4. سجل دخول

   ✅ النتيجة: يعمل من Cache (لمدة 7 أيام)

5. بعد 8 أيام (Offline):
   ❌ النتيجة: "يجب الاتصال بالإنترنت للتحقق من الاشتراك"
```

### **Test 6: إضافة موظف (Sub User)** ✅

```
1. سجل دخول كـ Owner
2. اذهب إلى "المستخدمون"
3. اضغط "إضافة موظف"
4. أدخل:
   - Username: ahmed
   - Password: 123456
   - Full Name: Ahmed Employee
   - Permissions: [اختر الصلاحيات]
5. احفظ

✅ النتيجة: تم حفظه في قاعدة البيانات المحلية

6. سجل خروج
7. اضغط "تسجيل دخول الموظف"
8. أدخل:
   - Username: ahmed
   - Password: 123456

✅ النتيجة: دخول ناجح (بدون إنترنت!)
```

### **Test 7: Subscription Expiry** ❌→✅

```
1. في Firestore، عدّل endDate ليكون في الماضي:

   subscriptions/test@example.com
   {
     endDate: Timestamp(2025-11-20)  // منتهي
   }

2. حاول تسجيل الدخول

   ❌ النتيجة المتوقعة:
   "انتهى اشتراكك. يرجى التجديد للاستمرار."
```

### **Test 8: Suspended Account** ❌→✅

```
1. في Firestore، عدّل status:

   subscriptions/test@example.com
   {
     status: "suspended",
     isActive: false
   }

2. حاول تسجيل الدخول

   ❌ النتيجة المتوقعة:
   "تم تعليق حسابك. يرجى التواصل مع الدعم الفني."
```

---

## ❓ الأسئلة الشائعة

### **س1: هل أحتاج لحذف Remote Config Parameters القديمة؟**
**ج:** لا، يمكنك الاحتفاظ بها. لن تؤثر على النظام الجديد. لكن يُنصح بحذفها لتنظيف لوحة التحكم.

### **س2: كيف أضيف اشتراك جديد لعميل؟**
**ج:**
```
1. Firebase Console → Firestore Database
2. subscriptions → Add document
3. Document ID: email@customer.com
4. املأ البيانات (استخدم الأمثلة أعلاه)
5. Save
```

### **س3: كيف أمدد اشتراك منتهي؟**
**ج:**
```
1. افتح: subscriptions/email@customer.com
2. عدّل:
   endDate: [تاريخ جديد]
   status: "active"
   isActive: true
3. أضف في paymentHistory:
   {
     amount: 199.00,
     paidAt: [الآن],
     method: "bank_transfer",
     transactionId: "..."
   }
```

### **س4: كيف أحظر جهاز معين؟**
**ج:**
```
1. افتح: subscriptions/email@customer.com/currentDevices
2. ابحث عن الجهاز
3. عدّل:
   isActive: false
4. أو احذف العنصر كلياً من المصفوفة
```

### **س5: هل يمكن استخدام payment gateway لاحقاً؟**
**ج:** نعم بالتأكيد! النظام مصمم ليدعم:
- Stripe
- PayPal
- Paddle
- RevenueCat
- أي payment gateway

عندها سيتم إنشاء الاشتراكات تلقائياً بدلاً من يدوياً.

### **س6: ماذا لو نسيت كلمة المرور؟**
**ج:** المالك يمكنه:
```
1. شاشة تسجيل الدخول
2. "نسيت كلمة المرور؟"
3. أدخل Email
4. سيرسل Firebase رابط reset على الإيميل ✅
```

أما الموظفين: المالك فقط يمكنه تغيير كلمة مرورهم (محلياً).

### **س7: كيف أعرف من أين جاء الخطأ؟**
**ج:** تحقق من Firestore Rules:
```
Firestore → Rules → Check logs

إذا رأيت:
"PERMISSION_DENIED" → المستخدم يحاول الوصول لبيانات ليست له
"NOT_FOUND" → الاشتراك غير موجود
```

---

## 📝 خطوات سريعة للبدء

```bash
# 1️⃣ تثبيت المكتبات
cd /home/user/accounting_app
flutter pub get

# 2️⃣ تشغيل التطبيق
flutter run

# 3️⃣ إنشاء اشتراك تجريبي في Firestore
# (اتبع الأمثلة أعلاه)

# 4️⃣ اختبار!
```

---

## 🎉 خلاصة

✅ **تم:**
- إضافة Firebase Auth & Firestore
- بنية Firestore واضحة ومنظمة
- أمثلة كاملة لكل نوع اشتراك
- Security Rules قوية
- دليل اختبار شامل

🚀 **جاهز للإطلاق!**

---

**أسئلة أو مشاكل؟**
راجع: `MIGRATION_GUIDE_V3.md` أو `UPGRADE_NOTES_V3.md`
