import 'package:sxwnl_spa_dart/sxwnl_spa_dart.dart';
import 'package:test/test.dart';

void main() {
  group('TianGan', () {
    test('label returns correct Chinese character', () {
      expect(TianGan.jia.label, '甲');
      expect(TianGan.gui.label, '癸');
    });

    test('fromName supports pinyin and Chinese', () {
      expect(TianGan.fromName('jia'), TianGan.jia);
      expect(TianGan.fromName('甲'), TianGan.jia);
      expect(TianGan.fromName('gui'), TianGan.gui);
      expect(TianGan.fromName('癸'), TianGan.gui);
    });

    test('isYang/isYin', () {
      expect(TianGan.jia.isYang, true);
      expect(TianGan.yi.isYin, true);
      expect(TianGan.bing.isYang, true);
    });
  });

  group('DiZhi', () {
    test('label returns correct Chinese character', () {
      expect(DiZhi.zi.label, '子');
      expect(DiZhi.hai.label, '亥');
    });

    test('fromName supports pinyin and Chinese', () {
      expect(DiZhi.fromName('zi'), DiZhi.zi);
      expect(DiZhi.fromName('子'), DiZhi.zi);
      expect(DiZhi.fromName('hai'), DiZhi.hai);
      expect(DiZhi.fromName('亥'), DiZhi.hai);
    });
  });

  group('GanZhi', () {
    test('toString returns correct format', () {
      final gz = GanZhi(TianGan.jia, DiZhi.zi);
      expect(gz.toString(), '甲子');
    });

    test('offset forward', () {
      final gz = GanZhi(TianGan.jia, DiZhi.zi);
      final next = gz.offset(1);
      expect(next.toString(), '乙丑');
    });

    test('offset backward', () {
      final gz = GanZhi(TianGan.jia, DiZhi.zi);
      final prev = gz.offset(-1);
      expect(prev.toString(), '癸亥');
    });

    test('operator + and -', () {
      final gz = GanZhi(TianGan.jia, DiZhi.zi);
      expect((gz + 1).toString(), '乙丑');
      expect((gz - 1).toString(), '癸亥');
    });

    test('getKongWang - jia zi xun', () {
      final gz = GanZhi(TianGan.jia, DiZhi.zi);
      expect(gz.getKongWang(), [DiZhi.xu, DiZhi.hai]);
    });

    test('getKongWang - jia xu xun', () {
      final gz = GanZhi(TianGan.jia, DiZhi.xu);
      expect(gz.getKongWang(), [DiZhi.shen, DiZhi.you]);
    });

    test('getKongWang - jia shen xun', () {
      final gz = GanZhi(TianGan.jia, DiZhi.shen);
      expect(gz.getKongWang(), [DiZhi.wu, DiZhi.wei]);
    });

    test('getKongWang - yi chou (yin stem)', () {
      final gz = GanZhi(TianGan.yi, DiZhi.chou);
      expect(gz.getKongWang(), [DiZhi.hai, DiZhi.xu]);
    });
  });

  group('BaZi', () {
    test('toString returns four pillars', () {
      final bazi = BaZi(
        year: GanZhi(TianGan.jia, DiZhi.zi),
        month: GanZhi(TianGan.bing, DiZhi.yin),
        day: GanZhi(TianGan.wu, DiZhi.wu),
        time: GanZhi(TianGan.geng, DiZhi.shen),
      );
      expect(bazi.toString(), '甲子 丙寅 戊午 庚申');
    });
  });

  group('calcBaZi', () {
    test('calcBaZi returns same result as calcGanZhi', () {
      // 2026-02-04 12:00:00 UTC+8
      final dt = AstroDateTime(2026, 2, 4, 12, 0, 0);
      final loc = Location(116.4, 39.9);
      final trueSolar = calcTrueSolarTime(dt, loc);
      final jdUt = dt.toJ2000() - 8 / 24;

      final strResult = calcGanZhi(jdUt, trueSolar.trueSolarTime.toJ2000());
      final typedResult = calcBaZi(jdUt, trueSolar.trueSolarTime.toJ2000());

      // Both should produce the same string representation
      expect(typedResult.bazi.toString(), strResult.toString());
      expect(typedResult.timeZhiIndex, strResult.timeZhiIndex);
    });

    test('calcBaZi returns correct typed objects', () {
      final dt = AstroDateTime(2026, 2, 4, 12, 0, 0);
      final loc = Location(116.4, 39.9);
      final trueSolar = calcTrueSolarTime(dt, loc);
      final jdUt = dt.toJ2000() - 8 / 24;

      final result = calcBaZi(jdUt, trueSolar.trueSolarTime.toJ2000());
      expect(result.bazi.year.gan, isA<TianGan>());
      expect(result.bazi.year.zhi, isA<DiZhi>());
      expect(result.bazi.month.gan, isA<TianGan>());
      expect(result.bazi.day.gan, isA<TianGan>());
      expect(result.bazi.time.gan, isA<TianGan>());
    });
  });

  group('LunarDate', () {
    test('fromSolar converts correctly', () {
      // 2025-01-29 = 农历2025年正月初一
      final solar = AstroDateTime(2025, 1, 29, 12, 0, 0);
      final lunar = LunarDate.fromSolar(solar);
      expect(lunar.lunarYear, 2025);
      expect(lunar.month, 1);
      expect(lunar.day, 1);
      expect(lunar.isLeap, false);
    });

    test('toSolar converts back correctly', () {
      final lunar = LunarDate.fromString(2025, "正", 1);
      final solar = lunar.toSolar;
      expect(solar.year, 2025);
      expect(solar.month, 1);
      expect(solar.day, 29);
    });

    test('round trip solar -> lunar -> solar', () {
      final original = AstroDateTime(2026, 3, 15, 12, 0, 0);
      final lunar = LunarDate.fromSolar(original);
      final backToSolar = lunar.toSolar;
      expect(backToSolar.year, original.year);
      expect(backToSolar.month, original.month);
      expect(backToSolar.day, original.day);
    });

    test('toString format', () {
      final lunar = LunarDate.fromString(2025, "正", 15);
      expect(lunar.toString(), contains('2025'));
      expect(lunar.toString(), contains('正'));
      expect(lunar.toString(), contains('十五'));
    });

    test('historical year helpers for BCE date', () {
      final lunar = LunarDate.fromSolar(AstroDateTime(-456, 4, 4, 12, 0, 0));
      expect(lunar.lunarYear, -456);
      expect(lunar.isBCE, true);
      expect(lunar.bceYear, 457);
      expect(lunar.historicalYear, 457);
    });
  });

  group('TimePack', () {
    test('createBySolarTime basic', () {
      final time = AstroDateTime(2026, 2, 18, 12, 0, 0);
      final tp = TimePack.createBySolarTime(clockTime: time);

      expect(tp.clockTime, time);
      expect(tp.timezone, 8.0);
      expect(tp.location, defaultLoc);
      expect(tp.ratHourMode, RatHourMode.noSplit);
      expect(tp.splitByRatHour, false); // 验证兼容性 getter
      expect(tp.solarTime, isNotNull);
      expect(tp.virtualTime, isNotNull);
      expect(tp.utcTime, isNotNull);
    });

    test('createBySolarTime with true solar time', () {
      final time = AstroDateTime(2026, 2, 18, 12, 0, 0);
      final tp = TimePack.createBySolarTime(
        clockTime: time,
        useTrueSolarTime: true,
      );

      // virtualTime should be the true solar time
      expect(tp.virtualTime, tp.solarTime.trueSolarTime);
    });

    test('createBySolarTime without true solar time', () {
      final time = AstroDateTime(2026, 2, 18, 12, 0, 0);
      final tp = TimePack.createBySolarTime(
        clockTime: time,
        useTrueSolarTime: false,
      );

      // virtualTime should equal clockTime when not using true solar time
      expect(tp.virtualTime, time);
    });

    test('bjClt returns UTC+8 time', () {
      final time = AstroDateTime(2026, 2, 18, 12, 0, 0);
      final tp = TimePack.createBySolarTime(clockTime: time, timezone: 8.0);

      // bjClt = utcTime + 8h, and utcTime = clockTime - 8h
      // so bjClt should equal clockTime when timezone is 8
      expect(tp.bjClt.year, time.year);
      expect(tp.bjClt.month, time.month);
      expect(tp.bjClt.day, time.day);
      expect(tp.bjClt.hour, time.hour);
    });
  });

  group('defaultLoc', () {
    test('defaultLoc is 120E 30N', () {
      expect(defaultLoc.longitude, 120);
      expect(defaultLoc.latitude, 30);
    });
  });
}
