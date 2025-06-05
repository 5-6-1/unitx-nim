import macros
import strutils
import algorithm
import math
import sequtils
import tables
import unicode

const superScriptMap={'0':"⁰",'1':"¹",'2':"²",'3':"³",'4':"⁴",'5':"⁵",'6':"⁶",'7':"⁷",'8':"⁸",'9':"⁹"}.toTable
proc readUnit(u:string):string=
  var flag=false
  for c in u:
    if c in '0'..'9':
      if flag:result.add superScriptMap[c]
      else:result.add c
    elif c=='^':flag=true
    elif c=='*':
      result.add"·"
      flag=false
    else:
      result.add c
      flag=false

proc fastPow[T](base: T, exponent: int): T =
  if exponent == 0:return T(1)
  if base == T(0):
    if exponent < 0: raise newException(DivByZeroError, "Division by zero: base is zero with negative exponent")
    else: return T(0)
  let exp = if exponent < 0: -exponent else: exponent
  var
    baseVal = base
    e = exp
  result = T(1)
  while e > 0:
    if (e and 1) != 0:
      result = result * baseVal
    baseVal = baseVal * baseVal
    e = e shr 1
  if exponent < 0:
    result = T(T(1) / result)
proc addInUnit(tups:var seq[(string,int)],tup:(string,int)) =
  if tup[1]==0:return
  var tr=false
  var result=newSeq[(string,int)]()
  for (s,e) in tups:
    let x = cmp(s,tup[0])
    if x==0:
      tr=true
      if e+tup[1]!=0:
        result.add (s,e+tup[1])
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
proc delOutUnit(tups:var seq[(string,int)],ss:string) =
  var result=newSeq[(string,int)]()
  for (s,e) in tups:
    let x = cmp(s,ss)
    if x<0:
      result.add (s,e)
    elif x>0:
      result.add (s,e)
  tups=result
type Unit*[T;U:static[string]]=distinct T #轻量单位类型,U为单位
proc createUnit*[T](val:T,u:static[string]):Unit[T,u]=Unit[T,u]val#由string创建单位
proc `$`*(arg:Unit):string = $arg.T(arg)&" "&arg.U.readUnit
proc formatUnit(u:static[string]):static[string] =
  let
    list=u.replace(" ","").replace("^1","").split"/"
  var
    left=list[0].split"*"
    right=if list.len>1:list[1].split"*" else: newSeq[string]()
  proc cmpUnit(a,b:string):int=
    let
      na=a.split"^"[0]
      nb=b.split"^"[0]
    cmp(na,nb)
  left.sort cmpUnit
  right.sort cmpUnit
  left.join"*"&(if right.len==0:"" else:"/"&right.join"*")
template `~`*(val,str):Unit = Unit[typeof val,formatUnit astToStr str] val#提供直接创建方法
proc tupUnit(u:static[string]):static[seq[(string,int)]]=
  let
    list=u.replace(" ","").split"/"
  let
    left=list[0].split"*"
    right=if list.len>1:list[1].split"*" else: newSeq[string]()
  for arg in left:
    let targ=arg.split"^"
    result.add((targ[0],if targ.len>1:parseInt(targ[1]) else:1))
  for arg in right:
    let targ=arg.split"^"
    result.add((targ[0],if targ.len>1: -parseInt(targ[1]) else: -1))
  proc comTupUnit(a,b:(string,int)):int=cmp(a,b)
  result.sort comTupUnit
proc tupToUnit(tups:static[seq[(string,int)]]):static[string] =
  var
    st=newSeq[string]()
    stDiv=newSeq[string]()
  for (s,e)in tups:
    if e>0:st.add s&(if e>1: "^" & $e else: "")
    elif e==0:continue
    else:stDiv.add s&(if e < -1: "^" & $(-e) else: "")
  st.join("*")&(if stDiv.len>0:"/"&stDiv.join("*") else:"")
proc mulUnitHelper(a,b:static[string]):static[seq[(string,int)]] =
  let
    tupA=tupUnit(a)
    tupB=tupUnit(b)
  var
    cuA=0
    cuB=0
  while cuA<tupA.len and cuB<tupB.len:
    let x= cmp(tupA[cuA][0],tupB[cuB][0])
    if x==0:
      if tupA[cuA][1]+tupB[cuB][1]!=0:
        result.add (tupA[cuA][0],tupA[cuA][1]+tupB[cuB][1])
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
proc divUnitHelper(a,b:static[string]):static[seq[(string,int)]] =
  let
    tupA=tupUnit(a)
    otupB=tupUnit(b)
  var
    tupB=newSeq[(string,int)]()
    cuA=0
    cuB=0
  for (s,e)in otupB:
    tupB.add (s, -e)
  while cuA<tupA.len and cuB<tupB.len:
    let x= cmp(tupA[cuA][0],tupB[cuB][0])
    if x==0:
      if tupA[cuA][1]+tupB[cuB][1]!=0:
        result.add (tupA[cuA][0],tupA[cuA][1]+tupB[cuB][1])
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
proc powerUnitHelper(a:static[string],n:static[int]):static[seq[(string,int)]] =
  let tupA=tupUnit(a)
  for (s,e) in tupA:
    result.add (s,e*n)
proc powerUnit(a:static[string],n:static[int]):static[string] = tupToUnit powerUnitHelper(a,n)
proc deUnit*[T;U:static[string]](u:Unit[T,U]):T=T(u)#获得单位数值
proc convertUnitHelp(val:static[string],orign:static[string]):static[int]=
  let tup=tupUnit(val)
  for (s,e) in tup:
    if s==orign:
      return e
  return 0
proc convertUnitHelper(val:static[string],orign:static[string],to:static[string]):
  static[seq[(string,int)]] =
  var tup=tupUnit(val)
  let toer=tupUnit(to)
  let e=convertUnitHelp(val,orign)
  delOutUnit(tup,orign)
  for t in toer:
    addInUnit(tup,(t[0],t[1]*e))
  tup
proc convertUnitInner*[T;U:static[string]](val:Unit[T,U],orign:static[string],to:static[string],factor:static[T]):
  Unit[T,tupToUnit convertUnitHelper(U,orign,to)]=
  Unit[T,tupToUnit convertUnitHelper(U,orign,to)] T(val)*factor.fastpow convertUnitHelp(U,orign)
macro convertUnit*(val,conv):untyped =
  result=val
  if conv.kind==nnkTableConstr:
    for con in conv:
      expectKind con, nnkExprColonExpr
      expectKind con[1],nnkInfix
      expectIdent con[1][0],"~"
      result = newCall(ident"convertUnitInner",result,toStrLit con[0],toStrLit con[1][2],con[1][1])#单位安全转换


proc `+`*[T;U:static[string]](l,r:Unit[T,U]):Unit[T,U] = Unit[T,U](T(l)+T(r))
proc `-`*[T;U:static[string]](l,r:Unit[T,U]):Unit[T,U] = Unit[T,U](T(l)-T(r))
proc `*`*[T;U1,U2:static[string]](l:Unit[T,U1],r:Unit[T,U2]):Unit[T,mulUnit(U1,U2)]=Unit[T,mulUnit(U1,U2)](T(l)*T(r))
proc `/`*[T;U1,U2:static[string]](l:Unit[T,U1],r:Unit[T,U2]):Unit[T,divUnit(U1,U2)]=Unit[T,divUnit(U1,U2)](T(l)/T(r))
proc `*`*[T;U:static[string]](l:Unit[T,U],r:T):Unit[T,U]=Unit[T,U](T(l)*r)
proc `/`*[T;U:static[string]](l:Unit[T,U],r:T):Unit[T,U]=Unit[T,U](T(l)/r)
proc `^`*[T;U:static[string]](l:Unit[T,U],n:static[int]):Unit[T,powerUnit(U,n)]=Unit[T,powerUnit(U,n)](T(l)^n)

