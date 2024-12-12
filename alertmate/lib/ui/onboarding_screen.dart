import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_page.dart';
import 'root_page.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<OnboardingScreen> {
  @override
  void initState() {
    super.initState();
    _navigateAfterOnboarding();
  }

  Future<void> _navigateAfterOnboarding() async {
    // Delay for 3 seconds
    await Future.delayed(const Duration(seconds: 3));

    // Check login state from SharedPreferences
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

    // Navigate to the appropriate page
    if (isLoggedIn) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const RootPage()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.cyan[400]!,
                Colors.tealAccent[700]!,
                Colors.tealAccent[700]!,
                Colors.tealAccent[700]!,
                Colors.cyan[400]!,
              ],
              stops: const [0, 0.33, 0.5, 0.66, 1],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Center(
            child: Image.asset(
              'assets/logo.png',
              width: 200,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(Icons.error, color: Colors.red, size: 75);
              },
            ),
          ),
        ),
      ),
    );
  }
}
