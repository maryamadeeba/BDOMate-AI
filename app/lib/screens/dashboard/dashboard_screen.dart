import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../services/auth_service.dart';
import '../../services/analytics_service.dart';
import '../../services/notification_service.dart';
import '../../widgets/app_widgets.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  late AnimationController _headerCtrl;
  late AnimationController _cardsCtrl;
  late AnimationController _pulseCtrl;
  late Animation<double> _headerFade;
  late Animation<Offset> _headerSlide;
  late Animation<double> _cardsFade;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();

    _headerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _cardsCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _headerFade = CurvedAnimation(parent: _headerCtrl, curve: Curves.easeOut);
    _headerSlide = Tween<Offset>(
      begin: const Offset(0, -0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _headerCtrl, curve: Curves.easeOutCubic));
    _cardsFade = CurvedAnimation(parent: _cardsCtrl, curve: Curves.easeOut);
    _pulseAnim = Tween<double>(
      begin: 0.85,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _headerCtrl.forward();
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) _cardsCtrl.forward();
      });
    });
  }

  @override
  void dispose() {
    _headerCtrl.dispose();
    _cardsCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final analytics = context.watch<AnalyticsService>();
    final notif = context.watch<NotificationService>();
    final stats = analytics.dashboardStats;
    final firstName = auth.currentUser?.name.split(' ').first ?? 'BDO';
    final initials =
        auth.currentUser?.name
            .split(' ')
            .take(2)
            .map((w) => w.isNotEmpty ? w[0] : '')
            .join() ??
        'MA';

    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Immersive Header Shell ───────────────────────────
          SliverAppBar(
            expandedHeight: 230,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: AppTheme.darkBg,
            systemOverlayStyle: SystemUiOverlayStyle.light,
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.parallax,
              background: _buildHeader(
                context,
                firstName,
                initials,
                notif,
                stats,
              ),
            ),
          ),

          // ── Body ─────────────────────────────────────────────
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _cardsFade,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),

                    // AI Banner
                    _buildAiBanner(context),
                    const SizedBox(height: 24),

                    // Stats Grid
                    _SectionLabel(label: 'OVERVIEW'),
                    const SizedBox(height: 12),
                    _buildStatsGrid(context, stats),
                    const SizedBox(height: 24),

                    // Quick Actions
                    _SectionLabel(label: 'QUICK ACTIONS'),
                    const SizedBox(height: 12),
                    _buildQuickActions(context),
                    const SizedBox(height: 24),

                    // Recent Activity
                    _buildSectionRow(
                      'Recent Activity',
                      'Analytics',
                      () => context.go('/analytics'),
                    ),
                    const SizedBox(height: 12),
                    ...analytics.recentActivity.asMap().entries.map(
                      (e) => _AnimatedActivityItem(
                        activity: e.value,
                        index: e.key,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Top Partners
                    _buildSectionRow(
                      'Top Partners',
                      'View All',
                      () => context.go('/crm'),
                    ),
                    const SizedBox(height: 12),
                    ...analytics.topPartners.asMap().entries.map(
                      (e) => _AnimatedPartnerItem(
                        partner: e.value,
                        index: e.key,
                        onTap: () => context.go('/crm'),
                      ),
                    ),

                    // 🔑 Fixed: Increased bottom padding spacing to let elements pass past the floating bottom nav bar fully
                    const SizedBox(height: 140),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Header Widget ─────────────────────────────────────────────
  Widget _buildHeader(
    BuildContext context,
    String firstName,
    String initials,
    NotificationService notif,
    Map<String, dynamic> stats,
  ) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0D1B2A), Color(0xFF1A2F5E), Color(0xFF0D2445)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        Positioned(
          top: -40,
          right: -40,
          child: Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.primary.withOpacity(0.12),
            ),
          ),
        ),
        Positioned(
          bottom: -20,
          left: -30,
          child: Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.secondary.withOpacity(0.08),
            ),
          ),
        ),
        Positioned(
          top: 60,
          right: 60,
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.warning.withOpacity(0.10),
            ),
          ),
        ),
        SafeArea(
          child: SlideTransition(
            position: _headerSlide,
            child: FadeTransition(
              opacity: _headerFade,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                gradient: AppTheme.blueGradient,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'B',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'BDOMate.AI',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () {
                                HapticFeedback.lightImpact();
                                context.go('/settings');
                              },
                              child: Container(
                                padding: const EdgeInsets.all(9),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.settings_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            GestureDetector(
                              onTap: () {
                                HapticFeedback.lightImpact();
                                context.go('/notifications');
                              },
                              child: Stack(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(9),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.notifications_rounded,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                  if (notif.unreadCount > 0)
                                    Positioned(
                                      right: 4,
                                      top: 4,
                                      child: Container(
                                        width: 9,
                                        height: 9,
                                        decoration: BoxDecoration(
                                          color: AppTheme.error,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: AppTheme.darkBg,
                                            width: 1.5,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            ScaleTransition(
                              scale: _pulseAnim,
                              child: GestureDetector(
                                onTap: () => context.go('/settings/profile'),
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: AppTheme.blueGradient,
                                    boxShadow: AppTheme.glowShadow,
                                  ),
                                  child: Center(
                                    child: Text(
                                      initials,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      '${_greeting()},',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.6),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      firstName,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        height: 1.1,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        _HeaderPill(
                          label: '${stats['totalPartners']} Partners',
                          color: AppTheme.primary,
                        ),
                        const SizedBox(width: 8),
                        _HeaderPill(
                          label: '${stats['activeMOUs']} MOUs',
                          color: AppTheme.secondary,
                        ),
                        const SizedBox(width: 8),
                        _HeaderPill(
                          label: '${stats['upcomingEvents']} Events',
                          color: AppTheme.warning,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAiBanner(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        context.go('/ai-assistant');
      },
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0D1B2A), Color(0xFF1A3A6B)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.secondary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.secondary.withOpacity(0.3)),
              ),
              child: const Icon(
                Icons.psychology_rounded,
                color: AppTheme.secondary,
                size: 26,
              ),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AI Assistant',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Draft emails, summarise calls, generate MOUs…',
                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.secondary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.arrow_forward_ios_rounded,
                color: AppTheme.secondary,
                size: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid(BuildContext context, Map<String, dynamic> stats) {
    final items = [
      _StatItem(
        'Total Partners',
        stats['totalPartners'].toString(),
        Icons.people_alt_rounded,
        AppTheme.blueGradient,
        '+${stats['newPartnersThisMonth']} this month',
        () => context.go('/crm'),
      ),
      _StatItem(
        'Active MOUs',
        stats['activeMOUs'].toString(),
        Icons.description_rounded,
        AppTheme.accentGradient,
        '${stats['mouExpiringIn30Days']} expiring',
        () => context.go('/mou'),
      ),
      _StatItem(
        'Emails Sent',
        stats['emailsSentThisMonth'].toString(),
        Icons.email_rounded,
        AppTheme.purpleGradient,
        'This month',
        () => context.go('/email'),
      ),
      _StatItem(
        'Upcoming Events',
        stats['upcomingEvents'].toString(),
        Icons.event_rounded,
        AppTheme.sunsetGradient,
        'Scheduled',
        () => context.go('/events'),
      ),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.55,
      children: items
          .asMap()
          .entries
          .map((e) => _StaggeredStatCard(item: e.value, index: e.key))
          .toList(),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final actions = [
      _ActionItem(
        Icons.edit_rounded,
        'Draft Email',
        AppTheme.blueGradient,
        () => context.go('/email/compose'),
      ),
      _ActionItem(
        Icons.call_rounded,
        'New Call',
        AppTheme.accentGradient,
        () => context.go('/calling'),
      ),
      _ActionItem(
        Icons.person_add_rounded,
        'Add Partner',
        AppTheme.purpleGradient,
        () => context.go('/crm/add'),
      ),
      _ActionItem(
        Icons.article_rounded,
        'Generate MOU',
        AppTheme.sunsetGradient,
        () => context.go('/mou/generate'),
      ),
      _ActionItem(
        Icons.event_rounded,
        'Add Event',
        const LinearGradient(colors: [Color(0xFF0891B2), Color(0xFF22D3EE)]),
        () => context.go('/events/add'),
      ),
      _ActionItem(
        Icons.campaign_rounded,
        'Campaign',
        const LinearGradient(colors: [Color(0xFF059669), Color(0xFF34D399)]),
        () => context.go('/marketing/create'),
      ),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: actions
            .asMap()
            .entries
            .map((e) => _QuickActionChip(item: e.value, index: e.key))
            .toList(),
      ),
    );
  }

  Widget _buildSectionRow(String title, String action, VoidCallback onTap) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimary,
          ),
        ),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.10),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              action,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning';
    if (h < 17) return 'Good Afternoon';
    return 'Good Evening';
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 14,
          decoration: BoxDecoration(
            gradient: AppTheme.blueGradient,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: AppTheme.textSecondary,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }
}

class _HeaderPill extends StatelessWidget {
  final String label;
  final Color color;
  const _HeaderPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _StatItem {
  final String label, value, subtitle;
  final IconData icon;
  final LinearGradient gradient;
  final VoidCallback onTap;
  const _StatItem(
    this.label,
    this.value,
    this.icon,
    this.gradient,
    this.subtitle,
    this.onTap,
  );
}

class _StaggeredStatCard extends StatefulWidget {
  final _StatItem item;
  final int index;
  const _StaggeredStatCard({required this.item, required this.index});

  @override
  State<_StaggeredStatCard> createState() => _StaggeredStatCardState();
}

class _StaggeredStatCardState extends State<_StaggeredStatCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

    Future.delayed(Duration(milliseconds: 80 * widget.index), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slide,
      child: FadeTransition(
        opacity: _fade,
        child: GestureDetector(
          onTapDown: (_) {
            HapticFeedback.lightImpact();
            setState(() => _pressed = true);
          },
          onTapUp: (_) {
            setState(() => _pressed = false);
            widget.item.onTap();
          },
          onTapCancel: () => setState(() => _pressed = false),
          child: AnimatedScale(
            scale: _pressed ? 0.95 : 1.0,
            duration: const Duration(milliseconds: 120),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: AppTheme.cardShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: widget.item.gradient,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          widget.item.icon,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          widget.item.subtitle,
                          style: const TextStyle(
                            fontSize: 9,
                            color: AppTheme.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    widget.item.value,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.textPrimary,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    widget.item.label,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionItem {
  final IconData icon;
  final String label;
  final LinearGradient gradient;
  final VoidCallback onTap;
  const _ActionItem(this.icon, this.label, this.gradient, this.onTap);
}

class _QuickActionChip extends StatefulWidget {
  final _ActionItem item;
  final int index;
  const _QuickActionChip({required this.item, required this.index});

  @override
  State<_QuickActionChip> createState() => _QuickActionChipState();
}

class _QuickActionChipState extends State<_QuickActionChip>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0.3, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    Future.delayed(Duration(milliseconds: 60 * widget.index), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slide,
      child: FadeTransition(
        opacity: _fade,
        child: GestureDetector(
          onTapDown: (_) {
            HapticFeedback.lightImpact();
            setState(() => _pressed = true);
          },
          onTapUp: (_) {
            setState(() => _pressed = false);
            widget.item.onTap();
          },
          onTapCancel: () => setState(() => _pressed = false),
          child: AnimatedScale(
            scale: _pressed ? 0.92 : 1.0,
            duration: const Duration(milliseconds: 100),
            child: Container(
              width: 78,
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: AppTheme.cardShadow,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: widget.item.gradient,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(
                      widget.item.icon,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.item.label,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AnimatedActivityItem extends StatefulWidget {
  final Map<String, dynamic> activity;
  final int index;
  const _AnimatedActivityItem({required this.activity, required this.index});

  @override
  State<_AnimatedActivityItem> createState() => _AnimatedActivityItemState();
}

class _AnimatedActivityItemState extends State<_AnimatedActivityItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(-0.1, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    Future.delayed(Duration(milliseconds: 60 * widget.index), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  IconData get _icon {
    switch (widget.activity['type']) {
      case 'email':
        return Icons.email_rounded;
      case 'call':
        return Icons.call_rounded;
      case 'mou':
        return Icons.article_rounded;
      case 'event':
        return Icons.event_rounded;
      case 'partner':
        return Icons.person_add_rounded;
      default:
        return Icons.circle_rounded;
    }
  }

  LinearGradient get _gradient {
    switch (widget.activity['type']) {
      case 'email':
        return AppTheme.blueGradient;
      case 'call':
        return AppTheme.accentGradient;
      case 'mou':
        return AppTheme.sunsetGradient;
      case 'event':
        return AppTheme.purpleGradient;
      case 'partner':
        return AppTheme.blueGradient;
      default:
        return AppTheme.blueGradient;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slide,
      child: FadeTransition(
        opacity: _fade,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: _gradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(_icon, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.activity['desc'] ?? '',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  widget.activity['time'] ?? '',
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnimatedPartnerItem extends StatefulWidget {
  final Map<String, dynamic> partner;
  final int index;
  final VoidCallback onTap;
  const _AnimatedPartnerItem({
    required this.partner,
    required this.index,
    required this.onTap,
  });

  @override
  State<_AnimatedPartnerItem> createState() => _AnimatedPartnerItemState();
}

class _AnimatedPartnerItemState extends State<_AnimatedPartnerItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0.1, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    Future.delayed(Duration(milliseconds: 70 * widget.index), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final score = (widget.partner['score'] as double);
    final pct = score / 100.0;

    return SlideTransition(
      position: _slide,
      child: FadeTransition(
        opacity: _fade,
        child: GestureDetector(
          onTapDown: (_) {
            HapticFeedback.lightImpact();
            setState(() => _pressed = true);
          },
          onTapUp: (_) {
            setState(() => _pressed = false);
            widget.onTap();
          },
          onTapCancel: () => setState(() => _pressed = false),
          child: AnimatedScale(
            scale: _pressed ? 0.97 : 1.0,
            duration: const Duration(milliseconds: 100),
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  PartnerAvatar(name: widget.partner['name'] ?? '', radius: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.partner['name'] ?? '',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          widget.partner['org'] ?? '',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: pct,
                            minHeight: 4,
                            backgroundColor: AppTheme.surface,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              pct > 0.7
                                  ? AppTheme.success
                                  : pct > 0.4
                                  ? AppTheme.primary
                                  : AppTheme.warning,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${score.toStringAsFixed(0)}%',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.primary,
                        ),
                      ),
                      const Text(
                        'engage',
                        style: TextStyle(
                          fontSize: 9,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
