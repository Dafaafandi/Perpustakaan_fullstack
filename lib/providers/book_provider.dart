import 'package:flutter/foundation.dart';
import 'package:perpus_app/models/book.dart';
import 'package:perpus_app/services/library_api_service.dart';

class BookProvider with ChangeNotifier {
  final LibraryApiService _apiService = LibraryApiService();

  List<Book> _books = [];
  Book? _selectedBook;
  bool _isLoading = false;
  String _errorMessage = '';

  // Pagination
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalItems = 0;
  final int _itemsPerPage = 10;

  List<Book> get books => _books;
  Book? get selectedBook => _selectedBook;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  int get totalItems => _totalItems;
  int get itemsPerPage => _itemsPerPage;

  Future<void> fetchBooks({int page = 1}) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final books =
          await _apiService.getAllBooks(page: page, perPage: _itemsPerPage);

      if (page == 1) {
        _books = books;
      } else {
        _books.addAll(books);
      }

      _currentPage = page;
      // Since API doesn't provide pagination info, we'll estimate
      _totalItems = books.length;
      _totalPages = books.length < _itemsPerPage ? page : page + 1;

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

  Future<void> fetchAllBooks() async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      _books = await _apiService.getAllBooks(page: 1, perPage: 100);
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

  Future<void> fetchBookById(int id) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      _selectedBook = await _apiService.getBookById(id);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      _selectedBook = null;
      notifyListeners();
      if (kDebugMode) {

      }
    }
  }

  Future<bool> addBook(Map<String, String> bookData) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final success = await _apiService.addBook(bookData);

      if (success) {
        // Refresh the books list
        await fetchAllBooks();
      } else {
        _errorMessage = 'Gagal menambahkan buku';
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

  Future<bool> updateBook(int id, Map<String, String> bookData) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final success = await _apiService.updateBook(id, bookData);

      if (success) {
        // Update local data
        final index = _books.indexWhere((book) => book.id == id);
        if (index != -1) {
          await fetchBookById(id); // Refresh the specific book
          if (_selectedBook != null) {
            _books[index] = _selectedBook!;
          }
        }
      } else {
        _errorMessage = 'Gagal memperbarui buku';
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

  Future<bool> deleteBook(int id) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final success = await _apiService.deleteBook(id);

      if (success) {
        // Remove from local list
        _books.removeWhere((book) => book.id == id);
        if (_selectedBook?.id == id) {
          _selectedBook = null;
        }
      } else {
        _errorMessage = 'Gagal menghapus buku';
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

  // Search books locally
  List<Book> searchBooks(String query) {
    if (query.isEmpty) return _books;

    return _books.where((book) {
      return book.judul.toLowerCase().contains(query.toLowerCase()) ||
          book.pengarang.toLowerCase().contains(query.toLowerCase()) ||
          book.category.name.toLowerCase().contains(query.toLowerCase());
    }).toList();
  }

  // Filter books by category
  List<Book> filterBooksByCategory(int categoryId) {
    if (categoryId == 0) return _books;
    return _books.where((book) => book.category.id == categoryId).toList();
  }

  // Export methods
  Future<String?> exportToPdf() async {
    try {
      return await _apiService.exportBooksToPdf();
    } catch (e) {
      _errorMessage = 'Gagal export ke PDF: $e';
      notifyListeners();
      return null;
    }
  }

  Future<String?> exportToExcel() async {
    try {
      return await _apiService.exportBooksToExcel();
    } catch (e) {
      _errorMessage = 'Gagal export ke Excel: $e';
      notifyListeners();
      return null;
    }
  }

  Future<String?> downloadTemplate() async {
    try {
      return await _apiService.downloadTemplate();
    } catch (e) {
      _errorMessage = 'Gagal download template: $e';
      notifyListeners();
      return null;
    }
  }

  Future<bool> importFromExcel(String filePath) async {
    _isLoading = true;
    notifyListeners();

    try {
      final success = await _apiService.importBooksFromExcel(filePath);

      if (success) {
        await fetchAllBooks(); // Refresh books after import
      } else {
        _errorMessage = 'Gagal import dari Excel';
      }

      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Error import: $e';
      notifyListeners();
      return false;
    }
  }

  void clearSelection() {
    _selectedBook = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = '';
    notifyListeners();
  }
}
