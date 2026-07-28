import 'package:flutter/material.dart';

import 'app_snack_bar_controller.dart';

/// Renders the actual snack bar surface: background, content, slide-in/out
/// animation, and gesture handling (press-and-hold to pause the timer,
/// horizontal swipe to dismiss).
///
/// This widget owns its own [AppSnackBarController] and animation
/// controller, and reports back to its host (the overlay) via
/// [onDismissed] once the exit animation has fully completed.
class AppSnackBarWidget extends StatefulWidget {
  const AppSnackBarWidget({
    super.key,
    required this.content,
    required this.backgroundColor,
    required this.duration,
    required this.style,
    required this.onDismissed,
  });

  final Widget content;
  final Color backgroundColor;
  final Duration duration;
  final AppSnackBarStyle style;

  /// Invoked after the exit animation finishes and the widget should be
  /// removed from the [Overlay].
  final VoidCallback onDismissed;

  @override
  State<AppSnackBarWidget> createState() => AppSnackBarWidgetState();
}

class AppSnackBarWidgetState extends State<AppSnackBarWidget>
    with SingleTickerProviderStateMixin {
  static const _dismissThresholdFraction = 0.3;
  static const _dragFadeDistance = 300.0;

  late final AnimationController _animController;
  late final Animation<Offset> _slideAnimation;
  late final AppSnackBarController _timerController;

  double _dragOffset = 0;
  bool _isClosing = false;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
      reverseDuration: const Duration(milliseconds: 200),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    ));

    _timerController = AppSnackBarController(
      duration: widget.duration,
      onTimeout: _handleTimeout,
    );

    _animController.forward();
    _timerController.start();
  }

  @override
  void dispose() {
    _animController.dispose();
    _timerController.cancelTimer();
    super.dispose();
  }

  void _handleTimeout() => dismiss();

  /// Plays the slide-down exit animation and then notifies the overlay to
  /// remove this entry. Safe to call multiple times; only runs once.
  Future<void> dismiss() async {
    if (_isClosing) return;
    _isClosing = true;
    _timerController.dismiss();

    if (mounted) {
      await _animController.reverse();
    }
    widget.onDismissed();
  }

  void _onPanDown(DragDownDetails details) {
    _timerController.pause();
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() => _dragOffset += details.delta.dx);
  }

  void _onPanEnd(DragEndDetails details) {
    if (_isClosing) return;

    final screenWidth = MediaQuery.of(context).size.width;
    final pastThreshold =
        _dragOffset.abs() > screenWidth * _dismissThresholdFraction;

    if (pastThreshold) {
      dismiss();
    } else {
      setState(() => _dragOffset = 0);
      _timerController.resume();
    }
  }

  void _onPanCancel() {
    if (_isClosing) return;
    setState(() => _dragOffset = 0);
    _timerController.resume();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final isFloating = widget.style == AppSnackBarStyle.floating;
    final bottomInset =
        mediaQuery.viewInsets.bottom + mediaQuery.padding.bottom;

    final dragFade =
    (1 - (_dragOffset.abs() / _dragFadeDistance)).clamp(0.0, 1.0);

    return Positioned(
      left: isFloating ? 12 : 0,
      right: isFloating ? 12 : 0,
      bottom: isFloating ? bottomInset + 12 : bottomInset,
      child: SlideTransition(
        position: _slideAnimation,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanDown: _onPanDown,
          onPanUpdate: _onPanUpdate,
          onPanEnd: _onPanEnd,
          onPanCancel: _onPanCancel,
          child: Transform.translate(
            offset: Offset(_dragOffset, 0),
            child: Opacity(
              opacity: dragFade,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  constraints: const BoxConstraints(minHeight: 48),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: widget.backgroundColor,
                    borderRadius:
                    BorderRadius.circular(isFloating ? 8 : 0),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 6,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: DefaultTextStyle(
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                    child: widget.content,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}