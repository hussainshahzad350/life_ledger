import 'package:flutter_test/flutter_test.dart';
import 'package:life_ledger/features/exercise/domain/exercise_entry.dart';
import 'package:life_ledger/features/mood/domain/mood_entry.dart';
import 'package:life_ledger/features/sleep/domain/sleep_entry.dart';
import 'package:life_ledger/features/symptoms/domain/symptom.dart';

void main() {
  final at = DateTime.utc(2026, 7, 21);
  const date = '2026-07-21';

  group('tracker entity equality (Equatable)', () {
    test('SleepEntry compares by value and exposes hours/minutes', () {
      final a = SleepEntry(
        id: 's1',
        userId: 'u1',
        durationMin: 455,
        quality: 3,
        loggedAt: at,
        localDate: date,
      );
      final b = SleepEntry(
        id: 's1',
        userId: 'u1',
        durationMin: 455,
        quality: 3,
        loggedAt: at,
        localDate: date,
      );
      expect(a, b);
      expect(a.hm, (7, 35));
    });

    test('MoodEntry compares by value', () {
      final a = MoodEntry(
        id: 'm1',
        userId: 'u1',
        mood: 4,
        loggedAt: at,
        localDate: date,
      );
      final b = MoodEntry(
        id: 'm1',
        userId: 'u1',
        mood: 4,
        loggedAt: at,
        localDate: date,
      );
      final c = MoodEntry(
        id: 'm1',
        userId: 'u1',
        mood: 2,
        loggedAt: at,
        localDate: date,
      );
      expect(a, b);
      expect(a, isNot(c));
    });

    test('SymptomType and SymptomEntry compare by value', () {
      const type = SymptomType(id: 'st-bloating', name: 'Bloating');
      const same = SymptomType(id: 'st-bloating', name: 'Bloating');
      expect(type, same);
      expect(type.isCustom, isFalse);

      final entry = SymptomEntry(
        id: 'sy1',
        userId: 'u1',
        type: type,
        severity: 3,
        loggedAt: at,
        localDate: date,
      );
      final copy = SymptomEntry(
        id: 'sy1',
        userId: 'u1',
        type: same,
        severity: 3,
        loggedAt: at,
        localDate: date,
      );
      expect(entry, copy);
    });

    test('ExerciseEntry compares by value', () {
      final a = ExerciseEntry(
        id: 'e1',
        userId: 'u1',
        activity: 'Run',
        durationMin: 30,
        intensity: ExerciseIntensity.vigorous,
        energyKcal: 300,
        loggedAt: at,
        localDate: date,
      );
      final b = ExerciseEntry(
        id: 'e1',
        userId: 'u1',
        activity: 'Run',
        durationMin: 30,
        intensity: ExerciseIntensity.vigorous,
        energyKcal: 300,
        loggedAt: at,
        localDate: date,
      );
      expect(a, b);
    });
  });
}
