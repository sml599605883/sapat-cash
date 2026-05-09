abstract class AsyncCommonParamProvider {
  Future<Map<String, dynamic>> getCommonParams();
}

abstract class SyncCommonParamProvider {
  Map<String, dynamic> getCommonParams();
}

class StaticCommonParamProvider implements SyncCommonParamProvider {
  const StaticCommonParamProvider(this.params);

  final Map<String, dynamic> params;

  @override
  Map<String, dynamic> getCommonParams() => Map<String, dynamic>.from(params);
}
