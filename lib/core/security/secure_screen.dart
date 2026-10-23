import 'dart:io';

import 'package:flutter/services.dart';

/// Blocks screenshots, screen recording and the recents-screen preview
/// (Android's `FLAG_SECURE`, set in `MainActivity`) — turned on whenever an
/// app-lock PIN is configured, so the figures a PIN is meant to hide
/// can't leak through the app switcher thumbnail either.
abstract final class SecureScreen {
  static const _channel = MethodChannel('com.fixedwise.app/secure_screen');

  static Future<void> setEnabled(bool enabled) async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod<void>('setSecure', enabled);
    } on MissingPluginException {
      // No native side (widget tests) — nothing to protect there.
    }
  }
}
