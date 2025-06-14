# unitx-nim

Zero-cost unit safety | Compile-time algebra | Fractional exponents

Build dimensionally correct physics, finance and astronomy models


## Examples
```nim
import unitx
import math
when isMainModule:
  # Define common units in SI base
  addSiUnit {
    # Metric prefixes
    km: 1000~meter, cm: 0.01~meter, mm: 0.001~meter,
    kg: 1~kilogram, g: 0.001~kilogram,
    ms: 0.001~second, min: 60~second, hr: 3600~second,

    # Scientific units
    N: 1~kilogram*meter/second^2,      # Newton
    J: 1~N*meter,                     # Joule
    W: 1~J/second,                    # Watt
    Pa: 1~N/meter^2,                   # Pascal

    # Astronomy
    AU: 149597870700~meter,            # Astronomical Unit
    ly: 9460730472580800~meter,        # Light-year

    # Economics
    USD: 1~"", EUR: 0.93~USD,           # Currency
    BTC: 25000~USD, ETH: 1800~USD,     # Crypto

    # Chemistry
    mol: 1~mole, mmol: 0.001~mole
  }
  echo "==== Physics: Gravitational Potential ===="
  const g = 9.80665~meter/second^2      # Standard gravity
  let height = 100.0~meter
  let fallTime = (2.0 * height / g)^0.5
  echo "Fall time: ", fallTime          # 4.5160075575178755 second

  let impactEnergy = height * (75.0~kilogram) * g  # Weight = 75kg
  echo "Impact energy: ", impactEnergy.convertSimpleSiUnit  # 73549.875 kilogram·meter²/second²

  echo "\n==== Quantum Physics: Photon Energy ===="
  const
    h = 6.62607015e-34~J*second            # Planck constant
    c = 299792458.0~meter/second         # Speed of light

  let photonWavelength = 532e-9~meter  # Green laser
  let photonEnergy = h * c / photonWavelength
  echo "Photon energy: ", photonEnergy.convertUnit {J: 1.0/1.602e-19~eV}  # 2.3307870063136877 eV

  echo "\n==== Finance: Unified Portfolio Calculation ===="
  let
    cash = 5000~USD
    btc = 1~BTC
    eth = 3~ETH

  let portfolioUSD = cash + btc + eth
  echo "Solution 1 portfolio: ", portfolioUSD  # 35400 USD

  echo "\n==== Chemistry: Molar Calculations ===="
  let H2O_Mass = 18.01528~g/mol        # Molar mass
  let sampleMass = 100.0~g
  let moles = sampleMass / H2O_Mass

  const N_A = 6.02214076e23 ~ /mol       # Avogadro's constant
  let molecules = moles * N_A
  echo "Molecules in 100g water: ≈", molecules #3.342796093094306e+24

  echo "\n==== Astronomy: Cosmic Scales ===="
  # 更精确的单位定义
  addSiUnit {
      AU: 149597870700~meter,           # 1 AU = 149,597,870,700 m
      ly: 9460730472580800~meter,       # 1 ly = 9,460,730,472,580,800 m
      year: 31556952~second             # 天文年 = 365.2425 days
  }
  let solarSystem = 80.0~AU
  echo "Solar System diameter: ", (0.0~ly) + solarSystem # 0.0012650005927856527 ly

  let andromeda = 2.5e6~ly
  let cosmicTravelTime = andromeda / c  # 单位：秒
  echo "Andromeda light travel time: ", cosmicTravelTime.convertSimpleSiUnit.convertUnit {second: 1/31556952~year} #2500051.3357563815 year

  echo "\n==== Engineering: Material Strength ===="
  let beamForce = 500.0~N
  let beamArea = 0.005~meter^2
  let stress = beamForce / beamArea
  echo "Material stress: ", stress.convertUnit {N:1.0~pa*meter^2,pa:0.0001~kpa}  # 10.0 kpa

  # Automatic dimension checking (commented to run)
  # let invalid = 5~meter + 10~second  # Compile-time error

  echo "\n==== Unitx Demonstration Complete ===="

```
Perhaps you need to use AI to analyze my 300 lines of lightweight source code

