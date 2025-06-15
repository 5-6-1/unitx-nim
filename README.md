# unitx-nim

Zero-cost unit safety | Compile-time algebra | Fractional exponents

Build dimensionally correct physics, finance and astronomy models


## Examples
```nim
import unitx
import unitx/[simphy,physics]
import math


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
  let solarSystem = 80.0~au
  echo "Solar System diameter: ", (0.0~ly) + solarSystem # 0.0012650005927856527 ly

  let andromeda = 2.5e6~ly
  let cosmicTravelTime = andromeda / c  # 单位：秒
  echo "Andromeda light travel time: ", cosmicTravelTime.convertSimpleSiUnit.siTo "year" #2500000.0000000005 year

  echo "\n==== Engineering: Material Strength ===="
  let beamForce = 500.0~newton
  let beamArea = 0.005~m^2
  let stress = beamForce / beamArea
  echo "Material stress: ", stress.siTo "kPa"  # 10.0 kPa


  echo 1 ~ ?-?^2*!^(1/3) #any unit  !¹⸍³·?-?²
  # Automatic dimension checking (commented to run)
  # let invalid = 5~meter + 10~second  # Compile-time error

  echo "\n==== Unitx Demonstration Complete ===="
```
Perhaps you need to use AI to analyze my 300 lines of lightweight source code

