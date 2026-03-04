/// 寿星万年历扩展功能包 (非原版实现)
///
/// 本文件包含在原版 sxwnl 基础上增加的自定义扩展逻辑。
library;

import '../sxwnl/astro_events.dart';
import '../models/calendar.dart';

extension DayInfoListMoonExt on List<DayInfo> {
  /// 将当前的日历列表升级为 8 月相显示 (包含峨眉月、凸月等)
  /// 
  /// 采用 copyWith 模式进行增量更新，不破坏原始数据。
  List<DayInfo> withMoonPhase8() {
    return map((day) {
      // 调用核心层提供的 use8Phases 算法，传递完整日期对象
      final mp8 = AstroEvents.getMoonPhase(day.solarDate, use8Phases: true);
      
      if (mp8 != null) {
        return day.copyWith(
          moonPhase: mp8.name,
          moonPhaseTime: mp8.dateTime,
        );
      }
      return day;
    }).toList();
  }
}
