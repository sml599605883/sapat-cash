import '../../core/json/json.dart';

class ProductDetailModel {
  const ProductDetailModel({
    required this.amount,
    required this.productId,
    required this.orderNo,
    required this.orderId,
    required this.fieldstone,
    required this.nonbiological,
    required this.temporalize,
    required this.profiteers,
  });

  factory ProductDetailModel.fromJson(dynamic raw) {
    final json = Json(raw);
    final marketer = json['marketer'];
    return ProductDetailModel(
      amount: marketer['undersexed'].stringOrNull ?? '',
      productId: marketer['braciole'].stringOrNull ?? '',
      orderNo: marketer['unsuspecting'].stringOrNull ?? '',
      orderId: marketer['leaguered'].intOrNull ?? 0,
      fieldstone: marketer['fieldstone'].stringOrNull ?? '',
      nonbiological: marketer['nonbiological'].intOrNull ?? 0,
      temporalize: ProductDetailTextsModel.fromJson(json['temporalize']),
      profiteers: Json(json['profiteers'].rawValue),
    );
  }

  final String amount;
  final String productId;
  final String orderNo;
  final int orderId;
  final String fieldstone;
  final int nonbiological;
  final ProductDetailTextsModel temporalize;
  final Json profiteers;
}

class ProductDetailTextsModel {
  const ProductDetailTextsModel({
    required this.identityHint,
    required this.identitySuccessHint,
    required this.faceHint,
    required this.personalHint,
    required this.workHint,
    required this.contactHint,
    required this.bankHint,
    required this.bankBottomHint,
  });

  factory ProductDetailTextsModel.fromJson(dynamic raw) {
    final json = raw is Json ? raw : Json(raw);
    return ProductDetailTextsModel(
      identityHint:
          json['precedences'].stringOrNull?.trim() ??
          'Snap your valid ID Clear photo, quick check',
      identitySuccessHint:
          json['bewilderedly'].stringOrNull?.trim() ??
          'Almost done! Check your details, then submit',
      faceHint:
          json['clinics'].stringOrNull?.trim() ??
          'Look straight at the camera, keep your face inside the frame',
      personalHint:
          json['yirds'].stringOrNull?.trim() ??
          'Upload successful! Please carefully check that your information is accurate.',
      workHint:
          json['marantas'].stringOrNull?.trim() ??
          'Complete your personal profile to help the system perform better credit evaluation.',
      contactHint:
          json['convicting'].stringOrNull?.trim() ??
          'Emergency contact information is used only for verification in special cases, kept strictly confidential.',
      bankHint:
          json['immigrational'].stringOrNull?.trim() ??
          'Complete the first step of verification by uploading your valid ID to speed up approval!',
      bankBottomHint:
          json['trainability'].stringOrNull?.trim() ??
          'Please verify your account details carefully to prevent delays.',
    );
  }

  final String identityHint;
  final String identitySuccessHint;
  final String faceHint;
  final String personalHint;
  final String workHint;
  final String contactHint;
  final String bankHint;
  final String bankBottomHint;
}
