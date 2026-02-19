import 'package:sxwnl_spa_dart/sxwnl_spa_dart.dart';

void main() {
  print('--- 节气 API 演示 ---');
  print('');

  final now = AstroDateTime(2025, 2, 19, 12, 0, 0);
  print('目标日期: $now');
  print('');

  // 1. 基础判断
  print('--- 节/气判断 ---');
  for (int i = 0; i < 6; i++) {
    print('  $i: ${jieQiNames[i]} - ${isJie(i) ? '节' : '气'}');
  }
  print('');

  // 2. 查询单个节/气
  print('--- 单个查询 ---');
  final prevJie = getPrevJie(now);
  final nextJie = getNextJie(now);
  final prevQi = getPrevQi(now);
  final nextQi = getNextQi(now);

  print('  上一个节: ${prevJie?.name} - ${prevJie?.dateTime}');
  print('  下一个节: ${nextJie?.name} - ${nextJie?.dateTime}');
  print('  上一个气: ${prevQi?.name} - ${prevQi?.dateTime}');
  print('  下一个气: ${nextQi?.name} - ${nextQi?.dateTime}');
  print('');

  // 3. Julian Day 版本
  print('--- Julian Day 版本 ---');
  final prevJieQiJd = getPrevJieQiJd(now);
  final nextJieQiJd = getNextJieQiJd(now);
  final prevJieJd = getPrevJieJd(now);
  final nextJieJd = getNextJieJd(now);
  final prevQiJd = getPrevQiJd(now);
  final nextQiJd = getNextQiJd(now);
  final yearJdArray = getYearJieQiJd(2025);

  print('  上节气 JD: $prevJieQiJd');
  print('  下节气 JD: $nextJieQiJd');
  print('  上节 JD:   $prevJieJd');
  print('  下节 JD:   $nextJieJd');
  print('  上气 JD:   $prevQiJd');
  print('  下气 JD:   $nextQiJd');
  print('');
  print('  2025年节气 JD 数组（前5个）:');
  for (int i = 0; i < 5; i++) {
    print('    $i: ${yearJdArray[i]}');
  }
  print('');

  // 4. 距离查询
  print('--- 距离查询 ---');
  final jieDist = getJieDistance(now);
  final qiDist = getQiDistance(now);

  print('  节距离: $jieDist');
  print('  气距离: $qiDist');
  print('');

  // 5. 完整信息
  print('--- 完整信息 ---');
  final info = getJieQiInfo(now);
  print('$info');
  print('');
  print('  距上节气: ${info?.daysSincePrevJieQi.toStringAsFixed(2)}天');
  print('  距下节气: ${info?.daysUntilNextJieQi.toStringAsFixed(2)}天');
  print('  距上节:   ${info?.daysSincePrevJie.toStringAsFixed(2)}天');
  print('  距下节:   ${info?.daysUntilNextJie.toStringAsFixed(2)}天');
  print('  距上气:   ${info?.daysSincePrevQi.toStringAsFixed(2)}天');
  print('  距下气:   ${info?.daysUntilNextQi.toStringAsFixed(2)}天');
}
