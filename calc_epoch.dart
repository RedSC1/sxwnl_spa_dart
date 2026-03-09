import 'package:sxwnl_spa_dart/src/astro_date_time.dart';
import 'package:sxwnl_spa_dart/src/jie_qi.dart';
import 'dart:math';

void main() {
  // slot 0, 1, 2 分别是什么？
  final d = pi / 12;
  for (var i = 0; i <= 25; i++) {
    final jd = qiAccurate(i * d);
    final dt = AstroDateTime.fromJ2000(jd);
    final idx = ((i % 24) + 5 + 24) % 24;
    print(
      'slot $i: ${jieQiNames[idx].padRight(4)} -> $dt (JD: ${jd.toStringAsFixed(1)})',
    );
  }
}
