from ../unitx import addSiUnit,addSimpleSiUnit,addSiUnitInner,formatUnit
{.used.}
addSiUnit {
  # 国际单位制基本单位（7个）
  ampere,                  # 安培 - 电流
  candela,                 # 坎德拉 - 发光强度
  kelvin,                  # 开尔文 - 热力学温度
  kilogram,                # 千克 - 质量
  meter,                   # 米 - 长度
  mole,                    # 摩尔 - 物质的量
  second,                  # 秒 - 时间

  # ============== 长度单位 ==============
  astronomical_unit: 149597870700~meter,             # 天文单位
  attometer: 1e-18~meter,                            # 阿米
  centimeter: 0.01~meter,                            # 厘米
  decimeter: 0.1~meter,                              # 分米
  exameter: 1e18~meter,                              # 艾米
  femtometer: 1e-15~meter,                           # 飞米
  kilometer: 1000~meter,                             # 千米
  lightyear: 9460730472580800~meter,                 # 光年
  megameter: 1e6~meter,                              # 兆米
  micrometer: 1e-6~meter,                            # 微米
  millimeter: 0.001~meter,                           # 毫米
  nanometer: 1e-9~meter,                             # 纳米
  nautical_mile: 1852~meter,                         # 海里
  parsec: 3.08567758149137e16~meter,                 # 秒差距
  petameter: 1e15~meter,                             # 拍米
  picometer: 1e-12~meter,                            # 皮米
  terameter: 1e12~meter,                             # 太米
  yoctometer: 1e-24~meter,                           # 幺米
  yottameter: 1e24~meter,                            # 尧米
  zeptometer: 1e-21~meter,                           # 仄米
  zettameter: 1e21~meter,                            # 泽米

  # ============== 质量单位 ==============
  centigram: 1e-5~kilogram,                         # 厘克
  decagram: 0.01~kilogram,                          # 十克
  decigram: 0.0001~kilogram,                        # 分克
  gigagram: 1e6~kilogram,                           # 吉克
  gram: 0.001~kilogram,                             # 克
  hectogram: 0.1~kilogram,                          # 百克
  megagram: 1000~kilogram,                          # 兆克（吨）
  microgram: 1e-9~kilogram,                         # 微克
  milligram: 1e-6~kilogram,                         # 毫克
  nanogram: 1e-12~kilogram,                         # 纳克
  picogram: 1e-15~kilogram,                         # 皮克
  teragram: 1e9~kilogram,                            # 太克
  ton: 1000~kilogram,                              # 吨

  # ============== 时间单位 ==============
  attosecond: 1e-18~second,                         # 阿秒
  centisecond: 0.01~second,                         # 厘秒
  day: 86400~second,                                # 日
  decisecond: 0.1~second,                           # 分秒
  femtosecond: 1e-15~second,                        # 飞秒
  gigasecond: 1e9~second,                           # 吉秒
  hour: 3600~second,                                # 小时
  kilosecond: 1000~second,                          # 千秒
  microsecond: 1e-6~second,                         # 微秒
  millisecond: 0.001~second,                        # 毫秒
  minute: 60~second,                                # 分
  nanosecond: 1e-9~second,                          # 纳秒
  picosecond: 1e-12~second,                         # 皮秒
  terasecond: 1e12~second,                          # 太秒
  week: 604800~second,                             # 周
  year: 31557600~second,                           # 年（儒略年）

  # ============== 电流单位 ==============
  centiampere: 0.01~ampere,                         # 厘安
  deciampere: 0.1~ampere,                           # 分安
  kiloampere: 1000~ampere,                          # 千安
  megaampere: 1e6~ampere,                           # 兆安
  microampere: 1e-6~ampere,                         # 微安
  milliampere: 0.001~ampere,                        # 毫安
  nanoampere: 1e-9~ampere,                          # 纳安
  picoampere: 1e-12~ampere,                         # 皮安

  # ============== 温度单位 ==============
  # 只有开尔文作为基本单位，避免复杂转换问题
  # 热力学温度差可直接使用开尔文

  # ============== 物质的量 ==============
  centimole: 0.01~mole,                            # 厘摩
  decimole: 0.1~mole,                              # 分摩
  kilomole: 1000~mole,                             # 千摩
  megamole: 1e6~mole,                              # 兆摩
  micromole: 1e-6~mole,                            # 微摩
  millimole: 0.001~mole,                           # 毫摩
  nanomole: 1e-9~mole,                             # 纳摩

  # ============== 发光强度 ==============
  kilocandela: 1000~candela,                       # 千坎
  millicandela: 0.001~candela,                     # 毫坎

  # ============== 基本导出单位 ==============
  newton: kilogram*meter/second^2,                  # 牛顿（力）
  joule: newton*meter,                              # 焦耳（能量）
  watt: joule/second,                               # 瓦特（功率）
  pascal: newton/meter^2,                           # 帕斯卡（压强）
  hertz: /second,                                   # 赫兹（频率）
  coulomb: ampere*second,                           # 库仑（电荷）
  volt: watt/ampere,                                # 伏特（电压）
  ohm: volt/ampere,                                 # 欧姆（电阻）
  siemens:  /ohm,                                   # 西门子（电导）
  farad: coulomb/volt,                              # 法拉（电容）
  weber: volt*second,                               # 韦伯（磁通量）
  tesla: weber/meter^2,                             # 特斯拉（磁感应强度）
  henry: weber/ampere,                              # 亨利（电感）

  # ============== 其他常用单位 ==============
  angstrom: 1e-10~meter,                           # 埃（原子尺度）
  atmosphere: 101325~pascal,                       # 标准大气压
  bar: 100000~pascal,                              # 巴
  calorie: 4.184~joule,                            # 卡路里（定义精确值）
  dyne: 1e-5~newton,                               # 达因（厘米-克-秒单位）
  electronvolt: 1.602176634e-19~joule,             # 电子伏特
  erg: 1e-7~joule,                                 # 尔格
  gauss: 1e-4~tesla,                               # 高斯（传统磁场单位）
  horsepower: 745.69987158227~watt,                # 马力
  inch: 0.0254~meter,                              # 英寸
  kiloelectronvolt: 1e3~electronvolt,              # 千电子伏特
  kilocalorie: 4184~joule,                         # 千卡
  kilowatt: 1000~watt,                             # 千瓦
  kilowatt_hour: 3.6e6~joule,                      # 千瓦时
  liter: 0.001~meter^3,                            # 升
  micron: 1e-6~meter,                              # 微米（旧称）
  mile: 1609.344~meter,                            # 英里
  ounce: 0.028349523125~kilogram,                  # 盎司
  pound: 0.45359237~kilogram,                      # 磅
  poundforce: 4.4482216152605~newton,              # 磅力
  ton_force: 8896.443230521~newton,                # 英吨力
  torr: 133.322~pascal,                            # 托（压强）

  # ============== 辐射单位 ==============
  becquerel: /second,                               # 贝克勒尔（放射性活度）
  gray: joule/kilogram,                             # 戈瑞（吸收剂量）
  sievert: joule/kilogram,                          # 希沃特（当量剂量）

  # ============== 光学单位 ==============
  lumen: candela*steradian,                         # 流明（光通量）
  lux: lumen/meter^2,                               # 勒克斯（照度）
}
