// lib/screens/notifications/notifications_screen.dart  (NEW FILE)
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../services/notification_service.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = context.watch<NotificationService>();

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A2340),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Notifications',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
            if (service.unreadCount > 0)
              Text('${service.unreadCount} unread',
                  style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12)),
          ],
        ),
        actions: [
          if (service.unreadCount > 0)
            TextButton(
              onPressed: service.markAllRead,
              child: const Text('Mark All Read',
                  style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
            ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: service.load,
          ),
        ],
      ),
      body: _buildBody(context, service),
    );
  }

  Widget _buildBody(BuildContext context, NotificationService service) {
    if (service.isLoading && service.notifications.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (service.error != null && service.notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 48, color: AppTheme.error),
            const SizedBox(height: 12),
            Text(service.error!,
                style: const TextStyle(color: AppTheme.textSecondary), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: service.load,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (service.notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.08), shape: BoxShape.circle),
              child: const Icon(Icons.notifications_none_rounded, size: 40, color: AppTheme.primary),
            ),
            const SizedBox(height: 20),
            const Text('No Notifications Yet',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            const Text(
              'Activity from emails, events, and calls\nwill appear here.',
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary, height: 1.5),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppTheme.accent,
      onRefresh: service.load,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        itemCount: service.notifications.length,
        itemBuilder: (_, i) {
          final n = service.notifications[i];
          return _NotificationTile(
            notif: n,
            onTap: () {
              service.markRead(n.id);
              _navigate(context, n);
            },
          );
        },
      ),
    );
  }

  void _navigate(BuildContext context, AppNotificationModel n) {
    switch (n.type) {
      case 'email_reply':
        context.go('/email/inbox');
        break;
      case 'event':
        if (n.referenceId != null) context.go('/events/${n.referenceId}');
        break;
      case 'call':
        if (n.referenceId != null) context.go('/calling/${n.referenceId}');
        break;
      default:
        break;
    }
  }
}

// ─── Notification Tile ────────────────────────────────────────────────────────

class _NotificationTile extends StatelessWidget {
  final AppNotificationModel notif;
  final VoidCallback onTap;

  const _NotificationTile({required this.notif, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final unread = !notif.isRead;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: unread
              ? Border(left: BorderSide(color: notif.color, width: 4))
              : null,
          boxShadow: [
            BoxShadow(
              color: (unread ? notif.color : Colors.black).withOpacity(0.06),
              blurRadius: 8, offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Type icon
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: notif.color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(notif.icon, size: 22, color: notif.color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notif.title,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: unread ? FontWeight.w800 : FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatDate(notif.createdAt),
                          style: TextStyle(
                            fontSize: 11,
                            color: unread ? notif.color : AppTheme.textSecondary,
                            fontWeight: unread ? FontWeight.w700 : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                    if (notif.body.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        notif.body,
                        maxLines: 2, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 12, color: AppTheme.textSecondary, height: 1.4),
                      ),
                    ],
                    const SizedBox(height: 6),
                    // Type badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: notif.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _typeLabel(notif.type),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: notif.color,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (unread)
                Container(
                  width: 8, height: 8, margin: const EdgeInsets.only(top: 4, left: 6),
                  decoration: BoxDecoration(color: notif.color, shape: BoxShape.circle),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'email_reply': return 'EMAIL REPLY';
      case 'event':       return 'EVENT';
      case 'call':        return 'CALL';
      default:            return 'NOTIFICATION';
    }
  }

  String _formatDate(DateTime dt) {
    final now  = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1)  return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24)   return '${diff.inHours}h ago';
    if (diff.inDays == 1)    return 'Yesterday';
    if (diff.inDays < 7)     return DateFormat('EEE').format(dt);
    return DateFormat('MMM d').format(dt);
  }
}
