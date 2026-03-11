import 'package:flutter/material.dart';

class AppInlineError extends StatelessWidget {
  const AppInlineError({
    super.key,
    required this.message,
    this.onRetry,
    this.retryLabel = 'Retry',
    this.padding = const EdgeInsets.all(12),
  });

  final String message;
  final VoidCallback? onRetry;
  final String retryLabel;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: padding,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.error_outline,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
            if (onRetry != null) ...[
              const SizedBox(width: 10),
              TextButton(
                onPressed: onRetry,
                child: Text(retryLabel),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
