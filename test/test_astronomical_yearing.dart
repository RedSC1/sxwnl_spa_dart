import 'package:sxwnl_spa_dart/sxwnl_spa_dart.dart';
import 'package:test/test.dart';

void main() {
  group('astronomical year numbering', () {
    test('BCE solar -> lunar -> solar round trip keeps the same day', () {
      final solar = AstroDateTime(-456, 4, 4, 12, 48, 0);
      final lunar = LunarDate.fromSolar(solar);
      final backToSolar = lunar.toSolar;

      expect(lunar.lunarYear, -456);
      expect(backToSolar.year, solar.year);
      expect(backToSolar.month, solar.month);
      expect(backToSolar.day, solar.day);
    });

    test('BCE lunar string uses historical display year', () {
      final lunar = LunarDate.fromSolar(AstroDateTime(-456, 4, 4, 12, 48, 0));

      expect(lunar.historicalYear, 457);
      expect(lunar.bceYear, 457);
      expect(lunar.toString(), contains('公元前457年'));
    });

    test('DayInfo string uses AstroDateTime BCE display', () {
      final day = getDayRange(
        AstroDateTime(0, 1, 1),
        AstroDateTime(0, 1, 1),
      ).single;

      expect(day.toString(), startsWith('公元前1-01-01'));
    });
  });

  group('cross-year lunar month matching', () {
    test('fromString resolves month 十一 within the requested lunar year', () {
      final lunar = LunarDate.fromString(2025, '十一', 1);
      final solar = lunar.toSolar;
      final back = LunarDate.fromSolar(
        AstroDateTime(solar.year, solar.month, solar.day, 12, 0, 0),
      );

      expect(back.lunarYear, 2025);
      expect(back.month, 11);
      expect(back.day, 1);
      expect(back.isLeap, false);
    });

    test('fromString rejects non-existent month 十二 in lunar year 2025', () {
      expect(
        () => LunarDate.fromString(2025, '十二', 1),
        throwsA(isA<FormatException>()),
      );
    });

    test('getLunarMonthDays keeps all days inside lunar year 2025 month 十一', () {
      final days = getLunarMonthDays(2025, '十一');

      expect(days, isNotEmpty);
      expect(days.first.lunarDate.lunarYear, 2025);
      expect(days.first.lunarDate.month, 11);
      expect(days.first.lunarDate.day, 1);
      expect(days.last.lunarDate.lunarYear, 2025);
      expect(days.last.lunarDate.month, 11);
      expect(days.last.lunarDate.day, days.first.lunarDate.monthSize);
    });

    test('getLunarMonthDays rejects non-existent month 十二 in lunar year 2025', () {
      expect(
        () => getLunarMonthDays(2025, '十二'),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
