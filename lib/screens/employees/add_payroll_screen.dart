// // lib/screens/employees/add_payroll_screen.dart

// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import '../../data/database_helper.dart';
// import '../../data/models.dart';
// import '../../services/auth_service.dart';
// import '../../utils/helpers.dart';
// import 'package:accounting_app/l10n/app_localizations.dart';
// import '../../theme/app_colors.dart';
// import '../../widgets/glass_container.dart';
// import '../../widgets/gradient_background.dart';

// class AddPayrollScreen extends StatefulWidget {
//   final Employee employee;
//   const AddPayrollScreen({super.key, required this.employee});

//   @override
//   State<AddPayrollScreen> createState() => _AddPayrollScreenState();
// }

// class _AddPayrollScreenState extends State<AddPayrollScreen> {
//   // ... (كل متغيرات الحالة والدوال المنطقية تبقى كما هي)
//   final _formKey = GlobalKey<FormState>();
//   final dbHelper = DatabaseHelper.instance;
//   final AuthService _authService = AuthService();
//   final _baseSalaryController = TextEditingController();
//   final _bonusesController = TextEditingController(text: '0');
//   final _deductionsController = TextEditingController(text: '0');
//   final _advanceRepaymentController = TextEditingController(text: '0');
//   final _notesController = TextEditingController();
//   final _dateController = TextEditingController();
//   late int _selectedYear;
//   late int _selectedMonth;
//   final List<String> _months = ['يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو', 'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'];
//   DateTime _selectedDate = DateTime.now();
//   double _netSalary = 0.0;

//   @override
//   void initState() {
//     super.initState();
//     _selectedYear = DateTime.now().year;
//     _selectedMonth = DateTime.now().month;
//     _baseSalaryController.text = widget.employee.baseSalary.toString();
//     _dateController.text = DateFormat('yyyy-MM-dd').format(_selectedDate);
//     _baseSalaryController.addListener(_calculateNetSalary);
//     _bonusesController.addListener(_calculateNetSalary);
//     _deductionsController.addListener(_calculateNetSalary);
//     _advanceRepaymentController.addListener(_calculateNetSalary);
//     _calculateNetSalary();
//   }

//   @override
//   void dispose() {
//     _baseSalaryController.dispose();
//     _bonusesController.dispose();
//     _deductionsController.dispose();
//     _advanceRepaymentController.dispose();
//     _notesController.dispose();
//     _dateController.dispose();
//     super.dispose();
//   }

//   void _calculateNetSalary() {
//     final baseSalary = double.tryParse(convertArabicNumbersToEnglish(_baseSalaryController.text)) ?? 0.0;
//     final bonuses = double.tryParse(convertArabicNumbersToEnglish(_bonusesController.text)) ?? 0.0;
//     final deductions = double.tryParse(convertArabicNumbersToEnglish(_deductionsController.text)) ?? 0.0;
//     final advanceRepayment = double.tryParse(convertArabicNumbersToEnglish(_advanceRepaymentController.text)) ?? 0.0;
//     setState(() {
//       _netSalary = (baseSalary + bonuses) - (deductions + advanceRepayment);
//     });
//   }

//   Future<void> _savePayroll() async {
//     final l10n = AppLocalizations.of(context)!;
//     if (!_formKey.currentState!.validate()) return;
//     try {
//       final isDuplicate = await dbHelper.isPayrollDuplicate(widget.employee.employeeID!, _selectedMonth, _selectedYear);
//       if (isDuplicate) {
//         if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.payrollAlreadyExists), backgroundColor: Colors.red));
//         return;
//       }
//       final baseSalary = double.parse(convertArabicNumbersToEnglish(_baseSalaryController.text));
//       final bonuses = double.parse(convertArabicNumbersToEnglish(_bonusesController.text));
//       final deductions = double.parse(convertArabicNumbersToEnglish(_deductionsController.text));
//       final advanceRepayment = double.parse(convertArabicNumbersToEnglish(_advanceRepaymentController.text));
//       final newPayroll = PayrollEntry(employeeID: widget.employee.employeeID!, paymentDate: _selectedDate.toIso8601String(), payrollMonth: _selectedMonth, payrollYear: _selectedYear, baseSalary: baseSalary, bonuses: bonuses, deductions: deductions, advanceDeduction: advanceRepayment, netSalary: _netSalary, notes: _notesController.text);
//       await dbHelper.recordNewPayroll(newPayroll, advanceRepayment);
//       final action = 'تسجيل راتب شهر ${_months[_selectedMonth - 1]} للموظف: ${widget.employee.fullName}';
//       await dbHelper.logActivity(action, userId: _authService.currentUser?.id, userName: _authService.currentUser?.fullName);
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.payrollSavedSuccess), backgroundColor: Colors.green));
//         Navigator.of(context).pop(true);
//       }
//     } catch (e) {
//       if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.errorOccurred(e.toString())), backgroundColor: Colors.red));
//     }
//   }

//   Future<void> _pickDate() async {
//     final pickedDate = await showDatePicker(context: context, initialDate: _selectedDate, firstDate: DateTime(2000), lastDate: DateTime.now().add(const Duration(days: 365)));
//     if (pickedDate != null && pickedDate != _selectedDate) {
//       setState(() {
//         _selectedDate = pickedDate;
//         _dateController.text = DateFormat('yyyy-MM-dd').format(pickedDate);
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final l10n = AppLocalizations.of(context)!;
//     final theme = Theme.of(context);

//     return Scaffold(
//       backgroundColor: Colors.transparent,
//       extendBodyBehindAppBar: true,
//       appBar: AppBar(
//         title: Text(l10n.payrollFor(widget.employee.fullName)),
//         backgroundColor: Colors.transparent,
//         elevation: 0,
//       ),
//       body: GradientBackground(
//         child: SafeArea(
//           child: Form(
//             key: _formKey,
//             child: ListView(
//               padding: const EdgeInsets.all(20.0),
//               children: [
//                 _buildNetSalaryCard(l10n),
//                 const SizedBox(height: 32),
                
//                 Text(l10n.payrollForMonthAndYear, style: theme.textTheme.titleMedium),
//                 const SizedBox(height: 12),
//                 Row(
//                   children: [
//                     Expanded(child: DropdownButtonFormField<int>(value: _selectedMonth, decoration: _getGlassInputDecoration(l10n.month), dropdownColor: AppColors.primaryPurple, items: List.generate(12, (index) => DropdownMenuItem(value: index + 1, child: Text(_months[index]))), onChanged: (v) { if (v != null) setState(() => _selectedMonth = v); })),
//                     const SizedBox(width: 16),
//                     Expanded(child: DropdownButtonFormField<int>(value: _selectedYear, decoration: _getGlassInputDecoration(l10n.year), dropdownColor: AppColors.primaryPurple, items: List.generate(5, (i) => DateTime.now().year - 2 + i).map((y) => DropdownMenuItem(value: y, child: Text(y.toString()))).toList(), onChanged: (v) { if (v != null) setState(() => _selectedYear = v); })),
//                   ],
//                 ),
//                 const SizedBox(height: 20),
                
//                 // --- ✅✅✅ بداية الإصلاح ✅✅✅ ---
//                 // الشرح: تم استدعاء دالة _buildTextField مع تمرير كل المتغيرات كأسماء
//                 _buildTextField(controller: _baseSalaryController, label: l10n.baseSalary, icon: Icons.account_balance_wallet_outlined),
//                 const SizedBox(height: 20),
//                 _buildTextField(controller: _bonusesController, label: l10n.bonuses, icon: Icons.card_giftcard_outlined),
//                 const SizedBox(height: 20),
//                 _buildTextField(controller: _deductionsController, label: l10n.deductions, icon: Icons.remove_circle_outline),
//                 const SizedBox(height: 20),
                
//                 // الشرح: تم استبدال TextFormField هنا أيضاً باستدعاء للدالة المساعدة
//                 _buildTextField(
//                   controller: _advanceRepaymentController,
//                   label: l10n.advanceRepayment,
//                   icon: Icons.request_quote_outlined,
//                   helperText: l10n.currentBalanceOnEmployee(formatCurrency(widget.employee.balance)),
//                   validator: (v) {
//                     if (v == null || v.isEmpty) return l10n.enterZeroIfNotRepaying;
//                     final amount = double.tryParse(convertArabicNumbersToEnglish(v));
//                     if (amount == null || amount < 0) return l10n.enterValidNumber;
//                     if (amount > widget.employee.balance) return l10n.repaymentExceedsBalance;
//                     return null;
//                   },
//                 ),
//                 // --- ⏹️⏹️⏹️ نهاية الإصلاح ⏹️⏹️⏹️ ---

//                 const SizedBox(height: 20),
//                 TextFormField(controller: _dateController, decoration: _getGlassInputDecoration(l10n.paymentDate, Icons.calendar_today), readOnly: true, onTap: _pickDate),
//                 const SizedBox(height: 20),
//                 TextFormField(controller: _notesController, decoration: _getGlassInputDecoration(l10n.notesOptional, Icons.notes), maxLines: 2),
//                 const SizedBox(height: 40),
//                 ElevatedButton.icon(onPressed: _savePayroll, icon: const Icon(Icons.save), label: Text(l10n.saveAndPaySalary)),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   // --- ✅✅✅ بداية الإصلاح ✅✅✅ ---
//   // الشرح: تم تعديل تعريف الدالة لجعل كل المتغيرات مسماة ومطلوبة (أو اختيارية)
//   Widget _buildTextField({
//     required TextEditingController controller,
//     required String label,
//     required IconData icon,
//     String? helperText,
//     String? Function(String?)? validator,
//   }) {
//     final l10n = AppLocalizations.of(context)!; // نحصل على l10n هنا
//     return TextFormField(
//       controller: controller,
//       decoration: _getGlassInputDecoration(label, icon, helperText),
//       keyboardType: const TextInputType.numberWithOptions(decimal: true),
//       validator: validator ?? (v) {
//         if (v == null || v.isEmpty) return l10n.fieldRequiredEnterZero;
//         if (double.tryParse(convertArabicNumbersToEnglish(v)) == null) return l10n.enterValidNumber;
//         return null;
//       },
//     );
//   }
//   // --- ⏹️⏹️⏹️ نهاية الإصلاح ⏹️⏹️⏹️ ---

//   Widget _buildNetSalaryCard(AppLocalizations l10n) {
//     return GlassContainer(
//       borderRadius: 20,
//       padding: const EdgeInsets.all(20.0),
//       child: Column(
//         children: [
//           Text(l10n.netSalaryDue, style: TextStyle(fontSize: 18, color: AppColors.textGrey)),
//           const SizedBox(height: 8),
//           Text(
//             formatCurrency(_netSalary),
//             style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: _netSalary >= 0 ? Colors.greenAccent : Colors.redAccent),
//           ),
//         ],
//       ),
//     );
//   }

//   InputDecoration _getGlassInputDecoration(String labelText, [IconData? icon, String? helperText]) {
//     final theme = Theme.of(context);
//     return InputDecoration(
//       labelText: labelText,
//       helperText: helperText,
//       helperStyle: TextStyle(color: theme.colorScheme.primary.withOpacity(0.8)),
//       prefixIcon: icon != null ? Icon(icon, color: AppColors.textGrey.withOpacity(0.8)) : null,
//       filled: true,
//       fillColor: AppColors.glassBgColor,
//       labelStyle: theme.textTheme.bodyMedium,
//       border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: AppColors.glassBorderColor, width: 1.5)),
//       enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: AppColors.glassBorderColor, width: 1.5)),
//       focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: theme.colorScheme.primary, width: 2)),
//     );
//   }
// }
