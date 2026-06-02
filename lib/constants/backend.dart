import 'package:flutter/foundation.dart';

String defaultBackendBaseUrl() {
  if (kIsWeb) {
    return 'http://localhost:3001';
  }

  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
      return 'http://10.0.2.2:3001';
    case TargetPlatform.iOS:
    case TargetPlatform.macOS:
    case TargetPlatform.linux:
    case TargetPlatform.windows:
    case TargetPlatform.fuchsia:
      return 'http://127.0.0.1:3001';
  }
}
