import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../services/marketing_service.dart';
import '../../widgets/app_widgets.dart';

class CampaignDetailScreen extends StatelessWidget {
  final String campaignId;
  const CampaignDetailScreen({super.key, required this.campaignId});

  @override
  Widget build(BuildContext context) {
    final service = context.watch<MarketingService>();
    final campaign = service.getById(campaignId);
    if (campaign == null) return const Scaffold(body: EmptyState(icon: Icons.campaign_outlined, title: 'Campaign not found', subtitle: ''));

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: GradientAppBar(
        title: 'Campaign Details',
        showBack: true,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
            onSelected: (v) {
              if (v == 'delete') { service.deleteCampaign(campaign.id); context.go('/marketing'); }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'pause', child: Text('Pause Campaign')),
              const PopupMenuItem(value: 'duplicate', child: Text('Duplicate')),
              const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
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
            decoration: BoxDecoration(gradient: AppTheme.primaryGradient, borderRadius: BorderRadius.circular(16)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(campaign.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white))),
                if (campaign.isAiGenerated) const AiBadge(),
              ]),
              const SizedBox(height: 8),
              Text(campaign.description, style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.8))),
              const SizedBox(height: 12),
              Row(children: [
                StatusBadge(label: campaign.status.name.toUpperCase(), color: Colors.white, bgColor: Colors.white.withOpacity(0.2)),
                const SizedBox(width: 8),
                StatusBadge(label: campaign.type.name.replaceAll('_', ' ').toUpperCase(), color: Colors.white, bgColor: Colors.white.withOpacity(0.2)),
              ]),
            ]),
          ),
          const SizedBox(height: 14),

          // Performance metrics
          if (campaign.totalReach > 0) ...[
            const Text('Performance Metrics', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: _MetricCard(label: 'Total Reach', value: campaign.totalReach.toString(), color: AppTheme.primary, icon: Icons.people_rounded)),
              const SizedBox(width: 10),
              Expanded(child: _MetricCard(label: 'Opened', value: campaign.opened.toString(), color: AppTheme.secondary, icon: Icons.mark_email_read_rounded)),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: _MetricCard(label: 'Clicked', value: campaign.clicked.toString(), color: AppTheme.accent, icon: Icons.ads_click_rounded)),
              const SizedBox(width: 10),
              Expanded(child: _MetricCard(label: 'Converted', value: campaign.converted.toString(), color: AppTheme.success, icon: Icons.check_circle_rounded)),
            ]),
            const SizedBox(height: 14),

            // Progress bars
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Funnel Performance', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                const SizedBox(height: 14),
                _ProgressRow(label: 'Open Rate', value: campaign.openRate, color: AppTheme.secondary),
                const SizedBox(height: 10),
                _ProgressRow(label: 'Click Rate', value: campaign.clickRate, color: AppTheme.accent),
                const SizedBox(height: 10),
                _ProgressRow(label: 'Conversion Rate', value: campaign.conversionRate, color: AppTheme.success),
              ]),
            ),
            const SizedBox(height: 14),
          ],

          // Content
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Campaign Content', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              Text(campaign.content, style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary, height: 1.6)),
            ]),
          ),
          const SizedBox(height: 14),

          if (campaign.targetAudience.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Target Audience', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                Wrap(spacing: 8, runSpacing: 8, children: campaign.targetAudience.map((a) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.08), borderRadius: BorderRadius.circular(20)),
                  child: Text(a, style: const TextStyle(fontSize: 13, color: AppTheme.primary, fontWeight: FontWeight.w500)),
                )).toList()),
              ]),
            ),

          const SizedBox(height: 20),
          Row(children: [
            Expanded(child: OutlinedButton.icon(icon: const Icon(Icons.edit_rounded), label: const Text('Edit'), onPressed: () {})),
            const SizedBox(width: 12),
            Expanded(child: ElevatedButton.icon(icon: const Icon(Icons.send_rounded), label: const Text('Launch'), onPressed: () {})),
          ]),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  const _MetricCard({required this.label, required this.value, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: color, size: 20)),
        const SizedBox(width: 10),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
          Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
        ]),
      ]),
    );
  }
}

class _ProgressRow extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  const _ProgressRow({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
        Text('${value.toStringAsFixed(1)}%', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
      ]),
      const SizedBox(height: 6),
      ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: value / 100, color: color, backgroundColor: color.withOpacity(0.1), minHeight: 8)),
    ]);
  }
}
