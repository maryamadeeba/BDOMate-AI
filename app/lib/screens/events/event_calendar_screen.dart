import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../services/event_service.dart';
import '../../models/event_model.dart';
import '../../widgets/app_widgets.dart';

// ─── Main Calendar Screen ────────────────────────────────────────────────────

class EventCalendarScreen extends StatefulWidget {
  const EventCalendarScreen({super.key});

  @override
  State<EventCalendarScreen> createState() => _EventCalendarScreenState();
}

class _EventCalendarScreenState extends State<EventCalendarScreen>
    with SingleTickerProviderStateMixin {
  DateTime _focusedMonth = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  late AnimationController _slideCtrl;
  late Animation<Offset> _slideAnim;
  int _lastMonthDir = 0; // -1 prev, 1 next

  static final DateTime _minDate = DateTime(2020, 1, 1);

  @override
  void initState() {
    super.initState();
    _slideCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
    _slideAnim = Tween<Offset>(
      begin: Offset.zero,
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _slideCtrl.dispose();
    super.dispose();
  }

  void _changeMonth(int delta) {
    setState(() {
      _lastMonthDir = delta;
      _slideAnim = Tween<Offset>(
        begin: Offset(delta.toDouble(), 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOut));
      final nm = DateTime(_focusedMonth.year, _focusedMonth.month + delta);
      if (nm.isBefore(_minDate) && delta < 0) return;
      _focusedMonth = nm;
    });
    _slideCtrl.forward(from: 0);
  }

  List<EventModel> _eventsForDay(List<EventModel> all, DateTime day) {
    return all.where((e) {
      final s = e.startDate;
      return s.year == day.year && s.month == day.month && s.day == day.day;
    }).toList();
  }

  bool _hasEvents(List<EventModel> all, DateTime day) =>
      _eventsForDay(all, day).isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final service = context.watch<EventService>();
    final events = service.events;
    final selectedEvents = _eventsForDay(events, _selectedDay);

    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: Column(
        children: [
          _CalendarHeader(
            focusedMonth: _focusedMonth,
            onPrev: () => _changeMonth(-1),
            onNext: () => _changeMonth(1),
            canGoPrev: DateTime(
              _focusedMonth.year,
              _focusedMonth.month - 1,
            ).isAfter(_minDate.subtract(const Duration(days: 1))),
          ),
          SlideTransition(
            position: _slideAnim,
            child: _CalendarGrid(
              focusedMonth: _focusedMonth,
              selectedDay: _selectedDay,
              allEvents: events,
              hasEvents: (d) => _hasEvents(events, d),
              onDayTap: (d) => setState(() => _selectedDay = d),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _DayDetailPanel(
              selectedDay: _selectedDay,
              events: selectedEvents,
              onAddEvent: () => context.go(
                '/events/add',
                extra: {'prefillDate': _selectedDay.toIso8601String()},
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go(
          '/events/add',
          extra: {'prefillDate': _selectedDay.toIso8601String()},
        ),
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'Add Event',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

// ─── Calendar Header ─────────────────────────────────────────────────────────

class _CalendarHeader extends StatelessWidget {
  final DateTime focusedMonth;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final bool canGoPrev;

  const _CalendarHeader({
    required this.focusedMonth,
    required this.onPrev,
    required this.onNext,
    required this.canGoPrev,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.gradientStart,
            Color(0xFF1A3A6E),
            AppTheme.gradientEnd,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 8, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.white,
                    ),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  Expanded(
                    child: Text(
                      DateFormat('MMMM yyyy').format(focusedMonth),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.chevron_left_rounded,
                      color: canGoPrev ? Colors.white : Colors.white30,
                      size: 28,
                    ),
                    onPressed: canGoPrev ? onPrev : null,
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.chevron_right_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                    onPressed: onNext,
                  ),
                ],
              ),
            ),
            // Day-of-week labels
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
              child: Row(
                children: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
                    .map(
                      (d) => Expanded(
                        child: Center(
                          child: Text(
                            d,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.white.withValues(alpha: 0.65),
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Calendar Grid ────────────────────────────────────────────────────────────

class _CalendarGrid extends StatelessWidget {
  final DateTime focusedMonth;
  final DateTime selectedDay;
  final List<EventModel> allEvents;
  final bool Function(DateTime) hasEvents;
  final ValueChanged<DateTime> onDayTap;

  const _CalendarGrid({
    required this.focusedMonth,
    required this.selectedDay,
    required this.allEvents,
    required this.hasEvents,
    required this.onDayTap,
  });

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(focusedMonth.year, focusedMonth.month, 1);
    final startWeekday = firstDay.weekday % 7; // 0=Sun
    final daysInMonth = DateTime(
      focusedMonth.year,
      focusedMonth.month + 1,
      0,
    ).day;
    final today = DateTime.now();

    final cells = <Widget>[];

    // Leading empty cells
    for (int i = 0; i < startWeekday; i++) {
      cells.add(const SizedBox());
    }

    for (int d = 1; d <= daysInMonth; d++) {
      final day = DateTime(focusedMonth.year, focusedMonth.month, d);
      final isSelected =
          day.year == selectedDay.year &&
          day.month == selectedDay.month &&
          day.day == selectedDay.day;
      final isToday =
          day.year == today.year &&
          day.month == today.month &&
          day.day == today.day;
      final eventCount = allEvents.where((e) {
        final s = e.startDate;
        return s.year == day.year && s.month == day.month && s.day == day.day;
      }).length;

      cells.add(
        _DayCell(
          day: day,
          isSelected: isSelected,
          isToday: isToday,
          eventCount: eventCount,
          onTap: () => onDayTap(day),
        ),
      );
    }

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
      child: GridView.count(
        crossAxisCount: 7,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 2,
        crossAxisSpacing: 2,
        childAspectRatio: 1.0,
        children: cells,
      ),
    );
  }
}

// ─── Day Cell ────────────────────────────────────────────────────────────────

class _DayCell extends StatelessWidget {
  final DateTime day;
  final bool isSelected;
  final bool isToday;
  final int eventCount;
  final VoidCallback onTap;

  const _DayCell({
    required this.day,
    required this.isSelected,
    required this.isToday,
    required this.eventCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color bg = Colors.transparent;
    Color textColor = AppTheme.textPrimary;

    if (isSelected) {
      bg = AppTheme.primary;
      textColor = Colors.white;
    } else if (isToday) {
      bg = AppTheme.primary.withValues(alpha: 0.12);
      textColor = AppTheme.primary;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
          border: isToday && !isSelected
              ? Border.all(color: AppTheme.primary, width: 1.5)
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${day.day}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: isToday || isSelected
                    ? FontWeight.w800
                    : FontWeight.w500,
                color: textColor,
              ),
            ),
            if (eventCount > 0) ...[
              const SizedBox(height: 2),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  eventCount.clamp(0, 3),
                  (i) => Container(
                    width: 5,
                    height: 5,
                    margin: const EdgeInsets.symmetric(horizontal: 1),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white : AppTheme.accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Day Detail Panel ─────────────────────────────────────────────────────────

class _DayDetailPanel extends StatelessWidget {
  final DateTime selectedDay;
  final List<EventModel> events;
  final VoidCallback onAddEvent;

  const _DayDetailPanel({
    required this.selectedDay,
    required this.events,
    required this.onAddEvent,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('EEEE, MMMM d');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
          child: Row(
            children: [
              Text(
                fmt.format(selectedDay),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const Spacer(),
              if (events.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${events.length} event${events.length > 1 ? 's' : ''}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primary,
                    ),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: events.isEmpty
              ? _EmptyDayView(onAdd: onAddEvent)
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                  itemCount: events.length,
                  itemBuilder: (_, i) => _CalendarEventTile(event: events[i]),
                ),
        ),
      ],
    );
  }
}

class _EmptyDayView extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyDayView({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.event_available_rounded,
            size: 48,
            color: AppTheme.textSecondary.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 10),
          const Text(
            'No events this day',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Tap + to schedule a new event',
            style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}

// ─── Calendar Event Tile ─────────────────────────────────────────────────────

class _CalendarEventTile extends StatelessWidget {
  final EventModel event;
  const _CalendarEventTile({required this.event});

  Color get _color {
    switch (event.type) {
      case EventType.conference:
        return AppTheme.secondary;
      case EventType.mou_signing:
        return AppTheme.warning;
      case EventType.webinar:
        return AppTheme.teal;
      case EventType.alumni_meet:
        return AppTheme.accent;
      case EventType.sponsor_meet:
        return AppTheme.rose;
      case EventType.seminar:
        return AppTheme.violet;
      case EventType.workshop:
        return const Color(0xFF00897B);
      case EventType.networking:
        return AppTheme.amber;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go('/events/${event.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border(left: BorderSide(color: _color, width: 4)),
          boxShadow: [
            BoxShadow(
              color: _color.withValues(alpha: 0.07),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: _color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      event.typeLabel.toUpperCase(),
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: _color,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (event.isVirtual)
                    const Icon(
                      Icons.videocam_rounded,
                      size: 16,
                      color: AppTheme.teal,
                    ),
                  const SizedBox(width: 4),
                  Icon(Icons.chevron_right_rounded, size: 18, color: _color),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                event.title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              if (event.description.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  event.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.access_time_rounded, size: 13, color: _color),
                  const SizedBox(width: 5),
                  Text(
                    '${DateFormat('h:mm a').format(event.startDate)} – ${DateFormat('h:mm a').format(event.endDate)}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(Icons.location_on_outlined, size: 13, color: _color),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      event.venue,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.person_outline_rounded, size: 13, color: _color),
                  const SizedBox(width: 4),
                  Text(
                    event.organizer,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.people_outline_rounded, size: 13, color: _color),
                  const SizedBox(width: 4),
                  Text(
                    'Expected: ${event.expectedAttendees}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  if (event.predictedAttendees != null) ...[
                    const SizedBox(width: 6),
                    const AiBadge(),
                    const SizedBox(width: 3),
                    Text(
                      '${event.predictedAttendees}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _color,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
