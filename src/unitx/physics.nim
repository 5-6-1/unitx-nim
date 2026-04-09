from ../unitx import addSiUnit, addSimpleSiUnit, addSiUnitInner, formatUnit
{.used.}

# 国际单位制基本单位（7个）
addSiUnit [ampere, candela, kelvin, kilogram, meter, mole, second]

# 倍数前缀单位（无量纲的转换因子）
addSiUnit:
  # SI前缀
  yotta: 1e24
  zetta: 1e21
  exa: 1e18
  peta: 1e15
  tera: 1e12
  giga: 1e9
  mega: 1e6
  kilo: 1000
  hecto: 100
  deca: 10
  deci: 0.1
  centi: 0.01
  milli: 0.001
  micro: 1e-6
  nano: 1e-9
  pico: 1e-12
  femto: 1e-15
  atto: 1e-18
  zepto: 1e-21
  yocto: 1e-24

  # 二进制倍数前缀
  kibi: 1024
  mebi: 1024{kibi}
  gibi: 1024{mebi}
  tebi: 1024{gibi}
  pebi: 1024{tebi}
  exbi: 1024{pebi}
  zebi: 1024{exbi}
  yobi: 1024{zebi}


  # ============== 长度单位 ==============
  astronomical_unit: 149597870700{meter}             # 天文单位
  attometer: atto*meter                             # 阿米
  centimeter: centi*meter                           # 厘米
  decimeter: deci*meter                             # 分米
  exameter: exa*meter                               # 艾米
  femtometer: femto*meter                           # 飞米
  kilometer: kilo*meter                             # 千米
  light_year: 9460730472580800{meter}               # 光年
  megameter: mega*meter                             # 兆米
  micrometer: micro*meter                           # 微米
  millimeter: milli*meter                           # 毫米
  nanometer: nano*meter                             # 纳米
  nautical_mile: 1852{meter}                        # 海里
  parsec: 3.08567758149137e16{meter}                # 秒差距
  petameter: peta*meter                             # 拍米
  picometer: pico*meter                             # 皮米
  terameter: tera*meter                             # 太米
  yoctometer: yocto*meter                           # 幺米
  yottameter: yotta*meter                           # 尧米
  zeptometer: zepto*meter                           # 仄米
  zettameter: zetta*meter                           # 泽米

  # 非SI长度单位
  angstrom: 1e-10{meter}                            # 埃
  fermi: femtometer                                 # 费米
  foot: 0.3048{meter}                               # 英尺
  inch: 0.0254{meter}                               # 英寸
  mile: 1609.344{meter}                             # 英里
  yard: 0.9144{meter}                               # 码
  mil: 2.54e-5{meter}                               # 密耳
  planck_length: 1.616255e-35{meter}                # 普朗克长度
  bohr_radius: 5.29177210903e-11{meter}             # 玻尔半径

  # ============== 质量单位 ==============
  centigram: centi*gram                             # 厘克
  decagram: deca*gram                               # 十克
  decigram: deci*gram                               # 分克
  gigagram: giga*gram                               # 吉克
  gram: milli*kilogram                              # 克
  hectogram: hecto*gram                             # 百克
  megagram: mega*gram                               # 兆克
  microgram: micro*gram                             # 微克
  milligram: milli*gram                             # 毫克
  nanogram: nano*gram                               # 纳克
  picogram: pico*gram                               # 皮克
  teragram: tera*gram                               # 太克
  metric_ton: mega*gram                             # 公吨

  # 非SI质量单位
  atomic_mass_unit: 1.66053906660e-27{kilogram}     # 原子质量单位
  dalton: atomic_mass_unit                          # 道尔顿
  electron_mass: 9.1093837015e-31{kilogram}         # 电子质量
  proton_mass: 1.67262192369e-27{kilogram}          # 质子质量
  neutron_mass: 1.67492749804e-27{kilogram}         # 中子质量
  pound: 0.45359237{kilogram}                       # 磅
  ounce: 0.028349523125{kilogram}                   # 盎司
  slug: 14.593903{kilogram}                         # 斯勒格
  planck_mass: 2.176434e-8{kilogram}                # 普朗克质量
  solar_mass: 1.98847e30{kilogram}                  # 太阳质量
  earth_mass: 5.9722e24{kilogram}                   # 地球质量
  jupiter_mass: 1.89813e27{kilogram}                # 木星质量

  # ============== 时间单位 ==============
  attosecond: atto*second                           # 阿秒
  centisecond: centi*second                         # 厘秒
  day: 86400{second}                                # 日
  decisecond: deci*second                           # 分秒
  femtosecond: femto*second                         # 飞秒
  gigasecond: giga*second                           # 吉秒
  hour: 3600{second}                                # 小时
  kilosecond: kilo*second                           # 千秒
  microsecond: micro*second                         # 微秒
  millisecond: milli*second                         # 毫秒
  minute: 60{second}                                # 分
  nanosecond: nano*second                           # 纳秒
  picosecond: pico*second                           # 皮秒
  terasecond: tera*second                           # 太秒
  week: 604800{second}                              # 周
  year: 31557600{second}                            # 年
  month: 2629746{second}                            # 月
  julian_year: 31557600{second}                     # 儒略年
  sidereal_year: 31558149.76{second}                # 恒星年
  tropical_year: 31556925.2{second}                 # 回归年
  planck_time: 5.391247e-44{second}                 # 普朗克时间

  # ============== 电流单位 ==============
  centiampere: centi*ampere                         # 厘安
  deciampere: deci*ampere                           # 分安
  kiloampere: kilo*ampere                           # 千安
  megaampere: mega*ampere                           # 兆安
  microampere: micro*ampere                         # 微安
  milliampere: milli*ampere                         # 毫安
  nanoampere: nano*ampere                           # 纳安
  picoampere: pico*ampere                           # 皮安

  # ============== 热力学温度单位 ==============
  # 注意：温度间隔单位
  degree_celsius: kelvin                            # 摄氏度间隔
  degree_fahrenheit: 0.55555555555555{kelvin}       # 华氏度间隔
  degree_rankine: 0.55555555555555{kelvin}          # 兰金度间隔
  millikelvin: milli*kelvin                         # 毫开
  microkelvin: micro*kelvin                         # 微开
  nanokelvin: nano*kelvin                           # 纳开

  # ============== 物质的量单位 ==============
  centimole: centi*mole                             # 厘摩
  decimole: deci*mole                               # 分摩
  kilomole: kilo*mole                               # 千摩
  millimole: milli*mole                             # 毫摩
  micromole: micro*mole                             # 微摩
  nanomole: nano*mole                               # 纳摩
  picomole: pico*mole                               # 皮摩

  # ============== 发光强度单位 ==============
  centicandela: centi*candela                       # 厘坎
  decicandela: deci*candela                         # 分坎
  kilocandela: kilo*candela                         # 千坎
  millicandela: milli*candela                       # 毫坎
  microcandela: micro*candela                       # 微坎

  # ============== 力学导出单位 ==============
  newton: kilogram*meter/second^2                   # 牛顿
  dyne: 1e-5{newton}                                # 达因
  pound_force: 4.4482216152605{newton}              # 磅力
  kilogram_force: 9.80665{newton}                   # 千克力
  kip: 4448.2216152605{newton}                      # 千磅力
  ounce_force: 0.27801385095378125{newton}          # 盎司力

  pascal: newton/meter^2                            # 帕斯卡
  bar: 100000{pascal}                               # 巴
  atmosphere: 101325{pascal}                        # 标准大气压
  torr: 133.322368421053{pascal}                    # 托
  millimeter_of_mercury: 133.322{pascal}            # 毫米汞柱
  inch_of_mercury: 3386.389{pascal}                 # 英寸汞柱
  psi: 6894.75729316836{pascal}                     # 磅力每平方英寸
  barye: 0.1{pascal}                                # 巴列

  joule: newton*meter                               # 焦耳
  erg: 1e-7{joule}                                  # 尔格
  calorie: 4.184{joule}                             # 卡路里
  kilocalorie: 4184{joule}                          # 千卡
  electronvolt: 1.602176634e-19{joule}              # 电子伏特
  kiloelectronvolt: kilo*electronvolt               # 千电子伏特
  megaelectronvolt: mega*electronvolt               # 兆电子伏特
  gigaelectronvolt: giga*electronvolt               # 吉电子伏特
  teraelectronvolt: tera*electronvolt               # 太电子伏特
  british_thermal_unit: 1055.05585262{joule}        # 英热单位
  therm: 1.05505585262e8{joule}                     # 撒姆
  foot_pound: 1.3558179483314004{joule}             # 英尺磅
  inch_pound: 0.1129848290276167{joule}             # 英寸磅
  planck_energy: 1.9561e9{joule}                    # 普朗克能量

  watt: joule/second                                # 瓦特
  horsepower: 745.69987158227{watt}                 # 马力
  metric_horsepower: 735.49875{watt}                # 公制马力
  kilowatt: kilo*watt                               # 千瓦
  megawatt: mega*watt                               # 兆瓦
  gigawatt: giga*watt                               # 吉瓦
  terawatt: tera*watt                               # 太瓦

  # 力矩单位
  newton_meter: newton*meter                       # 牛·米
  pound_foot: 1.3558179483314004{newton_meter}     # 磅·英尺
  kilogram_meter: 9.80665{newton_meter}            # 千克·米

  # ============== 电磁学导出单位 ==============
  coulomb: ampere*second                            # 库仑
  abcoulomb: 10{coulomb}                            # 绝对库仑
  statcoulomb: 3.33564095198152e-10{coulomb}        # 静库仑
  elementary_charge: 1.602176634e-19{coulomb}       # 元电荷

  volt: watt/ampere                                 # 伏特
  abvolt: 1e-8{volt}                                # 绝对伏特
  statvolt: 299.792458{volt}                        # 静伏特
  kilovolt: kilo*volt                               # 千伏
  megavolt: mega*volt                               # 兆伏

  ohm: volt/ampere                                  # 欧姆
  abohm: 1e-9{ohm}                                  # 绝对欧姆
  statohm: 8.987551787368176e11{ohm}                # 静欧姆
  kilohm: kilo*ohm                                  # 千欧
  megaohm: mega*ohm                                 # 兆欧

  siemens: /ohm                                    # 西门子
  mho: siemens                                      # 姆欧
  abmho: 1e9{siemens}                               # 绝对姆欧
  statmho: 1.112650056e-12{siemens}                 # 静姆欧

  farad: coulomb/volt                               # 法拉
  abfarad: 1e9{farad}                               # 绝对法拉
  statfarad: 1.112650056e-12{farad}                 # 静法拉
  microfarad: micro*farad                           # 微法
  picofarad: pico*farad                             # 皮法

  henry: volt*second/ampere                         # 亨利
  abhenry: 1e-9{henry}                              # 绝对亨利
  stathenry: 8.987551787368176e11{henry}            # 静亨利
  millihenry: milli*henry                           # 毫亨
  microhenry: micro*henry                           # 微亨

  weber: volt*second                                # 韦伯
  maxwell: 1e-8{weber}                              # 麦克斯韦
  kiloweber: kilo*weber                             # 千韦伯

  tesla: weber/meter^2                              # 特斯拉
  gauss: 1e-4{tesla}                                # 高斯
  kilogauss: 0.1{tesla}                             # 千高斯
  gamma: 1e-9{tesla}                                # 伽马

  oersted: 79.5774715459{ampere/meter}              # 奥斯特
  gilbert: 0.79577471459{ampere}                    # 吉伯

  # ============== 放射性导出单位 ==============
  becquerel: /second                               # 贝克勒尔
  curie: 3.7e10{becquerel}                          # 居里
  rutherford: 1e6{becquerel}                        # 卢瑟福

  gray: joule/kilogram                              # 戈瑞
  rad: 0.01{gray}                                   # 拉德
  sievert: gray                                     # 希沃特
  rem: 0.01{sievert}                                # 雷姆

  roentgen: 2.58e-4{coulomb/kilogram}               # 伦琴

  # ============== 化学导出单位 ==============
  molar: 1e-3{mole/meter^3}                  # 摩尔浓度
  millimolar: milli*molar                           # 毫摩尔浓度
  micromolar: micro*molar                           # 微摩尔浓度
  nanomolar: nano*molar                             # 纳摩尔浓度
  picomolar: pico*molar                             # 皮摩尔浓度

  # ============== 流体力学导出单位 ==============
  pascal_second: pascal*second                      # 帕斯卡·秒
  poise: 0.1{pascal_second}                         # 泊
  stokes: 1e-4{meter^2/second}                      # 斯托克斯

  darcy: 9.869233e-13{meter^2}                      # 达西
  millidarcy: milli*darcy                           # 毫达西

  # ============== 核物理导出单位 ==============
  barn: 1e-28{meter^2}                              # 靶恩
  millibarn: milli*barn                             # 毫靶恩
  microbarn: micro*barn                             # 微靶恩

  fermi_cubed: 1e-45{meter^3}                       # 费米立方

  # ============== 天体物理导出单位 ==============
  solar_radius: 6.957e8{meter}                      # 太阳半径
  solar_luminosity: 3.828e26{watt}                  # 太阳光度
  earth_radius: 6.371e6{meter}                      # 地球半径

  # ============== 地球物理导出单位 ==============
  gal: 0.01{meter/second^2}                         # 伽
  milligal: milli*gal                               # 毫伽
  eotvos: 1e-9{/second^2}                             # 厄缶

  # ============== 工程学导出单位 ==============
  knot: nautical_mile/hour                          # 节

  # 加速度单位
  standard_gravity: 9.80665{meter/second^2}         # 标准重力加速度

  # 力单位
  poundal: 0.138254954376{newton}                   # 磅达

  # 压力单位
  technical_atmosphere: 98066.5{pascal}             # 工程大气压
  millimeter_of_water: 9.80665{pascal}              # 毫米水柱

  # 能量单位
  thermochemical_calorie: 4.184{joule}              # 热化学卡路里
  ton_of_tnt: 4.184e9{joule}                        # 吨TNT当量

  # 功率单位
  poncelet: 980.665{watt}                           # 蓬塞莱



