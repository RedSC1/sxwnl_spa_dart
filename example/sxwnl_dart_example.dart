import 'package:sxwnl_spa_dart/sxwnl_spa_dart.dart';
import 'package:sxwnl_spa_dart/src/extensions/sxwnl_ext.dart';

void main() {
  print('=== 寿星万年历 (sxwnl_dart) 官方示例 ===\n');

  // 1. 设置地理位置 (北京)
  final beijing = Location(116.4, 39.9);
  print('当前位置: 北京 (东经 116.4, 北纬 39.9)\n');

  // 2. 核心功能展示：日历事件、节气、8月相
  print('--- 2026年2月 重要历法事件表 ---');
  final List<DayInfo> calendar = getSolarMonthDays(2026, 2, location: beijing).withMoonPhase8();
  print('-' * 85);
  for (var day in calendar) {
    bool isChunjie = day.lunarDate.month == 1 && day.lunarDate.day == 1;
    if (day.solarTerm != null || day.moonPhase != null || isChunjie) {
      final dateStr = day.solarDate.toString().split(' ')[0];
      final lunarStr = '农历${day.lunarDate.monthNameStr}月${day.lunarDate.dayName}(${day.lunarMonthSize == 30 ? "大" : "小"})';
      String eventStr = '';
      if (isChunjie) eventStr += '【春节】';
      if (day.solarTerm != null) eventStr += '[${day.solarTerm} ${day.solarTermTime!.toTimeString()}] ';
      if (day.moonPhase != null) eventStr += '(${day.moonPhase} ${day.moonPhaseTime!.toTimeString()}) ';
      print('$dateStr  ${day.ganZhi}  周${day.weekdayName}  ${day.constellation.padRight(4)}  ${lunarStr.padRight(18)}  $eventStr');
    }
  }
  print('-' * 85 + '\n');

  // 3. 特色功能展示：日上中天与真太阳时
  print('--- 真太阳时与日上中天 (2026年春节) ---');
  final DateTime testTime = DateTime(2026, 2, 17, 12, 0, 0); 
  final AstroDateTime astroTime = AstroDateTime.fromDateTime(testTime);
  final solarTimeRes = calcTrueSolarTime(astroTime, beijing);
  
  print('标准北京时间: ${astroTime.toString()}');
  print('日上中天时刻: ${solarTimeRes.solarNoon.toTimeString()} (日影最短时刻)');
  print('当日日出时刻: ${solarTimeRes.sunrise?.toTimeString() ?? "极区特殊天象"}');
  print('当日日落时刻: ${solarTimeRes.sunset?.toTimeString() ?? "极区特殊天象"}');
  print('均时差修正值: ${solarTimeRes.equationOfTime.inMinutes} 分 ${solarTimeRes.equationOfTime.inSeconds % 60} 秒');
  print('对应真太阳时: ${solarTimeRes.trueSolarTime.toString()}\n');

  // 4. 极地天象演示 (模拟南极科考站)
  print('--- 极地天象判定演示 (南极点附近) ---');
  final southPole = Location(0, -89.0); // 南纬 89 度
  final midSummer = AstroDateTime(2026, 1, 1, 12, 0, 0); // 南半球仲夏
  final midWinter = AstroDateTime(2026, 7, 1, 12, 0, 0); // 南半球仲冬

  final summerRes = calcTrueSolarTime(midSummer, southPole);
  final winterRes = calcTrueSolarTime(midWinter, southPole);

  print('1月1日 (南极仲夏) 状态: ${_formatPolar(summerRes.polarStatus)}');
  print('7月1日 (南极仲冬) 状态: ${_formatPolar(winterRes.polarStatus)}');
  print('说明: 本库完美支持全球任意维度的极昼/极夜判定。');
}

String _formatPolar(PolarStatus status) {
  switch (status) {
    case PolarStatus.polarDay: return "全天极昼 (太阳不落)";
    case PolarStatus.polarNight: return "全天极夜 (太阳不升)";
    default: return "正常昼夜";
  }
}
