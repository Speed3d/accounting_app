import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en')
  ];

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @homePage.
  ///
  /// In en, this message translates to:
  /// **'Home Page'**
  String get homePage;

  /// No description provided for @users.
  ///
  /// In en, this message translates to:
  /// **'Users'**
  String get users;

  /// No description provided for @suppliers.
  ///
  /// In en, this message translates to:
  /// **'Suppliers'**
  String get suppliers;

  /// No description provided for @products.
  ///
  /// In en, this message translates to:
  /// **'Products'**
  String get products;

  /// No description provided for @employees.
  ///
  /// In en, this message translates to:
  /// **'Employees'**
  String get employees;

  /// No description provided for @customers.
  ///
  /// In en, this message translates to:
  /// **'Customers'**
  String get customers;

  /// No description provided for @reports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get reports;

  /// No description provided for @customization.
  ///
  /// In en, this message translates to:
  /// **'Customization'**
  String get customization;

  /// No description provided for @companyInformation.
  ///
  /// In en, this message translates to:
  /// **'Company Information'**
  String get companyInformation;

  /// No description provided for @changeAppNameAndLogo.
  ///
  /// In en, this message translates to:
  /// **'Change app name and logo'**
  String get changeAppNameAndLogo;

  /// No description provided for @dataManagement.
  ///
  /// In en, this message translates to:
  /// **'Data Management'**
  String get dataManagement;

  /// No description provided for @archiveCenter.
  ///
  /// In en, this message translates to:
  /// **'Archive Center'**
  String get archiveCenter;

  /// No description provided for @restoreArchivedItems.
  ///
  /// In en, this message translates to:
  /// **'Restore archived items'**
  String get restoreArchivedItems;

  /// No description provided for @backupAndRestore.
  ///
  /// In en, this message translates to:
  /// **'Backup and Restore'**
  String get backupAndRestore;

  /// No description provided for @saveAndRestoreAppData.
  ///
  /// In en, this message translates to:
  /// **'Save and restore app data'**
  String get saveAndRestoreAppData;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @aboutTheApp.
  ///
  /// In en, this message translates to:
  /// **'About The App'**
  String get aboutTheApp;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @changeLanguage.
  ///
  /// In en, this message translates to:
  /// **'Change app language'**
  String get changeLanguage;

  /// No description provided for @customersList.
  ///
  /// In en, this message translates to:
  /// **'Customers List'**
  String get customersList;

  /// No description provided for @noActiveCustomers.
  ///
  /// In en, this message translates to:
  /// **'No active customers yet.'**
  String get noActiveCustomers;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @unregistered.
  ///
  /// In en, this message translates to:
  /// **'Unregistered'**
  String get unregistered;

  /// No description provided for @remainingForHim.
  ///
  /// In en, this message translates to:
  /// **'Credit'**
  String get remainingForHim;

  /// No description provided for @remainingOnHim.
  ///
  /// In en, this message translates to:
  /// **'Debt'**
  String get remainingOnHim;

  /// No description provided for @balance.
  ///
  /// In en, this message translates to:
  /// **'Balance'**
  String get balance;

  /// No description provided for @archive.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get archive;

  /// No description provided for @confirmArchive.
  ///
  /// In en, this message translates to:
  /// **'Confirm Archive'**
  String get confirmArchive;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @addEditCustomer.
  ///
  /// In en, this message translates to:
  /// **'Add/Edit Customer'**
  String get addEditCustomer;

  /// No description provided for @customerName.
  ///
  /// In en, this message translates to:
  /// **'Customer Name'**
  String get customerName;

  /// No description provided for @addressOptional.
  ///
  /// In en, this message translates to:
  /// **'Address (Optional)'**
  String get addressOptional;

  /// No description provided for @phoneOptional.
  ///
  /// In en, this message translates to:
  /// **'Phone (Optional)'**
  String get phoneOptional;

  /// No description provided for @fieldRequired.
  ///
  /// In en, this message translates to:
  /// **'Field is required'**
  String get fieldRequired;

  /// No description provided for @customerAddedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Customer added successfully!'**
  String get customerAddedSuccess;

  /// No description provided for @customerUpdatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Customer updated successfully!'**
  String get customerUpdatedSuccess;

  /// No description provided for @chooseImageSource.
  ///
  /// In en, this message translates to:
  /// **'Choose Image Source'**
  String get chooseImageSource;

  /// No description provided for @gallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get gallery;

  /// No description provided for @camera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get camera;

  /// No description provided for @customerDetails.
  ///
  /// In en, this message translates to:
  /// **'Customer Details'**
  String get customerDetails;

  /// No description provided for @purchases.
  ///
  /// In en, this message translates to:
  /// **'Purchases'**
  String get purchases;

  /// No description provided for @payments.
  ///
  /// In en, this message translates to:
  /// **'Payments'**
  String get payments;

  /// No description provided for @noPurchases.
  ///
  /// In en, this message translates to:
  /// **'No purchases recorded.'**
  String get noPurchases;

  /// No description provided for @noPayments.
  ///
  /// In en, this message translates to:
  /// **'No payments recorded.'**
  String get noPayments;

  /// No description provided for @newSaleSuccess.
  ///
  /// In en, this message translates to:
  /// **'New sale recorded successfully!'**
  String get newSaleSuccess;

  /// No description provided for @newPayment.
  ///
  /// In en, this message translates to:
  /// **'New Payment'**
  String get newPayment;

  /// No description provided for @paidAmount.
  ///
  /// In en, this message translates to:
  /// **'Paid Amount'**
  String get paidAmount;

  /// No description provided for @amountRequired.
  ///
  /// In en, this message translates to:
  /// **'Amount is required'**
  String get amountRequired;

  /// No description provided for @enterValidAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid amount greater than zero'**
  String get enterValidAmount;

  /// No description provided for @amountExceedsDebt.
  ///
  /// In en, this message translates to:
  /// **'Amount is greater than the remaining debt'**
  String get amountExceedsDebt;

  /// No description provided for @notesOptional.
  ///
  /// In en, this message translates to:
  /// **'Notes (Optional)'**
  String get notesOptional;

  /// No description provided for @paymentSuccess.
  ///
  /// In en, this message translates to:
  /// **'Payment recorded successfully!'**
  String get paymentSuccess;

  /// No description provided for @returnConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm Return'**
  String get returnConfirmTitle;

  /// No description provided for @returnConfirmContent.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to return this item?\n\"{details}\"\nThe quantity will be returned to stock and the customer\'s account will be adjusted.'**
  String returnConfirmContent(String details);

  /// No description provided for @returnSuccess.
  ///
  /// In en, this message translates to:
  /// **'Item returned successfully!'**
  String get returnSuccess;

  /// No description provided for @errorOccurred.
  ///
  /// In en, this message translates to:
  /// **'An error occurred: {error}'**
  String errorOccurred(String error);

  /// No description provided for @returnItem.
  ///
  /// In en, this message translates to:
  /// **'Return Item'**
  String get returnItem;

  /// No description provided for @saleDetails.
  ///
  /// In en, this message translates to:
  /// **'Sale Details: {productName} (Qty: {quantity})'**
  String saleDetails(String productName, String quantity);

  /// No description provided for @newAdvanceFor.
  ///
  /// In en, this message translates to:
  /// **'New Advance for: {name}'**
  String newAdvanceFor(Object name);

  /// No description provided for @advanceAmount.
  ///
  /// In en, this message translates to:
  /// **'Advance Amount'**
  String get advanceAmount;

  /// No description provided for @advanceDate.
  ///
  /// In en, this message translates to:
  /// **'Advance Date'**
  String get advanceDate;

  /// No description provided for @saveAdvance.
  ///
  /// In en, this message translates to:
  /// **'Save Advance'**
  String get saveAdvance;

  /// No description provided for @advanceAddedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Advance recorded successfully!'**
  String get advanceAddedSuccess;

  /// No description provided for @unpaid.
  ///
  /// In en, this message translates to:
  /// **'Unpaid'**
  String get unpaid;

  /// No description provided for @addEmployee.
  ///
  /// In en, this message translates to:
  /// **'Add Employee'**
  String get addEmployee;

  /// No description provided for @editEmployee.
  ///
  /// In en, this message translates to:
  /// **'Edit Employee'**
  String get editEmployee;

  /// No description provided for @employeeName.
  ///
  /// In en, this message translates to:
  /// **'Employee Full Name'**
  String get employeeName;

  /// No description provided for @employeeNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Employee name is required'**
  String get employeeNameRequired;

  /// No description provided for @jobTitle.
  ///
  /// In en, this message translates to:
  /// **'Job Title'**
  String get jobTitle;

  /// No description provided for @jobTitleRequired.
  ///
  /// In en, this message translates to:
  /// **'Job title is required'**
  String get jobTitleRequired;

  /// No description provided for @baseSalary.
  ///
  /// In en, this message translates to:
  /// **'Base Salary'**
  String get baseSalary;

  /// No description provided for @baseSalaryRequired.
  ///
  /// In en, this message translates to:
  /// **'Base salary is required'**
  String get baseSalaryRequired;

  /// No description provided for @enterValidNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid number'**
  String get enterValidNumber;

  /// No description provided for @hireDate.
  ///
  /// In en, this message translates to:
  /// **'Hire Date'**
  String get hireDate;

  /// No description provided for @employeeAddedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Employee added successfully!'**
  String get employeeAddedSuccess;

  /// No description provided for @employeeUpdatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Employee updated successfully!'**
  String get employeeUpdatedSuccess;

  /// No description provided for @payrollFor.
  ///
  /// In en, this message translates to:
  /// **'Payroll for: {name}'**
  String payrollFor(Object name);

  /// No description provided for @payrollForMonthAndYear.
  ///
  /// In en, this message translates to:
  /// **'Payroll for month and year:'**
  String get payrollForMonthAndYear;

  /// No description provided for @month.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get month;

  /// No description provided for @year.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get year;

  /// No description provided for @payrollAlreadyExists.
  ///
  /// In en, this message translates to:
  /// **'Error: A payroll for this month has already been recorded.'**
  String get payrollAlreadyExists;

  /// No description provided for @payrollSavedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Payroll saved successfully!'**
  String get payrollSavedSuccess;

  /// No description provided for @bonuses.
  ///
  /// In en, this message translates to:
  /// **'Bonuses (+)'**
  String get bonuses;

  /// No description provided for @deductions.
  ///
  /// In en, this message translates to:
  /// **'Deductions (-)'**
  String get deductions;

  /// No description provided for @advanceRepayment.
  ///
  /// In en, this message translates to:
  /// **'Advance Repayment (-)'**
  String get advanceRepayment;

  /// No description provided for @currentBalanceOnEmployee.
  ///
  /// In en, this message translates to:
  /// **'Current balance on employee: {balance}'**
  String currentBalanceOnEmployee(Object balance);

  /// No description provided for @enterZeroIfNotRepaying.
  ///
  /// In en, this message translates to:
  /// **'Enter 0 if there is no repayment'**
  String get enterZeroIfNotRepaying;

  /// No description provided for @repaymentExceedsBalance.
  ///
  /// In en, this message translates to:
  /// **'Amount is greater than the employee\'s advance balance'**
  String get repaymentExceedsBalance;

  /// No description provided for @paymentDate.
  ///
  /// In en, this message translates to:
  /// **'Payment Date'**
  String get paymentDate;

  /// No description provided for @saveAndPaySalary.
  ///
  /// In en, this message translates to:
  /// **'Save and Pay Salary'**
  String get saveAndPaySalary;

  /// No description provided for @netSalaryDue.
  ///
  /// In en, this message translates to:
  /// **'Net Salary Due'**
  String get netSalaryDue;

  /// No description provided for @fieldRequiredEnterZero.
  ///
  /// In en, this message translates to:
  /// **'Field is required, enter 0 for zero value'**
  String get fieldRequiredEnterZero;

  /// No description provided for @payrollHistory.
  ///
  /// In en, this message translates to:
  /// **'Payroll History'**
  String get payrollHistory;

  /// No description provided for @advancesHistory.
  ///
  /// In en, this message translates to:
  /// **'Advances History'**
  String get advancesHistory;

  /// No description provided for @noPayrolls.
  ///
  /// In en, this message translates to:
  /// **'No payrolls recorded.'**
  String get noPayrolls;

  /// No description provided for @noAdvances.
  ///
  /// In en, this message translates to:
  /// **'No advances recorded.'**
  String get noAdvances;

  /// No description provided for @payrollDetailsFor.
  ///
  /// In en, this message translates to:
  /// **'Payroll Details for {month}'**
  String payrollDetailsFor(Object month);

  /// No description provided for @paidOn.
  ///
  /// In en, this message translates to:
  /// **'Paid on: {date}'**
  String paidOn(Object date);

  /// No description provided for @payrollOfMonth.
  ///
  /// In en, this message translates to:
  /// **'Payroll for {month} {year}'**
  String payrollOfMonth(Object month, Object year);

  /// No description provided for @advanceAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Advance Amount: {amount}'**
  String advanceAmountLabel(Object amount);

  /// No description provided for @advanceDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Advance Date: {date}'**
  String advanceDateLabel(Object date);

  /// No description provided for @fullyPaid.
  ///
  /// In en, this message translates to:
  /// **'Fully Paid'**
  String get fullyPaid;

  /// No description provided for @employeesList.
  ///
  /// In en, this message translates to:
  /// **'Employees List'**
  String get employeesList;

  /// No description provided for @noEmployees.
  ///
  /// In en, this message translates to:
  /// **'No employees currently. Press + to add the first employee.'**
  String get noEmployees;

  /// No description provided for @jobTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Job Title: {title}'**
  String jobTitleLabel(Object title);

  /// No description provided for @baseSalaryLabel.
  ///
  /// In en, this message translates to:
  /// **'Base Salary: {salary}'**
  String baseSalaryLabel(Object salary);

  /// No description provided for @advancesBalanceLabel.
  ///
  /// In en, this message translates to:
  /// **'Advances Balance: {balance}'**
  String advancesBalanceLabel(Object balance);

  /// No description provided for @suppliersList.
  ///
  /// In en, this message translates to:
  /// **'Suppliers List'**
  String get suppliersList;

  /// No description provided for @noActiveSuppliers.
  ///
  /// In en, this message translates to:
  /// **'No active suppliers.'**
  String get noActiveSuppliers;

  /// No description provided for @type.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get type;

  /// No description provided for @individual.
  ///
  /// In en, this message translates to:
  /// **'Individual'**
  String get individual;

  /// No description provided for @partner.
  ///
  /// In en, this message translates to:
  /// **'Partner'**
  String get partner;

  /// No description provided for @addSupplier.
  ///
  /// In en, this message translates to:
  /// **'Add New Supplier'**
  String get addSupplier;

  /// No description provided for @editSupplier.
  ///
  /// In en, this message translates to:
  /// **'Edit Supplier'**
  String get editSupplier;

  /// No description provided for @supplierName.
  ///
  /// In en, this message translates to:
  /// **'Supplier Name'**
  String get supplierName;

  /// No description provided for @supplierNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Supplier name is required'**
  String get supplierNameRequired;

  /// No description provided for @supplierType.
  ///
  /// In en, this message translates to:
  /// **'Supplier Type'**
  String get supplierType;

  /// No description provided for @partnership.
  ///
  /// In en, this message translates to:
  /// **'Partnership'**
  String get partnership;

  /// No description provided for @partners.
  ///
  /// In en, this message translates to:
  /// **'Partners'**
  String get partners;

  /// No description provided for @addPartner.
  ///
  /// In en, this message translates to:
  /// **'Add Partner'**
  String get addPartner;

  /// No description provided for @atLeastOnePartnerRequired.
  ///
  /// In en, this message translates to:
  /// **'At least one partner must be added for a partnership type.'**
  String get atLeastOnePartnerRequired;

  /// No description provided for @partnerShareTotalExceeds100.
  ///
  /// In en, this message translates to:
  /// **'Error: Total partner shares ({total}%) exceeds 100%.'**
  String partnerShareTotalExceeds100(Object total);

  /// No description provided for @supplierAddedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Supplier added successfully!'**
  String get supplierAddedSuccess;

  /// No description provided for @supplierUpdatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Supplier updated successfully!'**
  String get supplierUpdatedSuccess;

  /// No description provided for @addNewPartner.
  ///
  /// In en, this message translates to:
  /// **'Add New Partner'**
  String get addNewPartner;

  /// No description provided for @partnerName.
  ///
  /// In en, this message translates to:
  /// **'Partner Name'**
  String get partnerName;

  /// No description provided for @partnerNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Partner name is required'**
  String get partnerNameRequired;

  /// No description provided for @sharePercentage.
  ///
  /// In en, this message translates to:
  /// **'Share Percentage (%)'**
  String get sharePercentage;

  /// No description provided for @percentageMustBeBetween1And100.
  ///
  /// In en, this message translates to:
  /// **'Percentage must be between 1 and 100'**
  String get percentageMustBeBetween1And100;

  /// No description provided for @shareTotalExceeds100.
  ///
  /// In en, this message translates to:
  /// **'Error: Total partner shares cannot exceed 100%.'**
  String get shareTotalExceeds100;

  /// No description provided for @percentageLabel.
  ///
  /// In en, this message translates to:
  /// **'Percentage: {percentage}%'**
  String percentageLabel(Object percentage);

  /// No description provided for @typeLabel.
  ///
  /// In en, this message translates to:
  /// **'Type: {type}'**
  String typeLabel(Object type);

  /// No description provided for @cannotArchiveSupplierWithActiveProducts.
  ///
  /// In en, this message translates to:
  /// **'This supplier cannot be archived because they are linked to active products.'**
  String get cannotArchiveSupplierWithActiveProducts;

  /// No description provided for @archiveSupplierConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to archive the supplier \"{name}\"? They will be hidden from lists.'**
  String archiveSupplierConfirmation(Object name);

  /// No description provided for @archiveSupplierLog.
  ///
  /// In en, this message translates to:
  /// **'Archive Supplier: {name}'**
  String archiveSupplierLog(Object name);

  /// No description provided for @addUser.
  ///
  /// In en, this message translates to:
  /// **'Add New User'**
  String get addUser;

  /// No description provided for @editUser.
  ///
  /// In en, this message translates to:
  /// **'Edit User'**
  String get editUser;

  /// No description provided for @passwordRequiredForNewUser.
  ///
  /// In en, this message translates to:
  /// **'Password is required for a new user'**
  String get passwordRequiredForNewUser;

  /// No description provided for @userAddedSuccess.
  ///
  /// In en, this message translates to:
  /// **'User added successfully!'**
  String get userAddedSuccess;

  /// No description provided for @userUpdatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'User updated successfully!'**
  String get userUpdatedSuccess;

  /// No description provided for @usernameAlreadyExists.
  ///
  /// In en, this message translates to:
  /// **'This username already exists. Please choose another one.'**
  String get usernameAlreadyExists;

  /// No description provided for @passwordHint.
  ///
  /// In en, this message translates to:
  /// **'Leave blank to keep unchanged'**
  String get passwordHint;

  /// No description provided for @userPermissions.
  ///
  /// In en, this message translates to:
  /// **'User Permissions'**
  String get userPermissions;

  /// No description provided for @adminPermission.
  ///
  /// In en, this message translates to:
  /// **'Full Admin Privileges'**
  String get adminPermission;

  /// No description provided for @adminPermissionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Grants all permissions and overrides any other selection.'**
  String get adminPermissionSubtitle;

  /// No description provided for @viewSuppliers.
  ///
  /// In en, this message translates to:
  /// **'View Suppliers'**
  String get viewSuppliers;

  /// No description provided for @editSuppliers.
  ///
  /// In en, this message translates to:
  /// **'Edit Suppliers'**
  String get editSuppliers;

  /// No description provided for @viewProducts.
  ///
  /// In en, this message translates to:
  /// **'View Products'**
  String get viewProducts;

  /// No description provided for @editProducts.
  ///
  /// In en, this message translates to:
  /// **'Edit Products'**
  String get editProducts;

  /// No description provided for @viewCustomers.
  ///
  /// In en, this message translates to:
  /// **'View Customers'**
  String get viewCustomers;

  /// No description provided for @editCustomers.
  ///
  /// In en, this message translates to:
  /// **'Edit Customers'**
  String get editCustomers;

  /// No description provided for @viewReports.
  ///
  /// In en, this message translates to:
  /// **'View Reports'**
  String get viewReports;

  /// No description provided for @viewEmployeesReport.
  ///
  /// In en, this message translates to:
  /// **'View Employees Report'**
  String get viewEmployeesReport;

  /// No description provided for @viewSettings.
  ///
  /// In en, this message translates to:
  /// **'View Settings'**
  String get viewSettings;

  /// No description provided for @manageEmployees.
  ///
  /// In en, this message translates to:
  /// **'Manage Employees'**
  String get manageEmployees;

  /// No description provided for @manageExpenses.
  ///
  /// In en, this message translates to:
  /// **'Manage General Expenses'**
  String get manageExpenses;

  /// No description provided for @viewCashSales.
  ///
  /// In en, this message translates to:
  /// **'View Cash Sales Reports'**
  String get viewCashSales;

  /// No description provided for @usersList.
  ///
  /// In en, this message translates to:
  /// **'Users List'**
  String get usersList;

  /// No description provided for @noUsers.
  ///
  /// In en, this message translates to:
  /// **'No users yet.'**
  String get noUsers;

  /// No description provided for @you.
  ///
  /// In en, this message translates to:
  /// **'(You)'**
  String get you;

  /// No description provided for @admin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get admin;

  /// No description provided for @customPermissionsUser.
  ///
  /// In en, this message translates to:
  /// **'User with custom permissions'**
  String get customPermissionsUser;

  /// No description provided for @usernameLabel.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get usernameLabel;

  /// No description provided for @cannotEditOwnAccount.
  ///
  /// In en, this message translates to:
  /// **'You cannot edit your own account from here. Use the settings screen instead.'**
  String get cannotEditOwnAccount;

  /// No description provided for @cannotDeleteOwnAccount.
  ///
  /// In en, this message translates to:
  /// **'You cannot delete your own account.'**
  String get cannotDeleteOwnAccount;

  /// No description provided for @cannotDeleteLastUser.
  ///
  /// In en, this message translates to:
  /// **'The last user in the system cannot be deleted.'**
  String get cannotDeleteLastUser;

  /// No description provided for @deleteUserConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete the user \"{name}\"? This action cannot be undone.'**
  String deleteUserConfirmation(String name);

  /// No description provided for @deleteUserLog.
  ///
  /// In en, this message translates to:
  /// **'Delete user: {name}'**
  String deleteUserLog(String name);

  /// No description provided for @productsList.
  ///
  /// In en, this message translates to:
  /// **'Products List'**
  String get productsList;

  /// No description provided for @noActiveProducts.
  ///
  /// In en, this message translates to:
  /// **'No active products in stock.'**
  String get noActiveProducts;

  /// No description provided for @searchForProduct.
  ///
  /// In en, this message translates to:
  /// **'Search for a product...'**
  String get searchForProduct;

  /// No description provided for @noMatchingResults.
  ///
  /// In en, this message translates to:
  /// **'No matching results found.'**
  String get noMatchingResults;

  /// No description provided for @supplier.
  ///
  /// In en, this message translates to:
  /// **'Supplier'**
  String get supplier;

  /// No description provided for @quantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get quantity;

  /// No description provided for @sellingPrice.
  ///
  /// In en, this message translates to:
  /// **'Selling Price'**
  String get sellingPrice;

  /// No description provided for @cannotArchiveSoldProduct.
  ///
  /// In en, this message translates to:
  /// **'This product cannot be archived because it is linked to previous sales.'**
  String get cannotArchiveSoldProduct;

  /// No description provided for @archiveProductConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to archive the product \"{name}\"?'**
  String archiveProductConfirmation(Object name);

  /// No description provided for @supplierLabel.
  ///
  /// In en, this message translates to:
  /// **'Supplier: {name}'**
  String supplierLabel(Object name);

  /// No description provided for @quantityLabel.
  ///
  /// In en, this message translates to:
  /// **'Quantity: {qty}'**
  String quantityLabel(Object qty);

  /// No description provided for @undefined.
  ///
  /// In en, this message translates to:
  /// **'Undefined'**
  String get undefined;

  /// No description provided for @sellingPriceLabel.
  ///
  /// In en, this message translates to:
  /// **'Selling Price: {price}'**
  String sellingPriceLabel(Object price);

  /// No description provided for @addProduct.
  ///
  /// In en, this message translates to:
  /// **'Add New Product'**
  String get addProduct;

  /// No description provided for @editProduct.
  ///
  /// In en, this message translates to:
  /// **'Edit Product'**
  String get editProduct;

  /// No description provided for @pleaseSelectSupplier.
  ///
  /// In en, this message translates to:
  /// **'Please select a supplier'**
  String get pleaseSelectSupplier;

  /// No description provided for @productAddedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Product added successfully!'**
  String get productAddedSuccess;

  /// No description provided for @productUpdatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Product updated successfully!'**
  String get productUpdatedSuccess;

  /// No description provided for @productName.
  ///
  /// In en, this message translates to:
  /// **'Product Name'**
  String get productName;

  /// No description provided for @productNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Product name is required'**
  String get productNameRequired;

  /// No description provided for @productDetailsOptional.
  ///
  /// In en, this message translates to:
  /// **'Product Details (Optional)'**
  String get productDetailsOptional;

  /// No description provided for @costPrice.
  ///
  /// In en, this message translates to:
  /// **'Cost Price'**
  String get costPrice;

  /// No description provided for @fieldCannotBeNegative.
  ///
  /// In en, this message translates to:
  /// **'Field cannot be negative'**
  String get fieldCannotBeNegative;

  /// No description provided for @selectSupplier.
  ///
  /// In en, this message translates to:
  /// **'Select a supplier'**
  String get selectSupplier;

  /// No description provided for @errorLoadingSuppliers.
  ///
  /// In en, this message translates to:
  /// **'Error loading suppliers.'**
  String get errorLoadingSuppliers;

  /// No description provided for @noSuppliersAddOneFirst.
  ///
  /// In en, this message translates to:
  /// **'No suppliers found. Please add a supplier first.'**
  String get noSuppliersAddOneFirst;

  /// No description provided for @barcode.
  ///
  /// In en, this message translates to:
  /// **'Barcode'**
  String get barcode;

  /// No description provided for @barcodeOptional.
  ///
  /// In en, this message translates to:
  /// **'Barcode (Optional)'**
  String get barcodeOptional;

  /// No description provided for @scanBarcode.
  ///
  /// In en, this message translates to:
  /// **'Scan Barcode'**
  String get scanBarcode;

  /// No description provided for @cameraPermissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Camera permission is required to scan barcodes.'**
  String get cameraPermissionRequired;

  /// No description provided for @openSettings.
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get openSettings;

  /// No description provided for @barcodeAlreadyExists.
  ///
  /// In en, this message translates to:
  /// **'Error: This barcode is already assigned to another product.'**
  String get barcodeAlreadyExists;

  /// No description provided for @productUpdatedWithBarcodeLog.
  ///
  /// In en, this message translates to:
  /// **'Update product with barcode: {name}'**
  String productUpdatedWithBarcodeLog(Object name);

  /// No description provided for @productAddedWithBarcodeLog.
  ///
  /// In en, this message translates to:
  /// **'Add new product with barcode: {name}'**
  String productAddedWithBarcodeLog(Object name);

  /// Message shown when a scanned barcode does not match any product in the database
  ///
  /// In en, this message translates to:
  /// **'Product not found or inactive'**
  String get productNotFound;

  /// Text on the barcode scanning button on the new sale screen
  ///
  /// In en, this message translates to:
  /// **'Scan Barcode to Sell'**
  String get scanBarcodeToSell;

  /// No description provided for @addWithProductName.
  ///
  /// In en, this message translates to:
  /// **'Add \"{productName}\"'**
  String addWithProductName(String productName);

  /// No description provided for @barcodeExistsError.
  ///
  /// In en, this message translates to:
  /// **'This barcode is already registered for another product.'**
  String get barcodeExistsError;

  /// No description provided for @reportsHub.
  ///
  /// In en, this message translates to:
  /// **'Reports Hub'**
  String get reportsHub;

  /// No description provided for @profitReport.
  ///
  /// In en, this message translates to:
  /// **'Profit Report'**
  String get profitReport;

  /// No description provided for @profitReportDesc.
  ///
  /// In en, this message translates to:
  /// **'View net profit from all sales'**
  String get profitReportDesc;

  /// No description provided for @supplierProfitReport.
  ///
  /// In en, this message translates to:
  /// **'Supplier & Partner Profit Report'**
  String get supplierProfitReport;

  /// No description provided for @supplierProfitReportDesc.
  ///
  /// In en, this message translates to:
  /// **'View profits grouped by each supplier'**
  String get supplierProfitReportDesc;

  /// No description provided for @employeesReport.
  ///
  /// In en, this message translates to:
  /// **'Employees Report'**
  String get employeesReport;

  /// No description provided for @employeesReportDesc.
  ///
  /// In en, this message translates to:
  /// **'Summary of salaries, advances, and employee statements'**
  String get employeesReportDesc;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @username.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get username;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @loginTo.
  ///
  /// In en, this message translates to:
  /// **'Login to'**
  String get loginTo;

  /// No description provided for @accountingProgram.
  ///
  /// In en, this message translates to:
  /// **'Accounting Program'**
  String get accountingProgram;

  /// No description provided for @invalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'Incorrect username or password.'**
  String get invalidCredentials;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @success.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// No description provided for @backupStarted.
  ///
  /// In en, this message translates to:
  /// **'Backup sharing started.'**
  String get backupStarted;

  /// No description provided for @backupFailed.
  ///
  /// In en, this message translates to:
  /// **'Backup failed: {error}'**
  String backupFailed(Object error);

  /// No description provided for @restoreConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm Restore'**
  String get restoreConfirmTitle;

  /// No description provided for @restoreConfirmContent.
  ///
  /// In en, this message translates to:
  /// **'Are you sure? All your current data will be replaced by the data in the backup. This action cannot be undone.'**
  String get restoreConfirmContent;

  /// No description provided for @restore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get restore;

  /// No description provided for @restoreSuccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Restore Successful'**
  String get restoreSuccessTitle;

  /// No description provided for @restoreSuccessContent.
  ///
  /// In en, this message translates to:
  /// **'Data restored successfully. Please restart the app to apply changes.'**
  String get restoreSuccessContent;

  /// No description provided for @restoreFailed.
  ///
  /// In en, this message translates to:
  /// **'Restore failed: {error}'**
  String restoreFailed(Object error);

  /// No description provided for @createBackupTitle.
  ///
  /// In en, this message translates to:
  /// **'Create & Share Backup'**
  String get createBackupTitle;

  /// No description provided for @createBackupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Save an encrypted copy of your data and share it to a safe place.'**
  String get createBackupSubtitle;

  /// No description provided for @restoreFromFileTitle.
  ///
  /// In en, this message translates to:
  /// **'Restore Data from File'**
  String get restoreFromFileTitle;

  /// No description provided for @restoreFromFileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Warning: This will replace all current data.'**
  String get restoreFromFileSubtitle;

  /// No description provided for @backupTip.
  ///
  /// In en, this message translates to:
  /// **'Tip: Periodically back up your data off-device (to Google Drive or email) to protect it from loss or damage.'**
  String get backupTip;

  /// No description provided for @companyOrShopName.
  ///
  /// In en, this message translates to:
  /// **'Company or Shop Name'**
  String get companyOrShopName;

  /// No description provided for @companyDescOptional.
  ///
  /// In en, this message translates to:
  /// **'Company Description (Optional)'**
  String get companyDescOptional;

  /// No description provided for @companyDescHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., business activity, short address...'**
  String get companyDescHint;

  /// No description provided for @companyInfoHint.
  ///
  /// In en, this message translates to:
  /// **'This name and logo will appear on the splash screen and in reports.'**
  String get companyInfoHint;

  /// No description provided for @infoSavedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Information saved successfully!'**
  String get infoSavedSuccess;

  /// No description provided for @errorPickingImage.
  ///
  /// In en, this message translates to:
  /// **'Error picking image: {error}'**
  String errorPickingImage(String error);

  /// No description provided for @archivedCustomer.
  ///
  /// In en, this message translates to:
  /// **'Archived Customer'**
  String get archivedCustomer;

  /// No description provided for @archivedSupplier.
  ///
  /// In en, this message translates to:
  /// **'Archived Supplier'**
  String get archivedSupplier;

  /// No description provided for @archivedProduct.
  ///
  /// In en, this message translates to:
  /// **'Archived Product | Supplier: {supplierName}'**
  String archivedProduct(Object supplierName);

  /// No description provided for @unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// No description provided for @itemRestoredSuccess.
  ///
  /// In en, this message translates to:
  /// **'Item \"{name}\" restored successfully!'**
  String itemRestoredSuccess(Object name);

  /// No description provided for @noArchivedItems.
  ///
  /// In en, this message translates to:
  /// **'No archived items.'**
  String get noArchivedItems;

  /// No description provided for @setupAdminAccount.
  ///
  /// In en, this message translates to:
  /// **'Setup Admin Account'**
  String get setupAdminAccount;

  /// No description provided for @welcomeSetup.
  ///
  /// In en, this message translates to:
  /// **'Welcome! This is a one-time setup. This account will have all permissions.'**
  String get welcomeSetup;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// No description provided for @fullNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Full name is required'**
  String get fullNameRequired;

  /// No description provided for @usernameForLogin.
  ///
  /// In en, this message translates to:
  /// **'Username (for login)'**
  String get usernameForLogin;

  /// No description provided for @usernameRequired.
  ///
  /// In en, this message translates to:
  /// **'Username is required'**
  String get usernameRequired;

  /// No description provided for @chooseStrongPassword.
  ///
  /// In en, this message translates to:
  /// **'Choose a strong password'**
  String get chooseStrongPassword;

  /// No description provided for @passwordRequired.
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get passwordRequired;

  /// No description provided for @passwordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 4 characters'**
  String get passwordTooShort;

  /// No description provided for @createAdminAndStart.
  ///
  /// In en, this message translates to:
  /// **'Create Admin & Start'**
  String get createAdminAndStart;

  /// No description provided for @adminCreatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Admin account created successfully! You can now log in.'**
  String get adminCreatedSuccess;

  /// No description provided for @usernameExists.
  ///
  /// In en, this message translates to:
  /// **'This username already exists. Please choose another one.'**
  String get usernameExists;

  /// No description provided for @unexpectedError.
  ///
  /// In en, this message translates to:
  /// **'An unexpected error occurred: {error}'**
  String unexpectedError(Object error);

  /// No description provided for @pleaseEnterUsername.
  ///
  /// In en, this message translates to:
  /// **'Please enter username'**
  String get pleaseEnterUsername;

  /// No description provided for @pleaseEnterPassword.
  ///
  /// In en, this message translates to:
  /// **'Please enter password'**
  String get pleaseEnterPassword;

  /// No description provided for @addCustomer.
  ///
  /// In en, this message translates to:
  /// **'Add Customer'**
  String get addCustomer;

  /// No description provided for @editCustomer.
  ///
  /// In en, this message translates to:
  /// **'Edit Customer'**
  String get editCustomer;

  /// No description provided for @customerNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Customer name is required'**
  String get customerNameRequired;

  /// No description provided for @imageSource.
  ///
  /// In en, this message translates to:
  /// **'Image Source'**
  String get imageSource;

  /// No description provided for @cannotArchiveCustomerWithDebt.
  ///
  /// In en, this message translates to:
  /// **'Cannot archive a customer with remaining debt.'**
  String get cannotArchiveCustomerWithDebt;

  /// No description provided for @archiveConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm Archive'**
  String get archiveConfirmTitle;

  /// No description provided for @archiveConfirmContent.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to archive the customer \"{name}\"?'**
  String archiveConfirmContent(Object name);

  /// No description provided for @chooseProducts.
  ///
  /// In en, this message translates to:
  /// **'Choose Products'**
  String get chooseProducts;

  /// No description provided for @reviewCart.
  ///
  /// In en, this message translates to:
  /// **'Review Cart'**
  String get reviewCart;

  /// No description provided for @noProductsInStock.
  ///
  /// In en, this message translates to:
  /// **'No products in stock.'**
  String get noProductsInStock;

  /// No description provided for @available.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get available;

  /// No description provided for @price.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get price;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @quantityExceedsStock.
  ///
  /// In en, this message translates to:
  /// **'Requested quantity is more than available in stock!'**
  String get quantityExceedsStock;

  /// No description provided for @cartIsEmpty.
  ///
  /// In en, this message translates to:
  /// **'Shopping cart is empty!'**
  String get cartIsEmpty;

  /// No description provided for @product.
  ///
  /// In en, this message translates to:
  /// **'Product'**
  String get product;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @finalTotal.
  ///
  /// In en, this message translates to:
  /// **'Final Total'**
  String get finalTotal;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @itemsCount.
  ///
  /// In en, this message translates to:
  /// **'Items: {count}'**
  String itemsCount(String count);

  /// No description provided for @totalSalariesPaid.
  ///
  /// In en, this message translates to:
  /// **'Total Salaries Paid'**
  String get totalSalariesPaid;

  /// No description provided for @totalAdvancesBalance.
  ///
  /// In en, this message translates to:
  /// **'Total Advances Balance'**
  String get totalAdvancesBalance;

  /// No description provided for @activeEmployeesCount.
  ///
  /// In en, this message translates to:
  /// **'Active Employees Count'**
  String get activeEmployeesCount;

  /// No description provided for @employeesStatement.
  ///
  /// In en, this message translates to:
  /// **'Employees Statement'**
  String get employeesStatement;

  /// No description provided for @noEmployeesToDisplay.
  ///
  /// In en, this message translates to:
  /// **'No employees to display.'**
  String get noEmployeesToDisplay;

  /// No description provided for @salaryLabel.
  ///
  /// In en, this message translates to:
  /// **'Salary: {salary}'**
  String salaryLabel(Object salary);

  /// No description provided for @totalNetProfit.
  ///
  /// In en, this message translates to:
  /// **'Total Net Profit'**
  String get totalNetProfit;

  /// No description provided for @salesDetails.
  ///
  /// In en, this message translates to:
  /// **'Sales Details'**
  String get salesDetails;

  /// No description provided for @loadingDetails.
  ///
  /// In en, this message translates to:
  /// **'Loading details...'**
  String get loadingDetails;

  /// No description provided for @noSalesRecorded.
  ///
  /// In en, this message translates to:
  /// **'No sales recorded to display.'**
  String get noSalesRecorded;

  /// No description provided for @customerLabel.
  ///
  /// In en, this message translates to:
  /// **'Customer: {name}'**
  String customerLabel(String name);

  /// No description provided for @dateLabel.
  ///
  /// In en, this message translates to:
  /// **'Date: {date}'**
  String dateLabel(String date);

  /// No description provided for @profitLabel.
  ///
  /// In en, this message translates to:
  /// **'Profit: {profit}'**
  String profitLabel(String profit);

  /// No description provided for @saleLabel.
  ///
  /// In en, this message translates to:
  /// **'Sale: {sale}'**
  String saleLabel(String sale);

  /// No description provided for @generalProfitReport.
  ///
  /// In en, this message translates to:
  /// **'General Profit Report'**
  String get generalProfitReport;

  /// No description provided for @generalProfitReportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'View summary of profits, expenses, and net profit'**
  String get generalProfitReportSubtitle;

  /// No description provided for @supplierProfitReportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'View profits grouped by supplier and partner share distribution'**
  String get supplierProfitReportSubtitle;

  /// No description provided for @cashSalesHistory.
  ///
  /// In en, this message translates to:
  /// **'Cash Sales History'**
  String get cashSalesHistory;

  /// No description provided for @cashSalesHistorySubtitle.
  ///
  /// In en, this message translates to:
  /// **'View and manage direct sale invoices'**
  String get cashSalesHistorySubtitle;

  /// No description provided for @cashFlowReport.
  ///
  /// In en, this message translates to:
  /// **'Cash Receipts Report'**
  String get cashFlowReport;

  /// No description provided for @cashFlowReportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'View cash sales and customer debt payments'**
  String get cashFlowReportSubtitle;

  /// No description provided for @expensesLog.
  ///
  /// In en, this message translates to:
  /// **'General Expenses Log'**
  String get expensesLog;

  /// No description provided for @expensesLogSubtitle.
  ///
  /// In en, this message translates to:
  /// **'View and record operational expenses'**
  String get expensesLogSubtitle;

  /// No description provided for @employeesAndSalariesReport.
  ///
  /// In en, this message translates to:
  /// **'Employees & Salaries Report'**
  String get employeesAndSalariesReport;

  /// No description provided for @employeesAndSalariesReportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'View summary of salaries, advances, and employee statements'**
  String get employeesAndSalariesReportSubtitle;

  /// No description provided for @noProfitsRecorded.
  ///
  /// In en, this message translates to:
  /// **'No profits recorded to display.'**
  String get noProfitsRecorded;

  /// No description provided for @partnersLabel.
  ///
  /// In en, this message translates to:
  /// **'Partners: {names}'**
  String partnersLabel(String names);

  /// No description provided for @netProfitLabel.
  ///
  /// In en, this message translates to:
  /// **'Net Profit: {amount}'**
  String netProfitLabel(String amount);

  /// No description provided for @selectDateRange.
  ///
  /// In en, this message translates to:
  /// **'Select Date Range'**
  String get selectDateRange;

  /// No description provided for @totalCashSales.
  ///
  /// In en, this message translates to:
  /// **'Total Cash Sales'**
  String get totalCashSales;

  /// No description provided for @totalDebtPayments.
  ///
  /// In en, this message translates to:
  /// **'Total Debt Payments'**
  String get totalDebtPayments;

  /// No description provided for @totalCashInflow.
  ///
  /// In en, this message translates to:
  /// **'Total Cash Inflow'**
  String get totalCashInflow;

  /// No description provided for @showDetails.
  ///
  /// In en, this message translates to:
  /// **'Show Details'**
  String get showDetails;

  /// No description provided for @hideDetails.
  ///
  /// In en, this message translates to:
  /// **'Hide Details'**
  String get hideDetails;

  /// No description provided for @noTransactions.
  ///
  /// In en, this message translates to:
  /// **'No cash transactions in this period.'**
  String get noTransactions;

  /// No description provided for @cashSaleDescription.
  ///
  /// In en, this message translates to:
  /// **'Direct Cash Sale (Invoice #{id})'**
  String cashSaleDescription(String id);

  /// No description provided for @debtPaymentDescription.
  ///
  /// In en, this message translates to:
  /// **'Payment from customer: {name}'**
  String debtPaymentDescription(String name);

  /// No description provided for @recordWithdrawalFor.
  ///
  /// In en, this message translates to:
  /// **'Record Withdrawal for: {name}'**
  String recordWithdrawalFor(String name);

  /// No description provided for @availableNetProfit.
  ///
  /// In en, this message translates to:
  /// **'Available Net Profit for Distribution: {amount}'**
  String availableNetProfit(String amount);

  /// No description provided for @withdrawnAmount.
  ///
  /// In en, this message translates to:
  /// **'Withdrawn Amount'**
  String get withdrawnAmount;

  /// No description provided for @amountExceedsProfit.
  ///
  /// In en, this message translates to:
  /// **'Amount exceeds available profit'**
  String get amountExceedsProfit;

  /// No description provided for @withdrawalSuccess.
  ///
  /// In en, this message translates to:
  /// **'Withdrawal recorded successfully'**
  String get withdrawalSuccess;

  /// No description provided for @totalProfitFromSupplier.
  ///
  /// In en, this message translates to:
  /// **'Total Profit from Supplier:'**
  String get totalProfitFromSupplier;

  /// No description provided for @totalWithdrawals.
  ///
  /// In en, this message translates to:
  /// **'Total Withdrawals:'**
  String get totalWithdrawals;

  /// No description provided for @remainingNetProfit.
  ///
  /// In en, this message translates to:
  /// **'Remaining Net Profit:'**
  String get remainingNetProfit;

  /// No description provided for @partnersProfitDistribution.
  ///
  /// In en, this message translates to:
  /// **'Partners\' Profit Distribution'**
  String get partnersProfitDistribution;

  /// No description provided for @partnerShare.
  ///
  /// In en, this message translates to:
  /// **'Share of net profit: {amount}'**
  String partnerShare(String amount);

  /// No description provided for @withdraw.
  ///
  /// In en, this message translates to:
  /// **'Withdraw'**
  String get withdraw;

  /// No description provided for @recordGeneralWithdrawal.
  ///
  /// In en, this message translates to:
  /// **'Record General Withdrawal'**
  String get recordGeneralWithdrawal;

  /// No description provided for @withdrawalsHistory.
  ///
  /// In en, this message translates to:
  /// **'Withdrawals History'**
  String get withdrawalsHistory;

  /// No description provided for @noWithdrawals.
  ///
  /// In en, this message translates to:
  /// **'No withdrawals recorded.'**
  String get noWithdrawals;

  /// No description provided for @withdrawalAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount: {amount}'**
  String withdrawalAmountLabel(String amount);

  /// No description provided for @withdrawalForLabel.
  ///
  /// In en, this message translates to:
  /// **'For: {name}'**
  String withdrawalForLabel(String name);

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @noDataToShow.
  ///
  /// In en, this message translates to:
  /// **'No data to display.'**
  String get noDataToShow;

  /// No description provided for @showSalesDetails.
  ///
  /// In en, this message translates to:
  /// **'Show Sales Details'**
  String get showSalesDetails;

  /// No description provided for @hideSalesDetails.
  ///
  /// In en, this message translates to:
  /// **'Hide Sales Details'**
  String get hideSalesDetails;

  /// No description provided for @grossProfitFromSales.
  ///
  /// In en, this message translates to:
  /// **'Gross Profit from Sales'**
  String get grossProfitFromSales;

  /// No description provided for @totalGeneralExpenses.
  ///
  /// In en, this message translates to:
  /// **'(-) Total General Expenses'**
  String get totalGeneralExpenses;

  /// No description provided for @totalProfitWithdrawals.
  ///
  /// In en, this message translates to:
  /// **'(-) Total Profit Withdrawals'**
  String get totalProfitWithdrawals;

  /// No description provided for @netProfit.
  ///
  /// In en, this message translates to:
  /// **'Final Net Profit'**
  String get netProfit;

  /// No description provided for @totalProfitFromThisSupplier.
  ///
  /// In en, this message translates to:
  /// **'Total profit from this supplier'**
  String get totalProfitFromThisSupplier;

  /// No description provided for @noPartnersForThisSupplier.
  ///
  /// In en, this message translates to:
  /// **'No partners registered for this supplier.'**
  String get noPartnersForThisSupplier;

  /// No description provided for @noSalesForThisSupplier.
  ///
  /// In en, this message translates to:
  /// **'No sales for this supplier.'**
  String get noSalesForThisSupplier;

  /// No description provided for @searchByInvoiceNumber.
  ///
  /// In en, this message translates to:
  /// **'Search by invoice number...'**
  String get searchByInvoiceNumber;

  /// No description provided for @showInvoices.
  ///
  /// In en, this message translates to:
  /// **'Show Invoices'**
  String get showInvoices;

  /// No description provided for @hideInvoices.
  ///
  /// In en, this message translates to:
  /// **'Hide Invoices'**
  String get hideInvoices;

  /// No description provided for @noCashInvoices.
  ///
  /// In en, this message translates to:
  /// **'No cash sale invoices recorded.'**
  String get noCashInvoices;

  /// No description provided for @invoiceNo.
  ///
  /// In en, this message translates to:
  /// **'Invoice No: {id}'**
  String invoiceNo(String id);

  /// No description provided for @modified.
  ///
  /// In en, this message translates to:
  /// **'Modified'**
  String get modified;

  /// No description provided for @voided.
  ///
  /// In en, this message translates to:
  /// **'Voided'**
  String get voided;

  /// No description provided for @confirmVoidTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm Invoice Void'**
  String get confirmVoidTitle;

  /// No description provided for @confirmVoidContent.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to void this entire invoice? All its products will be returned to stock.'**
  String get confirmVoidContent;

  /// No description provided for @confirmVoidAction.
  ///
  /// In en, this message translates to:
  /// **'Yes, Void'**
  String get confirmVoidAction;

  /// No description provided for @voidSuccess.
  ///
  /// In en, this message translates to:
  /// **'Invoice voided successfully.'**
  String get voidSuccess;

  /// No description provided for @detailsForInvoice.
  ///
  /// In en, this message translates to:
  /// **'Details for Invoice #{id}'**
  String detailsForInvoice(String id);

  /// No description provided for @directselling.
  ///
  /// In en, this message translates to:
  /// **'Direct selling'**
  String get directselling;

  /// No description provided for @directSalePoint.
  ///
  /// In en, this message translates to:
  /// **'Direct Sale Point'**
  String get directSalePoint;

  /// No description provided for @completeSale.
  ///
  /// In en, this message translates to:
  /// **'Complete Sale'**
  String get completeSale;

  /// No description provided for @saleSuccess.
  ///
  /// In en, this message translates to:
  /// **'Sale completed successfully!'**
  String get saleSuccess;

  /// No description provided for @pdfInvoiceTitle.
  ///
  /// In en, this message translates to:
  /// **'Cash Sale Invoice'**
  String get pdfInvoiceTitle;

  /// No description provided for @pdfDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get pdfDate;

  /// No description provided for @pdfInvoiceNumber.
  ///
  /// In en, this message translates to:
  /// **'Invoice #'**
  String get pdfInvoiceNumber;

  /// No description provided for @pdfHeaderProduct.
  ///
  /// In en, this message translates to:
  /// **'Product'**
  String get pdfHeaderProduct;

  /// No description provided for @pdfHeaderQty.
  ///
  /// In en, this message translates to:
  /// **'Qty'**
  String get pdfHeaderQty;

  /// No description provided for @pdfHeaderPrice.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get pdfHeaderPrice;

  /// No description provided for @pdfHeaderTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get pdfHeaderTotal;

  /// No description provided for @pdfFooterTotal.
  ///
  /// In en, this message translates to:
  /// **'Total Amount'**
  String get pdfFooterTotal;

  /// No description provided for @pdfFooterThanks.
  ///
  /// In en, this message translates to:
  /// **'Thank you for your business'**
  String get pdfFooterThanks;

  /// No description provided for @manageExpenseCategories.
  ///
  /// In en, this message translates to:
  /// **'Manage Expense Categories'**
  String get manageExpenseCategories;

  /// No description provided for @noCategories.
  ///
  /// In en, this message translates to:
  /// **'No categories found. Add your first one.'**
  String get noCategories;

  /// No description provided for @addCategory.
  ///
  /// In en, this message translates to:
  /// **'Add New Category'**
  String get addCategory;

  /// No description provided for @editCategory.
  ///
  /// In en, this message translates to:
  /// **'Edit Category'**
  String get editCategory;

  /// No description provided for @categoryName.
  ///
  /// In en, this message translates to:
  /// **'Category Name'**
  String get categoryName;

  /// No description provided for @categoryNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Category name is required'**
  String get categoryNameRequired;

  /// No description provided for @categoryExistsError.
  ///
  /// In en, this message translates to:
  /// **'Error: This category name already exists.'**
  String get categoryExistsError;

  /// No description provided for @confirmDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm Deletion'**
  String get confirmDeleteTitle;

  /// No description provided for @confirmDeleteCategory.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete the category \"{name}\"?'**
  String confirmDeleteCategory(String name);

  /// No description provided for @manageCategories.
  ///
  /// In en, this message translates to:
  /// **'Manage Categories'**
  String get manageCategories;

  /// No description provided for @noExpenses.
  ///
  /// In en, this message translates to:
  /// **'No expenses recorded.'**
  String get noExpenses;

  /// No description provided for @addExpense.
  ///
  /// In en, this message translates to:
  /// **'Add New Expense'**
  String get addExpense;

  /// No description provided for @newExpense.
  ///
  /// In en, this message translates to:
  /// **'Record New Expense'**
  String get newExpense;

  /// No description provided for @expenseDescription.
  ///
  /// In en, this message translates to:
  /// **'Expense Description'**
  String get expenseDescription;

  /// No description provided for @descriptionRequired.
  ///
  /// In en, this message translates to:
  /// **'Description is required'**
  String get descriptionRequired;

  /// No description provided for @amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @selectCategory.
  ///
  /// In en, this message translates to:
  /// **'Please select a category'**
  String get selectCategory;

  /// No description provided for @addCategoriesFirst.
  ///
  /// In en, this message translates to:
  /// **'Please add expense categories first from the manage categories screen.'**
  String get addCategoriesFirst;

  /// No description provided for @expenseAddedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Expense recorded successfully.'**
  String get expenseAddedSuccess;

  /// No description provided for @unclassified.
  ///
  /// In en, this message translates to:
  /// **'Unclassified'**
  String get unclassified;

  /// No description provided for @dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @thisMonth.
  ///
  /// In en, this message translates to:
  /// **'This Month'**
  String get thisMonth;

  /// No description provided for @sales.
  ///
  /// In en, this message translates to:
  /// **'Sales'**
  String get sales;

  /// No description provided for @profit.
  ///
  /// In en, this message translates to:
  /// **'Profit'**
  String get profit;

  /// No description provided for @topSelling.
  ///
  /// In en, this message translates to:
  /// **'Top Selling'**
  String get topSelling;

  /// No description provided for @topCustomer.
  ///
  /// In en, this message translates to:
  /// **'Top Customer'**
  String get topCustomer;

  /// No description provided for @generalStats.
  ///
  /// In en, this message translates to:
  /// **'General Statistics'**
  String get generalStats;

  /// No description provided for @totalCustomers.
  ///
  /// In en, this message translates to:
  /// **'Customers'**
  String get totalCustomers;

  /// No description provided for @totalProducts.
  ///
  /// In en, this message translates to:
  /// **'Products'**
  String get totalProducts;

  /// No description provided for @lowStock.
  ///
  /// In en, this message translates to:
  /// **'Low Stock'**
  String get lowStock;

  /// No description provided for @pendingPayments.
  ///
  /// In en, this message translates to:
  /// **'Pending Payments'**
  String get pendingPayments;

  /// No description provided for @topBuyerThisMonth.
  ///
  /// In en, this message translates to:
  /// **'Top buyer this month'**
  String get topBuyerThisMonth;

  /// No description provided for @noSalesData.
  ///
  /// In en, this message translates to:
  /// **'Not enough data to show top selling products'**
  String get noSalesData;

  /// No description provided for @noCustomersData.
  ///
  /// In en, this message translates to:
  /// **'Not enough data to show top customer'**
  String get noCustomersData;

  /// No description provided for @loadingStats.
  ///
  /// In en, this message translates to:
  /// **'Loading statistics...'**
  String get loadingStats;

  /// No description provided for @currency.
  ///
  /// In en, this message translates to:
  /// **'IQD'**
  String get currency;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
