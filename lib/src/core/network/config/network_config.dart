class NetworkConfig {
  NetworkConfig._();

  static const Set<int> successCodes = {0, 200, 20000};

  static const String defaultApiBaseUrl =
      'https://service.dingtaitechcorp.com/psc-v1';
  static const String defaultWebBaseUrl = 'https://service.dingtaitechcorp.com';
  static const String remoteConfigUrl =
      'https://raw.githubusercontent.com/DCSTC/Sapat-Cash/refs/heads/main/info';

  static const String signatureSecret = '152df029db80cdab409191852d63c17a';
  static const String signatureFieldKey = 'rehabilitant';
  static const String pathFieldKey = 'slicers';
  static const String protocolRandomFieldKey = 'quittor';
  static const String endpointRandomFieldKey = 'quittor';

  static const String encryptionKey = '01b908d5324a7aec';
  static const String encryptionIv = '8b3ff39d90da32c6';

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);
}
