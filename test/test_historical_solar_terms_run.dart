import 'package:sxwnl_spa_dart/src/astro_date_time.dart';
import 'package:sxwnl_spa_dart/src/models/calendar.dart';

void main() {
  print("Start");
  final daysHistorical = getSolarMonthDays(
    1650,
    1,
    useHistoricalSolarTerms: true,
  );
  print(daysHistorical.length);
}
