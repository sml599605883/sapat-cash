import '../../../core/json/json.dart';

class BankAccountListModel {
  const BankAccountListModel({required this.groups});

  factory BankAccountListModel.fromJson(dynamic raw) {
    final json = raw is Json ? raw : Json(raw);
    final groups = json['noniron'].listValue
        .map((item) => BankAccountGroup.fromJson(item))
        .toList(growable: false);
    return BankAccountListModel(groups: groups);
  }

  final List<BankAccountGroup> groups;

  bool get isEmpty => groups.every((group) => group.accounts.isEmpty);

  List<BankAccountItem> get allAccounts =>
      groups.expand((group) => group.accounts).toList(growable: false);
}

class BankAccountGroup {
  const BankAccountGroup({
    required this.title,
    required this.maskedAccount,
    required this.accounts,
  });

  factory BankAccountGroup.fromJson(dynamic raw) {
    final json = raw is Json ? raw : Json(raw);
    final accounts = json['platinoids'].listValue
        .map(
          (item) => BankAccountItem.fromJson(
            item,
            groupTitle: json['parader'].stringValue,
          ),
        )
        .toList(growable: false);
    return BankAccountGroup(
      title: json['parader'].stringOrNull?.trim() ?? '',
      maskedAccount: json['navigators'].stringOrNull?.trim() ?? '',
      accounts: accounts,
    );
  }

  final String title;
  final String maskedAccount;
  final List<BankAccountItem> accounts;
}

class BankAccountItem {
  const BankAccountItem({
    required this.bindCardId,
    required this.logo,
    required this.isMain,
    required this.status,
    required this.statusText,
    required this.maskedValue,
    required this.label,
    required this.groupTitle,
    required this.typeValue,
    required this.extraFields,
  });

  factory BankAccountItem.fromJson(dynamic raw, {required String groupTitle}) {
    final json = raw is Json ? raw : Json(raw);
    return BankAccountItem(
      bindCardId:
          json['reads'].stringOrNull?.trim() ??
          '${json['reads'].intOrNull ?? 0}',
      logo: json['dragomen'].stringOrNull?.trim() ?? '',
      isMain: json['entreats'].intValue == 1,
      status: json['subversions'].intOrNull ?? 0,
      statusText: json['subconsciously'].stringValue.trim(),
      maskedValue: json['grewsomest'].stringOrNull?.trim() ?? '',
      label: json['phpht'].stringOrNull?.trim() ?? '',
      groupTitle: groupTitle.trim(),
      typeValue:
          json['refortification'].stringOrNull?.trim() ??
          '${json['refortification'].intOrNull ?? 0}',
      extraFields: json['turbots'].mapValue,
    );
  }

  final String bindCardId;
  final String logo;
  final bool isMain;
  final int status;
  final String statusText;
  final String maskedValue;
  final String label;
  final String groupTitle;
  final String typeValue;
  final Map<String, dynamic> extraFields;

  bool get isMaintaining => status == 0;

  bool get isCashPickup => groupTitle.toLowerCase().contains('cash');

  String get title => label.isNotEmpty ? label : groupTitle;

  String get primaryValue => maskedValue;

  String get firstValue => '${extraFields['auto'] ?? 'Anna'}'.trim();

  String get middleValue => '${extraFields['horseraces'] ?? 'Oliver'}'.trim();

  String get lastValue => '${extraFields['deans'] ?? 'Mark'}'.trim();
}
