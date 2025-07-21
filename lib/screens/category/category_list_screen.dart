import 'package:flutter/material.dart';
import 'package:perpus_app/api/api_service.dart';
import 'package:perpus_app/models/category.dart';
import 'package:perpus_app/screens/category/category_form_screen.dart';

class CategoryListScreen extends StatefulWidget {
  const CategoryListScreen({super.key});

  @override
  State<CategoryListScreen> createState() => _CategoryListScreenState();
}

class _CategoryListScreenState extends State<CategoryListScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<Category>> _categoriesFuture;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  void _loadCategories() {
    setState(() {
      _categoriesFuture = _apiService.getCategories();
    });
  }

  void _deleteCategory(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: const Text('Menghapus kategori akan berpengaruh pada buku terkait. Yakin ingin melanjutkan?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Hapus', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true) {
      final success = await _apiService.deleteCategory(id);
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kategori berhasil dihapus')));
          _loadCategories(); // Refresh list
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal menghapus kategori')));
        }
      }
    }
  }

  void _navigateToForm({Category? category}) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => CategoryFormScreen(category: category)),
    );
    if (result == true) {
      _loadCategories(); // Refresh list jika ada perubahan
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manajemen Kategori'),
      ),
      body: FutureBuilder<List<Category>>(
        future: _categoriesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Gagal memuat data: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Tidak ada kategori.'));
          }
          final categories = snapshot.data!;
          return ListView.builder(
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: ListTile(
                  title: Text(category.name),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _navigateToForm(category: category),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteCategory(category.id),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToForm(),
        tooltip: 'Tambah Kategori',
        child: const Icon(Icons.add),
      ),
    );
  }
}