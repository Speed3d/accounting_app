// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get settings => 'الإعدادات';

  @override
  String get homePage => 'الصفحة الرئيسية';

  @override
  String get users => 'المستخدمين';

  @override
  String get suppliers => 'الموردين';

  @override
  String get products => 'المنتجات';

  @override
  String get employees => 'الموظفين';

  @override
  String get customers => 'العملاء';

  @override
  String get reports => 'التقارير';

  @override
  String get more => 'المزيد';

  @override
  String get home => 'الرئيسية';

  @override
  String get customization => 'التخصيص';

  @override
  String get companyInformation => 'معلومات الشركة';

  @override
  String get changeAppNameAndLogo => 'تغيير اسم وشعار التطبيق';

  @override
  String get dataManagement => 'إدارة البيانات';

  @override
  String get archiveCenter => 'مركز الأرشفة';

  @override
  String get restoreArchivedItems => 'استعادة العناصر المؤرشفة';

  @override
  String get noarchivedcustomers => 'لا يوجد زبائن مؤرشفة';

  @override
  String get noarchivedproducts => 'لا يوجد منتجات مؤرشفة';

  @override
  String get noarchivedsuppliers => 'لا يوجد موردين مؤرشفة';

  @override
  String get backupAndRestore => 'النسخ الاحتياطي والاستعادة';

  @override
  String get saveAndRestoreAppData => 'حفظ واستعادة بيانات التطبيق';

  @override
  String get about => 'حول';

  @override
  String get aboutTheApp => 'حول التطبيق';

  @override
  String get language => 'اللغة';

  @override
  String get changeLanguage => 'تغيير لغة التطبيق';

  @override
  String get customersList => 'قائمة الزبائن';

  @override
  String get noActiveCustomers => 'لا يوجد زبائن نشطون حتى الآن.';

  @override
  String get phone => 'الهاتف';

  @override
  String get unregistered => 'غير مسجل';

  @override
  String get remainingForHim => 'له رصيد';

  @override
  String get remainingOnHim => 'له دين';

  @override
  String get balance => 'الرصيد';

  @override
  String get archive => 'أرشفة';

  @override
  String get confirmArchive => 'تأكيد الأرشفة';

  @override
  String get cancel => 'إلغاء';

  @override
  String get edit => 'تعديل';

  @override
  String get delete => 'حذف';

  @override
  String get save => 'حفظ';

  @override
  String get addEditCustomer => 'إضافة/تعديل زبون';

  @override
  String get nopurchasesyetrecorded => 'لم يتم تسجيل أي مشتريات بعد';

  @override
  String get nopaymentsyetrecorded => 'لم يتم تسجيل أي دفعات بعد';

  @override
  String get customerName => 'اسم الزبون';

  @override
  String get startfirstcustomer => 'ابدأ بإضافة أول زبون لك';

  @override
  String get loadingcustomers => 'جاري تحميل الزبائن ...';

  @override
  String get addressOptional => 'العنوان (اختياري)';

  @override
  String get searchcustomer => 'بحث عن عميل';

  @override
  String get phoneOptional => 'الهاتف (اختياري)';

  @override
  String get fieldRequired => 'الحقل مطلوب';

  @override
  String get customerAddedSuccess => 'تم إضافة الزبون بنجاح!';

  @override
  String get customerUpdatedSuccess => 'تم تحديث الزبون بنجاح!';

  @override
  String get chooseImageSource => 'اختر مصدر الصورة';

  @override
  String get gallery => 'المعرض';

  @override
  String get camera => 'الكاميرا';

  @override
  String get customerDetails => 'تفاصيل الزبون';

  @override
  String get purchases => 'عمليات الشراء';

  @override
  String get payments => 'الدفعات';

  @override
  String get noPurchases => 'لا توجد عمليات شراء مسجلة.';

  @override
  String get noPayments => 'لا توجد دفعات مسجلة.';

  @override
  String get newSaleSuccess => 'تم تسجيل عملية الشراء بنجاح!';

  @override
  String get newPayment => 'دفعة جديدة';

  @override
  String get paidAmount => 'المبلغ المدفوع';

  @override
  String get amountRequired => 'المبلغ مطلوب';

  @override
  String get enterValidAmount => 'أدخل مبلغًا صحيحًا أكبر من صفر';

  @override
  String get amountExceedsDebt => 'المبلغ أكبر من الدين المتبقي';

  @override
  String get notesOptional => 'ملاحظات (اختياري)';

  @override
  String get paymentSuccess => 'تم تسجيل الدفعة بنجاح!';

  @override
  String get returnConfirmTitle => 'تأكيد الإرجاع';

  @override
  String returnConfirmContent(String details) {
    return 'هل أنت متأكد من إرجاع هذا المنتج؟\n\"$details\"\nسيتم إعادة الكمية للمخزن وتعديل حساب الزبون.';
  }

  @override
  String get returnSuccess => 'تم إرجاع المنتج بنجاح!';

  @override
  String errorOccurred(String error) {
    return 'حدث خطأ';
  }

  @override
  String get returnItem => 'تأكيد الإرجاع';

  @override
  String saleDetails(String productName, String quantity) {
    return 'تفاصيل البيع: $productName (الكمية: $quantity)';
  }

  @override
  String newAdvanceFor(Object name) {
    return 'سلفة جديدة لـ: $name';
  }

  @override
  String get advanceAmount => 'مبلغ السلفة';

  @override
  String get advanceDate => 'تاريخ السلفة';

  @override
  String get saveAdvance => 'حفظ السلفة';

  @override
  String get advanceAddedSuccess => 'تم تسجيل السلفة بنجاح!';

  @override
  String get unpaid => 'غير مسددة';

  @override
  String get addEmployee => 'إضافة موظف';

  @override
  String get editEmployee => 'تعديل بيانات موظف';

  @override
  String get employeeName => 'اسم الموظف الكامل';

  @override
  String get employeeNameRequired => 'اسم الموظف مطلوب';

  @override
  String get jobTitle => 'العنوان الوظيفي';

  @override
  String get jobTitleRequired => 'العنوان الوظيفي مطلوب';

  @override
  String get baseSalary => 'الراتب الأساسي';

  @override
  String get baseSalaryRequired => 'الراتب الأساسي مطلوب';

  @override
  String get enterValidNumber => 'الرجاء إدخال رقم صحيح';

  @override
  String get hireDate => 'تاريخ التعيين';

  @override
  String get employeeAddedSuccess => 'تمت إضافة الموظف بنجاح';

  @override
  String get employeeUpdatedSuccess => 'تم تحديث بيانات الموظف بنجاح';

  @override
  String payrollFor(Object name) {
    return 'راتب: $name';
  }

  @override
  String get payrollForMonthAndYear => 'الراتب عن شهر وسنة:';

  @override
  String get month => 'الشهر';

  @override
  String get year => 'السنة';

  @override
  String get payrollAlreadyExists => 'خطأ: تم تسجيل راتب لهذا الشهر بالفعل.';

  @override
  String get payrollSavedSuccess => 'تم تسجيل الراتب بنجاح!';

  @override
  String get bonuses => 'المكافآت';

  @override
  String get deductions => 'الخصومات';

  @override
  String get advanceRepayment => 'تسديد من السلفة (-)';

  @override
  String currentBalanceOnEmployee(Object balance) {
    return 'الرصيد الحالي على الموظف: $balance';
  }

  @override
  String get enterZeroIfNotRepaying => 'أدخل 0 إذا لم يكن هناك تسديد';

  @override
  String get repaymentExceedsBalance => 'المبلغ أكبر من رصيد السلفة على الموظف';

  @override
  String get paymentDate => 'تاريخ الدفع';

  @override
  String get saveAndPaySalary => 'حفظ وتسديد الراتب';

  @override
  String get netSalaryDue => 'الراتب الصافي المستحق للدفع';

  @override
  String get fieldRequiredEnterZero =>
      'هذا الحقل مطلوب، أدخل 0 إذا لم يكن هناك قيمة';

  @override
  String get payrollHistory => 'سجل الرواتب';

  @override
  String get advancesHistory => 'سجل السلف';

  @override
  String get noPayrolls => 'لا توجد رواتب مسجلة.';

  @override
  String get noAdvances => 'لا توجد سلف مسجلة';

  @override
  String payrollDetailsFor(Object month) {
    return 'تفاصيل راتب شهر $month';
  }

  @override
  String paidOn(String date) {
    return 'دُفع في: $date';
  }

  @override
  String payrollOfMonth(Object month, Object year) {
    return 'راتب شهر: $month $year';
  }

  @override
  String advanceAmountLabel(Object amount) {
    return 'مبلغ السلفة: $amount';
  }

  @override
  String advanceDateLabel(Object date) {
    return 'تاريخ السلفة: $date';
  }

  @override
  String get fullyPaid => 'مسددة بالكامل';

  @override
  String get employeesList => 'قائمة الموظفين';

  @override
  String get noEmployees =>
      'لا يوجد موظفون حاليًا. اضغط على زر + لإضافة أول موظف.';

  @override
  String jobTitleLabel(Object title) {
    return 'العنوان الوظيفي: $title';
  }

  @override
  String baseSalaryLabel(Object salary) {
    return 'الراتب الأساسي: $salary';
  }

  @override
  String advancesBalanceLabel(Object balance) {
    return 'رصيد السلف: $balance';
  }

  @override
  String get suppliersList => 'قائمة الموردين';

  @override
  String get noActiveSuppliers => 'لا يوجد موردون نشطون.';

  @override
  String get type => 'النوع';

  @override
  String get individual => 'فردي';

  @override
  String get partner => 'شريك';

  @override
  String get addSupplier => 'إضافة مورد';

  @override
  String get editSupplier => 'تعديل مورد';

  @override
  String get supplierName => 'اسم المورد';

  @override
  String get supplierNameRequired => 'اسم المورد مطلوب';

  @override
  String get supplierType => 'نوع المورد';

  @override
  String get partnership => 'شراكة';

  @override
  String get partners => 'شراكات';

  @override
  String get addPartner => 'إضافة شريك';

  @override
  String get atLeastOnePartnerRequired =>
      'يجب إضافة شريك واحد على الأقل لنوع الشراكة.';

  @override
  String partnerShareTotalExceeds100(Object total) {
    return 'خطأ: مجموع نسب الشركاء ($total%) يتجاوز 100%.';
  }

  @override
  String get supplierAddedSuccess => 'تم إضافة المورد بنجاح!';

  @override
  String get supplierUpdatedSuccess => 'تم تحديث المورد بنجاح!';

  @override
  String get addNewPartner => 'إضافة شريك جديد';

  @override
  String get partnerName => 'اسم الشريك';

  @override
  String get partnerNameRequired => 'اسم الشريك مطلوب';

  @override
  String get sharePercentage => 'نسبة الشراكة (%)';

  @override
  String get percentageMustBeBetween1And100 => 'النسبة يجب أن تكون بين 1 و 100';

  @override
  String get shareTotalExceeds100 =>
      'خطأ: مجموع نسب الشركاء لا يمكن أن يتجاوز 100%.';

  @override
  String percentageLabel(Object percentage) {
    return 'النسبة: $percentage%';
  }

  @override
  String typeLabel(Object type) {
    return 'النوع: $type';
  }

  @override
  String get cannotArchiveSupplierWithActiveProducts =>
      'لا يمكن أرشفة هذا المورد لأنه مرتبط بمنتجات نشطة.';

  @override
  String archiveSupplierConfirmation(Object name) {
    return 'هل أنت متأكد من أرشفة المورد \"$name\"؟ سيتم إخفاؤه من القوائم.';
  }

  @override
  String archiveSupplierLog(Object name) {
    return 'أرشفة المورد: $name';
  }

  @override
  String get addUser => 'إضافة مستخدم';

  @override
  String get editUser => 'تعديل مستخدم';

  @override
  String get passwordRequiredForNewUser => 'كلمة المرور مطلوبة للمستخدم الجديد';

  @override
  String get userAddedSuccess => 'تم إضافة المستخدم بنجاح!';

  @override
  String get userUpdatedSuccess => 'تم تحديث المستخدم بنجاح!';

  @override
  String get usernameAlreadyExists =>
      'اسم المستخدم هذا موجود بالفعل. الرجاء اختيار اسم آخر.';

  @override
  String get passwordHint => 'اتركه فارغًا لعدم التغيير';

  @override
  String get userPermissions => 'صلاحيات المستخدم';

  @override
  String get adminPermission => 'مدير كامل الصلاحيات (Admin)';

  @override
  String get adminPermissionSubtitle =>
      'يمنحه كل الصلاحيات ويتجاوز أي تحديد آخر.';

  @override
  String get viewSuppliers => 'عرض الموردين';

  @override
  String get editSuppliers => 'تعديل الموردين';

  @override
  String get viewProducts => 'عرض المنتجات';

  @override
  String get editProducts => 'تعديل المنتجات';

  @override
  String get viewCustomers => 'عرض الزبائن';

  @override
  String get editCustomers => 'تعديل الزبائن';

  @override
  String get viewReports => 'عرض التقارير';

  @override
  String get viewEmployeesReport => 'عرض تقرير الموظفين';

  @override
  String get viewSettings => 'عرض الإعدادات';

  @override
  String get manageEmployees => 'إدارة الموظفين';

  @override
  String get manageExpenses => 'إدارة المصاريف العامة';

  @override
  String get viewCashSales => 'عرض تقارير البيع النقدي';

  @override
  String get usersList => 'قائمة المستخدمين';

  @override
  String get noUsers => 'لا يوجد مستخدمين حالياً';

  @override
  String get you => '(أنت)';

  @override
  String get admin => 'مدير';

  @override
  String get customPermissionsUser => 'مستخدم بصلاحيات مخصصة';

  @override
  String get usernameLabel => 'اسم المستخدم';

  @override
  String get cannotEditOwnAccount =>
      'لا يمكنك تعديل حسابك الخاص من هنا. استخدم شاشة الإعدادات بدلاً من ذلك.';

  @override
  String get cannotDeleteOwnAccount => 'لا يمكنك حذف حسابك الخاص.';

  @override
  String get cannotDeleteLastUser => 'لا يمكن حذف آخر مستخدم في النظام.';

  @override
  String deleteUserConfirmation(String name) {
    return 'هل أنت متأكد من رغبتك في حذف المستخدم \"$name\"؟ هذا الإجراء لا يمكن التراجع عنه.';
  }

  @override
  String deleteUserLog(String name) {
    return 'حذف المستخدم: $name';
  }

  @override
  String get productsList => 'قائمة المنتجات';

  @override
  String get noActiveProducts => 'لا توجد منتجات نشطة في المخزن.';

  @override
  String get searchForProduct => ' ابحث عن منتج  ...';

  @override
  String get searchForProduct2 => ' ابحث عن منتج او مورد ...';

  @override
  String get noMatchingResults => 'لا توجد نتائج مطابقة للبحث.';

  @override
  String get supplier => 'المورد';

  @override
  String get quantity => 'الكمية';

  @override
  String get sellingPrice => 'سعر البيع';

  @override
  String get cannotArchiveSoldProduct =>
      'لا يمكن أرشفة هذا المنتج لأنه مرتبط بعمليات بيع سابقة.';

  @override
  String archiveProductConfirmation(Object name) {
    return 'هل أنت متأكد من أرشفة المنتج \"$name\"؟';
  }

  @override
  String supplierLabel(Object name) {
    return 'المورد: $name';
  }

  @override
  String quantityLabel(Object qty) {
    return 'الكمية: $qty';
  }

  @override
  String get undefined => 'غير محدد';

  @override
  String sellingPriceLabel(Object price) {
    return 'سعر البيع: $price';
  }

  @override
  String get addProduct => 'إضافة منتج';

  @override
  String get editProduct => 'تعديل منتج';

  @override
  String get pleaseSelectSupplier => 'الرجاء اختيار مورد';

  @override
  String get productAddedSuccess => 'تم إضافة المنتج بنجاح!';

  @override
  String get productUpdatedSuccess => 'تم تحديث المنتج بنجاح!';

  @override
  String get productName => 'اسم المنتج';

  @override
  String get productNameRequired => 'اسم المنتج مطلوب';

  @override
  String get productDetailsOptional => 'تفاصيل المنتج (اختياري)';

  @override
  String get costPrice => 'سعر التكلفة';

  @override
  String get fieldCannotBeNegative => 'لا يمكن أن يكون الرقم سالبًا';

  @override
  String get selectSupplier => 'اختر المورد';

  @override
  String get errorLoadingSuppliers => 'خطأ في تحميل الموردين.';

  @override
  String get noSuppliersAddOneFirst =>
      'لا يوجد موردون. الرجاء إضافة مورد أولاً.';

  @override
  String get barcode => 'الباركود';

  @override
  String get barcodeOptional => 'الباركود (اختياري)';

  @override
  String get scanBarcode => 'مسح الباركود';

  @override
  String get cameraPermissionRequired =>
      'إذن استخدام الكاميرا مطلوب لمسح الباركود.';

  @override
  String get openSettings => 'فتح الإعدادات';

  @override
  String get barcodeAlreadyExists => 'خطأ: هذا الباركود مسجل لمنتج آخر بالفعل.';

  @override
  String productUpdatedWithBarcodeLog(Object name) {
    return 'تحديث منتج مع باركود: $name';
  }

  @override
  String productAddedWithBarcodeLog(Object name) {
    return 'إضافة منتج جديد مع باركود: $name';
  }

  @override
  String get productNotFound => 'المنتج غير موجود أو غير نشط';

  @override
  String get scanBarcodeToSell => 'مسح باركود للبيع';

  @override
  String addWithProductName(String productName) {
    return 'إضافة \"$productName\"';
  }

  @override
  String get barcodeExistsError => 'هذا الباركود مسجل لمنتج آخر بالفعل.';

  @override
  String get reportsHub => 'مركز التقارير';

  @override
  String get profitReport => 'تقرير الأرباح';

  @override
  String get profitReportDesc => 'عرض صافي الربح من جميع المبيعات';

  @override
  String get supplierProfitReport => 'تقرير أرباح الموردين';

  @override
  String get supplierProfitReportDesc => 'عرض الأرباح مجمعة حسب كل مورد';

  @override
  String get employeesReport => 'تقرير الموظفين';

  @override
  String get employeesReportDesc => 'ملخص الرواتب والسلف وكشوفات حساب الموظفين';

  @override
  String get login => 'تسجيل الدخول';

  @override
  String get username => 'اسم المستخدم';

  @override
  String get password => 'كلمة المرور';

  @override
  String get loginTo => 'تسجيل الدخول إلى';

  @override
  String get accountingProgram => 'لمسة محاسب';

  @override
  String get invalidCredentials => 'اسم المستخدم أو كلمة المرور غير صحيحة.';

  @override
  String get ok => 'حسناً';

  @override
  String get error => 'خطأ';

  @override
  String get success => 'نجح';

  @override
  String get backupStarted => 'تم بدء مشاركة النسخة الاحتياطية.';

  @override
  String backupFailed(Object error) {
    return 'فشل النسخ الاحتياطي: $error';
  }

  @override
  String get restoreConfirmTitle => 'تأكيد الاستعادة';

  @override
  String get restoreConfirmContent =>
      'هل أنت متأكد؟ سيتم استبدال جميع بياناتك الحالية بالبيانات الموجودة في النسخة الاحتياطية. لا يمكن التراجع عن هذا الإجراء.';

  @override
  String get restore => 'استعادة';

  @override
  String get restoreSuccessTitle => 'تمت الاستعادة بنجاح';

  @override
  String get restoreSuccessContent =>
      'تم استعادة البيانات بنجاح. يرجى إغلاق التطبيق وإعادة تشغيله لتطبيق التغييرات.';

  @override
  String restoreFailed(Object error) {
    return 'فشل الاستعادة: $error';
  }

  @override
  String get createBackupTitle => 'إنشاء ومشاركة نسخة احتياطية';

  @override
  String get createBackupSubtitle =>
      'حفظ نسخة مشفرة من بياناتك ومشاركتها في مكان آمن.';

  @override
  String get restoreFromFileTitle => 'استعادة البيانات من ملف';

  @override
  String get restoreFromFileSubtitle =>
      'تحذير: هذه العملية ستحل محل جميع البيانات الحالية.';

  @override
  String get backupTip =>
      'تلميح: احتفظ بنسخ احتياطية بشكل دوري خارج جهازك (على Google Drive أو البريد الإلكتروني) لحماية بياناتك من الضياع أو التلف.';

  @override
  String get companyOrShopName => 'اسم الشركة أو المحل';

  @override
  String get companyDescOptional => 'وصف الشركة (اختياري)';

  @override
  String get companyDescHint => 'مثال: نشاط تجاري، عنوان مختصر...';

  @override
  String get companyInfoHint =>
      'سيظهر هذا الاسم والشعار في شاشة البداية والتقارير.';

  @override
  String get infoSavedSuccess => 'تم حفظ المعلومات بنجاح!';

  @override
  String errorPickingImage(String error) {
    return 'حدث خطأ أثناء اختيار الصورة: $error';
  }

  @override
  String get archivedCustomer => 'زبون مؤرشف';

  @override
  String get archivedSupplier => 'مورد مؤرشف';

  @override
  String archivedProduct(Object supplierName) {
    return 'منتج مؤرشف | المورد: $supplierName';
  }

  @override
  String get unknown => 'غير معروف';

  @override
  String itemRestoredSuccess(Object name) {
    return 'تم استعادة \"$name\" بنجاح!';
  }

  @override
  String get noArchivedItems => 'لا توجد عناصر مؤرشفة.';

  @override
  String get setupAdminAccount => 'إعداد حساب المدير';

  @override
  String get welcomeSetup =>
      'مرحبًا بك! هذا هو الإعداد لمرة واحدة فقط. هذا الحساب سيكون له كل الصلاحيات.';

  @override
  String get fullName => 'الاسم الكامل';

  @override
  String get fullNameRequired => 'الاسم الكامل مطلوب';

  @override
  String get usernameForLogin => 'اسم المستخدم (للدخول)';

  @override
  String get usernameRequired => 'اسم المستخدم مطلوب';

  @override
  String get chooseStrongPassword => 'اختر كلمة مرور قوية';

  @override
  String get passwordRequired => 'كلمة المرور مطلوبة';

  @override
  String get passwordTooShort => 'يجب أن تكون كلمة المرور 4 أحرف على الأقل';

  @override
  String get createAdminAndStart => 'إنشاء حساب المدير والبدء';

  @override
  String get adminCreatedSuccess =>
      'تم إنشاء حساب المدير بنجاح! يمكنك الآن تسجيل الدخول.';

  @override
  String get usernameExists =>
      'اسم المستخدم هذا موجود بالفعل. الرجاء اختيار اسم آخر.';

  @override
  String unexpectedError(Object error) {
    return 'حدث خطأ غير متوقع: $error';
  }

  @override
  String get pleaseEnterUsername => 'الرجاء إدخال اسم المستخدم';

  @override
  String get pleaseEnterPassword => 'الرجاء إدخال كلمة المرور';

  @override
  String get addCustomer => 'إضافة زبون';

  @override
  String get editCustomer => 'تعديل زبون';

  @override
  String get customerNameRequired => 'اسم الزبون مطلوب';

  @override
  String get imageSource => 'اختر مصدر الصورة';

  @override
  String get cannotArchiveCustomerWithDebt =>
      'لا يمكن أرشفة زبون لديه دين متبقي.';

  @override
  String get archiveConfirmTitle => 'تأكيد الأرشفة';

  @override
  String archiveConfirmContent(Object name) {
    return 'هل أنت متأكد من أرشفة الزبون \"$name\"؟';
  }

  @override
  String get chooseProducts => 'اختر المنتجات';

  @override
  String get reviewCart => 'مراجعة سلة المشتريات';

  @override
  String get noProductsInStock => 'لا توجد منتجات في المخزن.';

  @override
  String get available => 'المتوفر';

  @override
  String get price => 'السعر';

  @override
  String get add => 'إضافة';

  @override
  String get quantityExceedsStock =>
      'الكمية المطلوبة أكبر من المتوفر في المخزن!';

  @override
  String get cartIsEmpty => 'سلة المشتريات فارغة!';

  @override
  String get product => 'منتج';

  @override
  String get total => 'الإجمالي';

  @override
  String get finalTotal => 'الإجمالي النهائي';

  @override
  String get close => 'إغلاق';

  @override
  String itemsCount(String count) {
    return 'عدد الأصناف: $count';
  }

  @override
  String get totalSalariesPaid => 'إجمالي الرواتب المدفوعة';

  @override
  String get totalAdvancesBalance => 'إجمالي السلف المستحقة';

  @override
  String get activeEmployeesCount => 'عدد الموظفين النشطين';

  @override
  String get employeesStatement => 'كشف حساب الموظفين';

  @override
  String get noEmployeesToDisplay => 'لا يوجد موظفون لعرضهم.';

  @override
  String get salaryLabel => 'الراتب الاساسي';

  @override
  String get totalNetProfit => 'إجمالي صافي الربح';

  @override
  String get salesDetails => 'تفاصيل المبيعات';

  @override
  String get loadingDetails => 'جاري تحميل التفاصيل...';

  @override
  String get noSalesRecorded => 'لم يتم تسجيل أي عمليات بيع حتى الآن';

  @override
  String customerLabel(String name) {
    return 'الزبون: $name';
  }

  @override
  String dateLabel(String date) {
    return 'التاريخ: $date';
  }

  @override
  String profitLabel(String profit) {
    return 'الربح: $profit';
  }

  @override
  String saleLabel(String sale) {
    return 'المبيع: $sale';
  }

  @override
  String get generalProfitReport => 'تقرير الأرباح العام';

  @override
  String get generalProfitReportSubtitle =>
      'عرض ملخص الأرباح والمصاريف وصافي الربح';

  @override
  String get supplierProfitReportSubtitle =>
      'عرض الأرباح مجمعة حسب كل مورد وتوزيع حصص الشركاء';

  @override
  String get cashSalesHistory => 'سجل المبيعات النقدية';

  @override
  String get cashSalesHistorySubtitle => 'عرض وإدارة فواتير البيع المباشر';

  @override
  String get cashFlowReport => 'تقرير التدفق النقدي';

  @override
  String get cashFlowReportSubtitle => 'عرض المبيعات النقدية وتسديدات الزبائن';

  @override
  String get expensesLog => 'سجل المصاريف العامة';

  @override
  String get expensesLogSubtitle => 'عرض وتسجيل المصاريف التشغيلية';

  @override
  String get employeesAndSalariesReport => 'تقرير الموظفين والرواتب';

  @override
  String get employeesAndSalariesReportSubtitle =>
      'عرض ملخص الرواتب والسلف وكشوفات حساب الموظفين';

  @override
  String get noProfitsRecorded => 'لا توجد أرباح مسجلة لعرضها.';

  @override
  String partnersLabel(String names) {
    return 'الشركاء: $names';
  }

  @override
  String netProfitLabel(String amount) {
    return 'الربح الصافي: $amount';
  }

  @override
  String get selectDateRange => 'تحديد فترة زمنية';

  @override
  String get totalCashSales => 'إجمالي المبيعات النقدية';

  @override
  String get totalDebtPayments => 'إجمالي مقبوضات الديون';

  @override
  String get totalCashInflow => 'إجمالي الرصيد النقدي الوارد';

  @override
  String get showDetails => 'إظهار التفاصيل';

  @override
  String get hideDetails => 'إخفاء التفاصيل';

  @override
  String get noTransactions => 'لا توجد معاملات نقدية في هذه الفترة.';

  @override
  String cashSaleDescription(String id) {
    return 'بيع نقدي مباشر (فاتورة #$id)';
  }

  @override
  String debtPaymentDescription(String name) {
    return 'تسديد من الزبون: $name';
  }

  @override
  String recordWithdrawalFor(String name) {
    return 'سحب أرباح: $name';
  }

  @override
  String availableNetProfit(String amount) {
    return 'الربح الصافي المتاح للتوزيع: $amount';
  }

  @override
  String get withdrawnAmount => 'المبلغ المسحوب';

  @override
  String get amountExceedsProfit => 'المبلغ أكبر من الربح المتاح';

  @override
  String get withdrawalSuccess => 'تم تسجيل السحب بنجاح';

  @override
  String get totalProfitFromSupplier => 'إجمالي الأرباح من المورد';

  @override
  String get totalWithdrawals => 'إجمالي المسحوبات:';

  @override
  String get remainingNetProfit => 'صافي الربح المتبقي';

  @override
  String get partnersProfitDistribution => 'توزيع أرباح الشركاء';

  @override
  String partnerShare(String amount) {
    return 'حصته من الربح الصافي: $amount';
  }

  @override
  String get withdraw => 'سحب';

  @override
  String get recordGeneralWithdrawal => 'تسجيل سحب عام';

  @override
  String get withdrawalsHistory => 'سجل المسحوبات';

  @override
  String get noWithdrawals => 'لا توجد مسحوبات مسجلة.';

  @override
  String withdrawalAmountLabel(String amount) {
    return 'مبلغ: $amount';
  }

  @override
  String withdrawalForLabel(String name) {
    return 'لـ: $name';
  }

  @override
  String get refresh => 'تحديث';

  @override
  String get noDataToShow => 'لا توجد بيانات لعرضها.';

  @override
  String get showSalesDetails => 'عرض تفاصيل المبيعات';

  @override
  String get hideSalesDetails => 'إخفاء تفاصيل المبيعات';

  @override
  String get grossProfitFromSales => 'إجمالي الربح من المبيعات';

  @override
  String get totalGeneralExpenses => 'إجمالي المصاريف العامة';

  @override
  String get totalProfitWithdrawals => 'إجمالي مسحوبات الأرباح';

  @override
  String get netProfit => 'صافي الربح';

  @override
  String get totalProfitFromThisSupplier => 'إجمالي الربح من هذا المورد';

  @override
  String get noPartnersForThisSupplier => 'لا يوجد شركاء مسجلون لهذا المورد.';

  @override
  String get noSalesForThisSupplier => 'لا توجد مبيعات لهذا المورد.';

  @override
  String get searchByInvoiceNumber => 'ابحث برقم الفاتورة...';

  @override
  String get showInvoices => 'إظهار الفواتير';

  @override
  String get hideInvoices => 'إخفاء الفواتير';

  @override
  String get noCashInvoices => 'لا توجد فواتير بيع نقدي مسجلة.';

  @override
  String invoiceNo(String id) {
    return 'فاتورة رقم: $id';
  }

  @override
  String get modified => 'معدلة';

  @override
  String get voided => 'ملغاة';

  @override
  String get confirmVoidTitle => 'تأكيد إلغاء الفاتورة';

  @override
  String get confirmVoidContent =>
      'هل أنت متأكد من إلغاء هذه الفاتورة بالكامل؟ سيتم إرجاع جميع منتجاتها إلى المخزن.';

  @override
  String get confirmVoidAction => 'نعم، قم بالإلغاء';

  @override
  String get voidSuccess => 'تم إلغاء الفاتورة بنجاح.';

  @override
  String detailsForInvoice(String id) {
    return 'تفاصيل الفاتورة #$id';
  }

  @override
  String get directselling => 'بيع مباشر';

  @override
  String get directSalePoint => 'نقطة البيع المباشر';

  @override
  String get completeSale => 'إتمام البيع';

  @override
  String get saleSuccess => 'تم البيع بنجاح!';

  @override
  String get pdfInvoiceTitle => 'فاتورة بيع نقدي';

  @override
  String get pdfDate => 'التاريخ';

  @override
  String get pdfInvoiceNumber => 'فاتورة رقم';

  @override
  String get pdfHeaderProduct => 'المنتج';

  @override
  String get pdfHeaderQty => 'الكمية';

  @override
  String get pdfHeaderPrice => 'السعر';

  @override
  String get pdfHeaderTotal => 'الإجمالي';

  @override
  String get pdfFooterTotal => 'المبلغ الإجمالي';

  @override
  String get pdfFooterThanks => 'شكراً لتعاملكم معنا';

  @override
  String get manageExpenseCategories => 'إدارة فئات المصاريف';

  @override
  String get noCategories => 'لا توجد فئات';

  @override
  String get addCategory => 'إضافة فئة';

  @override
  String get editCategory => 'تعديل الفئة';

  @override
  String get categoryName => 'اسم الفئة';

  @override
  String get categoryNameRequired => 'اسم الفئة مطلوب';

  @override
  String get categoryExistsError => 'خطأ: اسم الفئة هذا موجود بالفعل.';

  @override
  String get confirmDeleteTitle => 'تأكيد الحذف';

  @override
  String confirmDeleteCategory(String name) {
    return 'هل أنت متأكد من حذف الفئة \"$name\"؟';
  }

  @override
  String get manageCategories => 'إدارة الفئات';

  @override
  String get noExpenses => 'لا توجد مصاريف';

  @override
  String get addExpense => 'إضافة مصروف';

  @override
  String get newExpense => 'مصروف جديد';

  @override
  String get expenseDescription => 'وصف المصروف';

  @override
  String get descriptionRequired => 'الوصف مطلوب';

  @override
  String get amount => 'المبلغ';

  @override
  String get category => 'الفئة';

  @override
  String get selectCategory => 'اختر الفئة';

  @override
  String get addCategoriesFirst => 'يرجى إضافة فئات المصاريف أولاً';

  @override
  String get expenseAddedSuccess => 'تم إضافة المصروف بنجاح';

  @override
  String get unclassified => 'غير مصنف';

  @override
  String get expensesarebeingloaded => 'جاري تحميل المصاريف';

  @override
  String get dashboard => 'لوحة القيادة';

  @override
  String get today => 'اليوم';

  @override
  String get thisMonth => 'هذا الشهر';

  @override
  String get sales => 'المبيعات';

  @override
  String get profit => 'الربح';

  @override
  String get topSelling => 'الأكثر مبيعاً';

  @override
  String get topCustomer => 'العميل المميز';

  @override
  String get generalStats => 'إحصائيات عامة';

  @override
  String get totalCustomers => 'العملاء';

  @override
  String get totalProducts => 'المنتجات';

  @override
  String get lowStock => 'مخزون منخفض';

  @override
  String get pendingPayments => 'مدفوعات معلقة';

  @override
  String get topBuyerThisMonth => 'العميل الأكثر شراءً هذا الشهر';

  @override
  String get noSalesData => 'لا توجد بيانات كافية لعرض المنتجات الأكثر مبيعاً';

  @override
  String get noCustomersData => 'لا توجد بيانات كافية لعرض العميل المميز';

  @override
  String get loadingStats => 'جاري تحميل الإحصائيات...';

  @override
  String get currency => 'د.ع';

  @override
  String get errorLoadingData => 'خطأ في تحميل البيانات';

  @override
  String get pleaseTryAgain => 'يرجى المحاولة مرة أخرى';

  @override
  String get noSales => 'لا توجد مبيعات';

  @override
  String get noCustomers => 'لا يوجد عملاء';

  @override
  String get enterCustomerName => 'أدخل اسم العميل';

  @override
  String get enterAddress => 'أدخل العنوان';

  @override
  String get enterPhone => 'أدخل رقم الهاتف';

  @override
  String get updateCustomer => 'تحديث بيانات العميل';

  @override
  String get loadingCustomers => 'جاري تحميل العملاء...';

  @override
  String get searchCustomers => 'بحث في العملاء';

  @override
  String get balanced => 'متوازن';

  @override
  String get archiveCustomer => 'أرشفة العميل';

  @override
  String get customerArchivedSuccess => 'تم أرشفة العميل بنجاح';

  @override
  String get basicInformation => 'المعلومات الأساسية';

  @override
  String get suppliersManagement => 'إدارة الموردين';

  @override
  String get productsManagement => 'إدارة المنتجات';

  @override
  String get customersManagement => 'إدارة العملاء';

  @override
  String get employeesManagement => 'إدارة الموظفين';

  @override
  String get reportsAndSales => 'التقارير والمبيعات';

  @override
  String get systemSettings => 'إعدادات النظام';

  @override
  String get changeImage => 'تغيير الصورة';

  @override
  String get primaryAdminAccount => 'حساب المدير الرئيسي';

  @override
  String get primaryAdminNote =>
      'يمكنك تعديل الاسم والصورة وكلمة المرور فقط. الصلاحيات محمية';

  @override
  String get updateProfile => 'تعديل الملف الشخصي';

  @override
  String get updateUser => 'تحديث المستخدم';

  @override
  String get editingYourProfile => 'تعديل ملفك الشخصي';

  @override
  String get selfEditNote =>
      'يمكنك تعديل اسمك، اسم المستخدم، كلمة المرور، والصورة الشخصية. الصلاحيات محمية';

  @override
  String get transactionDetails => 'تفاصيل المعاملات';

  @override
  String get noTransactionsInPeriod => 'لا توجد معاملات في هذه الفترة';

  @override
  String get cashIn => 'الوارد';

  @override
  String get appearance => 'المظهر';

  @override
  String get darkMode => 'الوضع الليلي';

  @override
  String get darkModeEnabled => 'مفعّل - العيون مرتاحة 😌';

  @override
  String get darkModeDisabled => 'معطّل - استمتع بالنور ☀️';

  @override
  String get appTitle => 'نظام المحاسبة الذكي';

  @override
  String get appVersion => 'الإصدار';

  @override
  String get loading => 'جاري التحميل...';

  @override
  String get appDescription =>
      'نظام محاسبي ذكي ومتكامل لإدارة أعمالك بسهولة واحترافية';

  @override
  String get companyInfo => 'معلومات الشركة';

  @override
  String get companyName => 'اسم الشركة';

  @override
  String get notSpecified => 'غير محدد';

  @override
  String get description => 'الوصف';

  @override
  String get developerInfo => 'معلومات المطور';

  @override
  String get developer => 'المطور';

  @override
  String get email => 'البريد الإلكتروني';

  @override
  String get rightsReserved => '© 2025 جميع الحقوق محفوظة';

  @override
  String get madeWith => 'صُنع بـ';

  @override
  String get madeInIraq => 'في العراق 🇮🇶';

  @override
  String get loadingData => 'جاري تحميل البيانات...';

  @override
  String get saveChanges => 'حفظ التغييرات';

  @override
  String get all => 'الكل';

  @override
  String get user => 'مستخدم';

  @override
  String get loadingUsers => 'جاري تحميل المستخدمين...';

  @override
  String get loadError => 'حدث خطأ أثناء تحميل البيانات';

  @override
  String get addNewUser => 'إضافة مستخدم جديد';

  @override
  String get noResults => 'لا توجد نتائج';

  @override
  String get noUsersMatch => 'لم يتم العثور على مستخدمين بهذه المعايير';

  @override
  String get searchUser => 'البحث عن مستخدم...';

  @override
  String get totalUsers => 'إجمالي المستخدمين';

  @override
  String get admins => 'المدراء';

  @override
  String get permission => 'صلاحية';

  @override
  String get viewEdit => 'عرض وتعديل';

  @override
  String get viewOnly => 'عرض فقط';

  @override
  String get none => 'لا يوجد';

  @override
  String get view => 'عرض';

  @override
  String get fullAccess => 'إدارة كاملة';

  @override
  String get employeeReports => 'تقارير الموظفين';

  @override
  String get expenses => 'المصروفات';

  @override
  String get cashSales => 'المبيعات النقدية';

  @override
  String get noPermissions => 'لا توجد صلاحيات ممنوحة';

  @override
  String get noUndo => 'هذا الإجراء لا يمكن التراجع عنه';

  @override
  String get deleteError => 'حدث خطأ أثناء الحذف';

  @override
  String get loadingSuppliers => 'جاري تحميل الموردين...';

  @override
  String get noSuppliers => 'لا يوجد موردين حالياً';

  @override
  String get addNewSupplier => 'إضافة مورد جديد';

  @override
  String get noSuppliersMatch => 'لم يتم العثور على موردين بهذا الاسم';

  @override
  String get searchSupplier => 'البحث عن مورد...';

  @override
  String get totalSuppliers => 'إجمالي الموردين';

  @override
  String get individuals => 'أفراد';

  @override
  String get canRestoreSupplier =>
      'يمكنك استعادة المورد لاحقاً من مركز الأرشيف';

  @override
  String get supplierArchived => 'تم أرشفة المورد';

  @override
  String get archiveError => 'خطأ في الأرشفة';

  @override
  String get basicInfo => 'المعلومات الأساسية';

  @override
  String get enterSupplierName => 'أدخل اسم المورد';

  @override
  String get additionalInfoOptional => 'معلومات إضافية (اختيارية)';

  @override
  String get enterPhoneNumber => 'أدخل رقم الهاتف';

  @override
  String get enterNotes => 'أدخل أي ملاحظات';

  @override
  String get updateSupplier => 'تحديث المورد';

  @override
  String get createSupplier => 'إضافة المورد';

  @override
  String get deletePartner => 'حذف شريك';

  @override
  String confirmDeletePartner(String name) {
    return 'هل أنت متأكد من حذف الشريك \"$name\"؟';
  }

  @override
  String get updateSupplierInfo => 'تحديث بيانات المورد';

  @override
  String get addNewSupplierAgain => 'إضافة مورد جديد';

  @override
  String get saveError => 'حدث خطأ أثناء الحفظ';

  @override
  String get editPartnerInfo => 'تعديل بيانات الشريك';

  @override
  String get partnerInfo => 'معلومات الشريك';

  @override
  String get enterPartnerName => 'أدخل اسم الشريك';

  @override
  String get enterPartnerShare => 'أدخل نسبة الشراكة (1-100)';

  @override
  String get invalidShare => 'النسبة المدخلة';

  @override
  String get additionalInfo => 'معلومات إضافية';

  @override
  String get updatePartner => 'تحديث الشريك';

  @override
  String get createPartner => 'اضافة الشريك';

  @override
  String get archiveProduct => 'أرشفة المنتج';

  @override
  String get productArchived => 'تم أرشفة';

  @override
  String errorArchiveRestor(Object error) {
    return 'حدث خطأ أثناء الاستعادة: $error';
  }

  @override
  String restoreConfirm(Object name) {
    return 'هل تريد استعادة \"$name\"؟';
  }

  @override
  String restoretheitem(Object name) {
    return 'استعادة العنصر \"$name\"?';
  }

  @override
  String get loadingProducts => 'جاري تحميل المنتجات...';

  @override
  String get startByAddingProduct => 'ابدأ بإضافة أول منتج في المخزون';

  @override
  String get addNewProduct => 'إضافة منتج جديد';

  @override
  String get addtonewstores => 'قم بإضافة منتجات للمخزن أولاً';

  @override
  String get totalQuantity => 'إجمالي الكمية';

  @override
  String get low => 'منخفضة';

  @override
  String get value => 'القيمة';

  @override
  String get tryAnotherSearch => 'جرب البحث بكلمة أخرى';

  @override
  String get purchase => 'الشراء';

  @override
  String get sell => 'البيع';

  @override
  String get pointCameraToBarcode => 'وجّه الكاميرا نحو الباركود للمسح';

  @override
  String get supplierInfo => 'معلومات المورد';

  @override
  String get productInfo => 'معلومات المنتج';

  @override
  String get enterProductName => 'أدخل اسم المنتج';

  @override
  String get scanOrEnterBarcode => 'امسح أو أدخل الباركود';

  @override
  String get enterProductDetails => 'أدخل تفاصيل المنتج';

  @override
  String get quantityAndPrices => 'الكمية والأسعار';

  @override
  String get enterQuantity => 'أدخل الكمية';

  @override
  String get purchasePrice => 'سعر الشراء';

  @override
  String get salePrice => 'سعر البيع';

  @override
  String get pricesSummary => 'ملخص الأسعار';

  @override
  String get loadingEmployees => 'جاري تحميل الموظفين...';

  @override
  String get startByAddingEmployee => 'ابدأ بإضافة أول موظف في فريقك';

  @override
  String get addNewEmployee => 'إضافة موظف جديد';

  @override
  String get searchNewEmployee => 'ابحث عن موظف';

  @override
  String get searchNewEmployee2 => 'ابحث عن موظف او تخصص الموظف';

  @override
  String get totalSalaries => 'إجمالي الرواتب';

  @override
  String get totalAdvances => 'إجمالي السلف';

  @override
  String get salary => 'الراتب';

  @override
  String get advance => 'السلف';

  @override
  String get months => 'الأشهر';

  @override
  String get january => 'يناير';

  @override
  String get february => 'فبراير';

  @override
  String get march => 'مارس';

  @override
  String get april => 'أبريل';

  @override
  String get may => 'مايو';

  @override
  String get june => 'يونيو';

  @override
  String get july => 'يوليو';

  @override
  String get august => 'أغسطس';

  @override
  String get september => 'سبتمبر';

  @override
  String get october => 'أكتوبر';

  @override
  String get november => 'نوفمبر';

  @override
  String get december => 'ديسمبر';

  @override
  String get noSalaryPaidYet => 'لم يتم صرف أي راتب بعد';

  @override
  String get addSalary => 'إضافة راتب';

  @override
  String get paySalary => 'صرف راتب';

  @override
  String get addNewSalary => 'إضافة راتب جديد';

  @override
  String get paidAt => 'دُفع في:';

  @override
  String get net => 'صافي';

  @override
  String get addAdvance => 'إضافة سلفة';

  @override
  String get addNewAdvance => 'إضافة سلفة جديدة';

  @override
  String get salaryDetails => 'تفاصيل راتب';

  @override
  String get recordSalaryFor => 'تسجيل راتب شهر';

  @override
  String get forEmployee => 'للموظف';

  @override
  String get selectPaymentDate => 'اختر تاريخ الدفع';

  @override
  String get confirm => 'تأكيد';

  @override
  String get financialPeriod => 'الفترة المالية';

  @override
  String get salaryComponents => 'مكونات الراتب';

  @override
  String get basicSalary => 'الراتب الأساسي';

  @override
  String get deductionAndPenalties => 'الخصومات والغرامات';

  @override
  String get deductAdvance => 'خصم السلف من الراتب';

  @override
  String get selectDate => 'اختر التاريخ';

  @override
  String get anyAdditionalNotes => 'أي ملاحظات إضافية';

  @override
  String get detailedSummary => 'الملخص التفصيلي';

  @override
  String get updateEmployeeData => 'تحديث بيانات الموظف:';

  @override
  String get addNewEmployeeData => 'إضافة موظف جديد:';

  @override
  String get selectHiringDate => 'اختر تاريخ التعيين';

  @override
  String get personalInfo => 'المعلومات الشخصية';

  @override
  String get enterFullName => 'أدخل الاسم الكامل';

  @override
  String get jobInfo => 'معلومات الوظيفة';

  @override
  String get enterJobTitle => 'أدخل المسمى الوظيفي';

  @override
  String get financialInfo => 'المعلومات المالية';

  @override
  String get enterBasicSalary => 'أدخل الراتب الأساسي';

  @override
  String get recordEmployeeAdvance => 'تسجيل سلفة للموظف:';

  @override
  String get selectAdvanceDate => 'اختر تاريخ السلفة';

  @override
  String get advanceData => 'بيانات السلفة';

  @override
  String get enterAdvanceAmount => 'أدخل مبلغ السلفة';

  @override
  String get enterAdvanceNotes => 'أدخل أي ملاحظات إضافية';

  @override
  String get currentBalance => 'الرصيد الحالي';

  @override
  String get financialSummary => 'الملخص المالي';

  @override
  String get expectedBalance => 'الرصيد المتوقع';

  @override
  String get autoDeductAdvance =>
      'سيتم خصم قيمة السلفة تلقائياً من الرواتب القادمة حتى تسديدها بالكامل';

  @override
  String deleteUserSuccess(String userName) {
    return 'تم حذف المستخدم \"$userName\" بنجاح';
  }

  @override
  String deleteUserError(String error) {
    return 'حدث خطأ أثناء الحذف: $error';
  }

  @override
  String get permissions => 'صلاحيات';

  @override
  String deleteSupplierSuccess(String userName, Object supplierName) {
    return 'تم حذف المورد \"$supplierName\" بنجاح';
  }

  @override
  String deleteSupplierError(String error) {
    return 'حدث خطأ أثناء الحذف: $error';
  }

  @override
  String partnersCount(int count) {
    return '$count شريك';
  }

  @override
  String partnerShareWarning(String percentage) {
    return 'مجموع النسب المئوية للشركاء هو $percentage% فقط.\nهل تريد المتابعة؟';
  }

  @override
  String activityUpdateSupplier(String name) {
    return 'تحديث بيانات المورد: $name';
  }

  @override
  String activityAddSupplier(String name) {
    return 'إضافة مورد جديد: $name';
  }

  @override
  String errorSaving(String error) {
    return 'حدث خطأ أثناء الحفظ: $error';
  }

  @override
  String get warning => 'تحذير';

  @override
  String get continueButton => 'متابعة';

  @override
  String get partnerships => 'شراكات';

  @override
  String supplierArchivedSuccess(String name) {
    return 'تم أرشفة المورد \"$name\" بنجاح';
  }

  @override
  String productArchivedSuccess(String name) {
    return 'تم أرشفة \"$name\" بنجاح';
  }

  @override
  String productArchivedError(String error) {
    return 'خطأ في الأرشفة: $error';
  }

  @override
  String archiveProductAction(String name) {
    return 'أرشفة المنتج: $name';
  }

  @override
  String updateEmployeeAction(String name) {
    return 'تحديث بيانات الموظف: $name';
  }

  @override
  String addEmployeeAction(String name) {
    return 'إضافة موظف جديد: $name';
  }

  @override
  String get deductionsSection => 'الخصومات';

  @override
  String get additionalInformation => 'معلومات إضافية';

  @override
  String get baseSalaryHint => 'الراتب الأساسي';

  @override
  String get bonusesAndIncentivesHint => 'المكافآت والحوافز';

  @override
  String get deductionsAndPenaltiesHint => 'الخصومات والغرامات';

  @override
  String get advanceDeductionFromSalaryHint => 'خصم السلف من الراتب';

  @override
  String get anyAdditionalNotesHint => 'أي ملاحظات إضافية';

  @override
  String payrollRegisteredForEmployee(String month, String employeeName) {
    return 'تسجيل راتب شهر $month للموظف: $employeeName';
  }

  @override
  String get advancesLabel => 'السلف';

  @override
  String get loadingMessage => 'جاري التحميل...';

  @override
  String get noPayrollsMessage => 'لم يتم صرف أي راتب بعد';

  @override
  String get addPayrollAction => 'إضافة راتب';

  @override
  String get paymentAction => 'صرف راتب';

  @override
  String get addNewPayrollTooltip => 'إضافة راتب جديد';

  @override
  String get noAdvancesMessage => 'لا توجد سلف مسجلة';

  @override
  String get addAdvanceAction => 'إضافة سلفة';

  @override
  String get addAdvanceButton => 'إضافة سلفة';

  @override
  String get addNewAdvanceTooltip => 'إضافة سلفة جديدة';

  @override
  String get netLabel => 'صافي';

  @override
  String payrollDetailsTitle(String month, String year) {
    return 'تفاصيل راتب $month $year';
  }

  @override
  String advanceRegisteredForEmployee(String employeeName, String amount) {
    return 'تسجيل سلفة للموظف: $employeeName بقيمة: $amount';
  }

  @override
  String archivedSuccess(String name) {
    return 'تم أرشفة \"$name\" بنجاح';
  }

  @override
  String newSaleActivityLog(String customerName, String amount) {
    return 'تسجيل عملية بيع جديدة للزبون: $customerName بقيمة: $amount';
  }

  @override
  String paymentActivityLog(String customerName, String amount) {
    return 'تسجيل دفعة للزبون: $customerName بقيمة: $amount';
  }

  @override
  String returnActivityLog(String invoiceId, String productName) {
    return 'إرجاع منتج من فاتورة نقدية #$invoiceId: $productName';
  }

  @override
  String saleRecordError(String error) {
    return 'خطأ في تسجيل البيع: $error';
  }

  @override
  String paymentRecordError(String error) {
    return 'خطأ في تسجيل الدفعة: $error';
  }

  @override
  String get loadingPurchases => 'جاري تحميل المشتريات...';

  @override
  String get loadingPayments => 'جاري تحميل الدفعات...';

  @override
  String get newSale => 'بيع جديد';

  @override
  String get generalProfitReport_desc => 'عرض إجمالي الأرباح وتفاصيل المبيعات';

  @override
  String get supplierProfitReport_desc => 'توزيع الأرباح حسب المورد أو الشريك';

  @override
  String get cashSalesRecord => 'سجل المبيعات النقدية';

  @override
  String get cashSalesRecord_desc => 'الفواتير والمبيعات النقدية المباشرة';

  @override
  String get cashFlowReport_desc => 'المقبوضات النقدية والتسديدات';

  @override
  String get expenseRecord => 'سجل المصاريف';

  @override
  String get expenseRecord_desc => 'جميع المصاريف والنفقات المسجلة';

  @override
  String get employeePayrollReport => 'تقرير الموظفين والرواتب';

  @override
  String get employeePayrollReport_desc => 'كشف الموظفين والرواتب والسلف';

  @override
  String get reportingCenter => 'مركز التقارير';

  @override
  String get noreportsavailable => 'لا يوجد تقارير متاحة';

  @override
  String get donotpermissionreports => 'ليس لديك صلاحية للوصول إلى أي تقرير';

  @override
  String get calculatingProfits => 'جاري حساب الأرباح...';

  @override
  String get noData => 'لا توجد بيانات';

  @override
  String get noOperationsRecorded => 'لم يتم تسجيل أي عمليات حتى الآن';

  @override
  String get totalProfitsFromSales => 'إجمالي الأرباح من المبيعات';

  @override
  String get beforeExpenses => 'قبل المصاريف';

  @override
  String get billsAndExpenses => 'فواتير ونفقات';

  @override
  String get forSuppliersAndPartners => 'للموردين والشركاء';

  @override
  String salesDetailsCount(String count) {
    return 'تفاصيل المبيعات ($count)';
  }

  @override
  String get notRegistered => 'غير مسجل';

  @override
  String fromAmount(String amount) {
    return 'من $amount';
  }

  @override
  String get returnWarningMessage =>
      'سيتم إرجاع المنتج للمخزن وتحديث حالة الفاتورة';

  @override
  String get loadingInvoiceDetails => 'جاري تحميل تفاصيل الفاتورة...';

  @override
  String get noItemsInInvoice => 'لا توجد بنود في هذه الفاتورة';

  @override
  String get invoiceEmptyOrCancelled => 'الفاتورة فارغة أو تم إلغاؤها';

  @override
  String get invoiceStatusModified => 'معدلة';

  @override
  String get invoiceTotalAmount => 'إجمالي الفاتورة:';

  @override
  String get returnedAmount => 'المبلغ المرجع:';

  @override
  String get netAmount => 'الصافي:';

  @override
  String itemsCount2(int count) {
    return 'عدد البنود: $count';
  }

  @override
  String get returnedStatus => 'مُرجع';

  @override
  String get longPressToReturn => 'اضغط مطولاً للإرجاع';

  @override
  String get noProfitsRecordedForSuppliers =>
      'لا توجد أرباح مسجلة للموردين بعد';

  @override
  String get totalProfits => 'إجمالي الأرباح';

  @override
  String get withdrawals => 'المسحوبات';

  @override
  String get trysearchinvoice => 'جرب البحث برقم فاتورة آخر';

  @override
  String get nocashrecordedyet => 'لم يتم تسجيل أي فاتورة بيع نقدي حتى الآن';

  @override
  String get invoicesloaded => 'جاري تحميل الفواتير...';

  @override
  String get beforeWithdrawals => 'قبل المسحوبات';

  @override
  String get withdrawnAmounts => 'المبالغ المسحوبة';

  @override
  String get recordWithdrawal => 'تسجيل سحب';

  @override
  String get noWithdrawalsRecorded => 'لم يتم تسجيل أي عملية سحب حتى الآن';

  @override
  String get loadingExpenses => 'جاري تحميل المصاريف...';

  @override
  String get noExpensesMessage => 'لم يتم تسجيل أي مصروف حتى الآن';

  @override
  String get expenseDescriptionHint => 'مثال: فاتورة كهرباء';

  @override
  String get addNote => 'أضف ملاحظة...';

  @override
  String get date => 'التاريخ';

  @override
  String get notes => 'الملاحظات';

  @override
  String get expenseDetails => 'تفاصيل المصروف';

  @override
  String get errorOccurred2 => 'حدث خطأ';

  @override
  String get manageCategoriesTitle => 'إدارة فئات المصاريف';

  @override
  String get loadingCategories => 'جاري تحميل الفئات...';

  @override
  String get noCategoriesMessage => 'لم يتم إضافة أي فئة للمصاريف حتى الآن';

  @override
  String get newCategory => 'فئة جديدة';

  @override
  String get addNewCategory => 'إضافة فئة جديدة';

  @override
  String get categoryNameHint => 'مثال: فواتير، إيجار، صيانة';

  @override
  String get update => 'تحديث';

  @override
  String get categoryUpdatedSuccess => 'تم تعديل الفئة بنجاح';

  @override
  String get categoryAddedSuccess => 'تم إضافة الفئة بنجاح';

  @override
  String get categoryAlreadyExists => 'هذه الفئة موجودة بالفعل';

  @override
  String get confirmDelete => 'تأكيد الحذف';

  @override
  String get deleteConfirmationQuestion => 'هل أنت متأكد من حذف الفئة؟';

  @override
  String get deleteWarning => 'سيتم حذف الفئة نهائياً ولن يمكن استرجاعها';

  @override
  String get categoryDeletedSuccess => 'تم حذف الفئة بنجاح';

  @override
  String get employees_report_title => 'تقرير الموظفين';

  @override
  String get employees_list_title => 'كشف الموظفين';

  @override
  String get stat_total_salaries => 'إجمالي الرواتب';

  @override
  String get stat_salaries_paid => 'المدفوعة';

  @override
  String get stat_advances_balance => 'رصيد السلف';

  @override
  String get stat_advances_due => 'المستحقة';

  @override
  String get stat_active_employees => 'الموظفين النشطين';

  @override
  String get stat_employee_unit => 'موظف';

  @override
  String get loading_data => 'جاري تحميل البيانات...';

  @override
  String get error_occurred => 'حدث خطأ';

  @override
  String get no_employees_title => 'لا يوجد موظفين';

  @override
  String get no_employees_message => 'لم يتم تسجيل أي موظف نشط حتى الآن';

  @override
  String get employee_salary_label => 'الراتب';

  @override
  String get employee_advances_label => 'السلف';

  @override
  String get directSales => 'مبيعات مباشرة';

  @override
  String get invoices => 'الفواتير';

  @override
  String get customersAndSuppliers => 'العملاء والموردين';

  @override
  String get inventory => 'المخزون';

  @override
  String get employeeManagement => 'إدارة الموظفين';

  @override
  String get reportsCenter => 'مركز التقارير';

  @override
  String get system => 'النظام';

  @override
  String get systemAdmin => 'مدير النظام';

  @override
  String get logout => 'تسجيل الخروج';

  @override
  String get logoutConfirmation => 'هل تريد تسجيل الخروج؟';

  @override
  String get errorOpeningReports => 'خطأ في فتح صفحة التقارير';

  @override
  String get menu => 'القائمة';

  @override
  String get daytimemode => 'الوضع النهاري';

  @override
  String get nighttimemode => 'الوضع الليلي';

  @override
  String get selectCurrency => 'اختر العملة';

  @override
  String get selectedcurrency => 'العملة المختارة';

  @override
  String get currencyChanged => 'تم تغيير العملة بنجاح';

  @override
  String get security => 'الأمان';

  @override
  String get biometricLogin => 'تسجيل الدخول بالبصمة';

  @override
  String get biometricEnabled => 'البصمة مُفعّلة';

  @override
  String get biometricDisabled => 'البصمة غير مُفعّلة';

  @override
  String get disableBiometric => 'إلغاء البصمة';

  @override
  String get disableBiometricConfirmation =>
      'هل أنت متأكد من إلغاء تفعيل البصمة؟';

  @override
  String get disable => 'إلغاء';

  @override
  String get biometricDisabledSuccess => 'تم إلغاء تفعيل البصمة بنجاح';

  @override
  String get or => 'أو';

  @override
  String get loginWithBiometric => 'تسجيل الدخول بالبصمة';

  @override
  String get noUsersFound => 'لم يتم العثور على مستخدمين';

  @override
  String get tryOnRealDevice => 'يمكنك تجربة الميزة على جهاز حقيقي';

  @override
  String get quickStats => 'إحصائيات سريعة';

  @override
  String get totalSales => 'إجمالي المبيعات';

  @override
  String get totalProfit => 'إجمالي الأرباح';

  @override
  String get activeCustomers => 'العملاء النشطون';

  @override
  String get availableProducts => 'المنتجات المتاحة';

  @override
  String get smartAlerts => 'تنبيهات ذكية';

  @override
  String get lowStockAlert => 'منتجات شارفت على النفاد';

  @override
  String lowStockAlertSubtitle(int count) {
    return '$count منتج بحاجة لإعادة طلب';
  }

  @override
  String get overdueCustomersAlert => 'عملاء متأخرون عن السداد';

  @override
  String overdueCustomersAlertSubtitle(int count) {
    return '$count عميل لديهم ديون متأخرة';
  }

  @override
  String get financialStats => 'الإحصائيات المالية';

  @override
  String get totalDebts => 'إجمالي الديون';

  @override
  String get totalPayments => 'إجمالي المدفوعات';

  @override
  String get collectionRate => 'نسبة التحصيل';

  @override
  String get topBuyers => 'أكثر العملاء شراءً';

  @override
  String get topDebtors => 'العملاء المدينون';

  @override
  String daysSinceLastTransaction(int days) {
    return '$days يوم منذ آخر معاملة';
  }

  @override
  String get topSellingProducts => 'أكثر المنتجات مبيعاً';

  @override
  String get inStock => 'متوفر';

  @override
  String get monthlySalesChart => 'المبيعات الشهرية';

  @override
  String get profitBySupplier => 'الأرباح حسب المورد';

  @override
  String get lowStockProducts => 'منتجات منخفضة المخزون';

  @override
  String get overdueCustomers => 'عملاء متأخرون';

  @override
  String get productOutOfStock => 'المنتج غير متوفر في المخزون';

  @override
  String get selectSaleDate => 'اختر تاريخ البيع';

  @override
  String get saleDate => 'تاريخ البيع';

  @override
  String get filterByDays => 'تصفية حسب الأيام';

  @override
  String get customDays => 'فترة مخصصة';

  @override
  String get customize => 'تخصيص';

  @override
  String daysCount(String count) {
    return '$count يوم';
  }

  @override
  String get selectCustomDays => 'اختر عدد الأيام';

  @override
  String get numberOfDays => 'عدد الأيام';

  @override
  String get apply => 'تطبيق';

  @override
  String get statisticsinformation => 'الاحصائيات والمعلومات';

  @override
  String get statistics => 'الاحصائيات';

  @override
  String get erroefirger => 'الجهاز لا يدعم البصمة';

  @override
  String get thedatabasefile => 'ملف قاعدة البيانات غير موجود';

  @override
  String get accountingbackupfile => 'ملف النسخة الاحتياطية لتطبيق المحاسبة 📦';

  @override
  String get sharecancelled => 'تم إلغاء المشاركة';

  @override
  String get contactInformation => 'معلومات الاتصال';

  @override
  String get legalInformation => 'المعلومات القانونية';

  @override
  String get companyLogo => 'شعار الشركة';

  @override
  String get phoneNumber => 'رقم الهاتف';

  @override
  String get address => 'العنوان';

  @override
  String get commercialRegistrationNumber => 'رقم السجل التجاري';

  @override
  String get backupSuccessTitle => 'تم بنجاح! ✓';

  @override
  String get backupSuccessContent =>
      'تم حفظ النسخة الاحتياطية في مجلد التنزيلات';

  @override
  String get backupFileLocation => 'موقع الملف:';

  @override
  String get pathCopied => 'تم نسخ المسار';

  @override
  String get copyPath => 'نسخ المسار';

  @override
  String get share => 'مشاركة';

  @override
  String get shareLastBackup => 'مشاركة آخر نسخة احتياطية';

  @override
  String get shareFailed => 'فشلت عملية المشاركة';

  @override
  String get filterOverdueCustomers => 'تصفية العملاء المتأخرين';

  @override
  String get selectPeriod => 'اختر الفترة الزمنية';

  @override
  String get noOverdueCustomers => 'لا يوجد عملاء متأخرون! 🎉';

  @override
  String noOverdueCustomersMessage(int days) {
    return 'جميع العملاء نشطون خلال الـ $days يوم الماضية';
  }

  @override
  String get debt => 'دين';

  @override
  String get appLocked => 'التطبيق مقفول';

  @override
  String get appLockedDescription => 'تم قفل التطبيق للحماية';

  @override
  String get lastActive => 'آخر نشاط';

  @override
  String get fewMinutesAgo => 'منذ دقائق';

  @override
  String get unlock => 'فتح القفل';

  @override
  String get unlockWithBiometric => 'فتح بالبصمة';

  @override
  String get enterPassword => 'أدخل كلمة المرور';

  @override
  String get wrongPassword => 'كلمة المرور خاطئة';

  @override
  String get attemptsRemaining => 'المحاولات المتبقية';

  @override
  String get tooManyAttempts =>
      'محاولات كثيرة فاشلة. الرجاء المحاولة بعد 30 ثانية';

  @override
  String get lockedOut => 'تم القفل مؤقتاً. انتظر';

  @override
  String get seconds => 'ثانية';

  @override
  String get appLockSettings => 'إعدادات القفل التلقائي';

  @override
  String get appLockSettingsDescription => 'تفعيل القفل عند الخروج من التطبيق';

  @override
  String get enableAppLock => 'تفعيل القفل التلقائي';

  @override
  String get appLockEnabled => 'القفل التلقائي مُفعّل';

  @override
  String get appLockDisabled => 'القفل التلقائي مُعطّل';

  @override
  String get appLockEnabledSuccess => 'تم تفعيل القفل التلقائي';

  @override
  String get appLockDisabledSuccess => 'تم إيقاف القفل التلقائي';

  @override
  String get lockDuration => 'المدة قبل القفل';

  @override
  String get immediately => 'فوراً';

  @override
  String get oneMinute => '1 دقيقة';

  @override
  String get twoMinutes => '2 دقيقة';

  @override
  String get fiveMinutes => '5 دقائق';

  @override
  String get tenMinutes => '10 دقائق';

  @override
  String get lockDurationChanged => 'تم تغيير المدة إلى';

  @override
  String get appLockInfo =>
      'سيتم قفل التطبيق تلقائياً بعد الخروج منه للمدة المحددة. يمكنك فتح القفل باستخدام كلمة المرور أو البصمة.';

  @override
  String get appBlocked => 'التطبيق محظور';

  @override
  String get appBlockedDescription => 'تم حظر التطبيق لحماية بياناتك';

  @override
  String get timeManipulationDetected => 'تم رصد تلاعب بالتاريخ والوقت';

  @override
  String get timeManipulationWarning => 'تحذير: تم رصد محاولة تلاعب';

  @override
  String get afterThatAppWillBeBlocked => 'بعد ذلك سيتم حظر التطبيق نهائياً';

  @override
  String get internetRequired => 'يتطلب اتصال بالإنترنت';

  @override
  String get noInternetFor7Days => 'لم يتم الاتصال بالإنترنت منذ 7 أيام';

  @override
  String get mustConnectToInternet =>
      'يجب الاتصال بالإنترنت لمتابعة استخدام التطبيق';

  @override
  String get tryConnect => 'حاول الاتصال';

  @override
  String get connectionFailed => 'فشل الاتصال بالإنترنت. حاول مرة أخرى';

  @override
  String get technicalSupport => 'الدعم الفني';

  @override
  String get contactSupport => 'اتصل بالدعم';

  @override
  String get contactViaWhatsApp => 'تواصل عبر واتساب';

  @override
  String get contactViaEmail => 'تواصل عبر البريد';

  @override
  String get contactViaPhone => 'اتصال هاتفي';

  @override
  String get contactViaFacebook => 'تواصل عبر فيسبوك';

  @override
  String get possibleReasons => 'الأسباب المحتملة';

  @override
  String get deviceTimeChanged => 'تم تغيير تاريخ ووقت الجهاز';

  @override
  String get repeatedManipulation => 'محاولات متكررة للتلاعب';

  @override
  String get fileManipulation => 'محاولة التلاعب بملفات التطبيق';

  @override
  String get solution => 'الحل';

  @override
  String get contactSupportForNewKey =>
      'الرجاء التواصل مع الدعم الفني للحصول على كود تفعيل جديد';

  @override
  String get deviceIdCopied => 'تم نسخ بصمة الجهاز إلى الحافظة';

  @override
  String get copyDeviceId => 'نسخ بصمة الجهاز';

  @override
  String get sendThisToSupport => 'قم بنسخ هذه البصمة وإرسالها للدعم الفني';

  @override
  String get syncingWithServer => 'جاري المزامنة مع الخادم...';

  @override
  String get syncSuccess => 'تمت المزامنة بنجاح';

  @override
  String get syncFailed => 'فشلت المزامنة';

  @override
  String get workingOffline => 'العمل بدون إنترنت';

  @override
  String get daysRemainingOffline => 'الأيام المتبقية قبل الحاجة للاتصال';

  @override
  String get connectTodayRequired => 'يجب الاتصال بالإنترنت اليوم';

  @override
  String get toEnsureContinuedUse => 'لضمان استمرار عمل التطبيق';

  @override
  String get createBackupPasswordTitle => 'احمِ نسختك الاحتياطية';

  @override
  String get createBackupPasswordSubtitle =>
      'اختر كلمة مرور لحماية نسختك الاحتياطية. ستحتاجها للاستعادة على أي جهاز.';

  @override
  String get restoreBackupPasswordTitle => 'فك تشفير النسخة الاحتياطية';

  @override
  String get restoreBackupPasswordSubtitle =>
      'أدخل كلمة المرور التي استخدمتها عند إنشاء هذه النسخة الاحتياطية.';

  @override
  String get confirmPassword => 'تأكيد كلمة المرور';

  @override
  String get reEnterPassword => 'أعد إدخال كلمة المرور';

  @override
  String get passwordCannotBeEmpty => 'كلمة المرور لا يمكن أن تكون فارغة';

  @override
  String get passwordsDoNotMatch => 'كلمات المرور غير متطابقة';

  @override
  String get passwordTip =>
      '⚠️ تذكر كلمة المرور جيداً! بدونها لن تتمكن من استعادة نسختك الاحتياطية.';

  @override
  String get userMergeTitle => 'دمج المستخدمين';

  @override
  String userMergeMessage(int count) {
    return 'لديك $count مستخدم حالياً.\n\nماذا تريد أن تفعل؟';
  }

  @override
  String get mergeUsers => 'دمج المستخدمين';

  @override
  String get mergeUsersDescription =>
      'إضافة المستخدمين من النسخة الاحتياطية مع الاحتفاظ بالمستخدمين الحاليين';

  @override
  String get replaceAllUsers => 'استبدال الكل';

  @override
  String get replaceAllUsersDescription =>
      'حذف جميع المستخدمين الحاليين واستبدالهم بالمستخدمين من النسخة الاحتياطية';

  @override
  String get keepCurrentUsers => 'الاحتفاظ بالمستخدمين الحاليين';

  @override
  String get keepCurrentUsersDescription =>
      'استعادة البيانات فقط بدون تغيير المستخدمين';

  @override
  String get selectBackupFile => 'اختر ملف النسخة الاحتياطية';

  @override
  String get enterBackupPassword => 'أدخل كلمة مرور النسخة الاحتياطية';

  @override
  String get verifyingPassword => 'جاري التحقق من كلمة المرور...';

  @override
  String get incorrectPassword => 'كلمة المرور غير صحيحة';

  @override
  String get usersMergedSuccessfully => 'تم دمج المستخدمين بنجاح';

  @override
  String get usersReplacedSuccessfully => 'تم استبدال المستخدمين بنجاح';

  @override
  String get noUsersInBackup => 'لا توجد بيانات مستخدمين في النسخة الاحتياطية';

  @override
  String duplicateUsernamesSkipped(int count) {
    return 'تم تخطي $count مستخدم لأن اسم المستخدم موجود مسبقاً';
  }

  @override
  String get permissionsWillBePreserved =>
      'ملاحظة: سيتم الاحتفاظ بصلاحيات المستخدمين الحاليين';

  @override
  String get allDataWillBeReplaced => 'تحذير: سيتم حذف جميع البيانات الحالية';

  @override
  String get productImage => 'صورة المنتج';

  @override
  String get addImage => 'إضافة صورة';

  @override
  String get selectImageSource => 'اختر مصدر الصورة';

  @override
  String get productImageNote =>
      'الصورة اختيارية. يمكنك إضافتها الآن أو لاحقاً.';

  @override
  String get comprehensiveCashFlowReport => 'تقرير التدفقات النقدية الشامل';

  @override
  String get timePeriod => 'الفترة الزمنية';

  @override
  String get from => 'من';

  @override
  String get to => 'إلى';

  @override
  String get allTime => 'كل الفترة';

  @override
  String get now => 'الآن';

  @override
  String get thisWeek => 'هذا الأسبوع';

  @override
  String get noDataAvailable => 'لا توجد بيانات متاحة';

  @override
  String get totalRevenue => 'إجمالي الإيرادات';

  @override
  String get totalExpenses => 'إجمالي المصروفات';

  @override
  String get netCashFlow => 'صافي التدفق النقدي';

  @override
  String get profitMargin => 'هامش الربح';

  @override
  String get revenue => 'الإيرادات';

  @override
  String get customerPayments => 'دفعات الزبائن';

  @override
  String get salesReturns => 'مرتجعات المبيعات';

  @override
  String get generalExpenses => 'المصاريف العامة';

  @override
  String get salaries => 'الرواتب';

  @override
  String get advances => 'السلف';

  @override
  String get profitWithdrawals => 'سحوبات الأرباح';

  @override
  String get sessionExpired => 'انتهت الجلسة';

  @override
  String get tryChangingFilters => 'لا توجد منتجات';

  @override
  String get noProductsFound => 'جرب تغيير الفلتر';

  @override
  String get categoryAndUnit => 'التصنيف والوحدة';

  @override
  String get noCategoriesAvailable => 'لا توجد تصنيفات متاحة';

  @override
  String get noUnitsAvailable => 'لا توجد وحدات متاحة';

  @override
  String get selectUnit => 'اختر الوحدة';

  @override
  String get bonusDeletedSuccess => 'تم حذف المكافأة بنجاح';

  @override
  String get bonusOptions => 'خيارات المكافأة';

  @override
  String get addBonusTooltip => 'إضافة مكافأة جديدة';

  @override
  String get addBonus => 'إضافة مكافأة';

  @override
  String get noBonusesMessage => 'لم يتم تسجيل أي مكافآت لهذا الموظف بعد';

  @override
  String get noBonuses => 'لا توجد مكافآت';

  @override
  String get bonusesHistory => 'سجل المكافآت';

  @override
  String get bonusDate => 'تاريخ المكافأة';

  @override
  String get bonusReasonHint => 'مثال: تميز في الأداء، إنجاز مشروع';

  @override
  String get bonusReason => 'سبب المكافأة';

  @override
  String get amountMustBePositive => 'المبلغ يجب أن يكون أكبر من صفر';

  @override
  String get enterAmount => 'أدخل المبلغ';

  @override
  String get bonusAmount => 'قيمة المكافأة';

  @override
  String get bonusDetails => 'تفاصيل المكافأة';

  @override
  String get editBonus => 'تعديل مكافأة';

  @override
  String get bonusAddedSuccess => 'تم إضافة المكافأة بنجاح';

  @override
  String get bonusUpdatedSuccess => 'تم تحديث المكافأة بنجاح';

  @override
  String get deleteBonusConfirmation => 'تأكيد حذف المكافأة';

  @override
  String get viewDetails => 'عرض التفاصيل';

  @override
  String get payrollDeletedSuccess => 'تم حذف الراتب بنجاح';

  @override
  String get advanceOptions => 'خيارات السلفة';

  @override
  String get repayAdvance => 'تسديد السلفة';

  @override
  String get confirmRepayment => 'تأكيد التسديد';

  @override
  String get advanceRepaidSuccess => 'تم تسديد السلفة بنجاح';

  @override
  String get advanceDeletedSuccess => 'تم حذف السلفة بنجاح';

  @override
  String get payrollUpdatedSuccess => 'تم تحديث الراتب بنجاح';

  @override
  String get advanceUpdatedSuccess => 'تم تحديث السلفة بنجاح';

  @override
  String get editPayroll => 'تعديل راتب';

  @override
  String get editAdvance => 'تعديل سلفة';

  @override
  String get subscriptionmanagement => 'ادارة الاشتراكات';

  @override
  String get activationcodegenerator => 'مولد اكواد التفعيل';

  @override
  String get details => 'التفاصيل';

  @override
  String get register_screen_title => 'إنشاء حساب جديد';

  @override
  String get register_screen_icon_label => 'إنشاء حساب جديد';

  @override
  String get register_full_name_label => 'الاسم الكامل';

  @override
  String get register_full_name_hint => 'أحمد محمد';

  @override
  String get register_email_label => 'البريد الإلكتروني';

  @override
  String get register_email_hint => 'example@company.com';

  @override
  String get register_password_label => 'كلمة المرور';

  @override
  String get register_password_hint => '••••••••';

  @override
  String get register_confirm_password_label => 'تأكيد كلمة المرور';

  @override
  String get register_confirm_password_hint => '••••••••';

  @override
  String get register_button_text => 'إنشاء الحساب';

  @override
  String get register_divider_text => 'أو';

  @override
  String get register_have_account_button => 'لدي حساب - تسجيل الدخول';

  @override
  String get register_validation_required => 'مطلوب';

  @override
  String get register_validation_email_invalid => 'صيغة غير صحيحة';

  @override
  String get register_validation_password_min => '6 أحرف على الأقل';

  @override
  String get register_validation_password_mismatch => 'غير متطابقة';

  @override
  String get register_success_dialog_title => 'نجح';

  @override
  String get register_success_auto_activated =>
      'تم إنشاء الحساب بنجاح!\n\n✅ تم تفعيل الاشتراك التجريبي لمدة 14 يوم.\n\nسيتم توجيهك للشاشة الرئيسية الآن.';

  @override
  String get register_success_manual_activation =>
      'تم إنشاء الحساب بنجاح!\n\nيرجى التواصل مع المطور لتفعيل الاشتراك.\n\nسيتم توجيهك للشاشة الرئيسية الآن.';

  @override
  String get register_success_button => 'ابدأ الآن';

  @override
  String get register_error_dialog_title => 'خطأ';

  @override
  String get register_error_email_in_use => 'هذا الإيميل مستخدم بالفعل';

  @override
  String get register_error_invalid_email => 'صيغة الإيميل غير صحيحة';

  @override
  String get register_error_weak_password => 'كلمة المرور ضعيفة جداً';

  @override
  String get register_error_network => 'خطأ في الاتصال بالإنترنت';

  @override
  String get register_error_general => 'حدث خطأ في التسجيل';

  @override
  String get register_error_button => 'حسناً';

  @override
  String get login_screen_title => 'تسجيل الدخول';

  @override
  String get login_welcome_back => 'مرحباً بعودتك';

  @override
  String get login_email_label => 'البريد الإلكتروني';

  @override
  String get login_email_hint => 'example@company.com';

  @override
  String get login_password_label => 'كلمة المرور';

  @override
  String get login_password_hint => '••••••••';

  @override
  String get login_forgot_password => 'نسيت كلمة المرور';

  @override
  String get login_button_text => 'تسجيل الدخول';

  @override
  String get login_divider_text => 'أو';

  @override
  String get login_no_account_button => 'ليس لدي حساب - إنشاء حساب';

  @override
  String get login_validation_required => 'مطلوب';

  @override
  String get login_validation_email_invalid => 'صيغة غير صحيحة';

  @override
  String get login_error_dialog_title => 'خطأ';

  @override
  String get login_error_user_not_found => 'لا يوجد حساب بهذا الإيميل';

  @override
  String get login_error_wrong_password => 'كلمة المرور غير صحيحة';

  @override
  String get login_error_invalid_email => 'صيغة الإيميل غير صحيحة';

  @override
  String get login_error_user_disabled => 'هذا الحساب معطل';

  @override
  String get login_error_network => 'خطأ في الاتصال بالإنترنت';

  @override
  String get login_error_too_many_requests => 'محاولات كثيرة - حاول لاحقاً';

  @override
  String get login_error_general => 'حدث خطأ في تسجيل الدخول';

  @override
  String get login_error_button => 'حسناً';

  @override
  String get login_subscription_expired_title => 'الاشتراك منتهي';

  @override
  String get login_subscription_expired_info => 'يرجى تجديد الاشتراك للمتابعة';

  @override
  String get login_subscription_expired_cancel => 'إلغاء';

  @override
  String get login_subscription_expired_renew => 'تجديد الاشتراك';

  @override
  String get login_no_subscription_title => 'لا يوجد اشتراك';

  @override
  String get login_no_subscription_message =>
      'لا يوجد اشتراك مسجل لهذا الحساب.';

  @override
  String get login_no_subscription_info =>
      'يرجى التواصل مع المطور للحصول على كود تفعيل.';

  @override
  String get login_no_subscription_cancel => 'إلغاء';

  @override
  String get login_no_subscription_activate => 'تفعيل الآن';

  @override
  String get login_forgot_password_empty =>
      'الرجاء إدخال البريد الإلكتروني أولاً';

  @override
  String get login_forgot_password_invalid =>
      'صيغة البريد الإلكتروني غير صحيحة';

  @override
  String get login_forgot_password_sent_title => 'تم الإرسال';

  @override
  String get login_forgot_password_sent_button => 'حسناً';

  @override
  String get login_forgot_password_error_user_not_found =>
      'لا يوجد حساب بهذا الإيميل';

  @override
  String get login_forgot_password_error_invalid => 'صيغة الإيميل غير صحيحة';

  @override
  String get login_forgot_password_error_network => 'خطأ في الاتصال بالإنترنت';

  @override
  String get login_forgot_password_error_general => 'حدث خطأ في إرسال الرابط';

  @override
  String get login_offline_mode_warning =>
      '⚠️ لا يمكن التحقق من الاشتراك - العمل في الوضع المحلي';

  @override
  String get login_unexpected_error =>
      'حدث خطأ غير متوقع. يرجى المحاولة لاحقاً.';

  @override
  String get login_online_check_required =>
      'يرجى الاتصال بالإنترنت للتحقق من الاشتراك';

  @override
  String get appGuide => 'دليل التطبيق';

  @override
  String get appGuideDescription => 'شرح شامل لجميع ميزات التطبيق';

  @override
  String get shareApp => 'مشاركة التطبيق';

  @override
  String get shareAppDescription => 'شارك التطبيق مع أصدقائك';

  @override
  String get profileuser => 'الملف الشخصي';

  @override
  String get accountuser => 'الحساب';

  @override
  String get youcantrythe => 'يمكنك تجربة الميزة على جهاز حقيقي';

  @override
  String get editNameAndPassword => 'تعديل الاسم وكلمة المرور';

  @override
  String get editName => 'تعديل الاسم';

  @override
  String get saveName => 'حفظ الاسم';

  @override
  String get requiredd => 'مطلوب';

  @override
  String get nameTooShort => 'الاسم قصير جداً';

  @override
  String get userNotFound => 'لم يتم العثور على المستخدم';

  @override
  String get nameUpdatedSuccess => 'تم تحديث الاسم بنجاح';

  @override
  String get nameUpdateError => 'حدث خطأ في تحديث الاسم';

  @override
  String get internetError => 'خطأ في الاتصال بالإنترنت';

  @override
  String get passwordChangedSuccess => 'تم تغيير كلمة المرور بنجاح';

  @override
  String get currentPasswordWrong => 'كلمة المرور الحالية غير صحيحة';

  @override
  String get newPasswordWeak => 'كلمة المرور الجديدة ضعيفة جداً';

  @override
  String get reloginRequired => 'يجب تسجيل الدخول مرة أخرى للقيام بهذا الإجراء';

  @override
  String get changePassword => 'تغيير كلمة المرور';

  @override
  String get currentPassword => 'كلمة المرور الحالية';

  @override
  String get newPassword => 'كلمة المرور الجديدة';

  @override
  String get passwordMinLength => '6 أحرف على الأقل';

  @override
  String get confirmNewPassword => 'تأكيد كلمة المرور الجديدة';

  @override
  String get passwordsNotMatch => 'غير متطابقة';

  @override
  String get sinanayad => 'سنان اياد';
}
