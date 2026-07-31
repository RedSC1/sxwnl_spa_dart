/// 真太阳时计算。
///
/// 使用 SPA (Solar Position Algorithm) 计算日上中天时刻，
/// 进而推导真太阳时。
library;

import '../third_party/spa.dart';
import '../astro_date_time.dart';
import '../location.dart';
import 'delta_t.dart';
import 'dart:math' as math;
import 'szj.dart';
import 'math_utils.dart' show rad, llrConv;
import 'solar_lunar_pos.dart' show eLon;
import 'nutation.dart' show hcjj;

/// 太阳算法选择器
enum SolarCalcMethod {
  /// 高精度光线解析模型 (NREL SPA)。推荐作为默认，速度极快且极点稳定。
  spa,

  /// 寿星天文历原生迭代模型 (基于 VSOP87 的高度适配与迭代)。适用于需要与古代理论或历史历表严格对齐的场景。
  sxwnl,
}

/// 极区特殊天象状态
enum PolarStatus {
  /// 正常昼夜交替
  none,

  /// 极昼 (太阳永不落)
  polarDay,

  /// 极夜 (太阳永不升)
  polarNight,
}

/// 真太阳时计算结果。
class SolarTimeResult {
  /// 真太阳时。
  final AstroDateTime trueSolarTime;

  /// 均时差 (Equation of Time)。
  /// 定义为：真太阳时 - 平太阳时。
  final Duration equationOfTime;

  /// 当日的日上中天时刻 (天顶)。
  /// 这是标准时区时间。
  final AstroDateTime solarNoon;

  /// 当日的日出时刻 (标准时区时间)。
  final AstroDateTime? sunrise;

  /// 当日的日落时刻 (标准时区时间)。
  final AstroDateTime? sunset;

  /// 极地状态。
  final PolarStatus polarStatus;

  SolarTimeResult({
    required this.trueSolarTime,
    required this.equationOfTime,
    required this.solarNoon,
    required this.polarStatus,
    this.sunrise,
    this.sunset,
  });
}

/// 计算真太阳时。
///
/// [dateTime] 输入时间 (标准时区时间，如北京时间)。
/// [location] 地理位置 (经纬度)。
/// [timezone] 时区偏移 (小时)，默认为 +8 (北京时间)。
/// [method] 日月算法选择，默认为 [SolarCalcMethod.spa]。
SolarTimeResult calcTrueSolarTime(
  AstroDateTime dateTime,
  Location location, {
  double timezone = 8.0,
  SolarCalcMethod method = SolarCalcMethod.spa,
}) {
  if (method == SolarCalcMethod.sxwnl) {
    return _calcTrueSolarTimeSxwnl(dateTime, location, timezone: timezone);
  }

  // 1. 准备 SPA 参数
  DateTime spaTime;
  double? manualJD;

  if (dateTime.isBCE || dateTime.year > 6000) {
    // 公元前：伪造一个现代日期以通过 SPA 的 assert 检查
    spaTime = DateTime.utc(2000, 1, 1, 12, 0, 0);
    // 计算真实的 UT JD
    // 标准时转 UTC: subtract timezone
    final utcTime = dateTime.subtract(
      Duration(minutes: (timezone * 60).round()),
    );
    manualJD = utcTime.toJulianDay();
  } else {
    // 公元后：直接转换
    final dt = dateTime.toDateTime()!;
    spaTime = DateTime.utc(
      dt.year,
      dt.month,
      dt.day,
      dt.hour,
      dt.minute,
      dt.second,
    );
  }

  final deltaTSeconds = dtT(dateTime.toJ2000()) * 86400.0;

  // 2. 调用 SPA
  final it = SPAIntermediate(); // 用于获取赤纬数据以判断极昼极夜
  final params = SPAParams(
    time: spaTime,
    // SPA 的 DateTime 主要承载年月日时分；秒单独传入，避免
    // AstroDateTime 的 fractionalSecond 在进入 SPA 时被截断。
    second: dateTime.preciseSecond,
    timeZone: timezone,
    longitude: location.longitude,
    latitude: location.latitude,
    elevation: 0,
    manualJD: manualJD,
    deltaT: deltaTSeconds,
  );

  // 3. 获取结果
  final out = spaCalculate(params, intermediate: it);

  // 4. 解析结果
  // sunTransit 是基于输入时区(timezone)的标准时间
  final transitStandard = out.sunTransit!;

  // 真太阳时 12:00 = 钟表 transitStandard
  // 钟表 12:00 = 真太阳时 12:00 - (transitStandard - 12) = 12 + 12 - transitStandard
  // 修正量 = 12 - transitStandard
  final totalOffsetHours = 12.0 - transitStandard;

  // 均时差 (EoT) = TotalOffset - LonDiff
  // LonDiff = (Lon - RefLon) / 15
  final lonDiffHours = (location.longitude - timezone * 15.0) / 15.0;
  final eotHours = totalOffsetHours - lonDiffHours;

  // 计算真太阳时
  final totalOffset = Duration(
    microseconds: (totalOffsetHours * 3600 * 1000000).round(),
  );
  final trueSolarTime = dateTime.add(totalOffset);

  // 计算日上中天时刻 (标准时)
  // transitStandard 本身就是日上中天的标准时间（小数小时）
  // 转换为 Duration 叠加在当天 0 点上
  // 注意：如果是跨天情况（transitStandard > 24 或 < 0），SPA 会返回修正后的值？
  // SPA 返回的是当日的时间。
  final solarNoon = AstroDateTime(
    dateTime.year,
    dateTime.month,
    dateTime.day,
    0,
    0,
    0,
  ).add(Duration(microseconds: (transitStandard * 3600 * 1000000).round()));

  // 5. 处理日出日落及极地判定
  // 日出日落 (标准时)
  AstroDateTime? sunrise;
  AstroDateTime? sunset;
  PolarStatus polarStatus = PolarStatus.none;

  if (out.sunrise != null && out.sunrise != -99999) {
    sunrise = AstroDateTime(
      dateTime.year,
      dateTime.month,
      dateTime.day,
      0,
      0,
      0,
    ).add(Duration(microseconds: (out.sunrise! * 3600 * 1000000).round()));
  }

  if (out.sunset != null && out.sunset != -99999) {
    sunset = AstroDateTime(
      dateTime.year,
      dateTime.month,
      dateTime.day,
      0,
      0,
      0,
    ).add(Duration(microseconds: (out.sunset! * 3600 * 1000000).round()));
  }

  // 极地判定逻辑
  if (sunrise == null || sunset == null) {
    // 使用 SPA 计算出的正午高度角 (it.sta) 进行判定。
    // 这是最准确的，因为它与 SPA 内部的“升落”定义（约 -0.833度）完全同步。
    if ((it.sta ?? -999) > -0.833) {
      polarStatus = PolarStatus.polarDay;
    } else {
      polarStatus = PolarStatus.polarNight;
    }
  }

  return SolarTimeResult(
    trueSolarTime: trueSolarTime,
    equationOfTime: Duration(microseconds: (eotHours * 3600 * 1000000).round()),
    solarNoon: solarNoon,
    polarStatus: polarStatus,
    sunrise: sunrise,
    sunset: sunset,
  );
}

SolarTimeResult _calcTrueSolarTimeSxwnl(
  AstroDateTime dateTime,
  Location location, {
  double timezone = 8.0,
}) {
  final localNoon = AstroDateTime(
    dateTime.year,
    dateTime.month,
    dateTime.day,
    12,
    0,
    0,
  );
  final jdUtNoon = localNoon.toJ2000() - timezone / 24.0;

  final szj = SZJ();
  szj.L = location.longitude / 180 * math.pi;
  szj.fa = location.latitude / 180 * math.pi;

  final res = szj.st(jdUtNoon);

  AstroDateTime fromJd(double jd) =>
      AstroDateTime.fromJ2000(jd + timezone / 24.0);

  final solarNoon = fromJd(res.z);
  final sunrise = res.sm.contains('无升起') ? null : fromJd(res.s);
  final sunset = res.sm.contains('无降落') ? null : fromJd(res.j);

  PolarStatus polarStatus = PolarStatus.none;
  if (sunrise == null && sunset == null) {
    // 物理级高精度极地判定：直接求此儒略日此刻的太阳真实赤纬（Declination）
    final t = (jdUtNoon + szj.dt) / 36525.0; // 儒略世纪数
    final e = hcjj(t); // 黄赤交角

    // 太阳黄经 (修正光行差前的极其微弱差异不影响大于 0 的宏观定性判断)
    final sunLon = eLon(t, 5) + math.pi - 20.5 / rad;

    // 太阳赤道坐标转换: z[0]赤经, z[1]赤纬, z[2]向径
    final eq = llrConv([sunLon, 0.0, 1.0], e);
    final isNorthSummer = eq[1] > 0; // 赤纬大于 0 说明太阳直射点在北半球

    if (location.latitude > 0) {
      polarStatus = isNorthSummer
          ? PolarStatus.polarDay
          : PolarStatus.polarNight;
    } else {
      polarStatus = isNorthSummer
          ? PolarStatus.polarNight
          : PolarStatus.polarDay;
    }
  }

  final transitStandard = res.z - jdUtNoon;
  final totalOffsetHours = -transitStandard * 24.0;

  final lonDiffHours = (location.longitude - timezone * 15.0) / 15.0;
  final eotHours = totalOffsetHours - lonDiffHours;
  final totalOffset = Duration(
    microseconds: (totalOffsetHours * 3600 * 1000000).round(),
  );

  return SolarTimeResult(
    trueSolarTime: dateTime.add(totalOffset),
    equationOfTime: Duration(microseconds: (eotHours * 3600 * 1000000).round()),
    solarNoon: solarNoon,
    polarStatus: polarStatus,
    sunrise: sunrise,
    sunset: sunset,
  );
}
