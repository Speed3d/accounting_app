// lib/screens/settings/app_lock_settings_screen.dart

import 'package:flutter/material.dart';
import '../../services/app_lock_service.dart';
import '../../services/biometric_service.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_constants.dart';

/// ⚙️ شاشة إعدادات قفل التطبيق
class AppLockSettingsScreen extends StatefulWidget {
  const AppLockSettingsScreen({super.key});

  @override
  State<AppLockSettingsScreen> createState() => _AppLockSettingsScreenState();
}

class _AppLockSettingsScreenState extends State<AppLockSettingsScreen> {
  bool _isLockEnabled = false;
  int _selectedDuration = 1;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    await AppLockService.instance.loadSettings();
    
    if (mounted) {
      setState(() {
        _isLockEnabled = AppLockService.instance.isLockEnabled;
        _selectedDuration = AppLockService.instance.lockDurationMinutes;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appLockSettings),
      ),
      body: ListView(
        padding: AppConstants.screenPadding,
        children: [
          const SizedBox(height: AppConstants.spacingMd),

          // ← Hint: بطاقة تفعيل/إيقاف القفل
          Card(
            child: SwitchListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppConstants.spacingMd,
                vertical: AppConstants.spacingSm,
              ),
              title: Text(
                l10n.enableAppLock,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                _isLockEnabled 
                  ? l10n.appLockEnabled 
                  : l10n.appLockDisabled,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              secondary: Container(
                padding: const EdgeInsets.all(AppConstants.spacingSm),
                decoration: BoxDecoration(
                  color: (_isLockEnabled ? AppColors.success : AppColors.error)
                    .withOpacity(0.1),
                  borderRadius: AppConstants.borderRadiusMd,
                ),
                child: Icon(
                  _isLockEnabled ? Icons.lock : Icons.lock_open,
                  color: _isLockEnabled ? AppColors.success : AppColors.error,
                ),
              ),
              value: _isLockEnabled,
              onChanged: (value) async {
                if (value) {
                  await AppLockService.instance.enableLock();
                } else {
                  await AppLockService.instance.disableLock();
                }
                
                setState(() {
                  _isLockEnabled = value;
                });

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.white),
                          const SizedBox(width: AppConstants.spacingSm),
                          Text(
                            value 
                              ? l10n.appLockEnabledSuccess 
                              : l10n.appLockDisabledSuccess,
                          ),
                        ],
                      ),
                      backgroundColor: AppColors.success,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
            ),
          ),

          const SizedBox(height: AppConstants.spacingLg),

          // ← Hint: بطاقة اختيار المدة
          if (_isLockEnabled) ...[
            _buildSectionHeader(
              context,
              title: l10n.lockDuration,
              icon: Icons.timer_outlined,
              isDark: isDark,
            ),

            const SizedBox(height: AppConstants.spacingSm),

            Card(
              child: Column(
                children: [
                  _buildDurationTile(0, l10n.immediately, isDark),
                  _buildDivider(isDark),
                  _buildDurationTile(1, l10n.oneMinute, isDark),
                  _buildDivider(isDark),
                  _buildDurationTile(2, l10n.twoMinutes, isDark),
                  _buildDivider(isDark),
                  _buildDurationTile(5, l10n.fiveMinutes, isDark),
                  _buildDivider(isDark),
                  _buildDurationTile(10, l10n.tenMinutes, isDark),
                ],
              ),
            ),

            const SizedBox(height: AppConstants.spacingLg),

            // ← Hint: معلومات إضافية
            Container(
              padding: AppConstants.paddingMd,
              decoration: BoxDecoration(
                color: AppColors.info.withOpacity(0.1),
                borderRadius: AppConstants.borderRadiusMd,
                border: Border.all(
                  color: AppColors.info.withOpacity(0.3),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppColors.info,
                    size: 20,
                  ),
                  const SizedBox(width: AppConstants.spacingSm),
                  Expanded(
                    child: Text(
                      l10n.appLockInfo,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context, {
    required String title,
    required IconData icon,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.spacingSm),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: (isDark ? AppColors.primaryDark : AppColors.primaryLight)
                .withOpacity(0.1),
              borderRadius: AppConstants.borderRadiusSm,
            ),
            child: Icon(
              icon,
              size: 16,
              color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
            ),
          ),
          const SizedBox(width: AppConstants.spacingSm),
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDurationTile(int minutes, String label, bool isDark) {
    final isSelected = _selectedDuration == minutes;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingMd,
        vertical: AppConstants.spacingXs,
      ),
      leading: Icon(
        isSelected ? Icons.check_circle : Icons.circle_outlined,
        color: isSelected ? AppColors.success : AppColors.textSecondaryLight,
      ),
      title: Text(
        label,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          color: isSelected ? AppColors.success : null,
        ),
      ),
      onTap: () async {
        await AppLockService.instance.setLockDuration(minutes);
        
        setState(() {
          _selectedDuration = minutes;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: AppConstants.spacingSm),
                  Text('${AppLocalizations.of(context)!.lockDurationChanged}: $label'),
                ],
              ),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 1),
            ),
          );
        }
      },
    );
  }

  Widget _buildDivider(bool isDark) {
    return Divider(
      height: 1,
      thickness: 1,
      color: isDark ? AppColors.borderDark : AppColors.borderLight,
    );
  }
}