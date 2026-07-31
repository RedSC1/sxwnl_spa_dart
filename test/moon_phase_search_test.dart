import 'package:sxwnl_spa_dart/sxwnl_spa_dart.dart';
import 'package:test/test.dart';

void main() {
  group('moon phase search', () {
    test(
      'returns all four principal phases for a year in chronological order',
      () {
        final phases = getYearMoonPhases(2026);

        // 2026 年有 12 个朔、12 个上弦、13 个望和 13 个下弦。
        expect(phases, hasLength(50));
        expect(phases.where((p) => p.name == '朔'), hasLength(12));
        expect(phases.where((p) => p.name == '上弦'), hasLength(12));
        expect(phases.where((p) => p.name == '望'), hasLength(13));
        expect(phases.where((p) => p.name == '下弦'), hasLength(13));

        for (var i = 1; i < phases.length; i++) {
          expect(phases[i].jd, greaterThan(phases[i - 1].jd));
          expect(phases[i].dateTime.timeZone, 8.0);
        }

        expect(phases.first.name, '望');
        expect(phases.first.dateTime, _sameMinute(2026, 1, 3, 18, 2));
        expect(phases.last.name, '下弦');
        expect(phases.last.dateTime, _sameMinute(2026, 12, 31, 2, 59));
      },
    );

    test('supports a half-open date range and eight-phase mode', () {
      final january = getMoonPhases(
        AstroDateTime(2026, 1, 1),
        AstroDateTime(2026, 2, 1),
      );
      expect(january, hasLength(4));
      expect(january.first.dateTime.day, 3);
      expect(january.last.dateTime.day, 26);

      final phases8 = getYearMoonPhases(2026, use8Phases: true);
      // 年初和年末的半月相分别落在范围外，因此是 99 个节点。
      expect(phases8, hasLength(99));
      expect(phases8.first.name, '望');
      expect(phases8[1].name, '亏凸月');
      expect(phases8[2].name, '下弦');
      expect(phases8[3].name, '残月');
      expect(phases8[4].name, '朔');
    });

    test('daily lookup remains compatible with the range search', () {
      final daily = AstroEvents.getMoonPhase(AstroDateTime(2026, 1, 19, 12));
      final range = getMoonPhases(
        AstroDateTime(2026, 1, 19),
        AstroDateTime(2026, 1, 20),
      );

      expect(daily, isNotNull);
      expect(daily!.name, '朔');
      expect(range, hasLength(1));
      expect(daily.jd, closeTo(range.single.jd, 1e-12));
    });
  });
}

Matcher _sameMinute(int year, int month, int day, int hour, int minute) {
  return predicate<AstroDateTime>(
    (actual) =>
        actual.year == year &&
        actual.month == month &&
        actual.day == day &&
        actual.hour == hour &&
        actual.minute == minute,
    'a Beijing time matching $year-$month-$day $hour:$minute',
  );
}
