import 'package:flutter/material.dart';
import 'package:perpus_app/api/api_service.dart';
import 'package:perpus_app/screens/auth/login_screen.dart';
import 'package:perpus_app/screens/book/book_list_screen.dart';
import 'package:perpus_app/screens/category/category_list_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ApiService _apiService = ApiService();
  String? _userName;

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  void _loadUserName() async {
    final name = await _apiService.getUserName();
    setState(() {
      _userName = name;
    });
  }

  void _logout() async {
    await _apiService.logout();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout, tooltip: 'Logout'),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Card(
            color: Colors.indigo.shade50,
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Selamat Datang,', style: TextStyle(fontSize: 18, color: Colors.grey.shade700)),
                  const SizedBox(height: 4),
                  _userName == null
                      ? const SizedBox(height: 28, width: 200, child: LinearProgressIndicator())
                      : Text(_userName!, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.indigo)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text('Menu Utama', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          GridView.count(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            children: [
              _buildDashboardItem(context, icon: Icons.menu_book, label: 'Manajemen Buku', onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const BookListScreen()))),
              _buildDashboardItem(context, icon: Icons.category, label: 'Kategori', onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CategoryListScreen()))),
              _buildDashboardItem(context, icon: Icons.person_search, label: 'Anggota', onTap: () {}),
              _buildDashboardItem(context, icon: Icons.bar_chart, label: 'Laporan', onTap: () {}),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardItem(BuildContext context, {required IconData icon, required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: Theme.of(context).primaryColor),
            const SizedBox(height: 12),
            Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}