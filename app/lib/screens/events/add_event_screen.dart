import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../services/event_service.dart';
import '../../models/event_model.dart';
import '../../widgets/app_widgets.dart';

class AddEventScreen extends StatefulWidget {
  /// Optional pre-filled date from calendar tap (ISO 8601 string)
  final String? prefillDateIso;

  const AddEventScreen({super.key, this.prefillDateIso});

  @override
  State<AddEventScreen> createState() => _AddEventScreenState();
}

class _AddEventScreenState extends State<AddEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _venueCtrl = TextEditingController();
  final _organizerCtrl = TextEditingController(text: ' ');
  final _attendeesCtrl = TextEditingController();
  final _meetingLinkCtrl = TextEditingController();

  EventType _type = EventType.seminar;
  late DateTime _startDate;
  late DateTime _endDate;
  bool _isVirtual = false;

  // Calendar mini-picker state
  bool _showCalendarPicker = false;
  DateTime _calPickerFocusedMonth = DateTime.now();

  // AI recommendations state
  List<ScheduleRecommendation> _recommendations = [];
  bool _loadingRecs = false;

  static final DateTime _minDate = DateTime(2020, 1, 1);

  @override
  void initState() {
    super.initState();
    final prefill = widget.prefillDateIso != null
        ? DateTime.tryParse(widget.prefillDateIso!)
        : null;
    final base = prefill ?? DateTime.now().add(const Duration(days: 7));
    _startDate = DateTime(base.year, base.month, base.day, 9, 0);
    _endDate = _startDate.add(const Duration(hours: 2));
    _calPickerFocusedMonth = _startDate;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _venueCtrl.dispose();
    _organizerCtrl.dispose();
    _attendeesCtrl.dispose();
    _meetingLinkCtrl.dispose();
    super.dispose();
  }

  // ── AI Recommendations ──────────────────────────────────────────────────────

  Future<void> _fetchRecommendations() async {
    if (_titleCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter an event title first to get recommendations.'),
        ),
      );
      return;
    }
    setState(() => _loadingRecs = true);

    final service = context.read<EventService>();
    try {
      final recs = await service.getSchedulingRecommendations(
        eventType: _type,
        expectedAttendees: int.tryParse(_attendeesCtrl.text) ?? 100,
        isVirtual: _isVirtual,
        referenceDate: _startDate,
      );
      setState(() {
        _recommendations = recs;
        _loadingRecs = false;
      });
    } catch (_) {
      setState(() {
        _recommendations = _localRecommendations();
        _loadingRecs = false;
      });
    }
  }

  List<ScheduleRecommendation> _localRecommendations() {
    // Local fallback: suggest Tue/Wed/Thu mornings
    final now = DateTime.now();
    final results = <ScheduleRecommendation>[];
    int added = 0;
    for (int i = 1; i <= 30 && added < 3; i++) {
      final d = now.add(Duration(days: i));
      if (d.weekday >= DateTime.tuesday && d.weekday <= DateTime.thursday) {
        results.add(
          ScheduleRecommendation(
            date: DateTime(d.year, d.month, d.day, 10, 0),
            reason:
                'Mid-week mornings (Tue–Thu) have historically high attendance.',
            score: 90 - (added * 5),
          ),
        );
        added++;
      }
    }
    return results;
  }

  void _applyRecommendation(ScheduleRecommendation rec) {
    setState(() {
      _startDate = rec.date;
      _endDate = rec.date.add(const Duration(hours: 2));
      _calPickerFocusedMonth = _startDate;
    });
  }

  // ── Calendar mini-picker ─────────────────────────────────────────────────────

  Widget _buildCalendarPicker() {
    final service = context.read<EventService>();
    final firstDay = DateTime(
      _calPickerFocusedMonth.year,
      _calPickerFocusedMonth.month,
      1,
    );
    final startWeekday = firstDay.weekday % 7;
    final daysInMonth = DateTime(
      _calPickerFocusedMonth.year,
      _calPickerFocusedMonth.month + 1,
      0,
    ).day;
    final today = DateTime.now();

    // Pre-compute days that have at least one event booked (for red dot indicator)
    final bookedDays = <String>{};
    for (final e in service.events) {
      bookedDays.add(
        '${e.startDate.year}-${e.startDate.month}-${e.startDate.day}',
      );
    }

    final cells = <Widget>[];
    for (int i = 0; i < startWeekday; i++) {
      cells.add(const SizedBox());
    }
    for (int d = 1; d <= daysInMonth; d++) {
      final day = DateTime(
        _calPickerFocusedMonth.year,
        _calPickerFocusedMonth.month,
        d,
      );
      final isPast = day.isBefore(DateTime(today.year, today.month, today.day));
      final isSelected =
          day.year == _startDate.year &&
          day.month == _startDate.month &&
          day.day == _startDate.day;
      final isToday =
          day.year == today.year &&
          day.month == today.month &&
          day.day == today.day;
      final hasBooking = bookedDays.contains(
        '${day.year}-${day.month}-${day.day}',
      );

      cells.add(
        GestureDetector(
          onTap: isPast
              ? null
              : () {
                  setState(() {
                    _startDate = DateTime(
                      day.year,
                      day.month,
                      day.day,
                      _startDate.hour,
                      _startDate.minute,
                    );
                    if (_endDate.isBefore(_startDate)) {
                      _endDate = _startDate.add(const Duration(hours: 2));
                    }
                  });
                },
          child: Container(
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppTheme.primary
                  : isToday
                  ? AppTheme.primary.withValues(alpha: 0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: isToday && !isSelected
                  ? Border.all(color: AppTheme.primary, width: 1.5)
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$d',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected || isToday
                        ? FontWeight.w800
                        : FontWeight.w500,
                    color: isSelected
                        ? Colors.white
                        : isPast
                        ? AppTheme.textSecondary.withValues(alpha: 0.35)
                        : AppTheme.textPrimary,
                  ),
                ),
                // Booking indicator dot
                if (hasBooking) ...[
                  const SizedBox(height: 2),
                  Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.white
                          : AppTheme.error.withValues(alpha: 0.7),
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    final canGoPrev = DateTime(
      _calPickerFocusedMonth.year,
      _calPickerFocusedMonth.month - 1,
    ).isAfter(_minDate.subtract(const Duration(days: 1)));

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.divider),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          // Month nav
          Row(
            children: [
              IconButton(
                icon: Icon(
                  Icons.chevron_left_rounded,
                  color: canGoPrev ? AppTheme.primary : AppTheme.divider,
                ),
                onPressed: canGoPrev
                    ? () => setState(() {
                        _calPickerFocusedMonth = DateTime(
                          _calPickerFocusedMonth.year,
                          _calPickerFocusedMonth.month - 1,
                        );
                      })
                    : null,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              Expanded(
                child: Text(
                  DateFormat('MMMM yyyy').format(_calPickerFocusedMonth),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.chevron_right_rounded,
                  color: AppTheme.primary,
                ),
                onPressed: () => setState(() {
                  _calPickerFocusedMonth = DateTime(
                    _calPickerFocusedMonth.year,
                    _calPickerFocusedMonth.month + 1,
                  );
                }),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Day labels
          Row(
            children: ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa']
                .map(
                  (d) => Expanded(
                    child: Center(
                      child: Text(
                        d,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 4),
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.1,
            children: cells,
          ),
          const Divider(height: 20),
          // Time pickers
          Row(
            children: [
              Expanded(
                child: _buildTimeTile(
                  label: 'Start Time',
                  dt: _startDate,
                  onPick: (t) {
                    if (t != null) {
                      setState(() {
                        _startDate = DateTime(
                          _startDate.year,
                          _startDate.month,
                          _startDate.day,
                          t.hour,
                          t.minute,
                        );
                        if (_endDate.isBefore(_startDate)) {
                          _endDate = _startDate.add(const Duration(hours: 2));
                        }
                      });
                    }
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildTimeTile(
                  label: 'End Time',
                  dt: _endDate,
                  onPick: (t) {
                    if (t != null) {
                      setState(() {
                        final nd = DateTime(
                          _endDate.year,
                          _endDate.month,
                          _endDate.day,
                          t.hour,
                          t.minute,
                        );
                        if (nd.isAfter(_startDate)) _endDate = nd;
                      });
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeTile({
    required String label,
    required DateTime dt,
    required ValueChanged<TimeOfDay?> onPick,
  }) {
    return GestureDetector(
      onTap: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.fromDateTime(dt),
        );
        onPick(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 3),
            Row(
              children: [
                const Icon(
                  Icons.access_time_rounded,
                  size: 14,
                  color: AppTheme.primary,
                ),
                const SizedBox(width: 5),
                Text(
                  DateFormat('h:mm a').format(dt),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Date/Time summary row (collapsed state) ──────────────────────────────────

  Widget _buildDateSummaryRow() {
    return GestureDetector(
      onTap: () => setState(() => _showCalendarPicker = !_showCalendarPicker),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _showCalendarPicker ? AppTheme.primary : AppTheme.divider,
            width: _showCalendarPicker ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_month_rounded,
              color: _showCalendarPicker
                  ? AppTheme.primary
                  : AppTheme.textSecondary,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat('EEE, MMM d, yyyy').format(_startDate),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${DateFormat('h:mm a').format(_startDate)} – ${DateFormat('h:mm a').format(_endDate)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              _showCalendarPicker
                  ? Icons.keyboard_arrow_up_rounded
                  : Icons.keyboard_arrow_down_rounded,
              color: AppTheme.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  // ── Save ────────────────────────────────────────────────────────────────────

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    // ── Clash detection ──────────────────────────────────────────────────────
    // Reject the save if another event already occupies this time slot.
    final service = context.read<EventService>();
    final clash = service.findClash(_startDate, _endDate);
    if (clash != null && mounted) {
      final fmt = DateFormat('h:mm a');
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: AppTheme.warning),
              SizedBox(width: 8),
              Text(
                'Time Slot Taken',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'This slot overlaps with an existing event:',
                style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.warning.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppTheme.warning.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      clash.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${fmt.format(clash.startDate)} – ${fmt.format(clash.endDate)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Please choose a different start or end time.',
                style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Change Time',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      );
      return; // Do not save
    }

    final event = EventModel(
      id: const Uuid().v4(),
      title: _titleCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      type: _type,
      startDate: _startDate,
      endDate: _endDate,
      venue: _isVirtual
          ? (_meetingLinkCtrl.text.isEmpty ? 'Online' : _meetingLinkCtrl.text)
          : _venueCtrl.text.trim(),
      expectedAttendees: int.tryParse(_attendeesCtrl.text) ?? 0,
      organizer: _organizerCtrl.text.trim(),
      isVirtual: _isVirtual,
      meetingLink: _isVirtual && _meetingLinkCtrl.text.isNotEmpty
          ? _meetingLinkCtrl.text
          : null,
    );

    await service.addEvent(event);
    // Persist to backend so data survives sign-out / restart
    service.persistEventToBackend(event);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Event added!'),
          backgroundColor: AppTheme.success,
        ),
      );
      context.go('/events');
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<EventService>();

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: GradientAppBar(
        title: 'Add Event',
        showBack: true,
        actions: [
          TextButton(
            onPressed: service.isLoading ? null : _save,
            child: const Text(
              'Save',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
          children: [
            // ── Event Type ──
            const Text(
              'Event Type',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: EventType.values.map((t) {
                final sel = _type == t;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _type = t;
                      _recommendations = [];
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: sel ? AppTheme.primary : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: sel ? AppTheme.primary : AppTheme.divider,
                      ),
                    ),
                    child: Text(
                      t.name.replaceAll('_', ' ').toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: sel ? Colors.white : AppTheme.textSecondary,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // ── Event Details ──
            _buildSection('Event Details', [
              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Event Title *',
                  prefixIcon: Icon(Icons.event_rounded),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Title is required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description *',
                  prefixIcon: Icon(Icons.description_outlined),
                  alignLabelWithHint: true,
                ),
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Description is required'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _organizerCtrl,
                decoration: const InputDecoration(
                  labelText: 'Organizer *',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _attendeesCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Expected Attendees',
                  prefixIcon: Icon(Icons.people_outline),
                ),
              ),
            ]),
            const SizedBox(height: 14),

            // ── Date & Time with calendar picker ──
            _buildSection('Date & Time', [
              _buildDateSummaryRow(),
              if (_showCalendarPicker) ...[
                const SizedBox(height: 12),
                _buildCalendarPicker(),
              ],
            ]),
            const SizedBox(height: 14),

            // ── AI Scheduling Recommendations ──
            _buildSection('AI Scheduling Recommendations', [
              const Text(
                'Get smart suggestions for the best date and time to schedule this event based on past attendance patterns.',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _loadingRecs ? null : _fetchRecommendations,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accent,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                  icon: _loadingRecs
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.psychology_rounded),
                  label: Text(
                    _loadingRecs
                        ? 'Analyzing patterns...'
                        : 'Get AI Recommendations',
                  ),
                ),
              ),
              if (_recommendations.isNotEmpty) ...[
                const SizedBox(height: 14),
                ..._recommendations.asMap().entries.map((entry) {
                  final i = entry.key;
                  final rec = entry.value;
                  return _RecommendationTile(
                    rec: rec,
                    rank: i + 1,
                    onApply: () => _applyRecommendation(rec),
                  );
                }),
              ],
            ]),
            const SizedBox(height: 14),

            // ── Venue ──
            _buildSection('Venue', [
              Row(
                children: [
                  const Text(
                    'Virtual Event?',
                    style: TextStyle(fontSize: 14, color: AppTheme.textPrimary),
                  ),
                  const Spacer(),
                  Switch(
                    value: _isVirtual,
                    onChanged: (v) => setState(() => _isVirtual = v),
                    activeColor: AppTheme.primary,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (_isVirtual)
                TextFormField(
                  controller: _meetingLinkCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Meeting Link (Zoom/Teams/etc)',
                    prefixIcon: Icon(Icons.link_rounded),
                  ),
                )
              else
                TextFormField(
                  controller: _venueCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Venue / Location *',
                    prefixIcon: Icon(Icons.location_on_outlined),
                  ),
                  validator: (v) =>
                      !_isVirtual && (v == null || v.trim().isEmpty)
                      ? 'Venue is required'
                      : null,
                ),
            ]),
            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: service.isLoading ? null : _save,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: service.isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Save Event',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
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
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}

// ─── Recommendation Tile ─────────────────────────────────────────────────────

class _RecommendationTile extends StatelessWidget {
  final ScheduleRecommendation rec;
  final int rank;
  final VoidCallback onApply;

  const _RecommendationTile({
    required this.rec,
    required this.rank,
    required this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    final color = rank == 1
        ? AppTheme.success
        : rank == 2
        ? AppTheme.primary
        : AppTheme.textSecondary;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '#$rank',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        DateFormat('EEE, MMM d, yyyy').format(rec.date),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${rec.score}% score',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: color,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    DateFormat('h:mm a').format(rec.date),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    rec.reason,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: onApply,
              style: TextButton.styleFrom(
                foregroundColor: color,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'Apply',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
