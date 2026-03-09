import 'dart:math';

import 'astro_date_time.dart';
import 'sxwnl/delta_t.dart';
import 'sxwnl/solar_lunar_pos.dart';

/// 二十四节气名称列表（按阳历年顺序排列）。
///
/// 顺序：小寒、大寒、立春、雨水、惊蛰、春分、清明、谷雨、立夏、小满、芒种、
///       夏至、小暑、大暑、立秋、处暑、白露、秋分、寒露、霜降、立冬、小雪、大雪、冬至。
///
/// 节（偶数索引）：小寒、立春、惊蛰、清明、立夏、芒种、小暑、立秋、白露、寒露、立冬、大雪
/// 气（奇数索引）：大寒、雨水、春分、谷雨、小满、夏至、大暑、处暑、秋分、霜降、小雪、冬至
const List<String> jieQiNames = [
  '小寒',
  '大寒',
  '立春',
  '雨水',
  '惊蛰',
  '春分',
  '清明',
  '谷雨',
  '立夏',
  '小满',
  '芒种',
  '夏至',
  '小暑',
  '大暑',
  '立秋',
  '处暑',
  '白露',
  '秋分',
  '寒露',
  '霜降',
  '立冬',
  '小雪',
  '大雪',
  '冬至',
];

/// 判断一个节气是否是"节"。
///
/// [index] 节气在 jieQiNames 中的索引（0-23）。
bool isJie(int index) => index % 2 == 0;

/// 判断一个节气是否是"气"。
///
/// [index] 节气在 jieQiNames 中的索引（0-23）。
bool isQi(int index) => index % 2 == 1;

/// 单个节气的计算结果。
class JieQiResult {
  /// 在当年节气列表中的索引（0-23）。
  final int index;

  /// 节气名称（如"立春"、"雨水"）。
  final String name;

  /// J2000 相对儒略日。
  final double jd;

  /// 北京时间（UTC+8）。
  final AstroDateTime dateTime;

  JieQiResult({
    required this.index,
    required this.name,
    required this.jd,
    required this.dateTime,
  });

  @override
  String toString() => '$name: $dateTime';
}

// ==================== 核心定气计算 ====================

/// ### 高精度定气
///
/// 已知太阳视黄经，反推精确的交节时刻。
///
/// **调用注意：**
/// * **累计弧度 [w]**：注意！这不仅仅是 0 到 2π。它是从 J2000 开始算的**累计值**。
///   - 0：2000 年春分
///   - 2π：2001 年春分
///   - 2π * n：第 n 年后的春分
///   - 如果你只传 0 到 2π 之间的数，永远只能算出 2000 年那几个节气。
/// * **单位**：必须是弧度，别传角度。
/// * **返回值**：北京时间 (J2000 相对天数)。内部已处理过 ΔT 并强制 `+8/24`。
double qiAccurate(double w) {
  final t = sALonT(w) * 36525.0;
  return t - dtT(t) + 8 / 24;
}

/// ### 智能定气搜索
///
/// 根据给定的儒略日 [jd]，自动寻找并计算最近的一个精确节气时刻。
///
/// **核心逻辑：**
/// * **初值估算**：利用回归年长度（365.2422天）将 [jd] 转换为对应的**累计弧度** [w]。
/// * **档位对齐**：`pi / 12` 代表 15 度（一个节气）。通过 `floor` 强行对齐到最近的节气档位。
/// * **双重保险**：如果初次算出的时刻离 [jd] 超过 5 天，说明轨道摄动太猛导致"找错档位"了，会自动前后挪一个节气重算。
///
/// [jd] 为北京时间（相对 J2000 的天数）。
double qiAccurate2(double jd) {
  final d = pi / 12;

  // 这里的 293 是从 J2000 历元到冬至的偏移天数估算
  // 注意：必须用 .floor() 保证在处理古代负数年份时取整逻辑不走样
  var w = ((jd + 293) / 365.2422 * 24).floor() * d;

  var a = qiAccurate(w);

  // 容错校准：偏差超过 5 天则切换相邻节气档位
  if (a - jd > 5) return qiAccurate(w - d);
  if (a - jd < -5) return qiAccurate(w + d);

  return a;
}

/// ### 获取指定年份的特定节气时刻 (单点查询)
///
/// 利用太阳视黄经模型直接推算特定节气，不生成全年历表。
///
/// **参数约定：**
/// * [year] 公历年份 (如 2026)。
/// * [n] 节气序号 (0~23)，以**春分**为 0 起点：
///   - 0=春分, 1=清明 ... 18=冬至 (发生于当年)
///   - 19=小寒, 20=大寒, 21=立春, 22=雨水, 23=惊蛰 (发生于次年 1~3 月)
///
/// **跨年物理修正：**
/// 天文学轨道周期以 3 月的春分为起点。当查询 1~3 月的节气 (n >= 19) 时，
/// 物理模型上属于“上一个天文年”的末尾。内部已作自动偏移处理。
double getSpecificJieQi(int year, int n) {
  int astroYear = year;
  // 修正 1~3 月节气的天文纪年偏移
  if (n >= 19) {
    astroYear -= 1;
  }

  // 计算累计弧度:
  // (astroYear - 2000) * 2 * pi -> 2000年起算的整圈数
  // n * (pi / 12) -> 当前圈内的局部节气偏移
  final w = (astroYear - 2000) * 2 * pi + n * (pi / 12);

  // 调用高精度定气，返回 J2000 相对天数 (北京时间)
  return qiAccurate(w);
}

// ==================== 内部 slot 定位引擎 ====================
//
// 每个节气在天文模型中对应一个"slot"编号。
// slot 0 = 2000 年春分, slot 1 = 2000 年清明, ..., slot 24 = 2001 年春分。
// 对应的黄经弧度 w = slot * (π/12)。
//
// slot → jieQiNames 的映射：春分在天文模型中是 slot%24==0，
// 在 jieQiNames 中是 index 5，所以 nameIndex = ((slot%24) + 5 + 24) % 24。

/// 从儒略日估算 slot 编号。
int _estimateSlot(double jd) => ((jd + 293) / 365.2422 * 24).floor();

/// 将 slot 编号转换为 jieQiNames 索引 (0-23)。
int _slotToIndex(int slot) => ((slot % 24) + 5 + 24) % 24;

/// 从 slot 编号构造 [JieQiResult]（调用一次 qiAccurate）。
JieQiResult _slotToResult(int slot) {
  final jd = qiAccurate(slot * (pi / 12));
  final idx = _slotToIndex(slot);
  return JieQiResult(
    index: idx,
    name: jieQiNames[idx],
    jd: jd,
    dateTime: AstroDateTime.fromJ2000(jd),
  );
}

/// 向前搜索：找到 targetJD 之前最近的节气。
///
/// [filter] 可选过滤器，传 `isJie` 则只匹配节，传 `isQi` 则只匹配气。
/// 内部仅需 2-3 次 qiAccurate 调用（对比旧版的 75 次）。
JieQiResult _findPrev(double targetJD, {bool Function(int)? filter}) {
  final d = pi / 12;
  var slot = _estimateSlot(targetJD);

  // 1. 定位：确保 slot 对应的节气 <= targetJD
  if (qiAccurate(slot * d) > targetJD) {
    slot--;
  } else {
    // 检查下一个 slot 是否也在 target 之前（轨道偏心率导致）
    if (qiAccurate((slot + 1) * d) <= targetJD) slot++;
  }

  // 2. 过滤：如需只找节或只找气，往前退一步
  if (filter != null) {
    while (!filter(_slotToIndex(slot))) {
      slot--;
    }
  }

  return _slotToResult(slot);
}

/// 向后搜索：找到 targetJD 之后最近的节气。
///
/// [filter] 可选过滤器，传 `isJie` 则只匹配节，传 `isQi` 则只匹配气。
JieQiResult _findNext(double targetJD, {bool Function(int)? filter}) {
  final d = pi / 12;
  var slot = _estimateSlot(targetJD) + 1;

  // 1. 定位：确保 slot 对应的节气 > targetJD
  if (qiAccurate(slot * d) <= targetJD) slot++;

  // 2. 过滤
  if (filter != null) {
    while (!filter(_slotToIndex(slot))) {
      slot++;
    }
  }

  return _slotToResult(slot);
}

// ==================== 批量查询 ====================

/// 获取指定阳历年的所有节气。
///
/// [year] 阳历年（如 2025）。
/// 返回从上一个冬至到当前冬至的节气列表（共25个节气，符合传统历法计算"岁"的范围）。
List<JieQiResult> getYearJieQi(int year) {
  final results = <JieQiResult>[];
  final y = year - 2000;

  // i = 0 是该年春分
  // i = -6 是上一年的冬至
  // i = 18 是当前年的冬至
  for (var i = -6; i <= 18; i++) {
    final w = (y + i / 24 + 1) * 2 * pi;
    final jd = qiAccurate(w);

    // 春分(i=0)在 jieQiNames 中的索引是 5
    int index = (i + 5) % 24;
    if (index < 0) {
      index += 24;
    }

    results.add(
      JieQiResult(
        index: index,
        name: jieQiNames[index],
        jd: jd,
        dateTime: AstroDateTime.fromJ2000(jd),
      ),
    );
  }

  return results;
}

// ==================== 单点查询 API ====================

/// 获取目标日期之前最近的一个节气。
JieQiResult? getPrevJieQi(AstroDateTime target) => _findPrev(target.toJ2000());

/// 获取目标日期之后最近的一个节气。
JieQiResult? getNextJieQi(AstroDateTime target) => _findNext(target.toJ2000());

/// 获取目标日期之前最近的一个"节"。
JieQiResult? getPrevJie(AstroDateTime target) =>
    _findPrev(target.toJ2000(), filter: isJie);

/// 获取目标日期之后最近的一个"节"。
JieQiResult? getNextJie(AstroDateTime target) =>
    _findNext(target.toJ2000(), filter: isJie);

/// 获取目标日期之前最近的一个"气"。
JieQiResult? getPrevQi(AstroDateTime target) =>
    _findPrev(target.toJ2000(), filter: isQi);

/// 获取目标日期之后最近的一个"气"。
JieQiResult? getNextQi(AstroDateTime target) =>
    _findNext(target.toJ2000(), filter: isQi);

// ==================== 距离模型 ====================

/// 通用节气区段距离模型（基类）。
///
/// [prev] 与 [next] 之间的时间区段，记录了目标日期在区段中的位置。
class SolarTermSpan {
  /// 区段起点节气。
  final JieQiResult prev;

  /// 区段终点节气。
  final JieQiResult next;

  /// 距离起点的天数。
  final double daysSincePrev;

  /// 距离终点的天数。
  final double daysUntilNext;

  /// 区段总天数。
  final double totalDays;

  SolarTermSpan({
    required this.prev,
    required this.next,
    required this.daysSincePrev,
    required this.daysUntilNext,
    required this.totalDays,
  });

  /// 在区段中的进度（0.0 - 1.0）。
  double get progress => daysSincePrev / totalDays;

  @override
  String toString() {
    return '距${prev.name}: ${daysSincePrev.toStringAsFixed(2)}天, '
        '距${next.name}: ${daysUntilNext.toStringAsFixed(2)}天, '
        '进度: ${(progress * 100).toStringAsFixed(1)}%';
  }
}

/// 目标日期与前后节气的距离信息（向后兼容）。
class JieQiDistance extends SolarTermSpan {
  JieQiDistance({
    required super.prev,
    required super.next,
    required super.daysSincePrev,
    required super.daysUntilNext,
    required super.totalDays,
  });
}

/// 目标日期与前后"节"的距离信息（向后兼容）。
class JieDistance extends SolarTermSpan {
  JieDistance({
    required JieQiResult prevJie,
    required JieQiResult nextJie,
    required double daysSincePrevJie,
    required double daysUntilNextJie,
    required double totalJieDays,
  }) : super(
         prev: prevJie,
         next: nextJie,
         daysSincePrev: daysSincePrevJie,
         daysUntilNext: daysUntilNextJie,
         totalDays: totalJieDays,
       );

  // 向后兼容的别名
  JieQiResult get prevJie => prev;
  JieQiResult get nextJie => next;
  double get daysSincePrevJie => daysSincePrev;
  double get daysUntilNextJie => daysUntilNext;
  double get totalJieDays => totalDays;
  double get jieProgress => progress;

  @override
  String toString() {
    return '距${prev.name}: ${daysSincePrev.toStringAsFixed(2)}天, '
        '距${next.name}: ${daysUntilNext.toStringAsFixed(2)}天, '
        '节进度: ${(progress * 100).toStringAsFixed(1)}%';
  }
}

/// 目标日期与前后"气"的距离信息（向后兼容）。
class QiDistance extends SolarTermSpan {
  QiDistance({
    required JieQiResult prevQi,
    required JieQiResult nextQi,
    required double daysSincePrevQi,
    required double daysUntilNextQi,
    required double totalQiDays,
  }) : super(
         prev: prevQi,
         next: nextQi,
         daysSincePrev: daysSincePrevQi,
         daysUntilNext: daysUntilNextQi,
         totalDays: totalQiDays,
       );

  // 向后兼容的别名
  JieQiResult get prevQi => prev;
  JieQiResult get nextQi => next;
  double get daysSincePrevQi => daysSincePrev;
  double get daysUntilNextQi => daysUntilNext;
  double get totalQiDays => totalDays;
  double get qiProgress => progress;

  @override
  String toString() {
    return '距${prev.name}: ${daysSincePrev.toStringAsFixed(2)}天, '
        '距${next.name}: ${daysUntilNext.toStringAsFixed(2)}天, '
        '气进度: ${(progress * 100).toStringAsFixed(1)}%';
  }
}

// ==================== 距离查询 API ====================

/// 内部通用距离计算引擎。
SolarTermSpan? _getSpan(
  AstroDateTime target,
  JieQiResult? Function(AstroDateTime) prevGetter,
  JieQiResult? Function(AstroDateTime) nextGetter,
) {
  final prev = prevGetter(target);
  final next = nextGetter(target);
  if (prev == null || next == null) return null;
  final targetJD = target.toJ2000();
  return SolarTermSpan(
    prev: prev,
    next: next,
    daysSincePrev: targetJD - prev.jd,
    daysUntilNext: next.jd - targetJD,
    totalDays: next.jd - prev.jd,
  );
}

/// 获取目标日期与前后节气的距离信息。
JieQiDistance? getJieQiDistance(AstroDateTime target) {
  final s = _getSpan(target, getPrevJieQi, getNextJieQi);
  if (s == null) return null;
  return JieQiDistance(
    prev: s.prev,
    next: s.next,
    daysSincePrev: s.daysSincePrev,
    daysUntilNext: s.daysUntilNext,
    totalDays: s.totalDays,
  );
}

/// 获取目标日期与前后"节"的距离信息。
JieDistance? getJieDistance(AstroDateTime target) {
  final s = _getSpan(target, getPrevJie, getNextJie);
  if (s == null) return null;
  return JieDistance(
    prevJie: s.prev,
    nextJie: s.next,
    daysSincePrevJie: s.daysSincePrev,
    daysUntilNextJie: s.daysUntilNext,
    totalJieDays: s.totalDays,
  );
}

/// 获取目标日期与前后"气"的距离信息。
QiDistance? getQiDistance(AstroDateTime target) {
  final s = _getSpan(target, getPrevQi, getNextQi);
  if (s == null) return null;
  return QiDistance(
    prevQi: s.prev,
    nextQi: s.next,
    daysSincePrevQi: s.daysSincePrev,
    daysUntilNextQi: s.daysUntilNext,
    totalQiDays: s.totalDays,
  );
}

// ==================== 综合信息 ====================

/// 目标日期的完整节、气信息。
class JieQiInfo {
  /// 上一个节气。
  final JieQiResult prevJieQi;

  /// 下一个节气。
  final JieQiResult nextJieQi;

  /// 上一个节。
  final JieQiResult prevJie;

  /// 下一个节。
  final JieQiResult nextJie;

  /// 上一个气。
  final JieQiResult prevQi;

  /// 下一个气。
  final JieQiResult nextQi;

  /// 距离上一个节气的天数。
  final double daysSincePrevJieQi;

  /// 距离下一个节气的天数。
  final double daysUntilNextJieQi;

  /// 距离上一个节的天数。
  final double daysSincePrevJie;

  /// 距离下一个节的天数。
  final double daysUntilNextJie;

  /// 距离上一个气的天数。
  final double daysSincePrevQi;

  /// 距离下一个气的天数。
  final double daysUntilNextQi;

  JieQiInfo({
    required this.prevJieQi,
    required this.nextJieQi,
    required this.prevJie,
    required this.nextJie,
    required this.prevQi,
    required this.nextQi,
    required this.daysSincePrevJieQi,
    required this.daysUntilNextJieQi,
    required this.daysSincePrevJie,
    required this.daysUntilNextJie,
    required this.daysSincePrevQi,
    required this.daysUntilNextQi,
  });

  @override
  String toString() {
    return '节气: ${prevJieQi.name} → ${nextJieQi.name}\n'
        '节: ${prevJie.name} → ${nextJie.name}\n'
        '气: ${prevQi.name} → ${nextQi.name}';
  }
}

/// 获取目标日期的完整节、气信息。
JieQiInfo? getJieQiInfo(AstroDateTime target) {
  final prevJieQi = getPrevJieQi(target);
  final nextJieQi = getNextJieQi(target);
  final prevJie = getPrevJie(target);
  final nextJie = getNextJie(target);
  final prevQi = getPrevQi(target);
  final nextQi = getNextQi(target);

  if (prevJieQi == null ||
      nextJieQi == null ||
      prevJie == null ||
      nextJie == null ||
      prevQi == null ||
      nextQi == null) {
    return null;
  }

  final targetJD = target.toJ2000();

  return JieQiInfo(
    prevJieQi: prevJieQi,
    nextJieQi: nextJieQi,
    prevJie: prevJie,
    nextJie: nextJie,
    prevQi: prevQi,
    nextQi: nextQi,
    daysSincePrevJieQi: targetJD - prevJieQi.jd,
    daysUntilNextJieQi: nextJieQi.jd - targetJD,
    daysSincePrevJie: targetJD - prevJie.jd,
    daysUntilNextJie: nextJie.jd - targetJD,
    daysSincePrevQi: targetJD - prevQi.jd,
    daysUntilNextQi: nextQi.jd - targetJD,
  );
}

// ==================== Julian Day 便捷接口 ====================

/// 获取目标日期之前最近的一个节气的 Julian Day。
double? getPrevJieQiJd(AstroDateTime target) => getPrevJieQi(target)?.jd;

/// 获取目标日期之后最近的一个节气的 Julian Day。
double? getNextJieQiJd(AstroDateTime target) => getNextJieQi(target)?.jd;

/// 获取目标日期之前最近的一个"节"的 Julian Day。
double? getPrevJieJd(AstroDateTime target) => getPrevJie(target)?.jd;

/// 获取目标日期之后最近的一个"节"的 Julian Day。
double? getNextJieJd(AstroDateTime target) => getNextJie(target)?.jd;

/// 获取目标日期之前最近的一个"气"的 Julian Day。
double? getPrevQiJd(AstroDateTime target) => getPrevQi(target)?.jd;

/// 获取目标日期之后最近的一个"气"的 Julian Day。
double? getNextQiJd(AstroDateTime target) => getNextQi(target)?.jd;

/// 获取指定阳历年的所有 24 个节气的 Julian Day 数组。
List<double> getYearJieQiJd(int year) {
  return getYearJieQi(year).map((jq) => jq.jd).toList();
}
