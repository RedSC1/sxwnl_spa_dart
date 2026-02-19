/// 干支计算器。
///
/// 移植自寿星万年历 (sxwnl) lunar.js 的 obb.mingLiBaZi 部分。
/// 负责计算年、月、日、时的干支。
library;

import 'delta_t.dart';
import 'math_utils.dart';
import 'solar_lunar_pos.dart';

const List<String> _gan = ["甲", "乙", "丙", "丁", "戊", "己", "庚", "辛", "壬", "癸"];
const List<String> _zhi = ["子", "丑", "寅", "卯", "辰", "巳", "午", "未", "申", "酉", "戌", "亥"];

/// 干支结果
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

/// 计算干支（八字）。
///
/// [jd] 为目标时刻的 J2000 相对儒略日 (UT)，用于年柱、月柱。
/// [trueSolarTimeJD] 为当地真太阳时的 J2000 相对儒略日，用于日柱、时柱。
///
/// 年柱、月柱由节气决定（全球同一瞬间，用 UT）。
/// 日柱、时柱由真太阳时决定（23:00 换日柱）。
GanZhiResult calcGanZhi(double jd, double trueSolarTimeJD) {
  // 1. 年柱、月柱：用 UT 计算节气索引
  final jd2 = jd + dtT(jd);
  final w = sALon(jd2 / 36525.0, -1);
  final k = int2((w / pi2 * 360 + 45 + 15 * 360) / 30);

  // 年柱
  var v = int2(k / 12 + 6000000);
  final yearGan = _gan[v % 10];
  final yearZhi = _zhi[v % 12];

  // 月柱
  v = k + 2 + 60000000;
  final monthGan = _gan[v % 10];
  final monthZhi = _zhi[v % 12];

  // 2. 日柱、时柱：用真太阳时
  // + 13/24 实现 23:00 换日柱（早子时）
  final jdForDay = trueSolarTimeJD + 13.0 / 24.0;
  final D = jdForDay.floor();

  // 日柱
  v = D - 6 + 9000000;
  final dayGan = _gan[v % 10];
  final dayZhi = _zhi[v % 12];

  // 时柱
  final sc = int2((jdForDay - D) * 12);
  v = (D - 1) * 12 + 90000000 + sc;
  final timeGan = _gan[v % 10];
  final timeZhi = _zhi[v % 12];

  return GanZhiResult(
    yearGanZhi: "$yearGan$yearZhi",
    monthGanZhi: "$monthGan$monthZhi",
    dayGanZhi: "$dayGan$dayZhi",
    timeGanZhi: "$timeGan$timeZhi",
    timeZhiIndex: sc % 12,
  );
}

/// 辅助：获取天干
String getGan(int idx) => _gan[idx % 10];

/// 辅助：获取地支
String getZhi(int idx) => _zhi[idx % 12];
