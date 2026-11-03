import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';

import 'core/config.dart';
import 'core/theme.dart';
import 'data/auth_repository.dart';
import 'features/account/account_screen.dart';
import 'features/account/admin_payments_screen.dart';
import 'features/auth/auth_screen.dart';
import 'features/cards/card_studio_screen.dart';
import 'features/checkin/checkin_screen.dart';
import 'features/events/event_detail_screen.dart';
import 'features/events/event_form_screen.dart';
import 'features/events/events_screen.dart';
import 'features/guests/guests_screen.dart';
import 'features/home/app_shell.dart';
import 'features/home/home_screen.dart';
import 'features/send/send_screen.dart';
import 'features/wallet/wallet_screen.dart';

class MwalikoApp extends StatefulWidget {
  const MwalikoApp({super.key});

  @override
  State<MwalikoApp> createState() => _MwalikoAppState();
}

class _MwalikoAppState extends State<MwalikoApp> {
  late final GoRouter _router = _buildRouter();

  @override
  Widget build(BuildContext context) {
    if (!AppConfig.isConfigured && !AppConfig.demo) {
      return MaterialApp(theme: buildTheme(), home: const _SetupRequired());
    }
    return MaterialApp.router(
      title: 'Mwaliko',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      routerConfig: _router,
      builder: AppConfig.demo ? (context, child) => _DemoFrame(child: child!) : null,
      locale: const Locale('sw'),
      supportedLocales: const [Locale('sw'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}

GoRouter _buildRouter() {
  final auth = AuthRepository.instance;
  return GoRouter(
    initialLocation: '/',
    refreshListenable: auth,
    redirect: (context, state) {
      final atLogin = state.matchedLocation == '/login';
      if (!auth.isSignedIn) return atLogin ? null : '/login';
      if (atLogin) return '/';
      return null;
    },
    routes: _routes,
  );
}

final _routes = <RouteBase>[
  GoRoute(path: '/login', builder: (_, _) => const AuthScreen()),
  // Tabo nne za chini (kila moja inakumbuka hali yake)
  StatefulShellRoute.indexedStack(
    builder: (_, _, shell) => AppShell(shell: shell),
    branches: [
      StatefulShellBranch(
        routes: [GoRoute(path: '/', builder: (_, _) => const HomeScreen())],
      ),
      StatefulShellBranch(
        routes: [GoRoute(path: '/events', builder: (_, _) => const EventsScreen())],
      ),
      StatefulShellBranch(
        routes: [GoRoute(path: '/wallet', builder: (_, _) => const WalletScreen())],
      ),
      StatefulShellBranch(
        routes: [GoRoute(path: '/account', builder: (_, _) => const AccountScreen())],
      ),
    ],
  ),
  // Skrini kamili (juu ya tabo)
  GoRoute(
    path: '/topup',
    builder: (_, s) => WalletScreen(need: int.tryParse(s.uri.queryParameters['need'] ?? '')),
  ),
  GoRoute(path: '/admin/payments', builder: (_, _) => const AdminPaymentsScreen()),
  GoRoute(path: '/events/new', builder: (_, _) => const EventFormScreen()),
  GoRoute(
    path: '/events/:id',
    builder: (_, s) => EventDetailScreen(eventId: s.pathParameters['id']!),
    routes: [
      GoRoute(
        path: 'edit',
        builder: (_, s) => EventFormScreen(eventId: s.pathParameters['id']),
      ),
      GoRoute(
        path: 'guests',
        builder: (_, s) => GuestsScreen(eventId: s.pathParameters['id']!),
      ),
      GoRoute(
        path: 'card',
        builder: (_, s) => CardStudioScreen(eventId: s.pathParameters['id']!),
      ),
      GoRoute(
        path: 'send',
        builder: (_, s) => SendScreen(eventId: s.pathParameters['id']!),
      ),
      GoRoute(
        path: 'checkin',
        builder: (_, s) => CheckinScreen(eventId: s.pathParameters['id']!),
      ),
    ],
  ),
];

/// Ukanda mdogo juu unaoonyesha kuwa hili ni toleo la majaribio.
class _DemoFrame extends StatelessWidget {
  const _DemoFrame({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return Column(
      children: [
        Material(
          color: MwalikoColors.gold,
          child: Padding(
            padding: EdgeInsets.fromLTRB(12, top + 3, 12, 3),
            child: const SizedBox(
              width: double.infinity,
              child: Text(
                'DEMO · data ya mfano, hakuna ujumbe unaotumwa kweli',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: MwalikoColors.ink),
              ),
            ),
          ),
        ),
        Expanded(
          child: MediaQuery.removePadding(context: context, removeTop: true, child: child),
        ),
      ],
    );
  }
}

class _SetupRequired extends StatelessWidget {
  const _SetupRequired();

  @override
  Widget build(BuildContext context) => const Scaffold(
    body: Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'Mwaliko haijaunganishwa na Supabase.\n\n'
          'Endesha app hivi:\nflutter run --dart-define-from-file=env.json\n\n'
          '(angalia env.example.json na README)',
          textAlign: TextAlign.center,
        ),
      ),
    ),
  );
}
