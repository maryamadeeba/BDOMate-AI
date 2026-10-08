import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../theme/app_theme.dart';
import '../../services/mou_service.dart';
import '../../models/mou_model.dart';
import '../../widgets/app_widgets.dart';

class GenerateMouScreen extends StatefulWidget {
  const GenerateMouScreen({super.key});

  @override
  State<GenerateMouScreen> createState() => _GenerateMouScreenState();
}

class _GenerateMouScreenState extends State<GenerateMouScreen> {
  final _formKey = GlobalKey<FormState>();
  final _partnerNameCtrl = TextEditingController();
  final _partnerOrgCtrl = TextEditingController();
  final _partnerRepCtrl = TextEditingController();
  final _purposeCtrl = TextEditingController();
  final _uniRepCtrl = TextEditingController(
    text: 'Prof. Dr. Khalid Mehmood (Vice Chancellor)',
  );
  final _obligationCtrl = TextEditingController();
  final List<String> _obligations = [];
  String? _generatedContent;
  int _step = 0;
  DateTime? _startDate;
  DateTime? _expiryDate;

  @override
  void dispose() {
    _partnerNameCtrl.dispose();
    _partnerOrgCtrl.dispose();
    _partnerRepCtrl.dispose();
    _purposeCtrl.dispose();
    _uniRepCtrl.dispose();
    _obligationCtrl.dispose();
    super.dispose();
  }

  void _addObligation() {
    final o = _obligationCtrl.text.trim();
    if (o.isNotEmpty) {
      setState(() {
        _obligations.add(o);
        _obligationCtrl.clear();
      });
    }
  }

  Future<void> _generate() async {
    if (!_formKey.currentState!.validate()) return;
    final service = context.read<MouService>();
    final content = await service.generateMou(
      partnerName: _partnerNameCtrl.text,
      partnerOrg: _partnerOrgCtrl.text,
      purpose: _purposeCtrl.text,
      obligations: _obligations,
    );
    setState(() {
      _generatedContent = content;
      _step = 1;
    });
  }

  Future<void> _save() async {
    final mou = MouModel(
      id: const Uuid().v4(),
      title: 'MOU – ${_partnerOrgCtrl.text}',
      partnerId: const Uuid().v4(),
      partnerName: _partnerNameCtrl.text,
      partnerOrganization: _partnerOrgCtrl.text,
      content: _generatedContent ?? '',
      universityRepresentative: _uniRepCtrl.text,
      partnerRepresentative: _partnerRepCtrl.text,
      createdAt: DateTime.now(),
      purpose: _purposeCtrl.text,
      obligations: _obligations,
      startDate: _startDate,
      expiryDate: _expiryDate,
      isAiGenerated: true,
    );
    await context.read<MouService>().addMou(mou);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('MOU saved successfully!'),
          backgroundColor: AppTheme.success,
        ),
      );
      context.go('/mou');
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<MouService>();
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: GradientAppBar(title: 'Generate MOU', showBack: true),
      body: Stack(
        children: [
          _step == 0 ? _buildForm(service) : _buildPreview(service),
          if (service.isGenerating)
            const LoadingOverlay(
              message:
                  'AI is generating your MOU...\nThis may take a few seconds',
            ),
        ],
      ),
    );
  }

  Widget _buildForm(MouService service) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: AppTheme.accentGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(Icons.psychology_rounded, color: Colors.white, size: 22),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'AI will generate a complete, legally-structured MOU based on your inputs.',
                    style: TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildSection('Partner Information', [
            TextFormField(
              controller: _partnerNameCtrl,
              decoration: const InputDecoration(
                labelText: 'Partner Contact Name *',
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _partnerOrgCtrl,
              decoration: const InputDecoration(
                labelText: 'Partner Organization *',
                prefixIcon: Icon(Icons.business_outlined),
              ),
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _partnerRepCtrl,
              decoration: const InputDecoration(
                labelText: 'Partner Representative & Title',
                prefixIcon: Icon(Icons.badge_outlined),
              ),
            ),
          ]),
          const SizedBox(height: 14),
          _buildSection('University Side', [
            TextFormField(
              controller: _uniRepCtrl,
              decoration: const InputDecoration(
                labelText: 'University Representative *',
                prefixIcon: Icon(Icons.account_balance_outlined),
              ),
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
          ]),
          const SizedBox(height: 14),
          _buildSection('Purpose & Scope', [
            TextFormField(
              controller: _purposeCtrl,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Purpose / Objective of MOU *',
                prefixIcon: Icon(Icons.info_outline),
                alignLabelWithHint: true,
              ),
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
          ]),
          const SizedBox(height: 14),
          _buildSection('Obligations', [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _obligationCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Add obligation',
                      prefixIcon: Icon(Icons.assignment_outlined),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _addObligation,
                  icon: const Icon(
                    Icons.add_circle_rounded,
                    color: AppTheme.primary,
                    size: 28,
                  ),
                ),
              ],
            ),
            if (_obligations.isNotEmpty) ...[
              const SizedBox(height: 10),
              ..._obligations.asMap().entries.map(
                (e) => Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.circle, size: 6, color: AppTheme.primary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          e.value,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.close,
                          size: 16,
                          color: AppTheme.error,
                        ),
                        onPressed: () =>
                            setState(() => _obligations.removeAt(e.key)),
                        padding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ]),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: service.isGenerating ? null : _generate,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accent,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            icon: const Icon(Icons.psychology_rounded),
            label: const Text(
              'Generate MOU with AI',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildPreview(MouService service) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          color: AppTheme.success.withOpacity(0.08),
          child: Row(
            children: [
              const Icon(
                Icons.check_circle_rounded,
                color: AppTheme.success,
                size: 20,
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'MOU generated successfully! Review and save.',
                  style: TextStyle(
                    color: AppTheme.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.edit_rounded,
                  color: AppTheme.success,
                  size: 18,
                ),
                onPressed: () => setState(() => _step = 0),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  _generatedContent ?? '',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                    height: 1.7,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => setState(() => _step = 0),
                      child: const Text('Edit Details'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: service.isLoading ? null : _save,
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
                              'Save MOU',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ],
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
