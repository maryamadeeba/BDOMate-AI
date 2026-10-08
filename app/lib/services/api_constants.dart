library;

class ApiConstants {
  static const bool isLive = false;

  static const String _local = 'http://localhost:8000';
  static const String _railway = "https://YOUR-APP.up.railway.app";

  static String get base => isLive ? _railway : _local;

  // ── Events ────────────────────────────────────────────────────
  static String get eventsAll => "$base/events/all";
  static String get eventsCreate => "$base/events/create";
  static String get eventsPredict => "$base/events/predict";
  static String get eventsRecommend => "$base/events/recommend";

  // ── MOU ───────────────────────────────────────────────────────
  static String get mouGenerate => "$base/mou/generate";
  static String get mouAll => "$base/mou/all";
  static String mouById(int id) => "$base/mou/$id";

  // ── Email ─────────────────────────────────────────────────────
  static String get emailGenerate => "$base/email/generate";

  // ── Email Inbox ───────────────────────────────────────────────
  // ✅ FIXED: was /email/replies (wrong) → now /emails/replies (correct)
  static String get emailReplies => "$base/emails/replies";
  static String get emailUnreadCount => "$base/notifications/unread-count";

  // ── Partners ──────────────────────────────────────────────────
  static String get partnersAdd => "$base/partners/add";
  static String get partnersAll => "$base/partners/all";
  static String partnerById(int id) => "$base/partners/$id";

  // ── AI ────────────────────────────────────────────────────────
  static String get aiChat => "$base/ai/chat";
  static String get aiMarketing => "$base/ai/marketing";

  // ── Sponsors ──────────────────────────────────────────────────
  static String get sponsorsSegment => "$base/sponsors/segment";

  // ── Calls ─────────────────────────────────────────────────────
  static String get callsSingle => "$base/calls/single";
  static String get callsBulk => "$base/calls/bulk";
  static String callTranscript(String id) => "$base/calls/transcript/$id";
  static String get callHistory => "$base/calls/history";

  // ── Notifications ─────────────────────────────────────────────
  static String get notificationsAll => "$base/notifications/all";
  static String get notifyMouFollowup => "$base/notifications/mou-followup";
  static String get notifyEventRemind => "$base/notifications/event-reminder";
  static String get notifyCallRemind => "$base/notifications/call-reminder";

  // ── Retrain ───────────────────────────────────────────────────
  static String get retrainStatus => "$base/retrain/status";
  static String get retrainRecord => "$base/retrain/record-actual";
}
