from ../unitx import addSiUnit,addSimpleSiUnit,addSiUnitInner,formatUnit
{.used.}
# 简写单位系统（兼容全称）

# ================ SI基本单位简写 ================
addSiUnit:
  A: ampere       # 安培
  cd: candela     # 坎德拉
  K: kelvin       # 开尔文
  kg: kilogram    # 千克
  m: meter        # 米
  mol: mole       # 摩尔
  s: second       # 秒

# ================ 长度单位简写 ================
  au: astronomical_unit
  am: attometer
  cm: centimeter
  dm: decimeter
  Em: exameter
  fm: femtometer
  km: kilometer
  ly: light_year
  Mm: megameter
  mm: millimeter
  nm: nanometer
  pc: parsec
  Pm: petameter
  pm: picometer
  Tm: terameter
  Ym: yottameter
  Zm: zettameter

  # 非SI长度单位简写
  ft: foot
  mi: mile
  yd: yard

# ================ 质量单位简写 ================
  cg: centigram
  dag: decagram
  dg: decigram
  Gg: gigagram
  g: gram
  hg: hectogram
  Mg: megagram
  mg: milligram
  ng: nanogram
  pg: picogram
  Tg: teragram
  t: metric_ton

  # 非SI质量单位简写
  u: atomic_mass_unit
  Da: dalton
  lb: pound
  oz: ounce

# ================ 时间单位简写 ================
  cs: centisecond
  ds: decisecond
  fs: femtosecond
  h: hour
  ks: kilosecond
  ms: millisecond
  min: minute
  ns: nanosecond
  ps: picosecond
  Ts: terasecond
  wk: week
  yr: year
  mo: month

# ================ 电流单位简写 ================
  cA: centiampere
  dA: deciampere
  kA: kiloampere
  MA: megaampere
  mA: milliampere
  nA: nanoampere
  pA: picoampere

# ================ 温度单位简写 ================
  mK: millikelvin
  nK: nanokelvin

# ================ 物质的量单位简写 ================
  cmol: centimole
  dmol: decimole
  kmol: kilomole
  mmol: millimole
  nmol: nanomole
  pmol: picomole

# ================ 发光强度单位简写 ================
  ccd: centicandela
  dcd: decicandela
  kcd: kilocandela
  mcd: millicandela

# ================ 力学导出单位简写 ================
  N: newton
  dyn: dyne
  lbf: pound_force
  kgf: kilogram_force
  ozf: ounce_force

  Pa: pascal
  kPa: kilo*Pa
  atm: atmosphere
  mmHg: millimeter_of_mercury
  Ba: barye

  J: joule
  cal: calorie
  kcal: kilocalorie
  eV: electronvolt
  keV: kiloelectronvolt
  MeV: megaelectronvolt
  GeV: gigaelectronvolt
  TeV: teraelectronvolt
  BTU: british_thermal_unit
  thm: therm

  W: watt
  hp: horsepower
  kW: kilowatt
  MW: megawatt
  GW: gigawatt
  TW: terawatt

  Nm: newton_meter

# ================ 电磁学导出单位简写 ================
  C: coulomb
  e: elementary_charge

  V: volt
  kV: kilovolt
  MV: megavolt

  kohm: kilohm
  Mohm: megaohm

  S: siemens

  F: farad
  pF: picofarad

  H: henry
  mH: millihenry

  Wb: weber
  kWb: kiloweber

  T: tesla
  Gs: gauss
  kGs: kilogauss

  Oe: oersted
  Gb: gilbert

# ================ 放射性导出单位简写 ================
  Bq: becquerel
  Ci: curie
  Rd: rutherford

  Gy: gray
  Sv: sievert


  R: roentgen

# ================ 化学导出单位简写 ================
  M: molar
  mM: millimolar
  nM: nanomolar
  pM: picomolar

# ================ 流体力学导出单位简写 ================
  Pas: pascal_second
  P: poise
  St: stokes

  D: darcy
  mD: millidarcy

# ================ 核物理导出单位简写 ================
  b: barn
  mb: millibarn

# ================ 天体物理导出单位简写 ================
  Rsun: solar_radius
  Lsun: solar_luminosity
  Rearth: earth_radius

# ================ 地球物理导出单位简写 ================
  Gal: gal
  mGal: milligal
  Eo: eotvos

# ================ 工程学导出单位简写 ================
  kn: knot
  g0: standard_gravity
  pdl: poundal
  at: technical_atmosphere
  tTNT: ton_of_tnt
  pn: poncelet
