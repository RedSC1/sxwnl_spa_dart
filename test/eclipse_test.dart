import 'package:sxwnl_spa_dart/sxwnl_spa_dart.dart';
import 'package:sxwnl_spa_dart/src/sxwnl/delta_t.dart';
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

    test('rsPL.secMax keeps original local total-eclipse contacts', () {
      // Reykjavík, 2026-08-12 total solar eclipse. Inputs are radians / km.
      rsPL.secMax(
        9719.5,
        -21.94 * 3.141592653589793 / 180,
        64.15 * 3.141592653589793 / 180,
        0,
      );

      expect(rsPL.LX, '全');
      expect(rsPL.sT[0], closeTo(9720.200267634398, 1e-7));
      expect(rsPL.sT[1], closeTo(9720.243021296714, 1e-7));
      expect(rsPL.sT[2], closeTo(9720.283894982804, 1e-7));
      expect(rsPL.sT[3], closeTo(9720.242642616087, 1e-7));
      expect(rsPL.sT[4], closeTo(9720.243397911465, 1e-7));
      expect(rsPL.sf, closeTo(1.0023036377048065, 1e-8));
      expect(rsPL.dur, closeTo(.000755295377530274, 1e-8));
      expect(rsPL.P1, closeTo(5.203423026330999, 1e-8));
      expect(rsPL.V2, closeTo(1.6129579828094092, 1e-8));
      // sT is TT, but the source-compatible sun_s/sun_j fields are UT.
      expect(rsPL.sun_s, closeTo(9719.714850370961, 1e-7));
      expect(rsPL.sun_j, closeTo(9720.412456485145, 1e-7));
    });

    test('rsPL uses the original NASA lunar-radius ratio', () {
      addTearDown(() => rsPL.nasa_r = 0);
      rsPL.nasa_r = 1;
      // Salem, Oregon, 2017-08-21 total solar eclipse.
      rsPL.secMax(
        6450.5,
        -123.0262 * 3.141592653589793 / 180,
        44.9429 * 3.141592653589793 / 180,
        0,
      );

      expect(rsPL.LX, '全');
      expect(rsPL.b1, closeTo(1.026574020633769, 1e-8));
      expect(rsPL.sT[3], closeTo(6442.22118068683, 1e-7));
      expect(rsPL.sT[4], closeTo(6442.222499303724, 1e-7));
    });

    test('rsPL retains contacts during polar day', () {
      // The 2026 eclipse is visible from high Arctic locations in polar day.
      rsPL.secMax(9719.5, 0, 80 * 3.141592653589793 / 180, 0);

      expect(rsPL.sun_s, 0);
      expect(rsPL.sun_j, 0);
      expect(rsPL.LX, isNotEmpty);
      expect(rsPL.sT[1], greaterThan(9000));
    });

    test(
      'rsPL does not overwrite a caller-managed rsGS interpolation table',
      () {
        rsGS.init(9719.5, 7);
        final originalZjd = rsGS.Zjd;
        final originalFeature = rsGS.feature(9719.5).jd;

        rsPL.secMax(9543.5, 0, 0, 0);

        expect(rsGS.Zjd, originalZjd);
        expect(rsGS.feature(9719.5).jd, closeTo(originalFeature, 1e-12));
      },
    );

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

  group('sxwnl planetary port', () {
    test('daJu keeps the original Mercury and Venus elongations', () {
      final mercuryEast = daJu(Planet.mercury, .26, true);
      final mercuryWest = daJu(Planet.mercury, .26, false);
      final venusEast = daJu(Planet.venus, .26, true);
      final venusWest = daJu(Planet.venus, .26, false);

      expect(mercuryEast.t, closeTo(.261361704930167, 1e-12));
      expect(mercuryEast.angle, closeTo(.316295744039011, 1e-12));
      expect(mercuryWest.t, closeTo(.2593395248536746, 1e-12));
      expect(mercuryWest.angle, closeTo(.3617948249875342, 1e-12));
      expect(venusEast.t, closeTo(.2661947487037865, 1e-12));
      expect(venusEast.angle, closeTo(.8009382678168715, 1e-12));
      expect(venusWest.t, closeTo(.2541447330515345, 1e-12));
      expect(venusWest.angle, closeTo(.8008395489121569, 1e-12));
    });

    test(
      'stationary, lunar-conjunction, and opposition events keep sxwnl values',
      () {
        expect(
          xingLiu(Planet.mercury, .26, true),
          closeTo(.2591139560045104, 1e-10),
        );
        expect(
          xingLiu(Planet.mercury, .26, false),
          closeTo(.25857560968230875, 1e-10),
        );
        expect(
          xingLiu(Planet.jupiter, .26, true),
          closeTo(.25862645897578346, 1e-10),
        );

        final lunarConjunction = xingHY(Planet.venus, .26);
        expect(lunarConjunction[0], closeTo(.2596633019180439, 1e-10));
        expect(lunarConjunction[1], closeTo(-.08507993640332062, 1e-10));

        final opposition = xingHR(Planet.jupiter, .26, true);
        expect(opposition[0], closeTo(.2602563570552122, 1e-10));
        expect(opposition[1], closeTo(.0045604130455663165, 1e-10));
      },
    );

    test(
      'h2g keeps original longitude normalization and rejects Earth xingHY',
      () {
        final geocentric = h2g([0, 0, 1], [3.141592653589793 / 2, 0, 1]);
        expect(geocentric[0], closeTo(7 * 3.141592653589793 / 4, 1e-12));
        expect(geocentric[2], closeTo(1.4142135623730951, 1e-12));
        expect(() => xingHY(Planet.earth, .26), throwsA(isA<ArgumentError>()));
      },
    );

    test('pCoord ports the original Pluto XL0Pluto/P03 position', () {
      final j2000 = pCoord(Planet.pluto, 0, -1, -1, -1);
      final t026 = pCoord(Planet.pluto, .26, 10, 10, 10);

      expect(j2000[0], closeTo(4.372856668464477, 1e-12));
      expect(j2000[1], closeTo(.19480427171780515, 1e-12));
      expect(j2000[2], closeTo(30.22324455021225, 1e-12));
      expect(t026[0], closeTo(5.294013982349257, 1e-12));
      expect(t026[1], closeTo(-.0675019681346099, 1e-12));
      expect(t026[2], closeTo(35.42131186535351, 1e-12));
      expect(
        () => xingLiu(Planet.pluto, .26, true),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => xingHR(Planet.pluto, .26, true),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('2003 Mars opposition agrees with the SEDS external oracle', () {
      // SEDS Mars 2003: 2003-08-28 17:58:49 UTC (JD 2452880.249178241).
      // This is also the external reference used by taiyin-ephemeris.
      const sedsUtc = 2452880.249178241;
      final initialT = (sedsUtc - 2451545 + dtT(sedsUtc - 2451545)) / 36525;
      final event = xingHR(Planet.mars, initialT, true);

      // First preserve the sxwnl port itself; xingHR returns TT centuries.
      expect(event[0], closeTo(.03655715053394121, 1e-10));

      // Then compare on the civil-time scale used by the external reference.
      final sxwnlUtc = event[0] * 36525 + 2451545 - dtT(event[0] * 36525);
      expect((sxwnlUtc - sedsUtc) * 86400, closeTo(-.23, .1));
    });
  });
}
