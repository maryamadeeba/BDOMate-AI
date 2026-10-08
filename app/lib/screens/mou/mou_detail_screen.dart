import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../services/mou_service.dart';
import '../../models/mou_model.dart';
import '../../widgets/app_widgets.dart';

class MouDetailScreen extends StatelessWidget {
  final String mouId;
  const MouDetailScreen({super.key, required this.mouId});

  @override
  Widget build(BuildContext context) {
    final service = context.watch<MouService>();
    final mou = service.getById(mouId);
    if (mou == null) {
      return const Scaffold(
        body: EmptyState(
          icon: Icons.description_outlined,
          title: 'MOU not found',
          subtitle: '',
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: GradientAppBar(
        title: 'MOU Details',
        showBack: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded, color: Colors.white),
            onPressed: () {},
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
            onSelected: (v) async {
              if (v == 'sign') await service.signMou(mou.id);
              if (v == 'delete') {
                service.updateMou(mou..status = MouStatus.terminated);
                context.go('/mou');
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'sign', child: Text('Mark as Signed')),
              const PopupMenuItem(
                value: 'download',
                child: Text('Download PDF'),
              ),
              const PopupMenuItem(
                value: 'send',
                child: Text('Send to Partner'),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Text(
                  'Terminate MOU',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        mou.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    if (mou.isAiGenerated)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.psychology_rounded,
                              color: Colors.white,
                              size: 12,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'AI',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                StatusBadge(
                  label: mou.statusLabel.toUpperCase(),
                  color: Colors.white,
                  bgColor: Colors.white.withOpacity(0.2),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Parties
          _InfoSection(
            title: 'Parties',
            children: [
              InfoRow(
                icon: Icons.account_balance_rounded,
                label: 'University Representative',
                value: mou.universityRepresentative,
              ),
              const Divider(height: 16),
              InfoRow(
                icon: Icons.business_rounded,
                label: 'Partner Organization',
                value: mou.partnerOrganization,
              ),
              const Divider(height: 16),
              InfoRow(
                icon: Icons.person_rounded,
                label: 'Partner Representative',
                value: mou.partnerRepresentative,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Dates
          _InfoSection(
            title: 'Timeline',
            children: [
              InfoRow(
                icon: Icons.create_rounded,
                label: 'Created',
                value: DateFormat('MMMM d, yyyy').format(mou.createdAt),
              ),
              if (mou.signedAt != null) ...[
                const Divider(height: 16),
                InfoRow(
                  icon: Icons.check_circle_rounded,
                  label: 'Signed',
                  value: DateFormat('MMMM d, yyyy').format(mou.signedAt!),
                  iconColor: AppTheme.success,
                ),
              ],
              if (mou.startDate != null) ...[
                const Divider(height: 16),
                InfoRow(
                  icon: Icons.play_circle_rounded,
                  label: 'Effective From',
                  value: DateFormat('MMMM d, yyyy').format(mou.startDate!),
                ),
              ],
              if (mou.expiryDate != null) ...[
                const Divider(height: 16),
                InfoRow(
                  icon: Icons.event_rounded,
                  label: 'Expires',
                  value: DateFormat('MMMM d, yyyy').format(mou.expiryDate!),
                  iconColor: mou.isExpired
                      ? AppTheme.error
                      : (mou.daysUntilExpiry! < 30 ? AppTheme.warning : null),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),

          // Purpose
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Purpose',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  mou.purpose,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Obligations
          if (mou.obligations.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Key Obligations',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),
                  ...mou.obligations.map(
                    (o) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.circle,
                            color: AppTheme.primary,
                            size: 8,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              o,
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppTheme.textSecondary,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),

          // MOU Content
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'MOU Document',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                Text(
                  mou.content,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                    height: 1.7,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          if (mou.status == MouStatus.draft ||
              mou.status == MouStatus.pending_review)
            ElevatedButton.icon(
              onPressed: () => service.signMou(mou.id),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.success,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              icon: const Icon(Icons.check_rounded),
              label: const Text(
                'Mark as Signed',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _InfoSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}
