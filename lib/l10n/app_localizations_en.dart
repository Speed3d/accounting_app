// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get settings => 'Settings';

  @override
  String get homePage => 'Home Page';

  @override
  String get users => 'Users';

  @override
  String get suppliers => 'Suppliers';

  @override
  String get products => 'Products';

  @override
  String get employees => 'Employees';

  @override
  String get customers => 'Customers';

  @override
  String get reports => 'Reports';

  @override
  String get customization => 'Customization';

  @override
  String get companyInformation => 'Company Information';

  @override
  String get changeAppNameAndLogo => 'Change app name and logo';

  @override
  String get dataManagement => 'Data Management';

  @override
  String get archiveCenter => 'Archive Center';

  @override
  String get restoreArchivedItems => 'Restore archived items';

  @override
  String get backupAndRestore => 'Backup and Restore';

  @override
  String get saveAndRestoreAppData => 'Save and restore app data';

  @override
  String get about => 'About';

  @override
  String get aboutTheApp => 'About The App';

  @override
  String get language => 'Language';

  @override
  String get changeLanguage => 'Change app language';

  @override
  String get customersList => 'Customers List';

  @override
  String get noActiveCustomers => 'No active customers yet.';

  @override
  String get phone => 'Phone';

  @override
  String get unregistered => 'Not registered';

  @override
  String get remainingForHim => 'Credit';

  @override
  String get remainingOnHim => 'Debt';

  @override
  String get balance => 'Balance';

  @override
  String get archive => 'Archive';

  @override
  String get confirmArchive => 'Confirm Archive';

  @override
  String get cancel => 'Cancel';

  @override
  String get edit => 'Edit';

  @override
  String get delete => 'Delete';

  @override
  String get save => 'Save';

  @override
  String get addEditCustomer => 'Add/Edit Customer';

  @override
  String get customerName => 'Customer Name';

  @override
  String get addressOptional => 'Address (Optional)';

  @override
  String get phoneOptional => 'Phone (Optional)';

  @override
  String get fieldRequired => 'Field is required';

  @override
  String get customerAddedSuccess => 'Customer added successfully!';

  @override
  String get customerUpdatedSuccess => 'Customer updated successfully!';

  @override
  String get chooseImageSource => 'Choose Image Source';

  @override
  String get gallery => 'Gallery';

  @override
  String get camera => 'Camera';

  @override
  String get customerDetails => 'Customer Details';

  @override
  String get purchases => 'Purchases';

  @override
  String get payments => 'Payments';

  @override
  String get noPurchases => 'No purchases recorded.';

  @override
  String get noPayments => 'No payments recorded.';

  @override
  String get newSaleSuccess => 'New sale recorded successfully!';

  @override
  String get newPayment => 'New Payment';

  @override
  String get paidAmount => 'Paid Amount';

  @override
  String get amountRequired => 'Amount is required';

  @override
  String get enterValidAmount => 'Enter a valid amount greater than zero';

  @override
  String get amountExceedsDebt => 'Amount is greater than the remaining debt';

  @override
  String get notesOptional => 'Notes (Optional)';

  @override
  String get paymentSuccess => 'Payment recorded successfully!';

  @override
  String get returnConfirmTitle => 'Confirm Return';

  @override
  String returnConfirmContent(String details) {
    return 'Are you sure you want to return this item?\n\"$details\"\nThe quantity will be returned to stock and the customer\'s account will be adjusted.';
  }

  @override
  String get returnSuccess => 'Item returned successfully!';

  @override
  String errorOccurred(String error) {
    return 'An error occurred: $error';
  }

  @override
  String get returnItem => 'Return Item';

  @override
  String saleDetails(String productName, String quantity) {
    return 'Sale Details: $productName (Qty: $quantity)';
  }

  @override
  String newAdvanceFor(Object name) {
    return 'New Advance for: $name';
  }

  @override
  String get advanceAmount => 'Advance Amount';

  @override
  String get advanceDate => 'Advance Date';

  @override
  String get saveAdvance => 'Save Advance';

  @override
  String get advanceAddedSuccess => 'Advance recorded successfully!';

  @override
  String get unpaid => 'Unpaid';

  @override
  String get addEmployee => 'Add Employee';

  @override
  String get editEmployee => 'Edit Employee';

  @override
  String get employeeName => 'Employee Full Name';

  @override
  String get employeeNameRequired => 'Employee name is required';

  @override
  String get jobTitle => 'Job Title';

  @override
  String get jobTitleRequired => 'Job title is required';

  @override
  String get baseSalary => 'Base Salary';

  @override
  String get baseSalaryRequired => 'Base salary is required';

  @override
  String get enterValidNumber => 'Enter a valid number';

  @override
  String get hireDate => 'Hire Date';

  @override
  String get employeeAddedSuccess => 'Employee added successfully!';

  @override
  String get employeeUpdatedSuccess => 'Employee updated successfully!';

  @override
  String payrollFor(Object name) {
    return 'Payroll for: $name';
  }

  @override
  String get payrollForMonthAndYear => 'Payroll for month and year:';

  @override
  String get month => 'Month';

  @override
  String get year => 'Year';

  @override
  String get payrollAlreadyExists =>
      'Error: A payroll for this month has already been recorded.';

  @override
  String get payrollSavedSuccess => 'Payroll saved successfully!';

  @override
  String get bonuses => 'Bonuses (+)';

  @override
  String get deductions => 'Deductions (-)';

  @override
  String get advanceRepayment => 'Advance Repayment (-)';

  @override
  String currentBalanceOnEmployee(Object balance) {
    return 'Current balance on employee: $balance';
  }

  @override
  String get enterZeroIfNotRepaying => 'Enter 0 if there is no repayment';

  @override
  String get repaymentExceedsBalance =>
      'Amount is greater than the employee\'s advance balance';

  @override
  String get paymentDate => 'Payment Date';

  @override
  String get saveAndPaySalary => 'Save and Pay Salary';

  @override
  String get netSalaryDue => 'Net Salary Due';

  @override
  String get fieldRequiredEnterZero =>
      'Field is required, enter 0 for zero value';

  @override
  String get payrollHistory => 'Payroll History';

  @override
  String get advancesHistory => 'Advances History';

  @override
  String get noPayrolls => 'No payrolls recorded.';

  @override
  String get noAdvances => 'No advances recorded.';

  @override
  String payrollDetailsFor(Object month) {
    return 'Payroll Details for $month';
  }

  @override
  String paidOn(Object date) {
    return 'Paid on: $date';
  }

  @override
  String payrollOfMonth(Object month, Object year) {
    return 'Payroll for $month $year';
  }

  @override
  String advanceAmountLabel(Object amount) {
    return 'Advance Amount: $amount';
  }

  @override
  String advanceDateLabel(Object date) {
    return 'Advance Date: $date';
  }

  @override
  String get fullyPaid => 'Fully Paid';

  @override
  String get employeesList => 'Employees List';

  @override
  String get noEmployees =>
      'No employees currently. Press + to add the first employee.';

  @override
  String jobTitleLabel(Object title) {
    return 'Job Title: $title';
  }

  @override
  String baseSalaryLabel(Object salary) {
    return 'Base Salary: $salary';
  }

  @override
  String advancesBalanceLabel(Object balance) {
    return 'Advances Balance: $balance';
  }

  @override
  String get suppliersList => 'Suppliers List';

  @override
  String get noActiveSuppliers => 'No active suppliers.';

  @override
  String get type => 'Type';

  @override
  String get individual => 'Individual';

  @override
  String get partner => 'Partner';

  @override
  String get addSupplier => 'Add New Supplier';

  @override
  String get editSupplier => 'Edit Supplier';

  @override
  String get supplierName => 'Supplier Name';

  @override
  String get supplierNameRequired => 'Supplier name is required';

  @override
  String get supplierType => 'Supplier Type';

  @override
  String get partnership => 'Partnership';

  @override
  String get partners => 'Partners';

  @override
  String get addPartner => 'Add Partner';

  @override
  String get atLeastOnePartnerRequired =>
      'At least one partner must be added for a partnership type.';

  @override
  String partnerShareTotalExceeds100(Object total) {
    return 'Error: Total partner shares ($total%) exceeds 100%.';
  }

  @override
  String get supplierAddedSuccess => 'Supplier added successfully!';

  @override
  String get supplierUpdatedSuccess => 'Supplier updated successfully!';

  @override
  String get addNewPartner => 'Add New Partner';

  @override
  String get partnerName => 'Partner Name';

  @override
  String get partnerNameRequired => 'Partner name is required';

  @override
  String get sharePercentage => 'Share Percentage (%)';

  @override
  String get percentageMustBeBetween1And100 =>
      'Percentage must be between 1 and 100';

  @override
  String get shareTotalExceeds100 =>
      'Error: Total partner shares cannot exceed 100%.';

  @override
  String percentageLabel(Object percentage) {
    return 'Percentage: $percentage%';
  }

  @override
  String typeLabel(Object type) {
    return 'Type: $type';
  }

  @override
  String get cannotArchiveSupplierWithActiveProducts =>
      'This supplier cannot be archived because they are linked to active products.';

  @override
  String archiveSupplierConfirmation(Object name) {
    return 'Are you sure you want to archive the supplier \"$name\"? They will be hidden from lists.';
  }

  @override
  String archiveSupplierLog(Object name) {
    return 'Archive Supplier: $name';
  }

  @override
  String get addUser => 'Add New User';

  @override
  String get editUser => 'Edit User';

  @override
  String get passwordRequiredForNewUser =>
      'Password is required for a new user';

  @override
  String get userAddedSuccess => 'User added successfully!';

  @override
  String get userUpdatedSuccess => 'User updated successfully!';

  @override
  String get usernameAlreadyExists =>
      'This username already exists. Please choose another one.';

  @override
  String get passwordHint => 'Leave blank to keep unchanged';

  @override
  String get userPermissions => 'User Permissions';

  @override
  String get adminPermission => 'Full Admin Privileges';

  @override
  String get adminPermissionSubtitle =>
      'Grants all permissions and overrides any other selection.';

  @override
  String get viewSuppliers => 'View Suppliers';

  @override
  String get editSuppliers => 'Edit Suppliers';

  @override
  String get viewProducts => 'View Products';

  @override
  String get editProducts => 'Edit Products';

  @override
  String get viewCustomers => 'View Customers';

  @override
  String get editCustomers => 'Edit Customers';

  @override
  String get viewReports => 'View Reports';

  @override
  String get viewEmployeesReport => 'View Employees Report';

  @override
  String get viewSettings => 'View Settings';

  @override
  String get manageEmployees => 'Manage Employees';

  @override
  String get manageExpenses => 'Manage General Expenses';

  @override
  String get viewCashSales => 'View Cash Sales Reports';

  @override
  String get usersList => 'Users List';

  @override
  String get noUsers => 'No users yet.';

  @override
  String get you => '(You)';

  @override
  String get admin => 'Admin';

  @override
  String get customPermissionsUser => 'User with custom permissions';

  @override
  String get usernameLabel => 'Username';

  @override
  String get cannotEditOwnAccount =>
      'You cannot edit your own account from here. Use the settings screen instead.';

  @override
  String get cannotDeleteOwnAccount => 'You cannot delete your own account.';

  @override
  String get cannotDeleteLastUser =>
      'The last user in the system cannot be deleted.';

  @override
  String deleteUserConfirmation(String name) {
    return 'Are you sure you want to delete the user \"$name\"? This action cannot be undone.';
  }

  @override
  String deleteUserLog(String name) {
    return 'Delete user: $name';
  }

  @override
  String get productsList => 'Products List';

  @override
  String get noActiveProducts => 'No active products in stock.';

  @override
  String get searchForProduct => 'Search for a product...';

  @override
  String get noMatchingResults => 'No matching results found.';

  @override
  String get supplier => 'Supplier';

  @override
  String get quantity => 'Quantity';

  @override
  String get sellingPrice => 'Selling Price';

  @override
  String get cannotArchiveSoldProduct =>
      'This product cannot be archived because it is linked to previous sales.';

  @override
  String archiveProductConfirmation(Object name) {
    return 'Are you sure you want to archive the product \"$name\"?';
  }

  @override
  String supplierLabel(Object name) {
    return 'Supplier: $name';
  }

  @override
  String quantityLabel(Object qty) {
    return 'Quantity: $qty';
  }

  @override
  String get undefined => 'Undefined';

  @override
  String sellingPriceLabel(Object price) {
    return 'Selling Price: $price';
  }

  @override
  String get addProduct => 'Add New Product';

  @override
  String get editProduct => 'Edit Product';

  @override
  String get pleaseSelectSupplier => 'Please select a supplier';

  @override
  String get productAddedSuccess => 'Product added successfully!';

  @override
  String get productUpdatedSuccess => 'Product updated successfully!';

  @override
  String get productName => 'Product Name';

  @override
  String get productNameRequired => 'Product name is required';

  @override
  String get productDetailsOptional => 'Product Details (Optional)';

  @override
  String get costPrice => 'Cost Price';

  @override
  String get fieldCannotBeNegative => 'Field cannot be negative';

  @override
  String get selectSupplier => 'Select a supplier';

  @override
  String get errorLoadingSuppliers => 'Error loading suppliers.';

  @override
  String get noSuppliersAddOneFirst =>
      'No suppliers found. Please add a supplier first.';

  @override
  String get barcode => 'Barcode';

  @override
  String get barcodeOptional => 'Barcode (Optional)';

  @override
  String get scanBarcode => 'Scan Barcode';

  @override
  String get cameraPermissionRequired =>
      'Camera permission is required to scan barcodes.';

  @override
  String get openSettings => 'Open Settings';

  @override
  String get barcodeAlreadyExists =>
      'Error: This barcode is already assigned to another product.';

  @override
  String productUpdatedWithBarcodeLog(Object name) {
    return 'Update product with barcode: $name';
  }

  @override
  String productAddedWithBarcodeLog(Object name) {
    return 'Add new product with barcode: $name';
  }

  @override
  String get productNotFound => 'Product not found or inactive';

  @override
  String get scanBarcodeToSell => 'Scan Barcode to Sell';

  @override
  String addWithProductName(String productName) {
    return 'Add \"$productName\"';
  }

  @override
  String get barcodeExistsError =>
      'This barcode is already registered for another product.';

  @override
  String get reportsHub => 'Reports Hub';

  @override
  String get profitReport => 'Profit Report';

  @override
  String get profitReportDesc => 'View net profit from all sales';

  @override
  String get supplierProfitReport => 'Supplier & Partner Profit Report';

  @override
  String get supplierProfitReportDesc =>
      'View profits grouped by each supplier';

  @override
  String get employeesReport => 'Employees Report';

  @override
  String get employeesReportDesc =>
      'Summary of salaries, advances, and employee statements';

  @override
  String get login => 'Login';

  @override
  String get username => 'Username';

  @override
  String get password => 'Password';

  @override
  String get loginTo => 'Login to';

  @override
  String get accountingProgram => 'Accounting Program';

  @override
  String get invalidCredentials => 'Incorrect username or password.';

  @override
  String get ok => 'OK';

  @override
  String get error => 'Error';

  @override
  String get success => 'Success';

  @override
  String get backupStarted => 'Backup sharing started.';

  @override
  String backupFailed(Object error) {
    return 'Backup failed: $error';
  }

  @override
  String get restoreConfirmTitle => 'Confirm Restore';

  @override
  String get restoreConfirmContent =>
      'Are you sure? All your current data will be replaced by the data in the backup. This action cannot be undone.';

  @override
  String get restore => 'Restore';

  @override
  String get restoreSuccessTitle => 'Restore Successful';

  @override
  String get restoreSuccessContent =>
      'Data restored successfully. Please restart the app to apply changes.';

  @override
  String restoreFailed(Object error) {
    return 'Restore failed: $error';
  }

  @override
  String get createBackupTitle => 'Create & Share Backup';

  @override
  String get createBackupSubtitle =>
      'Save an encrypted copy of your data and share it to a safe place.';

  @override
  String get restoreFromFileTitle => 'Restore Data from File';

  @override
  String get restoreFromFileSubtitle =>
      'Warning: This will replace all current data.';

  @override
  String get backupTip =>
      'Tip: Periodically back up your data off-device (to Google Drive or email) to protect it from loss or damage.';

  @override
  String get companyOrShopName => 'Company or Shop Name';

  @override
  String get companyDescOptional => 'Company Description (Optional)';

  @override
  String get companyDescHint => 'e.g., business activity, short address...';

  @override
  String get companyInfoHint =>
      'This name and logo will appear on the splash screen and in reports.';

  @override
  String get infoSavedSuccess => 'Information saved successfully!';

  @override
  String errorPickingImage(String error) {
    return 'Error picking image: $error';
  }

  @override
  String get archivedCustomer => 'Archived Customer';

  @override
  String get archivedSupplier => 'Archived Supplier';

  @override
  String archivedProduct(Object supplierName) {
    return 'Archived Product | Supplier: $supplierName';
  }

  @override
  String get unknown => 'Unknown';

  @override
  String itemRestoredSuccess(Object name) {
    return 'Item \"$name\" restored successfully!';
  }

  @override
  String get noArchivedItems => 'No archived items.';

  @override
  String get setupAdminAccount => 'Setup Admin Account';

  @override
  String get welcomeSetup =>
      'Welcome! This is a one-time setup. This account will have all permissions.';

  @override
  String get fullName => 'Full Name';

  @override
  String get fullNameRequired => 'Full name is required';

  @override
  String get usernameForLogin => 'Username (for login)';

  @override
  String get usernameRequired => 'Username is required';

  @override
  String get chooseStrongPassword => 'Choose a strong password';

  @override
  String get passwordRequired => 'Password is required';

  @override
  String get passwordTooShort => 'Password must be at least 4 characters';

  @override
  String get createAdminAndStart => 'Create Admin & Start';

  @override
  String get adminCreatedSuccess =>
      'Admin account created successfully! You can now log in.';

  @override
  String get usernameExists =>
      'This username already exists. Please choose another one.';

  @override
  String unexpectedError(Object error) {
    return 'An unexpected error occurred: $error';
  }

  @override
  String get pleaseEnterUsername => 'Please enter username';

  @override
  String get pleaseEnterPassword => 'Please enter password';

  @override
  String get addCustomer => 'Add Customer';

  @override
  String get editCustomer => 'Edit Customer';

  @override
  String get customerNameRequired => 'Customer name is required';

  @override
  String get imageSource => 'Image Source';

  @override
  String get cannotArchiveCustomerWithDebt =>
      'Cannot archive a customer with remaining debt.';

  @override
  String get archiveConfirmTitle => 'Confirm Archive';

  @override
  String archiveConfirmContent(Object name) {
    return 'Are you sure you want to archive the customer \"$name\"?';
  }

  @override
  String get chooseProducts => 'Choose Products';

  @override
  String get reviewCart => 'Review Cart';

  @override
  String get noProductsInStock => 'No products in stock.';

  @override
  String get available => 'Available';

  @override
  String get price => 'Price';

  @override
  String get add => 'Add';

  @override
  String get quantityExceedsStock =>
      'Requested quantity is more than available in stock!';

  @override
  String get cartIsEmpty => 'Shopping cart is empty!';

  @override
  String get product => 'product';

  @override
  String get total => 'Total';

  @override
  String get finalTotal => 'Final Total';

  @override
  String get close => 'Close';

  @override
  String itemsCount(String count) {
    return 'Items: $count';
  }

  @override
  String get totalSalariesPaid => 'Total Salaries Paid';

  @override
  String get totalAdvancesBalance => 'Total Advances Balance';

  @override
  String get activeEmployeesCount => 'Active Employees Count';

  @override
  String get employeesStatement => 'Employees Statement';

  @override
  String get noEmployeesToDisplay => 'No employees to display.';

  @override
  String salaryLabel(Object salary) {
    return 'Salary: $salary';
  }

  @override
  String get totalNetProfit => 'Total Net Profit';

  @override
  String get salesDetails => 'Sales Details';

  @override
  String get loadingDetails => 'Loading details...';

  @override
  String get noSalesRecorded => 'No sales recorded to display.';

  @override
  String customerLabel(String name) {
    return 'Customer: $name';
  }

  @override
  String dateLabel(String date) {
    return 'Date: $date';
  }

  @override
  String profitLabel(String profit) {
    return 'Profit: $profit';
  }

  @override
  String saleLabel(String sale) {
    return 'Sale: $sale';
  }

  @override
  String get generalProfitReport => 'General Profit Report';

  @override
  String get generalProfitReportSubtitle =>
      'View summary of profits, expenses, and net profit';

  @override
  String get supplierProfitReportSubtitle =>
      'View profits grouped by supplier and partner share distribution';

  @override
  String get cashSalesHistory => 'Cash Sales History';

  @override
  String get cashSalesHistorySubtitle => 'View and manage direct sale invoices';

  @override
  String get cashFlowReport => 'Cash Receipts Report';

  @override
  String get cashFlowReportSubtitle =>
      'View cash sales and customer debt payments';

  @override
  String get expensesLog => 'General Expenses Log';

  @override
  String get expensesLogSubtitle => 'View and record operational expenses';

  @override
  String get employeesAndSalariesReport => 'Employees & Salaries Report';

  @override
  String get employeesAndSalariesReportSubtitle =>
      'View summary of salaries, advances, and employee statements';

  @override
  String get noProfitsRecorded => 'No profits recorded to display.';

  @override
  String partnersLabel(String names) {
    return 'Partners: $names';
  }

  @override
  String netProfitLabel(String amount) {
    return 'Net Profit: $amount';
  }

  @override
  String get selectDateRange => 'Select Date Range';

  @override
  String get totalCashSales => 'Total Cash Sales';

  @override
  String get totalDebtPayments => 'Total Debt Payments';

  @override
  String get totalCashInflow => 'Total Cash Inflow';

  @override
  String get showDetails => 'Show Details';

  @override
  String get hideDetails => 'Hide Details';

  @override
  String get noTransactions => 'No cash transactions in this period.';

  @override
  String cashSaleDescription(String id) {
    return 'Direct Cash Sale (Invoice #$id)';
  }

  @override
  String debtPaymentDescription(String name) {
    return 'Payment from customer: $name';
  }

  @override
  String recordWithdrawalFor(String name) {
    return 'Record Withdrawal for: $name';
  }

  @override
  String availableNetProfit(String amount) {
    return 'Available Net Profit for Distribution: $amount';
  }

  @override
  String get withdrawnAmount => 'Withdrawn Amount';

  @override
  String get amountExceedsProfit => 'Amount exceeds available profit';

  @override
  String get withdrawalSuccess => 'Withdrawal recorded successfully';

  @override
  String get totalProfitFromSupplier => 'Total Profit from Supplier:';

  @override
  String get totalWithdrawals => 'Total Withdrawals:';

  @override
  String get remainingNetProfit => 'Remaining Net Profit:';

  @override
  String get partnersProfitDistribution => 'Partners\' Profit Distribution';

  @override
  String partnerShare(String amount) {
    return 'Share of net profit: $amount';
  }

  @override
  String get withdraw => 'Withdraw';

  @override
  String get recordGeneralWithdrawal => 'Record General Withdrawal';

  @override
  String get withdrawalsHistory => 'Withdrawals History';

  @override
  String get noWithdrawals => 'No withdrawals recorded.';

  @override
  String withdrawalAmountLabel(String amount) {
    return 'Amount: $amount';
  }

  @override
  String withdrawalForLabel(String name) {
    return 'For: $name';
  }

  @override
  String get refresh => 'Refresh';

  @override
  String get noDataToShow => 'No data to display.';

  @override
  String get showSalesDetails => 'Show Sales Details';

  @override
  String get hideSalesDetails => 'Hide Sales Details';

  @override
  String get grossProfitFromSales => 'Gross Profit from Sales';

  @override
  String get totalGeneralExpenses => '(-) Total General Expenses';

  @override
  String get totalProfitWithdrawals => '(-) Total Profit Withdrawals';

  @override
  String get netProfit => 'Final Net Profit';

  @override
  String get totalProfitFromThisSupplier => 'Total profit from this supplier';

  @override
  String get noPartnersForThisSupplier =>
      'No partners registered for this supplier.';

  @override
  String get noSalesForThisSupplier => 'No sales for this supplier.';

  @override
  String get searchByInvoiceNumber => 'Search by invoice number...';

  @override
  String get showInvoices => 'Show Invoices';

  @override
  String get hideInvoices => 'Hide Invoices';

  @override
  String get noCashInvoices => 'No cash sale invoices recorded.';

  @override
  String invoiceNo(String id) {
    return 'Invoice No: $id';
  }

  @override
  String get modified => 'Modified';

  @override
  String get voided => 'Voided';

  @override
  String get confirmVoidTitle => 'Confirm Invoice Void';

  @override
  String get confirmVoidContent =>
      'Are you sure you want to void this entire invoice? All its products will be returned to stock.';

  @override
  String get confirmVoidAction => 'Yes, Void';

  @override
  String get voidSuccess => 'Invoice voided successfully.';

  @override
  String detailsForInvoice(String id) {
    return 'Details for Invoice #$id';
  }

  @override
  String get directselling => 'Direct selling';

  @override
  String get directSalePoint => 'Direct Sale Point';

  @override
  String get completeSale => 'Complete Sale';

  @override
  String get saleSuccess => 'Sale completed successfully!';

  @override
  String get pdfInvoiceTitle => 'Cash Sale Invoice';

  @override
  String get pdfDate => 'Date';

  @override
  String get pdfInvoiceNumber => 'Invoice #';

  @override
  String get pdfHeaderProduct => 'Product';

  @override
  String get pdfHeaderQty => 'Qty';

  @override
  String get pdfHeaderPrice => 'Price';

  @override
  String get pdfHeaderTotal => 'Total';

  @override
  String get pdfFooterTotal => 'Total Amount';

  @override
  String get pdfFooterThanks => 'Thank you for your business';

  @override
  String get manageExpenseCategories => 'Manage Expense Categories';

  @override
  String get noCategories => 'No categories found. Add your first one.';

  @override
  String get addCategory => 'Add New Category';

  @override
  String get editCategory => 'Edit Category';

  @override
  String get categoryName => 'Category Name';

  @override
  String get categoryNameRequired => 'Category name is required';

  @override
  String get categoryExistsError => 'Error: This category name already exists.';

  @override
  String get confirmDeleteTitle => 'Confirm Deletion';

  @override
  String confirmDeleteCategory(String name) {
    return 'Are you sure you want to delete the category \"$name\"?';
  }

  @override
  String get manageCategories => 'Manage Categories';

  @override
  String get noExpenses => 'No expenses recorded.';

  @override
  String get addExpense => 'Add New Expense';

  @override
  String get newExpense => 'Record New Expense';

  @override
  String get expenseDescription => 'Expense Description';

  @override
  String get descriptionRequired => 'Description is required';

  @override
  String get amount => 'Amount';

  @override
  String get category => 'Category';

  @override
  String get selectCategory => 'Please select a category';

  @override
  String get addCategoriesFirst =>
      'Please add expense categories first from the manage categories screen.';

  @override
  String get expenseAddedSuccess => 'Expense recorded successfully.';

  @override
  String get unclassified => 'Unclassified';

  @override
  String get dashboard => 'Dashboard';

  @override
  String get today => 'Today';

  @override
  String get thisMonth => 'This Month';

  @override
  String get sales => 'Sales';

  @override
  String get profit => 'Profit';

  @override
  String get topSelling => 'Top Selling';

  @override
  String get topCustomer => 'Top Customer';

  @override
  String get generalStats => 'General Statistics';

  @override
  String get totalCustomers => 'Customers';

  @override
  String get totalProducts => 'Products';

  @override
  String get lowStock => 'Low Stock';

  @override
  String get pendingPayments => 'Pending Payments';

  @override
  String get topBuyerThisMonth => 'Top buyer this month';

  @override
  String get noSalesData => 'Not enough data to show top selling products';

  @override
  String get noCustomersData => 'Not enough data to show top customer';

  @override
  String get loadingStats => 'Loading statistics...';

  @override
  String get currency => 'IQD';

  @override
  String get errorLoadingData => 'Error loading data';

  @override
  String get pleaseTryAgain => 'Please try again';

  @override
  String get noSales => 'No sales';

  @override
  String get noCustomers => 'No customers';

  @override
  String get enterCustomerName => 'Enter customer name';

  @override
  String get enterAddress => 'Enter address';

  @override
  String get enterPhone => 'Enter phone number';

  @override
  String get updateCustomer => 'Update customer';

  @override
  String get loadingCustomers => 'Loading customers...';

  @override
  String get searchCustomers => 'Search customers';

  @override
  String get balanced => 'Balanced';

  @override
  String get archiveCustomer => 'Archive customer';

  @override
  String get customerArchivedSuccess => 'Customer archived successfully';

  @override
  String get basicInformation => 'Basic Information';

  @override
  String get suppliersManagement => 'Suppliers Management';

  @override
  String get productsManagement => 'Products Management';

  @override
  String get customersManagement => 'Customers Management';

  @override
  String get employeesManagement => 'Employees Management';

  @override
  String get reportsAndSales => 'Reports And Sales';

  @override
  String get systemSettings => 'System Settings';

  @override
  String get changeImage => 'Change Image';

  @override
  String get primaryAdminAccount => 'Primary Admin Account';

  @override
  String get primaryAdminNote =>
      'You can only edit your name, photo, and password. Permissions protect';

  @override
  String get updateProfile => 'Edit profile';

  @override
  String get updateUser => 'Update User';

  @override
  String get editingYourProfile => 'Editing Your Profile';

  @override
  String get selfEditNote =>
      'You can edit your name, username, password, and profile picture. Permissions are protected';
}
