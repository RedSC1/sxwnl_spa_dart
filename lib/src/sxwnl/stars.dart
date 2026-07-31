// ignore_for_file: non_constant_identifier_names

/// 寿星万年历可选恒星模块。
///
/// 移植自原版 `ephB.js`：恒星库、88 星座资料、周年视差/光行差、
/// 太阳引力偏折、岁差章动和站心坐标。恒星数据由
/// `tool/extract_ephb_stars.mjs` 机械提取，算法不依赖外部星历服务。
library;

export 'ephb_star_data.dart' show HXK, xz88;

import 'dart:math' as math;

import 'ephb_star_data.dart';
import 'math_utils.dart';
import 'nutation.dart';
import 'precession.dart';
import 'solar_lunar_pos.dart';

/// 恒星坐标模式，对应原版 `hxCalc` 的 `lx`。
enum StarCoordinateMode {
  /// 视赤经、视赤纬：包含岁差、章动、周年视差、光行差和太阳引力偏折。
  apparent,

  /// 站心坐标：在视位置基础上转换为方位角、高度角并加入固定折射。
  topocentric,

  /// 平赤经、平赤纬：只加入岁差，不加入章动和视差/光行差。
  mean,
}

/// 原版 HXK 的单条恒星记录。
class StarCatalogEntry {
  /// J2000 赤经，弧度。
  final double rightAscension;

  /// J2000 赤纬，弧度。
  final double declination;

  /// 赤经世纪自行，弧度/世纪。
  final double properMotionRa;

  /// 赤纬世纪自行，弧度/世纪。
  final double properMotionDec;

  /// 视差，弧度；无视差时为 0。
  final double parallax;

  /// 视星等。
  final double magnitude;

  /// 原始恒星名称/编号字段。
  final String name;

  /// 原始星座、拜耳编号及光谱字段。
  final String metadata;

  const StarCatalogEntry({
    required this.rightAscension,
    required this.declination,
    required this.properMotionRa,
    required this.properMotionDec,
    required this.parallax,
    required this.magnitude,
    required this.name,
    required this.metadata,
  });
}

/// 88 星座资料。
class Constellation {
  final String name;
  final String abbreviation;
  final double areaSquareDegrees;
  final double centerRightAscension;
  final double centerDeclination;
  final String quadrantFamily;
  final String englishName;

  const Constellation({
    required this.name,
    required this.abbreviation,
    required this.areaSquareDegrees,
    required this.centerRightAscension,
    required this.centerDeclination,
    required this.quadrantFamily,
    required this.englishName,
  });
}

/// 一条恒星的计算位置。
class StarPosition {
  final StarCatalogEntry star;
  final double first;
  final double second;
  final double distanceAu;
  final StarCoordinateMode mode;

  const StarPosition({
    required this.star,
    required this.first,
    required this.second,
    required this.distanceAu,
    required this.mode,
  });

  /// 视/平坐标模式下为赤经；站心模式下为方位角。
  double get rightAscension => first;

  /// 视/平坐标模式下为赤纬；站心模式下为高度角。
  double get declination => second;

  double get azimuth => first;
  double get altitude => second;
}

/// 解析寿星恒星库文本。
///
/// [source] 可以是 [HXK] 中的一个原始库字符串，也可以是
/// [schHXK] 返回的检索结果。默认只解析带 `*` 标记的恒星记录；传入
/// [all] 为 true 时也解析未标记记录。
List<StarCatalogEntry> getHXK(String source, [bool all = false]) {
  var text = source.replaceAll('\r', '').replaceAll('\n', '#');
  final first = text.indexOf('#');
  if (first >= 0) text = text.substring(first + 1);
  text = text.replaceAll(RegExp(r'#+'), ',').replaceAll(RegExp(r', +'), ',');
  final fields = text.split(',');
  final result = <StarCatalogEntry>[];
  for (var i = 0; i + 7 < fields.length; i += 8) {
    if (fields[i].length < 5) continue;
    final marked = fields[i].startsWith('*');
    if (!marked && !all) continue;
    final ra = fields[i].replaceFirst(RegExp(r'^\*'), '').trim();
    result.add(
      StarCatalogEntry(
        rightAscension: _sexagesimal(ra, hours: true),
        declination: _sexagesimal(fields[i + 1], hours: false),
        properMotionRa: double.parse(fields[i + 2]) / rad * 15,
        properMotionDec: double.parse(fields[i + 3]) / rad,
        parallax: double.parse(fields[i + 4]) / rad,
        magnitude: double.parse(fields[i + 5]),
        name: fields[i + 6].trim(),
        metadata: fields[i + 7].trim(),
      ),
    );
  }
  return result;
}

/// 按星座缩写检索恒星库，并附加该星座的中心记录。
///
/// 保留原版 `schHXK(key)` 的文本返回形式，便于直接交给 [getHXK]。
String schHXK(String key) {
  final result = StringBuffer();
  for (final block in HXK) {
    final records = block.split('#');
    for (final record in records.skip(1)) {
      if (record.contains(key)) result.write('#$record');
    }
  }
  for (var i = 0; i < xz88.length; i += 5) {
    final packed = xz88[i];
    final abbreviation = packed.substring(3, 6);
    if (abbreviation != key) continue;
    final centerRa = xz88[i + 2];
    final centerDec = xz88[i + 3];
    final ra =
        centerRa.substring(0, 5) +
        ' ${(double.parse(centerRa.substring(6, 8)) * .6).toStringAsFixed(1)}';
    final dec =
        centerDec.substring(0, 6) +
        ' ${(double.parse(centerDec.substring(7, 9)) * .6).toStringAsFixed(1)}';
    result.write(
      '#*$ra,$dec,0,0,0,0.0,中心${packed.substring(0, 6)}方,${xz88[i + 4]}',
    );
    break;
  }
  return result.toString();
}

/// 解析全部 88 星座资料。
List<Constellation> getConstellations() {
  return [
    for (var i = 0; i < xz88.length; i += 5)
      (() {
        final descriptor = xz88[i + 4].trim().split(RegExp(r'\s+'));
        return Constellation(
          name: xz88[i].substring(0, 3),
          abbreviation: xz88[i].substring(3, 6),
          areaSquareDegrees: double.parse(xz88[i + 1]),
          centerRightAscension: _sexagesimal(xz88[i + 2], hours: true),
          centerDeclination: _sexagesimal(xz88[i + 3], hours: false),
          quadrantFamily: descriptor.take(2).join(' '),
          englishName: descriptor.skip(2).join(' '),
        );
      })(),
  ];
}

/// 计算恒星视/平/站心位置。
List<StarPosition> calcStarPositions(
  double t,
  List<StarCatalogEntry> stars, {
  double zq = 0,
  StarCoordinateMode mode = StarCoordinateMode.apparent,
  double longitude = 0,
  double latitude = 0,
}) {
  final apparent = mode != StarCoordinateMode.mean;
  var dL = 0.0;
  var dE = 0.0;
  var gst = 0.0;
  List<double>? earthVelocity;
  List<double>? earthPosition;
  List<double>? sun;
  var E = hcjj(t);
  if (apparent) {
    final d = nutationFull(t, zq);
    dL = d[0];
    dE = d[1];
    earthVelocity = evSSB(t);
    earthPosition = epSSB(t);
    sun = llrConv(sun2000(t, 20), 84381.406 / rad);
    gst = pGST2(t * 36525) + dL * math.cos(E);
  }
  return [
    for (final star in stars)
      _calcStarPosition(
        t,
        star,
        mode,
        E,
        dL,
        dE,
        gst,
        earthVelocity,
        earthPosition,
        sun,
        longitude,
        latitude,
      ),
  ];
}

/// 原版 `hxCalc` 的结构化 Dart 入口。
List<StarPosition> hxCalcPositions(
  double t,
  List<StarCatalogEntry> stars,
  double zq,
  int lx,
  double L,
  double fa,
) {
  final mode = switch (lx) {
    0 => StarCoordinateMode.apparent,
    1 => StarCoordinateMode.topocentric,
    2 => StarCoordinateMode.mean,
    _ => throw ArgumentError.value(lx, 'lx', 'Expected 0, 1, or 2'),
  };
  return calcStarPositions(
    t,
    stars,
    zq: zq,
    mode: mode,
    longitude: L,
    latitude: fa,
  );
}

/// 原版 `hxCalc` 的文本兼容入口。
String hxCalc(
  double t,
  List<StarCatalogEntry> stars,
  double zq,
  int lx,
  double L,
  double fa,
) {
  final mode = switch (lx) {
    0 => StarCoordinateMode.apparent,
    1 => StarCoordinateMode.topocentric,
    2 => StarCoordinateMode.mean,
    _ => throw ArgumentError.value(lx, 'lx', 'Expected 0, 1, or 2'),
  };
  final positions = hxCalcPositions(t, stars, zq, lx, L, fa);
  final header = switch (mode) {
    StarCoordinateMode.apparent => '视赤经 视赤纬',
    StarCoordinateMode.topocentric => '站心坐标',
    StarCoordinateMode.mean => '平赤经 平赤纬',
  };
  final out = StringBuffer('J2000.0 TD $header\r\n');
  for (var i = 0; i < stars.length; i++) {
    final star = stars[i];
    final position = positions[i];
    out
      ..write('${star.name} ${star.metadata} ${star.magnitude} ')
      ..write(
        '${_formatAngle(position.first, mode == StarCoordinateMode.topocentric ? false : true)} ',
      )
      ..writeln(_formatAngle(position.second, false));
  }
  return out.toString();
}

StarPosition _calcStarPosition(
  double t,
  StarCatalogEntry star,
  StarCoordinateMode mode,
  double E,
  double dL,
  double dE,
  double gst,
  List<double>? earthVelocity,
  List<double>? earthPosition,
  List<double>? sun,
  double longitude,
  double latitude,
) {
  var z = <double>[
    star.rightAscension + star.properMotionRa * t * 100,
    star.declination + star.properMotionDec * t * 100,
    star.parallax == 0 ? 1e11 : 1 / star.parallax,
  ];
  if (mode != StarCoordinateMode.mean) {
    z = _ylpz(z, sun!);
    z = scGxc(z, earthPosition!, parallax: true);
    z = scGxc(z, earthVelocity!, parallax: false);
    z = cDllrJ2D(t, z);
    z = cDnutation(z, E, dL, dE);
  } else {
    z = cDllrJ2D(t, z);
  }
  if (mode == StarCoordinateMode.topocentric) {
    z[0] += piHalf - gst - longitude;
    z = llrConv(z, piHalf - latitude);
    z[0] = rad2mrad(-piHalf - z[0]);
    if (z[1] > 0) z[1] += MQC(z[1]);
  }
  return StarPosition(
    star: star,
    first: z[0],
    second: z[1],
    distanceAu: z[2],
    mode: mode,
  );
}

/// 地球相对太阳系质心的速度，单位 AU/世纪。
List<double> evSSB(double t) {
  final J = [
    3.1761467 + 1021.3285546 * t,
    1.7534703 + 628.3075849 * t,
    6.2034809 + 334.0612431 * t,
    0.5995465 + 52.9690965 * t,
    0.8740168 + 21.3299095 * t,
    5.4812939 + 7.4781599 * t,
    5.3118863 + 3.8133036 * t,
    3.8103444 + 8399.6847337 * t,
    5.1984667 + 7771.3771486 * t,
    2.3555559 + 8328.6914289 * t,
    1.6279052 + 8433.4661601 * t,
  ];
  final result = [0.0, 0.0, 0.0];
  for (var i = 0; i < 39; i++) {
    final k = i * 12;
    final c =
        evTab[k] * J[evTab[k + 1].toInt()] +
        evTab[k + 2] * J[evTab[k + 3].toInt()] +
        evTab[k + 4] * J[evTab[k + 5].toInt()];
    final S = math.sin(c);
    final C = math.cos(c);
    final scale = i >= 36 ? t : 1.0;
    result[0] += (evTab[k + 6] * S + evTab[k + 7] * C) * scale;
    result[1] += (evTab[k + 8] * S + evTab[k + 9] * C) * scale;
    result[2] += (evTab[k + 10] * S + evTab[k + 11] * C) * scale;
  }
  return [for (final value in result) value * 0.00036525];
}

/// 地心相对太阳系质心的位置，单位 AU。
List<double> epSSB(double t) {
  t /= 10;
  var x = 0.0;
  var y = 0.0;
  var z = 0.0;
  for (var i = 0; i < epTab.length; i += 6) {
    x += epTab[i] * math.cos(epTab[i + 1] + epTab[i + 2] * t);
    y += epTab[i + 3] * math.cos(epTab[i + 4] + epTab[i + 5] * t);
  }
  x +=
      t *
      (1234 +
          515 * math.cos(6.002663 + 12566.1517 * t) +
          13 * math.cos(5.959431 + 18849.22755 * t) +
          11 * math.cos(2.015542 + 6283.07585 * t));
  y +=
      t *
      (930 +
          515 * math.cos(4.431805 + 12566.1517 * t) +
          13 * math.cos(4.388605 + 18849.22755 * t));
  z +=
      t *
      (54 +
          2278 * math.cos(3.413725 + 6283.07585 * t) +
          19 * math.cos(3.370613 + 12566.15170 * t));
  x /= 1000000;
  y /= 1000000;
  z /= 1000000;
  final E = -84381.448 / rad;
  return [
    x,
    z * math.sin(E) + y * math.cos(E),
    z * math.cos(E) - y * math.sin(E),
  ];
}

/// 太阳引力偏折。
List<double> ylpz(List<double> z, List<double> sun) => _ylpz(z, sun);

List<double> _ylpz(List<double> z, List<double> sun) {
  final result = List<double>.from(z);
  final d = z[0] - sun[0];
  final D =
      math.sin(z[1]) * math.sin(sun[1]) +
      math.cos(z[1]) * math.cos(sun[1]) * math.cos(d);
  final correction = 0.00407 * (1 / (1 - D) + D / 2) / rad;
  result[0] += correction * math.cos(sun[1]) * math.sin(d) / math.cos(z[1]);
  result[1] +=
      correction *
      (math.sin(z[1]) * math.cos(sun[1]) * math.cos(d) -
          math.sin(sun[1]) * math.cos(z[1]));
  result[0] = rad2mrad(result[0]);
  return result;
}

/// 恒星周年视差或光行差修正。
List<double> scGxc(List<double> z, List<double> v, {required bool parallax}) {
  final result = List<double>.from(z);
  var c = csGS / csAU * 86400 * 36525;
  if (parallax) c = -z[2];
  final sinJ = math.sin(z[0]);
  final cosJ = math.cos(z[0]);
  final sinW = math.sin(z[1]);
  final cosW = math.cos(z[1]);
  result[0] += rad2rrad((v[1] * cosJ - v[0] * sinJ) / cosW / c);
  result[1] += (v[2] * cosW - (v[0] * cosJ + v[1] * sinJ) * sinW) / c;
  return result;
}

/// 太阳 J2000 黄道坐标。
List<double> sun2000(double t, int n) {
  final result = eCoord(t, n, n, n);
  result[0] += math.pi;
  result[1] = -result[1];
  return hDllrD2J(t, result);
}

double _sexagesimal(String text, {required bool hours}) {
  final negative = text.trimLeft().startsWith('-');
  final numbers = RegExp(
    r'\d+(?:\.\d+)?',
  ).allMatches(text).map((match) => double.parse(match.group(0)!)).toList();
  if (numbers.isEmpty)
    throw FormatException('Invalid sexagesimal value: $text');
  var value = numbers[0];
  if (numbers.length > 1) value += numbers[1] / 60;
  if (numbers.length > 2) value += numbers[2] / 3600;
  if (negative) value = -value;
  return value * (hours ? math.pi / 12 : math.pi / 180);
}

String _formatAngle(double value, bool rightAscension) {
  var degrees = value * (rightAscension ? 12 / math.pi : 180 / math.pi);
  if (rightAscension) degrees = degrees % 24;
  final sign = !rightAscension && degrees < 0 ? '-' : '';
  degrees = degrees.abs();
  final first = degrees.floor();
  final minutesFloat = (degrees - first) * 60;
  final minutes = minutesFloat.floor();
  final seconds = (minutesFloat - minutes) * 60;
  if (rightAscension) {
    return '${first.toString().padLeft(2, '0')}h${minutes.toString().padLeft(2, '0')}m${seconds.toStringAsFixed(2)}s';
  }
  return '$sign$first°${minutes.toString().padLeft(2, '0')}′${seconds.toStringAsFixed(2)}″';
}
