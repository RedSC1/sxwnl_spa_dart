import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:sxwnl_spa_dart/sxwnl_dart.dart';

int _secondsOfDay(AstroDateTime dt) {
  return dt.hour * 3600 + dt.minute * 60 + dt.second;
}

List<int> _collectYearSolarNoonSeconds(
  int year,
  Location location,
  double timezone,
) {
  final start = AstroDateTime(year, 1, 1);
  final end = AstroDateTime(year + 1, 1, 1);
  final days = (end.toJulianDay() - start.toJulianDay()).round();
  final out = List<int>.filled(days, 0);
  var date = start;
  for (var i = 0; i < days; i++) {
    final target = AstroDateTime(date.year, date.month, date.day, 12);
    final result = calcTrueSolarTime(target, location, timezone: timezone);
    out[i] = _secondsOfDay(result.solarNoon);
    date = date.add(const Duration(days: 1));
  }
  return out;
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
  final file = File('test/js_solar_noon.json');
  if (!file.existsSync()) {
    stderr.writeln('missing test/js_solar_noon.json');
    exitCode = 1;
    return;
  }
  final data = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  final startYear = data['startYear'] as int;
  final endYear = data['endYear'] as int;
  final solarNoon = data['solarNoon'] as Map<String, dynamic>;
  final locationMap = solarNoon['location'] as Map<String, dynamic>;
  final longitudeDeg = (locationMap['longitudeDeg'] as num).toDouble();
  final latitudeDeg = (locationMap['latitudeDeg'] as num).toDouble();
  final timezone = (locationMap['timezone'] as num).toDouble();
  final jsDays = (solarNoon['days'] as List)
      .map((e) => (e as List).map((v) => (v as num).toInt()).toList())
      .toList();
  final dayCounts = (solarNoon['dayCounts'] as List)
      .map((v) => (v as num).toInt())
      .toList();
  final location = Location(longitudeDeg, latitudeDeg);

  double sumDiff = 0;
  double maxDiff = 0;
  int total = 0;
  int exact = 0;
  int lt1 = 0;
  int lt4 = 0;
  int gt4 = 0;
  final yearCountMismatch = <int, int>{};

  for (var year = startYear; year <= endYear; year++) {
    final idx = year - startYear;
    final jsList = jsDays[idx];
    final dartList = _collectYearSolarNoonSeconds(year, location, timezone);
    if (dartList.length != dayCounts[idx] || jsList.length != dayCounts[idx]) {
      yearCountMismatch[year] = max(dartList.length, jsList.length);
    }
    final len = min(dartList.length, jsList.length);
    for (var i = 0; i < len; i++) {
      final jsSec = jsList[i];
      final dartSec = dartList[i];
      var diff = (dartSec - jsSec).abs();
      if (diff > 43200) diff = 86400 - diff;
      sumDiff += diff;
      if (diff > maxDiff) maxDiff = diff.toDouble();
      total++;
      if (diff == 0) {
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
  stdout.writeln('solar_noon');
  stdout.writeln('location: lon=$longitudeDeg lat=$latitudeDeg tz=$timezone');
  stdout.writeln('years: $startYear..$endYear');
  stdout.writeln('total_days: $total');
  stdout.writeln('avg_diff_seconds: ${avg.toStringAsFixed(6)}');
  stdout.writeln('max_diff_seconds: ${maxDiff.toStringAsFixed(6)}');
  stdout.writeln('exact_second: $exact');
  stdout.writeln('lt_1s: $lt1');
  stdout.writeln('lt_4s: $lt4');
  stdout.writeln('gt_4s: $gt4');
  stdout.writeln('day_count_mismatch: ${yearCountMismatch.length}');
  stdout.writeln('');
  stdout.writeln('sample_years:');
  final samples = _sampleYears(startYear, endYear, 3);
  for (final year in samples) {
    final idx = year - startYear;
    final jsList = jsDays[idx];
    final dartList = _collectYearSolarNoonSeconds(year, location, timezone);
    stdout.writeln('year: $year');
    for (var i = 0; i < min(jsList.length, min(dartList.length, 6)); i++) {
      final diff = (dartList[i] - jsList[i]).abs();
      final wrapped = diff > 43200 ? 86400 - diff : diff;
      stdout.writeln(
        '  day:$i | js:${jsList[i]} | spa:${dartList[i]} | ${wrapped}s',
      );
    }
  }
}
