// lib/utils/reference_type_helper.dart

import 'package:flutter/material.dart';

/// 🔤 مساعد ترجمة أنواع المراجع (ReferenceType)
///
/// ← Hint: يترجم الأسماء التقنية للمراجع إلى أسماء عربية واضحة
/// ← Hint: يوفر أيقونات مناسبة لكل نوع
///
/// **الأنواع المدعومة:**
/// - product_purchase: شراء منتج
/// - product_adjustment: تعديل منتج
/// - product_delete: حذف منتج
/// - sale: عملية بيع
/// - expense: مصروف
/// - profit_withdrawal: سحب أرباح
/// - salary: راتب
/// - advance: سلفة
/// - bonus: مكافأة
class ReferenceTypeHelper {
  /// ترجمة ReferenceType إلى العربية
  ///
  /// **Parameters:**
  /// - referenceType: النوع التقني (product_purchase, sale, etc.)
  ///
  /// **Returns:**
  /// النص المترجم بالعربية
  static String getDisplayName(String? referenceType) {
    if (referenceType == null || referenceType.isEmpty) {
      return 'غير محدد';
    }

    switch (referenceType.toLowerCase()) {
      case 'product_purchase':
        return 'شراء منتج';

      case 'product_adjustment':
        return 'تعديل منتج';

      case 'product_delete':
        return 'حذف منتج';

      case 'sale':
      case 'invoice':
        return 'عملية بيع';

      case 'expense':
      case 'general_expense':
        return 'مصروف';

      case 'profit_withdrawal':
        return 'سحب أرباح';

      case 'salary':
      case 'payroll':
        return 'راتب';

      case 'advance':
      case 'employee_advance':
        return 'سلفة';

      case 'bonus':
      case 'employee_bonus':
        return 'مكافأة';

      case 'customer_payment':
        return 'دفعة زبون';

      case 'supplier_payment':
        return 'دفعة لمورد';

      case 'advance_repayment':
        return 'تسديد سلفة';

      case 'sales_return':
        return 'مرتجع مبيعات';

      default:
        // إذا لم يتم التعرف على النوع، نعيد النص الأصلي
        return referenceType;
    }
  }

  /// الحصول على أيقونة مناسبة لنوع المرجع
  ///
  /// **Parameters:**
  /// - referenceType: النوع التقني (product_purchase, sale, etc.)
  ///
  /// **Returns:**
  /// IconData مناسب للنوع
  static IconData getIcon(String? referenceType) {
    if (referenceType == null || referenceType.isEmpty) {
      return Icons.help_outline;
    }

    switch (referenceType.toLowerCase()) {
      case 'product_purchase':
        return Icons.add_shopping_cart;

      case 'product_adjustment':
        return Icons.edit;

      case 'product_delete':
        return Icons.delete_outline;

      case 'sale':
      case 'invoice':
        return Icons.point_of_sale;

      case 'expense':
      case 'general_expense':
        return Icons.receipt_long;

      case 'profit_withdrawal':
        return Icons.account_balance_wallet;

      case 'salary':
      case 'payroll':
        return Icons.work;

      case 'advance':
      case 'employee_advance':
        return Icons.money;

      case 'bonus':
      case 'employee_bonus':
        return Icons.card_giftcard;

      case 'customer_payment':
        return Icons.payment;

      case 'supplier_payment':
        return Icons.payments;

      case 'advance_repayment':
        return Icons.money_off;

      case 'sales_return':
        return Icons.keyboard_return;

      default:
        return Icons.help_outline;
    }
  }

  /// الحصول على لون مناسب لنوع المرجع
  ///
  /// **Parameters:**
  /// - referenceType: النوع التقني (product_purchase, sale, etc.)
  ///
  /// **Returns:**
  /// Color مناسب للنوع (أخضر للإيرادات، أحمر للمصروفات، برتقالي للتعديلات)
  static Color getColor(String? referenceType) {
    if (referenceType == null || referenceType.isEmpty) {
      return Colors.grey;
    }

    switch (referenceType.toLowerCase()) {
      // مصروفات (أحمر)
      case 'product_purchase':
      case 'expense':
      case 'general_expense':
      case 'profit_withdrawal':
      case 'salary':
      case 'payroll':
      case 'advance':
      case 'employee_advance':
      case 'bonus':
      case 'employee_bonus':
      case 'supplier_payment':
        return Colors.red.shade600;

      // إيرادات (أخضر)
      case 'sale':
      case 'invoice':
      case 'customer_payment':
      case 'advance_repayment':
        return Colors.green.shade600;

      // تعديلات/حذف (برتقالي/رمادي)
      case 'product_adjustment':
        return Colors.orange.shade600;

      case 'product_delete':
      case 'sales_return':
        return Colors.grey.shade600;

      default:
        return Colors.grey;
    }
  }

  /// الحصول على وصف تفصيلي لنوع المرجع
  ///
  /// **Parameters:**
  /// - referenceType: النوع التقني (product_purchase, sale, etc.)
  ///
  /// **Returns:**
  /// وصف تفصيلي بالعربية
  static String getDescription(String? referenceType) {
    if (referenceType == null || referenceType.isEmpty) {
      return 'نوع المرجع غير محدد';
    }

    switch (referenceType.toLowerCase()) {
      case 'product_purchase':
        return 'عملية شراء منتج جديد أو إضافة كمية لمنتج موجود';

      case 'product_adjustment':
        return 'تعديل كمية أو سعر منتج موجود في المخزون';

      case 'product_delete':
        return 'حذف منتج من المخزون';

      case 'sale':
      case 'invoice':
        return 'عملية بيع منتجات للزبائن';

      case 'expense':
      case 'general_expense':
        return 'مصروف عام من مصاريف المؤسسة';

      case 'profit_withdrawal':
        return 'سحب أرباح من الصندوق';

      case 'salary':
      case 'payroll':
        return 'دفع راتب لموظف';

      case 'advance':
      case 'employee_advance':
        return 'سلفة مالية لموظف';

      case 'bonus':
      case 'employee_bonus':
        return 'مكافأة مالية لموظف';

      case 'customer_payment':
        return 'دفعة مالية من زبون';

      case 'supplier_payment':
        return 'دفعة مالية لمورد';

      case 'advance_repayment':
        return 'تسديد سلفة من موظف';

      case 'sales_return':
        return 'مرتجع مبيعات من زبون';

      default:
        return 'نوع مرجع: $referenceType';
    }
  }
}
