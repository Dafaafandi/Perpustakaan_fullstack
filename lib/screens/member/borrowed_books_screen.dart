import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../services/library_api_service.dart';
import '../../utils/error_handler.dart';

class BorrowedBooksScreen extends StatefulWidget {
  const BorrowedBooksScreen({super.key});

  @override
  _BorrowedBooksScreenState createState() => _BorrowedBooksScreenState();
}

class _BorrowedBooksScreenState extends State<BorrowedBooksScreen> {
  final LibraryApiService _apiService = LibraryApiService();

  List<dynamic> _borrowings = [];
  bool _isLoading = false;
  String _filterStatus = 'semua'; // semua, dipinjam, dikembalikan, terlambat
  int? _currentMemberId;

  @override
  void initState() {
    super.initState();
    _loadCurrentMember();
  }

  Future<void> _loadCurrentMember() async {
    try {
      // Debug authentication status first
      if (kDebugMode) {
        final authStatus = await _apiService.getAuthStatus();
      }

      // Get current user ID from LibraryApiService
      int? userId = await _apiService.getUserId();
      if (kDebugMode) {}

      if (userId != null) {
        setState(() {
          _currentMemberId = userId;
        });
        _loadBorrowings();
      } else {
        // Try to get from user profile API as fallback

        final profile = await _apiService.getUserProfile();
        if (profile != null && profile['id'] != null) {
          userId = profile['id'];
          // Save the user ID for future use
          await _apiService.saveUserId(userId!);
          setState(() {
            _currentMemberId = userId;
          });
          _loadBorrowings();

          if (kDebugMode) {}
        } else {
          // Final fallback: try to get user profile from API directly
          if (kDebugMode) {}

          // Here we could try additional API endpoints or ask user to re-login
          if (kDebugMode) {}
          if (mounted) {
            ErrorHandler.showError(
              context,
              'Sesi login tidak valid. Silakan logout dan login ulang untuk mengakses fitur ini.',
              duration: const Duration(seconds: 5),
            );
          }
        }
      }
    } catch (e) {
      ErrorHandler.logError('_loadCurrentMember', e);
      if (mounted) {
        final errorMessage = ErrorHandler.processError(e,
            fallbackMessage: 'Error memuat data member');
        ErrorHandler.showError(context, errorMessage);
      }
    }
  }

  Future<void> _loadBorrowings() async {
    if (_currentMemberId == null) return;

    setState(() => _isLoading = true);

    try {
      final allBorrowings = await _apiService.getAllBorrowings();

      // Filter borrowings for current member only
      final memberBorrowings = allBorrowings.where((borrowing) {
        // Check if borrowing belongs to current member
        final member = borrowing['member'];
        if (member != null && member['id'] != null) {
          final memberId = member['id'];
          if (kDebugMode && allBorrowings.indexOf(borrowing) < 3) {
            print(
                'Checking borrowing ${borrowing['id']}: member.id = $memberId vs current = $_currentMemberId');
          }
          return memberId == _currentMemberId;
        }
        // Check id_member field directly
        if (borrowing['id_member'] != null) {
          final idMember = borrowing['id_member'];
          if (kDebugMode && allBorrowings.indexOf(borrowing) < 3) {
            print(
                'Checking borrowing ${borrowing['id']}: id_member = $idMember vs current = $_currentMemberId');
          }
          return idMember == _currentMemberId;
        }
        // Fallback: check member_id field
        if (borrowing['member_id'] != null) {
          final memberId = borrowing['member_id'];
          if (kDebugMode && allBorrowings.indexOf(borrowing) < 3) {
            print(
                'Checking borrowing ${borrowing['id']}: member_id = $memberId vs current = $_currentMemberId');
          }
          return memberId == _currentMemberId;
        }
        return false;
      }).toList();

      setState(() => _borrowings = memberBorrowings);
    } catch (e) {
      ErrorHandler.logError('_loadBorrowings', e);
      if (mounted) {
        final errorMessage = ErrorHandler.processError(e,
            fallbackMessage: 'Gagal memuat data peminjaman');
        ErrorHandler.showError(context, errorMessage);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<dynamic> get _filteredBorrowings {
    if (_filterStatus == 'semua') {
      return _borrowings;
    }

    return _borrowings.where((borrowing) {
      final status = borrowing['status'];
      final tanggalKembali = _getActualReturnDate(borrowing);
      final tanggalJatuhTempo = _getExpectedReturnDate(borrowing);
      final now = DateTime.now();

      // Check if book is returned (status "2" or "3", or has actual return date)
      bool isReturned = (status == "2" || status == 2) ||
          (status == "3" || status == 3) ||
          (tanggalKembali != null);

      switch (_filterStatus) {
        case 'dipinjam':
          return !isReturned && (status == "1" || status == 1);
        case 'dikembalikan':
          return isReturned;
        case 'terlambat':
          // Buku terlambat = dipinjam (status 1) dan sudah lewat tanggal jatuh tempo
          if (isReturned)
            return false; // Jika sudah dikembalikan, tidak terlambat
          try {
            if (tanggalJatuhTempo != null) {
              final jatuhTempo = DateTime.parse(tanggalJatuhTempo);
              return now.isAfter(jatuhTempo) && (status == "1" || status == 1);
            }
            return false;
          } catch (e) {
            return false;
          }
        default:
          return true;
      }
    }).toList();
  }

  String _getStatusText(dynamic borrowing) {
    // PRIORITAS: Gunakan status API sebagai sumber kebenaran utama
    final status = borrowing['status'];

    if (kDebugMode && _borrowings.indexOf(borrowing) < 3) {}

    // Status mapping berdasarkan API response aktual:
    // "1" atau 1 = Dipinjam (Borrowed)
    // "2" atau 2 = Dikembalikan tepat waktu (Returned on time)
    // "3" atau 3 = Dikembalikan (Returned - could be late or on time)

    if (status == "2" || status == 2) {
      if (kDebugMode && _borrowings.indexOf(borrowing) < 3) {}
      return 'Dikembalikan';
    }

    if (status == "3" || status == 3) {
      if (kDebugMode && _borrowings.indexOf(borrowing) < 3) {}
      return 'Dikembalikan';
    }

    // Status "1" = Dipinjam, tapi cek apakah sudah terlambat
    if (status == "1" || status == 1) {
      try {
        final tanggalJatuhTempo = _getExpectedReturnDate(borrowing);
        if (tanggalJatuhTempo != null) {
          final jatuhTempo = DateTime.parse(tanggalJatuhTempo);
          final now = DateTime.now();

          if (now.isAfter(jatuhTempo)) {
            if (kDebugMode && _borrowings.indexOf(borrowing) < 3) {}
            return 'Terlambat';
          } else {
            if (kDebugMode && _borrowings.indexOf(borrowing) < 3) {}
            return 'Dipinjam';
          }
        } else {
          if (kDebugMode && _borrowings.indexOf(borrowing) < 3) {}
          return 'Dipinjam';
        }
      } catch (e) {
        if (kDebugMode && _borrowings.indexOf(borrowing) < 3) {}
        return 'Dipinjam';
      }
    }

    // Fallback untuk status yang tidak dikenal
    if (kDebugMode && _borrowings.indexOf(borrowing) < 3) {}
    return 'Dipinjam';
  }

  Color _getStatusColor(dynamic borrowing) {
    final status = _getStatusText(borrowing);
    switch (status) {
      case 'Dikembalikan':
        return Colors.green;
      case 'Terlambat':
        return Colors.red;
      case 'Dipinjam':
      default:
        return Colors.orange;
    }
  }

  String? _getExpectedReturnDate(dynamic borrowing) {
    // Debug: print available fields (hanya untuk beberapa record pertama)
    if (kDebugMode && _borrowings.indexOf(borrowing) < 3) {}

    // Prioritas field untuk tanggal jatuh tempo:
    // 1. original_due_date (preserved from before return)
    // 2. expected_return_date (paling reliable)
    // 3. due_date
    // 4. tanggal_jatuh_tempo
    // 5. tanggal_pengembalian (HANYA untuk status 1 - dipinjam)

    final status = borrowing['status'];

    // Untuk tanggal jatuh tempo asli, prioritaskan field khusus
    String? dueDate = borrowing['original_due_date'] ??
        borrowing['expected_return_date'] ??
        borrowing['due_date'] ??
        borrowing['tanggal_jatuh_tempo'];

    // Hanya gunakan tanggal_pengembalian sebagai fallback jika:
    // 1. Tidak ada field tanggal jatuh tempo lainnya
    // 2. Status masih dipinjam (bukan dikembalikan)
    if (dueDate == null && (status == "1" || status == 1)) {
      dueDate = borrowing['tanggal_pengembalian'];
    }

    // FALLBACK: Untuk buku yang sudah dikembalikan (status 2/3) tanpa info jatuh tempo
    // Estimasi berdasarkan tanggal peminjaman + durasi yang sesuai
    if (dueDate == null &&
        (status == "2" || status == 2 || status == "3" || status == 3)) {
      try {
        final tanggalPinjam = borrowing['tanggal_peminjaman'];
        final tanggalKembali = borrowing[
            'tanggal_pengembalian']; // actual return date for returned books

        if (tanggalPinjam != null && tanggalKembali != null) {
          final pinjamDate = DateTime.parse(tanggalPinjam);

          // Coba deteksi durasi yang sebenarnya dari data lain atau gunakan standar
          // Untuk ID 245: pinjam 18/07, jatuh tempo asli 26/07 = 8 hari
          // Gunakan 8 hari sebagai estimasi yang lebih akurat
          final estimatedDue = pinjamDate.add(const Duration(days: 8));
          dueDate = estimatedDue.toIso8601String().split('T')[0];

          if (kDebugMode && _borrowings.indexOf(borrowing) < 3) {
            print(
                'ESTIMATED due date for returned book: $dueDate (pinjam: $tanggalPinjam + 8 days)');
          }
        }
      } catch (e) {
        if (kDebugMode) {}
      }
    }

    return dueDate;
  }

  String? _getActualReturnDate(dynamic borrowing) {
    // PENTING: Hanya kembalikan tanggal return yang aktual, jangan fallback ke field lain!
    // Only return actual return date if the book has truly been returned

    final status = borrowing['status'];

    // If status is not returned status (2 or 3), don't try to find return date
    if (status != "2" && status != 2 && status != "3" && status != 3) {
      if (kDebugMode && _borrowings.indexOf(borrowing) < 3) {}
      return null; // No return date for non-returned books
    }

    // For status "2" or "3" (returned), look for actual return date
    final actualReturnDate = borrowing['actual_return_date'] ??
        borrowing['tanggal_kembali'] ??
        borrowing['returned_at'] ??
        borrowing['tanggal_pengembalian_aktual'] ??
        borrowing['tanggal_dikembalikan'] ??
        borrowing['return_date'] ??
        borrowing['date_returned'] ??
        borrowing['tanggal_return'] ??
        borrowing['actual_date'] ??
        borrowing['returned_date'] ??
        borrowing['return_datetime'];

    // If status is "2" or "3" but no explicit return date field found,
    // use tanggal_pengembalian as it might contain the actual return date
    if (actualReturnDate == null) {
      final fallbackDate = borrowing['tanggal_pengembalian'];
      if (kDebugMode && _borrowings.indexOf(borrowing) < 3) {}
      return fallbackDate;
    }

    if (kDebugMode && _borrowings.indexOf(borrowing) < 3) {}

    return actualReturnDate;
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return '-';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  Future<void> _showReturnDialog(dynamic borrowing) async {
    final TextEditingController dateController = TextEditingController();
    DateTime selectedDate = DateTime.now();
    dateController.text =
        _formatDate(selectedDate.toIso8601String().split('T')[0]);

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Kembalikan Buku'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Buku: ${borrowing['buku']?['judul'] ?? 'Unknown'}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: dateController,
                decoration: const InputDecoration(
                  labelText: 'Tanggal Pengembalian',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calendar_today),
                  suffixIcon: Icon(Icons.arrow_drop_down),
                ),
                readOnly: true,
                onTap: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );

                  if (picked != null) {
                    setDialogState(() {
                      selectedDate = picked;
                      dateController.text =
                          _formatDate(picked.toIso8601String().split('T')[0]);
                    });
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Kembalikan'),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      await _returnBook(borrowing['id']);
    }
  }

  Future<void> _returnBook(int borrowingId) async {
    try {
      // Debug: Log data sebelum pengembalian
      final borrowingBefore = _borrowings
          .firstWhere((b) => b['id'] == borrowingId, orElse: () => null);

      // PRESERVE the original due date before API call
      String? originalDueDate;
      if (borrowingBefore != null) {
        originalDueDate = _getExpectedReturnDate(borrowingBefore);
      }

      final success = await _apiService.returnBook(borrowingId);

      if (mounted) {
        if (success) {
          ErrorHandler.showSuccess(context, 'Buku berhasil dikembalikan');

          // Refresh data and restore due date if needed
          await _loadBorrowings();

          // RESTORE the original due date after API call corrupts it
          if (originalDueDate != null) {
            final borrowingAfter = _borrowings
                .firstWhere((b) => b['id'] == borrowingId, orElse: () => null);

            if (borrowingAfter != null) {
              // Restore the original due date to prevent status calculation errors
              borrowingAfter['original_due_date'] = originalDueDate;

              // MANUAL FIX: If API didn't set actual return date, set it manually
              if (_getActualReturnDate(borrowingAfter) == null &&
                  (borrowingAfter['status'] == "2" ||
                      borrowingAfter['status'] == 2)) {
                final today = DateTime.now().toIso8601String().split('T')[0];
                borrowingAfter['actual_return_date'] = today;
                borrowingAfter['tanggal_kembali'] = today;
                borrowingAfter['returned_at'] = today;
                if (kDebugMode) {}
              }
            }
          }
        } else {
          ErrorHandler.showError(context, 'Gagal mengembalikan buku');
        }
      }
    } catch (e) {
      ErrorHandler.logError('_returnBook', e);
      if (mounted) {
        final errorMessage = ErrorHandler.processError(e,
            fallbackMessage: 'Error saat mengembalikan buku');
        ErrorHandler.showError(context, errorMessage);
      }
    }
  }

  void _showBorrowingDetail(dynamic borrowing) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Detail Peminjaman'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ID: ${borrowing['id']}'),
            const SizedBox(height: 8),
            Text('Buku: ${borrowing['book']?['judul'] ?? 'Unknown'}'),
            Text('Pengarang: ${borrowing['book']?['pengarang'] ?? 'Unknown'}'),
            const SizedBox(height: 8),
            Text('Member: ${borrowing['member']?['name'] ?? 'Unknown'}'),
            const SizedBox(height: 8),
            Text(
                'Tanggal Pinjam: ${_formatDate(borrowing['tanggal_peminjaman'])}'),
            Text(
                'Tanggal Jatuh Tempo: ${_formatDate(_getExpectedReturnDate(borrowing))}'),
            Text(
                'Tanggal Kembali: ${_formatDate(_getActualReturnDate(borrowing))}'),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('Status: '),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(borrowing),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getStatusText(borrowing),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
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

  @override
  Widget build(BuildContext context) {
    final filteredBorrowings = _filteredBorrowings;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Buku Dipinjam'),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() => _filterStatus = value);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'semua', child: Text('Semua')),
              const PopupMenuItem(
                  value: 'dipinjam', child: Text('Sedang Dipinjam')),
              const PopupMenuItem(
                  value: 'dikembalikan', child: Text('Sudah Dikembalikan')),
              const PopupMenuItem(value: 'terlambat', child: Text('Terlambat')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Info
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.blue.shade50,
            child: Text(
              'Menampilkan: ${_getFilterText(_filterStatus)} (${filteredBorrowings.length} item)',
              style: TextStyle(
                color: Colors.blue.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          // Borrowings List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredBorrowings.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.book_outlined,
                              size: 64,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Tidak ada data peminjaman',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadBorrowings,
                        child: ListView.builder(
                          itemCount: filteredBorrowings.length,
                          itemBuilder: (context, index) {
                            final borrowing = filteredBorrowings[index];
                            final status = _getStatusText(borrowing);
                            final statusColor = _getStatusColor(borrowing);

                            return Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: statusColor,
                                  child: const Icon(
                                    Icons.book,
                                    color: Colors.white,
                                  ),
                                ),
                                title: Text(
                                  borrowing['book']?['judul'] ?? 'Unknown Book',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                        'Pinjam: ${_formatDate(borrowing['tanggal_peminjaman'])}'),
                                    // PERBAIKAN: Tampilkan tanggal yang tepat berdasarkan status
                                    if (_getStatusText(borrowing) ==
                                        'Dikembalikan') ...[
                                      // Untuk buku yang sudah dikembalikan, tampilkan tanggal jatuh tempo asli dan tanggal kembali
                                      Text(
                                          'Jatuh tempo: ${_formatDate(_getExpectedReturnDate(borrowing))}'),
                                      Text(
                                          'Tanggal kembali: ${_formatDate(_getActualReturnDate(borrowing))}'),
                                    ] else ...[
                                      // Untuk buku yang masih dipinjam, tampilkan tanggal jatuh tempo
                                      Text(
                                          'Jatuh tempo: ${_formatDate(_getExpectedReturnDate(borrowing))}'),
                                    ]
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: statusColor,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        status,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    PopupMenuButton<String>(
                                      onSelected: (value) {
                                        switch (value) {
                                          case 'detail':
                                            _showBorrowingDetail(borrowing);
                                            break;
                                          case 'return':
                                            _showReturnDialog(borrowing);
                                            break;
                                        }
                                      },
                                      itemBuilder: (context) => [
                                        const PopupMenuItem(
                                          value: 'detail',
                                          child: Row(
                                            children: [
                                              Icon(Icons.info_outline),
                                              SizedBox(width: 8),
                                              Text('Detail'),
                                            ],
                                          ),
                                        ),
                                        if (borrowing['actual_return_date'] ==
                                            null)
                                          const PopupMenuItem(
                                            value: 'return',
                                            child: Row(
                                              children: [
                                                Icon(Icons.assignment_return),
                                                SizedBox(width: 8),
                                                Text('Kembalikan'),
                                              ],
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  String _getFilterText(String filter) {
    switch (filter) {
      case 'dipinjam':
        return 'Sedang Dipinjam';
      case 'dikembalikan':
        return 'Sudah Dikembalikan';
      case 'terlambat':
        return 'Terlambat';
      case 'semua':
      default:
        return 'Semua Peminjaman';
    }
  }
}
