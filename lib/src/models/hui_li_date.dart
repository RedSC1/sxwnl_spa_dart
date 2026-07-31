// ignore_for_file: non_constant_identifier_names

import '../astro_date_time.dart';

/// 寿星万年历使用的算术回历日期。
///
/// 回历（伊斯兰历、Hijri）与中国农历是两套独立历法。寿星原版
/// `oba.getHuiLi()` 使用固定的 30 年回历周期，而不是根据观测新月
/// 或地点重新判定月份；本模型保留这套原版语义。回历纪元以前继续按同一
/// 周期作序推算，因此公元前日期可能得到 `year <= 0` 的序推年份；这不是
/// 对历史伊斯兰历纪年的断言，而是为了让算术模型覆盖完整的天文日期范围。
class HuiLiDate {
  /// 回历年。正常回历日期为 `1 AH` 起；回历纪元以前的序推结果可为 0 或负数。
  final int year;

  /// 回历月，范围为 1..12。
  final int month;

  /// 回历日，范围为 1..30。
  final int day;

  const HuiLiDate({required this.year, required this.month, required this.day})
    : assert(month >= 1 && month <= 12),
      assert(day >= 1 && day <= 30);

  /// 从寿星约定的北京时间 J2000.0 相对日数计算回历日期。
  ///
  /// 原版的 [d0] 通常是北京时间当天中午对应的整数日数；这里允许传入
  /// 任意日内时刻，并按北京时间民用日归属到 `floor(d0 + 0.5)`。
  factory HuiLiDate.fromBJJ2000(double d0) {
    var day = (d0 + .5).floor();
    day += _epochOffset;

    final cycle = (day / _cycleDays).floor();
    var inCycle = day - cycle * _cycleDays;

    final yearInCycle = ((inCycle + .5) / _meanYear).floor();
    inCycle -= (yearInCycle * _meanYear + .5).floor();

    final month = ((inCycle + .11) / _meanMonth).floor();
    inCycle -= (month * 29.5 + .5).floor();

    return HuiLiDate(
      year: cycle * 30 + yearInCycle + 1,
      month: month + 1,
      day: inCycle + 1,
    );
  }

  /// 从北京时间民用日期计算回历日期。
  factory HuiLiDate.fromSolar(AstroDateTime date) =>
      HuiLiDate.fromBJJ2000(date.toJ2000());

  /// 原版字段名兼容别名。
  int get Hyear => year;

  /// 原版字段名兼容别名。
  int get Hmonth => month;

  /// 原版字段名兼容别名。
  int get Hday => day;

  /// 阿拉伯数字形式的回历日期。
  @override
  String toString() => '$year-$month-$day AH';

  @override
  bool operator ==(Object other) =>
      other is HuiLiDate &&
      other.year == year &&
      other.month == month &&
      other.day == day;

  @override
  int get hashCode => Object.hash(year, month, day);

  static const int _epochOffset = 503105;
  static const int _cycleDays = 10631;
  static const double _meanYear = 354.366;
  static const double _meanMonth = 29.51;
}

/// English alias for [HuiLiDate].
typedef HijriDate = HuiLiDate;

/// 原版 `oba.getHuiLi(d0, r)` 的函数式入口。
HuiLiDate getHuiLi(double d0) => HuiLiDate.fromBJJ2000(d0);
