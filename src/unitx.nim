from macros import quote,eqIdent,newIntLitNode,nnkDotExpr,
  newIdentNode,kind,nnkTableConstr,items,newFloatLitNode,
  expectKind,nnkExprColonExpr,`[]`,nnkInfix,expectIdent,
  newCall,ident,toStrLit,newTree,nnkCall,nnkStmtList,nnkIdent,
  nnkStaticStmt,newStmtList,`$`,error,add,nnkAsgn,treeRepr,
  nnkBracketExpr,nnkTupleConstr,newStrLitNode,nnkStrLit
from tables import `[]`,`[]=`,initTable,toTable,contains,Table
from strutils import split,replace,join,parseInt,contains
from algorithm import sort
from math import `^`,floor
from sets import incl,contains,toHashSet

const superScriptMap={'0':"⁰",'1':"¹",'2':"²",'3':"³",'4':"⁴",'5':"⁵",'6':"⁶",'7':"⁷",'8':"⁸",'9':"⁹"}.toTable
func readUnit(u:static[string]):static[string]{.compileTime.}=
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
var siSeq{.compileTime.} = toHashSet [""]
var siTable{.compileTime.}=initTable[string,(float,string)]()
var unitxSiHasAdded*{.compileTime.}=true



func cmpTupUnit(a,b:(string,(int,int))):int=a[0].cmp b[0]
template tupUnitTemp(x)=
  block:
    let u=x
    var ans=newseq[(string,(int,int))]()
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
            let x=(nlist[0].replace(" ","")).parseInt
            if x==0: continue
            if nlist.len==1:
              (x,1)
            else:
              let y=nlist[1].parseInt
              if y>0: simplifyFrac (x,y)
              elif y<0: simplifyFrac (-x,-y)
              else: raise newException(ValueError, "invalid exponent")
          else:(1,1)
      ans.add (base,exp)
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
        ans.add (base,exp)
    ans.sort cmpTupUnit
    ans
template convertUnitHelpTemp(x,a)=
  block:
    let tup=tupUnitTemp(x)
    var ans=(0,1)
    for (s,e) in tup:
      if s==a:
        ans=e
    ans
template tupToUnitTemp(tups)=
  block:
    var
      st=newSeq[string]()
      stDiv=newSeq[string]()
    for (s,e)in tups:
      if e[0]>0:st.add s&(if e[0]!=1 or e[1]!=1: "^" & $e[0] & (if e[1]!=1:"/" & $e[1]else:"") else: "")
      elif e[0]==0:continue
      else:stDiv.add s&(if e[0] != -1 or e[1]!=1: "^" & $(-e[0]) & (if e[1]!=1:"/" & $e[1]else:"") else: "")
    st.join("*")&(if stDiv.len>0:"//"&stDiv.join"*" else:"")
template isSimpleSiUnittemp(s)=
  block:
    var ans=true
    let tup=tupUnitTemp s
    for (a,b) in tup:
      if not (a in siSeq):
        ans=false
        break
    ans



func gcd(a,b: int): int {.compileTime.}=
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
func simplifyFrac(num:(int,int)):(int,int) {.compileTime.}=
  if num[0]==0:
    return (0,1)
  let gcdVal=gcd(num[0],num[1])
  return
    if num[1]>0:(num[0] div gcdVal,num[1] div gcdVal)
    elif num[1]<0:(-num[0] div gcdVal,-num[1] div gcdVal)
    else: raise newException(ValueError,"Invalid fraction")
func fracAdd(a, b: (int, int)): (int, int) {.compileTime.}=simplifyFrac (a[0]*b[1]+b[0]*a[1],a[1]*b[1])
func fracMul(a, b: (int, int)): (int, int) {.compileTime.}=simplifyFrac (a[0]*b[0],a[1]*b[1])
func fracPow[T](a:T, b: (int, int)):T{.inline.}= T(a.float^(b[0].float/b[1].float))
func floatToFraction(x: float): (int, int) {.compileTime.}=
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



func findInsertIndex(tups: seq[(string, (int, int))], target: string): int {.compileTime.} =
  var
    low = 0
    high = tups.len - 1
  while low <= high:
    let mid = (low + high) shr 1
    let cmpRes = cmp(tups[mid][0], target)
    if cmpRes == 0:
      return mid
    elif cmpRes < 0:
      low = mid + 1
    else:
      high = mid - 1
  return low
func addInUnit(tups: var seq[(string, (int, int))], tup: (string, (int, int))) {.compileTime.} =
  if tup[1] == (0, 1): return
  let idx = tups.findInsertIndex(tup[0])
  if idx < tups.len and tups[idx][0] == tup[0]:
    let newExp = tups[idx][1].fracAdd(tup[1])
    if newExp[0] == 0 or (newExp[0]/newExp[1]).abs<1e-9:
      tups.del(idx)
    else:
      tups[idx] = (tup[0], newExp)
  else:
    tups.insert(tup, idx)
  tups.sort cmpTupUnit
func delOutUnit(tups: var seq[(string, (int, int))], target: string) {.compileTime.} =
  let idx = tups.findInsertIndex(target)
  if idx < tups.len and tups[idx][0] == target:
    tups.del(idx)
  tups.sort cmpTupUnit




type Unit[T;U:static[string]]=distinct T #轻量单位类型,U为单位
func `$`*(arg:Unit):string{.inline.} =
  when arg.U=="":
    $arg.T(arg)
  else:
    $arg.T(arg)&" "&arg.U.readUnit
func unit*[T;U:static[string]](u:Unit[T,U]):static[string]{.inline.}=u.U.readUnit
converter withNoUnit*[T](x:Unit[T,""]):T=T(x)
func formatUnitHelper(u:static[string]):static[string] {.compileTime.}=
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
func tupUnit(u:static[string]):static[seq[(string,(int,int))]]{.compileTime.}=
  let
    list=u.split"//"
    left=if u.contains"//"and list.len==1:newSeq[string]() else:list[0].split'*'
    right=if list.len>1:list[1].split'*' elif u.contains"//":list[0].split'*' else:newSeq[string]()
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
  result.sort cmpTupUnit
func tupToUnit(tups:static[seq[(string,(int,int))]]):static[string] {.compileTime.}=
  var
    st=newSeq[string]()
    stDiv=newSeq[string]()
  for (s,e)in tups:
    if e[0]>0:st.add s&(if e[0]!=1 or e[1]!=1: "^" & $e[0] & (if e[1]!=1:"/" & $e[1]else:"") else: "")
    elif e[0]==0:continue
    else:stDiv.add s&(if e[0] != -1 or e[1]!=1: "^" & $(-e[0]) & (if e[1]!=1:"/" & $e[1]else:"") else: "")
  st.join("*")&(if stDiv.len>0:"//"&stDiv.join"*" else:"")
func formatUnit*(u:static[string]):static[string]{.compileTime.} =
  if u=="":return u
  let list=u.split"//"
  if list.len>1:u
  else:tupToUnit tupUnit formatUnitHelper u
func createTheAbsolutelyNewUnit*[T](val:T,u:static[string]):Unit[T,u]{.inline.}=Unit[T,u]val#由string创建单位
func mulUnitHelper(a,b:static[string]):static[seq[(string,(int,int))]] {.compileTime.}=
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
func mulUnit(a,b:static[string]):static[string] {.compileTime.}= tupToUnit mulUnitHelper(a,b)
func divUnitHelper(a,b:static[string]):static[seq[(string,(int,int))]] {.compileTime.}=
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
func divUnit(a,b:static[string]):static[string] {.compileTime.}= tupToUnit divUnitHelper(a,b)
func powerUnitHelper(a:static[string],n:static[(int,int)]):static[seq[(string,(int,int))]] {.compileTime.}=
  let tupA=tupUnit(a)
  for (s,e) in tupA:
    result.add (s,(e[0],e[1]).fracMul n)
func powerUnit(a:static[string],n:static[(int,int)]):static[string] {.compileTime.}= tupToUnit powerUnitHelper(a,n)
macro `~`*(val,str):Unit {.warning[IgnoredSymbolInjection]:off.}=
  if val is Unit:
    quote do:`val` * createTheAbsolutelyNewUnit(`val`.T(1),formatUnit astToStr `str`)
  elif str.kind==nnkStrLit:
    quote do:createTheAbsolutelyNewUnit(`val`,toStrLit(""))#字符串下仅支持空单位
  else:
    quote do:createTheAbsolutelyNewUnit(`val`,formatUnit astToStr `str`)
macro `~/`*(val,str):Unit {.warning[IgnoredSymbolInjection]:off.}=
  let x=powerUnitHelper(str.astToStr,(-1,1))
  if val is Unit:
    quote do:`val` * createTheAbsolutelyNewUnit(`val`.T(1).formatUnit,`x`)
  elif str.kind!=nnkStrLit:
    quote do:createTheAbsolutelyNewUnit(formatUnit `val`,`x`)
  else:error "syntax error"
func deUnit*[T;U:static[string]](u:Unit[T,U]):T{.inline.}=T(u)#获得单位数值
func convertUnitHelp(val:static[string],orign:static[string]):static[(int,int)]{.compileTime.}=
  let tup=tupUnit(val)
  for (s,e) in tup:
    if s==orign:
      return e
  return (0,1)
func convertUnitHelper(val:static[string],orign:static[string],to:static[string]):
  static[seq[(string,(int,int))]] {.compileTime.}=
  var tup=tupUnit(val)
  let toer=tupUnit(to)
  let e=convertUnitHelp(val,orign)
  delOutUnit(tup,orign)
  for t in toer:
    addInUnit(tup,(t[0],t[1].fracMul e))
  tup
func convertUnitInner*[T;U:static[string]](val:Unit[T,U],orign:static[string],to:static[string],factor:static[T]):
  Unit[T,tupToUnit convertUnitHelper(U,orign,to)]{.inline.}=
  Unit[T,tupToUnit convertUnitHelper(U,orign,to)] T(val)*factor.fracpow convertUnitHelp(U,orign)
macro convertUnit*(val,conv):untyped =
  result=val
  if conv.kind==nnkTableConstr:
    for con in conv:
      expectKind con, nnkExprColonExpr
      if con[1].kind==nnkInfix and con[1][0].eqIdent"~":
        var s=toStrLit(con[1][2])
        if con[1][2].kind==nnkStrLit and con[1][2]==newStrLitNode(""):
          s=ident""
        result = newCall(ident"convertUnitInner",result,toStrLit con[0],newTree(nnkCall,ident"formatUnit",s),con[1][1])
      else:
        var s=toStrLit(con[1])
        if con[1].kind==nnkStrLit and con[1]==newStrLitNode(""):
          s=ident""
        result = newCall(ident"convertUnitInner",result,toStrLit con[0],newTree(nnkCall,ident"formatUnit",s),newCall(newTree(nnkDotExpr,val,ident"T"),newIntLitNode(1)))


proc addSiUnitInner*(a:static[string],b:static[float],c:static[string]){.compileTime.}=siTable[a]=(b,c)
proc addSimpleSiUnit*(s:static[string])=siSeq.incl s
macro addSiUnit*(conv):untyped =
  unitxSiHasAdded=false
  result=newTree(nnkStaticStmt,newStmtList())
  if conv.kind==nnkTableConstr:
    for con in conv:
      if con.kind == nnkExprColonExpr:
        if con[1].kind==nnkInfix and eqIdent(con[1][0],"~"):
          if $con[0] in siSeq:
            error "can not change si"
          var s=if con[1][2].kind==nnkStrLit:con[1][2] else:toStrLit(con[1][2])
          result[0].add newCall(ident"addSiUnitInner",toStrLit(con[0]),newCall(ident"float",con[1][1]), newCall(ident"formatUnit",s))
        else:
          if $con[0] in siSeq:
            error "can not change si"
          var s=if con[1].kind==nnkStrLit:con[1] else:toStrLit(con[1])
          result[0].add newCall(ident"addSiUnitInner",toStrLit(con[0]),newFloatLitNode(1.0), newCall(ident"formatUnit",s))
      elif con.kind==nnkIdent:
        if $con in siSeq:
          error "Duplicate si unit"
        result[0].add newCall(ident"addSimpleSiUnit",toStrLit con)
      else:
        error "syntax error"
  else:
    error "syntax error"
proc toSimpleSiUnit(s:static[string]):static[(float,seq[(string,(int,int))])]{.compileTime.}=
  var
    tup=tupUnit s
    num=1.0
    sss=s
    flag=true
  while flag:
    flag=false
    for (a,b) in tup:
      if a in siTable:
        flag=true
        let x=convertUnitHelpTemp(sss,a)
        num*=siTable[a][0]^(x[0]/x[1])
        tup=block:
          let
            val=sss
            orign=a
            to=siTable[a][1]
          var tup=tupUnitTemp(val)
          let toer=tupUnitTemp(to)
          let e=convertUnitHelpTemp(val,orign)
          delOutUnit(tup,orign)
          for t in toer:
            addInUnit(tup,(t[0],t[1].fracMul e))
          tup
        sss=tupToUnitTemp tup
        break
  let temp1=tupToUnitTemp tup
  let jud=isSimpleSiUnittemp temp1
  if jud:(num,tup)
  else:error "not si unit"
proc convertSimpleSiUnitHelp(s:static[string]):static[string]{.compileTime.}=tupToUnit toSimpleSiUnit(s)[1]
func convertSimpleSiUnit*[T;U:static[string]](s:Unit[T,U]):Unit[T,convertSimpleSiUnitHelp(U)]{.inline.}=
  const t=U.toSimpleSiUnit
  Unit[T,tupToUnit t[1]](s.float*t[0])
func doUnitInner*[T,TT;U:static[string]](x:Unit[T,U],f:proc(a:T):TT):Unit[TT,U]=createTheAbsolutelyNewUnit(f(x.deUnit),x.U)
func siTo*[T;U:static[string]](x:Unit[T,U],s:static[string]):Unit[T,s]=
  const
    lsi=toSimpleSiUnit(U)
    rsi=toSimpleSiUnit(s)
    lsistr=tuptoUnit(lsi[1])
    rsistr=tuptoUnit(rsi[1])
  when lsistr!=rsistr:error "not same si unit"
  Unit[T,s](lsi[0]*x.float/rsi[0])


func `+`*[T;U1,U2:static[string]](l:Unit[T,U1],r:Unit[T,U2]):Unit[T,U1]{.inline.} =
  when U1==U2:
    Unit[T,U1](T(l)+T(r))
  else:
    const
      lsi=toSimpleSiUnit(U1)
      rsi=toSimpleSiUnit(U2)
      lsistr=tuptoUnit(lsi[1])
      rsistr=tuptoUnit(rsi[1])
    when lsistr!=rsistr:error "not same si unit"
    Unit[T,U1]((lsi[0]*l.float+rsi[0]*r.float)/lsi[0])
func `-`*[T;U1,U2:static[string]](l:Unit[T,U1],r:Unit[T,U2]):Unit[T,U1]{.inline.} =
  when U1==U2:
    Unit[T,U1](T(l)-T(r))
  else:
    const
      lsi=toSimpleSiUnit(U1)
      rsi=toSimpleSiUnit(U2)
      lsistr=tuptoUnit(lsi[1])
      rsistr=tuptoUnit(rsi[1])
    when lsistr!=rsistr:error "not same si unit"
    Unit[T,U1]((lsi[0]*l.float-rsi[0]*r.float)/lsi[0])
func `*`*[T;U1,U2:static[string]](l:Unit[T,U1],r:Unit[T,U2]):
  Unit[T,mulUnit(U1,U2)]{.inline.}=Unit[T,mulUnit(U1,U2)](T(l)*T(r))
func `/`*[T;U1,U2:static[string]](l:Unit[T,U1],r:Unit[T,U2]):
  Unit[T,divUnit(U1,U2)]{.inline.}=Unit[T,divUnit(U1,U2)](T(l)/T(r))
func `*`*[T;U:static[string]](l:Unit[T,U],r:T):Unit[T,U]{.inline.}=Unit[T,U](T(l)*r)
func `/`*[T;U:static[string]](l:Unit[T,U],r:T):Unit[T,U]{.inline.}=Unit[T,U](T(l)/r)
func `*`*[T;U:static[string]](r:T,l:Unit[T,U]):Unit[T,U]{.inline.}=Unit[T,U](T(l)*r)
func `/`*[T;U:static[string]](r:T,l:Unit[T,U]):
  Unit[T,powerUnit(U,(-1,1))]{.inline.}=Unit[T,powerUnit(U,(-1,1))](r/T(l))
func `^`*[T;U:static[string]](l:Unit[T,U],n:static[(int,int)]):
  Unit[T,powerUnit(U,n)]{.inline.}=Unit[T,powerUnit(U,n)]T(float(l) ^ (n[0].float/n[1].float))
func `^`*[T;U:static[string]](l:Unit[T,U],n:static[int]):
  Unit[T,powerUnit(U,(n,1))]{.inline.}=Unit[T,powerUnit(U,(n,1))]T(l.float ^ n.float)
func `^`*[T;U:static[string]](l:Unit[T,U],n:static[float]):
  Unit[T,powerUnit(U,floatToFraction(n))]{.inline.}=Unit[T,powerUnit(U,floatToFraction(n))]T(l.float ^ n)
