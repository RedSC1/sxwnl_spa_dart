import 'package:sxwnl_spa_dart/sxwnl_spa_dart.dart';

void main() {
  final date = AstroDateTime(2026, 3, 4, 12, 0, 0);
  final loc = Location(116.3833, 39.9);

  print('=== comparing true solar time calculation engines ===\n');

  final resSpa = calcTrueSolarTime(date, loc, method: SolarCalcMethod.spa);
  print('[1] SPA Engine:');
  print('    Solar Noon:   ${resSpa.solarNoon}');
  print('    Sunrise:      ${resSpa.sunrise}');
  print('    Sunset:       ${resSpa.sunset}');
  print('    EoT:          ${resSpa.equationOfTime}');

  print('\n----------------------------------------\n');

  final resSxwnl = calcTrueSolarTime(date, loc, method: SolarCalcMethod.sxwnl);
  print('[2] SXWNL Engine (VSOP87):');
  print('    Solar Noon:   ${resSxwnl.solarNoon}');
  print('    Sunrise:      ${resSxwnl.sunrise}');
  print('    Sunset:       ${resSxwnl.sunset}');
  print('    EoT:          ${resSxwnl.equationOfTime}');
}
