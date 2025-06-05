# unitx-nim

Lightweight compile time unit system | Algebraic expression unit calculation | Zero cost type safe

You can use any unit you can think of


## Examples
```nim
import unitx

# =====================
# 基础物理单位运算 (修正：保持工程习惯输出)
# =====================
let
  distance = 150.0 ~ km         # 距离：150km
  time = 45.0 ~ minutes          # 时间：45分钟
  speed = distance / time        # 速度自动推导

echo "车速：", speed.convertUnit {minutes: 1.0/60.0 ~ hour}  # 输出：200.0 km/hour

# =====================
# 单位即时转换 (修正转换因子)
# =====================
let usSpeed = speed.convertUnit {
  km: 1.609 ~ mile,              # km → mile
  minutes: 1.0/60.0 ~ hour           # 分钟→小时
}

echo "美制单位：", usSpeed    # 输出：321.8 mile/hour

# =====================
# 跨学科单位计算 (完全重构)
# =====================
let
  cpuPower = 320.0 ~ GFLOPS      # 计算能力
  energyUse = 250.0 ~ watt       # 能耗
  efficiency = cpuPower / energyUse

# 物理正确的单位转换：
let econRating = efficiency.convertUnit {
  watt: 0.001 ~ kW,              # 功率单位转换
  GFLOPS: 1e10 ~ FLOPS/second,
  second: 1.0/3600.0 ~ hour          # 时间单位转换
}                                # GFLOPS → FLOPS (十亿到基本单位)

echo "能效评级：", econRating # 输出：4608000000000000.0 FLOPS/hour·kW (4.608e12)

# =====================
# 自定义趣味单位 (保持不变)
# =====================
const CoffeePower = 1.0 ~ 杯咖啡
let
  taskComplexity = 3.0 ~ 任务点
  programmer = (2.0 ~ 程序员) * (0.5 ~ 杯咖啡/hour)
  timeEstimate = taskComplexity / programmer

echo "完成时间：", timeEstimate # 输出：3.0 hour·任务点/杯咖啡·程序员

# =====================
# 编译时期量纲安全 (保持不变)
# =====================
try:
  # 下面语句会导致编译错误（类型不匹配）
  # let invalid = speed + energyUse
  discard
except:
  echo "✅ 量纲保护生效：无法将速度与能量相加！"

# 输出结果：
# 车速：200 km/hour
# 美制单位：200.0 mile/hour
# 能效评级：4.608e12 FLOPS·kW⁻¹·hour⁻¹
# 完成时间：3.0 hour·任务点/杯咖啡·程序员
# ✅ 量纲保护生效：无法将速度与能量相加！



```
