# 🔒 دليل إعداد Firestore Security Rules

## ⚠️ مهم جداً - يجب تنفيذ هذه الخطوة!

**بدون هذه الخطوة**: ستحصل على خطأ `permission-denied` عند محاولة إنشاء/قراءة الاشتراكات في Firestore.

**المشكلة**:
```
[cloud_firestore/permission-denied]
The caller does not have permission to execute the specified operation.
```

**الحل**: إضافة Security Rules الصحيحة في Firebase Console.

---

## 📋 الخطوات التفصيلية

### الخطوة 1️⃣: فتح Firebase Console

1. افتح المتصفح واذهب إلى: [https://console.firebase.google.com](https://console.firebase.google.com)

2. سجل دخول بحساب Google الخاص بك

3. اختر مشروعك من القائمة

---

### الخطوة 2️⃣: الانتقال لـ Firestore Rules

1. من القائمة الجانبية اليسرى، اختر:
   ```
   Build → Firestore Database
   ```

2. انقر على تبويب **"Rules"** (في الأعلى)

---

### الخطوة 3️⃣: نسخ Rules من المشروع

1. افتح ملف `firestore.rules` في مجلد المشروع:
   ```
   /home/user/accounting_app/firestore.rules
   ```

2. انسخ **جميع** محتويات الملف (Ctrl+A ثم Ctrl+C)

---

### الخطوة 4️⃣: لصق Rules في Firebase Console

1. في صفحة Rules، سترى محرر نصوص

2. **احذف** كل المحتوى الموجود حالياً

3. **الصق** محتوى ملف `firestore.rules` الذي نسخته

4. يجب أن يبدو المحرر هكذا:
   ```javascript
   rules_version = '2';

   service cloud.firestore {
     match /databases/{database}/documents {
       match /subscriptions/{email} {
         allow read: if request.auth != null
                     && request.auth.token.email == email;

         allow create: if request.auth != null
                       && request.auth.token.email == email;

         allow update: if request.auth != null
                       && request.auth.token.email == email
                       && request.resource.data.diff(resource.data)
                          .affectedKeys()
                          .hasOnly(['currentDevices', 'updatedAt']);
       }
     }
   }
   ```

---

### الخطوة 5️⃣: نشر Rules

1. انقر على زر **"Publish"** (في الأعلى يمين المحرر)

2. سترى رسالة تأكيد:
   ```
   ✅ Firestore rules published successfully
   ```

3. **مهم**: تأكد من ظهور رسالة النجاح!

---

### الخطوة 6️⃣: التحقق من Rules

#### طريقة 1: Rules Playground

1. بعد النشر، انقر على **"Rules Playground"** (بجانب زر Publish)

2. اختبر القراءة (Read):
   - **Location**: `/subscriptions/test@example.com`
   - **Authenticated**: Yes
   - **Auth UID**: (أي UID)
   - **Email**: `test@example.com`
   - انقر **"Run"**
   - النتيجة: ✅ **Allowed** (مسموح)

3. اختبر القراءة لإيميل آخر (يجب أن تُرفض):
   - **Location**: `/subscriptions/other@example.com`
   - **Email**: `test@example.com` (مختلف!)
   - انقر **"Run"**
   - النتيجة**: ❌ **Denied** (ممنوع) ← صحيح!

#### طريقة 2: اختبار من التطبيق

1. احذف حساب `test@example.com` من Firebase Authentication (إن وُجد)

2. شغّل التطبيق:
   ```bash
   flutter run
   ```

3. سجل حساب جديد بإيميل `test@example.com`

4. تابع الـ Logs:
   ```
   ✅ تم إنشاء الحساب في Firebase Auth بنجاح
   ✅ تم إنشاء Owner محلي بنجاح
   🔍 auto_activate_trial = true
   🚀 إنشاء اشتراك تجريبي تلقائياً...
   ✅ تم إنشاء الاشتراك التجريبي بنجاح  ← يجب أن تظهر!
   ```

5. إذا ظهرت الرسالة الأخيرة → ✅ **Rules تعمل!**

6. إذا ظهر خطأ permission-denied → ❌ راجع الخطوات السابقة

---

## 📊 فهم Rules (للمطورين)

### ما الذي تفعله Rules؟

```javascript
match /subscriptions/{email} {
  // 1️⃣ القراءة
  allow read: if request.auth != null
              && request.auth.token.email == email;
```

**الشرح**:
- المستخدم يجب أن يكون مسجل دخول (`request.auth != null`)
- Email المستخدم = email في الـ document path
- **مثال**: `test@example.com` يمكنه قراءة `/subscriptions/test@example.com` فقط

---

```javascript
  // 2️⃣ الإنشاء
  allow create: if request.auth != null
                && request.auth.token.email == email;
```

**الشرح**:
- يمكن إنشاء subscription فقط للمستخدم نفسه
- **مثال**: `test@example.com` يمكنه إنشاء `/subscriptions/test@example.com` فقط

---

```javascript
  // 3️⃣ التحديث
  allow update: if request.auth != null
                && request.auth.token.email == email
                && request.resource.data.diff(resource.data)
                   .affectedKeys()
                   .hasOnly(['currentDevices', 'updatedAt']);
```

**الشرح**:
- يمكن تحديث الحقول التالية فقط:
  - `currentDevices` (إضافة/إزالة أجهزة)
  - `updatedAt` (تحديث التاريخ)
- **لا يمكن** تعديل:
  - `plan` (الخطة)
  - `maxDevices` (الحد الأقصى للأجهزة)
  - `endDate` (تاريخ الانتهاء)
  - `isActive` (الحالة)

---

## 🎯 الأمان المُطبّق

| العملية | المسموح | الممنوع |
|---------|---------|---------|
| القراءة | اشتراكك فقط | اشتراكات الآخرين |
| الإنشاء | اشتراكك مرة واحدة | إنشاء لآخرين |
| التحديث | الأجهزة فقط | plan, endDate, isActive |
| الحذف | ❌ ممنوع تماماً | كل شيء |

---

## 🐛 حل المشاكل

### المشكلة 1: Rules لا تظهر بعد النشر

**الحل**:
1. انتظر 1-2 دقيقة (التحديث قد يأخذ وقتاً)
2. أعد تحميل الصفحة (Ctrl+R)
3. تحقق من تبويب "Rules" (ليس "Data")

---

### المشكلة 2: خطأ Syntax Error عند النشر

**الحل**:
1. تأكد من نسخ الملف كاملاً (من `rules_version` إلى آخر `}`)
2. تأكد من عدم وجود أحرف غريبة
3. انسخ من `firestore.rules` مباشرة (لا تكتب يدوياً!)

---

### المشكلة 3: permission-denied ما زال يظهر

**الأسباب المحتملة**:

1. **Rules لم تُنشر بعد**:
   - تحقق من ظهور رسالة "Rules published successfully"

2. **المستخدم غير مسجل دخول**:
   - تحقق من الـ Logs: `request.auth != null`

3. **Email مختلف**:
   - تحقق: Email في Auth = Email في Firestore path

4. **Cache**:
   - احذف cache التطبيق وأعد المحاولة
   - أو امسح بيانات التطبيق من Settings

---

## ✅ التحقق النهائي

قائمة التحقق:

- [ ] فتحت Firebase Console
- [ ] اخترت مشروعك الصحيح
- [ ] ذهبت لـ Firestore Database → Rules
- [ ] نسخت محتوى `firestore.rules` بالكامل
- [ ] لصقت في المحرر
- [ ] نشرت بالضغط على "Publish"
- [ ] ظهرت رسالة النجاح
- [ ] اختبرت من التطبيق
- [ ] الاشتراك يُنشأ بدون أخطاء

إذا أكملت جميع النقاط → ✅ **Rules جاهزة وتعمل!**

---

## 📚 مراجع إضافية

- [Firestore Security Rules Documentation](https://firebase.google.com/docs/firestore/security/get-started)
- [Testing Rules](https://firebase.google.com/docs/firestore/security/test-rules-emulator)
- [Common Patterns](https://firebase.google.com/docs/firestore/security/rules-conditions)

---

## ⏰ الوقت المتوقع

**الخطوات من 1-5**: 5-10 دقائق فقط!

**سهلة جداً** - فقط نسخ ولصق ونشر ✅

---

**ملاحظة**: يمكنك دائماً تعديل Rules لاحقاً إذا احتجت تغييرات.
لكن **لا تحذف** القواعد الموجودة حالياً - هي ضرورية لعمل التطبيق!
