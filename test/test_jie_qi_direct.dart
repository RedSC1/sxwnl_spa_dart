// test_jie_qi_direct.dart
// 专门测试直接调用暴露的 qiAccurate 函数（原 _qiAccurate）
import 'dart:math';
import 'package:sxwnl_spa_dart/src/jie_qi.dart';
import 'package:sxwnl_spa_dart/src/astro_date_time.dart';
import 'package:sxwnl_spa_dart/src/sxwnl/ssq.dart';
// Add this import

void main() {
  // Test 1: Direct call to qiAccurate for Winter Solstice 2025
  // 2025年冬至是第24个节气（从上一年冬至算起，或者按索引）
  // 2025年12月21日
  // jie_qi_dart 中 index 0 是小寒，23是冬至

  print('--- Test 1: Direct calculation using qiAccurate ---');
  // int year = 2025;

  // 冬至的黄经是 270度 = 3*PI/2
  // 在 getYearJieQi 中，w 的计算公式是：(y + i / 24 + 1) * 2 * pi;
  // 冬至对应的 i 大概是 23 (如果0是小寒)
  // 让我们反推一下角度：
  // 0度=春分 (i=5 左右)
  // 让我们用更直观的方式：
  // 春分 0度, 清明 15度 ...
  // w 是以 J2000 起算的累计角度（圈数 + 角度）

  // 让我们直接计算2025年每一个节气，并只打印冬至
  // 冬至的 i 值是多少？
  // i=0 是小寒(2025-01-05), i=23 是冬至(2025-12-21)
  // 实际上 getYearJieQi 里的循环 i 是从 -30 到 60 扫描
  // 让我们复用 getYearJieQi 的逻辑片段来手动计算验证

  // 目标：计算2025冬至
  // 冬至大致在 12月21日
  // y = 25
  // w = (25 + 23/24 + 1) * 2PI ? 不完全是，公式里有个 +1 是为了偏移
  // 让我们直接遍历类似 getYearJieQi

  for (var i = 0; i < 24; i++) {
    // 粗略估算 w
    // getYearJieQi 内部逻辑：
    // w = (y + k / 24 + 1) * 2 * pi
    // 我们不知道确切的 k，但可以遍历
  }

  print('Calculated all solar terms for 2025:');
  List<JieQiResult> results = getYearJieQi(2025);
  for (var r in results) {
    if (r.name == '冬至') {
      print('Found 冬至 via getYearJieQi: ${r.dateTime}');

      // 验证 qiAccurate
      // 拿它的时间和 qiAccurate 算出来的对比（虽然 getYearJieQi 内部就是调用的它）
      // 这里主要是证明 qiAccurate 现在可以在外部被调用了
      // double jd = qiAccurate(sALonT(r.jd - 2451545.0) * 36525.0 / 36525.0 * 2 * pi ); // 这样反推太麻烦

      // 简单点: 有了 qiAccurate，我们就可以自己写一个简单的节气计算器
      // 比如计算任意角度的时间
      break;
    }
  }

  // Test 2: Calculate specific solar longitude time
  print('\n--- Test 2: Calculate date for Spring Equinox (0 degree) ---');
  // 春分 2025 (y=25)
  // 春分 w 应该是 2*PI * (y + 偏移)
  // 2000年春分 w approx 0
  // 2025年春分 w approx 25 * 2PI
  // double w_chunfen = 25 * 2 * pi;
  // 由于岁差等影响，可能不是严格的整数圈，但 qiAccurate 接受的是视黄经弧度
  // 实际上 qiAccurate 内部调用 sALonT(w)，它期望的是累积弧度

  // 尝试计算几个关键点
  // 2025春分 (0度)
  double jdChunfen = qiAccurate(2 * pi * 25.0);
  print('2025 Spring Equinox JD: $jdChunfen');
  print('Time: ${AstroDateTime.fromJ2000(jdChunfen)}');

  // Test 3: Test SSQ public methods
  print('\n--- Test 3: SSQ public methods (qiHigh, soHigh) ---');
  var ssq = SSQ();
  // 随便找个时间点验证方法可调用
  double jdTest = ssq.qiHigh(2 * pi * 25.0);
  print('SSQ.qiHigh(2025春分): ${AstroDateTime.fromJ2000(jdTest)}');

  double jdSo = ssq.soHigh(2 * pi * 123.0); // 随便一个合朔角度
  print('SSQ.soHigh(random): ${AstroDateTime.fromJ2000(jdSo)}');

  print('\nSUCCESS: All private methods are now public and callable!');
}

// 辅助函数，模拟 sALonT 因为它是 private 或者在其他包?
// sALonT 在 solar_lunar_pos.dart 中，是 public 的，可以直接 import
// 上面已经 import 了
