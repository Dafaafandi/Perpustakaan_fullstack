import 'package:flutter/material.dart';
import '../../api/api_service.dart';
import '../../models/book.dart';
import '../../models/category.dart' as CategoryModel;

class MemberBooksListScreen extends StatefulWidget {
  const MemberBooksListScreen({super.key});

  @override
  _MemberBooksListScreenState createState() => _MemberBooksListScreenState();
}

class _MemberBooksListScreenState extends State<MemberBooksListScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Book> _books = [];
  List<CategoryModel.Category> _categories = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMoreData = true;
  int _currentPage = 1;
  int _perPage = 10;

  // Filter variables
  String _searchQuery = '';
  int? _selectedCategoryId;
  String _sortBy = 'judul';
  String _sortOrder = 'asc';

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _hasMoreData) {
      _loadMoreBooks();
    }
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load categories
      _categories = await _apiService.getCategories();

      // Load first page of books
      await _loadBooks(reset: true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadBooks({bool reset = false}) async {
    if (reset) {
      _currentPage = 1;
      _books.clear();
      _hasMoreData = true;
    }

    try {
      final result = await _apiService.getBooksPaginated(
        page: _currentPage,
        perPage: _perPage,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
        categoryId: _selectedCategoryId,
        sortBy: _sortBy,
        sortOrder: _sortOrder,
      );

      final List<Book> newBooks = result['books'] ?? [];
      final int totalPages = result['total_pages'] ?? 1;

      if (mounted) {
        setState(() {
          if (reset) {
            _books = newBooks;
          } else {
            _books.addAll(newBooks);
          }
          _hasMoreData = _currentPage < totalPages;
          _currentPage++;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading books: $e')),
        );
      }
    }
  }

  Future<void> _loadMoreBooks() async {
    if (_isLoadingMore || !_hasMoreData) return;

    setState(() {
      _isLoadingMore = true;
    });

    await _loadBooks();

    setState(() {
      _isLoadingMore = false;
    });
  }

  void _onSearchChanged(String query) {
    _searchQuery = query;
    _loadBooks(reset: true);
  }

  void _onCategoryChanged(int? categoryId) {
    _selectedCategoryId = categoryId;
    _loadBooks(reset: true);
  }

  void _onSortChanged(String sortBy, String sortOrder) {
    _sortBy = sortBy;
    _sortOrder = sortOrder;
    _loadBooks(reset: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cari Buku'),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search and Filter Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade600,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                // Search Bar
                TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Cari judul, pengarang, atau penerbit...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _onSearchChanged('');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Filter Row
                Row(
                  children: [
                    // Category Filter
                    Expanded(
                      child: DropdownButtonFormField<int?>(
                        value: _selectedCategoryId,
                        onChanged: _onCategoryChanged,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        items: [
                          const DropdownMenuItem<int?>(
                            value: null,
                            child: Text('Semua Kategori'),
                          ),
                          ..._categories.map((category) {
                            return DropdownMenuItem<int?>(
                              value: category.id,
                              child: Text(category.name),
                            );
                          }).toList(),
                        ],
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Sort Button
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: PopupMenuButton<String>(
                        icon: const Icon(Icons.sort),
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'judul_asc',
                            child: Text('Judul A-Z'),
                          ),
                          const PopupMenuItem(
                            value: 'judul_desc',
                            child: Text('Judul Z-A'),
                          ),
                          const PopupMenuItem(
                            value: 'pengarang_asc',
                            child: Text('Pengarang A-Z'),
                          ),
                          const PopupMenuItem(
                            value: 'tahun_desc',
                            child: Text('Tahun Terbaru'),
                          ),
                        ],
                        onSelected: (value) {
                          final parts = value.split('_');
                          _onSortChanged(parts[0], parts[1]);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Books List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _books.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: () => _loadBooks(reset: true),
                        child: ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(16),
                          itemCount: _books.length + (_isLoadingMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index >= _books.length) {
                              return const Padding(
                                padding: EdgeInsets.all(16),
                                child:
                                    Center(child: CircularProgressIndicator()),
                              );
                            }
                            return _buildBookCard(_books[index]);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty
                ? 'Tidak ada buku yang ditemukan'
                : 'Belum ada data buku',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty
                ? 'Coba kata kunci lain'
                : 'Data akan muncul setelah admin menambahkan buku',
            style: TextStyle(
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookCard(Book book) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          // Navigasi ke detail buku jika ada
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Book Cover
              SizedBox(
                width: 80,
                height: 120,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: book.coverUrl != null && book.coverUrl!.isNotEmpty
                      ? Image.network(
                          book.coverUrl!,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              color: Colors.grey[200],
                              child: const Center(
                                child:
                                    CircularProgressIndicator(strokeWidth: 2.0),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[200],
                              child: const Center(
                                child: Icon(Icons.book_outlined,
                                    color: Colors.grey),
                              ),
                            );
                          },
                        )
                      : Container(
                          color: Colors.grey[200],
                          child: const Center(
                            child:
                                Icon(Icons.book_outlined, color: Colors.grey),
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 16),
              // Book Info
              Expanded(
                child: SizedBox(
                  height: 120,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            book.judul,
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text('oleh ${book.pengarang}',
                              style: TextStyle(
                                  color: Colors.grey.shade600, fontSize: 14)),
                          Text(book.penerbit,
                              style: TextStyle(
                                  color: Colors.grey.shade600, fontSize: 13)),
                          Text('Tahun: ${book.tahun}',
                              style: TextStyle(
                                  color: Colors.grey.shade600, fontSize: 13)),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: book.stok > 0
                                  ? Colors.green.shade100
                                  : Colors.red.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              book.stok > 0 ? 'Stok: ${book.stok}' : 'Habis',
                              style: TextStyle(
                                color: book.stok > 0
                                    ? Colors.green.shade800
                                    : Colors.red.shade800,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          if (book.stok > 0)
                            ElevatedButton(
                              onPressed: () => _showBorrowDialog(book),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue.shade600,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                              ),
                              child: const Text('Pinjam'),
                            )
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showBorrowDialog(Book book) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Pinjam Buku'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Apakah Anda yakin ingin meminjam buku "${book.judul}"?'),
              const SizedBox(height: 8),
              Text(
                'Batas peminjaman: 14 hari dari tanggal peminjaman',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _borrowBook(book);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                foregroundColor: Colors.white,
              ),
              child: const Text('Pinjam'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _borrowBook(Book book) async {
    // Get current user ID
    int? userId = await _apiService.getUserId();

    // If user ID is null, try to get from user profile
    if (userId == null) {
      try {
        final profile = await _apiService.getUserProfile();
        if (profile != null && profile['id'] != null) {
          userId = profile['id'];
          // Save the user ID for future use
          await _apiService.saveUserId(userId!);
        }
      } catch (e) {}
    }

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Anda harus login terlebih dahulu. Silakan logout dan login kembali.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Show date picker dialog for borrow and return dates
    final borrowDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      helpText: 'Pilih Tanggal Peminjaman',
    );

    if (borrowDate == null) return;

    // Pick return date (must be after borrow date)
    final returnDate = await showDatePicker(
      context: context,
      initialDate: borrowDate.add(const Duration(days: 7)),
      firstDate: borrowDate.add(const Duration(days: 1)),
      lastDate: borrowDate.add(const Duration(days: 30)),
      helpText: 'Pilih Tanggal Pengembalian',
    );

    if (returnDate == null) return;

    // Format dates for display
    final borrowDateStr =
        '${borrowDate.day}/${borrowDate.month}/${borrowDate.year}';
    final returnDateStr =
        '${returnDate.day}/${returnDate.month}/${returnDate.year}';

    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Peminjaman'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Buku: ${book.judul}'),
            const SizedBox(height: 8),
            Text('Tanggal Pinjam: $borrowDateStr'),
            const SizedBox(height: 4),
            Text('Tanggal Kembali: $returnDateStr'),
            const SizedBox(height: 12),
            const Text('Apakah Anda yakin ingin meminjam buku ini?'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Ya, Pinjam'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Meminjam buku...'),
          ],
        ),
      ),
    );

    try {
      // Format dates for API (YYYY-MM-DD)
      final String borrowDateApi =
          '${borrowDate.year}-${borrowDate.month.toString().padLeft(2, '0')}-${borrowDate.day.toString().padLeft(2, '0')}';
      final String returnDateApi =
          '${returnDate.year}-${returnDate.month.toString().padLeft(2, '0')}-${returnDate.day.toString().padLeft(2, '0')}';

      // Call the borrowBook API
      final success = await _apiService.borrowBook(
        book.id,
        userId,
        borrowDateApi,
        returnDateApi,
      );

      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Berhasil meminjam buku "${book.judul}"'),
              backgroundColor: Colors.green,
            ),
          );

          // Refresh the books list to update stock
          _loadBooks(reset: true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Gagal meminjam buku. Silakan coba lagi.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal meminjam buku: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
