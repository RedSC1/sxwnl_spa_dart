/// 天文现象提取层 (Astro Events)
library;

import 'dart:math' as math;
import 'package:sxwnl_spa_dart/src/sxwnl_dart_base.dart';
import 'package:sxwnl_spa_dart/src/jie_qi.dart';

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
  /// ### 获取指定日期发生的精确月相
  ///
  /// 弃用日历级函数，改用物理级 [soAccurate] 反推秒级时刻。
  static MoonPhaseResult? getMoonPhase(
    AstroDateTime targetDate, {
    bool use8Phases = false,
  }) {
    final names = use8Phases ? moonPhaseNames8 : moonPhaseNames4;
    final count = names.length;
    final step = 1.0 / count;
    final jd = targetDate.toJ2000();

    // 估算当前月序
    int n = ((jd - 6) / 29.5306).floor();

    // 检查前后月份，确保不漏掉跨天的相位
    for (int monthOffset = -1; monthOffset <= 1; monthOffset++) {
      int currentN = n + monthOffset;
      for (int i = 0; i < count; i++) {
        // W 是累计弧度（相位点）
        double W = (currentN + i * step) * 2 * math.pi;

        // 【高精度修正】：直接调用底层的牛顿迭代定朔
        double phaseJD = soAccurate(W);

        final phaseDate = AstroDateTime.fromJ2000(phaseJD);

        // 只有时刻落在目标日期内才返回
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
  static String getConstellation(double jd) {
    // 采用 O(1) 的节气查表法，避免底层物理引擎的 TT vs UTC 转换死区。
    // 中气 (索引为奇数: 1, 3, 5... 23) 正好对应十二星座的起点。
    // 春分(5)=白羊, 谷雨(7)=金牛, 小满(9)=双子 ... 雨水(3)=双鱼

    // 1. 获取目标历年。因为节气表是按太阳年算的，我们往前后多取一年，保证边界绝对覆盖。
    final target = AstroDateTime.fromJ2000(jd);
    final y = target.year;

    // 把去年和今年的 50 个节气全拼在一起，必定包含目标 jd
    final allQi = <JieQiResult>[];
    allQi.addAll(getYearJieQi(y - 1));
    allQi.addAll(getYearJieQi(y));

    // 2. 找到最后一个 exact jd <= 当前 jd 的节气
    JieQiResult? prevQi;
    for (int i = 0; i < allQi.length; i++) {
      if (jd >= allQi[i].jd) {
        prevQi = allQi[i];
      } else {
        // 遇到了第一个明显大于 jd 的节气，前面的就是最近的上一个
        break;
      }
    }

    // 安全降级拦截 (理论上必不可能触发，除非传入远古年代)
    if (prevQi == null) return "未知";

    // 3. 将节气映射到星座
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
