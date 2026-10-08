import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/chat_message_model.dart';

class AiService extends ChangeNotifier {
  static const String _baseUrl = 'http://localhost:8000';

  List<ChatMessageModel> _messages = [];
  bool _isTyping = false;

  List<ChatMessageModel> get messages => _messages;
  bool get isTyping => _isTyping;

  AiService() {
    _initWelcome();
  }

  void _initWelcome() {
    _messages = [
      ChatMessageModel.ai(
        'Hello! I am your BDOMate.AI assistant. I can help you with:\n\n'
        '• Drafting professional emails\n'
        '• Summarizing call transcripts\n'
        '• Generating MOU documents\n'
        '• Creating marketing content\n'
        '• Analysing partner engagement\n'
        '• Scheduling reminders\n\n'
        'How can I assist you today?',
        suggestions: [
          'Draft an email',
          'Summarize a call',
          'Generate MOU',
          'Create campaign content',
        ],
      ),
    ];
  }

  Future<void> sendMessage(String userMessage) async {
    // Add user bubble + loading indicator
    _messages.add(ChatMessageModel.user(userMessage));
    _messages.add(ChatMessageModel.loading());
    _isTyping = true;
    notifyListeners();

    // Build conversation history from existing messages (skip loading bubble)
    final history = _messages
        .where((m) => !m.isLoading)
        .where((m) => m.content.isNotEmpty)
        .take(_messages.length - 1)
        .map(
          (m) => {
            'role': m.sender == MessageSender.user ? 'user' : 'assistant',
            'content': m.content,
          },
        )
        .toList();

    String reply = '';

    // ── Try real backend first ──────────────────────────────────
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/ai/chat'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'message': userMessage, 'history': history}),
          )
          .timeout(
            const Duration(seconds: 50),
          ); // generous — Gemini can be slow

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        reply = (data['reply'] ?? '').toString().trim();
      } else {
        // Backend returned an error code — use local fallback silently
        reply = '';
      }
    } catch (_) {
      // Network error or timeout — use local fallback silently
      reply = '';
    }

    // ── Local fallback if backend failed or returned empty ──────
    if (reply.isEmpty) {
      reply = _localFallback(userMessage);
    }

    // Remove loading bubble and add reply
    _messages.removeLast();
    _messages.add(
      ChatMessageModel.ai(reply, suggestions: _suggestionsFor(userMessage)),
    );
    _isTyping = false;
    notifyListeners();
  }

  // ── Local keyword fallback (used when backend is unreachable) ─
  String _localFallback(String input) {
    final lower = input.toLowerCase();

    if (lower.contains('email') ||
        lower.contains('draft') ||
        lower.contains('write')) {
      return 'I\'d be happy to draft a professional email for you!\n\nPlease provide:\n1. Recipient\'s name and organisation\n2. Purpose of the email\n3. Preferred tone (formal or friendly)\n\nOr go to the Email section and use the AI Generate button.';
    }
    if (lower.contains('mou') || lower.contains('memorandum')) {
      return 'I can generate a professional MOU document!\n\nI need:\n• Partner organisation name\n• Purpose of collaboration\n• Key obligations for both parties\n• Desired duration\n\nShall we proceed to the MOU generator?';
    }
    if (lower.contains('call') ||
        lower.contains('transcript') ||
        lower.contains('summar')) {
      return 'I can transcribe and summarise your calls.\n\nGo to the Calling section and select any completed call to generate an AI summary.';
    }
    if (lower.contains('campaign') || lower.contains('marketing')) {
      return 'Let me help you create marketing content!\n\nI can generate:\n• Email campaign copy\n• Social media posts\n• Event announcements\n\nWhat\'s the campaign about?';
    }
    if (lower.contains('partner') || lower.contains('crm')) {
      return 'Visit the CRM section to manage your partners, track engagement, and send follow-ups.';
    }
    if (lower.contains('hello') ||
        lower.contains('hi') ||
        lower.contains('hey')) {
      return 'Hello! Great to hear from you. I\'m your AI-powered BDO assistant. What would you like to work on today?';
    }
    return 'I understand you\'re asking about: "$input"\n\nI can help with emails, MOUs, marketing content, partner management, and analytics. Could you provide more context?';
  }

  List<String> _suggestionsFor(String input) {
    final lower = input.toLowerCase();
    if (lower.contains('email') || lower.contains('draft')) {
      return ['Go to Email section', 'Formal tone', 'Friendly tone'];
    }
    if (lower.contains('mou')) {
      return ['Go to MOU Generator', 'Tell me more about MOUs'];
    }
    if (lower.contains('campaign') || lower.contains('marketing')) {
      return ['Email campaign', 'Social media post', 'Event announcement'];
    }
    return [
      'Draft an email',
      'Generate MOU',
      'Analytics overview',
      'Campaign content',
    ];
  }

  void clearMessages() {
    _messages.clear();
    _initWelcome();
    notifyListeners();
  }
}
