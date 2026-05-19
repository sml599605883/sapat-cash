import '../core/network_manager.dart';
import '../core/network_response.dart';
import '../protocol/signature_helper.dart';
import '../../report/report_cache.dart';
import '../../../features/home/home_models.dart';
import '../../../features/product/product_detail_cache.dart';
import '../../../features/product/product_detail_model.dart';
import '../../../features/verification/models/address_region_model.dart';
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

  Future<NetworkResponse<dynamic>> fetchOrderLandingUrl({
    required String orderNo,
    required String amount,
    required String loanTerm,
    required String loanTermType,
  }) {
    return _networkManager.post(
      ApiEndpoints.fetchOrderLandingUrl,
      body: _withObfuscatedFields(
        {
          'slynesses': orderNo,
          'undersexed': amount,
          'fieldstone': loanTerm,
          'nonbiological': loanTermType,
        },
        {
          'unfrocking': _randomObfuscatedValue(),
          'talkathon': _randomObfuscatedValue(),
          'designed': _randomObfuscatedValue(),
          'aurality': _randomObfuscatedValue(),
        },
      ),
    );
  }

  Future<NetworkResponse<OrderListResponse>> fetchOrderList({
    required String status,
    required String page,
  }) async {
    final response = await _networkManager.post(
      ApiEndpoints.fetchOrderList,
      body: _withObfuscatedFields(
        {'balsamic': status, 'farmhouses': page, 'bollixing': '50'},
        {
          'unfrocking': _randomObfuscatedValue(),
          'talkathon': _randomObfuscatedValue(),
          'designed': _randomObfuscatedValue(),
          'aurality': _randomObfuscatedValue(),
        },
      ),
    );
    return NetworkResponse<OrderListResponse>(
      code: response.code,
      message: response.message,
      data: OrderListResponse.fromJson(response.data),
    );
  }

  Future<NetworkResponse<ProductDetailModel>> productDetail({
    required String productId,
  }) async {
    final response = await _networkManager.post(
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
    final detail = ProductDetailModel.fromJson(response.data);
    ProductDetailCache.save(detail);
    return NetworkResponse<ProductDetailModel>(
      code: response.code,
      message: response.message,
      data: detail,
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

  Future<NetworkResponse<dynamic>> fetchIdentityInfo({
    required String productId,
  }) {
    return _networkManager.get(
      ApiEndpoints.fetchIdentityInfo,
      queryParameters: _withObfuscatedFields(
        {'silken': productId},
        {'requiters': _randomObfuscatedValue()},
      ),
    );
  }

  Future<NetworkResponse<dynamic>> uploadIdentityAsset({
    required String type,
    required String imageSource,
    required String cardType,
    String? bizTokenOrLivenessId,
    String? authCode,
    String? faceType,
    String? businessNo,
    String? filePath,
  }) {
    return _networkManager.upload(
      ApiEndpoints.uploadIdentityAsset,
      body: _withObfuscatedFields({
        'refortification': type,
        'nonrealistic': imageSource,
        'tutorials': cardType,
        'salivate': bizTokenOrLivenessId,
        'pyramidal': authCode,
        'unreminiscent': faceType,
        'unrelaxed': businessNo,
      }, {}),
      filePath: filePath,
      fileField: 'attach',
    );
  }

  Future<NetworkResponse<dynamic>> saveIdentityInfo({
    required String birthday,
    required String certificateNo,
    required String fullName,
    required String type,
    required String cardType,
  }) {
    return _networkManager.post(
      ApiEndpoints.saveIdentityInfo,
      body: _withObfuscatedFields(
        {
          'tittie': birthday,
          'sketchbooks': certificateNo,
          'fornices': fullName,
          'refortification': type,
          'tutorials': cardType,
        },
        {'quittor': _randomObfuscatedValue()},
      ),
    );
  }

  Future<NetworkResponse<dynamic>> checkBaseCertification({
    required String productId,
  }) {
    return _networkManager.post(
      ApiEndpoints.checkBaseCertification,
      body: _withObfuscatedFields(
        {'silken': productId},
        {
          'semillon': _randomObfuscatedValue(),
          'pilaffs': _randomObfuscatedValue(),
        },
      ),
    );
  }

  Future<NetworkResponse<dynamic>> fetchFaceToken({
    required String orderNo,
    required String type,
  }) {
    return _networkManager.post(
      ApiEndpoints.fetchFaceToken,
      body: _withObfuscatedFields(
        {'slynesses': orderNo, 'refortification': type},
        {
          'manifest': _randomObfuscatedValue(),
          'unusualness': _randomObfuscatedValue(),
        },
      ),
    );
  }

  Future<NetworkResponse<dynamic>> fetchUserInfo({required String productId}) {
    return _networkManager.post(
      ApiEndpoints.fetchUserInfo,
      body: _withObfuscatedFields(
        {'silken': productId},
        {'eremuruses': _randomObfuscatedValue()},
      ),
    );
  }

  Future<NetworkResponse<dynamic>> saveUserInfo({
    required Map<String, dynamic> fields,
  }) {
    return _networkManager.post(
      ApiEndpoints.saveUserInfo,
      body: _withObfuscatedFields(fields, {
        'remediations': _randomObfuscatedValue(),
        'insistent': _randomObfuscatedValue(),
      }),
    );
  }

  Future<NetworkResponse<List<AddressRegionModel>>> initializeAddress() async {
    final response = await _networkManager.get(ApiEndpoints.initializeAddress);
    final regions = response.json['noniron'].listValue
        .map((item) => AddressRegionModel.fromJson(item))
        .toList(growable: false);
    return NetworkResponse<List<AddressRegionModel>>(
      code: response.code,
      message: response.message,
      data: regions,
    );
  }

  Future<NetworkResponse<dynamic>> fetchWorkInfo({required String productId}) {
    return _networkManager.get(
      ApiEndpoints.fetchWorkInfo,
      queryParameters: _withObfuscatedFields(
        {'silken': productId},
        {'eremuruses': _randomObfuscatedValue()},
      ),
    );
  }

  Future<NetworkResponse<dynamic>> saveWorkInfo({
    required Map<String, dynamic> fields,
  }) {
    return _networkManager.post(
      ApiEndpoints.saveWorkInfo,
      body: _withObfuscatedFields(fields, {
        'fonded': _randomObfuscatedValue(),
        'muggars': _randomObfuscatedValue(),
        'flying': _randomObfuscatedValue(),
      }),
    );
  }

  Future<NetworkResponse<dynamic>> fetchContactInfo({
    required String productId,
  }) {
    return _networkManager.get(
      ApiEndpoints.fetchContactInfo,
      queryParameters: _withObfuscatedFields(
        {'silken': productId},
        {'tefillin': _randomObfuscatedValue()},
      ),
    );
  }

  Future<NetworkResponse<dynamic>> saveContactInfo({
    required String productId,
    required String contactsJson,
  }) {
    return _networkManager.post(
      ApiEndpoints.saveContactInfo,
      body: _withObfuscatedFields(
        {'silken': productId, 'evaginate': contactsJson},
        {'zookeepers': _randomObfuscatedValue()},
      ),
    );
  }

  Future<NetworkResponse<dynamic>> fetchBindCardInfo({
    required String productId,
  }) {
    return _networkManager.get(
      ApiEndpoints.fetchBindCardInfo,
      queryParameters: _withObfuscatedFields(
        {'silken': productId},
        {
          'unfixt': _randomObfuscatedValue(),
          'cottony': _randomObfuscatedValue(),
        },
      ),
    );
  }

  Future<NetworkResponse<dynamic>> submitBindCard({
    required Map<String, dynamic> fields,
    String? filePath,
  }) {
    return _networkManager.upload(
      ApiEndpoints.submitBindCard,
      body: _withObfuscatedFields(fields, {}),
      filePath: filePath,
      fileField: 'attach',
    );
  }

  Future<NetworkResponse<dynamic>> fetchAccountList({
    required String productId,
  }) {
    return _networkManager.post(
      ApiEndpoints.fetchAccountList,
      body: _withObfuscatedFields(
        {'silken': productId},
        {
          'whispery': _randomObfuscatedValue(),
          'metalware': _randomObfuscatedValue(),
        },
      ),
    );
  }

  Future<NetworkResponse<dynamic>> changeBankCard({
    required String orderNo,
    required String bindCardId,
  }) {
    return _networkManager.post(
      ApiEndpoints.changeBankCard,
      body: _withObfuscatedFields(
        {'slynesses': orderNo, 'reads': bindCardId},
        {'outyielded': _randomObfuscatedValue()},
      ),
    );
  }

  Future<NetworkResponse<dynamic>> fetchRetainPopup({
    required String popupType,
    required String productId,
  }) {
    return _networkManager.post(
      ApiEndpoints.fetchRetainPopup,
      body: _withObfuscatedFields(
        {'flagellum': popupType, 'fellest': productId},
        {'muraenid': _randomObfuscatedValue()},
      ),
    );
  }

  Future<NetworkResponse<dynamic>> reportTongdun({
    String livenessId = '',
    String requestId = '',
    String resultCode = '',
    required String result,
  }) {
    return _networkManager.post(
      ApiEndpoints.reportTongdun,
      body: {
        'rhenium': livenessId,
        'derivative': requestId,
        'sirras': resultCode,
        'earphone': result,
      },
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
