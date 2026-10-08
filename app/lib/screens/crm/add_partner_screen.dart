import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../theme/app_theme.dart';
import '../../services/crm_service.dart';
import '../../models/partner_model.dart';
import '../../widgets/app_widgets.dart';

class AddPartnerScreen extends StatefulWidget {
  const AddPartnerScreen({super.key});

  @override
  State<AddPartnerScreen> createState() => _AddPartnerScreenState();
}

class _AddPartnerScreenState extends State<AddPartnerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _orgCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _websiteCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _tagCtrl = TextEditingController();
  PartnerType _type = PartnerType.industry;
  final List<String> _tags = [];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _orgCtrl.dispose();
    _addressCtrl.dispose();
    _websiteCtrl.dispose();
    _notesCtrl.dispose();
    _tagCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final partner = PartnerModel(
      id: const Uuid().v4(),
      name: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      organization: _orgCtrl.text.trim(),
      type: _type,
      address: _addressCtrl.text.trim().isEmpty
          ? null
          : _addressCtrl.text.trim(),
      website: _websiteCtrl.text.trim().isEmpty
          ? null
          : _websiteCtrl.text.trim(),
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      createdAt: DateTime.now(),
      tags: _tags,
    );
    await context.read<CrmService>().addPartner(partner);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Partner added successfully!'),
          backgroundColor: AppTheme.success,
        ),
      );
      context.go('/crm');
    }
  }

  void _addTag() {
    final tag = _tagCtrl.text.trim();
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() {
        _tags.add(tag);
        _tagCtrl.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final crm = context.watch<CrmService>();
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: GradientAppBar(
        title: 'Add Partner',
        showBack: true,
        actions: [
          TextButton(
            onPressed: crm.isLoading ? null : _save,
            child: crm.isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
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
          // 🔑 Fixed: Increased bottom padding from 40 to 140 so it clears the floating bar cleanly
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 140),
          children: [
            // Partner type selector
            const Text(
              'Partner Type',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: PartnerType.values
                  .map(
                    (t) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: GestureDetector(
                          onTap: () => setState(() => _type = t),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
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
                            child: Column(
                              children: [
                                Icon(
                                  _typeIcon(t),
                                  color: _type == t
                                      ? Colors.white
                                      : AppTheme.textSecondary,
                                  size: 20,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  t.name.capitalize(),
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: _type == t
                                        ? Colors.white
                                        : AppTheme.textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 20),

            _buildSection('Basic Information', [
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Full Name *',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Name is required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email Address *',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                validator: (v) => v == null || !v.contains('@')
                    ? 'Valid email required'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone Number *',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Phone is required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _orgCtrl,
                decoration: const InputDecoration(
                  labelText: 'Organization / Company *',
                  prefixIcon: Icon(Icons.business_outlined),
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Organization is required' : null,
              ),
            ]),
            const SizedBox(height: 16),

            _buildSection('Additional Details', [
              TextFormField(
                controller: _addressCtrl,
                decoration: const InputDecoration(
                  labelText: 'Address (Optional)',
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _websiteCtrl,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(
                  labelText: 'Website (Optional)',
                  prefixIcon: Icon(Icons.language_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notesCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Notes (Optional)',
                  prefixIcon: Icon(Icons.notes_outlined),
                  alignLabelWithHint: true,
                ),
              ),
            ]),
            const SizedBox(height: 16),

            _buildSection('Tags', [
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _tagCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Add tag',
                        prefixIcon: Icon(Icons.label_outline),
                      ),
                      onFieldSubmitted: (_) => _addTag(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _addTag,
                    icon: const Icon(
                      Icons.add_circle_rounded,
                      color: AppTheme.primary,
                      size: 28,
                    ),
                  ),
                ],
              ),
              if (_tags.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _tags
                      .map(
                        (t) => Chip(
                          label: Text(t),
                          onDeleted: () => setState(() => _tags.remove(t)),
                          backgroundColor: AppTheme.primary.withOpacity(0.08),
                          labelStyle: const TextStyle(
                            color: AppTheme.primary,
                            fontSize: 12,
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ]),
            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: crm.isLoading ? null : _save,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: crm.isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Add Partner',
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

  IconData _typeIcon(PartnerType t) {
    switch (t) {
      case PartnerType.industry:
        return Icons.factory_outlined;
      case PartnerType.alumni:
        return Icons.school_outlined;
      case PartnerType.sponsor:
        return Icons.monetization_on_outlined;
      case PartnerType.institution:
        return Icons.account_balance_outlined;
    }
  }
}

extension StringCapitalize on String {
  String capitalize() =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
}
