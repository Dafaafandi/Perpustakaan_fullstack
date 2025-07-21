import 'package:flutter/material.dart';
import 'member/borrowed_books_screen.dart';
import 'member/member_dashboard_screen.dart';
import 'member/books_list_screen_working.dart';
import 'package:perpus_app/providers/theme_provider.dart';

class TestMemberScreen extends StatelessWidget {
  const TestMemberScreen({super.key}); // Fixed: removed duplicate 'const'

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Member Features'),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        actions: const [
          ThemeToggleButton(),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Library Member Features',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // Feature Cards
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _buildFeatureCard(
                    context,
                    'Dashboard',
                    Icons.dashboard,
                    Colors.indigo,
                    'Lihat statistik dan dashboard member',
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MemberDashboardScreen(),
                        ),
                      );
                    },
                  ),
                  _buildFeatureCard(
                    context,
                    'Cari Buku',
                    Icons.search,
                    Colors.blue,
                    'Browse dan cari buku dengan infinite scroll',
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MemberBooksListScreen(),
                        ),
                      );
                    },
                  ),
                  _buildFeatureCard(
                    context,
                    'Buku Dipinjam',
                    Icons.library_books,
                    Colors.green,
                    'Lihat dan kembalikan buku yang dipinjam',
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BorrowedBooksScreen(),
                        ),
                      );
                    },
                  ),
                  _buildFeatureCard(
                    context,
                    'Status',
                    Icons.check_circle,
                    Colors.orange,
                    'Refresh data dan status member',
                    () {
                      // Kembali ke dashboard untuk refresh data
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content:
                              Text('Kembali ke dashboard untuk refresh data'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                  ),
                  _buildFeatureCard(
                    context,
                    'Info',
                    Icons.info,
                    Colors.purple,
                    'Bantuan dan informasi aplikasi',
                    () => _showInfoDialog(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard(BuildContext context, String title, IconData icon,
      Color color, String description, VoidCallback onTap) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [color.withValues(alpha: 0.7), color],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: Colors.white),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white70,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('📚 Bantuan Member'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Cara menggunakan aplikasi:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('• Cari Buku: Browse koleksi buku perpustakaan'),
            Text('• Buku Dipinjam: Kelola buku yang sedang dipinjam'),
            Text('• Status: Refresh data terbaru'),
            Text('• Info: Bantuan penggunaan aplikasi'),
            SizedBox(height: 12),
            Text('Tips:', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 4),
            Text('- Gunakan fitur pencarian untuk menemukan buku'),
            Text('- Cek status peminjaman secara berkala'),
            Text('- Kembalikan buku tepat waktu'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }
}
