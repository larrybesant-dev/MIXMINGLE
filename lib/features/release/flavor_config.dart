/// Flavor Configuration
///
/// Entry points for different build flavors.
library;

import 'package:flutter/material.dart';
import 'app_config.dart';

/// Development flavor entry point
void mainDev() {
  AppConfig.initialize(AppFlavor.dev);
  debugPrint('ðŸ”§ Starting Mix & Mingle in DEVELOPMENT mode');
  // Import and call main() from main.dart
}

/// Staging flavor entry point
void mainStaging() {
  AppConfig.initialize(AppFlavor.staging);
  debugPrint('ðŸ§ª Starting Mix & Mingle in STAGING mode');
  // Import and call main() from main.dart
}

/// Production flavor entry point
void mainProduction() {
  AppConfig.initialize(AppFlavor.production);
  debugPrint('ðŸš€ Starting Mix & Mingle in PRODUCTION mode');
  // Import and call main() from main.dart
}

/// Flavor banner widget for non-production builds
class FlavorBanner extends StatelessWidget {
  final Widget child;

  const FlavorBanner({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final flavor = AppConfig.instance.flavor;

    if (flavor == AppFlavor.production) {
      return child;
    }

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Banner(
        message: flavor.name.toUpperCase(),
        location: BannerLocation.topEnd,
        color: flavor == AppFlavor.dev ? Colors.green : Colors.orange,
        child: child,
      ),
    );
  }
}
