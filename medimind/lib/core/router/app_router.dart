import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/health_session_model.dart';
import '../../presentation/screens/auth/splash_screen.dart';
import '../../presentation/screens/auth/login_screen.dart';
import '../../presentation/screens/auth/register_screen.dart';
import '../../presentation/screens/home/main_scaffold.dart';
import '../../presentation/screens/analysis/symptom_input_screen.dart';
import '../../presentation/screens/analysis/analysis_result_screen.dart';
import '../../presentation/screens/schedule/set_schedule_screen.dart';
import '../../presentation/screens/reminders/reminders_screen.dart';
import '../../presentation/screens/history/history_detail_screen.dart';

final router = GoRouter(
  initialLocation: AppRoutes.splash,
  routes: [
    GoRoute(
      path: AppRoutes.splash,
      builder: (_, __) => const SplashScreen(),
    ),
    GoRoute(
      path: AppRoutes.login,
      builder: (_, __) => const LoginScreen(),
    ),
    GoRoute(
      path: AppRoutes.register,
      builder: (_, __) => const RegisterScreen(),
    ),
    GoRoute(
      path: AppRoutes.home,
      builder: (_, __) => const MainScaffold(initialIndex: 0),
    ),
    GoRoute(
      path: AppRoutes.symptomInput,
      builder: (context, state) {
        final source = state.extra as String?;
        return SymptomInputScreen(initialSource: source);
      },
    ),
    GoRoute(
      path: AppRoutes.analysisResult,
      builder: (context, state) {
        final session = state.extra as HealthSession;
        return AnalysisResultScreen(session: session);
      },
    ),
    GoRoute(
      path: AppRoutes.setSchedule,
      builder: (context, state) {
        final session = state.extra as HealthSession;
        return SetScheduleScreen(session: session);
      },
    ),
    GoRoute(
      path: AppRoutes.reminders,
      builder: (_, __) => const MainScaffold(initialIndex: 2),
    ),
    GoRoute(
      path: AppRoutes.history,
      builder: (_, __) => const MainScaffold(initialIndex: 1),
    ),
    GoRoute(
      path: AppRoutes.historyDetail,
      builder: (context, state) {
        final session = state.extra as HealthSession;
        return HistoryDetailScreen(session: session);
      },
    ),
    GoRoute(
      path: AppRoutes.profile,
      builder: (_, __) => const MainScaffold(initialIndex: 3),
    ),
  ],
  errorBuilder: (context, state) => Scaffold(
    body: Center(child: Text('Page not found: ${state.uri}')),
  ),
);