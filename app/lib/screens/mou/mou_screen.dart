import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../services/mou_service.dart';
import '../../models/mou_model.dart';
import '../../widgets/app_widgets.dart';

class MouScreen extends StatelessWidget {
  const MouScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = context.watch<MouService>();

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: GradientAppBar(
        title: 'MOU Manager',
        actions: [
          IconButton(icon: const Icon(Icons.add_rounded, color: Colors.white, size: 28), onPressed: () => context.go('/mou/generate')),
        ],
      ),
      body: Column(
        children: [
          if (service.expiringSoon.isNotEmpty)
            Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: AppTheme.warning.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.warning.withOpacity(0.3))),
              child: Row(children: [
                const Icon(Icons.warning_amber_rounded, color: AppTheme.warning, size: 22),
                const SizedBox(width: 10),
                Expanded(child: Text('${service.expiringSoon.length} MOU(s) expiring within 30 days', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.warning))),
                TextButton(onPressed: () {}, child: const Text('View', style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.warning))),
              ]),
            ),
          Expanded(
            child: service.mous.isEmpty
                ? const EmptyState(icon: Icons.description_outlined, title: 'No MOUs', subtitle: 'Generate your first MOU using AI')
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: service.mous.length,
                    itemBuilder: (_, i) => _MouCard(mou: service.mous[i], onTap: () => context.go('/mou/${service.mous[i].id}')),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/mou/generate'),
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.psychology_rounded, color: Colors.white),
        label: const Text('Generate MOU', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class _MouCard extends StatelessWidget {
  final MouModel mou;
  final VoidCallback onTap;

  const _MouCard({required this.mou, required this.onTap});

  Color get _statusColor {
    switch (mou.status) {
      case MouStatus.draft: return AppTheme.textSecondary;
      case MouStatus.pending_review: return AppTheme.warning;
      case MouStatus.signed: return AppTheme.secondary;
      case MouStatus.active: return AppTheme.success;
      case MouStatus.expired: return AppTheme.error;
      case MouStatus.terminated: return AppTheme.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(mou.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textPrimary), maxLines: 2)),
            const SizedBox(width: 8),
            StatusBadge(label: mou.statusLabel.toUpperCase(), color: _statusColor),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            PartnerAvatar(name: mou.partnerName, radius: 14),
            const SizedBox(width: 8),
            Text(mou.partnerOrganization, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
            const Spacer(),
            if (mou.isAiGenerated) const AiBadge(),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            if (mou.signedAt != null) ...[
              Icon(Icons.check_circle_rounded, size: 14, color: AppTheme.success),
              const SizedBox(width: 4),
              Text('Signed: ${DateFormat('MMM d, yyyy').format(mou.signedAt!)}', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
              const SizedBox(width: 12),
            ],
            if (mou.expiryDate != null) ...[
              Icon(mou.isExpired ? Icons.error_outline : Icons.access_time_rounded, size: 14, color: mou.isExpired ? AppTheme.error : (mou.daysUntilExpiry! < 30 ? AppTheme.warning : AppTheme.textSecondary)),
              const SizedBox(width: 4),
              Text(mou.isExpired ? 'Expired' : 'Expires: ${DateFormat('MMM d, yyyy').format(mou.expiryDate!)}', style: TextStyle(fontSize: 12, color: mou.isExpired ? AppTheme.error : (mou.daysUntilExpiry! < 30 ? AppTheme.warning : AppTheme.textSecondary), fontWeight: mou.daysUntilExpiry != null && mou.daysUntilExpiry! < 30 ? FontWeight.w700 : FontWeight.normal)),
            ],
          ]),
        ]),
      ),
    );
  }
}
