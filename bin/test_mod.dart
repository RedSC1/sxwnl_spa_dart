import 'dart:math' as math;
import '../lib/src/sxwnl/math_utils.dart';
import '../lib/src/sxwnl/nutation.dart';
import '../lib/src/sxwnl/delta_t.dart';

void main() {
  double jd = -1460987.3333333333;
  double L = 116.3833 / 180 * math.pi;

  var dt1 = dtT(jd);
  print('dt= $dt1');
  var E1 = hcjj(jd / 36525.0);
  print('E= $E1');
  var m = jsMod2(jd + L / pi2, 1);
  print('jsMod2(jd+L/pi2, 1)= $m');
  print('jd after jsMod2= ${jd - m}');
}
