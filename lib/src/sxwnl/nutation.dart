// ignore_for_file: non_constant_identifier_names

/// 章动 (Nutation) 和黄赤交角 (Obliquity) 计算。
///
/// 移植自寿星万年历 (sxwnl) eph0.js。
/// 原作者：许剑伟
library;

import 'dart:math' as math;

import 'ephb_nutation_data.dart';
import 'math_utils.dart';

// ==================== 章动计算 ====================

/// 中精度章动计算表。
///
/// 每 5 个元素为一组：[相位, 频率, 频率修正, 黄经章动系数, 交角章动系数]
final List<double> _nutB = [
  2.1824,
  -33.75705,
  36e-6,
  -1720,
  920,
  3.5069,
  1256.66393,
  11e-6,
  -132,
  57,
  1.3375,
  16799.4182,
  -51e-6,
  -23,
  10,
  4.3649,
  -67.5141,
  72e-6,
  21,
  -9,
  0.04,
  -628.302,
  0,
  -14,
  0,
  2.36,
  8328.691,
  0,
  7,
  0,
  3.46,
  1884.966,
  0,
  -5,
  2,
  5.44,
  16833.175,
  0,
  -4,
  2,
  3.69,
  25128.110,
  0,
  -3,
  0,
  3.55,
  628.362,
  0,
  2,
  0,
];

/// 中精度章动计算。
///
/// [t] 为儒略世纪数 (J2000.0 起算)。
/// 返回 [黄经章动, 交角章动]，单位为弧度。
///
/// 原函数名：nutation2(t)
List<double> nutation2(double t) {
  final t2 = t * t;
  double dL = 0, dE = 0;

  for (var i = 0; i < _nutB.length; i += 5) {
    final c = _nutB[i] + _nutB[i + 1] * t + _nutB[i + 2] * t2;
    final a = (i == 0) ? -1.742 * t : 0.0;
    dL += (_nutB[i + 3] + a) * math.sin(c);
    dE += _nutB[i + 4] * math.cos(c);
  }

  return [dL / 100 / rad, dE / 100 / rad];
}

/// 只计算黄经章动（比 nutation2 快，不需要交角章动时使用）。
///
/// [t] 为儒略世纪数。
/// 返回黄经章动，单位为弧度。
///
/// 原函数名：nutationLon2(t)
double nutationLon2(double t) {
  final t2 = t * t;
  double dL = 0;

  for (var i = 0; i < _nutB.length; i += 5) {
    final a = (i == 0) ? -1.742 * t : 0.0;
    dL +=
        (_nutB[i + 3] + a) *
        math.sin(_nutB[i] + _nutB[i + 1] * t + _nutB[i + 2] * t2);
  }

  return dL / 100 / rad;
}

/// IAU 2000B 章动计算，供寿星恒星模块使用。
///
/// [zq] 为周期筛选阈值（天）；传 0 表示保留全部 77 项。
/// 原函数名：`nutation(t, zq)`。
List<double> nutationFull(double t, double zq) {
  final t2 = t * t;
  final t3 = t2 * t;
  final t4 = t3 * t;
  final l =
      485868.249036 +
      1717915923.2178 * t +
      31.8792 * t2 +
      0.051635 * t3 -
      0.00024470 * t4;
  final l1 =
      1287104.79305 +
      129596581.0481 * t -
      0.5532 * t2 +
      0.000136 * t3 -
      0.00001149 * t4;
  final f =
      335779.526232 +
      1739527262.8478 * t -
      12.7512 * t2 -
      0.001037 * t3 +
      0.00000417 * t4;
  final d =
      1072260.70369 +
      1602961601.2090 * t -
      6.3706 * t2 +
      0.006593 * t3 -
      0.00003169 * t4;
  final om =
      450160.398036 -
      6962890.5431 * t +
      7.4722 * t2 +
      0.007702 * t3 -
      0.00005939 * t4;
  var dL = 0.0;
  var dE = 0.0;
  for (var i = 0; i < nuTab.length; i += 11) {
    final c =
        (nuTab[i] * l +
            nuTab[i + 1] * l1 +
            nuTab[i + 2] * f +
            nuTab[i + 3] * d +
            nuTab[i + 4] * om) /
        rad;
    if (zq != 0) {
      final period =
          36526 *
          2 *
          math.pi *
          rad /
          (1717915923.2178 * nuTab[i] +
              129596581.0481 * nuTab[i + 1] +
              1739527262.8478 * nuTab[i + 2] +
              1602961601.2090 * nuTab[i + 3] +
              -6962890.5431 * nuTab[i + 4]);
      if (period.abs() < zq) continue;
    }
    dL +=
        (nuTab[i + 5] + nuTab[i + 6] * t) * math.sin(c) +
        nuTab[i + 7] * math.cos(c);
    dE +=
        (nuTab[i + 8] + nuTab[i + 9] * t) * math.cos(c) +
        nuTab[i + 10] * math.sin(c);
  }
  return [dL / 10000000 / rad, dE / 10000000 / rad];
}

/// 原版函数名的兼容入口。
List<double> nutation(double t, double zq) => nutationFull(t, zq);

/// 章动修正赤道坐标。
///
/// 原函数名：`CDnutation(z, E, dL, dE)`。
List<double> cDnutation(List<double> z, double e, double dL, double dE) {
  final result = List<double>.from(z);
  result[0] +=
      (math.cos(e) + math.sin(e) * math.sin(z[0]) * math.tan(z[1])) * dL -
      math.cos(z[0]) * math.tan(z[1]) * dE;
  result[1] += math.sin(e) * math.cos(z[0]) * dL + math.sin(z[0]) * dE;
  result[0] = rad2mrad(result[0]);
  return result;
}

/// 原始大小写命名的兼容别名。
List<double> CDnutation(List<double> z, double e, double dL, double dE) =>
    cDnutation(z, e, dL, dE);

// ==================== 黄赤交角 ====================

/// 计算黄赤交角 (P03 模型)。
///
/// [t] 为儒略世纪数 (J2000.0 起算)。
/// 返回黄赤交角，单位为弧度。
///
/// 原函数名：hcjj(t)
double hcjj(double t) {
  final t2 = t * t;
  final t3 = t2 * t;
  final t4 = t3 * t;
  final t5 = t4 * t;
  return (84381.4060 -
          46.836769 * t -
          0.0001831 * t2 +
          0.00200340 * t3 -
          5.76e-7 * t4 -
          4.34e-8 * t5) /
      rad;
}
