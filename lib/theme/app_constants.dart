import 'package:flutter/material.dart';

/// ثوابت التطبيق للأحجام والمسافات
class AppConstants {
  AppConstants._();
  
  // ============= Spacing (المسافات) - مُصغّرة =============
  static const double spacingXs = 3.0;   // كانت 4
  static const double spacingSm = 6.0;   // كانت 8
  static const double spacingMd = 12.0;  // كانت 16
  static const double spacingLg = 18.0;  // كانت 24
  static const double spacingXl = 24.0;  // كانت 32
  static const double spacing2Xl = 36.0; // كانت 48
  
  // ============= Padding - مُصغّرة =============
  static const EdgeInsets paddingXs = EdgeInsets.all(spacingXs);
  static const EdgeInsets paddingSm = EdgeInsets.all(spacingSm);
  static const EdgeInsets paddingMd = EdgeInsets.all(spacingMd);
  static const EdgeInsets paddingLg = EdgeInsets.all(spacingLg);
  static const EdgeInsets paddingXl = EdgeInsets.all(spacingXl);
  
  // Horizontal & Vertical Padding
  static const EdgeInsets paddingHorizontalMd = EdgeInsets.symmetric(horizontal: spacingMd);
  static const EdgeInsets paddingHorizontalLg = EdgeInsets.symmetric(horizontal: spacingLg);
  static const EdgeInsets paddingVerticalMd = EdgeInsets.symmetric(vertical: spacingMd);
  static const EdgeInsets paddingVerticalLg = EdgeInsets.symmetric(vertical: spacingLg);
  
  // Screen Padding (للصفحات) - مُصغّرة
  static const EdgeInsets screenPadding = EdgeInsets.all(12.0);  // كانت 16
  static const EdgeInsets screenPaddingHorizontal = EdgeInsets.symmetric(horizontal: 12.0);
  
  // ============= Border Radius - مُصغّرة قليلاً =============
  static const double radiusXs = 4.0;
  static const double radiusSm = 6.0;   // كانت 8
  static const double radiusMd = 10.0;  // كانت 12
  static const double radiusLg = 14.0;  // كانت 16
  static const double radiusXl = 20.0;  // كانت 24
  static const double radiusFull = 999.0;
  
  static const BorderRadius borderRadiusXs = BorderRadius.all(Radius.circular(radiusXs));
  static const BorderRadius borderRadiusSm = BorderRadius.all(Radius.circular(radiusSm));
  static const BorderRadius borderRadiusMd = BorderRadius.all(Radius.circular(radiusMd));
  static const BorderRadius borderRadiusLg = BorderRadius.all(Radius.circular(radiusLg));
  static const BorderRadius borderRadiusXl = BorderRadius.all(Radius.circular(radiusXl));
  static const BorderRadius borderRadiusFull = BorderRadius.all(Radius.circular(radiusFull));
  
  // ============= Icon Sizes - مُصغّرة =============
  static const double iconSizeXs = 14.0;  // كانت 16
  static const double iconSizeSm = 18.0;  // كانت 20
  static const double iconSizeMd = 22.0;  // كانت 24
  static const double iconSizeLg = 28.0;  // كانت 32
  static const double iconSizeXl = 40.0;  // كانت 48
  static const double iconSize2Xl = 56.0; // كانت 64
  
  // ============= Button Heights - مُصغّرة =============
  static const double buttonHeightSm = 32.0;  // كانت 36
  static const double buttonHeightMd = 40.0;  // كانت 44
  static const double buttonHeightLg = 46.0;  // كانت 52
  
  // ============= App Bar - مُصغّرة =============
  static const double appBarHeight = 56.0;  // كانت 64
  static const double appBarElevation = 0.0;
  
  // ============= Bottom Navigation - مُصغّرة =============
  static const double bottomNavHeight = 56.0;  // كانت 64
  static const double bottomNavIconSize = 22.0; // كانت 24
  
  // ============= Drawer =============
  static const double drawerWidth = 280.0;
  static const double drawerHeaderHeight = 160.0; // كانت 180
  
  // ============= Cards - مُصغّرة =============
  static const double cardElevation = 0.5;
  static const BorderRadius cardBorderRadius = borderRadiusMd;
  
  // ============= Divider =============
  static const double dividerThickness = 1.0;
  static const double dividerIndent = spacingMd;
  
  // ============= Avatar - مُصغّرة =============
  static const double avatarSizeSm = 28.0;  // كانت 32
  static const double avatarSizeMd = 40.0;  // كانت 48
  static const double avatarSizeLg = 56.0;  // كانت 64
  static const double avatarSizeXl = 80.0;  // كانت 96
  
  // ============= Logo - مُصغّرة =============
  static const double logoSizeSm = 36.0;  // كانت 40
  static const double logoSizeMd = 48.0;  // كانت 56
  static const double logoSizeLg = 68.0;  // كانت 80
  
  // ============= Input Fields - مُصغّرة =============
  static const double inputHeight = 42.0;  // كانت 48
  static const double inputBorderWidth = 1.5;
  static const BorderRadius inputBorderRadius = borderRadiusMd;
  
  // ============= Shadows - مُخففة =============
  static const List<BoxShadow> shadowSm = [
    BoxShadow(
      color: Color(0x08000000),  // كانت 0A
      blurRadius: 3,
      offset: Offset(0, 1),
    ),
  ];
  
  static const List<BoxShadow> shadowMd = [
    BoxShadow(
      color: Color(0x10000000),  // كانت 14
      blurRadius: 6,
      offset: Offset(0, 3),
    ),
  ];
  
  static const List<BoxShadow> shadowLg = [
    BoxShadow(
      color: Color(0x18000000),  // كانت 1F
      blurRadius: 12,
      offset: Offset(0, 6),
    ),
  ];
  
  // ============= Animation Durations =============
  static const Duration animationFast = Duration(milliseconds: 200);
  static const Duration animationNormal = Duration(milliseconds: 300);
  static const Duration animationSlow = Duration(milliseconds: 500);
  
  // ============= Breakpoints (للـ Responsive) =============
  static const double breakpointMobile = 600;
  static const double breakpointTablet = 900;
  static const double breakpointDesktop = 1200;
  
  // ============= Maximum Widths =============
  static const double maxContentWidth = 1200;
  static const double maxDialogWidth = 600;
  static const double maxCardWidth = 400;
  
  // ============= List Tile - مُصغّرة =============
  static const double listTileHeight = 56.0;  // كانت 64
  static const EdgeInsets listTilePadding = EdgeInsets.symmetric(
    horizontal: spacingMd,
    vertical: spacingSm,
  );
  
  // ============= Data Table - مُصغّرة =============
  static const double tableRowHeight = 48.0;  // كانت 56
  static const double tableHeaderHeight = 56.0; // كانت 64
}

/// امتداد للتحقق من حجم الشاشة
extension ResponsiveExtension on BuildContext {
  /// هل الجهاز موبايل؟
  bool get isMobile => MediaQuery.of(this).size.width < AppConstants.breakpointMobile;
  
  /// هل الجهاز تابلت؟
  bool get isTablet => MediaQuery.of(this).size.width >= AppConstants.breakpointMobile &&
      MediaQuery.of(this).size.width < AppConstants.breakpointDesktop;
  
  /// هل الجهاز ديسكتوب؟
  bool get isDesktop => MediaQuery.of(this).size.width >= AppConstants.breakpointDesktop;
  
  /// عرض الشاشة
  double get screenWidth => MediaQuery.of(this).size.width;
  
  /// ارتفاع الشاشة
  double get screenHeight => MediaQuery.of(this).size.height;
  
  /// الحصول على Padding حسب حجم الشاشة
  EdgeInsets get responsivePadding {
    if (isMobile) return AppConstants.screenPadding;
    if (isTablet) return AppConstants.paddingLg;
    return AppConstants.paddingXl;
  }
}