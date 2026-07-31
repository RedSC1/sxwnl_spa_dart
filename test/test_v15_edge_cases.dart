import 'package:test/test.dart';
import 'package:sxwnl_spa_dart/src/astro_date_time.dart';
import 'package:sxwnl_spa_dart/src/jie_qi.dart';

void main() {
  group('v0.15.0 Slot 机制边缘情况测试', () {
    test('1. 压线测试 (Exact Boundary)：目标时间正好是交节时刻', () {
      // 2025年立春的精确时刻（北京时间）大约是 2025-02-03 22:10:28
      final result = getSpecificJieQi(2025, 21); // 立春序号是21 (基于春分0)
      final target = AstroDateTime.fromBJJ2000(result);

      final prev = getPrevJieQi(target);
      final next = getNextJieQi(target);

      // 验证：如果是“交节当天”，getPrevJieQi 应该返回当前的这个节气（因为用的 <=）
      expect(prev?.name, equals('立春'));
      expect((prev!.jd - result).abs(), lessThan(1e-9));

      // 验证：getNextJieQi 应该返回下一个节气（雨水）
      expect(next?.name, equals('雨水'));
    });

    test('2. 历元零点测试 (J2000 Epoch)：2000年1月1日前后', () {
      final y2000 = AstroDateTime(2000, 1, 1, 0, 0, 0);
      final prev = getPrevJieQi(y2000);
      final next = getNextJieQi(y2000);

      // 2000-01-01 是在 1999年冬至 (12-22) 之后, 2000年小寒 (01-06) 之前
      expect(prev?.name, equals('冬至'));
      expect(next?.name, equals('小寒'));
    });

    test('3. 远古/负数年份测试 (BC Years)：环形映射验证', () {
      // 公元前 2000 年 (天文年 -1999)
      final bcTime = AstroDateTime(-1999, 6, 1, 12, 0, 0);

      final prev = getPrevJieQi(bcTime);
      final next = getNextJieQi(bcTime);

      expect(prev, isNotNull);
      expect(next, isNotNull);

      // 只要能跑通且不报错，就说明 slot % 24 的负数处理没问题
      print('BC 2000 Prev: ${prev?.name} @ ${prev?.dateTime}');
      print('BC 2000 Next: ${next?.name} @ ${next?.dateTime}');
    });

    test('4. 逻辑闭环测试 (Logical Closure)', () {
      final today = AstroDateTime(2027, 8, 15, 12, 0, 0);

      // 今天 -> 前一个 -> 下一个
      final p1 = getPrevJieQi(today);
      expect(p1?.name, equals('立秋'));

      final targetDate = AstroDateTime.fromBJJ2000(p1!.jd);
      print('Logical Closure DEBUG:');
      print('  p1!.jd = ${p1.jd}');
      print(
        '  reconstructed jd = ${targetDate.toJ2000() - 8 / 24}',
      ); // UTC JD? AstroDateTime uses local time depending on constructor.

      final n1 = getNextJieQi(targetDate);
      expect(n1?.name, equals('处暑'), reason: '节气当天的Next应该是下一格');

      // 下一个 -> 前一个
      final n2 = getNextJieQi(today);
      final p2 = getPrevJieQi(AstroDateTime.fromBJJ2000(n2!.jd));
      expect(p2?.name, equals(n2.name), reason: '节气当天的Prev应该是自己');
    });

    test('5. 节/气 过滤测试', () {
      final target = AstroDateTime(
        2025,
        3,
        1,
        12,
        0,
        0,
      ); // 处于 惊蛰(节) 之前, 雨水(气) 之后

      final prevJie = getPrevJie(target);
      final prevQi = getPrevQi(target);

      expect(prevJie?.name, equals('立春'), reason: '3月1日的前一个"节"是立春');
      expect(prevQi?.name, equals('雨水'), reason: '3月1日的前一个"气"是雨水');
    });

    test('6. 近日点/远日点 轨道极速测试', () {
      // 1月初 (近日点，地球最快)
      final perihelion = AstroDateTime(2026, 1, 3, 12, 0, 0);
      final p1 = getPrevJieQi(perihelion);
      expect(p1?.name, equals('冬至'));

      // 7月初 (远日点，地球最慢)
      final aphelion = AstroDateTime(2026, 7, 4, 12, 0, 0);
      final p2 = getPrevJieQi(aphelion);
      expect(p2?.name, equals('夏至'));
    });
  });
}
