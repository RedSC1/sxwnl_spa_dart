import 'package:sxwnl_spa_dart/sxwnl_spa_dart.dart';
import 'package:test/test.dart';

void main() {
  group('dayGanZhi', () {
    test('2000-01-01 is 戊午', () {
      final gz = dayGanZhi(AstroDateTime(2000, 1, 1));
      expect(gz.gan, TianGan.wu);
      expect(gz.zhi, DiZhi.wu);
      expect(gz.toString(), '戊午');
    });

    test('2000-01-02 is 己未', () {
      final gz = dayGanZhi(AstroDateTime(2000, 1, 2));
      expect(gz.toString(), '己未');
    });

    test('2026-02-17 is 壬戌', () {
      // 这个是之前 TimelineProvider._dayGanZhi 出 Bug 的日期
      final gz = dayGanZhi(AstroDateTime(2026, 2, 17));
      expect(gz.toString(), '壬戌');
    });

    test('successive days increment correctly', () {
      final day1 = dayGanZhi(AstroDateTime(2026, 3, 1));
      final day2 = dayGanZhi(AstroDateTime(2026, 3, 2));
      final day3 = dayGanZhi(AstroDateTime(2026, 3, 3));
      expect(day2, isNot(equals(day1.toString())));
      expect(day2.toString(), (day1 + 1).toString());
      expect(day3.toString(), (day1 + 2).toString());
    });
  });

  group('dayGanZhiAt', () {
    test('before 23:00 same as dayGanZhi', () {
      final gz1 = dayGanZhi(AstroDateTime(2026, 2, 17));
      final gz2 = dayGanZhiAt(AstroDateTime(2026, 2, 17, 15, 0));
      expect(gz2.toString(), gz1.toString());
    });

    test('splitRatHour=false: 23:00+ shifts to next day', () {
      final today = dayGanZhi(AstroDateTime(2026, 2, 17));
      final tomorrow = dayGanZhi(AstroDateTime(2026, 2, 18));
      final gz = dayGanZhiAt(AstroDateTime(2026, 2, 17, 23, 30));
      expect(gz.toString(), tomorrow.toString());
      expect(gz.toString(), isNot(today.toString()));
    });

    test('splitRatHour=true: 23:00-00:00 stays on current day', () {
      final today = dayGanZhi(AstroDateTime(2026, 2, 17));
      final gz = dayGanZhiAt(
        AstroDateTime(2026, 2, 17, 23, 30),
        splitRatHour: true,
      );
      expect(gz.toString(), today.toString());
    });

    test('splitRatHour does not affect times before 23:00', () {
      final gz1 = dayGanZhiAt(AstroDateTime(2026, 2, 17, 22, 59));
      final gz2 = dayGanZhiAt(
        AstroDateTime(2026, 2, 17, 22, 59),
        splitRatHour: true,
      );
      expect(gz1.toString(), gz2.toString());
    });
  });

  group('getDayRange', () {
    test('single day range', () {
      final days = getDayRange(
        AstroDateTime(2026, 2, 17),
        AstroDateTime(2026, 2, 17),
      );
      expect(days.length, 1);
      expect(days[0].ganZhi.toString(), '壬戌');
    });

    test('three day range', () {
      final days = getDayRange(
        AstroDateTime(2026, 2, 17),
        AstroDateTime(2026, 2, 19),
      );
      expect(days.length, 3);
      // 日干支连续递增
      expect(days[1].ganZhi.toString(), (days[0].ganZhi + 1).toString());
      expect(days[2].ganZhi.toString(), (days[0].ganZhi + 2).toString());
    });

    test('empty range when start > end', () {
      final days = getDayRange(
        AstroDateTime(2026, 2, 19),
        AstroDateTime(2026, 2, 17),
      );
      expect(days, isEmpty);
    });

    test('correct solar dates in output', () {
      final days = getDayRange(
        AstroDateTime(2026, 3, 1),
        AstroDateTime(2026, 3, 3),
      );
      expect(days[0].solarDate.month, 3);
      expect(days[0].solarDate.day, 1);
      expect(days[1].solarDate.day, 2);
      expect(days[2].solarDate.day, 3);
    });
  });

  group('getSolarMonthDays', () {
    test('February 2026 has 28 days', () {
      final days = getSolarMonthDays(2026, 2);
      expect(days.length, 28);
      expect(days.first.solarDate.day, 1);
      expect(days.last.solarDate.day, 28);
    });

    test('February 2024 (leap year) has 29 days', () {
      final days = getSolarMonthDays(2024, 2);
      expect(days.length, 29);
    });

    test('January has 31 days', () {
      final days = getSolarMonthDays(2026, 1);
      expect(days.length, 31);
    });

    test('GanZhi are consecutive', () {
      final days = getSolarMonthDays(2026, 3);
      for (int i = 1; i < days.length; i++) {
        expect(
          days[i].ganZhi.toString(),
          (days[i - 1].ganZhi + 1).toString(),
          reason: 'Day ${i + 1} should be next GanZhi after day $i',
        );
      }
    });
  });

  group('getLunarMonthDays', () {
    test('2025 正月', () {
      final days = getLunarMonthDays(2025, "正");
      expect(days.isNotEmpty, true);
      // 2025年正月初一 = 2025-01-29
      expect(days.first.solarDate.year, 2025);
      expect(days.first.solarDate.month, 1);
      expect(days.first.solarDate.day, 29);
    });

    test('GanZhi are consecutive in lunar month', () {
      final days = getLunarMonthDays(2025, "二");
      for (int i = 1; i < days.length; i++) {
        expect(days[i].ganZhi.toString(), (days[i - 1].ganZhi + 1).toString());
      }
    });

    test('month has 29 or 30 days', () {
      final days = getLunarMonthDays(2025, "正");
      expect(days.length, inInclusiveRange(29, 30));
    });
  });

  group('getJieQiPeriodDays', () {
    test('returns non-empty list', () {
      final days = getJieQiPeriodDays(AstroDateTime(2026, 3, 15));
      expect(days.isNotEmpty, true);
    });

    test('period is roughly 29-32 days', () {
      final days = getJieQiPeriodDays(AstroDateTime(2026, 3, 15));
      // 节气月大约 29-32 天
      expect(days.length, inInclusiveRange(28, 33));
    });

    test('GanZhi are consecutive', () {
      final days = getJieQiPeriodDays(AstroDateTime(2026, 6, 15));
      for (int i = 1; i < days.length; i++) {
        expect(days[i].ganZhi.toString(), (days[i - 1].ganZhi + 1).toString());
      }
    });
  });

  group('hourGanZhi', () {
    test('甲日子时 → 甲子', () {
      expect(hourGanZhi(TianGan.jia, 0).toString(), '甲子');
    });

    test('乙日子时 → 丙子', () {
      expect(hourGanZhi(TianGan.yi, 0).toString(), '丙子');
    });

    test('丙日子时 → 戊子', () {
      expect(hourGanZhi(TianGan.bing, 0).toString(), '戊子');
    });

    test('丁日子时 → 庚子', () {
      expect(hourGanZhi(TianGan.ding, 0).toString(), '庚子');
    });

    test('戊日子时 → 壬子', () {
      expect(hourGanZhi(TianGan.wu, 0).toString(), '壬子');
    });

    test('己日子时 → 甲子 (same group as 甲)', () {
      expect(hourGanZhi(TianGan.ji, 0).toString(), '甲子');
    });

    test('甲日巳时(index=5) → 己巳', () {
      expect(hourGanZhi(TianGan.jia, 5).toString(), '己巳');
    });

    test('12 hours cycle through all dizhi', () {
      for (int i = 0; i < 12; i++) {
        final gz = hourGanZhi(TianGan.jia, i);
        expect(gz.zhi, DiZhi.values[i]);
      }
    });
  });

  group('monthGanZhi', () {
    test('甲年正月(寅月) → 丙寅', () {
      expect(monthGanZhi(TianGan.jia, 0).toString(), '丙寅');
    });

    test('乙年正月 → 戊寅', () {
      expect(monthGanZhi(TianGan.yi, 0).toString(), '戊寅');
    });

    test('丙年正月 → 庚寅', () {
      expect(monthGanZhi(TianGan.bing, 0).toString(), '庚寅');
    });

    test('丁年正月 → 壬寅', () {
      expect(monthGanZhi(TianGan.ding, 0).toString(), '壬寅');
    });

    test('戊年正月 → 甲寅', () {
      expect(monthGanZhi(TianGan.wu, 0).toString(), '甲寅');
    });

    test('己年正月 → 丙寅 (same group as 甲)', () {
      expect(monthGanZhi(TianGan.ji, 0).toString(), '丙寅');
    });

    test('甲年二月(卯月) → 丁卯', () {
      expect(monthGanZhi(TianGan.jia, 1).toString(), '丁卯');
    });

    test('12 months cycle through all dizhi starting from 寅', () {
      for (int i = 0; i < 12; i++) {
        final gz = monthGanZhi(TianGan.jia, i);
        expect(gz.zhi, DiZhi.values[(i + 2) % 12]);
      }
    });
  });

  group('yearGanZhi', () {
    test('1984 is JiaZi', () {
      final gz = yearGanZhi(1984);
      expect(gz.toString(), '甲子');
    });

    test('2024 is JiaChen', () {
      final gz = yearGanZhi(2024);
      expect(gz.toString(), '甲辰');
    });

    test('2025 is YiSi', () {
      final gz = yearGanZhi(2025);
      expect(gz.toString(), '乙巳');
    });

    test('184 is JiaZi (1984 - 1800)', () {
      expect(yearGanZhi(184).toString(), '甲子');
    });

    test('Negative year', () {
      expect(yearGanZhi(-56).toString(), '甲子');
    });
  });

  group('getYearMonthGanZhi', () {
    test('1984(甲子) should return BingYin, DingMao... DingChou', () {
      final yg = yearGanZhi(1984).gan; // 甲
      final months = getYearMonthGanZhi(yg);
      expect(months.length, 12);
      expect(months[0].toString(), '丙寅');
      expect(months[1].toString(), '丁卯');
      expect(months[11].toString(), '丁丑');
    });

    test('2025(乙巳) should return WuYin, JiMao... DingChou', () {
      final yg = yearGanZhi(2025).gan; // 乙
      final months = getYearMonthGanZhi(yg);
      expect(months.length, 12);
      expect(months[0].toString(), '戊寅');
      expect(months[1].toString(), '己卯');
    });
  });

  group('getDayHourGanZhi', () {
    test('JiaZi day should return JiaZi, YiChou... YiHai', () {
      final dg = TianGan.jia;
      final hours = getDayHourGanZhi(dg);
      expect(hours.length, 12);
      expect(hours[0].toString(), '甲子');
      expect(hours[1].toString(), '乙丑');
      expect(hours[11].toString(), '乙亥');
    });

    test('YiChou day should return BingZi, DingChou... DingHai', () {
      final dg = TianGan.yi;
      final hours = getDayHourGanZhi(dg);
      expect(hours.length, 12);
      expect(hours[0].toString(), '丙子');
      expect(hours[1].toString(), '丁丑');
    });
  });

  group('getYearRange', () {
    test('1984-1985', () {
      final years = getYearRange(1984, 1985);
      expect(years.length, 2);
      expect(years[0].year, 1984);
      expect(years[0].ganZhi.toString(), '甲子');
      expect(years[1].year, 1985);
      expect(years[1].ganZhi.toString(), '乙丑');
    });

    test('Single year', () {
      final years = getYearRange(2024, 2024);
      expect(years.length, 1);
      expect(years[0].ganZhi.toString(), '甲辰');
    });

    test('Invalid range', () {
      final years = getYearRange(2025, 2024);
      expect(years.isEmpty, true);
    });
  });
}
