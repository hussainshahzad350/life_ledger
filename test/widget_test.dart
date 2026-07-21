import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_ledger/app/app.dart';
import 'package:life_ledger/core/di/injector.dart';
import 'package:life_ledger/core/error/result.dart';
import 'package:life_ledger/features/data/domain/data_repository.dart';
import 'package:life_ledger/features/notifications/domain/reminder_scheduler.dart';
import 'package:life_ledger/features/onboarding/presentation/cubit/onboarding_cubit.dart';
import 'package:life_ledger/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:life_ledger/features/settings/domain/settings.dart';
import 'package:life_ledger/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:mocktail/mocktail.dart';

class MockOnboardingCubit extends MockCubit<OnboardingState>
    implements OnboardingCubit {}

class _StubSettingsRepository implements SettingsRepository {
  @override
  Future<Result<Settings>> load() async => const Result.success(Settings());

  @override
  Future<Result<void>> save(Settings settings) async =>
      const Result.success(null);
}

class _StubDataRepository implements DataRepository {
  @override
  Future<Result<String>> exportJson() async => const Result.success('{}');

  @override
  Future<Result<ImportResult>> importJson(String json) async =>
      const Result.success(ImportResult(rowsWritten: 0, migrated: false));

  @override
  Future<Result<void>> wipeAll() async => const Result.success(null);
}

void main() {
  group('app shell', () {
    setUp(() {
      getIt.registerFactory<SettingsCubit>(
        () => SettingsCubit(
          settings: _StubSettingsRepository(),
          data: _StubDataRepository(),
          cipher: const IdentityBackupCipher(),
          reminders: const NoopReminderScheduler(),
        ),
      );
    });
    tearDown(getIt.reset);

    testWidgets('renders the home placeholder', (tester) async {
      await tester.pumpWidget(const LifeLedgerApp());
      await tester.pump();
      expect(find.text('LifeLedger'), findsOneWidget);
      expect(
        find.text('Understand your body, one day at a time.'),
        findsOneWidget,
      );
    });
  });

  group('OnboardingPage (docs/08 F1)', () {
    late MockOnboardingCubit cubit;

    setUp(() {
      cubit = MockOnboardingCubit();
      whenListen(
        cubit,
        const Stream<OnboardingState>.empty(),
        initialState: const OnboardingInProgress(),
      );
      when(() => cubit.skip()).thenAnswer((_) async {});
    });

    Widget page({VoidCallback? onFinished}) => MaterialApp(
      home: BlocProvider<OnboardingCubit>.value(
        value: cubit,
        child: OnboardingPage(onFinished: onFinished ?? () {}),
      ),
    );

    testWidgets('renders the wizard with a visible Skip action (FR-4)', (
      tester,
    ) async {
      await tester.pumpWidget(page());
      expect(find.text('Welcome to LifeLedger'), findsOneWidget);
      expect(find.text('Skip'), findsOneWidget);
      // The privacy promise is stated up front.
      expect(find.textContaining('stays on'), findsOneWidget);
      // The submit button lives at the end of the scrollable wizard.
      await tester.scrollUntilVisible(
        find.text('Set my goals'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Set my goals'), findsOneWidget);
    });

    testWidgets('tapping Skip delegates to the cubit', (tester) async {
      await tester.pumpWidget(page());
      await tester.tap(find.text('Skip'));
      verify(() => cubit.skip()).called(1);
    });

    testWidgets('completion transition calls onFinished', (tester) async {
      whenListen(
        cubit,
        Stream<OnboardingState>.fromIterable(const [
          OnboardingSaving(),
          OnboardingDone(skipped: false),
        ]),
        initialState: const OnboardingInProgress(),
      );
      var finished = false;
      await tester.pumpWidget(page(onFinished: () => finished = true));
      await tester.pump();
      await tester.pump();
      expect(finished, isTrue);
    });
  });
}
