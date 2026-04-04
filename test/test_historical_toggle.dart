
import 'package:sxwnl_spa_dart/src/sxwnl/ssq.dart';

void main() {
  final ssq = SSQ();
  
  print('--- 验证 1500 年 (历史规则: 平气/平朔) ---');
  double jd1500 = -182621.0; 

  double q_hist = ssq.calc(jd1500, 1, enableHistoricalRules: true);
  double q_theory = ssq.calc(jd1500, 1, enableHistoricalRules: false);

  print('开启历史规则 (平气): $q_hist');
  print('关闭历史规则 (定气): $q_theory');

  if (q_hist != q_theory) {
    print('✅ 验证成功: calc 结果存在差异，说明 enableHistoricalRules 参数已成功切换计算引擎（平气 vs 定气）。');
  }

  print('\n--- 验证 1750 年 (历史规则: 修正表) ---');
  bool diffFound = false;
  // 扩大搜索范围，寻找修正表生效的点
  for (int i = 0; i < 120; i++) {
    double jd = -91310.0 + i * 29.53;
    double s_hist = ssq.calc(jd, 0, enableHistoricalRules: true);
    double s_theory = ssq.calc(jd, 0, enableHistoricalRules: false);
    if (s_hist != s_theory) {
      print('月份 $i 检测到修正表差异 (JD relative to J2000):');
      print('  历史模式: $s_hist');
      print('  理论模式: $s_theory');
      diffFound = true;
      break;
    }
  }

  if (diffFound) {
    print('✅ 验证成功: 成功在 1750 年附近检测到修正表的加减天操作已被 enableHistoricalRules 绕过。');
  } else {
    print('ℹ️ 未检测到修正表差异。');
  }
}
