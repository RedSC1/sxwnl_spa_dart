import 'package:sxwnl_spa_dart/sxwnl_spa_dart.dart';

void main() {
  print('=== sxwnl_spa_dart 示例 ===\n');

  // 1. 真太阳时
  final time = AstroDateTime(2023, 1, 22, 12, 0, 0); // 2023春节
  final loc = Location.beijing;
  final res = calcTrueSolarTime(time, loc);

  print('[真太阳时]');
  print('输入时间: $time (北京时间)');
  print('真太阳时: ${res.trueSolarTime}');
  print('日上中天: ${res.solarNoon}');
  print('均时差:   ${res.equationOfTime.inSeconds / 60} 分钟\n');

  // 2. 农历排盘
  print('[农历排盘]');
  final ssq = SSQ();
  // 计算 2023 年中 JD (J2000相对)
  final jd2023 = AstroDateTime(2023, 6, 1).toJ2000();
  final lunarRes = ssq.calcY(jd2023);

  print('闰月: ${lunarRes.leap > 0 ? "闰${lunarRes.ym[lunarRes.leap]}" : "无"}');
  print('月份列表:');
  for (int i = 0; i < 14; i++) {
    final dt = AstroDateTime.fromJ2000(lunarRes.hs[i]);
    final days = lunarRes.dx[i];
    final name = lunarRes.ym[i];
    print(
      '  ${i.toString().padLeft(2)}: $name月 ($days天) - 初一: ${dt.year}-${dt.month}-${dt.day}',
    );
  }
  print('');

  // 3. 干支计算
  print('[干支计算]');
  // 2023-02-04 12:00 (立春后)
  final dtBz = AstroDateTime(1611, 2, 6, 12, 0, 0);
  final jdBz = dtBz.toJulianDay();
  final bazi = calcGanZhi(jdBz - 8 / 24 - 2451545, jdBz - 2451545);
  print('时间: $dtBz');
  print('八字: $bazi');
}
