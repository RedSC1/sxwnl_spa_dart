## 0.20.0

- **新增冥王星位置**：机械生成并纳入寿星原版 `XL0Pluto` 系数表，移植 `pluto_coord()` 和 P03 岁差转换；`pCoord(Planet.pluto, ...)` 现可返回冥王星黄经、黄纬和日心距离。
- **补充冥王星回归测试**：J2000 与 `t = 0.26` 位置结果均与原版 `p_coord(8, ...)` 对齐；明确冥王星不支持原版未覆盖的 `xingLiu()` / `xingHR()` 快速事件接口。
- **扩展系数审计**：`tool/verify_xl_data.mjs` 现同时逐项核对原版 `XL0Pluto` 与 Dart 生成表。

## 0.19.0

- **修正动态节日日期**：数九改用当地历日中午日序并选择目标日期之前最近的冬至；同步修正三伏、入梅和出梅的日期基准，修复当年冬至后数九不显示的问题。感谢 [tsunehimatoi](https://github.com/tsunehimatoi) 提交 [PR #1](https://github.com/RedSC1/sxwnl_spa_dart/pull/1)。
- **新增寿星万年历日月食接口**：移植 `rsPL.secMax()` 地方日食计算，支持接触时刻、食型、食分、位置角和日出/日没截断；保留 `ysPL`、`rsGS`、`ecFast` 等原始命名。
- **新增行星位置与天象接口**：移植水星至海王星位置、`daJu` 水星/金星大距、`xingLiu` 行星留、`xingHY` 合月和 `xingHR` 合/冲。
- **修正 sxwnl 兼容细节**：补齐小角距近似、光行时迭代、NASA 月球视半径比例和日出日没迭代常数；修复极昼、`h2g` 经度归一化、`xingHY(Planet.earth)` 参数边界及日食计算器状态隔离。
- **增强验证**：新增 SEDS 2003 火星冲日外部 oracle、18 项日月食/行星回归测试，以及 `XL0`、`XL1`、`XL0_xzb` 系数逐项审计脚本。

## 0.18.5

- **新增 `calcGanZhiAstroDate` / `calcBaZiAstroDate` 精确边界版干支计算接口**
  - 日柱、时柱改为基于 `AstroDateTime` 的整数时分秒判断，彻底避开 JD 浮点精度在时辰整点边界（如 `13:00:00`、`23:00:00`）的漂移问题。
  - 原有 JD 版 `calcGanZhi` / `calcBaZi` 保持不变，向后兼容。
- **新增回归测试**：覆盖 `13:00:00` 进入未时、`23:00:00` 换日等关键边界用例。

## 0.18.4

- **修复 `LunarDate` 在历史改历时期的农历归年偏差**
  - 修复 `LunarDate.fromSolar()` / `toSolar()` 在武则天改历等历史窗口中可能出现的 round-trip 偏一年问题。
  - 修复 `LunarDate` 在公元前古历区间与公元后特殊改历区间混用统一“正月分年”规则导致的归年偏差。
  - 调整常规归年策略：普通年份与公元后改历窗口改用“农历年区间中点”定年，避免年首落在前一公历年末时误判。
  - 修正 2025 年十二月回归测试预期，确认跨公历年的农历月份仍属于请求的农历年。
  - 新增公元前古历、公元后改历（新莽、景初、武则天）回归测试。

## 0.18.3

- **修复 `LunarDate.fromString()` 在 BCE 年内前段月份的归年错误**
  - 修复 `LunarDate.fromString(-100, '十', 1)` 这类 BCE 输入仍会错误抛出 `FormatException` 的问题。
  - 修正 `LunarDate._astronomicalLunarYearForIndex()` 在 BCE 场景下对“正月前月份”的归年判定，避免把 `十一/十二` 所在年表中的 `正月前月份` 误归到下一天文年。
  - 补充 BCE `十月` 回归测试，覆盖 `fromString()` 与 `toSolar()/fromSolar()` 的一致性。

## 0.18.2

- **修复 `LunarDate.fromString()` 在 BCE 正月附近的归年错误**
  - 修复 `LunarDate.fromString(-100, '正', 1)` 这类 BCE 输入会错误抛出 `FormatException` 的问题。
  - 修正 `LunarDate._astronomicalLunarYearForIndex()` 在 BCE 场景下对同一份 SSQ 年表内月份的归年判定，避免把 `正月~十月` 误判到下一天文年。
  - 补充 BCE `fromString()` 回归测试，覆盖 `正月` 解析与 `solar -> lunar -> solar` 语义一致性。

## 0.18.1

- **重大修复：纠正 `LunarDate` 的天文纪年实现不完整问题**
  - 修复 `LunarDate.fromSolar()` 在公元前日期上仍返回偏历史纪年的问题；`LunarDate.lunarYear` 现在真正与 `AstroDateTime.year` 对齐，统一使用天文纪年（含公元 0 年）。
  - 修复 `LunarDate.toSolar()` / `LunarDate.fromString()` 在 BCE 与跨正月场景下的年份匹配逻辑，避免出现年号偏移或回转失败。
  - 修复 `getLunarMonthDays()` 对跨年重复月名（如 `十一`）的错误匹配问题，并在请求不存在的月份时明确抛出 `FormatException`。
  - 新增 `LunarDate.isBCE`、`LunarDate.bceYear`、`LunarDate.historicalYear`，便于在保持内部天文纪年的同时向 UI 或传统历法逻辑暴露历史纪年。
  - 补充 BCE 与跨年农历月份测试，覆盖 `solar -> lunar -> solar` 往返、公元前显示与 `十一/十二` 月份边界。

## 0.18.0

- **Breaking Change: 统一使用天文纪年（Astronomical Year Numbering）**:
  - `LunarDate.lunarYear` 现在统一存储天文年份（有公元0年），与 `AstroDateTime.year` 保持一致。
  - 历史年份与天文年份的对应关系：
    - 历史公元前1年 = 天文年 0
    - 历史公元前2年 = 天文年 -1
    - 公元后年份两者相同
  - 这修复了公元前日期干支计算错误的问题（如公元前457年应得甲申而非癸未）。
  - 使用 `fromSolar()` 创建农历时，传入的 `AstroDateTime` 已使用天文纪年，无需额外转换。

## 0.17.0

- **SSQ 引擎优化与历史规则解耦**：
    - 增强了 `enableHistoricalRules` 参数的功能。现在当关闭该参数时，`SSQ.calc` 将完全绕过历代历法修正表（`_suoS`, `_qiS`）以及平气/平朔算法，强制使用现代高精度天文算法。
    - 确保在理论农历研究场景下，能够获得纯粹的天文定气定朔结果，不再受古代实历拟合干扰。
    - 在 `SSQ.calcY` 中完整透传了该参数，确保整年排谱逻辑的一致性。

## 0.16.0

- **生产环境对齐与 OpenDestiny 集成优化**：
    - 针对 `opendestiny-flutter` 桌面端的展示需求，进一步优化了核心模型 `DayInfo` 的属性暴露与稳定性。
    - 提升了极端年份（BC/AC）在日历计算中的边界鲁棒性。
- **文档与工程化更新**：
    - 完善 `pubspec.yaml` 元数据（新增 topics, issue_tracker）。
    - 更新 `README.md` 中的安装示例与参考实现链接。

## 0.15.1

- **修复 `getConstellation` 在节气点附近的判定误差**：
    - 解决由 `DateTime` 精度舍入导致的“节气前 1 秒”星座识别偏移问题。
- **暴露 JD 浮点查询接口**：
    - `jie_qi.dart` 新增 `getPrevJieQiFromJd` 等接口。支持直接使用 `double` 类型的 JD 查询，避免经过 `AstroDateTime` 中转导致的精度丢失。
- **API 优化**：
    - `getConstellation` 增加支持 `AstroDateTime` 接口，高精度推算建议使用 `getConstellationFromJd`。

## 0.15.0

- **重构 `jie_qi.dart` 检索算法**：
  - 弃用基于预计算列表的全局搜索，引入 Slot 定位机制。
  - 相邻节气（Prev/Next）查询复杂度从 O(n) 降低至 O(1)，大幅提升推算效率。
  - 统一 `JieQiDistance`、`JieDistance` 与 `QiDistance` 的底层数据模型为 `SolarTermSpan`，并保持属性命名的向下兼容。
  - 增加 `getSpecificJieQi` 接口，支持按年份与节气序号直接反向推算精确时刻。

## 0.14.0

- **新增 `shuo_wang.dart` 高精度定朔/定气模块**：
  - 引入 `soAccurate` / `soAccurate2`：暴露底层牛顿迭代物理模型，支持**秒级**合朔（农历初一）时刻计算。
  - 引入 `getSpecificJieQi`：支持按年份与节气序号直接反向推算精确时刻，内置天文年（3月春分起算）与公历年的跨年偏移修正逻辑。
- **核心算法精度与稳定性重构 (Refactored Core Algorithms)**：
  - **月相计算升级**：`getMoonPhase` 彻底抛弃离散历表估算，改为调用 `soAccurate` 物理模型，实现真正的连续时间轴匹配，解决了跨天临界点的月相判定误差。
  - **星座算法优化**：重构 `getConstellation`，采用“10项快速初筛 + 临界点全项校准”的两级架构，消除了 20/21 号交界日期因摄动导致的判定模糊。
  - **智能节气搜索**：新增 `qiAccurate2` 接口，支持基于儒略日的自动节气对齐与轨道摄动容错补偿。
- **API 语义化与结构调整**：
  - 规范了 `AstroDateTime` 的天文纪年描述（包含公元 0 年），并优化了 `toJulianDay` 等基础方法的语义。
  - `sxwnl_dart_base.dart` 增加 `shuo_wang.dart` 的统一导出。

## 0.13.0

- **新增历史节气校正功能 (Historical Solar Terms Mapping)**：
  - 在日历相关 API (`getDayRange`, `getSolarMonthDays`, `getLunarMonthDays`, `getJieQiPeriodDays`) 中新增 `useHistoricalSolarTerms` 可选参数（默认 `false`）。
  - 该功能开启后，系统将自动调用 `SSQ` 历史修正表，将节气名称挂载到历史皇历印本对应的日期上（主要适配 1645-1929 年间的历法偏差），实现对寿星万年历原版行为的像素级还原。
  - **内外解耦设计**：日历文字显示关联历史日期，而 DayInfo 内部的 `solarTermTime` 仍保持高精度现代天文学数值，兼顾“排盘精度”与“历书呈现”。
- **强化八字计算准确性**：
  - 明确八字模块 (`calcBaZi`, `calcGanZhi`) 逻辑，强制使用绝对天文精密定气（基于 VSOP87），不参与历史历本日期偏移。
- **内部引用与 bug 修复**：
  - **修复包引用冲突**：统一 `lib/` 内部模型文件（如 `lunar_date.dart`）的导入方式，解决 Package 与 Relative 混合导入导致的类型不识别问题。
  - **健壮性优化**：修正了 `calendar.dart` 中个别私有方法的返回值缺失及未定义名称问题。
  - **验证案例**：新增 1645 年（清顺治二年）测试案例，成功验证了“雨水”节气在平定气转换期的 2 日历史偏移。

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
