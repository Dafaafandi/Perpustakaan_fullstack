class Category {
  final int id;
  final String name;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Category({
    required this.id,
    required this.name,
    this.createdAt,
    this.updatedAt,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: _parseId(json['id']),
      name: _parseName(json),
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

  // Helper method to parse name from different possible field names
  static String _parseName(Map<String, dynamic> json) {
    // Try different possible field names for category name
    if (json['nama_kategori'] != null) {
      return json['nama_kategori'].toString();
    }
    if (json['name'] != null) {
      return json['name'].toString();
    }
    if (json['category_name'] != null) {
      return json['category_name'].toString();
    }
    return 'Tanpa Nama';
  }

  // Helper method to parse DateTime
  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nama_kategori': name,
    };
  }

  Category copyWith({
    int? id,
    String? name,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Category(id: $id, name: $name)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Category && other.id == id && other.name == name;
  }

  @override
  int get hashCode => id.hashCode ^ name.hashCode;
}
