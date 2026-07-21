import 'package:flutter/material.dart';

import 'package:life_ledger/core/theme/app_theme.dart';
import 'package:life_ledger/core/theme/tokens.dart';

/// The root widget: MaterialApp shell with Material 3 light/dark themes
/// (docs/05-uiux-system.md). Navigation destinations arrive with their
/// feature milestones; M0 ships a minimal home shell.
class LifeLedgerApp extends StatelessWidget {
  /// Creates the app shell.
  const LifeLedgerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LifeLedger',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      home: const _ShellPlaceholder(),
    );
  }
}

/// Minimal M0 home: proves theming, boots instantly, and states what's next.
/// Replaced by the real dashboard in M4 (docs/12-implementation-plan.md).
class _ShellPlaceholder extends StatelessWidget {
  const _ShellPlaceholder();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppTokens.space6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.favorite_outline,
                size: 56,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: AppTokens.space4),
              Text('LifeLedger', style: textTheme.headlineMedium),
              const SizedBox(height: AppTokens.space2),
              Text(
                'Understand your body, one day at a time.',
                style: textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
