import 'package:sxwnl_spa_dart/sxwnl_spa_dart.dart';

void main() {
  final ssq = SSQ();
  final jd = AstroDateTime(2034, 1, 15).toJ2000();
  final res = ssq.calcY(jd);
  final leapIndex = res.leap;
  final leapName = leapIndex == 0 ? '无闰月' : '闰${res.ym[leapIndex]}月';
  print('2033 leapIndex=$leapIndex leapName=$leapName');
  print('hs13=${res.hs[13]} zq24=${res.zq[24]}');
  for (var i = 0; i < res.ym.length; i++) {
    final tag = leapIndex > 0 && i == leapIndex ? '(闰)' : '';
    print('${i.toString().padLeft(2, '0')} ${res.ym[i]}月 $tag');
  }
}
