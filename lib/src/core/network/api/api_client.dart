import '../core/network_client.dart';
import '../core/network_manager.dart';
import '../core/response_parser.dart';
import '../protocol/network_common_param_provider.dart';
import 'api_service.dart';

final NetworkClient _apiNetworkClient = NetworkClient();
final NetworkManager _apiNetworkManager = NetworkManager(
  client: _apiNetworkClient,
  responseParser: const ResponseParser(),
  asyncCommonParamProvider: const NetworkCommonParamProvider(),
);
final ApiService apiService = ApiService(_apiNetworkManager);

class ApiClient {
  const ApiClient._();

  static bool _initialized = false;
  static Future<void>? _initializingFuture;

  static Future<void> initialize() async {
    if (_initialized) {
      return;
    }
    final initializing = _initializingFuture;
    if (initializing != null) {
      await initializing;
      return;
    }

    final future = _apiNetworkManager.initialize();
    _initializingFuture = future;
    try {
      await future;
      _initialized = true;
    } finally {
      _initializingFuture = null;
    }
  }

  static void configureProxy({
    required String host,
    required int port,
    bool allowBadCertificates = false,
  }) {
    _apiNetworkClient.configureProxy(
      host: host,
      port: port,
      allowBadCertificates: allowBadCertificates,
    );
  }

  static void clearProxy() {
    _apiNetworkClient.clearProxy();
  }
}
