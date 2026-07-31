/// 天文现象提取层 (Astro Events)
library;

import 'dart:math' as math;
import 'package:sxwnl_spa_dart/src/sxwnl_dart_base.dart';

class MoonPhaseResult {
  final String name;
  final double jd;
  final AstroDateTime dateTime;

  MoonPhaseResult({
    required this.name,
    required this.jd,
    required this.dateTime,
  });

  @override
  String toString() => '$name: $dateTime';
}

const List<String> moonPhaseNames4 = ["朔", "上弦", "望", "下弦"];
const List<String> moonPhaseNames8 = [
  "朔",
  "峨眉月",
  "上弦",
  "盈凸月",
  "望",
  "亏凸月",
  "下弦",
  "残月",
];

class AstroEvents {
  /// 获取时间范围内发生的精确月相。
  ///
  /// 时间范围采用半开区间 `[start, end)`，日期字段按寿星万年历的北京
  /// 时间约定解释。默认返回朔、上弦、望、下弦四个主月相；设置
  /// [use8Phases] 后，会返回八个 45° 月相节点。
  static List<MoonPhaseResult> getMoonPhases(
    AstroDateTime start,
    AstroDateTime end, {
    bool use8Phases = false,
  }) {
    final startJd = start.toJ2000();
    final endJd = end.toJ2000();
    if (endJd <= startJd) return const [];

    final names = use8Phases ? moonPhaseNames8 : moonPhaseNames4;
    final count = names.length;
    final step = 1.0 / count;

    // 朔望月平均长度约 29.53 日。两端各多搜索两个周期，覆盖边界
    // 处的相位反解误差，也避免季度相位落在估算月序的相邻周期内。
    final firstMonth = ((startJd - 6) / 29.5306).floor() - 2;
    final lastMonth = ((endJd - 6) / 29.5306).ceil() + 2;
    final results = <MoonPhaseResult>[];

    for (var month = firstMonth; month <= lastMonth; month++) {
      for (var i = 0; i < count; i++) {
        final w = (month + i * step) * 2 * math.pi;
        final phaseJD = soAccurate(w);
        if (phaseJD < startJd || phaseJD >= endJd) continue;
        results.add(
          MoonPhaseResult(
            name: names[i],
            jd: phaseJD,
            dateTime: AstroDateTime.fromBJJ2000(phaseJD),
          ),
        );
      }
    }

    results.sort((a, b) => a.jd.compareTo(b.jd));
    final unique = <MoonPhaseResult>[];
    for (final result in results) {
      if (unique.isEmpty || (result.jd - unique.last.jd).abs() > 1e-9) {
        unique.add(result);
      }
    }
    return List<MoonPhaseResult>.unmodifiable(unique);
  }

  /// 获取指定公历年的全部月相。
  ///
  /// 返回该年北京时间 1 月 1 日（含）至次年 1 月 1 日（不含）之间的
  /// 月相，顺序按发生时刻排列。
  static List<MoonPhaseResult> getYearMoonPhases(
    int year, {
    bool use8Phases = false,
  }) {
    return getMoonPhases(
      AstroDateTime(year, 1, 1),
      AstroDateTime(year + 1, 1, 1),
      use8Phases: use8Phases,
    );
  }

  /// 获取指定公历日发生的精确月相。
  ///
  /// 这是对单日 `[start, end)` 范围搜索的便捷封装，底层仍使用
  /// [soAccurate] 反推秒级时刻。
  static MoonPhaseResult? getMoonPhase(
    AstroDateTime targetDate, {
    bool use8Phases = false,
  }) {
    final dayStart = AstroDateTime(
      targetDate.year,
      targetDate.month,
      targetDate.day,
    );
    final dayEnd = dayStart.add(const Duration(days: 1));
    final phases = getMoonPhases(dayStart, dayEnd, use8Phases: use8Phases);
    return phases.isEmpty ? null : phases.first;
  }

  static const List<String> _constellationNames = [
    "摩羯",
    "水瓶",
    "双鱼",
    "白羊",
    "金牛",
    "双子",
    "巨蟹",
    "狮子",
    "处女",
    "天秤",
    "天蝎",
    "射手",
  ];

  /// ### 精确星座查询 (回归黄道 + J2000 相对时间)
  ///
  /// 根据 J2000 相对儒略日 [jd] 计算太阳视黄经，确定其所属星座。
  ///
  /// **坐标与时间约定：**
  /// * **jd 定义**：传入的 [jd] 必须是相对于 J2000.0 (2000-01-01 12:00 UTC) 的天数。
  /// * **回归黄道**：本算法锚定 春分点 (Vernal Equinox) 为白羊座 0° (即太阳视黄经 w = 0)。
  /// * **星座划分**：从春分点开始，每隔 30° (π/6 弧度) 顺向划分一个星座。
  ///
  /// **算法细节：**
  /// * **分级精度**：默认用 n = 10 快速初筛，仅在交界处 ±10 角秒范围内触发 n = -1 全项校准。
  /// * **索引转换**：物理计算中白羊座索引为 0，通过 +3 偏移对齐至以“摩羯”开头的名称数组。
  /// 根据 [AstroDateTime] 获取星座名称（应用层接口）。
  ///
  /// 内部通过 [getPrevJieQi] 查找上一个节气，精度足够满足日常使用。
  /// 如果需要亚秒级物理精度，请使用 [getConstellationFromJd]。
  static String getConstellation(AstroDateTime target) {
    final prevQi = getPrevJieQi(target);
    if (prevQi == null) return "未知";
    return _qiToConstellation(prevQi);
  }

  /// 根据 J2000 相对儒略日 [jd] 获取星座名称（高精度物理层接口）。
  ///
  /// 全程使用 double 精度 JD 比对，不经过 AstroDateTime 转换，
  /// 在交界点附近也能保证亚秒级精度。
  static String getConstellationFromJd(double jd) {
    // 只用 AstroDateTime 获取大致年份，不用于精度比对
    final y = AstroDateTime.fromJ2000(jd).year;

    // 拼接去年和今年的节气，保证边界覆盖
    final allQi = <JieQiResult>[];
    allQi.addAll(getYearJieQi(y - 1));
    allQi.addAll(getYearJieQi(y));

    // 用原始 double jd 直接比大小，零精度损失
    JieQiResult? prevQi;
    for (int i = 0; i < allQi.length; i++) {
      if (jd >= allQi[i].jd) {
        prevQi = allQi[i];
      } else {
        break;
      }
    }

    if (prevQi == null) return "未知";
    return _qiToConstellation(prevQi);
  }

  /// 内部工具：将节气结果映射到星座名称。
  static String _qiToConstellation(JieQiResult prevQi) {
    // 如果上一个交点是 "节"（偶数索引），星座由再上一个 "气" 决定
    final targetQiIndex = prevQi.index % 2 == 0
        ? (prevQi.index - 1)
        : prevQi.index;

    final normalizedIndex = targetQiIndex < 0
        ? targetQiIndex + 24
        : targetQiIndex;
    int index = (((normalizedIndex - 5) ~/ 2) + 3) % 12;
    if (index < 0) index += 12;

    return "${_constellationNames[index]}座";
  }
}

/// 获取时间范围内发生的精确月相。
List<MoonPhaseResult> getMoonPhases(
  AstroDateTime start,
  AstroDateTime end, {
  bool use8Phases = false,
}) => AstroEvents.getMoonPhases(start, end, use8Phases: use8Phases);

/// 获取指定公历年的全部月相。
List<MoonPhaseResult> getYearMoonPhases(int year, {bool use8Phases = false}) =>
    AstroEvents.getYearMoonPhases(year, use8Phases: use8Phases);
