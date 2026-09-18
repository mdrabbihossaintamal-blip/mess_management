import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'providers/data_provider.dart';
import 'services/auth_service.dart';
import 'services/firestore_service.dart';
import 'services/notification_service.dart';
import 'services/seed_service.dart';
import 'utils/theme.dart';
import 'screens/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/setup_screen.dart';
import 'screens/home_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
    await NotificationService.instance.init();
  } catch (e) {
    debugPrint('Firebase init error: $e');
  }
  runApp(const MessApp());
}

class MessApp extends StatelessWidget {
  const MessApp({super.key});

  @override
  Widget build(BuildContext context) {
    const authService = AuthService();
    final firestoreService = FirestoreService(authService);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider(authService),
        ),
        ChangeNotifierProvider<DataProvider>(
          create: (_) => DataProvider(firestoreService)..init(),
        ),
      ],
      child: MaterialApp(
        title: 'মেস ম্যানেজমেন্ট',
        debugShowCheckedModeBanner: false,
        theme: appTheme(),
        home: const Root(),
      ),
    );
  }
}

class Root extends StatefulWidget {
  const Root({super.key});

  @override
  State<Root> createState() => _RootState();
}

class _RootState extends State<Root> {
  bool _checked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SeedService.maybeSeed(context);
      _boot();
    });
  }

  Future<void> _boot() async {
    final auth = context.read<AuthProvider>();
    if (auth.user == null) {
      await auth.refresh();
    }
    if (mounted) setState(() => _checked = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_checked) return const SplashScreen();

    final dataProvider = context.watch<DataProvider>();
    // First-time setup: no mess settings yet
    if (dataProvider.isInitialized && dataProvider.settings == null) {
      return const SetupScreen();
    }

    return Consumer<AuthProvider>(builder: (context, auth, _) {
      if (auth.user == null) return const LoginScreen();
      return const HomeShell();
    });
  }
}