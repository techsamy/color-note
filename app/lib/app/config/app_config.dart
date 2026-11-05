import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';

enum AppEnvironment { dev, prod }

/// Build-time configuration.
///
/// Flavor comes from `--flavor dev|prod`; API URL from
/// `--dart-define=API_BASE_URL=https://...` (defaults per flavor).
final class AppConfig {
  const new({required this.environment, required this.apiBaseUrl});

  factory fromEnvironment() {
    const env = appFlavor == 'prod' ? AppEnvironment.prod : AppEnvironment.dev;
    const override = String.fromEnvironment('API_BASE_URL');
    return AppConfig(
      environment: env,
      apiBaseUrl: override.isNotEmpty
          ? override
          : switch (env) {
              // Web preview runs on this machine; 10.0.2.2 = host from an
              // Android emulator. Real phone: pass API_BASE_URL with your LAN IP.
              AppEnvironment.dev when kIsWeb => 'http://127.0.0.1:8000/api/v1',
              AppEnvironment.dev => 'http://10.0.2.2:8000/api/v1',
              AppEnvironment.prod => 'https://api.huenote.app/api/v1',
            },
    );
  }

  final AppEnvironment environment;
  final String apiBaseUrl;

  bool get isDev => environment == AppEnvironment.dev;
}
