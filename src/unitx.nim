import unitx/core
import macros
from algorithm import reverse
from strutils import contains,parseInt,parseFloat,replace,split,join,toLowerAscii
from math import `^`,floor,sqrt,cbrt,pow,`mod`,ceil,hypot,round,
  trunc,gcd,lcm,floorDiv,floorMod,euclDiv,euclMod,ceilDiv
from tables import pairs,`[]=`,contains,`[]`

## 将公开部分放在最外层文件中，而不使用export
## 可以便于lsp分析

#[--core--]#
type
  UStr* = static string      ## 单位指定编译期字符串
  Unit*[T;U:UStr]=distinct T ## 轻量单位类型,U为单位;
  ## U以*开头，/为单位除法，//为指数分数除法 ;
  ## 如 *kg*m^1//2/s^2//3
converter withNoUnit*[T](x:Unit[T,"*"]):T=T(x) ## 空单位相当于非Unit

func `$`*(arg:Unit):string{.inline.}=
  ## $数值 + 可读unit
  when arg.U=="":
    $arg.T(arg)
  else:
    $arg.T(arg)&" "&arg.U.readUnit

template unit*[T;U:UStr](u:Unit[T,U]):static string=
  ## 生成标准内部字符串
  runnableExamples:
    let x=1{kg*m^(1/2)/s^2}
    echo x.unit
    ## kg*m^1/2//s^2
  unitInner(U)
template unitT*[T;U:UStr](t:type(Unit[T,U])):type=T
template unitU*[T;U:UStr](t:type(Unit[T,U])):static string=U
template unitT*[T;U:UStr](t:Unit[T,U]):type=T
template unitU*[T;U:UStr](t:Unit[T,U]):static string=U
func unitInner*(s:string):string{.compileTime.}=
  ## 将规范字符串转为标准字符串
  ## 如 kg*m^1/2/s^2/3
  ## 转为 kg*m^(1/2)/s^(2/3)
  let
    u=s[1..^1]
    list=u.split"//"
    left=if u.contains"//"and list.len==1:newSeq[string]() else:list[0].split'*'
    right=if list.len>1:list[1].split'*' elif u.contains"//":list[0].split'*' else:newSeq[string]()
  var
    ltup=newSeq[string]()
    rtup=newSeq[string]()
  for l in left:
    let
      llist=l.split"^"
      base=llist[0]
    if llist.len>1:
      let nlist=llist[1].split"/"
      let x=nlist[0].parseInt
      if x==0: continue
      if nlist.len==1:
        ltup.add base&"^" & $x
      else:
        let y=nlist[1].parseInt
        let (a,b)=
          if y>0: simplifyFrac (x,y)
          elif y<0: simplifyFrac (-x,-y)
          else: raise newException(ValueError, "invalid exponent")
        ltup.add base&"^(" & $a & "/" & $b&")"
    else:ltup.add base
  for r in right:
    let
      rlist=r.split"^"
      base=rlist[0]
    if rlist.len>1:
      let nlist=rlist[1].split"/"
      let x=nlist[0].parseInt
      if x==0: continue
      if nlist.len==1:
        rtup.add base&"^" & $x
      else:
        let y=nlist[1].parseInt
        let (a,b)=
          if y>0: simplifyFrac (x,y)
          elif y<0: simplifyFrac (-x,-y)
          else: raise newException(ValueError, "invalid exponent")
        rtup.add base&"^(" & $a & "/" & $b&")"
    else:rtup.add base
  ltup.join"*"&(if list.len==1:""else:"/"&rtup.join"*")
func formatUnit*(u:static string):static string{.compileTime.} =
  ## 获取规范字符串
  ## 如 kg*m^(1/2)/s^(2/3)
  ## 转化为 *kg*m^1//2/s^2//3
  if u=="":"*"
  elif u[0]=='*':u
  else:tupToUnit tupUnit formatUnitHelper u

func newUnit*[T](val:T,u:static string):Unit[T,formatUnit u]{.inline.}=
  ## 生成unit
  ## 推荐使用{}辅助函数
  runnableExamples:
    let speed=1{m/s}
    let speed2=(2*speed.deUnit).newUnit speed.unit
  Unit[T,formatUnit u]val

func mulUnit*(a,b:static string):static string {.compileTime.}= tupToUnit mulUnitHelper(a,b) ## 单位相乘
func divUnit*(a,b:static string):static string {.compileTime.}= tupToUnit divUnitHelper(a,b) ## 单位除法
func powUnit*(a:static string,n:static[(int,int)]):static string {.compileTime.}= tupToUnit powUnitHelper(a,n) ##单位分数幂
func powUnit*(a:static string,n:static int):static string {.compileTime.}= tupToUnit powUnitHelper(a,(n,1)) ##单位分数幂
func powUnit*(a:static string,n:static float):static string {.compileTime.}= tupToUnit powUnitHelper(a,floatToFraction(n)) ##单位分数幂

macro wisUnit*(args):untyped=
  ## 智慧获取unit组合
  runnableExamples:
    let
      a=1{m}
      b=1{s}
    let c=1.newUnit wisUnit(a.unit/b.unit) ##获取m/s单位
  wisUnitHelp(args)
macro wisUnitNF*(args):untyped=
  ## 智慧获取unit组合但不用formatUnit
  runnableExamples:
    ## 对于已经format的UStr组合采用not format的wisUnitNF
    proc mul[T;U1,U2:UStr](a:Unit[T,U1],b:Unit[T,U2]):
      Unit[T,wisUnitNF(U1*U2)]=a*b
  wisUnitHelp(args,false)
template wisNewUnit*(x,args):Unit=
  ## wisNewUnit(x,args)等价于newUnit(x,wisUnit(args))
  x.newUnit wisUnit(args)

macro `{}`*(val,str):Unit=
  ## 单位辅助生成宏
  ## 1{m} 即 newUnit(1,"m")
  ## 允许字符串 1{"m"}与1{m}一致
  ## 推荐不带字符串写法,即1{m}
  runnableExamples:
    let a=1{m}
    let b=1{"m"}
    ## 二者完全一致
  if str.kind!=nnkStrLit:
    newCall("newUnit",val,newCall("astToStr",str))
  else:
    newCall("newUnit",val,str)
func deUnit*[T;U:UStr](u:Unit[T,U]):T{.inline.}=T(u) ##去单位化

proc flatUnitHelp(T:typedesc):static string{.compileTime.}=
  ## 得到复合Unit的U部分的复合
  when T is Unit:
    T.U.mulUnit flatUnitHelp T.T
  else:
    "*"
template flatUnitHelpIn(T:type):type=
  ## 得到复合Unit的内部数值类型
  when T is Unit:
    flatUnitHelpIn(unitT(T))
  else:
    T
proc flatUnitHelper[T;U:UStr](u:Unit[T,U]):flatUnitHelpIn(T)=
  ## 得到复合unit的内部数值
  when T is Unit:
    flatUnitHelper(u.deUnit)
  else:
    u.deUnit
proc flatUnit*[T;U:UStr](u:Unit[T,U]):Unit[flatUnitHelpIn T,flatUnitHelp typeof u]{.inline.}=
  ## 将复合Unit展平
  ## 如1{m}{s} => 1{m*s}
  Unit[flatUnitHelpIn T,flatUnitHelp typeof u]flatUnitHelper u

func convertUnitInner*[T;U:UStr](val:Unit[T,U],orign:static string,to:static string,factor:static T):
  Unit[T,tupToUnit convertUnitHelper(U,orign,to)]{.inline.}=
  ## 将unit中的orign变为to字符串，并以factor因子乘指定倍率
  Unit[T,tupToUnit convertUnitHelper(U,orign,to)] T(val)*factor.fracpow convertUnitHelp(U,orign)
macro convertUnit*(val,conv):untyped =
  ## unit单位指定转换辅助宏
  ## 更推荐使用si系统
  runnableExamples:
    let x=1.0{km/h}
    echo x.convertUnit { ## 只支持{}表示
      km:1000.0{m},
      h:60.0{min},
      min:50.0{s},
      s: /hz
    }
  result=val
  if conv.kind==nnkTableConstr:
    for con in conv:
      expectKind con, nnkExprColonExpr
      if con[1].kind==nnkCurlyExpr:
        var s=toStrLit(con[1][1])
        if con[1][1].kind==nnkStrLit and con[1][1]==newStrLitNode(""):
          s=ident""
        result = newCall(ident"convertUnitInner",result,toStrLit con[0],newTree(nnkCall,ident"formatUnit",s),con[1][0])
      else:
        var s=toStrLit(con[1])
        if con[1].kind==nnkStrLit and con[1]==newStrLitNode(""):
          s=ident""
        result = newCall(ident"convertUnitInner",result,toStrLit con[0],newTree(nnkCall,ident"formatUnit",s),newCall(newTree(nnkDotExpr,val,ident"T"),newIntLitNode(1)))

proc addSiUnitInner*(a:static string,b:static[float],c:static string){.compileTime.}=siTable[a]=(b,c.formatUnit) ##si转换表导入
proc addSimpleSiUnit*(s:static string)=siseq.add s ## si基本表增加元素
macro addSiUnit*(conv):untyped =
  ## si系统增加元素宏
  runnableExamples:
    addSiUnit meter    #基本单位
    addSiUnit [ampere,mole]    #基本单位推荐写法
    addSiUnit:
      second             #基本单位
      kilogram
      m:meter
      s:second
      kg:kilogram        #相同单位
      N:kg*m/s^2
      minute:60{s}
      hour:60{minute}    #单位与转换因子
      cm:0.01{m}
      kilo:1000
    addSiUnit {
      # Economics
      USD,          #Directly increase the basic SI unit
      EUR: 0.93{USD},           # Currency
      BTC: 25000{USD}, ETH: 1800{USD},     # Crypto
    }
  result=newTree(nnkStaticStmt,newStmtList())
  if conv.kind==nnkTableConstr:
    for con in conv:
      if con.kind == nnkExprColonExpr:
        if con[1].kind==nnkCurlyExpr:
          if $con[0] in siseq:
            error "can not change si"
          var s=if con[1][1].kind==nnkStrLit:con[1][1] else:toStrLit(con[1][1])
          result[0].add newCall(ident"addSiUnitInner",toStrLit(con[0]),newCall(ident"float",con[1][0]),s)
        elif isNumLit(con[1]):
          result[0].add newCall(ident"addSiUnitInner",toStrLit(con[0]),newCall(ident"float",con[1]),newStrLitNode(""))
        else:
          if $con[0] in siseq:
            error "can not change si"
          var s=if con[1].kind==nnkStrLit:con[1] else:toStrLit(con[1])
          result[0].add newCall(ident"addSiUnitInner",toStrLit(con[0]),newFloatLitNode(1.0),s)
      elif con.kind==nnkIdent:
        if $con in siseq:
          error "Duplicate si unit"
        result[0].add newCall(ident"addSimpleSiUnit",toStrLit con)
      else:
        error "syntax error"
  elif conv.kind==nnkStmtList:
    for con in conv:
      if con.kind == nnkCall and con[1].kind==nnkStmtList:
        if con[1][0].kind==nnkCurlyExpr:
          if $con[0] in siseq:
            error "can not change si"
          var s=if con[1][0][1].kind==nnkStrLit:con[1][0][1] else:toStrLit(con[1][0][1])
          result[0].add newCall(ident"addSiUnitInner",toStrLit(con[0]),newCall(ident"float",con[1][0][0]),s)
        elif isNumLit(con[1][0]):
          result[0].add newCall(ident"addSiUnitInner",toStrLit(con[0]),newCall(ident"float",con[1][0]),newStrLitNode(""))
        else:
          if $con[0] in siseq:
            error "can not change si"
          var s=if con[1][0].kind==nnkStrLit:con[1][0] else:toStrLit(con[1][0])
          result[0].add newCall(ident"addSiUnitInner",toStrLit(con[0]),newFloatLitNode(1.0),s)
      elif con.kind==nnkIdent:
        if $con in siseq:
          error "Duplicate si unit"
        result[0].add newCall(ident"addSimpleSiUnit",toStrLit con)
      else:
        error "syntax error"
  elif conv.kind==nnkBracket:
    for con in conv:
      expectKind(con,nnkIdent)
      result[0].add newCall(ident"addSimpleSiUnit",toStrLit con)
  elif conv.kind==nnkIdent:
    if $conv in siseq:
      error "Duplicate si unit"
    result[0].add newCall(ident"addSimpleSiUnit",toStrLit conv)
  else:
    error "syntax error"
macro addSiUnit*(con,to):untyped=
  ## si系统增加元素宏
  runnableExamples:
    addSiUnit m:meter
    addSiUnit g:0.0001{kg}
  result=newTree(nnkStaticStmt,newStmtList())
  if con.kind==nnkIdent and to.kind==nnkStmtList:
    if to.kind==nnkCurlyExpr:
      if $con in siseq:
        error "can not change si"
      var s=if to[0][1].kind==nnkStrLit:to[0][1] else:toStrLit(to[0][1])
      result[0].add newCall(ident"addSiUnitInner",toStrLit(con),newCall(ident"float",to[0][0]),s)
    else:
      if $con in siseq:
        error "can not change si"
      var s=if to[0].kind==nnkStrLit:to[0] else:toStrLit(to[0])
      result[0].add newCall(ident"addSiUnitInner",toStrLit(con),newFloatLitNode(1.0),s)
  else:
    error "syntax error"

proc strSimpleSiUnit*(s:static string):static string{.compileTime.}=tupToUnit (toSimpleSiUnit s)[1] ## 单位转为基本si单位str
func convertSimpleSiUnit*[T;U:UStr](s:Unit[T,U]):Unit[T,strSimpleSiUnit U]{.inline.}=
  ## 将unit转为基本si单位unit
  const t=U.toSimpleSiUnit
  Unit[T,tupToUnit t[1]](s.float*t[0])
proc isSameSiUnit*(a,b:static string):static bool{.compileTime.}=
  ## 判断两单位是否相同
  const
    x=a.formatUnit
    y=b.formatUnit
  if x!=y: return x.strSimpleSiUnit==y.strSimpleSiUnit
  true
proc getConvertSiValue*(a,b:static string):static float{.compileTime.}=1.0.newUnit(a).siTo(b).deUnit ##获取单位之间转换倍率

proc curSimpleSi*():seq[string]{.compileTime.}=siseq ## 获取当前基本si表
proc curSi*():seq[string]{.compileTime.}=
  ## 查看当前si表str形式
  result=siseq
  for (k,v) in siTable.pairs:
    result.add (k&":"&(if v[0]==1.0:v[1].unitInner else: $v[0]&"~"&unitInner(v[1])))
proc curSiUnit*():seq[(string,(float,string))]{.compileTime.}=
  ## 查看当前si表@[]s^(a/b)形式
  for t in siseq:
    result.add (t,(NaN,""))
  for (k,v) in siTable.pairs:
    result.add (k,(v[0],v[1].unitInner))
proc checkCurSi*(max_times:static int=100):bool{.compileTime.}=
  result=true
  for (k,v) in siTable.pairs:
    let t=v[1]
    var
      tup=tupUnitTemp t
      sss=t
      flag=true
      times=0
    while flag:
      flag=false
      for (a,b) in tup:
        inc times;
        if a in siTable:
          flag=true
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
    if not jud:
      echo k," can not tran to si ",v[1]
      result=false


func value*[T,U](x:var Unit[T,U]):var T{.inline.}=cast[ptr T](x.addr)[] ## 绕过单位获取可修改值
proc doUnitInner*[T,TT;U:UStr](x:Unit[T,U],f:proc(a:T):TT):Unit[TT,U]=newUnit(f(x.deUnit),x.U) ## 绕过单位操纵内部值
proc doUnitInner*[T;U:UStr](x:Unit[T,U],f:proc(a:T))=f(x.deUnit) ## 绕过单位操纵内部值
proc doUnitInner*[T,TT;U:UStr](x:var Unit[T,U],f:proc(a:var T):TT):Unit[TT,U]=newUnit(f(x.value),x.U) ## 绕过单位操纵内部值
proc doUnitInner*[T;U:UStr](x:var Unit[T,U],f:proc(a:var T))=f(x.value) ## 绕过单位操纵内部值

func siTo*[T;U:UStr](x:Unit[T,U],s:static string):Unit[T,formatUnit s]=
  ## 将当前单位根据si系统转化为指定单位
  runnableExamples:
    let x=1.0{kilogram/second}
    echo x.siTo "gram/hour"
    ##3600000.0000000005 gram/hour
  const
    lsi=toSimpleSiUnit(U)
    rsi=toSimpleSiUnit(formatUnit s)
    lsistr=tupToUnit(lsi[1])
    rsistr=tupToUnit(rsi[1])
  when lsistr!=rsistr:error "not same si unit"
  Unit[T,formatUnit s](lsi[0]*x.float/rsi[0])
macro wisSiTo*[T;U:UStr](x:Unit[T,U],args):Unit=
  ## siTo智慧型辅助宏
  runnableExamples:
    let g=9.8{m/s^2}
    let h=5.0{cm}
    let v1=sqrt(2.0*g.wisSiTo(h.unit/"s"^2)*h)

    func get_v[T](h:USi[T,"m"]):USi[T,"m/s"]=
      let g=9.8{m/s^2}
      sqrt(2.0*g.wisSiTo(h.unit/"s"^2)*h)
    let v2=get_v 5.0{cm}
  newCall("siTo",x,wisUnitHelp(args))

type USi*[T;U:UStr]=concept u
  ## Unit可有si转化为USi的U即符合
  runnableExamples:
    const g = 9.80665~meter/second^2      ## Standard gravity
    let height = 100.0~meter
    proc getTime[T](h:USi[T,"meter"],g:USi[T,"N/gram"]):USi[T,"s"]=sqrt T(2)*h/g
    echo getTime(height,g)                #4.5160075575178755 second
  u is Unit
  u.T is T
  const ut=U.formatUnit
  when ut!=u.U:
    const usiU = strSimpleSiUnit ut
    const siU = strSimpleSiUnit u.U
    usiU==siU


#[--umath--]#
func `+`*[T;U:UStr](l:Unit[T,U],r:USi[T,U]):Unit[T,U]{.inline.} =Unit[T,U](T(l)+T(r.siTo(U)))
func `-`*[T;U:UStr](l:Unit[T,U],r:USi[T,U]):Unit[T,U]{.inline.} =Unit[T,U](T(l)-T(r.siTo(U)))
func `-`*[T;U:UStr](x:Unit[T,U]):Unit[T,U]{.inline.} =Unit[T,U](-T(x))
func `*`*[T;U1,U2:UStr](l:Unit[T,U1],r:Unit[T,U2]):Unit[T,mulUnit(U1,U2)]{.inline.}=Unit[T,mulUnit(U1,U2)](T(l)*T(r))
func `/`*[T;U1,U2:UStr](l:Unit[T,U1],r:Unit[T,U2]):Unit[T,divUnit(U1,U2)]{.inline.}=Unit[T,divUnit(U1,U2)](T(l)/T(r))
func `div`*[T;U1,U2:UStr](l:Unit[T,U1],r:Unit[T,U2]):Unit[T,divUnit(U1,U2)]{.inline.}=Unit[T,divUnit(U1,U2)](T(l) div T(r))
func `*`*[T;U:UStr](l:Unit[T,U],r:T):Unit[T,U]{.inline.}=Unit[T,U](T(l)*r)
func `/`*[T;U:UStr](l:Unit[T,U],r:T):Unit[T,U]{.inline.}=Unit[T,U](T(l)/r)
func `div`*[T;U:UStr](l:Unit[T,U],r:T):Unit[T,U]{.inline.}=Unit[T,U](T(l) div r)
func `*`*[T;U:UStr](r:T,l:Unit[T,U]):Unit[T,U]{.inline.}=Unit[T,U](T(l)*r)
func `div`*[T;U:UStr](r:T,l:Unit[T,U]):Unit[T,powUnit(U,(-1,1))]{.inline.}=Unit[T,powUnit(U,(-1,1))](r div T(l))
func `^`*[T;U:UStr](l:Unit[T,U],n:static[(int,int)]):Unit[T,powUnit(U,n)]{.inline.}=Unit[T,powUnit(U,n)]T(T(l) ^ (n[0]/n[1]))
func `^`*[T;U:UStr](l:Unit[T,U],n:static int):Unit[T,powUnit(U,(n,1))]{.inline.}=Unit[T,powUnit(U,(n,1))]T(T(l) ^ n.float)
func `^`*[T;U:UStr](l:Unit[T,U],n:static float):Unit[T,powUnit(U,floatToFraction(n))]{.inline.}=Unit[T,powUnit(U,floatToFraction(n))]T(T(l) ^ n)
func sqrt*[T;U:UStr](x:Unit[T,U]):Unit[T,powUnit(U,(1,2))]{.inline.}=Unit[T,powUnit(U,(1,2))]T(sqrt T(x))
func cbrt*[T;U:UStr](x:Unit[T,U]):Unit[T,powUnit(U,(1,3))]{.inline.}=Unit[T,powUnit(U,(1,3))]T(cbrt T(x))
func `mod`*[T;U:UStr](l:Unit[T,U],n:T):Unit[T,U]{.inline.}=Unit[T,U]T(T(l) mod n)
func `mod`*[T;U:UStr](l:Unit[T,U],r:USi[T,U]):Unit[T,U]{.inline.}=Unit[T,U](T(l) mod T(r.siTo(U)))
func abs*[T;U:UStr](l:Unit[T,U]):Unit[T,U]{.inline.}=Unit[T,U](abs T(l))
func floor*[T;U:UStr](l:Unit[T,U]):Unit[T,U]{.inline.}=Unit[T,U](floor T(l))
func ceil*[T;U:UStr](l:Unit[T,U]):Unit[T,U]{.inline.}=Unit[T,U](ceil T(l))
func round*[T;U:UStr](l:Unit[T,U]):Unit[T,U]{.inline.}=Unit[T,U](round T(l))
func trunc*[T;U:UStr](l:Unit[T,U]):Unit[T,U]{.inline.}=Unit[T,U](trunc T(l))
func max*[T;U:UStr](l:Unit[T,U],r:USi[T,U]):Unit[T,U]{.inline.}=Unit[T,U](T(l).max T(r.siTo(U)))
func min*[T;U:UStr](l:Unit[T,U],r:USi[T,U]):Unit[T,U]{.inline.}=Unit[T,U](T(l).min T(r.siTo(U)))
func gcd*[T;U:UStr](l:Unit[T,U],r:USi[T,U]):Unit[T,U]{.inline.}=Unit[T,U](T(l).gcd T(r.siTo(U)))
func lcm*[T;U:UStr](l:Unit[T,U],r:USi[T,U]):Unit[T,U]{.inline.}=Unit[T,U](T(l).lcm T(r.siTo(U)))
func clamp*[T;U:UStr](a:Unit[T,U],b:USi[T,U],c:USi[T,U]):Unit[T,U]{.inline.}=Unit[T,U](clamp(T(a),T(b.siTo(U)),T(c.siTo(U))))
func `==`*[T;U:UStr](l:Unit[T,U],r:USi[T,U]):bool{.inline.}=T(l)==T(r.siTo(U))
func `<`*[T;U:UStr](l:Unit[T,U],r:USi[T,U]):bool{.inline.}=T(l)<T(r.siTo(U))
func `<=`*[T;U:UStr](l:Unit[T,U],r:USi[T,U]):bool{.inline.}=T(l)<=T(r.siTo(U))
func hypot*[T;U:UStr](l:Unit[T,U],r:USi[T,U]):Unit[T,U]{.inline.}=Unit[T,U](T(l).hypot T(r.siTo(U)))
func floorDiv*[T;U1,U2:UStr](l:Unit[T,U1],r:Unit[T,U2]):Unit[T,divUnit(U1,U2)]{.inline.}=Unit[T,divUnit(U1,U2)](T(l).floorDiv T(r))
func ceilDiv*[T;U1,U2:UStr](l:Unit[T,U1],r:Unit[T,U2]):Unit[T,divUnit(U1,U2)]{.inline.}=Unit[T,divUnit(U1,U2)](T(l).ceilDiv T(r))
func euclDiv*[T;U1,U2:UStr](l:Unit[T,U1],r:Unit[T,U2]):Unit[T,divUnit(U1,U2)]{.inline.}=Unit[T,divUnit(U1,U2)](T(l).euclDiv T(r))
func floorMod*[T;U:UStr](l:Unit[T,U],r:USi[T,U]):Unit[T,U]{.inline.}=Unit[T,U](T(l).floorMod T(r.siTo(U)))
func euclMod*[T;U:UStr](l:Unit[T,U],r:USi[T,U]):Unit[T,U]{.inline.}=Unit[T,U](T(l).euclMod T(r.siTo(U)))
func divmod*[T;U:UStr](l:Unit[T,U],r:USi[T,U]):(T,Unit[T,U]){.inline.}=(T(euclDiv(l,r).siTo""),euclMod(l,r))


#[--usiplugin--]#
type USimode{.pure.}=enum
  n
  m d                                                 # 0->1,1->3,2->7,3->15
  mm md dd                                            # 4->30,5->33
  mmm mmd mdd ddd                                     # 6->23 7->4
  mmmm mmmd mmdd mddd dddd                            # all=116
  mmmmm mmmmd mmmdd mmddd mdddd ddddd
  mmmmmm mmmmmd mmmmdd mmmddd mmdddd mddddd dddddd    # 1+2+..7=28
  p                                                   # 1
  pm mp pmp pd dp pdp                                 # 6
  pmm mpm mmp pmd mpd mdp pdd dpd ddp
  pmpm pmmp mpmp pmpd pmdp mpdp pdpd pddp dpdp
  pmpmp pmpdp pdpdp                                   # 3*3+3*3+3=21
  pmmm mpmm mmpm mmmp pmmd mpmd mmpd mmdp
  pmdd mpdd mdpd mddp pddd dpdd ddpd dddp             # 4*4=16
  pmpmm pmmpm pmmmp mpmpm mpmmp mmpmp
  pmpmd pmmpd pmmdp mpmpd mpmdp mmpdp
  pmpdd pmdpd pmddp mpdpd mpddp mdpdp
  pdpdd pddpd pdddp dpdpd dpddp ddpdp                 # 4*6=24
  pmpmpm pmpmmp pmmpmp mpmpmp
  pmpmpd pmpmdp pmmpdp mpmpdp
  pmpdpd pmpddp pmdpdp mpdpdp
  pdpdpd pdpddp pddpdp dpdpdp
  pmpmpmp pmpmpdp pmpdpdp pdpdpdp                     # 4*5=20                                                # all=116

type mode{.pure.}=enum p,m,d

proc tostr(t:NimNode):NimNode=
  if t.kind==nnkIntLit:
    toStrLit t
  elif t.kind==nnkFloatLit:
    toStrLit t
  elif t.kind==nnkPar:
    toStrLit t
  else:t

macro wisUSi0(T,args):typedesc=
  ## 欲处理限制情况，暂限于编译器，无法使用
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
    mode_bra=newNimNode(nnkBracket)
    unit_bra=newNimNode(nnkBracket)
  for i in mulSeq:
    mode_bra.add ord(mode.m).newIntLitNode
    if i.kind==nnkInfix:
      mode_bra.add ord(mode.p).newIntLitNode
      unit_bra.add tostr(i[1])
      unit_bra.add tostr(i[2])
    else:
      unit_bra.add tostr(i)
  for i in divSeq:
    mode_bra.add ord(mode.d).newIntLitNode
    if i.kind==nnkInfix:
      mode_bra.add ord(mode.p).newIntLitNode
      unit_bra.add tostr(i[1])
      unit_bra.add tostr(i[2])
    else:
      unit_bra.add tostr(i)
  echo  repr newTree(nnkBracketExpr,ident"AutoUSi",T,newIntLitNode(mode_bra.len),mode_bra,unit_bra)

  newTree(nnkBracketExpr,ident"AutoUSi",T,newIntLitNode(mode_bra.len),mode_bra,unit_bra)

macro wisUSi*(T,args):typedesc=
  ## 解决单独USi无法处理U*"m"类型,即涉及泛型U的单位计算
  runnableExamples:
    const g = 9.80665~meter/second^2
    let height = 100.0~meter
    proc getTime[T;U:static string](h:Unit[T,U],g:wisUSi(T,U*"/s^2")):USi[T,"s"]=sqrt T(2)*h/g
    let fallTime = getTime(height,g)
    #And More
    proc getTime[T;U:static string](h:Unit[T,U],g:wisUSi(T,U/"s"^2)):USi[T,"s"]=sqrt T(2)*h/g
    proc getTime[T;U:static string](h:Unit[T,U],g:wisUSi(T,U^0.5*"/s"^2*U^(1/2))):USi[T,"s"]
    #...
    #支持mul,div,pow组合操作,有数量限制
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
    mlen=mulSeq.len
    dlen=divSeq.len
  reverse mulSeq
  reverse divSeq
  var later=newStmtList()
  if mlen>=10 or mlen<0 or dlen>=10 or dlen<0:
    error "syntax error"
  var
    len=0
    i=1
    plen=mlen+dlen
  for m in mulSeq:
    if m.kind==nnkInfix:len=len or i
    i=i shl 1
  for d in divSeq:
    if d.kind==nnkInfix:len=len or i
    i=i shl 1
  mulseq.add divseq
  # 2 + 4*2 + 8*3 + 16*4 + 5 + 6 + 7 = 10 + 88 +18 = 116
  case 10*mlen+dlen:
  of 10:                                                            # n p
    case len:
    of 0:i=ord(USimode.n)
    of 1:i=ord(USimode.p)
    else:error"syntax error"
  of 20:                                                            # m pm mp pmp
    case len:
    of 0:i=ord(USimode.m)
    of 1:i=ord(USimode.pm)
    of 2:i=ord(USimode.mp)
    of 3:i=ord(USimode.pmp)
    else:error "syntax error"
  of 11:                                                            # d pd dp pdp
    case len:
    of 0:i=ord(USimode.d)
    of 1:i=ord(USimode.pd)
    of 2:i=ord(USimode.dp)
    of 3:i=ord(USimode.pdp)
    else:error "syntax error"
  of 30:                                                            # mm pmm mpm pmpm mmp pmmp mpmp pmpmp
    case len:
    of 0:i=ord(USimode.mm)
    of 1:i=ord(USimode.pmm)
    of 2:i=ord(USimode.mpm)
    of 3:i=ord(USimode.pmpm)
    of 4:i=ord(USimode.mmp)
    of 5:i=ord(USimode.pmmp)
    of 6:i=ord(USimode.mpmp)
    of 7:i=ord(USimode.pmpmp)
    else:error "syntax error"
  of 21:                                                            # md pmd mpd pmpd mdp pmdp mpdp pmpdp
    case len:
    of 0:i=ord(USimode.md)
    of 1:i=ord(USimode.pmd)
    of 2:i=ord(USimode.mpd)
    of 3:i=ord(USimode.pmpd)
    of 4:i=ord(USimode.mdp)
    of 5:i=ord(USimode.pmdp)
    of 6:i=ord(USimode.mpdp)
    of 7:i=ord(USimode.pmpdp)
    else:error "syntax error"
  of 12:                                                            # dd pdd dpd pdpd ddp pddp dpdp pdpdp
    case len:
    of 0:i=ord(USimode.dd)
    of 1:i=ord(USimode.pdd)
    of 2:i=ord(USimode.dpd)
    of 3:i=ord(USimode.pdpd)
    of 4:i=ord(USimode.ddp)
    of 5:i=ord(USimode.pddp)
    of 6:i=ord(USimode.dpdp)
    of 7:i=ord(USimode.pdpdp)
    else:error "syntax error"
  of 40:                                                            # mmm pmmm mpmm pmpmm mmpm pmmpm mpmpm pmpmpm                                                              # mmmp pmmmp mpmmp pmpmmp mmpmp pmmpmp mpmpmp pmpmpmp
    case len:
    of 0:i=ord(USimode.mmm)
    of 1:i=ord(USimode.pmmm)
    of 2:i=ord(USimode.mpmm)
    of 3:i=ord(USimode.pmpmm)
    of 4:i=ord(USimode.mmpm)
    of 5:i=ord(USimode.pmmpm)
    of 6:i=ord(USimode.mpmpm)
    of 7:i=ord(USimode.pmpmpm)
    of 8:i=ord(USimode.mmmp)
    of 9:i=ord(USimode.pmmmp)
    of 10:i=ord(USimode.mpmmp)
    of 11:i=ord(USimode.pmpmmp)
    of 12:i=ord(USimode.mmpmp)
    of 13:i=ord(USimode.pmmpmp)
    of 14:i=ord(USimode.mpmpmp)
    of 15:i=ord(USimode.pmpmpmp)
    else:error "syntax error"
  of 31:                                                            # mmd pmmd mpmd pmpmd mmpd pmmpd mpmpd pmpmpd                                                              # mmdp pmmdp mpmdp pmpmdp mmpdp pmmpdp mpmpdp pmpmpdp
    case len:
    of 0:i=ord(USimode.mmd)
    of 1:i=ord(USimode.pmmd)
    of 2:i=ord(USimode.mpmd)
    of 3:i=ord(USimode.pmpmd)
    of 4:i=ord(USimode.mmpd)
    of 5:i=ord(USimode.pmmpd)
    of 6:i=ord(USimode.mpmpd)
    of 7:i=ord(USimode.pmpmpd)
    of 8:i=ord(USimode.mmdp)
    of 9:i=ord(USimode.pmmdp)
    of 10:i=ord(USimode.mpmdp)
    of 11:i=ord(USimode.pmpmdp)
    of 12:i=ord(USimode.mmpdp)
    of 13:i=ord(USimode.pmmpdp)
    of 14:i=ord(USimode.mpmpdp)
    of 15:i=ord(USimode.pmpmpdp)
    else:error "syntax error"
  of 22:                                                            # mdd pmdd mpdd pmpdd mdpd pmdpd mpdpd pmpdpd                                                              # mddp pmddp mpddp pmpddp mdpdp pmdpdp mpdpdp pmpdpdp
    case len:
    of 0:i=ord(USimode.mdd)
    of 1:i=ord(USimode.pmdd)
    of 2:i=ord(USimode.mpdd)
    of 3:i=ord(USimode.pmpdd)
    of 4:i=ord(USimode.mdpd)
    of 5:i=ord(USimode.pmdpd)
    of 6:i=ord(USimode.mpdpd)
    of 7:i=ord(USimode.pmpdpd)
    of 8:i=ord(USimode.mddp)
    of 9:i=ord(USimode.pmddp)
    of 10:i=ord(USimode.mpddp)
    of 11:i=ord(USimode.pmpddp)
    of 12:i=ord(USimode.mdpdp)
    of 13:i=ord(USimode.pmdpdp)
    of 14:i=ord(USimode.mpdpdp)
    of 15:i=ord(USimode.pmpdpdp)
    else:error "syntax error"
  of 13:                                                            # ddd pddd dpdd pdpdd ddpd pddpd dpdpd pdpdpd                                                              # dddp pdddp dpddp pdpddp ddpdp pddpdp dpdpdp pdpdpdp
    case len:
    of 0:i=ord(USimode.ddd)
    of 1:i=ord(USimode.pddd)
    of 2:i=ord(USimode.dpdd)
    of 3:i=ord(USimode.pdpdd)
    of 4:i=ord(USimode.ddpd)
    of 5:i=ord(USimode.pddpd)
    of 6:i=ord(USimode.dpdpd)
    of 7:i=ord(USimode.pdpdpd)
    of 8:i=ord(USimode.dddp)
    of 9:i=ord(USimode.pdddp)
    of 10:i=ord(USimode.dpddp)
    of 11:i=ord(USimode.pdpddp)
    of 12:i=ord(USimode.ddpdp)
    of 13:i=ord(USimode.pddpdp)
    of 14:i=ord(USimode.dpdpdp)
    of 15:i=ord(USimode.pdpdpdp)
    else:error "syntax error"
  of 50:
    case len:
    of 0:i=ord(USimode.mmmm)
    else:error "syntax error"
  of 41:
    case len:
    of 0:i=ord(USimode.mmmd)
    else:error "syntax error"
  of 32:
    case len:
    of 0:i=ord(USimode.mmdd)
    else:error "syntax error"
  of 23:
    case len:
    of 0:i=ord(USimode.mddd)
    else:error "syntax error"
  of 14:
    case len:
    of 0:i=ord(USimode.dddd)
    else:error "syntax error"
  of 60:
    case len:
    of 0:i=ord(USimode.mmmmm)
    else:error "syntax error"
  of 51:
    case len:
    of 0:i=ord(USimode.mmmmd)
    else:error "syntax error"
  of 42:
    case len:
    of 0:i=ord(USimode.mmmdd)
    else:error "syntax error"
  of 33:
    case len:
    of 0:i=ord(USimode.mmddd)
    else:error "syntax error"
  of 24:
    case len:
    of 0:i=ord(USimode.mdddd)
    else:error "syntax error"
  of 15:
    case len:
    of 0:i=ord(USimode.ddddd)
    else:error "syntax error"
  of 70:
    case len:
    of 0:i=ord(USimode.mmmmmm)
    else:error "syntax error"
  of 61:
    case len:
    of 0:i=ord(USimode.mmmmmd)
    else:error "syntax error"
  of 52:
    case len:
    of 0:i=ord(USimode.mmmmdd)
    else:error "syntax error"
  of 43:
    case len:
    of 0:i=ord(USimode.mmmddd)
    else:error "syntax error"
  of 34:
    case len:
    of 0:i=ord(USimode.mmdddd)
    else:error "syntax error"
  of 25:
    case len:
    of 0:i=ord(USimode.mddddd)
    else:error "syntax error"
  of 16:
    case len:
    of 0:i=ord(USimode.dddddd)
    else:error "syntax error"
  else:
    error "syntax error"
  for t in 0..<mlen+dlen:
    if (len and (1 shl t))==0:
      later.add mulseq[t]
    else:
      later.add mulSeq[t][1]
      later.add mulSeq[t][2]
      inc plen
  result=
    case plen:
    of 1:newTree(nnkBracketExpr,ident"AutoUSi0")
    of 2:newTree(nnkBracketExpr,ident"AutoUSi1")
    of 3:newTree(nnkBracketExpr,ident"AutoUSi2")
    of 4:newTree(nnkBracketExpr,ident"AutoUSi3")
    of 5:newTree(nnkBracketExpr,ident"AutoUSi4")
    of 6:newTree(nnkBracketExpr,ident"AutoUSi5")
    of 7:newTree(nnkBracketExpr,ident"AutoUSi6")
    of 8:newTree(nnkBracketExpr,ident"AutoUSi7")
    else:error "syntax error"
  result.add T
  result.add newIntLitNode(i)
  for t in later:
    result.add t.tostr


func toTuple(s:static string):static[(int,int)]=
  let N=s.replace(" ","").replace("(","").replace(")","")
  if N.contains".":
    floatToFraction N.parseFloat
  elif N.contains"/":
    let p=N.split"/"
    simplifyFrac (p[0].parseInt,p[1].parseInt)
  else:
    simplifyFrac (N.parseInt,1)

proc trans[N:static int](M:static array[0..N-1,int],U:static array[0..N-1,string]):static string=
  if N<=0:return ""
  result=""
  var
    prev=""
    pm=ord(mode.m)
  for i in 0..N-1:
    case M[i]:
    of ord(mode.p): prev=prev.powUnit U[i].toTuple
    of ord(mode.m):
      result=result.mulUnit prev
      prev=U[i].formatUnit
    of ord(mode.d):
      if pm==ord(mode.m):
        pm=ord(mode.d)
        result=result.mulUnit prev
      else:
        result=result.divUnit prev
      prev=U[i].formatUnit
    if pm==ord(mode.m):
      result=result.mulUnit prev
    else:
      result=result.divUnit prev
proc cor_m[N:static int](M:static array[0..N-1,int]):static bool=
  var
    pre_p=true
    in_div=false
  for i in 0..N-1:
    case M[i]:
    of ord(mode.p):
      if pre_p:return false
      pre_p=true
    of ord(mode.m):
      if in_div:return false
      pre_p=false
    of ord(mode.d):
      in_div=true
      pre_p=false
    else:
      return false
  true

type AutoUSi[T;N:static int,M:static array[0..N-1,int],U:static array[0..N-1,string]]=concept u
  ## 欲实现无限制usi组合，编译器限制暂无法实现
  u is Unit
  u.T is T
  cor_m(M)
  const ut=trans(M,U)
  when ut!=u.U:
    const usiU =strSimpleSiUnit ut
    const siU = strSimpleSiUnit u.U
    uSiU==siU

type #wisUSi辅助概念
  AutoUSi0*[T;N:static int;U:static string]#[1]#=concept u
    u is Unit
    u.T is T
    const ut=
      when N==ord(USimode.n): U.formatUnit
      else:""
    when ut!=u.U:
      const usiU =strSimpleSiUnit ut
      const siU = strSimpleSiUnit u.U
      usiU==siU
  AutoUSi1*[T;N:static int;U,V:static string]#[3]#=concept u
    u is Unit
    u.T is T
    const ut=
      when N==ord(USimode.m): U.formatUnit.mulUnit(V.formatUnit)
      elif N==ord(USimode.d): U.formatUnit.divUnit(V.formatUnit)
      # 幂操作基础系列 (1+6+21+16=44种)
      elif N==ord(USimode.p): U.formatUnit.powUnit(V.toTuple)
      else:""
    when ut!=u.U:
      const usiU =strSimpleSiUnit ut
      const siU = strSimpleSiUnit u.U
      usiU==siU
  AutoUSi2*[T;N:static int;U,V,W:static string]#[7]#=concept u
    u is Unit
    u.T is T
    const ut=
      when N==ord(USimode.mm): U.formatUnit.mulUnit(V.formatUnit).mulUnit(W.formatUnit)
      elif N==ord(USimode.md): U.formatUnit.mulUnit(V.formatUnit).divUnit(W.formatUnit)
      elif N==ord(USimode.dd): U.formatUnit.divUnit(V.formatUnit).divUnit(W.formatUnit)
      # 幂操作基础系列 (1+6+21+16=44种)
      elif N==ord(USimode.pm): U.formatUnit.powUnit(V.toTuple).mulUnit(W.formatUnit)
      elif N==ord(USimode.mp): U.formatUnit.mulUnit(V.formatUnit.powUnit(W.toTuple))
      elif N==ord(USimode.pd): U.formatUnit.powUnit(V.toTuple).divUnit(W.formatUnit)
      elif N==ord(USimode.dp): U.formatUnit.divUnit(V.formatUnit.powUnit(W.toTuple))
      else:""
    when ut!=u.U:
      const usiU =strSimpleSiUnit ut
      const siU = strSimpleSiUnit u.U
      usiU==siU
  AutoUSi3*[T;N:static int;U,V,W,X:static string]#[15]#=concept u
    u is Unit
    u.T is T
    const ut=
      when N==ord(USimode.mmm): U.formatUnit.mulUnit(V.formatUnit).mulUnit(W.formatUnit).mulUnit(X.formatUnit)
      elif N==ord(USimode.mmd): U.formatUnit.mulUnit(V.formatUnit).mulUnit(W.formatUnit).divUnit(X.formatUnit)
      elif N==ord(USimode.mdd): U.formatUnit.mulUnit(V.formatUnit).divUnit(W.formatUnit).divUnit(X.formatUnit)
      elif N==ord(USimode.ddd): U.formatUnit.divUnit(V.formatUnit).divUnit(W.formatUnit).divUnit(X.formatUnit)
      elif N==ord(USimode.pmp): U.formatUnit.powUnit(V.toTuple).mulUnit(W.formatUnit.powUnit(X.toTuple))
      elif N==ord(USimode.pdp): U.formatUnit.powUnit(V.toTuple).divUnit(W.formatUnit.powUnit(X.toTuple))

      elif N==ord(USimode.pmm): U.formatUnit.powUnit(V.toTuple).mulUnit(W.formatUnit).mulUnit(X.formatUnit)
      elif N==ord(USimode.mpm): U.formatUnit.mulUnit(V.formatUnit.powUnit(W.toTuple)).mulUnit(X.formatUnit)
      elif N==ord(USimode.mmp): U.formatUnit.mulUnit(V.formatUnit).mulUnit(W.formatUnit.powUnit(X.toTuple))
      elif N==ord(USimode.pmd): U.formatUnit.powUnit(V.toTuple).mulUnit(W.formatUnit).divUnit(X.formatUnit)
      elif N==ord(USimode.mpd): U.formatUnit.mulUnit(V.formatUnit.powUnit(W.toTuple)).divUnit(X.formatUnit)
      elif N==ord(USimode.mdp): U.formatUnit.mulUnit(V.formatUnit).divUnit(W.formatUnit.powUnit(X.toTuple))
      elif N==ord(USimode.pdd): U.formatUnit.powUnit(V.toTuple).divUnit(W.formatUnit).divUnit(X.formatUnit)
      elif N==ord(USimode.dpd): U.formatUnit.divUnit(V.formatUnit.powUnit(W.toTuple)).divUnit(X.formatUnit)
      elif N==ord(USimode.ddp): U.formatUnit.divUnit(V.formatUnit).divUnit(W.formatUnit.powUnit(X.toTuple))
      else:""
    when ut!=u.U:
      const usiU =strSimpleSiUnit ut
      const siU = strSimpleSiUnit u.U
      usiU==siU
  AutoUSi4*[T;N:static int;U,V,W,X,Y:static string]#[30]#=concept u
    u is Unit
    u.T is T
    const ut=
      when N==ord(USimode.mmmm): U.formatUnit.mulUnit(V.formatUnit).mulUnit(W.formatUnit).mulUnit(X.formatUnit).mulUnit(Y.formatUnit)
      elif N==ord(USimode.mmmd): U.formatUnit.mulUnit(V.formatUnit).mulUnit(W.formatUnit).mulUnit(X.formatUnit).divUnit(Y.formatUnit)
      elif N==ord(USimode.mmdd): U.formatUnit.mulUnit(V.formatUnit).mulUnit(W.formatUnit).divUnit(X.formatUnit).divUnit(Y.formatUnit)
      elif N==ord(USimode.mddd): U.formatUnit.mulUnit(V.formatUnit).divUnit(W.formatUnit).divUnit(X.formatUnit).divUnit(Y.formatUnit)
      elif N==ord(USimode.dddd): U.formatUnit.divUnit(V.formatUnit).divUnit(W.formatUnit).divUnit(X.formatUnit).divUnit(Y.formatUnit)

      elif N==ord(USimode.pmpm): U.formatUnit.powUnit(V.toTuple).mulUnit(W.formatUnit.powUnit(X.toTuple)).mulUnit(Y.formatUnit)
      elif N==ord(USimode.pmmp): U.formatUnit.powUnit(V.toTuple).mulUnit(W.formatUnit).mulUnit(X.formatUnit.powUnit(Y.toTuple))
      elif N==ord(USimode.mpmp): U.formatUnit.mulUnit(V.formatUnit.powUnit(W.toTuple)).mulUnit(X.formatUnit.powUnit(Y.toTuple))
      elif N==ord(USimode.pmpd): U.formatUnit.powUnit(V.toTuple).mulUnit(W.formatUnit.powUnit(X.toTuple)).divUnit(Y.formatUnit)
      elif N==ord(USimode.pmdp): U.formatUnit.powUnit(V.toTuple).mulUnit(W.formatUnit).divUnit(X.formatUnit.powUnit(Y.toTuple))

      elif N==ord(USimode.mpdp): U.formatUnit.mulUnit(V.formatUnit.powUnit(W.toTuple)).divUnit(X.formatUnit.powUnit(Y.toTuple))
      elif N==ord(USimode.pdpd): U.formatUnit.powUnit(V.toTuple).divUnit(W.formatUnit.powUnit(X.toTuple)).divUnit(Y.formatUnit)
      elif N==ord(USimode.pddp): U.formatUnit.powUnit(V.toTuple).divUnit(W.formatUnit).divUnit(X.formatUnit.powUnit(Y.toTuple))
      elif N==ord(USimode.dpdp): U.formatUnit.divUnit(V.formatUnit.powUnit(W.toTuple)).divUnit(X.formatUnit.powUnit(Y.toTuple))
      elif N==ord(USimode.ddpd): U.formatUnit.divUnit(V.formatUnit).divUnit(W.formatUnit.powUnit(X.toTuple)).divUnit(Y.formatUnit)

      elif N==ord(USimode.dpdd): U.formatUnit.divUnit(V.formatUnit.powUnit(W.toTuple)).divUnit(X.formatUnit).divUnit(Y.formatUnit)
      elif N==ord(USimode.dddp): U.formatUnit.divUnit(V.formatUnit).divUnit(W.formatUnit).divUnit(X.formatUnit.powUnit(Y.toTuple))
      elif N==ord(USimode.pmmm): U.formatUnit.powUnit(V.toTuple).mulUnit(W.formatUnit).mulUnit(X.formatUnit).mulUnit(Y.formatUnit)
      elif N==ord(USimode.mpmm): U.formatUnit.mulUnit(V.formatUnit.powUnit(W.toTuple)).mulUnit(X.formatUnit).mulUnit(Y.formatUnit)
      elif N==ord(USimode.mmpm): U.formatUnit.mulUnit(V.formatUnit).mulUnit(W.formatUnit.powUnit(X.toTuple)).mulUnit(Y.formatUnit)

      elif N==ord(USimode.mmmp): U.formatUnit.mulUnit(V.formatUnit).mulUnit(W.formatUnit).mulUnit(X.formatUnit.powUnit(Y.toTuple))
      elif N==ord(USimode.pmmd): U.formatUnit.powUnit(V.toTuple).mulUnit(W.formatUnit).mulUnit(X.formatUnit).divUnit(Y.formatUnit)
      elif N==ord(USimode.mpmd): U.formatUnit.mulUnit(V.formatUnit.powUnit(W.toTuple)).mulUnit(X.formatUnit).divUnit(Y.formatUnit)
      elif N==ord(USimode.mmpd): U.formatUnit.mulUnit(V.formatUnit).mulUnit(W.formatUnit.powUnit(X.toTuple)).divUnit(Y.formatUnit)
      elif N==ord(USimode.mmdp): U.formatUnit.mulUnit(V.formatUnit).mulUnit(W.formatUnit).divUnit(X.formatUnit.powUnit(Y.toTuple))

      elif N==ord(USimode.pmdd): U.formatUnit.powUnit(V.toTuple).mulUnit(W.formatUnit).divUnit(X.formatUnit).divUnit(Y.formatUnit)
      elif N==ord(USimode.mpdd): U.formatUnit.mulUnit(V.formatUnit.powUnit(W.toTuple)).divUnit(X.formatUnit).divUnit(Y.formatUnit)
      elif N==ord(USimode.mdpd): U.formatUnit.mulUnit(V.formatUnit).divUnit(W.formatUnit.powUnit(X.toTuple)).divUnit(Y.formatUnit)
      elif N==ord(USimode.mddp): U.formatUnit.mulUnit(V.formatUnit).divUnit(W.formatUnit).divUnit(X.formatUnit.powUnit(Y.toTuple))
      elif N==ord(USimode.pddd): U.formatUnit.powUnit(V.toTuple).divUnit(W.formatUnit).divUnit(X.formatUnit).divUnit(Y.formatUnit)
      else:""
    when ut!=u.U:
      const usiU =strSimpleSiUnit ut
      const siU = strSimpleSiUnit u.U
      usiU==siU
  AutoUSi5*[T;N:static int;U,V,W,X,Y,Z:static string]#[33]#=concept u
    u is Unit
    u.T is T
    const ut=
      when N==ord(USimode.mmmmm): U.formatUnit.mulUnit(V.formatUnit).mulUnit(W.formatUnit).mulUnit(X.formatUnit).mulUnit(Y.formatUnit).mulUnit(Z.formatUnit)
      elif N==ord(USimode.mmmmd): U.formatUnit.mulUnit(V.formatUnit).mulUnit(W.formatUnit).mulUnit(X.formatUnit).mulUnit(Y.formatUnit).divUnit(Z.formatUnit)
      elif N==ord(USimode.mmmdd): U.formatUnit.mulUnit(V.formatUnit).mulUnit(W.formatUnit).mulUnit(X.formatUnit).divUnit(Y.formatUnit).divUnit(Z.formatUnit)
      elif N==ord(USimode.mmddd): U.formatUnit.mulUnit(V.formatUnit).mulUnit(W.formatUnit).divUnit(X.formatUnit).divUnit(Y.formatUnit).divUnit(Z.formatUnit)
      elif N==ord(USimode.mdddd): U.formatUnit.mulUnit(V.formatUnit).divUnit(W.formatUnit).divUnit(X.formatUnit).divUnit(Y.formatUnit).divUnit(Z.formatUnit)

      elif N==ord(USimode.ddddd): U.formatUnit.divUnit(V.formatUnit).divUnit(W.formatUnit).divUnit(X.formatUnit).divUnit(Y.formatUnit).divUnit(Z.formatUnit)
      elif N==ord(USimode.pmpmm): U.formatUnit.powUnit(V.toTuple).mulUnit(W.formatUnit.powUnit(X.toTuple)).mulUnit(Y.formatUnit).mulUnit(Z.formatUnit)
      elif N==ord(USimode.pmmpm): U.formatUnit.powUnit(V.toTuple).mulUnit(W.formatUnit).mulUnit(X.formatUnit.powUnit(Y.toTuple)).mulUnit(Z.formatUnit)
      elif N==ord(USimode.pmmmp): U.formatUnit.powUnit(V.toTuple).mulUnit(W.formatUnit).mulUnit(X.formatUnit).mulUnit(Y.formatUnit.powUnit(Z.toTuple))
      elif N==ord(USimode.mpmpm): U.formatUnit.mulUnit(V.formatUnit.powUnit(W.toTuple)).mulUnit(X.formatUnit.powUnit(Y.toTuple)).mulUnit(Z.formatUnit)

      elif N==ord(USimode.mpmmp): U.formatUnit.mulUnit(V.formatUnit.powUnit(W.toTuple)).mulUnit(X.formatUnit).mulUnit(Y.formatUnit.powUnit(Z.toTuple))
      elif N==ord(USimode.mmpmp): U.formatUnit.mulUnit(V.formatUnit).mulUnit(W.formatUnit.powUnit(X.toTuple)).mulUnit(Y.formatUnit.powUnit(Z.toTuple))
      elif N==ord(USimode.pmpmd): U.formatUnit.powUnit(V.toTuple).mulUnit(W.formatUnit.powUnit(X.toTuple)).mulUnit(Y.formatUnit).divUnit(Z.formatUnit)
      elif N==ord(USimode.pmmpd): U.formatUnit.powUnit(V.toTuple).mulUnit(W.formatUnit).mulUnit(X.formatUnit.powUnit(Y.toTuple)).divUnit(Z.formatUnit)
      elif N==ord(USimode.pmmdp): U.formatUnit.powUnit(V.toTuple).mulUnit(W.formatUnit).mulUnit(X.formatUnit).divUnit(Y.formatUnit.powUnit(Z.toTuple))

      elif N==ord(USimode.mpmpd): U.formatUnit.mulUnit(V.formatUnit.powUnit(W.toTuple)).mulUnit(X.formatUnit.powUnit(Y.toTuple)).divUnit(Z.formatUnit)
      elif N==ord(USimode.mpmdp): U.formatUnit.mulUnit(V.formatUnit.powUnit(W.toTuple)).mulUnit(X.formatUnit).divUnit(Y.formatUnit.powUnit(Z.toTuple))
      elif N==ord(USimode.mmpdp): U.formatUnit.mulUnit(V.formatUnit).mulUnit(W.formatUnit.powUnit(X.toTuple)).divUnit(Y.formatUnit.powUnit(Z.toTuple))
      elif N==ord(USimode.pmpdd): U.formatUnit.powUnit(V.toTuple).mulUnit(W.formatUnit.powUnit(X.toTuple)).divUnit(Y.formatUnit).divUnit(Z.formatUnit)
      elif N==ord(USimode.pmdpd): U.formatUnit.powUnit(V.toTuple).mulUnit(W.formatUnit).divUnit(X.formatUnit.powUnit(Y.toTuple)).divUnit(Z.formatUnit)

      elif N==ord(USimode.pmddp): U.formatUnit.powUnit(V.toTuple).mulUnit(W.formatUnit).divUnit(X.formatUnit).divUnit(Y.formatUnit.powUnit(Z.toTuple))
      elif N==ord(USimode.mpdpd): U.formatUnit.mulUnit(V.formatUnit.powUnit(W.toTuple)).divUnit(X.formatUnit.powUnit(Y.toTuple)).divUnit(Z.formatUnit)
      elif N==ord(USimode.mpddp): U.formatUnit.mulUnit(V.formatUnit.powUnit(W.toTuple)).divUnit(X.formatUnit).divUnit(Y.formatUnit.powUnit(Z.toTuple))
      elif N==ord(USimode.mdpdp): U.formatUnit.mulUnit(V.formatUnit).divUnit(W.formatUnit.powUnit(X.toTuple)).divUnit(Y.formatUnit.powUnit(Z.toTuple))
      elif N==ord(USimode.pdpdd): U.formatUnit.powUnit(V.toTuple).divUnit(W.formatUnit.powUnit(X.toTuple)).divUnit(Y.formatUnit).divUnit(Z.formatUnit)

      elif N==ord(USimode.pddpd): U.formatUnit.powUnit(V.toTuple).divUnit(W.formatUnit).divUnit(X.formatUnit.powUnit(Y.toTuple)).divUnit(Z.formatUnit)
      elif N==ord(USimode.pdddp): U.formatUnit.powUnit(V.toTuple).divUnit(W.formatUnit).divUnit(X.formatUnit).divUnit(Y.formatUnit.powUnit(Z.toTuple))
      elif N==ord(USimode.dpdpd): U.formatUnit.divUnit(V.formatUnit.powUnit(W.toTuple)).divUnit(X.formatUnit.powUnit(Y.toTuple)).divUnit(Z.formatUnit)
      elif N==ord(USimode.dpddp): U.formatUnit.divUnit(V.formatUnit.powUnit(W.toTuple)).divUnit(X.formatUnit).divUnit(Y.formatUnit.powUnit(Z.toTuple))
      elif N==ord(USimode.ddpdp): U.formatUnit.divUnit(V.formatUnit).divUnit(W.formatUnit.powUnit(X.toTuple)).divUnit(Y.formatUnit.powUnit(Z.toTuple))

      elif N==ord(USimode.pmpmp): U.formatUnit.powUnit(V.toTuple).mulUnit(W.formatUnit.powUnit(X.toTuple)).mulUnit(Y.formatUnit.powUnit(Z.toTuple))
      elif N==ord(USimode.pmpdp): U.formatUnit.powUnit(V.toTuple).mulUnit(W.formatUnit.powUnit(X.toTuple)).divUnit(Y.formatUnit.powUnit(Z.toTuple))
      elif N==ord(USimode.pdpdp): U.formatUnit.powUnit(V.toTuple).divUnit(W.formatUnit.powUnit(X.toTuple)).divUnit(Y.formatUnit.powUnit(Z.toTuple))
      else:""
    when ut!=u.U:
      const usiU =strSimpleSiUnit ut
      const siU = strSimpleSiUnit u.U
      usiU==siU
  AutoUSi6*[T;N:static int;U,V,W,X,Y,Z,A:static string]#[23]#=concept u
    u is Unit
    u.T is T
    const ut=
      when N==ord(USimode.mmmmmm): U.formatUnit.mulUnit(V.formatUnit).mulUnit(W.formatUnit).mulUnit(X.formatUnit).mulUnit(Y.formatUnit).mulUnit(Z.formatUnit).mulUnit(A.formatUnit)
      elif N==ord(USimode.mmmmmd): U.formatUnit.mulUnit(V.formatUnit).mulUnit(W.formatUnit).mulUnit(X.formatUnit).mulUnit(Y.formatUnit).mulUnit(Z.formatUnit).divUnit(A.formatUnit)
      elif N==ord(USimode.mmmmdd): U.formatUnit.mulUnit(V.formatUnit).mulUnit(W.formatUnit).mulUnit(X.formatUnit).mulUnit(Y.formatUnit).divUnit(Z.formatUnit).divUnit(A.formatUnit)
      elif N==ord(USimode.mmmddd): U.formatUnit.mulUnit(V.formatUnit).mulUnit(W.formatUnit).mulUnit(X.formatUnit).divUnit(Y.formatUnit).divUnit(Z.formatUnit).divUnit(A.formatUnit)
      elif N==ord(USimode.mmdddd): U.formatUnit.mulUnit(V.formatUnit).mulUnit(W.formatUnit).divUnit(X.formatUnit).divUnit(Y.formatUnit).divUnit(Z.formatUnit).divUnit(A.formatUnit)

      elif N==ord(USimode.mddddd): U.formatUnit.mulUnit(V.formatUnit).divUnit(W.formatUnit).divUnit(X.formatUnit).divUnit(Y.formatUnit).divUnit(Z.formatUnit).divUnit(A.formatUnit)
      elif N==ord(USimode.dddddd): U.formatUnit.divUnit(V.formatUnit).divUnit(W.formatUnit).divUnit(X.formatUnit).divUnit(Y.formatUnit).divUnit(Z.formatUnit).divUnit(A.formatUnit)
      elif N==ord(USimode.pmpmpm): U.formatUnit.powUnit(V.toTuple).mulUnit(W.formatUnit.powUnit(X.toTuple)).mulUnit(Y.formatUnit.powUnit(Z.toTuple)).mulUnit(A.formatUnit)
      elif N==ord(USimode.pmpmmp): U.formatUnit.powUnit(V.toTuple).mulUnit(W.formatUnit.powUnit(X.toTuple)).mulUnit(Y.formatUnit).mulUnit(Z.formatUnit.powUnit(A.toTuple))
      elif N==ord(USimode.pmmpmp): U.formatUnit.powUnit(V.toTuple).mulUnit(W.formatUnit).mulUnit(X.formatUnit.powUnit(Y.toTuple)).mulUnit(Z.formatUnit.powUnit(A.toTuple))

      elif N==ord(USimode.mpmpmp): U.formatUnit.mulUnit(V.formatUnit.powUnit(W.toTuple)).mulUnit(X.formatUnit.powUnit(Y.toTuple)).mulUnit(Z.formatUnit.powUnit(A.toTuple))
      elif N==ord(USimode.pmpmpd): U.formatUnit.powUnit(V.toTuple).mulUnit(W.formatUnit.powUnit(X.toTuple)).mulUnit(Y.formatUnit.powUnit(Z.toTuple)).divUnit(A.formatUnit)
      elif N==ord(USimode.pmpmdp): U.formatUnit.powUnit(V.toTuple).mulUnit(W.formatUnit.powUnit(X.toTuple)).mulUnit(Y.formatUnit).divUnit(Z.formatUnit.powUnit(A.toTuple))
      elif N==ord(USimode.pmmpdp): U.formatUnit.powUnit(V.toTuple).mulUnit(W.formatUnit).mulUnit(X.formatUnit.powUnit(Y.toTuple)).divUnit(Z.formatUnit.powUnit(A.toTuple))
      elif N==ord(USimode.mpmpdp): U.formatUnit.mulUnit(V.formatUnit.powUnit(W.toTuple)).mulUnit(X.formatUnit.powUnit(Y.toTuple)).divUnit(Z.formatUnit.powUnit(A.toTuple))

      elif N==ord(USimode.pmpdpd): U.formatUnit.powUnit(V.toTuple).mulUnit(W.formatUnit.powUnit(X.toTuple)).divUnit(Y.formatUnit.powUnit(Z.toTuple)).divUnit(A.formatUnit)
      elif N==ord(USimode.pmpddp): U.formatUnit.powUnit(V.toTuple).mulUnit(W.formatUnit.powUnit(X.toTuple)).divUnit(Y.formatUnit).divUnit(Z.formatUnit.powUnit(A.toTuple))
      elif N==ord(USimode.pmdpdp): U.formatUnit.powUnit(V.toTuple).mulUnit(W.formatUnit).divUnit(X.formatUnit.powUnit(Y.toTuple)).divUnit(Z.formatUnit.powUnit(A.toTuple))
      elif N==ord(USimode.mpdpdp): U.formatUnit.mulUnit(V.formatUnit.powUnit(W.toTuple)).divUnit(X.formatUnit.powUnit(Y.toTuple)).divUnit(Z.formatUnit.powUnit(A.toTuple))
      elif N==ord(USimode.pdpdpd): U.formatUnit.powUnit(V.toTuple).divUnit(W.formatUnit.powUnit(X.toTuple)).divUnit(Y.formatUnit.powUnit(Z.toTuple)).divUnit(A.formatUnit)

      elif N==ord(USimode.pdpddp): U.formatUnit.powUnit(V.toTuple).divUnit(W.formatUnit.powUnit(X.toTuple)).divUnit(Y.formatUnit).divUnit(Z.formatUnit.powUnit(A.toTuple))
      elif N==ord(USimode.pddpdp): U.formatUnit.powUnit(V.toTuple).divUnit(W.formatUnit).divUnit(X.formatUnit.powUnit(Y.toTuple)).divUnit(Z.formatUnit.powUnit(A.toTuple))
      elif N==ord(USimode.dpdpdp): U.formatUnit.divUnit(V.formatUnit.powUnit(W.toTuple)).divUnit(X.formatUnit.powUnit(Y.toTuple)).divUnit(Z.formatUnit.powUnit(A.toTuple))
      else:""
    when ut!=u.U:
      const usiU =strSimpleSiUnit ut
      const siU = strSimpleSiUnit u.U
      usiU==siU
  AutoUSi7*[T;N:static int;U,V,W,X,Y,Z,A,B:static string]#[4]#=concept u
    u is Unit
    u.T is T
    const ut=
      when N==ord(USimode.pmpmpmp): U.formatUnit.powUnit(V.toTuple).mulUnit(W.formatUnit.powUnit(X.toTuple)).mulUnit(Y.formatUnit.powUnit(Z.toTuple)).mulUnit(A.formatUnit.powUnit(B.toTuple))
      elif N==ord(USimode.pmpmpdp): U.formatUnit.powUnit(V.toTuple).mulUnit(W.formatUnit.powUnit(X.toTuple)).mulUnit(Y.formatUnit.powUnit(Z.toTuple)).divUnit(A.formatUnit.powUnit(B.toTuple))
      elif N==ord(USimode.pmpdpdp): U.formatUnit.powUnit(V.toTuple).mulUnit(W.formatUnit.powUnit(X.toTuple)).divUnit(Y.formatUnit.powUnit(Z.toTuple)).divUnit(A.formatUnit.powUnit(B.toTuple))
      elif N==ord(USimode.pdpdpdp): U.formatUnit.powUnit(V.toTuple).divUnit(W.formatUnit.powUnit(X.toTuple)).divUnit(Y.formatUnit.powUnit(Z.toTuple)).divUnit(A.formatUnit.powUnit(B.toTuple))
      else:""
    when ut!=u.U:
      const usiU =strSimpleSiUnit ut
      const siU = strSimpleSiUnit u.U
      usiU==siU





when isMainModule:
  import unitx/[simphy,physics]
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

