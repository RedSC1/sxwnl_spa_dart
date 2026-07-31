/// P03 岁差模型与球面坐标旋转。
///
/// 移植自寿星万年历 eph0.js 的 `prece`、`CDllr_*` 与 `HDllr_*`。
library;

import 'dart:math' as math;

import 'math_utils.dart';

const List<List<double>> _preceP03 = [
  [0, 5038.481507, -1.0790069, -0.00114045, 0.000132851, -9.51e-8],
  [84381.406000, -0.025754, 0.0512623, -0.00772503, -4.67e-7, 3.337e-7],
  [0, 4.199094, 0.1939873, -0.00022466, -9.12e-7, 1.20e-8],
  [0, -46.811015, 0.0510283, 0.00052413, -6.46e-7, -1.72e-8],
  [84381.406000, -46.836769, -0.0001831, 0.00200340, -5.76e-7, -4.34e-8],
  [0, 10.556403, -2.3814292, -0.00121197, 0.000170663, -5.60e-8],
  [0, 46.998973, -0.0334926, -0.00012559, 1.13e-7, -2.2e-9],
  [629546.7936, -867.95758, 0.157992, -0.0005371, -0.00004797, 7.2e-8],
  [0, 5028.796195, 1.1054348, 0.00007964, -0.000023857, 3.83e-8],
  [0, 2004.191903, -0.4294934, -0.04182264, -7.089e-6, -1.274e-7],
  [2.650545, 2306.083227, 0.2988499, 0.01801828, -5.971e-6, -3.173e-7],
  [-2.650545, 2306.077181, 1.0927348, 0.01826837, -0.000028596, -2.904e-7],
];

double preceP03(double t, int row) {
  var value = 0.0;
  var power = 1.0;
  for (final coefficient in _preceP03[row]) {
    value += coefficient * power;
    power *= t;
  }
  return value / rad;
}

/// J2000 赤道坐标转当日赤道坐标。
List<double> cDllrJ2D(double t, List<double> llr) {
  final Z = preceP03(t, 10) + llr[0];
  final z = preceP03(t, 11);
  final theta = preceP03(t, 9);
  final cosW = math.cos(llr[1]);
  final cosH = math.cos(theta);
  final sinW = math.sin(llr[1]);
  final sinH = math.sin(theta);
  final A = cosW * math.sin(Z);
  final B = cosH * cosW * math.cos(Z) - sinH * sinW;
  final C = sinH * cosW * math.cos(Z) + cosH * sinW;
  return [rad2mrad(math.atan2(A, B) + z), math.asin(C), llr[2]];
}

/// 当日赤道坐标转 J2000 赤道坐标。
List<double> cDllrD2J(double t, List<double> llr) {
  final Z = -preceP03(t, 11) + llr[0];
  final z = -preceP03(t, 10);
  final theta = -preceP03(t, 9);
  final cosW = math.cos(llr[1]);
  final cosH = math.cos(theta);
  final sinW = math.sin(llr[1]);
  final sinH = math.sin(theta);
  final A = cosW * math.sin(Z);
  final B = cosH * cosW * math.cos(Z) - sinH * sinW;
  final C = sinH * cosW * math.cos(Z) + cosH * sinW;
  return [rad2mrad(math.atan2(A, B) + z), math.asin(C), llr[2]];
}

/// J2000 黄道坐标转当日黄道坐标。
List<double> hDllrJ2D(double t, List<double> llr) {
  var result = List<double>.from(llr);
  result[0] += preceP03(t, 0);
  result = llrConv(result, preceP03(t, 1));
  result[0] -= preceP03(t, 5);
  return llrConv(result, -preceP03(t, 4));
}

/// 当日黄道坐标转 J2000 黄道坐标。
List<double> hDllrD2J(double t, List<double> llr) {
  var result = llrConv(List<double>.from(llr), preceP03(t, 4));
  result[0] += preceP03(t, 5);
  result = llrConv(result, -preceP03(t, 1));
  result[0] -= preceP03(t, 0);
  return rad2mradList(result);
}

List<double> rad2mradList(List<double> value) {
  value[0] = rad2mrad(value[0]);
  return value;
}
