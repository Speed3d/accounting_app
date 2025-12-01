import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/database_helper.dart';
import '../l10n/app_localizations.dart';
import '../providers/theme_provider.dart';
import '../services/session_service.dart'; // 🆕 استبدال AuthService بـ SessionService
import '../theme/app_colors.dart';
import '../theme/app_constants.dart';

/// AppBar مخصص مع شعار الشركة واسم المستخدم
class CustomAppBar extends StatefulWidget implements PreferredSizeWidget {
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
  State<CustomAppBar> createState() => _CustomAppBarState();
}

class _CustomAppBarState extends State<CustomAppBar> {
  String? _companyLogoPath;

  @override
  void initState() {
    super.initState();
    _loadCompanyLogo();
  }

  /// تحميل شعار الشركة من الإعدادات
  Future<void> _loadCompanyLogo() async {
    try {
      final settings = await DatabaseHelper.instance.getAppSettings();
      final logoPath = settings['companyLogoPath'];
      if (logoPath != null && logoPath.isNotEmpty) {
        final file = File(logoPath);
        if (file.existsSync()) {
          setState(() {
            _companyLogoPath = logoPath;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading company logo: $e');
    }
  }

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
        onPressed: widget.onMenuTap ?? () {
          Scaffold.of(context).openDrawer();
        },
        tooltip: l10n.menu,
      ),
      
      // ============= Title =============
      title: Row(
        children: [
          // ✅ شعار الشركة (صورة حقيقية أو أيقونة)
          if (widget.showLogo) ...[
            _buildCompanyLogo(isDark),
            const SizedBox(width: AppConstants.spacingMd),
          ],
          
          // اسم الصفحة
          Expanded(
            child: Text(
              widget.title,
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
          tooltip: isDark ? l10n.daytimemode : l10n.nighttimemode,
        ),
        
        // معلومات المستخدم (اختياري)
        if (widget.showUserInfo) ...[
          _buildUserInfo(context, isDark),
        ],
        
        // Actions إضافية
        if (widget.actions != null) ...widget.actions!,
        
        const SizedBox(width: AppConstants.spacingSm),
      ],
    );
  }

  /// ✅ بناء شعار الشركة (صورة حقيقية أو أيقونة افتراضية)
  Widget _buildCompanyLogo(bool isDark) {
    return Container(
      width: AppConstants.logoSizeSm,
      height: AppConstants.logoSizeSm,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppConstants.borderRadiusSm,
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: AppConstants.borderRadiusSm,
        child: _companyLogoPath != null
            ? Image.file(
                File(_companyLogoPath!),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.store,
                    color: AppColors.primaryLight,
                    size: 24,
                  );
                },
              )
            : const Icon(
                Icons.store,
                color: AppColors.primaryLight,
                size: 24,
              ),
      ),
    );
  }

  /// ✅ بناء معلومات المستخدم (النظام الجديد - SessionService)
  /// ← Hint: استخدام FutureBuilder للحصول على البيانات من SessionService
  Widget _buildUserInfo(BuildContext context, bool isDark) {
    final l10n = AppLocalizations.of(context)!;

    return FutureBuilder<Map<String, String?>>(
      future: _getUserInfo(),
      builder: (context, snapshot) {
        final displayName = snapshot.data?['displayName'] ?? l10n.user;
        final photoURL = snapshot.data?['photoURL'];

        // ← Hint: لا توجد صور محلية بعد الآن - فقط من Firebase Storage
        final hasUserImage = photoURL != null && photoURL.isNotEmpty;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppConstants.spacingSm),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // اسم المستخدم - بحجم أصغر
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    displayName,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.textPrimaryDark : Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    l10n.systemAdmin, // ← Hint: كل مستخدم admin في النظام الجديد
                    style: TextStyle(
                      fontSize: 10,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : Colors.white.withOpacity(0.8),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),

              const SizedBox(width: AppConstants.spacingSm),

              // ✅ صورة المستخدم من Firebase Storage
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: ClipOval(
                  child: hasUserImage
                      ? Image.network(
                          photoURL!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.person,
                              color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
                              size: 20,
                            );
                          },
                        )
                      : Icon(
                          Icons.person,
                          color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
                          size: 20,
                        ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// ← Hint: دالة مساعدة للحصول على معلومات المستخدم من SessionService
  Future<Map<String, String?>> _getUserInfo() async {
    try {
      final displayName = await SessionService.instance.getDisplayName();
      final photoURL = await SessionService.instance.getPhotoURL();

      return {
        'displayName': displayName ?? '',
        'photoURL': photoURL,
      };
    } catch (e) {
      debugPrint('⚠️ خطأ في الحصول على معلومات المستخدم: $e');
      return {
        'displayName': '',
        'photoURL': null,
      };
    }
  }
}