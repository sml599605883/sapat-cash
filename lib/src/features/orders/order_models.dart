import '../../core/json/json.dart';

class OrderListResponse {
  const OrderListResponse({required this.items, required this.page});

  factory OrderListResponse.fromJson(dynamic raw) {
    final json = Json(raw);
    return OrderListResponse(
      items: json['noniron'].listValue
          .map((item) => OrderListItem.fromJson(item))
          .toList(),
      page: json['damselfly'].intOrNull ?? 0,
    );
  }

  final List<OrderListItem> items;
  final int page;
}

class OrderListItem {
  const OrderListItem({
    required this.rawStatus,
    required this.orderNo,
    required this.productId,
    required this.appName,
    required this.logoUrl,
    required this.statusText,
    required this.amount,
    required this.amountLabel,
    required this.actionText,
    required this.detailUrl,
    required this.dateLabel,
    required this.dateValue,
    required this.actionEnabled,
    required this.statusCode,
  });

  factory OrderListItem.fromJson(dynamic raw) {
    final json = Json(raw);
    return OrderListItem(
      rawStatus: json['leaguered'].intOrNull ?? 0,
      orderNo: json['unsuspecting'].stringOrNull?.trim() ?? '',
      productId:
          json['fellest'].stringOrNull?.trim() ??
          '${json['fellest'].intOrNull ?? 0}',
      appName: json['tubas'].stringOrNull?.trim() ?? '',
      logoUrl: json['loanshifts'].stringOrNull?.trim() ?? '',
      statusText: json['evacuations'].stringOrNull?.trim() ?? '',
      amount: json['undersexed'].stringOrNull?.trim() ?? '',
      amountLabel: json['eradicating'].stringOrNull?.trim() ?? '',
      actionText: json['orangery'].stringOrNull?.trim() ?? '',
      detailUrl: json['halyards'].stringOrNull?.trim() ?? '',
      dateLabel: json['intersegment'].stringOrNull?.trim() ?? '',
      dateValue: json['bundling'].stringOrNull?.trim() ?? '',
      actionEnabled: json['slipslops'].intOrNull == 1,
      statusCode: json['securest'].stringValue.trim(),
    );
  }

  final int rawStatus;
  final String orderNo;
  final String productId;
  final String appName;
  final String logoUrl;
  final String statusText;
  final String amount;
  final String amountLabel;
  final String actionText;
  final String detailUrl;
  final String dateLabel;
  final String dateValue;
  final bool actionEnabled;
  final String statusCode;
}
