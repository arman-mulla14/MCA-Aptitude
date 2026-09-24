import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'firebase_options.dart';
import 'services/data_service.dart';
import 'services/auth_service.dart';
import 'features/splash/splash_screen.dart';
import 'features/auth/login_screen.dart';
import 'features/admin/admin_dashboard.dart';
import 'features/student/student_dashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Attempt Firebase initialization
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase init fallback: $e');
  }

  runApp(const McaAptitudeApp());
}

class McaAptitudeApp extends StatelessWidget {
  const McaAptitudeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DataService()),
        ChangeNotifierProvider(create: (_) => AuthService()),
      ],
      child: MaterialApp(
        title: AppConstants.appTitle,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const AuthRouter(),
      ),
    );
  }
}

class AuthRouter extends StatefulWidget {
  const AuthRouter({super.key});

  @override
  State<AuthRouter> createState() => _AuthRouterState();
}

class _AuthRouterState extends State<AuthRouter> {
  bool _showSplash = true;

  @override
  Widget build(BuildContext context) {
    if (_showSplash) {
      return SplashScreen(
        onFinish: () {
          setState(() {
            _showSplash = false;
          });
        },
      );
    }

    final authService = Provider.of<AuthService>(context);

    if (authService.isInitializing) {
      return const Scaffold(
        backgroundColor: AppTheme.bgCanvas,
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.primaryBlue),
        ),
      );
    }

    if (!authService.isAuthenticated) {
      return const LoginScreen();
    } else if (authService.isAdmin) {
      return const AdminDashboardScreen();
    } else {
      return const StudentDashboardScreen();
    }
  }
}
