import '../data/models.dart';

// =================================================================================================
// Hint: تعريف خدمة المصادقة (Singleton)
// =================================================================================================
// الشرح: هذا الكلاس يتبع نمط Singleton، مما يعني أنه يوجد منه كائن واحد فقط على مستوى التطبيق كله.
// هذا يضمن أننا نتعامل دائماً مع نفس بيانات المستخدم الذي قام بتسجيل الدخول.
class AuthService {
  static final AuthService _instance = AuthService._internal();
  AuthService._internal();
  factory AuthService() {
    return _instance;
  }

  User? _currentUser;

  void login(User user) {
    _currentUser = user;
  }

  void logout() {
    _currentUser = null;
  }

  User? get currentUser => _currentUser;

  // --- ✅ نظام الصلاحيات الجديد ---
  // Hint: بدلاً من دالة واحدة (isAdmin)، لدينا الآن دوال "getters" لكل صلاحية.
  // هذا يجعل الكود في الواجهات أنظف وأكثر قابلية للقراءة.
  // مثال: if (_authService.isAdmin) -> if (_authService.canManageEmployees)

  // الصلاحية العليا
  bool get isAdmin => _currentUser?.isAdmin ?? false;

  // صلاحيات الموردين
  bool get canViewSuppliers => _currentUser?.canViewSuppliers ?? false;
  bool get canEditSuppliers => _currentUser?.canEditSuppliers ?? false;

  // صلاحيات المنتجات
  bool get canViewProducts => _currentUser?.canViewProducts ?? false;
  bool get canEditProducts => _currentUser?.canEditProducts ?? false;

  // صلاحيات الزبائن
  bool get canViewCustomers => _currentUser?.canViewCustomers ?? false;
  bool get canEditCustomers => _currentUser?.canEditCustomers ?? false;

  // صلاحيات التقارير
  bool get canViewReports => _currentUser?.canViewReports ?? false;

  // صلاحيات الموظفين
  bool get canManageEmployees => _currentUser?.canManageEmployees ?? false;
  bool get canViewEmployeesReport => _currentUser?.canViewEmployeesReport ?? false;


  // صلاحيات الإعدادات
  bool get canViewSettings => _currentUser?.canViewSettings ?? false;

  /// تستخدم `?? false` كقيمة افتراضية آمنة في حالة عدم وجود مستخدم مسجل دخوله.
  bool get canManageExpenses => _currentUser?.canManageExpenses ?? false;

  ///  دالة getter جديدة للتحقق مما إذا كان المستخدم الحالي يمكنه عرض تقارير المبيعات النقدية.
  bool get canViewCashSales => _currentUser?.canViewCashSales ?? false;
}
