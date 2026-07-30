/// sxwnl 天文数学工具函数和常量。
///
/// 移植自寿星万年历 (sxwnl) eph0.js 的基础数学工具部分。
/// 原作者：许剑伟
library;

import 'dart:math' as math;

// ==================== 天文常量 ====================

/// J2000.0 历元的儒略日 (2000-01-01 12:00 TT)
const double j2000 = 2451545.0;

/// 2π
const double pi2 = math.pi * 2;

/// π/2
const double piHalf = math.pi / 2;

/// 每弧度的角秒数 (206264.806...)
/// 用法：角秒值 / rad → 弧度值
final double rad = 180 * 3600 / math.pi;

/// 每弧度的度数 (57.2957...)
final double radd = 180 / math.pi;

// ==================== 天文物理常量 ====================

/// 地球赤道半径 (千米)
const double csREar = 6378.1366;

/// 地球平均半径 (千米)
const double csREarA = 0.99834 * csREar;

/// 月球平均赤道视半径常数（弧度 × 千米）。
///
/// 原常量名：cs_sMoon。
final double csSMoon = 0.2725076 * csREar * 1.0000036 * rad;

/// 月球本影计算用的视半径常数（弧度 × 千米）。
///
/// 原常量名：cs_sMoon2。`rsPL.nasa_r` 启用时须以它与 [csSMoon]
/// 的比值修正月球视半径，而不是使用原源码注释中的近似小数。
final double csSMoon2 = 0.2722810 * csREar * 1.0000036 * rad;

/// 地球极赤半径比
const double csBa = 0.99664719;

/// 地球极赤半径比的平方
const double csBa2 = csBa * csBa;

/// 天文单位长度 (千米)
const double csAU = 1.49597870691e8;

/// sin(太阳视差)
final double csSinP = csREar / csAU;

/// 光速 (千米/秒)
const double csGS = 299792.458;

/// 每天文单位的光行时间 (儒略世纪)
final double csAgx = csAU / csGS / 86400 / 36525;

// ==================== 数学工具函数 ====================

/// 取整数部分（向下取整），对应 JS 的 Math.floor()。
///
/// 原函数名：int2(v)
int int2(double v) => v.floor();

/// 模拟 JavaScript 的 `%` 运算符。
///
/// JS 的 `%` 对负数是向零截断 (truncate)，
/// 而 Dart 的 `%` 是向负无穷取整 (floor)，两者对负数行为不同。
/// 例如：JS: `-1.7 % 1 = -0.7`，Dart: `-1.7 % 1 = 0.3`。
double jsMod(double a, double b) {
  return a - b * (a / b).truncateToDouble();
}

/// 模拟 JavaScript 的 `mod2(v,n) = (v%n+n)%n`，保证返回 `[0, n)` 正余数。
///
/// 原函数名：mod2(v, n)  — eph0.js 第 42 行的版本。
/// 使用 [jsMod] 模拟 JS `%` 以确保对负数行为一致。
double jsMod2(double v, double n) {
  return jsMod(jsMod(v, n) + n, n);
}

/// 临界余数：a 与最近的整倍数 b 相差的距离。
///
/// 原函数名：mod2(a, b)
/// 注意：sxwnl 中有两个 mod2，这里用的是后面那个（临界余数版本），
/// 因为它在历法计算中被广泛使用。
double mod2(double a, double b) {
  var c = jsMod(a + b, b);
  if (c > b / 2.0) c -= b;
  return c;
}

/// 将角度归一化到 [0, 2π) 范围。
///
/// 原函数名：rad2mrad(v)
double rad2mrad(double v) {
  v = jsMod(v, pi2);
  if (v < 0) v += pi2;
  return v;
}

/// 将角度归一化到 (-π, π] 范围。
///
/// 原函数名：rad2rrad(v)
double rad2rrad(double v) {
  v = jsMod(v, pi2);
  if (v <= -math.pi) v += pi2;
  if (v > math.pi) v -= pi2;
  return v;
}

// ==================== 坐标转换 ====================

/// 黄道赤道坐标变换
///
/// [z] 为 [经度, 纬度, 距离] 形式的数组，距离不参与变换。
/// [e] 是对应时刻的黄赤交角或赤道所在的球面参考坐标系的倾角。
/// 返回从黄道转换到赤道（或赤道转换到地平）的新 [经度, 纬度, 距离]。
///
/// 原函数名：llrConv(z, E)
List<double> llrConv(List<double> z, double e) {
  final jj = z[0];
  final w = z[1];
  final sinE = math.sin(e);
  final cosE = math.cos(e);
  final sinW = math.sin(w);
  final cosW = math.cos(w);

  final j = math.atan2(math.sin(jj) * cosE - sinW / cosW * sinE, math.cos(jj));
  var W = math.asin(sinW * cosE + cosW * math.sin(e) * math.sin(jj));
  return [rad2mrad(j), W, if (z.length > 2) z[2] else 0.0];
}

// ==================== 恒星时计算 ====================

/// 平恒星时计算 (适用于J2000平春分点)
///
/// [jd] 为 UT 世界时，[dt] 为 TD - UT。
/// 或者两者相加 jd+dt=TD。返回值为平恒星时 (弧度)。
/// 精度比原版稍高，直接采用 IAU1982 标准公式。
///
/// 返回格林尼治平恒星时(不含赤经章动及非多项式部分),即格林尼治子午圈的平春风点起算的赤经
/// 传入[jd]是2000年首起算的日数(UT), [dt]是deltatT(日)
/// 原函数名：pGST(T, dt)
double pGst(double jd, double dt) {
  final t = (jd + dt) / 36525.0; // 世纪数
  final t2 = t * t;
  final t3 = t2 * t;
  final t4 = t3 * t;

  double v =
      pi2 * (0.7790572732640 + 1.00273781191135448 * jd) +
      (0.014506 +
              4612.15739966 * t +
              1.39667721 * t2 -
              0.00009344 * t3 +
              0.00001882 * t4) /
          rad;

  return rad2mrad(v);
}
