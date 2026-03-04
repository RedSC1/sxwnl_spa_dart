import 'package:sxwnl_spa_dart/src/sxwnl/festivals.dart';
import 'package:sxwnl_spa_dart/sxwnl_spa_dart.dart';

void main() {
  print('=== sxwnl_dart 节日与民俗时段测试 ===');

  // 1. 测试三伏 (2026年7月)
  print('--- 2026年7月：查看三伏 (夏至三庚入伏) ---');
  final july = getSolarMonthDays(2026, 7);
  for (var day in july) {
    // 只要有节日或者属于伏天，就打印
    final fu = FestivalEngine.getSanfu(day.solarDate, day.ganZhi);
    if (day.festivals.isNotEmpty || fu != null) {
      print('${day.solarDate.toString().split(' ')[0]} ${day.ganZhi} | '
          '当前状态: ${fu ?? "非伏天"} | '
          '显示标签: ${day.getFestivalsByLevel().join(", ")}');
    }
  }
  print('');

  // 2. 测试梅雨 (2026年6月)
  print('--- 2026年6月：查看梅雨 (芒种后丙日入梅) ---');
  final june = getSolarMonthDays(2026, 6);
  for (var day in june) {
    final mei = FestivalEngine.getMeiyu(day.solarDate, day.ganZhi);
    if (mei != null) {
      print('${day.solarDate.toString().split(' ')[0]} ${day.ganZhi} | 事件: $mei');
    }
  }
  print('');

  // 3. 测试数九 (2026年1月)
  print('--- 2026年1月：查看数九 (冬至起算) ---');
  final jan = getSolarMonthDays(2026, 1);
  for (var day in jan) {
    final jiu = FestivalEngine.getShujiu(day.solarDate);
    if (jiu != null) {
      // 简单判断是否是九的第一天
      if (day.festivals.any((f) => f.name.contains('九'))) {
        print('${day.solarDate.toString().split(' ')[0]} | 今日进: $jiu');
      }
    }
  }
  print('');

  // 4. 测试 5 级分类过滤
  print('--- 节日分类显示测试 (2026年2月) ---');
  final feb = getSolarMonthDays(2026, 2);
  
  final day2 = feb.firstWhere((d) => d.solarDate.day == 2); // 世界湿地日 (Commemorative)
  final day14 = feb.firstWhere((d) => d.solarDate.day == 14); // 情人节 (Popular)
  
  print('2月2日 (Commemorative) 默认 toString: $day2');
  print('2月2日 全量节日列表: ${day2.festivals}');
  print('');
  print('2月14日 (Popular) 默认 toString: $day14');
  print('说明: toString 默认显示 Popular 以上级别，因此情人节可见，湿地日不可见。');
}
