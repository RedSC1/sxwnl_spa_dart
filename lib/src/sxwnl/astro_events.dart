/// 天文现象提取层 (Astro Events)
///
/// 本文件负责从底层的星历坐标中提取人类可读的天文事件。
library;

import 'dart:math' as math;
import '../astro_date_time.dart';
import 'ssq.dart';
import 'solar_lunar_pos.dart';

/// 月相计算结果。
class MoonPhaseResult {
  /// 月相名称 ("朔", "上弦", "望", "下弦" 或 8 相位下的扩展名称)。
  final String name;

  /// J2000 相对儒略日。
  final double jd;

  /// 北京时间。
  final AstroDateTime dateTime;

  MoonPhaseResult({
    required this.name,
    required this.jd,
    required this.dateTime,
  });

  @override
  String toString() => '$name: $dateTime';
}

/// 4 个主要月相名称 (原版 sxwnl 标配)
const List<String> moonPhaseNames4 = ["朔", "上弦", "望", "下弦"];

/// 8 个细分月相名称 (天文学标准扩展)
const List<String> moonPhaseNames8 = [
  "朔", "峨眉月", "上弦", "盈凸月", "望", "亏凸月", "下弦", "残月"
];

class AstroEvents {
  /// 获取指定公历日期 [targetDate] 发生的月相。
  /// 
  /// [use8Phases] 是否使用 8 相位模式。
  static MoonPhaseResult? getMoonPhase(AstroDateTime targetDate, {bool use8Phases = false}) {
    final ssq = SSQ();
    final names = use8Phases ? moonPhaseNames8 : moonPhaseNames4;
    final count = names.length;
    final step = 1.0 / count;

    final jd = targetDate.toJ2000();
    
    // 估算 n (总月数偏移)
    double n_float = (jd - 6) / 29.5306;
    int n = n_float.floor();

    // 检查范围：前后各一个月，确保覆盖所有可能的相位时刻
    for (int monthOffset = -1; monthOffset <= 1; monthOffset++) {
      int currentN = n + monthOffset;
      for (int i = 0; i < count; i++) {
        double W = (currentN + i * step) * 2 * math.pi;
        double phaseJD = ssq.soHigh(W);
        
        // 关键修正：将时刻转换为日期对象，进行精确的年月日对比
        // 这能彻底解决由于儒略日舍入导致的“一天双相”或“一相双占”问题
        final phaseDate = AstroDateTime.fromJ2000(phaseJD);
        if (phaseDate.year == targetDate.year &&
            phaseDate.month == targetDate.month &&
            phaseDate.day == targetDate.day) {
          return MoonPhaseResult(
            name: names[i],
            jd: phaseJD,
            dateTime: phaseDate,
          );
        }
      }
    }
    return null;
  }

  /// 星座名称列表。
  static const List<String> _constellationNames = [
    "摩羯", "水瓶", "双鱼", "白羊", "金牛", "双子",
    "巨蟹", "狮子", "处女", "天秤", "天蝎", "射手"
  ];

  /// 获取指定时刻的星座。
  static String getConstellation(double jd) {
    final ssq = SSQ();
    final res = ssq.calcY(jd);
    int mk = 0;
    // 星座切换点在“中气”上
    for (int i = 0; i <= 22; i += 2) {
      if (jd >= res.zq[i]) {
        mk = i ~/ 2;
      } else {
        break;
      }
    }
    return "${_constellationNames[mk % 12]}座";
  }
}
