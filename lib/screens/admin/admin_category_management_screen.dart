import 'package:flutter/material.dart';
import '../../api/api_service.dart';
import '../../models/category.dart' as CategoryModel;

class AdminCategoryManagementScreen extends StatefulWidget {
  const AdminCategoryManagementScreen({super.key});

  @override
  _AdminCategoryManagementScreenState createState() =>
      _AdminCategoryManagementScreenState();
}

class _AdminCategoryManagementScreenState
    extends State<AdminCategoryManagementScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();

  List<CategoryModel.Category> _categories = [];
  bool _isLoading = false;

  // Pagination variables
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalItems = 0;
  int _perPage = 10;

  // Filter variables
  String _sortBy = 'name';
  String _sortOrder = 'asc';
  bool? _hasBooks;

  // Filter options
  final List<String> _sortByOptions = ['name', 'created_at', 'books_count'];
  final List<String> _sortOrderOptions = ['asc', 'desc'];
  final List<String> _hasBooksOptions = ['Semua', 'Dengan Buku', 'Tanpa Buku'];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories({bool resetPage = false}) async {
    if (resetPage) {
      _currentPage = 1;
    }

    setState(() => _isLoading = true);

    try {

      final result = await _apiService.getCategoriesPaginated(
        page: _currentPage,
        perPage: _perPage,
        search:
            _searchController.text.isNotEmpty ? _searchController.text : null,
        sortBy: _sortBy,
        sortOrder: _sortOrder,
        hasBooks: _hasBooks,
      );

      if (mounted) {
        setState(() {
          _categories = result['categories'] ?? [];
          _currentPage = result['current_page'] ?? 1;
          _totalPages = result['total_pages'] ?? 1;
          _totalItems = result['total_items'] ?? 0;
          _perPage = result['per_page'] ?? 10;
        });

        print(
            '  Categories on this page: ${_categories.map((c) => c.name).join(', ')}');
      }
    } catch (e) {

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat kategori: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showAddCategoryDialog() {
    _showCategoryDialog();
  }

  void _showEditCategoryDialog(CategoryModel.Category category) {
    _showCategoryDialog(category: category);
  }

  void _showCategoryDialog({CategoryModel.Category? category}) {
    final nameController = TextEditingController(text: category?.name ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(category == null ? 'Tambah Kategori' : 'Edit Kategori'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Nama Kategori',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Nama kategori tidak boleh kosong')),
                );
                return;
              }

              try {
                bool success;
                if (category == null) {
                  // Create new category
                  success = await _apiService.addCategory(nameController.text);
                  if (success) {
                    Navigator.pop(context);
                    _loadCategories();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Kategori berhasil ditambahkan')),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Gagal menambahkan kategori')),
                    );
                  }
                } else {
                  // Update existing category
                  success = await _apiService.updateCategory(
                      category.id, nameController.text);
                  if (success) {
                    Navigator.pop(context);
                    _loadCategories();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Kategori berhasil diupdate')),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Gagal mengupdate kategori')),
                    );
                  }
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              }
            },
            child: Text(category == null ? 'Tambah' : 'Update'),
          ),
        ],
      ),
    );
  }

  void _deleteCategory(CategoryModel.Category category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Kategori'),
        content: Text(
            'Apakah Anda yakin ingin menghapus kategori "${category.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              try {
                final success = await _apiService.deleteCategory(category.id);
                Navigator.pop(context);
                if (success) {
                  _loadCategories();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Kategori berhasil dihapus')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Gagal menghapus kategori')),
                  );
                }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manajemen Kategori'),
        backgroundColor: Colors.red.shade600,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddCategoryDialog,
            tooltip: 'Tambah Kategori',
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
                labelText: 'Cari kategori...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                _loadCategories(resetPage: true);
              },
            ),
          ),

          // Filter Section
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ExpansionTile(
              title: const Text('Filter & Sorting'),
              leading: const Icon(Icons.filter_list),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _sortBy,
                              decoration: const InputDecoration(
                                labelText: 'Urutkan berdasarkan',
                                border: OutlineInputBorder(),
                              ),
                              items: _sortByOptions.map((option) {
                                String displayText = option;
                                switch (option) {
                                  case 'name':
                                    displayText = 'Nama';
                                    break;
                                  case 'created_at':
                                    displayText = 'Tanggal Dibuat';
                                    break;
                                  case 'books_count':
                                    displayText = 'Jumlah Buku';
                                    break;
                                }
                                return DropdownMenuItem<String>(
                                  value: option,
                                  child: Text(displayText),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() => _sortBy = value ?? 'name');
                                _loadCategories(resetPage: true);
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _sortOrder,
                              decoration: const InputDecoration(
                                labelText: 'Urutan',
                                border: OutlineInputBorder(),
                              ),
                              items: _sortOrderOptions.map((option) {
                                return DropdownMenuItem<String>(
                                  value: option,
                                  child: Text(option == 'asc' ? 'A-Z' : 'Z-A'),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() => _sortOrder = value ?? 'asc');
                                _loadCategories(resetPage: true);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _hasBooks == null
                            ? 'Semua'
                            : (_hasBooks! ? 'Dengan Buku' : 'Tanpa Buku'),
                        decoration: const InputDecoration(
                          labelText: 'Filter kategori',
                          border: OutlineInputBorder(),
                        ),
                        items: _hasBooksOptions.map((option) {
                          return DropdownMenuItem<String>(
                            value: option,
                            child: Text(option),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            if (value == 'Semua') {
                              _hasBooks = null;
                            } else if (value == 'Dengan Buku') {
                              _hasBooks = true;
                            } else {
                              _hasBooks = false;
                            }
                          });
                          _loadCategories(resetPage: true);
                        },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          ElevatedButton.icon(
                            onPressed: () {
                              setState(() {
                                _searchController.clear();
                                _sortBy = 'name';
                                _sortOrder = 'asc';
                                _hasBooks = null;
                              });
                              _loadCategories(resetPage: true);
                            },
                            icon: const Icon(Icons.clear),
                            label: const Text('Reset Filter'),
                          ),
                          const Spacer(),
                          Text(
                            'Total: $_totalItems kategori',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Categories List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _categories.isEmpty
                    ? const Center(
                        child: Text(
                          'Tidak ada kategori ditemukan',
                          style: TextStyle(fontSize: 16),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _categories.length,
                        itemBuilder: (context, index) {
                          final category = _categories[index];

                          return Card(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            child: ListTile(
                              title: Text(
                                category.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text('ID: ${category.id}'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit,
                                        color: Colors.blue),
                                    onPressed: () =>
                                        _showEditCategoryDialog(category),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete,
                                        color: Colors.red),
                                    onPressed: () => _deleteCategory(category),
                                  ),
                                ],
                              ),
                            ),
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
                    'Halaman $_currentPage dari $_totalPages ($_totalItems kategori)',
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
                                _loadCategories();
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
                                      _loadCategories();
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
                                _loadCategories();
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
