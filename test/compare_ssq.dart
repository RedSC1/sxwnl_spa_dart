import 'dart:convert';
import 'dart:io';

import 'package:sxwnl_spa_dart/src/astro_date_time.dart';
import 'package:sxwnl_spa_dart/src/sxwnl/ssq.dart';

void main() {
  print('Loading JS SSQ data...');
  final file = File('test/js_ssq.json');
  if (!file.existsSync()) {
    stderr.writeln(
      'missing test/js_ssq.json, please run node test/compute_ssq_js.js first.',
    );
    exitCode = 1;
    return;
  }

  final data = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  final startYear = data['startYear'] as int;
  final endYear = data['endYear'] as int;
  final results = data['results'] as List;

  int totalYears = 0;
  int zqMismatches = 0;
  int hsMismatches = 0;
  int dxMismatches = 0;
  int ymMismatches = 0;
  int leapMismatches = 0;

  print('Comparing years $startYear to $endYear...');
  final ssq = SSQ();

  for (var year = startYear; year <= endYear; year++) {
    final idx = year - startYear;
    final jsRes = results[idx] as Map<String, dynamic>;

    final dartRes = ssq.calcY(AstroDateTime(year, 1, 1).toJulianDay());
    totalYears++;

    // Compare ZQ
    final jsZq = (jsRes['ZQ'] as List).cast<num>();
    for (int i = 0; i < 25; i++) {
      if ((dartRes.zq[i] - jsZq[i].toDouble()).abs() > 1e-6) {
        zqMismatches++;
        if (zqMismatches <= 5)
          print(
            'Year $year ZQ[$i] mismatch: JS=${jsZq[i]}, Dart=${dartRes.zq[i]}',
          );
      }
    }

    // Compare HS
    final jsHs = (jsRes['HS'] as List).cast<num>();
    for (int i = 0; i < 15; i++) {
      // Depending on historical/modern logic, HS can be exact or float. Test exactness.
      if ((dartRes.hs[i] - jsHs[i].toDouble()).abs() > 1e-6) {
        hsMismatches++;
        if (hsMismatches <= 5)
          print(
            'Year $year HS[$i] mismatch: JS=${jsHs[i]}, Dart=${dartRes.hs[i]}',
          );
      }
    }

    // Compare dx
    final jsDx = (jsRes['dx'] as List).cast<num>();
    for (int i = 0; i < 14; i++) {
      if (dartRes.dx[i] != jsDx[i].toInt()) {
        dxMismatches++;
        if (dxMismatches <= 5)
          print(
            'Year $year dx[$i] mismatch: JS=${jsDx[i]}, Dart=${dartRes.dx[i]}',
          );
      }
    }

    // Compare ym
    final jsYm = (jsRes['ym'] as List).cast<String>();
    for (int i = 0; i < 14; i++) {
      if (dartRes.ym[i] != jsYm[i]) {
        ymMismatches++;
        if (ymMismatches <= 5)
          print(
            'Year $year ym[$i] mismatch: JS=${jsYm[i]}, Dart=${dartRes.ym[i]}',
          );
      }
    }

    // Compare leap
    final jsLeap = (jsRes['leap'] as num).toInt();
    if (dartRes.leap != jsLeap) {
      leapMismatches++;
      if (leapMismatches <= 5)
        print('Year $year leap mismatch: JS=$jsLeap, Dart=${dartRes.leap}');
    }
  }

  print('');
  print('SSQ Historical Lunar Calendar Core Test Complete.');
  print('Total Years tested: $totalYears');
  print('Total ZQ (25x) mismatches: $zqMismatches');
  print('Total HS (15x) mismatches: $hsMismatches');
  print('Total dx (14x) mismatches: $dxMismatches');
  print('Total ym (14x) mismatches: $ymMismatches');
  print('Total leap mismatches: $leapMismatches');
}
