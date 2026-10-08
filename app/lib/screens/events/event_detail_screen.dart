import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../services/event_service.dart';
import '../../models/event_model.dart';
import '../../widgets/app_widgets.dart';

class EventDetailScreen extends StatelessWidget {
  final String eventId;
  const EventDetailScreen({super.key, required this.eventId});

  // ── Edit bottom sheet ────────────────────────────────────────────────────────
  void _openEditSheet(
    BuildContext context,
    EventModel event,
    EventService service,
  ) {
    final titleCtrl = TextEditingController(text: event.title);
    final descCtrl = TextEditingController(text: event.description);
    final venueCtrl = TextEditingController(
      text: event.venue == 'TBD' ? '' : event.venue,
    );
    final organizerCtrl = TextEditingController(text: event.organizer);
    final attendeesCtrl = TextEditingController(
      text: event.expectedAttendees == 0
          ? ''
          : event.expectedAttendees.toString(),
    );
    final meetingLinkCtrl = TextEditingController(
      text: event.meetingLink ?? '',
    );
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      // ✅ useSafeArea ensures it doesn't go under system bars
      useSafeArea: false,
      builder: (ctx) => DraggableScrollableSheet(
        // ✅ starts at 90% of screen height so Save is always visible
        initialChildSize: 1.0,
        minChildSize: 0.6,
        maxChildSize: 1.0,
        expand: false,
        builder: (ctx, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Form(
            key: formKey,
            child: Column(
              children: [
                // ── Handle + title (fixed at top) ──────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                  child: Column(
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppTheme.divider,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Edit Event',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Divider(),
                    ],
                  ),
                ),

                // ── Scrollable fields ───────────────────────────────────────
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                    children: [
                      TextFormField(
                        controller: titleCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Event Title *',
                          prefixIcon: Icon(Icons.event_rounded),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Title is required'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: descCtrl,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          prefixIcon: Icon(Icons.description_outlined),
                          alignLabelWithHint: true,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: organizerCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Organizer',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: attendeesCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Expected Attendees',
                          prefixIcon: Icon(Icons.people_outline),
                        ),
                        validator: (v) {
                          if (v != null &&
                              v.isNotEmpty &&
                              int.tryParse(v) == null) {
                            return 'Enter a valid number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      if (event.isVirtual)
                        TextFormField(
                          controller: meetingLinkCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Meeting Link',
                            prefixIcon: Icon(Icons.link_rounded),
                          ),
                        )
                      else
                        TextFormField(
                          controller: venueCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Venue / Location *',
                            prefixIcon: Icon(Icons.location_on_outlined),
                          ),
                          validator: (v) =>
                              !event.isVirtual &&
                                  (v == null || v.trim().isEmpty)
                              ? 'Venue is required'
                              : null,
                        ),
                    ],
                  ),
                ),

                // ── Save button (always visible, pinned at bottom) ──────────
                Container(
                  padding: EdgeInsets.fromLTRB(
                    20,
                    12,
                    20,
                    // ✅ adds extra padding above system nav bar
                    12 +
                        MediaQuery.of(ctx).viewInsets.bottom +
                        MediaQuery.of(ctx).padding.bottom,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(top: BorderSide(color: AppTheme.divider)),
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (!formKey.currentState!.validate()) return;
                        final updated = EventModel(
                          id: event.id,
                          title: titleCtrl.text.trim(),
                          description: descCtrl.text.trim(),
                          type: event.type,
                          status: event.status,
                          startDate: event.startDate,
                          endDate: event.endDate,
                          venue: event.isVirtual
                              ? event.venue
                              : (venueCtrl.text.trim().isEmpty
                                    ? 'TBD'
                                    : venueCtrl.text.trim()),
                          expectedAttendees:
                              int.tryParse(attendeesCtrl.text) ??
                              event.expectedAttendees,
                          organizer: organizerCtrl.text.trim().isEmpty
                              ? event.organizer
                              : organizerCtrl.text.trim(),
                          isVirtual: event.isVirtual,
                          meetingLink: event.isVirtual
                              ? meetingLinkCtrl.text.trim()
                              : event.meetingLink,
                          predictedAttendees: event.predictedAttendees,
                          actualAttendees: event.actualAttendees,
                          invitedPartnerIds: event.invitedPartnerIds,
                          confirmedPartnerIds: event.confirmedPartnerIds,
                        );
                        service.updateEvent(updated);
                        Navigator.of(ctx).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Event updated successfully'),
                            backgroundColor: AppTheme.success,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text(
                        'Save Changes',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<EventService>();
    final event = service.getById(eventId);
    if (event == null)
      return const Scaffold(
        body: EmptyState(
          icon: Icons.event_outlined,
          title: 'Event not found',
          subtitle: '',
        ),
      );

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: GradientAppBar(
        title: 'Event Details',
        showBack: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded, color: Colors.white),
            onPressed: () => _openEditSheet(context, event, service),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
            onSelected: (v) {
              if (v == 'delete') {
                service.deleteEvent(event.id);
                context.go('/events');
              }
              if (v == 'predict') {
                service.predictAttendance(eventId);
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'invite', child: Text('Send Invites')),
              const PopupMenuItem(
                value: 'predict',
                child: Text('Predict Attendance'),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Text('Delete', style: TextStyle(color: Colors.red)),
              ),
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
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StatusBadge(
                  label: event.typeLabel,
                  color: Colors.white,
                  bgColor: Colors.white.withValues(alpha: 0.2),
                ),
                const SizedBox(height: 12),
                Text(
                  event.title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  event.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.8),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Date / Venue
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                InfoRow(
                  icon: Icons.calendar_today_rounded,
                  label: 'Start Date',
                  value: DateFormat(
                    'EEE, MMM d, yyyy – h:mm a',
                  ).format(event.startDate),
                  iconColor: AppTheme.primary,
                ),
                const Divider(height: 16),
                InfoRow(
                  icon: Icons.event_available_rounded,
                  label: 'End Date',
                  value: DateFormat(
                    'EEE, MMM d, yyyy – h:mm a',
                  ).format(event.endDate),
                  iconColor: AppTheme.secondary,
                ),
                const Divider(height: 16),
                InfoRow(
                  icon: Icons.location_on_rounded,
                  label: 'Venue',
                  value: event.venue,
                  iconColor: AppTheme.warning,
                ),
                if (event.meetingLink != null) ...[
                  const Divider(height: 16),
                  InfoRow(
                    icon: Icons.link_rounded,
                    label: 'Meeting Link',
                    value: event.meetingLink!,
                    iconColor: AppTheme.accent,
                  ),
                ],
                const Divider(height: 16),
                InfoRow(
                  icon: Icons.person_rounded,
                  label: 'Organizer',
                  value: event.organizer,
                  iconColor: AppTheme.primary,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Attendance
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Attendance',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _AttendanceCard(
                        label: 'Expected',
                        value: event.expectedAttendees.toString(),
                        color: AppTheme.primary,
                        icon: Icons.people_outline_rounded,
                      ),
                    ),
                    const SizedBox(width: 10),
                    if (event.predictedAttendees != null)
                      Expanded(
                        child: _AttendanceCard(
                          label: 'AI Predicted',
                          value: event.predictedAttendees.toString(),
                          color: AppTheme.accent,
                          icon: Icons.psychology_rounded,
                          isAi: true,
                        ),
                      ),
                    if (event.actualAttendees != null) ...[
                      const SizedBox(width: 10),
                      Expanded(
                        child: _AttendanceCard(
                          label: 'Actual',
                          value: event.actualAttendees.toString(),
                          color: AppTheme.success,
                          icon: Icons.how_to_reg_rounded,
                        ),
                      ),
                    ],
                  ],
                ),
                if (event.predictedAttendees != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Confirmation Rate: ${((event.confirmedPartnerIds.length / (event.invitedPartnerIds.isEmpty ? 1 : event.invitedPartnerIds.length)) * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: event.invitedPartnerIds.isEmpty
                        ? 0
                        : event.confirmedPartnerIds.length /
                              event.invitedPartnerIds.length,
                    backgroundColor: AppTheme.divider,
                    color: AppTheme.success,
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: service.isPredicting
                        ? null
                        : () => service.predictAttendance(eventId),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accent,
                    ),
                    icon: service.isPredicting
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
                      service.isPredicting
                          ? 'Predicting...'
                          : 'Predict Attendance with AI',
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Partners
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Partners',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '${event.confirmedPartnerIds.length}/${event.invitedPartnerIds.length} confirmed',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.success,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (event.invitedPartnerIds.isEmpty)
                  const Text(
                    'No partners invited yet',
                    style: TextStyle(color: AppTheme.textSecondary),
                  )
                else
                  Text(
                    '${event.invitedPartnerIds.length} partners invited',
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 14,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.email_rounded),
                  label: const Text('Send Invites'),
                  onPressed: () => context.go('/email/compose'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.share_rounded),
                  label: const Text('Share'),
                  onPressed: () {},
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _AttendanceCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  final bool isAi;

  const _AttendanceCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
    this.isAi = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 18),
              if (isAi) ...[const SizedBox(width: 4), const AiBadge()],
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
