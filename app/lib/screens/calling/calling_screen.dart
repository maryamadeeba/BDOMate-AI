import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../services/call_service.dart';
import '../../models/call_model.dart';
import '../../widgets/app_widgets.dart';

class CallingScreen extends StatefulWidget {
  const CallingScreen({super.key});
  @override
  State<CallingScreen> createState() => _CallingScreenState();
}

class _CallingScreenState extends State<CallingScreen> {
  bool _isCalling = false;

  @override
  Widget build(BuildContext context) {
    final callService = context.watch<CallService>();

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: GradientAppBar(
        title: 'Call Center',
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics_outlined, color: Colors.white),
            onPressed: () => context.go('/analytics'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Stats
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
                _Stat(
                  'Total',
                  callService.totalCalls.toString(),
                  Icons.call_rounded,
                  AppTheme.primary,
                ),
                _Stat(
                  'Missed',
                  callService.missedCalls.toString(),
                  Icons.call_missed_rounded,
                  AppTheme.error,
                ),
                _Stat(
                  'Duration',
                  _fmtTotal(callService.totalDuration),
                  Icons.timer_rounded,
                  AppTheme.accent,
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // New Call button
          Padding(
            padding: const EdgeInsets.all(12),
            child: ElevatedButton.icon(
              onPressed: _isCalling ? null : _showNewCallDialog,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                minimumSize: const Size(double.infinity, 50),
              ),
              icon: _isCalling
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.add_call, size: 20),
              label: Text(
                _isCalling ? 'Calling...' : 'New AI Call',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Recent Calls',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(height: 8),

          Expanded(
            child: callService.calls.isEmpty
                ? const EmptyState(
                    icon: Icons.call_outlined,
                    title: 'No Calls Yet',
                    subtitle: 'Tap "New AI Call" to call a partner',
                  )
                : RefreshIndicator(
                    onRefresh: () => callService.loadCallHistory(),
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: callService.calls.length,
                      itemBuilder: (_, i) => _CallCard(
                        call: callService.calls[i],
                        onTap: () => _showResultDialog(callService.calls[i]),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  String _fmtTotal(int secs) {
    final h = secs ~/ 3600;
    final m = (secs % 3600) ~/ 60;
    return '${h}h ${m}m';
  }

  // ── New Call Dialog ──────────────────────────────────────────
  void _showNewCallDialog() {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    String purpose = 'attendance';

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'New AI Call',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Contact Name',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone Number (+923001234567)',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: purpose,
                decoration: const InputDecoration(
                  labelText: 'Call Purpose',
                  prefixIcon: Icon(Icons.notes_outlined),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'attendance',
                    child: Text('Attendance Confirmation'),
                  ),
                  DropdownMenuItem(value: 'mou', child: Text('MOU Follow-up')),
                  DropdownMenuItem(
                    value: 'general',
                    child: Text('General Partnership'),
                  ),
                ],
                onChanged: (v) =>
                    setDialogState(() => purpose = v ?? 'general'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(dialogCtx).pop(); // close dialog using dialogCtx
                _makeCall(
                  name: nameCtrl.text.trim().isEmpty
                      ? 'Contact'
                      : nameCtrl.text.trim(),
                  phone: phoneCtrl.text.trim().isEmpty
                      ? '+923000000000'
                      : phoneCtrl.text.trim(),
                  purpose: purpose,
                );
              },
              icon: const Icon(Icons.call, size: 16),
              label: const Text('Start AI Call'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Make the call ────────────────────────────────────────────
  Future<void> _makeCall({
    required String name,
    required String phone,
    required String purpose,
  }) async {
    setState(() => _isCalling = true);

    try {
      final result = await context.read<CallService>().startCall(
        name,
        phone,
        purpose: purpose,
      );

      setState(() => _isCalling = false);

      // Show result in a dialog (not bottom sheet — avoids GoRouter blank screen bug)
      if (mounted) {
        final calls = context.read<CallService>().calls;
        if (calls.isNotEmpty) {
          _showResultDialog(calls.first, callData: result);
        }
      }
    } catch (e) {
      setState(() => _isCalling = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Call failed: $e'),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // ── Show call result — uses Dialog (fixes blank screen issue) ─
  void _showResultDialog(CallModel call, {Map<String, dynamic>? callData}) {
    final transcript = call.transcription ?? callData?['transcript'];
    final summary = call.summary ?? callData?['recipient_action'];
    final digitPressed = callData?['digit_pressed'];

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (resultCtx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: const EdgeInsets.all(16),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.80,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.05),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.call_rounded,
                        color: AppTheme.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            call.contactName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            call.contactPhone,
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Status badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle_rounded,
                            color: Colors.green,
                            size: 12,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'COMPLETED',
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.w700,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Duration
                      if (call.durationSeconds > 0)
                        Row(
                          children: [
                            const Icon(
                              Icons.timer_rounded,
                              size: 14,
                              color: AppTheme.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Duration: ${call.durationFormatted}',
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),

                      // Digit pressed
                      if (digitPressed != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Colors.blue.withOpacity(0.2),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.dialpad_rounded,
                                color: Colors.blue,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Recipient pressed: $digitPressed',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // Summary / Action
                      if (summary != null && summary.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        const Text(
                          'Result',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppTheme.primary.withOpacity(0.2),
                            ),
                          ),
                          child: Text(
                            summary,
                            style: const TextStyle(fontSize: 13, height: 1.5),
                          ),
                        ),
                      ],

                      // Transcript
                      if (transcript != null && transcript.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        const Text(
                          'Transcript',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: Text(
                            transcript,
                            style: const TextStyle(
                              fontSize: 12,
                              height: 1.7,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Close button — uses resultCtx, ONLY closes dialog
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: ElevatedButton(
                  onPressed: () => Navigator.of(resultCtx).pop(),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  child: const Text(
                    'Close',
                    style: TextStyle(fontWeight: FontWeight.w700),
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

// ── Reusable widgets ─────────────────────────────────────────

class _Stat extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _Stat(this.label, this.value, this.icon, this.color);
  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: color,
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

class _CallCard extends StatelessWidget {
  final CallModel call;
  final VoidCallback onTap;
  const _CallCard({required this.call, required this.onTap});

  IconData get _icon {
    switch (call.type) {
      case CallType.outgoing:
        return Icons.call_made_rounded;
      case CallType.incoming:
        return Icons.call_received_rounded;
      case CallType.missed:
        return Icons.call_missed_rounded;
    }
  }

  Color get _color {
    switch (call.type) {
      case CallType.outgoing:
        return AppTheme.secondary;
      case CallType.incoming:
        return AppTheme.success;
      case CallType.missed:
        return AppTheme.error;
    }
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_icon, color: _color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  call.contactName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  call.contactPhone,
                  style: const TextStyle(
                    fontSize: 12,
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
                DateFormat('MMM d').format(call.callTime),
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
              if (call.durationSeconds > 0) ...[
                const SizedBox(height: 4),
                Text(
                  call.durationFormatted,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
              if (call.isAiSummarized) ...[
                const SizedBox(height: 4),
                const AiBadge(),
              ],
            ],
          ),
        ],
      ),
    ),
  );
}
