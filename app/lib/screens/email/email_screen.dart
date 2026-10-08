import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../services/email_service.dart';
import '../../models/email_model.dart';
import '../../widgets/app_widgets.dart';
import '../../services/email_reply_service.dart';

class EmailScreen extends StatefulWidget {
  const EmailScreen({super.key});

  @override
  State<EmailScreen> createState() => _EmailScreenState();
}

class _EmailScreenState extends State<EmailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final emailService = context.watch<EmailService>();

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: const Text(
          'Email',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppTheme.primary,
        elevation: 0,
        actions: [
          // ✅ Inbox button with unread badge
          Consumer<EmailReplyService>(
            builder: (_, svc, __) => Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.inbox_rounded, color: Colors.white),
                  tooltip: 'Inbox',
                  onPressed: () => context.go('/email/inbox'),
                ),
                if (svc.unreadCount > 0)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: const BoxDecoration(
                        color: AppTheme.error,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${svc.unreadCount}',
                          style: const TextStyle(
                            fontSize: 9,
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_rounded, color: Colors.white),
            onPressed: () => context.go('/email/compose'),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: AppTheme.primary,
            child: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white60,
              labelStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              tabs: [
                Tab(text: 'All (${emailService.emails.length})'),
                Tab(text: 'Sent (${emailService.sent.length})'),
                Tab(text: 'Drafts (${emailService.drafts.length})'),
              ],
            ),
          ),
          // 🌟 Expanded forces the TabBarView to strictly occupy remaining space and blocks infinite growth
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildEmailList(emailService.emails, emailService),
                _buildEmailList(emailService.sent, emailService),
                _buildEmailList(emailService.drafts, emailService),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/email/compose'),
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.psychology_rounded, color: Colors.white),
        label: const Text(
          'AI Compose',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildEmailList(List<EmailModel> emails, EmailService service) {
    if (emails.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.email_outlined,
                size: 48,
                color: AppTheme.textSecondary,
              ),
              SizedBox(height: 12),
              Text(
                'No Emails',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textSecondary,
                ),
              ),
              Text(
                'Compose your first email using AI',
                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    // Wrapped builder tightly inside an explicit LayoutBuilder structure
    return LayoutBuilder(
      builder: (context, constraints) {
        return ListView.builder(
          // 🔑 Fixed: Increased bottom padding from 12 to 140 to lift content above the floating bar layout layer
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 140),
          itemCount: emails.length,
          itemBuilder: (_, i) {
            return _EmailCard(
              email: emails[i],
              cardWidth: constraints.maxWidth,
              onTap: () {
                service.markRead(emails[i].id);
                context.go('/email/${emails[i].id}');
              },
            );
          },
        );
      },
    );
  }
}

class _EmailCard extends StatelessWidget {
  final EmailModel email;
  final double cardWidth;
  final VoidCallback onTap;

  const _EmailCard({
    required this.email,
    required this.cardWidth,
    required this.onTap,
  });

  Color get _statusColor {
    switch (email.status) {
      case EmailStatus.sent:
        return AppTheme.success;
      case EmailStatus.draft:
        return AppTheme.textSecondary;
      case EmailStatus.failed:
        return AppTheme.error;
      case EmailStatus.scheduled:
        return AppTheme.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    // We use a bounded horizontal frame limit to instantly terminate row calculations going out of bounds
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: cardWidth,
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: !email.isRead
                ? AppTheme.secondary.withValues(alpha: 0.3)
                : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: Profile and Info
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                  child: Text(
                    email.toName.isNotEmpty
                        ? email.toName[0].toUpperCase()
                        : 'P',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        email.toName.isEmpty ? 'Partner' : email.toName,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: email.isRead
                              ? FontWeight.w500
                              : FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        email.toEmail,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      DateFormat('MMM d').format(email.createdAt),
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        email.status.name.toUpperCase(),
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: _statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Row 2: Subject line
            Row(
              children: [
                Expanded(
                  child: Text(
                    email.subject.isEmpty ? '(No Subject)' : email.subject,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: email.isRead
                          ? FontWeight.w500
                          : FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (email.isAiGenerated) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.secondary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'AI',
                      style: TextStyle(
                        fontSize: 9,
                        color: AppTheme.secondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 4),

            // Text 3: Body text
            Text(
              email.body.isEmpty ? '(Empty message body)' : email.body,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
