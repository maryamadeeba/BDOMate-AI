import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../theme/app_theme.dart';
import '../../services/email_service.dart';
import '../../models/email_model.dart';
import '../../widgets/app_widgets.dart';

class ComposeEmailScreen extends StatefulWidget {
  const ComposeEmailScreen({super.key});

  @override
  State<ComposeEmailScreen> createState() => _ComposeEmailScreenState();
}

class _ComposeEmailScreenState extends State<ComposeEmailScreen> {
  final _toCtrl = TextEditingController();
  final _toNameCtrl = TextEditingController();
  final _subjectCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  bool _showAiPanel = false;
  final _purposeCtrl = TextEditingController();
  String _tone = 'formal';
  EmailPriority _priority = EmailPriority.normal;

  @override
  void dispose() {
    _toCtrl.dispose(); _toNameCtrl.dispose();
    _subjectCtrl.dispose(); _bodyCtrl.dispose();
    _purposeCtrl.dispose();
    super.dispose();
  }

  Future<void> _aiGenerate() async {
    if (_toNameCtrl.text.isEmpty || _purposeCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill recipient name and purpose')));
      return;
    }
    final service = context.read<EmailService>();
    final body = await service.generateEmail(
      recipientName: _toNameCtrl.text,
      recipientOrg: '',
      purpose: _purposeCtrl.text,
      tone: _tone,
    );
    setState(() {
      _bodyCtrl.text = body;
      _showAiPanel = false;
    });
  }

  Future<void> _send() async {
    if (_toCtrl.text.isEmpty || _subjectCtrl.text.isEmpty || _bodyCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all required fields')));
      return;
    }
    final email = EmailModel(
      id: const Uuid().v4(),
      subject: _subjectCtrl.text,
      body: _bodyCtrl.text,
      toEmail: _toCtrl.text,
      toName: _toNameCtrl.text.isEmpty ? _toCtrl.text : _toNameCtrl.text,
      fromEmail: 'maryam@usa.edu.pk',
      fromName: 'Maryam Adeeba',
      priority: _priority,
      createdAt: DateTime.now(),
    );
    await context.read<EmailService>().sendEmail(email);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Email sent successfully!'), backgroundColor: AppTheme.success));
      context.go('/email');
    }
  }

  Future<void> _saveDraft() async {
    final email = EmailModel(
      id: const Uuid().v4(),
      subject: _subjectCtrl.text.isEmpty ? '(No Subject)' : _subjectCtrl.text,
      body: _bodyCtrl.text,
      toEmail: _toCtrl.text,
      toName: _toNameCtrl.text,
      fromEmail: 'maryam@usa.edu.pk',
      fromName: 'Maryam Adeeba',
      createdAt: DateTime.now(),
    );
    await context.read<EmailService>().saveDraft(email);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Draft saved')));
      context.go('/email');
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<EmailService>();

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: GradientAppBar(
        title: 'Compose Email',
        showBack: true,
        actions: [
          IconButton(icon: const Icon(Icons.save_outlined, color: Colors.white), onPressed: _saveDraft),
          TextButton(
            onPressed: service.isLoading ? null : _send,
            child: service.isLoading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Send', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
          ),
        ],
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // AI Generate Banner
              GestureDetector(
                onTap: () => setState(() => _showAiPanel = !_showAiPanel),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(gradient: AppTheme.accentGradient, borderRadius: BorderRadius.circular(12)),
                  child: Row(children: [
                    const Icon(Icons.psychology_rounded, color: Colors.white, size: 22),
                    const SizedBox(width: 10),
                    const Expanded(child: Text('Generate email with AI', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600))),
                    Icon(_showAiPanel ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded, color: Colors.white),
                  ]),
                ),
              ),

              if (_showAiPanel) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.accent.withOpacity(0.3))),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('AI Email Generator', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),
                    TextFormField(controller: _toNameCtrl, decoration: const InputDecoration(labelText: 'Recipient Name', prefixIcon: Icon(Icons.person_outline))),
                    const SizedBox(height: 10),
                    TextFormField(controller: _purposeCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Purpose of email (e.g. internship offer, sponsorship request)', prefixIcon: Icon(Icons.info_outline), alignLabelWithHint: true)),
                    const SizedBox(height: 10),
                    const Text('Tone', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
                    const SizedBox(height: 6),
                    Row(children: [
                      _ToneChip(label: 'Formal', selected: _tone == 'formal', onTap: () => setState(() => _tone = 'formal')),
                      const SizedBox(width: 8),
                      _ToneChip(label: 'Friendly', selected: _tone == 'friendly', onTap: () => setState(() => _tone = 'friendly')),
                      const SizedBox(width: 8),
                      _ToneChip(label: 'Persuasive', selected: _tone == 'persuasive', onTap: () => setState(() => _tone = 'persuasive')),
                    ]),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: service.isGenerating ? null : _aiGenerate,
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accent),
                        icon: service.isGenerating ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.auto_awesome_rounded),
                        label: Text(service.isGenerating ? 'Generating...' : 'Generate Email'),
                      ),
                    ),
                  ]),
                ),
              ],
              const SizedBox(height: 14),

              // Email form
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                child: Column(children: [
                  TextFormField(controller: _toCtrl, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'To (Email) *', prefixIcon: Icon(Icons.email_outlined))),
                  const SizedBox(height: 12),
                  TextFormField(controller: _toNameCtrl, decoration: const InputDecoration(labelText: 'Recipient Name', prefixIcon: Icon(Icons.person_outline))),
                  const SizedBox(height: 12),
                  TextFormField(controller: _subjectCtrl, decoration: const InputDecoration(labelText: 'Subject *', prefixIcon: Icon(Icons.subject_rounded))),
                  const SizedBox(height: 12),
                  Row(children: [
                    const Text('Priority:', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                    const SizedBox(width: 10),
                    ...EmailPriority.values.map((p) => Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(label: Text(p.name.toUpperCase(), style: const TextStyle(fontSize: 11)), selected: _priority == p, onSelected: (_) => setState(() => _priority = p), selectedColor: _priorityColor(p).withOpacity(0.15)),
                    )),
                  ]),
                ]),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                child: TextFormField(
                  controller: _bodyCtrl,
                  maxLines: 16,
                  decoration: const InputDecoration(labelText: 'Email Body *', border: InputBorder.none, alignLabelWithHint: true),
                  style: const TextStyle(fontSize: 14, height: 1.6),
                ),
              ),
              const SizedBox(height: 80),
            ],
          ),
          if (service.isLoading) const LoadingOverlay(message: 'Sending email...'),
          if (service.isGenerating) const LoadingOverlay(message: 'Generating email with AI...\nThis may take a few seconds'),
        ],
      ),
    );
  }

  Color _priorityColor(EmailPriority p) {
    switch (p) {
      case EmailPriority.low: return AppTheme.success;
      case EmailPriority.normal: return AppTheme.secondary;
      case EmailPriority.high: return AppTheme.error;
    }
  }
}

class _ToneChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ToneChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(color: selected ? AppTheme.accent : AppTheme.surface, borderRadius: BorderRadius.circular(8), border: Border.all(color: selected ? AppTheme.accent : AppTheme.divider)),
        child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: selected ? Colors.white : AppTheme.textSecondary)),
      ),
    );
  }
}
