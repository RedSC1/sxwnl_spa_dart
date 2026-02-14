# sxwnl_spa_dart

> Chinese calendar & astronomical calculations library based on sxwnl + SPA. Provides lunar calendar, solar terms, gan-zhi and true solar time. Comparison scripts are included in the test directory.
>
> 免责声明：本库为 AI 移植版本，作者非天文历法专业，结果不保证完全准确，仅供学习与参考。项目包含一系列对比测试脚本，详见 test 目录。

AI 移植的天文历法库：农历、节气等部分来自寿星天文历（万年历）[sxwnl](https://github.com/sxwnl/sxwnl)，太阳位置算法基于 [dart-spa](https://github.com/pingbird/dart-spa) 并做了魔改调整。

## ✨ 特性

*   **农历节气**：农历排盘与节气计算
*   **太阳位置**：真太阳时、均时差、日出日落、日上中天
*   **干支排盘**：四柱干支计算
*   **历史历法**：春秋、战国、秦汉等时期的历法规则（已移植部分）
*   **纯 Dart**：零 Native 依赖，全平台支持

## 📦 安装

```yaml
dependencies:
  sxwnl_spa_dart:
    path: ../sxwnl_dart
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

*   **Chinese lunar calendar**: lunar year structure and solar terms
*   **Solar position**: true solar time, equation of time, sunrise, sunset, solar noon
*   **Gan-zhi**: four pillars calculation
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
