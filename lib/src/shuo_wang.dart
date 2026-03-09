import 'dart:math';

import 'package:sxwnl_spa_dart/src/sxwnl/delta_t.dart';
import 'package:sxwnl_spa_dart/src/sxwnl/solar_lunar_pos.dart';

/// ### 高精度定朔
///
/// 根据日月黄经差反推合朔（农历初一）的精确时刻。
///
/// **调用注意：**
/// * **累计弧度 [w]**：这是合朔的档位。0 是 J2000 附近的合朔，2π 是下一个月，以此类推。
/// * **返回值**：北京时间 (J2000 相对天数)。内部已自动扣除 ΔT 并加了 8 小时偏移。
/// * **精度说明**：这是基于底层星历模型的完整计算，精度最高，适合算具体的合朔秒数。
double soAccurate(double w) {
  // msALonT 是月球对应的星历反算函数
  final t = msALonT(w) * 36525.0;
  return t - dtT(t) + 8 / 24;
}

/// ### 智能定朔搜索
///
/// 根据给定的日期 [jd]，自动寻找并计算该月精确的合朔（初一）时刻。
///
/// **核心逻辑：**
/// * **相位对齐 (jd + 8)**：J2000 历元（2000-01-01）距离上一次合朔大约差了 8 天。加上这个偏移量，才能确保 `floor` 算出来的是正确的累计月份序号。
/// * **月数转弧度**：将估算的月份序号乘以 `2 * pi`，得到 `soAccurate` 需要的累计弧度 [w]。
/// * **返回值**：北京时间 (J2000 相对天数)。
double soAccurate2(double jd) {
  // 29.5306 是平均朔望月的长度
  final w = ((jd + 8) / 29.5306).floor() * 2 * pi;
  return soAccurate(w);
}
