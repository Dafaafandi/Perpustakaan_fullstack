import 'package:flutter/material.dart';

class SimpleBooksListScreen extends StatelessWidget {
  const SimpleBooksListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Books List'),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text(
          'Books List Screen\nComing Soon',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
