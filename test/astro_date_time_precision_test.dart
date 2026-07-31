import 'package:sxwnl_spa_dart/sxwnl_spa_dart.dart';
import 'package:test/test.dart';

void main() {
  group('AstroDateTime fractional seconds', () {
    test('preserves fractional seconds through Julian Day conversion', () {
      final original = AstroDateTime(2025, 1, 1, 12, 34, 56, 0.789);
      final roundTrip = AstroDateTime.fromJulianDay(original.toJulianDay());
      final j2000RoundTrip = AstroDateTime.fromJ2000(original.toJ2000());

      expect(roundTrip.year, original.year);
      expect(roundTrip.month, original.month);
      expect(roundTrip.day, original.day);
      expect(roundTrip.hour, original.hour);
      expect(roundTrip.minute, original.minute);
      expect(roundTrip.second, original.second);
      expect(roundTrip.preciseSecond, closeTo(original.preciseSecond, 1e-4));
      expect(roundTrip.toJulianDay(), closeTo(original.toJulianDay(), 1e-9));
      expect(j2000RoundTrip.preciseSecond, closeTo(56.789, 1e-4));
      expect(
        j2000RoundTrip.toJulianDay(),
        closeTo(original.toJulianDay(), 1e-9),
      );
    });

    test('keeps raw and standard-timezone factories distinct', () {
      final utc = AstroDateTime(2025, 1, 1, 0, 0, 0, 0.5);
      final utcJ2000 = utc.toJ2000();
      final local = AstroDateTime.fromStdJ2000(utcJ2000, timeZone: 8);

      expect(AstroDateTime.fromJ2000(utcJ2000).timeZone, isNull);
      expect(AstroDateTime.fromJulianDay(utc.toJulianDay()).timeZone, isNull);
      expect(AstroDateTime.fromStdJ2000(utcJ2000).timeZone, 0.0);
      expect(local.timeZone, 8.0);
      expect(local.year, 2025);
      expect(local.month, 1);
      expect(local.day, 1);
      expect(local.hour, 8);
      expect(local.minute, 0);
      expect(local.second, 0);
      expect(local.fractionalSecond, closeTo(0.5, 1e-4));
    });

    test('fromBJJ2000 does not apply a second Beijing timezone shift', () {
      final beijing = AstroDateTime(2025, 1, 1, 8, 0, 0, 0.5);
      final parsed = AstroDateTime.fromBJJ2000(beijing.toJ2000());
      final parsedAbsolute = AstroDateTime.fromBJJulianDay(
        beijing.toJulianDay(),
      );

      expect(parsed.year, beijing.year);
      expect(parsed.month, beijing.month);
      expect(parsed.day, beijing.day);
      expect(parsed.hour, beijing.hour);
      expect(parsed.fractionalSecond, closeTo(0.5, 1e-4));
      expect(parsedAbsolute.timeZone, 8.0);
      expect(parsed.toStdJ2000(), closeTo(beijing.toJ2000() - 8 / 24, 1e-9));
      expect(
        parsedAbsolute.toStdJulianDay(),
        closeTo(beijing.toJulianDay() - 8 / 24, 1e-9),
      );
    });

    test('preserves microseconds when converting to and from DateTime', () {
      final dateTime = DateTime.utc(2025, 1, 1, 12, 34, 56, 123, 456);
      final astro = AstroDateTime.fromDateTime(dateTime);
      final roundTrip = astro.toDateTime();

      expect(astro.fractionalSecond, closeTo(0.123456, 1e-12));
      expect(astro.timeZone, isNull);
      expect(roundTrip, isNotNull);
      expect(roundTrip!.year, dateTime.year);
      expect(roundTrip.month, dateTime.month);
      expect(roundTrip.day, dateTime.day);
      expect(roundTrip.hour, dateTime.hour);
      expect(roundTrip.minute, dateTime.minute);
      expect(roundTrip.second, dateTime.second);
      expect(roundTrip.microsecond, dateTime.microsecond);
      expect(roundTrip.millisecond, dateTime.millisecond);
    });

    test('add, subtract, and difference retain sub-second durations', () {
      final start = AstroDateTime(2025, 1, 1, 23, 59, 59, 0.125);
      final duration = const Duration(microseconds: 1_125_000);
      final end = start.add(duration);

      expect(end.year, 2025);
      expect(end.month, 1);
      expect(end.day, 2);
      expect(end.hour, 0);
      expect(end.minute, 0);
      expect(end.second, 0);
      expect(end.fractionalSecond, closeTo(0.25, 1e-4));
      expect(end.difference(start).inMicroseconds, closeTo(1_125_000, 200));
      expect(
        end.subtract(duration).difference(start).inMicroseconds.abs(),
        lessThan(200),
      );
    });

    test('keeps the old integer-second display by default', () {
      final value = AstroDateTime(2025, 1, 1, 12, 34, 56, 0.789);

      expect(value.toTimeString(), '12:34:56');
      expect(value.toTimeString(fractionDigits: 6), '12:34:56.789');
      expect(value.toString(), '2025-01-01 12:34:56.789');
      expect(
        AstroDateTime(2025, 1, 1, 12, 34, 56).toString(),
        '2025-01-01 12:34:56',
      );
    });
  });
}
