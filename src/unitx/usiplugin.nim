from macros import newTree,nnkBracketExpr,add,
  len,`[]`,quote,newIdentNode,error,items,newIntLitNode,
  kind,nnkInfix,eqIdent,newStmtList,newDotExpr,ident,
  nnkIntLit,nnkFloatLit,toStrLit,newStrLitNode,nnkPar
from algorithm import reverse
from strutils import contains,parseInt,parseFloat,replace,split

from core import formatUnit,strSimpleSiUnit,Unit,mulUnit,divUnit,powUnit,floatToFraction,simplifyFrac

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

proc tostr(t:NimNode):NimNode=
  if t.kind==nnkIntLit:
    toStrLit t
  elif t.kind==nnkFloatLit:
    toStrLit t
  elif t.kind==nnkPar:
    toStrLit t
  else:t

macro wisUSi*(T,args):untyped=
  #解决单独USi无法处理U*"m"类型,即涉及泛型U的单位计算
  runnableExamples:
    const g = 9.80665~meter/second^2
    let height = 100.0~meter
    proc getTime[T;U:static[string]](h:Unit[T,U],g:wisUSi(T,U*"/s^2")):USi[T,"s"]=sqrt T(2)*h/g
    let fallTime = getTime(height,g)
    #And More
    proc getTime[T;U:static[string]](h:Unit[T,U],g:wisUSi(T,U/"s"^2)):USi[T,"s"]=sqrt T(2)*h/g
    proc getTime[T;U:static[string]](h:Unit[T,U],g:wisUSi(T,U^0.5*"/s"^2*U^(1/2))):USi[T,"s"]
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

func toTuple(s:static[string]):static[(int,int)]=
  let N=s.replace(" ","").replace("(","").replace(")","")
  if N.contains".":
    floatToFraction N.parseFloat
  elif N.contains"/":
    let p=N.split"/"
    simplifyFrac (p[0].parseInt,p[1].parseInt)
  else:
    simplifyFrac (N.parseInt,1)

type
  AutoUSi0*[T;N:static[int];U:static[string]]#[1]#=concept u
    u is Unit
    u.T is T
    const ut=
      when N==ord(USimode.n): U.formatUnit
      else:""
    when ut!=u.U:
      const usiU =strSimpleSiUnit ut
      const siU = strSimpleSiUnit u.U
      usiU==siU
  AutoUSi1*[T;N:static[int];U,V:static[string]]#[3]#=concept u
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
  AutoUSi2*[T;N:static[int];U,V,W:static[string]]#[7]#=concept u
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
  AutoUSi3*[T;N:static[int];U,V,W,X:static[string]]#[15]#=concept u
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
  AutoUSi4*[T;N:static[int];U,V,W,X,Y:static[string]]#[30]#=concept u
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
  AutoUSi5*[T;N:static[int];U,V,W,X,Y,Z:static[string]]#[33]#=concept u
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
  AutoUSi6*[T;N:static[int];U,V,W,X,Y,Z,A:static[string]]#[23]#=concept u
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
  AutoUSi7*[T;N:static[int];U,V,W,X,Y,Z,A,B:static[string]]#[4]#=concept u
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



