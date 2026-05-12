import '../../core/json/json.dart';

enum HomeSectionType {
  banner,
  largeCard,
  smallCard,
  repay,
  productList,
  processList,
  adList,
  unknown,
}

class AppHomeResponse {
  AppHomeResponse({
    required this.icon,
    required this.sections,
  });

  factory AppHomeResponse.fromJson(dynamic raw) {
    final json = Json(raw);
    return AppHomeResponse(
      icon: HomeIconEntry.fromJson(json['hideout']),
      sections: json['noniron']
          .listValue
          .map((item) => HomeSection.fromJson(item))
          .toList(),
    );
  }

  final HomeIconEntry icon;
  final List<HomeSection> sections;

  HomeSection? firstSection(HomeSectionType type) {
    for (final section in sections) {
      if (section.type == type) {
        return section;
      }
    }
    return null;
  }
}

class HomeIconEntry {
  const HomeIconEntry({required this.imageUrl, required this.link});

  factory HomeIconEntry.fromJson(dynamic raw) {
    final json = Json(raw);
    return HomeIconEntry(
      imageUrl: json['overscaled'].stringValue,
      link: json['microfilming'].stringValue,
    );
  }

  final String imageUrl;
  final String link;
}

class HomeSection {
  const HomeSection({
    required this.type,
    required this.rawType,
    required this.items,
  });

  factory HomeSection.fromJson(dynamic raw) {
    final json = Json(raw);
    final rawType = json['refortification'].stringValue;
    return HomeSection(
      type: HomeSectionTypeMapper.fromApiValue(rawType),
      rawType: rawType,
      items: json['platinoids']
          .listValue
          .map((item) => HomeSectionItem.fromJson(item))
          .toList(),
    );
  }

  final HomeSectionType type;
  final String rawType;
  final List<HomeSectionItem> items;
}

class HomeSectionItem {
  HomeSectionItem({
    required this.raw,
    this.authProgress = const [],
    this.creditProgress = const [],
    this.tags = const [],
    this.buttons = const [],
    this.bannerConfigId,
    this.link,
    this.imageUrl,
    this.productId,
    this.productName,
    this.productLogo,
    this.buttonText,
    this.amount,
    this.amountText,
    this.loanTerm,
    this.loanTermText,
    this.interestRate,
    this.interestRateText,
    this.description,
    this.authFinished,
    this.receiptAccount,
    this.receiptAccountText,
    this.packageName,
    this.buttonStyle,
    this.loanTermsText,
    this.loanOrderNo,
    this.title,
    this.loanAmount,
    this.loanAmountText,
    this.applyDate,
    this.applyDateText,
    this.orderStatus,
    this.orderStatusText,
    this.progressDescription,
    this.orderDetailLink,
  });

  factory HomeSectionItem.fromJson(dynamic raw) {
    final json = Json(raw);
    return HomeSectionItem(
      raw: json,
      bannerConfigId: json['braciole'].stringOrNull,
      link: json['oreides'].stringOrNull,
      imageUrl: _readFirst(json, const ['putonghua', 'loanshifts']),
      productId: json['braciole'].stringOrNull ?? json['silken'].stringOrNull,
      productName: _readFirst(json, const ['tubas', 'territory']),
      productLogo: _readFirst(json, const ['loanshifts', 'kingfishes']),
      buttonText: json['orangery'].stringOrNull,
      amount: _readFirst(json, const ['sari', 'output']),
      amountText: _readFirst(json, const ['encyclics', 'infighters']),
      loanTerm: _readFirst(json, const ['cantal', 'fibrotic']),
      loanTermText: _readFirst(json, const ['headword', 'raucously', 'cyanic']),
      interestRate: _readFirst(json, const ['polarizable', 'retrofitted']),
      interestRateText: json['isoprenalines'].stringOrNull,
      description: json['rigidified'].stringOrNull,
      authFinished: json['tuyer'].intOrNull == 1,
      receiptAccount: json['grewsomest'].stringOrNull,
      receiptAccountText: json['exception'].stringOrNull,
      authProgress: json['conflicted']
          .listValue
          .map((item) => HomeProgressEntry.fromJson(item))
          .toList(),
      creditProgress: json['gadid']
          .listValue
          .map((item) => HomeCreditProgressEntry.fromJson(item))
          .toList(),
      tags: json['satirical'].listValue.map((item) => '$item').toList(),
      packageName: json['photomontage'].stringOrNull,
      buttonStyle: json['handsome'].stringOrNull,
      loanTermsText: json['cyanic'].stringOrNull,
      loanOrderNo: json['slynesses'].stringOrNull,
      title: json['interdiffusions'].stringOrNull,
      loanAmount: json['undersexed'].numOrNull,
      loanAmountText: json['infighters'].stringOrNull,
      applyDate: json['fibrotic'].stringOrNull,
      applyDateText: json['raucously'].stringOrNull,
      orderStatus: json['snappier'].intOrNull,
      orderStatusText: json['counterargues'].stringOrNull,
      progressDescription: json['rigidified'].stringOrNull,
      orderDetailLink: json['oreides'].stringOrNull,
      buttons: json['kleagle']
          .listValue
          .map((item) => HomeActionButton.fromJson(item))
          .toList(),
    );
  }

  final Json raw;
  final String? bannerConfigId;
  final String? link;
  final String? imageUrl;
  final String? productId;
  final String? productName;
  final String? productLogo;
  final String? buttonText;
  final String? amount;
  final String? amountText;
  final String? loanTerm;
  final String? loanTermText;
  final String? interestRate;
  final String? interestRateText;
  final String? description;
  final bool? authFinished;
  final String? receiptAccount;
  final String? receiptAccountText;
  final List<HomeProgressEntry> authProgress;
  final List<HomeCreditProgressEntry> creditProgress;
  final List<String> tags;
  final String? packageName;
  final String? buttonStyle;
  final String? loanTermsText;
  final String? loanOrderNo;
  final String? title;
  final num? loanAmount;
  final String? loanAmountText;
  final String? applyDate;
  final String? applyDateText;
  final int? orderStatus;
  final String? orderStatusText;
  final String? progressDescription;
  final String? orderDetailLink;
  final List<HomeActionButton> buttons;

  static String? _readFirst(Json json, List<String> keys) {
    for (final key in keys) {
      final value = json[key].stringOrNull?.trim();
      if (value != null && value.isNotEmpty) {
        return value;
      }
    }
    return null;
  }
}

class HomeProgressEntry {
  const HomeProgressEntry({
    required this.period,
    required this.amount,
    required this.finished,
  });

  factory HomeProgressEntry.fromJson(dynamic raw) {
    final json = Json(raw);
    return HomeProgressEntry(
      period: json['interdiffusions'].stringValue,
      amount: json['prosing'].stringValue,
      finished: json['boisterously'].intValue == 1,
    );
  }

  final String period;
  final String amount;
  final bool finished;
}

class HomeCreditProgressEntry {
  const HomeCreditProgressEntry({
    required this.period,
    required this.periodText,
    required this.interestRate,
  });

  factory HomeCreditProgressEntry.fromJson(dynamic raw) {
    final json = Json(raw);
    return HomeCreditProgressEntry(
      period: json['keelboat'].stringValue,
      periodText: json['mustering'].stringValue,
      interestRate: json['polarizable'].stringValue,
    );
  }

  final String period;
  final String periodText;
  final String interestRate;
}

class HomeActionButton {
  const HomeActionButton({
    required this.type,
    required this.rawType,
    required this.enabled,
    required this.text,
  });

  factory HomeActionButton.fromJson(dynamic raw) {
    final json = Json(raw);
    final rawType = json['refortification'].stringValue;
    return HomeActionButton(
      type: HomeActionTypeMapper.fromApiValue(rawType),
      rawType: rawType,
      enabled: json['toilet'].intValue == 1,
      text: json['martyries'].stringValue,
    );
  }

  final HomeActionType type;
  final String rawType;
  final bool enabled;
  final String text;
}

enum HomeActionType { retry, change, repay, unknown }

class HomeSectionTypeMapper {
  const HomeSectionTypeMapper._();

  static HomeSectionType fromApiValue(String rawValue) {
    return _sectionTypeMap[rawValue.trim()] ?? HomeSectionType.unknown;
  }

  static const Map<String, HomeSectionType> _sectionTypeMap = {
    'BANNER': HomeSectionType.banner,
    'LARGE_CARD': HomeSectionType.largeCard,
    'SMALL_CARD': HomeSectionType.smallCard,
    'REPAY': HomeSectionType.repay,
    'PRODUCT_LIST': HomeSectionType.productList,
    'PROCESS_LIST': HomeSectionType.processList,
    'AD_LIST': HomeSectionType.adList,
    'ChaffinchVerged': HomeSectionType.banner,
    'Pretasted': HomeSectionType.largeCard,
    'Boltrope': HomeSectionType.smallCard,
    'Disputant': HomeSectionType.repay,
    'Diphthongizes': HomeSectionType.productList,
    'Inaccessible': HomeSectionType.processList,
    'LubberlyParadoxicality': HomeSectionType.adList,
  };
}

class HomeActionTypeMapper {
  const HomeActionTypeMapper._();

  static HomeActionType fromApiValue(String rawValue) {
    return _actionTypeMap[rawValue.trim().toLowerCase()] ??
        HomeActionType.unknown;
  }

  static const Map<String, HomeActionType> _actionTypeMap = {
    'retry': HomeActionType.retry,
    'change': HomeActionType.change,
    'repay': HomeActionType.repay,
  };
}
