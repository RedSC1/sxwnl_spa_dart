import 'dart:math' as math;
import '../lib/src/sxwnl/szj.dart';

void main() {
  var szj = SZJ();
  szj.L = 116.3833 / 180 * math.pi;
  szj.fa = 39.9 / 180 * math.pi;
  var jdUtNoon = -1460987.3333333333;
  var r = szj.st(jdUtNoon);
  print(r.s);
}
