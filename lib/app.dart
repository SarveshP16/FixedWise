import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/security/app_lock_controller.dart';
import 'core/security/app_lock_gate.dart';
import 'core/theme/app_theme.dart';

/// App-wide default status bar style: dark icons, since every screen
/// except the Dashboard has a light "paper" background right at the top.
/// `DashboardScreen` nests its own `AnnotatedRegion` with
/// [SystemUiOverlayStyle.light] around its dark hero, which overrides
/// this default while it's the active screen and reverts automatically
/// once it isn't.
const _defaultSystemOverlayStyle = SystemUiOverlayStyle(
  statusBarColor: Colors.transparent,
  statusBarIconBrightness: Brightness.dark,
  statusBarBrightness: Brightness.light,
);

class FixedWiseApp extends ConsumerStatefulWidget {
  const FixedWiseApp({super.key});

  @override
  ConsumerState<FixedWiseApp> createState() => _FixedWiseAppState();
}

class _FixedWiseAppState extends ConsumerState<FixedWiseApp> with WidgetsBindingObserver {
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
    final router = ref.watch(appRouterProvider);
    final isLocked = ref.watch(appLockProvider).isLocked;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: _defaultSystemOverlayStyle,
      child: MaterialApp.router(
        title: 'FixedWise',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        routerConfig: router,
        // The lock gate is layered *over* the routed content, not swapped
        // in for it — replacing `child` outright while locked would
        // unmount go_router's own Navigator, silently resetting every
        // unlock back to the dashboard instead of wherever you actually
        // were.
        builder: (context, child) {
          return Stack(children: [?child, if (isLocked) const AppLockGate()]);
        },
      ),
    );
  }
}
