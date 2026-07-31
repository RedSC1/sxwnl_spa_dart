# sxwnl_spa_dart

> Chinese calendar & astronomical calculations library based on sxwnl + SPA. Provides lunar calendar, solar terms, gan-zhi and true solar time. Comparison scripts are included in the test directory.
>
> 免责声明：本库为 AI 参考与实现版本，作者非天文历法专业，结果不保证完全准确，仅供学习与参考。项目包含一系列对比测试脚本，详见 test 目录。如使用本项目或本包，请标注算法原作者与来源（寿星天文历作者：许剑伟）。商用提醒：本项目代码采用 MIT 协议开源，但算法本身的商业使用授权需由使用者自行联系原作者取得。作者不承担因第三方商业行为引发的任何版权争议或法律责任。
>
> Disclaimer: This project is an AI-assisted implementation for learning/reference only. Accuracy is not guaranteed. Please credit the original algorithm author (SXWNL author: Xu Jianwei) when using this project/package. For commercial use, obtain authorization from the original algorithm author first. Commercial use of this project's code is under the MIT license, but commercial use of the underlying algorithms requires separate permission from the original author; the maintainer assumes no liability for any third-party commercial use.

本项目的农历、节气、日月食、行星、恒星及实时日月位置等主天文历法计算，均以寿星天文历（万年历）[sxwnl](https://github.com/sxwnl/sxwnl) 为原始算法来源并进行 Dart 移植；独立的日出日落、真太阳时和日上中天接口另提供基于 [dart-spa](https://github.com/pingbird/dart-spa) 的 SPA 路径，并做了适配与调整。两套算法不应混用于同一条寿星历法计算链。详见下方的[项目沿革：为什么同时内置两套算法？](#why-two-architectures)。

## ✨ 特性

*   **农历转换**：`LunarDate` 支持阳历 ↔ 农历双向转换，兼容历史特殊月名
*   **回历**：`HuiLiDate` / `HijriDate` 按寿星原版 30 年周期规则计算伊斯兰历日期
*   **农历节气**：农历排盘与节气计算
*   **太阳位置**：真太阳时、均时差、日出日落、日上中天
*   **实时日月位置（sxwnl 兼容）**：太阳/月亮的方位角、高度角、视差修正、固定标准折射前后坐标
*   **干支排盘**：类型安全的 `TianGan`/`DiZhi`/`GanZhi`/`BaZi` 模型 + `calcBaZi()` API
*   **时间封装**：`TimePack` 统一管理钟表时间、真太阳时、UTC 时间
*   **一站式模型**：`DayInfo` 对象集成干支、农历、节日、节气、月相、日出日落、星座等全量单日信息
*   **节日民俗**：对标原版 sxwnl (lunar.js) 补全节日库，支持分类过滤与民俗进度显示（如“初伏第3天”）
*   **日月食（sxwnl 兼容）**：月食食甚与接触时刻、日食快速筛选、全球日食中心线及半影/本影南北界
*   **行星位置与天象（sxwnl 兼容）**：太阳、月亮及水星至冥王星等太阳系主要天体的位置；水星/金星大距、行星留、合月及合/冲
*   **恒星位置（sxwnl `ephB` 兼容）**：脚本提取的 `HXK` 恒星库、88 星座表、岁差/章动/光行差/视差修正与站心地平坐标
*   **历史历法**：春秋、战国、秦汉等时期的历法规则（已移植部分）
*   **纯 Dart**：零 Native 依赖，全平台支持

## 📦 安装

```yaml
dependencies:
  sxwnl_spa_dart: ^1.0.0
```

> `0.18.1` 起，`LunarDate.lunarYear` 对外语义真正统一为天文纪年（含公元 0 年）。
> 如需传统显示或历史纪年，可使用 `LunarDate.historicalYear` / `LunarDate.bceYear` / `LunarDate.isBCE`。

## 🚀 快速上手

### 1. 真太阳时 (True Solar Time)

```dart
import 'package:sxwnl_spa_dart/sxwnl_spa_dart.dart';

void main() {
  // 新版入口要求把民用时区随 AstroDateTime 一起携带。
  final time = AstroDateTime(2023, 1, 22, 12, 0, 0).withTimeZone(8.0);
  final loc = Location(87.6, 43.8);
  // SPA 仅用于独立的真太阳时、日出日落和日上中天计算。
  final res = calcTrueSolarTime2(time, loc, method: SolarCalcMethod.spa);

  print('平太阳时 (Mean Solar Time): $time');
  print('真太阳时 (True Solar Time): ${res.trueSolarTime}');
  print('日上中天 (Solar Noon): ${res.solarNoon}');
  print('均时差 (Equation of Time): ${res.equationOfTime.inMinutes} 分钟');
}
```

`calcTrueSolarTime2()` 会保留输入的 `UTC+8` 时区标记；若需要与寿星万年历
原版路径对齐，可将 `method` 改为 `SolarCalcMethod.sxwnl`。旧版
`calcTrueSolarTime()` 仍保留兼容，但时区通过单独的 `timezone` 参数传入，
新代码建议使用上面的新版入口。

### 时间尺度与时区

`AstroDateTime` 的 `toJulianDay()` / `toJ2000()` 保持原有的时区中立
行为，不会根据元数据自动偏移。直接构造的对象以及 `fromJulianDay()` /
`fromJ2000()` 的 `timeZone` 都是 `null`，用于兼容旧代码。

需要明确标记时间表示时：

- `fromBJJ2000()`：寿星万年历约定的北京时间 J2000 日数，标记为 `UTC+8`，不再额外偏移。
- `fromBJJulianDay()`：寿星万年历约定的北京时间绝对 JD，标记为 `UTC+8`。
- `fromStdJulianDay(jd, timeZone: 8)`：先按标准 UTC+0 绝对 JD 反解，再显示为指定时区并保留标记。
- `fromStdJ2000(jd, timeZone: 8)`：先按原始 J2000 行为反解，再将显示时间加 8 小时并标记为 `UTC+8`。
- `toTimeZone(7)`：保持同一瞬间，将带有时区的对象转换为 UTC+7，并返回新对象；不会就地修改原对象。
- `withTimeZone(7)`：只替换时区标记，不改变钟表字段，适合确认元数据而不是进行时刻换算。
- `toStdJulianDay()` / `toStdJ2000()`：根据对象的 `timeZone` 转回 UTC+0；时区为空时不偏移。

寿星 `SSQ` / `JieQi` 等接口返回的“北京时间 J2000 日数”可直接使用
`AstroDateTime.fromBJJ2000()`，不要再额外加 8 小时。

例如，将 UTC J2000 日数显示为北京时间：

```dart
final utcJ2000 = AstroDateTime(2025, 1, 1, 0, 0, 0, 0.5).toJ2000();
final beijing = AstroDateTime.fromStdJ2000(utcJ2000, timeZone: 8);
```

### 2. 农历排盘 (Lunar Calendar)

```dart
import 'package:sxwnl_spa_dart/sxwnl_spa_dart.dart';

void main() {
  final ssq = SSQ();
  final jd2023 = AstroDateTime(2023, 6, 1).toJ2000();
  final res = ssq.calcY(jd2023);

  print('闰月索引 (Leap Month Index): ${res.leap}');
  for (int i = 0; i < 14; i++) {
    final dt = AstroDateTime.fromBJJ2000(res.hs[i]);
    print('${res.ym[i]}月 (Month): ${dt.year}-${dt.month}-${dt.day}');
  }
}
```

### 3. 干支计算 (Gan-zhi)

干支计算需要 J2000 相对 JD，日柱与时柱建议使用真太阳时 JD。

```dart
import 'package:sxwnl_spa_dart/sxwnl_spa_dart.dart';

void main() {
  final dt = AstroDateTime(2023, 2, 4, 12, 0, 0);
  final loc = Location(116.4, 39.9);
  final trueSolar = calcTrueSolarTime(dt, loc);
  final jdUt = dt.subtract(const Duration(hours: 8)).toJ2000();
  final bazi = calcGanZhi(jdUt, trueSolar.trueSolarTime.toJ2000());
  print('八字 (Gan-zhi): $bazi');
}
```

### 4. 农历转换 (Lunar Calendar Conversion)

```dart
import 'package:sxwnl_spa_dart/sxwnl_spa_dart.dart';

void main() {
  // 阳历 → 农历
  final solar = AstroDateTime(2025, 1, 29, 12, 0, 0);
  final lunar = LunarDate.fromSolar(solar);
  print('农历: $lunar'); // 2025年正月初一

  // 农历 → 阳历
  final lunar2 = LunarDate.fromString(2025, "正", 15);
  print('阳历: ${lunar2.toSolar}');
}
```

#### 回历 / 伊斯兰历（Hijri）

`HuiLiDate` / `HijriDate` 移植的是寿星万年历 `oba.getHuiLi()` 的**算术回历**：
按固定的 30 年（10631 日）周期计算，不根据观测新月、地点或当地教法重新判月。
输入日期按寿星万年历的北京时间民用日归属处理；`fromBJJ2000()` 接收北京时间
J2000.0 相对日数，`fromSolar()` 接收 `AstroDateTime`。

```dart
final hijri = HuiLiDate.fromSolar(AstroDateTime(2000, 1, 1));
print(hijri); // 1420-9-24 AH
print('${hijri.Hyear}-${hijri.Hmonth}-${hijri.Hday}');
```

### 5. 类型安全的干支计算 (Typed Gan-zhi)

```dart
import 'package:sxwnl_spa_dart/sxwnl_spa_dart.dart';

void main() {
  final dt = AstroDateTime(2026, 2, 4, 12, 0, 0);
  final loc = Location(116.4, 39.9);
  final trueSolar = calcTrueSolarTime(dt, loc);
  final jdUt = dt.toJ2000() - 8 / 24;

  // 类型安全版本
  final result = calcBaZi(jdUt, trueSolar.trueSolarTime.toJ2000());
  print('年柱: ${result.bazi.year}'); // GanZhi 对象
  print('年干: ${result.bazi.year.gan}'); // TianGan 枚举

  // 原版字符串版本（保留兼容）
  final strResult = calcGanZhi(jdUt, trueSolar.trueSolarTime.toJ2000());
  print('八字: $strResult');
}
```

### 6. 时间封装 (TimePack)

```dart
import 'package:sxwnl_spa_dart/sxwnl_spa_dart.dart';

void main() {
  final tp = TimePack.createBySolarTime(
    clockTime: AstroDateTime(2026, 2, 18, 12, 0, 0),
    location: Location(116.4, 39.9),
    timezone: 8.0,
    useTrueSolarTime: true,
  );

  print('钟表时间: ${tp.clockTime}');
  print('真太阳时: ${tp.virtualTime}');
  print('UTC时间: ${tp.utcTime}');
}
```

### 7. 节气查询 (Solar Terms)

```dart
import 'package:sxwnl_spa_dart/sxwnl_spa_dart.dart';

void main() {
  final now = AstroDateTime(2025, 2, 19, 12, 0, 0);

  // 获取一年所有节气
  final jq2025 = getYearJieQi(2025);
  for (final jq in jq2025) {
    print('${jq.name}: ${jq.dateTime}');
  }

  // 查询上一个/下一个节气
  final prev = getPrevJieQi(now);
  final next = getNextJieQi(now);

  // 查询上一个/下一个节
  final prevJie = getPrevJie(now);
  final nextJie = getNextJie(now);

  // 查询上一个/下一个气
  final prevQi = getPrevQi(now);
  final nextQi = getNextQi(now);

  // 获取距离信息
  final dist = getJieQiDistance(now);
  final jieDist = getJieDistance(now);
  final qiDist = getQiDistance(now);
  final info = getJieQiInfo(now);

  // 仅获取 Julian Day
  final jdList = getYearJieQiJd(2025);
  final prevJd = getPrevJieQiJd(now);
}
```

### 8. 一站式日历信息 (DayInfo)

`DayInfo` 是本库最核心的数据模型，通过 `getDayRange` 或 `getSolarMonthDays` 等接口返回。它集合了几乎所有常用的单日历法与天文数据。

```dart
import 'package:sxwnl_spa_dart/sxwnl_spa_dart.dart';

void main() {
  // 获取 2026 年 3 月的单日信息列表 (包含地理位置以计算日出日落)
  final days = getSolarMonthDays(2026, 3, location: Location(116.4, 39.9));
  
  for (final d in days) {
    print('--- ${d.solarDate.toDateString()} ---');
    print('农历: ${d.lunarDate} (月大小: ${d.lunarMonthSize})');
    print('干支: ${d.ganZhi} (周${d.weekdayName})');
    print('星座: ${d.constellation}');
    print('节日: ${d.festivals}');
    if (d.solarTerm != null) print('节气: ${d.solarTerm} @ ${d.solarTermTime}');
    if (d.moonPhase != null) print('月相: ${d.moonPhase} @ ${d.moonPhaseTime}');
    if (d.sunrise != null) print('日出: ${d.sunrise} / 日落: ${d.sunset}');
  }
}
```

### 9. 节日民俗过滤与进度 (Festivals)

`DayInfo.festivals` 返回全量节日列表。可以使用 `getFestivalsByLevel()` 方法进行 UI 降噪。

```dart
import 'package:sxwnl_spa_dart/sxwnl_spa_dart.dart';

void main() {
  final day = getSolarMonthDays(2026, 7).firstWhere((d) => d.solarDate.day == 16);
  
  // 1. 获取全量列表
  print('全量: ${day.festivals}'); // [中伏, 国际臭氧层保护日...]
  
  // 2. 简易显示 (仅法定、传统、流行级别)
  print('主要节日: ${day.getFestivalsByLevel()}'); 

  // 3. 进度追踪 (三伏、数九)
  print('当前进度: ${day.festivals.firstWhere((f) => f.name.contains("伏"))}'); // 中伏第1天
}
```

### 10. 日月食（sxwnl 兼容接口）

寿星万年历的历法日期与常规界面展示以北京时间为准。本节保留的是 `eph.js` 的低层日月食根数接口：`ysPL`、`rsGS` 与 `ecFast` 的 `jd`、`lT`、`gk*` 等原始时刻字段均为 **J2000.0 起算的 TT/TD 儒略日数**；原版 `rsGS.jieX3()` 也明确标注其曲线时间为“力学时”。例外是 `rsPL.secMax()` 的 `sun_s`、`sun_j`：原版在返回前已将它们转为 J2000.0 起算的 **UT** 日数，而 `sT` 仍是 TT/TD。需要按寿星万年历的用户界面显示时，应先将 TT 字段减去 `dT` 转 UTC，再加 8 小时转北京时间；UT 字段则直接加 8 小时。

```dart
import 'package:sxwnl_spa_dart/sxwnl_spa_dart.dart';

void main() {
  // 2026-08-12 日全食附近的 J2000 TT/TD 日数。
  const jd = 9719.5;

  // 全球食带：使用 7 点全精度 Bessel 插值。
  rsGS.init(jd, 7);
  final eclipse = rsGS.jieX(jd);
  print('类型: ${eclipse.lx}'); // T（全食）
  print('中心线点数: ${eclipse.L0.length ~/ 2}');
  print('半影北/南界: ${eclipse.L1.length ~/ 2} / ${eclipse.L2.length ~/ 2}');
  print('本影北/南界: ${eclipse.L3.length ~/ 2} / ${eclipse.L4.length ~/ 2}');

  // 月食：lT = [初亏, 食甚, 复圆, 半影食始, 半影食终, 食既, 生光]。
  ysPL.lecMax(9380.5); // 2025-09-07 月全食附近
  print('月食类型: ${ysPL.LX}'); // 全
  print('食甚（J2000 TT/TD）: ${ysPL.lT[1]}');
}
```

`rsGS.jieX()` 的曲线均为扁平的 `[经度, 纬度, ...]` 弧度数组：`L0` 是中心线，`L1/L2` 是半影北/南界，`L3/L4` 是本影北/南界，`L5/L6` 是 0.5 食分北/南界。`p*`、`q*` 还保留了原版的初亏界和日出日没食甚连接线。`rsGS.jieX2()` 提供闭合的全球本影/半影/晨昏圈曲线，`rsGS.jieX3()` 提供原版逐分钟界线表；地方日食（`rsPL`）的 `secMax()`、`secXY()` 和 `nbj()` 南北界计算也已移植。

#### PMO 独立对照

下面是以紫金山天文台（PMO）公开历书表为基准的独立 sanity check；`差值` 均为“本库 − PMO”。原 sxwnl JS 的逐点回归仍是本模块的兼容 oracle。PMO 表本身有公开发布精度的四舍五入，因此不应把这些秒级/公里级差异理解为对 sxwnl 移植正确性的判定。

2025-09-07 月全食：PMO 同时公布 TD 和北京时间；此表直接使用 **TD**，对应本库 `J2000 TT/TD + 2451545`，不进行北京时间偏移。

| PMO 行 | sxwnl 字段 | PMO TD | 差值 |
| --- | --- | ---: | ---: |
| 半影食始（P1） | `ysPL.lT[3]` | 15:28.0 | +5.1 s |
| 初亏（U1） | `ysPL.lT[0]` | 16:27.9 | +2.8 s |
| 食既（U2） | `ysPL.lT[5]` | 17:31.5 | +2.7 s |
| 食甚（Greatest） | `ysPL.lT[1]` | 18:13.0 | −2.1 s |
| 生光（U3） | `ysPL.lT[6]` | 18:54.4 | +0.8 s |
| 复圆（U4） | `ysPL.lT[2]` | 19:58.0 | +1.5 s |
| 半影食终（P4） | `ysPL.lT[4]` | 20:57.8 | −1.9 s |

2026-08-12 日全食：PMO 公开表使用 **UT**；本库通过 `J2000 TT/TD + 2451545 − dT` 比较。

| PMO 行 | sxwnl 字段 | PMO UT | 差值 |
| --- | --- | ---: | ---: |
| 偏食始（P1） | `rsGS.feature().gk3[2]` | 15:34:14 | +0.6 s |
| 全食始（C1） | `rsGS.feature().gk1[2]` | 17:00:06 | +1.0 s |
| 食甚（Greatest） | `rsGS.feature().jd` | 17:45:56 | +0.1 s |
| 全食终（C4） | `rsGS.feature().gk2[2]` | 18:32:12 | +0.8 s |
| 偏食终（P4） | `rsGS.feature().gk4[2]` | 19:57:59 | +0.9 s |

| 食甚概要 | 差值 |
| --- | ---: |
| 纬度 | +0.0052° |
| 经度 | +0.0081° |
| 食分 | −0.00136 |
| 全食持续时间 | −2.7 s |
| 食带宽度 | −2.3 km |

### 11. UI 增强：细分月相扩展 (8 Moon Phases)

如果你的 UI 需要更细致的月相描述（如峨眉月、凸月等），可以使用扩展方法进行升级。

```dart
import 'package:sxwnl_spa_dart/sxwnl_spa_dart.dart';
import 'package:sxwnl_spa_dart/src/extensions/sxwnl_ext.dart';

void main() {
  List<DayInfo> days = getSolarMonthDays(2026, 2);
  
  // 一键升级月相显示 (将 moonPhase 字段补全为 8 种形态)
  final enhancedDays = days.withMoonPhase8();
  
  for (final d in enhancedDays) {
    if (d.moonPhase != null) print('${d.solarDate.day}日: ${d.moonPhase}');
  }
}
```

### 11. 实时太阳/月亮方位与高度（sxwnl `msc`）

需要某一时刻的方位角和高度角时，可使用原版同名的 `msc`。经纬度使用弧度，东经/北纬为正；`sDJ/sDW`、`mDJ/mDW` 为折射前结果，`sPJ/sPW`、`mPJ/mPW` 为采用寿星固定标准折射公式后的结果。

```dart
import 'dart:math' as math;
import 'package:sxwnl_spa_dart/sxwnl_spa_dart.dart';

void main() {
  // jd 是 J2000 起算的 TT/TD 日数；海拔单位为 km。
  msc.calc(9203.5, 116.4 * math.pi / 180, 39.9 * math.pi / 180, 0.05);
  print('太阳方位/真高度: ${msc.sDJ}, ${msc.sDW}');
  print('太阳方位/视高度: ${msc.sPJ}, ${msc.sPW}');
  print('月亮方位/视高度: ${msc.mPJ}, ${msc.mPW}');
}
```

### 12. 太阳算法切换 (Algorithm Switch)

本项目的定朔、定气、农历、节气、日月食、实时日月位置及其余寿星万年历功能，**一律使用原版 sxwnl 移植实现**。SPA 只是早期为补齐独立的日出日落、真太阳时和日上中天而引入的补充算法。

**除日出日落、真太阳时、日上中天外，不要使用 SPA。** SPA 与 sxwnl 的公式、截断项、修正项和时间处理并不完全相同；把 SPA 的太阳位置或均时差接入寿星万年历的定朔定气、历法或日月事件计算，会造成潜在的数据不一致。需要寿星万年历语义或与原版结果对齐时，直接使用 `sxwnl`。

```dart
import 'package:sxwnl_spa_dart/sxwnl_spa_dart.dart';

void main() {
  final date = AstroDateTime(2026, 3, 4, 12, 0, 0);
  final loc = Location(116.3833, 39.9);

  // 1. 使用 SPA 算法（默认）
  final resSpa = calcTrueSolarTime(date, loc, method: SolarCalcMethod.spa);
  print('SPA 算法日出: ${resSpa.sunrise}');

  // 2. 使用 SXWNL 原始路径（用于兼容寿星万年历）
  final resSxwnl = calcTrueSolarTime(date, loc, method: SolarCalcMethod.sxwnl);
  print('SXWNL 算法日出: ${resSxwnl.sunrise}');

  // 3. 在批量 API 中应用
  final days = getSolarMonthDays(2026, 3, location: loc, solarMethod: SolarCalcMethod.sxwnl);
}
```

### 13. 行星位置与天象（sxwnl）

`pCoord()`、`xingJJ()`、`daJu()`、`xingLiu()`、`xingHY()`、`xingHR()` 与 `xingXPosition()` 直接移植自寿星万年历的行星计算路径，当前已覆盖太阳、月亮以及水星至冥王星等太阳系主要天体。水星至海王星的底层坐标调用原版 `XL0_calc` 对应的 Dart 实现；冥王星则接入原版 `XL0Pluto` 级数并沿用 P03 岁差转换。`xingXPosition()` 还覆盖站心视差、地平坐标和固定标准大气折射；文本兼容入口为 `xingX()`。底层 `xingLiu0()`、`xingMP()`、`xingSP()` 也保留为公开接口，便于复用寿星的事件迭代链。所有这些路径都包括寿星原有的系数截断、地球多项式修正和对应经验修正；行星事件求解继续保留原版光行时迭代，并非调用 SPA。冥王星可用于 `pCoord()`、`xingJJ()`、`xingHY()`、`xingLiu()` 与 `xingHR()`；原版 `xingLiu()` / `xingHR()` 的迭代初始步骤直接调用 `XL0_calc(8, ...)`，而 `XL0` 只覆盖到海王星，因此原版 JavaScript 传入冥王星时会因数组越界抛出运行时错误。本库利用已经移植的 `pCoord()` 冥王星经度路径补上这两个事件接口；这是面向完整行星覆盖的兼容性扩展，冥王星事件结果不应被表述为原版 JavaScript 的逐值回归。

这些低层 API 的 `t` 和返回时刻均为 **J2000.0 起算的 TT/TD 儒略世纪**。`daJu()` 仅适用于水星、金星；`xingHR(..., true)` 对外行星求冲、对内行星求下合。太阳均时差还可直接调用 `ptyZty()`（高精度）或 `ptyZty2()`（约 1 秒精度），返回单位为日（一天的分数）。用于民用时间展示时，应按该时刻的 `dT` 先转 UTC，再按需要转北京时间。

这里有一条可复现的外部 oracle：SEDS 的 [Mars 2003](https://spider.seds.org/spider/Mars/mars2003.html) 记载火星冲日为 **2003-08-28 17:58:49 UTC**（北京时间为次日 01:58:49）。本库 `xingHR(Planet.mars, ..., true)` 给出 **17:58:48.77 UTC**，相差约 **−0.23 秒**；该断言已作为回归测试保留。它是与公开天文资料的交叉验证，而与原版寿星万年历的 TT 输出仍单独做逐值一致性测试。

```dart
import 'package:sxwnl_spa_dart/sxwnl_spa_dart.dart';

void main() {
  const t = 0.03656; // 约 2003 年，J2000.0 TT 儒略世纪
  final marsOpposition = xingHR(Planet.mars, t, true);
  print(marsOpposition); // [TT 儒略世纪, 火星与太阳黄纬差（弧度）]

  final venusGreatestElongation = daJu(Planet.venus, .26, true);
  print(venusGreatestElongation.t);
}
```

### 14. 恒星与星座（sxwnl `ephB`）

`ephB` 中的 `HXK` 恒星库与 `xz88` 88 星座表由 `tool/extract_ephb_stars.mjs` 从原版源码机械提取，Dart 侧不手抄系数或星表记录；可用 `tool/verify_ephb_data.mjs` 逐项核对生成文件。`getHXK()` 将原始分块解析为类型安全的恒星记录，`calcStarPositions()` / `hxCalcPositions()` 提供平位置、视位置和站心地平坐标，`schHXK()` 保留原版星库检索入口。

恒星计算的时刻参数为 J2000.0 起算的 TT/TD 儒略世纪；经纬度使用弧度，结果中的距离单位沿用寿星原版（恒星为 AU 标度）。

寿星底层坐标辅助也从包入口导出，包括 `llr2xyz()`、`xyz2llr()`、`CD2DP()`、`j1_j2()`、`parallax()`、`MQC()`、`MQC2()`、`shiChaJ()`、`sunShengJ()`、`pGST2()`、`nutation()` 和 `CDnutation()`；它们保留原版的坐标单位与 J2000/TT 语义。

<a id="why-two-architectures"></a>

## 🌗 项目沿革：为什么同时内置 SPA 和 SXWNL？

实话实说：早期 AI 辅助开发时，为了尽快实现真太阳时和日出日落，直接移植并接入了现成的 `dart-spa`。当时对天文历法模型理解不够，README 曾把这件事讲得过于“架构化”和玄乎；这不是两套完全不同的天文世界观。对于一个以寿星万年历为主体的移植项目，SPA 不是历法主干，也不应被当作全库默认的权威数据源。

后来梳理后确认：两条太阳位置路径的基础都可归到 VSOP87 级数的截断与配套修正，差别主要在采用的公式、保留项数、修正项和面向的输出。SPA 保留的太阳位置项通常更多；在本库中用于真太阳时、日出日落和日上中天时，通常可期待略好的数值表现，但多数普通日期和地点的差异并不大，也不应在没有独立基准时宣称某一路“绝对更准”。

保留两者的实际理由是：

* `SolarCalcMethod.sxwnl`：寿星万年历主路径；定朔、定气、农历、节气、日月食及所有与原版结果衔接的功能均使用它。
* `SolarCalcMethod.spa`：只保留给独立的日出日落、真太阳时、日上中天需求；不要用于其他寿星万年历功能，也不是替代 sxwnl 历法语义的“更高级版本”。

也就是说，这不是两套可以任意替换的全库算法：SPA 的适用范围仅限上述三个太阳时间/地平事件 API。尤其不要把 SPA 的均时差或太阳位置和 sxwnl 的定朔定气、历法或日月事件结果拼在一起。对需要严肃精度声明的场景，应以明确的外部星历/公开历书基准验证，而不是依据算法名称下结论。

## ✅ 测试结果

*   静态分析：dart analyze 通过
*   对比基准：sxwnl 寿星天文历(万年历) 5.10 原作者: 许剑伟（https://github.com/sxwnl/sxwnl）
*   对比范围：节气/朔、日上中天、日出、日落（均与 sxwnl 对比，不与 spa 对比）
*   对比脚本：test/compare_jq.dart、test/compare_solar_noon.dart、test/compare_sunrise.dart、test/compare_sunset.dart
*   系数表审计：`node tool/verify_xl_data.mjs` 从原版 `eph0.js` 读取数值，逐项精确比较本库 `XL0`（行星）、`XL1`（月球）、`XL0_xzb`（行星经验修正）及 `XL0Pluto`（冥王星）四张表；`verify_ephb_data.mjs` 与 `verify_nutation_iau2000b.mjs` 分别逐项核对恒星/星座表和 847 个 IAU 2000B 章动系数。
*   说明：未随包附带 sxwnl 原始源码，运行对比脚本需自行从 sxwnl 仓库下载后放入 test/sxwnl_js
*   基准数据：test/compute_*_js.js 生成 js_*.json
*   测试项不仅包含核心算法本身，也包含了与原版同样的查表修正（如 SSQ 的历史历法修正数据）。
*   回历专项回归：`test/test_hui_li_date.dart` 覆盖寿星原版固定日期对照、30 年周期重复性、闰年 12 月 30 日边界、北京时间跨日及 `DayInfo` 集成，共 5 项。
*   具体数值（由于太阳位置算法实现不同，日出/日上中天/日落存在秒级差异属于正常现象）：

| 指标 | 参数 | avg_diff_seconds | max_diff_seconds | exact_second | lt_1s | gt_1s |
| --- | --- | --- | --- | --- | --- | --- |
| 节气 (`compare_jq`) | years: -2000..5000, 纯浮点对比 | 0.000000 | 0.000000 | 168024 | 0 | 0 |
| 农历基线 (`compare_ssq`) | years: -2000..5000, 包含历史表与月建 | 0.000000 | 0.000000 | 7001年完全一致 | 0 | 0 |
| 日月升中降 (`compare_szj`) | years: -2000..5000, 纯浮点对比 | 0.000026 | 0.000110 | 15341686 | 794 | 0 |
| 日上中天 (`compare_solar_noon`)* | lon 116.3833, lat 39.9, tz 8.0 | 0.804249 | 18.000000 | 1032940 | 1494625 | 29515 |
| 日出 (`compare_sunrise`)* | lon 116.3833, lat 39.9, tz 8.0 | 57.273736 | 191.000000 | 6747 | 40550 | 2509783 |
| 日落 (`compare_sunset`)* | lon 116.3833, lat 39.9, tz 8.0 | 0.876318 | 62.000000 | 953666 | 1564709 | 38705 |

*\*注：带有 \* 号的为当前 SPA 默认路径的测试项，而非与 sxwnl 原生路径逐项一致的实现。日出日落采用固定的标准阈值（太阳半径加标准大气折射，约 −0.833°）；公开 API 尚未暴露气压、温度或实时视高度角修正。*

## English

Chinese calendar & astronomical calculations library based on sxwnl + SPA.

### Features

*   **Lunar conversion**: `LunarDate` for solar ↔ lunar bidirectional conversion
*   **Chinese lunar calendar**: lunar year structure and solar terms
*   **Solar position**: true solar time, equation of time, sunrise, sunset, solar noon
*   **Gan-zhi**: type-safe `TianGan`/`DiZhi`/`GanZhi`/`BaZi` models + `calcBaZi()` API
*   **Time packing**: `TimePack` for unified clock/solar/UTC time management
*   **Unified Model**: `DayInfo` object integrating Gan-zhi, Lunar, Festivals, Solar Terms, Moon Phases, Sunrise/Sunset, etc.
*   **Festivals & Customs**: Comprehensive festival database aligned with sxwnl (lunar.js) with classification and progress tracking (e.g., "3rd day of Sanfu")
*   **Historical calendars**: partial rules for Spring/Autumn, Warring States, Qin/Han
*   **Pure Dart**: no native dependencies

### Installation

```yaml
dependencies:
  sxwnl_spa_dart: ^1.0.0
```

### Quick Start

See the Chinese examples above: 真太阳时 / 农历排盘 / 干支计算.

### Test Results

*   Static analysis: dart analyze
*   Baseline: sxwnl 5.10 by Xu Jianwei (https://github.com/sxwnl/sxwnl)
*   Scope: solar terms/new moons, solar noon, sunrise, sunset (all compared to sxwnl, not SPA)
*   Scripts: test/compare_jq.dart, test/compare_solar_noon.dart, test/compare_sunrise.dart, test/compare_sunset.dart
*   Note: the original sxwnl sources are not bundled; download from sxwnl repo and place under test/sxwnl_js to run scripts
*   Test suites encompass both the raw VSOP87 calculations and all historical adjustment data structures in `SSQ`.
*   Data: test/compute_*_js.js generates js_*.json
*   Numbers (second-level differences in solar position are expected due to algorithm differences):

| Metric | Params | avg_diff_seconds | max_diff_seconds | exact_second | lt_1s | gt_1s |
| --- | --- | --- | --- | --- | --- | --- |
| Solar terms | JS VSOP87 engine, 7000 yrs float | 0.000000 | 0.000000 | 168024 | 0 | 0 |
| Lunar baseline | Lunar arrays and historical fixes | 0.000000 | 0.000000 | 7001 yrs identical | 0 | 0 |
| Sun/Moon R/T/S | 7000 yrs, 15.3M floats | 0.000026 | 0.000110 | 15341686 | 794 | 0 |
| Solar noon* | lon 116.3833, lat 39.9, tz 8.0 | 0.804249 | 18.000000 | 1032940 | 1494625 | 29515 |
| Sunrise* | lon 116.3833, lat 39.9, tz 8.0 | 57.273736 | 191.000000 | 6747 | 40550 | 2509783 |
| Sunset* | lon 116.3833, lat 39.9, tz 8.0 | 0.876318 | 62.000000 | 953666 | 1564709 | 38705 |

---

### 🎨 推荐实现 (Reference Implementation)

本项目为核心算法库。如需查看基于本库构建的专业紫微斗数/八字排盘 UI 实现，请参考：

*   **[OpenDestiny](https://github.com/RedSC1/opendestiny-flutter)** - 开源易学排盘工具（Flutter 桌面版/全平台）。

## 📚 感谢

*   许剑伟（寿星天文历（万年历）原作者）
*   [dart-spa](https://pub.dev/packages/spa)

## 📄 License

MIT
