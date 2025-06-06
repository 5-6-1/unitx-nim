# unitx-nim

Lightweight compile time unit system | Algebraic expression unit calculation | Zero cost type safe

You can use any unit you can think of


## Examples
```nim
import unitx
import math

when isMainModule:
  echo "====== Physics & Mechanics ======"

  # Basic kinematics demo
  let height = 100.0~m        # Distance in meters
  const g = 9.8~m/s^2         # Gravitational acceleration
  let time = (2.0 * height / g)^0.5
  echo "Time to fall: ", time  # Automatically formats as " 4.5175395145262565 s"

  let initVelocity = 20.0~m/s
  let velocity = initVelocity + g * time
  echo "Impact velocity: ", velocity  # "64.27188724235731 m/s"

  echo "\n====== Finance Calculation ======"
  let 电脑价格 = 5000.0~元       # Computer price in yuan
  let monthlyIncome = 12000.0~元/月  # Monthly income

  # Calculate payoff time
  let payoffTime = 电脑价格 / monthlyIncome
  echo "电脑偿还时间: ", payoffTime  # Shows as 0.4166666666666667 月

  # Convert to days
  let payoffDays = payoffTime.convertUnit {月: 30.0~日}
  echo "相当于 ", payoffDays  # Shows as 12.5 日

  echo "\n====== Chemistry Calculations ======"
  const molarMass = 18.015~g/mol
  let waterSample = 5.0~g

  # Calculate moles
  let moles = waterSample / molarMass
  echo "Moles of water: ", moles  # "0.2775464890369137 mol"

  # Avogadro's number
  const N_A = 6.022e23 ~ /mol
  let molecules = moles * N_A
  echo "Molecules: ≈", molecules.deUnit  # Show as integer count 1.6713849569802942e+23

  echo "\n====== Custom Units ======"
  # Astronomy example
  const astronomicalUnit = 1.496e11~m  # Earth-Sun distance
  let marsDistance = 1.52 * astronomicalUnit
  echo "Mars distance: ", marsDistance.convertUnit {m: 1e3~km}  # Show in km 227392000000000.0 km

  # Crypto example
  let portfolio = (0.5~₿) + (3.5~Ξ).convertUnit {Ξ: 0.069~₿}
  echo "Portfolio value: ", portfolio, " (in BTC)"   #0.7415 ₿

  echo "\n====== Complex Formulas ======"
  # Electromagnetism: Energy in a capacitor
  let capacitance = 100e-6~F      # 100 μF
  let voltage = 12.0~V            # 12 Volts
  let energy = 0.5 * capacitance * (voltage^2)
  echo "Capacitor energy: ", energy.convertUnit {V:1.0~J^(1/2)/F^(1/2),J: 1e3~mJ}  # Show in milliJoules 7.200000000000001 mJ

  # Wave physics
  let wavelength = 500e-9~m       # 500 nm (green light)
  const c = 3e8~m/s               # Speed of light
  let frequency = c / wavelength
  echo "Light frequency: ", frequency.convertUnit {s: 1.0 ~ /Hz}  # Show in Hz   600000000000000.0 Hz

  echo "\n====== Fractional Exponents ======"
  # Drag force equation: Fₛ = √(ρ) * A * v²
  let density = 1.225~kg/m^3       # Air density
  let area = 0.5~m^2               # Frontal area
  let velocity_n = 25.0~m/s          # Velocity

  let dragForce = createUnit(density.deUnit ^ 0.5,density.U) * area * velocity_n^2
  echo "Drag force: ≈", dragForce.convertUnit {kg: 1.0~s^2*N/m}  # ~345.8741190809165 N

  # Custom fractional exponent
  let volume = 27.0~m^3
  let sideLength = (volume) ^ (1.0/3)  # = ∛(27 m³) = 3 m
  echo "Cube side: ", sideLength    # 3.0 m

  echo "\n====== Error Prevention ======"
  # Type-safe units prevent incorrect operations
  let distance = 10.0~m
  let time_n = 2.0~s
  # let invalid = distance + time_n  # Compile-time error: unit mismatch
  echo "\n====== All Features Showcase Complete ======"



```
Perhaps you need to use AI to analyze my 300 lines of lightweight source code

