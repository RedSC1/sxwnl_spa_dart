import '../lib/src/sxwnl/szj.dart';
import '../lib/src/location.dart';
import '../lib/src/astro_date_time.dart';
import '../lib/src/sxwnl/true_solar_time.dart';

void main() {
  print('Running SZJ Debug');
  // dt is implicitly used to calculate utcTime in earlier code block if needed
  // Currently just demonstration for comments

  // We want Beijing noon (04:00 UTC) on March 4th.
  // To get SZJ to target March 4th noon, we pass 04:00 UTC of March 4th!
  var jd = AstroDateTime(2026, 3, 4, 4, 0, 0).toJ2000(); // UTC 04:00

  var szj = SZJ();
  szj.L = 116.4 / 180 * 3.14159265; // Beijing Longitude
  szj.fa = 39.9 / 180 * 3.14159265; // Beijing Latitude

  var sunRes = szj.st(jd);

  var dtBeijingNoon = AstroDateTime(2026, 3, 4, 12, 0, 0); // Beijingnoon
  var trueSolar = calcTrueSolarTime(
    dtBeijingNoon,
    Location(116.4, 39.9),
    timezone: 8.0,
  );

  var spaTransitLocal = trueSolar.solarNoon;
  var spaTransitFraction =
      spaTransitLocal.hour / 24.0 +
      spaTransitLocal.minute / 1440.0 +
      spaTransitLocal.second / 86400.0;

  // sunRes.z is J2000.0 (noon-based).
  // +0.5 shifts to midnight-based, +8.0/24.0 shifts to Beijing time.
  double zLocalDecimalStr = (sunRes.z + 0.5 + 8.0 / 24.0) % 1.0;

  print('SPA Transit Local Fraction: ' + spaTransitFraction.toString());
  print('SZJ Transit Local Fraction: ' + zLocalDecimalStr.toString());

  // Diff already printed

  print('SZJ Raw z: ' + sunRes.z.toString());
  print('SZJ Raw jd: ' + jd.toString());
}
