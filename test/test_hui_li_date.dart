import 'package:sxwnl_spa_dart/sxwnl_spa_dart.dart';
import 'package:test/test.dart';

void main() {
  group('HuiLiDate', () {
    test('matches the sxwnl epoch calibration', () {
      final date = getHuiLi(0);
      expect(date.year, 1420);
      expect(date.month, 9);
      expect(date.day, 24);
      expect(date.Hyear, date.year);
      expect(date.Hmonth, date.month);
      expect(date.Hday, date.day);
    });

    test('assigns a Beijing civil day from an intra-day value', () {
      final noon = getHuiLi(0);
      final lateNight = getHuiLi(.49);
      final nextMidnight = getHuiLi(.5);
      expect(lateNight, equals(noon));
      expect(nextMidnight.day, noon.day + 1);
    });

    test('matches sxwnl across cycle and leap-year boundaries', () {
      // These are fixed outputs from oba.getHuiLi() in the original lunar.js.
      final oracle = <double, HuiLiDate>{
        -503105: const HuiLiDate(year: 1, month: 1, day: 1),
        -503104: const HuiLiDate(year: 1, month: 1, day: 2),
        -502397: const HuiLiDate(year: 2, month: 12, day: 30),
        -502396: const HuiLiDate(year: 3, month: 1, day: 1),
        -492475: const HuiLiDate(year: 30, month: 12, day: 29),
        -492474: const HuiLiDate(year: 31, month: 1, day: 1),
        0: const HuiLiDate(year: 1420, month: 9, day: 24),
        1000: const HuiLiDate(year: 1423, month: 7, day: 20),
        10630: const HuiLiDate(year: 1450, month: 9, day: 23),
        10631: const HuiLiDate(year: 1450, month: 9, day: 24),
        503105: const HuiLiDate(year: 2840, month: 6, day: 16),
      };
      for (final entry in oracle.entries) {
        expect(getHuiLi(entry.key), entry.value, reason: 'd0=${entry.key}');
      }
    });

    test('repeats the same month/day after one 30-year cycle', () {
      for (final d0 in [0.0, 1.0, 1000.0, 5000.0]) {
        final first = getHuiLi(d0);
        final nextCycle = getHuiLi(d0 + 10631);
        expect(nextCycle.month, first.month);
        expect(nextCycle.day, first.day);
        expect(nextCycle.year, first.year + 30);
      }
    });

    test('is distinct from the Chinese lunar date', () {
      final day = getDayRange(
        AstroDateTime(2000, 1, 1),
        AstroDateTime(2000, 1, 1),
      ).single;
      expect(day.huiLiDate, equals(getHuiLi(-.5)));
      expect(day.hijriDate, equals(day.huiLiDate));
    });
  });
}
