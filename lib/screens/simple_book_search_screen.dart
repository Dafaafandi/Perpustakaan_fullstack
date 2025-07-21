import 'package:flutter/material.dart';
import '../api/api_service.dart';
import '../models/book.dart';

class SimpleBookSearchScreen extends StatefulWidget {
  const SimpleBookSearchScreen({super.key});

  @override
  _SimpleBookSearchScreenState createState() => _SimpleBookSearchScreenState();
}

class _SimpleBookSearchScreenState extends State<SimpleBookSearchScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();

  List<Book> _books = [];
  bool _isLoading = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadBooks();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadBooks() async {
    setState(() => _isLoading = true);

    try {
      final result = await _apiService.getBooksPaginated(
        page: 1,
        perPage: 50,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
      );

      final List<Book> books = result['books'] ?? [];
      setState(() => _books = books);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat buku: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _onSearchChanged(String value) {
    setState(() => _searchQuery = value);
    _loadBooks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cari Buku'),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Cari buku berdasarkan judul atau penulis...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: _onSearchChanged,
            ),
          ),

          // Books List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _books.isEmpty
                    ? const Center(
                        child: Text(
                          'Tidak ada buku ditemukan',
                          style: TextStyle(fontSize: 16),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _books.length,
                        itemBuilder: (context, index) {
                          final book = _books[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: ListTile(
                              leading: const Icon(
                                Icons.book,
                                color: Colors.blue,
                                size: 40,
                              ),
                              title: Text(
                                book.judul,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Pengarang: ${book.pengarang}'),
                                  Text('Stok: ${book.stok}'),
                                  Text('Kategori: ${book.category.name}'),
                                ],
                              ),
                              trailing: book.stok > 0
                                  ? const Icon(
                                      Icons.check_circle,
                                      color: Colors.green,
                                    )
                                  : const Icon(
                                      Icons.cancel,
                                      color: Colors.red,
                                    ),
                              onTap: () {
                                // Show book details
                                _showBookDetails(book);
                              },
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  void _showBookDetails(Book book) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(book.judul),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Pengarang: ${book.pengarang}'),
            Text('Penerbit: ${book.penerbit}'),
            Text('Tahun Terbit: ${book.tahun}'),
            Text('Kategori: ${book.category.name}'),
            Text('Stok: ${book.stok}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Tutup'),
          ),
          if (book.stok > 0)
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Fitur peminjaman akan segera tersedia'),
                    backgroundColor: Colors.blue,
                  ),
                );
              },
              child: const Text('Pinjam'),
            ),
        ],
      ),
    );
  }
}
