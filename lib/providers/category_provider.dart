import 'package:flutter/foundation.dart';
import 'package:perpus_app/models/category.dart' as CategoryModel;
import 'package:perpus_app/services/library_api_service.dart';

class CategoryProvider with ChangeNotifier {
  final LibraryApiService _apiService = LibraryApiService();

  List<CategoryModel.Category> _categories = [];
  CategoryModel.Category? _selectedCategory;
  bool _isLoading = false;
  String _errorMessage = '';

  List<CategoryModel.Category> get categories => _categories;
  CategoryModel.Category? get selectedCategory => _selectedCategory;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;

  Future<void> fetchCategories() async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      _categories = await _apiService.getAllCategories();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      if (kDebugMode) {

      }
    }
  }

  Future<void> fetchCategoryById(int id) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      _selectedCategory = await _apiService.getCategoryById(id);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      _selectedCategory = null;
      notifyListeners();
      if (kDebugMode) {

      }
    }
  }

  Future<bool> addCategory(String categoryName) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final success = await _apiService.addCategory(categoryName);

      if (success) {
        // Refresh the categories list
        await fetchCategories();
      } else {
        _errorMessage = 'Gagal menambahkan kategori';
      }

      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      if (kDebugMode) {

      }
      return false;
    }
  }

  Future<bool> updateCategory(int id, String categoryName) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final success = await _apiService.updateCategory(id, categoryName);

      if (success) {
        // Update local data
        final index = _categories.indexWhere((category) => category.id == id);
        if (index != -1) {
          _categories[index] = _categories[index].copyWith(name: categoryName);
        }

        if (_selectedCategory?.id == id) {
          _selectedCategory = _selectedCategory!.copyWith(name: categoryName);
        }
      } else {
        _errorMessage = 'Gagal memperbarui kategori';
      }

      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      if (kDebugMode) {

      }
      return false;
    }
  }

  Future<bool> deleteCategory(int id) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final success = await _apiService.deleteCategory(id);

      if (success) {
        // Remove from local list
        _categories.removeWhere((category) => category.id == id);
        if (_selectedCategory?.id == id) {
          _selectedCategory = null;
        }
      } else {
        _errorMessage = 'Gagal menghapus kategori';
      }

      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      if (kDebugMode) {

      }
      return false;
    }
  }

  // Search categories locally
  List<CategoryModel.Category> searchCategories(String query) {
    if (query.isEmpty) return _categories;

    return _categories.where((category) {
      return category.name.toLowerCase().contains(query.toLowerCase());
    }).toList();
  }

  // Get category by ID from local list
  CategoryModel.Category? getCategoryById(int id) {
    try {
      return _categories.firstWhere((category) => category.id == id);
    } catch (e) {
      return null;
    }
  }

  void clearSelection() {
    _selectedCategory = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = '';
    notifyListeners();
  }
}
