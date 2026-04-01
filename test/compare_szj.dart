import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:sxwnl_spa_dart/src/astro_date_time.dart';
import 'package:sxwnl_spa_dart/src/sxwnl/szj.dart';

List<List<double>> _collectYearSzjSeconds(
  int year,
  double longitudeDeg,
  double latitudeDeg,
  double timezone,
) {
  final start = AstroDateTime(year, 1, 1);
  final end = AstroDateTime(year + 1, 1, 1);
  final days = (end.toJulianDay() - start.toJulianDay()).round();
  final out = List<List<double>>.filled(days, []);

  var szj = SZJ();
  szj.L = longitudeDeg * pi / 180;
  szj.fa = latitudeDeg * pi / 180;

  var date = start;
  for (var i = 0; i < days; i++) {
    // Exact computation logic from JS script:
    final dayJd = date.toJulianDay();
    final jdLocalNoon = dayJd + 0.5 - AstroDateTime.j2000;
    final jdUtNoon = jdLocalNoon - timezone / 24.0;

    final r = szj.st(jdUtNoon);
    final m = szj.mt(jdUtNoon);

    out[i] = [
      (r.s - jdUtNoon) * 86400,
      (r.z - jdUtNoon) * 86400,
      (r.j - jdUtNoon) * 86400,
      (m.s - jdUtNoon) * 86400,
      (m.z - jdUtNoon) * 86400,
      (m.j - jdUtNoon) * 86400,
    ];
    date = date.add(const Duration(days: 1));
  }
  return out;
}

void main() {
  print('Loading JS data...');
  final file = File('test/js_szj.json');
  if (!file.existsSync()) {
    stderr.writeln(
      'missing test/js_szj.json, please run node test/compute_szj_js.js first.',
    );
    exitCode = 1;
    return;
  }
  final data = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  final startYear = data['startYear'] as int;
  final endYear = data['endYear'] as int;
  final szjData = data['szj'] as Map<String, dynamic>;
  final locationMap = szjData['location'] as Map<String, dynamic>;
  final longitudeDeg = (locationMap['longitudeDeg'] as num).toDouble();
  final latitudeDeg = (locationMap['latitudeDeg'] as num).toDouble();
  final timezone = (locationMap['timezone'] as num).toDouble();

  final jsDays = (szjData['days'] as List)
      .map(
        (e) => (e as List)
            .map((v) => (v as List).map((n) => (n as num).toDouble()).toList())
            .toList(),
      )
      .toList();
  final dayCounts = (szjData['dayCounts'] as List)
      .map((v) => (v as num).toInt())
      .toList();

  int total = 0;
  int exact = 0;
  int lt1 = 0;
  int lt4 = 0;
  int gt4 = 0;
  double maxDiffSec = 0.0;
  double sumDiff = 0.0;

  print('Comparing years $startYear to $endYear...');

  for (var year = startYear; year <= endYear; year++) {
    final idx = year - startYear;
    final jsList = jsDays[idx];
    final dartList = _collectYearSzjSeconds(
      year,
      longitudeDeg,
      latitudeDeg,
      timezone,
    );

    if (dartList.length != dayCounts[idx] || jsList.length != dayCounts[idx]) {
      print(
        'Length mismatch for year $year: dart=${dartList.length}, js=${jsList.length}, expected=${dayCounts[idx]}',
      );
    }

    final len = min(dartList.length, jsList.length);
    for (var i = 0; i < len; i++) {
      final jsVals = jsList[i];
      final dartVals = dartList[i];
      for (var j = 0; j < 6; j++) {
        total++;
        double diff = (jsVals[j] - dartVals[j]).abs();
        sumDiff += diff;
        if (diff > maxDiffSec) maxDiffSec = diff;

        final jsSec = jsVals[j].round();
        final dartSec = dartVals[j].round();
        final diffSecRounded = (dartSec - jsSec).abs();

        if (diffSecRounded == 0) {
          exact++;
        } else if (diff <= 1) {
          lt1++;
        } else if (diff <= 4) {
          lt4++;
        } else {
          gt4++;
          if (total - exact - lt1 - lt4 <= 10) {
            print(
              'Mismatch at $year day $i, var $j: js=${jsVals[j]}, dart=${dartVals[j]}, diff=$diff, rounded_diff=$diffSecRounded',
            );
          }
        }
      }
    }
  }

  double avg = total == 0 ? 0 : sumDiff / total;
  print('');
  print('SZJ Porting Test Complete');
  print('Total comparisons: $total (dates * 6 variables)');
  print('avg_diff_seconds: ${avg.toStringAsFixed(6)}');
  print('max_diff_seconds: ${maxDiffSec.toStringAsFixed(6)}');
  print('exact_second: $exact');
  print('lt_1s: $lt1');
  print('lt_4s: $lt4');
  print('gt_4s: $gt4');
}
