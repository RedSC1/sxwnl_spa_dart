/// 行星位置与大距计算。
///
/// 移植自寿星万年历 `eph.js` 的 `xingJJ()`、`daJu()`，底层使用已内置的
/// VSOP87 `XL0` 数据；冥王星使用原版 `XL0Pluto` 级数和 P03 岁差转换。
/// 时间均为 J2000.0 起算的 TT/TD 儒略世纪。
library;

import 'dart:math' as math;

import 'math_utils.dart';
import 'nutation.dart';
import 'solar_lunar_pos.dart';
import 'xl0_pluto.dart';

/// 寿星行星编号：地球 0，水星至海王星为 1..7，冥王星为 8。
enum Planet {
  earth,
  mercury,
  venus,
  mars,
  jupiter,
  saturn,
  uranus,
  neptune,
  pluto,
}

/// 水星/金星大距结果。
class DaJuResult {
  const DaJuResult(this.t, this.angle);

  /// J2000.0 起算的 TT/TD 儒略世纪。
  final double t;

  /// 行星与太阳的球面距角，弧度。
  final double angle;

  double get jd => t * 36525;
}

List<double> _llr2xyz(List<double> z) => [
  z[2] * math.cos(z[1]) * math.cos(z[0]),
  z[2] * math.cos(z[1]) * math.sin(z[0]),
  z[2] * math.sin(z[1]),
];

List<double> _xyz2llr(List<double> z) {
  final r = math.sqrt(z[0] * z[0] + z[1] * z[1] + z[2] * z[2]);
  return [rad2mrad(math.atan2(z[1], z[0])), math.asin(z[2] / r), r];
}

double _j1J2(double j1, double w1, double j2, double w2) {
  var dJ = rad2rrad(j1 - j2);
  final dW = w1 - w2;
  if (dJ.abs() < 1 / 1000 && dW.abs() < 1 / 1000) {
    dJ *= math.cos((w1 + w2) / 2);
    return math.sqrt(dJ * dJ + dW * dW);
  }
  return math.acos(
    math.sin(w1) * math.sin(w2) + math.cos(w1) * math.cos(w2) * math.cos(dJ),
  );
}

/// 日心球坐标转地心球坐标。
///
/// 原函数名：`h2g(z, a)`。
List<double> h2g(List<double> z, List<double> a) {
  final body = _llr2xyz(z);
  final earth = _llr2xyz(a);
  return _xyz2llr([body[0] - earth[0], body[1] - earth[1], body[2] - earth[2]]);
}

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

double _preceP03Value(double t, int row) {
  var value = 0.0;
  var power = 1.0;
  for (final coefficient in _preceP03[row]) {
    value += coefficient * power;
    power *= t;
  }
  return value / rad;
}

List<double> _plutoCoord(double t) {
  const c0 = math.pi / 180 / 100000;
  final x = -1 + 2 * (t * 36525 + 1825394.5) / 2185000;
  final scaledT = t / 100000000;
  final result = [0.0, 0.0, 0.0];
  for (var i = 0; i < xl0Pluto.length; i++) {
    final terms = xl0Pluto[i];
    var value = 0.0;
    for (var j = 0; j < terms.length; j += 3) {
      value += terms[j] * math.sin(terms[j + 1] * scaledT + terms[j + 2] * c0);
    }
    if (i % 3 == 1) value *= x;
    if (i % 3 == 2) value *= x * x;
    result[i ~/ 3] += value / 100000000;
  }
  result[0] += 9.922274 + 0.154154 * x;
  result[1] += 10.016090 + 0.064073 * x;
  result[2] += -3.947474 - 0.042746 * x;
  return result;
}

List<double> _plutoDateCoord(double t) {
  var result = _xyz2llr(_plutoCoord(t));
  result[0] += _preceP03Value(t, 0);
  result = llrConv(result, _preceP03Value(t, 1));
  result[0] -= _preceP03Value(t, 5);
  return llrConv(result, -_preceP03Value(t, 4));
}

/// 行星日心黄道坐标 `[黄经, 黄纬, 向径]`。
///
/// 原函数名：`p_coord(xt, t, n1, n2, n3)`；水星至海王星使用 `XL0`，
/// 冥王星使用独立的 `XL0Pluto` 级数。
List<double> pCoord(Planet planet, double t, int n1, int n2, int n3) {
  final xt = planet.index;
  if (planet == Planet.pluto) return _plutoDateCoord(t);
  return [xl0Calc(xt, 0, t, n1), xl0Calc(xt, 1, t, n2), xl0Calc(xt, 2, t, n3)];
}

/// 行星和太阳的球面距角。
///
/// 原函数名：`xingJJ(xt, t, jing)`；对水星至冥王星有效。
double xingJJ(Planet planet, double t, int jing) {
  if (planet == Planet.earth) {
    throw ArgumentError.value(
      planet,
      'planet',
      'Earth has no geocentric elongation',
    );
  }
  var earth = pCoord(Planet.earth, t, 10, 10, 10);
  var body = pCoord(planet, t, 10, 10, 10);
  body = h2g(body, earth);
  if (jing == 1) {
    earth = pCoord(Planet.earth, t, 60, 60, 60);
    body = h2g(pCoord(planet, t, 60, 60, 60), earth);
  }
  if (jing >= 2) {
    earth = pCoord(Planet.earth, t - earth[2] * csAgx, -1, -1, -1);
    body = h2g(pCoord(planet, t - body[2] * csAgx, -1, -1, -1), earth);
  }
  final sunLon = earth[0] + math.pi;
  final sunLat = -earth[1];
  return _j1J2(body[0], body[1], sunLon, sunLat);
}

/// 水星或金星的东/西大距。
///
/// [east] 为 true 求东大距，为 false 求西大距。输入及返回 [DaJuResult.t]
/// 均为 J2000.0 起算的 TT/TD 儒略世纪。
/// 原函数名：`daJu(xt, t, dx)`。
DaJuResult daJu(Planet planet, double t, bool east) {
  late double period;
  late List<double> c;
  switch (planet) {
    case Planet.mercury:
      period = 115.8774777586 / 36525;
      c = [2, .2, .01, 46, 87];
      break;
    case Planet.venus:
      period = 583.9213708245 / 36525;
      c = [4, .2, .01, 382, 521];
      break;
    default:
      throw ArgumentError.value(
        planet,
        'planet',
        'daJu only supports Mercury and Venus',
      );
  }
  final b = c[east ? 3 : 4] / 36525;
  t = b + period * ((t - b) / period + .5).floor();
  var r1 = 0.0;
  var r2 = 0.0;
  var r3 = 0.0;
  for (var i = 0; i < 3; i++) {
    final dt = c[i] / 36525;
    r1 = xingJJ(planet, t - dt, i);
    r2 = xingJJ(planet, t, i);
    r3 = xingJJ(planet, t + dt, i);
    t += (r1 - r3) / (r1 + r3 - 2 * r2) * dt / 2;
  }
  r2 += (r1 - r3) / (r1 + r3 - 2 * r2) * (r3 - r1) / 8;
  return DaJuResult(t, r2);
}

List<double> _xingLiu0(Planet planet, double t, int n, double lightTime) {
  final earth = pCoord(Planet.earth, t - lightTime, n, n, n);
  final body = h2g(pCoord(planet, t - lightTime, n, n, n), earth);
  var e = hcjj(t);
  if (lightTime != 0) {
    final zd = nutation2(t);
    body[0] += zd[0];
    e += zd[1];
  }
  return llrConv(body, e);
}

/// 行星顺留或逆留时刻。
///
/// [direct] 为 true 求顺留，为 false 求逆留。原函数名：`xingLiu(xt,t,sn)`。
double xingLiu(Planet planet, double t, bool direct) {
  if (planet == Planet.earth || planet == Planet.pluto) {
    throw ArgumentError.value(
      planet,
      'planet',
      'Stationary events are supported for Mercury through Neptune only',
    );
  }
  const periods = [116, 584, 780, 399, 378, 370, 367];
  const offsets = [17.4, 28, 52, 82, 86, 88, 89];
  final xt = planet.index;
  final hh = periods[xt - 1] / 36525;
  var v = pi2 / hh;
  if (xt > 2) v = -v;
  for (var i = 0; i < 6; i++) {
    t -= rad2rrad(xl0Calc(xt, 0, t, 8) - xl0Calc(0, 0, t, 8)) / v;
  }
  final tc = offsets[xt - 1] / 36525;
  if (direct) {
    t += xt > 2 ? -tc : tc;
  } else {
    t += xt > 2 ? tc : -tc;
  }
  const steps = [5 / 36525, 1 / 36525, .5 / 36525, 2e-6];
  late List<double> y2;
  for (var i = 0; i < 4; i++) {
    final dt = steps[i];
    final n = i >= 3 ? -1 : 8;
    final g = i >= 3 ? y2[2] * csAgx : 0.0;
    final y1 = _xingLiu0(planet, t - dt, n, g);
    y2 = _xingLiu0(planet, t, n, g);
    final y3 = _xingLiu0(planet, t + dt, n, g);
    t += (y1[0] - y3[0]) / (y1[0] + y3[0] - 2 * y2[0]) * dt / 2;
  }
  return t;
}

List<double> _xingMP(Planet planet, double t, int n, double e, List<double> g) {
  final earth = pCoord(Planet.earth, t - g[1], n, n, n);
  final body = h2g(pCoord(planet, t - g[1], n, n, n), earth);
  final moon = mCoord(t - g[0], n, n, n);
  moon[0] += g[2];
  body[0] += g[2];
  final m = llrConv(moon, e + g[3]);
  final p = llrConv(body, e + g[3]);
  return [
    rad2rrad(m[0] - p[0]),
    m[1] - p[1],
    m[2] / csGS / 86400 / 36525,
    p[2] / csGS / 86400 / 36525 * csAU,
  ];
}

/// 行星合月（视赤经相等）的时刻与赤纬差 `[t, Δdec]`。
///
/// 原函数名：`xingHY(xt,t)`。
List<double> xingHY(Planet planet, double t) {
  if (planet == Planet.earth) {
    throw ArgumentError.value(
      planet,
      'planet',
      'Earth has no lunar conjunction event',
    );
  }
  var g = [0.0, 0.0, 0.0, 0.0];
  List<double> d = [];
  for (var i = 0; i < 3; i++) {
    d = _xingMP(planet, t, 8, .4091, g);
    t -= d[0] / 8192;
  }
  final e = hcjj(t);
  final zd = nutation2(t);
  g = [d[2], d[3], zd[0], zd[1]];
  d = _xingMP(planet, t, 8, e, g);
  final d2 = _xingMP(planet, t + 1e-6, 8, e, g);
  final v = (d2[0] - d[0]) / 1e-6;
  d = _xingMP(planet, t, 30, e, g);
  t -= d[0] / v;
  d = _xingMP(planet, t, -1, e, g);
  t -= d[0] / v;
  return [t, d[1]];
}

List<double> _xingSP(
  Planet planet,
  double t,
  int n,
  double w0,
  double ts,
  double tp,
) {
  final earth = pCoord(Planet.earth, t - tp, n, n, n);
  final body = h2g(pCoord(planet, t - tp, n, n, n), earth);
  final sun = pCoord(Planet.earth, t - ts, n, n, n);
  sun[0] += math.pi;
  sun[1] = -sun[1];
  return [
    rad2rrad(body[0] - sun[0] - w0),
    body[1] - sun[1],
    sun[2] * csAgx,
    body[2] * csAgx,
  ];
}

/// 行星合/冲（内行星为上、下合）时刻与黄纬差 `[t, Δlat]`。
/// [oppositionOrInferior] 为 true 求冲或下合。原函数名：`xingHR(xt,t,f)`。
List<double> xingHR(Planet planet, double t, bool oppositionOrInferior) {
  if (planet == Planet.earth || planet == Planet.pluto) {
    throw ArgumentError.value(
      planet,
      'planet',
      'Conjunction/opposition events are supported for Mercury through Neptune only',
    );
  }
  const periods = [116, 584, 780, 399, 378, 370, 367];
  final xt = planet.index;
  var heliocentricTarget = math.pi;
  var geocentricTarget = 0.0;
  if (oppositionOrInferior) {
    heliocentricTarget = 0;
    if (xt > 2) geocentricTarget = math.pi;
  }
  var v = pi2 / periods[xt - 1] * 36525;
  if (xt > 2) v = -v;
  for (var i = 0; i < 6; i++) {
    t -=
        rad2rrad(
          xl0Calc(xt, 0, t, 8) - xl0Calc(0, 0, t, 8) - heliocentricTarget,
        ) /
        v;
  }
  const dt = 2e-5;
  var a = _xingSP(planet, t, 8, geocentricTarget, 0, 0);
  final b = _xingSP(planet, t + dt, 8, geocentricTarget, 0, 0);
  v = (b[0] - a[0]) / dt;
  a = _xingSP(planet, t, 40, geocentricTarget, a[2], a[3]);
  t -= a[0] / v;
  a = _xingSP(planet, t, -1, geocentricTarget, a[2], a[3]);
  t -= a[0] / v;
  return [t, a[1]];
}
