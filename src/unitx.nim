import macros
import strutils
import algorithm
import math
import tables
import unicode

const superScriptMap={'0':"⁰",'1':"¹",'2':"²",'3':"³",'4':"⁴",'5':"⁵",'6':"⁶",'7':"⁷",'8':"⁸",'9':"⁹"}.toTable
proc readUnit*(u:string):string=
  var
    flag=false
    d=0
  for c in u:
    if c=='/':
      inc d
    else:
      if d==1:
        result.add"⸍"
      elif d==2:
        result.add'/'
      if c in '0'..'9':
        if flag: result.add superScriptMap[c]
        else:result.add c
      elif c=='^':flag=true
      elif c=='*':
        result.add"·"
        flag=false
      else:
        result.add c
        flag=false
      d=0

proc gcd(a,b: int): int =
  var (x, y) = (abs a, abs b)
  var n = 0
  while (x and 1) == 0 and (y and 1) == 0:
    x = x shr 1
    y = y shr 1
    inc n
  while true:
    if (x and 1) == 0: x = x shr 1
    elif (y and 1) == 0: y = y shr 1
    else:
      if x < y: swap(x, y)
      x -= y
      if x == 0:
        return y shl n
proc simplifyFrac(num:(int,int)):(int,int) =
  if num[0]==0:
    return (0,1)
  let gcdVal=gcd(num[0],num[1])
  return
    if num[1]>0:(num[0] div gcdVal,num[1] div gcdVal)
    elif num[1]<0:(-num[0] div gcdVal,-num[1] div gcdVal)
    else: raise newException(ValueError,"Invalid fraction")
proc fracAdd(a, b: (int, int)): (int, int) =simplifyFrac (a[0]*b[1]+b[0]*a[1],a[1]*b[1])
proc fracMul(a, b: (int, int)): (int, int) =simplifyFrac (a[0]*b[0],a[1]*b[1])
proc fracPow[T](a:T, b: (int, int)):T = T(a.float^(b[0].float/b[1].float))
proc floatToFraction(x: float): (int, int) =
  if x == 0.0:
    return (0, 1)
  let
    sign = if x < 0: -1 else: 1
    x0 = abs(x)
    maxDenominator = 1_000_000
    epsilon = 1e-6
  var whole = floor(x0).int64
  var remainder = x0 - whole.float
  if remainder < 1e-12:
    return (sign * whole.int, 1)
  var
    a0: int64 = whole
    r = remainder
    h0: int64 = 1
    k0: int64 = 0
    h1: int64 = a0
    k1: int64 = 1
  while true:
    let an = floor(1.0 / r).int64
    let rNext = 1.0 / r - an.float
    let h2 = an * h1 + h0
    let k2 = an * k1 + k0
    if k2 > maxDenominator:
      let err1 = abs(h1.float / k1.float - x0)
      let err2 = abs(h2.float / k2.float - x0)
      if err1 <= err2:
        return (sign * h1.int, k1.int)
      else:
        return (sign * h2.int, k2.int)
    let error = abs(h2.float / k2.float - x0)
    if error <= epsilon:
      return (sign * h2.int, k2.int)
    h0 = h1; k0 = k1
    h1 = h2; k1 = k2
    r = rNext
    if r < 1e-12:
      return (sign * h2.int, k2.int)


proc addInUnit(tups:var seq[(string,(int,int))],tup:(string,(int,int))) =
  if tup[1]==(0,1):return
  var tr=false
  var result=newSeq[(string,(int,int))]()
  for (s,e) in tups:
    let x = cmp(s,tup[0])
    if x==0:
      tr=true
      if (e.fracAdd tup[1])[0]!=0:
        result.add (s,e.fracAdd tup[1])
    elif x<0:
      result.add (s,e)
    else:
      if not tr:
        tr=true
        result.add tup
      result.add (s,e)
  if not tr:
    result.add tup
  tups=result
proc delOutUnit(tups:var seq[(string,(int,int))],ss:string) =
  var result=newSeq[(string,(int,int))]()
  for (s,e) in tups:
    if s!=ss:
      result.add (s,e)
  tups=result


type Unit*[T;U:static[string]]=distinct T #轻量单位类型,U为单位
proc `$`*(arg:Unit):string = $arg.T(arg)&" "&arg.U.readUnit
proc formatUnitHelper(u:static[string]):static[string] =
  let li=u.replace(" ","")
  var
    str=""
    flag=false
  for c in li:
    if c=='(':
      flag=true
    elif c==')':
      flag=false
    elif c=='/':
      str.add if flag:"/"else:"//"
    else:
      str.add c
  let
    list=str.split"//"
  var
    left=list[0].split'*'
    right=if list.len>1:list[1].split'*' else:newSeq[string]()
  left.join"*"&(if right.len==0:"" else:"//"&right.join"*")
proc tupUnit(u:static[string]):static[seq[(string,(int,int))]]=
  let
    list=u.split"//"
    left=list[0].split'*'
    right=if list.len>1:list[1].split'*' else:newSeq[string]()
  for l in left:
    let
      llist=l.split"^"
      base=llist[0]
      exp=
        if llist.len>1:
          let nlist=llist[1].split"/"
          let x=nlist[0].parseInt
          if x==0: continue
          if nlist.len==1:
            (x,1)
          else:
            let y=nlist[1].parseInt
            if y>0: simplifyFrac (x,y)
            elif y<0: simplifyFrac (-x,-y)
            else: raise newException(ValueError, "invalid exponent")
        else:(1,1)
    result.add (base,exp)
  for l in right:
    let
      llist=l.split"^"
      base=llist[0]
      exp=
        if llist.len>1:
          let nlist=llist[1].split"/"
          let x=nlist[0].parseInt
          if x==0: continue
          if nlist.len==1:
            (-x,1)
          else:
            let y=nlist[1].parseInt
            if y>0:simplifyFrac (-x,y)
            elif y<0:simplifyFrac (x,-y)
            else: raise newException(ValueError, "invalid exponent")
        else:(-1,1)
    result.add (base,exp)
  proc comTupUnit(a,b:(string,(int,int))):int=cmp a[0],b[0]
  result.sort comTupUnit
proc tupToUnit(tups:static[seq[(string,(int,int))]]):static[string] =
  var
    st=newSeq[string]()
    stDiv=newSeq[string]()
  for (s,e)in tups:
    if e[0]>0:st.add s&(if e[0]!=1 or e[1]!=1: "^" & $e[0] & (if e[1]!=1:"/" & $e[1]else:"") else: "")
    elif e[0]==0:continue
    else:stDiv.add s&(if e[0] != -1 or e[1]!=1: "^" & $(-e[0]) & (if e[1]!=1:"/" & $e[1]else:"") else: "")
  st.join("*")&(if stDiv.len>0:"//"&stDiv.join"*" else:"")
proc formatUnit*(u:static[string]):static[string] =
  let list=u.split"//"
  if list.len>1:u
  else:tupToUnit tupUnit formatUnitHelper u
proc createUnit*[T](val:T,u:static[string]):Unit[T,formatUnit u]=Unit[T,formatUnit u]val#由string创建单位
macro `~`*(val,str):Unit =
  if val is unitx.Unit:
    quote do:`val` * createUnit(`val`.T(1),formatUnit astToStr `str`)
  else:
    quote do:unitx.Unit[typeof `val`,formatUnit astToStr `str`] `val`#提供直接创建方法
proc mulUnitHelper(a,b:static[string]):static[seq[(string,(int,int))]] =
  let
    tupA=tupUnit(a)
    tupB=tupUnit(b)
  var
    cuA=0
    cuB=0
  while cuA<tupA.len and cuB<tupB.len:
    let x= cmp(tupA[cuA][0],tupB[cuB][0])
    if x==0:
      if (tupA[cuA][1].fracAdd tupB[cuB][1])[0]!=0:
        result.add (tupA[cuA][0],tupA[cuA][1].fracAdd tupB[cuB][1])
      inc cuA
      inc cuB
    elif x<0:
      result.add tupA[cuA]
      inc cuA
    else:
      result.add tupB[cuB]
      inc cuB
  if cuA!=tupA.len:
    for i in cuA..tupA.len-1:
      result.add tupA[i]
  if cuB!=tupB.len:
    for i in cuB..tupB.len-1:
      result.add tupB[i]
proc mulUnit(a,b:static[string]):static[string] = tupToUnit mulUnitHelper(a,b)
proc divUnitHelper(a,b:static[string]):static[seq[(string,(int,int))]] =
  let
    tupA=tupUnit(a)
    otupB=tupUnit(b)
  var
    tupB=newSeq[(string,(int,int))]()
    cuA=0
    cuB=0
  for (s,e)in otupB:
    tupB.add (s, (-e[0],e[1]))
  while cuA<tupA.len and cuB<tupB.len:
    let x= cmp(tupA[cuA][0],tupB[cuB][0])
    if x==0:
      if (tupA[cuA][1].fracAdd tupB[cuB][1])[0]!=0:
        result.add (tupA[cuA][0],tupA[cuA][1].fracAdd tupB[cuB][1])
      inc cuA
      inc cuB
    elif x<0:
      result.add tupA[cuA]
      inc cuA
    else:
      result.add tupB[cuB]
      inc cuB
  if cuA!=tupA.len:
    for i in cuA..tupA.len-1:
      result.add tupA[i]
  if cuB!=tupB.len:
    for i in cuB..tupB.len-1:
      result.add tupB[i]
proc divUnit(a,b:static[string]):static[string] = tupToUnit divUnitHelper(a,b)
proc powerUnitHelper(a:static[string],n:static[(int,int)]):static[seq[(string,(int,int))]] =
  let tupA=tupUnit(a)
  for (s,e) in tupA:
    result.add (s,(e[0],e[1]).fracMul n)
proc powerUnit(a:static[string],n:static[(int,int)]):static[string] = tupToUnit powerUnitHelper(a,n)
proc deUnit*[T;U:static[string]](u:Unit[T,U]):T=T(u)#获得单位数值
proc convertUnitHelp(val:static[string],orign:static[string]):static[(int,int)]=
  let tup=tupUnit(val)
  for (s,e) in tup:
    if s==orign:
      return e
  return (0,1)
proc convertUnitHelper(val:static[string],orign:static[string],to:static[string]):
  static[seq[(string,(int,int))]] =
  var tup=tupUnit(val)
  let toer=tupUnit(to)
  let e=convertUnitHelp(val,orign)
  delOutUnit(tup,orign)
  for t in toer:
    addInUnit(tup,(t[0],t[1].fracMul e))
  tup
proc convertUnitInner*[T;U:static[string]](val:Unit[T,U],orign:static[string],to:static[string],factor:static[T]):
  Unit[T,tupToUnit convertUnitHelper(U,orign,to)]=
  Unit[T,tupToUnit convertUnitHelper(U,orign,to)] T(val)*factor.fracpow convertUnitHelp(U,orign)
macro convertUnit*(val,conv):untyped =
  result=val
  if conv.kind==nnkTableConstr:
    for con in conv:
      expectKind con, nnkExprColonExpr
      expectKind con[1],nnkInfix
      expectIdent con[1][0],"~"
      result = newCall(ident"convertUnitInner",result,toStrLit con[0],newTree(nnkCall,ident"formatUnit",toStrLit con[1][2]),con[1][1])#单位安全转换


proc `+`*[T;U:static[string]](l,r:Unit[T,U]):Unit[T,U] = Unit[T,U](T(l)+T(r))
proc `-`*[T;U:static[string]](l,r:Unit[T,U]):Unit[T,U] = Unit[T,U](T(l)-T(r))
proc `*`*[T;U1,U2:static[string]](l:Unit[T,U1],r:Unit[T,U2]):Unit[T,mulUnit(U1,U2)]=Unit[T,mulUnit(U1,U2)](T(l)*T(r))
proc `/`*[T;U1,U2:static[string]](l:Unit[T,U1],r:Unit[T,U2]):Unit[T,divUnit(U1,U2)]=Unit[T,divUnit(U1,U2)](T(l)/T(r))
proc `*`*[T;U:static[string]](l:Unit[T,U],r:T):Unit[T,U]=Unit[T,U](T(l)*r)
proc `/`*[T;U:static[string]](l:Unit[T,U],r:T):Unit[T,U]=Unit[T,U](T(l)/r)
proc `*`*[T;U:static[string]](r:T,l:Unit[T,U]):Unit[T,U]=Unit[T,U](T(l)*r)
proc `/`*[T;U:static[string]](r:T,l:Unit[T,U]):Unit[T,powerUnit(U,(-1,1))]=Unit[T,powerUnit(U,(-1,1))](r/T(l))
proc `^`*[T;U:static[string]](l:Unit[T,U],n:static[(int,int)]):
  Unit[T,powerUnit(U,n)]=Unit[T,powerUnit(U,n)]T(float(l) ^ (n[0].float/n[1].float))
proc `^`*[T;U:static[string]](l:Unit[T,U],n:static[int]):
  Unit[T,powerUnit(U,(n,1))]=Unit[T,powerUnit(U,(n,1))]T(l.float ^ n.float)
proc `^`*[T;U:static[string]](l:Unit[T,U],n:static[float]):
  Unit[T,powerUnit(U,floatToFraction(n))]=Unit[T,powerUnit(U,floatToFraction(n))]T(l.float ^ n)


when isMainModule:
  let high=3.0~m
  let speed=5.0~m/s
  const g=9.8~m/s^2
  let time=(high/g*2)^0.5
  let length=time*speed
  echo length
  let 电脑=5000.0~元
  let 生产力=7200.0~元/月
  let 时间=电脑/生产力
  let 日时间=时间.convertUnit {月:30.0~日}
  echo 日时间

