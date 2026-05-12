import '../core/network_manager.dart';
import '../core/network_response.dart';
import '../protocol/signature_helper.dart';
import '../../report/report_cache.dart';
import '../../../features/home/home_models.dart';
import 'api_endpoints.dart';

class ApiService {
  const ApiService(this._networkManager);

  final NetworkManager _networkManager;

  Future<NetworkResponse<dynamic>> reportLocation({
    String? province,
    required String countryCode,
    required String country,
    required String street,
    required String latitude,
    required String longitude,
    required String city,
  }) {
    return _networkManager.post(
      ApiEndpoints.reportLocation,
      body: _withObfuscatedFields(
        {
          'thionins': province,
          'paperclips': countryCode,
          'dreamlike': country,
          'compeller': street,
          'forages': latitude,
          'antisnob': longitude,
          'baseboards': city,
        },
        {
          'punkah': _randomObfuscatedValue(),
          'terminuses': _randomObfuscatedValue(),
        },
      ),
    );
  }

  Future<NetworkResponse<dynamic>> reportGoogleMarket({
    required String idfv,
    required String idfa,
  }) {
    return _networkManager.post(
      ApiEndpoints.reportGoogleMarket,
      body: _withObfuscatedFields(
        {'donkeys': idfv, 'owlishly': idfa},
        {'gouramies': _randomObfuscatedValue()},
      ),
    );
  }

  Future<NetworkResponse<dynamic>> reportRiskBehavior({
    required String productId,
    required String sceneType,
    required String orderNo,
    required String riskDeviceId,
    required String idfa,
    required String longitude,
    required String latitude,
    required String startTime,
    required String endTime,
  }) {
    return _networkManager.post(
      ApiEndpoints.reportRiskBehavior,
      body: _withObfuscatedFields(
        {
          'fellest': productId,
          'bewrapt': sceneType,
          'unsuspecting': orderNo,
          'girasoles': riskDeviceId,
          'goopier': idfa,
          'antisnob': longitude,
          'forages': latitude,
          'overtops': startTime,
          'cornered': endTime,
        },
        {'unfixt': _randomObfuscatedValue()},
      ),
    );
  }

  Future<NetworkResponse<dynamic>> reportDeviceInfo({
    required String encryptedPayload,
  }) {
    return _networkManager.post(
      ApiEndpoints.reportDeviceInfo,
      body: {'evaginate': encryptedPayload},
    );
  }

  Future<NetworkResponse<dynamic>> reportContacts({
    required String encryptedPayload,
  }) {
    return _networkManager.post(
      ApiEndpoints.reportContacts,
      body: _withObfuscatedFields(
        {'refortification': '3', 'evaginate': encryptedPayload},
        {
          'gavots': _randomObfuscatedValue(),
          'premigration': _randomObfuscatedValue(),
        },
      ),
    );
  }

  Future<NetworkResponse<dynamic>> reportApplePushToken({
    required String token,
  }) {
    return _networkManager.post(
      ApiEndpoints.reportApplePushToken,
      body: {'reviviscence': token},
    );
  }

  Future<NetworkResponse<dynamic>> clickApply({
    required String productId,
    String? apiremind,
  }) {
    return _networkManager.post(
      ApiEndpoints.clickApply,
      body: _withObfuscatedFields(
        {'silken': productId, 'praseodymium': apiremind},
        {
          'lavender': _randomObfuscatedValue(),
          'coattend': _randomObfuscatedValue(),
        },
      ),
    );
  }

  Future<NetworkResponse<dynamic>> productDetail({required String productId}) {
    return _networkManager.post(
      ApiEndpoints.productDetail,
      body: _withObfuscatedFields(
        {'silken': productId},
        {
          'gleaning': _randomObfuscatedValue(),
          'magus': _randomObfuscatedValue(),
          'soundable': _randomObfuscatedValue(),
        },
      ),
    );
  }

  Future<NetworkResponse<AppHomeResponse>> fetchAppHome() async {
    final response = await _networkManager.get(
      ApiEndpoints.fetchAppHome,
      queryParameters: _withObfuscatedFields({}, {
        'virginal': _randomObfuscatedValue(),
        'broker': _randomObfuscatedValue(),
      }),
    );
    return NetworkResponse<AppHomeResponse>(
      code: response.code,
      message: response.message,
      data: AppHomeResponse.fromJson(response.data),
    );
  }

  Future<NetworkResponse<dynamic>> reportApp({
    required int reportType,
    required String payload,
  }) {
    return _networkManager.post(
      ApiEndpoints.reportApp,
      body: _withObfuscatedFields(
        {'sided': '$reportType', 'befringes': payload},
        {'fair': _randomObfuscatedValue()},
      ),
    );
  }

  Future<NetworkResponse<dynamic>> reCredit() {
    return _networkManager.get(
      ApiEndpoints.reCredit,
      queryParameters: _withObfuscatedFields({}, {
        'acquires': _randomObfuscatedValue(),
      }),
    );
  }

  Future<NetworkResponse<dynamic>> fetchPopup({required int scene}) {
    return _networkManager.get(
      ApiEndpoints.fetchPopup,
      queryParameters: _withObfuscatedFields({'smutchiest': scene}, {}),
    );
  }

  Future<NetworkResponse<dynamic>> uploadBannerClickRecord({
    required String bannerConfigId,
  }) {
    return _networkManager.post(
      ApiEndpoints.uploadBannerClickRecord,
      body: _withObfuscatedFields(
        {'infantilizing': bannerConfigId},
        {'zings': _randomObfuscatedValue()},
      ),
    );
  }

  Future<NetworkResponse<dynamic>> requestLoginSmsCode({
    required String phone,
  }) {
    return _networkManager.post(
      ApiEndpoints.requestLoginSmsCode,
      body: _withObfuscatedFields(
        {'tambourers': phone},
        {'gestating': _randomObfuscatedValue()},
      ),
    );
  }

  Future<NetworkResponse<dynamic>> loginOrRegisterByCode({
    required String phone,
    required String code,
  }) async {
    final response = await _networkManager.post(
      ApiEndpoints.loginOrRegisterByCode,
      body: _withObfuscatedFields(
        {'warily': phone, 'seedpod': code},
        {
          'averter': _randomObfuscatedValue(),
          'oceanologists': _randomObfuscatedValue(),
        },
      ),
    );
    final sessionId = response.json['nucleosyntheses'].stringValue.trim();
    if (sessionId.isNotEmpty) {
      await ReportCache.setSessionId(sessionId);
    }
    return response;
  }

  Future<NetworkResponse<dynamic>> logout() {
    return _networkManager.get(
      ApiEndpoints.logout,
      queryParameters: _withObfuscatedFields({}, {
        'hypercapnic': _randomObfuscatedValue(),
        'myxamoeba': _randomObfuscatedValue(),
      }),
    );
  }

  Future<NetworkResponse<dynamic>> deleteAccount() {
    return _networkManager.get(
      ApiEndpoints.deleteAccount,
      queryParameters: _withObfuscatedFields({}, {
        'urethrae': _randomObfuscatedValue(),
      }),
    );
  }

  Map<String, dynamic> _withObfuscatedFields(
    Map<String, dynamic> businessParams,
    Map<String, dynamic> obfuscatedParams,
  ) {
    return {...businessParams, ...obfuscatedParams};
  }

  String _randomObfuscatedValue() {
    return SignatureHelper.randomDigits();
  }
}
