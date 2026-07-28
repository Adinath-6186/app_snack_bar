import 'package:flutter/material.dart';
import 'package:practiva/core/constant/app_keys.dart';

import 'app_snack_bar_controller.dart';
import 'app_snack_bar_style.dart';

/// ScaffoldMessenger-based alternative to [AppSnackBar].
///
/// [AppSnackBar] renders via a raw `OverlayEntry`: it floats freely above
/// everything and needs a `NavigatorState`/`Overlay` to hook into.
/// `AppSnackBarMessenger` instead rides on Flutter's built-in
/// `ScaffoldMessenger` + `SnackBar`, which means:
///
/// - It automatically avoids a `Scaffold`'s `bottomNavigationBar` (no
///   overlay/root-vs-nearest concerns at all).
/// - Slide animation + swipe-to-dismiss come from Flutter's own SnackBar
///   for free.
/// - Only-one-at-a-time / queuing is handled by ScaffoldMessenger itself.
///
/// The trade-off: it needs a `BuildContext` that has a `ScaffoldMessenger`
/// ancestor (which `MaterialApp`/`MaterialApp.router` always provides),
/// and it renders within that Scaffold's bounds rather than floating
/// completely freely.
///
/// How pause/resume works: Flutter's `SnackBar` has no exposed API to
/// pause its own auto-dismiss timer, so we give it a very long duration
/// (effectively "never") and drive dismissal ourselves with the same
/// [AppSnackBarController] used by [AppSnackBar]. `pause()`/`resume()`
/// just stop/restart that external timer; the SnackBar widget itself
/// doesn't need to know anything changed.
///
/// Setup (once, in your `MaterialApp`):
/// ```dart
/// MaterialApp(
///   scaffoldMessengerKey: AppSnackBarMessenger.scaffoldMessengerKey,
///   home: const HomePage(),
/// )
/// ```
///
/// Usage (from anywhere, or pass `context:` explicitly):
/// ```dart
/// AppSnackBarMessenger.success("Profile updated");
/// AppSnackBarMessenger.error("Network error");
/// AppSnackBarMessenger.warning("Please select a doctor");
/// AppSnackBarMessenger.info("Uploading...");
/// ```
class AppSnackBarMessenger {
  AppSnackBarMessenger._();

  static const Duration _defaultDuration = Duration(seconds: 2);

  /// Long enough that Flutter's own built-in SnackBar timer effectively
  /// never fires on its own - the external [AppSnackBarController] is
  /// what actually drives dismissal, which is what makes pause/resume
  /// possible.
  static const Duration _internalSnackBarDuration = Duration(days: 1);

  /// Global scaffold messenger key. Assign this to your
  /// `MaterialApp.scaffoldMessengerKey` so `AppSnackBarMessenger` can
  /// find a `ScaffoldMessengerState` without one being passed in
  /// explicitly.
  static GlobalKey<ScaffoldMessengerState> get scaffoldMessengerKey => AppKeys.scaffoldMessengerKey;

  static AppSnackBarController? _activeController;

  static void success(
      String message, {
        BuildContext? context,
        Duration duration = _defaultDuration,
        AppSnackBarStyle style = AppSnackBarStyle.floating,
      }) {
    _show(
      message: message,
      type: AppSnackBarType.success,
      context: context,
      duration: duration,
      style: style,
    );
  }

  static void error(
      String message, {
        BuildContext? context,
        Duration duration = _defaultDuration,
        AppSnackBarStyle style = AppSnackBarStyle.floating,
      }) {
    _show(
      message: message,
      type: AppSnackBarType.error,
      context: context,
      duration: duration,
      style: style,
    );
  }

  static void warning(
      String message, {
        BuildContext? context,
        Duration duration = _defaultDuration,
        AppSnackBarStyle style = AppSnackBarStyle.floating,
      }) {
    _show(
      message: message,
      type: AppSnackBarType.warning,
      context: context,
      duration: duration,
      style: style,
    );
  }

  static void info(
      String message, {
        BuildContext? context,
        Duration duration = _defaultDuration,
        AppSnackBarStyle style = AppSnackBarStyle.floating,
      }) {
    _show(
      message: message,
      type: AppSnackBarType.info,
      context: context,
      duration: duration,
      style: style,
    );
  }

  /// Hides the currently visible snack bar, if any.
  static void hide({BuildContext? context}) {
    _activeController?.dismiss();
    _activeController = null;
    _resolveMessenger(context)?.hideCurrentSnackBar();
  }

  static ScaffoldMessengerState? _resolveMessenger(BuildContext? context) {
    if (context != null) {
      return ScaffoldMessenger.of(context);
    }
    return scaffoldMessengerKey.currentState;
  }

  static void _show({
    required String message,
    required AppSnackBarType type,
    required Duration duration,
    required AppSnackBarStyle style,
    BuildContext? context,
  }) {
    final messenger = _resolveMessenger(context);

    assert(
    messenger != null,
    'AppSnackBarMessenger: no ScaffoldMessengerState available.\n'
        'Either pass `context:` explicitly to AppSnackBarMessenger.success/'
        'error/warning/info, or assign '
        'AppSnackBarMessenger.scaffoldMessengerKey to your '
        'MaterialApp(scaffoldMessengerKey: ...).',
    );
    if (messenger == null) return;

    // Only one snack bar's worth of timer logic should be alive at a
    // time; ScaffoldMessenger itself already handles replacing the
    // visible SnackBar, we just also need to stop the old timer so it
    // doesn't fire and hide a SnackBar that isn't its own anymore.
    _activeController?.dismiss();

    final controller = AppSnackBarController(
      duration: duration,
      onTimeout: () => messenger.hideCurrentSnackBar(),
    );
    _activeController = controller;

    final closedFuture = messenger.showSnackBar(
      SnackBar(
        duration: _internalSnackBarDuration,
        backgroundColor: AppSnackBarStyleHelper.colorFor(type),
        behavior: style == AppSnackBarStyle.floating
            ? SnackBarBehavior.floating
            : SnackBarBehavior.fixed,
        content: GestureDetector(
          behavior:  HitTestBehavior.opaque,
          onPanDown: (_) => controller.pause(),
          onPanEnd: (_) => controller.resume(),
          onPanCancel: () => controller.resume(),
          child: AppSnackBarStyleHelper.buildContent(type, message),
        ),
      ),
    )
        .closed;

    // If the SnackBar goes away for any other reason (swiped, replaced
    // by a new one, or hide() called directly), make sure our timer for
    // *this* snack bar is stopped and no longer considered active.
    closedFuture.then((_) {
      if (identical(_activeController, controller)) {
        controller.dismiss();
        _activeController = null;
      }
    });

    controller.start();
  }
}