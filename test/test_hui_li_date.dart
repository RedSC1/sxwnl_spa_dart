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
