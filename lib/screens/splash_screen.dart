import 'dart:async';
import 'package:flutter/material.dart';
import 'package:perpus_app/api/api_service.dart';
import 'package:perpus_app/screens/auth/login_screen.dart';
import 'package:perpus_app/screens/dashboard/member_dashboard_screen.dart';
import 'package:perpus_app/screens/admin/admin_dashboard_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  void _checkLoginStatus() async {
    await Future.delayed(const Duration(seconds: 3));
    final apiService = ApiService();
    final token = await apiService.getToken();
    if (mounted) {
      if (token != null) {
        // PERBAIKAN: Cek role user untuk menentukan dashboard yang tepat
        final userRole = await apiService.getUserRole();
        print('DEBUG: User role after restart: $userRole'); // Debug log

        if (userRole == 'admin') {
          print('DEBUG: Redirecting to AdminDashboardScreen'); // Debug log
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
          );
        } else {
          print(
              'DEBUG: Redirecting to MemberDashboardScreen (member)'); // Debug log
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const MemberDashboardScreen()),
          );
        }
      } else {
        print('DEBUG: No token found, redirecting to LoginScreen'); // Debug log
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 25, 132, 255),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/Mamorasoft.png',
              width: 300,
              height: 300,
              color: Colors.white,
            ),
            const SizedBox(height: 24),
            const Text('Mamorasoft Library',
                style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
            const SizedBox(height: 48),
            const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
          ],
        ),
      ),
    );
  }
}
