import 'package:sxwnl_spa_dart/sxwnl_spa_dart.dart';
import 'package:sxwnl_spa_dart/src/extensions/sxwnl_ext.dart'; // 导入扩展

void main() {
  print('=== 8月相链式升级测试 (2026年3月) ===');
  
  // 1. 获取原版日历 (只有 4 月相)
  final originalDays = getSolarMonthDays(2026, 3);
  
  // 2. 链式升级为 8 月相
  final extendedDays = originalDays.withMoonPhase8();
  
  for (var day in extendedDays) {
    if (day.moonPhase != null) {
      // 如果是扩展月相（不是原版的 4 个），特别标注出来
      bool isOriginal = ["朔", "上弦", "望", "下弦"].contains(day.moonPhase);
      String prefix = isOriginal ? '[原版]' : '[扩展]';
      print('$prefix $day');
    }
  }
}
