import 'package:flutter/material.dart';
import '../../api/api_service.dart';
import '../../models/borrowing.dart';

class AdminBorrowingManagementScreen extends StatefulWidget {
  const AdminBorrowingManagementScreen({super.key});

  @override
  _AdminBorrowingManagementScreenState createState() =>
      _AdminBorrowingManagementScreenState();
}

class _AdminBorrowingManagementScreenState
    extends State<AdminBorrowingManagementScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  List<Borrowing> _allBorrowings = [];
  List<Borrowing> _displayedBorrowings = [];
  String _currentFilter = 'all'; // 'all', 'active', 'overdue', 'returned'

  // Pagination variables
  int _currentPage = 1;
  int _itemsPerPage = 20;
  int _totalPages = 1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadBorrowings();
    });
  }

  Future<void> _loadBorrowings() async {
    setState(() => _isLoading = true);
    try {
      // Get all borrowings from API
      final borrowings = await _apiService.fetchAllBorrowingPages();
      setState(() {
        _allBorrowings = borrowings;
        _applyFilterAndPagination();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading borrowings: $e')),
        );
      }
      // Fallback to empty list if API call fails
      setState(() {
        _allBorrowings = [];
        _displayedBorrowings = [];
        _totalPages = 1;
        _currentPage = 1;
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _applyFilterAndPagination() {
    List<Borrowing> filteredBorrowings = _allBorrowings;

    // Debug log untuk melihat semua status

    Map<String, int> statusCount = {};
    for (var b in _allBorrowings) {
      statusCount[b.status] = (statusCount[b.status] ?? 0) + 1;
    }

    // Apply filter
    switch (_currentFilter) {
      case 'active':
        // PERBAIKAN: Filter aktif untuk yang BELUM dikembalikan
        filteredBorrowings = _allBorrowings.where((b) => _isActive(b)).toList();
        print(
            'DEBUG: Active filter - found ${filteredBorrowings.length} borrowings (all not returned)');
        break;
      case 'overdue':
        // PERBAIKAN: Filter terlambat konsisten dengan display logic
        filteredBorrowings =
            _allBorrowings.where((b) => _isActuallyOverdue(b)).toList();
        print(
            'DEBUG: Overdue filter - found ${filteredBorrowings.length} borrowings (isOverdue OR status=overdue)');
        break;
      case 'returned':
        // Filter kembali: semua yang sudah dikembalikan (termasuk yang dulu terlambat)
        filteredBorrowings =
            _allBorrowings.where((b) => b.status == 'returned').toList();
        print(
            'DEBUG: Returned filter - found ${filteredBorrowings.length} borrowings (all returned books)');
        break;
      default: // 'all'
        filteredBorrowings = _allBorrowings;
        print(
            'DEBUG: All filter - found ${filteredBorrowings.length} borrowings');
    }

    _totalPages = (filteredBorrowings.length / _itemsPerPage).ceil();
    if (_totalPages == 0) _totalPages = 1;

    // Ensure current page is valid
    if (_currentPage > _totalPages) _currentPage = _totalPages;
    if (_currentPage < 1) _currentPage = 1;

    int startIndex = (_currentPage - 1) * _itemsPerPage;
    int endIndex = startIndex + _itemsPerPage;
    if (endIndex > filteredBorrowings.length)
      endIndex = filteredBorrowings.length;

    _displayedBorrowings = filteredBorrowings.sublist(
        startIndex, endIndex.clamp(0, filteredBorrowings.length));
  }

  void _setFilter(String filter) {
    setState(() {
      _currentFilter = filter;
      _currentPage = 1; // Reset to first page when changing filter
      _applyFilterAndPagination();
    });
  }

  void _goToNextPage() {
    if (_currentPage < _totalPages) {
      setState(() {
        _currentPage++;
        _applyFilterAndPagination();
      });
    }
  }

  void _goToPreviousPage() {
    if (_currentPage > 1) {
      setState(() {
        _currentPage--;
        _applyFilterAndPagination();
      });
    }
  }

  void _goToPage(int page) {
    if (page >= 1 && page <= _totalPages) {
      setState(() {
        _currentPage = page;
        _applyFilterAndPagination();
      });
    }
  }

  void _showBorrowingDetails(Borrowing borrowing) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Detail Peminjaman'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Member: ${borrowing.member?.name ?? 'Unknown Member'}'),
            const SizedBox(height: 8),
            Text('Buku: ${borrowing.book?.judul ?? 'Unknown Book'}'),
            const SizedBox(height: 8),
            Text('Tanggal Pinjam: ${_formatDate(borrowing.borrowDate)}'),
            const SizedBox(height: 8),
            Text('Tanggal Kembali: ${_getReturnDateText(borrowing)}'),
            const SizedBox(height: 8),
            Text('Status: ${borrowing.status}'),
            if (borrowing.status == 'overdue')
              const Text(
                'TERLAMBAT!',
                style:
                    TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _getReturnDateText(Borrowing borrowing) {
    // If status is returned, check for actual return date
    if (borrowing.status == 'returned') {
      if (borrowing.actualReturnDate != null) {
        return _formatDate(borrowing.actualReturnDate!);
      } else {
        // If status is returned but no specific date, show generic returned message
        return 'Sudah dikembalikan';
      }
    } else {
      // For books not yet returned
      return 'Belum dikembalikan';
    }
  }

  String _getStatusDisplayText(Borrowing borrowing) {
    // PERBAIKAN: Sinkronkan status display dengan logika terlambat
    if (borrowing.status == 'returned') {
      return 'Dikembalikan';
    } else if (borrowing.isOverdue || borrowing.status == 'overdue') {
      return 'Terlambat';
    } else if (borrowing.status == 'borrowed') {
      return 'Dipinjam';
    } else {
      return borrowing.status.toUpperCase();
    }
  }

  Color _getBorrowingColor(Borrowing borrowing) {
    // PERBAIKAN: Konsisten antara warna dan status
    if (borrowing.status == 'returned') {
      return Colors.green; // Sudah dikembalikan
    } else if (borrowing.isOverdue || borrowing.status == 'overdue') {
      return Colors.red; // Terlambat (berdasarkan tanggal atau status API)
    } else {
      return Colors.blue; // Dipinjam normal
    }
  }

  IconData _getBorrowingIcon(Borrowing borrowing) {
    // PERBAIKAN: Konsisten antara icon dan status
    if (borrowing.status == 'returned') {
      return Icons.check; // Sudah dikembalikan
    } else if (borrowing.isOverdue || borrowing.status == 'overdue') {
      return Icons.warning; // Terlambat
    } else {
      return Icons.book; // Dipinjam normal
    }
  }

  // Helper method untuk mengecek apakah borrowing benar-benar terlambat
  bool _isActuallyOverdue(Borrowing borrowing) {
    return borrowing.status != 'returned' &&
        (borrowing.isOverdue || borrowing.status == 'overdue');
  }

  // Helper method untuk mengecek apakah borrowing masih aktif
  bool _isActive(Borrowing borrowing) {
    return borrowing.status != 'returned';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manajemen Peminjaman'),
        backgroundColor: Colors.red.shade600,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadBorrowings,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter tabs
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _setFilter('all'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _currentFilter == 'all'
                          ? Colors.blue
                          : Colors.grey.shade300,
                      foregroundColor:
                          _currentFilter == 'all' ? Colors.white : Colors.black,
                    ),
                    child: const Text('Semua'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _setFilter('active'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _currentFilter == 'active'
                          ? Colors.blue
                          : Colors.grey.shade300,
                      foregroundColor: _currentFilter == 'active'
                          ? Colors.white
                          : Colors.black,
                    ),
                    child: const Text('Aktif'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _setFilter('overdue'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _currentFilter == 'overdue'
                          ? Colors.red
                          : Colors.grey.shade300,
                      foregroundColor: _currentFilter == 'overdue'
                          ? Colors.white
                          : Colors.black,
                    ),
                    child: const Text('Terlambat'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _setFilter('returned'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _currentFilter == 'returned'
                          ? Colors.green
                          : Colors.grey.shade300,
                      foregroundColor: _currentFilter == 'returned'
                          ? Colors.white
                          : Colors.black,
                    ),
                    child: const Text('Kembali'),
                  ),
                ),
              ],
            ),
          ),

          // Borrowings List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _displayedBorrowings.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.library_books,
                                size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'Tidak ada data peminjaman',
                              style:
                                  TextStyle(fontSize: 16, color: Colors.grey),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Coba filter lain atau refresh data',
                              style:
                                  TextStyle(fontSize: 14, color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : Column(
                        children: [
                          // Borrowings List
                          Expanded(
                            child: ListView.builder(
                              itemCount: _displayedBorrowings.length,
                              itemBuilder: (context, index) {
                                final borrowing = _displayedBorrowings[index];

                                return Card(
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor:
                                          _getBorrowingColor(borrowing),
                                      child: Icon(
                                        _getBorrowingIcon(borrowing),
                                        color: Colors.white,
                                      ),
                                    ),
                                    title: Text(
                                      borrowing.book?.judul ?? 'Unknown Book',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                            'Member: ${borrowing.member?.name ?? 'Unknown Member'}'),
                                        Text(
                                            'Pinjam: ${_formatDate(borrowing.borrowDate)}'),
                                        Text(
                                            'Kembali: ${_getReturnDateText(borrowing)}'),
                                        Text(
                                          'Status: ${_getStatusDisplayText(borrowing)}',
                                          style: TextStyle(
                                            color:
                                                _getBorrowingColor(borrowing),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.info,
                                          color: Colors.blue),
                                      onPressed: () =>
                                          _showBorrowingDetails(borrowing),
                                    ),
                                    isThreeLine: true,
                                  ),
                                );
                              },
                            ),
                          ),

                          // Pagination Controls
                          if (_allBorrowings.isNotEmpty)
                            _buildPaginationControls(),
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaginationControls() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Column(
        children: [
          // Page info with filter info
          Text(
            'Halaman $_currentPage dari $_totalPages | Filter: ${_getFilterDisplayName()} (${_allBorrowings.length} total record)',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),

          // Navigation buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Previous button
              ElevatedButton.icon(
                onPressed: _currentPage > 1 ? _goToPreviousPage : null,
                icon: const Icon(Icons.chevron_left),
                label: const Text('Previous'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade300,
                  disabledForegroundColor: Colors.grey.shade600,
                ),
              ),

              // Page numbers
              Row(
                children: _buildPageNumbers(),
              ),

              // Next button
              ElevatedButton.icon(
                onPressed: _currentPage < _totalPages ? _goToNextPage : null,
                icon: const Icon(Icons.chevron_right),
                label: const Text('Next'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade300,
                  disabledForegroundColor: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getFilterDisplayName() {
    switch (_currentFilter) {
      case 'active':
        return 'Aktif';
      case 'overdue':
        return 'Terlambat';
      case 'returned':
        return 'Dikembalikan';
      default:
        return 'Semua';
    }
  }

  List<Widget> _buildPageNumbers() {
    List<Widget> pageNumbers = [];

    // Show page numbers around current page
    int start = (_currentPage - 2).clamp(1, _totalPages);
    int end = (_currentPage + 2).clamp(1, _totalPages);

    // Always show first page
    if (start > 1) {
      pageNumbers.add(_buildPageButton(1));
      if (start > 2) {
        pageNumbers.add(const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: Text('...', style: TextStyle(color: Colors.grey)),
        ));
      }
    }

    // Show page numbers in range
    for (int i = start; i <= end; i++) {
      pageNumbers.add(_buildPageButton(i));
    }

    // Always show last page
    if (end < _totalPages) {
      if (end < _totalPages - 1) {
        pageNumbers.add(const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: Text('...', style: TextStyle(color: Colors.grey)),
        ));
      }
      pageNumbers.add(_buildPageButton(_totalPages));
    }

    return pageNumbers;
  }

  Widget _buildPageButton(int pageNumber) {
    bool isCurrentPage = pageNumber == _currentPage;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: GestureDetector(
        onTap: () => _goToPage(pageNumber),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isCurrentPage ? Colors.blue : Colors.transparent,
            border: Border.all(
              color: isCurrentPage ? Colors.blue : Colors.grey.shade400,
            ),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Center(
            child: Text(
              pageNumber.toString(),
              style: TextStyle(
                color: isCurrentPage ? Colors.white : Colors.grey.shade700,
                fontWeight: isCurrentPage ? FontWeight.bold : FontWeight.normal,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Placeholder model for borrowing records
class BorrowingRecord {
  final int id;
  final String memberName;
  final String bookTitle;
  final DateTime borrowDate;
  final DateTime returnDate;
  final String status; // 'borrowed', 'returned', 'overdue'

  BorrowingRecord({
    required this.id,
    required this.memberName,
    required this.bookTitle,
    required this.borrowDate,
    required this.returnDate,
    required this.status,
  });

  bool get isOverdue =>
      DateTime.now().isAfter(returnDate) && status == 'borrowed';
}
