import 'package:flutter/material.dart';

/// Semantic type of message being shown; drives color and icon.
/// Shared between [AppSnackBar] (OverlayEntry-based) and
/// [AppSnackBarMessenger] (ScaffoldMessenger-based) so both look
/// identical.
enum AppSnackBarType { success, error, warning, info }

/// Centralized color/icon mapping so both snack bar implementations stay
/// visually in sync.
class AppSnackBarStyleHelper {
  AppSnackBarStyleHelper._();

  static Color colorFor(AppSnackBarType type) {
    switch (type) {
      case AppSnackBarType.success:
        return const Color(0xFF2E7D32);
      case AppSnackBarType.error:
        return const Color(0xFFC62828);
      case AppSnackBarType.warning:
        return const Color(0xFFF9A825);
      case AppSnackBarType.info:
        return const Color(0xFF1565C0);
    }
  }

  static IconData iconFor(AppSnackBarType type) {
    switch (type) {
      case AppSnackBarType.success:
        return Icons.check_circle;
      case AppSnackBarType.error:
        return Icons.error;
      case AppSnackBarType.warning:
        return Icons.warning_amber_rounded;
      case AppSnackBarType.info:
        return Icons.info;
    }
  }

  /// Standard content row: icon + message, used by both implementations.
  static Widget buildContent(AppSnackBarType type, String message) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(iconFor(type), color: Colors.white, size: 20),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            message,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}