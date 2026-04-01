import 'package:test/test.dart';
import 'package:sxwnl_spa_dart/src/sxwnl/szj.dart';
import 'package:sxwnl_spa_dart/src/location.dart';
import 'package:sxwnl_spa_dart/src/astro_date_time.dart';
import 'package:sxwnl_spa_dart/src/sxwnl/true_solar_time.dart';

void main() {
  group('SZJ Math Verification', () {
    test('Sun and Moon Rise events calculation', () {
      // 2026-03-04 12:00 Beijing Time
      var dt = AstroDateTime(2026, 3, 4, 12, 0, 0);

      // Calculate standard JD for noon UTC (approx jd)
      dt.subtract(Duration(hours: 8));

      // For Beijing local events on March 4th 2026, target the local noon UTC equivalent (04:00 UTC)
      var jd = AstroDateTime(2026, 3, 4, 4, 0, 0).toJ2000();

      var szj = SZJ();
      szj.L = 116.4 / 180 * 3.14159265; // Beijing Longitude
      szj.fa = 39.9 / 180 * 3.14159265; // Beijing Latitude

      var sunRes = szj.st(jd);
      var moonRes = szj.mt(jd);

      print('--- Sun Events ---');
      print('Rise: \${sunRes.s + 0.5}');
      print('Transit: \${sunRes.z + 0.5}');
      print('Set: \${sunRes.j + 0.5}');
      print('Civil Twilight Morning: \${sunRes.c + 0.5}');
      print('Civil Twilight Evening: \${sunRes.h + 0.5}');

      print('--- Moon Events ---');
      print('Rise: \${moonRes.s + 0.5}');
      print('Transit: \${moonRes.z + 0.5}');
      print('Set: \${moonRes.j + 0.5}');

      // Note: Because jd represents Noon UT, +0.5 shifts the fraction to local time day start
      // where integer jd+0.5 is midnight.

      expect(sunRes.s, isNotNull);
      expect(moonRes.s, isNotNull);

      // Compare sun transit with SPA calculations
      var dtBeijing20260304Noon = AstroDateTime(
        2026,
        3,
        4,
        12,
        0,
        0,
      ); // Beijingnoon
      var trueSolar = calcTrueSolarTime(
        dtBeijing20260304Noon,
        Location.beijing,
        timezone: 8.0,
      );

      var spaTransitLocal = trueSolar.solarNoon;
      // Convert SPA local time back to fraction of day
      var spaTransitFraction =
          spaTransitLocal.hour / 24.0 +
          spaTransitLocal.minute / 1440.0 +
          spaTransitLocal.second / 86400.0;

      // SZJ raw Z operates on internally calculated relative fractional JD noon/midnight bounds.
      // UTC 0 + 0.5 + 8.0 / 24.0 transforms Z offset back into Beijing Local Fractional time.
      double zLocalDecimalStr = (sunRes.z + 0.5 + 8.0 / 24.0) % 1.0;

      print('SPA Transit Local Fraction: \$spaTransitFraction');
      print('SZJ Transit Local Fraction: \$zLocalDecimalStr');
      double diff = (spaTransitFraction - zLocalDecimalStr).abs();
      print('Diff in days: \$diff');
      // SPA error threshold to 0.001 days (under a minute) since pGST is now highly accurate.
      expect(diff < 0.001, isTrue, reason: "SPA and SZJ should be close");
    });
  });
}
