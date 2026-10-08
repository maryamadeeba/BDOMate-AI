import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../services/marketing_service.dart';
import '../../models/campaign_model.dart';
import '../../widgets/app_widgets.dart';

class MarketingScreen extends StatelessWidget {
  const MarketingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = context.watch<MarketingService>();

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: GradientAppBar(
        title: 'Marketing',
        actions: [
          IconButton(icon: const Icon(Icons.add_rounded, color: Colors.white, size: 28), onPressed: () => context.go('/marketing/create')),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          // Summary stats
          Row(children: [
            Expanded(child: StatCard(label: 'Total Reach', value: service.totalReach.toString(), icon: Icons.people_rounded, color: AppTheme.primary)),
            const SizedBox(width: 10),
            Expanded(child: StatCard(label: 'Avg Open Rate', value: '${service.avgOpenRate.toStringAsFixed(0)}%', icon: Icons.open_in_new_rounded, color: AppTheme.accent)),
          ]),
          const SizedBox(height: 16),
          SectionHeader(title: 'Campaigns', actionLabel: 'Create New', onAction: () => context.go('/marketing/create')),
          const SizedBox(height: 10),
          if (service.campaigns.isEmpty)
            const EmptyState(icon: Icons.campaign_outlined, title: 'No Campaigns', subtitle: 'Create your first AI-powered marketing campaign')
          else
            ...service.campaigns.map((c) => _CampaignCard(campaign: c, onTap: () => context.go('/marketing/${c.id}'))),
          const SizedBox(height: 80),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/marketing/create'),
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.psychology_rounded, color: Colors.white),
        label: const Text('AI Campaign', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class _CampaignCard extends StatelessWidget {
  final CampaignModel campaign;
  final VoidCallback onTap;

  const _CampaignCard({required this.campaign, required this.onTap});

  Color get _statusColor {
    switch (campaign.status) {
      case CampaignStatus.draft: return AppTheme.textSecondary;
      case CampaignStatus.scheduled: return AppTheme.warning;
      case CampaignStatus.active: return AppTheme.success;
      case CampaignStatus.paused: return AppTheme.warning;
      case CampaignStatus.completed: return AppTheme.secondary;
    }
  }

  Color get _typeColor {
    switch (campaign.type) {
      case CampaignType.email: return AppTheme.primary;
      case CampaignType.social_media: return AppTheme.secondary;
      case CampaignType.sms: return AppTheme.accent;
      case CampaignType.whatsapp: return const Color(0xFF25D366);
      case CampaignType.mixed: return AppTheme.warning;
    }
  }

  IconData get _typeIcon {
    switch (campaign.type) {
      case CampaignType.email: return Icons.email_rounded;
      case CampaignType.social_media: return Icons.share_rounded;
      case CampaignType.sms: return Icons.sms_rounded;
      case CampaignType.whatsapp: return Icons.chat_rounded;
      case CampaignType.mixed: return Icons.campaign_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: _typeColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: Icon(_typeIcon, color: _typeColor, size: 20)),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(campaign.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
              if (campaign.platform != null) Text(campaign.platform!, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              StatusBadge(label: campaign.status.name.toUpperCase(), color: _statusColor),
              if (campaign.isAiGenerated) ...[const SizedBox(height: 4), const AiBadge()],
            ]),
          ]),
          const SizedBox(height: 12),
          Text(campaign.content, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary, height: 1.4)),
          if (campaign.totalReach > 0) ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 10),
            Row(children: [
              _MetricChip(label: 'Reach', value: campaign.totalReach.toString(), color: AppTheme.primary),
              _MetricChip(label: 'Open Rate', value: '${campaign.openRate.toStringAsFixed(0)}%', color: AppTheme.secondary),
              _MetricChip(label: 'Click Rate', value: '${campaign.clickRate.toStringAsFixed(0)}%', color: AppTheme.accent),
              _MetricChip(label: 'Converted', value: campaign.converted.toString(), color: AppTheme.success),
            ]),
          ],
        ]),
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MetricChip({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(child: Column(children: [
      Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: color)),
      Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
    ]));
  }
}
