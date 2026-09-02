import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
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

class FixedWiseApp extends ConsumerWidget {
  const FixedWiseApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: _defaultSystemOverlayStyle,
      child: MaterialApp.router(
        title: 'FixedWise',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        routerConfig: router,
      ),
    );
  }
}
