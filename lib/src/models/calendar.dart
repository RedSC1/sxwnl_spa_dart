/// 日历工具 API
///
/// 提供基于日期范围的逐日干支查询，以及按公历、农历、节气三种月份边界的便捷接口。
library;

import 'dart:math' as math;
import '../astro_date_time.dart';
import '../jie_qi.dart';
import '../sxwnl/ssq.dart';
import 'gan_zhi.dart';
import 'lunar_date.dart';
import '../location.dart';
import '../sxwnl/true_solar_time.dart';
import '../sxwnl/astro_events.dart';

/// 单日信息 (对标原版 sxwnl 的 ob 对象)
class DayInfo {
  final AstroDateTime solarDate;
  final LunarDate lunarDate;
  final int lunarMonthSize;
  final GanZhi ganZhi;
  final int weekday;
  final String? solarTerm;
  final AstroDateTime? solarTermTime;
  final String? moonPhase;
  final AstroDateTime? moonPhaseTime;
  final AstroDateTime? sunrise;
  final AstroDateTime? sunset;
  final PolarStatus polarStatus;
  final String constellation;

  DayInfo({
    required this.solarDate,
    required this.lunarDate,
    required this.lunarMonthSize,
    required this.ganZhi,
    required this.weekday,
    required this.constellation,
    this.polarStatus = PolarStatus.none,
    this.solarTerm,
    this.solarTermTime,
    this.moonPhase,
    this.moonPhaseTime,
    this.sunrise,
    this.sunset,
  });

  /// 拷贝并替换部分字段 (用于扩展功能打补丁)
  DayInfo copyWith({
    AstroDateTime? solarDate,
    LunarDate? lunarDate,
    int? lunarMonthSize,
    GanZhi? ganZhi,
    int? weekday,
    String? constellation,
    PolarStatus? polarStatus,
    String? solarTerm,
    AstroDateTime? solarTermTime,
    String? moonPhase,
    AstroDateTime? moonPhaseTime,
    AstroDateTime? sunrise,
    AstroDateTime? sunset,
  }) {
    return DayInfo(
      solarDate: solarDate ?? this.solarDate,
      lunarDate: lunarDate ?? this.lunarDate,
      lunarMonthSize: lunarMonthSize ?? this.lunarMonthSize,
      ganZhi: ganZhi ?? this.ganZhi,
      weekday: weekday ?? this.weekday,
      constellation: constellation ?? this.constellation,
      polarStatus: polarStatus ?? this.polarStatus,
      solarTerm: solarTerm ?? this.solarTerm,
      solarTermTime: solarTermTime ?? this.solarTermTime,
      moonPhase: moonPhase ?? this.moonPhase,
      moonPhaseTime: moonPhaseTime ?? this.moonPhaseTime,
      sunrise: sunrise ?? this.sunrise,
      sunset: sunset ?? this.sunset,
    );
  }

  /// 星期几的中文名称 (一, 二, ..., 日)
  String get weekdayName => _weekdayLabel[weekday - 1];

  @override
  String toString() {
    String s =
        '${solarDate.year}-${_pad(solarDate.month)}-${_pad(solarDate.day)} ';
    s += '$ganZhi 周$weekdayName $constellation ';
    s += '农历$lunarDate(${lunarMonthSize == 30 ? "大" : "小"})';

    if (solarTerm != null) s += ' [$solarTerm ${_timeStr(solarTermTime!)}]';
    if (moonPhase != null) s += ' ($moonPhase ${_timeStr(moonPhaseTime!)})';
    
    if (polarStatus == PolarStatus.polarDay) {
      s += ' {全天极昼}';
    } else if (polarStatus == PolarStatus.polarNight) {
      s += ' {全天极夜}';
    } else if (sunrise != null && sunset != null) {
      s += ' {日出 ${_timeStr(sunrise!)} / 日落 ${_timeStr(sunset!)}}';
    }
    return s;
  }

  static String _pad(int n) => n.toString().padLeft(2, '0');
  static const _weekdayLabel = ['一', '二', '三', '四', '五', '六', '日'];
}

/// 年份信息
class YearInfo {
  final int year;
  final GanZhi ganZhi;
  YearInfo({required this.year, required this.ganZhi});
  @override
  String toString() => '$year $ganZhi';
}

// ================================================================
// 底层核心
// ================================================================

GanZhi yearGanZhi(int year) {
  final offset = (year - 4) % 60;
  final index = (offset + 60) % 60;
  return GanZhi(TianGan.values[index % 10], DiZhi.values[index % 12]);
}

List<YearInfo> getYearRange(int startYear, int endYear) {
  final count = endYear - startYear + 1;
  if (count <= 0) return [];
  final result = <YearInfo>[];
  for (int i = 0; i < count; i++) {
    final year = startYear + i;
    result.add(YearInfo(year: year, ganZhi: yearGanZhi(year)));
  }
  return result;
}

List<GanZhi> getYearMonthGanZhi(TianGan yearGan) => List.generate(12, (i) => monthGanZhi(yearGan, i));
List<GanZhi> getDayHourGanZhi(TianGan dayGan) => List.generate(12, (i) => hourGanZhi(dayGan, i));

GanZhi dayGanZhi(AstroDateTime date) => _ganZhiFromDayId(_dayId(date.year, date.month, date.day));

GanZhi dayGanZhiAt(AstroDateTime dateTime, {bool splitRatHour = false}) {
  int year = dateTime.year;
  int month = dateTime.month;
  int day = dateTime.day;
  if (!splitRatHour && dateTime.hour >= 23) {
    final nextDay = AstroDateTime(year, month, day).add(Duration(days: 1));
    year = nextDay.year; month = nextDay.month; day = nextDay.day;
  }
  return _ganZhiFromDayId(_dayId(year, month, day));
}

int _dayId(int year, int month, int day) => AstroDateTime(year, month, day, 12, 0, 0).toJ2000().floor();

GanZhi _ganZhiFromDayId(int D) {
  final offset = D - 6;
  return GanZhi(TianGan.values[((offset % 10) + 10) % 10], DiZhi.values[((offset % 12) + 12) % 12]);
}

int weekday(AstroDateTime date) => ((_dayId(date.year, date.month, date.day) + 5) % 7 + 7) % 7 + 1;

GanZhi hourGanZhi(TianGan dayGan, int hourIndex) {
  final startGanIdx = (dayGan.index % 5) * 2;
  return GanZhi(TianGan.values[(startGanIdx + hourIndex) % 10], DiZhi.values[hourIndex % 12]);
}

GanZhi monthGanZhi(TianGan yearGan, int monthIndex) {
  final startGanIdx = ((yearGan.index % 5) * 2 + 2) % 10;
  return GanZhi(TianGan.values[(startGanIdx + monthIndex) % 10], DiZhi.values[(monthIndex + 2) % 12]);
}

/// 获取日期范围内每一天的日历详细信息
List<DayInfo> getDayRange(AstroDateTime start, AstroDateTime end, {Location? location}) {
  final startDate = AstroDateTime(start.year, start.month, start.day, 12, 0, 0);
  final endDate = AstroDateTime(end.year, end.month, end.day, 12, 0, 0);
  final startJd = startDate.toJ2000();
  final endJd = endDate.toJ2000();
  final totalDays = (endJd - startJd).round() + 1;
  if (totalDays <= 0) return [];

  final years = <int>{};
  for (int i = 0; i < totalDays; i++) years.add(startDate.add(Duration(days: i)).year);
  
  final jqMap = <String, JieQiResult>{};
  for (final y in years) {
    for (final jq in getYearJieQi(y)) {
      final key = "${jq.dateTime.year}-${_pad(jq.dateTime.month)}-${_pad(jq.dateTime.day)}";
      jqMap[key] = jq;
    }
  }

  final firstGanZhi = dayGanZhi(startDate);
  final result = <DayInfo>[];
  
  for (int i = 0; i < totalDays; i++) {
    final date = startDate.add(Duration(days: i));
    final currentJD = date.toJ2000();
    
    final lunar = LunarDate.fromSolar(date);
    final dateKey = "${date.year}-${_pad(date.month)}-${_pad(date.day)}";
    final jq = jqMap[dateKey];
    
    final mp = AstroEvents.getMoonPhase(date);
    final constellation = AstroEvents.getConstellation(currentJD);

    AstroDateTime? sunrise, sunset;
    PolarStatus polarStatus = PolarStatus.none;
    if (location != null) {
      final solarRes = calcTrueSolarTime(date, location);
      sunrise = solarRes.sunrise;
      sunset = solarRes.sunset;
      polarStatus = solarRes.polarStatus;
    }

    result.add(DayInfo(
      solarDate: AstroDateTime(date.year, date.month, date.day),
      lunarDate: lunar,
      lunarMonthSize: lunar.monthSize,
      ganZhi: firstGanZhi + i,
      weekday: weekday(date),
      constellation: constellation,
      polarStatus: polarStatus,
      solarTerm: jq?.name,
      solarTermTime: jq?.dateTime,
      moonPhase: mp?.name,
      moonPhaseTime: mp?.dateTime,
      sunrise: sunrise,
      sunset: sunset,
    ));
  }
  return result;
}

String _pad(int n) => n.toString().padLeft(2, '0');
String _timeStr(AstroDateTime dt) => dt.toTimeString();

// ================================================================
// 快捷接口
// ================================================================

List<DayInfo> getSolarMonthDays(int year, int month, {Location? location}) {
  final start = AstroDateTime(year, month, 1);
  int nextMonth = month + 1, nextYear = year;
  if (nextMonth > 12) { nextMonth = 1; nextYear++; }
  final daysInMonth = (AstroDateTime(nextYear, nextMonth, 1).toJ2000() - start.toJ2000()).round();
  return getDayRange(start, AstroDateTime(year, month, daysInMonth), location: location);
}

List<DayInfo> getLunarMonthDays(int lunarYear, String monthName, {Location? location}) {
  final startSolar = LunarDate.fromString(lunarYear, monthName, 1).toSolar;
  final result = SSQ().calcY(AstroDateTime(lunarYear, 6, 1).toJ2000());
  int daysInMonth = 30;
  for (int i = 0; i < result.ym.length; i++) {
    if (_matchLunarMonth(result, i, monthName)) { daysInMonth = result.dx[i]; break; }
  }
  return getDayRange(AstroDateTime(startSolar.year, startSolar.month, startSolar.day), startSolar.add(Duration(days: daysInMonth - 1)), location: location);
}

bool _matchLunarMonth(dynamic result, int index, String targetName) {
  final rawName = result.ym[index];
  final isLeapIdx = (result.leap > 0 && index == result.leap);
  if (rawName == targetName) return true;
  if (targetName.startsWith("闰")) return rawName == targetName.replaceAll("闰", "") && isLeapIdx;
  return rawName == targetName && !isLeapIdx;
}

List<DayInfo> getJieQiPeriodDays(AstroDateTime date, {Location? location}) {
  final start = getPrevJie(date)?.dateTime, end = getNextJie(date)?.dateTime.subtract(Duration(days: 1));
  if (start == null || end == null) return [];
  return getDayRange(start, end, location: location);
}
