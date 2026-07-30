// ignore_for_file: non_constant_identifier_names

/// 日月升中天降 (SZJ - Sun & Moon Rise/Transit/Set) 计算。
///
/// 移植自寿星万年历 (sxwnl) eph.js。
/// 原作者：许剑伟
/// 提供了不依赖第三方 SPA 的纯血天文算法版日月升落计算，
/// 支持月亮升降及多个曙暮光阶段查询。
library;

import 'dart:math' as math;

import 'math_utils.dart';
import 'nutation.dart';
import 'solar_lunar_pos.dart';
import 'delta_t.dart';

/// 一天的升中降计算结果
class SZJResult {
  final double jd; // 传入的当日UTC12:00

  // 时间数据，存的是日历上的日的小数部分偏移 (UT)
  double s = 0.0; // 升
  double z = 0.0; // 中天
  double j = 0.0; // 降
  double x = 0.0; // 下中天

  // 以下为太阳特有：各种曙暮光
  double c = 0.0; // 民用晨 (-6度)
  double h = 0.0; // 民用昏
  double c2 = 0.0; // 航海晨 (-12度)
  double h2 = 0.0; // 航海昏
  double c3 = 0.0; // 天文晨 (-18度)
  double h3 = 0.0; // 天文昏

  String sm = ''; // 极地状况备注（如“无升起”）

  SZJResult(this.jd);
}

/// 多日升中降结果，对应原版 `SZJ.rts[i]`。
class SZJDailyResult {
  String Ms = '--:--:--';
  String Mz = '--:--:--';
  String Mj = '--:--:--';
  String s = '--:--:--';
  String z = '--:--:--';
  String j = '--:--:--';
  String c = '--:--:--';
  String h = '--:--:--';
  String ch = '--:--:--';
  String sj = '--:--:--';
}

/// 内部计算中间状态
class _SZJContext {
  double H = 0.0;
  double H0 = 0.0;
  double H1 = 0.0;
  double H2 = 0.0;
  double H3 = 0.0;
  double H4 = 0.0;
}

class SZJ {
  double L = 0.0; // 站点地理经度 (向东测量为正, 弧度)
  double fa = 0.0; // 站点地理纬度 (弧度)
  double dt = 0.0; // TD-UT
  double E = 0.409092614; // 黄赤交角

  /// 多日计算缓存，对应原版 `SZJ.rts`。
  final List<SZJDailyResult> rts = [];

  /// 计算连续 [n] 天的太阳/月亮升、中天、降落。
  ///
  /// [jd] 为当地起始日中午对应的 J2000.0 起算 UT 儒略日，[Jdl]、[Wdl]
  /// 为东经、北纬（弧度），[sq] 为时区小时。返回值中的时间字符串为当地钟表时。
  /// 原函数名：`SZJ.calcRTS(jd, n, Jdl, Wdl, sq)`。
  List<SZJDailyResult> calcRTS(
    double jd,
    int n,
    double Jdl,
    double Wdl,
    double sq,
  ) {
    if (n < 0) throw ArgumentError.value(n, 'n', 'must be non-negative');
    L = Jdl;
    fa = Wdl;
    final timezoneDays = sq / 24;
    rts
      ..clear()
      ..addAll(List.generate(n, (_) => SZJDailyResult()));
    for (var i = -1; i <= n; i++) {
      if (i >= 0 && i < n) {
        final sun = st(jd + i + timezoneDays);
        final day = rts[i];
        day.s = _timeStr(sun.s - timezoneDays);
        day.z = _timeStr(sun.z - timezoneDays);
        day.j = _timeStr(sun.j - timezoneDays);
        day.c = _timeStr(sun.c - timezoneDays);
        day.h = _timeStr(sun.h - timezoneDays);
        day.ch = _timeStr(sun.h - sun.c - .5);
        day.sj = _timeStr(sun.j - sun.s - .5);
      }
      final moon = mt(jd + i + timezoneDays);
      final assign = (double value, String Function(SZJDailyResult) setter) {
        final dayIndex = int2(value - timezoneDays + .5) - int2(jd);
        if (dayIndex >= 0 && dayIndex < n) {
          setter(rts[dayIndex]);
        }
      };
      assign(moon.s, (day) => day.Ms = _timeStr(moon.s - timezoneDays));
      assign(moon.z, (day) => day.Mz = _timeStr(moon.z - timezoneDays));
      assign(moon.j, (day) => day.Mj = _timeStr(moon.j - timezoneDays));
    }
    return List<SZJDailyResult>.unmodifiable(rts);
  }

  /// 获取时角
  /// [h] 地平纬度, [w] 赤纬, 返回时角
  double getH(double h, double w) {
    double c =
        (math.sin(h) - math.sin(fa) * math.sin(w)) /
        (math.cos(fa) * math.cos(w));
    if (c.abs() > 1) return math.pi;
    return math.acos(c);
  }

  /// 月球坐标及所需时角
  /// [jd] UT 时间，[H0] 标记是否需要算时角，[r] 上下文
  void _mCoord(double jd, bool needH0, _SZJContext r) {
    var z = mCoord((jd + dt) / 36525.0, 40, 30, 8); // 低精度月亮赤经纬
    z = llrConv(z, E); // 转为赤道坐标
    r.H = rad2rrad(pGst(jd, dt) + L - z[0]); // 得到此刻天体时角

    if (needH0) {
      r.H0 = getH(0.7275 * csREar / z[2] - 34 * 60 / rad, z[1]); // 升起对应的时角
    }
  }

  /// 月亮到中升降时刻计算
  /// [jd] 当地中午12点时间对应的2000年首起算的格林尼治时间UT
  SZJResult mt(double jd) {
    dt = dtT(jd);
    E = hcjj(jd / 36525.0);
    // 查找最靠近当日中午的月上中天
    jd -= mod2(0.1726222 + 0.966136808032357 * jd - 0.0366 * dt + L / pi2, 1);

    var res = SZJResult(jd);
    var ctx = _SZJContext();
    double sv = pi2 * 0.966;

    res.z = res.x = res.s = res.j = jd;
    _mCoord(jd, true, ctx); // 月亮坐标

    res.s += (-ctx.H0 - ctx.H) / sv;
    res.j += (ctx.H0 - ctx.H) / sv;
    res.z += (0 - ctx.H) / sv;
    res.x += (math.pi - ctx.H) / sv;

    _mCoord(res.s, true, ctx);
    res.s += rad2rrad(-ctx.H0 - ctx.H) / sv;

    _mCoord(res.j, true, ctx);
    res.j += rad2rrad(ctx.H0 - ctx.H) / sv;

    _mCoord(res.z, false, ctx);
    res.z += rad2rrad(0 - ctx.H) / sv;

    _mCoord(res.x, false, ctx);
    res.x += rad2rrad(math.pi - ctx.H) / sv;

    return res;
  }

  /// 太阳坐标及所需时角
  void _sCoord(double jd, int xm, _SZJContext r) {
    // 太阳坐标(修正了光行差)
    var z = [eLon((jd + dt) / 36525.0, 5) + math.pi - 20.5 / rad, 0.0, 1.0];
    z = llrConv(z, E); // 转为赤道坐标
    r.H = rad2rrad(pGst(jd, dt) + L - z[0]); // 得到此刻天体时角

    if (xm == 10 || xm == 1) r.H1 = getH(-50 * 60 / rad, z[1]); // 地平以下50分(日出落)
    if (xm == 10 || xm == 2) r.H2 = getH(-6 * 3600 / rad, z[1]); // 地平以下6度(民用)
    if (xm == 10 || xm == 3) r.H3 = getH(-12 * 3600 / rad, z[1]); // 地平以下12度(航海)
    if (xm == 10 || xm == 4) r.H4 = getH(-18 * 3600 / rad, z[1]); // 地平以下18度(天文)
  }

  /// 太阳到中升降时刻计算
  /// [jd] 当地中午12点时间对应的2000年首起算的格林尼治时间UT
  SZJResult st(double jd) {
    dt = dtT(jd);
    E = hcjj(jd / 36525.0);
    // 查找最靠近当日中午的日上中天
    jd -= mod2(jd + L / pi2, 1);

    var res = SZJResult(jd);
    var ctx = _SZJContext();
    double sv = pi2;

    res.z = res.x = res.s = res.j = res.c = res.h = res.c2 = res.h2 = res.c3 =
        res.h3 = jd;

    _sCoord(jd, 10, ctx); // 太阳坐标

    res.s += (-ctx.H1 - ctx.H) / sv; // 升起
    res.j += (ctx.H1 - ctx.H) / sv; // 降落
    res.c += (-ctx.H2 - ctx.H) / sv; // 民用晨
    res.h += (ctx.H2 - ctx.H) / sv; // 民用昏
    res.c2 += (-ctx.H3 - ctx.H) / sv; // 航海晨
    res.h2 += (ctx.H3 - ctx.H) / sv; // 航海昏
    res.c3 += (-ctx.H4 - ctx.H) / sv; // 天文晨
    res.h3 += (ctx.H4 - ctx.H) / sv; // 天文昏
    res.z += (0 - ctx.H) / sv; // 中天
    res.x += (math.pi - ctx.H) / sv; // 下中天

    _sCoord(res.s, 1, ctx);
    res.s += rad2rrad(-ctx.H1 - ctx.H) / sv;
    if (ctx.H1 == math.pi) res.sm += '无升起.';

    _sCoord(res.j, 1, ctx);
    res.j += rad2rrad(ctx.H1 - ctx.H) / sv;
    if (ctx.H1 == math.pi) res.sm += '无降落.';

    _sCoord(res.c, 2, ctx);
    res.c += rad2rrad(-ctx.H2 - ctx.H) / sv;
    if (ctx.H2 == math.pi) res.sm += '无民用晨.';

    _sCoord(res.h, 2, ctx);
    res.h += rad2rrad(ctx.H2 - ctx.H) / sv;
    if (ctx.H2 == math.pi) res.sm += '无民用昏.';

    _sCoord(res.c2, 3, ctx);
    res.c2 += rad2rrad(-ctx.H3 - ctx.H) / sv;
    if (ctx.H3 == math.pi) res.sm += '无航海晨.';

    _sCoord(res.h2, 3, ctx);
    res.h2 += rad2rrad(ctx.H3 - ctx.H) / sv;
    if (ctx.H3 == math.pi) res.sm += '无航海昏.';

    _sCoord(res.c3, 4, ctx);
    res.c3 += rad2rrad(-ctx.H4 - ctx.H) / sv;
    if (ctx.H4 == math.pi) res.sm += '无天文晨.';

    _sCoord(res.h3, 4, ctx);
    res.h3 += rad2rrad(ctx.H4 - ctx.H) / sv;
    if (ctx.H4 == math.pi) res.sm += '无天文昏.';

    _sCoord(res.z, 0, ctx);
    res.z += (0 - ctx.H) / sv;

    _sCoord(res.x, 0, ctx);
    res.x += rad2rrad(math.pi - ctx.H) / sv;

    return res;
  }

  String _timeStr(double jd) {
    jd += .5;
    jd -= int2(jd);
    var seconds = int2(jd * 86400 + .5);
    final h = seconds ~/ 3600;
    seconds -= h * 3600;
    final m = seconds ~/ 60;
    seconds -= m * 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
