import 'package:test/test.dart';
import 'package:sxwnl_spa_dart/sxwnl_spa_dart.dart';

void main() {
  test('ephB star tables are mechanically extracted and parse like sxwnl', () {
    final stars = getHXK(HXK[0]);
    expect(stars, hasLength(20));
    expect(stars.first.name, '星1630');
    expect(stars.first.metadata, 'Psc 30 M3');
    expect(stars.first.magnitude, closeTo(4.37, 1e-12));
    expect(stars.first.rightAscension, closeTo(0.008553567775815544, 1e-15));
    expect(stars.first.declination, closeTo(-0.10496545869324608, 1e-15));

    final lyra = getConstellations().firstWhere(
      (item) => item.abbreviation == 'Lyr',
    );
    expect(lyra.name, '天琴座');
    expect(lyra.areaSquareDegrees, closeTo(286.476, 1e-12));
  });

  test('ephB apparent star position matches original hxCalc chain', () {
    final star = getHXK(HXK[0]).first;
    final position = calcStarPositions(0, [star]).single;
    expect(position.first, closeTo(0.008472650550734295, 1e-14));
    expect(position.second, closeTo(-0.10501022537981308, 1e-14));
    expect(position.distanceAu, closeTo(25783100.78088704, 1e-6));
  });

  test(
    'ephB topocentric and mean modes expose the original coordinate stages',
    () {
      final star = getHXK(HXK[0]).first;
      final mean = calcStarPositions(0, [
        star,
      ], mode: StarCoordinateMode.mean).single;
      final topocentric = calcStarPositions(
        0,
        [star],
        mode: StarCoordinateMode.topocentric,
        longitude: 116 * 3.141592653589793 / 180,
        latitude: 40 * 3.141592653589793 / 180,
      ).single;
      expect(mean.first, closeTo(0.008553567775815544, 1e-15));
      expect(mean.second, closeTo(-0.10496545869324608, 1e-15));
      expect(topocentric.mode, StarCoordinateMode.topocentric);
      expect(topocentric.azimuth, inInclusiveRange(0, 2 * 3.141592653589793));
      expect(
        topocentric.altitude,
        inInclusiveRange(-3.141592653589793 / 2, 3.141592653589793 / 2),
      );
    },
  );

  test('remaining XL planetary events match the original eph0 helpers', () {
    expect(moonIll(0), closeTo(0.22923807634303117, 1e-15));
    expect(moonRad(384400, .2), closeTo(935.71805876286, 1e-10));
    expect(
      moonMinR(0, true),
      orderedCloseTo([-.0002750093924352198, 356653.6854581151], 1e-10),
    );
    expect(
      moonMinR(0, false),
      orderedCloseTo([.00008257673507956666, 406417.98280435917], 1e-10),
    );
    expect(
      moonNode(0, true),
      orderedCloseTo([-.0002065136678077557, 2.16349127265736], 1e-10),
    );
    expect(
      earthMinR(0, true),
      orderedCloseTo([.000047111075354180425, .9833213890592591], 1e-10),
    );
  });

  test('SZJ.calcRTS matches the original multi-day wrapper', () {
    final szj = SZJ();
    final days = szj.calcRTS(
      9500,
      2,
      116.3833 * 3.141592653589793 / 180,
      39.9 * 3.141592653589793 / 180,
      8,
    );
    expect(days, hasLength(2));
    expect(days[0].s, '15:36:14');
    expect(days[0].z, '20:19:43');
    expect(days[0].j, '01:03:23');
    expect(days[0].Ms, '01:54:03');
    expect(days[0].Mz, '09:38:43');
    expect(days[0].Mj, '17:11:03');
    expect(days[1].s, '15:36:13');
    expect(days[1].Mz, '10:33:57');
  });

  test('xingX structured positions match the original eph.js chain', () {
    const lon = 116.3833 * 3.141592653589793 / 180;
    const lat = 39.9 * 3.141592653589793 / 180;
    final jupiter = xingXPosition(4, 9500, lon, lat);
    expect(
      jupiter.heliocentricEcliptic![0],
      closeTo(14.479600257112768, 1e-14),
    );
    expect(jupiter.apparentEcliptic[0], closeTo(1.9354980823586243, 1e-14));
    expect(jupiter.apparentEquatorial[0], closeTo(1.965828691022156, 1e-14));
    expect(jupiter.geocentricDistance, closeTo(4.235406145956073, 1e-14));
    expect(jupiter.lightDistance, closeTo(4.2353931810880745, 1e-14));
    expect(jupiter.visualDistance, closeTo(4.235443693451683, 1e-14));
    expect(jupiter.horizontal[0], closeTo(1.4484733917594301, 1e-11));
    expect(jupiter.horizontal[1], closeTo(0.47358255561874724, 1e-11));
    final moon = xingXPosition(10, 9500, lon, lat);
    expect(moon.apparentEcliptic[0], closeTo(2.0759743333819642, 1e-14));
    expect(moon.apparentEquatorial[0], closeTo(2.1264462522079226, 1e-12));
    expect(moon.geocentricDistance, closeTo(366009.08624007454, 1e-8));
    expect(moon.lightDistance, closeTo(365999.5904727084, 1e-8));
    expect(moon.visualDistance, closeTo(366009.02683804405, 1e-8));
    expect(xingX(4, 9500, lon, lat), contains('视赤经'));
  });
}

Matcher orderedCloseTo(List<double> expected, double absolute) =>
    predicate<List<double>>((actual) {
      if (actual.length != expected.length) return false;
      for (var i = 0; i < expected.length; i++) {
        if ((actual[i] - expected[i]).abs() > absolute) return false;
      }
      return true;
    });
