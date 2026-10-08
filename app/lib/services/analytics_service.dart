import 'package:flutter/material.dart';
import 'crm_service.dart';
import 'email_service.dart';
import 'mou_service.dart';
import 'event_service.dart';
import '../models/email_model.dart';

class AnalyticsService extends ChangeNotifier {
  final CrmService _crm;
  final EmailService _email;
  final MouService _mou;
  final EventService _event;

  AnalyticsService(this._crm, this._email, this._mou, this._event) {
    // FIX: use addPostFrameCallback so listeners are never attached
    // during a widget build — avoids "setState() called during build"
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _crm.addListener(_onChange);
      _email.addListener(_onChange);
      _mou.addListener(_onChange);
      _event.addListener(_onChange);
    });
  }

  // FIX: schedule notifyListeners for after the current frame,
  // never inline during a build pass
  void _onChange() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  // Called by dashboard_screen.dart — just triggers a refresh
  Future<void> loadDashboardStats([String? token]) async {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _crm.removeListener(_onChange);
    _email.removeListener(_onChange);
    _mou.removeListener(_onChange);
    _event.removeListener(_onChange);
    super.dispose();
  }

  // ── Live dashboard stats ─────────────────────────────────────
  Map<String, dynamic> get dashboardStats {
    final now = DateTime.now();

    final emailsSentThisMonth = _email.emails.where((e) =>
        e.status == EmailStatus.sent &&
        e.sentAt != null &&
        e.sentAt!.month == now.month &&
        e.sentAt!.year == now.year).length;

    final newPartnersThisMonth = _crm.partners.where((p) =>
        p.createdAt.month == now.month &&
        p.createdAt.year == now.year).length;

    final mouExpiringIn30Days = _mou.mous.where((m) =>
        m.daysUntilExpiry != null &&
        m.daysUntilExpiry! >= 0 &&
        m.daysUntilExpiry! < 30).length;

    return {
      'totalPartners':        _crm.totalCount,
      'activePartners':       _crm.activeCount,
      'totalMOUs':            _mou.mous.length,
      'activeMOUs':           _mou.active.length,
      'totalEmails':          _email.emails.length,
      'emailsSentThisMonth':  emailsSentThisMonth,
      'totalCalls':           0,
      'callsThisMonth':       0,
      'upcomingEvents':       _event.upcoming.length,
      'totalCampaigns':       0,
      'campaignReach':        0,
      'avgEngagementScore':   _avgEngagement(),
      'newPartnersThisMonth': newPartnersThisMonth,
      'mouExpiringIn30Days':  mouExpiringIn30Days,
    };
  }

  double _avgEngagement() {
    final all = _crm.partners;
    if (all.isEmpty) return 0.0;
    final total = all.fold<double>(0, (sum, p) => sum + p.engagementScore);
    return double.parse((total / all.length).toStringAsFixed(1));
  }

  // ── Chart data ───────────────────────────────────────────────

  List<Map<String, dynamic>> get monthlyPartnerGrowth {
    final now = DateTime.now();
    return List.generate(6, (i) {
      final month = DateTime(now.year, now.month - 5 + i);
      final count = _crm.partners.where((p) =>
          p.createdAt.isBefore(DateTime(month.year, month.month + 1))).length;
      return {'month': _monthLabel(month.month), 'count': count};
    });
  }

  List<Map<String, dynamic>> get emailStats {
    final now = DateTime.now();
    return List.generate(6, (i) {
      final month = DateTime(now.year, now.month - 5 + i);
      final sent = _email.emails.where((e) =>
          e.sentAt != null &&
          e.sentAt!.month == month.month &&
          e.sentAt!.year == month.year).length;
      return {
        'month':  _monthLabel(month.month),
        'sent':   sent,
        'opened': (sent * 0.75).round(),
      };
    });
  }

  List<Map<String, dynamic>> get partnerTypeBreakdown {
    final counts = _crm.typeCounts;
    const colors = {
      'industry':    0xFF1E3A5F,
      'alumni':      0xFF2E86AB,
      'sponsor':     0xFF00BFA6,
      'institution': 0xFFF4A261,
      'government':  0xFFE63946,
      'ngo':         0xFF8338EC,
    };
    return counts.entries
        .where((e) => e.value > 0)
        .map((e) => {
              'type':  e.key,
              'count': e.value,
              'color': colors[e.key] ?? 0xFF888888,
            })
        .toList();
  }

  List<Map<String, dynamic>> get topPartners {
    final sorted = List.of(_crm.partners)
      ..sort((a, b) => b.engagementScore.compareTo(a.engagementScore));
    return sorted.take(5).map((p) => {
      'name':  p.name,
      'org':   p.organization,
      'score': p.engagementScore,
    }).toList();
  }

  List<Map<String, dynamic>> get recentActivity {
    final List<Map<String, dynamic>> activity = [];
    final now = DateTime.now();
    for (final e in _email.sent.take(3)) {
      activity.add({
        'type': 'email',
        'desc': 'Email sent to ${e.toName} – ${e.subject}',
        'time': _timeAgo(e.sentAt ?? e.createdAt, now),
      });
    }
    for (final m in _mou.mous.take(2)) {
      activity.add({
        'type': 'mou',
        'desc': 'MOU – ${m.title}',
        'time': _timeAgo(m.createdAt, now),
      });
    }
    for (final p in _crm.partners.reversed.take(2)) {
      activity.add({
        'type': 'partner',
        'desc': '${p.name} (${p.organization}) added',
        'time': _timeAgo(p.createdAt, now),
      });
    }
    activity.sort((a, b) => a['time'].toString().compareTo(b['time'].toString()));
    return activity.take(6).toList();
  }

  String _monthLabel(int m) {
    const labels = ['Jan','Feb','Mar','Apr','May','Jun',
                    'Jul','Aug','Sep','Oct','Nov','Dec'];
    return labels[(m - 1) % 12];
  }

  String _timeAgo(DateTime dt, DateTime now) {
    final diff = now.difference(dt);
    if (diff.inMinutes < 60)  return '${diff.inMinutes}m ago';
    if (diff.inHours   < 24)  return '${diff.inHours}h ago';
    if (diff.inDays    < 30)  return '${diff.inDays}d ago';
    return '${(diff.inDays / 30).floor()}mo ago';
  }

  List<Map<String, dynamic>> get callStats => [];
  List<Map<String, dynamic>> get campaignPerformance => [];
}
