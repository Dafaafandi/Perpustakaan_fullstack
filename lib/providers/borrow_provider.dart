import 'package:flutter/foundation.dart';
import 'package:perpus_app/services/library_api_service.dart';

class BorrowingProvider with ChangeNotifier {
  final LibraryApiService _apiService = LibraryApiService();

  List<dynamic> _borrowings = [];
  Map<String, dynamic>? _selectedBorrowing;
  bool _isLoading = false;
  String _errorMessage = '';

  // Pagination
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalItems = 0;
  final int _itemsPerPage = 10;

  List<dynamic> get borrowings => _borrowings;
  Map<String, dynamic>? get selectedBorrowing => _selectedBorrowing;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  int get totalItems => _totalItems;
  int get itemsPerPage => _itemsPerPage;

  Future<void> fetchBorrowings({int page = 1}) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final borrowings = await _apiService.getAllBorrowings(
          page: page, perPage: _itemsPerPage);

      if (page == 1) {
        _borrowings = borrowings;
      } else {
        _borrowings.addAll(borrowings);
      }

      _currentPage = page;
      _totalItems = borrowings.length;
      _totalPages = borrowings.length < _itemsPerPage ? page : page + 1;

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

  Future<void> fetchBorrowingDetail(int id) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      _selectedBorrowing = await _apiService.getBorrowingDetail(id);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      _selectedBorrowing = null;
      notifyListeners();
      if (kDebugMode) {

      }
    }
  }

  Future<bool> createBorrowing(
      int bookId, int memberId, String borrowDate, String returnDate) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final success = await _apiService.createBorrowing(
          bookId, memberId, borrowDate, returnDate);

      if (success) {
        // Refresh the borrowings list
        await fetchBorrowings();
      } else {
        _errorMessage = 'Gagal membuat peminjaman';
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

  Future<bool> returnBook(int peminjamanId) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final success = await _apiService.returnBook(peminjamanId);

      if (success) {
        // Update local data or refresh list
        await fetchBorrowings();
      } else {
        _errorMessage = 'Gagal mengembalikan buku';
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

  // Search borrowings locally
  List<dynamic> searchBorrowings(String query) {
    if (query.isEmpty) return _borrowings;

    return _borrowings.where((borrowing) {
      if (borrowing is Map<String, dynamic>) {
        final bookTitle = borrowing['book']?['judul']?.toString() ?? '';
        final memberName = borrowing['member']?['name']?.toString() ?? '';
        final status = borrowing['status']?.toString() ?? '';

        return bookTitle.toLowerCase().contains(query.toLowerCase()) ||
            memberName.toLowerCase().contains(query.toLowerCase()) ||
            status.toLowerCase().contains(query.toLowerCase());
      }
      return false;
    }).toList();
  }

  // Filter borrowings by status
  List<dynamic> filterBorrowingsByStatus(String status) {
    if (status.isEmpty || status.toLowerCase() == 'all') return _borrowings;

    return _borrowings.where((borrowing) {
      if (borrowing is Map<String, dynamic>) {
        final borrowingStatus =
            borrowing['status']?.toString().toLowerCase() ?? '';
        return borrowingStatus == status.toLowerCase();
      }
      return false;
    }).toList();
  }

  // Get overdue borrowings
  List<dynamic> getOverdueBorrowings() {
    return _borrowings.where((borrowing) {
      if (borrowing is Map<String, dynamic>) {
        final status = borrowing['status']?.toString().toLowerCase() ?? '';
        final returnDate = borrowing['tanggal_pengembalian']?.toString();

        if (status == 'returned') return false;

        if (returnDate != null) {
          try {
            final expectedReturn = DateTime.parse(returnDate);
            return expectedReturn.isBefore(DateTime.now());
          } catch (e) {
            return false;
          }
        }
      }
      return false;
    }).toList();
  }

  void clearSelection() {
    _selectedBorrowing = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = '';
    notifyListeners();
  }
}
