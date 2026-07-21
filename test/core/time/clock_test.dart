import 'package:flutter_test/flutter_test.dart';
import 'package:life_ledger/core/time/clock.dart';

void main() {
  group('FixedClock', () {
    test('reports the frozen instant', () {
      final fixed = DateTime(2026, 7, 21, 8, 30);
      final clock = FixedClock(fixed);
      expect(clock.nowLocal(), fixed);
      expect(clock.nowUtc(), fixed.toUtc());
    });

    test('localDate formats as YYYY-MM-DD with zero padding', () {
      expect(FixedClock(DateTime(2026, 7, 21)).localDate(), '2026-07-21');
      expect(FixedClock(DateTime(2026, 1, 5)).localDate(), '2026-01-05');
      expect(FixedClock(DateTime(2026, 12, 31)).localDate(), '2026-12-31');
    });

    test('day boundary: 23:59 and 00:00 land on different local dates', () {
      final beforeMidnight = FixedClock(DateTime(2026, 7, 21, 23, 59));
      final afterMidnight = FixedClock(DateTime(2026, 7, 22));
      expect(beforeMidnight.localDate(), '2026-07-21');
      expect(afterMidnight.localDate(), '2026-07-22');
    });
  });

  group('Clock.formatLocalDate', () {
    test('converts UTC instants to the local calendar day', () {
      final utc = DateTime.utc(2026, 7, 21, 12);
      expect(Clock.formatLocalDate(utc), Clock.formatLocalDate(utc.toLocal()));
    });
  });

  group('SystemClock', () {
    test('produces a plausible current time and valid local date', () {
      const clock = SystemClock();
      final now = clock.nowUtc();
      expect(now.isUtc, isTrue);
      expect(
        RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(clock.localDate()),
        isTrue,
      );
    });
  });
}
