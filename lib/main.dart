import 'package:material_ui/material_ui.dart';
import 'package:flutter/foundation.dart';

import 'app.dart';

void main() {
  final binding = WidgetsFlutterBinding.ensureInitialized();
  runApp(
    NewsApp(
      introReady: !kIsWeb && defaultTargetPlatform == TargetPlatform.android
          ? binding.waitUntilFirstFrameRasterized
          : null,
    ),
  );
}
