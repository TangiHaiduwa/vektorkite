import 'package:amplify_api/amplify_api.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_storage_s3/amplify_storage_s3.dart';
import 'package:vektorkite/amplifyconfiguration.dart';
import 'package:vektorkite/core/utils/app_logger.dart';

class AmplifyBootstrapService {
  const AmplifyBootstrapService._();

  static Future<void> configure() async {
    if (Amplify.isConfigured) return;

    try {
      await Amplify.addPlugins([
        AmplifyAuthCognito(),
        AmplifyAPI(),
        AmplifyStorageS3(),
      ]);
      await Amplify.configure(amplifyconfig);
      AppLogger.info('Amplify configured', name: 'Amplify');
    } on AmplifyAlreadyConfiguredException {
      AppLogger.info('Amplify already configured', name: 'Amplify');
    } catch (error, stackTrace) {
      AppLogger.error(
        'Failed to configure Amplify',
        name: 'Amplify',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
}
