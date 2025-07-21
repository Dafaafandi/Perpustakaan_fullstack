import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:perpus_app/providers/auth_provider.dart';
import 'package:perpus_app/providers/book_provider.dart';
import 'package:perpus_app/providers/category_provider.dart';
import 'package:perpus_app/utils/error_handler.dart';
import 'package:perpus_app/utils/retry_manager.dart';

class CredentialTestScreen extends StatefulWidget {
  const CredentialTestScreen({super.key});

  @override
  State<CredentialTestScreen> createState() => _CredentialTestScreenState();
}

class _CredentialTestScreenState extends State<CredentialTestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  String _loginResult = '';
  String _currentUser = '';

  @override
  void initState() {
    super.initState();
    _checkCurrentUser();
  }

  void _checkCurrentUser() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.isLoggedIn) {
      setState(() {
        _currentUser =
            'Logged in as: ${authProvider.userName} (${authProvider.userRole})';
      });
    }
  }

  Future<void> _testLogin(String username, String password) async {
    setState(() {
      _isLoading = true;
      _loginResult = 'Testing login for $username...';
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // Use retry mechanism for login
      final success = await RetryManager.retryNetworkOperation(
        () => authProvider.login(username, password),
        context: 'Login Test',
        maxRetries: 2,
      );

      if (success) {
        setState(() {
          _loginResult = '✅ LOGIN SUCCESS for $username\n'
              'User: ${authProvider.userName}\n'
              'Role: ${authProvider.userRole}\n'
              'Email: ${authProvider.userEmail}';
          _currentUser =
              'Logged in as: ${authProvider.userName} (${authProvider.userRole})';
        });

        // Test API calls after successful login
        await _testApiCalls();

        if (mounted) {
          ErrorHandler.showSuccess(context, 'Login dan API test berhasil!');
        }
      } else {
        setState(() {
          _loginResult = '❌ LOGIN FAILED for $username';
        });

        if (mounted) {
          ErrorHandler.showError(context, 'Login gagal untuk $username');
        }
      }
    } catch (e) {
      setState(() {
        _loginResult = '❌ LOGIN ERROR for $username: $e';
      });

      if (mounted) {
        ErrorHandler.showError(
            context, 'Login error: ${ErrorHandler.processError(e)}');
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testApiCalls() async {
    try {
      final bookProvider = Provider.of<BookProvider>(context, listen: false);
      final categoryProvider =
          Provider.of<CategoryProvider>(context, listen: false);

      // Test fetching books with retry
      await RetryManager.retryNetworkOperation(
        () => bookProvider.fetchBooks(),
        context: 'Fetch Books',
        maxRetries: 2,
      );

      // Test fetching categories with retry
      await RetryManager.retryNetworkOperation(
        () => categoryProvider.fetchCategories(),
        context: 'Fetch Categories',
        maxRetries: 2,
      );

      setState(() {
        _loginResult += '\n\n📚 API Test Results: Success\n'
            '• Books count: ${bookProvider.books.length}\n'
            '• Categories count: ${categoryProvider.categories.length}';
      });
    } catch (e) {
      setState(() {
        _loginResult +=
            '\n\n❌ API Test Failed: ${ErrorHandler.processError(e)}';
      });

      if (mounted) {
        ErrorHandler.showError(
            context, 'API Test gagal: ${ErrorHandler.processError(e)}');
      }
    }
  }

  Future<void> _manualLogin() async {
    if (!_formKey.currentState!.validate()) return;

    await _testLogin(_usernameController.text, _passwordController.text);
  }

  Future<void> _logout() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      await ErrorHandler.handleAsync(
        context,
        authProvider.logout(),
        successMessage: 'Logout berhasil!',
        errorContext: 'Logout',
      );

      setState(() {
        _currentUser = '';
        _loginResult = 'Logged out successfully';
      });
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(
            context, 'Logout error: ${ErrorHandler.processError(e)}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('API Credential Test'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          if (_currentUser.isNotEmpty)
            IconButton(
              onPressed: _logout,
              icon: const Icon(Icons.logout),
              tooltip: 'Logout',
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current User Status
            if (_currentUser.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  border: Border.all(color: Colors.green),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _currentUser,
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

            const SizedBox(height: 16),

            // Manual Login Form
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Manual Login Test',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _usernameController,
                        decoration: const InputDecoration(
                          labelText: 'Username',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter username';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _passwordController,
                        decoration: const InputDecoration(
                          labelText: 'Password',
                          border: OutlineInputBorder(),
                        ),
                        obscureText: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter password';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _manualLogin,
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Test Login'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Results Display
            if (_loginResult.isNotEmpty)
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Test Results:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Text(
                            _loginResult,
                            style: const TextStyle(fontFamily: 'monospace'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
