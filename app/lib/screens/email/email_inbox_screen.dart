// lib/screens/email/email_inbox_screen.dart  (REPLACE existing file)
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../services/email_reply_service.dart';
import '../../models/email_reply_model.dart';
import '../../widgets/app_widgets.dart';

class EmailInboxScreen extends StatefulWidget {
  const EmailInboxScreen({super.key});

  @override
  State<EmailInboxScreen> createState() => _EmailInboxScreenState();
}

class _EmailInboxScreenState extends State<EmailInboxScreen> {
  String? _expandedId;

  @override
  Widget build(BuildContext context) {
    final service = context.watch<EmailReplyService>();

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A2340),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Inbox',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
            ),
            if (service.unreadCount > 0)
              Text(
                '${service.unreadCount} unread',
                style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12),
              ),
          ],
        ),
        actions: [
          if (service.unreadCount > 0)
            TextButton(
              onPressed: service.markAllRead,
              child: const Text('Mark All Read',
                  style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
            ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: service.loadReplies,
          ),
        ],
      ),
      body: _buildBody(service),
    );
  }

  Widget _buildBody(EmailReplyService service) {
    if (service.isLoading && service.replies.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (service.error != null && service.replies.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72, height: 72,
                decoration: BoxDecoration(
                  color: AppTheme.error.withOpacity(0.1), shape: BoxShape.circle),
                child: const Icon(Icons.wifi_off_rounded, size: 36, color: AppTheme.error),
              ),
              const SizedBox(height: 20),
              const Text('Could Not Load Inbox',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text(service.error!,
                  style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary, height: 1.5),
                  textAlign: TextAlign.center),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: service.loadReplies,
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                label: const Text('Retry', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      );
    }

    if (service.replies.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.08), shape: BoxShape.circle),
              child: const Icon(Icons.mark_email_unread_outlined, size: 40, color: AppTheme.primary),
            ),
            const SizedBox(height: 20),
            const Text('No Replies Yet',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            const Text('Replies to your BDOMate.AI emails\nwill appear here.',
                style: TextStyle(fontSize: 13, color: AppTheme.textSecondary, height: 1.5),
                textAlign: TextAlign.center),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppTheme.accent,
      onRefresh: service.loadReplies,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(0, 8, 0, 100),
        itemCount: service.replies.length,
        itemBuilder: (_, i) {
          final reply = service.replies[i];
          return _ReplyTile(
            key: ValueKey(reply.id),
            reply: reply,
            isExpanded: _expandedId == reply.id,
            onTap: () {
              setState(() => _expandedId = (_expandedId == reply.id) ? null : reply.id);
              if (!reply.isRead) service.markRead(reply.id);
            },
            onDelete: () {
              service.deleteReply(reply.id);
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(SnackBar(
                  behavior: SnackBarBehavior.floating,
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  backgroundColor: const Color(0xFF1A2340),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  content: Text('Reply from ${reply.displayName} deleted',
                      style: const TextStyle(color: Colors.white)),
                  action: SnackBarAction(
                      label: 'Undo',
                      textColor: AppTheme.accent,
                      onPressed: service.loadReplies),
                  duration: const Duration(seconds: 4),
                ));
            },
          );
        },
      ),
    );
  }
}

// ─── Reply Tile ───────────────────────────────────────────────────────────────

class _ReplyTile extends StatelessWidget {
  final EmailReplyModel reply;
  final bool isExpanded;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _ReplyTile({
    super.key,
    required this.reply,
    required this.isExpanded,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final unread = !reply.isRead;

    return Dismissible(
      key: ValueKey('dismiss-${reply.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(color: AppTheme.error, borderRadius: BorderRadius.circular(16)),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.delete_rounded, color: Colors.white, size: 22),
            SizedBox(height: 4),
            Text('Delete', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
      confirmDismiss: (_) async => true,
      onDismissed: (_) => onDelete(),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: unread
                ? Border(left: BorderSide(color: AppTheme.accent, width: 4))
                : null,
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2)),
            ],
          ),
          child: Column(
            children: [
              // ── Header row ────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Avatar(initials: reply.initials, unread: unread),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  reply.displayName,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: unread ? FontWeight.w800 : FontWeight.w600,
                                    color: AppTheme.textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _formatDate(reply.receivedAt),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: unread ? AppTheme.accent : AppTheme.textSecondary,
                                  fontWeight: unread ? FontWeight.w700 : FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(reply.senderEmail,
                              style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  reply.subject,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: unread ? FontWeight.w700 : FontWeight.w500,
                                    color: AppTheme.textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (unread) ...[
                                const SizedBox(width: 8),
                                Container(
                                  width: 8, height: 8,
                                  decoration: const BoxDecoration(
                                      color: AppTheme.accent, shape: BoxShape.circle),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ── Body ──────────────────────────────────────────────────────
              AnimatedCrossFade(
                duration: const Duration(milliseconds: 250),
                crossFadeState:
                    isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                firstChild: _CollapsedBody(body: reply.body),
                secondChild: _ExpandedBody(reply: reply),
              ),

              // ── Chevron ───────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    AnimatedRotation(
                      turns: isExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 250),
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 20,
                        color: AppTheme.textSecondary.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final now  = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1)  return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24)   return '${diff.inHours}h ago';
    if (diff.inDays == 1)    return 'Yesterday';
    if (diff.inDays < 7)     return DateFormat('EEE').format(dt);
    return DateFormat('MMM d').format(dt);
  }
}

// ─── Collapsed preview ────────────────────────────────────────────────────────

class _CollapsedBody extends StatelessWidget {
  final String body;
  const _CollapsedBody({required this.body});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
      child: Text(
        body.replaceAll('\n', ' '),
        maxLines: 2, overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.5),
      ),
    );
  }
}

// ─── Expanded body + Generate Reply panel ────────────────────────────────────

class _ExpandedBody extends StatefulWidget {
  final EmailReplyModel reply;
  const _ExpandedBody({required this.reply});

  @override
  State<_ExpandedBody> createState() => _ExpandedBodyState();
}

class _ExpandedBodyState extends State<_ExpandedBody> {
  bool _showReplyPanel   = false;
  bool _replyGenerated   = false;
  String _generatedBody  = '';
  String _replySubject   = '';
  String _replyToEmail   = '';
  String _replyToName    = '';
  late TextEditingController _bodyCtrl;

  @override
  void initState() {
    super.initState();
    _bodyCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _bodyCtrl.dispose();
    super.dispose();
  }

  Future<void> _generateReply(BuildContext context) async {
    final service = context.read<EmailReplyService>();
    try {
      final result = await service.generateReply(widget.reply.id);
      setState(() {
        _generatedBody = result['generated_body'] ?? '';
        _replySubject  = result['reply_subject']  ?? '';
        _replyToEmail  = result['reply_to_email'] ?? '';
        _replyToName   = result['reply_to_name']  ?? '';
        _bodyCtrl.text = _generatedBody;
        _replyGenerated = true;
      });
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('AI error: $e'), backgroundColor: AppTheme.error),
        );
      }
    }
  }

  Future<void> _sendReply(BuildContext context) async {
    if (_bodyCtrl.text.trim().isEmpty) return;
    final service = context.read<EmailReplyService>();
    final ok = await service.sendReply(
      replyId: widget.reply.id,
      toEmail: _replyToEmail,
      toName:  _replyToName,
      subject: _replySubject,
      body:    _bodyCtrl.text.trim(),
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok ? 'Reply sent to $_replyToEmail' : 'Failed to send. Check SMTP settings.'),
        backgroundColor: ok ? AppTheme.success : AppTheme.error,
      ));
      if (ok) setState(() => _showReplyPanel = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<EmailReplyService>();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Full email body ───────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.divider),
            ),
            child: Text(
              widget.reply.body,
              style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary, height: 1.7),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.alternate_email_rounded, size: 13, color: AppTheme.textSecondary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(widget.reply.senderEmail,
                    style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // ── Generate Reply button ─────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: service.isGenerating
                  ? null
                  : () {
                      setState(() => _showReplyPanel = true);
                      _generateReply(context);
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accent,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: service.isGenerating
                  ? const SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.psychology_rounded, color: Colors.white),
              label: Text(
                service.isGenerating ? 'Generating reply...' : 'Generate Reply with AI',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
              ),
            ),
          ),

          // ── AI reply panel ────────────────────────────────────────────────
          if (_showReplyPanel && _replyGenerated) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.accent.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const AiBadge(),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text('AI Generated Reply',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 18),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => setState(() {
                          _showReplyPanel  = false;
                          _replyGenerated  = false;
                        }),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // To / Subject info
                  Text('To: $_replyToName <$_replyToEmail>',
                      style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                  Text('Subject: $_replySubject',
                      style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                  const SizedBox(height: 12),
                  // Editable reply body
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.divider),
                    ),
                    child: TextField(
                      controller: _bodyCtrl,
                      maxLines: null,
                      minLines: 6,
                      style: const TextStyle(fontSize: 13, height: 1.6, color: AppTheme.textPrimary),
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.all(12),
                        border: InputBorder.none,
                        hintText: 'Edit the reply before sending...',
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      // Regenerate
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: service.isGenerating
                              ? null
                              : () => _generateReply(context),
                          icon: const Icon(Icons.refresh_rounded, size: 16),
                          label: const Text('Regenerate'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.accent,
                            side: BorderSide(color: AppTheme.accent),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Send
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: service.isSendingReply
                              ? null
                              : () => _sendReply(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.success,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: service.isSendingReply
                              ? const SizedBox(
                                  width: 16, height: 16,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2))
                              : const Icon(Icons.send_rounded, size: 16, color: Colors.white),
                          label: Text(
                            service.isSendingReply ? 'Sending...' : 'Send Reply',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 6),
        ],
      ),
    );
  }
}

// ─── Avatar ──────────────────────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  final String initials;
  final bool unread;
  const _Avatar({required this.initials, required this.unread});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46, height: 46,
      decoration: BoxDecoration(
        gradient: unread
            ? const LinearGradient(
                colors: [AppTheme.accent, AppTheme.primary],
                begin: Alignment.topLeft, end: Alignment.bottomRight)
            : LinearGradient(
                colors: [
                  AppTheme.textSecondary.withOpacity(0.2),
                  AppTheme.textSecondary.withOpacity(0.1),
                ],
                begin: Alignment.topLeft, end: Alignment.bottomRight),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: unread ? Colors.white : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }
}
