# sxwnl_spa_dart

> Chinese calendar & astronomical calculations library based on sxwnl + SPA. Provides lunar calendar, solar terms, gan-zhi and true solar time. Comparison scripts are included in the test directory.
>
> 免责声明：本库为 AI 参考与实现版本，作者非天文历法专业，结果不保证完全准确，仅供学习与参考。项目包含一系列对比测试脚本，详见 test 目录。如使用本项目或本包，请标注算法原作者与来源（寿星天文历作者：许剑伟）。商用提醒：本项目代码采用 MIT 协议开源，但算法本身的商业使用授权需由使用者自行联系原作者取得。作者不承担因第三方商业行为引发的任何版权争议或法律责任。
>
> Disclaimer: This project is an AI-assisted implementation for learning/reference only. Accuracy is not guaranteed. Please credit the original algorithm author (SXWNL author: Xu Jianwei) when using this project/package. For commercial use, obtain authorization from the original algorithm author first. Commercial use of this project's code is under the MIT license, but commercial use of the underlying algorithms requires separate permission from the original author; the maintainer assumes no liability for any third-party commercial use.

天文历法计算参考寿星天文历（万年历）[sxwnl](https://github.com/sxwnl/sxwnl)，太阳位置算法参考 [dart-spa](https://github.com/pingbird/dart-spa) 并做了魔改调整。

## ✨ 特性

*   **农历转换**：`LunarDate` 支持阳历 ↔ 农历双向转换，兼容历史特殊月名
*   **农历节气**：农历排盘与节气计算
*   **太阳位置**：真太阳时、均时差、日出日落、日上中天
*   **干支排盘**：类型安全的 `TianGan`/`DiZhi`/`GanZhi`/`BaZi` 模型 + `calcBaZi()` API
*   **时间封装**：`TimePack` 统一管理钟表时间、真太阳时、UTC 时间
*   **日历工具**：`dayGanZhi()` 单日查询、公历/农历/节气三种月份边界的逐日干支表
*   **历史历法**：春秋、战国、秦汉等时期的历法规则（已移植部分）
*   **纯 Dart**：零 Native 依赖，全平台支持

## 📦 安装

```yaml
dependencies:
  sxwnl_spa_dart: ^0.10.1
```

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

### 8. 日历工具 (Calendar Utilities)

```dart
import 'package:sxwnl_spa_dart/sxwnl_spa_dart.dart';

void main() {
  // 查询某天的日干支
  final gz = dayGanZhi(AstroDateTime(2026, 2, 17));
  print('日干支: $gz'); // 壬戌

  // 公历月份日历
  final solarDays = getSolarMonthDays(2026, 3);
  for (final d in solarDays) {
    print('${d.solarDate.day}日: ${d.ganZhi}');
  }

  // 农历月份日历
  final lunarDays = getLunarMonthDays(2025, "正");
  print('正月有 ${lunarDays.length} 天');

  // 节气月份日历（上一个节 ~ 下一个节）
  final jqDays = getJieQiPeriodDays(AstroDateTime(2026, 3, 15));
  print('节气月有 ${jqDays.length} 天');
}
```

## ✅ 测试结果

*   静态分析：dart analyze 通过
*   对比基准：sxwnl 寿星天文历(万年历) 5.10 原作者: 许剑伟（https://github.com/sxwnl/sxwnl）
*   对比范围：节气/朔、日上中天、日出、日落（均与 sxwnl 对比，不与 spa 对比）
*   对比脚本：test/compare_jq.dart、test/compare_solar_noon.dart、test/compare_sunrise.dart、test/compare_sunset.dart
*   说明：未随包附带 sxwnl 原始源码，运行对比脚本需自行从 sxwnl 仓库下载后放入 test/sxwnl_js
*   基准数据：test/compute_*_js.js 生成 js_*.json
*   具体数值（由于太阳位置算法实现不同，日出/日上中天/日落存在秒级差异属于正常现象）：

| 指标 | 参数 | avg_diff_seconds | max_diff_seconds | exact_second | lt_4s | gt_4s |
| --- | --- | --- | --- | --- | --- | --- |
| 节气 | years: -2000..5000, total_terms: 168024 | 0.000000 | 0.000000 | 168024 | - | - |
| 朔 | years: -2000..5000, total_terms: 86591 | 0.000000 | 0.000000 | 86591 | - | - |
| 日上中天 | lon 116.3833, lat 39.9, tz 8.0, total_days 2557080 | 0.804249 | 18.000000 | 1032940 | 1494625 | 29515 |
| 日出 | lon 116.3833, lat 39.9, tz 8.0, total_days 2557080 | 57.273736 | 191.000000 | 6747 | 40550 | 2509783 |
| 日落 | lon 116.3833, lat 39.9, tz 8.0, total_days 2557080 | 0.876318 | 62.000000 | 953666 | 1564709 | 38705 |

## English

Chinese calendar & astronomical calculations library based on sxwnl + SPA.

### Features

*   **Lunar conversion**: `LunarDate` for solar ↔ lunar bidirectional conversion
*   **Chinese lunar calendar**: lunar year structure and solar terms
*   **Solar position**: true solar time, equation of time, sunrise, sunset, solar noon
*   **Gan-zhi**: type-safe `TianGan`/`DiZhi`/`GanZhi`/`BaZi` models + `calcBaZi()` API
*   **Time packing**: `TimePack` for unified clock/solar/UTC time management
*   **Calendar utilities**: `dayGanZhi()`, day range queries, solar/lunar/jieqi month calendars
*   **Historical calendars**: partial rules for Spring/Autumn, Warring States, Qin/Han
*   **Pure Dart**: no native dependencies

### Installation

```yaml
dependencies:
  sxwnl_spa_dart:
    path: ../sxwnl_dart
```

### Quick Start

See the Chinese examples above: 真太阳时 / 农历排盘 / 干支计算.

### Test Results

*   Static analysis: dart analyze
*   Baseline: sxwnl 5.10 by Xu Jianwei (https://github.com/sxwnl/sxwnl)
*   Scope: solar terms/new moons, solar noon, sunrise, sunset (all compared to sxwnl, not SPA)
*   Scripts: test/compare_jq.dart, test/compare_solar_noon.dart, test/compare_sunrise.dart, test/compare_sunset.dart
*   Note: the original sxwnl sources are not bundled; download from sxwnl repo and place under test/sxwnl_js to run scripts
*   Data: test/compute_*_js.js generates js_*.json
*   Numbers (second-level differences in solar position are expected due to algorithm differences):

| Metric | Params | avg_diff_seconds | max_diff_seconds | exact_second | lt_4s | gt_4s |
| --- | --- | --- | --- | --- | --- | --- |
| Solar terms | years: -2000..5000, total_terms: 168024 | 0.000000 | 0.000000 | 168024 | - | - |
| New moons | years: -2000..5000, total_terms: 86591 | 0.000000 | 0.000000 | 86591 | - | - |
| Solar noon | lon 116.3833, lat 39.9, tz 8.0, total_days 2557080 | 0.804249 | 18.000000 | 1032940 | 1494625 | 29515 |
| Sunrise | lon 116.3833, lat 39.9, tz 8.0, total_days 2557080 | 57.273736 | 191.000000 | 6747 | 40550 | 2509783 |
| Sunset | lon 116.3833, lat 39.9, tz 8.0, total_days 2557080 | 0.876318 | 62.000000 | 953666 | 1564709 | 38705 |

## 📚 感谢

*   许剑伟（寿星天文历（万年历）原作者）
*   [dart-spa](https://pub.dev/packages/spa)

## 📄 License

MIT
