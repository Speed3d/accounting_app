import 'package:intl/intl.dart'; 

// هذا الملف سيحتوي على دوال مساعدة عامة يمكن استخدامها في أي مكان بالتطبيق

String convertArabicNumbersToEnglish(String input) {
  const arabicNumbers = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
  
  const englishNumbers = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];

  for (int i = 0; i < arabicNumbers.length; i++) {
    input = input.replaceAll(arabicNumbers[i], englishNumbers[i]);
  }
  return input;

}

// Hint: هذه دالة مساعدة لتنسيق الأرقام كعملة.
// تأخذ رقمًا (double) وترجعه كنص منسق مع فواصل الآلاف.
// مثال: formatCurrency(50000.5)  ->  "50,000.5"
// مثال: formatCurrency(1234567) ->  "1,234,567"
String formatCurrency(double amount) {
  // Hint: NumberFormat هو كلاس من حزمة intl يقوم بكل العمل الصعب.
  // '###,##0.##' هو النمط الذي نستخدمه:
  // # - يعني رقم اختياري (لا يظهر إذا كان صفرًا).
  // 0 - يعني رقم إجباري (يظهر كـ 0 إذا لم يكن هناك رقم).
  // , - يعني ضع فاصلة الآلاف.
  // . - يعني ضع الفاصلة العشرية.
  final formatter = NumberFormat('###,##0.##', 'en_US');
  return formatter.format(amount);
}


