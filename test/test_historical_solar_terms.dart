import 'package:sxwnl_spa_dart/src/astro_date_time.dart';
import 'package:sxwnl_spa_dart/src/models/calendar.dart';
import 'package:test/test.dart';

void main() {
  test('Historical Solar terms toggle test', () {
    bool foundDifference = false;

    // Scan years starting from 1645 (when the SSQ table starts having offsets)
    for (int year = 1645; year <= 1700; year++) {
      for (int month = 1; month <= 12; month++) {
        final daysHistorical = getSolarMonthDays(
          year,
          month,
          useHistoricalSolarTerms: true,
        );
        final daysModern = getSolarMonthDays(
          year,
          month,
          useHistoricalSolarTerms: false,
        );

        for (int i = 0; i < daysHistorical.length; i++) {
          if (daysHistorical[i].solarTerm != daysModern[i].solarTerm) {
            foundDifference = true;
            print('--- FOUND DIFFERENCE ---');
            print('Year/Month: $year-$month');
            print('Historical Day ${i + 1}: ${daysHistorical[i].solarTerm}');
            print('Modern Day ${i + 1}: ${daysModern[i].solarTerm}');
            // We found one, test is successful!
            break;
          }
        }
        if (foundDifference) break;
      }
      if (foundDifference) break;
    }

    expect(
      foundDifference,
      true,
      reason:
          'Expected to find at least one solar term difference between 1645 and 1700',
    );
  });
}
