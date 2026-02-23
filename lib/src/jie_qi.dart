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
  '小寒', '大寒', '立春', '雨水', '惊蛰',
  '春分', '清明', '谷雨', '立夏', '小满', '芒种',
  '夏至', '小暑', '大暑', '立秋', '处暑', '白露',
  '秋分', '寒露', '霜降', '立冬', '小雪', '大雪', '冬至',
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

/// 高精度定气计算（已知太阳视黄经求时间）。
///
/// [w] 目标太阳视黄经（弧度）。
/// 返回 J2000 相对儒略日（北京时间）。
double qiAccurate(double w) {
  final t = sALonT(w) * 36525.0;
  return t - dtT(t) + 8 / 24;
}

/// 定义一个共用的辅助方法来获取覆盖 target 所在的节气列表
List<JieQiResult> _getSurroundingJieQi(int year) {
  final list1 = getYearJieQi(year - 1);
  final list2 = getYearJieQi(year);
  final list3 = getYearJieQi(year + 1);
  final all = [...list1, ...list2, ...list3];
  
  // 去重
  final uniqueAll = <JieQiResult>[];
  for (final jq in all) {
    if (uniqueAll.isEmpty || (jq.jd - uniqueAll.last.jd).abs() > 1e-9) {
      uniqueAll.add(jq);
    }
  }
  return uniqueAll;
}

/// 获取指定阳历年的所有节气。
///
/// [year] 阳历年（如 2025）。
/// 返回从上一个冬至到当前冬至的节气列表（共25个节气，符合传统历法计算“岁”的范围）。
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
    
    results.add(JieQiResult(
      index: index,
      name: jieQiNames[index],
      jd: jd,
      dateTime: AstroDateTime.fromJ2000(jd),
    ));
  }

  return results;
}

/// 获取目标日期之前最近的一个节气。
///
/// [target] 目标日期。
/// 返回上一个节气，如未找到则返回 null。
JieQiResult? getPrevJieQi(AstroDateTime target) {
  final all = _getSurroundingJieQi(target.year);
  final targetJD = target.toJ2000();

  for (var i = all.length - 1; i >= 0; i--) {
    if (all[i].jd <= targetJD) {
      return all[i];
    }
  }
  return null;
}

/// 获取目标日期之后最近的一个节气。
///
/// [target] 目标日期。
/// 返回下一个节气，如未找到则返回 null。
JieQiResult? getNextJieQi(AstroDateTime target) {
  final all = _getSurroundingJieQi(target.year);
  final targetJD = target.toJ2000();

  for (var i = 0; i < all.length; i++) {
    if (all[i].jd > targetJD) {
      return all[i];
    }
  }
  return null;
}

/// 目标日期与前后节气的距离信息。
class JieQiDistance {
  /// 上一个节气。
  final JieQiResult prev;

  /// 下一个节气。
  final JieQiResult next;

  /// 距离上一个节气的天数。
  final double daysSincePrev;

  /// 距离下一个节气的天数。
  final double daysUntilNext;

  /// 两个节气之间的总天数。
  final double totalDays;

  JieQiDistance({
    required this.prev,
    required this.next,
    required this.daysSincePrev,
    required this.daysUntilNext,
    required this.totalDays,
  });

  /// 在两个节气之间的进度（0.0 - 1.0）。
  double get progress => daysSincePrev / totalDays;

  @override
  String toString() {
    return '距${prev.name}: ${daysSincePrev.toStringAsFixed(2)}天, '
        '距${next.name}: ${daysUntilNext.toStringAsFixed(2)}天, '
        '进度: ${(progress * 100).toStringAsFixed(1)}%';
  }
}

/// 获取目标日期与前后节气的距离信息。
///
/// [target] 目标日期。
/// 返回节气距离信息，如未找到则返回 null。
JieQiDistance? getJieQiDistance(AstroDateTime target) {
  final prev = getPrevJieQi(target);
  final next = getNextJieQi(target);

  if (prev == null || next == null) return null;

  final targetJD = target.toJ2000();

  return JieQiDistance(
    prev: prev,
    next: next,
    daysSincePrev: targetJD - prev.jd,
    daysUntilNext: next.jd - targetJD,
    totalDays: next.jd - prev.jd,
  );
}

/// 获取目标日期之前最近的一个"节"。
///
/// [target] 目标日期。
/// 返回上一个节，如未找到则返回 null。
JieQiResult? getPrevJie(AstroDateTime target) {
  final all = _getSurroundingJieQi(target.year);
  final targetJD = target.toJ2000();

  for (var i = all.length - 1; i >= 0; i--) {
    if (all[i].jd <= targetJD && isJie(all[i].index)) {
      return all[i];
    }
  }
  return null;
}

/// 获取目标日期之前最近的一个"气"。
///
/// [target] 目标日期。
/// 返回上一个气，如未找到则返回 null。
JieQiResult? getPrevQi(AstroDateTime target) {
  final all = _getSurroundingJieQi(target.year);
  final targetJD = target.toJ2000();

  for (var i = all.length - 1; i >= 0; i--) {
    if (all[i].jd <= targetJD && isQi(all[i].index)) {
      return all[i];
    }
  }
  return null;
}

/// 获取目标日期之后最近的一个"节"。
///
/// [target] 目标日期。
/// 返回下一个节，如未找到则返回 null。
JieQiResult? getNextJie(AstroDateTime target) {
  final all = _getSurroundingJieQi(target.year);
  final targetJD = target.toJ2000();

  for (var i = 0; i < all.length; i++) {
    if (all[i].jd > targetJD && isJie(all[i].index)) {
      return all[i];
    }
  }
  return null;
}

/// 获取目标日期之后最近的一个"气"。
///
/// [target] 目标日期。
/// 返回下一个气，如未找到则返回 null。
JieQiResult? getNextQi(AstroDateTime target) {
  final all = _getSurroundingJieQi(target.year);
  final targetJD = target.toJ2000();

  for (var i = 0; i < all.length; i++) {
    if (all[i].jd > targetJD && isQi(all[i].index)) {
      return all[i];
    }
  }
  return null;
}

/// 目标日期与前后节的距离信息。
class JieDistance {
  /// 上一个节。
  final JieQiResult prevJie;

  /// 下一个节。
  final JieQiResult nextJie;

  /// 距离上一个节的天数。
  final double daysSincePrevJie;

  /// 距离下一个节的天数。
  final double daysUntilNextJie;

  /// 两个节之间的总天数。
  final double totalJieDays;

  JieDistance({
    required this.prevJie,
    required this.nextJie,
    required this.daysSincePrevJie,
    required this.daysUntilNextJie,
    required this.totalJieDays,
  });

  /// 在两个节之间的进度（0.0 - 1.0）。
  double get jieProgress => daysSincePrevJie / totalJieDays;

  @override
  String toString() {
    return '距${prevJie.name}: ${daysSincePrevJie.toStringAsFixed(2)}天, '
        '距${nextJie.name}: ${daysUntilNextJie.toStringAsFixed(2)}天, '
        '节进度: ${(jieProgress * 100).toStringAsFixed(1)}%';
  }
}

/// 目标日期与前后气的距离信息。
class QiDistance {
  /// 上一个气。
  final JieQiResult prevQi;

  /// 下一个气。
  final JieQiResult nextQi;

  /// 距离上一个气的天数。
  final double daysSincePrevQi;

  /// 距离下一个气的天数。
  final double daysUntilNextQi;

  /// 两个气之间的总天数。
  final double totalQiDays;

  QiDistance({
    required this.prevQi,
    required this.nextQi,
    required this.daysSincePrevQi,
    required this.daysUntilNextQi,
    required this.totalQiDays,
  });

  /// 在两个气之间的进度（0.0 - 1.0）。
  double get qiProgress => daysSincePrevQi / totalQiDays;

  @override
  String toString() {
    return '距${prevQi.name}: ${daysSincePrevQi.toStringAsFixed(2)}天, '
        '距${nextQi.name}: ${daysUntilNextQi.toStringAsFixed(2)}天, '
        '气进度: ${(qiProgress * 100).toStringAsFixed(1)}%';
  }
}

/// 获取目标日期与前后节的距离信息。
///
/// [target] 目标日期。
/// 返回节距离信息，如未找到则返回 null。
JieDistance? getJieDistance(AstroDateTime target) {
  final prevJie = getPrevJie(target);
  final nextJie = getNextJie(target);

  if (prevJie == null || nextJie == null) return null;

  final targetJD = target.toJ2000();

  return JieDistance(
    prevJie: prevJie,
    nextJie: nextJie,
    daysSincePrevJie: targetJD - prevJie.jd,
    daysUntilNextJie: nextJie.jd - targetJD,
    totalJieDays: nextJie.jd - prevJie.jd,
  );
}

/// 获取目标日期与前后气的距离信息。
///
/// [target] 目标日期。
/// 返回气距离信息，如未找到则返回 null。
QiDistance? getQiDistance(AstroDateTime target) {
  final prevQi = getPrevQi(target);
  final nextQi = getNextQi(target);

  if (prevQi == null || nextQi == null) return null;

  final targetJD = target.toJ2000();

  return QiDistance(
    prevQi: prevQi,
    nextQi: nextQi,
    daysSincePrevQi: targetJD - prevQi.jd,
    daysUntilNextQi: nextQi.jd - targetJD,
    totalQiDays: nextQi.jd - prevQi.jd,
  );
}

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
///
/// [target] 目标日期。
/// 返回完整信息，如未找到则返回 null。
JieQiInfo? getJieQiInfo(AstroDateTime target) {
  final prevJieQi = getPrevJieQi(target);
  final nextJieQi = getNextJieQi(target);
  final prevJie = getPrevJie(target);
  final nextJie = getNextJie(target);
  final prevQi = getPrevQi(target);
  final nextQi = getNextQi(target);

  if (prevJieQi == null || nextJieQi == null || prevJie == null || nextJie == null || prevQi == null || nextQi == null) {
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

// ========== Julian Day 版本 ==========

/// 获取目标日期之前最近的一个节气的 Julian Day。
///
/// [target] 目标日期。
/// 返回 J2000 相对儒略日，如未找到则返回 null。
double? getPrevJieQiJd(AstroDateTime target) {
  return getPrevJieQi(target)?.jd;
}

/// 获取目标日期之后最近的一个节气的 Julian Day。
///
/// [target] 目标日期。
/// 返回 J2000 相对儒略日，如未找到则返回 null。
double? getNextJieQiJd(AstroDateTime target) {
  return getNextJieQi(target)?.jd;
}

/// 获取目标日期之前最近的一个"节"的 Julian Day。
///
/// [target] 目标日期。
/// 返回 J2000 相对儒略日，如未找到则返回 null。
double? getPrevJieJd(AstroDateTime target) {
  return getPrevJie(target)?.jd;
}

/// 获取目标日期之后最近的一个"节"的 Julian Day。
///
/// [target] 目标日期。
/// 返回 J2000 相对儒略日，如未找到则返回 null。
double? getNextJieJd(AstroDateTime target) {
  return getNextJie(target)?.jd;
}

/// 获取目标日期之前最近的一个"气"的 Julian Day。
///
/// [target] 目标日期。
/// 返回 J2000 相对儒略日，如未找到则返回 null。
double? getPrevQiJd(AstroDateTime target) {
  return getPrevQi(target)?.jd;
}

/// 获取目标日期之后最近的一个"气"的 Julian Day。
///
/// [target] 目标日期。
/// 返回 J2000 相对儒略日，如未找到则返回 null。
double? getNextQiJd(AstroDateTime target) {
  return getNextQi(target)?.jd;
}

/// 获取指定阳历年的所有 24 个节气的 Julian Day 数组。
///
/// [year] 阳历年（如 2025）。
/// 返回从该年 1 月 1 日开始的 24 个节气的 J2000 相对儒略日数组。
List<double> getYearJieQiJd(int year) {
  return getYearJieQi(year).map((jq) => jq.jd).toList();
}
