import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/security/app_lock_controller.dart';
import 'core/security/app_lock_gate.dart';
import 'core/security/secure_screen.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'features/profile/application/settings_providers.dart';

/// App-wide default status bar style for a given resolved [brightness]:
/// dark icons on light, light icons on dark, since every screen except the
/// Dashboard has a "paper"-background app bar right at the top.
/// `DashboardScreen` nests its own `AnnotatedRegion` with
/// [SystemUiOverlayStyle.light] around its dark hero, which overrides this
/// default while it's the active screen and reverts automatically once it
/// isn't.
SystemUiOverlayStyle _defaultSystemOverlayStyle(Brightness brightness) {
  final iconBrightness = brightness == Brightness.dark ? Brightness.light : Brightness.dark;
  return SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: iconBrightness,
    statusBarBrightness: brightness,
  );
}

class FixedWiseApp extends ConsumerStatefulWidget {
  const FixedWiseApp({super.key});

  @override
  ConsumerState<FixedWiseApp> createState() => _FixedWiseAppState();
}

class _FixedWiseAppState extends ConsumerState<FixedWiseApp> with WidgetsBindingObserver {
  Brightness? _lastBrightness;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Re-lock the moment the app leaves the foreground, so it's already
    // locked by the time you come back to it — not on `inactive` alone,
    // which also fires for transient things like a permission dialog or
    // the notification shade, where the app hasn't really left.
    if (state == AppLifecycleState.paused) {
      ref.read(appLockProvider.notifier).lock();
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(appLockProvider.select((state) => state.pinConfigured), (_, configured) {
      SecureScreen.setEnabled(configured);
    });
    final router = ref.watch(appRouterProvider);
    final isLocked = ref.watch(appLockProvider).isLocked;
    final themeMode = ref.watch(themePreferenceProvider).themeMode;

    return MaterialApp.router(
      title: 'FixedWise',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      routerConfig: router,
      // The lock gate is layered *over* the routed content, not swapped
      // in for it — replacing `child` outright while locked would
      // unmount go_router's own Navigator, silently resetting every
      // unlock back to the dashboard instead of wherever you actually
      // were.
      builder: (context, child) {
        // Keeps AppColors' dynamic getters in sync with whichever of
        // theme/darkTheme Flutter actually resolved for this frame, before
        // any descendant (routed screens, the lock gate) builds and reads
        // one of them.
        final brightness = Theme.of(context).brightness;
        AppColors.brightness = brightness;
        // Screens read colors through AppColors' static getters, not
        // Theme.of, so nothing marks them dirty when the theme flips —
        // and StatefulShellRoute keeps every tab alive offstage, so a tab
        // built before the switch kept its old-theme colors (dark text on
        // a dark background) until the app restarted. Rebuild the whole
        // tree once after any brightness change.
        if (_lastBrightness != null && _lastBrightness != brightness) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) _markSubtreeNeedsBuild(context as Element);
          });
        }
        _lastBrightness = brightness;
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: _defaultSystemOverlayStyle(brightness),
          child: Stack(
            children: [
              if (child != null) ExcludeSemantics(excluding: isLocked, child: child),
              if (isLocked) const AppLockGate(),
            ],
          ),
        );
      },
    );
  }
}

void _markSubtreeNeedsBuild(Element root) {
  void mark(Element element) {
    element.markNeedsBuild();
    element.visitChildren(mark);
  }

  root.visitChildren(mark);
}
