import 'package:flutter/material.dart';
import 'package:perpus_app/services/library_api_service.dart';

class ApiTestScreen extends StatefulWidget {
  const ApiTestScreen({super.key});

  @override
  State<ApiTestScreen> createState() => _ApiTestScreenState();
}

class _ApiTestScreenState extends State<ApiTestScreen> {
  final LibraryApiService _apiService = LibraryApiService();
  String _result = '';
  bool _isLoading = false;

  Future<void> _testLogin() async {
    setState(() {
      _isLoading = true;
      _result = 'Testing login...';
    });

    try {
      final success = await _apiService.login('Admin123', '12345678');
      setState(() {
        _result = success ? 'Login Success!' : 'Login Failed!';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _result = 'Login Error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _testGetBooks() async {
    setState(() {
      _isLoading = true;
      _result = 'Testing get books...';
    });

    try {
      final books = await _apiService.getAllBooks();
      setState(() {
        _result = 'Books loaded: ${books.length} items';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _result = 'Books Error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _testGetCategories() async {
    setState(() {
      _isLoading = true;
      _result = 'Testing get categories...';
    });

    try {
      final categories = await _apiService.getAllCategories();
      setState(() {
        _result = 'Categories loaded: ${categories.length} items';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _result = 'Categories Error: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('API Test'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: _isLoading ? null : _testLogin,
              child: const Text('Test Login'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _isLoading ? null : _testGetBooks,
              child: const Text('Test Get Books'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _isLoading ? null : _testGetCategories,
              child: const Text('Test Get Categories'),
            ),
            const SizedBox(height: 20),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(_result),
              ),
          ],
        ),
      ),
    );
  }
}
