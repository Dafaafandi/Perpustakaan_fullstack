import 'package:flutter/material.dart';
import 'package:perpus_app/api/api_service.dart';
import 'package:perpus_app/screens/admin/admin_dashboard_screen.dart';
import 'package:perpus_app/screens/auth/login_screen.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isPasswordVisible = false;

  void _adminLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      // Try admin login first
      bool success = await _apiService.adminLogin(
          _usernameController.text, _passwordController.text);

      setState(() => _isLoading = false);

      if (success && mounted) {
        // Verify admin role
        final isAdmin = await _apiService.isAdmin();
        if (isAdmin) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Akses ditolak! Anda bukan admin.')),
          );
          await _apiService.logout();
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('Login Admin Gagal! Username atau Password salah.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Login'),
        backgroundColor: Colors.red.shade600,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.red.shade400, Colors.red.shade800],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Admin Icon
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: Colors.red.shade100,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.admin_panel_settings,
                            size: 50,
                            color: Colors.red.shade700,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'ADMIN LOGIN',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade800,
                          ),
                        ),
                        const Text(
                            'Masuk sebagai Administrator Mamorasoft Library',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey)),
                        const SizedBox(height: 32),
                        TextFormField(
                          controller: _usernameController,
                          decoration: InputDecoration(
                            labelText: 'Username Admin',
                            prefixIcon: Icon(Icons.person_outline,
                                color: Colors.red.shade600),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                  color: Colors.red.shade600, width: 2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          validator: (value) => value!.isEmpty
                              ? 'Username tidak boleh kosong'
                              : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: !_isPasswordVisible,
                          decoration: InputDecoration(
                            labelText: 'Password Admin',
                            prefixIcon: Icon(Icons.lock_outline,
                                color: Colors.red.shade600),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isPasswordVisible
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: Colors.red.shade600,
                              ),
                              onPressed: () => setState(() =>
                                  _isPasswordVisible = !_isPasswordVisible),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                  color: Colors.red.shade600, width: 2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          validator: (value) => value!.isEmpty
                              ? 'Password tidak boleh kosong'
                              : null,
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: _isLoading
                              ? const Center(child: CircularProgressIndicator())
                              : ElevatedButton(
                                  onPressed: _adminLogin,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red.shade600,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: const Text('LOGIN ADMIN',
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold)),
                                ),
                        ),
                        const SizedBox(height: 16),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: () => Navigator.of(context)
                              .pushReplacement(MaterialPageRoute(
                                  builder: (_) => const LoginScreen())),
                          child: Text(
                            'Kembali ke Login Member',
                            style: TextStyle(color: Colors.red.shade600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
