import 'package:sxwnl_spa_dart/src/astro_date_time.dart';
import 'package:sxwnl_spa_dart/src/jie_qi.dart';
import 'package:sxwnl_spa_dart/src/sxwnl/ssq.dart';
import 'package:sxwnl_spa_dart/src/models/calendar.dart';

void main() {
  final int year = 1645;
  print("=== Comparing Solar Terms for Year $year ===");

  // 1. Get accurate astronomical solar terms
  final accurateJqs = getYearJieQi(year);

  // 2. Get historical calendar solar terms (from SSQ.calcY)
  final ssq = SSQ();
  final res = ssq.calcY(AstroDateTime(year, 6, 1).toJ2000());

  print("Index | Name     | Modern Date (Time)      | Hist Date | Match?");
  print("------|----------|-------------------------|-----------|-------");

  // ZQ contains 25 items:
  // ZQ[0] is Dongzhi of previous year (1644)
  // ZQ[1] is XiaoHan of this year (1645)
  // ...
  // ZQ[24] is Dongzhi of this year (1645)

  for (int k = 1; k <= 24; k++) {
    final histJD = res.zq[k];
    final histDt = AstroDateTime.fromBJJ2000(histJD);

    // Find the corresponding accurate JQ
    final jqName = jieQiNames[(k + 23) % 24];
    final accJq = accurateJqs.firstWhere(
      (j) => j.name == jqName,
      orElse: () => JieQiResult(
        index: -1,
        name: "N/A",
        jd: 0,
        dateTime: AstroDateTime(0, 0, 0),
      ),
    );

    final modernDt = accJq.dateTime;
    final modernDateStr =
        "${modernDt.year}-${_pad(modernDt.month)}-${_pad(modernDt.day)}";
    final histDateStr =
        "${histDt.year}-${_pad(histDt.month)}-${_pad(histDt.day)}";

    final match = modernDateStr == histDateStr ? "YES" : "NO!!";

    print(
      "${k.toString().padRight(5)} | ${jqName.padRight(8)} | $modernDateStr (${modernDt.toTimeString()}) | $histDateStr | $match",
    );
  }
}

String _pad(int n) => n.toString().padLeft(2, '0');
