import 'package:sxwnl_spa_dart/sxwnl_spa_dart.dart';
import 'package:test/test.dart';

void main() {
  void expectSolarLunarRoundTrip(AstroDateTime solar) {
    final lunar = LunarDate.fromSolar(solar);
    final backToSolar = lunar.toSolar;
    final reconstructed = LunarDate.fromString(
      lunar.lunarYear,
      lunar.monthNameStr,
      lunar.day,
      isLeap: lunar.isLeap,
    );
    final reconstructedSolar = reconstructed.toSolar;

    expect(backToSolar.year, solar.year);
    expect(backToSolar.month, solar.month);
    expect(backToSolar.day, solar.day);

    expect(reconstructed.lunarYear, lunar.lunarYear);
    expect(reconstructed.month, lunar.month);
    expect(reconstructed.day, lunar.day);
    expect(reconstructed.isLeap, lunar.isLeap);

    expect(reconstructedSolar.year, solar.year);
    expect(reconstructedSolar.month, solar.month);
    expect(reconstructedSolar.day, solar.day);
  }

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

    test('pre-Han BCE solar keeps astronomical lunar year under historical month naming', () {
      final solar = AstroDateTime(-456, 4, 4, 12, 48, 0);
      final lunar = LunarDate.fromSolar(solar);

      expect(lunar.lunarYear, -456);
      expect(lunar.month, 5);
      expect(lunar.day, 12);
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
    test('fromString resolves BCE month 正 within the requested lunar year', () {
      final lunar = LunarDate.fromString(-100, '正', 1);
      final solar = lunar.toSolar;
      final back = LunarDate.fromSolar(
        AstroDateTime(solar.year, solar.month, solar.day, 12, 0, 0),
      );

      expect(back.lunarYear, -100);
      expect(back.month, 1);
      expect(back.day, 1);
      expect(back.isLeap, false);
    });

    test('fromString resolves BCE month 十 within the requested lunar year', () {
      final lunar = LunarDate.fromString(-100, '十', 1);
      final solar = lunar.toSolar;
      final back = LunarDate.fromSolar(
        AstroDateTime(solar.year, solar.month, solar.day, 12, 0, 0),
      );

      expect(back.lunarYear, -100);
      expect(back.month, 10);
      expect(back.day, 1);
      expect(back.isLeap, false);
    });

    test('fromString resolves ancient historical BCE month 五 within the requested lunar year', () {
      final lunar = LunarDate.fromString(-456, '五', 1);
      final solar = lunar.toSolar;
      final back = LunarDate.fromSolar(
        AstroDateTime(solar.year, solar.month, solar.day, 12, 0, 0),
      );

      expect(back.lunarYear, -456);
      expect(back.month, 5);
      expect(back.day, 1);
      expect(back.isLeap, false);
    });

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

    test('fromString resolves month 十二 within the requested lunar year 2025', () {
      final lunar = LunarDate.fromString(2025, '十二', 1);
      final solar = lunar.toSolar;
      final back = LunarDate.fromSolar(
        AstroDateTime(solar.year, solar.month, solar.day, 12, 0, 0),
      );

      expect(back.lunarYear, 2025);
      expect(back.month, 12);
      expect(back.day, 1);
      expect(back.isLeap, false);
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

    test('getLunarMonthDays keeps all days inside lunar year 2025 month 十二', () {
      final days = getLunarMonthDays(2025, '十二');

      expect(days, isNotEmpty);
      expect(days.first.lunarDate.lunarYear, 2025);
      expect(days.first.lunarDate.month, 12);
      expect(days.first.lunarDate.day, 1);
      expect(days.last.lunarDate.lunarYear, 2025);
      expect(days.last.lunarDate.month, 12);
      expect(days.last.lunarDate.day, days.first.lunarDate.monthSize);
    });
  });

  group('CE historical reform periods', () {
    test('Xin dynasty historical month naming keeps solar/lunar round trip stable', () {
      expectSolarLunarRoundTrip(AstroDateTime(10, 6, 1, 12, 0, 0));
    });

    test('Jingchu reform period keeps solar/lunar round trip stable', () {
      expectSolarLunarRoundTrip(AstroDateTime(238, 6, 1, 12, 0, 0));
    });

    test('Wu Zetian reform period keeps solar/lunar round trip stable', () {
      expectSolarLunarRoundTrip(AstroDateTime(690, 6, 1, 12, 0, 0));
    });
  });
}
