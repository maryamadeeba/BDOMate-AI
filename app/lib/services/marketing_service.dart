import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/campaign_model.dart';
import 'api_constants.dart';

class MarketingService extends ChangeNotifier {
  final List<CampaignModel> _campaigns = [];
  bool _isLoading = false;
  bool _isGenerating = false;

  List<CampaignModel> get campaigns => _campaigns;
  bool get isLoading => _isLoading;
  bool get isGenerating => _isGenerating;
  int get totalReach => _campaigns.fold(0, (s, c) => s + c.totalReach);
  double get avgOpenRate {
    final sent = _campaigns.where((c) => c.totalReach > 0).toList();
    if (sent.isEmpty) return 0;
    return sent.fold(0.0, (s, c) => s + c.openRate) / sent.length;
  }

  CampaignModel? getById(String id) =>
      _campaigns.firstWhere((c) => c.id == id, orElse: () => _campaigns.first);

  // ── Generate marketing content via backend AI ────────────────
  Future<String> generateContent({
    required String campaignType, // email / instagram / linkedin / facebook
    required String audience,
    required String goal, // event name or topic
    required String tone,
  }) async {
    _isGenerating = true;
    notifyListeners();
    try {
      // Map frontend campaign type to backend platform name
      final platform = _mapPlatform(campaignType, tone);

      final res = await http
          .post(
            Uri.parse(ApiConstants.aiMarketing),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'event_name': goal,
              'event_type': audience,
              'event_date': 'Coming Soon',
              'platform': platform,
            }),
          )
          .timeout(const Duration(seconds: 60));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        _isGenerating = false;
        notifyListeners();
        return data['content'] ?? 'Could not generate content.';
      } else {
        throw Exception('Server error ${res.statusCode}');
      }
    } catch (e) {
      _isGenerating = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> addCampaign(CampaignModel campaign) async {
    _isLoading = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 400));
    _campaigns.insert(0, campaign);
    _isLoading = false;
    notifyListeners();
  }

  Future<void> updateCampaign(CampaignModel updated) async {
    final idx = _campaigns.indexWhere((c) => c.id == updated.id);
    if (idx != -1) {
      _campaigns[idx] = updated;
      notifyListeners();
    }
  }

  Future<void> deleteCampaign(String id) async {
    _campaigns.removeWhere((c) => c.id == id);
    notifyListeners();
  }

  // Map frontend campaign type + tone to backend platform name
  String _mapPlatform(String type, String tone) {
    switch (type.toLowerCase()) {
      case 'social_media':
        return tone == 'formal' ? 'linkedin' : 'instagram';
      case 'whatsapp':
        return 'facebook';
      case 'email':
        return 'email';
      default:
        return 'email';
    }
  }
}
