import '../../core/json/json.dart';

enum HomeSectionType { banner, pretasted, productList, progressCard, unknown }

class AppHomeResponse {
  AppHomeResponse({
    required this.icon,
    this.banner = const [],
    this.pretasted,
    this.productList = const [],
    this.progressCard = const [],
  });

  factory AppHomeResponse.fromJson(dynamic raw) {
    final json = Json(raw);
    final sections = json['noniron'].listValue
        .map((item) => HomeSection.fromJson(item))
        .toList();
    return AppHomeResponse(
      icon: HomeIconEntry.fromJson(json['hideout']),
      banner:
          (_firstSection(sections, HomeSectionType.banner)?.items ?? const [])
              .map((item) => HomeBannerItem.fromJson(item.rawValue))
              .toList(),
      pretasted: _mapLargeCardSection(
        _sectionsByType(sections, HomeSectionType.pretasted),
      ),
      productList: _mapProductListSection(
        _firstSection(sections, HomeSectionType.productList),
      ),
      progressCard: _mapProgressCardSection(
        _firstSection(sections, HomeSectionType.progressCard),
      ),
    );
  }

  final HomeIconEntry icon;
  final List<HomeBannerItem> banner;
  final HomeLargeCardItem? pretasted;
  final List<HomeProductListItem> productList;
  final List<HomeProgressCardItem> progressCard;
  HomeLargeCardItem? get largeCard => pretasted;

  static HomeSection? _firstSection(
    List<HomeSection> sections,
    HomeSectionType type,
  ) {
    for (final section in sections) {
      if (section.type == type) {
        return section;
      }
    }
    return null;
  }

  static List<HomeSection> _sectionsByType(
    List<HomeSection> sections,
    HomeSectionType type,
  ) {
    return sections.where((section) => section.type == type).toList();
  }

  static HomeLargeCardItem? _mapLargeCardSection(List<HomeSection> sections) {
    if (sections.isEmpty) {
      return null;
    }
    for (final item in sections.expand((section) => section.items)) {
      return HomeLargeCardItem.fromJson(item.rawValue);
    }
    return null;
  }

  static List<HomeProductListItem> _mapProductListSection(
    HomeSection? section,
  ) {
    if (section == null) {
      return const [];
    }
    return section.items
        .map((item) => HomeProductListItem.fromJson(item.rawValue))
        .toList();
  }

  static List<HomeProgressCardItem> _mapProgressCardSection(
    HomeSection? section,
  ) {
    if (section == null) {
      return const [];
    }
    return section.items
        .map((item) => HomeProgressCardItem.fromJson(item.rawValue))
        .toList();
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

class HomeBannerItem {
  const HomeBannerItem({
    required this.bannerConfigId,
    required this.link,
    required this.imageUrl,
  });

  factory HomeBannerItem.fromJson(dynamic raw) {
    final json = Json(raw);
    return HomeBannerItem(
      bannerConfigId: json['braciole'].stringValue,
      link: json['oreides'].stringValue,
      imageUrl: json['putonghua'].stringValue,
    );
  }
  final String bannerConfigId;
  final String link;
  final String imageUrl;
}

class HomeLargeCardItem {
  const HomeLargeCardItem({
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
    this.authProgress = const [],
    this.creditProgress = const [],
    this.receiptAccount,
    this.receiptAccountText,
  });

  factory HomeLargeCardItem.fromJson(dynamic raw) {
    final json = Json(raw);
    return HomeLargeCardItem(
      productId: json['braciole'].stringOrNull ?? json['silken'].stringOrNull,
      productName: json['tubas'].stringOrNull,
      productLogo: json['loanshifts'].stringOrNull,
      buttonText: json['orangery'].stringOrNull,
      amount: json['sari'].stringOrNull,
      amountText: json['encyclics'].stringOrNull,
      loanTerm: json['cantal'].stringOrNull,
      loanTermText: json['headword'].stringOrNull,
      interestRate: json['polarizable'].stringOrNull,
      interestRateText: json['isoprenalines'].stringOrNull,
      description: json['rigidified'].stringOrNull,
      authFinished: json['tuyer'].intOrNull == 1,
      authProgress: json['conflicted'].listValue
          .map((item) => HomeProgressEntry.fromJson(item))
          .toList(),
      creditProgress: json['gadid'].listValue
          .map((item) => HomeCreditProgressEntry.fromJson(item))
          .toList(),
      receiptAccount: json['grewsomest'].stringOrNull,
      receiptAccountText: json['exception'].stringOrNull,
    );
  }
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
  final List<HomeProgressEntry> authProgress;
  final List<HomeCreditProgressEntry> creditProgress;
  final String? receiptAccount;
  final String? receiptAccountText;
}

class HomeProductListItem {
  static const productButtonActiveGradient = <int>[0xFFF89350, 0xFFF45834];

  const HomeProductListItem({
    this.productId,
    this.productName,
    this.productLogo,
    this.amount,
    this.amountText,
    this.tags = const [],
    this.primaryTag,
    this.packageName,
    this.buttonText,
    this.buttonStyle,
    this.canApply,
    this.applyStatus,
    this.apiCanApplyType,
    this.periodValue,
    this.periodUnitType,
    this.loanTerm,
    this.loanTermsText,
    this.interestRate,
    this.interestRateText,
    this.link,
    this.tips = const [],
    this.applyProgressPercent,
    this.amountValueText,
    this.productType,
    this.productCategory,
  });

  factory HomeProductListItem.fromJson(dynamic raw) {
    final json = Json(raw);
    return HomeProductListItem(
      productId: json['braciole'].stringOrNull,
      productName: json['tubas'].stringOrNull,
      productLogo: json['loanshifts'].stringOrNull,
      amount: json['sari'].stringOrNull,
      amountText: json['encyclics'].stringOrNull,
      tags: json['satirical'].listValue.map((item) => '$item').toList(),
      primaryTag: json['olfactometers'].stringOrNull,
      packageName: json['photomontage'].stringOrNull,
      buttonText: json['orangery'].stringOrNull,
      buttonStyle: json['handsome'].stringOrNull,
      canApply: json['enunciations'].intOrNull == 1,
      applyStatus: json['deglamorization'].intOrNull,
      apiCanApplyType: json['api_can_apply_type'].intOrNull,
      periodValue: json['fieldstone'].stringOrNull,
      periodUnitType: json['polyelectrolyte'].intOrNull,
      loanTerm: json['cantal'].stringOrNull,
      loanTermsText: json['cyanic'].stringOrNull,
      interestRate: _readFirst(json, const ['retrofitted', 'polarizable']),
      interestRateText: json['isoprenalines'].stringOrNull,
      link: json['oreides'].stringOrNull,
      tips: json['pah'].listValue.map((item) => '$item').toList(),
      applyProgressPercent: json['queazy'].intOrNull,
      amountValueText: json['derangers'].stringOrNull,
      productType: json['suabilities'].intOrNull,
      productCategory: json['kegelers'].intOrNull,
    );
  }
  final String? productId;
  final String? productName;
  final String? productLogo;
  final String? amount;
  final String? amountText;
  final List<String> tags;
  final String? primaryTag;
  final String? packageName;
  final String? buttonText;
  final String? buttonStyle;
  final bool? canApply;
  final int? applyStatus;
  final int? apiCanApplyType;
  final String? periodValue;
  final int? periodUnitType;
  final String? loanTerm;
  final String? loanTermsText;
  final String? interestRate;
  final String? interestRateText;
  final String? link;
  final List<String> tips;
  final int? applyProgressPercent;
  final String? amountValueText;
  final int? productType;
  final int? productCategory;

  bool get isButtonDisabled => applyStatus == -1;

  List<int>? get buttonGradientColors =>
      isButtonDisabled ? null : productButtonActiveGradient;

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

class HomeProgressCardItem {
  const HomeProgressCardItem({
    required this.loanOrderNo,
    required this.productId,
    required this.productName,
    required this.productLogo,
    required this.title,
    required this.loanAmount,
    required this.loanAmountText,
    required this.applyDate,
    required this.applyDateText,
    required this.receiptAccount,
    required this.receiptAccountText,
    required this.reviewStatus,
    required this.orderStatus,
    required this.amount,
    required this.orderStatusText,
    required this.progressDescription,
    required this.authProgress,
    required this.repaymentTimestamp,
    required this.reviewEndTimestamp,
    required this.orderDetailLink,
    required this.buttons,
  });

  factory HomeProgressCardItem.fromJson(dynamic raw) {
    final json = Json(raw);
    return HomeProgressCardItem(
      loanOrderNo: json['slynesses'].stringValue,
      productId: json['silken'].stringValue,
      productName: json['territory'].stringValue,
      productLogo: json['kingfishes'].stringValue,
      title: json['interdiffusions'].stringValue,
      loanAmount: json['undersexed'].stringValue,
      loanAmountText: json['infighters'].stringValue,
      applyDate: json['fibrotic'].stringValue,
      applyDateText: json['raucously'].stringValue,
      receiptAccount: json['grewsomest'].stringValue,
      receiptAccountText: json['exception'].stringValue,
      reviewStatus: json['spatular'].intValue,
      orderStatus: json['snappier'].intValue,
      amount: json['output'].stringValue,
      orderStatusText: json['counterargues'].stringValue,
      progressDescription: json['rigidified'].stringValue,
      authProgress: json['conflicted'].listValue
          .map((item) => HomeProgressEntry.fromJson(item))
          .toList(),
      repaymentTimestamp: json['repassages'].intValue,
      reviewEndTimestamp: json['overemphasized'].intValue,
      orderDetailLink: json['oreides'].stringValue,
      buttons: json['kleagle'].listValue
          .map((item) => HomeActionButton.fromJson(item))
          .toList(),
    );
  }
  final String loanOrderNo;
  final String productId;
  final String productName;
  final String productLogo;
  final String title;
  final String loanAmount;
  final String loanAmountText;
  final String applyDate;
  final String applyDateText;
  final String receiptAccount;
  final String receiptAccountText;
  final int reviewStatus;
  final int orderStatus;
  final String amount;
  final String orderStatusText;
  final String progressDescription;
  final List<HomeProgressEntry> authProgress;
  final int repaymentTimestamp;
  final int reviewEndTimestamp;
  final String orderDetailLink;
  final List<HomeActionButton> buttons;

  bool get isNoButtons => orderStatus == 1 || orderStatus == 4;
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
      items: json['platinoids'].listValue.map((item) => Json(item)).toList(),
    );
  }

  final HomeSectionType type;
  final String rawType;
  final List<Json> items;
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
    'ChaffinchVerged': HomeSectionType.banner,
    'Pretasted': HomeSectionType.pretasted,
    'Boltrope': HomeSectionType.pretasted,
    'Diphthongizes': HomeSectionType.productList,
    'Inaccessible': HomeSectionType.progressCard,
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
