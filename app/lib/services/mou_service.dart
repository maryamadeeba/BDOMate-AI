import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/mou_model.dart';
import 'api_constants.dart';

class MouService extends ChangeNotifier {
  final List<MouModel> _mous = [];
  bool _isLoading = false;
  bool _isGenerating = false;
  String? _error;

  List<MouModel> get mous => _mous;
  bool get isLoading => _isLoading;
  bool get isGenerating => _isGenerating;
  String? get error => _error;

  List<MouModel> get active => _mous
      .where(
        (m) => m.status == MouStatus.active || m.status == MouStatus.signed,
      )
      .toList();

  List<MouModel> get expiringSoon => _mous
      .where(
        (m) =>
            m.daysUntilExpiry != null &&
            m.daysUntilExpiry! < 30 &&
            m.daysUntilExpiry! >= 0,
      )
      .toList();

  MouService() {
    loadMous();
  }

  Future<void> loadMous() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final res = await http
          .get(Uri.parse(ApiConstants.mouAll))
          .timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final list = data['mous'] as List;
        final backendIds = list.map((m) => m['id'].toString()).toSet();
        _mous.removeWhere((m) => backendIds.contains(m.id));
        for (final m in list) {
          _mous.insert(
            0,
            MouModel(
              id: m['id'].toString(),
              title: 'MOU #${m['id']}',
              partnerId: m['request_id'].toString(),
              partnerName: 'Partner Contact',
              partnerOrganization: 'Partner Organization',
              content: m['mou_text'] ?? '',
              universityRepresentative: 'University of South Asia',
              partnerRepresentative: 'Partner Representative',
              purpose: 'University Partnership',
              createdAt:
                  DateTime.tryParse(m['created_at'] ?? '') ?? DateTime.now(),
              isAiGenerated: true,
            ),
          );
        }
      }
    } catch (e) {
      _error = 'Could not load MOUs. Using local data.';
    }
    _isLoading = false;
    notifyListeners();
  }

  MouModel? getById(String id) {
    try {
      return _mous.firstWhere((m) => m.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<String> generateMou({
    required String partnerName,
    required String partnerOrg,
    required String purpose,
    required List<String> obligations,
    String partnerType = 'tech_company',
    String partnerEmail = '',
    int durationYears = 2,
  }) async {
    _isGenerating = true;
    notifyListeners();
    try {
      final res = await http
          .post(
            Uri.parse(ApiConstants.mouGenerate),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'partner_name': partnerOrg,
              'partner_type': partnerType,
              'partner_email': partnerEmail,
              'contact_person': partnerName,
              'collaboration_focus': purpose,
              'duration_years': durationYears,
              'special_notes': obligations.join('; '),
            }),
          )
          .timeout(const Duration(seconds: 60));

      _isGenerating = false;
      notifyListeners();

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['mou_text'] ?? 'Error: No MOU text returned';
      } else {
        throw Exception('Server error ${res.statusCode}: ${res.body}');
      }
    } catch (e) {
      _isGenerating = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> addMou(MouModel mou) async {
    _isLoading = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 300));
    _mous.insert(0, mou);
    _isLoading = false;
    notifyListeners();
  }

  Future<void> updateMou(MouModel updated) async {
    final idx = _mous.indexWhere((m) => m.id == updated.id);
    if (idx != -1) {
      _mous[idx] = updated;
      notifyListeners();
    }
  }

  Future<void> signMou(String id) async {
    final idx = _mous.indexWhere((m) => m.id == id);
    if (idx != -1) {
      _mous[idx].status = MouStatus.signed;
      _mous[idx].signedAt = DateTime.now();
      notifyListeners();
    }
  }

  Future<void> deleteMou(String id) async {
    _mous.removeWhere((m) => m.id == id);
    notifyListeners();
  }
}
