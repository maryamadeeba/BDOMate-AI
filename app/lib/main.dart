import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'theme/app_theme.dart';
import 'services/auth_service.dart';
import 'services/crm_service.dart';
import 'services/email_service.dart';
import 'services/call_service.dart';
import 'services/event_service.dart';
import 'services/mou_service.dart';
import 'services/marketing_service.dart';
import 'services/analytics_service.dart';
import 'services/notification_service.dart';
import 'services/ai_service.dart';
import 'services/email_reply_service.dart';
import 'app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const BdoMateApp());
}

class BdoMateApp extends StatelessWidget {
  const BdoMateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => CrmService()),
        ChangeNotifierProvider(create: (_) => EmailService()),
        ChangeNotifierProvider(create: (_) => CallService()),
        ChangeNotifierProvider(create: (_) => EventService()),
        ChangeNotifierProvider(create: (_) => MouService()),
        ChangeNotifierProvider(create: (_) => MarketingService()),
        ChangeNotifierProvider(create: (_) => NotificationService()),
        ChangeNotifierProvider(create: (_) => AiService()),
        ChangeNotifierProvider(create: (_) => EmailReplyService()),
        ChangeNotifierProxyProvider4<
          CrmService,
          EmailService,
          MouService,
          EventService,
          AnalyticsService
        >(
          create: (ctx) => AnalyticsService(
            ctx.read<CrmService>(),
            ctx.read<EmailService>(),
            ctx.read<MouService>(),
            ctx.read<EventService>(),
          ),
          update: (_, crm, email, mou, event, previous) =>
              previous ?? AnalyticsService(crm, email, mou, event),
        ),
      ],
      child: Builder(
        builder: (context) {
          final router = AppRouter.router(context);
          // Apply Nunito as the global font via google_fonts
          final baseTheme = AppTheme.lightTheme;
          final nunitoTheme = baseTheme.copyWith(
            textTheme: GoogleFonts.nunitoTextTheme(baseTheme.textTheme),
          );
          return MaterialApp.router(
            title: 'BDOMate.AI',
            debugShowCheckedModeBanner: false,
            theme: nunitoTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.light,
            routerConfig: router,
          );
        },
      ),
    );
  }
}
