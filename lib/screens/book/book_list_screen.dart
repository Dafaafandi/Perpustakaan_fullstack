import 'package:flutter/material.dart';
import 'package:perpus_app/api/api_service.dart';
import 'package:perpus_app/models/book.dart';
import 'package:perpus_app/screens/book/book_detail_screen.dart';
import 'package:perpus_app/screens/book/book_form_screen.dart';

class BookListScreen extends StatefulWidget {
  const BookListScreen({super.key});

  @override
  State<BookListScreen> createState() => _BookListScreenState();
}

class _BookListScreenState extends State<BookListScreen> {
  final ApiService _apiService = ApiService();
  List<Book> _books = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBooks();
  }

  Future<void> _loadBooks() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final books = await _apiService.getBooks();
      setState(() {
        _books = books;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat buku: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Daftar Buku')),
      body: RefreshIndicator(
        onRefresh: _loadBooks,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _buildBookListView(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // Navigasi ke halaman form dan TUNGGU hasilnya
          final result = await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const BookFormScreen()),
          );

          // JIKA kabar yang kembali adalah 'true', maka REFRESH daftarnya
          if (result == true) {
            _loadBooks(); // Memanggil ulang API untuk mendapatkan list terbaru
          }
        },
        tooltip: 'Tambah Buku',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBookListView() {
    if (_books.isEmpty) {
      return const Center(child: Text('Tidak ada buku yang ditemukan.'));
    }
    return ListView.builder(
      itemCount: _books.length,
      itemBuilder: (context, index) {
        final book = _books[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: Colors.indigo.shade100,
              child: Text(book.id.toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
            title: Text(book.judul, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(book.pengarang),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              // Navigasi ke halaman detail dan TUNGGU hasilnya
              final result = await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => BookDetailScreen(bookId: book.id)),
              );

              // JIKA kabar yang kembali adalah 'true' (setelah edit/delete), REFRESH
              if (result == true) {
                _loadBooks();
              }
            },
          ),
        );
      },
    );
  }
}