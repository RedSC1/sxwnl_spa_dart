import 'dart:math' as math;

import 'package:sxwnl_spa_dart/sxwnl_spa_dart.dart';
import 'package:test/test.dart';

void main() {
  test('low-level sxwnl helpers are reachable from the package entrypoint', () {
    final xyz = llr2xyz([0, 0, 1]);
    expect(xyz, orderedCloseTo([1, 0, 0], 1e-15));
    expect(xyz2llr(xyz), orderedCloseTo([0, 0, 1], 1e-15));

    final horizon = CD2DP([0, 0, 1], 0, 0, 0);
    expect(horizon, hasLength(3));
    expect(horizon.every((value) => value.isFinite), isTrue);
    expect(j1_j2(0, 0, 0, 0), closeTo(0, 1e-15));
    expect(MQC(math.pi / 4), greaterThan(0));
    expect(MQC2(math.pi / 4), lessThan(0));

    final body = [0.1, 0.2, 1.0];
    parallax(body, 0.3, 0.4, 0);
    expect(body.every((value) => value.isFinite), isTrue);
    expect(shiChaJ(0.2, 0.3, 0.4, 0.1, 0.2), inInclusiveRange(0, pi2));
    expect(
      sunShengJ(9500, 116 * math.pi / 180, 40 * math.pi / 180, -1),
      greaterThanOrEqualTo(0),
    );

    expect(nutation(0, 0), hasLength(2));
    expect(CDnutation([0.1, 0.2, 1], 0.4, 1e-5, 2e-5), hasLength(3));
    expect(pGST2(0), isA<double>());
    expect(dtT(0), greaterThan(0));
    expect(preceP03(0, 4), closeTo(84381.406 / rad, 1e-15));
    expect(sALonT2(0), isA<double>());
    expect(ptyZty(0), closeTo(-0.0022784199179502218, 1e-12));
    expect(ptyZty2(0), closeTo(-0.0022845033527827113, 1e-12));
    expect(pty_zty(0), closeTo(ptyZty(0), 1e-15));
    expect(pty_zty2(0), closeTo(ptyZty2(0), 1e-15));

    final lowLevelPlanet = xingLiu0(Planet.mars, 0.24, 8, 0);
    expect(lowLevelPlanet, hasLength(3));
    expect(lowLevelPlanet.every((value) => value.isFinite), isTrue);
    final lunarPlanet = xingMP(Planet.mars, 0.24, 8, .4091, [0, 0, 0, 0]);
    expect(lunarPlanet, hasLength(4));
    final solarPlanet = xingSP(Planet.mars, 0.24, 8, 0, 0, 0);
    expect(solarPlanet, hasLength(4));
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
