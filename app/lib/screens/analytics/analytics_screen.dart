import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../theme/app_theme.dart';
import '../../services/analytics_service.dart';
import '../../widgets/app_widgets.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final analytics = context.watch<AnalyticsService>();
    final stats = analytics.dashboardStats;

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: GradientAppBar(
        title: 'Analytics',
        actions: [
          IconButton(icon: const Icon(Icons.download_rounded, color: Colors.white), onPressed: () {}),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // KPI Cards
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.6,
            children: [
              StatCard(label: 'Total Partners', value: stats['totalPartners'].toString(), icon: Icons.people_rounded, color: AppTheme.primary, subtitle: '+${stats['newPartnersThisMonth']} this month'),
              StatCard(label: 'Active MOUs', value: stats['activeMOUs'].toString(), icon: Icons.description_rounded, color: AppTheme.secondary, subtitle: '${stats['mouExpiringIn30Days']} expiring soon'),
              StatCard(label: 'Campaign Reach', value: stats['campaignReach'].toString(), icon: Icons.campaign_rounded, color: AppTheme.accent),
              StatCard(label: 'Avg Engagement', value: '${stats['avgEngagementScore']}%', icon: Icons.trending_up_rounded, color: AppTheme.success),
            ],
          ),
          const SizedBox(height: 20),

          // Partner Growth Chart
          _ChartCard(
            title: 'Partner Growth',
            subtitle: 'Last 6 months',
            child: SizedBox(
              height: 180,
              child: LineChart(LineChartData(
                gridData: FlGridData(show: true, getDrawingHorizontalLine: (_) => FlLine(color: AppTheme.divider, strokeWidth: 1)),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 28, getTitlesWidget: (v, _) => Text(v.toInt().toString(), style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary)))),
                  bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, _) {
                    final data = analytics.monthlyPartnerGrowth;
                    if (v.toInt() >= 0 && v.toInt() < data.length) return Text(data[v.toInt()]['month'], style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary));
                    return const Text('');
                  })),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: analytics.monthlyPartnerGrowth.asMap().entries.map((e) => FlSpot(e.key.toDouble(), (e.value['count'] as int).toDouble())).toList(),
                    isCurved: true,
                    color: AppTheme.primary,
                    barWidth: 3,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(show: true, color: AppTheme.primary.withOpacity(0.1)),
                  ),
                ],
              )),
            ),
          ),
          const SizedBox(height: 14),

          // Partner Type Breakdown
          _ChartCard(
            title: 'Partner Types',
            subtitle: 'Distribution',
            child: SizedBox(
              height: 200,
              child: Row(children: [
                Expanded(
                  child: PieChart(PieChartData(
                    sections: analytics.partnerTypeBreakdown.map((d) => PieChartSectionData(
                      value: (d['count'] as int).toDouble(),
                      color: Color(d['color'] as int),
                      title: '${d['count']}',
                      radius: 70,
                      titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white),
                    )).toList(),
                    sectionsSpace: 3,
                    centerSpaceRadius: 30,
                  )),
                ),
                const SizedBox(width: 16),
                Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: analytics.partnerTypeBreakdown.map((d) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(children: [
                    Container(width: 12, height: 12, decoration: BoxDecoration(color: Color(d['color'] as int), borderRadius: BorderRadius.circular(3))),
                    const SizedBox(width: 8),
                    Text('${d['type']} (${d['count']})', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                  ]),
                )).toList()),
              ]),
            ),
          ),
          const SizedBox(height: 14),

          // Email Stats
          _ChartCard(
            title: 'Email Performance',
            subtitle: 'Sent vs Opened',
            child: SizedBox(
              height: 180,
              child: BarChart(BarChartData(
                barGroups: analytics.emailStats.asMap().entries.map((e) => BarChartGroupData(
                  x: e.key,
                  barRods: [
                    BarChartRodData(toY: (e.value['sent'] as int).toDouble(), color: AppTheme.primary, width: 10, borderRadius: BorderRadius.circular(4)),
                    BarChartRodData(toY: (e.value['opened'] as int).toDouble(), color: AppTheme.accent, width: 10, borderRadius: BorderRadius.circular(4)),
                  ],
                )).toList(),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, _) {
                    final d = analytics.emailStats;
                    if (v.toInt() >= 0 && v.toInt() < d.length) return Text(d[v.toInt()]['month'], style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary));
                    return const Text('');
                  })),
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 24, getTitlesWidget: (v, _) => Text(v.toInt().toString(), style: const TextStyle(fontSize: 9, color: AppTheme.textSecondary)))),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(show: true, getDrawingHorizontalLine: (_) => FlLine(color: AppTheme.divider, strokeWidth: 1)),
                borderData: FlBorderData(show: false),
              )),
            ),
          ),
          const SizedBox(height: 14),

          // Top Partners
          const SectionHeader(title: 'Top Partners by Engagement'),
          const SizedBox(height: 10),
          ...analytics.topPartners.asMap().entries.map((e) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
            child: Row(children: [
              Text('#${e.key + 1}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: e.key == 0 ? AppTheme.warning : AppTheme.textSecondary)),
              const SizedBox(width: 12),
              PartnerAvatar(name: e.value['name'], radius: 22),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(e.value['name'], style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                Text(e.value['org'], style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
              ])),
              Column(children: [
                Text('${(e.value['score'] as double).toStringAsFixed(0)}%', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.primary)),
                const Text('engagement', style: TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
              ]),
            ]),
          )),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;
  const _ChartCard({required this.title, required this.subtitle, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        Text(subtitle, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
        const SizedBox(height: 16),
        child,
      ]),
    );
  }
}
