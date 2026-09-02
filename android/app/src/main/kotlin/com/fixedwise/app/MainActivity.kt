package com.fixedwise.app

import io.flutter.embedding.android.FlutterFragmentActivity

// local_auth requires a FragmentActivity, not a plain FlutterActivity —
// see lib/core/security/device_auth_service.dart.
class MainActivity : FlutterFragmentActivity()
