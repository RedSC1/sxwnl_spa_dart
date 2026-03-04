/// 节日系统 (Festivals)
///
/// 采用双维度解耦设计：
/// 1. FestivalSource: 表达计算来源 (公历、农历、星期等)
/// 2. FestivalLevel: 表达存在感/重要程度 (法定、传统、流行、纪念、历史、民族)
///
/// 数据说明：
/// 本模块节日数据严格遵循原版 sxwnl (lunar.js) 的定义。部分节日的日期或起始年份（如正月廿九送穷日、
/// 国际气象节、愚人节起源年等）可能在史实或地域习俗上存在多解，但为保持与原版逻辑的 100% 兼容性，
/// 本库默认不做擅自修正。
library;

import '../models/lunar_date.dart';
import '../astro_date_time.dart';
import '../jie_qi.dart';
import '../models/gan_zhi.dart';
import '../models/calendar.dart';

/// 节日计算来源
enum FestivalSource {
  /// 公历固定
  solar,
  /// 农历固定
  lunar,
  /// 星期规则 (如: 5月第2个周日)
  weekBased,
  /// 节气关联 (如: 清明、冬至)
  termBased,
  /// 特殊推算 (如: 三伏、数九、梅雨)
  custom,
}

/// 节日重要性级别
enum FestivalLevel {
  /// 1. 法定节假日 (有假放的)
  statutory,
  /// 2. 传统/民俗节日 (元宵、七夕、中秋等)
  traditional,
  /// 3. 流行/社交节日 (情人节、母亲节、教师节等)
  popular,
  /// 4. 24 节气
  solarTerm,
  /// 5. 科普/国际纪念日 (世界水日、禁毒日等)
  commemorative,
  /// 6. 历史纪念日 (建军、抗战胜利、公祭日等)
  historical,
  /// 7. 少数民族节日/地方民俗 (瑶族忌鸟节、送穷日等)
  ethnic,
}

/// 节日对象
class Festival {
  final String name;
  final FestivalSource source;
  final FestivalLevel level;
  final bool isPublicHoliday;
  final int startYear;
  final int endYear;

  const Festival(
    this.name, {
    required this.source,
    required this.level,
    this.isPublicHoliday = false,
    this.startYear = 0,
    this.endYear = 9999,
  });

  bool isValidAt(int year) => year >= startYear && year <= endYear;

  @override
  String toString() => name;
}

class FestivalEngine {
  /// 农历节日数据库 (完全版 - 严格对标原版数据)
  static const Map<String, List<Festival>> _lunarFtv = {
    "0101": [Festival("春节", source: FestivalSource.lunar, level: FestivalLevel.statutory, isPublicHoliday: true)],
    "0102": [Festival("大年初二", source: FestivalSource.lunar, level: FestivalLevel.traditional)],
    "0115": [
      Festival("元宵节", source: FestivalSource.lunar, level: FestivalLevel.statutory, isPublicHoliday: true),
      Festival("上元节", source: FestivalSource.lunar, level: FestivalLevel.traditional),
      Festival("壮族歌墟节", source: FestivalSource.lunar, level: FestivalLevel.ethnic),
      Festival("苗族踩山节", source: FestivalSource.lunar, level: FestivalLevel.ethnic),
      Festival("达斡尔族卡钦", source: FestivalSource.lunar, level: FestivalLevel.ethnic),
    ],
    "0116": [Festival("侗族芦笙节", source: FestivalSource.lunar, level: FestivalLevel.ethnic)],
    "0125": [Festival("填仓节", source: FestivalSource.lunar, level: FestivalLevel.ethnic)],
    "0129": [Festival("送穷日", source: FestivalSource.lunar, level: FestivalLevel.ethnic)],
    "0201": [Festival("瑶族忌鸟节", source: FestivalSource.lunar, level: FestivalLevel.ethnic)],
    "0202": [
      Festival("龙抬头", source: FestivalSource.lunar, level: FestivalLevel.traditional),
      Festival("春龙节", source: FestivalSource.lunar, level: FestivalLevel.traditional),
      Festival("畲族会亲节", source: FestivalSource.lunar, level: FestivalLevel.ethnic),
    ],
    "0208": [Festival("傈傈族刀杆节", source: FestivalSource.lunar, level: FestivalLevel.ethnic)],
    "0303": [
      Festival("北帝诞", source: FestivalSource.lunar, level: FestivalLevel.traditional),
      Festival("苗族黎族歌墟节", source: FestivalSource.lunar, level: FestivalLevel.ethnic),
    ],
    "0315": [Festival("白族三月街", source: FestivalSource.lunar, level: FestivalLevel.ethnic)],
    "0323": [
      Festival("妈祖诞辰", source: FestivalSource.lunar, level: FestivalLevel.traditional),
      Festival("天后诞", source: FestivalSource.lunar, level: FestivalLevel.traditional),
    ],
    "0408": [Festival("牛王诞", source: FestivalSource.lunar, level: FestivalLevel.traditional)],
    "0418": [Festival("锡伯族西迁节", source: FestivalSource.lunar, level: FestivalLevel.ethnic)],
    "0505": [Festival("端午节", source: FestivalSource.lunar, level: FestivalLevel.statutory, isPublicHoliday: true)],
    "0513": [
      Festival("关帝诞", source: FestivalSource.lunar, level: FestivalLevel.traditional),
      Festival("阿昌族泼水节", source: FestivalSource.lunar, level: FestivalLevel.ethnic),
    ],
    "0522": [Festival("鄂温克族米阔鲁节", source: FestivalSource.lunar, level: FestivalLevel.ethnic)],
    "0529": [Festival("瑶族达努节", source: FestivalSource.lunar, level: FestivalLevel.ethnic)],
    "0606": [
      Festival("天贶节", source: FestivalSource.lunar, level: FestivalLevel.traditional),
      Festival("姑姑节", source: FestivalSource.lunar, level: FestivalLevel.traditional),
      Festival("壮族祭田节", source: FestivalSource.lunar, level: FestivalLevel.ethnic),
      Festival("瑶族尝新节", source: FestivalSource.lunar, level: FestivalLevel.ethnic),
    ],
    "0624": [Festival("火把节", source: FestivalSource.lunar, level: FestivalLevel.ethnic)],
    "0707": [
      Festival("七夕节", source: FestivalSource.lunar, level: FestivalLevel.traditional),
      Festival("乞巧节", source: FestivalSource.lunar, level: FestivalLevel.traditional),
      Festival("女儿节", source: FestivalSource.lunar, level: FestivalLevel.traditional),
    ],
    "0713": [Festival("侗族吃新节", source: FestivalSource.lunar, level: FestivalLevel.ethnic)],
    "0715": [
      Festival("中元节", source: FestivalSource.lunar, level: FestivalLevel.traditional),
      Festival("鬼节", source: FestivalSource.lunar, level: FestivalLevel.traditional),
    ],
    "0815": [Festival("中秋节", source: FestivalSource.lunar, level: FestivalLevel.statutory, isPublicHoliday: true)],
    "0909": [Festival("重阳节", source: FestivalSource.lunar, level: FestivalLevel.traditional)],
    "1001": [Festival("祭祖节(十月朝)", source: FestivalSource.lunar, level: FestivalLevel.traditional)],
    "1015": [Festival("下元节", source: FestivalSource.lunar, level: FestivalLevel.traditional)],
    "1016": [Festival("瑶族盘王节", source: FestivalSource.lunar, level: FestivalLevel.ethnic)],
    "1208": [Festival("腊八节", source: FestivalSource.lunar, level: FestivalLevel.traditional)],
    "1223": [Festival("北方小年", source: FestivalSource.lunar, level: FestivalLevel.traditional)],
    "1224": [Festival("南方小年", source: FestivalSource.lunar, level: FestivalLevel.traditional)],
  };

  /// 公历节日数据库 (完全版)
  static const Map<String, List<Festival>> _solarFtv = {
    "0101": [Festival("元旦", source: FestivalSource.solar, level: FestivalLevel.statutory, isPublicHoliday: true)],
    "0202": [Festival("世界湿地日", source: FestivalSource.solar, level: FestivalLevel.commemorative)],
    "0210": [Festival("国际气象节", source: FestivalSource.solar, level: FestivalLevel.commemorative)],
    "0214": [Festival("情人节", source: FestivalSource.solar, level: FestivalLevel.popular)],
    "0301": [Festival("国际海豹日", source: FestivalSource.solar, level: FestivalLevel.commemorative)],
    "0303": [Festival("全国爱耳日", source: FestivalSource.solar, level: FestivalLevel.commemorative)],
    "0305": [Festival("学雷锋纪念日", source: FestivalSource.solar, level: FestivalLevel.popular, startYear: 1963)],
    "0308": [Festival("妇女节", source: FestivalSource.solar, level: FestivalLevel.popular)],
    "0312": [
      Festival("植树节", source: FestivalSource.solar, level: FestivalLevel.popular),
      Festival("孙中山逝世纪念日", source: FestivalSource.solar, level: FestivalLevel.commemorative, startYear: 1925),
    ],
    "0314": [Festival("国际警察日", source: FestivalSource.solar, level: FestivalLevel.commemorative)],
    "0315": [Festival("消费者权益日", source: FestivalSource.solar, level: FestivalLevel.popular, startYear: 1983)],
    "0317": [
      Festival("中国国医节", source: FestivalSource.solar, level: FestivalLevel.traditional),
      Festival("国际航海日", source: FestivalSource.solar, level: FestivalLevel.commemorative),
    ],
    "0321": [
      Festival("世界森林日", source: FestivalSource.solar, level: FestivalLevel.commemorative),
      Festival("消除种族歧视国际日", source: FestivalSource.solar, level: FestivalLevel.commemorative),
      Festival("世界儿歌日", source: FestivalSource.solar, level: FestivalLevel.commemorative),
    ],
    "0322": [Festival("世界水日", source: FestivalSource.solar, level: FestivalLevel.popular)],
    "0323": [Festival("世界气象日", source: FestivalSource.solar, level: FestivalLevel.popular)],
    "0324": [Festival("世界防治结核病日", source: FestivalSource.solar, level: FestivalLevel.commemorative, startYear: 1982)],
    "0325": [Festival("全国中小学生安全教育日", source: FestivalSource.solar, level: FestivalLevel.commemorative)],
    "0330": [Festival("巴勒斯坦国土日", source: FestivalSource.solar, level: FestivalLevel.commemorative)],
    "0401": [
      Festival("愚人节", source: FestivalSource.solar, level: FestivalLevel.popular, startYear: 1564),
      Festival("全国爱国卫生运动月", source: FestivalSource.solar, level: FestivalLevel.commemorative),
      Festival("税收宣传月", source: FestivalSource.solar, level: FestivalLevel.commemorative),
    ],
    "0407": [Festival("世界卫生日", source: FestivalSource.solar, level: FestivalLevel.commemorative)],
    "0422": [Festival("世界地球日", source: FestivalSource.solar, level: FestivalLevel.commemorative)],
    "0423": [Festival("世界图书和版权日", source: FestivalSource.solar, level: FestivalLevel.commemorative)],
    "0424": [Festival("亚非新闻工作者日", source: FestivalSource.solar, level: FestivalLevel.commemorative)],
    "0501": [Festival("劳动节", source: FestivalSource.solar, level: FestivalLevel.statutory, isPublicHoliday: true, startYear: 1889)],
    "0504": [Festival("青年节", source: FestivalSource.solar, level: FestivalLevel.popular)],
    "0505": [Festival("碘缺乏病防治日", source: FestivalSource.solar, level: FestivalLevel.commemorative)],
    "0508": [Festival("世界红十字日", source: FestivalSource.solar, level: FestivalLevel.commemorative)],
    "0512": [Festival("国际护士节", source: FestivalSource.solar, level: FestivalLevel.popular)],
    "0515": [Festival("国际家庭日", source: FestivalSource.solar, level: FestivalLevel.popular)],
    "0517": [Festival("世界电信日", source: FestivalSource.solar, level: FestivalLevel.commemorative)],
    "0518": [Festival("国际博物馆日", source: FestivalSource.solar, level: FestivalLevel.commemorative)],
    "0520": [Festival("全国学生营养日", source: FestivalSource.solar, level: FestivalLevel.commemorative)],
    "0523": [Festival("国际牛奶日", source: FestivalSource.solar, level: FestivalLevel.commemorative)],
    "0531": [Festival("世界无烟日", source: FestivalSource.solar, level: FestivalLevel.commemorative)],
    "0601": [Festival("儿童节", source: FestivalSource.solar, level: FestivalLevel.popular, startYear: 1949)],
    "0605": [Festival("世界环境日", source: FestivalSource.solar, level: FestivalLevel.commemorative)],
    "0606": [Festival("全国爱眼日", source: FestivalSource.solar, level: FestivalLevel.commemorative)],
    "0617": [Festival("防治荒漠化和干旱日", source: FestivalSource.solar, level: FestivalLevel.commemorative)],
    "0623": [Festival("国际奥林匹克日", source: FestivalSource.solar, level: FestivalLevel.commemorative)],
    "0625": [Festival("全国土地日", source: FestivalSource.solar, level: FestivalLevel.commemorative)],
    "0626": [Festival("国际禁毒日", source: FestivalSource.solar, level: FestivalLevel.commemorative)],
    "0701": [
      Festival("中共诞辰", source: FestivalSource.solar, level: FestivalLevel.historical, startYear: 1921),
      Festival("香港回归纪念日", source: FestivalSource.solar, level: FestivalLevel.historical, startYear: 1997),
      Festival("世界建筑日", source: FestivalSource.solar, level: FestivalLevel.commemorative),
    ],
    "0702": [Festival("国际体育记者日", source: FestivalSource.solar, level: FestivalLevel.commemorative)],
    "0707": [Festival("抗日战争纪念日", source: FestivalSource.solar, level: FestivalLevel.historical, startYear: 1937)],
    "0711": [Festival("世界人口日", source: FestivalSource.solar, level: FestivalLevel.commemorative)],
    "0730": [Festival("非洲妇女日", source: FestivalSource.solar, level: FestivalLevel.commemorative)],
    "0801": [Festival("建军节", source: FestivalSource.solar, level: FestivalLevel.historical, startYear: 1927)],
    "0808": [Festival("中国男子节(爸爸节)", source: FestivalSource.solar, level: FestivalLevel.popular)],
    "0903": [Festival("抗日战争胜利纪念", source: FestivalSource.solar, level: FestivalLevel.historical, startYear: 1945)],
    "0908": [
      Festival("国际扫盲日", source: FestivalSource.solar, level: FestivalLevel.commemorative, startYear: 1966),
      Festival("国际新闻工作者日", source: FestivalSource.solar, level: FestivalLevel.commemorative),
    ],
    "0909": [Festival("毛泽东逝世纪念", source: FestivalSource.solar, level: FestivalLevel.commemorative, startYear: 1976)],
    "0910": [Festival("教师节", source: FestivalSource.solar, level: FestivalLevel.popular, startYear: 1985)],
    "0914": [Festival("世界清洁地球日", source: FestivalSource.solar, level: FestivalLevel.commemorative)],
    "0916": [Festival("国际臭氧层保护日", source: FestivalSource.solar, level: FestivalLevel.commemorative)],
    "0918": [Festival("九一八事变纪念日", source: FestivalSource.solar, level: FestivalLevel.historical, startYear: 1931)],
    "0920": [Festival("国际爱牙日", source: FestivalSource.solar, level: FestivalLevel.commemorative)],
    "0927": [Festival("世界旅游日", source: FestivalSource.solar, level: FestivalLevel.commemorative)],
    "0928": [Festival("孔子诞辰", source: FestivalSource.solar, level: FestivalLevel.traditional)],
    "1001": [
      Festival("国庆节", source: FestivalSource.solar, level: FestivalLevel.statutory, isPublicHoliday: true, startYear: 1949),
      Festival("世界音乐日", source: FestivalSource.solar, level: FestivalLevel.commemorative),
      Festival("国际老人节", source: FestivalSource.solar, level: FestivalLevel.commemorative),
    ],
    "1002": [
      Festival("国庆节假日", source: FestivalSource.solar, level: FestivalLevel.statutory, isPublicHoliday: true),
      Festival("国际和平与民主自由斗争日", source: FestivalSource.solar, level: FestivalLevel.commemorative),
    ],
    "1003": [Festival("国庆节假日", source: FestivalSource.solar, level: FestivalLevel.statutory, isPublicHoliday: true)],
    "1004": [Festival("世界动物日", source: FestivalSource.solar, level: FestivalLevel.commemorative)],
    "1006": [Festival("老人节", source: FestivalSource.solar, level: FestivalLevel.traditional)],
    "1008": [
      Festival("全国高血压日", source: FestivalSource.solar, level: FestivalLevel.commemorative),
      Festival("世界视觉日", source: FestivalSource.solar, level: FestivalLevel.commemorative),
    ],
    "1009": [
      Festival("世界邮政日", source: FestivalSource.solar, level: FestivalLevel.commemorative),
      Festival("万国邮联日", source: FestivalSource.solar, level: FestivalLevel.commemorative),
    ],
    "1010": [
      Festival("辛亥革命纪念日", source: FestivalSource.solar, level: FestivalLevel.historical, startYear: 1911),
      Festival("世界精神卫生日", source: FestivalSource.solar, level: FestivalLevel.commemorative),
    ],
    "1013": [
      Festival("世界保健日", source: FestivalSource.solar, level: FestivalLevel.commemorative),
      Festival("国际教师节", source: FestivalSource.solar, level: FestivalLevel.commemorative),
    ],
    "1014": [Festival("世界标准日", source: FestivalSource.solar, level: FestivalLevel.commemorative)],
    "1015": [Festival("国际盲人节", source: FestivalSource.solar, level: FestivalLevel.commemorative)],
    "1016": [Festival("世界粮食日", source: FestivalSource.solar, level: FestivalLevel.commemorative)],
    "1017": [Festival("世界消除贫困日", source: FestivalSource.solar, level: FestivalLevel.commemorative)],
    "1022": [Festival("世界传统医药日", source: FestivalSource.solar, level: FestivalLevel.commemorative)],
    "1024": [Festival("联合国日", source: FestivalSource.solar, level: FestivalLevel.commemorative)],
    "1031": [Festival("世界勤俭日", source: FestivalSource.solar, level: FestivalLevel.commemorative)],
    "1107": [Festival("十月社会主义革命纪念日", source: FestivalSource.solar, level: FestivalLevel.commemorative, startYear: 1917)],
    "1108": [Festival("中国记者日", source: FestivalSource.solar, level: FestivalLevel.commemorative)],
    "1109": [Festival("全国消防安全宣传日", source: FestivalSource.solar, level: FestivalLevel.commemorative)],
    "1110": [Festival("世界青年节", source: FestivalSource.solar, level: FestivalLevel.commemorative)],
    "1111": [Festival("国际科学与和平周", source: FestivalSource.solar, level: FestivalLevel.commemorative)],
    "1112": [Festival("孙中山诞辰纪念日", source: FestivalSource.solar, level: FestivalLevel.commemorative, startYear: 1866)],
    "1114": [Festival("世界糖尿病日", source: FestivalSource.solar, level: FestivalLevel.commemorative)],
    "1117": [
      Festival("国际大学生节", source: FestivalSource.solar, level: FestivalLevel.popular),
      Festival("世界学生节", source: FestivalSource.solar, level: FestivalLevel.popular),
    ],
    "1120": [Festival("彝族年", source: FestivalSource.solar, level: FestivalLevel.ethnic)],
    "1121": [
      Festival("彝族年", source: FestivalSource.solar, level: FestivalLevel.ethnic),
      Festival("世界问候日", source: FestivalSource.solar, level: FestivalLevel.popular),
      Festival("世界电视日", source: FestivalSource.solar, level: FestivalLevel.commemorative),
    ],
    "1122": [Festival("彝族年", source: FestivalSource.solar, level: FestivalLevel.ethnic)],
    "1129": [Festival("国际声援巴勒斯坦人民日", source: FestivalSource.solar, level: FestivalLevel.commemorative)],
    "1201": [Festival("世界艾滋病日", source: FestivalSource.solar, level: FestivalLevel.popular, startYear: 1988)],
    "1203": [Festival("世界残疾人日", source: FestivalSource.solar, level: FestivalLevel.commemorative)],
    "1205": [Festival("国际志愿人员日", source: FestivalSource.solar, level: FestivalLevel.commemorative)],
    "1208": [Festival("国际儿童电视日", source: FestivalSource.solar, level: FestivalLevel.commemorative)],
    "1209": [Festival("世界足球日", source: FestivalSource.solar, level: FestivalLevel.popular)],
    "1210": [Festival("世界人权日", source: FestivalSource.solar, level: FestivalLevel.commemorative)],
    "1212": [Festival("西安事变纪念日", source: FestivalSource.solar, level: FestivalLevel.historical, startYear: 1936)],
    "1213": [Festival("南京大屠杀纪念日", source: FestivalSource.solar, level: FestivalLevel.historical, startYear: 1937)],
    "1220": [Festival("澳门回归纪念", source: FestivalSource.solar, level: FestivalLevel.historical, startYear: 1999)],
    "1221": [Festival("国际篮球日", source: FestivalSource.solar, level: FestivalLevel.popular)],
    "1224": [Festival("平安夜", source: FestivalSource.solar, level: FestivalLevel.popular)],
    "1225": [Festival("圣诞节", source: FestivalSource.solar, level: FestivalLevel.popular)],
    "1226": [Festival("毛泽东诞辰纪念", source: FestivalSource.solar, level: FestivalLevel.commemorative, startYear: 1893)],
  };

  static List<Festival> getFestivals(AstroDateTime solar, LunarDate lunar, GanZhi ganZhi) {
    final results = <Festival>[];
    final year = solar.year;

    // 1. 公历固定
    final sKey = _pad(solar.month) + _pad(solar.day);
    if (_solarFtv.containsKey(sKey)) {
      results.addAll(_solarFtv[sKey]!.where((f) => f.isValidAt(year)));
    }

    // 2. 农历固定 (闰月不过节，对标原版 u.Lleap!='闰')
    if (!lunar.isLeap) {
      final lKey = _pad(lunar.month) + _pad(lunar.day);
      if (_lunarFtv.containsKey(lKey)) {
        results.addAll(_lunarFtv[lKey]!.where((f) => f.isValidAt(year)));
      }
    }

    // 3. 除夕 (农历最后一天)
    if (lunar.month == 12 && lunar.isLastDay) {
      results.add(const Festival("除夕", source: FestivalSource.lunar, level: FestivalLevel.statutory, isPublicHoliday: true));
    }

    // 4. 星期规则 (含原版 wFtv)
    _addWeekBasedFestivals(solar, results);

    // 5. 节气判定 (含清明放假)
    final jqList = getYearJieQi(solar.year);
    for (var jq in jqList) {
      if (jq.dateTime.year == solar.year && jq.dateTime.month == solar.month && jq.dateTime.day == solar.day) {
        if (jq.name == "清明") {
          results.add(const Festival("清明", source: FestivalSource.termBased, level: FestivalLevel.statutory, isPublicHoliday: true));
        } else {
          results.add(Festival(jq.name, source: FestivalSource.termBased, level: FestivalLevel.solarTerm));
        }
      }
    }

    // 6. 动态推算 (数九、三伏、梅雨 - 带天数计数)
    _addDynamicFestivals(solar, ganZhi, results);

    return results;
  }

  /// 星期规则节日处理
  static void _addWeekBasedFestivals(AstroDateTime solar, List<Festival> results) {
    final m = solar.month;
    final d = solar.day;
    final w = solar.weekday; // 1-7 (Mon-Sun)
    
    // 计算当前是第几个星期几
    final n = ((d - 1) ~/ 7) + 1;
    
    // 计算是否是当月最后一个
    final isLast = (d + 7) > _daysInMonth(solar.year, m);

    // 1月最后周日: 世界麻风日
    if (m == 1 && w == 7 && isLast) {
      results.add(const Festival("世界麻风日", source: FestivalSource.weekBased, level: FestivalLevel.commemorative));
    }
    // 5月第2个周日: 母亲节
    if (m == 5 && w == 7 && n == 2) {
      results.add(const Festival("母亲节", source: FestivalSource.weekBased, level: FestivalLevel.popular));
    }
    // 5月第3个周日: 全国助残日
    if (m == 5 && w == 7 && n == 3) {
      results.add(const Festival("全国助残日", source: FestivalSource.weekBased, level: FestivalLevel.popular));
    }
    // 6月第3个周日: 父亲节
    if (m == 6 && w == 7 && n == 3) {
      results.add(const Festival("父亲节", source: FestivalSource.weekBased, level: FestivalLevel.popular));
    }
    // 7月第3个周日: 被奴役国家周
    if (m == 7 && w == 7 && n == 3) {
      results.add(const Festival("被奴役国家周", source: FestivalSource.weekBased, level: FestivalLevel.commemorative));
    }
    // 9月第3个周二: 国际和平日
    if (m == 9 && w == 2 && n == 3) {
      results.add(const Festival("国际和平日", source: FestivalSource.weekBased, level: FestivalLevel.commemorative));
    }
    // 9月第4个周日: 国际聋人节 / 世界儿童日
    if (m == 9 && w == 7 && n == 4) {
      results.add(const Festival("国际聋人节", source: FestivalSource.weekBased, level: FestivalLevel.commemorative));
      results.add(const Festival("世界儿童日", source: FestivalSource.weekBased, level: FestivalLevel.commemorative));
    }
    // 9月最后周日: 世界海事日
    if (m == 9 && w == 7 && isLast) {
      results.add(const Festival("世界海事日", source: FestivalSource.weekBased, level: FestivalLevel.commemorative));
    }
    // 10月第1个周一: 国际住房日
    if (m == 10 && w == 1 && n == 1) {
      results.add(const Festival("国际住房日", source: FestivalSource.weekBased, level: FestivalLevel.commemorative));
    }
    // 10月第2个周三: 国际减轻自然灾害日
    if (m == 10 && w == 3 && n == 2) {
      results.add(const Festival("国际减轻自然灾害日", source: FestivalSource.weekBased, level: FestivalLevel.commemorative));
    }
    // 11月第4个周四: 感恩节
    if (m == 11 && w == 4 && n == 4) {
      results.add(const Festival("感恩节", source: FestivalSource.weekBased, level: FestivalLevel.popular));
    }
  }

  /// 动态推算类节日 (含“第X天”逻辑)
  static void _addDynamicFestivals(AstroDateTime solar, GanZhi ganZhi, List<Festival> results) {
    // 1. 数九
    final shujiu = getShujiu(solar);
    if (shujiu != null) {
      // 第一天 (带括号) 设为传统级别，其它天设为纪念/详情级别
      final isFirstDay = shujiu.startsWith('『');
      results.add(Festival(
        shujiu,
        source: FestivalSource.custom,
        level: isFirstDay ? FestivalLevel.traditional : FestivalLevel.commemorative,
      ));
    }

    // 2. 三伏
    final sanfu = getSanfu(solar, ganZhi);
    if (sanfu != null) {
      // 第一天 (不含“第”字) 设为传统级别，其它天设为纪念/详情级别
      final isFirstDay = !sanfu.contains('第');
      results.add(Festival(
        sanfu,
        source: FestivalSource.custom,
        level: isFirstDay ? FestivalLevel.traditional : FestivalLevel.commemorative,
      ));
    }

    // 3. 梅雨 (原版入梅/出梅只标第一天，维持传统级别)
    final mei = getMeiyu(solar, ganZhi);
    if (mei != null) {
      results.add(Festival(mei, source: FestivalSource.custom, level: FestivalLevel.traditional));
    }
  }

  /// 增强版数九逻辑：返回“三九”或“三九第2天”
  static String? getShujiu(AstroDateTime solar) {
    final currentJD = solar.toJ2000().floor();
    final dz = getYearJieQi(solar.year).firstWhere((j) => j.name == "冬至").dateTime;
    final dzJD = AstroDateTime(dz.year, dz.month, dz.day).toJ2000().floor();
    
    // 如果还没到冬至，找去年的冬至
    int baseJD = dzJD;
    if (currentJD < dzJD) {
      final lastDz = getYearJieQi(solar.year - 1).firstWhere((j) => j.name == "冬至").dateTime;
      baseJD = AstroDateTime(lastDz.year, lastDz.month, lastDz.day).toJ2000().floor();
    }

    final diff = currentJD - baseJD;
    if (diff >= 0 && diff < 81) {
      final index = (diff ~/ 9) + 1;
      final day = (diff % 9) + 1;
      final name = _numToJiu(index);
      return day == 1 ? "『$name』" : "$name第${day}天";
    }
    return null;
  }

  /// 增强版三伏逻辑：返回“初伏”或“初伏第3天”
  static String? getSanfu(AstroDateTime solar, GanZhi gz) {
    final xz = getYearJieQi(solar.year).firstWhere((j) => j.name == "夏至").dateTime;
    final lq = getYearJieQi(solar.year).firstWhere((j) => j.name == "立秋").dateTime;

    final currentJD = solar.toJ2000().floor();
    final xzMidnight = AstroDateTime(xz.year, xz.month, xz.day);
    final lqMidnight = AstroDateTime(lq.year, lq.month, lq.day);

    int g3 = _getNthGengAfter(xzMidnight, 3);
    int g4 = _getNthGengAfter(xzMidnight, 4);
    int moStart = _getNthGengAfter(lqMidnight, 1);

    if (currentJD >= g3 && currentJD < g4) {
      int d = currentJD - g3 + 1;
      return d == 1 ? "初伏" : "初伏第${d}天";
    }
    if (currentJD >= g4 && currentJD < moStart) {
      int d = currentJD - g4 + 1;
      return d == 1 ? "中伏" : "中伏第${d}天";
    }
    if (currentJD >= moStart && currentJD < moStart + 10) {
      int d = currentJD - moStart + 1;
      return d == 1 ? "末伏" : "末伏第${d}天";
    }
    return null;
  }

  /// 保持入梅/出梅原版逻辑 (仅限当天)
  static String? getMeiyu(AstroDateTime solar, GanZhi gz) {
    final currentJD = solar.toJ2000().floor();
    final mz = getYearJieQi(solar.year).firstWhere((j) => j.name == "芒种").dateTime;
    final mzJD = AstroDateTime(mz.year, mz.month, mz.day).toJ2000().floor();
    final xs = getYearJieQi(solar.year).firstWhere((j) => j.name == "小暑").dateTime;
    final xsJD = AstroDateTime(xs.year, xs.month, xs.day).toJ2000().floor();

    // 芒种后第一个丙日入梅 (10天内必有)
    if (dayGanZhi(solar).gan == TianGan.bing && currentJD > mzJD && currentJD < mzJD + 11) return "入梅";
    // 小暑后第一个未日出梅 (12天内必有)
    if (dayGanZhi(solar).zhi == DiZhi.wei && currentJD > xsJD && currentJD < xsJD + 13) return "出梅";

    return null;
  }

  static int _getNthGengAfter(AstroDateTime base, int n) {
    int count = 0;
    AstroDateTime current = base; // 原版算法包含当天(如果是庚日)吗？通常是夏至后第3个庚日。
    // 如果夏至当天是庚日，算第1个。
    while (count < n) {
      if (dayGanZhi(current).gan == TianGan.geng) {
        count++;
        if (count == n) return current.toJ2000().floor();
      }
      current = current.add(const Duration(days: 1));
    }
    return current.toJ2000().floor();
  }

  static int _daysInMonth(int year, int month) {
    if (month == 2) {
      return (year % 4 == 0 && (year % 100 != 0 || year % 400 == 0)) ? 29 : 28;
    }
    const days = [0, 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
    return days[month];
  }

  static String _numToJiu(int n) {
    const names = ["", "一九", "二九", "三九", "四九", "五九", "六九", "七九", "八九", "九九"];
    return (n >= 1 && n <= 9) ? names[n] : "";
  }

  static String _pad(int n) => n.toString().padLeft(2, '0');
}
