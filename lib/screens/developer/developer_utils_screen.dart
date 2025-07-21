import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DeveloperUtilsScreen extends StatefulWidget {
  const DeveloperUtilsScreen({super.key});

  @override
  _DeveloperUtilsScreenState createState() => _DeveloperUtilsScreenState();
}

class _DeveloperUtilsScreenState extends State<DeveloperUtilsScreen> {
  String _debugInfo = '';

  @override
  void initState() {
    super.initState();
    _loadDebugInfo();
  }

  Future<void> _loadDebugInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();

    String info = 'Local Storage Contents:\n\n';
    for (String key in keys) {
      final value = prefs.get(key);
      info += '$key: $value\n';
    }

    setState(() {
      _debugInfo = info;
    });
  }

  Future<void> _clearLocalStorage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Local storage cleared!')),
    );

    await _loadDebugInfo();
  }

  Future<void> _createTestAdmin() async {
    final prefs = await SharedPreferences.getInstance();

    // Create default admin credentials
    await prefs.setString('local_admin_name', 'Administrator');
    await prefs.setString('local_admin_username', 'admin');
    await prefs.setString('local_admin_email', 'admin@library.com');
    await prefs.setString('local_admin_password', 'admin123');
    await prefs.setString('local_admin_role', 'admin');

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content:
            Text('Test admin created!\nUsername: admin\nPassword: admin123'),
        duration: Duration(seconds: 4),
      ),
    );

    await _loadDebugInfo();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Developer Utils'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Development Tools',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // Buttons
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                ElevatedButton(
                  onPressed: _clearLocalStorage,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text('Clear Local Storage'),
                ),
                ElevatedButton(
                  onPressed: _createTestAdmin,
                  style:
                      ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  child: const Text('Create Test Admin'),
                ),
                ElevatedButton(
                  onPressed: _loadDebugInfo,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  child: const Text('Refresh Debug Info'),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Debug Info
            const Text(
              'Debug Information:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _debugInfo.isEmpty ? 'Loading...' : _debugInfo,
                    style: const TextStyle(fontFamily: 'Courier'),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Test Credentials
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                border: Border.all(color: Colors.blue[200]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Test Credentials:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text('Admin: username=admin, password=admin123'),
                  Text('Member: username=member, password=member123'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
