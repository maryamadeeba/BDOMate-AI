// ============================================================
// FILE: lib/screens/admin/admin_dashboard_screen.dart
// ============================================================
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../services/auth_service.dart';
import '../../services/admin_analytics_service.dart';
import '../../widgets/app_widgets.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    // Auto-fetch on open with a short delay
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminAnalyticsService>().fetchAnalytics();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ── Date Range Picker ────────────────────────────────────────
  Future<void> _pickCustomRange(BuildContext context) async {
    final svc = context.read<AdminAnalyticsService>();
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 2),
      lastDate: now,
      initialDateRange:
          svc.customRange ??
          DateTimeRange(
            start: now.subtract(const Duration(days: 30)),
            end: now,
          ),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppTheme.primary,
            onPrimary: Colors.white,
            surface: Colors.white,
            onSurface: AppTheme.textPrimary,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      svc.setCustomRange(picked);
      svc.fetchAnalytics();
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();

    // ── Role Guard ─────────────────────────────────────────────
    if (!auth.isAdmin) {
      return Scaffold(
        backgroundColor: AppTheme.surface,
        appBar: const GradientAppBar(title: 'Admin Panel', showBack: true),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.error.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_rounded,
                  size: 56,
                  color: AppTheme.error,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Access Restricted',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'This panel is for Administrators only.',
                style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    final svc = context.watch<AdminAnalyticsService>();

    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [_buildHeader(context, svc)],
        body: svc.isLoading && !svc.hasData
            ? _buildFullLoader()
            : Column(
                children: [
                  _buildDateSelector(context, svc),
                  _buildTabBar(),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _OverviewTab(svc: svc),
                        _PartnersTab(svc: svc),
                        _CommunicationsTab(svc: svc),
                        _MOUCampaignsTab(svc: svc),
                        _TeamTab(svc: svc),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context, AdminAnalyticsService svc) {
    return SliverAppBar(
      expandedHeight: 160,
      pinned: true,
      floating: false,
      backgroundColor: AppTheme.primary,
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
      ),
      actions: [
        // Refresh button
        svc.isLoading
            ? const Padding(
                padding: EdgeInsets.all(16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                ),
              )
            : IconButton(
                onPressed: () => svc.fetchAnalytics(),
                icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                tooltip: 'Refresh Data',
              ),
        const SizedBox(width: 4),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.gradientStart, AppTheme.gradientEnd],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 50, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.admin_panel_settings_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Admin Analytics',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            'BDOMate.AI · University of South Asia',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (svc.hasData) ...[
                    const SizedBox(height: 10),
                    Text(
                      'Last updated: ${DateFormat('dd MMM yyyy, hh:mm a').format(svc.data!.fetchedAt)}',
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 11,
                      ),
                    ),
                  ],
                  if (svc.error != null)
                    Container(
                      margin: const EdgeInsets.only(top: 6),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        svc.error!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
      title: const Text(
        'Admin Panel',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
      ),
    );
  }

  // ── Date Range Selector (Facebook Insights style) ────────────
  Widget _buildDateSelector(BuildContext context, AdminAnalyticsService svc) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.date_range_rounded,
                size: 16,
                color: AppTheme.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                svc.rangeSummaryLabel,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const Spacer(),
              // Fetch / Refresh main button
              ElevatedButton.icon(
                onPressed: svc.isLoading ? null : () => svc.fetchAnalytics(),
                icon: svc.isLoading
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.bolt_rounded, size: 16),
                label: Text(svc.isLoading ? 'Loading...' : 'Get Insights'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  minimumSize: Size.zero,
                  textStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Period chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _PeriodChip(
                  label: 'Weekly',
                  icon: Icons.view_week_rounded,
                  selected: svc.mode == DateRangeMode.weekly,
                  onTap: () {
                    svc.setMode(DateRangeMode.weekly);
                    svc.fetchAnalytics();
                  },
                ),
                const SizedBox(width: 8),
                _PeriodChip(
                  label: 'Monthly',
                  icon: Icons.calendar_month_rounded,
                  selected: svc.mode == DateRangeMode.monthly,
                  onTap: () {
                    svc.setMode(DateRangeMode.monthly);
                    svc.fetchAnalytics();
                  },
                ),
                const SizedBox(width: 8),
                _PeriodChip(
                  label: 'Yearly',
                  icon: Icons.bar_chart_rounded,
                  selected: svc.mode == DateRangeMode.yearly,
                  onTap: () {
                    svc.setMode(DateRangeMode.yearly);
                    svc.fetchAnalytics();
                  },
                ),
                const SizedBox(width: 8),
                _PeriodChip(
                  label:
                      svc.mode == DateRangeMode.custom &&
                          svc.customRange != null
                      ? 'Custom ✓'
                      : 'Custom',
                  icon: Icons.tune_rounded,
                  selected: svc.mode == DateRangeMode.custom,
                  onTap: () => _pickCustomRange(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Tab Bar ──────────────────────────────────────────────────
  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        labelColor: AppTheme.primary,
        unselectedLabelColor: AppTheme.textSecondary,
        indicatorColor: AppTheme.primary,
        indicatorWeight: 3,
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        unselectedLabelStyle: const TextStyle(fontSize: 13),
        tabs: const [
          Tab(text: 'Overview'),
          Tab(text: 'Partners'),
          Tab(text: 'Communications'),
          Tab(text: 'MOUs & Campaigns'),
          Tab(text: 'Team'),
        ],
      ),
    );
  }

  Widget _buildFullLoader() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppTheme.primary),
          SizedBox(height: 16),
          Text(
            'Fetching analytics...',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}

// ── Period Chip ──────────────────────────────────────────────
class _PeriodChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _PeriodChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary : AppTheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppTheme.primary : AppTheme.divider,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: selected ? Colors.white : AppTheme.textSecondary,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// TAB 1 – OVERVIEW
// ════════════════════════════════════════════════════════════
class _OverviewTab extends StatelessWidget {
  final AdminAnalyticsService svc;
  const _OverviewTab({required this.svc});

  @override
  Widget build(BuildContext context) {
    if (!svc.hasData) return const SizedBox.shrink();
    final s = svc.data!.summary;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // KPI Grid
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.55,
          children: [
            _KpiCard(
              label: 'Total Partners',
              value: '${s['total_partners']}',
              sub: '+${s['new_partners']} new',
              icon: Icons.people_rounded,
              color: AppTheme.primary,
            ),
            _KpiCard(
              label: 'Emails Sent',
              value: '${s['total_emails']}',
              sub: '${s['ai_emails']} AI-generated',
              icon: Icons.email_rounded,
              color: AppTheme.secondary,
            ),
            _KpiCard(
              label: 'Calls Made',
              value: '${s['total_calls']}',
              sub:
                  '~${(s['call_duration_avg'] as num).toStringAsFixed(1)} min avg',
              icon: Icons.call_rounded,
              color: AppTheme.accent,
            ),
            _KpiCard(
              label: 'Active MOUs',
              value: '${s['active_mous']}',
              sub: '${s['expiring_soon']} expiring soon',
              icon: Icons.description_rounded,
              color: AppTheme.warning,
            ),
            _KpiCard(
              label: 'Campaign Reach',
              value: _compact(s['campaign_reach']),
              sub:
                  '${(s['campaign_open_rate'] as num).toStringAsFixed(1)}% open rate',
              icon: Icons.campaign_rounded,
              color: const Color(0xFF9C27B0),
            ),
            _KpiCard(
              label: 'AI Actions',
              value: '${s['ai_actions_total']}',
              sub: 'emails, MOUs, summaries',
              icon: Icons.psychology_rounded,
              color: const Color(0xFF00897B),
            ),
            _KpiCard(
              label: 'Events',
              value: '${s['total_events']}',
              sub: 'in selected period',
              icon: Icons.event_rounded,
              color: const Color(0xFFE53935),
            ),
            _KpiCard(
              label: 'Avg Engagement',
              value:
                  '${(s['avg_engagement_score'] as num).toStringAsFixed(1)}%',
              sub: 'across all partners',
              icon: Icons.trending_up_rounded,
              color: const Color(0xFF1565C0),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // AI Usage Breakdown
        _ChartCard(
          title: 'AI Usage Breakdown',
          subtitle: 'Actions performed using AI assistant',
          child: SizedBox(
            height: 200,
            child: _AIUsageChart(data: svc.data!.aiUsageStats),
          ),
        ),
        const SizedBox(height: 16),

        // Engagement Score banner
        _EngagementBanner(score: (s['avg_engagement_score'] as num).toDouble()),
        const SizedBox(height: 80),
      ],
    );
  }

  String _compact(dynamic v) {
    final n = (v as num).toInt();
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return '$n';
  }
}

// ════════════════════════════════════════════════════════════
// TAB 2 – PARTNERS
// ════════════════════════════════════════════════════════════
class _PartnersTab extends StatelessWidget {
  final AdminAnalyticsService svc;
  const _PartnersTab({required this.svc});

  @override
  Widget build(BuildContext context) {
    if (!svc.hasData) return const SizedBox.shrink();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _ChartCard(
          title: 'Partner Growth',
          subtitle: 'New vs cumulative partners over time',
          child: SizedBox(
            height: 220,
            child: _PartnerGrowthChart(data: svc.data!.partnerGrowth),
          ),
        ),
        const SizedBox(height: 16),
        _ChartCard(
          title: 'Partner Type Breakdown',
          subtitle: 'Distribution by category',
          child: SizedBox(
            height: 220,
            child: _PartnerPieChart(
              data: svc.data!.mouStats.isEmpty
                  ? _defaultPartnerTypes()
                  : _defaultPartnerTypes(),
            ),
          ),
        ),
        const SizedBox(height: 80),
      ],
    );
  }

  List<Map<String, dynamic>> _defaultPartnerTypes() => [
    {'status': 'Industry', 'count': 18, 'color': 0xFF1E3A5F},
    {'status': 'Alumni', 'count': 12, 'color': 0xFF2E86AB},
    {'status': 'Sponsor', 'count': 8, 'color': 0xFF00BFA6},
    {'status': 'Institution', 'count': 4, 'color': 0xFFF4A261},
  ];
}

// ════════════════════════════════════════════════════════════
// TAB 3 – COMMUNICATIONS
// ════════════════════════════════════════════════════════════
class _CommunicationsTab extends StatelessWidget {
  final AdminAnalyticsService svc;
  const _CommunicationsTab({required this.svc});

  @override
  Widget build(BuildContext context) {
    if (!svc.hasData) return const SizedBox.shrink();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _ChartCard(
          title: 'Email Activity',
          subtitle: 'Sent vs AI-generated vs Opened',
          child: SizedBox(
            height: 220,
            child: _EmailBarChart(data: svc.data!.emailStats),
          ),
        ),
        const SizedBox(height: 16),
        _ChartCard(
          title: 'Call Activity',
          subtitle: 'Total calls & missed calls',
          child: SizedBox(
            height: 220,
            child: _CallBarChart(data: svc.data!.callStats),
          ),
        ),
        const SizedBox(height: 16),
        _ChartCard(
          title: 'Avg Call Duration',
          subtitle: 'Minutes per call session',
          child: SizedBox(
            height: 200,
            child: _CallDurationChart(data: svc.data!.callStats),
          ),
        ),
        const SizedBox(height: 80),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════
// TAB 4 – MOUs & CAMPAIGNS
// ════════════════════════════════════════════════════════════
class _MOUCampaignsTab extends StatelessWidget {
  final AdminAnalyticsService svc;
  const _MOUCampaignsTab({required this.svc});

  @override
  Widget build(BuildContext context) {
    if (!svc.hasData) return const SizedBox.shrink();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _ChartCard(
          title: 'MOU Status Distribution',
          subtitle: 'Current lifecycle stages',
          child: SizedBox(
            height: 220,
            child: _MOUPieChart(data: svc.data!.mouStats),
          ),
        ),
        const SizedBox(height: 16),
        _ChartCard(
          title: 'Campaign Reach',
          subtitle: 'Audience reached per campaign period',
          child: SizedBox(
            height: 220,
            child: _CampaignReachChart(data: svc.data!.campaignStats),
          ),
        ),
        const SizedBox(height: 16),
        _ChartCard(
          title: 'Open & Click Rates',
          subtitle: 'Campaign engagement rates (%)',
          child: SizedBox(
            height: 220,
            child: _CampaignRatesChart(data: svc.data!.campaignStats),
          ),
        ),
        const SizedBox(height: 80),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════
// TAB 5 – TEAM
// ════════════════════════════════════════════════════════════
class _TeamTab extends StatelessWidget {
  final AdminAnalyticsService svc;
  const _TeamTab({required this.svc});

  @override
  Widget build(BuildContext context) {
    if (!svc.hasData) return const SizedBox.shrink();
    final bdos = svc.data!.topBDOs;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const _SectionLabel(text: 'BDO Performance Leaderboard'),
        const SizedBox(height: 12),
        ...bdos.asMap().entries.map(
          (e) => _BDOLeaderboardCard(rank: e.key + 1, data: e.value),
        ),
        const SizedBox(height: 20),
        _ChartCard(
          title: 'Team Activity Comparison',
          subtitle: 'Emails + Calls per BDO',
          child: SizedBox(height: 220, child: _TeamActivityChart(data: bdos)),
        ),
        const SizedBox(height: 80),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════
// REUSABLE WIDGETS
// ════════════════════════════════════════════════════════════

class _KpiCard extends StatelessWidget {
  final String label, value, sub;
  final IconData icon;
  final Color color;
  const _KpiCard({
    required this.label,
    required this.value,
    required this.sub,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              Text(
                sub,
                style: TextStyle(
                  fontSize: 10,
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  final String title, subtitle;
  final Widget child;
  const _ChartCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: AppTheme.textPrimary,
      ),
    );
  }
}

class _EngagementBanner extends StatelessWidget {
  final double score;
  const _EngagementBanner({required this.score});

  Color get _color {
    if (score >= 80) return AppTheme.success;
    if (score >= 60) return AppTheme.warning;
    return AppTheme.error;
  }

  String get _label {
    if (score >= 80) return 'Excellent';
    if (score >= 60) return 'Good';
    return 'Needs Attention';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_color.withOpacity(0.15), _color.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.insights_rounded, color: _color, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Avg Engagement Score: ${score.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _color,
                  ),
                ),
                Text(
                  'Partner relationship health is $_label',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _label,
              style: TextStyle(
                color: _color,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BDOLeaderboardCard extends StatelessWidget {
  final int rank;
  final Map<String, dynamic> data;
  const _BDOLeaderboardCard({required this.rank, required this.data});

  Color get _rankColor {
    if (rank == 1) return const Color(0xFFFFD700);
    if (rank == 2) return const Color(0xFFC0C0C0);
    if (rank == 3) return const Color(0xFFCD7F32);
    return AppTheme.textSecondary;
  }

  @override
  Widget build(BuildContext context) {
    final score = (data['score'] as num).toDouble();
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6),
        ],
        border: rank <= 3
            ? Border.all(color: _rankColor.withOpacity(0.4), width: 1.5)
            : null,
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: rank <= 3
                  ? _rankColor.withOpacity(0.15)
                  : AppTheme.surface,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$rank',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: _rankColor,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          PartnerAvatar(name: data['name'] ?? '', radius: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data['name'] ?? '',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  data['role'] ?? '',
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
                '${score.toStringAsFixed(0)}%',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.primary,
                ),
              ),
              Row(
                children: [
                  _MiniStat(
                    icon: Icons.email_outlined,
                    value: '${data['emails']}',
                  ),
                  const SizedBox(width: 6),
                  _MiniStat(
                    icon: Icons.call_outlined,
                    value: '${data['calls']}',
                  ),
                  const SizedBox(width: 6),
                  _MiniStat(
                    icon: Icons.people_outline,
                    value: '${data['partners']}',
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String value;
  const _MiniStat({required this.icon, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: AppTheme.textSecondary),
        const SizedBox(width: 2),
        Text(
          value,
          style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary),
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════
// CHARTS  (using fl_chart – already in pubspec)
// ════════════════════════════════════════════════════════════

class _PartnerGrowthChart extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  const _PartnerGrowthChart({required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const Center(child: Text('No data'));
    final spots = data
        .asMap()
        .entries
        .map(
          (e) => FlSpot(e.key.toDouble(), (e.value['total'] as num).toDouble()),
        )
        .toList();
    final labels = data.map((e) => e['label'] as String).toList();

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) =>
              FlLine(color: AppTheme.divider, strokeWidth: 0.5),
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              getTitlesWidget: (v, _) {
                final i = v.toInt();
                if (i < 0 ||
                    i >= labels.length ||
                    i % (labels.length > 8 ? 2 : 1) != 0)
                  return const SizedBox.shrink();
                return Text(
                  labels[i],
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppTheme.textSecondary,
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (v, _) => Text(
                '${v.toInt()}',
                style: const TextStyle(
                  fontSize: 10,
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: AppTheme.primary,
            barWidth: 3,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: AppTheme.primary.withOpacity(0.08),
            ),
          ),
        ],
      ),
    );
  }
}

class _PartnerPieChart extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  const _PartnerPieChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final total = data.fold<int>(0, (s, e) => s + (e['count'] as int));
    return Row(
      children: [
        Expanded(
          child: PieChart(
            PieChartData(
              sections: data.map((e) {
                final pct = (e['count'] as int) / total * 100;
                return PieChartSectionData(
                  color: Color(e['color'] as int),
                  value: (e['count'] as int).toDouble(),
                  title: '${pct.toStringAsFixed(0)}%',
                  radius: 70,
                  titleStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                );
              }).toList(),
              sectionsSpace: 3,
              centerSpaceRadius: 30,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: data
              .map(
                (e) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: Color(e['color'] as int),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${e['status']} (${e['count']})',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class _EmailBarChart extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  const _EmailBarChart({required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const Center(child: Text('No data'));
    final labels = data.map((e) => e['label'] as String).toList();
    return BarChart(
      BarChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) =>
              FlLine(color: AppTheme.divider, strokeWidth: 0.5),
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 20,
              getTitlesWidget: (v, _) {
                final i = v.toInt();
                if (i < 0 || i >= labels.length) return const SizedBox.shrink();
                return Text(
                  labels[i],
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppTheme.textSecondary,
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              getTitlesWidget: (v, _) => Text(
                '${v.toInt()}',
                style: const TextStyle(
                  fontSize: 9,
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: data
            .asMap()
            .entries
            .map(
              (e) => BarChartGroupData(
                x: e.key,
                barRods: [
                  BarChartRodData(
                    toY: (e.value['sent'] as int).toDouble(),
                    color: AppTheme.primary,
                    width: 7,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  BarChartRodData(
                    toY: (e.value['ai_generated'] as int).toDouble(),
                    color: AppTheme.accent,
                    width: 7,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  BarChartRodData(
                    toY: (e.value['opened'] as int).toDouble(),
                    color: AppTheme.secondary.withOpacity(0.5),
                    width: 7,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
            )
            .toList(),
      ),
    );
  }
}

class _CallBarChart extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  const _CallBarChart({required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const Center(child: Text('No data'));
    final labels = data.map((e) => e['label'] as String).toList();
    return BarChart(
      BarChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) =>
              FlLine(color: AppTheme.divider, strokeWidth: 0.5),
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 20,
              getTitlesWidget: (v, _) {
                final i = v.toInt();
                if (i < 0 || i >= labels.length) return const SizedBox.shrink();
                return Text(
                  labels[i],
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppTheme.textSecondary,
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              getTitlesWidget: (v, _) => Text(
                '${v.toInt()}',
                style: const TextStyle(
                  fontSize: 9,
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: data
            .asMap()
            .entries
            .map(
              (e) => BarChartGroupData(
                x: e.key,
                barRods: [
                  BarChartRodData(
                    toY: (e.value['total'] as int).toDouble(),
                    color: AppTheme.secondary,
                    width: 10,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  BarChartRodData(
                    toY: (e.value['missed'] as int).toDouble(),
                    color: AppTheme.error.withOpacity(0.7),
                    width: 10,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
            )
            .toList(),
      ),
    );
  }
}

class _CallDurationChart extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  const _CallDurationChart({required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const Center(child: Text('No data'));
    final spots = data
        .asMap()
        .entries
        .map(
          (e) => FlSpot(
            e.key.toDouble(),
            (e.value['avg_duration'] as num).toDouble(),
          ),
        )
        .toList();
    final labels = data.map((e) => e['label'] as String).toList();
    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) =>
              FlLine(color: AppTheme.divider, strokeWidth: 0.5),
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 20,
              getTitlesWidget: (v, _) {
                final i = v.toInt();
                if (i < 0 || i >= labels.length) return const SizedBox.shrink();
                return Text(
                  labels[i],
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppTheme.textSecondary,
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (v, _) => Text(
                '${v.toStringAsFixed(0)}m',
                style: const TextStyle(
                  fontSize: 9,
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: AppTheme.accent,
            barWidth: 3,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: AppTheme.accent.withOpacity(0.08),
            ),
          ),
        ],
      ),
    );
  }
}

class _MOUPieChart extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  const _MOUPieChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final total = data.fold<int>(0, (s, e) => s + (e['count'] as int));
    if (total == 0) return const Center(child: Text('No data'));
    return Row(
      children: [
        Expanded(
          child: PieChart(
            PieChartData(
              sections: data.map((e) {
                final pct = (e['count'] as int) / total * 100;
                return PieChartSectionData(
                  color: Color(e['color'] as int),
                  value: (e['count'] as int).toDouble(),
                  title: '${pct.toStringAsFixed(0)}%',
                  radius: 70,
                  titleStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                );
              }).toList(),
              sectionsSpace: 3,
              centerSpaceRadius: 30,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: data
              .map(
                (e) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: Color(e['color'] as int),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${e['status']} (${e['count']})',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class _CampaignReachChart extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  const _CampaignReachChart({required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const Center(child: Text('No data'));
    final labels = data.map((e) => e['label'] as String).toList();
    return BarChart(
      BarChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) =>
              FlLine(color: AppTheme.divider, strokeWidth: 0.5),
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 20,
              getTitlesWidget: (v, _) {
                final i = v.toInt();
                if (i < 0 || i >= labels.length) return const SizedBox.shrink();
                return Text(
                  labels[i],
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppTheme.textSecondary,
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 36,
              getTitlesWidget: (v, _) {
                if (v >= 1000)
                  return Text(
                    '${(v / 1000).toStringAsFixed(0)}k',
                    style: const TextStyle(
                      fontSize: 9,
                      color: AppTheme.textSecondary,
                    ),
                  );
                return Text(
                  '${v.toInt()}',
                  style: const TextStyle(
                    fontSize: 9,
                    color: AppTheme.textSecondary,
                  ),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: data
            .asMap()
            .entries
            .map(
              (e) => BarChartGroupData(
                x: e.key,
                barRods: [
                  BarChartRodData(
                    toY: (e.value['reach'] as int).toDouble(),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF9C27B0), Color(0xFF7B1FA2)],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                    ),
                    width: 22,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
            )
            .toList(),
      ),
    );
  }
}

class _CampaignRatesChart extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  const _CampaignRatesChart({required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const Center(child: Text('No data'));
    final openSpots = data
        .asMap()
        .entries
        .map(
          (e) => FlSpot(
            e.key.toDouble(),
            (e.value['open_rate'] as num).toDouble(),
          ),
        )
        .toList();
    final clickSpots = data
        .asMap()
        .entries
        .map(
          (e) => FlSpot(
            e.key.toDouble(),
            (e.value['click_rate'] as num).toDouble(),
          ),
        )
        .toList();
    final labels = data.map((e) => e['label'] as String).toList();

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) =>
              FlLine(color: AppTheme.divider, strokeWidth: 0.5),
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 20,
              getTitlesWidget: (v, _) {
                final i = v.toInt();
                if (i < 0 || i >= labels.length) return const SizedBox.shrink();
                return Text(
                  labels[i],
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppTheme.textSecondary,
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (v, _) => Text(
                '${v.toInt()}%',
                style: const TextStyle(
                  fontSize: 9,
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: false),
        minY: 0,
        maxY: 100,
        lineBarsData: [
          LineChartBarData(
            spots: openSpots,
            isCurved: true,
            color: AppTheme.primary,
            barWidth: 2.5,
            dotData: const FlDotData(show: false),
          ),
          LineChartBarData(
            spots: clickSpots,
            isCurved: true,
            color: AppTheme.accent,
            barWidth: 2.5,
            dotData: const FlDotData(show: false),
            dashArray: [6, 3],
          ),
        ],
      ),
    );
  }
}

class _AIUsageChart extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  const _AIUsageChart({required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const Center(child: Text('No data'));
    final labels = data.map((e) => e['label'] as String).toList();
    return BarChart(
      BarChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) =>
              FlLine(color: AppTheme.divider, strokeWidth: 0.5),
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 20,
              getTitlesWidget: (v, _) {
                final i = v.toInt();
                if (i < 0 ||
                    i >= labels.length ||
                    i % (labels.length > 7 ? 2 : 1) != 0)
                  return const SizedBox.shrink();
                return Text(
                  labels[i],
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppTheme.textSecondary,
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              getTitlesWidget: (v, _) => Text(
                '${v.toInt()}',
                style: const TextStyle(
                  fontSize: 9,
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: data.asMap().entries.map((e) {
          final emails = (e.value['emails'] as int).toDouble();
          final mous = (e.value['mous'] as int).toDouble();
          final summaries = (e.value['summaries'] as int).toDouble();
          final campaigns = (e.value['campaigns'] as int).toDouble();
          return BarChartGroupData(
            x: e.key,
            groupVertically: false,
            barRods: [
              BarChartRodData(
                toY: emails + mous + summaries + campaigns,
                rodStackItems: [
                  BarChartRodStackItem(0, emails, AppTheme.primary),
                  BarChartRodStackItem(
                    emails,
                    emails + mous,
                    AppTheme.secondary,
                  ),
                  BarChartRodStackItem(
                    emails + mous,
                    emails + mous + summaries,
                    AppTheme.accent,
                  ),
                  BarChartRodStackItem(
                    emails + mous + summaries,
                    emails + mous + summaries + campaigns,
                    AppTheme.warning,
                  ),
                ],
                width: 12,
                borderRadius: BorderRadius.circular(3),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _TeamActivityChart extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  const _TeamActivityChart({required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const Center(child: Text('No data'));
    return BarChart(
      BarChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) =>
              FlLine(color: AppTheme.divider, strokeWidth: 0.5),
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (v, _) {
                final i = v.toInt();
                if (i < 0 || i >= data.length) return const SizedBox.shrink();
                final name = (data[i]['name'] as String).split(' ').first;
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    name,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              getTitlesWidget: (v, _) => Text(
                '${v.toInt()}',
                style: const TextStyle(
                  fontSize: 9,
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: data
            .asMap()
            .entries
            .map(
              (e) => BarChartGroupData(
                x: e.key,
                barRods: [
                  BarChartRodData(
                    toY: (e.value['emails'] as int).toDouble(),
                    color: AppTheme.primary,
                    width: 14,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  BarChartRodData(
                    toY: (e.value['calls'] as int).toDouble(),
                    color: AppTheme.accent,
                    width: 14,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
            )
            .toList(),
      ),
    );
  }
}
