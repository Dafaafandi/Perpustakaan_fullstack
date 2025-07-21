import 'package:perpus_app/models/book.dart';
import 'package:perpus_app/models/user.dart';

class Borrowing {
  final int id;
  final int bookId;
  final int memberId;
  final DateTime borrowDate;
  final DateTime expectedReturnDate;
  final DateTime? actualReturnDate;
  final String status; // 'borrowed', 'returned', 'overdue'
  final Book? book;
  final User? member;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Borrowing({
    required this.id,
    required this.bookId,
    required this.memberId,
    required this.borrowDate,
    required this.expectedReturnDate,
    this.actualReturnDate,
    required this.status,
    this.book,
    this.member,
    this.createdAt,
    this.updatedAt,
  });

  factory Borrowing.fromJson(Map<String, dynamic> json) {
    // Handle original due date preservation for returned books
    DateTime? expectedReturnDate;

    // If this is a returned book and we have preserved the original due date
    if (json['original_due_date'] != null) {
      expectedReturnDate = _parseDateTime(json['original_due_date']);
    }

    // Otherwise use the normal priority order
    expectedReturnDate ??= _parseDateTime(json['expected_return_date'] ??
        json['due_date'] ??
        json['tanggal_jatuh_tempo'] ??
        json['tanggal_pengembalian']);

    return Borrowing(
      id: _parseId(json['id']),
      bookId: _parseId(json['book_id'] ?? json['bookId']),
      memberId: _parseId(json['member_id'] ?? json['memberId']),
      borrowDate:
          _parseDateTime(json['tanggal_peminjaman'] ?? json['borrow_date']) ??
              DateTime.now(),
      expectedReturnDate: expectedReturnDate ?? DateTime.now(),
      actualReturnDate: _parseActualReturnDate(json),
      status: _parseStatus(json),
      book: json['book'] != null ? Book.fromJson(json['book']) : null,
      member: json['member'] != null ? User.fromJson(json['member']) : null,
      createdAt: _parseDateTime(json['created_at']),
      updatedAt: _parseDateTime(json['updated_at']),
    );
  }

  // Helper method to parse ID safely
  static int _parseId(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) {
      final parsed = int.tryParse(value);
      return parsed ?? 0;
    }
    return 0;
  }

  // Helper method to parse DateTime
  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        // Try alternative date format
        try {
          final parts = value.split('-');
          if (parts.length == 3) {
            return DateTime(
              int.parse(parts[0]),
              int.parse(parts[1]),
              int.parse(parts[2]),
            );
          }
        } catch (e) {
          return null;
        }
        return null;
      }
    }
    return null;
  }

  // Helper method to parse actual return date with proper priority
  static DateTime? _parseActualReturnDate(Map<String, dynamic> json) {
    final status = json['status']?.toString();

    // For returned books (status "2" or "3"), look for actual return date
    if (status == "2" || status == 2 || status == "3" || status == 3) {
      // Priority order for return date fields
      DateTime? returnDate = _parseDateTime(json['actual_return_date'] ??
          json['tanggal_kembali'] ??
          json['returned_at'] ??
          json['tanggal_pengembalian_aktual'] ??
          json['tanggal_dikembalikan'] ??
          json['return_date'] ??
          json['date_returned'] ??
          json['tanggal_return'] ??
          json['actual_date'] ??
          json['returned_date'] ??
          json['return_datetime']);

      // If no explicit return date field found, use tanggal_pengembalian for returned books
      if (returnDate == null) {
        returnDate = _parseDateTime(json['tanggal_pengembalian']);
      }

      return returnDate;
    }

    // For non-returned books, only return date if explicitly found in return-specific fields
    return _parseDateTime(json['actual_return_date'] ??
        json['tanggal_kembali'] ??
        json['returned_at'] ??
        json['tanggal_pengembalian_aktual'] ??
        json['tanggal_dikembalikan'] ??
        json['return_date'] ??
        json['date_returned'] ??
        json['tanggal_return'] ??
        json['actual_date'] ??
        json['returned_date'] ??
        json['return_datetime']);
  }

  // Helper method to parse status
  static String _parseStatus(Map<String, dynamic> json) {
    // Try different possible status field names
    if (json['status'] != null) {
      final statusValue = json['status'].toString();

      // Handle numeric status codes from API
      switch (statusValue) {
        case '1':
          return 'borrowed';
        case '2':
          return 'returned';
        case '3':
          return 'returned'; // API uses status 3 for returned books (not overdue)
        default:
          // Handle string status values
          return statusValue.toLowerCase();
      }
    }

    // Determine status based on return date
    if (json['actual_return_date'] != null || json['returned_at'] != null) {
      return 'returned';
    }

    // Check if overdue
    final returnDate = _parseDateTime(
        json['tanggal_pengembalian'] ?? json['expected_return_date']);
    if (returnDate != null && returnDate.isBefore(DateTime.now())) {
      return 'overdue';
    }

    return 'borrowed';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'book_id': bookId,
      'member_id': memberId,
      'tanggal_peminjaman': borrowDate.toIso8601String(),
      'tanggal_pengembalian': expectedReturnDate.toIso8601String(),
      'actual_return_date': actualReturnDate?.toIso8601String(),
      'status': status,
    };
  }

  // Convert to form data for API submission
  Map<String, String> toFormData() {
    return {
      'tanggal_peminjaman': _formatDate(borrowDate),
      'tanggal_pengembalian': _formatDate(expectedReturnDate),
      if (actualReturnDate != null)
        'actual_return_date': _formatDate(actualReturnDate!),
    };
  }

  // Helper method to format date for API
  static String _formatDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  bool get isOverdue {
    // Jika status dari API sudah "overdue", langsung return true
    if (status == 'overdue') return true;

    // Jika sudah dikembalikan, tidak bisa dianggap terlambat
    if (status == 'returned') return false;

    // Untuk status "borrowed", cek apakah sudah melewati tanggal jatuh tempo
    return expectedReturnDate.isBefore(DateTime.now());
  }

  bool get isReturned {
    return actualReturnDate != null || status.toLowerCase() == 'returned';
  }

  int get daysOverdue {
    if (!isOverdue) return 0;
    return DateTime.now().difference(expectedReturnDate).inDays;
  }

  Borrowing copyWith({
    int? id,
    int? bookId,
    int? memberId,
    DateTime? borrowDate,
    DateTime? expectedReturnDate,
    DateTime? actualReturnDate,
    String? status,
    Book? book,
    User? member,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Borrowing(
      id: id ?? this.id,
      bookId: bookId ?? this.bookId,
      memberId: memberId ?? this.memberId,
      borrowDate: borrowDate ?? this.borrowDate,
      expectedReturnDate: expectedReturnDate ?? this.expectedReturnDate,
      actualReturnDate: actualReturnDate ?? this.actualReturnDate,
      status: status ?? this.status,
      book: book ?? this.book,
      member: member ?? this.member,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Borrowing(id: $id, bookId: $bookId, memberId: $memberId, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Borrowing && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
