import 'package:flutter/material.dart';

class MemberPlaceholderScreen extends StatelessWidget {
  const MemberPlaceholderScreen({
    super.key,
    required this.title,
    required this.hint,
  });

  final String title;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(hint, style: Theme.of(context).textTheme.bodyMedium),
      ),
    );
  }
}
