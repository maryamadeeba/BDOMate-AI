// lib/app_router.dart
//
// FIX 3 — The redirect guard already uses auth.isLoggedIn, which is now set to
//          false by logout(). This means after sign-out context.go('/login') is
//          redundant but harmless — GoRouter would redirect anyway.
//
// Key change: refreshListenable is passed so GoRouter re-evaluates the redirect
// whenever AuthService notifies (i.e., on login AND on logout).
// Without this, the blank-screen bug can persist even if logout() is correct.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../screens/auth/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/crm/crm_screen.dart';
import '../screens/crm/partner_detail_screen.dart';
import '../screens/crm/add_partner_screen.dart';
import '../screens/email/email_screen.dart';
import '../screens/email/compose_email_screen.dart';
import '../screens/email/email_detail_screen.dart';
import '../screens/calling/calling_screen.dart';
import '../screens/calling/call_detail_screen.dart';
import '../screens/calling/active_call_screen.dart';
import '../screens/events/events_screen.dart';
import '../screens/events/event_detail_screen.dart';
import '../screens/events/add_event_screen.dart';
import '../screens/mou/mou_screen.dart';
import '../screens/mou/mou_detail_screen.dart';
import '../screens/mou/generate_mou_screen.dart';
import '../screens/marketing/marketing_screen.dart';
import '../screens/marketing/campaign_detail_screen.dart';
import '../screens/marketing/create_campaign_screen.dart';
import '../screens/analytics/analytics_screen.dart';
import '../screens/notifications/notifications_screen.dart';
import '../screens/ai_assistant/ai_assistant_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/settings/profile_screen.dart';
import '../widgets/main_scaffold.dart';

class AppRouter {
  static GoRouter router(BuildContext context) {
    final auth = Provider.of<AuthService>(context, listen: false);

    return GoRouter(
      initialLocation: '/splash',
      // FIX 3 — re-evaluate redirect every time AuthService notifies
      refreshListenable: auth,
      redirect: (context, state) {
        final isAuth = auth.isLoggedIn;
        final loc = state.matchedLocation;
        final isOnAuth =
            loc == '/login' ||
            loc == '/register' ||
            loc == '/forgot-password' ||
            loc == '/splash';

        // Not logged in and trying to access a protected route → send to login
        if (!isAuth && !isOnAuth) return '/login';

        // Already logged in and landing on an auth screen → send to dashboard
        if (isAuth && isOnAuth && loc != '/splash') return '/dashboard';

        return null; // no redirect needed
      },
      routes: [
        GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
        GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
        GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
        GoRoute(
          path: '/forgot-password',
          builder: (_, __) => const ForgotPasswordScreen(),
        ),
        ShellRoute(
          builder: (context, state, child) => MainScaffold(child: child),
          routes: [
            GoRoute(
              path: '/dashboard',
              builder: (_, __) => const DashboardScreen(),
            ),
            GoRoute(
              path: '/crm',
              builder: (_, __) => const CrmScreen(),
              routes: [
                GoRoute(
                  path: 'add',
                  builder: (_, __) => const AddPartnerScreen(),
                ),
                GoRoute(
                  path: ':id',
                  builder: (_, state) => PartnerDetailScreen(
                    partnerId: state.pathParameters['id']!,
                  ),
                ),
              ],
            ),
            GoRoute(
              path: '/email',
              builder: (_, __) => const EmailScreen(),
              routes: [
                GoRoute(
                  path: 'compose',
                  builder: (_, __) => const ComposeEmailScreen(),
                ),
                GoRoute(
                  path: ':id',
                  builder: (_, state) =>
                      EmailDetailScreen(emailId: state.pathParameters['id']!),
                ),
              ],
            ),
            GoRoute(
              path: '/calling',
              builder: (_, __) => const CallingScreen(),
              routes: [
                GoRoute(
                  path: 'active',
                  builder: (_, __) => const ActiveCallScreen(),
                ),
                GoRoute(
                  path: ':id',
                  builder: (_, state) =>
                      CallDetailScreen(callId: state.pathParameters['id']!),
                ),
              ],
            ),
            GoRoute(
              path: '/events',
              builder: (_, __) => const EventsScreen(),
              routes: [
                GoRoute(
                  path: 'add',
                  builder: (_, __) => const AddEventScreen(),
                ),
                GoRoute(
                  path: ':id',
                  builder: (_, state) =>
                      EventDetailScreen(eventId: state.pathParameters['id']!),
                ),
              ],
            ),
            GoRoute(
              path: '/mou',
              builder: (_, __) => const MouScreen(),
              routes: [
                GoRoute(
                  path: 'generate',
                  builder: (_, __) => const GenerateMouScreen(),
                ),
                GoRoute(
                  path: ':id',
                  builder: (_, state) =>
                      MouDetailScreen(mouId: state.pathParameters['id']!),
                ),
              ],
            ),
            GoRoute(
              path: '/marketing',
              builder: (_, __) => const MarketingScreen(),
              routes: [
                GoRoute(
                  path: 'create',
                  builder: (_, __) => const CreateCampaignScreen(),
                ),
                GoRoute(
                  path: ':id',
                  builder: (_, state) => CampaignDetailScreen(
                    campaignId: state.pathParameters['id']!,
                  ),
                ),
              ],
            ),
            GoRoute(
              path: '/analytics',
              builder: (_, __) => const AnalyticsScreen(),
            ),
            GoRoute(
              path: '/notifications',
              builder: (_, __) => const NotificationsScreen(),
            ),
            GoRoute(
              path: '/ai-assistant',
              builder: (_, __) => const AiAssistantScreen(),
            ),
            GoRoute(
              path: '/settings',
              builder: (_, __) => const SettingsScreen(),
              routes: [
                GoRoute(
                  path: 'profile',
                  builder: (_, __) => const ProfileScreen(),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
