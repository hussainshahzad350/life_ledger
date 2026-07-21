import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:life_ledger/core/di/injector.dart';
import 'package:life_ledger/core/theme/app_theme.dart';
import 'package:life_ledger/core/theme/tokens.dart';
import 'package:life_ledger/features/onboarding/presentation/cubit/onboarding_cubit.dart';
import 'package:life_ledger/features/onboarding/presentation/pages/onboarding_page.dart';

/// The root widget: MaterialApp shell with Material 3 light/dark themes
/// (docs/05-uiux-system.md). Shows the skippable onboarding wizard on
/// first launch; the dashboard replaces the placeholder home in M4.
class LifeLedgerApp extends StatefulWidget {
  /// Creates the app shell. [showOnboarding] is true on first launch.
  const LifeLedgerApp({this.showOnboarding = false, super.key});

  /// Whether to open on the onboarding wizard.
  final bool showOnboarding;

  @override
  State<LifeLedgerApp> createState() => _LifeLedgerAppState();
}

class _LifeLedgerAppState extends State<LifeLedgerApp> {
  late bool _showOnboarding = widget.showOnboarding;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LifeLedger',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      home: _showOnboarding
          ? BlocProvider<OnboardingCubit>(
              create: (_) => getIt<OnboardingCubit>(),
              child: OnboardingPage(
                onFinished: () => setState(() => _showOnboarding = false),
              ),
            )
          : const ShellPlaceholder(),
    );
  }
}

/// Minimal home shell: proves theming and boots instantly.
/// Replaced by the real dashboard in M4 (docs/12-implementation-plan.md).
class ShellPlaceholder extends StatelessWidget {
  /// Creates the placeholder.
  const ShellPlaceholder({super.key});

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
