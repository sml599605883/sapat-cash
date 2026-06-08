import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

import '../../core/layout/screen.dart';
import '../../core/network/api/api_client.dart';
import '../../core/network/core/error_message_adapter.dart';
import '../../core/push/app_push.dart';
import '../../core/push/route_names.dart';
import 'order_models.dart';

enum OrderListType { all, outstanding, overdue, settled }

extension on OrderListType {
  String get apiValue {
    switch (this) {
      case OrderListType.all:
        return '4';
      case OrderListType.outstanding:
        return '7';
      case OrderListType.overdue:
        return '6';
      case OrderListType.settled:
        return '5';
    }
  }

  String get title {
    switch (this) {
      case OrderListType.all:
        return 'All';
      case OrderListType.outstanding:
        return 'Outstanding';
      case OrderListType.overdue:
        return 'Overdue';
      case OrderListType.settled:
        return 'Settled';
    }
  }
}

bool shouldRefreshOrderListOnRouteResume({
  required bool hasBeenTopRoute,
  required String? previousTopRouteName,
  required String? currentTopRouteName,
}) {
  if (!hasBeenTopRoute) {
    return false;
  }
  return previousTopRouteName?.trim() != RouteNames.orderList &&
      currentTopRouteName?.trim() == RouteNames.orderList;
}

class OrderListPage extends StatefulWidget {
  const OrderListPage({super.key, this.initialType = OrderListType.all});

  static const routeName = RouteNames.orderList;

  final OrderListType initialType;

  @override
  State<OrderListPage> createState() => _OrderListPageState();
}

class _OrderListPageState extends State<OrderListPage> {
  static const _pageSize = 50;

  final ScrollController _scrollController = ScrollController();
  final List<OrderListItem> _items = [];

  late OrderListType _selectedType = widget.initialType;
  bool _loading = false;
  bool _loadingMore = false;
  bool _hasMore = true;
  bool _hasBeenTopRoute = false;
  int _page = 1;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
    AppPush.addRouteChangeListener(_handleRouteChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _hasBeenTopRoute =
            AppPush.currentRouteName()?.trim() == RouteNames.orderList;
        _loadFirstPage();
      }
    });
  }

  @override
  void dispose() {
    AppPush.removeRouteChangeListener(_handleRouteChanged);
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    super.dispose();
  }

  void _handleRouteChanged(
    String? previousRouteName,
    String? currentRouteName,
  ) {
    if (currentRouteName?.trim() != RouteNames.orderList) {
      return;
    }
    if (shouldRefreshOrderListOnRouteResume(
      hasBeenTopRoute: _hasBeenTopRoute,
      previousTopRouteName: previousRouteName,
      currentTopRouteName: currentRouteName,
    )) {
      unawaited(_loadFirstPage());
    }
    _hasBeenTopRoute = true;
  }

  void _handleScroll() {
    if (!_scrollController.hasClients ||
        _loading ||
        _loadingMore ||
        !_hasMore) {
      return;
    }
    final position = _scrollController.position;
    if (position.extentAfter < 240) {
      unawaited(_loadMore());
    }
  }

  Future<void> _loadFirstPage() async {
    if (_loading) {
      return;
    }
    setState(() {
      _loading = true;
      _page = 1;
      _hasMore = true;
      _items.clear();
    });
    await _fetchPage(reset: true);
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore) {
      return;
    }
    setState(() {
      _loadingMore = true;
    });
    await _fetchPage(reset: false);
  }

  Future<void> _fetchPage({required bool reset}) async {
    try {
      EasyLoading.show();
      final response = await apiService.fetchOrderList(
        status: _selectedType.apiValue,
        page: '$_page',
      );
      final data = response.data;
      final newItems = data?.items ?? const <OrderListItem>[];
      setState(() {
        if (reset) {
          _items
            ..clear()
            ..addAll(newItems);
        } else {
          _items.addAll(newItems);
        }
        _hasMore = newItems.length >= _pageSize;
        if (newItems.isNotEmpty) {
          _page++;
        }
      });
    } catch (error) {
      if (mounted) {
        EasyLoading.showToast(ErrorMessageAdapter.resolve(error));
      }
    } finally {
      if (mounted) {
        EasyLoading.dismiss();
        setState(() {
          _loading = false;
          _loadingMore = false;
        });
      }
    }
  }

  Future<void> _onRefresh() async {
    await _loadFirstPage();
  }

  void _handleTypeTap(OrderListType type) {
    if (_selectedType == type) {
      return;
    }
    setState(() {
      _selectedType = type;
    });
    unawaited(_loadFirstPage());
  }

  void _handleItemTap(OrderListItem item) {
    final url = item.detailUrl.trim();
    if (url.isEmpty) {
      AppPush.clickApply(context, productId: item.productId);
      return;
    }
    AppPush.openWebPage(context, rawUrl: url);
  }

  @override
  Widget build(BuildContext context) {
    final screen = context.screen;
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                SizedBox(height: screen.dp(14)),
                Row(
                  children: [
                    SizedBox(width: screen.dp(16)),
                    GestureDetector(
                      onTap: () => AppPush.pop(context),
                      child: Image.asset(
                        'assets/image/login_back_icon.png',
                        width: screen.dp(24),
                        height: screen.dp(24),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'Loan List',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: const Color(0xFF281001),
                          fontSize: screen.dp(20),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    SizedBox(width: screen.dp(48)),
                  ],
                ),
                SizedBox(height: screen.dp(21)),
                Container(
                  width: double.infinity,
                  color: const Color(0xFFF5F5F3),
                  padding: EdgeInsets.symmetric(
                    horizontal: screen.dp(32),
                    vertical: screen.dp(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: OrderListType.values.map((type) {
                      final selected = type == _selectedType;
                      return GestureDetector(
                        onTap: () => _handleTypeTap(type),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              type.title,
                              style: TextStyle(
                                color: selected
                                    ? const Color(0xFF281001)
                                    : const Color(0xFF908E8C),
                                fontSize: screen.dp(16),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: screen.dp(4)),
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 160),
                              width: screen.dp(19),
                              height: screen.dp(2),
                              decoration: BoxDecoration(
                                color: selected
                                    ? const Color(0xFFF45834)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(
                                  screen.dp(1),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _onRefresh,
              child: _items.isEmpty && !_loading
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      children: [
                        SizedBox(height: screen.dp(140)),
                        Center(
                          child: Image.asset(
                            'assets/image/slices/image-wrapper_2.png',
                            width: screen.dp(240),
                            height: screen.dp(241),
                            fit: BoxFit.contain,
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      padding: EdgeInsets.fromLTRB(
                        screen.dp(16),
                        screen.dp(16),
                        screen.dp(16),
                        screen.dp(24),
                      ),
                      itemCount: _items.length + (_loadingMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index >= _items.length) {
                          return Padding(
                            padding: EdgeInsets.symmetric(
                              vertical: screen.dp(16),
                            ),
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }
                        return Padding(
                          padding: EdgeInsets.only(bottom: screen.dp(16)),
                          child: _OrderCard(
                            item: _items[index],
                            onTap: () => _handleItemTap(_items[index]),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.item, required this.onTap});

  final OrderListItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final screen = context.screen;
    final status = item.statusText.trim();
    final statusCode = item.statusCode.trim();
    final appName = item.appName.isEmpty ? 'App Name' : item.appName;
    final amount = item.amount.isEmpty ? '₱20.000' : item.amount;
    final dueDate = item.dateValue.isEmpty ? '09-01-2025' : item.dateValue;
    final amountLabel = item.amountLabel.isEmpty
        ? 'Loan Amount'
        : item.amountLabel;
    final dateLabel = item.dateLabel.isEmpty ? 'Due Date' : item.dateLabel;
    // final type = _resolveType(item);
    final backgroundAsset = _resolveBackgroundAsset(statusCode);
    final showActionButton =
        (statusCode == '180' || statusCode == '174') &&
        item.actionText.isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(backgroundAsset),
            fit: BoxFit.fill,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              height: screen.dp(31),
              decoration: BoxDecoration(
                // color: _headerBackground(type),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(screen.dp(14)),
                  bottomRight: Radius.circular(screen.dp(14)),
                  topLeft: Radius.circular(screen.dp(100)),
                  topRight: Radius.circular(screen.dp(100)),
                ),
              ),
              padding: EdgeInsets.symmetric(horizontal: screen.dp(24)),
              alignment: Alignment.centerLeft,
              child: Text(
                status,
                style: TextStyle(
                  color: _resolveStatusTextColor(statusCode),
                  fontSize: screen.dp(12),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Container(
              width: double.infinity,
              height: screen.dp(60),
              padding: EdgeInsets.fromLTRB(
                screen.dp(24),
                screen.dp(14),
                screen.dp(24),
                screen.dp(14),
              ),
              decoration: BoxDecoration(
                // color: Colors.white,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(screen.dp(14)),
                  bottomRight: Radius.circular(screen.dp(14)),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: screen.dp(20),
                    height: screen.dp(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD8D8D8),
                      borderRadius: BorderRadius.circular(screen.dp(4)),
                      border: Border.all(color: const Color(0xFF979797)),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(screen.dp(4)),
                      child: Image.network(
                        item.logoUrl,
                        width: screen.dp(20),
                        height: screen.dp(20),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            SizedBox(),
                      ),
                    ),
                  ),
                  SizedBox(width: screen.dp(10)),
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            appName,
                            style: TextStyle(
                              color: const Color(0xFF281001),
                              fontSize: screen.dp(12),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 1,
                    height: screen.dp(28),
                    color: const Color(0xFFE4D9CE),
                  ),
                  SizedBox(width: screen.dp(16)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          amount,
                          style: TextStyle(
                            color: const Color(0xFF281001),
                            fontSize: screen.dp(12),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          amountLabel,
                          style: TextStyle(
                            color: const Color(0xFF908E8C),
                            fontSize: screen.dp(12),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 1,
                    height: screen.dp(28),
                    color: const Color(0xFFE4D9CE),
                  ),
                  SizedBox(width: screen.dp(16)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dueDate,
                          style: TextStyle(
                            color: const Color(0xFF281001),
                            fontSize: screen.dp(12),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          dateLabel,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: const Color(0xFF908E8C),
                            fontSize: screen.dp(12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: screen.dp(10)),
            if (showActionButton)
              Container(
                width: screen.dp(180),
                height: screen.dp(28),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFFF89350), Color(0xFFF45834)],
                  ),
                  borderRadius: BorderRadius.circular(screen.dp(15)),
                ),
                alignment: Alignment.center,
                child: Text(
                  item.actionText,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: screen.dp(14),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _resolveBackgroundAsset(String statusCode) {
    switch (statusCode) {
      case '180':
        return 'assets/image/slices/block_5.png';
      case '174':
        return 'assets/image/slices/block_3.png';
      default:
        return 'assets/image/slices/group_4.png';
    }
  }

  Color _resolveStatusTextColor(String statusCode) {
    switch (statusCode) {
      case '174':
        return const Color(0xFFF45834);
      case '180':
        return const Color(0xFFE43432);
      default:
        return const Color(0xFF5F5752);
    }
  }
}
