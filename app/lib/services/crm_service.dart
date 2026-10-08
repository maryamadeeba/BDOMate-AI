import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/partner_model.dart';
import 'api_constants.dart';

class CrmService extends ChangeNotifier {
  List<PartnerModel> _partners = [];
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';
  PartnerType? _filterType;
  PartnerStatus? _filterStatus;

  List<PartnerModel> get partners => _filtered();
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  PartnerType? get filterType => _filterType;
  PartnerStatus? get filterStatus => _filterStatus;
  int get activeCount =>
      _partners.where((p) => p.status == PartnerStatus.active).length;
  int get totalCount => _partners.length;

  CrmService() {
    loadPartners();
  }

  // ── Load partners from backend ───────────────────────────────
  Future<void> loadPartners() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final res = await http
          .get(Uri.parse(ApiConstants.partnersAll))
          .timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final list = data['partners'] as List;
        _partners = list
            .map(
              (p) => PartnerModel(
                id: p['id'].toString(),
                // Backend: name = company, contact_person = person name
                name: p['contact_person'] ?? p['name'] ?? '',
                organization: p['name'] ?? '',
                email: p['email'] ?? '',
                phone: p['phone'] ?? '',
                type: _parseType(p['type']),
                status: _parseStatus(p['status']),
                createdAt:
                    DateTime.tryParse(p['created_at'] ?? '') ?? DateTime.now(),
              ),
            )
            .toList();
      } else {
        _error = 'Failed to load partners (${res.statusCode})';
      }
    } catch (e) {
      _error = 'Cannot connect to backend. Check server is running.';
    }
    _isLoading = false;
    notifyListeners();
  }

  // ── Add partner to backend ───────────────────────────────────
  // Field mapping fix:
  //   frontend name         → backend contact_person
  //   frontend organization → backend name (company)
  Future<void> addPartner(PartnerModel partner) async {
    _isLoading = true;
    notifyListeners();
    try {
      final res = await http
          .post(
            Uri.parse(ApiConstants.partnersAdd),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'name': partner.organization, // company name → backend name
              'type': partner.type.name,
              'contact_person': partner.name, // person name → contact_person
              'email': partner.email,
              'phone': partner.phone,
              'address': partner.address ?? '',
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        // Update local partner with the ID returned from backend
        final saved = PartnerModel(
          id: data['partner_id'].toString(),
          name: partner.name,
          organization: partner.organization,
          email: partner.email,
          phone: partner.phone,
          type: partner.type,
          status: partner.status,
          address: partner.address,
          website: partner.website,
          notes: partner.notes,
          createdAt: partner.createdAt,
          tags: partner.tags,
          engagementScore: partner.engagementScore,
        );
        _partners.insert(0, saved);
      } else {
        // Fallback: add locally so UI still works
        _partners.insert(0, partner);
      }
    } catch (e) {
      // Fallback: add locally
      _partners.insert(0, partner);
    }
    _isLoading = false;
    notifyListeners();
  }

  PartnerModel? getById(String id) =>
      _partners.firstWhere((p) => p.id == id, orElse: () => _partners.first);

  Future<void> updatePartner(PartnerModel updated) async {
    final idx = _partners.indexWhere((p) => p.id == updated.id);
    if (idx != -1) {
      _partners[idx] = updated;
      notifyListeners();
    }
  }

  Future<void> deletePartner(String id) async {
    _partners.removeWhere((p) => p.id == id);
    notifyListeners();
  }

  void setSearch(String q) {
    _searchQuery = q;
    notifyListeners();
  }

  void setFilterType(PartnerType? t) {
    _filterType = t;
    notifyListeners();
  }

  void setFilterStatus(PartnerStatus? s) {
    _filterStatus = s;
    notifyListeners();
  }

  List<PartnerModel> _filtered() {
    var list = List<PartnerModel>.from(_partners);
    if (_searchQuery.isNotEmpty) {
      list = list
          .where(
            (p) =>
                p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                p.organization.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ) ||
                p.email.toLowerCase().contains(_searchQuery.toLowerCase()),
          )
          .toList();
    }
    if (_filterType != null) {
      list = list.where((p) => p.type == _filterType).toList();
    }
    if (_filterStatus != null) {
      list = list.where((p) => p.status == _filterStatus).toList();
    }
    return list;
  }

  Map<String, int> get typeCounts {
    final m = <String, int>{};
    for (final t in PartnerType.values) {
      m[t.name] = _partners.where((p) => p.type == t).length;
    }
    return m;
  }

  // ── Helpers ──────────────────────────────────────────────────
  PartnerType _parseType(String? t) {
    switch (t) {
      case 'alumni':
        return PartnerType.alumni;
      case 'sponsor':
        return PartnerType.sponsor;
      case 'institution':
        return PartnerType.institution;
      default:
        return PartnerType.industry;
    }
  }

  PartnerStatus _parseStatus(String? s) {
    switch (s) {
      case 'inactive':
        return PartnerStatus.inactive;
      case 'pending':
        return PartnerStatus.pending;
      default:
        return PartnerStatus.active;
    }
  }
}
