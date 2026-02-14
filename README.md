# sxwnl_spa_dart

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

### 1. 真太阳时

```dart
import 'package:sxwnl_spa_dart/sxwnl_spa_dart.dart';

void main() {
  final time = AstroDateTime(2023, 1, 22, 12, 0, 0);
  final loc = Location(87.6, 43.8);
  final res = calcTrueSolarTime(time, loc);

  print('平太阳时: $time');
  print('真太阳时: ${res.trueSolarTime}');
  print('日上中天: ${res.solarNoon}');
  print('均时差: ${res.equationOfTime.inMinutes} 分钟');
}
```

### 2. 农历排盘

```dart
import 'package:sxwnl_spa_dart/sxwnl_spa_dart.dart';

void main() {
  final ssq = SSQ();
  final jd2023 = AstroDateTime(2023, 6, 1).toJ2000();
  final res = ssq.calcY(jd2023);

  print('闰月索引: ${res.leap}');
  for (int i = 0; i < 14; i++) {
    final dt = AstroDateTime.fromJ2000(res.hs[i]);
    print('${res.ym[i]}月: ${dt.year}-${dt.month}-${dt.day}');
  }
}
```

### 3. 干支计算

干支计算需要 J2000 相对 JD，日柱与时柱建议使用真太阳时 JD。

```dart
import 'package:sxwnl_spa_dart/sxwnl_spa_dart.dart';

void main() {
  final dt = AstroDateTime(2023, 2, 4, 12, 0, 0);
  final loc = Location(116.4, 39.9);
  final trueSolar = calcTrueSolarTime(dt, loc);
  final jdUt = dt.toJ2000() - 8 / 24;
  final bazi = calcGanZhi(jdUt, trueSolar.trueSolarTime.toJ2000());
  print('八字: $bazi');
}
```

## ✅ 测试结果

*   静态分析：dart analyze 通过
*   对比基准：sxwnl 寿星天文历(万年历) 5.10 原作者: 许剑伟（https://github.com/sxwnl/sxwnl）
*   对比范围：节气/朔、日上中天、日出、日落（均与 sxwnl 对比，不与 spa 对比）
*   对比脚本：test/compare_jq.dart、test/compare_solar_noon.dart、test/compare_sunrise.dart、test/compare_sunset.dart
*   基准数据：test/compute_*_js.js 生成 js_*.json
*   具体数值（由于太阳位置算法实现不同，日出/日上中天/日落存在秒级差异属于正常现象）：
    *   节气（years: -2000..5000, total_terms: 168024）：avg_diff_seconds 0.000000，max_diff_seconds 0.000000，exact_second 168024
    *   朔（years: -2000..5000, total_terms: 86591）：avg_diff_seconds 0.000000，max_diff_seconds 0.000000，exact_second 86591
    *   日上中天（lon 116.3833, lat 39.9, tz 8.0, total_days 2557080）：avg_diff_seconds 0.804249，max_diff_seconds 18.000000，exact_second 1032940，lt_4s 1494625，gt_4s 29515
    *   日出（lon 116.3833, lat 39.9, tz 8.0, total_days 2557080）：avg_diff_seconds 57.273736，max_diff_seconds 191.000000，exact_second 6747，lt_4s 40550，gt_4s 2509783
    *   日落（lon 116.3833, lat 39.9, tz 8.0, total_days 2557080）：avg_diff_seconds 0.876318，max_diff_seconds 62.000000，exact_second 953666，lt_4s 1564709，gt_4s 38705

## 📚 感谢

*   许剑伟（寿星天文历（万年历）原作者）
*   [dart-spa](https://pub.dev/packages/spa)

## 📄 License

MIT
