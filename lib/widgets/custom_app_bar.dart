import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../providers/theme_provider.dart';
import '../services/auth_service.dart'; // ← أضف هذا
import '../theme/app_colors.dart';
import '../theme/app_constants.dart';

/// AppBar مخصص مع شعار الشركة واسم المستخدم
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final VoidCallback? onMenuTap;
  final bool showLogo;
  final bool showUserInfo;

  const CustomAppBar({
    super.key,
    required this.title,
    this.actions,
    this.onMenuTap,
    this.showLogo = true,
    this.showUserInfo = true,
  });

  @override
  Size get preferredSize => const Size.fromHeight(AppConstants.appBarHeight);

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;
    final l10n = AppLocalizations.of(context)!;

    return AppBar(
      elevation: 0,
      toolbarHeight: AppConstants.appBarHeight,
      
      // ============= Leading (قائمة الدرج) =============
      leading: IconButton(
        icon: const Icon(Icons.menu),
        onPressed: onMenuTap ?? () {
          Scaffold.of(context).openDrawer();
        },
        // tooltip: 'القائمة',
        tooltip: l10n.menu,
      ),
      
      // ============= Title =============
      title: Row(
        children: [
          // شعار الشركة (اختياري)
          if (showLogo) ...[
            Container(
              width: AppConstants.logoSizeSm,
              height: AppConstants.logoSizeSm,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: AppConstants.borderRadiusSm,
              ),
              child: const Icon(
                Icons.store,
                color: AppColors.primaryLight,
                size: 24,
              ),
            ),
            const SizedBox(width: AppConstants.spacingMd),
          ],
          
          // اسم الصفحة
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      
      // ============= Actions =============
      actions: [
        // زر تبديل الثيم
        IconButton(
          icon: Icon(
            isDark ? Icons.light_mode : Icons.dark_mode,
          ),
          onPressed: () {
            themeProvider.toggleTheme();
          },
          // الوضع النهاري والليلي - تدوين كلمات
          tooltip: isDark ? l10n.daytimemode : l10n.nighttimemode,
        ),
        
        // معلومات المستخدم (اختياري)
        if (showUserInfo) ...[
          _buildUserInfo(context, isDark),
        ],
        
        // Actions إضافية
        if (actions != null) ...actions!,
        
        const SizedBox(width: AppConstants.spacingSm),
      ],
    );
  }

  /// بناء معلومات المستخدم
  Widget _buildUserInfo(BuildContext context, bool isDark) {
    final authService = AuthService(); // ← جلب بيانات المستخدم
    final user = authService.currentUser;
    final l10n = AppLocalizations.of(context)!;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.spacingSm),
      child: Row(
        children: [
          // اسم المستخدم
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                // user?.fullName ?? 'مستخدم', // ← الاسم الحقيقي!
                user?.fullName ?? l10n.user, // ← الاسم الحقيقي!

                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.textPrimaryDark : Colors.white,
                ),
              ),
              Text(
                // user?.isAdmin == true ? 'مدير النظام' : 'مستخدم', // ← الصلاحية!
                user?.isAdmin == true ? l10n.systemAdmin : l10n.user, // ← الصلاحية!
                style: TextStyle(
                  fontSize: 11,
                  color: isDark 
                      ? AppColors.textSecondaryDark 
                      : Colors.white.withOpacity(0.8),
                ),
              ),
            ],
          ),
          
          const SizedBox(width: AppConstants.spacingSm),
          
          // صورة المستخدم
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.white,
            child: Icon(
              Icons.person,
              color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}