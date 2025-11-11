// lib/services/auth_service.dart

import 'package:bcrypt/bcrypt.dart';
import '../data/models.dart';

/// خدمة المصادقة - Singleton Pattern
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

  // ==========================================================================
  // ← Hint: دالة جديدة - التحقق من كلمة المرور
  // ==========================================================================
  bool verifyPassword(String password) {
    if (_currentUser == null) return false;
    return BCrypt.checkpw(password, _currentUser!.password);
  }

  // ==========================================================================
  // ← Hint: دالة جديدة - الحصول على المستخدم الحالي
  // ==========================================================================
  User? getCurrentUser() {
    return _currentUser;
  }

  // --- نظام الصلاحيات ---
  bool get isAdmin => _currentUser?.isAdmin ?? false;
  bool get canViewSuppliers => _currentUser?.canViewSuppliers ?? false;
  bool get canEditSuppliers => _currentUser?.canEditSuppliers ?? false;
  bool get canViewProducts => _currentUser?.canViewProducts ?? false;
  bool get canEditProducts => _currentUser?.canEditProducts ?? false;
  bool get canViewCustomers => _currentUser?.canViewCustomers ?? false;
  bool get canEditCustomers => _currentUser?.canEditCustomers ?? false;
  bool get canViewReports => _currentUser?.canViewReports ?? false;
  bool get canManageEmployees => _currentUser?.canManageEmployees ?? false;
  bool get canViewEmployeesReport => _currentUser?.canViewEmployeesReport ?? false;
  bool get canViewSettings => _currentUser?.canViewSettings ?? false;
  bool get canManageExpenses => _currentUser?.canManageExpenses ?? false;
  bool get canViewCashSales => _currentUser?.canViewCashSales ?? false;
}