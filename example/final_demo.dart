import 'package:sxwnl_spa_dart/sxwnl_spa_dart.dart';

void main() {
  print('=== sxwnl_dart 最终成品功能展示 ===');
  
  // 北京的坐标
  final beijing = Location(116.4, 39.9);
  
  // 获取 2026 年 2 月的日历（包含春节和立春）
  final days = getSolarMonthDays(2026, 2, location: beijing);
  
  print('日期范围: 2026-02-01 至 2026-02-28');
  print('地理位置: 北京 (116.4, 39.9)');
  print('-' * 50);

  for (var day in days) {
    // 重点展示有天象的日子，或者春节
    bool isChunjie = day.lunarDate.month == 1 && day.lunarDate.day == 1;
    bool hasEvent = day.solarTerm != null || day.moonPhase != null || isChunjie;
    
    if (hasEvent) {
      print(day);
    }
  }
}
