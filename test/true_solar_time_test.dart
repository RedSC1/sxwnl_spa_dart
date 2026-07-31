import 'package:sxwnl_spa_dart/sxwnl_spa_dart.dart';
import 'package:test/test.dart';

void main() {
  test('calcTrueSolarTime2 reads and preserves the AstroDateTime timezone', () {
    final localTime = AstroDateTime(2026, 3, 4, 12).withTimeZone(8.0);

    final legacy = calcTrueSolarTime(
      localTime,
      Location.beijing,
      timezone: 8.0,
      method: SolarCalcMethod.sxwnl,
    );
    final modern = calcTrueSolarTime2(
      localTime,
      Location.beijing,
      method: SolarCalcMethod.sxwnl,
    );

    expect(
      modern.trueSolarTime.toJ2000(),
      closeTo(legacy.trueSolarTime.toJ2000(), 1e-12),
    );
    expect(modern.trueSolarTime.timeZone, 8.0);
    expect(
      modern.solarNoon.toJ2000(),
      closeTo(legacy.solarNoon.toJ2000(), 1e-12),
    );
    expect(modern.solarNoon.timeZone, 8.0);
    expect(modern.sunrise, isNotNull);
    expect(legacy.sunrise, isNotNull);
    expect(
      modern.sunrise?.toJ2000(),
      closeTo(legacy.sunrise!.toJ2000(), 1e-12),
    );
    expect(modern.sunrise?.timeZone, 8.0);
    expect(modern.sunset, isNotNull);
    expect(legacy.sunset, isNotNull);
    expect(modern.sunset!.toJ2000(), closeTo(legacy.sunset!.toJ2000(), 1e-12));
    expect(modern.sunset?.timeZone, 8.0);
  });

  test('calcTrueSolarTime2 rejects an unmarked timezone', () {
    expect(
      () => calcTrueSolarTime2(AstroDateTime(2026, 3, 4, 12), Location.beijing),
      throwsArgumentError,
    );
  });
}
