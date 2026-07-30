// ignore_for_file: non_constant_identifier_names

/// 日月食快速计算。
///
/// 直接移植自寿星万年历（sxwnl）`eph.js` 的 `ysPL` 与 `ecFast`。
/// 原作者：许剑伟。
///
/// 本库中的 [YsPL.lecMax] 与 [ecFast] 都接收自 J2000.0 起算的
/// 力学时（TT/TD）儒略日数；北京时间转换应由调用方的展示层完成。
library;

import 'dart:math' as math;

import 'delta_t.dart';
import 'math_utils.dart';
import 'nutation.dart';
import 'solar_lunar_pos.dart';

class _LecPoint {
  double x = 0;
  double y = 0;
  double mr = 0;
  double er = 0;
  double Er = 0;
  double t = 0;
}

/// 月食快速计算器。
///
/// 公共字段与原版 `ysPL` 保持一致：
/// - [lT]：初亏、食甚、复圆、半影食始、半影食终、食既、生光。
/// - [sf]：食分。
/// - [LX]：`偏` 或 `全`；无月食时为空字符串。
class YsPL {
  /// 接触时刻，单位为 J2000.0 起算的 TT/TD 儒略日数。
  List<double> lT = List<double>.filled(7, 0);

  /// 月食食分。
  double sf = 0;

  /// 月食类型：`偏`、`全`，或空字符串。
  String LX = '';

  /// 已知时刻星体位置、速度，求 `x²+y²=r²` 的交点时刻。
  ///
  /// 移植自 `ysPL.lineT()`。
  double _lineT(_LecPoint g, double v, double u, double r, bool later) {
    final b = g.y * v - g.x * u;
    final a = u * u + v * v;
    final B = u * b;
    final c = b * b - r * r * v * v;
    var d = B * B - a * c;
    if (d < 0) return 0;
    d = math.sqrt(d);
    if (!later) d = -d;
    return g.t + ((-B + d) / a - g.x) / v;
  }

  /// 日月黄经纬差转换为日面中心直角坐标。
  ///
  /// 移植自 `ysPL.lecXY()`。
  void _lecXY(double jd, _LecPoint re) {
    final t = jd / 36525;
    final zs = eCoord(t, -1, -1, -1);
    final zm = mCoord(t, -1, -1, -1);

    zs[0] = rad2mrad(zs[0] + math.pi + gxcSunLon(t));
    zs[1] = -zs[1] + gxcSunLat(t);
    zm[0] = rad2mrad(zm[0] + gxcMoonLon(t));
    zm[1] += gxcMoonLat(t);

    final eMRad = csSMoon / zm[2];
    final eShadow =
        (csREarA / zm[2] * rad - (959.63 - 8.794) / zs[2]) * 51 / 50;
    final eShadow2 =
        (csREarA / zm[2] * rad + (959.63 + 8.794) / zs[2]) * 51 / 50;

    re.x = rad2rrad(zm[0] + math.pi - zs[0]) * math.cos((zm[1] - zs[1]) / 2);
    re.y = zm[1] + zs[1];
    re.mr = eMRad / rad;
    re.er = eShadow / rad;
    re.Er = eShadow2 / rad;
    re.t = jd;
  }

  /// 计算接近 [jd] 的月食食甚。
  ///
  /// [jd] 可为月食附近的 TT/TD J2000 儒略日数，误差数日仍可收敛；
  /// 算法会先反求相邻的望时刻。
  /// 结果写入 [lT]、[sf]、[LX]，以保持原版 `ysPL.lecMax()` 的用法。
  void lecMax(double jd) {
    lT = List<double>.filled(7, 0);
    sf = 0;
    LX = '';

    jd = msALonT2(((jd - 4) / 29.5306).floor() * pi2 + math.pi) * 36525;

    final g = _LecPoint();
    final G = _LecPoint();
    var u = -18461 * math.sin(0.057109 + 0.23089571958 * jd) * 0.23090 / rad;
    var v = (mV(jd / 36525) - eV(jd / 36525)) / 36525;
    _lecXY(jd, G);
    jd -= (G.y * u + G.x * v) / (u * u + v * v);

    var dt = 60 / 86400;
    _lecXY(jd, G);
    _lecXY(jd + dt, g);
    u = (g.y - G.y) / dt;
    v = (g.x - G.x) / dt;
    dt = -(G.y * u + G.x * v) / (u * u + v * v);
    jd += dt;

    final x = G.x + dt * v;
    final y = G.y + dt * u;
    final rmin = math.sqrt(x * x + y * y);

    if (rmin <= G.mr + G.er) {
      lT[1] = jd;
      LX = '偏';
      sf = (G.mr + G.er - rmin) / G.mr / 2;

      lT[0] = _lineT(G, v, u, G.mr + G.er, false);
      _lecXY(lT[0], g);
      lT[0] = _lineT(g, v, u, g.mr + g.er, false);

      lT[2] = _lineT(G, v, u, G.mr + G.er, true);
      _lecXY(lT[2], g);
      lT[2] = _lineT(g, v, u, g.mr + g.er, true);
    }
    if (rmin <= G.mr + G.Er) {
      lT[3] = _lineT(G, v, u, G.mr + G.Er, false);
      _lecXY(lT[3], g);
      lT[3] = _lineT(g, v, u, g.mr + g.Er, false);

      lT[4] = _lineT(G, v, u, G.mr + G.Er, true);
      _lecXY(lT[4], g);
      lT[4] = _lineT(g, v, u, g.mr + g.Er, true);
    }
    if (rmin <= G.er - G.mr) {
      LX = '全';
      lT[5] = _lineT(G, v, u, G.er - G.mr, false);
      _lecXY(lT[5], g);
      lT[5] = _lineT(g, v, u, g.er - g.mr, false);

      lT[6] = _lineT(G, v, u, G.er - G.mr, true);
      _lecXY(lT[6], g);
      lT[6] = _lineT(g, v, u, g.er - g.mr, true);
    }
  }
}

/// 与 sxwnl 原版同名的月食计算器实例。
final ysPL = YsPL();

/// [ecFast] 的返回值。
///
/// 字段名保留原版：`jd`、`jdSuo`、`lx`、`ac`。
class EcFastResult {
  EcFastResult({
    required this.jd,
    required this.jdSuo,
    required this.lx,
    required this.ac,
  });

  double jd;
  double jdSuo;
  String lx;
  int ac;
}

/// 快速筛选接近 [jd] 的日食。
///
/// [jd] 为接近合朔的 TT/TD J2000 儒略日数；返回日食类别（`N`、`P`、
/// `A`、`T`、`H` 等）和校验标志 [EcFastResult.ac]。
///
/// 移植自 `eph.js: ecFast()`。
EcFastResult ecFast(double jd) {
  var t = ((jd + 8) / 29.5306).floor() * pi2;
  final w = t;
  t = (w + 1.08472) / 7771.37714500204;
  var re = EcFastResult(jd: t * 36525, jdSuo: t * 36525, lx: 'N', ac: 1);

  var t2 = t * t;
  final t3 = t2 * t;
  final t4 = t3 * t;
  var L =
      (93.2720993 +
          483202.0175273 * t -
          0.0034029 * t2 -
          t3 / 3526000 +
          t4 / 863310000) /
      180 *
      math.pi;
  if (math.sin(L).abs() > 0.4) return re;

  t -= (-0.0000331 * t * t + 0.10976 * math.cos(0.785 + 8328.6914 * t)) / 7771;
  t2 = t * t;
  L =
      -1.084719 +
      7771.377145013 * t -
      0.0000331 * t2 +
      (22640 * math.cos(0.785 + 8328.6914 * t + 0.000152 * t2) +
              4586 * math.cos(0.19 + 7214.063 * t - 0.000218 * t2) +
              2370 * math.cos(2.54 + 15542.754 * t - 0.000070 * t2) +
              769 * math.cos(3.1 + 16657.383 * t) +
              666 * math.cos(1.5 + 628.302 * t) +
              412 * math.cos(4.8 + 16866.93 * t) +
              212 * math.cos(4.1 - 1114.63 * t) +
              205 * math.cos(0.2 + 6585.76 * t) +
              192 * math.cos(4.9 + 23871.45 * t) +
              165 * math.cos(2.6 + 14914.45 * t) +
              147 * math.cos(5.5 - 7700.39 * t) +
              125 * math.cos(0.5 + 7771.38 * t) +
              109 * math.cos(3.9 + 8956.99 * t) +
              55 * math.cos(5.6 - 1324.18 * t) +
              45 * math.cos(0.9 + 25195.62 * t) +
              40 * math.cos(3.8 - 8538.24 * t) +
              38 * math.cos(4.3 + 22756.82 * t) +
              36 * math.cos(5.5 + 24986.07 * t) -
              6893 * math.cos(4.669257 + 628.3076 * t) -
              72 * math.cos(4.6261 + 1256.62 * t) -
              43 * math.cos(2.67823 + 628.31 * t) * t +
              21) /
          rad;
  t +=
      (w - L) /
      (7771.38 -
          914 * math.sin(0.7848 + 8328.691425 * t + 0.0001523 * t2) -
          179 * math.sin(2.543 + 15542.7543 * t) -
          160 * math.sin(0.1874 + 7214.0629 * t));
  jd = t * 36525;
  re = EcFastResult(jd: jd, jdSuo: jd, lx: 'N', ac: 1);

  t2 = t * t / 10000;
  final t3b = t2 * t / 10000;
  var mB =
      (18461 * math.cos(0.0571 + 8433.46616 * t - .640 * t2 - t3b) +
          1010 * math.cos(2.413 + 16762.1576 * t + .88 * t2 + 25 * t3b) +
          1000 * math.cos(5.440 - 104.7747 * t + 2.16 * t2 + 26 * t3b) +
          624 * math.cos(.915 + 7109.2881 * t + 7 * t3b) +
          199 * math.cos(1.82 + 15647.529 * t - 2.8 * t2 - 19 * t3b) +
          167 * math.cos(4.84 - 1219.403 * t - 1.5 * t2 - 18 * t3b) +
          117 * math.cos(4.17 + 23976.220 * t - 1.3 * t2 + 6 * t3b) +
          62 * math.cos(4.8 + 25090.849 * t + 2 * t2 + 50 * t3b) +
          33 * math.cos(3.3 + 15437.980 * t + 2 * t2 + 32 * t3b) +
          32 * math.cos(1.5 + 8223.917 * t + 4 * t2 + 51 * t3b) +
          30 * math.cos(1.0 + 6480.986 * t + 7 * t3b) +
          16 * math.cos(2.5 - 9548.095 * t - 3 * t2 - 43 * t3b) +
          15 * math.cos(.2 + 32304.912 * t + 31 * t3b) +
          12 * math.cos(4.0 + 7737.590 * t) +
          9 * math.cos(1.9 + 15019.227 * t) +
          8 * math.cos(5.4 + 8399.709 * t) +
          8 * math.cos(4.2 + 23347.918 * t) +
          7 * math.cos(4.9 - 1847.705 * t) +
          7 * math.cos(3.8 - 16133.856 * t) +
          7 * math.cos(2.7 + 14323.351 * t)) /
      rad;
  final mR =
      (385001 +
          20905 * math.cos(5.4971 + 8328.691425 * t + 1.52 * t2 + 25 * t3b) +
          3699 * math.cos(4.900 + 7214.06287 * t - 2.18 * t2 - 19 * t3b) +
          2956 * math.cos(.972 + 15542.75429 * t - .66 * t2 + 6 * t3b) +
          570 * math.cos(1.57 + 16657.3828 * t + 3 * t2 + 50 * t3b) +
          246 * math.cos(5.69 - 1114.6286 * t - 3.7 * t2 - 44 * t3b) +
          205 * math.cos(1.02 + 14914.4523 * t - t2 + 6 * t3b) +
          171 * math.cos(3.33 + 23871.4457 * t + t2 + 31 * t3b) +
          152 * math.cos(4.94 + 6585.761 * t - 2 * t2 - 19 * t3b) +
          130 * math.cos(.74 - 7700.389 * t - 2 * t2 - 25 * t3b) +
          109 * math.cos(5.20 + 7771.377 * t) +
          105 * math.cos(2.31 + 8956.993 * t + t2 + 25 * t3b) +
          80 * math.cos(5.38 - 8538.241 * t + 2.8 * t2 + 26 * t3b) +
          49 * math.cos(6.24 + 628.302 * t) +
          35 * math.cos(2.7 + 22756.817 * t - 3 * t2 - 13 * t3b) +
          31 * math.cos(4.1 + 16171.056 * t - t2 + 6 * t3b) +
          24 * math.cos(1.7 + 7842.365 * t - 2 * t2 - 19 * t3b) +
          23 * math.cos(3.9 + 24986.074 * t + 5 * t2 + 75 * t3b) +
          22 * math.cos(.4 + 14428.126 * t - 4 * t2 - 38 * t3b) +
          17 * math.cos(2.0 + 8399.679 * t)) /
      csREar;

  t = jd / 365250;
  t2 = t * t;
  final t3c = t2 * t;
  var sR =
      10001399 +
      167070 * math.cos(3.098464 + 6283.07585 * t) +
      1396 * math.cos(3.0552 + 12566.1517 * t) +
      10302 * math.cos(1.10749 + 6283.07585 * t) * t +
      172 * math.cos(1.064 + 12566.152 * t) * t +
      436 * math.cos(5.785 + 6283.076 * t) * t2 +
      14 * math.cos(4.27 + 6283.08 * t) * t3c;
  sR *= 1.49597870691 / csREar * 10;

  t = jd / 36525;
  final vL =
      (7771 -
          914 * math.sin(.785 + 8328.6914 * t) -
          179 * math.sin(2.543 + 15542.7543 * t) -
          160 * math.sin(.187 + 7214.0629 * t)) /
      36525;
  final vB =
      (-755 * math.sin(.057 + 8433.4662 * t) -
          82 * math.sin(2.413 + 16762.1576 * t)) /
      36525;
  final vR =
      (-27299 * math.sin(5.497 + 8328.691425 * t) -
          4184 * math.sin(4.900 + 7214.06287 * t) -
          7204 * math.sin(.972 + 15542.75429 * t)) /
      36525;

  final gm = mR * math.sin(mB) * vL / math.sqrt(vB * vB + vL * vL);
  final smR = sR - mR;
  const mk = .2725076;
  const sk = 109.1222;
  final f1 = (sk + mk) / smR;
  final r1 = mk + f1 * mR;
  final f2 = (sk - mk) / smR;
  final r2 = mk - f2 * mR;
  const b = .9972;
  final agm = gm.abs();
  final ar2 = r2.abs();
  final fh2 = mR - mk / f2;
  final h = agm < 1 ? math.sqrt(1 - gm * gm) : 0.0;
  re.lx = fh2 < h ? 'T' : 'A';

  final ls1 = agm - (b + r1);
  if (ls1.abs() < .016) re.ac = 0;
  final ls2 = agm - (b + ar2);
  if (ls2.abs() < .016) re.ac = 0;
  final ls3 = agm - b;
  if (ls3.abs() < .016) re.ac = 0;
  final ls4 = agm - (b - ar2);
  if (ls4.abs() < .016) re.ac = 0;

  if (ls1 > 0) {
    re.lx = 'N';
  } else if (ls2 > 0) {
    re.lx = 'P';
  } else if (ls3 > 0) {
    re.lx += '0';
  } else if (ls4 > 0) {
    re.lx += '1';
  } else {
    if ((fh2 - h).abs() < .019) re.ac = 0;
    if (fh2.abs() < h) {
      final dr = vR * h / vL / mR;
      final h1 = mR - dr - mk / f2;
      final h2 = mR + dr - mk / f2;
      if (h1 > 0) re.lx = 'H3';
      if (h2 > 0) re.lx = 'H2';
      if (h1 > 0 && h2 > 0) re.lx = 'H';
      if (h1.abs() < .019) re.ac = 0;
      if (h2.abs() < .019) re.ac = 0;
    }
  }
  return re;
}

double _mqc(double h) => .0002967 / math.tan(h + .003138 / (h + .08919));

void _parallax(
  List<double> z,
  double hourAngle,
  double latitude,
  double elevationKm,
) {
  final distanceScale = z[2] < 500 ? csAU : 1.0;
  z[2] *= distanceScale;
  final u = math.atan(csBa * math.tan(latitude));
  final g = z[0] + hourAngle;
  final r0 = csREar * math.cos(u) + elevationKm * math.cos(latitude);
  final z0 = csREar * math.sin(u) * csBa + elevationKm * math.sin(latitude);
  final observerX = r0 * math.cos(g);
  final observerY = r0 * math.sin(g);
  final body = _llr2xyz(z);
  final corrected = _xyz2llr(
    _Vec3(body.x - observerX, body.y - observerY, body.z - z0),
  );
  z[0] = corrected[0];
  z[1] = corrected[1];
  z[2] = corrected[2] / distanceScale;
}

List<double> _lineEar(List<double> p, List<double> q, double gst) {
  final a = _llr2xyz(p);
  final b = _llr2xyz(q);
  final dx = b.x - a.x;
  final dy = b.y - a.y;
  final dz = b.z - a.z;
  final e2 = csBa2;
  final aa = dx * dx + dy * dy + dz * dz / e2;
  final bb = a.x * dx + a.y * dy + a.z * dz / e2;
  final cc = a.x * a.x + a.y * a.y + a.z * a.z / e2 - csREar * csREar;
  final d = bb * bb - aa * cc;
  if (d < 0) return [100, 100];
  var root = math.sqrt(d);
  if (bb < 0) root = -root;
  final t = (-bb + root) / aa;
  final x = a.x + dx * t;
  final y = a.y + dy * t;
  final z = a.z + dz * t;
  return [
    rad2rrad(math.atan2(y, x) - gst),
    math.atan(z / csBa2 / math.sqrt(x * x + y * y)),
  ];
}

double _moonIll(double t) {
  final t2 = t * t;
  final t3 = t2 * t;
  final t4 = t3 * t;
  const deg = math.pi / 180;
  final d =
      (297.8502042 +
          445267.1115168 * t -
          .0016300 * t2 +
          t3 / 545868 -
          t4 / 113065000) *
      deg;
  final m =
      (357.5291092 + 35999.0502909 * t - .0001536 * t2 + t3 / 24490000) * deg;
  final moonM =
      (134.9634114 +
          477198.8676313 * t +
          .0089970 * t2 +
          t3 / 69699 -
          t4 / 14712000) *
      deg;
  final phase =
      math.pi -
      d +
      (-6.289 * math.sin(moonM) +
              2.100 * math.sin(m) -
              1.274 * math.sin(2 * d - moonM) -
              .658 * math.sin(2 * d) -
              .214 * math.sin(2 * moonM) -
              .110 * math.sin(d)) *
          deg;
  return (1 + math.cos(phase)) / 2;
}

/// 日月实时位置计算器。
///
/// 直接移植自 sxwnl `eph.js` 的 `msc`。调用 [calc] 后读取同名字段：
/// `sDJ/sDW`、`mDJ/mDW` 是折射前的太阳/月亮方位角和高度角；
/// `sPJ/sPW`、`mPJ/mPW` 是采用原版固定标准折射后的值。
///
/// [calc] 的 [jd] 为 J2000.0 起算的 TT/TD 日数，[longitude]、[latitude]
/// 均为弧度（东经、北纬为正），[elevationKm] 为海拔千米。
class Msc {
  double T = 0;
  double L = 0;
  double fa = 0;
  double dt = 0;
  double jd = 0;
  double dL = 0;
  double dE = 0;
  double E = 0;
  double gst = 0;
  double mHJ = 0;
  double mHW = 0;
  double mR = 0;
  double mCJ = 0;
  double mCW = 0;
  double mShiJ = 0;
  double mCJ2 = 0;
  double mCW2 = 0;
  double mR2 = 0;
  double mDJ = 0;
  double mDW = 0;
  double mPJ = 0;
  double mPW = 0;
  double sHJ = 0;
  double sHW = 0;
  double sR = 0;
  double sCJ = 0;
  double sCW = 0;
  double sShiJ = 0;
  double sCJ2 = 0;
  double sCW2 = 0;
  double sR2 = 0;
  double sDJ = 0;
  double sDW = 0;
  double sPJ = 0;
  double sPW = 0;
  double sc = 0;
  double pty = 0;
  double zty = 0;
  double mRad = 0;
  double sRad = 0;
  double eMRad = 0;
  double eShadow = 0;
  double eShadow2 = 0;
  double mIll = 0;
  double zxJ = 100;
  double zxW = 100;

  /// 计算指定时刻和站点的日月位置。
  void calc(double jd, double longitude, double latitude, double elevationKm) {
    T = jd;
    L = longitude;
    fa = latitude;
    dt = dtT(jd);
    this.jd = jd - dt;
    final t = jd / 36525;
    final zd = nutation2(t);
    dL = zd[0];
    dE = zd[1];
    E = hcjj(t) + dE;
    gst = pGst(this.jd, dt) + dL * math.cos(E);

    var z = mCoord(t, -1, -1, -1);
    z[0] = rad2mrad(z[0] + gxcMoonLon(t) + dL);
    z[1] += gxcMoonLat(t);
    mHJ = z[0];
    mHW = z[1];
    mR = z[2];
    z = llrConv(z, E);
    mCJ = z[0];
    mCW = z[1];
    mShiJ = rad2rrad(gst + L - z[0]);
    _parallax(z, mShiJ, fa, elevationKm);
    mCJ2 = z[0];
    mCW2 = z[1];
    mR2 = z[2];
    z[0] += math.pi / 2 - gst - L;
    z = llrConv(z, math.pi / 2 - fa);
    z[0] = rad2mrad(-math.pi / 2 - z[0]);
    mDJ = z[0];
    mDW = z[1];
    if (z[1] > 0) z[1] += _mqc(z[1]);
    mPJ = z[0];
    mPW = z[1];

    z = eCoord(t, -1, -1, -1);
    z[0] = rad2mrad(z[0] + math.pi + gxcSunLon(t) + dL);
    z[1] = -z[1] + gxcSunLat(t);
    sHJ = z[0];
    sHW = z[1];
    sR = z[2];
    z = llrConv(z, E);
    sCJ = z[0];
    sCW = z[1];
    sShiJ = rad2rrad(gst + L - z[0]);
    _parallax(z, sShiJ, fa, elevationKm);
    sCJ2 = z[0];
    sCW2 = z[1];
    sR2 = z[2];
    z[0] += math.pi / 2 - gst - L;
    z = llrConv(z, math.pi / 2 - fa);
    z[0] = rad2mrad(-math.pi / 2 - z[0]);
    sDJ = z[0];
    sDW = z[1];
    if (z[1] > 0) z[1] += _mqc(z[1]);
    sPJ = z[0];
    sPW = z[1];

    final tt = t / 10;
    final tt2 = tt * tt;
    final tt3 = tt2 * tt;
    final tt4 = tt3 * tt;
    final tt5 = tt4 * tt;
    var lon =
        (1753470142 +
                6283319653318 * tt +
                529674 * tt2 +
                432 * tt3 -
                1124 * tt4 -
                9 * tt5) /
            1000000000 +
        math.pi -
        20.5 / rad;
    lon = rad2mrad(lon - (sCJ - dL * math.cos(E)));
    if (lon > math.pi) lon -= pi2;
    sc = lon / pi2;
    pty = this.jd + L / pi2;
    zty = pty + sc;
    mRad = csSMoon / mR2;
    sRad = 959.63 / sR2;
    eMRad = csSMoon / mR;
    eShadow = (csREarA / mR * rad - (959.63 - 8.794) / sR) * 51 / 50;
    eShadow2 = (csREarA / mR * rad + (959.63 + 8.794) / sR) * 51 / 50;
    mIll = _moonIll(t);
    if (rad2rrad(mCJ - sCJ).abs() < 50 * math.pi / 180) {
      final center = _lineEar([mCJ, mCW, mR], [sCJ, sCW, sR * csAU], gst);
      zxJ = center[0];
      zxW = center[1];
    } else {
      zxJ = zxW = 100;
    }
  }
}

/// 与 sxwnl 原版同名的日月实时位置计算器实例。
final msc = Msc();

class _Vec3 {
  _Vec3(this.x, this.y, this.z);

  double x;
  double y;
  double z;
}

/// Bessel 坐标轴参数：赤经、贝赤交角与真恒星时。
class RsGSFrame {
  RsGSFrame(this.j, this.w, this.gst);

  double j;
  double w;
  double gst;
}

class _GeoPoint {
  _GeoPoint({this.j = 100, this.w = 100, this.r1 = 0, this.r2 = 0});

  double j;
  double w;
  double r1;
  double r2;

  bool get valid => w != 100;
}

class _LinePoint {
  _LinePoint({
    this.x = 0,
    this.y = 0,
    this.x2 = 0,
    this.y2 = 0,
    this.r1 = 0,
    this.r2 = 0,
    this.n = 0,
  });

  double x;
  double y;
  double x2;
  double y2;
  double r1;
  double r2;
  int n;
}

class _ShadowRadii {
  _ShadowRadii(this.r1, this.r2, this.sf);

  double r1;
  double r2;
  double sf;

  double get ar2 => r2.abs();
}

/// `rsGS.feature()` 的日食根数与特征结果。
class RsGSFeature {
  double jdSuo = 0;
  double dT = 0;
  double ds = 0;
  double vx = 0;
  double vy = 0;
  double ax = 0;
  double ay = 0;
  double v = 0;
  double k = 0;
  double jd = 0;
  double xc = 0;
  double yc = 0;
  double zc = 0;
  double D = 0;
  double d = 0;
  late RsGSFrame I;
  double zxJ = 0;
  double zxW = 0;
  double sf = 0;
  String lx = '';
  double dw = 0;
  double tt = 0;
  List<double> gk1 = [0, 0, 0];
  List<double> gk2 = [0, 0, 0];
  List<double> gk3 = [0, 0, 0];
  List<double> gk4 = [0, 0, 0];
  List<double> gk5 = [0, 0, 0];
  List<double> Sdp = [0, 0, 0];
  List<double> p1 = [];
  List<double> p2 = [];
  List<double> p3 = [];
  List<double> p4 = [];
  List<double> q1 = [];
  List<double> q2 = [];
  List<double> q3 = [];
  List<double> q4 = [];
  List<double> L0 = [];
  List<double> L1 = [];
  List<double> L2 = [];
  List<double> L3 = [];
  List<double> L4 = [];
  List<double> L5 = [];
  List<double> L6 = [];
}

_Vec3 _llr2xyz(List<double> z) {
  final cw = math.cos(z[1]);
  return _Vec3(
    z[2] * cw * math.cos(z[0]),
    z[2] * cw * math.sin(z[0]),
    z[2] * math.sin(z[1]),
  );
}

List<double> _xyz2llr(_Vec3 z) {
  final r = math.sqrt(z.x * z.x + z.y * z.y + z.z * z.z);
  return [rad2mrad(math.atan2(z.y, z.x)), math.asin(z.z / r), r];
}

_GeoPoint _lineEar2(_Vec3 p1, _Vec3 p2, double e, double r, RsGSFrame i) {
  final c = math.cos(i.w);
  final s = math.sin(i.w);
  final x1 = p1.x;
  final y1 = c * p1.y - s * p1.z;
  final z1 = s * p1.y + c * p1.z;
  final x2 = p2.x;
  final y2 = c * p2.y - s * p2.z;
  final z2 = s * p2.y + c * p2.z;
  final dx = x2 - x1;
  final dy = y2 - y1;
  final dz = z2 - z1;
  final e2 = e * e;
  final a = dx * dx + dy * dy + dz * dz / e2;
  final b = x1 * dx + y1 * dy + z1 * dz / e2;
  final cc = x1 * x1 + y1 * y1 + z1 * z1 / e2 - r * r;
  final discriminant = b * b - a * cc;
  if (discriminant < 0 || a == 0) return _GeoPoint();
  var d = math.sqrt(discriminant);
  if (b < 0) d = -d;
  final t = (-b + d) / a;
  final x = x1 + dx * t;
  final y = y1 + dy * t;
  final z = z1 + dz * t;
  final length = math.sqrt(dx * dx + dy * dy + dz * dz);
  return _GeoPoint(
    j: rad2rrad(math.atan2(y, x) + i.j - i.gst),
    w: math.atan(z / e2 / math.sqrt(x * x + y * y)),
    r1: length * t.abs(),
    r2: length * (t - 1).abs(),
  );
}

_LinePoint _lineOvl(
  double x1,
  double y1,
  double dx,
  double dy,
  double r,
  double ba,
) {
  final ba2 = ba * ba;
  final a = dx * dx + dy * dy / ba2;
  final b = x1 * dx + y1 * dy / ba2;
  final c = x1 * x1 + y1 * y1 / ba2 - r * r;
  final d = b * b - a * c;
  if (d < 0 || a == 0) return _LinePoint();
  final root = math.sqrt(d);
  final t1 = (-b + root) / a;
  final t2 = (-b - root) / a;
  final length = math.sqrt(dx * dx + dy * dy);
  return _LinePoint(
    x: x1 + dx * t1,
    y: y1 + dy * t1,
    x2: x1 + dx * t2,
    y2: y1 + dy * t2,
    r1: length * t1.abs(),
    r2: length * t2.abs(),
    n: d == 0 ? 1 : 2,
  );
}

/// 全球日食计算器。
///
/// 直接移植自 sxwnl `eph.js` 的 `rsGS`。所有时刻均为 J2000.0 起算的
/// TT/TD 儒略日数；经度向东为正，纬度向北为正，单位均为弧度。
class RsGS {
  List<double> Zs = [];
  double Zdt = .04;
  double Zjd = 0;
  double dT = 0;
  double tanf1 = .0046;
  double tanf2 = .0045;
  double srad = .0046;
  double bba = 1;
  double bhc = 0;
  double dyj = 23500;

  /// 创建 Bessel 根数插值表。
  ///
  /// [n] 与原版相同：2 为低精度、3 为中精度、7 为全精度。
  void init(double jd, int n) {
    if (_suoN(jd) == _suoN(Zjd) && Zs.length == n * 9) return;
    Zs = [];
    Zjd = jd = msALonT2(_suoN(jd) * pi2) * 36525;
    dT = dtT(jd);
    final zd = nutation2(jd / 36525);
    final e = hcjj(jd / 36525) + zd[1];

    for (var i = 0; i < n; i++) {
      final t = (Zjd + (i - n / 2 + .5) * Zdt) / 36525;
      late List<double> s;
      late List<double> m;
      if (n == 7) {
        s = eCoord(t, -1, -1, -1);
        m = mCoord(t, -1, -1, -1);
      } else if (n == 3) {
        s = eCoord(t, 65, 65, 65);
        m = mCoord(t, -1, 150, 150);
      } else if (n == 2) {
        s = eCoord(t, 20, 20, 20);
        m = mCoord(t, 30, 30, 30);
      } else {
        throw ArgumentError.value(n, 'n', 'must be 2, 3, or 7');
      }
      s[0] += zd[0] + gxcSunLon(t) + math.pi;
      s[1] = -s[1] + gxcSunLat(t);
      m[0] += zd[0] + gxcMoonLon(t);
      m[1] += gxcMoonLat(t);
      s = llrConv(s, e);
      m = llrConv(m, e);
      s[2] *= csAU;
      if (i > 0 && s[0] < Zs[0]) s[0] += pi2;
      if (i > 0 && m[0] < Zs[3]) m[0] += pi2;

      final sv = _llr2xyz(s);
      final mv = _llr2xyz(m);
      final b = _xyz2llr(_Vec3(sv.x - mv.x, sv.y - mv.y, sv.z - mv.z));
      b[0] = math.pi / 2 + b[0];
      b[1] = math.pi / 2 - b[1];
      if (i > 0 && b[0] < Zs[6]) b[0] += pi2;
      var gst = pGst(t * 36525 - dT, dT) + zd[0] * math.cos(e);
      if (i > 0 && gst < Zs[8]) {
        gst += pi2;
      }
      Zs.addAll([s[0], s[1], s[2], m[0], m[1], m[2], b[0], b[1], gst]);
    }
    final p = Zs.length - 9;
    dyj = (Zs[2] + Zs[p + 2] - Zs[5] - Zs[p + 5]) / 2 / csREar;
    tanf1 = (.2725076 + 109.1222) / dyj;
    tanf2 = (109.1222 - .2722810) / dyj;
    srad = 109.1222 / ((Zs[2] + Zs[p + 2]) / 2 / csREar);
    bba = math.sin((Zs[1] + Zs[p + 1]) / 2);
    bba = csBa * (1 + (1 - csBa2) * bba * bba / 2);
    bhc = -math.atan(math.tan(e) * math.sin((Zs[6] + Zs[p + 6]) / 2));
  }

  List<double> _chazhi(double jd, int xt) {
    var p = xt * 3;
    const m = 3;
    final n = Zs.length ~/ 9;
    const w = 9;
    var t = (jd - Zjd) / Zdt + n / 2 - .5;
    if (n == 2)
      return List<double>.generate(
        m,
        (i) => Zs[p + i] + (Zs[p + i + w] - Zs[p + i]) * t,
      );
    var c = (t + .5).floor();
    if (c <= 0) c = 1;
    if (c > n - 2) c = n - 2;
    t -= c;
    p += c * w;
    return List<double>.generate(m, (i) {
      final q = p + i;
      return Zs[q] +
          (Zs[q + w] - Zs[q - w] + (Zs[q + w] + Zs[q - w] - Zs[q] * 2) * t) *
              t /
              2;
    });
  }

  /// 太阳赤道坐标插值结果。
  List<double> sun(double jd) => _chazhi(jd, 0);

  /// 月亮赤道坐标插值结果。
  List<double> moon(double jd) => _chazhi(jd, 1);

  /// Bessel 坐标轴参数 `[赤经, 贝赤交角, 真恒星时]`。
  List<double> bse(double jd) => _chazhi(jd, 2);

  RsGSFrame _frame(double jd) {
    final i = bse(jd);
    return RsGSFrame(i[0], i[1], i[2]);
  }

  _GeoPoint _bseXY2db(double x, double y, RsGSFrame i) =>
      _lineEar2(_Vec3(x, y, 2), _Vec3(x, y, 0), csBa, 1, i);

  List<double> _bse2db(_Vec3 z, RsGSFrame i, {bool ellipsoid = true}) {
    var r = _xyz2llr(z);
    r = llrConv(r, i.w);
    r[0] = rad2rrad(r[0] + i.j - i.gst);
    if (ellipsoid) r[1] = math.atan(math.tan(r[1]) / csBa2);
    return r;
  }

  List<double> _bseM(double jd) {
    final m = moon(jd);
    final i = bse(jd);
    final r = llrConv([m[0] - i[0], m[1], m[2]], -i[1]);
    final v = _llr2xyz(r);
    return [v.x / csREar, v.y / csREar, v.z / csREar];
  }

  _ShadowRadii _rSM(double mR) => _ShadowRadii(
    .2725076 + tanf1 * mR,
    .2722810 - tanf2 * mR,
    .2722810 / mR / 109.1222 * (dyj + mR),
  );

  List<double> _vxy(double x, double y, double s, double vx, double vy) {
    var h = 1 - x * x - y * y;
    h = h < 0 ? 0 : math.sqrt(h);
    final sx = pi2 * (math.sin(s) * h - math.cos(s) * y);
    final sy = pi2 * x * math.cos(s);
    final rx = vx - sx;
    final ry = vy - sy;
    return [rx, ry, math.sqrt(rx * rx + ry * ry)];
  }

  List<double> _qrd(double jd, double dx, double dy, int fs) {
    final ba2 = bba * bba;
    final m = _bseM(jd);
    final shadow = _rSM(m[2]);
    final r = fs == 1 ? shadow.r1 : 0.0;
    var x = m[0];
    var y = m[1];
    final d = 1 - (1 / ba2 - 1) * y * y / (x * x + y * y) / 2 + r;
    final t = (d * d - x * x - y * y) / (dx * x + dy * y) / 2;
    x += t * dx;
    y += t * dy;
    jd += t;
    final c = (1 - ba2) * r * x * y / (d * d * d);
    x += c * y;
    y -= c * x;
    final point = _bse2db(_Vec3(x / d, y / d, 0), _frame(jd));
    return [point[0], point[1], jd];
  }

  List<double> _cd2dp(List<double> z, double lon, double lat, double gst) {
    var a = [z[0] + math.pi / 2 - gst - lon, z[1], z[2]];
    a = llrConv(a, math.pi / 2 - lat);
    a[0] = rad2mrad(-math.pi / 2 - a[0]);
    return a;
  }

  /// 计算该朔附近全球日食的基本特征。
  ///
  /// 调用前应先使用 [init] 创建对应精度的根数表。参数 [jd] 为兼容原版
  /// 保留，但特征计算以插值表对应的低精度朔 [Zjd] 为中心。
  RsGSFeature feature(double jd) {
    jd = Zjd;
    const tg = .04;
    final re = RsGSFeature();
    final a = _bseM(jd - tg);
    final b = _bseM(jd);
    final c = _bseM(jd + tg);
    final vx = (c[0] - a[0]) / tg / 2;
    final vy = (c[1] - a[1]) / tg / 2;
    final vz = (c[2] - a[2]) / tg / 2;
    final ax = (c[0] + a[0] - 2 * b[0]) / (tg * tg);
    final ay = (c[1] + a[1] - 2 * b[1]) / (tg * tg);
    final v = math.sqrt(vx * vx + vy * vy);
    final t0 = -(b[0] * vx + b[1] * vy) / (v * v);
    re
      ..jdSuo = jd
      ..dT = dT
      ..ds = bhc
      ..vx = vx
      ..vy = vy
      ..ax = ax
      ..ay = ay
      ..v = v
      ..k = vy / vx
      ..jd = jd + t0
      ..xc = b[0] + vx * t0
      ..yc = b[1] + vy * t0
      ..zc = b[2] + vz * t0 - 1.37 * t0 * t0
      ..D = (vx * b[1] - vy * b[0]) / v;
    re.d = re.D.abs();
    re.I = _frame(re.jd);

    final f = _lineEar2(
      _Vec3(re.xc, re.yc, 2),
      _Vec3(re.xc, re.yc, 0),
      csBa,
      1,
      re.I,
    );
    final bc = _rSM(re.zc);
    var bp = bc;
    if (f.valid) bp = _rSM(re.zc - f.r2);
    var b2 = bc;
    var b3 = bc;
    var t2 = 0.0;
    var t3 = 0.0;
    if (re.d < 1) {
      final dt = math.sqrt(1 - re.d * re.d) / v;
      t2 = t0 - dt;
      t3 = t0 + dt;
      b2 = _rSM(t2 * vz + b[2] - 1.37 * t2 * t2);
      b3 = _rSM(t3 * vz + b[2] - 1.37 * t3 * t3);
    }
    final penumbraRadius = 1 + bc.r1;
    final penumbraDt = re.d < penumbraRadius
        ? math.sqrt(penumbraRadius * penumbraRadius - re.d * re.d) / v
        : 0.0;
    final t4 = t0 - penumbraDt;
    final t5 = t0 + penumbraDt;
    final t6 = -b[0] / vx;
    if (re.d < 1) {
      re.gk1 = _qrd(t2 + jd, vx, vy, 0);
      re.gk2 = _qrd(t3 + jd, vx, vy, 0);
    }
    re.gk3 = _qrd(t4 + jd, vx, vy, 1);
    re.gk4 = _qrd(t5 + jd, vx, vy, 1);
    final gk5 = _bseXY2db(t6 * vx + b[0], t6 * vy + b[1], _frame(t6 + jd));
    re.gk5 = [gk5.j, gk5.w, t6 + jd];

    if (!f.valid) {
      final p = _bse2db(_Vec3(re.xc, re.yc, 0), re.I, ellipsoid: false);
      re
        ..zxJ = p[0]
        ..zxW = p[1]
        ..sf = (bc.r1 - (re.d - .9972)) / (bc.r1 - bc.r2);
      if (re.d > .9972 + bc.r1) {
        re.lx = 'N';
      } else if (re.d > .9972 + bc.ar2) {
        re.lx = 'P';
      } else {
        re.lx = bp.sf < 1 ? 'A0' : 'T0';
      }
    } else {
      re
        ..zxJ = f.j
        ..zxW = f.w
        ..sf = bp.sf;
      if (re.d > .9966 - bp.ar2) {
        re.lx = bp.sf < 1 ? 'A1' : 'T1';
      } else if (bp.sf >= 1) {
        re.lx = 'H';
        if (b2.sf > 1) re.lx = 'H2';
        if (b3.sf > 1) re.lx = 'H3';
        if (b2.sf > 1 && b3.sf > 1) re.lx = 'T';
      } else {
        re.lx = 'A';
      }
    }
    re.Sdp = _cd2dp(sun(re.jd), re.zxJ, re.zxW, re.I.gst);
    if (f.valid) {
      re.dw = (2 * bp.r2 * csREar).abs() / math.sin(re.Sdp[1]);
      final vv = _vxy(re.xc, re.yc, re.I.w, re.vx, re.vy);
      re.tt = 2 * bp.r2.abs() / vv[2];
    }
    return re;
  }

  _LinePoint _cirOvl(double r, double ba, double r2, double x0, double y0) {
    final d = math.sqrt(x0 * x0 + y0 * y0);
    if (d == 0) return _LinePoint();
    final sinB = y0 / d;
    final cosB = x0 / d;
    var cosA = (r * r + d * d - r2 * r2) / (2 * d * r);
    if (cosA.abs() > 1) return _LinePoint();
    var sinA = math.sqrt(1 - cosA * cosA);
    final ba2 = ba * ba;
    var ax = 0.0;
    var ay = 0.0;
    var bx = 0.0;
    var by = 0.0;
    for (final k in [-1.0, 1.0]) {
      var s = cosA * sinB + sinA * cosB * k;
      final g = r - s * s * (1 / ba2 - 1) / 2;
      cosA = (g * g + d * d - r2 * r2) / (2 * d * g);
      if (cosA.abs() > 1) return _LinePoint();
      sinA = math.sqrt(1 - cosA * cosA);
      final c = cosA * cosB - sinA * sinB * k;
      s = cosA * sinB + sinA * cosB * k;
      if (k == 1) {
        ax = g * c;
        ay = g * s;
      } else {
        bx = g * c;
        by = g * s;
      }
    }
    return _LinePoint(x: ax, y: ay, x2: bx, y2: by, n: 2);
  }

  void _push(List<double> point, List<double> target) {
    target.add(point[0]);
    target.add(point[1]);
  }

  void _elmCpy(List<double> a, int n, List<double> b, int m) {
    if (b.isEmpty) return;
    if (n == -2) n = a.length;
    if (m == -2) m = b.length;
    if (n == -1) n = a.length - 2;
    if (m == -1) m = b.length - 2;
    if (n == a.length) {
      a.add(b[m]);
    } else {
      a[n] = b[m];
    }
    if (n + 1 == a.length) {
      a.add(b[m + 1]);
    } else {
      a[n + 1] = b[m + 1];
    }
  }

  List<double> _nanbei(
    List<double> m,
    double vx0,
    double vy0,
    int h,
    double r,
    RsGSFrame i,
  ) {
    var x = m[0] - vy0 / vx0 * r * h;
    var y = m[1] + h * r;
    var sinA = 0.0;
    var cosA = 1.0;
    var clipped = 0;
    for (var k = 0; k < 3; k++) {
      var z = 1 - x * x - y * y;
      if (z < 0) {
        if (clipped != 0) break;
        z = 0;
        clipped++;
      } else {
        z = math.sqrt(z);
      }
      x -= (x - m[0]) * z / m[2];
      y -= (y - m[1]) * z / m[2];
      final vx = vx0 - pi2 * (math.sin(i.w) * z - math.cos(i.w) * y);
      final vy = vy0 - pi2 * math.cos(i.w) * x;
      final v = math.sqrt(vx * vx + vy * vy);
      sinA = h * vy / v;
      cosA = h * vx / v;
      x = m[0] - r * sinA;
      y = m[1] + r * cosA;
    }
    final point = _lineEar2(
      _Vec3(m[0] - .2725076 * sinA, m[1] + .2725076 * cosA, m[2]),
      _Vec3(x, y, 0),
      csBa,
      1,
      i,
    );
    return [point.j, point.w, x, y];
  }

  void _mQie(
    List<double> m,
    double vx,
    double vy,
    int h,
    double r,
    RsGSFrame i,
    List<double> target,
    Map<List<double>, int> state,
  ) {
    final p = _nanbei(m, vx, vy, h, r, i);
    final f = p[1] == 100 ? 0 : 1;
    final f2 = state[target] ?? 0;
    if (f2 != f) {
      final g = _lineOvl(p[2], p[3], vx, vy, 1, bba);
      if (g.n != 0) {
        final entering = f != 0;
        final dj = entering ? g.r2 : g.r1;
        final point = entering ? _Vec3(g.x2, g.y2, 0) : _Vec3(g.x, g.y, 0);
        final i2 = RsGSFrame(
          i.j,
          i.w,
          i.gst - dj / math.sqrt(vx * vx + vy * vy) * 6.28,
        );
        _push(_bse2db(point, i2), target);
      }
    }
    state[target] = f;
    if (f != 0) _push(p, target);
  }

  bool _mDian(
    List<double> m,
    double vx,
    double vy,
    bool ab,
    double r,
    RsGSFrame i,
    List<double> target,
  ) {
    var x = m[0];
    var y = m[1];
    var p = _LinePoint();
    var radius = 0.0;
    for (var k = 0; k < 2; k++) {
      final v = _vxy(x, y, i.w, vx, vy);
      p = _lineOvl(m[0], m[1], v[1], -v[0], 1, bba);
      if (p.n == 0) break;
      if (ab) {
        x = p.x;
        y = p.y;
        radius = p.r1;
      } else {
        x = p.x2;
        y = p.y2;
        radius = p.r2;
      }
    }
    if (p.n != 0 && radius <= r) {
      _push(_bse2db(_Vec3(x, y, 0), i), target);
      return true;
    }
    return false;
  }

  /// 生成全球食带曲线。
  ///
  /// 结果字段与 sxwnl `rsGS.jieX()` 一致：`L0` 为中心线，`L1/L2`
  /// 为半影北/南界，`L3/L4` 为本影北/南界，`L5/L6` 为 0.5 食分界；
  /// 每条线为扁平的 `[经度, 纬度, ...]` 弧度数组。
  RsGSFeature jieX(double jd) {
    final re = feature(jd);
    re
      ..p1 = []
      ..p2 = []
      ..p3 = []
      ..p4 = []
      ..q1 = []
      ..q2 = []
      ..q3 = []
      ..q4 = []
      ..L0 = []
      ..L1 = []
      ..L2 = []
      ..L3 = []
      ..L4 = []
      ..L5 = []
      ..L6 = [];
    var t = 1.7 * 1.7 - re.d * re.d;
    if (t < 0) t = 0;
    final span = math.sqrt(t) / re.v + .01;
    t = re.jd - span;
    const n = 400;
    final dt = 2 * span / n;
    var n1 = 0;
    var n4 = 0;
    var ua = re.q1;
    var ub = re.q2;
    _push([0, 0], re.q2);
    _push([0, 0], re.q3);
    _push([0, 0], re.q4);
    final boundaryState = <List<double>, int>{};

    for (var k = 0; k <= n; k++, t += dt) {
      final vx = re.vx + re.ax * (t - re.jdSuo);
      final vy = re.vy + re.ay * (t - re.jdSuo);
      final m = _bseM(t);
      final b = _rSM(m[2]);
      final i = _frame(t);
      final p = _cirOvl(1, bba, b.r1, m[0], m[1]);
      if (n1.isOdd) {
        if (p.n == 0) n1++;
      } else if (p.n != 0) {
        n1++;
      }
      if (p.n != 0) {
        _push(_bse2db(_Vec3(p.x, p.y, 0), i), n1 == 1 ? re.p1 : re.p3);
        _push(_bse2db(_Vec3(p.x2, p.y2, 0), i), n1 == 1 ? re.p2 : re.p4);
      }

      if (!_mDian(m, vx, vy, false, b.r1, i, ua) && ua.isNotEmpty) ua = re.q3;
      if (!_mDian(m, vx, vy, true, b.r1, i, ub) && ub.length > 2) ub = re.q4;
      if (t > re.jd) {
        if (ua.isEmpty) ua = re.q3;
        if (ub.length == 2) ub = re.q4;
      }

      final center = _bseXY2db(m[0], m[1], i);
      if ((center.valid && n4 == 0) || (!center.valid && n4 == 1)) {
        final edge = _lineOvl(m[0], m[1], vx, vy, 1, bba);
        final entering = n4 == 0;
        final dj = entering ? edge.r2 : edge.r1;
        final point = entering
            ? _Vec3(edge.x2, edge.y2, 0)
            : _Vec3(edge.x, edge.y, 0);
        final i2 = RsGSFrame(
          i.j,
          i.w,
          i.gst - dj / math.sqrt(vx * vx + vy * vy) * 6.28,
        );
        _push(_bse2db(point, i2), re.L0);
        n4++;
      }
      if (center.valid) _push([center.j, center.w], re.L0);

      _mQie(m, vx, vy, 1, b.r1, i, re.L1, boundaryState);
      _mQie(m, vx, vy, -1, b.r1, i, re.L2, boundaryState);
      _mQie(m, vx, vy, 1, b.r2, i, re.L3, boundaryState);
      _mQie(m, vx, vy, -1, b.r2, i, re.L4, boundaryState);
      _mQie(m, vx, vy, 1, (b.r1 + b.r2) / 2, i, re.L5, boundaryState);
      _mQie(m, vx, vy, -1, (b.r1 + b.r2) / 2, i, re.L6, boundaryState);
    }
    _elmCpy(re.q3, 0, re.q1, -1);
    _elmCpy(re.q4, 0, re.q2, -1);
    _elmCpy(re.q1, -2, re.L1, 0);
    _elmCpy(re.q2, -2, re.L2, 0);
    _elmCpy(re.q3, 0, re.L1, -1);
    _elmCpy(re.q4, 0, re.L2, -1);
    _elmCpy(re.q2, 0, re.q1, 0);
    _elmCpy(re.q3, -2, re.q4, -1);
    return re;
  }

  static int _suoN(double jd) => ((jd + 8) / 29.5306).floor();
}

/// 与 sxwnl 原版同名的全球日食计算器实例。
final rsGS = RsGS();

/// `rsPL.secXY()` 的中间日月坐标。
class RsPLPoint {
  double mCJ = 0;
  double mCW = 0;
  double mR = 0;
  double mCJ2 = 0;
  double mCW2 = 0;
  double mR2 = 0;
  double sCJ = 0;
  double sCW = 0;
  double sR = 0;
  double sCJ2 = 0;
  double sCW2 = 0;
  double sR2 = 0;
  double mr = 0;
  double sr = 0;
  double x = 0;
  double y = 0;
  double t = 0;
}

/// 寿星原版 `rsPL` 的地方日食计算器。
///
/// 经纬度单位为弧度（东经、北纬为正），海拔单位为 km；输入/输出时刻均为
/// J2000.0 起算的 TT/TD 儒略日数。`sT` 的顺序为
/// `[初亏, 食甚, 复圆, 食既, 生光]`，地平线以下的接触时刻会保留为 0。
class RsPL {
  int nasa_r = 0;
  List<double> sT = List<double>.filled(5, 0);
  String LX = '';
  double sf = 0;
  double sf2 = 0;
  double sf3 = 0;
  String sflx = ' ';
  double b1 = 1;
  double dur = 0;
  double P1 = 0;
  double V1 = 0;
  double P2 = 0;
  double V2 = 0;
  double sun_s = 0;
  double sun_j = 0;

  void secXY(double jd, double L, double fa, double high, RsPLPoint re) {
    final deltaT = dtT(jd);
    final zd = nutation2(jd / 36525);
    final gst =
        pGst(jd - deltaT, deltaT) + zd[0] * math.cos(hcjj(jd / 36525) + zd[1]);

    var z = List<double>.from(rsGS.moon(jd));
    re
      ..mCJ = z[0]
      ..mCW = z[1]
      ..mR = z[2];
    _parallax(z, rad2rrad(gst + L - z[0]), fa, high);
    re
      ..mCJ2 = z[0]
      ..mCW2 = z[1]
      ..mR2 = z[2];

    z = List<double>.from(rsGS.sun(jd));
    re
      ..sCJ = z[0]
      ..sCW = z[1]
      ..sR = z[2];
    _parallax(z, rad2rrad(gst + L - z[0]), fa, high);
    re
      ..sCJ2 = z[0]
      ..sCW2 = z[1]
      ..sR2 = z[2]
      ..mr = csSMoon / re.mR2 / rad
      ..sr = 959.63 / re.sR2 / rad * csAU;
    if (nasa_r != 0) re.mr *= 0.99925;
    re
      ..x = rad2rrad(re.mCJ2 - re.sCJ2) * math.cos((re.mCW2 + re.sCW2) / 2)
      ..y = re.mCW2 - re.sCW2
      ..t = jd;
  }

  double lineT(RsPLPoint g, double v, double u, double r, bool end) {
    final b = g.y * v - g.x * u;
    final a = u * u + v * v;
    final bb = u * b;
    final c = b * b - r * r * v * v;
    final d0 = bb * bb - a * c;
    if (d0 < 0) return 0;
    var d = math.sqrt(d0);
    if (!end) d = -d;
    return g.t + ((-bb + d) / a - g.x) / v;
  }

  /// 计算一个地点的日食接触时刻和食甚参数。
  void secMax(double jd, double L, double fa, double high) {
    sT = List<double>.filled(5, 0);
    LX = '';
    sf = sf2 = sf3 = 0;
    sflx = ' ';
    b1 = 1;
    dur = P1 = V1 = P2 = V2 = sun_s = sun_j = 0;

    rsGS.init(jd, 7);
    jd = rsGS.Zjd;
    final g = RsPLPoint();
    final g2 = RsPLPoint();
    secXY(jd, L, fa, high, g);
    jd -= g.x / .2128;

    var u = 0.0;
    var v = 0.0;
    const dt = 60 / 86400;
    for (var i = 0; i < 2; i++) {
      secXY(jd, L, fa, high, g);
      secXY(jd + dt, L, fa, high, g2);
      u = (g2.y - g.y) / dt;
      v = (g2.x - g.x) / dt;
      jd += -(g.y * u + g.x * v) / (u * u + v * v);
    }

    var maxSf = 0.0;
    var maxJd = jd;
    for (var i = -30; i < 30; i += 6) {
      final tt = jd + i / 86400;
      secXY(tt, L, fa, high, g2);
      final value =
          (g2.mr + g2.sr - math.sqrt(g2.x * g2.x + g2.y * g2.y)) / g2.sr / 2;
      if (value > maxSf) {
        maxSf = value;
        maxJd = tt;
      }
    }
    jd = maxJd;
    for (var i = -5; i < 5; i++) {
      final tt = jd + i / 86400;
      secXY(tt, L, fa, high, g2);
      final value =
          (g2.mr + g2.sr - math.sqrt(g2.x * g2.x + g2.y * g2.y)) / g2.sr / 2;
      if (value > maxSf) {
        maxSf = value;
        maxJd = tt;
      }
    }
    jd = maxJd;
    secXY(jd, L, fa, high, g);
    final rmin = math.sqrt(g.x * g.x + g.y * g.y);

    final deltaT = dtT(jd);
    sun_s = _sunShengJ(jd - deltaT + L / pi2, L, fa, -1) + deltaT;
    sun_j = _sunShengJ(jd - deltaT + L / pi2, L, fa, 1) + deltaT;

    if (rmin <= g.mr + g.sr) {
      sT[1] = jd;
      LX = '偏';
      sf = (g.mr + g.sr - rmin) / g.sr / 2;
      b1 = g.mr / g.sr;

      secXY(sun_s, L, fa, high, g2);
      sf2 = (g2.mr + g2.sr - math.sqrt(g2.x * g2.x + g2.y * g2.y)) / g2.sr / 2;
      if (sf2 < 0) sf2 = 0;
      secXY(sun_j, L, fa, high, g2);
      sf3 = (g2.mr + g2.sr - math.sqrt(g2.x * g2.x + g2.y * g2.y)) / g2.sr / 2;
      if (sf3 < 0) sf3 = 0;

      sT[0] = lineT(g, v, u, g.mr + g.sr, false);
      for (var i = 0; i < 3; i++) {
        secXY(sT[0], L, fa, high, g2);
        sT[0] = lineT(g2, v, u, g2.mr + g2.sr, false);
      }
      P1 = rad2mrad(math.atan2(g2.x, g2.y));
      V1 = rad2mrad(P1 - _shiChaJ(_pGst2(sT[0]), L, fa, g2.sCJ, g2.sCW));

      sT[2] = lineT(g, v, u, g.mr + g.sr, true);
      for (var i = 0; i < 3; i++) {
        secXY(sT[2], L, fa, high, g2);
        sT[2] = lineT(g2, v, u, g2.mr + g2.sr, true);
      }
      P2 = rad2mrad(math.atan2(g2.x, g2.y));
      V2 = rad2mrad(P2 - _shiChaJ(_pGst2(sT[2]), L, fa, g2.sCJ, g2.sCW));
    }

    void innerContacts(double radius, String kind) {
      LX = kind;
      sT[3] = lineT(g, v, u, radius, false);
      secXY(sT[3], L, fa, high, g2);
      sT[3] = lineT(g2, v, u, g2.mr - g2.sr, false);
      sT[4] = lineT(g, v, u, radius, true);
      secXY(sT[4], L, fa, high, g2);
      sT[4] = lineT(g2, v, u, g2.mr - g2.sr, true);
      dur = sT[4] - sT[3];
    }

    if (rmin <= g.mr - g.sr) innerContacts(g.mr - g.sr, '全');
    if (rmin <= g.sr - g.mr) {
      LX = '环';
      sT[3] = lineT(g, v, u, g.sr - g.mr, false);
      secXY(sT[3], L, fa, high, g2);
      sT[3] = lineT(g2, v, u, g2.sr - g2.mr, false);
      sT[4] = lineT(g, v, u, g.sr - g.mr, true);
      secXY(sT[4], L, fa, high, g2);
      sT[4] = lineT(g2, v, u, g2.sr - g2.mr, true);
      dur = sT[4] - sT[3];
    }

    if (sT[1] < sun_s && sf2 > 0) {
      sf = sf2;
      sflx = '#';
    }
    if (sT[1] > sun_j && sf3 > 0) {
      sf = sf3;
      sflx = '*';
    }
    for (var i = 0; i < 5; i++) {
      if (sT[i] < sun_s || sT[i] > sun_j) sT[i] = 0;
    }
    sun_s -= dtT(jd);
    sun_j -= dtT(jd);
  }
}

double _shiChaJ(double gst, double lon, double lat, double ra, double dec) {
  final h = gst + lon - ra;
  return math.atan2(
    math.sin(h),
    math.tan(lat) * math.cos(dec) - math.sin(dec) * math.cos(h),
  );
}

double _pGst2(double jd) {
  final deltaT = dtT(jd);
  return pGst(jd - deltaT, deltaT);
}

double _sunShengJ(double jd, double lon, double lat, int direction) {
  jd = (jd + .5).floorToDouble() - lon / pi2;
  for (var i = 0; i < 2; i++) {
    final t = jd / 36525;
    final e = (84381.4060 - 46.836769 * t) / rad;
    final td = t + (32 * (t + 1.8) * (t + 1.8) - 20) / 86400 / 36525;
    final j =
        (48950621.66 +
            6283319653.318 * td +
            53 * td * td -
            994 +
            334166 * math.cos(4.669257 + 628.307585 * td) +
            3489 * math.cos(4.6261 + 1256.61517 * td) +
            2060.6 * math.cos(2.67823 + 628.307585 * td) * td) /
        10000000;
    final ra = math.atan2(math.sin(j) * math.cos(e), math.cos(j));
    final dec = math.asin(math.sin(e) * math.sin(j));
    final cosH =
        (math.sin(-50 * 60 / rad) - math.sin(lat) * math.sin(dec)) /
        (math.cos(lat) * math.cos(dec));
    if (cosH.abs() >= 1) return 0;
    final gst =
        (0.7790572732640 + 1.00273781191135448 * jd) * pi2 +
        (0.014506 + 4612.15739966 * t + 1.39667721 * t * t) / rad;
    jd += rad2rrad(direction * math.acos(cosH) - (gst + lon - ra)) / pi2;
  }
  return jd;
}

/// 与 sxwnl 原版同名的地方日食计算器实例。
final rsPL = RsPL();
