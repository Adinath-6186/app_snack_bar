import 'package:flutter/material.dart';

import 'app_snack_bar_controller.dart';
import 'app_snack_bar_widget.dart';

/// Handles inserting/removing the [OverlayEntry] that hosts an
/// [AppSnackBarWidget], and guarantees that only one snack bar is ever
/// visible at a time.
///
/// This is intentionally the only class in the feature that touches
/// [Overlay] directly - everything else works with plain widgets and
/// callbacks, which keeps it easy to test.
class AppSnackBarOverlay {
  AppSnackBarOverlay._();

  static OverlayEntry? _currentEntry;
  static GlobalKey<AppSnackBarWidgetState>? _currentKey;

  /// Shows a new snack bar, instantly removing any currently visible one
  /// first (so there is never more than one on screen).
  ///
  /// Callers must supply the [OverlayState] to insert into directly
  /// (rather than a [BuildContext]) - see [AppSnackBar] for how it
  /// resolves this correctly whether it was given an explicit context or
  /// is using the global navigator key.
  static void show({
    required OverlayState overlayState,
    required Widget content,
    required Color backgroundColor,
    Duration duration = const Duration(seconds: 2),
    AppSnackBarStyle style = AppSnackBarStyle.floating,
  }) {
    // Drop any existing snack bar immediately (no exit animation) so the
    // new one can take its place without visual overlap.
    _forceRemoveCurrent();

    final widgetKey = GlobalKey<AppSnackBarWidgetState>();
    late final OverlayEntry entry;

    entry = OverlayEntry(
      builder: (_) => AppSnackBarWidget(
        key: widgetKey,
        content: content,
        backgroundColor: backgroundColor,
        duration: duration,
        style: style,
        onDismissed: () => _removeEntryIfCurrent(entry),
      ),
    );

    _currentEntry = entry;
    _currentKey = widgetKey;
    overlayState.insert(entry);
  }

  /// Gracefully hides the currently visible snack bar (plays the
  /// slide-down animation first, if possible).
  static void hide() {
    final key = _currentKey;
    if (key?.currentState != null) {
      key!.currentState!.dismiss();
    } else {
      _forceRemoveCurrent();
    }
  }

  static void _removeEntryIfCurrent(OverlayEntry entry) {
    if (identical(_currentEntry, entry)) {
      _safeRemove(entry);
      _currentEntry = null;
      _currentKey = null;
    }
  }

  static void _forceRemoveCurrent() {
    final entry = _currentEntry;
    if (entry == null) return;
    _safeRemove(entry);
    _currentEntry = null;
    _currentKey = null;
  }

  /// Removes an [OverlayEntry], tolerating the case where Flutter already
  /// disposed it on its own - e.g. the Navigator/Overlay that hosted it
  /// was torn down by navigation before we got to it.
  static void _safeRemove(OverlayEntry entry) {
    try {
      entry.remove();
    } catch (_) {
      // Already removed/disposed elsewhere - nothing further to do.
    }
  }
}