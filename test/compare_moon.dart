import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:sxwnl_spa_dart/src/astro_date_time.dart';
import 'package:sxwnl_spa_dart/src/sxwnl/delta_t.dart';
import 'package:sxwnl_spa_dart/src/sxwnl/solar_lunar_pos.dart';

double _suoAccurate(double w) {
  final t = msALonT(w) * 36525.0;
  return t - dtT(t) + 8 / 24;
}

List<double> _collectYearMoonPhases(int year) {
  final start = AstroDateTime(year, 1, 1).toJulianDay();
  final end = AstroDateTime(year + 1, 1, 1).toJulianDay();
  final candidates = <double>[];
  final y = year - 2000;
  final n0 = (y * (365.2422 / 29.53058886)).floor();
  
  for (var i = -3; i < 60; i++) {
    final w = (n0 + i * 0.25) * 2 * pi;
    final jd = _suoAccurate(w);
    candidates.add(jd);
  }
  
  candidates.sort();
  final unique = <double>[];
  for (final v in candidates) {
    if (unique.isEmpty || (v - unique.last).abs() > 1e-9) {
      unique.add(v);
    }
  }

  return unique.where((jd) {
    final abs = jd + AstroDateTime.j2000;
    return abs >= start - 1e-9 && abs < end - 1e-9;
  }).toList();
}

void main() {
  final file = File('test/js_moon_phase.json');
  if (!file.existsSync()) {
    print('错误: 找不到 test/js_moon_phase.json');
    return;
  }

  final data = jsonDecode(file.readAsStringSync());
  final startYear = data['startYear'] as int;
  final endYear = data['endYear'] as int;
  final jsMoonPhases = (data['moonPhases'] as List)
      .map((e) => (e as List).map((v) => (v as num).toDouble()).toList())
      .toList();

  print('=== 月相计算对账报告 ($startYear - $endYear) ===');
  
  double sumDiff = 0;
  double maxDiff = 0;
  int total = 0;
  int exact = 0;
  int gt1s = 0;

  for (int year = startYear; year <= endYear; year++) {
    final idx = year - startYear;
    final jsList = jsMoonPhases[idx];
    final dartList = _collectYearMoonPhases(year);

    final len = min(jsList.length, dartList.length);
    for (int i = 0; i < len; i++) {
      final diffSeconds = (dartList[i] - jsList[i]).abs() * 86400.0;
      sumDiff += diffSeconds;
      if (diffSeconds > maxDiff) maxDiff = diffSeconds;
      total++;

      if (diffSeconds < 0.5) {
        exact++;
      } else {
        gt1s++;
      }
    }
  }

  print('测试相位总数: $total');
  print('平均误差: ${(sumDiff / total).toStringAsFixed(4)} 秒');
  print('最大误差: ${maxDiff.toStringAsFixed(4)} 秒');
  print('秒级完全一致: $exact');
  print('误差大于1秒: $gt1s');
  
  print('\n示例对比 (2026年3月):');
  final sampleYear = 2026;
  final js2026 = jsMoonPhases[sampleYear - startYear];
  final dart2026 = _collectYearMoonPhases(sampleYear);
  for(int i=0; i<min(js2026.length, dart2026.length); i++){
    final dt = AstroDateTime.fromJ2000(dart2026[i]);
    if (dt.month == 3) {
      print('JS: ${js2026[i].toStringAsFixed(8)} | Dart: ${dart2026[i].toStringAsFixed(8)} | 差: ${((dart2026[i]-js2026[i])*86400).toStringAsFixed(2)}s | ${dt}');
    }
  }
}
