import macros
from tables import `[]`,initTable,toTable,contains,Table
from strutils import split,replace,join,parseInt,contains,toLowerAscii,parseFloat
from algorithm import sort,reverse
from math import `^`,floor

# Map美观输出
const superScriptMap* ={'0':"⁰",'1':"¹",'2':"²",'3':"³",'4':"⁴",'5':"⁵",'6':"⁶",'7':"⁷",'8':"⁸",'9':"⁹"}.toTable
func readUnit*(u:static string):static string{.compileTime.}=
  var
    flag=false
    d=0
  #忽略u[0]标记位
  for c in u[1..^1]:
    if c=='/':
      inc d
    else:
      # d==1 即如 a^1/2 表示 a^(1/2)
      if d==1:
        result.add"⸍"
      # d==2 即如 a//b 表示 a/b
      elif d==2:
        result.add'/'
      if c in '0'..'9':
        if flag: result.add superScriptMap[c]
        else:result.add c
      # flag 进入上标状态
      elif c=='^':flag=true
      elif c=='*':
        result.add"·"
        flag=false
      else:
        result.add c
        flag=false
      d=0



# simplified internal unit system
var siseq*{.compileTime.} = @[""]  ## 编译期基础单位表，""为单纯倍数单位
var siTable*{.compileTime.}=initTable[string,(float,string)]()  ## 编译期单位转化表


# (int,int)表为分数，其中统一以(0,1)表示0
func cmpTupUnit*(a,b:(string,(int,int))):int=a[0].cmp b[0] ## s^(a,b)按s排序


func mygcd*(a,b:int):int=
  ## 获取最大公因数
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
func simplifyFrac*(num:(int,int)):(int,int)=
  ## 分数化简
  if num[0]==0:
    return (0,1)
  let gcdVal=mygcd(num[0],num[1])
  return
    if num[1]>0:(num[0] div gcdVal,num[1] div gcdVal)
    elif num[1]<0:(-num[0] div gcdVal,-num[1] div gcdVal)
    else: raise newException(ValueError,"Invalid fraction")
func fracAdd*(a,b:(int,int)):(int,int) {.compileTime.}=simplifyFrac (a[0]*b[1]+b[0]*a[1],a[1]*b[1]) ## 分数相加
func fracMul*(a,b:(int,int)):(int,int) {.compileTime.}=simplifyFrac (a[0]*b[0],a[1]*b[1]) ## 分数相乘
func fracPow*[T](a:T,b:(int,int)):T{.inline.}=T(a.float^(b[0].float/b[1].float)) ## 分数指数计算
func floatToFraction*(x:float):(int,int) {.compileTime.}=
  ## 小数转分数
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



func findInsertIndex*(tups: seq[(string, (int, int))], target: string): int {.compileTime.} =
  ## 二分查找@[] s^(a/b)的s位置，不然找到该插入的位置
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
func addInUnit*(tups: var seq[(string, (int, int))], tup: (string, (int, int))) {.compileTime.} =
  ## @[] s^(a/b)加入指定单位 s^(a/b)
  if tup[1] == (0, 1): return
  let idx = tups.findInsertIndex tup[0]
  if idx < tups.len and tups[idx][0] == tup[0]:
    let newExp = tups[idx][1].fracAdd(tup[1])
    if newExp[0] == 0 or (newExp[0]/newExp[1]).abs<1e-9:
      tups.del(idx)
    else:
      tups[idx] = (tup[0], newExp)
  else:
    tups.insert(tup, idx)
  tups.sort cmpTupUnit
func delOutUnit*(tups: var seq[(string, (int, int))], target: string) {.compileTime.} =
  ## 对@[] s^(a/b)剔除指定单位
  let idx = tups.findInsertIndex target
  if idx < tups.len and tups[idx][0] == target:
    tups.del idx
  tups.sort cmpTupUnit





func formatUnitHelper*(u:static string):static string {.compileTime.}=
  ## 规范化标准内部字符串辅助
  ## 使更适合转化
  ## 如 kg*m^(1/2)/s^(2/3)
  ## 转化为 kg*m^1//2/s^2//3
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
func tupUnit*(s:static string):static seq[(string,(int,int))]{.compileTime.}=
  ## 将规范化字符串转为@[]s^(a/b)
  if s=="":return newSeq[(string,(int,int))]()
  let u=if s[0]=='*':s[1..^1]else:s
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
          if nlist[0].contains".":
            floatToFraction parseFloat nlist[0]
          else:
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
func tupToUnit*(tups:seq[(string,(int,int))]):string {.compileTime.}=
  ## 将@[]s^(a/b)转为"*"+规范字符串
  var
    st=newSeq[string]()
    stDiv=newSeq[string]()
  for (s,e)in tups:
    if s=="":continue
    if e[0]>0:st.add s&(if e[0]!=1 or e[1]!=1: "^" & $e[0] & (if e[1]!=1:"/" & $e[1]else:"") else: "")
    elif e[0]==0:continue
    else:stDiv.add s&(if e[0] != -1 or e[1]!=1: "^" & $(-e[0]) & (if e[1]!=1:"/" & $e[1]else:"") else: "")
  "*"&st.join("*")&(if stDiv.len>0:"//"&stDiv.join"*" else:"")

func mulUnitHelper*(a,b:static string):static seq[(string,(int,int))] {.compileTime.}=
  ## 单位相乘辅助函数
  ## 返回辅助的@[]s^(a/b)
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

func divUnitHelper*(a,b:static string):static seq[(string,(int,int))] {.compileTime.}=
  ## 单位除法辅助函数
  ## 返回辅助的@[]s^(a/b)
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

func powUnitHelper*(a:static string,n:static[(int,int)]):static seq[(string,(int,int))] {.compileTime.}=
  ## 单位分数幂辅助函数
  ## 返回辅助的@[]s^(a/b)
  let tupA=tupUnit(a)
  for (s,e) in tupA:
    result.add (s,(e[0],e[1]).fracMul n)


proc wisUnitHelp*(args:NimNode,format:static bool=true):NimNode=
  var
    u=args
    divFlag=false
    seq1=newSeq[NimNode]()
    seq2=newSeq[NimNode]()
  while u.kind==nnkInfix:
    if eqIdent(u[0],"/"):
      divFlag=true
      seq1.add u[2]
    elif eqIdent(u[0],"*"):
      if divFlag:seq2.add u[2]
      else:seq1.add u[2]
    elif eqIdent(u[0],"^"):break
    else:error "syntax error"
    u=u[1]
  if divFlag:
    seq2.add u
  else:
    seq1.add u
  var
    mulSeq=if divFlag:seq2 else:seq1
    divSeq=if divFlag:seq1 else:seq2
  reverse mulSeq
  reverse divSeq
  var
    mulTree=if mulSeq.len>0:
        if mulseq[0].kind==nnkInfix and mulseq[0][0].eqIdent "^":
          newCall("powUnit",(if format:newCall("formatUnit",mulseq[0][1]) else:mulseq[0][1]),mulseq[0][2])
        else:
          (if format:newCall("formatUnit",mulseq[0]) else:mulseq[0])
      else:newEmptyNode()
    divTree=if divFlag:
        if divseq[0].kind==nnkInfix and divseq[0][0].eqIdent "^":
          newCall("powUnit",(if format:newCall("formatUnit",divseq[0][1]) else:divseq[0][1]),divseq[0][2])
        else:
          (if format:newCall("formatUnit",divseq[0]) else:divseq[0])
      else:newEmptyNode()
  if mulSeq.len>1:
    for m in mulseq[1..^1]:
      mulTree=newCall("mulUnit",mulTree,
        if m.kind==nnkInfix and m[0].eqIdent "^":
          newCall("powUnit",(if format:newCall("formatUnit",m[1]) else:m[1]),m[2])
        else:
          (if format:newCall("formatUnit",m) else:m)
        )
  if divSeq.len>1:
    for d in divSeq[1..^1]:
      divTree=newCall("mulUnit",divTree,
        if d.kind==nnkInfix and d[0].eqIdent "^":
          newCall("powUnit",(if format:newCall("formatUnit",d[1]) else:d[1]),d[2])
        else:
          (if format:newCall("formatUnit",d) else:d)
        )
  result=mulTree
  if divFlag:
    result=newCall("divUnit",result,divTree)



func convertUnitHelp*(val:static string,orign:static string):static[(int,int)]{.compileTime.}=
  ## 返回指定字符串指数
  let tup=tupUnit(val)
  for (s,e) in tup:
    if s==orign:
      return e
  return (0,1)
func convertUnitHelper*(val:static string,orign:static string,to:static string):
  static seq[(string,(int,int))] {.compileTime.}=
  ## 返回单位转换后@[]s^(a/b)
  var tup=tupUnit(val)
  let toer=tupUnit(to)
  let e=convertUnitHelp(val,orign)
  delOutUnit(tup,orign)
  for t in toer:
    addInUnit(tup,(t[0],t[1].fracMul e))
  tup


proc isNumLit*(c:NimNode):bool=
  c.kind==nnkIntLit or c.kind==nnkInt8Lit or c.kind==nnkInt16Lit or 
  c.kind==nnkInt32Lit or c.kind==nnkInt64Lit or c.kind==nnkUIntLit or 
  c.kind==nnkUInt8Lit or c.kind==nnkUInt16Lit or c.kind==nnkUInt32Lit or 
  c.kind==nnkUInt64Lit or c.kind==nnkFloatLit or c.kind==nnkFloat32Lit or 
  c.kind==nnkFloat64Lit or c.kind==nnkFloat128Lit



template tupUnitTemp*(x):seq[(string, (int, int))]=
  ## 避开编译器错误检查的template
  ## 将内部字符串转为 @[] s^(a/b) 的分组
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
template tupToUnitTemp*(tups):string=
  ## 避开编译器错误检查的template
  ## 将 @[] s^(a/b) 转为内部字符串
  block:
    var
      st=newSeq[string]()
      stDiv=newSeq[string]()
    for (s,e)in tups:
      if e[0]>0:st.add s&(if e[0]!=1 or e[1]!=1: "^" & $e[0] & (if e[1]!=1:"/" & $e[1]else:"") else: "")
      elif e[0]==0:continue
      else:stDiv.add s&(if e[0] != -1 or e[1]!=1: "^" & $(-e[0]) & (if e[1]!=1:"/" & $e[1]else:"") else: "")
    st.join("*")&(if stDiv.len>0:"//"&stDiv.join"*" else:"")
template convertUnitHelpTemp*(x,a):(int, int)=
  ## 避开编译器错误检查的template
  ## 找到x指定单位a的指数
  block:
    let tup=tupUnitTemp(x)
    var ans=(0,1)
    for (s,e) in tup:
      if s==a:
        ans=e
    ans
template isSimpleSiUnittemp*(s):bool=
  ## 避开编译器错误检查的template
  ## 判断s的所有单位是否都是基本单位
  block:
    var ans=true
    let tup=tupUnitTemp s
    for (a,b) in tup:
      if not (a in siseq):
        ans=false
        break
    ans


proc toSimpleSiUnit*(s:static string,max_times:static int=100):static[(float,seq[(string,(int,int))])]{.compileTime.}=
  ## 将单位转为基本si单位
  var
    tup=tupUnit s
    num=1.0
    sss=s
    flag=true
    times=0
  while flag:
    inc times
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
    if times>=max_times:
      echo "iter too much"
      echo "maybe error?"
      echo tup
      break
  let temp1=tupToUnitTemp tup
  let jud=isSimpleSiUnittemp temp1
  if jud:(num,tup)
  else:error $temp1&" not si unit"

