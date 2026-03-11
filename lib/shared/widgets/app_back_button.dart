import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppBackButton extends StatelessWidget {
  const AppBackButton({super.key});

  @override
  Widget build(BuildContext context) {
    if (!context.canPop()) {
      return const SizedBox.shrink();
    }
    return IconButton(
      tooltip: 'Back',
      onPressed: () => context.pop(),
      icon: const Icon(Icons.arrow_back),
    );
  }
}
