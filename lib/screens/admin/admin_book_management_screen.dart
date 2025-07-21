import 'package:flutter/material.dart';
import 'package:perpus_app/api/api_service.dart';
import 'package:perpus_app/models/book.dart';
import 'package:perpus_app/models/category.dart' as CategoryModel;

class AdminBookManagementScreen extends StatefulWidget {
  const AdminBookManagementScreen({super.key});

  @override
  State<AdminBookManagementScreen> createState() =>
      _AdminBookManagementScreenState();
}

class _AdminBookManagementScreenState extends State<AdminBookManagementScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();

  List<Book> _books = [];
  List<CategoryModel.Category> _categories = [];
  List<String> _authors = [];
  List<String> _publishers = [];
  List<int> _years = [];

  bool _isLoading = false;
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalItems = 0;
  int _perPage = 10;

  // Filter variables
  int? _selectedCategoryId;
  String? _selectedAuthor;
  String? _selectedPublisher;
  int? _selectedYear;
  String? _selectedStatus;
  String _sortBy = 'judul';
  String _sortOrder = 'asc';

  // Filter options
  final List<String> _statusOptions = ['Semua', 'Tersedia', 'Dipinjam'];
  final List<String> _sortByOptions = [
    'judul',
    'pengarang',
    'penerbit',
    'tahun'
  ];
  final List<String> _sortOrderOptions = ['asc', 'desc'];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);

    try {
      // Load filter options
      await Future.wait([
        _loadCategories(),
        _loadAuthors(),
        _loadPublishers(),
        _loadYears(),
      ]);

      // Load books
      await _loadBooks();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat data: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadBooks({bool resetPage = false}) async {
    if (resetPage) {
      _currentPage = 1;
    }

    setState(() => _isLoading = true);

    try {
      final result = await _apiService.getBooksPaginated(
        page: _currentPage,
        perPage: _perPage,
        search:
            _searchController.text.isNotEmpty ? _searchController.text : null,
        categoryId: _selectedCategoryId,
        author: _selectedAuthor,
        publisher: _selectedPublisher,
        year: _selectedYear,
        status: _selectedStatus,
        sortBy: _sortBy,
        sortOrder: _sortOrder,
      );

      if (mounted) {
        setState(() {
          _books = result['books'] ?? [];
          _currentPage = result['current_page'] ?? 1;
          _totalPages = result['total_pages'] ?? 1;
          _totalItems = result['total_items'] ?? 0;
          _perPage = result['per_page'] ?? 10;
        });
      }
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

  Future<void> _loadCategories() async {
    try {
      final categories = await _apiService.getCategories();
      setState(() {
        _categories = categories;
      });
    } catch (e) {}
  }

  Future<void> _loadAuthors() async {
    try {
      final authors = await _apiService.getAuthors();
      if (mounted) {
        setState(() => _authors = authors);
      }
    } catch (e) {}
  }

  Future<void> _loadPublishers() async {
    try {
      final publishers = await _apiService.getPublishers();
      if (mounted) {
        setState(() => _publishers = publishers);
      }
    } catch (e) {}
  }

  Future<void> _loadYears() async {
    try {
      final years = await _apiService.getPublicationYears();
      if (mounted) {
        setState(() => _years = years);
      }
    } catch (e) {}
  }

  void _showAddBookDialog() {
    _showBookDialog();
  }

  void _showEditBookDialog(Book book) {
    _showBookDialog(book: book);
  }

  void _showBookDialog({Book? book}) {
    final titleController = TextEditingController(text: book?.judul ?? '');
    final authorController = TextEditingController(text: book?.pengarang ?? '');
    final publisherController =
        TextEditingController(text: book?.penerbit ?? '');
    final yearController = TextEditingController(text: book?.tahun ?? '');
    final stockController =
        TextEditingController(text: book?.stok.toString() ?? '1');
    final pathController =
        TextEditingController(text: book?.path ?? ''); // Field baru
    int? selectedCategoryId = book?.category.id;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(book == null ? 'Tambah Buku' : 'Edit Buku'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Judul Buku',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: authorController,
                  decoration: const InputDecoration(
                    labelText: 'Pengarang',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: publisherController,
                  decoration: const InputDecoration(
                    labelText: 'Penerbit',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: yearController,
                  decoration: const InputDecoration(
                    labelText: 'Tahun',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: stockController,
                  decoration: const InputDecoration(
                    labelText: 'Stok',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: pathController,
                  decoration: const InputDecoration(
                    labelText: 'Path Gambar (contoh: storage/covers/file.jpg)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  value: selectedCategoryId,
                  decoration: const InputDecoration(
                    labelText: 'Kategori',
                    border: OutlineInputBorder(),
                  ),
                  items: _categories.map<DropdownMenuItem<int>>((category) {
                    return DropdownMenuItem<int>(
                      value: category.id,
                      child: Text(category.name),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setDialogState(() {
                      selectedCategoryId = value;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.isEmpty ||
                    authorController.text.isEmpty ||
                    selectedCategoryId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Mohon lengkapi semua field')),
                  );
                  return;
                }

                try {
                  final bookData = {
                    'judul': titleController.text,
                    'pengarang': authorController.text,
                    'penerbit': publisherController.text,
                    'tahun': yearController.text,
                    'category_id': selectedCategoryId.toString(),
                    'stok': stockController.text,
                    'path': pathController.text, // Kirim path gambar
                  };

                  bool success;
                  if (book == null) {
                    // Create new book
                    success = await _apiService.addBook(bookData);
                    if (success) {
                      Navigator.pop(context);
                      _loadBooks();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Buku berhasil ditambahkan')),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Gagal menambahkan buku')),
                      );
                    }
                  } else {
                    // Update existing book
                    success = await _apiService.updateBook(book.id, bookData);
                    if (success) {
                      Navigator.pop(context);
                      _loadBooks();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Buku berhasil diupdate')),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Gagal mengupdate buku')),
                      );
                    }
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              },
              child: Text(book == null ? 'Tambah' : 'Update'),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteBook(Book book) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Buku'),
        content:
            Text('Apakah Anda yakin ingin menghapus buku "${book.judul}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              try {
                await _apiService.deleteBook(book.id);
                Navigator.pop(context);
                _loadBooks();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Buku berhasil dihapus')),
                );
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              }
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  void _clearFilters() {
    setState(() {
      _selectedCategoryId = null;
      _selectedAuthor = null;
      _selectedPublisher = null;
      _selectedYear = null;
      _selectedStatus = null;
      _sortBy = 'judul';
      _sortOrder = 'asc';
      _searchController.clear();
    });
    _loadBooks(resetPage: true);
  }

  bool _hasActiveFilters() {
    return _selectedCategoryId != null ||
        _selectedAuthor != null ||
        _selectedPublisher != null ||
        _selectedYear != null ||
        (_selectedStatus != null && _selectedStatus != 'Semua') ||
        _searchController.text.isNotEmpty ||
        _sortBy != 'judul' ||
        _sortOrder != 'asc';
  }

  int _getActiveFilterCount() {
    int count = 0;
    if (_selectedCategoryId != null) count++;
    if (_selectedAuthor != null) count++;
    if (_selectedPublisher != null) count++;
    if (_selectedYear != null) count++;
    if (_selectedStatus != null && _selectedStatus != 'Semua') count++;
    if (_searchController.text.isNotEmpty) count++;
    if (_sortBy != 'judul' || _sortOrder != 'asc') count++;
    return count;
  }

  List<Widget> _buildActiveFilterChips() {
    List<Widget> chips = [];

    if (_selectedCategoryId != null) {
      final categoryName =
          _categories.firstWhere((c) => c.id == _selectedCategoryId).name;
      chips.add(_buildFilterChip('Kategori: $categoryName', () {
        setState(() => _selectedCategoryId = null);
        _loadBooks(resetPage: true);
      }));
    }

    if (_selectedAuthor != null) {
      chips.add(_buildFilterChip('Pengarang: $_selectedAuthor', () {
        setState(() => _selectedAuthor = null);
        _loadBooks(resetPage: true);
      }));
    }

    if (_selectedPublisher != null) {
      chips.add(_buildFilterChip('Penerbit: $_selectedPublisher', () {
        setState(() => _selectedPublisher = null);
        _loadBooks(resetPage: true);
      }));
    }

    if (_selectedYear != null) {
      chips.add(_buildFilterChip('Tahun: $_selectedYear', () {
        setState(() => _selectedYear = null);
        _loadBooks(resetPage: true);
      }));
    }

    if (_selectedStatus != null && _selectedStatus != 'Semua') {
      chips.add(_buildFilterChip('Status: $_selectedStatus', () {
        setState(() => _selectedStatus = null);
        _loadBooks(resetPage: true);
      }));
    }

    if (_searchController.text.isNotEmpty) {
      chips.add(_buildFilterChip('Pencarian: "${_searchController.text}"', () {
        setState(() => _searchController.clear());
        _loadBooks(resetPage: true);
      }));
    }

    if (_sortBy != 'judul' || _sortOrder != 'asc') {
      String sortLabel = _sortBy;
      switch (_sortBy) {
        case 'judul':
          sortLabel = 'Judul';
          break;
        case 'pengarang':
          sortLabel = 'Pengarang';
          break;
        case 'penerbit':
          sortLabel = 'Penerbit';
          break;
        case 'tahun':
          sortLabel = 'Tahun';
          break;
      }
      chips.add(_buildFilterChip(
          'Urutan: $sortLabel ${_sortOrder == 'asc' ? 'A-Z' : 'Z-A'}', () {
        setState(() {
          _sortBy = 'judul';
          _sortOrder = 'asc';
        });
        _loadBooks(resetPage: true);
      }));
    }

    return chips;
  }

  Widget _buildFilterChip(String label, VoidCallback onRemove) {
    return Chip(
      label: Text(
        label,
        style: const TextStyle(fontSize: 12),
      ),
      onDeleted: onRemove,
      deleteIcon: const Icon(Icons.close, size: 16),
      backgroundColor: Colors.blue.shade100,
      deleteIconColor: Colors.blue.shade700,
      labelStyle: TextStyle(color: Colors.blue.shade700),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manajemen Buku'),
        backgroundColor: Colors.red.shade600,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddBookDialog,
            tooltip: 'Tambah Buku',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Cari buku...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                _loadBooks(resetPage: true);
              },
            ),
          ),

          // Filter Section with Clear Active Filter Indicators
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ExpansionTile(
              title: Row(
                children: [
                  const Text('Filter & Sorting'),
                  const SizedBox(width: 8),
                  if (_hasActiveFilters())
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _getActiveFilterCount().toString(),
                        style:
                            const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                ],
              ),
              leading: Icon(
                Icons.filter_list,
                color: _hasActiveFilters() ? Colors.blue : null,
              ),
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Active filters summary
                      if (_hasActiveFilters())
                        Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            border: Border.all(color: Colors.blue.shade200),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.filter_alt,
                                      size: 16, color: Colors.blue.shade700),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Filter Aktif:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue.shade700,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 4,
                                children: _buildActiveFilterChips(),
                              ),
                            ],
                          ),
                        ),

                      // Row 1: Category and Author
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<int>(
                              value: _selectedCategoryId,
                              decoration: InputDecoration(
                                labelText: 'Kategori',
                                border: const OutlineInputBorder(),
                                filled: true,
                                fillColor: _selectedCategoryId != null
                                    ? Colors.blue.shade50
                                    : Colors.white,
                                prefixIcon: Icon(
                                  Icons.category,
                                  color: _selectedCategoryId != null
                                      ? Colors.blue
                                      : Colors.grey,
                                ),
                              ),
                              items: [
                                const DropdownMenuItem<int>(
                                  value: null,
                                  child: Text('Semua Kategori'),
                                ),
                                ..._categories
                                    .map<DropdownMenuItem<int>>((category) {
                                  return DropdownMenuItem<int>(
                                    value: category.id,
                                    child: Text(category.name),
                                  );
                                }).toList(),
                              ],
                              onChanged: (value) {
                                setState(() => _selectedCategoryId = value);
                                _loadBooks(resetPage: true);
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _selectedAuthor,
                              decoration: InputDecoration(
                                labelText: 'Pengarang',
                                border: const OutlineInputBorder(),
                                filled: true,
                                fillColor: _selectedAuthor != null
                                    ? Colors.blue.shade50
                                    : Colors.white,
                                prefixIcon: Icon(
                                  Icons.person,
                                  color: _selectedAuthor != null
                                      ? Colors.blue
                                      : Colors.grey,
                                ),
                              ),
                              items: [
                                const DropdownMenuItem<String>(
                                  value: null,
                                  child: Text('Semua Pengarang'),
                                ),
                                ..._authors.map((author) {
                                  return DropdownMenuItem<String>(
                                    value: author,
                                    child: Text(author),
                                  );
                                }).toList(),
                              ],
                              onChanged: (value) {
                                setState(() => _selectedAuthor = value);
                                _loadBooks(resetPage: true);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Row 2: Publisher and Year
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _selectedPublisher,
                              decoration: InputDecoration(
                                labelText: 'Penerbit',
                                border: const OutlineInputBorder(),
                                filled: true,
                                fillColor: _selectedPublisher != null
                                    ? Colors.blue.shade50
                                    : Colors.white,
                                prefixIcon: Icon(
                                  Icons.business,
                                  color: _selectedPublisher != null
                                      ? Colors.blue
                                      : Colors.grey,
                                ),
                              ),
                              items: [
                                const DropdownMenuItem<String>(
                                  value: null,
                                  child: Text('Semua Penerbit'),
                                ),
                                ..._publishers.map((publisher) {
                                  return DropdownMenuItem<String>(
                                    value: publisher,
                                    child: Text(publisher),
                                  );
                                }).toList(),
                              ],
                              onChanged: (value) {
                                setState(() => _selectedPublisher = value);
                                _loadBooks(resetPage: true);
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: DropdownButtonFormField<int>(
                              value: _selectedYear,
                              decoration: InputDecoration(
                                labelText: 'Tahun',
                                border: const OutlineInputBorder(),
                                filled: true,
                                fillColor: _selectedYear != null
                                    ? Colors.blue.shade50
                                    : Colors.white,
                                prefixIcon: Icon(
                                  Icons.calendar_today,
                                  color: _selectedYear != null
                                      ? Colors.blue
                                      : Colors.grey,
                                ),
                              ),
                              items: [
                                const DropdownMenuItem<int>(
                                  value: null,
                                  child: Text('Semua Tahun'),
                                ),
                                ..._years.map((year) {
                                  return DropdownMenuItem<int>(
                                    value: year,
                                    child: Text(year.toString()),
                                  );
                                }).toList(),
                              ],
                              onChanged: (value) {
                                setState(() => _selectedYear = value);
                                _loadBooks(resetPage: true);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Row 3: Status Filter (full width)
                      DropdownButtonFormField<String>(
                        value: _selectedStatus,
                        decoration: InputDecoration(
                          labelText: 'Status Ketersediaan',
                          border: const OutlineInputBorder(),
                          filled: true,
                          fillColor: (_selectedStatus != null &&
                                  _selectedStatus != 'Semua')
                              ? Colors.blue.shade50
                              : Colors.white,
                          prefixIcon: Icon(
                            Icons.inventory,
                            color: (_selectedStatus != null &&
                                    _selectedStatus != 'Semua')
                                ? Colors.blue
                                : Colors.grey,
                          ),
                        ),
                        items: _statusOptions.map((status) {
                          return DropdownMenuItem<String>(
                            value: status,
                            child: Row(
                              children: [
                                Icon(
                                  status == 'Tersedia'
                                      ? Icons.check_circle
                                      : status == 'Dipinjam'
                                          ? Icons.remove_circle
                                          : Icons.all_inclusive,
                                  size: 16,
                                  color: status == 'Tersedia'
                                      ? Colors.green
                                      : status == 'Dipinjam'
                                          ? Colors.red
                                          : Colors.grey,
                                ),
                                const SizedBox(width: 8),
                                Text(status),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => _selectedStatus = value);
                          _loadBooks(resetPage: true);
                        },
                      ),
                      const SizedBox(height: 16),

                      // Row 4: Sort options
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _sortBy,
                              decoration: InputDecoration(
                                labelText: 'Urutkan berdasarkan',
                                border: const OutlineInputBorder(),
                                filled: true,
                                fillColor: _sortBy != 'judul'
                                    ? Colors.orange.shade50
                                    : Colors.white,
                                prefixIcon: Icon(
                                  Icons.sort,
                                  color: _sortBy != 'judul'
                                      ? Colors.orange
                                      : Colors.grey,
                                ),
                              ),
                              items: _sortByOptions.map((option) {
                                String displayText = option;
                                IconData iconData = Icons.sort_by_alpha;
                                switch (option) {
                                  case 'judul':
                                    displayText = 'Judul';
                                    iconData = Icons.title;
                                    break;
                                  case 'pengarang':
                                    displayText = 'Pengarang';
                                    iconData = Icons.person;
                                    break;
                                  case 'penerbit':
                                    displayText = 'Penerbit';
                                    iconData = Icons.business;
                                    break;
                                  case 'tahun':
                                    displayText = 'Tahun';
                                    iconData = Icons.calendar_today;
                                    break;
                                }
                                return DropdownMenuItem<String>(
                                  value: option,
                                  child: Row(
                                    children: [
                                      Icon(iconData, size: 16),
                                      const SizedBox(width: 8),
                                      Text(displayText),
                                    ],
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() => _sortBy = value ?? 'judul');
                                _loadBooks(resetPage: true);
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _sortOrder,
                              decoration: InputDecoration(
                                labelText: 'Urutan',
                                border: const OutlineInputBorder(),
                                filled: true,
                                fillColor: _sortOrder != 'asc'
                                    ? Colors.orange.shade50
                                    : Colors.white,
                                prefixIcon: Icon(
                                  _sortOrder == 'asc'
                                      ? Icons.arrow_upward
                                      : Icons.arrow_downward,
                                  color: _sortOrder != 'asc'
                                      ? Colors.orange
                                      : Colors.grey,
                                ),
                              ),
                              items: _sortOrderOptions.map((option) {
                                return DropdownMenuItem<String>(
                                  value: option,
                                  child: Row(
                                    children: [
                                      Icon(
                                        option == 'asc'
                                            ? Icons.arrow_upward
                                            : Icons.arrow_downward,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(option == 'asc'
                                          ? 'A-Z (Naik)'
                                          : 'Z-A (Turun)'),
                                    ],
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() => _sortOrder = value ?? 'asc');
                                _loadBooks(resetPage: true);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Row 5: Reset and info with better styling
                      Row(
                        children: [
                          ElevatedButton.icon(
                            onPressed: _clearFilters,
                            icon: const Icon(Icons.clear_all),
                            label: const Text('Reset Semua Filter'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.shade50,
                              foregroundColor: Colors.red.shade700,
                              side: BorderSide(color: Colors.red.shade200),
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              border: Border.all(color: Colors.green.shade200),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.book,
                                    size: 16, color: Colors.green.shade700),
                                const SizedBox(width: 4),
                                Text(
                                  'Total: $_totalItems buku',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
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
                        padding: const EdgeInsets.all(8),
                        itemCount: _books.length,
                        itemBuilder: (context, index) {
                          final book = _books[index];
                          return _BookListItem(
                            book: book,
                            onEdit: () => _showEditBookDialog(book),
                            onDelete: () => _deleteBook(book),
                          );
                        },
                      ),
          ),

          // Pagination Controls
          if (_totalPages > 1)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                border: Border(top: BorderSide(color: Colors.grey.shade300)),
              ),
              child: Column(
                children: [
                  Text(
                    'Halaman $_currentPage dari $_totalPages ($_totalItems buku)',
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _currentPage > 1
                            ? () {
                                setState(() => _currentPage--);
                                _loadBooks();
                              }
                            : null,
                        icon: const Icon(Icons.chevron_left),
                        label: const Text('Sebelumnya'),
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              _totalPages > 7 ? 7 : _totalPages,
                              (index) {
                                int pageNumber;
                                if (_totalPages <= 7) {
                                  pageNumber = index + 1;
                                } else if (_currentPage <= 4) {
                                  pageNumber = index + 1;
                                } else if (_currentPage > _totalPages - 4) {
                                  pageNumber = _totalPages - 6 + index;
                                } else {
                                  pageNumber = _currentPage - 3 + index;
                                }

                                return Container(
                                  margin:
                                      const EdgeInsets.symmetric(horizontal: 2),
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          pageNumber == _currentPage
                                              ? Colors.red.shade600
                                              : Colors.grey.shade300,
                                      foregroundColor:
                                          pageNumber == _currentPage
                                              ? Colors.white
                                              : Colors.black,
                                      minimumSize: const Size(40, 36),
                                      padding: EdgeInsets.zero,
                                    ),
                                    onPressed: () {
                                      setState(() => _currentPage = pageNumber);
                                      _loadBooks();
                                    },
                                    child: Text('$pageNumber'),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _currentPage < _totalPages
                            ? () {
                                setState(() => _currentPage++);
                                _loadBooks();
                              }
                            : null,
                        icon: const Icon(Icons.chevron_right),
                        label: const Text('Selanjutnya'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// **BARU:** Widget terpisah untuk menampilkan item buku di sisi admin
class _BookListItem extends StatelessWidget {
  final Book book;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _BookListItem({
    required this.book,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Gambar Sampul
            SizedBox(
              width: 80,
              height: 110,
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
                              child: CircularProgressIndicator(),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[200],
                            child: const Center(
                              child: Icon(Icons.error, color: Colors.red),
                            ),
                          );
                        },
                      )
                    : Container(
                        color: Colors.grey[200],
                        child: const Center(
                          child: Icon(Icons.book, color: Colors.grey),
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 16),
            // Detail Buku
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.judul,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text('oleh ${book.pengarang}',
                      style: TextStyle(color: Colors.grey[700])),
                  const SizedBox(height: 8),
                  Text('Kategori: ${book.category.name}'),
                  Text('Stok: ${book.stok}'),
                  Text('Penerbit: ${book.penerbit} (${book.tahun})'),
                ],
              ),
            ),
            // Tombol Aksi
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: onEdit,
                  tooltip: 'Edit',
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: onDelete,
                  tooltip: 'Hapus',
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
