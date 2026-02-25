/// 日历工具 API
///
/// 提供基于日期范围的逐日干支查询，以及按公历、农历、节气三种月份边界的便捷接口。
library;

import '../astro_date_time.dart';
import '../jie_qi.dart';
import '../sxwnl/ssq.dart';
import 'gan_zhi.dart';
import 'lunar_date.dart';

/// 单日信息
class DayInfo {
  /// 阳历日期
  final AstroDateTime solarDate;

  /// 日干支
  final GanZhi ganZhi;

  /// 星期几 (1=周一, 2=周二, ..., 7=周日)
  final int weekday;

  DayInfo({
    required this.solarDate,
    required this.ganZhi,
    required this.weekday,
  });

  @override
  String toString() =>
      '${solarDate.year}-${_pad(solarDate.month)}-${_pad(solarDate.day)} $ganZhi 周${_weekdayLabel[weekday - 1]}';

  static String _pad(int n) => n.toString().padLeft(2, '0');
  static const _weekdayLabel = ['一', '二', '三', '四', '五', '六', '日'];
}

// ================================================================
// 底层核心
// ================================================================

/// 计算某一天的日干支
///
/// 基于 J2000 纪元：2000-01-01 12:00 UT = 戊午日
///
/// [date] 阳历日期（只使用年月日，忽略时分秒）
GanZhi dayGanZhi(AstroDateTime date) {
  return _ganZhiFromDayId(_dayId(date.year, date.month, date.day));
}

/// 计算某一时刻的日干支（支持早晚子时）
///
/// 与 [dayGanZhi] 不同，此方法会考虑时分秒和早晚子时配置：
/// - [splitRatHour] = `false`（默认）：23:00 后算**次日**（不分早晚子，传统换日）
/// - [splitRatHour] = `true`：23:00-00:00 仍算**当日**的晚子时
///
/// ```dart
/// final gz1 = dayGanZhiAt(AstroDateTime(2026, 2, 17, 23, 30));
/// // splitRatHour=false → 返回 2月18日 的日干支
///
/// final gz2 = dayGanZhiAt(AstroDateTime(2026, 2, 17, 23, 30), splitRatHour: true);
/// // splitRatHour=true → 返回 2月17日 的日干支（晚子时仍属当天）
/// ```
GanZhi dayGanZhiAt(AstroDateTime dateTime, {bool splitRatHour = false}) {
  int year = dateTime.year;
  int month = dateTime.month;
  int day = dateTime.day;

  if (!splitRatHour && dateTime.hour >= 23) {
    // 不分早晚子时：23:00 后换日，算次日
    final nextDay = AstroDateTime(year, month, day).add(Duration(days: 1));
    year = nextDay.year;
    month = nextDay.month;
    day = nextDay.day;
  }
  // splitRatHour=true：23:00-00:00 仍属当天，不换日，直接用原日期

  return _ganZhiFromDayId(_dayId(year, month, day));
}

/// 内部：从年月日计算 day ID
int _dayId(int year, int month, int day) {
  final noonJd = AstroDateTime(year, month, day, 12, 0, 0).toJ2000();
  return noonJd.floor();
}

/// 内部：从 day ID 计算日干支
GanZhi _ganZhiFromDayId(int D) {
  // D=0 对应 J2000 纪元 2000-01-01 = 戊午日，偏移 -6 对齐甲子起点
  final offset = D - 6;
  final ganIdx = ((offset % 10) + 10) % 10;
  final zhiIdx = ((offset % 12) + 12) % 12;
  return GanZhi(TianGan.values[ganIdx], DiZhi.values[zhiIdx]);
}

/// 获取某一天是星期几
///
/// 返回 1=周一, 2=周二, ..., 7=周日（与 Dart 的 DateTime.weekday 一致）。
int weekday(AstroDateTime date) {
  final D = _dayId(date.year, date.month, date.day);
  // J2000 纪元 2000-01-01 = 周六(6)
  // (D + 5) % 7: D=0 → 5 % 7 = 5(周六), +1 得 6(周六)
  return ((D + 5) % 7 + 7) % 7 + 1;
}

/// 五鼠遁：根据日干推算时辰干支
///
/// [dayGan] 当日的天干
/// [hourIndex] 时辰索引 (0=子, 1=丑, 2=寅, ..., 11=亥)
///
/// 口诀：甲己还加甲，乙庚丙作初，丙辛从戊起，丁壬庚子居，戊癸何方发，壬子是真途。
///
/// ```dart
/// final gz = hourGanZhi(TianGan.jia, 0); // 甲日子时 → 甲子
/// final gz2 = hourGanZhi(TianGan.yi, 0); // 乙日子时 → 丙子
/// ```
GanZhi hourGanZhi(TianGan dayGan, int hourIndex) {
  // 五鼠遁起始天干索引：甲己→甲(0), 乙庚→丙(2), 丙辛→戊(4), 丁壬→庚(6), 戊癸→壬(8)
  final startGanIdx = (dayGan.index % 5) * 2;
  final ganIdx = (startGanIdx + hourIndex) % 10;
  final zhiIdx = hourIndex % 12;
  return GanZhi(TianGan.values[ganIdx], DiZhi.values[zhiIdx]);
}

/// 五虎遁：根据年干推算月干支
///
/// [yearGan] 当年的天干
/// [monthIndex] 月份索引 (0=寅月/正月, 1=卯月/二月, ..., 11=丑月/腊月)
///
/// 口诀：甲己之年丙作首，乙庚之岁戊为头，丙辛之年寻庚上，丁壬壬寅顺水流，戊癸之年甲寅头。
///
/// ```dart
/// final gz = monthGanZhi(TianGan.jia, 0); // 甲年寅月(正月) → 丙寅
/// final gz2 = monthGanZhi(TianGan.yi, 0); // 乙年寅月(正月) → 戊寅
/// ```
GanZhi monthGanZhi(TianGan yearGan, int monthIndex) {
  // 五虎遁起始天干索引：甲己→丙(2), 乙庚→戊(4), 丙辛→庚(6), 丁壬→壬(8), 戊癸→甲(0)
  final startGanIdx = ((yearGan.index % 5) * 2 + 2) % 10;
  final ganIdx = (startGanIdx + monthIndex) % 10;
  final zhiIdx = (monthIndex + 2) % 12; // 寅=2, 卯=3, ..., 丑=1
  return GanZhi(TianGan.values[ganIdx], DiZhi.values[zhiIdx]);
}

/// 获取日期范围内每一天的日干支
///
/// 返回从 [start] 到 [end]（**含首尾**）的逐日干支列表。
/// [start] 和 [end] 只使用年月日部分，时分秒被忽略。
///
/// ```dart
/// final days = getDayRange(
///   AstroDateTime(2026, 2, 1),
///   AstroDateTime(2026, 2, 28),
/// );
/// ```
List<DayInfo> getDayRange(AstroDateTime start, AstroDateTime end) {
  final startDate = AstroDateTime(start.year, start.month, start.day, 12, 0, 0);
  final endDate = AstroDateTime(end.year, end.month, end.day, 12, 0, 0);

  final startJd = startDate.toJ2000();
  final endJd = endDate.toJ2000();
  final totalDays = (endJd - startJd).round() + 1;

  if (totalDays <= 0) return [];

  // 计算第一天的干支
  final firstGanZhi = dayGanZhi(startDate);

  final result = <DayInfo>[];
  for (int i = 0; i < totalDays; i++) {
    final date = startDate.add(Duration(days: i));
    final gz = firstGanZhi + i; // 利用 GanZhi 的 + 运算符逐日递推
    result.add(
      DayInfo(
        solarDate: AstroDateTime(date.year, date.month, date.day),
        ganZhi: gz,
        weekday: weekday(AstroDateTime(date.year, date.month, date.day)),
      ),
    );
  }

  return result;
}

// ================================================================
// 公历月份
// ================================================================

/// 获取公历某月的逐日干支表
///
/// [year] 公历年份
/// [month] 公历月份 (1-12)
///
/// ```dart
/// final days = getSolarMonthDays(2026, 2);
/// // 返回 2026年2月1日 ~ 2月28日 的28天日历
/// ```
List<DayInfo> getSolarMonthDays(int year, int month) {
  final start = AstroDateTime(year, month, 1);

  // 计算该月天数：下个月1号 - 当月1号
  int nextMonth = month + 1;
  int nextYear = year;
  if (nextMonth > 12) {
    nextMonth = 1;
    nextYear++;
  }
  final nextMonthStart = AstroDateTime(nextYear, nextMonth, 1);
  final daysInMonth = (nextMonthStart.toJ2000() - start.toJ2000()).round();

  final end = AstroDateTime(year, month, daysInMonth);
  return getDayRange(start, end);
}

// ================================================================
// 农历月份
// ================================================================

/// 获取农历某月的逐日干支表
///
/// [lunarYear] 农历年份
/// [monthName] 农历月份名称（如 "正", "二", "闰五", "后九", "腊" 等）
///
/// 返回该农历月每一天对应的阳历日期和日干支。
///
/// ```dart
/// final days = getLunarMonthDays(2025, "正");
/// // 返回 2025年正月 的逐日日历
/// ```
List<DayInfo> getLunarMonthDays(int lunarYear, String monthName) {
  // 1. 利用 LunarDate 找到该月初一的阳历日期
  final firstDay = LunarDate.fromString(lunarYear, monthName, 1);
  final startSolar = firstDay.toSolar;

  // 2. 通过 SSQ 获取该月天数
  final ssq = SSQ();
  final result = ssq.calcY(AstroDateTime(lunarYear, 6, 1).toJ2000());

  int daysInMonth = 30; // 默认值
  for (int i = 0; i < result.ym.length; i++) {
    if (_matchLunarMonth(result, i, monthName)) {
      daysInMonth = result.dx[i];
      break;
    }
  }

  // 3. 生成日期范围
  final endSolar = startSolar.add(Duration(days: daysInMonth - 1));
  return getDayRange(
    AstroDateTime(startSolar.year, startSolar.month, startSolar.day),
    AstroDateTime(endSolar.year, endSolar.month, endSolar.day),
  );
}

/// 内部：匹配农历月名
bool _matchLunarMonth(dynamic result, int index, String targetName) {
  final rawName = result.ym[index];
  final isLeapIdx = (result.leap > 0 && index == result.leap);

  // 特殊月名直接比较
  if (rawName == targetName) return true;

  // 处理闰月：SSQ 返回的 rawName 不带"闰"前缀，需要根据 leap index 判断
  if (targetName.startsWith("闰")) {
    final clean = targetName.replaceAll("闰", "");
    return rawName == clean && isLeapIdx;
  }

  // 非闰月匹配
  return rawName == targetName && !isLeapIdx;
}

// ================================================================
// 节气月份
// ================================================================

/// 获取某个节气区间（节令月）的逐日干支表
///
/// 返回包含 [date] 所在的"节令月"——即**上一个节**到**下一个节**之间的所有日期。
///
/// 注意：这里用的是"节"（立春、惊蛰...）而非"气"（雨水、春分...），
/// 因为八字月柱以"节"为分界。
///
/// ```dart
/// final days = getJieQiPeriodDays(AstroDateTime(2026, 3, 15));
/// // 返回 惊蛰 ~ 清明 之间的逐日日历
/// ```
List<DayInfo> getJieQiPeriodDays(AstroDateTime date) {
  // 1. 找到上一个"节"和下一个"节"
  final prevJie = getPrevJie(date);
  final nextJie = getNextJie(date);

  if (prevJie == null || nextJie == null) return [];

  final start = prevJie.dateTime;
  final end = nextJie.dateTime.subtract(Duration(days: 1)); // 不含下一个节当天

  return getDayRange(
    AstroDateTime(start.year, start.month, start.day),
    AstroDateTime(end.year, end.month, end.day),
  );
}
