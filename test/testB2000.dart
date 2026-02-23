import 'package:sxwnl_spa_dart/sxwnl_spa_dart.dart';

void main() {
  // 获取一年所有节气
  final jqB2001 = getYearJieQi(-2000);
  for (final jq in jqB2001) {
    print('${jq.name}: ${jq.dateTime}');
  }
}
