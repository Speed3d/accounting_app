// Hint: هذا الملف يحتوي على كل نماذج البيانات (الكلاسات) التي تمثل الجداول في قاعدة البيانات.

// --- نموذج المستخدم ---
//  قمنا بإزالة 'role' 
//وأضفنا متغيرات bool لكل صلاحية.
class User {
  final int? id;
  final String fullName;
  final String userName;
  final String password;
  final String dateT;
  final String? imagePath;

  // --- الصلاحيات الجديدة ---
  final bool isAdmin;
  final bool canViewSuppliers;
  final bool canEditSuppliers;
  final bool canViewProducts;
  final bool canEditProducts;
  final bool canViewCustomers;
  final bool canEditCustomers;
  final bool canViewReports;
  final bool canManageEmployees;
  final bool canViewSettings;
  final bool canViewEmployeesReport;
  final bool canManageExpenses;
  final bool canViewCashSales;

  User({
    this.id,
    required this.fullName,
    required this.userName,
    required this.password,
    required this.dateT,
    this.imagePath,
    // --- الصلاحيات في الكونستركتور ---
    this.isAdmin = false,
    this.canViewSuppliers = false,
    this.canEditSuppliers = false,
    this.canViewProducts = false,
    this.canEditProducts = false,
    this.canViewCustomers = false,
    this.canEditCustomers = false,
    this.canViewReports = false,
    this.canManageEmployees = false,
    this.canViewSettings = false,
    this.canViewEmployeesReport=false,
    this.canManageExpenses = false,
    this.canViewCashSales = false,
  });

  // Hint: دالة toMap الآن تقوم بتحويل قيم bool إلى 1 أو 0 لتخزينها في قاعدة البيانات.
  Map<String, dynamic> toMap() => {
        'ID': id,
        'FullName': fullName,
        'UserName': userName,
        'Password': password,
        'DateT': dateT,
        'ImagePath': imagePath,
        // --- تحويل الصلاحيات إلى أرقام ---
        'IsAdmin': isAdmin ? 1 : 0,
        'CanViewSuppliers': canViewSuppliers ? 1 : 0,
        'CanEditSuppliers': canEditSuppliers ? 1 : 0,
        'CanViewProducts': canViewProducts ? 1 : 0,
        'CanEditProducts': canEditProducts ? 1 : 0,
        'CanViewCustomers': canViewCustomers ? 1 : 0,
        'CanEditCustomers': canEditCustomers ? 1 : 0,
        'CanViewReports': canViewReports ? 1 : 0,
        'CanManageEmployees': canManageEmployees ? 1 : 0,
        'CanViewSettings': canViewSettings ? 1 : 0,
        'CanViewEmployeesReport': canViewEmployeesReport ? 1 : 0,
        'CanManageExpenses': canManageExpenses ? 1 : 0,
        'CanViewCashSales': canViewCashSales ? 1 : 0,
      };

  // Hint: دالة fromMap تقوم بالعكس، تحول 1 أو 0 من قاعدة البيانات إلى true أو false.
 factory User.fromMap(Map<String, dynamic> map) => User(
      id: map['ID'],
      fullName: map['FullName'],
      userName: map['UserName'],
      password: map['Password'],
      dateT: map['DateT'],
      imagePath: map['ImagePath'],
      
      // --- ✅ الإصلاح الرئيسي هنا ---
      // Hint: نستخدم `?? 0` كقيمة افتراضية آمنة.
      // إذا كان المفتاح (مثل 'IsAdmin') غير موجود في الـ map، فإنه سيعيد null.
      // `?? 0` تعني: "إذا كانت القيمة null، استخدم 0 بدلاً منها".
      // هذا يضمن أن المقارنة `== 1` ستعمل دائمًا بشكل صحيح.
      isAdmin: (map['IsAdmin'] ?? 0) == 1,
      canViewSuppliers: (map['CanViewSuppliers'] ?? 0) == 1,
      canEditSuppliers: (map['CanEditSuppliers'] ?? 0) == 1,
      canViewProducts: (map['CanViewProducts'] ?? 0) == 1,
      canEditProducts: (map['CanEditProducts'] ?? 0) == 1,
      canViewCustomers: (map['CanViewCustomers'] ?? 0) == 1,
      canEditCustomers: (map['CanEditCustomers'] ?? 0) == 1,
      canViewReports: (map['CanViewReports'] ?? 0) == 1,
      canManageEmployees: (map['CanManageEmployees'] ?? 0) == 1,
      canViewSettings: (map['CanViewSettings'] ?? 0) == 1,
      canViewEmployeesReport: (map['CanViewEmployeesReport'] ?? 0) ==1,
      canManageExpenses: (map['CanManageExpenses'] ?? 0) == 1,
      canViewCashSales: (map['CanViewCashSales'] ?? 0) == 1,
    );
}

//Job title
// --- ✅ الخطوة 2: إضافة نماذج البيانات الجديدة للموظفين ---

// --- نموذج الموظف ---
class Employee {
  final int? employeeID;
  final String fullName;
  final String jobTitle;
  final String? address;
  final String? phone;
  final String? imagePath;
  final String hireDate;
  final dynamic baseSalary;
  final dynamic balance; // الرصيد المستحق على الموظف (للسلف)
  final bool isActive;

  Employee({
    this.employeeID,
    required this.fullName,
    required this.jobTitle,
    this.address,
    this.phone,
    this.imagePath,
    required this.hireDate,
    required this.baseSalary,
    this.balance = 0.0,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() => {
        'EmployeeID': employeeID,
        'FullName': fullName,
        'jobTitle': jobTitle,
        'Address': address,
        'Phone': phone,
        'ImagePath': imagePath,
        'HireDate': hireDate,
        'BaseSalary': baseSalary,
        'Balance': balance,
        'IsActive': isActive ? 1 : 0,
      };

  factory Employee.fromMap(Map<String, dynamic> map) => Employee(
        employeeID: map['EmployeeID'],
        fullName: map['FullName'],
        jobTitle: map['jobTitle'],
        address: map['Address'],
        phone: map['Phone'],
        imagePath: map['ImagePath'],
        hireDate: map['HireDate'],
        baseSalary: (map['BaseSalary'] as num).toDouble(),
        balance: (map['Balance'] as num).toDouble(),
        isActive: map['IsActive'] == 1,
      );
}

// --- نموذج سجل الرواتب ---
class PayrollEntry {
  final int? payrollID;
  final int employeeID;
  final String paymentDate;
  final int payrollMonth; // ✅ الحقل الجديد
  final int payrollYear;  // ✅ الحقل الجديد
  final dynamic baseSalary;
  final dynamic bonuses;
  final dynamic deductions;
  final dynamic advanceDeduction; // المبلغ المخصوم من السلفة
  final dynamic netSalary;
  final String? notes;

  PayrollEntry({
    this.payrollID,
    required this.employeeID,
    required this.paymentDate,
    required this.payrollMonth, // ✅
    required this.payrollYear,  // ✅
    required this.baseSalary,
    this.bonuses = 0.0,
    this.deductions = 0.0,
    this.advanceDeduction = 0.0,
    required this.netSalary,
    this.notes,
  });

  Map<String, dynamic> toMap() => {
        'PayrollID': payrollID,
        'EmployeeID': employeeID,
        'PaymentDate': paymentDate,
        'PayrollMonth': payrollMonth, // ✅
        'PayrollYear': payrollYear,   // ✅
        'BaseSalary': baseSalary,
        'Bonuses': bonuses,
        'Deductions': deductions,
        'AdvanceDeduction': advanceDeduction,
        'NetSalary': netSalary,
        'Notes': notes,
      };

        factory PayrollEntry.fromMap(Map<String, dynamic> map) => PayrollEntry(
        payrollID: map['PayrollID'],
        employeeID: map['EmployeeID'],
        paymentDate: map['PaymentDate'],
        payrollMonth: map['PayrollMonth'], // ✅
        payrollYear: map['PayrollYear'],   // ✅
        baseSalary: (map['BaseSalary'] as num).toDouble(),
        bonuses: (map['Bonuses'] as num).toDouble(),
        deductions: (map['Deductions'] as num).toDouble(),
        advanceDeduction: (map['AdvanceDeduction'] as num).toDouble(),
        netSalary: (map['NetSalary'] as num).toDouble(),
        notes: map['Notes'],
      );
}

// --- نموذج سلفة الموظف ---
class EmployeeAdvance {
  final int? advanceID;
  final int employeeID;
  final String advanceDate;
  final dynamic advanceAmount;
  final String repaymentStatus; // "غير مسددة", "مسددة جزئيًا", "مسددة بالكامل"
  final String? notes;

  EmployeeAdvance({
    this.advanceID,
    required this.employeeID,
    required this.advanceDate,
    required this.advanceAmount,
    required this.repaymentStatus,
    this.notes,
  });

    Map<String, dynamic> toMap() => {
        'AdvanceID': advanceID,
        'EmployeeID': employeeID,
        'AdvanceDate': advanceDate,
        'AdvanceAmount': advanceAmount,
        'RepaymentStatus': repaymentStatus,
        'Notes': notes,
      };

       factory EmployeeAdvance.fromMap(Map<String, dynamic> map) => EmployeeAdvance(
        advanceID: map['AdvanceID'],
        employeeID: map['EmployeeID'],
        advanceDate: map['AdvanceDate'],
        advanceAmount: (map['AdvanceAmount'] as num).toDouble(),
        repaymentStatus: map['RepaymentStatus'],
        notes: map['Notes'],
      );
}


// --- نموذج المورد ---
class Supplier {
  final int? supplierID;
  final String supplierName;
  final String supplierType;
  final String? address;
  final String? phone;
  final String? notes;
  final String dateAdded;
  final String? imagePath;
  final bool isActive;
  List<Partner> partners;

  Supplier({
    this.supplierID, 
    required this.supplierName,
    required this.supplierType, 
    this.address,
    this.phone, 
    this.notes, 
    required this.dateAdded, 
    this.partners = const [], 
    this.imagePath, 
    this.isActive = true});

  Map<String, dynamic> toMap() => {
  'SupplierID': supplierID, 
  'SupplierName': supplierName, 
  'SupplierType': supplierType, 
  'Address': address, 
  'Phone': phone, 
  'Notes': notes, 
  'DateAdded': dateAdded, 
  'ImagePath': imagePath, 
  'IsActive': isActive ? 1 : 0};

  factory Supplier.fromMap(Map<String, dynamic> map) => Supplier(
  supplierID: map['SupplierID'], 
  supplierName: map['SupplierName'], 
  supplierType: map['SupplierType'], 
  address: map['Address'], 
  phone: map['Phone'], 
  notes: map['Notes'], 
  dateAdded: map['DateAdded'], 
  imagePath: map['ImagePath'], 
  isActive: map['IsActive'] == 1);
}

// --- نموذج الشريك ---
class Partner {
  final int? partnerID;
  final int? supplierID;
  final String partnerName;
  final dynamic sharePercentage;
  final String? partnerAddress;
  final String? partnerPhone;
  final String? imagePath;
  final String? dateAdded;
  final String? notes;

  Partner({this.partnerID, 
  this.supplierID, required 
  this.partnerName, required 
  this.sharePercentage, 
  this.partnerAddress, 
  this.partnerPhone, 
  this.imagePath,
  this.dateAdded, 
  this.notes});

  Map<String, dynamic> toMap() => {
    'PartnerID': partnerID, 
    'SupplierID': supplierID, 
    'PartnerName': partnerName, 
    'SharePercentage': sharePercentage, 
    'PartnerAddress': partnerAddress, 
    'PartnerPhone': partnerPhone, 
    'ImagePath': imagePath,
    'DateAdded': dateAdded, 
    'Notes': notes};

  factory Partner.fromMap(Map<String, dynamic> map) => Partner(
   partnerID: map['PartnerID'],
   supplierID: map['SupplierID'], 
   partnerName: map['PartnerName'], 
   sharePercentage: map['SharePercentage'], 
   partnerAddress: map['PartnerAddress'], 
   partnerPhone: map['PartnerPhone'], 
   imagePath: map['ImagePath'],
   dateAdded: map['DateAdded'], 
   notes: map['Notes']);

  Partner copyWith({
    int? partnerID, 
    int? supplierID,
     String? partnerName, 
     dynamic? sharePercentage, 
     String? partnerAddress, 
     String? partnerPhone, 
     String? imagePath,
     String? dateAdded, 
     String? notes}) => Partner(
     partnerID: partnerID ?? this.partnerID, 
     supplierID: supplierID ?? this.supplierID, 
     partnerName: partnerName ?? this.partnerName, 
     sharePercentage: sharePercentage ?? this.sharePercentage, 
     partnerAddress: partnerAddress ?? this.partnerAddress, 
     partnerPhone: partnerPhone ?? this.partnerPhone, 
     imagePath: imagePath ?? this.imagePath,
     dateAdded: dateAdded ?? this.dateAdded, 
     notes: notes ?? this.notes);
}

// --- نموذج المنتج ---
class Product {
  final int? productID;
  final String productName;
  final String? productDetails;
  final String? barcode; 
  final int quantity;
  // final double costPrice;
  final dynamic costPrice;
  final dynamic sellingPrice;
  final int supplierID;
  final bool isActive;
  String? supplierName;
  final String? imagePath;

  Product({
    this.productID, required 
    this.productName, 
    this.productDetails, required 
    this.barcode, required
    this.quantity, required 
    this.costPrice, required 
    this.sellingPrice, required 
    this.supplierID, 
    this.supplierName, 
    this.isActive = true,
    this.imagePath,
    });

  Map<String, dynamic> toMap() => {
    'ProductID': productID, 
    'ProductName': productName,
    'ProductDetails': productDetails, 
    'Barcode': barcode,
    'Quantity': quantity, 
    'CostPrice': costPrice, 
    'SellingPrice': sellingPrice, 
    'SupplierID': supplierID, 
    'IsActive': isActive ? 1 : 0,
    'ImagePath': imagePath,
    };

  factory Product.fromMap(Map<String, dynamic> map) => Product(
    productID: map['ProductID'], 
    productName: map['ProductName'], 
    productDetails: map['ProductDetails'], 
    barcode: map['Barcode'],
    quantity: map['Quantity'], 
    costPrice: (map['CostPrice'] as num).toDouble(), 
    sellingPrice: (map['SellingPrice'] as num).toDouble(), 
    supplierID: map['SupplierID'], 
    supplierName: map['SupplierName'], 
    isActive: map['IsActive'] == null ? true : map['IsActive'] == 1,
    imagePath: map['ImagePath'],
    );
}

// --- نموذج الزبون ---
class Customer {
  final int? customerID;
  final String customerName;
  final String? address;
  final String? phone;
  final dynamic debt;
  final dynamic payment;
  final dynamic remaining;
  final String dateT;
  final String? imagePath;
  final bool isActive;

  Customer({
    this.customerID, 
    required this.customerName, 
    this.address, 
    this.phone, 
    this.debt = 0.0, 
    this.payment = 0.0, 
    this.remaining = 0.0, 
    required this.dateT, 
    this.imagePath, 
    this.isActive = true});

  Map<String, dynamic> toMap() => {
    'CustomerID': customerID,
    'CustomerName': customerName,
    'Address': address, 
    'Phone': phone, 
    'Debt': debt, 
    'Payment': payment, 
    'Remaining': remaining, 
    'DateT': dateT, 
    'ImagePath': imagePath, 
    'IsActive': isActive ? 1 : 0};

  factory Customer.fromMap(Map<String, dynamic> map) => Customer(customerID: map['CustomerID'], customerName: map['CustomerName'], address: map['Address'], phone: map['Phone'], debt: (map['Debt'] as num).toDouble(), payment: (map['Payment'] as num).toDouble(), remaining: (map['Remaining'] as num).toDouble(), dateT: map['DateT'], imagePath: map['ImagePath'], isActive: map['IsActive'] == 1);
}

// --- نموذج دين الزبون (عملية شراء) ---
// Hint: قمنا بإضافة حقل isReturned لحفظ حالة الإرجاع.
class CustomerDebt {
  final int? id;
  final int customerID;
  final String? customerName;
  final String details;
  final dynamic debt;
  final String dateT;
  // final int qty_Coustomer;
  final int qty_Customer;
  final int productID;
  final dynamic costPriceAtTimeOfSale;
  final dynamic profitAmount;
  final int isReturned; // 0 = not returned, 1 = returned

  CustomerDebt({this.id, required this.customerID, this.customerName, required this.details, required this.debt, required this.dateT, required this.qty_Customer, required this.productID, required this.costPriceAtTimeOfSale, required this.profitAmount, this.isReturned = 0});

  Map<String, dynamic> toMap() => {'ID': id, 'CustomerID': customerID, 'CustomerName': customerName, 'Details': details, 'Debt': debt, 'DateT': dateT, 'Qty_Customer': qty_Customer, 'ProductID': productID, 'CostPriceAtTimeOfSale': costPriceAtTimeOfSale, 'ProfitAmount': profitAmount, 'IsReturned': isReturned};

  factory CustomerDebt.fromMap(Map<String, dynamic> map) => CustomerDebt(id: map['ID'], customerID: map['CustomerID'], customerName: map['CustomerName'], details: map['Details'], debt: (map['Debt'] as num).toDouble(), dateT: map['DateT'], qty_Customer: map['Qty_Customer'], productID: map['ProductID'], costPriceAtTimeOfSale: (map['CostPriceAtTimeOfSale'] as num).toDouble(), profitAmount: (map['ProfitAmount'] as num).toDouble(), isReturned: map['IsReturned'] ?? 0);
}

// --- نموذج دفعة الزبون ---
// Hint: قمنا بتصحيح اسم الحقل من CustomerID إلى customerID ليتوافق مع الاستخدام.
class CustomerPayment {
  final int? id;
  final int customerID;
  final String? customerName;
  final dynamic payment;
  final String dateT;
  final String? comments;

  CustomerPayment({this.id, required this.customerID, this.customerName, required this.payment, required this.dateT, this.comments});

  Map<String, dynamic> toMap() => {'ID': id, 'CustomerID': customerID, 'CustomerName': customerName, 'Payment': payment, 'DateT': dateT, 'Comments': comments};

  factory CustomerPayment.fromMap(Map<String, dynamic> map) => CustomerPayment(id: map['ID'], customerID: map['CustomerID'], customerName: map['CustomerName'], payment: (map['Payment'] as num).toDouble(), dateT: map['DateT'], comments: map['Comments']);
}

// --- نموذج عنصر سلة المشتريات ---
class CartItem {
  final Product product;
  final int quantity;
  CartItem({required this.product, required this.quantity});
}

// --- نموذج مرتجع المبيعات ---
class SalesReturn {
  final int? returnID;
  final int originalSaleID;
  final int productID;
  final int returnedQuantity;
  final dynamic returnAmount;
  final String returnDate;
  final int customerID;
  final String? reason;

  SalesReturn({this.returnID, required this.originalSaleID, required this.productID, required this.returnedQuantity, required this.returnAmount, required this.returnDate, required this.customerID, this.reason});

  Map<String, dynamic> toMap() => {'ReturnID': returnID, 'OriginalSaleID': originalSaleID, 'ProductID': productID, 'ReturnedQuantity': returnedQuantity, 'ReturnAmount': returnAmount, 'ReturnDate': returnDate, 'CustomerID': customerID, 'Reason': reason};
}

// --- نموذج سجل النشاط ---
class ActivityLog {
  final int? logID;
  final int? userID;
  final String? userName;
  final String action;
  final String timestamp;

  ActivityLog({this.logID, this.userID, this.userName, required this.action, required this.timestamp});
}
