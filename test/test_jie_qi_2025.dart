import 'dart:io';
import 'package:path/path.dart' as p;

// 为了解决 package 引用问题，我们不使用 package:sxwnl_dart
// 而是通过相对路径直接引用文件，或者设置 package config
// 在这个测试脚本中，我将直接读取 E:\ziwei_core_v2\sxwnl_dart\lib\src 下的文件
// 并尝试动态运行，或者更简单的方法：
// 在 E:\ziwei_core_v2\sxwnl_dart 目录下运行测试脚本。

// 修正后的测试脚本，将被放置在 E:\ziwei_core_v2\sxwnl_dart\test 目录下运行
// 这样可以使用相对路径引用

import '../lib/src/jie_qi.dart';
import '../lib/src/astro_date_time.dart';

void main() {
  int year = 2025;
  // print('正在计算 $year 年的节气时刻 (北京时间)...');

  List<JieQiResult> results = getYearJieQi(year);

  for (var jieQi in results) {
    String timeStr = _formatDateTime(jieQi.dateTime);
    print('${jieQi.name}: $timeStr');
  }
}

String _formatDateTime(AstroDateTime dt) {
  String twoDigits(int n) {
    if (n >= 10) return "$n";
    return "0$n";
  }
  
  int s = dt.second.round();
  int m = dt.minute;
  int h = dt.hour;
  int d = dt.day;
  // mo 是 AstroDateTime 中的 month
  int mo = dt.month; 
  int y = dt.year;

  if (s >= 60) {
    s -= 60;
    m += 1;
  }
  if (m >= 60) {
    m -= 60;
    h += 1;
  }
  if (h >= 24) {
    h -= 24;
    // 忽略日期进位
  }

  return "$y-${twoDigits(mo)}-${twoDigits(d)} ${twoDigits(h)}:${twoDigits(m)}:${twoDigits(s)}";
}
