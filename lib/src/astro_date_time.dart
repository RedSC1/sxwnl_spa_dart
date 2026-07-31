import 'dart:math' as math;

/// 支持公元前的天文日期时间类。
///
/// [year] 采用天文纪年（Astronomical Year Numbering）：
///   1 = 公元1年, 0 = 公元前1年, -1 = 公元前2年, ...
///
/// 构造函数签名与 Dart [DateTime] 保持一致，方便迁移：
///   `AstroDateTime(year, [month, day, hour, minute, second, fractionalSecond])`
///
/// 内部通过儒略日（Julian Day）进行日期运算，
/// 所有天文/历法计算均基于 J2000.0 相对儒略日。
class AstroDateTime implements Comparable<AstroDateTime> {
  /// 天文纪年年份（有0年：0 = 公元前1年）
  final int year;

  /// 月 (1-12)
  final int month;

  /// 日 (1-31)
  final int day;

  /// 时 (0-23)
  final int hour;

  /// 分 (0-59)
  final int minute;

  /// 秒 (0-59)
  final int second;

  /// 秒的小数部分，范围为 `[0, 1)`。
  ///
  /// 例如 `second = 28, fractionalSecond = 0.125` 表示 `28.125` 秒。
  /// 旧代码只传整数秒时，该字段默认为 `0.0`，行为保持不变。
  final double fractionalSecond;

  /// 民用时间的时区偏移（单位：小时）。
  ///
  /// `null` 表示旧版的时区中立语义；它不会改变 JD 数值换算。
  /// 该字段主要用于标注 `fromBJJ2000()`、`fromStdJ2000()` 等入口生成的
  /// 日期表示属于哪个时区。
  final double? timeZone;

  /// 构造函数，参数顺序与 [DateTime] 一致。
  const AstroDateTime(
    this.year, [
    this.month = 1,
    this.day = 1,
    this.hour = 0,
    this.minute = 0,
    this.second = 0,
    this.fractionalSecond = 0.0,
  ]) : timeZone = null,
       assert(
         fractionalSecond >= 0 && fractionalSecond < 1,
         'fractionalSecond must be in [0, 1)',
       );

  const AstroDateTime._internal(
    this.year,
    this.month,
    this.day,
    this.hour,
    this.minute,
    this.second,
    this.fractionalSecond,
    this.timeZone,
  ) : assert(
        fractionalSecond >= 0 && fractionalSecond < 1,
        'fractionalSecond must be in [0, 1)',
      );

  /// 完整秒数（整数秒加小数秒）。
  double get preciseSecond => second + fractionalSecond;

  /// 时区别名，便于与 [TimePack] 和 SPA 参数命名保持一致。
  double? get timezone => timeZone;

  /// 返回带有指定时区标记的同一日期字段。
  ///
  /// 此方法只改变时区元数据，不换算钟表字段。例如，`12:00 UTC+8` 调用
  /// `withTimeZone(7)` 后仍显示 `12:00`，只是被标记为 UTC+7。若要保持同一
  /// 瞬间并换算显示时间，请使用 [toTimeZone]。
  AstroDateTime withTimeZone(double? zone) => AstroDateTime._internal(
    year,
    month,
    day,
    hour,
    minute,
    second,
    fractionalSecond,
    zone,
  );

  /// 将同一瞬间转换为目标民用时区，返回新的对象。
  ///
  /// 例如，`12:00 UTC+8` 转为 UTC+7 会得到 `11:00 UTC+7`。本类是不可变
  /// 对象，因此不会就地修改当前实例；当前实例仍保持原时区和钟表字段。
  AstroDateTime toTimeZone(double zone) {
    return AstroDateTime.fromStdJulianDay(toStdJulianDay(), timeZone: zone);
  }

  // --------------- 与 DateTime 兼容的属性 ---------------

  /// 是否公元前
  bool get isBCE => year <= 0;

  /// 公元前的传统纪年（公元前1年 → 1, 公元前2年 → 2）。
  /// 公元后返回 null。
  int? get bceYear => isBCE ? 1 - year : null;

  /// 星期几 (1 = Monday, 7 = Sunday)，与 [DateTime.weekday] 一致。
  int get weekday {
    // 从儒略日计算星期
    final jd = toJulianDay();
    // JD 0 是星期一，JD 的小数部分从正午开始
    // 标准公式：(floor(JD + 1.5)) mod 7 → 0=Mon, 1=Tue, ..., 6=Sun
    final w = ((jd + 1.5).floor()) % 7;
    // 转为 1=Mon ~ 7=Sun
    return w == 0 ? 7 : w;
  }

  // --------------- 核心：儒略日转换 ---------------

  /// 绝对儒略日常量 J2000.0 = 2451545.0 (2000-01-01 12:00 TT)
  static const double j2000 = 2451545.0;

  /// ### 转为绝对儒略日 (JD)
  ///
  /// 基于 Jean Meeus 标准算法，将当前历法时间转换为绝对儒略日。
  ///
  /// **历法切换逻辑：**
  /// * **格里历 (Gregorian)**：1582-10-15 及之后。
  /// * **儒略历 (Julian)**：1582-10-15 之前。
  ///
  /// **注意：** 本方法仅执行数学转换，不包含时区或 ΔT 修正。
  /// `timeZone` 只是日期表示的可空元数据，不会改变这里的旧行为。
  ///
  /// 本方法与旧版 [fromJulianDay] 配套使用。若当前对象是通过
  /// [fromStdJulianDay] 构造、且需要按其时区还原 UTC+0，请改用
  /// [toStdJulianDay]。
  double toJulianDay() {
    return _gregorianToJD(year, month, day, hour, minute, preciseSecond);
  }

  /// 将当前日期表示转换为标准 UTC+0 的绝对儒略日。
  ///
  /// 与 [toJulianDay] 不同，这里会使用 [timeZone] 将民用时间换回
  /// UTC+0；时区为 `null` 时按 0 小时处理。
  double toStdJulianDay() {
    return toJulianDay() - (timeZone ?? 0.0) / 24.0;
  }

  /// ### 转为 J2000.0 相对天数
  ///
  /// 计算相对于历元 J2000.0 (2000-01-01 12:00:00) 的偏移天数。
  ///
  /// **核心用途：**
  /// 此结果是 sxwnl（如行星摄动、定气定朔）的标准输入格式。
  ///
  /// **换算关系：**
  /// `j2kDays = absoluteJD - 2451545.0`
  ///
  /// 本方法与旧版 [fromJ2000] 配套使用。若当前对象是通过
  /// [fromStdJ2000] 构造、且需要按其时区还原 UTC+0，请改用
  /// [toStdJ2000]。
  double toJ2000() {
    return toJulianDay() - j2000;
  }

  /// 将当前日期表示转换为标准 UTC+0 的 J2000 相对日数。
  double toStdJ2000() {
    return toStdJulianDay() - j2000;
  }

  /// 从绝对儒略日 (JD) 构造历法时间。
  ///
  /// **核心逻辑：**
  /// * **时区/标尺中立**：不包含时区偏移或ΔT (TT-UT1) 修正。输入是什么标尺（TT/UT1/UTC等），解析出的就是什么标尺。
  /// * **天文学纪年法**：包含公元 0 年。
  ///   * `year > 0`：公元纪年（如 2026 = AD 2026）。
  ///   * `year == 0`：公元前 1 年 (1 BC)。
  ///   * `year < 0`：公元前 |year| + 1 年（例: -1 = 2 BC）。
  /// * **UI 注意事项**：展示古代年份时，前端需自行处理 `year <= 0` 的平移逻辑。
  ///
  /// JD 的日内小数会写入 [fractionalSecond]，不会被截断为整秒。
  /// 该入口保持时区中立，因此返回对象的 [timeZone] 为 `null`。
  ///
  /// 如果 [jd] 表示 UTC+0 的标准时刻、且需要把结果显示为某个民用时区，
  /// 请使用 [fromStdJulianDay]，不要在调用方手动加减时区偏移。
  factory AstroDateTime.fromJulianDay(double jd) {
    return _jdToGregorian(jd);
  }

  /// 从 J2000.0 相对天数构造历法时间。
  ///
  /// **核心逻辑：**
  /// * **历元基准**：J2000.0 对应绝对儒略日 `2451545.0` (2000-01-01 12:00:00)。
  /// * **单位限制**：入参 [j2k] 必须是**天数 (Days)**。
  /// * **避坑指南**：此接口仅接收天数，切勿传入星历公式中常用的儒略世纪数 (T)。
  ///
  /// 输入天数的小数部分会写入 [fractionalSecond]，不会被截断为整秒。
  /// 该入口保持旧的时区中立行为，因此返回对象的 [timeZone] 为 `null`。
  ///
  /// 如果 [j2k] 表示 UTC+0 的标准时刻、且需要把结果显示为某个民用时区，
  /// 请使用 [fromStdJ2000]，不要在调用方手动加减时区偏移。
  factory AstroDateTime.fromJ2000(double j2k) {
    return _jdToGregorian(j2k + j2000);
  }

  /// 从寿星万年历约定的“北京时间 J2000 日数”构造日期。
  ///
  /// 寿星的定朔、定气等接口返回的数值已经包含北京时间的 `+8/24`
  /// 约定，因此这里不能再额外加 8 小时。该入口只是为这个常见语义
  /// 提供明确名称，并在结果上标记 `timeZone: 8`。
  factory AstroDateTime.fromBJJ2000(double bjJ2000) {
    return AstroDateTime.fromBJJulianDay(bjJ2000 + j2000);
  }

  /// 从寿星万年历约定的“北京时间绝对儒略日”构造日期。
  ///
  /// 输入数值已经按北京时间字段编码，不会再额外加 8 小时；返回对象
  /// 会标记 `timeZone: 8`。
  factory AstroDateTime.fromBJJulianDay(double bjJulianDay) {
    return AstroDateTime.fromJulianDay(bjJulianDay).withTimeZone(8.0);
  }

  /// 从标准时区（默认 UTC+0）的绝对儒略日构造日期。
  ///
  /// 先按 UTC+0 反解，再把显示时间整体加上 [timeZone] 小时，
  /// 并在结果上保留该时区标记。该入口与 [fromStdJ2000] 的区别仅在于
  /// 入参使用绝对 JD，而不是 J2000.0 相对日数。
  factory AstroDateTime.fromStdJulianDay(double jd, {double timeZone = 0.0}) {
    final result = AstroDateTime.fromJulianDay(
      jd,
    ).add(Duration(microseconds: (timeZone * 3600 * 1000000).round()));
    return result.withTimeZone(timeZone);
  }

  /// 从标准时区（默认 UTC+0）的 J2000 日数构造日期。
  ///
  /// 先按 [fromJ2000] 的原始行为反解，再把显示字段整体加上 [timeZone]
  /// 小时，并在结果上保留该时区标记。该入口适合将标准 UTC JD 显示为
  /// 北京时间等民用时间。
  factory AstroDateTime.fromStdJ2000(double j2k, {double timeZone = 0.0}) {
    return AstroDateTime.fromStdJulianDay(j2k + j2000, timeZone: timeZone);
  }

  // --------------- 与 Dart DateTime 互转 ---------------

  /// 从 Dart [DateTime] 构造（现代日期的便捷入口）。
  factory AstroDateTime.fromDateTime(DateTime dt) {
    return AstroDateTime(
      dt.year,
      dt.month,
      dt.day,
      dt.hour,
      dt.minute,
      dt.second,
      (dt.millisecond * 1000 + dt.microsecond) / 1000000.0,
    );
  }

  /// 转为 Dart [DateTime]。
  ///
  /// 如果日期在公元前（[isBCE] == true），返回 null，
  /// 因为 Dart 的 [DateTime] 不支持公元前。
  DateTime? toDateTime() {
    if (isBCE) return null;
    // DateTime 也以微秒为最小单位；四舍五入时处理恰好进位到下一秒的情况。
    var microsecond = (fractionalSecond * Duration.microsecondsPerSecond)
        .round();
    var secondValue = second;
    if (microsecond >= Duration.microsecondsPerSecond) {
      microsecond = 0;
      secondValue += 1;
    }
    return DateTime(
      year,
      month,
      day,
      hour,
      minute,
      secondValue,
      microsecond ~/ Duration.microsecondsPerMillisecond,
      microsecond % Duration.microsecondsPerMillisecond,
    );
  }

  // --------------- 运算 ---------------

  /// 加上一段时间，返回新的 [AstroDateTime]。
  ///
  /// 与 [DateTime.add] 行为一致。
  /// 内部通过儒略日运算，天然支持跨公元前后。
  AstroDateTime add(Duration duration) {
    final jd =
        toJulianDay() + duration.inMicroseconds / Duration.microsecondsPerDay;
    return AstroDateTime.fromJulianDay(jd).withTimeZone(timeZone);
  }

  /// 减去一段时间，返回新的 [AstroDateTime]。
  AstroDateTime subtract(Duration duration) {
    return add(Duration(microseconds: -duration.inMicroseconds));
  }

  /// 两个日期之间的时间差。
  Duration difference(AstroDateTime other) {
    final diffDays = toJulianDay() - other.toJulianDay();
    return Duration(
      microseconds: (diffDays * Duration.microsecondsPerDay).round(),
    );
  }

  /// 是否在 [other] 之后。
  bool isAfter(AstroDateTime other) => toJulianDay() > other.toJulianDay();

  /// 是否在 [other] 之前。
  bool isBefore(AstroDateTime other) => toJulianDay() < other.toJulianDay();

  // --------------- Comparable / Object ---------------

  @override
  int compareTo(AstroDateTime other) {
    return toJulianDay().compareTo(other.toJulianDay());
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AstroDateTime &&
        other.year == year &&
        other.month == month &&
        other.day == day &&
        other.hour == hour &&
        other.minute == minute &&
        other.second == second &&
        other.fractionalSecond == fractionalSecond;
  }

  @override
  int get hashCode =>
      Object.hash(year, month, day, hour, minute, second, fractionalSecond);

  @override
  String toString() {
    final y = isBCE ? '公元前${1 - year}' : '$year';
    final m = month.toString().padLeft(2, '0');
    final d = day.toString().padLeft(2, '0');
    final time = fractionalSecond == 0
        ? toTimeString()
        : toTimeString(fractionDigits: 6);
    return '$y-$m-$d $time';
  }

  /// 获取时间部分的字符串 (HH:mm:ss)
  ///
  /// [fractionDigits] 大于 0 时追加秒的小数部分；默认值为 0，
  /// 以保持旧代码的输出格式。
  String toTimeString({int fractionDigits = 0}) {
    if (fractionDigits < 0 || fractionDigits > 15) {
      throw ArgumentError.value(
        fractionDigits,
        'fractionDigits',
        'must be between 0 and 15',
      );
    }
    final h = hour.toString().padLeft(2, '0');
    final mi = minute.toString().padLeft(2, '0');
    final s = second.toString().padLeft(2, '0');
    final base = '$h:$mi:$s';
    if (fractionDigits == 0 || fractionalSecond == 0) return base;

    final scale = math.pow(10, fractionDigits).toInt();
    var fraction = (fractionalSecond * scale).round();
    // 防止显示舍入把 [0, 1) 舍入为 1.000...。
    if (fraction >= scale) fraction = scale - 1;
    final fractionText = fraction.toString().padLeft(fractionDigits, '0');
    final trimmed = fractionText.replaceFirst(RegExp(r'0+$'), '');
    return trimmed.isEmpty ? base : '$base.$trimmed';
  }

  // --------------- 内部：JD 转换算法 (Meeus) ---------------

  /// 公历 → 绝对儒略日。
  ///
  /// 基于 Jean Meeus《Astronomical Algorithms》标准算法。
  /// 正确处理 Julian/Gregorian 历法切换（1582-10-15）。
  static double _gregorianToJD(int y, int m, int d, int h, int mi, double s) {
    final dayFraction = d + h / 24.0 + mi / 1440.0 + s / 86400.0;

    int year = y;
    int month = m;
    if (month <= 2) {
      year -= 1;
      month += 12;
    }

    // 判断是否在格里历生效之后（1582-10-15）
    // 使用线性比较避免多重条件
    final double isGregorian = (y * 10000.0 + m * 100.0 + d) >= 15821015.0
        ? 1.0
        : 0.0;

    final a = (year / 100).floor();
    // 格里历修正项：格里历时 B = 2 - A + floor(A/4)，儒略历时 B = 0
    final b = isGregorian * (2 - a + (a / 4).floor());

    return (365.25 * (year + 4716)).floor() +
        (30.6001 * (month + 1)).floor() +
        dayFraction +
        b -
        1524.5;
  }

  /// 绝对儒略日 → 公历。
  ///
  /// 基于 Meeus 逆算法。
  static AstroDateTime _jdToGregorian(double jd) {
    // 不再先舍入到整秒，否则会丢失 fractionalSecond。JD 的浮点精度
    // 本身约为几十微秒，已经足够覆盖 Dart DateTime 的微秒接口。
    final jdShifted = jd + 0.5;
    var z = jdShifted.floor();
    var f = jdShifted - z;
    if (f < 0) {
      f += 1;
      z -= 1;
    } else if (f >= 1) {
      f -= 1;
      z += 1;
    }
    // 将反解结果归一到微秒；JD 的浮点误差可能把整秒推到相邻秒的几十
    // 微秒内，例如把 J2000.0 表示成 11:59:59.999987，此时应吸附回整秒。
    final rawSecondsOfDay = f * 86400.0;
    final nearestSecond = rawSecondsOfDay.roundToDouble();
    var secondsOfDay = (rawSecondsOfDay - nearestSecond).abs() < 5e-5
        ? nearestSecond
        : (rawSecondsOfDay * Duration.microsecondsPerSecond).round() /
              Duration.microsecondsPerSecond;
    // 极少数情况下浮点乘法会把小于一天的 f 舍入为 86400，
    // 此时进位到下一天后再进行日历字段计算。
    if (secondsOfDay >= 86400.0) {
      secondsOfDay = 0.0;
      f = 0.0;
      z += 1;
    }

    int a;
    if (z < 2299161) {
      // 儒略历
      a = z;
    } else {
      // 格里历
      final alpha = ((z - 1867216.25) / 36524.25).floor();
      a = z + 1 + alpha - (alpha / 4).floor();
    }

    final b = a + 1524;
    final c = ((b - 122.1) / 365.25).floor();
    final d = (365.25 * c).floor();
    final e = ((b - d) / 30.6001).floor();

    final day = b - d - (30.6001 * e).floor();

    final month = e < 14 ? e - 1 : e - 13;
    final year = month > 2 ? c - 4716 : c - 4715;

    final hour = (secondsOfDay / 3600.0).floor();
    final minute = ((secondsOfDay - hour * 3600.0) / 60.0).floor();
    final secondValue = secondsOfDay - hour * 3600.0 - minute * 60.0;
    final second = secondValue.floor();
    var fractionalSecond = secondValue - second;
    if (fractionalSecond < 1e-12) fractionalSecond = 0.0;

    return AstroDateTime(
      year,
      month,
      day,
      hour,
      minute,
      second,
      fractionalSecond,
    );
  }
}
