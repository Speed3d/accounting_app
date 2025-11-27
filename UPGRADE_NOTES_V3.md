# ملاحظات الترقية - النظام الجديد v3.0

## ⚡ ملخص سريع

تم تحويل التطبيق من **نظام Device-based** إلى **Email-based Subscription System**.

---

## 🎯 ما تغير؟

| الميزة | قبل (v2) | بعد (v3) |
|--------|---------|---------|
| **المصادقة** | Username + Password | Email + Password (Firebase) |
| **التفعيل** | Device Fingerprint + Code | Firestore Subscription |
| **Multi-Device** | ❌ جهاز واحد فقط | ✅ 3 أجهزة (أو unlimited) |
| **استعادة كلمة المرور** | ❌ غير متوفر | ✅ عبر الإيميل |
| **المستخدمون الفرعيون** | ✅ محلي فقط | ✅ Owner + Sub Users |
| **Offline Mode** | ✅ دائماً | ✅ 7 أيام grace period |

---

## 📦 Dependencies الجديدة

```yaml
firebase_auth: ^4.15.3
cloud_firestore: ^4.13.6
```

---

## 🚀 خطوات التشغيل

### 1. تثبيت المكتبات
```bash
flutter pub get
```

### 2. إعداد Firebase
1. إنشاء مشروع Firebase
2. إضافة `google-services.json` في `android/app/`
3. تفعيل Authentication + Firestore

### 3. Firestore Security Rules
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /subscriptions/{email} {
      allow read: if request.auth != null &&
                     request.auth.token.email == email;
      allow write: if false;
    }
  }
}
```

### 4. إنشاء اشتراك تجريبي
```javascript
// Firestore Console
Collection: subscriptions
Document: test@example.com

{
  email: "test@example.com",
  plan: "trial",
  startDate: Timestamp.now(),
  endDate: Timestamp (بعد 14 يوم),
  isActive: true,
  maxDevices: 3,
  currentDevices: [],
  features: {
    canCreateSubUsers: true,
    maxSubUsers: 10
  },
  status: "active"
}
```

### 5. تشغيل التطبيق
```bash
flutter run
```

---

## 🧪 الاختبار

### Test Case 1: تسجيل حساب جديد
```
1. افتح التطبيق
2. "إنشاء حساب"
3. test@example.com + password123
4. ✅ الحساب يُنشأ في Firebase
```

### Test Case 2: تسجيل الدخول
```
1. "تسجيل دخول المالك"
2. test@example.com + password123
3. ✅ يتحقق من Firestore
4. ✅ يحفظ الـ Cache محلياً
```

### Test Case 3: Offline Mode
```
1. سجل دخول (مع إنترنت)
2. قطع الإنترنت
3. أعد فتح التطبيق
4. ✅ يعمل من الـ Cache (لمدة 7 أيام)
```

### Test Case 4: إضافة موظف
```
1. سجل دخول كـ Owner
2. "المستخدمون" → "إضافة"
3. أضف موظف (username: ahmed, pass: 123456)
4. سجل خروج
5. "تسجيل دخول الموظف"
6. ✅ يعمل بدون إنترنت
```

---

## 🔧 الملفات المهمة

### للقراءة:
- `MIGRATION_GUIDE_V3.md` - دليل شامل ومفصل
- `lib/services/subscription_service.dart` - منطق الاشتراكات
- `lib/data/database_migrations.dart` - نظام الترقية

### للتعديل (إذا مطلوب):
- `lib/screens/auth/splash_screen.dart` - التدفق الأولي
- Firestore Security Rules

---

## ⚠️ تحذيرات

1. ❌ **لا تُشغّل** في production بدون إعداد Firebase
2. ❌ **لا تنشر** `google-services.json` في GitHub
3. ✅ **استخدم** `.gitignore` للملفات الحساسة
4. ✅ **اختبر** Database Migration على بيانات تجريبية أولاً

---

## 📝 TODO للمطور

- [ ] إعداد Firebase Production Project
- [ ] تحديث Firestore Security Rules
- [ ] إضافة subscriptions للمستخدمين الحاليين
- [ ] اختبار Multi-device
- [ ] تحديث الوثائق للمستخدمين النهائيين

---

## 📞 الدعم

مشاكل؟ اتصل بنا:
- Email: developer@company.com
- GitHub Issues: [Link]

---

**تاريخ:** 2025-11-27
**الإصدار:** 3.0.0
**Database Version:** 3
