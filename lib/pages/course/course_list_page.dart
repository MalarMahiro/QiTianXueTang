import 'package:flutter/material.dart';
import '../../config/theme.dart';

class CourseListPage extends StatelessWidget {
  const CourseListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('精品课程')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.menu_book, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            const Text('课程功能开发中', style: TextStyle(fontSize: 16, color: AppTheme.textSecondary)),
          ],
        ),
      ),
    );
  }
}