import '../../../core/json/json.dart';

class IdentityVerificationModel {
  const IdentityVerificationModel({
    required this.recommendedOptions,
    required this.otherOptions,
  });

  factory IdentityVerificationModel.fromJson(dynamic raw) {
    final json = Json(raw);
    final groups = json['somewhats'].listValue
        .map(
          (group) => Json(group).listValue
              .map((item) => '$item'.trim())
              .where((item) => item.isNotEmpty)
              .map((item) => IdentityDocumentOption(name: item))
              .toList(),
        )
        .where((group) => group.isNotEmpty)
        .toList();

    return IdentityVerificationModel(
      recommendedOptions: groups.isNotEmpty ? groups.first : const [],
      otherOptions: groups.length > 1
          ? groups.skip(1).expand((group) => group).toList()
          : const [],
    );
  }

  final List<IdentityDocumentOption> recommendedOptions;
  final List<IdentityDocumentOption> otherOptions;
}

class IdentityDocumentOption {
  const IdentityDocumentOption({required this.name});

  final String name;
}
