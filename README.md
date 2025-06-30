# UnitX: One System, All Measurements

Universal Unit Safety​
Zero-Cost • Compile-Time • Fractional Exponents

1. Compile-Time Validation
2. Fractional Exponents: m^(3/2)
3. Zero Runtime Overhead
4. Cross-Domain Consistency

## Examples
```nim
import unitx
import unitx/[simphy,physics]

when isMainModule:
  # Define common units in SI base
  addSiUnit {
    # Economics
    USD,          #Directly increase the basic SI unit
    EUR: 0.93~USD,           # Currency
    BTC: 25000~USD, ETH: 1800~USD,     # Crypto
  }

  echo "==== Physics: Gravitational Potential ===="
  const g = 9.80665~meter/second^2      # Standard gravity
  let height = 100.0~meter
  proc getTime[T;U:static[string]](h:Unit[T,U],g:wisUSi(T,U^0.5*"/s"^2*U^(1/2))):USi[T,"s"]=sqrt T(2)*h/g
  #Unit是本体,右侧为死的字符串约束
  #USi是concept,根据Si系统匹配
  #wisUSi是宏,生成concept,用来处理泛型的乘除幂操作
  let fallTime = getTime(height,g)


  echo "Fall time: ", fallTime          # 4.5160075575178755 second

  let impactEnergy = height * 75.0{kilogram} * g  # `{}`语法是`~`语法糖,用于减少~操作符所带来的优先级问题,且提供同样简洁直观的写法
  echo "Impact energy: ", impactEnergy.siTo"N*m"  # 73549.875 N·m

  echo "\n==== Quantum Physics: Photon Energy ===="
  const
    h = 6.62607015e-34~J*second            # Planck constant
    c = 299792458.0~meter/second         # Speed of light

  let photonWavelength = 532e-9~meter  # Green laser
  let photonEnergy = h * c / photonWavelength
  echo "Photon energy: ", photonEnergy.convertUnit {J: 1.0/1.602e-19~eV}  # 2.3307870063136877 ev

  echo "\n==== Finance: Unified Portfolio Calculation ===="
  let
    cash = 5000~USD
    btc = 1~BTC
    eth = 3~ETH

  let portfolioUSD = cash + btc + eth
  echo "Solution 1 portfolio: ", portfolioUSD  # 35400 Usd

  echo "\n==== Chemistry: Molar Calculations ===="
  let H2O_Mass = 18.01528~g/mol        # Molar mass
  let sampleMass = 100.0~g
  let moles = sampleMass / H2O_Mass

  const N_A = 6.02214076e23~/mol       # Avogadro's constant
  let molecules = moles * N_A
  echo "Molecules in 100g water: ≈", molecules #3.342796093094306e+24

  echo "\n==== Astronomy: Cosmic Scales ===="
  # 更精确的单位定义
  let solarSystem = 80.0~au
  echo "Solar System diameter: ", 0.0{ly} + solarSystem # 0.0012650005927856527 ly

  let andromeda = 2.5e6~ly
  let cosmicTravelTime = andromeda / c  # 单位：秒
  echo "Andromeda light travel time: ", cosmicTravelTime.siTo "year" #2500000.0000000005 year

  echo "\n==== Engineering: Material Strength ===="
  let beamForce = 500.0~newton
  let beamArea = 0.005~m^2
  let stress = beamForce / beamArea
  echo "Material stress: ", stress.siTo "kPa"  # 10.0 kpa


  echo 1 ~ ?-?^2*!^(1/3) #any unit  !¹⸍³·?-?²
  # Automatic dimension checking (commented to run)
  # let invalid = 5~meter + 10~second  # Compile-time error

  echo "\n==== Unitx Demonstration Complete ===="


```

