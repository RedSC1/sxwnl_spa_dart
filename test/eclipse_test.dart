import 'package:sxwnl_spa_dart/sxwnl_spa_dart.dart';
import 'package:test/test.dart';

void main() {
  group('sxwnl eclipse port', () {
    test('ysPL.lecMax keeps the original J2000 TT lunar-eclipse result', () {
      ysPL.lecMax(9203.5); // 2025-03-14 near the total lunar eclipse.

      expect(ysPL.LX, '全');
      expect(ysPL.sf, closeTo(1.1828107517800281, 1e-8));
      expect(ysPL.lT, hasLength(7));
      expect(ysPL.lT[0], closeTo(9203.715610745487, 1e-7));
      expect(ysPL.lT[1], closeTo(9203.79162146142, 1e-7));
      expect(ysPL.lT[2], closeTo(9203.867607655653, 1e-7));
      expect(ysPL.lT[5], closeTo(9203.768590337877, 1e-7));
      expect(ysPL.lT[6], closeTo(9203.814634560274, 1e-7));
    });

    test('ecFast preserves the original eclipse classification', () {
      final result = ecFast(9719.5); // 2026-08-12 near a total solar eclipse.

      expect(result.lx, 'T');
      expect(result.ac, 1);
      expect(result.jdSuo, closeTo(9720.23401422019, 1e-8));
      expect(result.jd, result.jdSuo);
    });

    test('ecFast keeps the original annular eclipse classification', () {
      final result = ecFast(
        9543.5,
      ); // 2026-02-17 near an annular solar eclipse.

      expect(result.lx, 'A');
      expect(result.ac, 0);
      expect(result.jdSuo, closeTo(9543.9993147274, 1e-8));
    });

    test('msc keeps the original solar and lunar horizontal coordinates', () {
      msc.calc(
        9203.5,
        116.4 * 3.141592653589793 / 180,
        39.9 * 3.141592653589793 / 180,
        .05,
      );

      expect(msc.mDJ, closeTo(5.080294119961927, 1e-10));
      expect(msc.mDW, closeTo(-.3118640454624751, 1e-10));
      expect(msc.mPJ, closeTo(5.080294119961927, 1e-10));
      expect(msc.mPW, closeTo(-.3118640454624751, 1e-10));
      expect(msc.sDJ, closeTo(1.8803719744526024, 1e-10));
      expect(msc.sDW, closeTo(.28493110855189174, 1e-10));
      expect(msc.sPJ, closeTo(1.8803719744526024, 1e-10));
      expect(msc.sPW, closeTo(.2859134590654813, 1e-10));
      expect(msc.sCJ2, closeTo(6.181538709527393, 1e-10));
      expect(msc.sCW2, closeTo(-.0440052048745766, 1e-10));
      expect(msc.mIll, closeTo(.9991329560302329, 1e-10));
    });

    test('rsGS.feature keeps sxwnl global eclipse characteristics', () {
      rsGS.init(9719.5, 7); // 2026-08-12 total solar eclipse.
      final result = rsGS.feature(9719.5);

      expect(rsGS.Zjd, closeTo(9720.234924486316, 1e-8));
      expect(result.lx, 'T');
      expect(result.jd, closeTo(9720.24103126692, 1e-7));
      expect(result.zxJ, closeTo(-.44061165494877486, 1e-7));
      expect(result.zxW, closeTo(1.1384233571550517, 1e-7));
      expect(result.sf, closeTo(1.0386370162302527, 1e-7));
      expect(result.dw, closeTo(298.00264568454094, 1e-4));
      expect(result.tt, closeTo(.0016033124655390615, 1e-8));
    });

    test('rsGS.jieX generates the original centerline and limits', () {
      rsGS.init(9719.5, 7); // 2026-08-12 total solar eclipse.
      final result = rsGS.jieX(9719.5);

      expect(result.L0, hasLength(224));
      expect(result.L3, hasLength(216));
      expect(result.L4, hasLength(234));
      expect(result.L2, hasLength(502));
      expect(result.L6, hasLength(410));
      expect(result.L0.first, closeTo(1.9808243286262908, 1e-7));
      expect(result.L0[1], closeTo(1.3120089908749715, 1e-7));
      expect(
        result.L0[result.L0.length - 2],
        closeTo(.09296145675234158, 1e-7),
      );
      expect(result.L3.first, closeTo(1.8973368044045813, 1e-7));
      expect(result.L4.first, closeTo(2.059878677641059, 1e-7));
    });

    test('rsGS unwraps sidereal time across 2π before interpolation', () {
      // 2006-03-29 total eclipse: the 7-point GST samples cross 2π.
      // This guards the original eph.js longitude continuity behavior.
      rsGS.init(2278.71, 7);
      final feature = rsGS.feature(2278.71);
      final limits = rsGS.jieX(2278.71);

      expect(feature.lx, 'T');
      expect(feature.gk2[0], closeTo(1.723766388954644, 1e-7));
      expect(feature.gk4[0], closeTo(1.4488076583684943, 1e-7));
      expect(limits.L0, hasLength(414));
      expect(
        limits.L0[limits.L0.length - 2],
        closeTo(1.7237665286039174, 1e-7),
      );
    });

    test('rsGS retains the original [100, 100] no-intersection sentinel', () {
      // 2003-11-23: no Earth intersection for the local-noon axis point.
      rsGS.init(1422.32, 7);
      final result = rsGS.feature(1422.32);

      expect(result.lx, 'T');
      expect(result.gk5[0], 100);
      expect(result.gk5[1], 100);
      expect(result.gk5[2], closeTo(1422.4731483885248, 1e-7));
    });

    test('matches the rounded 2025 PMO total-lunar-eclipse TD table', () {
      ysPL.lecMax(9380.5); // 2025-09-07 total lunar eclipse.
      const pmoTd = [
        2460926.144444444, // P1
        2460926.186041667, // U1
        2460926.230208333, // U2
        2460926.259027778, // Greatest
        2460926.287777778, // U3
        2460926.331944444, // U4
        2460926.373472222, // P4
      ];
      final actual = [
        ysPL.lT[3] + 2451545,
        ysPL.lT[0] + 2451545,
        ysPL.lT[5] + 2451545,
        ysPL.lT[1] + 2451545,
        ysPL.lT[6] + 2451545,
        ysPL.lT[2] + 2451545,
        ysPL.lT[4] + 2451545,
      ];
      for (var i = 0; i < actual.length; i++) {
        expect(actual[i], closeTo(pmoTd[i], 7 / 86400));
      }
    });

    test('matches the rounded 2026 PMO global-solar-eclipse summary', () {
      rsGS.init(9719.5, 7);
      final result = rsGS.feature(9719.5);

      const pmoUt = [
        2461265.148773148, // P1
        2461265.208402778, // C1
        2461265.240231481, // Greatest
        2461265.272361111, // C4
        2461265.331932870, // P4
      ];
      final actualUt = [
        result.gk3[2] + 2451545 - result.dT,
        result.gk1[2] + 2451545 - result.dT,
        result.jd + 2451545 - result.dT,
        result.gk2[2] + 2451545 - result.dT,
        result.gk4[2] + 2451545 - result.dT,
      ];
      for (var i = 0; i < actualUt.length; i++) {
        expect(actualUt[i], closeTo(pmoUt[i], 2 / 86400));
      }
      expect(
        result.jd + 2451545 - result.dT,
        closeTo(2461265.240231481, 2 / 86400),
      );
      expect(
        result.zxW * 180 / 3.141592653589793,
        closeTo(65 + 13.3 / 60, .02),
      );
      expect(
        result.zxJ * 180 / 3.141592653589793,
        closeTo(-(25 + 15.2 / 60), .02),
      );
      expect(result.sf, closeTo(1.040, .002));
      expect(result.tt * 86400, closeTo(141.2, 5));
      expect(result.dw, closeTo(300.3, 5));
    });
  });
}
