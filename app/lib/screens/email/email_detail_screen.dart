import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../services/email_service.dart';
import '../../models/email_model.dart';
import '../../widgets/app_widgets.dart';

class EmailDetailScreen extends StatelessWidget {
  final String emailId;
  const EmailDetailScreen({super.key, required this.emailId});

  @override
  Widget build(BuildContext context) {
    final service = context.watch<EmailService>();
    final email = service.getById(emailId);
    if (email == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Email Not Found')),
        body: const EmptyState(
          icon: Icons.email_outlined,
          title: 'Email not found',
          subtitle: '',
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: GradientAppBar(
        title: 'Email',
        showBack: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.reply_rounded, color: Colors.white),
            onPressed: () => context.go('/email/compose'),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
            onSelected: (v) {
              if (v == 'delete') {
                service.deleteEmail(email.id);
                context.go('/email');
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'forward', child: Text('Forward')),
              const PopupMenuItem(
                value: 'delete',
                child: Text('Delete', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [

          // ── Subject / From / To card ──────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // Subject line
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        email.subject,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    if (email.isAiGenerated) const AiBadge(),
                  ],
                ),
                const SizedBox(height: 12),

                // From row
                Row(
                  children: [
                    PartnerAvatar(name: email.fromName, radius: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            email.fromName,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'From: ${email.fromEmail}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          DateFormat('MMM d, yyyy').format(email.createdAt),
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        if (email.sentAt != null)
                          Text(
                            DateFormat('h:mm a').format(email.sentAt!),
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                const Divider(height: 16),

                // To row
                Row(
                  children: [
                    const Icon(
                      Icons.person_outline,
                      size: 16,
                      color: AppTheme.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'To: ${email.toName} <${email.toEmail}>',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),

              ],  // Column children
            ),    // Column
          ),      // Container (subject card)
          const SizedBox(height: 12),

          // ── Status card ───────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  _StatusItem(
                    icon: Icons.info_outline,
                    label: 'Status',
                    value: email.status.name.toUpperCase(),
                    color: _statusColor(email.status),
                  ),
                  const VerticalDivider(width: 32),
                  _StatusItem(
                    icon: Icons.priority_high_rounded,
                    label: 'Priority',
                    value: email.priority.name.toUpperCase(),
                    color: _priorityColor(email.priority),
                  ),
                  if (email.category != null) ...[
                    const VerticalDivider(width: 32),
                    _StatusItem(
                      icon: Icons.label_outline,
                      label: 'Category',
                      value: email.category!,
                      color: AppTheme.secondary,
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ── Body card ─────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              email.body,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textPrimary,
                height: 1.7,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // ── Action buttons ────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.reply_rounded),
                  label: const Text('Reply'),
                  onPressed: () => context.go('/email/compose'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.forward_to_inbox_rounded),
                  label: const Text('Forward'),
                  onPressed: () => context.go('/email/compose'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),

        ],      // ListView children
      ),        // ListView
    );          // Scaffold
  }

  Color _statusColor(EmailStatus s) {
    switch (s) {
      case EmailStatus.sent:      return AppTheme.success;
      case EmailStatus.draft:     return AppTheme.textSecondary;
      case EmailStatus.failed:    return AppTheme.error;
      case EmailStatus.scheduled: return AppTheme.warning;
    }
  }

  Color _priorityColor(EmailPriority p) {
    switch (p) {
      case EmailPriority.low:    return AppTheme.success;
      case EmailPriority.normal: return AppTheme.secondary;
      case EmailPriority.high:   return AppTheme.error;
    }
  }
}

class _StatusItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatusItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
