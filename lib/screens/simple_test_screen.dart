import 'package:flutter/material.dart';
import 'member/books_list_screen_working.dart';

class SimpleTestScreen extends StatelessWidget {
  const SimpleTestScreen({super.key}); // Fixed: removed duplicate 'const'

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Test')),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    const MemberBooksListScreen(), // Add const if constructor is const
              ),
            );
          },
          child: const Text('Test Books List'),
        ),
      ),
    );
  }
}
