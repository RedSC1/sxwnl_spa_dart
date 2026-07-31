import 'package:sxwnl_spa_dart/sxwnl_spa_dart.dart';
import 'package:test/test.dart';

/// 中国科学院紫金山天文台《二○二六年日历资料》回归数据。
///
/// 资料按 GB/T 33661-2017 编制；日历中的时刻均为北京时间，且节气
/// 只印到分钟。因此这里不把印刷分钟当作秒级真值，而是允许计算结果与
/// 印刷时刻相差不超过 60 秒。
void main() {
  group('PMO 2026 year oracle', () {
    test('24 solar terms agree with the printed Beijing-time minutes', () {
      // 官方资料只列到分钟；项目计算保留秒及秒的小数部分。
      const expected = <String, List<int>>{
        '小寒': [2026, 1, 5, 16, 23],
        '大寒': [2026, 1, 20, 9, 45],
        '立春': [2026, 2, 4, 4, 2],
        '雨水': [2026, 2, 18, 23, 52],
        '惊蛰': [2026, 3, 5, 21, 59],
        '春分': [2026, 3, 20, 22, 46],
        '清明': [2026, 4, 5, 2, 40],
        '谷雨': [2026, 4, 20, 9, 39],
        '立夏': [2026, 5, 5, 19, 49],
        '小满': [2026, 5, 21, 8, 37],
        '芒种': [2026, 6, 5, 23, 48],
        '夏至': [2026, 6, 21, 16, 25],
        '小暑': [2026, 7, 7, 9, 57],
        '大暑': [2026, 7, 23, 3, 13],
        '立秋': [2026, 8, 7, 19, 43],
        '处暑': [2026, 8, 23, 10, 19],
        '白露': [2026, 9, 7, 22, 41],
        '秋分': [2026, 9, 23, 8, 5],
        '寒露': [2026, 10, 8, 14, 29],
        '霜降': [2026, 10, 23, 17, 38],
        '立冬': [2026, 11, 7, 17, 52],
        '小雪': [2026, 11, 22, 15, 23],
        '大雪': [2026, 12, 7, 10, 53],
        '冬至': [2026, 12, 22, 4, 50],
      };

      final terms = getYearJieQi(2026);
      for (final entry in expected.entries) {
        final actual = terms.firstWhere(
          (term) =>
              term.name == entry.key && term.dateTime.year == entry.value[0],
        );
        final e = entry.value;
        final printed = AstroDateTime(e[0], e[1], e[2], e[3], e[4]);
        final differenceSeconds =
            (actual.dateTime.toJulianDay() - printed.toJulianDay()).abs() *
            86400;

        expect(actual.dateTime.timeZone, 8.0, reason: '${entry.key} 应标记为北京时间');
        expect(
          differenceSeconds,
          lessThanOrEqualTo(60.0),
          reason:
              '${entry.key}: 计算值 $actual，官方 ${printed.year}-'
              '${printed.month.toString().padLeft(2, '0')}-'
              '${printed.day.toString().padLeft(2, '0')} '
              '${printed.toTimeString()}，差 $differenceSeconds 秒',
        );
      }
    });

    test('lunar month names and sizes match the official calendar', () {
      // 资料跨越了 2025 农历十一、十二月，以及 2026 农历正月至十二月。
      const expected = <int, Map<String, int>>{
        2025: {'十一': 30, '十二': 29},
        2026: {
          '正': 30,
          '二': 29,
          '三': 30,
          '四': 29,
          '五': 29,
          '六': 30,
          '七': 29,
          '八': 29,
          '九': 30,
          '十': 30,
          '十一': 30,
          '十二': 29,
        },
      };

      final ssq = SSQ();
      final result = ssq.calcY(AstroDateTime(2026, 6, 1).toJ2000());
      final sizesByName = <String, int>{};
      for (var i = 0; i < result.ym.length; i++) {
        // 2026 这一轮排谱没有闰月，名称不会重复。
        sizesByName[result.ym[i]] = result.dx[i];
      }

      for (final yearEntry in expected.entries) {
        for (final monthEntry in yearEntry.value.entries) {
          final lunar = LunarDate.fromString(yearEntry.key, monthEntry.key, 1);
          expect(
            lunar.monthSize,
            monthEntry.value,
            reason: '${yearEntry.key}年${monthEntry.key}月大小',
          );
          expect(
            lunar.isLeap,
            isFalse,
            reason: '官方 2026 资料没有闰月：${yearEntry.key}年${monthEntry.key}月',
          );

          // SSQ 的窗口以冬至年组织，2025 十一、十二月和 2026 正月至
          // 十一月均在同一个结果中；十二月则由该结果的末月给出。
          final rawName = monthEntry.key;
          expect(
            sizesByName[rawName],
            monthEntry.value,
            reason: 'SSQ 排谱中的 $rawName 月大小',
          );
        }
      }
    });

    test('lunar new-year and month boundaries match the printed pages', () {
      final beforeLunarNewYear = LunarDate.fromSolar(
        AstroDateTime(2026, 2, 16, 12),
      );
      final lunarNewYear = LunarDate.fromSolar(AstroDateTime(2026, 2, 17, 12));
      final nextMonth = LunarDate.fromSolar(AstroDateTime(2026, 3, 19, 12));

      expect(beforeLunarNewYear.monthNameStr, '十二');
      expect(beforeLunarNewYear.day, 29);
      expect(lunarNewYear.lunarYear, 2026);
      expect(lunarNewYear.monthNameStr, '正');
      expect(lunarNewYear.day, 1);
      expect(nextMonth.monthNameStr, '二');
      expect(nextMonth.day, 1);
    });

    test('朔、上弦、望、下弦 match the PMO 2026 phase table', () {
      // 官方表只发布到分钟；计算结果保留秒及秒的小数部分，因此按
      // 60 秒以内核对，而不把官方打印分钟当作秒级真值。
      const expected = <_MoonPhaseOracle>[
        _MoonPhaseOracle('望', 2026, 1, 3, 18, 3),
        _MoonPhaseOracle('下弦', 2026, 1, 10, 23, 48),
        _MoonPhaseOracle('朔', 2026, 1, 19, 3, 52),
        _MoonPhaseOracle('上弦', 2026, 1, 26, 12, 47),
        _MoonPhaseOracle('望', 2026, 2, 2, 6, 9),
        _MoonPhaseOracle('下弦', 2026, 2, 9, 20, 43),
        _MoonPhaseOracle('朔', 2026, 2, 17, 20, 1),
        _MoonPhaseOracle('上弦', 2026, 2, 24, 20, 28),
        _MoonPhaseOracle('望', 2026, 3, 3, 19, 38),
        _MoonPhaseOracle('下弦', 2026, 3, 11, 17, 39),
        _MoonPhaseOracle('朔', 2026, 3, 19, 9, 23),
        _MoonPhaseOracle('上弦', 2026, 3, 26, 3, 18),
        _MoonPhaseOracle('望', 2026, 4, 2, 10, 12),
        _MoonPhaseOracle('下弦', 2026, 4, 10, 12, 52),
        _MoonPhaseOracle('朔', 2026, 4, 17, 19, 52),
        _MoonPhaseOracle('上弦', 2026, 4, 24, 10, 32),
        _MoonPhaseOracle('望', 2026, 5, 2, 1, 23),
        _MoonPhaseOracle('下弦', 2026, 5, 10, 5, 10),
        _MoonPhaseOracle('朔', 2026, 5, 17, 4, 1),
        _MoonPhaseOracle('上弦', 2026, 5, 23, 19, 11),
        _MoonPhaseOracle('望', 2026, 5, 31, 16, 45),
        _MoonPhaseOracle('下弦', 2026, 6, 8, 18, 1),
        _MoonPhaseOracle('朔', 2026, 6, 15, 10, 54),
        _MoonPhaseOracle('上弦', 2026, 6, 22, 5, 55),
        _MoonPhaseOracle('望', 2026, 6, 30, 7, 57),
        _MoonPhaseOracle('下弦', 2026, 7, 8, 3, 29),
        _MoonPhaseOracle('朔', 2026, 7, 14, 17, 44),
        _MoonPhaseOracle('上弦', 2026, 7, 21, 19, 6),
        _MoonPhaseOracle('望', 2026, 7, 29, 22, 36),
        _MoonPhaseOracle('下弦', 2026, 8, 6, 10, 21),
        _MoonPhaseOracle('朔', 2026, 8, 13, 1, 37),
        _MoonPhaseOracle('上弦', 2026, 8, 20, 10, 46),
        _MoonPhaseOracle('望', 2026, 8, 28, 12, 19),
        _MoonPhaseOracle('下弦', 2026, 9, 4, 15, 51),
        _MoonPhaseOracle('朔', 2026, 9, 11, 11, 27),
        _MoonPhaseOracle('上弦', 2026, 9, 19, 4, 44),
        _MoonPhaseOracle('望', 2026, 9, 27, 0, 49),
        _MoonPhaseOracle('下弦', 2026, 10, 3, 21, 25),
        _MoonPhaseOracle('朔', 2026, 10, 10, 23, 50),
        _MoonPhaseOracle('上弦', 2026, 10, 19, 0, 13),
        _MoonPhaseOracle('望', 2026, 10, 26, 12, 12),
        _MoonPhaseOracle('下弦', 2026, 11, 2, 4, 28),
        _MoonPhaseOracle('朔', 2026, 11, 9, 15, 2),
        _MoonPhaseOracle('上弦', 2026, 11, 17, 19, 48),
        _MoonPhaseOracle('望', 2026, 11, 24, 22, 54),
        _MoonPhaseOracle('下弦', 2026, 12, 1, 14, 9),
        _MoonPhaseOracle('朔', 2026, 12, 9, 8, 52),
        _MoonPhaseOracle('上弦', 2026, 12, 17, 13, 43),
        _MoonPhaseOracle('望', 2026, 12, 24, 9, 28),
        _MoonPhaseOracle('下弦', 2026, 12, 31, 2, 59),
      ];

      final actual = getYearMoonPhases(2026);
      expect(actual, hasLength(expected.length));
      for (var i = 0; i < expected.length; i++) {
        final oracle = expected[i];
        final result = actual[i];
        final printed = AstroDateTime(
          oracle.year,
          oracle.month,
          oracle.day,
          oracle.hour,
          oracle.minute,
        );
        final differenceSeconds =
            (result.dateTime.toJulianDay() - printed.toJulianDay()).abs() *
            86400;

        expect(result.name, oracle.name, reason: '第 ${i + 1} 个月相名称');
        expect(result.dateTime.timeZone, 8.0, reason: '第 ${i + 1} 个月相时区');
        expect(
          differenceSeconds,
          lessThanOrEqualTo(60.0),
          reason: '第 ${i + 1} 个${oracle.name}应与官方印刷分钟一致',
        );
      }
    });

    test('梅雨 and 三伏 dates match the official calendar', () {
      final meiyuCases = <AstroDateTime, String>{
        AstroDateTime(2026, 6, 11): '入梅',
        AstroDateTime(2026, 7, 8): '出梅',
      };
      for (final entry in meiyuCases.entries) {
        final gz = dayGanZhi(entry.key);
        expect(
          FestivalEngine.getMeiyu(entry.key, gz),
          entry.value,
          reason: '${entry.key} 的梅雨日期',
        );
      }

      final sanfuCases = <AstroDateTime, String>{
        AstroDateTime(2026, 7, 15): '初伏',
        AstroDateTime(2026, 7, 25): '中伏',
        AstroDateTime(2026, 8, 14): '末伏',
      };
      for (final entry in sanfuCases.entries) {
        final gz = dayGanZhi(entry.key);
        expect(
          FestivalEngine.getSanfu(entry.key, gz),
          entry.value,
          reason: '${entry.key} 的三伏日期',
        );
      }
    });

    test('数九 start dates match the official calendar', () {
      const expected = <String, String>{
        // 2025-12-21 冬至发生在北京时间 23:03，年历按冬至日开始数九。
        '2025-12-21': '『一九』',
        '2025-12-30': '『二九』',
        '2026-01-08': '『三九』',
        '2026-01-17': '『四九』',
        '2026-01-26': '『五九』',
        '2026-02-04': '『六九』',
        '2026-02-13': '『七九』',
        '2026-02-22': '『八九』',
        '2026-03-03': '『九九』',
        '2026-12-22': '『一九』',
        '2026-12-31': '『二九』',
      };

      for (final entry in expected.entries) {
        final parts = entry.key.split('-').map(int.parse).toList();
        final date = AstroDateTime(parts[0], parts[1], parts[2]);
        expect(
          FestivalEngine.getShujiu(date),
          entry.value,
          reason: '${entry.key} 的数九起始日',
        );
      }
    });
  });
}

class _MoonPhaseOracle {
  final String name;
  final int year;
  final int month;
  final int day;
  final int hour;
  final int minute;

  const _MoonPhaseOracle(
    this.name,
    this.year,
    this.month,
    this.day,
    this.hour,
    this.minute,
  );
}
