import 'package:flutter/material.dart';

import '../../../core/layout/screen.dart';

class HomeBottomNav extends StatelessWidget {
  const HomeBottomNav({
    required this.currentIndex,
    required this.onTap,
    super.key,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final screen = context.screen;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(screen.dp(77), 0, screen.dp(79), 0),
          child: Row(
            children: [
              Expanded(
                child: Align(
                  alignment: currentIndex == 0
                      ? Alignment.center
                      : Alignment.centerRight,
                  child: currentIndex == 0
                      ? Container(
                          width: screen.dp(17),
                          height: screen.dp(1),
                          color: const Color(0xFF331707),
                        )
                      : const SizedBox.shrink(),
                ),
              ),
              Expanded(
                child: Align(
                  alignment: currentIndex == 1
                      ? Alignment.center
                      : Alignment.centerLeft,
                  child: currentIndex == 1
                      ? Container(
                          width: screen.dp(17),
                          height: screen.dp(1),
                          color: const Color(0xFF331707),
                        )
                      : const SizedBox.shrink(),
                ),
              ),
            ],
          ),
        ),
        Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Color.fromRGBO(0, 0, 0, 0.08),
                blurRadius: 16,
                offset: Offset(0, -4),
              ),
            ],
          ),
          padding: EdgeInsets.fromLTRB(
            screen.dp(77),
            screen.dp(13),
            screen.dp(79),
            screen.dp(34),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Expanded(
                child: _BottomNavItem(
                  icon: currentIndex == 0
                      ? 'assets/image/bar/tab_home_selected.png'
                      : 'assets/image/bar/tab_home_normal.png',
                  label: 'Home',
                  active: currentIndex == 0,
                  onTap: () => onTap(0),
                ),
              ),
              Expanded(
                child: _BottomNavItem(
                  icon: currentIndex == 1
                      ? 'assets/image/bar/tab_mine_selected.png'
                      : 'assets/image/bar/tab_mine_normal.png',
                  label: 'Mine',
                  active: currentIndex == 1,
                  onTap: () => onTap(1),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  const _BottomNavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final screen = context.screen;
    final color = active ? const Color(0xFF331707) : const Color(0xFF908E8C);

    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            icon,
            width: screen.dp(30),
            height: screen.dp(30),
            fit: BoxFit.contain,
          ),
          Text(
            label,
            style: TextStyle(color: color, fontSize: screen.dp(12)),
          ),
        ],
      ),
    );
  }
}
