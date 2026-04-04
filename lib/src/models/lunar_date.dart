import '../astro_date_time.dart';
import '../enums/rat_hour_mode.dart';
import '../sxwnl/ssq.dart';

class LunarDate {
  /// 农历年份（天文纪年，Astronomical Year Numbering）
  /// - year > 0: 公元纪年（如 2026 = AD 2026）
  /// - year == 0: 公元前1年 (1 BC)
  /// - year < 0: 公元前 |year| + 1 年（如 -1 = 2 BC）
  final int lunarYear;
  final int month;
  final int day;
  final bool isLeap;
  final String monthNameStr;

  /// 该月总天数 (29 或 30)
  final int monthSize;

  const LunarDate._({
    required this.lunarYear,
    required this.month,
    required this.day,
    required this.isLeap,
    required this.monthNameStr,
    required this.monthSize,
  });

  factory LunarDate.fromString(
    int year,
    String monthName,
    int day, {
    bool? isLeap,
  }) {
    int logicalMonth;
    bool isLeapMonth;
    String cleanName;

    if (monthName == "十三") {
      logicalMonth = 13;
      isLeapMonth = true;
      cleanName = "十三";
    } else if (monthName == "后九") {
      logicalMonth = 9;
      isLeapMonth = true;
      cleanName = "后九";
    } else if (monthName == "拾贰") {
      logicalMonth = 12;
      isLeapMonth = false;
      cleanName = "拾贰";
    } else {
      cleanName = monthName.replaceAll("闰", "");
      logicalMonth = _cnToInt(cleanName);
      isLeapMonth = isLeap ?? monthName.contains("闰");
    }

    String finalShowName;
    if (monthName == "十三" || monthName == "后九" || monthName == "拾贰") {
      finalShowName = monthName;
    } else if (isLeapMonth) {
      finalShowName = "闰$cleanName";
    } else {
      finalShowName = cleanName;
    }

    final ssq = SSQ();
    final result = ssq.calcY(AstroDateTime(year, 6, 1).toJ2000());
    final zhengYueIndex = result.ym.indexOf("正");
    bool found = false;
    int monthSize = 30;
    for (int i = 0; i < result.ym.length; i++) {
      final rawName = result.ym[i];
      int currentMonth;
      bool currentIsLeap;

      if (rawName == "十三") {
        currentMonth = 13;
        currentIsLeap = true;
      } else if (rawName == "后九") {
        currentMonth = 9;
        currentIsLeap = true;
      } else if (rawName == "拾贰") {
        currentMonth = 12;
        currentIsLeap = false;
      } else {
        currentMonth = _cnToInt(rawName);
        currentIsLeap = (result.leap > 0 && i == result.leap);
      }

      if (currentMonth == logicalMonth && currentIsLeap == isLeapMonth) {
        if (zhengYueIndex >= 0) {
          final expectedLunarYear = _astronomicalLunarYearForIndex(
            result,
            i,
            zhengYueIndex,
          );

          if (expectedLunarYear != year) {
            continue;
          }
        }

        found = true;
        monthSize = result.dx[i];
        if (day < 1 || day > monthSize) {
          throw RangeError("农历 $year 年 $finalShowName 只有 $monthSize 天");
        }
        break;
      }
    }

    if (!found) {
      throw FormatException("农历 $year 年不存在 '$finalShowName'");
    }

    return LunarDate._(
      lunarYear: year,
      month: logicalMonth,
      day: day,
      isLeap: isLeapMonth,
      monthNameStr: finalShowName,
      monthSize: monthSize,
    );
  }

  static LunarDate fromSolar(
    AstroDateTime solarTime, {
    RatHourMode ratHourMode = RatHourMode.noSplit,
  }) {
    var solar = solarTime;
    if (ratHourMode == RatHourMode.noSplit && solarTime.hour >= 23) {
      solar = solarTime.add(Duration(hours: 1));
    }

    final ssq = SSQ();
    final targetJD = solar.toJ2000();
    final result = ssq.calcY(targetJD);

    int arrayIndex = -1;

    if (targetJD >= result.zq[0] && targetJD < result.hs[0] - 0.5) {
      arrayIndex = 0;
    }

    if (arrayIndex < 0) {
      for (int i = 0; i < result.hs.length - 1; i++) {
        if (targetJD >= result.hs[i] - 0.5 &&
            targetJD < result.hs[i + 1] - 0.5) {
          arrayIndex = i;
          break;
        }
      }
    }

    if (arrayIndex < 0 &&
        targetJD >= result.hs[13] - 0.5 &&
        targetJD < result.zq[24]) {
      arrayIndex = 13;
    }

    if (arrayIndex < 0) {
      throw StateError("无法定位 JD: $targetJD");
    }

    final rawName = result.ym[arrayIndex];
    int logicalMonth;
    bool isLeapMonth;
    String finalShowName;

    if (rawName == "十三") {
      logicalMonth = 13;
      isLeapMonth = true;
      finalShowName = "十三";
    } else if (rawName == "后九") {
      logicalMonth = 9;
      isLeapMonth = true;
      finalShowName = "后九";
    } else if (rawName == "拾贰") {
      logicalMonth = 12;
      isLeapMonth = false;
      finalShowName = "拾贰";
    } else {
      logicalMonth = _cnToInt(rawName);
      isLeapMonth = (result.leap > 0 && arrayIndex == result.leap);
      finalShowName = isLeapMonth ? "闰$rawName" : rawName;
    }

    // 找正月初一索引
    int zhengYueIndex = -1;
    for (int i = 0; i < result.ym.length; i++) {
      if (result.ym[i] == "正") {
        zhengYueIndex = i;
        break;
      }
    }

    // 农历年：以正月初一为界
    // 🌟 使用天文纪年（Astronomical Year Numbering），有公元0年
    // 历史公元前1年 = 天文年0，历史公元前2年 = 天文年-1，以此类推
    int lunarYear;
    if (zhengYueIndex >= 0) {
      lunarYear = _astronomicalLunarYearForIndex(result, arrayIndex, zhengYueIndex);
    } else {
      // 找不到正月（不应该发生），用阳历年兜底
      lunarYear = solar.year;
    }

    final dayOfMonth = (targetJD - (result.hs[arrayIndex] - 0.5)).floor() + 1;

    return LunarDate._(
      lunarYear: lunarYear,
      month: logicalMonth,
      day: dayOfMonth,
      isLeap: isLeapMonth,
      monthNameStr: finalShowName,
      monthSize: result.dx[arrayIndex],
    );
  }

  AstroDateTime get toSolar {
    final ssq = SSQ();

    // 需要查两年的冬至年数据
    for (int offset = 0; offset <= 1; offset++) {
      final searchYear = lunarYear + offset;
      final result = ssq.calcY(AstroDateTime(searchYear, 6, 1).toJ2000());

      for (int i = 0; i < result.ym.length; i++) {
        final rawName = result.ym[i];
        int currentMonth;
        bool currentIsLeap;

        if (rawName == "十三") {
          currentMonth = 13;
          currentIsLeap = true;
        } else if (rawName == "后九") {
          currentMonth = 9;
          currentIsLeap = true;
        } else if (rawName == "拾贰") {
          currentMonth = 12;
          currentIsLeap = false;
        } else {
          currentMonth = _cnToInt(rawName);
          currentIsLeap = (result.leap > 0 && i == result.leap);
        }

        if (currentMonth == month && currentIsLeap == isLeap) {
          // 验证农历年是否匹配
          final zhengYueIndex = result.ym.indexOf("正");
          if (zhengYueIndex >= 0) {
            final expectedLunarYear = _astronomicalLunarYearForIndex(
              result,
              i,
              zhengYueIndex,
            );

            if (expectedLunarYear != lunarYear) {
              continue;
            }
          }

          return AstroDateTime.fromJ2000(result.hs[i] + (day - 1));
        }
      }
    }

    throw StateError("数据异常");
  }

  /// 获取农历日名称 (如 "初一", "廿一")
  String get dayName => _dayToCn(day);

  /// 是否是本月最后一天 (除夕判断用)
  bool get isLastDay => day == monthSize;

  /// 是否公元前
  bool get isBCE => lunarYear <= 0;

  /// 公元前年份（公元前1年 -> 1，公元前2年 -> 2）。
  /// 公元后返回 null。
  int? get bceYear => isBCE ? 1 - lunarYear : null;

  /// 历史纪年年份（无公元0年）。
  /// 公元前返回正整数的 BCE 年号，公元后直接返回原值。
  int get historicalYear => isBCE ? 1 - lunarYear : lunarYear;

  @override
  String toString() {
    // 天文纪年转历史纪年显示（与 AstroDateTime.toString() 保持一致）
    final yearDisplay = isBCE ? '公元前$historicalYear' : '$historicalYear';
    return "$yearDisplay年$monthNameStr月$dayName";
  }

  static int _astronomicalLunarYearForIndex(
    dynamic result,
    int monthIndex,
    int zhengYueIndex,
  ) {
    final zhengYue1st = AstroDateTime.fromJ2000(result.hs[zhengYueIndex]);
    final historicalYear = monthIndex < zhengYueIndex
        ? zhengYue1st.year - 1
        : zhengYue1st.year;
    return _historicalToAstronomicalYear(historicalYear);
  }

  // SSQ 的历史年份分支在 BCE 段仍按“无 0 年”口径判年。
  // LunarDate 对外统一暴露天文纪年，因此在 API 边界做一次归一化：
  // 历史公元前 1 年 -> 天文年 0，历史公元前 2 年 -> 天文年 -1。
  static int _historicalToAstronomicalYear(int year) {
    return year <= 0 ? year + 1 : year;
  }

  static int _cnToInt(String cn) {
    const map = {
      "正": 1,
      "一": 1,
      "二": 2,
      "三": 3,
      "四": 4,
      "五": 5,
      "六": 6,
      "七": 7,
      "八": 8,
      "九": 9,
      "十": 10,
      "十一": 11,
      "冬": 11,
      "腊": 12,
      "十二": 12,
      "拾贰": 12,
      "十三": 13,
      "后九": 9,
    };
    return map[cn] ?? 0;
  }

  static String _dayToCn(int day) {
    const days = [
      "初一",
      "初二",
      "初三",
      "初四",
      "初五",
      "初六",
      "初七",
      "初八",
      "初九",
      "初十",
      "十一",
      "十二",
      "十三",
      "十四",
      "十五",
      "十六",
      "十七",
      "十八",
      "十九",
      "二十",
      "廿一",
      "廿二",
      "廿三",
      "廿四",
      "廿五",
      "廿六",
      "廿七",
      "廿八",
      "廿九",
      "三十",
    ];
    if (day < 1 || day > days.length) {
      return "$day日";
    }
    return days[day - 1];
  }
}
