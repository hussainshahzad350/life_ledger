import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:life_ledger/core/database/app_database.dart';
import 'package:life_ledger/core/di/injector.dart';
import 'package:life_ledger/features/food/infrastructure/food_seeder.dart';
import 'package:life_ledger/features/journal/presentation/pages/today_page.dart';
import 'package:life_ledger/features/profile/domain/entities/user_profile.dart';
import 'package:life_ledger/features/profile/domain/repositories/profile_repository.dart';

/// On-device integration test for the core-logging flow (docs/11 §3.7 flow 1,
/// docs/12 M3 DoD): the < 10 s food log. Runs on an emulator/device in the
/// nightly job (docs/11 §6), not in the fast unit CI.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('cold-ish start → Quick-Add → food appears, under 10 seconds', (
    tester,
  ) async {
    final stopwatch = Stopwatch()..start();

    await configureDependencies();
    await getIt<AppDatabase>().open();
    await getIt<FoodSeeder>().seed();
    // A profile is required to attribute entries; create a default one.
    const userId = 'itest-user';
    await getIt<ProfileRepository>().saveProfile(const UserProfile(id: userId));

    await tester.pumpWidget(const MaterialApp(home: TodayPage(userId: userId)));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add food'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Egg').first);
    await tester.pumpAndSettle();

    stopwatch.stop();
    expect(find.text('Egg'), findsOneWidget);
    expect(
      stopwatch.elapsed.inSeconds,
      lessThan(10),
      reason: 'the core logging promise (FR-10)',
    );

    await getIt.reset();
  });
}
