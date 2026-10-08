import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../services/crm_service.dart';
import '../../models/partner_model.dart';
import '../../widgets/app_widgets.dart';

class CrmScreen extends StatefulWidget {
  const CrmScreen({super.key});

  @override
  State<CrmScreen> createState() => _CrmScreenState();
}

class _CrmScreenState extends State<CrmScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final crm = context.watch<CrmService>();

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: GradientAppBar(
        title: 'Partner CRM',
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list_rounded, color: Colors.white),
            onPressed: () => _showFilter(context),
          ),
          IconButton(
            icon: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
            onPressed: () => context.go('/crm/add'),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: AppTheme.primary,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white60,
              labelStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              tabs: const [
                Tab(text: 'All'),
                Tab(text: 'Industry'),
                Tab(text: 'Alumni'),
                Tab(text: 'Sponsors'),
                Tab(text: 'Institutions'),
              ],
              onTap: (i) {
                if (i == 0) {
                  crm.setFilterType(null);
                } else if (i == 1)
                  crm.setFilterType(PartnerType.industry);
                else if (i == 2)
                  crm.setFilterType(PartnerType.alumni);
                else if (i == 3)
                  crm.setFilterType(PartnerType.sponsor);
                else
                  crm.setFilterType(PartnerType.institution);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search partners, organizations...',
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: AppTheme.textSecondary,
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onChanged: crm.setSearch,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  '${crm.partners.length} partners',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Text(
                  '${crm.activeCount} active',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: crm.partners.isEmpty
                ? const EmptyState(
                    icon: Icons.people_outline_rounded,
                    title: 'No Partners Found',
                    subtitle: 'Add partners to start building your network',
                  )
                : ListView.builder(
                    // 🔑 Fixed: Increased bottom padding to prevent cutoff behind the bar
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 100),
                    itemCount: crm.partners.length,
                    itemBuilder: (_, i) => _PartnerCard(
                      partner: crm.partners[i],
                      onTap: () => context.go('/crm/${crm.partners[i].id}'),
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/crm/add'),
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.person_add_rounded, color: Colors.white),
        label: const Text(
          'Add Partner',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  void _showFilter(BuildContext context) {
    final crm = context.read<CrmService>();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filter Partners',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            const Text(
              'Status',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                FilterChip(
                  label: const Text('All'),
                  selected: crm.filterStatus == null,
                  onSelected: (_) {
                    crm.setFilterStatus(null);
                    Navigator.pop(context);
                  },
                ),
                ...PartnerStatus.values.map(
                  (s) => FilterChip(
                    label: Text(s.name.capitalize()),
                    selected: crm.filterStatus == s,
                    onSelected: (_) {
                      crm.setFilterStatus(s);
                      Navigator.pop(context);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

extension StringExt on String {
  String capitalize() =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
}

class _PartnerCard extends StatelessWidget {
  final PartnerModel partner;
  final VoidCallback onTap;

  const _PartnerCard({required this.partner, required this.onTap});

  Color get _statusColor {
    switch (partner.status) {
      case PartnerStatus.active:
        return AppTheme.success;
      case PartnerStatus.inactive:
        return AppTheme.textSecondary;
      case PartnerStatus.pending:
        return AppTheme.warning;
      case PartnerStatus.blacklisted:
        return AppTheme.error;
    }
  }

  Color get _typeColor {
    switch (partner.type) {
      case PartnerType.industry:
        return AppTheme.primary;
      case PartnerType.alumni:
        return AppTheme.secondary;
      case PartnerType.sponsor:
        return AppTheme.accent;
      case PartnerType.institution:
        return AppTheme.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8),
          ],
        ),
        child: Row(
          children: [
            PartnerAvatar(
              name: partner.name,
              avatarUrl: partner.avatar,
              radius: 26,
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
                          partner.name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      StatusBadge(
                        label: partner.statusLabel,
                        color: _statusColor,
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    partner.organization,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      StatusBadge(label: partner.typeLabel, color: _typeColor),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.star_rounded,
                        size: 14,
                        color: AppTheme.warning,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${partner.engagementScore.toStringAsFixed(0)}%',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      if (partner.lastContactedAt != null) ...[
                        const SizedBox(width: 8),
                        Icon(
                          Icons.access_time_rounded,
                          size: 12,
                          color: AppTheme.textSecondary.withOpacity(0.6),
                        ),
                        const SizedBox(width: 2),
                        Text(
                          _timeAgo(partner.lastContactedAt!),
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.textSecondary.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppTheme.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    return 'just now';
  }
}
