import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:perpus_app/screens/splash_screen.dart';
import 'package:perpus_app/providers/auth_provider.dart';
import 'package:perpus_app/providers/book_provider.dart';
import 'package:perpus_app/providers/category_provider.dart';
import 'package:perpus_app/providers/borrow_provider.dart';
import 'package:perpus_app/providers/theme_provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key}); // Fixed: removed duplicate 'const'

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => BookProvider()),
        ChangeNotifierProvider(create: (_) => CategoryProvider()),
        ChangeNotifierProvider(create: (_) => BorrowingProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Mamorasoft Library',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            home: const SplashScreen(),
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}
