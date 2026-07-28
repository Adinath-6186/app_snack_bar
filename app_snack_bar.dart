import 'package:flutter/material.dart';
import 'package:practiva/core/constant/app_keys.dart';

import 'app_snack_bar_controller.dart' show AppSnackBarStyle;
import 'app_snack_bar_overlay.dart';
import 'app_snack_bar_style.dart';

export 'app_snack_bar_style.dart' show AppSnackBarType;

/// Public, static API for showing snack bars from anywhere in the app -
/// no `BuildContext` plumbing required at the call site (as long as
/// [navigatorKey] is wired up, see below).
///
/// Setup (once, in your `MaterialApp`):
/// ```dart
/// MaterialApp(
///   navigatorKey: AppSnackBar.navigatorKey,
///   home: const HomePage(),
/// )
/// ```
///
/// Usage (from anywhere):
/// ```dart
/// AppSnackBar.success("Profile updated");
/// AppSnackBar.error("Network error");
/// AppSnackBar.warning("Please select a doctor");
/// AppSnackBar.info("Uploading...");
/// ```
///
/// If you'd rather not use the global navigator key, every method also
/// accepts an explicit `context` argument.
class AppSnackBar {
  AppSnackBar._();

  static const Duration _defaultDuration = Duration(seconds: 2);

  /// Global navigator key. Assign this to your `MaterialApp.navigatorKey`
  /// so `AppSnackBar` can find a `BuildContext` without one being passed
  /// in explicitly.
  static GlobalKey<NavigatorState>  get navigatorKey => AppKeys.navigatorKey;

  static void success(
      String message, {
        BuildContext? context,
        Duration duration = _defaultDuration,
        AppSnackBarStyle style = AppSnackBarStyle.floating,
        bool useRootOverlay = false,
      }) {
    _show(
      message: message,
      type: AppSnackBarType.success,
      context: context,
      duration: duration,
      style: style,
      useRootOverlay: useRootOverlay,
    );
  }

  static void error(
      String message, {
        BuildContext? context,
        Duration duration = _defaultDuration,
        AppSnackBarStyle style = AppSnackBarStyle.floating,
        bool useRootOverlay = false,
      }) {
    _show(
      message: message,
      type: AppSnackBarType.error,
      context: context,
      duration: duration,
      style: style,
      useRootOverlay: useRootOverlay,
    );
  }

  static void warning(
      String message, {
        BuildContext? context,
        Duration duration = _defaultDuration,
        AppSnackBarStyle style = AppSnackBarStyle.floating,
        bool useRootOverlay = false,
      }) {
    _show(
      message: message,
      type: AppSnackBarType.warning,
      context: context,
      duration: duration,
      style: style,
      useRootOverlay: useRootOverlay,
    );
  }

  static void info(
      String message, {
        BuildContext? context,
        Duration duration = _defaultDuration,
        AppSnackBarStyle style = AppSnackBarStyle.floating,
        bool useRootOverlay = false,
      }) {
    _show(
      message: message,
      type: AppSnackBarType.info,
      context: context,
      duration: duration,
      style: style,
      useRootOverlay: useRootOverlay,
    );
  }

  /// Hides the currently visible snack bar, if any, playing its exit
  /// animation.
  static void hide() => AppSnackBarOverlay.hide();

  static void _show({
    required String message,
    required AppSnackBarType type,
    required Duration duration,
    required AppSnackBarStyle style,
    BuildContext? context,
    bool useRootOverlay = false,
  }) {
    // Resolve the OverlayState directly rather than walking up from a
    // BuildContext. This matters because when using the global
    // `navigatorKey`, `navigatorKey.currentContext` is the Navigator's
    // *own* context - and the Overlay lives *inside* the Navigator, not
    // above it - so `Overlay.of(navigatorKey.currentContext)` can never
    // find it. `NavigatorState.overlay` gives us the OverlayState
    // directly, sidestepping that lookup entirely.
    //
    // When an explicit `context` is passed in (e.g. from a button's
    // onPressed), we default to the *nearest* Overlay rather than the
    // root one. If that context lives inside a GoRouter ShellRoute /
    // StatefulShellRoute branch (the common way to build a bottom
    // navigation bar), the nearest Overlay belongs to that branch's own
    // nested Navigator - which is confined to the body area, below the
    // nav bar in the widget tree. That means the snack bar physically
    // can't cover the nav bar, with no manual height math needed.
    //
    // Pass `useRootOverlay: true` for the rare case you want the snack
    // bar to sit above absolutely everything, including dialogs opened
    // with a root navigator.
    final overlayState = context != null
        ? Overlay.of(context, rootOverlay: useRootOverlay)
        : navigatorKey.currentState?.overlay;

    assert(
    overlayState != null,
    'AppSnackBar: no OverlayState available.\n'
        'Either pass `context:` explicitly to AppSnackBar.success/error/'
        'warning/info, or assign AppSnackBar.navigatorKey to your '
        'MaterialApp(navigatorKey: ...) and make sure it has been built.',
    );
    if (overlayState == null) return;

    AppSnackBarOverlay.show(
      overlayState: overlayState,
      backgroundColor: AppSnackBarStyleHelper.colorFor(type),
      duration: duration,
      style: style,
      content: AppSnackBarStyleHelper.buildContent(type, message),
    );
  }
}