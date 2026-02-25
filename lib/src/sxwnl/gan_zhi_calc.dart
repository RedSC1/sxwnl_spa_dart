/// 干支计算器。
///
/// 移植自寿星万年历 (sxwnl) lunar.js 的 obb.mingLiBaZi 部分。
/// 负责计算年、月、日、时的干支。
library;

import 'delta_t.dart';
import 'math_utils.dart';
import 'solar_lunar_pos.dart';
import '../models/gan_zhi.dart';

const List<String> _gan = ["甲", "乙", "丙", "丁", "戊", "己", "庚", "辛", "壬", "癸"];
const List<String> _zhi = [
  "子",
  "丑",
  "寅",
  "卯",
  "辰",
  "巳",
  "午",
  "未",
  "申",
  "酉",
  "戌",
  "亥",
];

/// 干支结果（字符串版本，保留原版 sxwnl 行为）
class GanZhiResult {
  final String yearGanZhi;
  final String monthGanZhi;
  final String dayGanZhi;
  final String timeGanZhi;
  final int timeZhiIndex;

  GanZhiResult({
    required this.yearGanZhi,
    required this.monthGanZhi,
    required this.dayGanZhi,
    required this.timeGanZhi,
    required this.timeZhiIndex,
  });

  @override
  String toString() => '$yearGanZhi $monthGanZhi $dayGanZhi $timeGanZhi';
}

/// 八字计算结果（类型安全版本）
///
/// 包含类型安全的 [BaZi] 对象和时辰地支索引。
class BaZiCalcResult {
  /// 类型安全的八字四柱
  final BaZi bazi;

  /// 时辰地支索引 (0=子, 1=丑, ..., 11=亥)
  final int timeZhiIndex;

  BaZiCalcResult({required this.bazi, required this.timeZhiIndex});

  @override
  String toString() => '$bazi';
}

// ================================================================
// 内部核心计算（共用逻辑）
// ================================================================

/// 内部：计算干支原始索引
({
  int yearGanIdx,
  int yearZhiIdx,
  int monthGanIdx,
  int monthZhiIdx,
  int dayGanIdx,
  int dayZhiIdx,
  int timeGanIdx,
  int timeZhiIdx,
  int sc,
})
_calcRawIndices(double jd, double trueSolarTimeJD) {
  // 1. 年柱、月柱：用 UT 计算节气索引
  final jd2 = jd + dtT(jd);
  final w = sALon(jd2 / 36525.0, -1);
  final k = int2((w / pi2 * 360 + 45 + 15 * 360) / 30);

  // 年柱
  var v = int2(k / 12 + 6000000);
  final yearGanIdx = v % 10;
  final yearZhiIdx = v % 12;

  // 月柱
  v = k + 2 + 60000000;
  final monthGanIdx = v % 10;
  final monthZhiIdx = v % 12;

  // 2. 日柱、时柱：用真太阳时
  // + 13/24 实现 23:00 换日柱（早子时）
  final jdForDay = trueSolarTimeJD + 13.0 / 24.0;
  final D = jdForDay.floor();

  // 日柱
  v = D - 6 + 9000000;
  final dayGanIdx = v % 10;
  final dayZhiIdx = v % 12;

  // 时柱
  final sc = int2((jdForDay - D) * 12);
  v = (D - 1) * 12 + 90000000 + sc;
  final timeGanIdx = v % 10;
  final timeZhiIdx = v % 12;

  return (
    yearGanIdx: yearGanIdx,
    yearZhiIdx: yearZhiIdx,
    monthGanIdx: monthGanIdx,
    monthZhiIdx: monthZhiIdx,
    dayGanIdx: dayGanIdx,
    dayZhiIdx: dayZhiIdx,
    timeGanIdx: timeGanIdx,
    timeZhiIdx: timeZhiIdx,
    sc: sc,
  );
}

// ================================================================
// 公开 API
// ================================================================

/// 计算干支（八字）—— 字符串版本（保留原版 sxwnl 行为）。
///
/// [jd] 为目标时刻的 J2000 相对儒略日 (UT)，用于年柱、月柱。
/// [trueSolarTimeJD] 为当地真太阳时的 J2000 相对儒略日，用于日柱、时柱。
///
/// 年柱、月柱由节气决定（全球同一瞬间，用 UT）。
/// 日柱、时柱由真太阳时决定（23:00 换日柱）。
GanZhiResult calcGanZhi(double jd, double trueSolarTimeJD) {
  final r = _calcRawIndices(jd, trueSolarTimeJD);

  return GanZhiResult(
    yearGanZhi: "${_gan[r.yearGanIdx]}${_zhi[r.yearZhiIdx]}",
    monthGanZhi: "${_gan[r.monthGanIdx]}${_zhi[r.monthZhiIdx]}",
    dayGanZhi: "${_gan[r.dayGanIdx]}${_zhi[r.dayZhiIdx]}",
    timeGanZhi: "${_gan[r.timeGanIdx]}${_zhi[r.timeZhiIdx]}",
    timeZhiIndex: r.sc % 12,
  );
}

/// 计算干支（八字）—— 类型安全版本。
///
/// 返回 [BaZiCalcResult]，包含类型安全的 [BaZi] 对象。
/// 参数含义同 [calcGanZhi]。
BaZiCalcResult calcBaZi(double jd, double trueSolarTimeJD) {
  final r = _calcRawIndices(jd, trueSolarTimeJD);

  final bazi = BaZi(
    year: GanZhi(TianGan.values[r.yearGanIdx], DiZhi.values[r.yearZhiIdx]),
    month: GanZhi(TianGan.values[r.monthGanIdx], DiZhi.values[r.monthZhiIdx]),
    day: GanZhi(TianGan.values[r.dayGanIdx], DiZhi.values[r.dayZhiIdx]),
    time: GanZhi(TianGan.values[r.timeGanIdx], DiZhi.values[r.timeZhiIdx]),
  );

  return BaZiCalcResult(bazi: bazi, timeZhiIndex: r.sc % 12);
}

/// 辅助：获取天干
String getGan(int idx) => _gan[idx % 10];

/// 辅助：获取地支
String getZhi(int idx) => _zhi[idx % 12];
