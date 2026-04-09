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
    # 1. 基本单位创建与运算 (`{}` 宏)
    let distance = 100{km}        # 距离
    let time = 2{h}               # 时间 (使用simphy中的小时单位)
    let velocity = distance / time # 速度，自动组合单位
    echo "速度: ", velocity        # 50 km/h
  
    # 2. 单位字符串获取 (`unit` 函数)
    echo "速度单位: ", velocity.unit  # km/h
    echo "单位内部字符串", velocity.unitU # *km//h
  
    # 3. 去单位化 (`deUnit` 函数)
    echo "速度值: ", velocity.deUnit  # 50.0
  
    # 4. 单位转换 (`siTo` 函数)
    echo "转换为 m/s: ", velocity.siTo("m/s")  # 13.888... m/s
  
    # 5. 智慧型单位转换 (`wisSiTo` 函数)
    let g = 9.8{m/s^2}             # 重力加速度 (使用simphy中的平方符号)
    let height = 50.0{cm}            # 高度 (使用simphy中的厘米单位)
    let impactVelocity = sqrt(2.0 * g.wisSiTo(height.unit/"s^2") * height)
    echo "落地速度: ", impactVelocity  # 3.130... m/s
  
    # 6. 复合单位展平 (`flatUnit` 函数)
    let compoundUnit = 1{m}{s}     # 复合单位
    let flat = compoundUnit.flatUnit  # 展平单位
    echo "复合单位: ", compoundUnit  # 1 m s
    echo "展平后: ", flat  # 1 m·s
  
    # 7. 智慧获取单位组合 (`wisUnit` 函数)
    let a = 1{m}
    let b = 1{s}
    let c = 1.wisNewUnit(a.unit/b.unit)  # 获取m/s单位
    echo "智慧单位组合: ", c  # 1 m/s
  
    # 8. 单位转换辅助 (`convertUnit` 函数)
    let speed = 100.0{km/h}
    echo "速度转换: ", speed.convertUnit {
      km: 1000.0{m},
      h: 3600.0{s}
    }  # 27.77777777777778 m/s
  
    # 9. 内部值操作 (`doUnitInner` 函数)
    var v = 5.0{m}
    doUnitInner(v, proc(x: var float)=x*=2.0)
    echo "值操作后: ", v  # 10.0 m
  
    # 10. 跨领域单位 (金融)
    addSiUnit:
      USD: 1.0                # 美元
      EUR: 0.93{USD}          # 欧元
      BTC: 25000{USD}         # 比特币
  
    let price = 100.0{EUR}
    echo "价格(美元): ", price.siTo("USD")  # 93.0 USD
  
    # 11. 物理计算示例
    let mass = 10.0{kg}              # 质量
    let velocity2 = 10.0{m/s}        # 速度
    let kineticEnergy = 0.5 * mass * velocity2^2  # 动能
    echo "动能: ", kineticEnergy.siTo"J"    # 500.0 J
  
    # 12. 类型安全与USi概念
    func getWork[T](force: USi[T, "N"], distance: USi[T, "m"]): USi[T, "J"] =
      force * distance
  
    let f = 10{N}                  # 力 (使用simphy中的牛顿单位)
    let d = 5{m}
    let work = getWork(f, d)
    echo "做功: ", work  # 50 N·m
  
    # 13. 数学运算
    let x = 10.0{m}
    let y = 5.0{m}
    echo "加法: ", x + y  # 15.0 m
    echo "减法: ", x - y  # 5.0 m
    echo "乘法: ", x * y  # 50.0 m²
    echo "除法: ", x / y  # 2.0 (无单位)
    echo "平方根: ", sqrt(x)  # 3.1622776601683795 m¹⸍²
    echo "绝对值: ", abs(-x)  # 10.0 m
  
    # 14. 比较运算符
    echo "相等: ", x == y  # false
    echo "小于: ", y < x  # true
    echo "大于: ", x > y  # true
  
    # 15. 检查单位表 (`checkCurSi` 函数)
    static:
      let siCheck = checkCurSi()
      echo "SI单位表检查: ", siCheck  # true

```

