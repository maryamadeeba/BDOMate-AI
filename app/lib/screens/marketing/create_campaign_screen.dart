import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../theme/app_theme.dart';
import '../../services/marketing_service.dart';
import '../../models/campaign_model.dart';
import '../../widgets/app_widgets.dart';

class CreateCampaignScreen extends StatefulWidget {
  const CreateCampaignScreen({super.key});

  @override
  State<CreateCampaignScreen> createState() => _CreateCampaignScreenState();
}

class _CreateCampaignScreenState extends State<CreateCampaignScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  final _audienceCtrl = TextEditingController();
  final _goalCtrl = TextEditingController();
  CampaignType _type = CampaignType.email;
  String _tone = 'formal';
  final List<String> _audiences = [];
  bool _aiMode = true;
  String? _generatedContent;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _contentCtrl.dispose();
    _audienceCtrl.dispose();
    _goalCtrl.dispose();
    super.dispose();
  }

  void _addAudience() {
    final a = _audienceCtrl.text.trim();
    if (a.isNotEmpty && !_audiences.contains(a)) {
      setState(() {
        _audiences.add(a);
        _audienceCtrl.clear();
      });
    }
  }

  Future<void> _generateContent() async {
    if (_goalCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the campaign goal')),
      );
      return;
    }
    final service = context.read<MarketingService>();
    final content = await service.generateContent(
      campaignType: _type.name,
      audience: _audiences.isEmpty ? 'General' : _audiences.join(', '),
      goal: _goalCtrl.text,
      tone: _tone,
    );
    setState(() {
      _generatedContent = content;
      _contentCtrl.text = content;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final campaign = CampaignModel(
      id: const Uuid().v4(),
      title: _titleCtrl.text,
      description: _descCtrl.text,
      type: _type,
      content: _contentCtrl.text,
      targetAudience: _audiences,
      createdAt: DateTime.now(),
      isAiGenerated: _generatedContent != null,
    );
    await context.read<MarketingService>().addCampaign(campaign);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Campaign created!'),
          backgroundColor: AppTheme.success,
        ),
      );
      context.go('/marketing');
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<MarketingService>();
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: GradientAppBar(
        title: 'Create Campaign',
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
      body: Stack(
        children: [
          Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // AI Toggle
                Row(
                  children: [
                    const Icon(
                      Icons.psychology_rounded,
                      color: AppTheme.accent,
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'AI Content Generation',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Switch(
                      value: _aiMode,
                      onChanged: (v) => setState(() => _aiMode = v),
                      activeThumbColor: AppTheme.accent,
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Campaign Type
                const Text(
                  'Campaign Type',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: CampaignType.values
                        .map(
                          (t) => GestureDetector(
                            onTap: () => setState(() => _type = t),
                            child: Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: _type == t
                                    ? AppTheme.primary
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: _type == t
                                      ? AppTheme.primary
                                      : AppTheme.divider,
                                ),
                              ),
                              child: Text(
                                t.name.replaceAll('_', ' ').toUpperCase(),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: _type == t
                                      ? Colors.white
                                      : AppTheme.textSecondary,
                                ),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
                const SizedBox(height: 14),

                _buildSection('Campaign Details', [
                  TextFormField(
                    controller: _titleCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Campaign Title *',
                      prefixIcon: Icon(Icons.campaign_outlined),
                    ),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _descCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      prefixIcon: Icon(Icons.description_outlined),
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _audienceCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Target Audience',
                            prefixIcon: Icon(Icons.group_outlined),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: _addAudience,
                        icon: const Icon(
                          Icons.add_circle_rounded,
                          color: AppTheme.primary,
                          size: 28,
                        ),
                      ),
                    ],
                  ),
                  if (_audiences.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _audiences
                          .map(
                            (a) => Chip(
                              label: Text(a),
                              onDeleted: () =>
                                  setState(() => _audiences.remove(a)),
                              backgroundColor: AppTheme.secondary.withOpacity(
                                0.08,
                              ),
                              labelStyle: const TextStyle(
                                color: AppTheme.secondary,
                                fontSize: 12,
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ]),
                const SizedBox(height: 14),

                if (_aiMode) ...[
                  _buildSection('AI Content Generator', [
                    TextFormField(
                      controller: _goalCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'What is the goal of this campaign? *',
                        prefixIcon: Icon(Icons.flag_outlined),
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Tone',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _ToneChip(
                          label: 'Formal',
                          selected: _tone == 'formal',
                          onTap: () => setState(() => _tone = 'formal'),
                        ),
                        const SizedBox(width: 8),
                        _ToneChip(
                          label: 'Casual',
                          selected: _tone == 'casual',
                          onTap: () => setState(() => _tone = 'casual'),
                        ),
                        const SizedBox(width: 8),
                        _ToneChip(
                          label: 'Urgent',
                          selected: _tone == 'urgent',
                          onTap: () => setState(() => _tone = 'urgent'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: service.isGenerating
                            ? null
                            : _generateContent,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.accent,
                        ),
                        icon: service.isGenerating
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.auto_awesome_rounded),
                        label: Text(
                          service.isGenerating
                              ? 'Generating...'
                              : 'Generate Content with AI',
                        ),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 14),
                ],

                _buildSection('Content', [
                  TextFormField(
                    controller: _contentCtrl,
                    maxLines: 8,
                    decoration: InputDecoration(
                      labelText: _aiMode && _generatedContent == null
                          ? 'Click "Generate" above or write manually'
                          : 'Campaign Content *',
                      prefixIcon: const Icon(Icons.article_outlined),
                      alignLabelWithHint: true,
                    ),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Content is required' : null,
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
                          'Create Campaign',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
          if (service.isGenerating)
            const LoadingOverlay(
              message: 'AI is crafting your campaign content...',
            ),
        ],
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

class _ToneChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _ToneChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppTheme.accent : AppTheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? AppTheme.accent : AppTheme.divider,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }
}
