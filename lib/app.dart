import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config.dart';
import 'core/theme.dart';
import 'features/auth/login_screen.dart';
import 'features/cards/card_studio_screen.dart';
import 'features/checkin/checkin_screen.dart';
import 'features/events/event_detail_screen.dart';
import 'features/events/event_form_screen.dart';
import 'features/events/events_screen.dart';
import 'features/guests/guests_screen.dart';
import 'features/send/send_screen.dart';

class MwalikoApp extends StatefulWidget {
  const MwalikoApp({super.key});

  @override
  State<MwalikoApp> createState() => _MwalikoAppState();
}

class _MwalikoAppState extends State<MwalikoApp> {
  late final GoRouter _router = _buildRouter();

  @override
  Widget build(BuildContext context) {
    if (!AppConfig.isConfigured) {
      return MaterialApp(theme: buildTheme(), home: const _SetupRequired());
    }
    return MaterialApp.router(
      title: 'Mwaliko',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      routerConfig: _router,
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
  final auth = Supabase.instance.client.auth;
  return GoRouter(
    initialLocation: '/',
    refreshListenable: _AuthListenable(auth.onAuthStateChange),
    redirect: (context, state) {
      final loggedIn = auth.currentSession != null;
      final atLogin = state.matchedLocation == '/login';
      if (!loggedIn && !atLogin) return '/login';
      if (loggedIn && atLogin) return '/';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(path: '/', builder: (_, _) => const EventsScreen()),
      GoRoute(path: '/events/new', builder: (_, _) => const EventFormScreen()),
      GoRoute(
        path: '/events/:id',
        builder: (_, s) => EventDetailScreen(eventId: s.pathParameters['id']!),
        routes: [
          GoRoute(path: 'edit', builder: (_, s) => EventFormScreen(eventId: s.pathParameters['id'])),
          GoRoute(path: 'guests', builder: (_, s) => GuestsScreen(eventId: s.pathParameters['id']!)),
          GoRoute(path: 'card', builder: (_, s) => CardStudioScreen(eventId: s.pathParameters['id']!)),
          GoRoute(path: 'send', builder: (_, s) => SendScreen(eventId: s.pathParameters['id']!)),
          GoRoute(path: 'checkin', builder: (_, s) => CheckinScreen(eventId: s.pathParameters['id']!)),
        ],
      ),
    ],
  );
}

class _AuthListenable extends ChangeNotifier {
  _AuthListenable(Stream<AuthState> stream) {
    _sub = stream.listen((_) => notifyListeners());
  }
  late final StreamSubscription<AuthState> _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
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
