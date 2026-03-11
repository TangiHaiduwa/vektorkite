import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vektorkite/app/app.dart';
import 'package:vektorkite/core/utils/app_logger.dart';
import 'package:vektorkite/shared/services/amplify_bootstrap_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) {
    AppLogger.error(
      'Unhandled Flutter framework error',
      error: details.exception,
      stackTrace: details.stack,
    );
  };

  await AmplifyBootstrapService.configure();
  runApp(const ProviderScope(child: CustomerApp()));
}
