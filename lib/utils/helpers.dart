
import '../services/currency_service.dart'; // ✅ Hint: استيراد CurrencyService
// هذا الملف سيحتوي على دوال مساعدة عامة يمكن استخدامها في أي مكان بالتطبيق
String convertArabicNumbersToEnglish(String input) {
const arabicNumbers = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
const englishNumbers = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
for (int i = 0; i < arabicNumbers.length; i++) {
input = input.replaceAll(arabicNumbers[i], englishNumbers[i]);
}
return input;
}
/// ✅ Hint: تنسيق الأرقام كعملة باستخدام CurrencyService
/// الآن تستخدم العملة المختارة من المستخدم
String formatCurrency(double amount) {
// ✅ Hint: استخدام CurrencyService لتنسيق المبلغ
return CurrencyService.instance.formatAmount(amount);
}
/// ✅ Hint: دالة جديدة - تنسيق بدون رمز العملة
String formatCurrencyWithoutSymbol(double amount) {
return CurrencyService.instance.formatAmountWithoutSymbol(amount);
}
// ✅ نسخة محسّنة تدعم حالات أكثر
bool isPartnership(String? supplierType) {
if (supplierType == null || supplierType.isEmpty) return false;
final normalized = supplierType.trim().toLowerCase();
return normalized == 'شراكة' ||
normalized == 'partnership' ||
normalized.contains('شراك') ||
normalized.contains('partner');
}
bool isIndividual(String? supplierType) {
if (supplierType == null || supplierType.isEmpty) return false;
final normalized = supplierType.trim().toLowerCase();
return normalized == 'فردي' ||
normalized == 'individual' ||
normalized.contains('فرد') ||
normalized.contains('individ');
}