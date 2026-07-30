// ignore_for_file: non_constant_identifier_names

/// 行星位置与大距计算。
///
/// 移植自寿星万年历 `eph.js` 的 `xingJJ()`、`daJu()`，底层使用已内置的
/// VSOP87 `XL0` 数据；冥王星使用原版 `XL0Pluto` 级数和 P03 岁差转换。
/// 时间均为 J2000.0 起算的 TT/TD 儒略世纪。
library;

import 'dart:math' as math;

import 'delta_t.dart';
import 'math_utils.dart';
import 'nutation.dart';
import 'precession.dart';
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

/// 原版 `xingX()` 的结构化结果。
class XingXResult {
  final int body;
  final List<double>? heliocentricEcliptic;
  final List<double> apparentEcliptic;
  final List<double> apparentEquatorial;
  final List<double> stationEquatorial;
  final List<double> horizontal;
  final double geocentricDistance;
  final double lightDistance;
  final double visualDistance;
  final double meanSiderealTime;
  final double trueSiderealTime;

  const XingXResult({
    required this.body,
    required this.heliocentricEcliptic,
    required this.apparentEcliptic,
    required this.apparentEquatorial,
    required this.stationEquatorial,
    required this.horizontal,
    required this.geocentricDistance,
    required this.lightDistance,
    required this.visualDistance,
    required this.meanSiderealTime,
    required this.trueSiderealTime,
  });

  double get azimuth => horizontal[0];
  double get altitude => horizontal[1];
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
  return hDllrJ2D(t, _xyz2llr(_plutoCoord(t)));
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

/// 计算太阳、月亮或行星的完整站心星历。
///
/// [body] 沿用寿星原版编号：水星至海王星 `1..7`、冥王星 `8`、太阳 `9`、
/// 月亮 `10`。输入 [jd] 为 J2000.0 起算的力学时日数，[longitude]、[latitude]
/// 为弧度。结果同时保留视黄道、视赤道、站赤道和地平坐标。
XingXResult xingXPosition(
  int body,
  double jd,
  double longitude,
  double latitude,
) {
  if (body < 1 || body > 10) {
    throw ArgumentError.value(body, 'body', 'Expected sxwnl body 1..10');
  }
  var t = jd / 36525;
  final zd = nutation2(t);
  final dL = zd[0];
  final dE = zd[1];
  final e = hcjj(t) + dE;
  final gstMean = _pGST2(jd);
  final gst = gstMean + dL * math.cos(e);
  var geocentricDistance = 0.0;
  var lightDistance = 0.0;
  var visualDistance = 0.0;
  List<double>? heliocentric;
  late List<double> apparentEcliptic;

  if (body == 10) {
    var earth = eCoord(t, 15, 15, 15);
    var moon = mCoord(t, 1, 1, -1);
    geocentricDistance = moon[2];
    t -= moon[2] * csAgx / csAU;
    final earthAtReception = eCoord(t, 15, 15, 15);
    moon = mCoord(t, -1, -1, -1);
    visualDistance = moon[2];
    final earthDifference = h2g(earth, earthAtReception);
    earthDifference[2] *= csAU;
    lightDistance = h2g(moon, earthDifference)[2];
    moon[0] = rad2mrad(moon[0] + dL);
    apparentEcliptic = moon;
  } else {
    final earth = eCoord(t, -1, -1, -1);
    var planet = _rawPlanetCoord(body, t);
    heliocentric = List<double>.from(planet);
    planet[0] = rad2mrad(planet[0]);
    geocentricDistance = h2g(planet, earth)[2];
    t -= geocentricDistance * csAgx;
    final earthAtReception = eCoord(t, -1, -1, -1);
    final planetAtReception = _rawPlanetCoord(body, t);
    lightDistance = h2g(planetAtReception, earth)[2];
    visualDistance = h2g(planetAtReception, earthAtReception)[2];
    // sxwnl uses the observer-time Earth for the apparent (visual) vector;
    // the initial-Earth vector above is retained only as the light distance.
    planet = h2g(planetAtReception, earthAtReception);
    planet[0] = rad2mrad(planet[0] + dL);
    apparentEcliptic = planet;
  }

  final apparentEquatorial = llrConv(apparentEcliptic, e);
  var stationEquatorial = List<double>.from(apparentEquatorial);
  final hourAngle = rad2rrad(gst + longitude - stationEquatorial[0]);
  _applyParallax(stationEquatorial, hourAngle, latitude, 0);
  visualDistance = visualDistance == 0 ? stationEquatorial[2] : visualDistance;
  final horizontal = List<double>.from(stationEquatorial);
  horizontal[0] += piHalf - gst - longitude;
  final horizon = llrConv(horizontal, piHalf - latitude);
  horizon[0] = rad2mrad(-piHalf - horizon[0]);
  if (horizon[1] > 0) horizon[1] += _mqc(horizon[1]);

  return XingXResult(
    body: body,
    heliocentricEcliptic: heliocentric,
    apparentEcliptic: apparentEcliptic,
    apparentEquatorial: apparentEquatorial,
    stationEquatorial: stationEquatorial,
    horizontal: horizon,
    geocentricDistance: geocentricDistance,
    lightDistance: lightDistance,
    visualDistance: visualDistance,
    meanSiderealTime: rad2mrad(gstMean),
    trueSiderealTime: rad2mrad(gst),
  );
}

/// 原版 `xingX()` 的文本兼容入口。
String xingX(int body, double jd, double longitude, double latitude) {
  final result = xingXPosition(body, jd, longitude, latitude);
  final rfn = body == 10 ? 2 : 8;
  final out = StringBuffer();
  if (result.heliocentricEcliptic != null) {
    final z = result.heliocentricEcliptic!;
    out
      ..writeln(
        '黄经一 ${_radText(z[0], false)} 黄纬一 ${_radText(z[1], false)} 向径一 ${z[2].toStringAsFixed(rfn)}',
      )
      ..writeln(
        '视黄经 ${_radText(result.apparentEcliptic[0], false)} 视黄纬 ${_radText(result.apparentEcliptic[1], false)} 地心距 ${result.geocentricDistance.toStringAsFixed(rfn)}',
      )
      ..writeln(
        '视赤经 ${_radText(result.apparentEquatorial[0], true)} 视赤纬 ${_radText(result.apparentEquatorial[1], false)} 光行距 ${result.lightDistance.toStringAsFixed(rfn)}',
      );
  } else {
    out
      ..writeln(
        '视黄经 ${_radText(result.apparentEcliptic[0], false)} 视黄纬 ${_radText(result.apparentEcliptic[1], false)} 地心距 ${result.geocentricDistance.toStringAsFixed(rfn)}',
      )
      ..writeln(
        '视赤经 ${_radText(result.apparentEquatorial[0], true)} 视赤纬 ${_radText(result.apparentEquatorial[1], false)} 光行距 ${result.lightDistance.toStringAsFixed(rfn)}',
      );
  }
  out
    ..writeln(
      '站赤经 ${_radText(result.stationEquatorial[0], true)} 站赤纬 ${_radText(result.stationEquatorial[1], false)} 视距离 ${result.visualDistance.toStringAsFixed(rfn)}',
    )
    ..writeln(
      '方位角 ${_radText(result.azimuth, false)} 高度角 ${_radText(result.altitude, false)}',
    )
    ..writeln(
      '恒星时 ${_radText(result.meanSiderealTime, true)}(平) ${_radText(result.trueSiderealTime, true)}(真)',
    );
  return out.toString();
}

List<double> _rawPlanetCoord(int body, double t) {
  if (body == 9) return [0, 0, 0];
  return pCoord(Planet.values[body], t, -1, -1, -1);
}

void _applyParallax(
  List<double> z,
  double hourAngle,
  double latitude,
  double high,
) {
  final distanceScale = z[2] < 500 ? csAU : 1.0;
  z[2] *= distanceScale;
  final u = math.atan(csBa * math.tan(latitude));
  final g = z[0] + hourAngle;
  final r0 = csREar * math.cos(u) + high * math.cos(latitude);
  final z0 = csREar * math.sin(u) * csBa + high * math.sin(latitude);
  final observer = [r0 * math.cos(g), r0 * math.sin(g), z0];
  final body = _llr2xyz(z);
  final corrected = _xyz2llr([
    body[0] - observer[0],
    body[1] - observer[1],
    body[2] - observer[2],
  ]);
  z
    ..[0] = corrected[0]
    ..[1] = corrected[1]
    ..[2] = corrected[2] / distanceScale;
}

double _pGST2(double jd) {
  final dt = dtT(jd);
  return pGst(jd - dt, dt);
}

double _mqc(double h) => .0002967 / math.tan(h + .003138 / (h + .08919));

String _radText(double value, bool rightAscension) {
  var units = value * (rightAscension ? 12 / math.pi : 180 / math.pi);
  final sign = !rightAscension && units < 0 ? '-' : '';
  units = units.abs();
  final first = units.floor();
  final minuteValue = (units - first) * 60;
  final minute = minuteValue.floor();
  final second = (minuteValue - minute) * 60;
  if (rightAscension) {
    return '${first.toString().padLeft(2, '0')}h${minute.toString().padLeft(2, '0')}m${second.toStringAsFixed(3)}s';
  }
  return '$sign${first.toString().padLeft(2, ' ')}°${minute.toString().padLeft(2, '0')}′${second.toStringAsFixed(2)}″';
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
