import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui'; // 👈 Added this missing engine UI package import
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:badges/badges.dart' as badges;
import '../theme/app_theme.dart';
import '../services/notification_service.dart';

class MainScaffold extends StatefulWidget {
  final Widget child;
  const MainScaffold({super.key, required this.child});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  final List<_NavItem> _navItems = [
    _NavItem('/dashboard', Icons.home_rounded, Icons.home_outlined, 'Home'),
    _NavItem(
      '/crm',
      Icons.people_alt_rounded,
      Icons.people_alt_outlined,
      'CRM',
    ),
    _NavItem('/email', Icons.email_rounded, Icons.email_outlined, 'Email'),
    _NavItem('/calling', Icons.call_rounded, Icons.call_outlined, 'Calls'),
    _NavItem('/events', Icons.event_rounded, Icons.event_outlined, 'Events'),
    _NavItem(
      '/ai-assistant',
      Icons.psychology_rounded,
      Icons.psychology_outlined,
      'AI',
    ),
    _NavItem(
      '/notifications',
      Icons.notifications_rounded,
      Icons.notifications_outlined,
      'Alerts',
    ),
  ];

  String _getCurrentRoute(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    for (final item in _navItems) {
      if (location.startsWith(item.route)) return item.route;
    }
    return _navItems[0].route;
  }

  int _getIndex(String route) {
    for (int i = 0; i < _navItems.length; i++) {
      if (route.startsWith(_navItems[i].route)) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final currentRoute = _getCurrentRoute(context);
    final currentIndex = _getIndex(currentRoute);
    final notifService = context.watch<NotificationService>();

    return Scaffold(
      body: widget.child,
      extendBody: true, // let body go behind the floating nav bar
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              height: 64,
              decoration: BoxDecoration(
                color: AppTheme.darkBg.withOpacity(0.92),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: Colors.white.withOpacity(0.08),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withOpacity(0.15),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.30),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: _navItems.asMap().entries.map((entry) {
                  final i = entry.key;
                  final item = entry.value;
                  final sel = currentIndex == i;
                  final isAi = item.route == '/ai-assistant';
                  final isAlert = item.route == '/notifications';

                  return Expanded(
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        context.go(item.route);
                      },
                      behavior: HitTestBehavior.opaque,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutCubic,
                        height: 64,
                        decoration: BoxDecoration(
                          gradient: sel
                              ? (isAi
                                    ? AppTheme.accentGradient
                                    : AppTheme.blueGradient)
                              : null,
                          borderRadius: BorderRadius.circular(28),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildIcon(item, sel, isAlert, notifService),
                            const SizedBox(height: 2),
                            AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 200),
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: sel
                                    ? FontWeight.w800
                                    : FontWeight.w500,
                                color: sel ? Colors.white : Colors.white38,
                                fontFamily: 'Nunito',
                              ),
                              child: Text(item.label),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(
    _NavItem item,
    bool sel,
    bool isAlert,
    NotificationService notif,
  ) {
    final icon = Icon(
      sel ? item.activeIcon : item.icon,
      color: sel ? Colors.white : Colors.white38,
      size: 22,
    );

    if (isAlert && notif.unreadCount > 0) {
      return badges.Badge(
        showBadge: true,
        badgeContent: Text(
          notif.unreadCount > 9 ? '9+' : notif.unreadCount.toString(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 8,
            fontWeight: FontWeight.bold,
          ),
        ),
        badgeStyle: const badges.BadgeStyle(
          badgeColor: AppTheme.error,
          padding: EdgeInsets.all(3),
        ),
        child: icon,
      );
    }
    return icon;
  }
}

class _NavItem {
  final String route, label;
  final IconData activeIcon, icon;
  const _NavItem(this.route, this.activeIcon, this.icon, this.label);
}
