import 'package:flutter/material.dart';
import '../../services/library_api_service.dart';
import 'books_list_screen_working.dart';
import 'borrowed_books_screen.dart';

class MemberDashboardScreen extends StatefulWidget {
  const MemberDashboardScreen({super.key});

  @override
  _MemberDashboardScreenState createState() => _MemberDashboardScreenState();
}

class _MemberDashboardScreenState extends State<MemberDashboardScreen> {
  final LibraryApiService _apiService = LibraryApiService();

  Map<String, dynamic> _stats = {};
  bool _isLoading = true;
  String? _userName;
  int? _currentMemberId;

  @override
  void initState() {
    super.initState();
    _loadMemberData();
  }

  Future<void> _loadMemberData() async {
    setState(() => _isLoading = true);

    try {
      // Get current user info
      final userName = await _apiService.getUserName();
      int? userId = await _apiService.getUserId();

      // If user ID not found, try from profile
      if (userId == null) {
        final profile = await _apiService.getUserProfile();
        if (profile != null && profile['id'] != null) {
          userId = profile['id'];
        }
      }

      if (userId != null) {
        _currentMemberId = userId;
      } else {
        // Show login error instead of fallback
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Sesi login tidak valid. Silakan logout dan login kembali.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        _currentMemberId = null;
        setState(() => _isLoading = false);
        return;
      }

      // Get member borrowing statistics
      await _calculateMemberStats();

      setState(() {
        _userName = userName;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }
  }

  Future<void> _calculateMemberStats() async {
    try {
      final allBorrowings = await _apiService.getAllBorrowings();

      // Filter borrowings for current member
      final memberBorrowings = allBorrowings.where((borrowing) {
        // Check id_member field directly (this is the main field in API response)
        if (borrowing['id_member'] != null) {
          return borrowing['id_member'] == _currentMemberId;
        }
        // Fallback: check nested member.id
        final member = borrowing['member'];
        if (member != null && member['id'] != null) {
          return member['id'] == _currentMemberId;
        }
        // Fallback: check member_id field
        if (borrowing['member_id'] != null) {
          return borrowing['member_id'] == _currentMemberId;
        }
        return false;
      }).toList();

      print(
          'DEBUG: Found ${memberBorrowings.length} borrowings for member $_currentMemberId');

      // Debug: Print first few borrowings to understand structure
      for (int i = 0; i < memberBorrowings.length && i < 5; i++) {
        final borrowing = memberBorrowings[i];
        print(
            'DEBUG Sample ${i + 1}: ID=${borrowing['id']}, Status=${borrowing['status']}, ActualReturnDate=${borrowing['tanggal_pengembalian_aktual']}, DueDate=${borrowing['tanggal_pengembalian']}');
      }

      int totalBorrowed = memberBorrowings.length;
      int currentlyBorrowed = 0;
      int returned = 0;
      int overdue = 0;

      for (var borrowing in memberBorrowings) {
        // Check all available fields for returned status
        final status = borrowing['status'];
        final statusStr = status?.toString() ?? '';
        final returnedDate = borrowing['tanggal_pengembalian_aktual'];
        final updateDate = borrowing['updated_at'];
        final returnDate = borrowing['tanggal_pengembalian'];

        // Debug: Print borrowing details
        print(
            'ID: ${borrowing['id']}, Status: $statusStr, ActualReturn: $returnedDate, Updated: $updateDate, ReturnDate: $returnDate');

        // Enhanced logic: Check multiple indicators for returned status
        bool isReturned = false;
        bool isOverdue = false;

        // Method 1: Status is explicitly "2" (dikembalikan)
        if (statusStr == "2") {
          isReturned = true;
        }
        // Method 2: Has actual return date (tanggal_pengembalian_aktual)
        else if (returnedDate != null && returnedDate.toString().isNotEmpty) {
          isReturned = true;
        }
        // Method 3: For status "3", determine if it's returned or actually overdue
        else if (statusStr == "3") {
          try {
            final borrowDate = DateTime.parse(borrowing['tanggal_peminjaman']);
            final dueDate = DateTime.parse(returnDate);
            final updated = DateTime.parse(updateDate);
            final now = DateTime.now();

            // Check if the book has been returned (updated recently and return date is set)
            // When a book is returned, API sets status to 3 and updates tanggal_pengembalian to actual return date
            bool wasReturnedToday = updated.year == now.year &&
                updated.month == now.month &&
                updated.day == now.day;

            // Calculate the original due date (borrowed date + typical loan period of 7-8 days)
            final estimatedDueDate = borrowDate.add(const Duration(days: 8));
            print(
                'ESTIMATED due date for returned book: ${estimatedDueDate.toString().substring(0, 10)} (pinjam: ${borrowDate.toString().substring(0, 10)} + 8 days)');

            // If tanggal_pengembalian matches today's date and book was updated today,
            // it's likely a returned book (not overdue)
            if (wasReturnedToday &&
                returnDate == now.toString().substring(0, 10)) {
              isReturned = true;
              print(
                  'Book ${borrowing['id']} marked as RETURNED (returned today)');
            }
            // If the return date is before or equal to the estimated due date, it's returned on time
            else if (DateTime.parse(returnDate).isBefore(estimatedDueDate) ||
                DateTime.parse(returnDate).isAtSameMomentAs(estimatedDueDate)) {
              isReturned = true;
              print(
                  'Book ${borrowing['id']} marked as RETURNED (returned on time)');
            }
            // Otherwise, check if it's actually overdue
            else if (now.isAfter(dueDate)) {
              isOverdue = true;
              print('Book ${borrowing['id']} marked as OVERDUE');
            } else {
              // Default case for status 3 - treat as returned to be safe
              isReturned = true;
              print(
                  'Book ${borrowing['id']} marked as RETURNED (default for status 3)');
            }
          } catch (e) {
            // Date parsing failed, assume it's returned to avoid false overdue counts
            print('Date parsing failed for borrowing ${borrowing['id']}: $e');
            isReturned = true;
          }
        }

        // Count based on the determined status
        if (isReturned) {
          returned++;
        } else if (isOverdue || statusStr == "4") {
          // status 4 might be used for actual overdue
          overdue++;
        } else if (statusStr == "1") {
          currentlyBorrowed++;
        } else {
          // Unknown status, treat as currently borrowed
          print('Unknown status: $statusStr for borrowing ${borrowing['id']}');
          currentlyBorrowed++;
        }
      }

      print(
          'DEBUG Final Stats: Total=$totalBorrowed, Currently=$currentlyBorrowed, Returned=$returned, Overdue=$overdue');
      print(
          'DEBUG Calculation: $returned + $currentlyBorrowed + $overdue = ${returned + currentlyBorrowed + overdue} (should equal $totalBorrowed)');

      setState(() {
        _stats = {
          'total_borrowed': totalBorrowed,
          'currently_borrowed': currentlyBorrowed,
          'returned': returned,
          'overdue': overdue,
        };
      });
    } catch (e) {
      setState(() {
        _stats = {
          'total_borrowed': 0,
          'currently_borrowed': 0,
          'returned': 0,
          'overdue': 0,
        };
      });
    }
  }

  String? _getExpectedReturnDate(dynamic borrowing) {
    // Prioritas field untuk tanggal jatuh tempo:
    // 1. expected_return_date (paling reliable)
    // 2. due_date
    // 3. tanggal_jatuh_tempo
    // 4. tanggal_pengembalian (fallback, tapi bisa berubah saat pengembalian)
    return borrowing['expected_return_date'] ??
        borrowing['due_date'] ??
        borrowing['tanggal_jatuh_tempo'] ??
        borrowing['tanggal_pengembalian'];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Member'),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadMemberData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Welcome Card
                    Card(
                      elevation: 4,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.blue.shade600,
                              Colors.blue.shade400
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Selamat Datang!',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _userName ?? 'Member',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Member ID: ${_currentMemberId ?? 'Unknown'}',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Statistics Grid
                    const Text(
                      'Statistik Peminjaman',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),

                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.2,
                      children: [
                        _buildStatCard(
                          'Total Dipinjam',
                          _stats['total_borrowed']?.toString() ?? '0',
                          Icons.library_books,
                          Colors.blue,
                        ),
                        _buildStatCard(
                          'Sedang Dipinjam',
                          _stats['currently_borrowed']?.toString() ?? '0',
                          Icons.book,
                          Colors.orange,
                        ),
                        _buildStatCard(
                          'Sudah Dikembalikan',
                          _stats['returned']?.toString() ?? '0',
                          Icons.assignment_return,
                          Colors.green,
                        ),
                        _buildStatCard(
                          'Terlambat',
                          _stats['overdue']?.toString() ?? '0',
                          Icons.warning,
                          Colors.red,
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Quick Actions
                    const Text(
                      'Aksi Cepat',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: _buildActionCard(
                            'Cari Buku',
                            Icons.search,
                            Colors.blue,
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => MemberBooksListScreen(),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildActionCard(
                            'Riwayat Peminjaman',
                            Icons.history,
                            Colors.green,
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => BorrowedBooksScreen(),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Tips Card
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.lightbulb,
                                    color: Colors.amber.shade600),
                                const SizedBox(width: 8),
                                const Text(
                                  'Tips Peminjaman',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              '• Kembalikan buku tepat waktu untuk menghindari denda\n'
                              '• Maksimal peminjaman adalah 14 hari\n'
                              '• Gunakan fitur pencarian untuk menemukan buku dengan mudah\n'
                              '• Periksa status peminjaman secara berkala',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.black87,
                                height: 1.5,
                              ),
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

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 3,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 32,
              color: color,
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black54,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(
      String title, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(
                icon,
                size: 32,
                color: color,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
