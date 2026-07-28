import 'dart:async';
import 'package:flutter/foundation.dart';

/// Visual placement style for [AppSnackBar], mirroring Material's
/// `SnackBarBehavior`.
enum AppSnackBarStyle { fixed, floating }

/// Manages the auto-dismiss timer for a single snack bar instance.
///
/// Responsibilities:
/// - Starts a countdown for [duration].
/// - [pause] freezes the countdown and remembers how much time is left.
/// - [resume] restarts the countdown using the remaining time.
/// - [dismiss] cancels everything permanently (no more callbacks fire).
///
/// This class has no knowledge of animation or UI - it purely tracks time.
class AppSnackBarController {
  AppSnackBarController({
    required this.duration,
    required this.onTimeout,
  }) : _remaining = duration;

  /// Total duration the snack bar should stay visible for, absent any
  /// pausing.
  final Duration duration;

  /// Called exactly once, when the countdown reaches zero without being
  /// dismissed first.
  final VoidCallback onTimeout;

  Timer? _timer;
  Duration _remaining;
  DateTime? _segmentStart;
  bool _isPaused = false;
  bool _isDismissed = false;

  /// How much time is left before auto-dismiss fires.
  Duration get remaining => _remaining;

  bool get isPaused => _isPaused;
  bool get isDismissed => _isDismissed;

  /// Begins (or restarts) the countdown from [duration].
  void start() {
    if (_isDismissed) return;
    _remaining = duration;
    _restartTimer();
  }

  /// Pauses the countdown, e.g. while the user is holding the snack bar.
  /// Safe to call multiple times; a no-op if already paused/dismissed.
  void pause() {
    if (_isDismissed || _isPaused) return;
    _isPaused = true;
    _timer?.cancel();
    _timer = null;

    final start = _segmentStart;
    if (start != null) {
      final elapsed = DateTime.now().difference(start);
      _remaining -= elapsed;
      if (_remaining.isNegative) {
        _remaining = Duration.zero;
      }
    }
  }

  /// Resumes the countdown using whatever time was remaining when
  /// [pause] was called. If time had already run out, fires the timeout
  /// immediately.
  void resume() {
    if (_isDismissed || !_isPaused) return;
    _isPaused = false;

    if (_remaining <= Duration.zero) {
      _fireTimeout();
      return;
    }
    _restartTimer();
  }

  /// Permanently stops the countdown. No further [onTimeout] calls will
  /// occur after this.
  void dismiss() {
    if (_isDismissed) return;
    _isDismissed = true;
    _timer?.cancel();
    _timer = null;
  }

  /// Cancels the underlying timer without marking the controller as
  /// dismissed. Useful for cleanup in `dispose()`.
  void cancelTimer() {
    _timer?.cancel();
    _timer = null;
  }

  void _restartTimer() {
    _segmentStart = DateTime.now();
    _timer?.cancel();
    _timer = Timer(_remaining, _fireTimeout);
  }

  void _fireTimeout() {
    if (_isDismissed) return;
    _isDismissed = true;
    _timer?.cancel();
    _timer = null;
    onTimeout();
  }
}