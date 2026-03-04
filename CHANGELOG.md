## 0.12.0

- **新增太阳计算算法切换功能 (Algorithm Switch)**：
  - 支持在 **SPA** (现代物理模型) 与 **SXWNL** (适配版 VSOP87 迭代模型) 之间进行选择。
  - 提供 `SolarCalcMethod` 枚举参数，开发者可根据业务场景（现代授时或古典历法）选择适合的算法。
  - 已在 `calcTrueSolarTime`、`getSolarMonthDays`、`getLunarMonthDays` 等主要 API 中集成。
- **优化极地判定逻辑**：
  - 更新极昼/极夜判定逻辑，由此前的月份估算改为基于太阳赤纬的实时计算。
  - 在特殊极地场景下（如春秋分前后），通过实时赤纬判断提升了极昼/极夜判定的稳定性。
- **修正核心算法偏移**：
  - 修正了 SXWNL 算法中可能出现的锚点计算偏移，优化了真太阳时计算的稳定性。
  - 统一使用当日当地 12:00:00 作为计算基准，使均时差 (EoT) 计算结果更趋近于物理模型值。
- **文档与用词优化**：
  - 优化了 README 与注释中的技术术语表达，修正了部分不符合中文习惯的用词。
  - 更新了算法对比数据与使用示例。

## 0.11.0

- **新增节日与民俗系统 (`festivals.dart`)**：
  - **扩充节日数据库**：参考原版 sxwnl (lunar.js) 补全了大量公历、农历及星期规则节日，并支持根据起始年份判定有效性。
  - **引入分类管理**：通过 `FestivalLevel` 枚举对节日进行初步划分（法定、传统、流行、纪念、历史、民族等），便于 UI 灵活过滤。
  - **支持时段进度显示**：针对数九、三伏等民俗时段，新增天数计数逻辑（如“初伏第3天”）。
  - **对齐历法细节**：支持“闰月不过节”判定；补全了“月份最后一个周日”等复杂的星期节日计算。
- **核心模型升级 (`DayInfo`)**：
  - 增强 `DayInfo` 数据模型：支持挂载节日列表、月相名称、详细节气及日月升落数据。
  - 新增 `getFestivalsByLevel()`：提供展示过滤接口，支持在 UI 层面进行节日信息的“降噪”处理。
- **扩展工具**：
  - 新增 `DayInfoListMoonExt` 扩展：支持一键将日历列表升级为包含 8 种细分月相（如峨眉月、凸月等）的展示模式。

## 0.10.3

- 完善第三方代码版权声明：补充 dart-spa 原作者 (Andre Lipke) 的 MIT 协议署名。

## 0.10.2

- 新增 `yearGanZhi()` — 查询某一年的年干支 (1984=甲子)。
- 新增 `getYearRange()` — 获取年份范围内逐年干支。
- 新增 `getYearMonthGanZhi()` — 获取某一年的所有月份干支 (12个)。
- 新增 `getDayHourGanZhi()` — 获取某日的所有时辰干支 (12个)。

## 0.10.1

- 新增 `GanZhi` 类的纳音五行属性：`naYin` (如'海中金') 和 `naYinWuXing` (如'金')。

## 0.10.0
- 新增 `LunarDate` 农历日期类：支持阳历 ↔ 农历双向转换，兼容历史特殊月名（后九、拾贰、十三等）。
- 新增 `TimePack` 时间封装包：统一管理钟表时间、真太阳时、UTC 时间和排盘基准时间。
- 新增 `calcBaZi()` 方法：返回类型安全的 `BaZiCalcResult`（包含 `BaZi` 对象），原版 `calcGanZhi()` 字符串版本保留不变。
- 新增 `defaultLoc` 常量（东经 120°，北纬 30°）。
- 新增日历工具 API：
  - `dayGanZhi()` — 查询某一天的日干支
  - `dayGanZhiAt()` — 查询某一时刻的日干支，支持早晚子时 (`splitRatHour`) 配置
  - `weekday()` — 查询某一天是星期几 (1=周一, 7=周日)
  - `getDayRange()` — 获取日期范围内每一天的干支与星期
  - `getSolarMonthDays()` — 公历月份逐日干支表
  - `getLunarMonthDays()` — 农历月份逐日干支表
  - `getJieQiPeriodDays()` — 节气月份逐日干支表
  - `hourGanZhi()` — 五鼠遁：根据日干推算时辰干支
  - `monthGanZhi()` — 五虎遁：根据年干推算月干支

## 0.9.7

- 重大修复：修复 `getYearJieQi` 在历史远古年份（如公元前）因儒略历漂移导致的节气名称映射错误。
- 逻辑优化：`getYearJieQi` 现在返回从“上个冬至”到“当前冬至”的 25 个节气节点，对齐原版 sxwnl 跨度。
- 逻辑优化：所有节气查询 API（`getPrevJieQi` 等）现在使用更鲁棒的跨年搜索算法，彻底解决历法漂移带来的相邻节气丢失问题。

## 0.9.6

- 新增 jie_qi.dart 模块，提供便捷的节气查询 API。
- 公开底层定气/定朔计算接口：qiAccurate(), SSQ.qiHigh(), SSQ.soHigh(), SSQ.qiLow(), SSQ.soLow()。
- 新增节/气查询与距离计算：getPrevJie(), getNextJie(), getPrevQi(), getNextQi(), getJieDistance(), getQiDistance(), getJieQiInfo()。
- 新增 Julian Day 版本 API：getPrevJieQiJd(), getNextJieQiJd(), getPrevJieJd(), getNextJieJd(), getPrevQiJd(), getNextQiJd(), getYearJieQiJd()。

## 0.9.5

- SSQ.calcY 增加 enableHistoricalRules 参数，控制是否启用特殊历史历法规则（春秋/战国/秦汉月名与月建处理）。

## 0.9.4

- 真太阳时计算：公元 6000 年以上使用 manualJD。

## 0.9.3

- 修复 SPA 默认时区分钟偏移丢失问题。
- 修复 JD 反解在 24:00:00 的边界问题。
- 修复极昼/极夜场景仍返回中天时间。
- 修复 SPAParams.list 默认大气折射值与主构造不一致。
- 修复 manualJD 绕过年份限制的断言逻辑。

## 0.9.2

- README 更新免责声明与署名/商用授权提示。

## 0.9.1

- 移除未授权的 sxwnl 原始源码测试资源。
- README 增加测试资源获取说明。

## 0.9.0

- 对齐 sxwnl 原版闰月判定与测试基准说明。
- 更新发布前示例与导入路径。
