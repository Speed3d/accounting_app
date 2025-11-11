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

  /// No description provided for @more.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get more;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

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

  /// No description provided for @noarchivedcustomers.
  ///
  /// In en, this message translates to:
  /// **'No archived customers'**
  String get noarchivedcustomers;

  /// No description provided for @noarchivedproducts.
  ///
  /// In en, this message translates to:
  /// **'No archived products'**
  String get noarchivedproducts;

  /// No description provided for @noarchivedsuppliers.
  ///
  /// In en, this message translates to:
  /// **'No archived suppliers'**
  String get noarchivedsuppliers;

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
  /// **'Not registered'**
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

  /// Text for cancel button in forms
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Tooltip text for edit button
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// Tooltip text for delete button
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// Text for save button in forms
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @addEditCustomer.
  ///
  /// In en, this message translates to:
  /// **'Add/Edit Customer'**
  String get addEditCustomer;

  /// No description provided for @nopurchasesyetrecorded.
  ///
  /// In en, this message translates to:
  /// **'No purchases have been recorded yet'**
  String get nopurchasesyetrecorded;

  /// No description provided for @nopaymentsyetrecorded.
  ///
  /// In en, this message translates to:
  /// **'No payments have been recorded yet'**
  String get nopaymentsyetrecorded;

  /// No description provided for @customerName.
  ///
  /// In en, this message translates to:
  /// **'Customer Name'**
  String get customerName;

  /// No description provided for @startfirstcustomer.
  ///
  /// In en, this message translates to:
  /// **'Start with your first customer'**
  String get startfirstcustomer;

  /// No description provided for @loadingcustomers.
  ///
  /// In en, this message translates to:
  /// **'Loading customers ...'**
  String get loadingcustomers;

  /// No description provided for @addressOptional.
  ///
  /// In en, this message translates to:
  /// **'Address (Optional)'**
  String get addressOptional;

  /// No description provided for @searchcustomer.
  ///
  /// In en, this message translates to:
  /// **'search for a customer'**
  String get searchcustomer;

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

  /// Validation error message when amount field is empty
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

  /// Label for optional notes field
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
  /// **'Error occurred'**
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
  /// **'Advance amount'**
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
  /// **'Add employee'**
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

  /// Invalid number error message
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid number'**
  String get enterValidNumber;

  /// No description provided for @hireDate.
  ///
  /// In en, this message translates to:
  /// **'Hire Date'**
  String get hireDate;

  /// No description provided for @employeeAddedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Employee added successfully'**
  String get employeeAddedSuccess;

  /// No description provided for @employeeUpdatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Employee data updated successfully'**
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
  /// **'Bonuses & incentives'**
  String get bonuses;

  /// No description provided for @deductions.
  ///
  /// In en, this message translates to:
  /// **'Deductions'**
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
  /// **'This field is required, enter 0 if no value'**
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
  /// **'No advances recorded'**
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
  String paidOn(String date);

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
  /// **'Fully paid'**
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
  /// **'Add supplier'**
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
  /// **'Add new partner'**
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
  /// **'Add user'**
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
  /// **'No users available'**
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
  /// **'Search for a product ...'**
  String get searchForProduct;

  /// No description provided for @searchForProduct2.
  ///
  /// In en, this message translates to:
  /// **'Search for a product or supplier...'**
  String get searchForProduct2;

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
  /// **'Add product'**
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
  /// **'Cost price'**
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
  /// **'Scan barcode'**
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
  /// **'Supplier Profit Report'**
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
  /// **'product'**
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

  /// Text for close button in dialogs
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
  /// **'Salary'**
  String get salaryLabel;

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
  /// **'No sales have been recorded yet'**
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
  /// **'Cash Flow Report'**
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

  /// Dialog title for recording withdrawal
  ///
  /// In en, this message translates to:
  /// **'Withdraw Profits for: {name}'**
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

  /// Label for total profit from supplier
  ///
  /// In en, this message translates to:
  /// **'Total Profit from Supplier'**
  String get totalProfitFromSupplier;

  /// No description provided for @totalWithdrawals.
  ///
  /// In en, this message translates to:
  /// **'Total Withdrawals:'**
  String get totalWithdrawals;

  /// Label for remaining net profit after withdrawals
  ///
  /// In en, this message translates to:
  /// **'Remaining Net Profit'**
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

  /// Tooltip for recording general withdrawal
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
  /// **'Total General Expenses'**
  String get totalGeneralExpenses;

  /// No description provided for @totalProfitWithdrawals.
  ///
  /// In en, this message translates to:
  /// **'Total Profit Withdrawals'**
  String get totalProfitWithdrawals;

  /// No description provided for @netProfit.
  ///
  /// In en, this message translates to:
  /// **'Net Profit'**
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

  /// Title for Empty State when there are no categories
  ///
  /// In en, this message translates to:
  /// **'No Categories'**
  String get noCategories;

  /// Text for add new category button
  ///
  /// In en, this message translates to:
  /// **'Add Category'**
  String get addCategory;

  /// Title for edit category dialog
  ///
  /// In en, this message translates to:
  /// **'Edit Category'**
  String get editCategory;

  /// Label for category name field
  ///
  /// In en, this message translates to:
  /// **'Category Name'**
  String get categoryName;

  /// Validation message when name field is empty
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

  /// Text for manage expense categories button
  ///
  /// In en, this message translates to:
  /// **'Manage Categories'**
  String get manageCategories;

  /// Title for Empty State when there are no expenses
  ///
  /// In en, this message translates to:
  /// **'No Expenses'**
  String get noExpenses;

  /// Text for add new expense button
  ///
  /// In en, this message translates to:
  /// **'Add Expense'**
  String get addExpense;

  /// Tooltip for floating action button (FAB)
  ///
  /// In en, this message translates to:
  /// **'New Expense'**
  String get newExpense;

  /// Label for expense description field
  ///
  /// In en, this message translates to:
  /// **'Expense Description'**
  String get expenseDescription;

  /// Validation error message when description field is empty
  ///
  /// In en, this message translates to:
  /// **'Description is required'**
  String get descriptionRequired;

  /// Label for amount field
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// Label for category field
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// Validation error message when no category is selected
  ///
  /// In en, this message translates to:
  /// **'Select category'**
  String get selectCategory;

  /// Warning message when trying to add expense without categories
  ///
  /// In en, this message translates to:
  /// **'Please add expense categories first'**
  String get addCategoriesFirst;

  /// Success message after adding new expense
  ///
  /// In en, this message translates to:
  /// **'Expense added successfully'**
  String get expenseAddedSuccess;

  /// Text shown when expense has no category assigned
  ///
  /// In en, this message translates to:
  /// **'Unclassified'**
  String get unclassified;

  /// No description provided for @expensesarebeingloaded.
  ///
  /// In en, this message translates to:
  /// **'Expenses are being loaded'**
  String get expensesarebeingloaded;

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

  /// No description provided for @errorLoadingData.
  ///
  /// In en, this message translates to:
  /// **'Error loading data'**
  String get errorLoadingData;

  /// No description provided for @pleaseTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Please try again'**
  String get pleaseTryAgain;

  /// No description provided for @noSales.
  ///
  /// In en, this message translates to:
  /// **'No Sales'**
  String get noSales;

  /// No description provided for @noCustomers.
  ///
  /// In en, this message translates to:
  /// **'No customers'**
  String get noCustomers;

  /// No description provided for @enterCustomerName.
  ///
  /// In en, this message translates to:
  /// **'Enter customer name'**
  String get enterCustomerName;

  /// No description provided for @enterAddress.
  ///
  /// In en, this message translates to:
  /// **'Enter address'**
  String get enterAddress;

  /// No description provided for @enterPhone.
  ///
  /// In en, this message translates to:
  /// **'Enter phone number'**
  String get enterPhone;

  /// No description provided for @updateCustomer.
  ///
  /// In en, this message translates to:
  /// **'Update customer'**
  String get updateCustomer;

  /// No description provided for @loadingCustomers.
  ///
  /// In en, this message translates to:
  /// **'Loading customers...'**
  String get loadingCustomers;

  /// No description provided for @searchCustomers.
  ///
  /// In en, this message translates to:
  /// **'Search customers'**
  String get searchCustomers;

  /// No description provided for @balanced.
  ///
  /// In en, this message translates to:
  /// **'Balanced'**
  String get balanced;

  /// No description provided for @archiveCustomer.
  ///
  /// In en, this message translates to:
  /// **'Archive customer'**
  String get archiveCustomer;

  /// No description provided for @customerArchivedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Customer archived successfully'**
  String get customerArchivedSuccess;

  /// No description provided for @basicInformation.
  ///
  /// In en, this message translates to:
  /// **'Basic Information'**
  String get basicInformation;

  /// No description provided for @suppliersManagement.
  ///
  /// In en, this message translates to:
  /// **'Suppliers Management'**
  String get suppliersManagement;

  /// No description provided for @productsManagement.
  ///
  /// In en, this message translates to:
  /// **'Products Management'**
  String get productsManagement;

  /// No description provided for @customersManagement.
  ///
  /// In en, this message translates to:
  /// **'Customers Management'**
  String get customersManagement;

  /// No description provided for @employeesManagement.
  ///
  /// In en, this message translates to:
  /// **'Employees Management'**
  String get employeesManagement;

  /// No description provided for @reportsAndSales.
  ///
  /// In en, this message translates to:
  /// **'Reports And Sales'**
  String get reportsAndSales;

  /// No description provided for @systemSettings.
  ///
  /// In en, this message translates to:
  /// **'System Settings'**
  String get systemSettings;

  /// No description provided for @changeImage.
  ///
  /// In en, this message translates to:
  /// **'Change Image'**
  String get changeImage;

  /// No description provided for @primaryAdminAccount.
  ///
  /// In en, this message translates to:
  /// **'Primary Admin Account'**
  String get primaryAdminAccount;

  /// No description provided for @primaryAdminNote.
  ///
  /// In en, this message translates to:
  /// **'You can only edit your name, photo, and password. Permissions protect'**
  String get primaryAdminNote;

  /// No description provided for @updateProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get updateProfile;

  /// No description provided for @updateUser.
  ///
  /// In en, this message translates to:
  /// **'Update User'**
  String get updateUser;

  /// No description provided for @editingYourProfile.
  ///
  /// In en, this message translates to:
  /// **'Editing Your Profile'**
  String get editingYourProfile;

  /// No description provided for @selfEditNote.
  ///
  /// In en, this message translates to:
  /// **'You can edit your name, username, password, and profile picture. Permissions are protected'**
  String get selfEditNote;

  /// No description provided for @transactionDetails.
  ///
  /// In en, this message translates to:
  /// **'Transaction details'**
  String get transactionDetails;

  /// No description provided for @noTransactionsInPeriod.
  ///
  /// In en, this message translates to:
  /// **'No Transactions In Period'**
  String get noTransactionsInPeriod;

  /// No description provided for @cashIn.
  ///
  /// In en, this message translates to:
  /// **'Cash In'**
  String get cashIn;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// No description provided for @darkModeEnabled.
  ///
  /// In en, this message translates to:
  /// **'Enabled - Relax your eyes 😌'**
  String get darkModeEnabled;

  /// No description provided for @darkModeDisabled.
  ///
  /// In en, this message translates to:
  /// **'Disabled - Enjoy the light ☀️'**
  String get darkModeDisabled;

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Smart Accounting System'**
  String get appTitle;

  /// No description provided for @appVersion.
  ///
  /// In en, this message translates to:
  /// **'Version 1.0.0'**
  String get appVersion;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @appDescription.
  ///
  /// In en, this message translates to:
  /// **'A smart and integrated accounting system to manage your business easily and professionally'**
  String get appDescription;

  /// No description provided for @companyInfo.
  ///
  /// In en, this message translates to:
  /// **'Company Information'**
  String get companyInfo;

  /// No description provided for @companyName.
  ///
  /// In en, this message translates to:
  /// **'Company Name'**
  String get companyName;

  /// No description provided for @notSpecified.
  ///
  /// In en, this message translates to:
  /// **'Not specified'**
  String get notSpecified;

  /// General label for description in detail pages
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @developerInfo.
  ///
  /// In en, this message translates to:
  /// **'Developer Information'**
  String get developerInfo;

  /// No description provided for @developer.
  ///
  /// In en, this message translates to:
  /// **'Developer'**
  String get developer;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @rightsReserved.
  ///
  /// In en, this message translates to:
  /// **'© 2025 All rights reserved'**
  String get rightsReserved;

  /// No description provided for @madeWith.
  ///
  /// In en, this message translates to:
  /// **'Made with'**
  String get madeWith;

  /// No description provided for @madeInIraq.
  ///
  /// In en, this message translates to:
  /// **'In Iraq 🇮🇶'**
  String get madeInIraq;

  /// No description provided for @loadingData.
  ///
  /// In en, this message translates to:
  /// **'Loading data...'**
  String get loadingData;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get saveChanges;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @user.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get user;

  /// No description provided for @loadingUsers.
  ///
  /// In en, this message translates to:
  /// **'Loading users...'**
  String get loadingUsers;

  /// Generic error message when data loading fails
  ///
  /// In en, this message translates to:
  /// **'Error loading data'**
  String get loadError;

  /// No description provided for @addNewUser.
  ///
  /// In en, this message translates to:
  /// **'Add new user'**
  String get addNewUser;

  /// No description provided for @noResults.
  ///
  /// In en, this message translates to:
  /// **'No results'**
  String get noResults;

  /// No description provided for @noUsersMatch.
  ///
  /// In en, this message translates to:
  /// **'No users found with these criteria'**
  String get noUsersMatch;

  /// No description provided for @searchUser.
  ///
  /// In en, this message translates to:
  /// **'Search for a user...'**
  String get searchUser;

  /// No description provided for @totalUsers.
  ///
  /// In en, this message translates to:
  /// **'Total users'**
  String get totalUsers;

  /// No description provided for @admins.
  ///
  /// In en, this message translates to:
  /// **'Admins'**
  String get admins;

  /// Single permission word
  ///
  /// In en, this message translates to:
  /// **'Permission'**
  String get permission;

  /// No description provided for @viewEdit.
  ///
  /// In en, this message translates to:
  /// **'View & Edit'**
  String get viewEdit;

  /// No description provided for @viewOnly.
  ///
  /// In en, this message translates to:
  /// **'View only'**
  String get viewOnly;

  /// No description provided for @none.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get none;

  /// No description provided for @view.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get view;

  /// No description provided for @fullAccess.
  ///
  /// In en, this message translates to:
  /// **'Full Access'**
  String get fullAccess;

  /// No description provided for @employeeReports.
  ///
  /// In en, this message translates to:
  /// **'Employee Reports'**
  String get employeeReports;

  /// No description provided for @expenses.
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get expenses;

  /// No description provided for @cashSales.
  ///
  /// In en, this message translates to:
  /// **'Cash Sales'**
  String get cashSales;

  /// No description provided for @noPermissions.
  ///
  /// In en, this message translates to:
  /// **'No permissions granted'**
  String get noPermissions;

  /// No description provided for @noUndo.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone'**
  String get noUndo;

  /// No description provided for @deleteError.
  ///
  /// In en, this message translates to:
  /// **'An error occurred while deleting'**
  String get deleteError;

  /// No description provided for @loadingSuppliers.
  ///
  /// In en, this message translates to:
  /// **'Loading suppliers...'**
  String get loadingSuppliers;

  /// No description provided for @noSuppliers.
  ///
  /// In en, this message translates to:
  /// **'No suppliers available'**
  String get noSuppliers;

  /// No description provided for @addNewSupplier.
  ///
  /// In en, this message translates to:
  /// **'Add new supplier'**
  String get addNewSupplier;

  /// No description provided for @noSuppliersMatch.
  ///
  /// In en, this message translates to:
  /// **'No suppliers found with this name'**
  String get noSuppliersMatch;

  /// No description provided for @searchSupplier.
  ///
  /// In en, this message translates to:
  /// **'Search for a supplier...'**
  String get searchSupplier;

  /// No description provided for @totalSuppliers.
  ///
  /// In en, this message translates to:
  /// **'Total suppliers'**
  String get totalSuppliers;

  /// Filter button - show only individuals
  ///
  /// In en, this message translates to:
  /// **'Individuals'**
  String get individuals;

  /// No description provided for @canRestoreSupplier.
  ///
  /// In en, this message translates to:
  /// **'You can restore this supplier later from the archive center'**
  String get canRestoreSupplier;

  /// No description provided for @supplierArchived.
  ///
  /// In en, this message translates to:
  /// **'Supplier archived'**
  String get supplierArchived;

  /// No description provided for @archiveError.
  ///
  /// In en, this message translates to:
  /// **'Archiving error'**
  String get archiveError;

  /// No description provided for @basicInfo.
  ///
  /// In en, this message translates to:
  /// **'Basic Information'**
  String get basicInfo;

  /// No description provided for @enterSupplierName.
  ///
  /// In en, this message translates to:
  /// **'Enter supplier name'**
  String get enterSupplierName;

  /// No description provided for @additionalInfoOptional.
  ///
  /// In en, this message translates to:
  /// **'Additional information (optional)'**
  String get additionalInfoOptional;

  /// No description provided for @enterPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter phone number'**
  String get enterPhoneNumber;

  /// No description provided for @enterNotes.
  ///
  /// In en, this message translates to:
  /// **'Enter any notes'**
  String get enterNotes;

  /// No description provided for @updateSupplier.
  ///
  /// In en, this message translates to:
  /// **'Update supplier'**
  String get updateSupplier;

  /// No description provided for @createSupplier.
  ///
  /// In en, this message translates to:
  /// **'Add supplier'**
  String get createSupplier;

  /// No description provided for @deletePartner.
  ///
  /// In en, this message translates to:
  /// **'Delete Partner '**
  String get deletePartner;

  /// No description provided for @confirmDeletePartner.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete partner \"{name}\"?'**
  String confirmDeletePartner(String name);

  /// No description provided for @updateSupplierInfo.
  ///
  /// In en, this message translates to:
  /// **'Update supplier information'**
  String get updateSupplierInfo;

  /// No description provided for @addNewSupplierAgain.
  ///
  /// In en, this message translates to:
  /// **'Add new supplier'**
  String get addNewSupplierAgain;

  /// No description provided for @saveError.
  ///
  /// In en, this message translates to:
  /// **'An error occurred while saving'**
  String get saveError;

  /// No description provided for @editPartnerInfo.
  ///
  /// In en, this message translates to:
  /// **'Edit partner information'**
  String get editPartnerInfo;

  /// No description provided for @partnerInfo.
  ///
  /// In en, this message translates to:
  /// **'Partner information'**
  String get partnerInfo;

  /// No description provided for @enterPartnerName.
  ///
  /// In en, this message translates to:
  /// **'Enter partner name'**
  String get enterPartnerName;

  /// No description provided for @enterPartnerShare.
  ///
  /// In en, this message translates to:
  /// **'Enter partnership percentage (1-100)'**
  String get enterPartnerShare;

  /// No description provided for @invalidShare.
  ///
  /// In en, this message translates to:
  /// **'Invalid percentage'**
  String get invalidShare;

  /// No description provided for @additionalInfo.
  ///
  /// In en, this message translates to:
  /// **'Additional information'**
  String get additionalInfo;

  /// No description provided for @updatePartner.
  ///
  /// In en, this message translates to:
  /// **'Update partner'**
  String get updatePartner;

  /// No description provided for @createPartner.
  ///
  /// In en, this message translates to:
  /// **'Add partner'**
  String get createPartner;

  /// No description provided for @archiveProduct.
  ///
  /// In en, this message translates to:
  /// **'Archive product'**
  String get archiveProduct;

  /// No description provided for @productArchived.
  ///
  /// In en, this message translates to:
  /// **'Product archived'**
  String get productArchived;

  /// No description provided for @errorArchiveRestor.
  ///
  /// In en, this message translates to:
  /// **'Error restoring: {error}'**
  String errorArchiveRestor(Object error);

  /// No description provided for @restoreConfirm.
  ///
  /// In en, this message translates to:
  /// **'Do you want to restore \"{name}\"?'**
  String restoreConfirm(Object name);

  /// No description provided for @restoretheitem.
  ///
  /// In en, this message translates to:
  /// **'Restore The Item \"{name}\"?'**
  String restoretheitem(Object name);

  /// No description provided for @loadingProducts.
  ///
  /// In en, this message translates to:
  /// **'Loading products...'**
  String get loadingProducts;

  /// No description provided for @startByAddingProduct.
  ///
  /// In en, this message translates to:
  /// **'Start by adding your first product in inventory'**
  String get startByAddingProduct;

  /// No description provided for @addNewProduct.
  ///
  /// In en, this message translates to:
  /// **'Add new product'**
  String get addNewProduct;

  /// No description provided for @addtonewstores.
  ///
  /// In en, this message translates to:
  /// **'Add to new stores'**
  String get addtonewstores;

  /// No description provided for @totalQuantity.
  ///
  /// In en, this message translates to:
  /// **'Total quantity'**
  String get totalQuantity;

  /// No description provided for @low.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get low;

  /// No description provided for @value.
  ///
  /// In en, this message translates to:
  /// **'Value'**
  String get value;

  /// No description provided for @tryAnotherSearch.
  ///
  /// In en, this message translates to:
  /// **'Try searching another keyword'**
  String get tryAnotherSearch;

  /// No description provided for @purchase.
  ///
  /// In en, this message translates to:
  /// **'Purchase'**
  String get purchase;

  /// No description provided for @sell.
  ///
  /// In en, this message translates to:
  /// **'Sell'**
  String get sell;

  /// No description provided for @pointCameraToBarcode.
  ///
  /// In en, this message translates to:
  /// **'Point the camera at the barcode to scan'**
  String get pointCameraToBarcode;

  /// No description provided for @supplierInfo.
  ///
  /// In en, this message translates to:
  /// **'Supplier information'**
  String get supplierInfo;

  /// No description provided for @productInfo.
  ///
  /// In en, this message translates to:
  /// **'Product information'**
  String get productInfo;

  /// No description provided for @enterProductName.
  ///
  /// In en, this message translates to:
  /// **'Enter product name'**
  String get enterProductName;

  /// No description provided for @scanOrEnterBarcode.
  ///
  /// In en, this message translates to:
  /// **'Scan or enter barcode'**
  String get scanOrEnterBarcode;

  /// No description provided for @enterProductDetails.
  ///
  /// In en, this message translates to:
  /// **'Enter product details'**
  String get enterProductDetails;

  /// No description provided for @quantityAndPrices.
  ///
  /// In en, this message translates to:
  /// **'Quantity and prices'**
  String get quantityAndPrices;

  /// No description provided for @enterQuantity.
  ///
  /// In en, this message translates to:
  /// **'Enter quantity'**
  String get enterQuantity;

  /// No description provided for @purchasePrice.
  ///
  /// In en, this message translates to:
  /// **'Purchase price'**
  String get purchasePrice;

  /// No description provided for @salePrice.
  ///
  /// In en, this message translates to:
  /// **'Sale price'**
  String get salePrice;

  /// No description provided for @pricesSummary.
  ///
  /// In en, this message translates to:
  /// **'Prices summary'**
  String get pricesSummary;

  /// No description provided for @loadingEmployees.
  ///
  /// In en, this message translates to:
  /// **'Loading employees...'**
  String get loadingEmployees;

  /// No description provided for @startByAddingEmployee.
  ///
  /// In en, this message translates to:
  /// **'Start by adding your first employee'**
  String get startByAddingEmployee;

  /// No description provided for @addNewEmployee.
  ///
  /// In en, this message translates to:
  /// **'Add new employee'**
  String get addNewEmployee;

  /// No description provided for @searchNewEmployee.
  ///
  /// In en, this message translates to:
  /// **'Search Employee'**
  String get searchNewEmployee;

  /// No description provided for @searchNewEmployee2.
  ///
  /// In en, this message translates to:
  /// **'Search for employee or employee specialization'**
  String get searchNewEmployee2;

  /// No description provided for @totalSalaries.
  ///
  /// In en, this message translates to:
  /// **'Total salaries'**
  String get totalSalaries;

  /// No description provided for @totalAdvances.
  ///
  /// In en, this message translates to:
  /// **'Total advances'**
  String get totalAdvances;

  /// No description provided for @salary.
  ///
  /// In en, this message translates to:
  /// **'Salary'**
  String get salary;

  /// No description provided for @advance.
  ///
  /// In en, this message translates to:
  /// **'Advance'**
  String get advance;

  /// No description provided for @months.
  ///
  /// In en, this message translates to:
  /// **'Months'**
  String get months;

  /// No description provided for @january.
  ///
  /// In en, this message translates to:
  /// **'January'**
  String get january;

  /// No description provided for @february.
  ///
  /// In en, this message translates to:
  /// **'February'**
  String get february;

  /// No description provided for @march.
  ///
  /// In en, this message translates to:
  /// **'March'**
  String get march;

  /// No description provided for @april.
  ///
  /// In en, this message translates to:
  /// **'April'**
  String get april;

  /// No description provided for @may.
  ///
  /// In en, this message translates to:
  /// **'May'**
  String get may;

  /// No description provided for @june.
  ///
  /// In en, this message translates to:
  /// **'June'**
  String get june;

  /// No description provided for @july.
  ///
  /// In en, this message translates to:
  /// **'July'**
  String get july;

  /// No description provided for @august.
  ///
  /// In en, this message translates to:
  /// **'August'**
  String get august;

  /// No description provided for @september.
  ///
  /// In en, this message translates to:
  /// **'September'**
  String get september;

  /// No description provided for @october.
  ///
  /// In en, this message translates to:
  /// **'October'**
  String get october;

  /// No description provided for @november.
  ///
  /// In en, this message translates to:
  /// **'November'**
  String get november;

  /// No description provided for @december.
  ///
  /// In en, this message translates to:
  /// **'December'**
  String get december;

  /// No description provided for @noSalaryPaidYet.
  ///
  /// In en, this message translates to:
  /// **'No salary has been paid yet'**
  String get noSalaryPaidYet;

  /// No description provided for @addSalary.
  ///
  /// In en, this message translates to:
  /// **'Add salary'**
  String get addSalary;

  /// No description provided for @paySalary.
  ///
  /// In en, this message translates to:
  /// **'Pay salary'**
  String get paySalary;

  /// No description provided for @addNewSalary.
  ///
  /// In en, this message translates to:
  /// **'Add new salary'**
  String get addNewSalary;

  /// No description provided for @paidAt.
  ///
  /// In en, this message translates to:
  /// **'Paid on:'**
  String get paidAt;

  /// No description provided for @net.
  ///
  /// In en, this message translates to:
  /// **'Net'**
  String get net;

  /// No description provided for @addAdvance.
  ///
  /// In en, this message translates to:
  /// **'Add advance'**
  String get addAdvance;

  /// No description provided for @addNewAdvance.
  ///
  /// In en, this message translates to:
  /// **'Add new advance'**
  String get addNewAdvance;

  /// No description provided for @salaryDetails.
  ///
  /// In en, this message translates to:
  /// **'Salary details'**
  String get salaryDetails;

  /// No description provided for @recordSalaryFor.
  ///
  /// In en, this message translates to:
  /// **'Record salary for month'**
  String get recordSalaryFor;

  /// No description provided for @forEmployee.
  ///
  /// In en, this message translates to:
  /// **'for employee'**
  String get forEmployee;

  /// No description provided for @selectPaymentDate.
  ///
  /// In en, this message translates to:
  /// **'Select Payment Date'**
  String get selectPaymentDate;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @financialPeriod.
  ///
  /// In en, this message translates to:
  /// **'Financial Period'**
  String get financialPeriod;

  /// No description provided for @salaryComponents.
  ///
  /// In en, this message translates to:
  /// **'Salary Components'**
  String get salaryComponents;

  /// No description provided for @basicSalary.
  ///
  /// In en, this message translates to:
  /// **'Basic salary'**
  String get basicSalary;

  /// No description provided for @deductionAndPenalties.
  ///
  /// In en, this message translates to:
  /// **'Deductions & penalties'**
  String get deductionAndPenalties;

  /// No description provided for @deductAdvance.
  ///
  /// In en, this message translates to:
  /// **'Deduct advances from salary'**
  String get deductAdvance;

  /// No description provided for @selectDate.
  ///
  /// In en, this message translates to:
  /// **'Select Date'**
  String get selectDate;

  /// No description provided for @anyAdditionalNotes.
  ///
  /// In en, this message translates to:
  /// **'Any additional notes'**
  String get anyAdditionalNotes;

  /// No description provided for @detailedSummary.
  ///
  /// In en, this message translates to:
  /// **'Detailed Summary'**
  String get detailedSummary;

  /// No description provided for @updateEmployeeData.
  ///
  /// In en, this message translates to:
  /// **'Update employee data:'**
  String get updateEmployeeData;

  /// No description provided for @addNewEmployeeData.
  ///
  /// In en, this message translates to:
  /// **'Add new employee:'**
  String get addNewEmployeeData;

  /// No description provided for @selectHiringDate.
  ///
  /// In en, this message translates to:
  /// **'Select hiring date'**
  String get selectHiringDate;

  /// No description provided for @personalInfo.
  ///
  /// In en, this message translates to:
  /// **'Personal information'**
  String get personalInfo;

  /// No description provided for @enterFullName.
  ///
  /// In en, this message translates to:
  /// **'Enter full name'**
  String get enterFullName;

  /// No description provided for @jobInfo.
  ///
  /// In en, this message translates to:
  /// **'Job information'**
  String get jobInfo;

  /// No description provided for @enterJobTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter job title'**
  String get enterJobTitle;

  /// No description provided for @financialInfo.
  ///
  /// In en, this message translates to:
  /// **'Financial information'**
  String get financialInfo;

  /// No description provided for @enterBasicSalary.
  ///
  /// In en, this message translates to:
  /// **'Enter basic salary'**
  String get enterBasicSalary;

  /// No description provided for @recordEmployeeAdvance.
  ///
  /// In en, this message translates to:
  /// **'Record an advance for employee:'**
  String get recordEmployeeAdvance;

  /// No description provided for @selectAdvanceDate.
  ///
  /// In en, this message translates to:
  /// **'Select advance date'**
  String get selectAdvanceDate;

  /// No description provided for @advanceData.
  ///
  /// In en, this message translates to:
  /// **'Advance data'**
  String get advanceData;

  /// No description provided for @enterAdvanceAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter advance amount'**
  String get enterAdvanceAmount;

  /// No description provided for @enterAdvanceNotes.
  ///
  /// In en, this message translates to:
  /// **'Enter any additional notes'**
  String get enterAdvanceNotes;

  /// No description provided for @currentBalance.
  ///
  /// In en, this message translates to:
  /// **'Current Balance'**
  String get currentBalance;

  /// No description provided for @financialSummary.
  ///
  /// In en, this message translates to:
  /// **'Financial summary'**
  String get financialSummary;

  /// No description provided for @expectedBalance.
  ///
  /// In en, this message translates to:
  /// **'Expected balance'**
  String get expectedBalance;

  /// No description provided for @autoDeductAdvance.
  ///
  /// In en, this message translates to:
  /// **'The advance amount will be automatically deducted from upcoming salaries until fully paid'**
  String get autoDeductAdvance;

  /// Success message shown when a user is deleted
  ///
  /// In en, this message translates to:
  /// **'User \"{userName}\" deleted successfully'**
  String deleteUserSuccess(String userName);

  /// Error message shown when user deletion fails
  ///
  /// In en, this message translates to:
  /// **'An error occurred while deleting: {error}'**
  String deleteUserError(String error);

  /// Plural permissions word
  ///
  /// In en, this message translates to:
  /// **'Permissions'**
  String get permissions;

  /// Success message when resource deletion failed
  ///
  /// In en, this message translates to:
  /// **'Resource deleted \"{supplierName}\" Success'**
  String deleteSupplierSuccess(String userName, Object supplierName);

  /// Error message when resource deletion failed
  ///
  /// In en, this message translates to:
  /// **'An error occurred during deletion: {error}'**
  String deleteSupplierError(String error);

  /// No description provided for @partnersCount.
  ///
  /// In en, this message translates to:
  /// **'{count} partner(s)'**
  String partnersCount(int count);

  /// No description provided for @partnerShareWarning.
  ///
  /// In en, this message translates to:
  /// **'Total partner shares is only {percentage}%.\nDo you want to continue?'**
  String partnerShareWarning(String percentage);

  /// No description provided for @activityUpdateSupplier.
  ///
  /// In en, this message translates to:
  /// **'Update supplier data: {name}'**
  String activityUpdateSupplier(String name);

  /// No description provided for @activityAddSupplier.
  ///
  /// In en, this message translates to:
  /// **'Add new supplier: {name}'**
  String activityAddSupplier(String name);

  /// No description provided for @errorSaving.
  ///
  /// In en, this message translates to:
  /// **'An error occurred while saving: {error}'**
  String errorSaving(String error);

  /// No description provided for @warning.
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get warning;

  /// No description provided for @continueButton.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueButton;

  /// Filter button - show only partnerships
  ///
  /// In en, this message translates to:
  /// **'Partnerships'**
  String get partnerships;

  /// Success message after archiving supplier
  ///
  /// In en, this message translates to:
  /// **'Supplier \"{name}\" has been archived successfully'**
  String supplierArchivedSuccess(String name);

  /// Shown when a product is successfully archived
  ///
  /// In en, this message translates to:
  /// **'\"{name}\" has been archived successfully'**
  String productArchivedSuccess(String name);

  /// Shown when archiving fails
  ///
  /// In en, this message translates to:
  /// **'Error archiving product: {error}'**
  String productArchivedError(String error);

  /// Used when logging product archive action
  ///
  /// In en, this message translates to:
  /// **'Archive product: {name}'**
  String archiveProductAction(String name);

  /// Used when updating an employee's data
  ///
  /// In en, this message translates to:
  /// **'Update employee data: {name}'**
  String updateEmployeeAction(String name);

  /// Used when adding a new employee
  ///
  /// In en, this message translates to:
  /// **'Add new employee: {name}'**
  String addEmployeeAction(String name);

  /// No description provided for @deductionsSection.
  ///
  /// In en, this message translates to:
  /// **'Deductions'**
  String get deductionsSection;

  /// No description provided for @additionalInformation.
  ///
  /// In en, this message translates to:
  /// **'Additional Information'**
  String get additionalInformation;

  /// No description provided for @baseSalaryHint.
  ///
  /// In en, this message translates to:
  /// **'Base Salary'**
  String get baseSalaryHint;

  /// No description provided for @bonusesAndIncentivesHint.
  ///
  /// In en, this message translates to:
  /// **'Bonuses and Incentives'**
  String get bonusesAndIncentivesHint;

  /// No description provided for @deductionsAndPenaltiesHint.
  ///
  /// In en, this message translates to:
  /// **'Deductions and Penalties'**
  String get deductionsAndPenaltiesHint;

  /// No description provided for @advanceDeductionFromSalaryHint.
  ///
  /// In en, this message translates to:
  /// **'Advance Deduction from Salary'**
  String get advanceDeductionFromSalaryHint;

  /// No description provided for @anyAdditionalNotesHint.
  ///
  /// In en, this message translates to:
  /// **'Any Additional Notes'**
  String get anyAdditionalNotesHint;

  /// No description provided for @payrollRegisteredForEmployee.
  ///
  /// In en, this message translates to:
  /// **'Payroll registered for {month} for employee: {employeeName}'**
  String payrollRegisteredForEmployee(String month, String employeeName);

  /// No description provided for @advancesLabel.
  ///
  /// In en, this message translates to:
  /// **'Advances'**
  String get advancesLabel;

  /// No description provided for @loadingMessage.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loadingMessage;

  /// No description provided for @noPayrollsMessage.
  ///
  /// In en, this message translates to:
  /// **'No salaries have been paid yet'**
  String get noPayrollsMessage;

  /// No description provided for @addPayrollAction.
  ///
  /// In en, this message translates to:
  /// **'Add Payroll'**
  String get addPayrollAction;

  /// No description provided for @paymentAction.
  ///
  /// In en, this message translates to:
  /// **'Pay Salary'**
  String get paymentAction;

  /// No description provided for @addNewPayrollTooltip.
  ///
  /// In en, this message translates to:
  /// **'Add new payroll'**
  String get addNewPayrollTooltip;

  /// No description provided for @noAdvancesMessage.
  ///
  /// In en, this message translates to:
  /// **'No advances recorded'**
  String get noAdvancesMessage;

  /// No description provided for @addAdvanceAction.
  ///
  /// In en, this message translates to:
  /// **'Add Advance'**
  String get addAdvanceAction;

  /// No description provided for @addAdvanceButton.
  ///
  /// In en, this message translates to:
  /// **'Add Advance'**
  String get addAdvanceButton;

  /// No description provided for @addNewAdvanceTooltip.
  ///
  /// In en, this message translates to:
  /// **'Add new advance'**
  String get addNewAdvanceTooltip;

  /// No description provided for @netLabel.
  ///
  /// In en, this message translates to:
  /// **'Net'**
  String get netLabel;

  /// No description provided for @payrollDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'{month} {year} Payroll Details'**
  String payrollDetailsTitle(String month, String year);

  /// No description provided for @advanceRegisteredForEmployee.
  ///
  /// In en, this message translates to:
  /// **'Advance registered for employee: {employeeName} with amount: {amount}'**
  String advanceRegisteredForEmployee(String employeeName, String amount);

  /// Authentication Success Message
  ///
  /// In en, this message translates to:
  /// **'Archived \"{name}\" Successful'**
  String archivedSuccess(String name);

  /// No description provided for @newSaleActivityLog.
  ///
  /// In en, this message translates to:
  /// **'New sale recorded for customer: {customerName} with amount: {amount}'**
  String newSaleActivityLog(String customerName, String amount);

  /// No description provided for @paymentActivityLog.
  ///
  /// In en, this message translates to:
  /// **'Payment recorded for customer: {customerName} with amount: {amount}'**
  String paymentActivityLog(String customerName, String amount);

  /// No description provided for @returnActivityLog.
  ///
  /// In en, this message translates to:
  /// **'Product returned from cash invoice #{invoiceId}: {productName}'**
  String returnActivityLog(String invoiceId, String productName);

  /// No description provided for @saleRecordError.
  ///
  /// In en, this message translates to:
  /// **'Error recording sale: {error}'**
  String saleRecordError(String error);

  /// No description provided for @paymentRecordError.
  ///
  /// In en, this message translates to:
  /// **'Error recording payment: {error}'**
  String paymentRecordError(String error);

  /// No description provided for @loadingPurchases.
  ///
  /// In en, this message translates to:
  /// **'Loading purchases...'**
  String get loadingPurchases;

  /// No description provided for @loadingPayments.
  ///
  /// In en, this message translates to:
  /// **'Loading payments...'**
  String get loadingPayments;

  /// No description provided for @newSale.
  ///
  /// In en, this message translates to:
  /// **'New Sale'**
  String get newSale;

  /// No description provided for @generalProfitReport_desc.
  ///
  /// In en, this message translates to:
  /// **'Displays total profits and sales details'**
  String get generalProfitReport_desc;

  /// No description provided for @supplierProfitReport_desc.
  ///
  /// In en, this message translates to:
  /// **'Distribution of profits by supplier or partner'**
  String get supplierProfitReport_desc;

  /// No description provided for @cashSalesRecord.
  ///
  /// In en, this message translates to:
  /// **'Cash Sales Record'**
  String get cashSalesRecord;

  /// No description provided for @cashSalesRecord_desc.
  ///
  /// In en, this message translates to:
  /// **'Invoices and direct cash sales'**
  String get cashSalesRecord_desc;

  /// No description provided for @cashFlowReport_desc.
  ///
  /// In en, this message translates to:
  /// **'Cash receipts and payments'**
  String get cashFlowReport_desc;

  /// Title of the expenses screen in AppBar
  ///
  /// In en, this message translates to:
  /// **'Expense Record'**
  String get expenseRecord;

  /// No description provided for @expenseRecord_desc.
  ///
  /// In en, this message translates to:
  /// **'All recorded expenses and expenditures'**
  String get expenseRecord_desc;

  /// No description provided for @employeePayrollReport.
  ///
  /// In en, this message translates to:
  /// **'Employee and Payroll Report'**
  String get employeePayrollReport;

  /// No description provided for @employeePayrollReport_desc.
  ///
  /// In en, this message translates to:
  /// **'Employee statement, salaries, and advances'**
  String get employeePayrollReport_desc;

  /// No description provided for @reportingCenter.
  ///
  /// In en, this message translates to:
  /// **'Reporting Center'**
  String get reportingCenter;

  /// No description provided for @noreportsavailable.
  ///
  /// In en, this message translates to:
  /// **'No reports are available'**
  String get noreportsavailable;

  /// No description provided for @donotpermissionreports.
  ///
  /// In en, this message translates to:
  /// **'You do not have permission to access any reports'**
  String get donotpermissionreports;

  /// No description provided for @calculatingProfits.
  ///
  /// In en, this message translates to:
  /// **'Calculating profits...'**
  String get calculatingProfits;

  /// No description provided for @noData.
  ///
  /// In en, this message translates to:
  /// **'No Data'**
  String get noData;

  /// No description provided for @noOperationsRecorded.
  ///
  /// In en, this message translates to:
  /// **'No operations have been recorded yet'**
  String get noOperationsRecorded;

  /// No description provided for @totalProfitsFromSales.
  ///
  /// In en, this message translates to:
  /// **'Total Profits from Sales'**
  String get totalProfitsFromSales;

  /// No description provided for @beforeExpenses.
  ///
  /// In en, this message translates to:
  /// **'Before expenses'**
  String get beforeExpenses;

  /// No description provided for @billsAndExpenses.
  ///
  /// In en, this message translates to:
  /// **'Bills and expenses'**
  String get billsAndExpenses;

  /// No description provided for @forSuppliersAndPartners.
  ///
  /// In en, this message translates to:
  /// **'For suppliers and partners'**
  String get forSuppliersAndPartners;

  /// No description provided for @salesDetailsCount.
  ///
  /// In en, this message translates to:
  /// **'Sales Details ({count})'**
  String salesDetailsCount(String count);

  /// No description provided for @notRegistered.
  ///
  /// In en, this message translates to:
  /// **'Not registered'**
  String get notRegistered;

  /// No description provided for @fromAmount.
  ///
  /// In en, this message translates to:
  /// **'From {amount}'**
  String fromAmount(String amount);

  /// No description provided for @returnWarningMessage.
  ///
  /// In en, this message translates to:
  /// **'Product will be returned to stock and invoice status will be updated'**
  String get returnWarningMessage;

  /// No description provided for @loadingInvoiceDetails.
  ///
  /// In en, this message translates to:
  /// **'Loading invoice details...'**
  String get loadingInvoiceDetails;

  /// No description provided for @noItemsInInvoice.
  ///
  /// In en, this message translates to:
  /// **'No items in this invoice'**
  String get noItemsInInvoice;

  /// No description provided for @invoiceEmptyOrCancelled.
  ///
  /// In en, this message translates to:
  /// **'Invoice is empty or cancelled'**
  String get invoiceEmptyOrCancelled;

  /// No description provided for @invoiceStatusModified.
  ///
  /// In en, this message translates to:
  /// **'Modified'**
  String get invoiceStatusModified;

  /// No description provided for @invoiceTotalAmount.
  ///
  /// In en, this message translates to:
  /// **'Invoice Total:'**
  String get invoiceTotalAmount;

  /// No description provided for @returnedAmount.
  ///
  /// In en, this message translates to:
  /// **'Returned Amount:'**
  String get returnedAmount;

  /// No description provided for @netAmount.
  ///
  /// In en, this message translates to:
  /// **'Net:'**
  String get netAmount;

  /// No description provided for @itemsCount2.
  ///
  /// In en, this message translates to:
  /// **'Items Count: {count}'**
  String itemsCount2(int count);

  /// No description provided for @returnedStatus.
  ///
  /// In en, this message translates to:
  /// **'Returned'**
  String get returnedStatus;

  /// No description provided for @longPressToReturn.
  ///
  /// In en, this message translates to:
  /// **'Long press to return'**
  String get longPressToReturn;

  /// Message shown when no supplier profits are available
  ///
  /// In en, this message translates to:
  /// **'No profits recorded for suppliers yet'**
  String get noProfitsRecordedForSuppliers;

  /// Label for total profits amount
  ///
  /// In en, this message translates to:
  /// **'Total Profits'**
  String get totalProfits;

  /// Label for withdrawals amount
  ///
  /// In en, this message translates to:
  /// **'Withdrawals'**
  String get withdrawals;

  /// No description provided for @trysearchinvoice.
  ///
  /// In en, this message translates to:
  /// **'Try searching with a different invoice number'**
  String get trysearchinvoice;

  /// No description provided for @nocashrecordedyet.
  ///
  /// In en, this message translates to:
  /// **'No cash sales invoice has been recorded yet'**
  String get nocashrecordedyet;

  /// No description provided for @invoicesloaded.
  ///
  /// In en, this message translates to:
  /// **'Invoices are being loaded...'**
  String get invoicesloaded;

  /// Subtitle indicating amount is before withdrawals
  ///
  /// In en, this message translates to:
  /// **'Before Withdrawals'**
  String get beforeWithdrawals;

  /// Subtitle for withdrawn amounts
  ///
  /// In en, this message translates to:
  /// **'Withdrawn Amounts'**
  String get withdrawnAmounts;

  /// Button text to record a new withdrawal
  ///
  /// In en, this message translates to:
  /// **'Record Withdrawal'**
  String get recordWithdrawal;

  /// Message when no withdrawals exist
  ///
  /// In en, this message translates to:
  /// **'No withdrawal operations have been recorded yet'**
  String get noWithdrawalsRecorded;

  /// Message shown while loading expenses list
  ///
  /// In en, this message translates to:
  /// **'Loading expenses...'**
  String get loadingExpenses;

  /// Descriptive message in Empty State
  ///
  /// In en, this message translates to:
  /// **'No expenses have been recorded yet'**
  String get noExpensesMessage;

  /// Placeholder for expense description field
  ///
  /// In en, this message translates to:
  /// **'e.g., Electricity bill'**
  String get expenseDescriptionHint;

  /// Placeholder for notes field
  ///
  /// In en, this message translates to:
  /// **'Add a note...'**
  String get addNote;

  /// General label for date
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// General label for notes
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// Title for expense details dialog
  ///
  /// In en, this message translates to:
  /// **'Expense Details'**
  String get expenseDetails;

  /// Generic error message
  ///
  /// In en, this message translates to:
  /// **'An error occurred'**
  String get errorOccurred2;

  /// Title of manage categories screen in AppBar
  ///
  /// In en, this message translates to:
  /// **'Manage Expense Categories'**
  String get manageCategoriesTitle;

  /// Message shown while loading categories list
  ///
  /// In en, this message translates to:
  /// **'Loading categories...'**
  String get loadingCategories;

  /// Descriptive message in Empty State
  ///
  /// In en, this message translates to:
  /// **'No expense categories have been added yet'**
  String get noCategoriesMessage;

  /// Tooltip for floating action button
  ///
  /// In en, this message translates to:
  /// **'New Category'**
  String get newCategory;

  /// Title for add new category dialog
  ///
  /// In en, this message translates to:
  /// **'Add New Category'**
  String get addNewCategory;

  /// Placeholder for category name field
  ///
  /// In en, this message translates to:
  /// **'e.g., Bills, Rent, Maintenance'**
  String get categoryNameHint;

  /// Text for update button in edit mode
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get update;

  /// Success message after updating category
  ///
  /// In en, this message translates to:
  /// **'Category updated successfully'**
  String get categoryUpdatedSuccess;

  /// Success message after adding new category
  ///
  /// In en, this message translates to:
  /// **'Category added successfully'**
  String get categoryAddedSuccess;

  /// Error message when trying to add duplicate category
  ///
  /// In en, this message translates to:
  /// **'This category already exists'**
  String get categoryAlreadyExists;

  /// Title for delete confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Confirm Delete'**
  String get confirmDelete;

  /// Confirmation question before deletion
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this category?'**
  String get deleteConfirmationQuestion;

  /// Warning message in delete dialog
  ///
  /// In en, this message translates to:
  /// **'The category will be permanently deleted and cannot be recovered'**
  String get deleteWarning;

  /// Success message after deleting category
  ///
  /// In en, this message translates to:
  /// **'Category deleted successfully'**
  String get categoryDeletedSuccess;

  /// Title of the employees report page in the app bar
  ///
  /// In en, this message translates to:
  /// **'Employees Report'**
  String get employees_report_title;

  /// Title of the detailed employees list section
  ///
  /// In en, this message translates to:
  /// **'Employees List'**
  String get employees_list_title;

  /// Title of the total paid salaries card
  ///
  /// In en, this message translates to:
  /// **'Total Salaries'**
  String get stat_total_salaries;

  /// Subtitle for salaries card (clarifying they are paid salaries)
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get stat_salaries_paid;

  /// Title of the advances balance card
  ///
  /// In en, this message translates to:
  /// **'Advances Balance'**
  String get stat_advances_balance;

  /// Subtitle for advances card (clarifying they are due advances)
  ///
  /// In en, this message translates to:
  /// **'Due'**
  String get stat_advances_due;

  /// Title of the active employees count card
  ///
  /// In en, this message translates to:
  /// **'Active Employees'**
  String get stat_active_employees;

  /// Unit of measurement for employee count
  ///
  /// In en, this message translates to:
  /// **'Employee'**
  String get stat_employee_unit;

  /// Message displayed while loading data
  ///
  /// In en, this message translates to:
  /// **'Loading data...'**
  String get loading_data;

  /// Beginning of error message when data loading fails
  ///
  /// In en, this message translates to:
  /// **'An error occurred'**
  String get error_occurred;

  /// Title of the message when there are no employees in the system
  ///
  /// In en, this message translates to:
  /// **'No Employees'**
  String get no_employees_title;

  /// Descriptive message when there are no employees in the system
  ///
  /// In en, this message translates to:
  /// **'No active employees have been registered yet'**
  String get no_employees_message;

  /// Label for the salary field in employee item
  ///
  /// In en, this message translates to:
  /// **'Salary'**
  String get employee_salary_label;

  /// Label for the advances field in employee item
  ///
  /// In en, this message translates to:
  /// **'Advances'**
  String get employee_advances_label;

  /// No description provided for @directSales.
  ///
  /// In en, this message translates to:
  /// **'Direct Sales'**
  String get directSales;

  /// No description provided for @invoices.
  ///
  /// In en, this message translates to:
  /// **'Invoices'**
  String get invoices;

  /// No description provided for @customersAndSuppliers.
  ///
  /// In en, this message translates to:
  /// **'Customers & Suppliers'**
  String get customersAndSuppliers;

  /// No description provided for @inventory.
  ///
  /// In en, this message translates to:
  /// **'Inventory'**
  String get inventory;

  /// No description provided for @employeeManagement.
  ///
  /// In en, this message translates to:
  /// **'Employee Management'**
  String get employeeManagement;

  /// No description provided for @reportsCenter.
  ///
  /// In en, this message translates to:
  /// **'Reports Center'**
  String get reportsCenter;

  /// No description provided for @system.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get system;

  /// No description provided for @systemAdmin.
  ///
  /// In en, this message translates to:
  /// **'System Admin'**
  String get systemAdmin;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @logoutConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Do you want to logout?'**
  String get logoutConfirmation;

  /// No description provided for @errorOpeningReports.
  ///
  /// In en, this message translates to:
  /// **'Error opening reports page'**
  String get errorOpeningReports;

  /// No description provided for @menu.
  ///
  /// In en, this message translates to:
  /// **'Menu'**
  String get menu;

  /// No description provided for @daytimemode.
  ///
  /// In en, this message translates to:
  /// **'Daytime mode'**
  String get daytimemode;

  /// No description provided for @nighttimemode.
  ///
  /// In en, this message translates to:
  /// **'Nighttime mode'**
  String get nighttimemode;

  /// No description provided for @selectCurrency.
  ///
  /// In en, this message translates to:
  /// **'Select Currency'**
  String get selectCurrency;

  /// No description provided for @currencyChanged.
  ///
  /// In en, this message translates to:
  /// **'Currency changed successfully'**
  String get currencyChanged;

  /// No description provided for @security.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get security;

  /// No description provided for @biometricLogin.
  ///
  /// In en, this message translates to:
  /// **'Biometric Login'**
  String get biometricLogin;

  /// No description provided for @biometricEnabled.
  ///
  /// In en, this message translates to:
  /// **'Biometric Enabled'**
  String get biometricEnabled;

  /// No description provided for @biometricDisabled.
  ///
  /// In en, this message translates to:
  /// **'Biometric Disabled'**
  String get biometricDisabled;

  /// No description provided for @disableBiometric.
  ///
  /// In en, this message translates to:
  /// **'Disable Biometric'**
  String get disableBiometric;

  /// No description provided for @disableBiometricConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to disable biometric?'**
  String get disableBiometricConfirmation;

  /// No description provided for @disable.
  ///
  /// In en, this message translates to:
  /// **'Disable'**
  String get disable;

  /// No description provided for @biometricDisabledSuccess.
  ///
  /// In en, this message translates to:
  /// **'Biometric disabled successfully'**
  String get biometricDisabledSuccess;

  /// No description provided for @or.
  ///
  /// In en, this message translates to:
  /// **'OR'**
  String get or;

  /// No description provided for @loginWithBiometric.
  ///
  /// In en, this message translates to:
  /// **'Login with Biometric'**
  String get loginWithBiometric;

  /// No description provided for @noUsersFound.
  ///
  /// In en, this message translates to:
  /// **'No users found'**
  String get noUsersFound;

  /// No description provided for @tryOnRealDevice.
  ///
  /// In en, this message translates to:
  /// **'You can try this feature on a real device'**
  String get tryOnRealDevice;

  /// No description provided for @quickStats.
  ///
  /// In en, this message translates to:
  /// **'Quick Stats'**
  String get quickStats;

  /// No description provided for @totalSales.
  ///
  /// In en, this message translates to:
  /// **'Total Sales'**
  String get totalSales;

  /// No description provided for @totalProfit.
  ///
  /// In en, this message translates to:
  /// **'Total Profit'**
  String get totalProfit;

  /// No description provided for @activeCustomers.
  ///
  /// In en, this message translates to:
  /// **'Active Customers'**
  String get activeCustomers;

  /// No description provided for @availableProducts.
  ///
  /// In en, this message translates to:
  /// **'Available Products'**
  String get availableProducts;

  /// No description provided for @smartAlerts.
  ///
  /// In en, this message translates to:
  /// **'Smart Alerts'**
  String get smartAlerts;

  /// No description provided for @lowStockAlert.
  ///
  /// In en, this message translates to:
  /// **'Low Stock Products'**
  String get lowStockAlert;

  /// No description provided for @lowStockAlertSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{count} products need reordering'**
  String lowStockAlertSubtitle(int count);

  /// No description provided for @overdueCustomersAlert.
  ///
  /// In en, this message translates to:
  /// **'Overdue Customers'**
  String get overdueCustomersAlert;

  /// No description provided for @overdueCustomersAlertSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{count} customers with overdue debts'**
  String overdueCustomersAlertSubtitle(int count);

  /// No description provided for @financialStats.
  ///
  /// In en, this message translates to:
  /// **'Financial Stats'**
  String get financialStats;

  /// No description provided for @totalDebts.
  ///
  /// In en, this message translates to:
  /// **'Total Debts'**
  String get totalDebts;

  /// No description provided for @totalPayments.
  ///
  /// In en, this message translates to:
  /// **'Total Payments'**
  String get totalPayments;

  /// No description provided for @collectionRate.
  ///
  /// In en, this message translates to:
  /// **'Collection Rate'**
  String get collectionRate;

  /// No description provided for @topBuyers.
  ///
  /// In en, this message translates to:
  /// **'Top Buyers'**
  String get topBuyers;

  /// No description provided for @topDebtors.
  ///
  /// In en, this message translates to:
  /// **'Top Debtors'**
  String get topDebtors;

  /// No description provided for @daysSinceLastTransaction.
  ///
  /// In en, this message translates to:
  /// **'{days} days since last transaction'**
  String daysSinceLastTransaction(int days);

  /// No description provided for @topSellingProducts.
  ///
  /// In en, this message translates to:
  /// **'Top Selling Products'**
  String get topSellingProducts;

  /// No description provided for @inStock.
  ///
  /// In en, this message translates to:
  /// **'In Stock'**
  String get inStock;

  /// No description provided for @monthlySalesChart.
  ///
  /// In en, this message translates to:
  /// **'Monthly Sales Chart'**
  String get monthlySalesChart;

  /// No description provided for @profitBySupplier.
  ///
  /// In en, this message translates to:
  /// **'Profit by Supplier'**
  String get profitBySupplier;

  /// No description provided for @lowStockProducts.
  ///
  /// In en, this message translates to:
  /// **'Low Stock Products'**
  String get lowStockProducts;

  /// No description provided for @overdueCustomers.
  ///
  /// In en, this message translates to:
  /// **'Overdue Customers'**
  String get overdueCustomers;

  /// No description provided for @productOutOfStock.
  ///
  /// In en, this message translates to:
  /// **'Product out of stock'**
  String get productOutOfStock;

  /// No description provided for @selectSaleDate.
  ///
  /// In en, this message translates to:
  /// **'Select sale date'**
  String get selectSaleDate;

  /// No description provided for @saleDate.
  ///
  /// In en, this message translates to:
  /// **'Sale Date'**
  String get saleDate;

  /// No description provided for @filterByDays.
  ///
  /// In en, this message translates to:
  /// **'Filter by Days'**
  String get filterByDays;

  /// Custom period button
  ///
  /// In en, this message translates to:
  /// **'Custom Period'**
  String get customDays;

  /// No description provided for @customize.
  ///
  /// In en, this message translates to:
  /// **'Customize'**
  String get customize;

  /// Days count display
  ///
  /// In en, this message translates to:
  /// **'{count} days'**
  String daysCount(String count);

  /// Custom days dialog title
  ///
  /// In en, this message translates to:
  /// **'Select Number of Days'**
  String get selectCustomDays;

  /// Days input field label
  ///
  /// In en, this message translates to:
  /// **'Number of Days'**
  String get numberOfDays;

  /// Apply changes button
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// No description provided for @statisticsinformation.
  ///
  /// In en, this message translates to:
  /// **'Statistics and information'**
  String get statisticsinformation;

  /// No description provided for @statistics.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get statistics;

  /// No description provided for @erroefirger.
  ///
  /// In en, this message translates to:
  /// **'The device does not support fingerprinting'**
  String get erroefirger;

  /// No description provided for @thedatabasefile.
  ///
  /// In en, this message translates to:
  /// **'The database file does not exist'**
  String get thedatabasefile;

  /// No description provided for @accountingbackupfile.
  ///
  /// In en, this message translates to:
  /// **'Accounting app backup file 📦'**
  String get accountingbackupfile;

  /// No description provided for @sharecancelled.
  ///
  /// In en, this message translates to:
  /// **'Share cancelled'**
  String get sharecancelled;

  /// No description provided for @contactInformation.
  ///
  /// In en, this message translates to:
  /// **'Contact Information'**
  String get contactInformation;

  /// No description provided for @legalInformation.
  ///
  /// In en, this message translates to:
  /// **'Legal Information'**
  String get legalInformation;

  /// No description provided for @companyLogo.
  ///
  /// In en, this message translates to:
  /// **'Company Logo'**
  String get companyLogo;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// No description provided for @address.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address;

  /// No description provided for @commercialRegistrationNumber.
  ///
  /// In en, this message translates to:
  /// **'Commercial Registration Number'**
  String get commercialRegistrationNumber;

  /// Backup success dialog title
  ///
  /// In en, this message translates to:
  /// **'Success! ✓'**
  String get backupSuccessTitle;

  /// Backup success message content
  ///
  /// In en, this message translates to:
  /// **'Backup file saved to Downloads folder'**
  String get backupSuccessContent;

  /// Backup file location label
  ///
  /// In en, this message translates to:
  /// **'File location:'**
  String get backupFileLocation;

  /// Path copied to clipboard message
  ///
  /// In en, this message translates to:
  /// **'Path copied'**
  String get pathCopied;

  /// Copy path button tooltip
  ///
  /// In en, this message translates to:
  /// **'Copy path'**
  String get copyPath;

  /// Share button
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// Button to share last created backup file
  ///
  /// In en, this message translates to:
  /// **'Share last backup'**
  String get shareLastBackup;

  /// Share failed message
  ///
  /// In en, this message translates to:
  /// **'Share failed'**
  String get shareFailed;

  /// Filter button tooltip
  ///
  /// In en, this message translates to:
  /// **'Filter Overdue Customers'**
  String get filterOverdueCustomers;

  /// Period selection section title
  ///
  /// In en, this message translates to:
  /// **'Select Period'**
  String get selectPeriod;

  /// Empty state title
  ///
  /// In en, this message translates to:
  /// **'No Overdue Customers! 🎉'**
  String get noOverdueCustomers;

  /// Empty state message
  ///
  /// In en, this message translates to:
  /// **'All customers are active within the last {days} days'**
  String noOverdueCustomersMessage(int days);

  /// Debt label
  ///
  /// In en, this message translates to:
  /// **'Debt'**
  String get debt;

  /// No description provided for @appLocked.
  ///
  /// In en, this message translates to:
  /// **'App Locked'**
  String get appLocked;

  /// No description provided for @appLockedDescription.
  ///
  /// In en, this message translates to:
  /// **'App locked for security'**
  String get appLockedDescription;

  /// No description provided for @lastActive.
  ///
  /// In en, this message translates to:
  /// **'Last active'**
  String get lastActive;

  /// No description provided for @fewMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'few minutes ago'**
  String get fewMinutesAgo;

  /// No description provided for @unlock.
  ///
  /// In en, this message translates to:
  /// **'Unlock'**
  String get unlock;

  /// No description provided for @unlockWithBiometric.
  ///
  /// In en, this message translates to:
  /// **'Unlock with Biometric'**
  String get unlockWithBiometric;

  /// No description provided for @enterPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter password'**
  String get enterPassword;

  /// No description provided for @wrongPassword.
  ///
  /// In en, this message translates to:
  /// **'Wrong password'**
  String get wrongPassword;

  /// No description provided for @attemptsRemaining.
  ///
  /// In en, this message translates to:
  /// **'attempts remaining'**
  String get attemptsRemaining;

  /// No description provided for @tooManyAttempts.
  ///
  /// In en, this message translates to:
  /// **'Too many failed attempts. Please try again after 30 seconds'**
  String get tooManyAttempts;

  /// No description provided for @lockedOut.
  ///
  /// In en, this message translates to:
  /// **'Temporarily locked. Wait'**
  String get lockedOut;

  /// No description provided for @seconds.
  ///
  /// In en, this message translates to:
  /// **'seconds'**
  String get seconds;

  /// No description provided for @appLockSettings.
  ///
  /// In en, this message translates to:
  /// **'App Lock Settings'**
  String get appLockSettings;

  /// No description provided for @appLockSettingsDescription.
  ///
  /// In en, this message translates to:
  /// **'Enable lock when leaving the app'**
  String get appLockSettingsDescription;

  /// No description provided for @enableAppLock.
  ///
  /// In en, this message translates to:
  /// **'Enable Auto Lock'**
  String get enableAppLock;

  /// No description provided for @appLockEnabled.
  ///
  /// In en, this message translates to:
  /// **'Auto lock enabled'**
  String get appLockEnabled;

  /// No description provided for @appLockDisabled.
  ///
  /// In en, this message translates to:
  /// **'Auto lock disabled'**
  String get appLockDisabled;

  /// No description provided for @appLockEnabledSuccess.
  ///
  /// In en, this message translates to:
  /// **'Auto lock enabled successfully'**
  String get appLockEnabledSuccess;

  /// No description provided for @appLockDisabledSuccess.
  ///
  /// In en, this message translates to:
  /// **'Auto lock disabled successfully'**
  String get appLockDisabledSuccess;

  /// No description provided for @lockDuration.
  ///
  /// In en, this message translates to:
  /// **'Lock Duration'**
  String get lockDuration;

  /// No description provided for @immediately.
  ///
  /// In en, this message translates to:
  /// **'Immediately'**
  String get immediately;

  /// No description provided for @oneMinute.
  ///
  /// In en, this message translates to:
  /// **'1 minute'**
  String get oneMinute;

  /// No description provided for @twoMinutes.
  ///
  /// In en, this message translates to:
  /// **'2 minutes'**
  String get twoMinutes;

  /// No description provided for @fiveMinutes.
  ///
  /// In en, this message translates to:
  /// **'5 minutes'**
  String get fiveMinutes;

  /// No description provided for @tenMinutes.
  ///
  /// In en, this message translates to:
  /// **'10 minutes'**
  String get tenMinutes;

  /// No description provided for @lockDurationChanged.
  ///
  /// In en, this message translates to:
  /// **'Duration changed to'**
  String get lockDurationChanged;

  /// No description provided for @appLockInfo.
  ///
  /// In en, this message translates to:
  /// **'The app will be automatically locked after leaving it for the specified duration. You can unlock using your password or biometric authentication.'**
  String get appLockInfo;
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
