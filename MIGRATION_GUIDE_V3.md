# دليل الترحيل إلى النظام الجديد v3.0

## 📋 نظرة عامة

تم تطوير النظام بالكامل من نظام **Device-based Authentication** إلى **Email-based Subscription System** مع دعم Firebase.

---

## 🎯 التغييرات الرئيسية

### 1️⃣ نظام المصادقة

#### **قبل (v2.0):**
- Username + Password (محلي فقط)
- لا يوجد استعادة لكلمة المرور
- مرتبط بجهاز واحد فقط

#### **بعد (v3.0):**
- **Owner:** Email + Password (Firebase Auth)
- **Sub Users:** Username + Password (محلي)
- استعادة كلمة المرور عبر الإيميل
- دعم Multi-device (3 أجهزة أو unlimited)

---

### 2️⃣ نظام الاشتراكات

#### **قبل (v2.0):**
```
Device Fingerprint → Activation Code → Local Expiry Date
```

#### **بعد (v3.0):**
```
Email → Firestore Subscription → Multi-Device Support
```

**خطط الاشتراك:**
- 🆓 تجريبي (14 يوم)
- 📅 6 أشهر
- 📅 سنوي
- ♾️ مدى الحياة

---

### 3️⃣ قاعدة البيانات

**جدول TB_Users - الحقول الجديدة:**
```sql
Email TEXT UNIQUE,           -- للـ Owner فقط
Phone TEXT,                  -- اختياري
UserType TEXT,               -- 'owner' أو 'sub_user'
OwnerEmail TEXT,             -- للـ Sub Users (FK)
CreatedBy TEXT,              -- إيميل المنشئ
LastLoginAt TEXT             -- آخر تسجيل دخول
```

**جدول جديد: TB_Subscription_Cache:**
```sql
CREATE TABLE TB_Subscription_Cache (
  ID INTEGER PRIMARY KEY CHECK (ID = 1),
  Email TEXT NOT NULL,
  Plan TEXT NOT NULL,
  StartDate TEXT NOT NULL,
  EndDate TEXT,
  IsActive INTEGER NOT NULL DEFAULT 1,
  MaxDevices INTEGER,
  CurrentDeviceCount INTEGER DEFAULT 0,
  CurrentDeviceId TEXT NOT NULL,
  CurrentDeviceName TEXT,
  LastSyncAt TEXT NOT NULL,
  OfflineDaysRemaining INTEGER DEFAULT 7,
  LastOnlineCheck TEXT NOT NULL,
  FeaturesJson TEXT,
  Status TEXT NOT NULL DEFAULT 'active',
  UpdatedAt TEXT NOT NULL
)
```

---

## 🔧 الإعدادات المطلوبة

### 1. Firebase Setup

#### **أ. Firebase Console:**
1. إنشاء مشروع Firebase (أو استخدام الموجود)
2. تفعيل **Firebase Authentication**:
   - Sign-in methods → Email/Password ✅
3. تفعيل **Cloud Firestore**:
   - Start in Production Mode
   - إضافة Security Rules (انظر أدناه)
4. تفعيل **Firebase Storage** (للنسخ الاحتياطية - اختياري)

#### **ب. إضافة التطبيق:**

**Android:**
1. Add Android App
2. Package name: `com.example.accountant_touch`
3. تنزيل `google-services.json`
4. نسخه إلى: `android/app/google-services.json`

**iOS (إذا مطلوب):**
1. Add iOS App
2. Bundle ID: `com.example.accountantTouch`
3. تنزيل `GoogleService-Info.plist`
4. نسخه إلى: `ios/Runner/GoogleService-Info.plist`

---

### 2. Firestore Security Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // قاعدة: كل مستخدم يقرأ بياناته فقط
    match /subscriptions/{email} {
      allow read: if request.auth != null &&
                     request.auth.token.email == email;
      allow write: if false;  // فقط من Server/Console
    }

    // منع الوصول لأي شيء آخر
    match /{document=**} {
      allow read, write: if false;
    }
  }
}
```

---

### 3. إنشاء اشتراك جديد (Manual Activation)

#### **Firebase Console → Firestore Database:**

```javascript
Collection: subscriptions
Document ID: owner@company.com

{
  // معلومات الاشتراك
  email: "owner@company.com",
  createdAt: Timestamp.now(),

  // الخطة
  plan: "yearly",  // أو "trial", "6months", "lifetime"

  // التواريخ
  startDate: Timestamp.now(),
  endDate: Timestamp (بعد سنة),  // null للـ lifetime
  isActive: true,

  // الأجهزة
  maxDevices: 3,  // أو null للـ unlimited
  currentDevices: [],

  // الميزات
  features: {
    canCreateSubUsers: true,
    maxSubUsers: 10,  // أو null للـ unlimited
    cloudBackupEnabled: false,
    prioritySupport: false
  },

  // سجل الدفعات
  paymentHistory: [
    {
      date: Timestamp.now(),
      plan: "yearly",
      amount: 500,
      method: "bank_transfer",
      notes: "تحويل بنكي - رقم العملية: 12345"
    }
  ],

  // الحالة
  status: "active",  // أو "expired", "suspended"
  suspensionReason: "",

  updatedAt: Timestamp.now()
}
```

---

## 🚀 كيفية الاستخدام

### 1. تسجيل حساب جديد (Owner)

```
1. افتح التطبيق
2. اختر "إنشاء حساب"
3. أدخل:
   - الاسم الكامل
   - البريد الإلكتروني
   - كلمة المرور (6 أحرف على الأقل)
4. اضغط "إنشاء الحساب"
5. ✅ سيصلك بريد تأكيد (اختياري)
6. تواصل مع المطور لتفعيل الاشتراك
```

### 2. تسجيل الدخول

#### **كمالك (Owner):**
```
1. افتح التطبيق
2. اختر "تسجيل دخول المالك"
3. أدخل الإيميل وكلمة المرور
4. اضغط "تسجيل الدخول"
5. ✅ سيتم التحقق من الاشتراك في Firestore
```

#### **كموظف (Sub User):**
```
1. افتح التطبيق
2. اختر "تسجيل دخول الموظف"
3. أدخل اسم المستخدم وكلمة المرور
4. اضغط "تسجيل الدخول"
5. ✅ تحقق محلي بدون إنترنت
```

### 3. إضافة موظف جديد (Sub User)

```
1. سجل دخول كمالك (Owner)
2. انتقل إلى "المستخدمون"
3. اضغط "إضافة موظف"
4. أدخل البيانات:
   - الاسم الكامل
   - اسم المستخدم
   - كلمة المرور
   - الصلاحيات المطلوبة
5. اضغط "حفظ"
6. ✅ سيتمكن الموظف من تسجيل الدخول
```

---

## 🔄 الترحيل من النظام القديم

### التحديث التلقائي (Database Migration)

عند فتح التطبيق لأول مرة بعد التحديث:

```
1. ✅ قاعدة البيانات ترتقي تلقائياً من v2 → v3
2. ✅ الحقول الجديدة تُضاف لجدول TB_Users
3. ✅ جدول TB_Subscription_Cache يُنشأ
4. ✅ المستخدمين الحاليين يتحولون لـ 'owner' إذا كانوا admins
```

### خطوات يدوية مطلوبة:

```
1. تسجيل حساب Firebase للمستخدم الحالي
2. تفعيل الاشتراك في Firestore
3. تسجيل دخول أول مرة بالإيميل
```

---

## 📂 الملفات الجديدة

```
lib/
├── data/
│   └── database_migrations.dart         🆕
├── services/
│   └── subscription_service.dart        🆕
└── screens/
    └── auth/
        ├── login_selection_screen.dart  🆕
        ├── owner_login_screen.dart      🆕
        ├── sub_user_login_screen.dart   🆕
        ├── register_screen.dart         🆕
        └── forgot_password_screen.dart  🆕
```

## ✏️ الملفات المعدلة

```
lib/
├── data/
│   ├── database_helper.dart             ✏️ (Migration + دوال جديدة)
│   └── models.dart                      ✏️ (حقول جديدة للـ User)
├── screens/
│   └── auth/
│       └── splash_screen.dart           ✏️ (التدفق الجديد)
└── pubspec.yaml                         ✏️ (Firebase dependencies)
```

---

## ⚠️ ملاحظات مهمة

### 1. الاتصال بالإنترنت

- **Owner Login:** يحتاج إنترنت لأول مرة فقط
- **Sub User Login:** لا يحتاج إنترنت
- **Offline Grace Period:** 7 أيام بعدها يطلب التحقق أونلاين

### 2. Multi-Device Support

```
خطة احترافية: 3 أجهزة
خطة الشركات: unlimited

كيف يعمل:
1. المستخدم يسجل دخول من جهاز جديد
2. التطبيق يتحقق من عدد الأجهزة المسجلة
3. إذا وصل للحد الأقصى → يمنع الدخول
4. المطور يستطيع حذف جهاز من Firestore Console
```

### 3. الأمان

```
✅ Firebase Auth (Google-grade security)
✅ Firestore Security Rules (كل مستخدم يرى بياناته فقط)
✅ SQLCipher للتخزين المحلي (AES-256)
✅ BCrypt لكلمات المرور المحلية
✅ Device Fingerprinting
```

---

## 🐛 استكشاف الأخطاء

### مشكلة: "لا يوجد اشتراك لهذا الإيميل"

**الحل:**
1. تأكد من إنشاء الاشتراك في Firestore
2. تحقق من الإيميل (حساس لحالة الأحرف)
3. تحقق من Firestore Security Rules

### مشكلة: "تم الوصول للحد الأقصى من الأجهزة"

**الحل:**
1. Firebase Console → Firestore → subscriptions → [email]
2. تعديل `currentDevices` → حذف الجهاز غير المستخدم
3. أو زيادة `maxDevices`

### مشكلة: "يرجى الاتصال بالإنترنت"

**الحل:**
- انتهت الـ Grace Period (7 أيام)
- الاتصال بالإنترنت مرة واحدة يُحدّث الـ Cache

---

## 📞 الدعم الفني

للمساعدة:
- 📧 Email: developer@company.com
- 💬 WhatsApp: +966xxxxxxxxx
- 🐛 GitHub Issues: https://github.com/your-repo/issues

---

## 🔄 التحديثات المستقبلية

### قادم قريباً:
- ☁️ Cloud Backup (النسخ الاحتياطي السحابي)
- 💳 Payment Gateway Integration
- 🌐 Admin Web Panel
- 📱 Phone OTP Login
- 🔔 Push Notifications

---

**تاريخ آخر تحديث:** 2025-11-27
**الإصدار:** 3.0.0
**Database Version:** 3
