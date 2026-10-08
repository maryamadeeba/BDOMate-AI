import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../services/call_service.dart';
import '../../models/call_model.dart';
import '../../widgets/app_widgets.dart';

class CallDetailScreen extends StatelessWidget {
  final String callId;
  const CallDetailScreen({super.key, required this.callId});

  @override
  Widget build(BuildContext context) {
    final service = context.watch<CallService>();
    final call = service.getById(callId);
    if (call == null) return Scaffold(appBar: AppBar(title: const Text('Not Found')), body: const EmptyState(icon: Icons.call_outlined, title: 'Call not found', subtitle: ''));

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: GradientAppBar(
        title: 'Call Details',
        showBack: true,
        actions: [
          IconButton(icon: const Icon(Icons.call_rounded, color: Colors.white), onPressed: () {
            service.startCall(call.contactName, call.contactPhone, contactId: call.contactId);
            context.go('/calling/active');
          }),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(gradient: AppTheme.primaryGradient, borderRadius: BorderRadius.circular(16)),
            child: Row(children: [
              PartnerAvatar(name: call.contactName, radius: 32),
              const SizedBox(width: 16),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(call.contactName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
                Text(call.contactPhone, style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.8))),
                const SizedBox(height: 8),
                Row(children: [
                  _CallInfoChip(icon: _typeIcon(call.type), label: call.type.name.toUpperCase(), color: _typeColor(call.type)),
                  const SizedBox(width: 8),
                  _CallInfoChip(icon: Icons.timer_rounded, label: call.durationFormatted, color: Colors.white),
                ]),
              ])),
            ]),
          ),
          const SizedBox(height: 12),

          // Date/time
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
            child: Row(children: [
              const Icon(Icons.access_time_rounded, color: AppTheme.textSecondary, size: 20),
              const SizedBox(width: 10),
              Text(DateFormat('EEEE, MMMM d, yyyy – h:mm a').format(call.callTime), style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary)),
            ]),
          ),
          const SizedBox(height: 12),

          // AI Summary
          if (call.isAiSummarized && call.summary != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppTheme.accent.withOpacity(0.3))),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Row(children: [AiBadge(), SizedBox(width: 8), Text('AI Summary', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 10),
                Text(call.summary!, style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary, height: 1.5)),
              ]),
            ),

          if (call.keyPoints.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Key Points', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                ...call.keyPoints.map((kp) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Icon(Icons.check_circle_rounded, color: AppTheme.success, size: 18),
                    const SizedBox(width: 10),
                    Expanded(child: Text(kp, style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary))),
                  ]),
                )),
              ]),
            ),
          ],

          if (call.transcription != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Transcript', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                Text(call.transcription!, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary, height: 1.7, fontFamily: 'monospace')),
              ]),
            ),
          ],

          if (!call.isAiSummarized && call.status == CallStatus.completed) ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => service.transcribeCall(callId),
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accent, padding: const EdgeInsets.symmetric(vertical: 14)),
              icon: service.isTranscribing ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.psychology_rounded),
              label: Text(service.isTranscribing ? 'Transcribing...' : 'Generate AI Summary'),
            ),
          ],

          const SizedBox(height: 20),
          Row(children: [
            Expanded(child: OutlinedButton.icon(icon: const Icon(Icons.call_rounded), label: const Text('Call Again'), onPressed: () {
              service.startCall(call.contactName, call.contactPhone, contactId: call.contactId);
              context.go('/calling/active');
            })),
            const SizedBox(width: 12),
            Expanded(child: ElevatedButton.icon(icon: const Icon(Icons.email_rounded), label: const Text('Send Email'), onPressed: () => context.go('/email/compose'))),
          ]),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  IconData _typeIcon(CallType t) {
    switch (t) {
      case CallType.outgoing: return Icons.call_made_rounded;
      case CallType.incoming: return Icons.call_received_rounded;
      case CallType.missed: return Icons.call_missed_rounded;
    }
  }

  Color _typeColor(CallType t) {
    switch (t) {
      case CallType.outgoing: return Colors.white;
      case CallType.incoming: return AppTheme.success;
      case CallType.missed: return AppTheme.error;
    }
  }
}

class _CallInfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _CallInfoChip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}
