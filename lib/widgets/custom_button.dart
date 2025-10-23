import 'package:flutter/material.dart';
import '../theme/app_constants.dart';

/// أزرار مخصصة موحدة
class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final ButtonType type;
  final ButtonSize size;
  final IconData? icon;
  final bool isLoading;
  final bool fullWidth;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.type = ButtonType.primary,
    this.size = ButtonSize.medium,
    this.icon,
    this.isLoading = false,
    this.fullWidth = true,
  });

  @override
  Widget build(BuildContext context) {
    // الارتفاع حسب الحجم
    final double height = size == ButtonSize.small
        ? AppConstants.buttonHeightSm
        : size == ButtonSize.large
            ? AppConstants.buttonHeightLg
            : AppConstants.buttonHeightMd;

    // المحتوى
    Widget content = Row(
      mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading)
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                type == ButtonType.primary ? Colors.white : Theme.of(context).primaryColor,
              ),
            ),
          )
        else ...[
          if (icon != null) ...[
            Icon(icon, size: 20),
            const SizedBox(width: AppConstants.spacingSm),
          ],
          Text(text),
        ],
      ],
    );

    // حسب النوع
    switch (type) {
      case ButtonType.primary:
        return SizedBox(
          width: fullWidth ? double.infinity : null,
          height: height,
          child: ElevatedButton(
            onPressed: isLoading ? null : onPressed,
            child: content,
          ),
        );

      case ButtonType.secondary:
        return SizedBox(
          width: fullWidth ? double.infinity : null,
          height: height,
          child: OutlinedButton(
            onPressed: isLoading ? null : onPressed,
            child: content,
          ),
        );

      case ButtonType.text:
        return SizedBox(
          width: fullWidth ? double.infinity : null,
          height: height,
          child: TextButton(
            onPressed: isLoading ? null : onPressed,
            child: content,
          ),
        );
    }
  }
}

/// أنواع الأزرار
enum ButtonType {
  primary,
  secondary,
  text,
}

/// أحجام الأزرار
enum ButtonSize {
  small,
  medium,
  large,
}