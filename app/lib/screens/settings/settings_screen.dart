// lib/screens/settings/settings_screen.dart
//
// FIX 3 — Sign-out now:
//   1. Calls auth.logout() which clears _isLoggedIn, _currentUser, and _token
//   2. Uses context.go('/login') via GoRouter (not Navigator.pushAndRemoveUntil)
//      GoRouter's redirect guard picks up isLoggedIn == false and forces /login,
//      so there is no blank /#/settings shell left in the history.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../services/auth_service.dart';
import '../../widgets/app_widgets.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _emailNotifications = true;
  bool _callNotifications = true;
  bool _eventReminders = true;
  bool _mouAlerts = true;
  bool _aiSuggestions = true;
  bool _darkMode = false;
  String _language = 'English';

  // ── Sign-out handler ──────────────────────────────────────────────────────
  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    // FIX 3A — clear all auth state (token, currentUser, isLoggedIn flag)
    await context.read<AuthService>().logout();

    // FIX 3B — GoRouter's redirect guard sees isLoggedIn == false and reroutes.
    //           context.go() replaces the current entry so there is no back-stack
    //           left pointing at /settings.
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final user = auth.currentUser;

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: GradientAppBar(title: 'Settings'),
      body: ListView(
        children: [
          // ── Profile card ──────────────────────────────────────────────────
          GestureDetector(
            onTap: () => context.go('/settings/profile'),
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  // FIX 2 — uses PartnerAvatar which derives initials from user.name
                  PartnerAvatar(name: user?.name ?? 'BDO', radius: 30),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.name ?? 'User',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          user?.email ?? '',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            user?.role ?? '',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.edit_rounded, color: Colors.white),
                ],
              ),
            ),
          ),

          // ── Notifications ─────────────────────────────────────────────────
          _SectionTitle('Notifications'),
          _ToggleTile(
            icon: Icons.email_rounded,
            label: 'Email Notifications',
            value: _emailNotifications,
            onChanged: (v) => setState(() => _emailNotifications = v),
          ),
          _ToggleTile(
            icon: Icons.call_rounded,
            label: 'Call Alerts',
            value: _callNotifications,
            onChanged: (v) => setState(() => _callNotifications = v),
          ),
          _ToggleTile(
            icon: Icons.event_rounded,
            label: 'Event Reminders',
            value: _eventReminders,
            onChanged: (v) => setState(() => _eventReminders = v),
          ),
          _ToggleTile(
            icon: Icons.description_rounded,
            label: 'MOU Expiry Alerts',
            value: _mouAlerts,
            onChanged: (v) => setState(() => _mouAlerts = v),
          ),

          // ── AI & Automation ───────────────────────────────────────────────
          _SectionTitle('AI & Automation'),
          _ToggleTile(
            icon: Icons.psychology_rounded,
            label: 'AI Suggestions',
            value: _aiSuggestions,
            onChanged: (v) => setState(() => _aiSuggestions = v),
          ),
          _NavigationTile(
            icon: Icons.auto_awesome_rounded,
            label: 'AI Email Templates',
            onTap: () {},
          ),
          _NavigationTile(
            icon: Icons.record_voice_over_rounded,
            label: 'Call Transcription Settings',
            onTap: () {},
          ),

          // ── Appearance ────────────────────────────────────────────────────
          _SectionTitle('Appearance'),
          _ToggleTile(
            icon: Icons.dark_mode_rounded,
            label: 'Dark Mode',
            value: _darkMode,
            onChanged: (v) => setState(() => _darkMode = v),
          ),
          _NavigationTile(
            icon: Icons.language_rounded,
            label: 'Language',
            trailing: Text(
              _language,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
              ),
            ),
            onTap: () => showDialog(
              context: context,
              builder: (_) => SimpleDialog(
                title: const Text('Select Language'),
                children: ['English', 'Urdu', 'Arabic']
                    .map(
                      (l) => SimpleDialogOption(
                        onPressed: () {
                          setState(() => _language = l);
                          Navigator.pop(context);
                        },
                        child: Text(l),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),

          // ── Data & Security ───────────────────────────────────────────────
          _SectionTitle('Data & Security'),
          _NavigationTile(
            icon: Icons.backup_rounded,
            label: 'Backup & Sync',
            onTap: () {},
          ),
          _NavigationTile(
            icon: Icons.security_rounded,
            label: 'Privacy & Security',
            onTap: () {},
          ),
          _NavigationTile(
            icon: Icons.lock_rounded,
            label: 'Change Password',
            onTap: () {},
          ),
          _NavigationTile(
            icon: Icons.download_rounded,
            label: 'Export Data',
            onTap: () {},
          ),

          // ── Support ───────────────────────────────────────────────────────
          _SectionTitle('Support'),
          _NavigationTile(
            icon: Icons.help_outline_rounded,
            label: 'Help & FAQ',
            onTap: () {},
          ),
          _NavigationTile(
            icon: Icons.feedback_outlined,
            label: 'Send Feedback',
            onTap: () {},
          ),
          _NavigationTile(
            icon: Icons.info_outline_rounded,
            label: 'About BDOMate.AI',
            onTap: () => showAboutDialog(
              context: context,
              applicationName: 'BDOMate.AI',
              applicationVersion: '1.0.0',
              applicationLegalese: '© 2025 University of South Asia',
            ),
          ),

          // ── Sign Out ──────────────────────────────────────────────────────
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ElevatedButton.icon(
              // FIX 3 — calls _signOut() which clears state then navigates
              onPressed: _signOut,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.error,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              icon: const Icon(Icons.logout_rounded),
              label: const Text(
                'Sign Out',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

// ── Private helpers (unchanged from original) ─────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 6),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppTheme.textSecondary,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

class _ToggleTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value;
  final Function(bool) onChanged;
  const _ToggleTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primary, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppTheme.primary,
          ),
        ],
      ),
    );
  }
}

class _NavigationTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget? trailing;
  final VoidCallback onTap;
  const _NavigationTile({
    required this.icon,
    required this.label,
    this.trailing,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppTheme.primary, size: 22),
        title: Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        trailing:
            trailing ??
            const Icon(
              Icons.chevron_right_rounded,
              color: AppTheme.textSecondary,
            ),
        onTap: onTap,
      ),
    );
  }
}
