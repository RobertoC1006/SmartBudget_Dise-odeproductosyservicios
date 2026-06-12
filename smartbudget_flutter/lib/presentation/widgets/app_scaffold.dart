import 'package:flutter/material.dart';
import 'bottom_nav_bar.dart';

class AppScaffold extends StatelessWidget {
  final int currentIndex;
  final Widget body;

  const AppScaffold({
    super.key,
    required this.currentIndex,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: body,
      bottomNavigationBar: BottomNavBar(
        currentIndex: currentIndex,
      ),
    );
  }
}
