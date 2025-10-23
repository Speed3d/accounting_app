import 'package:flutter/material.dart';

/// ثوابت التطبيق للأحجام والمسافات
class AppConstants {
  AppConstants._();
  
  // ============= Spacing (المسافات) =============
  static const double spacingXs = 4.0;
  static const double spacingSm = 8.0;
  static const double spacingMd = 16.0;
  static const double spacingLg = 24.0;
  static const double spacingXl = 32.0;
  static const double spacing2Xl = 48.0;
  
  // ============= Padding =============
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
  
  // Screen Padding (للصفحات)
  static const EdgeInsets screenPadding = EdgeInsets.all(spacingMd);
  static const EdgeInsets screenPaddingHorizontal = EdgeInsets.symmetric(horizontal: spacingMd);
  
  // ============= Border Radius =============
  static const double radiusXs = 4.0;
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 24.0;
  static const double radiusFull = 999.0;
  
  static const BorderRadius borderRadiusXs = BorderRadius.all(Radius.circular(radiusXs));
  static const BorderRadius borderRadiusSm = BorderRadius.all(Radius.circular(radiusSm));
  static const BorderRadius borderRadiusMd = BorderRadius.all(Radius.circular(radiusMd));
  static const BorderRadius borderRadiusLg = BorderRadius.all(Radius.circular(radiusLg));
  static const BorderRadius borderRadiusXl = BorderRadius.all(Radius.circular(radiusXl));
  static const BorderRadius borderRadiusFull = BorderRadius.all(Radius.circular(radiusFull));
  
  // ============= Icon Sizes =============
  static const double iconSizeXs = 16.0;
  static const double iconSizeSm = 20.0;
  static const double iconSizeMd = 24.0;
  static const double iconSizeLg = 32.0;
  static const double iconSizeXl = 48.0;
  static const double iconSize2Xl = 64.0;
  
  // ============= Button Heights =============
  static const double buttonHeightSm = 36.0;
  static const double buttonHeightMd = 44.0;
  static const double buttonHeightLg = 52.0;
  
  // ============= App Bar =============
  static const double appBarHeight = 64.0;
  static const double appBarElevation = 0.0; // Material 3 style
  
  // ============= Bottom Navigation =============
  static const double bottomNavHeight = 64.0;
  static const double bottomNavIconSize = 24.0;
  
  // ============= Drawer =============
  static const double drawerWidth = 280.0;
  static const double drawerHeaderHeight = 180.0;
  
  // ============= Cards =============
  static const double cardElevation = 0.5;
  static const BorderRadius cardBorderRadius = borderRadiusMd;
  
  // ============= Divider =============
  static const double dividerThickness = 1.0;
  static const double dividerIndent = spacingMd;
  
  // ============= Avatar =============
  static const double avatarSizeSm = 32.0;
  static const double avatarSizeMd = 48.0;
  static const double avatarSizeLg = 64.0;
  static const double avatarSizeXl = 96.0;
  
  // ============= Logo =============
  static const double logoSizeSm = 40.0;
  static const double logoSizeMd = 56.0;
  static const double logoSizeLg = 80.0;
  
  // ============= Input Fields =============
  static const double inputHeight = 48.0;
  static const double inputBorderWidth = 1.5;
  static const BorderRadius inputBorderRadius = borderRadiusMd;
  
  // ============= Shadows =============
  static const List<BoxShadow> shadowSm = [
    BoxShadow(
      color: Color(0x0A000000),
      blurRadius: 4,
      offset: Offset(0, 2),
    ),
  ];
  
  static const List<BoxShadow> shadowMd = [
    BoxShadow(
      color: Color(0x14000000),
      blurRadius: 8,
      offset: Offset(0, 4),
    ),
  ];
  
  static const List<BoxShadow> shadowLg = [
    BoxShadow(
      color: Color(0x1F000000),
      blurRadius: 16,
      offset: Offset(0, 8),
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
  
  // ============= List Tile =============
  static const double listTileHeight = 64.0;
  static const EdgeInsets listTilePadding = EdgeInsets.symmetric(
    horizontal: spacingMd,
    vertical: spacingSm,
  );
  
  // ============= Data Table =============
  static const double tableRowHeight = 56.0;
  static const double tableHeaderHeight = 64.0;
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