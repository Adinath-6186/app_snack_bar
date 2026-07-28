# AppSnackBar

Two parallel implementations of a Material-style snack bar that supports
pausing its auto-dismiss timer while the user holds it down. Pick
whichever fits your app; both share the same look and the same timer
logic (`AppSnackBarController`).

| | `AppSnackBar` | `AppSnackBarMessenger` |
|---|---|---|
| Rendering | Raw `OverlayEntry` | Flutter's `ScaffoldMessenger` + `SnackBar` |
| Needs | a `NavigatorState`/`Overlay` (via `navigatorKey` or `context`) | a `ScaffoldMessengerState` (via `scaffoldMessengerKey` or `context`) |
| Avoids bottom nav bar | only if given the nearest `context`-based overlay | automatically (it's a Scaffold descendant) |
| Slide animation | custom-built | Flutter's built-in |
| Swipe-to-dismiss | custom gesture logic | Flutter's built-in |
| Floats above everything | yes (with root overlay) | no - confined to the nearest Scaffold |

## Files

```
lib/core/snackbar/
├── app_snack_bar.dart             # Overlay-based public API
├── app_snack_bar_overlay.dart     # OverlayEntry lifecycle, single-instance guard
├── app_snack_bar_widget.dart      # UI, slide animation, gestures (Overlay version only)
├── app_snack_bar_messenger.dart   # ScaffoldMessenger-based public API
├── app_snack_bar_controller.dart  # Pause/resume/dismiss timer logic (shared)
└── app_snack_bar_style.dart       # Shared type enum, colors, icons (shared)
```

## Setup

Wire up whichever key(s) your chosen implementation(s) need, once, in
your `MaterialApp`:

```dart
import 'core/snackbar/app_snack_bar.dart';
import 'core/snackbar/app_snack_bar_messenger.dart';

MaterialApp(
  navigatorKey: AppSnackBar.navigatorKey,                            // for AppSnackBar
  scaffoldMessengerKey: AppSnackBarMessenger.scaffoldMessengerKey,   // for AppSnackBarMessenger
  home: const HomePage(),
);
```

You only need to wire up the key for whichever implementation(s) you
actually use.

If you're on `go_router`: point `AppSnackBar.navigatorKey` at the
**same** key you already pass to `GoRouter(navigatorKey: ...)`, rather
than creating a second one - `GoRouter` supplies that key to
`MaterialApp.router` internally, so you don't add `navigatorKey`
directly on `MaterialApp.router` either way:

```dart
void main() {
  AppSnackBar.navigatorKey = AppKeys.navigatorKey; // same key GoRouter uses
  runApp(const MyApp());
}
```

(If you'd rather not use global keys at all, every method on both
classes also accepts an explicit `context:` argument instead.)

## Usage

```dart
// Overlay-based
AppSnackBar.success("Profile updated");
AppSnackBar.error("Network error");
AppSnackBar.warning("Please select a doctor");
AppSnackBar.info("Uploading...");

// ScaffoldMessenger-based
AppSnackBarMessenger.success("Profile updated");
AppSnackBarMessenger.error("Network error");
AppSnackBarMessenger.warning("Please select a doctor");
AppSnackBarMessenger.info("Uploading...");
```

Both accept the same optional parameters:

```dart
AppSnackBar.success(
  "Saved",
  duration: const Duration(seconds: 3),
  style: AppSnackBarStyle.fixed, // or AppSnackBarStyle.floating (default)
  context: context,              // optional - see "Avoiding a bottom nav bar" below
);
```

Dismiss manually (e.g. before navigating away - though this is
optional, see below):

```dart
AppSnackBar.hide();
AppSnackBarMessenger.hide();
```

## Do I need to close the snack bar before navigating?

No - it's optional for both implementations.

- `AppSnackBarMessenger` is tied to whichever `Scaffold` showed it; if
  you navigate away from that screen entirely, `ScaffoldMessenger`
  handles cleanup on its own.
- `AppSnackBar`'s `OverlayEntry` isn't tied to any route at all - it
  keeps floating and counting down across navigation. If the specific
  `Navigator`/`Overlay` that hosted it gets torn down mid-navigation,
  cleanup is handled safely (no crash) automatically.

## Avoiding a bottom navigation bar (AppSnackBar / Overlay version)

`AppSnackBarMessenger` avoids a `bottomNavigationBar` automatically,
since it renders inside the nearest `Scaffold`. For `AppSnackBar`:

The widget already respects the **system** safe area (notches, home
indicator) via `MediaQuery.padding.bottom` - no setup needed there.

A **custom bottom navigation bar** (e.g. from a `go_router` `ShellRoute`
/ `StatefulShellRoute`) is different: it isn't reported in `MediaQuery`
at all, so nothing tells the snack bar it exists. This comes down to
*which* `Overlay` you insert into, not padding math:

- With **no `context`**, `AppSnackBar` uses the global `navigatorKey`'s
  **root** overlay - which sits above your entire app, including any
  bottom nav bar.
- Pass **`context:`** from inside a page (the common case) and it
  defaults to the **nearest** `Overlay` instead. When that page lives
  inside a shell route branch, the nearest overlay belongs to that
  branch's own nested `Navigator` - confined to the body area, below
  the nav bar in the widget tree:

```dart
AppSnackBar.success("Saved", context: context);
```

- Pass `useRootOverlay: true` alongside an explicit `context` for the
  rare case you want it above absolutely everything (e.g. above a
  dialog on the root navigator).

## Behavior

- **Appearance** matches Flutter's default `SnackBar` (rounded floating
  card or edge-to-edge fixed bar, drop shadow, white text/icon on a
  colored surface).
- **Animation**: slides up from the bottom on show, slides back down on
  dismiss.
- **Auto-dismiss** after 2 seconds by default (configurable per call).
- **Press and hold** anywhere on the snack bar pauses the countdown;
  releasing resumes it with whatever time was left.
- **Swipe** to dismiss immediately; a smaller swipe snaps back and
  resumes the timer.
- **Only one snack bar at a time.**
- **No third-party packages.**

## How the pause/resume logic works

`AppSnackBarController` (shared by both implementations) tracks a
`remaining` duration and a single `Timer`:

- `start()` sets `remaining = duration` and starts the timer.
- `pause()` cancels the timer and subtracts the elapsed time from
  `remaining`.
- `resume()` restarts the timer using whatever `remaining` is left (or
  fires immediately if it had already hit zero while paused).
- `dismiss()` cancels the timer permanently; no further callbacks fire.

`AppSnackBar` calls `pause()`/`resume()` from its own gesture detector
tied to the slide/animation widget. `AppSnackBarMessenger` instead gives
Flutter's `SnackBar` a near-infinite `duration` (so Flutter's own timer
never fires) and lets the external controller call
`ScaffoldMessenger.hideCurrentSnackBar()` when it times out - a
`GestureDetector` around the content calls `pause()`/`resume()` the same
way.

## Minimal runnable demo

```dart
import 'package:flutter/material.dart';
import 'core/snackbar/app_snack_bar.dart';
import 'core/snackbar/app_snack_bar_messenger.dart';

void main() => runApp(const DemoApp());

class DemoApp extends StatelessWidget {
  const DemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: AppSnackBar.navigatorKey,
      scaffoldMessengerKey: AppSnackBarMessenger.scaffoldMessengerKey,
      home: Scaffold(
        appBar: AppBar(title: const Text('AppSnackBar Demo')),
        body: Center(
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              ElevatedButton(
                onPressed: () => AppSnackBar.success('Saved (Overlay)'),
                child: const Text('Overlay: Success'),
              ),
              ElevatedButton(
                onPressed: () => AppSnackBar.error('Something went wrong'),
                child: const Text('Overlay: Error'),
              ),
              ElevatedButton(
                onPressed: () =>
                    AppSnackBarMessenger.success('Saved (Messenger)'),
                child: const Text('Messenger: Success'),
              ),
              ElevatedButton(
                onPressed: () =>
                    AppSnackBarMessenger.warning('Please select a doctor'),
                child: const Text('Messenger: Warning'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

Try pressing and holding one of the snack bars after it appears - the
countdown pauses until you let go.
