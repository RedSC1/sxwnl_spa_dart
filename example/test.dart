import 'package:sxwnl_spa_dart/sxwnl_spa_dart.dart';

void main() {
  print('=== ⚖️ 冤案重审：2033年置闰逻辑复盘 ===');

  final ssq = SSQ();

  // 关键改变：选择 2034年1月15日
  // 这个时间点位于 [2033年冬至, 2034年冬至] 区间内
  // 这才是包含 "闰十一月" 的那个 "岁"
  final jd = AstroDateTime(2034, 1, 15).toJ2000();

  final res = ssq.calcY(jd);

  print('计算基准日期: 2034-01-15');
  print('闰月索引 (leap): ${res.leap}');

  if (res.leap > 0) {
    print('闰月名称: 闰${res.ym[res.leap]}月');
    if (res.ym[res.leap] == "十一") {
      print('✅ 翻案成功！库没问题，是输入时间点选错了！');
    }
  } else {
    print('❌ 依然无闰月。那就是库真的有 Bug。');
  }

  print('\n--- 月序表 ---');
  for (int i = 0; i < 14; i++) {
    String mark = (i == res.leap && res.leap > 0) ? "(闰)" : "";
    // 过滤掉空字符串（因为dx/ym数组长度固定14，非闰年只有13项有效）
    if (res.ym[i].isNotEmpty) {
      print("索引$i: ${res.ym[i]}月 $mark");
    }
  }
}
