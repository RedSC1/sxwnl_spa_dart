import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:sxwnl_spa_dart/src/astro_date_time.dart';
import 'package:sxwnl_spa_dart/src/sxwnl/delta_t.dart';
import 'package:sxwnl_spa_dart/src/sxwnl/math_utils.dart';
import 'package:sxwnl_spa_dart/src/sxwnl/solar_lunar_pos.dart';

List<double> _uniqueSorted(List<double> values) {
  values.sort();
  final out = <double>[];
  for (final v in values) {
    if (out.isEmpty || (v - out.last).abs() > 1e-9) {
      out.add(v);
    }
  }
  return out;
}

double _qiAccurate(double w) {
  final t = sALonT(w) * 36525.0;
  return t - dtT(t) + 8 / 24;
}

double _suoAccurate(double w) {
  final t = msALonT(w) * 36525.0;
  return t - dtT(t) + 8 / 24;
}

List<double> _collectYearJQ(int year) {
  final start = AstroDateTime(year, 1, 1).toJulianDay();
  final candidates = <double>[];
  final y = year - 2000;
  for (var i = -30; i < 60; i++) {
    final w = (y + i / 24 + 1) * 2 * pi;
    final jd = _qiAccurate(w);
    candidates.add(jd);
  }
  final sorted = _uniqueSorted(candidates);
  var idx = 0;
  for (; idx < sorted.length; idx++) {
    if (sorted[idx] + AstroDateTime.j2000 >= start - 1e-9) break;
  }
  return sorted.sublist(idx, min(idx + 24, sorted.length));
}

List<double> _collectYearSuo(int year) {
  final start = AstroDateTime(year, 1, 1).toJulianDay();
  final end = AstroDateTime(year + 1, 1, 1).toJulianDay();
  final candidates = <double>[];
  final y = year - 2000;
  final n0 = int2(y * (365.2422 / 29.53058886));
  for (var i = -3; i < 17; i++) {
    final w = (n0 + i) * 2 * pi;
    final jd = _suoAccurate(w);
    candidates.add(jd);
  }
  final sorted = _uniqueSorted(candidates);
  return sorted
      .where(
        (jd) =>
            jd + AstroDateTime.j2000 >= start - 1e-9 &&
            jd + AstroDateTime.j2000 < end - 1e-9,
      )
      .toList();
}

String _jdToStr(double jd) {
  return AstroDateTime.fromJ2000(jd).toString();
}

List<int> _sampleYears(int start, int end, int count) {
  final rng = Random(20260213);
  final years = <int>{};
  while (years.length < count) {
    years.add(start + rng.nextInt(end - start + 1));
  }
  return years.toList()..sort();
}

void main() {
  final file = File('test/js_jq.json');
  if (!file.existsSync()) {
    stderr.writeln('missing test/js_jq.json');
    exitCode = 1;
    return;
  }
  final data = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  final startYear = data['startYear'] as int;
  final endYear = data['endYear'] as int;
  final jq = (data['jq'] as List)
      .map((e) => (e as List).map((v) => (v as num).toDouble()).toList())
      .toList();
  final jsMismatches = data['mismatches'] as List;
  final suo = (data['suo'] as List)
      .map((e) => (e as List).map((v) => (v as num).toDouble()).toList())
      .toList();
  final suoMismatches = data['suoMismatches'] as List;

  double sumDiff = 0;
  double maxDiff = 0;
  int total = 0;
  int exact = 0;
  int lt1 = 0;
  int lt4 = 0;
  int gt4 = 0;
  final yearCountMismatch = <int, int>{};

  void report({
    required String title,
    required List<List<double>> jsSeries,
    required List listMismatches,
    required List<double> Function(int) collectYear,
    required bool expectFixedCount,
    required int expectedCount,
  }) {
    sumDiff = 0;
    maxDiff = 0;
    total = 0;
    exact = 0;
    lt1 = 0;
    lt4 = 0;
    gt4 = 0;
    yearCountMismatch.clear();

    for (var year = startYear; year <= endYear; year++) {
      final idx = year - startYear;
      final jsList = jsSeries[idx];
      final dartList = collectYear(year);
      if (expectFixedCount) {
        if (dartList.length != expectedCount ||
            jsList.length != expectedCount) {
          yearCountMismatch[year] = max(dartList.length, jsList.length);
        }
      } else {
        if (dartList.length != jsList.length) {
          yearCountMismatch[year] = max(dartList.length, jsList.length);
        }
      }
      final len = min(dartList.length, jsList.length);
      for (var i = 0; i < len; i++) {
        final jsVal = jsList[i];
        final dartVal = dartList[i];
        final diff = (dartVal - jsVal).abs() * 86400.0;
        sumDiff += diff;
        if (diff > maxDiff) maxDiff = diff;
        total++;
        final jsSec = (jsVal * 86400.0).round();
        final dartSec = (dartVal * 86400.0).round();
        final diffSecRounded = (dartSec - jsSec).abs();
        if (diffSecRounded == 0) {
          exact++;
        } else if (diff < 1) {
          lt1++;
        } else if (diff < 4) {
          lt4++;
        } else {
          gt4++;
        }
      }
    }

    final avg = total == 0 ? 0 : sumDiff / total;
    stdout.writeln('');
    stdout.writeln(title);
    stdout.writeln('years: $startYear..$endYear');
    stdout.writeln('total_terms: $total');
    stdout.writeln('avg_diff_seconds: ${avg.toStringAsFixed(6)}');
    stdout.writeln('max_diff_seconds: ${maxDiff.toStringAsFixed(6)}');
    stdout.writeln('exact_second: $exact');
    stdout.writeln('lt_1s: $lt1');
    stdout.writeln('lt_4s: $lt4');
    stdout.writeln('gt_4s: $gt4');
    stdout.writeln('js_count_mismatch: ${listMismatches.length}');
    stdout.writeln('dart_or_js_count_mismatch: ${yearCountMismatch.length}');
    stdout.writeln('');
    stdout.writeln('sample_years:');
    final samples = _sampleYears(startYear, endYear, 3);
    for (final year in samples) {
      final idx = year - startYear;
      final jsList = jsSeries[idx];
      final dartList = collectYear(year);
      stdout.writeln('year: $year');
      for (var i = 0; i < min(jsList.length, min(dartList.length, 6)); i++) {
        final jsVal = jsList[i];
        final dartVal = dartList[i];
        final diffSec = (dartVal - jsVal).abs() * 86400.0;
        stdout.writeln(
          '  $i | ${_jdToStr(jsVal)} | ${_jdToStr(dartVal)} | ${diffSec.toStringAsFixed(6)}s',
        );
      }
    }
  }

  report(
    title: 'jieqi',
    jsSeries: jq,
    listMismatches: jsMismatches,
    collectYear: _collectYearJQ,
    expectFixedCount: true,
    expectedCount: 24,
  );

  report(
    title: 'suo',
    jsSeries: suo,
    listMismatches: suoMismatches,
    collectYear: _collectYearSuo,
    expectFixedCount: false,
    expectedCount: 0,
  );
}
