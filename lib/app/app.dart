import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:life_ledger/core/di/injector.dart';
import 'package:life_ledger/core/theme/app_theme.dart';
import 'package:life_ledger/core/theme/tokens.dart';
import 'package:life_ledger/features/journal/presentation/pages/today_page.dart';
import 'package:life_ledger/features/onboarding/presentation/cubit/onboarding_cubit.dart';
import 'package:life_ledger/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:life_ledger/features/profile/application/get_current_user_id.dart';

/// The root widget: MaterialApp shell with Material 3 light/dark themes
/// (docs/05-uiux-system.md). Shows the skippable onboarding wizard on
/// first launch, then the interim "Today" home (M3); the full dashboard
/// replaces it in M4.
class LifeLedgerApp extends StatefulWidget {
  /// Creates the app shell.
  const LifeLedgerApp({this.showOnboarding = false, this.userId, super.key});

  /// Whether to open on the onboarding wizard.
  final bool showOnboarding;

  /// The resolved current user id (null before onboarding completes).
  final String? userId;

  @override
  State<LifeLedgerApp> createState() => _LifeLedgerAppState();
}

class _LifeLedgerAppState extends State<LifeLedgerApp> {
  late bool _showOnboarding = widget.showOnboarding;
  late String? _userId = widget.userId;

  Future<void> _onOnboardingFinished() async {
    // Onboarding (including skip) always leaves a profile; pick it up.
    final userId = (await getIt<GetCurrentUserId>().call()).valueOrNull;
    if (!mounted) return;
    setState(() {
      _userId = userId;
      _showOnboarding = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LifeLedger',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      home: _home(),
    );
  }

  Widget _home() {
    if (_showOnboarding) {
      return BlocProvider<OnboardingCubit>(
        create: (_) => getIt<OnboardingCubit>(),
        child: OnboardingPage(onFinished: _onOnboardingFinished),
      );
    }
    final userId = _userId;
    if (userId == null) return const ShellPlaceholder();
    return TodayPage(userId: userId);
  }
}

/// Fallback shell shown only if no profile could be resolved (should not
/// normally occur post-onboarding).
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
