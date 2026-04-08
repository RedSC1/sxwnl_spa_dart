# sxwnl_spa_dart

> Chinese calendar & astronomical calculations library based on sxwnl + SPA. Provides lunar calendar, solar terms, gan-zhi and true solar time. Comparison scripts are included in the test directory.
>
> 免责声明：本库为 AI 参考与实现版本，作者非天文历法专业，结果不保证完全准确，仅供学习与参考。项目包含一系列对比测试脚本，详见 test 目录。如使用本项目或本包，请标注算法原作者与来源（寿星天文历作者：许剑伟）。商用提醒：本项目代码采用 MIT 协议开源，但算法本身的商业使用授权需由使用者自行联系原作者取得。作者不承担因第三方商业行为引发的任何版权争议或法律责任。
>
> Disclaimer: This project is an AI-assisted implementation for learning/reference only. Accuracy is not guaranteed. Please credit the original algorithm author (SXWNL author: Xu Jianwei) when using this project/package. For commercial use, obtain authorization from the original algorithm author first. Commercial use of this project's code is under the MIT license, but commercial use of the underlying algorithms requires separate permission from the original author; the maintainer assumes no liability for any third-party commercial use.

天文历法计算参考寿星天文历（万年历）[sxwnl](https://github.com/sxwnl/sxwnl)，太阳位置算法参考 [dart-spa](https://github.com/pingbird/dart-spa) 并做了深度适配与调整。

## ✨ 特性

*   **农历转换**：`LunarDate` 支持阳历 ↔ 农历双向转换，兼容历史特殊月名
*   **农历节气**：农历排盘与节气计算
*   **太阳位置**：真太阳时、均时差、日出日落、日上中天
*   **干支排盘**：类型安全的 `TianGan`/`DiZhi`/`GanZhi`/`BaZi` 模型 + `calcBaZi()` API
*   **时间封装**：`TimePack` 统一管理钟表时间、真太阳时、UTC 时间
*   **一站式模型**：`DayInfo` 对象集成干支、农历、节日、节气、月相、日出日落、星座等全量单日信息
*   **节日民俗**：对标原版 sxwnl (lunar.js) 补全节日库，支持分类过滤与民俗进度显示（如“初伏第3天”）
*   **历史历法**：春秋、战国、秦汉等时期的历法规则（已移植部分）
*   **纯 Dart**：零 Native 依赖，全平台支持

## 📦 安装

```yaml
dependencies:
  sxwnl_spa_dart: ^0.18.5
```

> `0.18.1` 起，`LunarDate.lunarYear` 对外语义真正统一为天文纪年（含公元 0 年）。
> 如需传统显示或历史纪年，可使用 `LunarDate.historicalYear` / `LunarDate.bceYear` / `LunarDate.isBCE`。

## 🚀 快速上手

### 1. 真太阳时 (True Solar Time)

```dart
import 'package:sxwnl_spa_dart/sxwnl_spa_dart.dart';

void main() {
  final time = AstroDateTime(2023, 1, 22, 12, 0, 0);
  final loc = Location(87.6, 43.8);
  final res = calcTrueSolarTime(time, loc);

  print('平太阳时 (Mean Solar Time): $time');
  print('真太阳时 (True Solar Time): ${res.trueSolarTime}');
  print('日上中天 (Solar Noon): ${res.solarNoon}');
  print('均时差 (Equation of Time): ${res.equationOfTime.inMinutes} 分钟');
}
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
    final dt = AstroDateTime.fromJ2000(res.hs[i]);
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
  final jdUt = dt.toJ2000() - 8 / 24;
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

### 10. UI 增强：细分月相扩展 (8 Moon Phases)

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

### 11. 太阳算法切换 (Algorithm Switch)

本库支持在 SPA (现代物理模型) 与 SXWNL (古典解析模型) 之间自由切换。建议普通天气应用使用 SPA，而需要与古典历书对齐的应用使用 SXWNL。

```dart
import 'package:sxwnl_spa_dart/sxwnl_spa_dart.dart';

void main() {
  final date = AstroDateTime(2026, 3, 4, 12, 0, 0);
  final loc = Location(116.3833, 39.9);

  // 1. 使用 SPA 算法 (默认)
  final resSpa = calcTrueSolarTime(date, loc, method: SolarCalcMethod.spa);
  print('SPA 算法日出: ${resSpa.sunrise}');

  // 2. 使用 SXWNL 原生算法 (基于 VSOP87 高度适配)
  final resSxwnl = calcTrueSolarTime(date, loc, method: SolarCalcMethod.sxwnl);
  print('SXWNL 算法日出: ${resSxwnl.sunrise}');

  // 3. 在批量 API 中应用
  final days = getSolarMonthDays(2026, 3, location: loc, solarMethod: SolarCalcMethod.sxwnl);
}
```

## 🌗 架构漫谈：为什么同时内置了两套天文算法？

本库的一个独特之处是**双算法架构**：同时保留了原版 `sxwnl` 的原生算法体系，以及引入了 NREL SPA (Solar Position Algorithm) 算法。

源于历史契机与对精度的追求，这里形成了一个巧妙的互补架构：

1. **SPA (Solar Position Algorithm)**
   * **来源**: 美国国家可再生能源实验室（NREL）发布的极高精度算法（原作者在早期开发时为了能快速实现真太阳时而引用了 `dart-spa` 包）。
   * **特点**: 基于现代高精度的纯物理模型，主要靠无迭代的数学解析式解析，极其精准且不存在迭代产生的浮点漂移。
   * **用途**: 目前库内 `calcTrueSolarTime`（真太阳时、日出日落时分、均时差）等不需要复杂中国古典历书修正的 API，均主要由 SPA 高速驱动。

2. **SXWNL 原生算法 (基于 VSOP87 的深度适配与历史历法历表)**
   * **来源**: 著名开源天文历框架《寿星天文历》，我们在 Dart 版本中以 100% 的同构逻辑重新移植了其大循环核心基线。
   * **特点**: 拥有极其复杂的牛顿逼近循环系统，以及海量的“历史朝代历法校准表格”。为了做到和古书分毫不差（如汉朝太初历、唐代大衍历等建正法则），它自带庞大的查表缓存与整数截断过滤系统。
   * **用途**: 农历排盘 (`LunarDate`)、历史节气时刻 (`SSQ`)、月相盈亏、干支纪年等涉及中国传统阴阳合历的深水区算法，依然坚如磐石地交由 `sxwnl` 核心算法模块运算。

**好钢用在刀刃上**：通过这两套体系并存，并通过 `SolarCalcMethod` 开关显式对外暴露，开发者可以根据业务场景（现代授时 vs 古典历法）灵活选择合适的算法底座。同时，这也为跨语言、跨架构的 1500 万次浮点运算全量验证提供了可靠的对照基准。

## ✅ 测试结果

*   静态分析：dart analyze 通过
*   对比基准：sxwnl 寿星天文历(万年历) 5.10 原作者: 许剑伟（https://github.com/sxwnl/sxwnl）
*   对比范围：节气/朔、日上中天、日出、日落（均与 sxwnl 对比，不与 spa 对比）
*   对比脚本：test/compare_jq.dart、test/compare_solar_noon.dart、test/compare_sunrise.dart、test/compare_sunset.dart
*   说明：未随包附带 sxwnl 原始源码，运行对比脚本需自行从 sxwnl 仓库下载后放入 test/sxwnl_js
*   基准数据：test/compute_*_js.js 生成 js_*.json
*   测试项不仅包含核心算法本身，也包含了与原版同样的查表修正（如 SSQ 的历史历法修正数据）。
*   具体数值（由于太阳位置算法实现不同，日出/日上中天/日落存在秒级差异属于正常现象）：

| 指标 | 参数 | avg_diff_seconds | max_diff_seconds | exact_second | lt_1s | gt_1s |
| --- | --- | --- | --- | --- | --- | --- |
| 节气 (`compare_jq`) | years: -2000..5000, 纯浮点对比 | 0.000000 | 0.000000 | 168024 | 0 | 0 |
| 农历基线 (`compare_ssq`) | years: -2000..5000, 包含历史表与月建 | 0.000000 | 0.000000 | 7001年完全一致 | 0 | 0 |
| 日月升中降 (`compare_szj`) | years: -2000..5000, 纯浮点对比 | 0.000026 | 0.000110 | 15341686 | 794 | 0 |
| 日上中天 (`compare_solar_noon`)* | lon 116.3833, lat 39.9, tz 8.0 | 0.804249 | 18.000000 | 1032940 | 1494625 | 29515 |
| 日出 (`compare_sunrise`)* | lon 116.3833, lat 39.9, tz 8.0 | 57.273736 | 191.000000 | 6747 | 40550 | 2509783 |
| 日落 (`compare_sunset`)* | lon 116.3833, lat 39.9, tz 8.0 | 0.876318 | 62.000000 | 953666 | 1564709 | 38705 |

*\*注：带有 \* 号的为 SPA 等纯解析算法测试项，非直接依赖 SXWNL 的原生迭代方法。*

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
  sxwnl_spa_dart: ^0.18.5
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
