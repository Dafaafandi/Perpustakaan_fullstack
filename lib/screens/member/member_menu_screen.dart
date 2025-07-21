import 'package:flutter/material.dart';
import 'borrowed_books_screen.dart';
import 'books_list_screen_working.dart';

class MemberMenuScreen extends StatelessWidget {
  const MemberMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Menu Member'),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _buildMenuCard(
              context,
              'Cari Buku',
              Icons.search,
              Colors.blue,
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MemberBooksListScreen(),
                ),
              ),
            ),
            _buildMenuCard(
              context,
              'Buku Dipinjam',
              Icons.library_books,
              Colors.green,
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BorrowedBooksScreen(),
                ),
              ),
            ),
            _buildMenuCard(
              context,
              'Pinjam Buku',
              Icons.add_box,
              Colors.orange,
              () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Pilih buku dari daftar buku untuk dipinjam'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard(BuildContext context, String title, IconData icon,
      Color color, VoidCallback onTap) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
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
              Icon(icon, size: 48, color: Colors.white),
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
            ],
          ),
        ),
      ),
    );
  }
}
