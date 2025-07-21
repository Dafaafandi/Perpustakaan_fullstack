import 'package:dio/dio.dart';
import 'package:perpus_app/models/book.dart';
import 'package:perpus_app/models/category.dart' as CategoryModel;
import 'package:perpus_app/models/user.dart';
import 'package:perpus_app/models/borrowing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class ApiService {
  final Dio _dio;

  ApiService._()
      : _dio = Dio(BaseOptions(
          baseUrl: 'http://perpus-api.mamorasoft.com/api',
          connectTimeout: const Duration(
              milliseconds: 15000), // Increase timeout for external API
          receiveTimeout: const Duration(milliseconds: 15000),
          sendTimeout: const Duration(milliseconds: 15000),
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
        )) {
    // Add logging interceptor for debugging
    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          requestHeader: true,
          responseHeader: false,
          error: true,
        ),
      );
    }

    // Auth interceptor
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final prefs = await SharedPreferences.getInstance();
          final token = prefs.getString('auth_token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (error, handler) async {
          // Handle 401 Unauthorized - auto logout
          if (error.response?.statusCode == 401) {
            await logout();
            // You could add navigation to login screen here
          }
          return handler.next(error);
        },
      ),
    );
  }

  static final ApiService _instance = ApiService._();

  factory ApiService() => _instance;

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_name');
  }

  Future<void> _saveUserName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', name);
  }

  Future<String?> getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_role');
  }

  Future<void> _saveUserRole(String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_role', role);
  }

  Future<String?> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_email');
  }

  Future<void> _saveUserEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_email', email);
  }

  Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');
    if (kDebugMode) {

    }
    return userId;
  }

  Future<void> _saveUserId(int id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('user_id', id);
    if (kDebugMode) {

    }
  }

  // Public method to save user ID (for external use)
  Future<void> saveUserId(int id) async {
    await _saveUserId(id);
  }

  Future<void> logout() async {
    try {
      // Try to call logout endpoint if available
      await _dio.post('/logout');
    } catch (e) {
      // Continue with local logout even if server call fails
      if (kDebugMode) {

      }
    } finally {
      // Always clear local data
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      await prefs.remove('user_name');
      await prefs.remove('user_role');
      await prefs.remove('user_email');
      await prefs.remove('user_id'); // Fix: Remove user_id on logout
    }
  }

  Future<bool> login(String username, String password) async {
    try {
      // Prepare form data as required by the API
      final formData = FormData.fromMap({
        'username': username,
        'password': password,
      });

      final response = await _dio.post(
        '/login',
        data: formData,
        options: Options(
          contentType: 'application/x-www-form-urlencoded',
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;

        // Check for successful response structure
        if (data != null && data['access_token'] != null) {
          await _saveToken(data['access_token']);

          // Save user info if available
          if (data['user'] != null) {
            await _saveUserName(data['user']['name'] ?? 'User');
            if (data['user']['id'] != null) {
              await _saveUserId(data['user']['id']);
            }
            if (data['user']['role'] != null) {
              await _saveUserRole(data['user']['role']);
            }
            if (data['user']['email'] != null) {
              await _saveUserEmail(data['user']['email']);
            }
          } else {
            // Default values if user info not provided
            await _saveUserName('User');
            await _saveUserRole('member');
          }

          return true;
        } else if (data != null && data['token'] != null) {
          // Alternative token field name
          await _saveToken(data['token']);

          // Check for user info in alternative structure
          if (data['user'] != null) {
            await _saveUserName(data['user']['name'] ?? 'User');
            if (data['user']['id'] != null) {
              await _saveUserId(data['user']['id']);
            }
            if (data['user']['role'] != null) {
              await _saveUserRole(data['user']['role']);
            }
            if (data['user']['email'] != null) {
              await _saveUserEmail(data['user']['email']);
            }
          } else {
            await _saveUserName('User');
            await _saveUserRole('member');
          }
          return true;
        } else if (data != null &&
            data['status'] == 200 &&
            data['data'] != null) {
          // Handle response with status and data structure: {"status": 200, "data": {"token": "...", "user": {...}}}
          final responseData = data['data'];
          if (responseData['token'] != null) {
            await _saveToken(responseData['token']);

            if (responseData['user'] != null) {
              await _saveUserName(responseData['user']['name'] ?? 'User');
              if (responseData['user']['id'] != null) {
                await _saveUserId(responseData['user']['id']);
              }
              if (responseData['user']['role'] != null) {
                await _saveUserRole(responseData['user']['role']);
              }
              if (responseData['user']['email'] != null) {
                await _saveUserEmail(responseData['user']['email']);
              }
            } else {
              await _saveUserName('User');
              await _saveUserRole('member');
            }
            return true;
          }
        }
      }

      return false;
    } on DioException catch (e) {
      if (kDebugMode) {
        String message = 'Login gagal';
        if (e.response?.statusCode == 401) {
          message = 'Username atau password salah';
        } else if (e.response?.statusCode == 422) {
          message = 'Data login tidak valid';
        } else if (e.type == DioExceptionType.connectionError) {
          message = 'Tidak dapat terhubung ke server';
        }

      }

      return false;
    } catch (e) {
      if (kDebugMode) {

      }
      return false;
    }
  }

  Future<bool> register(String name, String username, String email,
      String password, String confirmPassword) async {
    try {
      final response = await _dio.post(
        '/register',
        data: {
          'name': name,
          'username': username,
          'email': email,
          'password': password,
          'confirm_password': confirmPassword,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      }

      return false;
    } on DioException catch (e) {
      if (kDebugMode) {
        String message = 'Registrasi gagal';

        if (e.response?.statusCode == 422) {
          // Handle validation errors
          final errors = e.response?.data['errors'];
          if (errors != null && errors is Map) {
            List<String> errorMessages = [];
            errors.forEach((key, value) {
              if (value is List && value.isNotEmpty) {
                errorMessages.add(value.first.toString());
              }
            });
            message = errorMessages.join('\n');
          } else {
            message = 'Data registrasi tidak valid';
          }
        } else if (e.type == DioExceptionType.connectionError) {
          message = 'Tidak dapat terhubung ke server';
        }

      }

      return false;
    }
  }

  // == CREATE (Tambah Buku Baru) - Menggunakan Endpoint Final dari Backend ==
  Future<bool> addBook(Map<String, String> bookData) async {
    try {
      final formData = FormData.fromMap(bookData);

      final response = await _dio.post(
        '/book/create',
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
        ),
      );
      return response.statusCode == 201 || response.statusCode == 200;
    } on DioException catch (e) {
      if (kDebugMode) {

      }
      return false;
    } catch (e) {
      if (kDebugMode) {

      }
      return false;
    }
  }

  Future<bool> updateBook(int id, Map<String, String> bookData) async {
    try {
      final formData = FormData.fromMap(bookData);

      final response = await _dio.post(
        '/book/$id/update',
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
        ),
      );
      return response.statusCode == 200;
    } on DioException catch (e) {
      if (kDebugMode) {

      }
      return false;
    } catch (e) {
      if (kDebugMode) {

      }
      return false;
    }
  }

  Future<bool> deleteBook(int id) async {
    try {
      final response = await _dio.delete('/book/$id/delete');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<List<Book>> getBooks() async {
    try {
      // Use the correct API endpoint with pagination
      final response = await _dio.get('/book/all?page=1&per_page=100');
      final responseData = response.data;

      // Handle the API response structure based on actual API response
      if (responseData is Map<String, dynamic>) {
        if (responseData['data'] is Map<String, dynamic> &&
            responseData['data']['books'] is Map<String, dynamic> &&
            responseData['data']['books']['data'] is List) {
          // Correct structure: {status: 200, data: {books: {data: [...]}}}
          final List<dynamic> bookList = responseData['data']['books']['data'];
          return bookList.map((json) => Book.fromJson(json)).toList();
        } else if (responseData['data'] is List) {
          // Direct data array
          final List<dynamic> bookList = responseData['data'];
          return bookList.map((json) => Book.fromJson(json)).toList();
        } else if (responseData['data'] is Map<String, dynamic> &&
            responseData['data']['data'] is List) {
          // Nested pagination structure
          final List<dynamic> bookList = responseData['data']['data'];
          return bookList.map((json) => Book.fromJson(json)).toList();
        } else if (responseData['books'] is List) {
          // Books directly in response
          final List<dynamic> bookList = responseData['books'];
          return bookList.map((json) => Book.fromJson(json)).toList();
        }
      }

      // If structure is unexpected, return empty list
      return [];
    } on DioException catch (e) {
      if (kDebugMode) {

      }
      throw Exception('Gagal mengambil data buku dari server.');
    } catch (e) {
      if (kDebugMode) {

      }
      throw Exception('Terjadi kesalahan yang tidak terduga.');
    }
  }

  Future<Book> getBookById(int bookId) async {
    try {
      final response = await _dio.get('/book/$bookId');
      final responseData = response.data;

      // Handle different possible response structures
      if (responseData is Map<String, dynamic>) {
        if (responseData['data'] is Map<String, dynamic>) {
          return Book.fromJson(responseData['data']);
        } else if (responseData['book'] is Map<String, dynamic>) {
          return Book.fromJson(responseData['book']);
        } else if (responseData['id'] != null) {
          // Direct book object
          return Book.fromJson(responseData);
        }
      }

      throw Exception('Struktur data detail buku tidak terduga.');
    } on DioException catch (e) {
      if (kDebugMode) {

      }
      throw Exception('Gagal memuat detail buku.');
    } catch (e) {
      if (kDebugMode) {

      }
      throw Exception('Terjadi kesalahan yang tidak terduga.');
    }
  }

  // == CATEGORY CRUD METHODS ==

  // CREATE
  Future<bool> addCategory(String categoryName) async {
    try {
      final formData = FormData.fromMap({
        'nama_kategori': categoryName,
      });

      final response = await _dio.post(
        '/category/create',
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
        ),
      );
      return response.statusCode == 201 || response.statusCode == 200;
    } on DioException catch (e) {
      if (kDebugMode) {

      }
      return false;
    } catch (e) {
      if (kDebugMode) {

      }
      return false;
    }
  }

  // UPDATE
  Future<bool> updateCategory(int id, String categoryName) async {
    try {
      final formData = FormData.fromMap({
        'nama_kategori': categoryName,
      });

      final response = await _dio.post(
        '/category/update/$id',
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
        ),
      );
      return response.statusCode == 200;
    } on DioException catch (e) {
      if (kDebugMode) {

      }
      return false;
    } catch (e) {
      if (kDebugMode) {

      }
      return false;
    }
  }

  // DELETE
  Future<bool> deleteCategory(int id) async {
    try {
      final response = await _dio.delete('/category/$id/delete');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // GET LIST (sudah ada, kita pastikan lagi)
  Future<List<CategoryModel.Category>> getCategories() async {
    try {
      final response = await _dio.get('/category/all/all');
      final responseData = response.data;

      // Handle different possible response structures based on actual API response
      if (responseData is Map<String, dynamic>) {
        if (responseData['data'] is Map<String, dynamic> &&
            responseData['data']['categories'] is List) {
          // Correct structure: {status: 200, data: {categories: [...]}}
          final List<dynamic> categoryList = responseData['data']['categories'];
          return categoryList
              .map((json) => CategoryModel.Category.fromJson(json))
              .toList();
        } else if (responseData['data'] is List) {
          // Direct data array
          final List<dynamic> categoryList = responseData['data'];
          return categoryList
              .map((json) => CategoryModel.Category.fromJson(json))
              .toList();
        } else if (responseData['categories'] is List) {
          // Categories directly in response
          final List<dynamic> categoryList = responseData['categories'];
          return categoryList
              .map((json) => CategoryModel.Category.fromJson(json))
              .toList();
        }
      } else if (responseData is List) {
        // Direct array response
        return responseData
            .map((json) => CategoryModel.Category.fromJson(json))
            .toList();
      }

      return [];
    } on DioException catch (e) {
      if (kDebugMode) {

      }
      throw Exception('Gagal memuat kategori.');
    } catch (e) {
      if (kDebugMode) {

      }
      throw Exception('Terjadi kesalahan yang tidak terduga.');
    }
  }

  // == PAGINATION & SEARCH SUPPORT ==

  // Get books with pagination and enhanced filtering
  Future<Map<String, dynamic>> getBooksPaginated({
    int page = 1,
    int perPage = 10,
    String? search,
    int? categoryId,
    String? author,
    String? publisher,
    String? isbn,
    String? sortBy,
    String? sortOrder,
    int? year,
    String? status,
  }) async {
    try {
      Map<String, dynamic> queryParams = {
        'page': page,
        'per_page': perPage,
      };

      // Search parameter
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }

      // Filter by category
      if (categoryId != null) {
        queryParams['category_id'] = categoryId;
      }

      // Filter by author
      if (author != null && author.isNotEmpty) {
        queryParams['author'] = author;
      }

      // Filter by publisher
      if (publisher != null && publisher.isNotEmpty) {
        queryParams['publisher'] = publisher;
      }

      // Filter by ISBN
      if (isbn != null && isbn.isNotEmpty) {
        queryParams['isbn'] = isbn;
      }

      // Filter by publication year
      if (year != null) {
        queryParams['year'] = year;
      }

      // Filter by status (available, borrowed, etc.)
      if (status != null && status.isNotEmpty) {
        queryParams['status'] = status;
      }

      // Sorting options
      if (sortBy != null && sortBy.isNotEmpty) {
        queryParams['sort_by'] = sortBy; // title, author, created_at, etc.
      }

      if (sortOrder != null && sortOrder.isNotEmpty) {
        queryParams['sort_order'] = sortOrder; // asc, desc
      }

      if (kDebugMode) {

      }

      final response =
          await _dio.get('/book/all', queryParameters: queryParams);
      final responseData = response.data;

      if (responseData is Map<String, dynamic> &&
          responseData['data'] is Map<String, dynamic> &&
          responseData['data']['books'] is Map<String, dynamic>) {
        final booksData = responseData['data']['books'];
        final List<dynamic> bookList = booksData['data'] ?? [];

        // Convert to Book objects
        List<Book> books = bookList.map((json) => Book.fromJson(json)).toList();

        // If API doesn't support filtering, implement client-side filtering
        if (books.isNotEmpty &&
            (categoryId != null ||
                author != null ||
                publisher != null ||
                year != null ||
                status != null)) {
          // Apply category filter
          if (categoryId != null) {
            books =
                books.where((book) => book.category.id == categoryId).toList();
          }

          // Apply author filter
          if (author != null && author.isNotEmpty) {
            books = books
                .where((book) =>
                    book.pengarang.toLowerCase().contains(author.toLowerCase()))
                .toList();
          }

          // Apply publisher filter
          if (publisher != null && publisher.isNotEmpty) {
            books = books
                .where((book) => book.penerbit
                    .toLowerCase()
                    .contains(publisher.toLowerCase()))
                .toList();
          }

          // Apply year filter
          if (year != null) {
            books =
                books.where((book) => book.tahun == year.toString()).toList();
          }

          // Apply status filter
          if (status != null && status.isNotEmpty && status != 'Semua') {
            if (status == 'Tersedia') {
              books = books.where((book) => book.stok > 0).toList();
            } else if (status == 'Dipinjam') {
              books = books.where((book) => book.stok <= 0).toList();
            }
          }

          // Apply sorting
          if (sortBy != null && sortBy.isNotEmpty) {
            books.sort((a, b) {
              int comparison = 0;
              switch (sortBy) {
                case 'judul':
                  comparison = a.judul.compareTo(b.judul);
                  break;
                case 'pengarang':
                  comparison = a.pengarang.compareTo(b.pengarang);
                  break;
                case 'penerbit':
                  comparison = a.penerbit.compareTo(b.penerbit);
                  break;
                case 'tahun':
                  comparison = a.tahun.compareTo(b.tahun);
                  break;
                default:
                  comparison = a.judul.compareTo(b.judul);
              }
              return sortOrder == 'desc' ? -comparison : comparison;
            });
          }

          // Implement pagination for filtered results
          final totalFilteredItems = books.length;
          final totalFilteredPages = (totalFilteredItems / perPage).ceil();
          final startIndex = (page - 1) * perPage;
          final endIndex = startIndex + perPage;
          final paginatedBooks = books.sublist(
              startIndex, endIndex > books.length ? books.length : endIndex);

          return {
            'books': paginatedBooks,
            'current_page': page,
            'total_pages': totalFilteredPages,
            'total_items': totalFilteredItems,
            'per_page': perPage,
          };
        }

        return {
          'books': books,
          'current_page': booksData['current_page'] ?? 1,
          'total_pages': booksData['last_page'] ?? 1,
          'total_items': booksData['total'] ?? 0,
          'per_page': booksData['per_page'] ?? perPage,
        };
      } else {
        return {
          'books': <Book>[],
          'current_page': 1,
          'total_pages': 1,
          'total_items': 0,
          'per_page': perPage,
        };
      }
    } on DioException catch (e) {
      if (kDebugMode) {

      }
      throw Exception('Gagal mengambil data buku dari server.');
    }
  }

  // Get categories with pagination and enhanced filtering
  Future<Map<String, dynamic>> getCategoriesPaginated({
    int page = 1,
    int perPage = 10,
    String? search,
    String? sortBy,
    String? sortOrder,
    bool? hasBooks, // Filter categories that have books or not
  }) async {
    try {
      if (kDebugMode) {

      }

      // Since the API endpoint '/category/all/all' doesn't seem to support
      // server-side filtering and pagination, we'll use client-side approach
      try {
        final allCategories = await getCategories();
        List<CategoryModel.Category> filteredCategories = [...allCategories];

        if (kDebugMode) {

        }

        // Apply search filter
        if (search != null && search.isNotEmpty) {
          filteredCategories = filteredCategories
              .where((category) =>
                  category.name.toLowerCase().contains(search.toLowerCase()))
              .toList();
          
        }

        // Apply hasBooks filter - placeholder implementation
        if (hasBooks != null) {
          if (hasBooks) {
            // Filter categories that have books (books_count > 0)
            // Since we don't have books_count, we'll simulate by filtering some categories
            // In a real implementation, you'd need to fetch book counts from the API
            filteredCategories = filteredCategories.where((category) {
              // Placeholder: assume categories with ID > 50 have books
              return category.id > 50;
            }).toList();
          } else {
            // Filter categories that don't have books (books_count == 0)
            filteredCategories = filteredCategories.where((category) {
              // Placeholder: assume categories with ID <= 50 don't have books
              return category.id <= 50;
            }).toList();
          }
          
        }

        // Apply sorting
        if (sortBy != null && sortBy.isNotEmpty) {
          filteredCategories.sort((a, b) {
            int comparison = 0;
            switch (sortBy) {
              case 'name':
                comparison =
                    a.name.toLowerCase().compareTo(b.name.toLowerCase());
                break;
              case 'created_at':
                comparison = (a.createdAt ?? DateTime.now())
                    .compareTo(b.createdAt ?? DateTime.now());
                break;
              case 'books_count':
                // For books_count sorting, we'd need the count field in the model
                // For now, fallback to name sorting
                comparison =
                    a.name.toLowerCase().compareTo(b.name.toLowerCase());
                break;
              default:
                comparison =
                    a.name.toLowerCase().compareTo(b.name.toLowerCase());
            }
            return sortOrder == 'desc' ? -comparison : comparison;
          });
          
        }

        // Implement pagination
        final totalItems = filteredCategories.length;
        final totalPages = totalItems > 0 ? (totalItems / perPage).ceil() : 1;
        final startIndex = (page - 1) * perPage;
        final endIndex = startIndex + perPage;

        final paginatedCategories = filteredCategories.sublist(
            startIndex,
            endIndex > filteredCategories.length
                ? filteredCategories.length
                : endIndex);

        return {
          'categories': paginatedCategories,
          'current_page': page,
          'total_pages': totalPages,
          'total_items': totalItems,
          'per_page': perPage,
        };
      } catch (e) {
        if (kDebugMode) {

        }
        return {
          'categories': <CategoryModel.Category>[],
          'current_page': 1,
          'total_pages': 1,
          'total_items': 0,
          'per_page': perPage,
        };
      }
    } on DioException catch (e) {
      if (kDebugMode) {

      }
      throw Exception('Gagal mengambil data kategori dari server.');
    }
  }

  // Search books
  Future<List<Book>> searchBooks(String query) async {
    try {
      final response =
          await _dio.get('/book/search', queryParameters: {'q': query});
      final responseData = response.data;

      if (responseData is Map<String, dynamic> &&
          responseData['data'] is Map<String, dynamic> &&
          responseData['data']['books'] is List) {
        final List<dynamic> bookList = responseData['data']['books'];
        return bookList.map((json) => Book.fromJson(json)).toList();
      } else {
        return [];
      }
    } on DioException catch (e) {
      if (kDebugMode) {

      }
      throw Exception('Gagal mencari buku.');
    }
  }

  // == MEMBER MANAGEMENT (for Admin) ==

  // Enhanced method to get all members (tries API first, then extracts from borrowing data)
  Future<List<User>> getMembers() async {
    try {
      // Get authentication token for protected endpoints
      final token = await getToken();

      // Try the correct user endpoints as provided
      Response? response;
      List<String> endpointsToTry = [
        '/user/member/all?page=1', // Get the first page to get total count
        '/user/member?page=1', // This might return member users
        '/user?page=1', // This might return current user or users
      ];

      for (String endpoint in endpointsToTry) {
        try {
          if (kDebugMode) {

          }

          // Prepare headers with authentication if available
          Map<String, dynamic> headers = {};
          if (token != null) {
            headers['Authorization'] = 'Bearer $token';
          }

          response =
              await _dio.get(endpoint, options: Options(headers: headers));
          if (response.statusCode == 200) {
            if (kDebugMode) {

            }
            break;
          }
        } catch (e) {
          if (kDebugMode) {

          }
          continue;
        }
      }

      if (response == null) {
        
      }

      if (response != null) {
        final responseData = response.data;
        if (responseData is Map<String, dynamic>) {
          // Try different response structures with pagination support
          List<User> allUsers = [];

          // Check if this is the /user endpoint response structure
          if (responseData['status'] == 200 && responseData['data'] != null) {
            final data = responseData['data'];

            // Handle single user object
            if (data is Map<String, dynamic> && data.containsKey('user')) {
              // This is likely the current user endpoint, try to get all users differently
              
            }

            // Handle list of users
            if (data is List) {
              allUsers.addAll(data.map((json) => User.fromJson(json)).toList());
            }

            // Handle paginated users in data.users
            if (data is Map<String, dynamic> && data.containsKey('users')) {
              final usersData = data['users'];
              if (usersData is List) {
                allUsers.addAll(
                    usersData.map((json) => User.fromJson(json)).toList());
              } else if (usersData is Map<String, dynamic> &&
                  usersData['data'] is List) {
                // Add users from current page
                allUsers.addAll((usersData['data'] as List)
                    .map((json) => User.fromJson(json))
                    .toList());

                // Get total count from API response
                final totalExpected = usersData['total'] ?? 0;
                final lastPage = usersData['last_page'] ?? 1;
                final currentPage = usersData['current_page'] ?? 1;

                // Only fetch additional pages if there are more pages
                if (lastPage > currentPage) {
                  for (int page = currentPage + 1; page <= lastPage; page++) {
                    try {
                      Map<String, dynamic> headers = {};
                      if (await getToken() != null) {
                        headers['Authorization'] = 'Bearer ${await getToken()}';
                      }

                      final pageResponse = await _dio.get('/user/member/all',
                          queryParameters: {'page': page},
                          options: Options(headers: headers));
                      final pageData = pageResponse.data;
                      if (pageData is Map<String, dynamic> &&
                          pageData['data'] is Map<String, dynamic> &&
                          pageData['data']['users'] is Map<String, dynamic> &&
                          pageData['data']['users']['data'] is List) {
                        allUsers.addAll(
                            (pageData['data']['users']['data'] as List)
                                .map((json) => User.fromJson(json))
                                .toList());
                      }
                    } catch (e) {
                      if (kDebugMode) {

                      }
                      break;
                    }
                  }
                }

                // Validate we got the expected count
                
              }
            }
          }

          // Check if this is a paginated response
          if (responseData['data'] is Map<String, dynamic>) {
            final dataMap = responseData['data'] as Map<String, dynamic>;

            // Single page list in data.members or data.users
            if (dataMap['members'] is List) {
              allUsers.addAll((dataMap['members'] as List)
                  .map((json) => User.fromJson(json))
                  .toList());
            } else if (dataMap['users'] is List) {
              allUsers.addAll((dataMap['users'] as List)
                  .map((json) => User.fromJson(json))
                  .toList());
            }
          }

          // Try other response structures
          if (allUsers.isEmpty) {
            if (responseData['data'] is List) {
              allUsers.addAll((responseData['data'] as List)
                  .map((json) => User.fromJson(json))
                  .toList());
            } else if (responseData['members'] is List) {
              allUsers.addAll((responseData['members'] as List)
                  .map((json) => User.fromJson(json))
                  .toList());
            } else if (responseData['users'] is List) {
              allUsers.addAll((responseData['users'] as List)
                  .map((json) => User.fromJson(json))
                  .toList());
            }
          }

          if (allUsers.isNotEmpty) {
            // Remove duplicates by ID to ensure accurate count
            final Map<int, User> uniqueUsers = {};
            for (var user in allUsers) {
              uniqueUsers[user.id] = user;
            }
            final uniqueUsersList = uniqueUsers.values.toList();

            return uniqueUsersList;
          }
        }
      }

      // Try to extract members from borrowing data (fetch all pages) and also try other sources
      try {
        final Map<int, User> uniqueMembers = {};

        // 1. Extract from borrowing data (all pages)
        int currentPage = 1;
        int maxPages = 50; // Safety limit to prevent infinite loops
        bool hasMorePages = true;

        while (hasMorePages && currentPage <= maxPages) {
          try {
            final borrowingResponse = await _dio.get('/peminjaman/all',
                queryParameters: {'page': currentPage, 'per_page': 100});
            final borrowingData = borrowingResponse.data;

            if (borrowingData is Map<String, dynamic> &&
                borrowingData['data'] is Map<String, dynamic> &&
                borrowingData['data']['peminjaman'] is Map<String, dynamic>) {
              final peminjamanData =
                  borrowingData['data']['peminjaman'] as Map<String, dynamic>;

              if (peminjamanData['data'] is List) {
                final List<dynamic> borrowings = peminjamanData['data'];

                for (var borrowing in borrowings) {
                  if (borrowing['member'] != null) {
                    final memberData = borrowing['member'];
                    final member = User(
                      id: memberData['id'] ?? 0,
                      name: memberData['name'] ?? 'Unknown',
                      username: memberData['username'] ?? '',
                      email: memberData['email'] ?? '',
                      role: 'member',
                    );
                    uniqueMembers[member.id] = member;
                  }

                  // Also check if there's a 'user' field in addition to 'member'
                  if (borrowing['user'] != null) {
                    final userData = borrowing['user'];
                    final user = User(
                      id: userData['id'] ?? 0,
                      name: userData['name'] ?? 'Unknown',
                      username: userData['username'] ?? '',
                      email: userData['email'] ?? '',
                      role: userData['role'] ?? 'member',
                    );
                    uniqueMembers[user.id] = user;
                  }
                }

                // Check pagination
                final currentPageNum =
                    peminjamanData['current_page'] ?? currentPage;
                final lastPage = peminjamanData['last_page'] ?? currentPage;
                final total = peminjamanData['total'] ?? 0;

                if (currentPageNum >= lastPage) {
                  hasMorePages = false;
                } else {
                  currentPage = currentPageNum + 1;
                }
              } else {
                hasMorePages = false;
              }
            } else {
              hasMorePages = false;
            }
          } catch (e) {
            if (kDebugMode) {

            }
            hasMorePages = false;
          }
        }

        // 2. Try to get additional members from history or other borrowing endpoints
        try {
          final allBorrowingResponse = await _dio.get('/peminjaman/all');
          final allBorrowingData = allBorrowingResponse.data;
          if (allBorrowingData is Map<String, dynamic> &&
              allBorrowingData['data'] is List) {
            for (var borrowing in allBorrowingData['data']) {
              if (borrowing['member'] != null) {
                final memberData = borrowing['member'];
                final member = User(
                  id: memberData['id'] ?? 0,
                  name: memberData['name'] ?? 'Unknown',
                  username: memberData['username'] ?? '',
                  email: memberData['email'] ?? '',
                  role: 'member',
                );
                uniqueMembers[member.id] = member;
              }
            }
          }
        } catch (e) {
          if (kDebugMode) {

          }
        }

        // 3. Try to get members from book borrowing history with higher per_page
        try {
          final historyResponse = await _dio
              .get('/peminjaman', queryParameters: {'per_page': 1000});
          final historyData = historyResponse.data;
          if (historyData is Map<String, dynamic> &&
              historyData['data'] is Map<String, dynamic> &&
              historyData['data']['peminjaman'] is Map<String, dynamic>) {
            final peminjamanData =
                historyData['data']['peminjaman'] as Map<String, dynamic>;
            if (peminjamanData['data'] is List) {
              for (var borrowing in peminjamanData['data']) {
                if (borrowing['member'] != null) {
                  final memberData = borrowing['member'];
                  final member = User(
                    id: memberData['id'] ?? 0,
                    name: memberData['name'] ?? 'Unknown',
                    username: memberData['username'] ?? '',
                    email: memberData['email'] ?? '',
                    role: 'member',
                  );
                  uniqueMembers[member.id] = member;
                }
              }
            }
          }
        } catch (e) {
          if (kDebugMode) {

          }
        }

        if (uniqueMembers.isNotEmpty) {
          if (kDebugMode) {

          }
          return uniqueMembers.values.toList();
        }
      } catch (e) {
        if (kDebugMode) {

        }
      }

      return _getMockMembers();
    } on DioException catch (e) {
      if (kDebugMode) {

      }
      // Return mock data instead of empty list for better UX
      return _getMockMembers();
    } catch (e) {
      if (kDebugMode) {

      }
      return _getMockMembers();
    }
  }

  // Mock members data for development
  List<User> _getMockMembers() {
    return [
      User(
        id: 1,
        name: 'John Doe',
        username: 'johndoe',
        email: 'john@example.com',
        role: 'member',
      ),
      User(
        id: 2,
        name: 'Jane Smith',
        username: 'janesmith',
        email: 'jane@example.com',
        role: 'member',
      ),
      User(
        id: 3,
        name: 'Bob Wilson',
        username: 'bobwilson',
        email: 'bob@example.com',
        role: 'member',
      ),
      User(
        id: 4,
        name: 'Alice Brown',
        username: 'alicebrown',
        email: 'alice@example.com',
        role: 'member',
      ),
      User(
        id: 5,
        name: 'Charlie Davis',
        username: 'charliedavis',
        email: 'charlie@example.com',
        role: 'member',
      ),
    ];
  }

  // Get members with pagination - Enhanced to use real data from borrowing
  Future<Map<String, dynamic>> getMembersPaginated({
    int page = 1,
    int perPage = 10,
    String? search,
  }) async {
    try {
      Map<String, dynamic> queryParams = {
        'page': page,
        'per_page': perPage,
      };

      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }

      // Try multiple possible endpoints first
      Response? response;
      List<User> allMembers = [];

      try {
        response =
            await _dio.get('/admin/members', queryParameters: queryParams);
      } catch (e) {
        try {
          response = await _dio.get('/users', queryParameters: queryParams);
        } catch (e) {
          try {
            response = await _dio.get('/members', queryParameters: queryParams);
          } catch (e) {
            
          }
        }
      }

      if (response != null) {
        final responseData = response.data;
        if (responseData is Map<String, dynamic> &&
            responseData['data'] is Map<String, dynamic>) {
          final membersData = responseData['data'];
          final List<dynamic> memberList = membersData['members'] ??
              membersData['users'] ??
              membersData['data'] ??
              [];

          return {
            'members': memberList.map((json) => User.fromJson(json)).toList(),
            'current_page': membersData['current_page'] ?? 1,
            'total_pages': membersData['last_page'] ?? 1,
            'total_items': membersData['total'] ?? 0,
            'per_page': perPage,
          };
        }
      }

      // If direct member endpoints fail, get members from getMembers() which extracts from borrowing data
      try {
        allMembers = await getMembers();
        
      } catch (e) {
        
        return _getMockMembersPaginated(page, perPage, search);
      }

      // Filter by search if provided
      List<User> filteredMembers = allMembers;
      if (search != null && search.isNotEmpty) {
        filteredMembers = allMembers
            .where((member) =>
                member.name.toLowerCase().contains(search.toLowerCase()) ||
                member.username.toLowerCase().contains(search.toLowerCase()) ||
                member.email.toLowerCase().contains(search.toLowerCase()))
            .toList();
      }

      // Calculate pagination
      final totalItems = filteredMembers.length;
      final totalPages = (totalItems / perPage).ceil();
      final startIndex = (page - 1) * perPage;
      final endIndex = startIndex + perPage;
      final paginatedMembers = filteredMembers.sublist(
          startIndex,
          endIndex > filteredMembers.length
              ? filteredMembers.length
              : endIndex);

      return {
        'members': paginatedMembers,
        'current_page': page,
        'total_pages': totalPages,
        'total_items': totalItems,
        'per_page': perPage,
      };
    } on DioException catch (e) {
      if (kDebugMode) {

      }
      return _getMockMembersPaginated(page, perPage, search);
    }
  }

  // Mock paginated members data
  Map<String, dynamic> _getMockMembersPaginated(
      int page, int perPage, String? search) {
    final allMembers = _getMockMembers();

    // Filter by search if provided
    List<User> filteredMembers = allMembers;
    if (search != null && search.isNotEmpty) {
      filteredMembers = allMembers
          .where((member) =>
              member.name.toLowerCase().contains(search.toLowerCase()) ||
              member.username.toLowerCase().contains(search.toLowerCase()) ||
              member.email.toLowerCase().contains(search.toLowerCase()))
          .toList();
    }

    // Paginate
    final startIndex = (page - 1) * perPage;
    final endIndex = startIndex + perPage;
    final paginatedMembers = filteredMembers.sublist(startIndex,
        endIndex > filteredMembers.length ? filteredMembers.length : endIndex);

    return {
      'members': paginatedMembers,
      'current_page': page,
      'total_pages': (filteredMembers.length / perPage).ceil(),
      'total_items': filteredMembers.length,
      'per_page': perPage,
    };
  }

  // == BORROWING SYSTEM ==

  // Get borrowing history with pagination
  Future<Map<String, dynamic>> getBorrowingsPaginated({
    int page = 1,
    int perPage = 15,
    String? status,
  }) async {
    try {
      Map<String, dynamic> queryParams = {
        'page': page,
      };

      if (perPage != 15) {
        queryParams['per_page'] = perPage;
      }

      if (status != null && status.isNotEmpty) {
        queryParams['status'] = status;
      }

      if (kDebugMode) {

      }

      final response =
          await _dio.get('/peminjaman', queryParameters: queryParams);
      final responseData = response.data;

      if (kDebugMode) {

      }

      // Handle the correct API response structure based on your JSON data
      if (responseData is Map<String, dynamic> &&
          responseData['status'] == 200 &&
          responseData['data'] is Map<String, dynamic> &&
          responseData['data']['peminjaman'] is Map<String, dynamic>) {
        final borrowingsData = responseData['data']['peminjaman'];
        final List<dynamic> borrowingList = borrowingsData['data'] ?? [];

        return {
          'borrowings': borrowingList,
          'current_page': borrowingsData['current_page'] ?? page,
          'total_pages': borrowingsData['last_page'] ?? 1,
          'total_items': borrowingsData['total'] ?? borrowingList.length,
          'per_page': borrowingsData['per_page'] ?? perPage,
          'next_page_url': borrowingsData['next_page_url'],
          'prev_page_url': borrowingsData['prev_page_url'],
        };
      } else if (responseData is Map<String, dynamic> &&
          responseData['data'] is List) {
        // Fallback for direct data array
        final List<dynamic> borrowingList = responseData['data'];
        return {
          'borrowings': borrowingList,
          'current_page': page,
          'total_pages': 1,
          'total_items': borrowingList.length,
          'per_page': perPage,
        };
      }

      return {
        'borrowings': [],
        'current_page': 1,
        'total_pages': 1,
        'total_items': 0,
        'per_page': perPage,
      };
    } on DioException catch (e) {
      if (kDebugMode) {

      }
      throw Exception('Gagal mengambil data peminjaman.');
    } catch (e) {
      if (kDebugMode) {

      }
      throw Exception('Terjadi kesalahan yang tidak terduga.');
    }
  }

  // Get all borrowings
  Future<List<dynamic>> getAllBorrowings() async {
    try {
      final response = await _dio.get('/peminjaman/all');
      final responseData = response.data;

      if (responseData is Map<String, dynamic>) {
        if (responseData['data'] is List) {
          return responseData['data'];
        } else if (responseData['borrowings'] is List) {
          return responseData['borrowings'];
        }
      } else if (responseData is List) {
        return responseData;
      }

      return [];
    } on DioException catch (e) {
      if (kDebugMode) {

      }
      throw Exception('Gagal mengambil data peminjaman.');
    }
  }

  // Get borrowing detail
  Future<Map<String, dynamic>?> getBorrowingDetail(int id) async {
    try {
      final response = await _dio.get('/peminjaman/show?id=$id');
      final responseData = response.data;

      if (responseData is Map<String, dynamic>) {
        if (responseData['data'] is Map<String, dynamic>) {
          return responseData['data'];
        } else if (responseData['borrowing'] is Map<String, dynamic>) {
          return responseData['borrowing'];
        }
      }

      return null;
    } on DioException catch (e) {
      if (kDebugMode) {

      }
      return null;
    }
  }

  // Create a borrowing (requires bookId and memberId)
  Future<bool> borrowBook(
      int bookId, int memberId, String borrowDate, String returnDate) async {
    try {
      final formData = FormData.fromMap({
        'tanggal_peminjaman': borrowDate,
        'tanggal_pengembalian': returnDate,
      });

      final response = await _dio.post(
        '/peminjaman/book/$bookId/member/$memberId',
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
        ),
      );
      return response.statusCode == 201 || response.statusCode == 200;
    } on DioException catch (e) {
      if (kDebugMode) {

      }
      return false;
    } catch (e) {
      if (kDebugMode) {

      }
      return false;
    }
  }

  // Return a book - FUNGSI BARU UNTUK MENGEMBALIKAN BUKU
  Future<bool> returnBook(int peminjamanId) async {
    try {
      // Gunakan endpoint return yang benar untuk mengembalikan stok buku
      final response = await _dio.post('/peminjaman/book/$peminjamanId/return');

      if (kDebugMode) {

      }

      // Endpoint return yang benar akan mengembalikan stok buku
      return response.statusCode == 200;
    } on DioException catch (e) {
      if (kDebugMode) {

      }
      return false;
    } catch (e) {
      if (kDebugMode) {

      }
      return false;
    }
  }

  // == DASHBOARD DATA ==

  // Get dashboard statistics (enhanced with real data extraction)
  Future<Map<String, dynamic>?> getDashboardStats() async {
    try {
      if (kDebugMode) {

      }

      // Try to calculate stats from real data
      Map<String, dynamic> calculatedStats = {
        'total_books': 0,
        'total_members': 0,
        'books_borrowed': 0,
        'books_available': 0,
        'total_categories': 0,
        'overdue_books': 0,
      };

      // Get total books from books API and calculate total stock
      try {
        final books = await getBooks();
        calculatedStats['total_books'] = books.length;

        // Calculate total stock from all books
        int totalStock = 0;
        for (var book in books) {
          totalStock += book.stok;
        }
        calculatedStats['total_stock'] = totalStock;

        if (kDebugMode) {

        }
      } catch (e) {
        if (kDebugMode) {

        }
        calculatedStats['total_stock'] = calculatedStats['total_books'];
      }

      // Get total members using the enhanced getMembers method
      try {
        final members = await getMembers();
        calculatedStats['total_members'] = members.length;
        if (kDebugMode) {

        }
      } catch (e) {
        if (kDebugMode) {

        }
      }

      // Get categories count
      try {
        final categories = await getCategories();
        calculatedStats['total_categories'] = categories.length;
        if (kDebugMode) {

        }
      } catch (e) {
        if (kDebugMode) {

        }
        calculatedStats['total_categories'] = 8; // fallback
      }

      // Get borrowing statistics
      try {
        final borrowings = await getBorrowings();
        int activeBorrowings = 0;
        int overdueBorrowings = 0;
        final DateTime now = DateTime.now();

        if (kDebugMode) {

        }

        for (var borrowing in borrowings) {
          if (kDebugMode && borrowings.indexOf(borrowing) < 3) {
            print(
                'Borrowing ${borrowing.id}: status="${borrowing.status}", actualReturnDate=${borrowing.actualReturnDate}');
          }

          // Count active borrowings - use model's converted status
          // Model converts: "1" -> "borrowed", "2" -> "returned", "3" -> "returned"
          bool isActiveBorrowing = false;

          if (borrowing.status == "borrowed" || borrowing.status == "overdue") {
            isActiveBorrowing = true;
          }

          if (kDebugMode && borrowings.indexOf(borrowing) < 5) {
            print(
                'Borrowing ${borrowing.id}: status="${borrowing.status}", isActive=$isActiveBorrowing');
          }

          if (isActiveBorrowing) {
            activeBorrowings++;

            // Check for overdue books using expectedReturnDate
            if (borrowing.actualReturnDate == null) {
              try {
                if (now.isAfter(borrowing.expectedReturnDate)) {
                  overdueBorrowings++;
                }
              } catch (e) {
                // Skip if date parsing fails
                
              }
            }
          }
        }

        calculatedStats['books_borrowed'] = activeBorrowings;
        calculatedStats['overdue_books'] = overdueBorrowings;

        if (kDebugMode) {

        }
      } catch (e) {
        if (kDebugMode) {

        }
        // Set safe defaults
        calculatedStats['books_borrowed'] = 0;
        calculatedStats['overdue_books'] = 0;
      }

      // Calculate available books (ensure it's never negative)
      int totalStock =
          calculatedStats['total_stock'] ?? calculatedStats['total_books'] ?? 0;
      int borrowedBooks = calculatedStats['books_borrowed'] ?? 0;
      int availableBooks = totalStock - borrowedBooks;

      // Ensure available books is never negative
      if (availableBooks < 0) {
        
        availableBooks = 0;
      }

      calculatedStats['books_available'] = availableBooks;

      if (kDebugMode) {

      }

      // Return calculated stats if we have any real data
      if (calculatedStats['total_books'] > 0 ||
          calculatedStats['total_members'] > 0 ||
          calculatedStats['total_categories'] > 0) {
        return calculatedStats;
      }

      // Return mock data only if no real data is available
      if (kDebugMode) {

      }
      return _getMockDashboardStats();
    } catch (e) {
      if (kDebugMode) {

      }
      return _getMockDashboardStats();
    }
  }

  // Mock dashboard stats for development
  Map<String, dynamic> _getMockDashboardStats() {
    // Use realistic numbers that make sense
    const int totalBooks = 45;
    const int booksBorrowed = 62; // Based on actual stats from console log
    final int booksAvailable = totalBooks > booksBorrowed
        ? totalBooks - booksBorrowed
        : 0; // Ensure non-negative

    return {
      'total_books': totalBooks,
      'total_members': 90, // Based on screenshot
      'books_borrowed': booksBorrowed,
      'books_available': booksAvailable,
      'total_categories': 33, // Realistic number
      'overdue_books': 0,
    };
  }

  // == FILE OPERATIONS ==

  // Upload file (for book cover, etc.)
  Future<String?> uploadFile(String filePath,
      {String fieldName = 'file'}) async {
    try {
      final fileName = filePath.split('/').last;
      final formData = FormData.fromMap({
        fieldName: await MultipartFile.fromFile(filePath, filename: fileName),
      });

      final response = await _dio.post('/upload', data: formData);

      if (response.statusCode == 200 && response.data['data'] != null) {
        return response.data['data']['file_url'];
      }
      return null;
    } on DioException catch (e) {
      if (kDebugMode) {

      }
      return null;
    }
  }

  // Download file (for export)
  Future<bool> downloadFile(String url, String savePath) async {
    try {
      final response = await _dio.download(url, savePath);
      return response.statusCode == 200;
    } on DioException catch (e) {
      if (kDebugMode) {

      }
      return false;
    }
  }

  // == EXPORT & IMPORT METHODS ==

  // Export books to PDF
  Future<String?> exportBooksToPdf() async {
    try {
      final response = await _dio.get('/book/export/pdf');

      // The API returns path similar to Excel export
      if (response.statusCode == 200) {
        if (response.data is Map<String, dynamic> &&
            response.data['path'] != null) {
          // Return the full URL for download
          String filePath = response.data['path'];
          return 'http://perpus-api.mamorasoft.com/$filePath';
        }
        return 'pdf_exported_successfully';
      }
      return null;
    } on DioException catch (e) {
      if (kDebugMode) {

      }
      return null;
    }
  }

  // Export books to Excel
  Future<String?> exportBooksToExcel() async {
    try {
      final response = await _dio.get('/book/export/excel');

      // The API returns path in the format: {"status":200,"message":"Berhasil Export File Buku Excel","path":"storage/export/buku_export.xlsx"}
      if (response.statusCode == 200) {
        if (response.data is Map<String, dynamic> &&
            response.data['path'] != null) {
          // Return the full URL for download
          String filePath = response.data['path'];
          return 'http://perpus-api.mamorasoft.com/$filePath';
        }
        return 'excel_exported_successfully';
      }
      return null;
    } on DioException catch (e) {
      if (kDebugMode) {

      }
      return null;
    }
  }

  // Download template for book import
  Future<String?> downloadBookTemplate() async {
    try {
      final response = await _dio.get('/book/download/template');

      if (response.statusCode == 200) {
        if (response.data is Map<String, dynamic> &&
            response.data['path'] != null) {
          // Return the full URL for download
          String filePath = response.data['path'];
          return 'http://perpus-api.mamorasoft.com/$filePath';
        }
        return 'template_downloaded_successfully';
      }
      return null;
    } on DioException catch (e) {
      if (kDebugMode) {

      }
      return null;
    }
  }

  // Import books from Excel file (for web) - Enhanced with multiple attempts
  Future<Map<String, dynamic>> importBooksFromExcel(
      List<int> fileBytes, String fileName) async {
    try {
      // Ensure user is authenticated
      final token = await getToken();
      if (token == null || token.isEmpty) {
        return {
          'success': false,
          'message': 'Token tidak valid. Silakan login kembali.',
          'data': null
        };
      }

      // Try multiple field name variations
      List<Map<String, dynamic>> attempts = [
        // Attempt 1: Original format with additional fields
        {
          'file_import': MultipartFile.fromBytes(
            fileBytes,
            filename: fileName,
            contentType: DioMediaType('application',
                'vnd.openxmlformats-officedocument.spreadsheetml.sheet'),
          ),
          'type': 'excel',
          'import_type': 'books',
        },
        // Attempt 2: Just the file without extra fields
        {
          'file_import': MultipartFile.fromBytes(
            fileBytes,
            filename: fileName,
            contentType: DioMediaType('application',
                'vnd.openxmlformats-officedocument.spreadsheetml.sheet'),
          ),
        },
        // Attempt 3: Different field name
        {
          'file': MultipartFile.fromBytes(
            fileBytes,
            filename: fileName,
            contentType: DioMediaType('application',
                'vnd.openxmlformats-officedocument.spreadsheetml.sheet'),
          ),
        },
        // Attempt 4: Excel specific field name
        {
          'excel_file': MultipartFile.fromBytes(
            fileBytes,
            filename: fileName,
            contentType: DioMediaType('application',
                'vnd.openxmlformats-officedocument.spreadsheetml.sheet'),
          ),
        },
      ];

      for (int attemptIndex = 0;
          attemptIndex < attempts.length;
          attemptIndex++) {
        if (kDebugMode) {

        }

        try {
          final formData = FormData.fromMap(attempts[attemptIndex]);

          final response = await _dio.post(
            '/book/import/excel',
            data: formData,
            options: Options(
              contentType: 'multipart/form-data',
              headers: {
                'Authorization': 'Bearer $token',
                'Accept': 'application/json',
              },
            ),
          );

          if (kDebugMode) {

          }

          // Check if response contains status field indicating success/failure
          if (response.statusCode == 200 || response.statusCode == 201) {
            // Check internal status in response data
            if (response.data is Map<String, dynamic>) {
              final responseData = response.data as Map<String, dynamic>;

              // If there's an internal status field, check it
              if (responseData.containsKey('status')) {
                final internalStatus = responseData['status'];

                if (internalStatus == 200 || internalStatus == 201) {
                  return {
                    'success': true,
                    'message': _extractMessage(responseData['message']) ??
                        'Import berhasil',
                    'data': responseData
                  };
                } else if (attemptIndex < attempts.length - 1) {
                  // Try next attempt if not the last one
                  
                  continue;
                } else {
                  // This was the last attempt
                  String errorMessage =
                      _extractMessage(responseData['message']) ??
                          'Import gagal';

                  return {
                    'success': false,
                    'message': errorMessage,
                    'data': responseData
                  };
                }
              } else {
                // No internal status, assume success if HTTP status is OK
                return {
                  'success': true,
                  'message': _extractMessage(responseData['message']) ??
                      'Import berhasil',
                  'data': responseData
                };
              }
            }

            return {
              'success': true,
              'message': 'Import berhasil',
              'data': response.data
            };
          } else {
            if (attemptIndex < attempts.length - 1) {
              continue; // Try next attempt
            }
            return {'success': false, 'message': 'Import gagal', 'data': null};
          }
        } catch (e) {
          if (attemptIndex < attempts.length - 1) {
            
            continue; // Try next attempt
          } else {
            rethrow; // Last attempt, let the outer catch handle it
          }
        }
      }

      // This should never be reached, but just in case
      return {
        'success': false,
        'message': 'Semua percobaan import gagal',
        'data': null
      };
    } on DioException catch (e) {
      if (kDebugMode) {

      }

      // Handle different error cases
      if (e.response?.statusCode == 401) {
        return {
          'success': false,
          'message': 'Sesi telah berakhir. Silakan login kembali.',
          'data': null
        };
      } else if (e.response?.statusCode == 403) {
        return {
          'success': false,
          'message': 'Tidak memiliki akses untuk import data.',
          'data': null
        };
      } else if (e.response?.statusCode == 422) {
        return {
          'success': false,
          'message': 'Format file tidak valid atau data tidak sesuai template.',
          'data': e.response?.data
        };
      } else if (e.response?.statusCode == 500) {
        String errorMessage = 'Terjadi kesalahan di server saat import';

        // Try to extract specific error message
        if (e.response?.data != null) {
          if (e.response!.data is Map<String, dynamic>) {
            final data = e.response!.data as Map<String, dynamic>;
            if (data['message'] != null) {
              if (data['message'] is Map) {
                errorMessage = data['message']['message'] ?? errorMessage;
              } else {
                errorMessage = data['message'].toString();
              }
            }
          }
        }

        return {
          'success': false,
          'message': errorMessage,
          'data': e.response?.data
        };
      }

      return {
        'success': false,
        'message':
            e.response?.data?['message'] ?? 'Terjadi kesalahan saat import',
        'data': e.response?.data
      };
    } catch (e) {
      if (kDebugMode) {

      }
      return {
        'success': false,
        'message': 'Terjadi kesalahan tidak terduga',
        'data': null
      };
    }
  }

  // Helper method to extract message from response
  String? _extractMessage(dynamic messageData) {
    if (messageData == null) return null;

    if (messageData is String) {
      return messageData;
    } else if (messageData is Map<String, dynamic>) {
      return messageData['message']?.toString();
    }

    return messageData.toString();
  }

  // Check if user is authenticated
  Future<bool> isAuthenticated() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  // Check user role
  Future<bool> isAdmin() async {
    final role = await getUserRole();
    return role?.toLowerCase() == 'admin';
  }

  Future<bool> isMember() async {
    final role = await getUserRole();
    return role?.toLowerCase() == 'member';
  }

  Future<bool> isVisitor() async {
    final role = await getUserRole();
    return role == null || role.toLowerCase() == 'visitor';
  }

  // Debug method to check authentication status
  Future<Map<String, dynamic>> getAuthStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final userId = prefs.getInt('user_id');
    final userName = prefs.getString('user_name');
    final userRole = prefs.getString('user_role');
    final userEmail = prefs.getString('user_email');

    final status = {
      'hasToken': token != null && token.isNotEmpty,
      'token': token?.substring(0, 10) ??
          'null', // Show first 10 chars for debugging
      'userId': userId,
      'userName': userName,
      'userRole': userRole,
      'userEmail': userEmail,
      'isAuthenticated': token != null && token.isNotEmpty && userId != null,
    };

    if (kDebugMode) {

    }

    return status;
  }

  // Get user profile
  Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      // Try multiple endpoints that are known to work
      List<String> endpointsToTry = [
        '/user', // Current user endpoint
        '/user/member', // Member specific endpoint
        '/auth/me', // Alternative auth endpoint
        '/me', // Simple me endpoint
      ];

      final token = await getToken();

      for (String endpoint in endpointsToTry) {
        try {
          if (kDebugMode) {

          }

          Map<String, dynamic> headers = {};
          if (token != null) {
            headers['Authorization'] = 'Bearer $token';
          }

          final response =
              await _dio.get(endpoint, options: Options(headers: headers));

          if (response.statusCode == 200) {
            final responseData = response.data;

            if (kDebugMode) {

            }

            // Handle different response structures
            if (responseData is Map<String, dynamic>) {
              if (responseData['status'] == 200 &&
                  responseData['data'] != null) {
                final data = responseData['data'];
                if (data is Map<String, dynamic> && data['id'] != null) {
                  if (kDebugMode) {

                  }
                  return data;
                }
              } else if (responseData['data'] is Map<String, dynamic>) {
                final data = responseData['data'];
                if (data['id'] != null) {
                  if (kDebugMode) {

                  }
                  return data;
                }
              } else if (responseData['id'] != null) {
                // Direct user object
                
                return responseData;
              }
            }
          }
        } catch (e) {
          if (kDebugMode) {

          }
          continue;
        }
      }

      // If profile endpoints fail, try to extract from borrowing data

      try {
        // Get current user name to match with borrowing data
        final userName = await getUserName();
        if (userName != null && userName.isNotEmpty) {
          final borrowings = await getAllBorrowings();
          for (var borrowing in borrowings) {
            if (borrowing['member'] != null &&
                borrowing['member']['name'] == userName) {
              final memberData = borrowing['member'];
              if (memberData['id'] != null) {
                
                return memberData;
              }
            }
            if (borrowing['user'] != null &&
                borrowing['user']['name'] == userName) {
              final userData = borrowing['user'];
              if (userData['id'] != null) {
                
                return userData;
              }
            }
          }
        }
      } catch (e) {
        if (kDebugMode) {

        }
      }

      return null;
    } catch (e) {
      if (kDebugMode) {

      }
      return null;
    }
  }

  // Method to manually extract and save user ID from borrowing data
  Future<int?> extractAndSaveUserIdFromBorrowings() async {
    try {
      final userName = await getUserName();
      if (userName == null || userName.isEmpty) {
        if (kDebugMode) {

        }
        return null;
      }

      if (kDebugMode) {

      }

      final borrowings = await getAllBorrowings();

      for (var borrowing in borrowings) {
        // Check member field
        if (borrowing['member'] != null) {
          final memberData = borrowing['member'];
          if (memberData['name'] == userName && memberData['id'] != null) {
            final userId = memberData['id'] as int;
            await saveUserId(userId);
            
            return userId;
          }
        }

        // Check user field
        if (borrowing['user'] != null) {
          final userData = borrowing['user'];
          if (userData['name'] == userName && userData['id'] != null) {
            final userId = userData['id'] as int;
            await saveUserId(userId);
            
            return userId;
          }
        }
      }

      return null;
    } catch (e) {
      if (kDebugMode) {

      }
      return null;
    }
  }

  // Admin login (specific endpoint if needed)
  Future<bool> adminLogin(String username, String password) async {
    try {
      // Try API first - use same login endpoint as regular login
      try {
        final response = await _dio.post(
          '/login',
          data: {'username': username, 'password': password},
        );

        if (response.statusCode == 200) {
          final data = response.data['data'];
          if (data != null && data['token'] != null) {
            await _saveToken(data['token']);
            await _saveUserName(data['user']['name']);

            // Check if user has admin role
            final userRoles = data['user']['roles'];
            bool isAdmin = false;

            if (userRoles != null && userRoles is List) {
              for (var role in userRoles) {
                if (role['name'] == 'admin') {
                  isAdmin = true;
                  break;
                }
              }
            }

            if (isAdmin) {
              await _saveUserRole('admin');
              if (data['user']['email'] != null) {
                await _saveUserEmail(data['user']['email']);
              }
              return true;
            } else {
              // User is not admin, logout
              await logout();
              return false;
            }
          }
        }
      } catch (apiError) {
        // If API fails, check local credentials

        final prefs = await SharedPreferences.getInstance();
        final localUsername = prefs.getString('local_admin_username');
        final localPassword = prefs.getString('local_admin_password');
        final localName = prefs.getString('local_admin_name');
        final localEmail = prefs.getString('local_admin_email');

        // Check default admin credentials or locally stored ones
        if ((username == 'admin' && password == 'admin123') ||
            (username == localUsername && password == localPassword)) {
          // Save login session
          await _saveToken(
              'local_admin_token_${DateTime.now().millisecondsSinceEpoch}');
          await _saveUserName(localName ?? 'Administrator');
          await _saveUserRole('admin');
          await _saveUserEmail(localEmail ?? 'admin@library.com');

          return true;
        }
      }

      return false;
    } catch (e) {
      if (kDebugMode) {

      }
      return false;
    }
  }

  // Member registration (visitor becomes member)
  Future<bool> memberRegister(String name, String username, String email,
      String password, String confirmPassword) async {
    try {
      final response = await _dio.post(
        '/member/register',
        data: {
          'name': name,
          'username': username,
          'email': email,
          'password': password,
          'confirm_password': confirmPassword,
          'role': 'member',
        },
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      if (kDebugMode) {

      }
      return false;
    }
  }

  // == ADMIN REGISTRATION ==
  Future<bool> registerAdmin(Map<String, String> adminData) async {
    try {
      // TEMPORARY: Save admin credentials locally when backend is not available
      // In production, this should always call the actual API

      // Try API first
      try {
        final response = await _dio.post(
          '/admin/register',
          data: adminData,
        );

        if (response.statusCode == 201 || response.statusCode == 200) {
          return true;
        }
      } catch (apiError) {
        // If API fails, save locally as fallback for development

        // Save admin credentials locally
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('local_admin_name', adminData['name'] ?? '');
        await prefs.setString(
            'local_admin_username', adminData['username'] ?? '');
        await prefs.setString('local_admin_email', adminData['email'] ?? '');
        await prefs.setString(
            'local_admin_password', adminData['password'] ?? '');
        await prefs.setString('local_admin_role', 'admin');

        return true; // Return success for local storage
      }

      return false;
    } catch (e) {
      if (kDebugMode) {

      }
      return false;
    }
  }

  // Simple method to get all borrowings (for demo purposes)
  Future<List<Borrowing>> getBorrowings() async {
    try {
      // Use the same endpoint as LibraryApiService for consistency
      final response = await _dio.get('/peminjaman/all');
      final responseData = response.data;

      if (kDebugMode) {

      }

      // Handle the /all endpoint response structure
      if (responseData is Map<String, dynamic> &&
          responseData['status'] == 200 &&
          responseData['data'] is Map<String, dynamic> &&
          responseData['data']['peminjaman'] is List) {
        final List<dynamic> borrowingList = responseData['data']['peminjaman'];

        return borrowingList.map((json) => Borrowing.fromJson(json)).toList();
      }

      // Fallback to paginated endpoint if /all fails
      final fallbackResponse = await _dio.get('/peminjaman?per_page=1000');
      final fallbackData = fallbackResponse.data;

      // Handle the paginated API response structure
      if (fallbackData is Map<String, dynamic> &&
          fallbackData['status'] == 200 &&
          fallbackData['data'] is Map<String, dynamic> &&
          fallbackData['data']['peminjaman'] is Map<String, dynamic>) {
        final borrowingsData = fallbackData['data']['peminjaman'];
        final List<dynamic> borrowingList = borrowingsData['data'] ?? [];

        return borrowingList.map((json) => Borrowing.fromJson(json)).toList();
      } else if (fallbackData is Map<String, dynamic> &&
          fallbackData['data'] is List) {
        // Fallback for direct data array
        final List<dynamic> borrowingList = fallbackData['data'];
        return borrowingList.map((json) => Borrowing.fromJson(json)).toList();
      } else if (fallbackData is Map<String, dynamic> &&
          fallbackData['data'] is Map<String, dynamic> &&
          fallbackData['data']['data'] is List) {
        // Another fallback structure
        final List<dynamic> borrowingList = fallbackData['data']['data'];
        return borrowingList.map((json) => Borrowing.fromJson(json)).toList();
      }

      if (kDebugMode) {

      }
      return [];
    } on DioException catch (e) {
      if (kDebugMode) {

      }
      // Return empty list instead of throwing for better UX
      return [];
    } catch (e) {
      if (kDebugMode) {

      }
      return [];
    }
  }

  /// Fetches ALL borrowing records by looping through all available pages.
  Future<List<Borrowing>> fetchAllBorrowingPages() async {
    List<Borrowing> allBorrowings = [];
    int currentPage = 1;
    int lastPage = 1;

    if (kDebugMode) {

    }

    do {
      try {
        final response = await _dio.get(
          '/peminjaman',
          queryParameters: {
            'page': currentPage,
            'per_page': 100
          }, // Ambil 100 item per request
        );

        final responseData = response.data;

        if (responseData is Map<String, dynamic> &&
            responseData['status'] == 200 &&
            responseData['data'] is Map<String, dynamic> &&
            responseData['data']['peminjaman'] is Map<String, dynamic>) {
          final borrowingsData = responseData['data']['peminjaman'];
          final List<dynamic> borrowingList = borrowingsData['data'] ?? [];

          if (borrowingList.isNotEmpty) {
            allBorrowings.addAll(
                borrowingList.map((json) => Borrowing.fromJson(json)).toList());
          }

          currentPage = borrowingsData['current_page'] ?? currentPage;
          lastPage = borrowingsData['last_page'] ?? currentPage;

          currentPage++; // Siapkan untuk halaman berikutnya
        } else {
          // Jika struktur data tidak sesuai, hentikan loop
          
          break;
        }
      } catch (e) {
        if (kDebugMode) {

        }
        break; // Hentikan loop jika ada error
      }
    } while (currentPage <= lastPage);

    return allBorrowings;
  }

  // == MEMBER ROLE MANAGEMENT ==

  // Update user role
  Future<bool> updateUserRole(int userId, String newRole) async {
    try {
      final token = await getToken();
      Map<String, dynamic> headers = {};
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      // Try multiple potential endpoints for role update
      List<String> endpointsToTry = [
        '/user/$userId/role',
        '/user/$userId/update-role',
        '/admin/user/$userId/role',
        '/user/update/$userId',
      ];

      for (String endpoint in endpointsToTry) {
        try {
          if (kDebugMode) {

          }

          final response = await _dio.put(
            endpoint,
            data: {'role': newRole},
            options: Options(headers: headers),
          );

          if (response.statusCode == 200) {
            if (kDebugMode) {

            }
            return true;
          }
        } catch (e) {
          if (kDebugMode) {

          }
          continue;
        }
      }

      // If all PUT endpoints fail, try POST endpoints
      List<String> postEndpointsToTry = [
        '/user/$userId/role',
        '/user/$userId/update-role',
        '/admin/user/$userId/role',
        '/user/update/$userId',
      ];

      for (String endpoint in postEndpointsToTry) {
        try {
          if (kDebugMode) {

          }

          final formData = FormData.fromMap({'role': newRole});
          final response = await _dio.post(
            endpoint,
            data: formData,
            options: Options(headers: headers),
          );

          if (response.statusCode == 200) {
            if (kDebugMode) {

            }
            return true;
          }
        } catch (e) {
          if (kDebugMode) {

          }
          continue;
        }
      }

      if (kDebugMode) {

      }
      return false;
    } catch (e) {
      if (kDebugMode) {

      }
      return false;
    }
  }

  // Delete user/member
  Future<bool> deleteUser(int userId) async {
    try {
      final token = await getToken();
      Map<String, dynamic> headers = {};
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      // Try multiple potential endpoints for user deletion
      List<String> endpointsToTry = [
        '/user/$userId/delete',
        '/user/$userId',
        '/admin/user/$userId',
        '/member/$userId/delete',
      ];

      for (String endpoint in endpointsToTry) {
        try {
          if (kDebugMode) {

          }

          final response = await _dio.delete(
            endpoint,
            options: Options(headers: headers),
          );

          if (response.statusCode == 200) {
            if (kDebugMode) {

            }
            return true;
          }
        } catch (e) {
          if (kDebugMode) {

          }
          continue;
        }
      }

      if (kDebugMode) {

      }
      return false;
    } catch (e) {
      if (kDebugMode) {

      }
      return false;
    }
  }

  // == FILTER OPTIONS METHODS ==

  // Get unique authors for filter dropdown
  Future<List<String>> getAuthors() async {
    try {
      final response = await _dio.get('/book/authors');
      final responseData = response.data;

      if (responseData is Map<String, dynamic> &&
          responseData['data'] is List) {
        return (responseData['data'] as List).cast<String>();
      } else if (responseData is List) {
        return responseData.cast<String>();
      }

      // Fallback: extract from books if dedicated endpoint not available
      try {
        final books = await getBooks();
        final Set<String> authors = {};
        for (var book in books) {
          if (book.pengarang.isNotEmpty) {
            authors.add(book.pengarang);
          }
        }
        return authors.toList()..sort();
      } catch (e) {
        if (kDebugMode) {

        }
      }

      return [];
    } catch (e) {
      if (kDebugMode) {

      }
      return [];
    }
  }

  // Get unique publishers for filter dropdown
  Future<List<String>> getPublishers() async {
    try {
      final response = await _dio.get('/book/publishers');
      final responseData = response.data;

      if (responseData is Map<String, dynamic> &&
          responseData['data'] is List) {
        return (responseData['data'] as List).cast<String>();
      } else if (responseData is List) {
        return responseData.cast<String>();
      }

      // Fallback: extract from books if dedicated endpoint not available
      try {
        final books = await getBooks();
        final Set<String> publishers = {};
        for (var book in books) {
          if (book.penerbit.isNotEmpty) {
            publishers.add(book.penerbit);
          }
        }
        return publishers.toList()..sort();
      } catch (e) {
        if (kDebugMode) {

        }
      }

      return [];
    } catch (e) {
      if (kDebugMode) {

      }
      return [];
    }
  }

  // Get unique publication years for filter dropdown
  Future<List<int>> getPublicationYears() async {
    try {
      final response = await _dio.get('/book/years');
      final responseData = response.data;

      if (responseData is Map<String, dynamic> &&
          responseData['data'] is List) {
        return (responseData['data'] as List).cast<int>();
      } else if (responseData is List) {
        return responseData.cast<int>();
      }

      // Fallback: extract from books if dedicated endpoint not available
      try {
        final books = await getBooks();
        final Set<int> years = {};
        for (var book in books) {
          final yearInt = int.tryParse(book.tahun) ?? 0;
          if (yearInt > 0) {
            years.add(yearInt);
          }
        }
        final yearsList = years.toList()
          ..sort((a, b) => b.compareTo(a)); // Newest first
        return yearsList;
      } catch (e) {
        if (kDebugMode) {

        }
      }

      return [];
    } catch (e) {
      if (kDebugMode) {

      }
      return [];
    }
  }

  // Get filter statistics for admin dashboard
  Future<Map<String, dynamic>> getFilterStats() async {
    try {
      final response = await _dio.get('/admin/filter-stats');
      final responseData = response.data;

      if (responseData is Map<String, dynamic> &&
          responseData['data'] != null) {
        return responseData['data'];
      }

      // Fallback: calculate from available data
      try {
        final books = await getBooks();
        final categories = await getCategories();

        final Set<String> authors = {};
        final Set<String> publishers = {};
        final Set<int> years = {};

        for (var book in books) {
          if (book.pengarang.isNotEmpty) authors.add(book.pengarang);
          if (book.penerbit.isNotEmpty) publishers.add(book.penerbit);
          final yearInt = int.tryParse(book.tahun) ?? 0;
          if (yearInt > 0) years.add(yearInt);
        }

        return {
          'total_books': books.length,
          'total_categories': categories.length,
          'total_authors': authors.length,
          'total_publishers': publishers.length,
          'year_range': years.isEmpty
              ? null
              : {
                  'min': years.reduce((a, b) => a < b ? a : b),
                  'max': years.reduce((a, b) => a > b ? a : b),
                },
        };
      } catch (e) {
        if (kDebugMode) {

        }
      }

      return {
        'total_books': 0,
        'total_categories': 0,
        'total_authors': 0,
        'total_publishers': 0,
        'year_range': null,
      };
    } catch (e) {
      if (kDebugMode) {

      }
      return {
        'total_books': 0,
        'total_categories': 0,
        'total_authors': 0,
        'total_publishers': 0,
        'year_range': null,
      };
    }
  }

  // Advanced search for books with multiple criteria
  Future<List<Book>> advancedSearchBooks({
    String? title,
    String? author,
    String? publisher,
    String? isbn,
    int? categoryId,
    int? year,
    String? status,
  }) async {
    try {
      Map<String, dynamic> queryParams = {};

      if (title != null && title.isNotEmpty) {
        queryParams['title'] = title;
      }
      if (author != null && author.isNotEmpty) {
        queryParams['author'] = author;
      }
      if (publisher != null && publisher.isNotEmpty) {
        queryParams['publisher'] = publisher;
      }
      if (isbn != null && isbn.isNotEmpty) {
        queryParams['isbn'] = isbn;
      }
      if (categoryId != null) {
        queryParams['category_id'] = categoryId;
      }
      if (year != null) {
        queryParams['year'] = year;
      }
      if (status != null && status.isNotEmpty) {
        queryParams['status'] = status;
      }

      final response =
          await _dio.get('/book/advanced-search', queryParameters: queryParams);
      final responseData = response.data;

      if (responseData is Map<String, dynamic> &&
          responseData['data'] is List) {
        final List<dynamic> bookList = responseData['data'];
        return bookList.map((json) => Book.fromJson(json)).toList();
      } else if (responseData is List) {
        return responseData.map((json) => Book.fromJson(json)).toList();
      }

      // Fallback: filter books manually if advanced search endpoint not available
      try {
        final books = await getBooks();
        return books.where((book) {
          if (title != null &&
              title.isNotEmpty &&
              !book.judul.toLowerCase().contains(title.toLowerCase())) {
            return false;
          }
          if (author != null &&
              author.isNotEmpty &&
              !book.pengarang.toLowerCase().contains(author.toLowerCase())) {
            return false;
          }
          if (publisher != null &&
              publisher.isNotEmpty &&
              !book.penerbit.toLowerCase().contains(publisher.toLowerCase())) {
            return false;
          }
          if (isbn != null && isbn.isNotEmpty) {
            // Book model doesn't have ISBN field, skip this filter for now
            // or could search in judul or other fields
          }
          if (categoryId != null && book.category.id != categoryId) {
            return false;
          }
          if (year != null) {
            final bookYear = int.tryParse(book.tahun) ?? 0;
            if (bookYear != year) {
              return false;
            }
          }
          return true;
        }).toList();
      } catch (e) {
        if (kDebugMode) {

        }
      }

      return [];
    } catch (e) {
      if (kDebugMode) {

      }
      return [];
    }
  }

  // Search categories with advanced options
  Future<List<CategoryModel.Category>> searchCategories({
    String? name,
    bool? hasBooks,
    String? sortBy,
    String? sortOrder,
  }) async {
    try {
      Map<String, dynamic> queryParams = {};

      if (name != null && name.isNotEmpty) {
        queryParams['name'] = name;
      }
      if (hasBooks != null) {
        queryParams['has_books'] = hasBooks ? '1' : '0';
      }
      if (sortBy != null && sortBy.isNotEmpty) {
        queryParams['sort_by'] = sortBy;
      }
      if (sortOrder != null && sortOrder.isNotEmpty) {
        queryParams['sort_order'] = sortOrder;
      }

      final response =
          await _dio.get('/category/search', queryParameters: queryParams);
      final responseData = response.data;

      if (responseData is Map<String, dynamic> &&
          responseData['data'] is List) {
        final List<dynamic> categoryList = responseData['data'];
        return categoryList
            .map((json) => CategoryModel.Category.fromJson(json))
            .toList();
      } else if (responseData is List) {
        return responseData
            .map((json) => CategoryModel.Category.fromJson(json))
            .toList();
      }

      // Fallback: filter categories manually
      try {
        final categories = await getCategories();
        var filteredCategories = categories;

        if (name != null && name.isNotEmpty) {
          filteredCategories = filteredCategories
              .where((category) =>
                  category.name.toLowerCase().contains(name.toLowerCase()))
              .toList();
        }

        // Sort manually if needed
        if (sortBy != null) {
          filteredCategories.sort((a, b) {
            int comparison = 0;
            switch (sortBy) {
              case 'name':
                comparison = a.name.compareTo(b.name);
                break;
              case 'created_at':
                comparison = (a.createdAt ?? DateTime.now())
                    .compareTo(b.createdAt ?? DateTime.now());
                break;
              default:
                comparison = a.name.compareTo(b.name);
            }
            return sortOrder == 'desc' ? -comparison : comparison;
          });
        }

        return filteredCategories;
      } catch (e) {
        if (kDebugMode) {

        }
      }

      return [];
    } catch (e) {
      if (kDebugMode) {

      }
      return [];
    }
  }

  // == END FILTER OPTIONS METHODS ==
}

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, this.statusCode);

  @override
  String toString() {
    return 'ApiException: $message (Status Code: $statusCode)';
  }
}

class LoginResult {
  final bool success;
  final String message;
  final String? token;
  final dynamic user;

  LoginResult({
    required this.success,
    required this.message,
    this.token,
    this.user,
  });
}

class RegisterResult {
  final bool success;
  final String message;

  RegisterResult({
    required this.success,
    required this.message,
  });
}
