from macros import newTree,nnkBracketExpr,add,
  len,`[]`,quote,newIdentNode,error,items,
  kind,nnkInfix,eqIdent,newStmtList,newDotExpr,ident,
  nnkIntLit,nnkFloatLit,toStrLit,newStrLitNode,nnkPar
from algorithm import reverse
from strutils import contains,parseInt,parseFloat,replace,split

from core import formatUnit,strSimpleSiUnit,Unit,mulUnit,divUnit,powUnit,floatToFraction,simplifyFrac


proc tostr(t:NimNode):NimNode=
  if t.kind==nnkIntLit:
    toStrLit t
  elif t.kind==nnkFloatLit:
    toStrLit t
  elif t.kind==nnkPar:
    toStrLit t
  else:t

macro wisUSi*(T,args):untyped=
  #解决单独USi无法处理U*"m"类型,即设计泛型U的计算
  runnableExamples:
    const g = 9.80665~meter/second^2
    let height = 100.0~meter
    proc getTime[T;U:static[string]](h:Unit[T,U],g:wisUSi(T,U/"s^2")):USi[T,"s"]=sqrt T(2)*h/g
    let fallTime = getTime(height,g)
    #And More
    const g = 9.80665~meter/second^2
    let height = 100.0~meter
    proc getTime[T;U:static[string]](h:Unit[T,U],g:wisUSi(T,U/"s"^2)):USi[T,"s"]=sqrt T(2)*h/g
    let fallTime = getTime(height,g)
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
      if divFlag:
        seq2.add u[2]
      else:
        seq1.add u[2]
    elif eqIdent(u[0],"^"):
      break
    else:
      error "syntax error"
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
  var later=newStmtList(T)
  if mlen>=10 or mlen<0 or dlen>=10 or dlen<0:
    error "syntax error"
  var
    len=0
    i=1
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
    of 0:
      later.add newDotExpr(ident"USimode",ident"n")
      later.add mulSeq[0]
      len=1
    of 1:
      later.add newDotExpr(ident"USimode",ident"p")
      later.add mulSeq[0][1]
      later.add mulSeq[0][2]
      len=2
    else:
      error"syntax error"
  of 20:                                                            # m pm mp pmp
    case len:
    of 0:
      later.add newDotExpr(ident"USimode",ident"m")
      later.add mulSeq[0]
      later.add mulSeq[1]
      len=2
    of 1:
      later.add newDotExpr(ident"USimode",ident"pm")
      later.add mulSeq[0][1]
      later.add mulSeq[0][2]
      later.add mulSeq[1]
      len=3
    of 2:
      later.add newDotExpr(ident"USimode",ident"mp")
      later.add mulSeq[0]
      later.add mulSeq[1][1]
      later.add mulSeq[1][2]
      len=3
    of 3:
      later.add newDotExpr(ident"USimode",ident"pmp")
      later.add mulSeq[0][1]
      later.add mulSeq[0][2]
      later.add mulSeq[1][1]
      later.add mulSeq[1][2]
      len=4
    else:
      error "syntax error"
  of 11:                                                            # d pd dp pdp
    case len:
    of 0:
      later.add newDotExpr(ident"USimode",ident"d")
      later.add mulSeq[0]
      later.add mulSeq[1]
      len=2
    of 1:
      later.add newDotExpr(ident"USimode",ident"pd")
      later.add mulSeq[0][1]
      later.add mulSeq[0][2]
      later.add mulSeq[1]
      len=3
    of 2:
      later.add newDotExpr(ident"USimode",ident"dp")
      later.add mulSeq[0]
      later.add mulSeq[1][1]
      later.add mulSeq[1][2]
      len=3
    of 3:
      later.add newDotExpr(ident"USimode",ident"pdp")
      later.add mulSeq[0][1]
      later.add mulSeq[0][2]
      later.add mulSeq[1][1]
      later.add mulSeq[1][2]
      len=4
    else:
      error "syntax error"
  of 30:                                                            # mm pmm mpm pmpm mmp pmmp mpmp pmpmp
    case len:
    of 0:
      later.add newDotExpr(ident"USimode",ident"mm")
      later.add mulSeq[0]
      later.add mulSeq[1]
      later.add mulSeq[2]
      len=3
    of 1:
      later.add newDotExpr(ident"USimode",ident"pmm")
      later.add mulSeq[0][1]
      later.add mulSeq[0][2]
      later.add mulSeq[1]
      later.add mulSeq[2]
      len=4
    of 2:
      later.add newDotExpr(ident"USimode",ident"mpm")
      later.add mulSeq[0]
      later.add mulSeq[1][1]
      later.add mulSeq[1][2]
      later.add mulSeq[2]
      len=4
    of 3:
      later.add newDotExpr(ident"USimode",ident"pmpm")
      later.add mulSeq[0][1]
      later.add mulSeq[0][2]
      later.add mulSeq[1][1]
      later.add mulSeq[1][2]
      later.add mulSeq[2]
      len=5
    of 4:
      later.add newDotExpr(ident"USimode",ident"mmp")
      later.add mulSeq[0]
      later.add mulSeq[1]
      later.add mulSeq[2][1]
      later.add mulSeq[2][2]
      len=4
    of 5:
      later.add newDotExpr(ident"USimode",ident"pmmp")
      later.add mulSeq[0][1]
      later.add mulSeq[0][2]
      later.add mulSeq[1]
      later.add mulSeq[2][1]
      later.add mulSeq[2][2]
      len=5
    of 6:
      later.add newDotExpr(ident"USimode",ident"mpmp")
      later.add mulSeq[0]
      later.add mulSeq[1][1]
      later.add mulSeq[1][2]
      later.add mulSeq[2][1]
      later.add mulSeq[2][2]
      len=5
    of 7:
      later.add newDotExpr(ident"USimode",ident"pmpmp")
      later.add mulSeq[0][1]
      later.add mulSeq[0][2]
      later.add mulSeq[1][1]
      later.add mulSeq[1][2]
      later.add mulSeq[2][1]
      later.add mulSeq[2][2]
      len=6
    else:
      error "syntax error"
  of 21:                                                            # md pmd mpd pmpd mdp pmdp mpdp pmpdp
    case len:
    of 0:
      later.add newDotExpr(ident"USimode",ident"md")
      later.add mulSeq[0]
      later.add mulSeq[1]
      later.add mulSeq[2]
      len=3
    of 1:
      later.add newDotExpr(ident"USimode",ident"pmd")
      later.add mulSeq[0][1]
      later.add mulSeq[0][2]
      later.add mulSeq[1]
      later.add mulSeq[2]
      len=4
    of 2:
      later.add newDotExpr(ident"USimode",ident"mpd")
      later.add mulSeq[0]
      later.add mulSeq[1][1]
      later.add mulSeq[1][2]
      later.add mulSeq[2]
      len=4
    of 3:
      later.add newDotExpr(ident"USimode",ident"pmpd")
      later.add mulSeq[0][1]
      later.add mulSeq[0][2]
      later.add mulSeq[1][1]
      later.add mulSeq[1][2]
      later.add mulSeq[2]
      len=5
    of 4:
      later.add newDotExpr(ident"USimode",ident"mdp")
      later.add mulSeq[0]
      later.add mulSeq[1]
      later.add mulSeq[2][1]
      later.add mulSeq[2][2]
      len=4
    of 5:
      later.add newDotExpr(ident"USimode",ident"pmdp")
      later.add mulSeq[0][1]
      later.add mulSeq[0][2]
      later.add mulSeq[1]
      later.add mulSeq[2][1]
      later.add mulSeq[2][2]
      len=5
    of 6:
      later.add newDotExpr(ident"USimode",ident"mpdp")
      later.add mulSeq[0]
      later.add mulSeq[1][1]
      later.add mulSeq[1][2]
      later.add mulSeq[2][1]
      later.add mulSeq[2][2]
      len=5
    of 7:
      later.add newDotExpr(ident"USimode",ident"pmpdp")
      later.add mulSeq[0][1]
      later.add mulSeq[0][2]
      later.add mulSeq[1][1]
      later.add mulSeq[1][2]
      later.add mulSeq[2][1]
      later.add mulSeq[2][2]
      len=6
    else:
      error "syntax error"
  of 12:                                                            # dd pdd dpd pdpd ddp pddp dpdp pdpdp
    case len:
    of 0:
      later.add newDotExpr(ident"USimode",ident"dd")
      later.add mulSeq[0]
      later.add mulSeq[1]
      later.add mulSeq[2]
      len=3
    of 1:
      later.add newDotExpr(ident"USimode",ident"pdd")
      later.add mulSeq[0][1]
      later.add mulSeq[0][2]
      later.add mulSeq[1]
      later.add mulSeq[2]
      len=4
    of 2:
      later.add newDotExpr(ident"USimode",ident"dpd")
      later.add mulSeq[0]
      later.add mulSeq[1][1]
      later.add mulSeq[1][2]
      later.add mulSeq[2]
      len=4
    of 3:
      later.add newDotExpr(ident"USimode",ident"pdpd")
      later.add mulSeq[0][1]
      later.add mulSeq[0][2]
      later.add mulSeq[1][1]
      later.add mulSeq[1][2]
      later.add mulSeq[2]
      len=5
    of 4:
      later.add newDotExpr(ident"USimode",ident"ddp")
      later.add mulSeq[0]
      later.add mulSeq[1]
      later.add mulSeq[2][1]
      later.add mulSeq[2][2]
      len=4
    of 5:
      later.add newDotExpr(ident"USimode",ident"pddp")
      later.add mulSeq[0][1]
      later.add mulSeq[0][2]
      later.add mulSeq[1]
      later.add mulSeq[2][1]
      later.add mulSeq[2][2]
      len=5
    of 6:
      later.add newDotExpr(ident"USimode",ident"dpdp")
      later.add mulSeq[0]
      later.add mulSeq[1][1]
      later.add mulSeq[1][2]
      later.add mulSeq[2][1]
      later.add mulSeq[2][2]
      len=5
    of 7:
      later.add newDotExpr(ident"USimode",ident"pdpdp")
      later.add mulSeq[0][1]
      later.add mulSeq[0][2]
      later.add mulSeq[1][1]
      later.add mulSeq[1][2]
      later.add mulSeq[2][1]
      later.add mulSeq[2][2]
      len=6
    else:
      error "syntax error"
  of 40:                                                            # mmm pmmm mpmm pmpmm mmpm pmmpm mpmpm pmpmpm
                                                                    # mmmp pmmmp mpmmp pmpmmp mmpmp pmmpmp mpmpmp pmpmpmp
    case len:
    of 0:
      later.add newDotExpr(ident"USimode",ident"mmm")
      later.add mulSeq[0]
      later.add mulSeq[1]
      later.add mulSeq[2]
      later.add mulSeq[3]
      len=4
    of 1:
      later.add newDotExpr(ident"USimode",ident"pmmm")
      later.add mulSeq[0][1]
      later.add mulSeq[0][2]
      later.add mulSeq[1]
      later.add mulSeq[2]
      later.add mulSeq[3]
      len=5
    of 2:
      later.add newDotExpr(ident"USimode",ident"mpmm")
      later.add mulSeq[0]
      later.add mulSeq[1][1]
      later.add mulSeq[1][2]
      later.add mulSeq[2]
      later.add mulSeq[3]
      len=5
    of 3:
      later.add newDotExpr(ident"USimode",ident"pmpmm")
      later.add mulSeq[0][1]
      later.add mulSeq[0][2]
      later.add mulSeq[1][1]
      later.add mulSeq[1][2]
      later.add mulSeq[2]
      later.add mulSeq[3]
      len=6
    of 4:
      later.add newDotExpr(ident"USimode",ident"mmpm")
      later.add mulSeq[0]
      later.add mulSeq[1]
      later.add mulSeq[2][1]
      later.add mulSeq[2][2]
      later.add mulSeq[3]
      len=5
    of 5:
      later.add newDotExpr(ident"USimode",ident"pmmpm")
      later.add mulSeq[0][1]
      later.add mulSeq[0][2]
      later.add mulSeq[1]
      later.add mulSeq[2][1]
      later.add mulSeq[2][2]
      later.add mulSeq[3]
      len=6
    of 6:
      later.add newDotExpr(ident"USimode",ident"mpmpm")
      later.add mulSeq[0]
      later.add mulSeq[1][1]
      later.add mulSeq[1][2]
      later.add mulSeq[2][1]
      later.add mulSeq[2][2]
      later.add mulSeq[3]
      len=6
    of 7:
      later.add newDotExpr(ident"USimode",ident"pmpmpm")
      later.add mulSeq[0][1]
      later.add mulSeq[0][2]
      later.add mulSeq[1][1]
      later.add mulSeq[1][2]
      later.add mulSeq[2][1]
      later.add mulSeq[2][2]
      later.add mulSeq[3]
      len=7
    of 8:
      later.add newDotExpr(ident"USimode",ident"mmmp")
      later.add mulSeq[0]
      later.add mulSeq[1]
      later.add mulSeq[2]
      later.add mulSeq[3][1]
      later.add mulSeq[3][2]
      len=5
    of 9:
      later.add newDotExpr(ident"USimode",ident"pmmmp")
      later.add mulSeq[0][1]
      later.add mulSeq[0][2]
      later.add mulSeq[1]
      later.add mulSeq[2]
      later.add mulSeq[3][1]
      later.add mulSeq[3][2]
      len=6
    of 10:
      later.add newDotExpr(ident"USimode",ident"mpmmp")
      later.add mulSeq[0]
      later.add mulSeq[1][1]
      later.add mulSeq[1][2]
      later.add mulSeq[2]
      later.add mulSeq[3][1]
      later.add mulSeq[3][2]
      len=6
    of 11:
      later.add newDotExpr(ident"USimode",ident"pmpmmp")
      later.add mulSeq[0][1]
      later.add mulSeq[0][2]
      later.add mulSeq[1][1]
      later.add mulSeq[1][2]
      later.add mulSeq[2]
      later.add mulSeq[3][1]
      later.add mulSeq[3][2]
      len=7
    of 12:
      later.add newDotExpr(ident"USimode",ident"mmpmp")
      later.add mulSeq[0]
      later.add mulSeq[1]
      later.add mulSeq[2][1]
      later.add mulSeq[2][2]
      later.add mulSeq[3][1]
      later.add mulSeq[3][2]
      len=6
    of 13:
      later.add newDotExpr(ident"USimode",ident"pmmpmp")
      later.add mulSeq[0][1]
      later.add mulSeq[0][2]
      later.add mulSeq[1]
      later.add mulSeq[2][1]
      later.add mulSeq[2][2]
      later.add mulSeq[3][1]
      later.add mulSeq[3][2]
      len=7
    of 14:
      later.add newDotExpr(ident"USimode",ident"mpmpmp")
      later.add mulSeq[0]
      later.add mulSeq[1][1]
      later.add mulSeq[1][2]
      later.add mulSeq[2][1]
      later.add mulSeq[2][2]
      later.add mulSeq[3][1]
      later.add mulSeq[3][2]
      len=7
    of 15:
      later.add newDotExpr(ident"USimode",ident"pmpmpmp")
      later.add mulSeq[0][1]
      later.add mulSeq[0][2]
      later.add mulSeq[1][1]
      later.add mulSeq[1][2]
      later.add mulSeq[2][1]
      later.add mulSeq[2][2]
      later.add mulSeq[3][1]
      later.add mulSeq[3][2]
      len=8
    else:
      error "syntax error"
  of 31:                                                            # mmd pmmd mpmd pmpmd mmpd pmmpd mpmpd pmpmpd
                                                                    # mmdp pmmdp mpmdp pmpmdp mmpdp pmmpdp mpmpdp pmpmpdp
    case len:
    of 0:
      later.add newDotExpr(ident"USimode",ident"mmd")
      later.add mulSeq[0]
      later.add mulSeq[1]
      later.add mulSeq[2]
      later.add mulSeq[3]
      len=4
    of 1:
      later.add newDotExpr(ident"USimode",ident"pmmd")
      later.add mulSeq[0][1]
      later.add mulSeq[0][2]
      later.add mulSeq[1]
      later.add mulSeq[2]
      later.add mulSeq[3]
      len=5
    of 2:
      later.add newDotExpr(ident"USimode",ident"mpmd")
      later.add mulSeq[0]
      later.add mulSeq[1][1]
      later.add mulSeq[1][2]
      later.add mulSeq[2]
      later.add mulSeq[3]
      len=5
    of 3:
      later.add newDotExpr(ident"USimode",ident"pmpmd")
      later.add mulSeq[0][1]
      later.add mulSeq[0][2]
      later.add mulSeq[1][1]
      later.add mulSeq[1][2]
      later.add mulSeq[2]
      later.add mulSeq[3]
      len=6
    of 4:
      later.add newDotExpr(ident"USimode",ident"mmpd")
      later.add mulSeq[0]
      later.add mulSeq[1]
      later.add mulSeq[2][1]
      later.add mulSeq[2][2]
      later.add mulSeq[3]
      len=5
    of 5:
      later.add newDotExpr(ident"USimode",ident"pmmpd")
      later.add mulSeq[0][1]
      later.add mulSeq[0][2]
      later.add mulSeq[1]
      later.add mulSeq[2][1]
      later.add mulSeq[2][2]
      later.add mulSeq[3]
      len=6
    of 6:
      later.add newDotExpr(ident"USimode",ident"mpmpd")
      later.add mulSeq[0]
      later.add mulSeq[1][1]
      later.add mulSeq[1][2]
      later.add mulSeq[2][1]
      later.add mulSeq[2][2]
      later.add mulSeq[3]
      len=6
    of 7:
      later.add newDotExpr(ident"USimode",ident"pmpmpd")
      later.add mulSeq[0][1]
      later.add mulSeq[0][2]
      later.add mulSeq[1][1]
      later.add mulSeq[1][2]
      later.add mulSeq[2][1]
      later.add mulSeq[2][2]
      later.add mulSeq[3]
      len=7
    of 8:
      later.add newDotExpr(ident"USimode",ident"mmdp")
      later.add mulSeq[0]
      later.add mulSeq[1]
      later.add mulSeq[2]
      later.add mulSeq[3][1]
      later.add mulSeq[3][2]
      len=5
    of 9:
      later.add newDotExpr(ident"USimode",ident"pmmdp")
      later.add mulSeq[0][1]
      later.add mulSeq[0][2]
      later.add mulSeq[1]
      later.add mulSeq[2]
      later.add mulSeq[3][1]
      later.add mulSeq[3][2]
      len=6
    of 10:
      later.add newDotExpr(ident"USimode",ident"mpmdp")
      later.add mulSeq[0]
      later.add mulSeq[1][1]
      later.add mulSeq[1][2]
      later.add mulSeq[2]
      later.add mulSeq[3][1]
      later.add mulSeq[3][2]
      len=6
    of 11:
      later.add newDotExpr(ident"USimode",ident"pmpmdp")
      later.add mulSeq[0][1]
      later.add mulSeq[0][2]
      later.add mulSeq[1][1]
      later.add mulSeq[1][2]
      later.add mulSeq[2]
      later.add mulSeq[3][1]
      later.add mulSeq[3][2]
      len=7
    of 12:
      later.add newDotExpr(ident"USimode",ident"mmpdp")
      later.add mulSeq[0]
      later.add mulSeq[1]
      later.add mulSeq[2][1]
      later.add mulSeq[2][2]
      later.add mulSeq[3][1]
      later.add mulSeq[3][2]
      len=6
    of 13:
      later.add newDotExpr(ident"USimode",ident"pmmpdp")
      later.add mulSeq[0][1]
      later.add mulSeq[0][2]
      later.add mulSeq[1]
      later.add mulSeq[2][1]
      later.add mulSeq[2][2]
      later.add mulSeq[3][1]
      later.add mulSeq[3][2]
      len=7
    of 14:
      later.add newDotExpr(ident"USimode",ident"mpmpdp")
      later.add mulSeq[0]
      later.add mulSeq[1][1]
      later.add mulSeq[1][2]
      later.add mulSeq[2][1]
      later.add mulSeq[2][2]
      later.add mulSeq[3][1]
      later.add mulSeq[3][2]
      len=7
    of 15:
      later.add newDotExpr(ident"USimode",ident"pmpmpdp")
      later.add mulSeq[0][1]
      later.add mulSeq[0][2]
      later.add mulSeq[1][1]
      later.add mulSeq[1][2]
      later.add mulSeq[2][1]
      later.add mulSeq[2][2]
      later.add mulSeq[3][1]
      later.add mulSeq[3][2]
      len=8
    else:
      error "syntax error"
  of 22:                                                            # mdd pmdd mpdd pmpdd mdpd pmdpd mpdpd pmpdpd
                                                                    # mddp pmddp mpddp pmpddp mdpdp pmdpdp mpdpdp pmpdpdp
    case len:
    of 0:
      later.add newDotExpr(ident"USimode",ident"mdd")
      later.add mulSeq[0]
      later.add mulSeq[1]
      later.add mulSeq[2]
      later.add mulSeq[3]
      len=4
    of 1:
      later.add newDotExpr(ident"USimode",ident"pmdd")
      later.add mulSeq[0][1]
      later.add mulSeq[0][2]
      later.add mulSeq[1]
      later.add mulSeq[2]
      later.add mulSeq[3]
      len=5
    of 2:
      later.add newDotExpr(ident"USimode",ident"mpdd")
      later.add mulSeq[0]
      later.add mulSeq[1][1]
      later.add mulSeq[1][2]
      later.add mulSeq[2]
      later.add mulSeq[3]
      len=5
    of 3:
      later.add newDotExpr(ident"USimode",ident"pmpdd")
      later.add mulSeq[0][1]
      later.add mulSeq[0][2]
      later.add mulSeq[1][1]
      later.add mulSeq[1][2]
      later.add mulSeq[2]
      later.add mulSeq[3]
      len=6
    of 4:
      later.add newDotExpr(ident"USimode",ident"mdpd")
      later.add mulSeq[0]
      later.add mulSeq[1]
      later.add mulSeq[2][1]
      later.add mulSeq[2][2]
      later.add mulSeq[3]
      len=5
    of 5:
      later.add newDotExpr(ident"USimode",ident"pmdpd")
      later.add mulSeq[0][1]
      later.add mulSeq[0][2]
      later.add mulSeq[1]
      later.add mulSeq[2][1]
      later.add mulSeq[2][2]
      later.add mulSeq[3]
      len=6
    of 6:
      later.add newDotExpr(ident"USimode",ident"mpdpd")
      later.add mulSeq[0]
      later.add mulSeq[1][1]
      later.add mulSeq[1][2]
      later.add mulSeq[2][1]
      later.add mulSeq[2][2]
      later.add mulSeq[3]
      len=6
    of 7:
      later.add newDotExpr(ident"USimode",ident"pmpdpd")
      later.add mulSeq[0][1]
      later.add mulSeq[0][2]
      later.add mulSeq[1][1]
      later.add mulSeq[1][2]
      later.add mulSeq[2][1]
      later.add mulSeq[2][2]
      later.add mulSeq[3]
      len=7
    of 8:
      later.add newDotExpr(ident"USimode",ident"mddp")
      later.add mulSeq[0]
      later.add mulSeq[1]
      later.add mulSeq[2]
      later.add mulSeq[3][1]
      later.add mulSeq[3][2]
      len=5
    of 9:
      later.add newDotExpr(ident"USimode",ident"pmddp")
      later.add mulSeq[0][1]
      later.add mulSeq[0][2]
      later.add mulSeq[1]
      later.add mulSeq[2]
      later.add mulSeq[3][1]
      later.add mulSeq[3][2]
      len=6
    of 10:
      later.add newDotExpr(ident"USimode",ident"mpddp")
      later.add mulSeq[0]
      later.add mulSeq[1][1]
      later.add mulSeq[1][2]
      later.add mulSeq[2]
      later.add mulSeq[3][1]
      later.add mulSeq[3][2]
      len=6
    of 11:
      later.add newDotExpr(ident"USimode",ident"pmpddp")
      later.add mulSeq[0][1]
      later.add mulSeq[0][2]
      later.add mulSeq[1][1]
      later.add mulSeq[1][2]
      later.add mulSeq[2]
      later.add mulSeq[3][1]
      later.add mulSeq[3][2]
      len=7
    of 12:
      later.add newDotExpr(ident"USimode",ident"mdpdp")
      later.add mulSeq[0]
      later.add mulSeq[1]
      later.add mulSeq[2][1]
      later.add mulSeq[2][2]
      later.add mulSeq[3][1]
      later.add mulSeq[3][2]
      len=6
    of 13:
      later.add newDotExpr(ident"USimode",ident"pmdpdp")
      later.add mulSeq[0][1]
      later.add mulSeq[0][2]
      later.add mulSeq[1]
      later.add mulSeq[2][1]
      later.add mulSeq[2][2]
      later.add mulSeq[3][1]
      later.add mulSeq[3][2]
      len=7
    of 14:
      later.add newDotExpr(ident"USimode",ident"mpdpdp")
      later.add mulSeq[0]
      later.add mulSeq[1][1]
      later.add mulSeq[1][2]
      later.add mulSeq[2][1]
      later.add mulSeq[2][2]
      later.add mulSeq[3][1]
      later.add mulSeq[3][2]
      len=7
    of 15:
      later.add newDotExpr(ident"USimode",ident"pmpdpdp")
      later.add mulSeq[0][1]
      later.add mulSeq[0][2]
      later.add mulSeq[1][1]
      later.add mulSeq[1][2]
      later.add mulSeq[2][1]
      later.add mulSeq[2][2]
      later.add mulSeq[3][1]
      later.add mulSeq[3][2]
      len=8
    else:
      error "syntax error"
  of 13:                                                            # ddd pddd dpdd pdpdd ddpd pddpd dpdpd pdpdpd
                                                                    # dddp pdddp dpddp pdpddp ddpdp pddpdp dpdpdp pdpdpdp
    case len:
    of 0:
      later.add newDotExpr(ident"USimode",ident"ddd")
      later.add mulSeq[0]
      later.add mulSeq[1]
      later.add mulSeq[2]
      later.add mulSeq[3]
      len=4
    of 1:
      later.add newDotExpr(ident"USimode",ident"pddd")
      later.add mulSeq[0][1]
      later.add mulSeq[0][2]
      later.add mulSeq[1]
      later.add mulSeq[2]
      later.add mulSeq[3]
      len=5
    of 2:
      later.add newDotExpr(ident"USimode",ident"dpdd")
      later.add mulSeq[0]
      later.add mulSeq[1][1]
      later.add mulSeq[1][2]
      later.add mulSeq[2]
      later.add mulSeq[3]
      len=5
    of 3:
      later.add newDotExpr(ident"USimode",ident"pdpdd")
      later.add mulSeq[0][1]
      later.add mulSeq[0][2]
      later.add mulSeq[1][1]
      later.add mulSeq[1][2]
      later.add mulSeq[2]
      later.add mulSeq[3]
      len=6
    of 4:
      later.add newDotExpr(ident"USimode",ident"ddpd")
      later.add mulSeq[0]
      later.add mulSeq[1]
      later.add mulSeq[2][1]
      later.add mulSeq[2][2]
      later.add mulSeq[3]
      len=5
    of 5:
      later.add newDotExpr(ident"USimode",ident"pddpd")
      later.add mulSeq[0][1]
      later.add mulSeq[0][2]
      later.add mulSeq[1]
      later.add mulSeq[2][1]
      later.add mulSeq[2][2]
      later.add mulSeq[3]
      len=6
    of 6:
      later.add newDotExpr(ident"USimode",ident"dpdpd")
      later.add mulSeq[0]
      later.add mulSeq[1][1]
      later.add mulSeq[1][2]
      later.add mulSeq[2][1]
      later.add mulSeq[2][2]
      later.add mulSeq[3]
      len=6
    of 7:
      later.add newDotExpr(ident"USimode",ident"pdpdpd")
      later.add mulSeq[0][1]
      later.add mulSeq[0][2]
      later.add mulSeq[1][1]
      later.add mulSeq[1][2]
      later.add mulSeq[2][1]
      later.add mulSeq[2][2]
      later.add mulSeq[3]
      len=7
    of 8:
      later.add newDotExpr(ident"USimode",ident"dddp")
      later.add mulSeq[0]
      later.add mulSeq[1]
      later.add mulSeq[2]
      later.add mulSeq[3][1]
      later.add mulSeq[3][2]
      len=5
    of 9:
      later.add newDotExpr(ident"USimode",ident"pdddp")
      later.add mulSeq[0][1]
      later.add mulSeq[0][2]
      later.add mulSeq[1]
      later.add mulSeq[2]
      later.add mulSeq[3][1]
      later.add mulSeq[3][2]
      len=6
    of 10:
      later.add newDotExpr(ident"USimode",ident"dpddp")
      later.add mulSeq[0]
      later.add mulSeq[1][1]
      later.add mulSeq[1][2]
      later.add mulSeq[2]
      later.add mulSeq[3][1]
      later.add mulSeq[3][2]
      len=6
    of 11:
      later.add newDotExpr(ident"USimode",ident"pdpddp")
      later.add mulSeq[0][1]
      later.add mulSeq[0][2]
      later.add mulSeq[1][1]
      later.add mulSeq[1][2]
      later.add mulSeq[2]
      later.add mulSeq[3][1]
      later.add mulSeq[3][2]
      len=7
    of 12:
      later.add newDotExpr(ident"USimode",ident"ddpdp")
      later.add mulSeq[0]
      later.add mulSeq[1]
      later.add mulSeq[2][1]
      later.add mulSeq[2][2]
      later.add mulSeq[3][1]
      later.add mulSeq[3][2]
      len=6
    of 13:
      later.add newDotExpr(ident"USimode",ident"pddpdp")
      later.add mulSeq[0][1]
      later.add mulSeq[0][2]
      later.add mulSeq[1]
      later.add mulSeq[2][1]
      later.add mulSeq[2][2]
      later.add mulSeq[3][1]
      later.add mulSeq[3][2]
      len=7
    of 14:
      later.add newDotExpr(ident"USimode",ident"dpdpdp")
      later.add mulSeq[0]
      later.add mulSeq[1][1]
      later.add mulSeq[1][2]
      later.add mulSeq[2][1]
      later.add mulSeq[2][2]
      later.add mulSeq[3][1]
      later.add mulSeq[3][2]
      len=7
    of 15:
      later.add newDotExpr(ident"USimode",ident"pdpdpdp")
      later.add mulSeq[0][1]
      later.add mulSeq[0][2]
      later.add mulSeq[1][1]
      later.add mulSeq[1][2]
      later.add mulSeq[2][1]
      later.add mulSeq[2][2]
      later.add mulSeq[3][1]
      later.add mulSeq[3][2]
      len=8
    else:
      error "syntax error"
  of 50:
    case len:
    of 0:
      later.add newDotExpr(ident"USimode",ident"mmmm")
      later.add mulSeq[0]
      later.add mulSeq[1]
      later.add mulSeq[2]
      later.add mulSeq[3]
      later.add mulSeq[4]
      len=5
    else:
      error "syntax error"
  of 41:
    case len:
    of 0:
      later.add newDotExpr(ident"USimode",ident"mmmd")
      later.add mulSeq[0]
      later.add mulSeq[1]
      later.add mulSeq[2]
      later.add mulSeq[3]
      later.add mulSeq[4]
      len=5
    else:
      error "syntax error"
  of 32:
    case len:
    of 0:
      later.add newDotExpr(ident"USimode",ident"mmdd")
      later.add mulSeq[0]
      later.add mulSeq[1]
      later.add mulSeq[2]
      later.add mulSeq[3]
      later.add mulSeq[4]
      len=5
    else:
      error "syntax error"
  of 23:
    case len:
    of 0:
      later.add newDotExpr(ident"USimode",ident"mddd")
      later.add mulSeq[0]
      later.add mulSeq[1]
      later.add mulSeq[2]
      later.add mulSeq[3]
      later.add mulSeq[4]
      len=5
    else:
      error "syntax error"
  of 14:
    case len:
    of 0:
      later.add newDotExpr(ident"USimode",ident"dddd")
      later.add mulSeq[0]
      later.add mulSeq[1]
      later.add mulSeq[2]
      later.add mulSeq[3]
      later.add mulSeq[4]
      len=5
    else:
      error "syntax error"
  of 60:
    case len:
    of 0:
      later.add newDotExpr(ident"USimode",ident"mmmmm")
      later.add mulSeq[0]
      later.add mulSeq[1]
      later.add mulSeq[2]
      later.add mulSeq[3]
      later.add mulSeq[4]
      later.add mulSeq[5]
      len=6
    else:
      error "syntax error"
  of 51:
    case len:
    of 0:
      later.add newDotExpr(ident"USimode",ident"mmmmd")
      later.add mulSeq[0]
      later.add mulSeq[1]
      later.add mulSeq[2]
      later.add mulSeq[3]
      later.add mulSeq[4]
      later.add mulSeq[5]
      len=6
    else:
      error "syntax error"
  of 42:
    case len:
    of 0:
      later.add newDotExpr(ident"USimode",ident"mmmdd")
      later.add mulSeq[0]
      later.add mulSeq[1]
      later.add mulSeq[2]
      later.add mulSeq[3]
      later.add mulSeq[4]
      later.add mulSeq[5]
      len=6
    else:
      error "syntax error"
  of 33:
    case len:
    of 0:
      later.add newDotExpr(ident"USimode",ident"mmddd")
      later.add mulSeq[0]
      later.add mulSeq[1]
      later.add mulSeq[2]
      later.add mulSeq[3]
      later.add mulSeq[4]
      later.add mulSeq[5]
      len=6
    else:
      error "syntax error"
  of 24:
    case len:
    of 0:
      later.add newDotExpr(ident"USimode",ident"mdddd")
      later.add mulSeq[0]
      later.add mulSeq[1]
      later.add mulSeq[2]
      later.add mulSeq[3]
      later.add mulSeq[4]
      later.add mulSeq[5]
      len=6
    else:
      error "syntax error"
  of 15:
    case len:
    of 0:
      later.add newDotExpr(ident"USimode",ident"ddddd")
      later.add mulSeq[0]
      later.add mulSeq[1]
      later.add mulSeq[2]
      later.add mulSeq[3]
      later.add mulSeq[4]
      later.add mulSeq[5]
      len=6
    else:
      error "syntax error"
  of 70:
    case len:
    of 0:
      later.add newDotExpr(ident"USimode",ident"mmmmmm")
      later.add mulSeq[0]
      later.add mulSeq[1]
      later.add mulSeq[2]
      later.add mulSeq[3]
      later.add mulSeq[4]
      later.add mulSeq[5]
      later.add mulSeq[6]
      len=7
    else:
      error "syntax error"
  of 61:
    case len:
    of 0:
      later.add newDotExpr(ident"USimode",ident"mmmmmd")
      later.add mulSeq[0]
      later.add mulSeq[1]
      later.add mulSeq[2]
      later.add mulSeq[3]
      later.add mulSeq[4]
      later.add mulSeq[5]
      later.add mulSeq[6]
      len=7
    else:
      error "syntax error"
  of 52:
    case len:
    of 0:
      later.add newDotExpr(ident"USimode",ident"mmmmdd")
      later.add mulSeq[0]
      later.add mulSeq[1]
      later.add mulSeq[2]
      later.add mulSeq[3]
      later.add mulSeq[4]
      later.add mulSeq[5]
      later.add mulSeq[6]
      len=7
    else:
      error "syntax error"
  of 43:
    case len:
    of 0:
      later.add newDotExpr(ident"USimode",ident"mmmddd")
      later.add mulSeq[0]
      later.add mulSeq[1]
      later.add mulSeq[2]
      later.add mulSeq[3]
      later.add mulSeq[4]
      later.add mulSeq[5]
      later.add mulSeq[6]
      len=7
    else:
      error "syntax error"
  of 34:
    case len:
    of 0:
      later.add newDotExpr(ident"USimode",ident"mmdddd")
      later.add mulSeq[0]
      later.add mulSeq[1]
      later.add mulSeq[2]
      later.add mulSeq[3]
      later.add mulSeq[4]
      later.add mulSeq[5]
      later.add mulSeq[6]
      len=7
    else:
      error "syntax error"
  of 25:
    case len:
    of 0:
      later.add newDotExpr(ident"USimode",ident"mddddd")
      later.add mulSeq[0]
      later.add mulSeq[1]
      later.add mulSeq[2]
      later.add mulSeq[3]
      later.add mulSeq[4]
      later.add mulSeq[5]
      later.add mulSeq[6]
      len=7
    else:
      error "syntax error"
  of 16:
    case len:
    of 0:
      later.add newDotExpr(ident"USimode",ident"dddddd")
      later.add mulSeq[0]
      later.add mulSeq[1]
      later.add mulSeq[2]
      later.add mulSeq[3]
      later.add mulSeq[4]
      later.add mulSeq[5]
      later.add mulSeq[6]
      len=7
    else:
      error "syntax error"
  else:
    error "syntax error"
  result=
    case len:
    of 1:newTree(nnkBracketExpr,ident"AutoUSi0")
    of 2:newTree(nnkBracketExpr,ident"AutoUSi1")
    of 3:newTree(nnkBracketExpr,ident"AutoUSi2")
    of 4:newTree(nnkBracketExpr,ident"AutoUSi3")
    of 5:newTree(nnkBracketExpr,ident"AutoUSi4")
    of 6:newTree(nnkBracketExpr,ident"AutoUSi5")
    of 7:newTree(nnkBracketExpr,ident"AutoUSi6")
    of 8:newTree(nnkBracketExpr,ident"AutoUSi7")
    else:error "syntax error"
  for t in later:
    result.add t.tostr




type USimode*{.pure.}=enum
  n
  m d
  mm md dd
  mmm mmd mdd ddd
  mmmm mmmd mmdd mddd dddd
  mmmmm mmmmd mmmdd mmddd mdddd ddddd
  mmmmmm mmmmmd mmmmdd mmmddd mmdddd mddddd dddddd   # 1+2+..7=28
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
  pmpmpmp pmpmpdp pmpdpdp pdpdpdp                     # 4*5=20
                                                      # all=116



func toTuple(s:static[string]):static[(int,int)]=
  let N=s.replace(" ","").replace("(","").replace(")","")
  if N.contains".":
    floatToFraction N.parseFloat
  elif N.contains"/":
    let p=N.split"/"
    simplifyFrac (p[0].parseInt,p[1].parseInt)
  else:
    simplifyFrac (N.parseInt,1)

type AutoUSi0*[T;N:static[USimode];U:static[string]]=concept u
  u is Unit
  u.T is T
  const ut=
    when N==USimode.n: U.formatUnit
    else:""
  when ut!=u.U:
    const usiU =strSimpleSiUnit ut
    const siU = strSimpleSiUnit u.U
    usiU==siU
type AutoUSi1*[T;N:static[USimode];U,V:static[string]]=concept u
  u is Unit
  u.T is T
  const ut=
    when N==USimode.m: U.formatUnit.mulUnit(V.formatUnit)
    elif N==USimode.d: U.formatUnit.divUnit(V.formatUnit)
    # 幂操作基础系列 (1+6+21+16=44种)
    elif N==USimode.p: U.formatUnit.powUnit(V.toTuple)
    else:""
  when ut!=u.U:
    const usiU =strSimpleSiUnit ut
    const siU = strSimpleSiUnit u.U
    usiU==siU
type AutoUSi2*[T;N:static[USimode];U,V,W:static[string]]=concept u
  u is Unit
  u.T is T
  const ut=
    when N==USimode.mm: U.formatUnit.mulUnit(V.formatUnit).mulUnit(W.formatUnit)
    elif N==USimode.md: U.formatUnit.mulUnit(V.formatUnit).divUnit(W.formatUnit)
    elif N==USimode.dd: U.formatUnit.divUnit(V.formatUnit).divUnit(W.formatUnit)
    # 幂操作基础系列 (1+6+21+16=44种)
    elif N==USimode.pm: U.formatUnit.powUnit(V.toTuple).mulUnit(W.formatUnit)
    elif N==USimode.mp: U.formatUnit.mulUnit(V.formatUnit.powUnit(W.toTuple))
    elif N==USimode.pd: U.formatUnit.powUnit(V.toTuple).divUnit(W.formatUnit)
    elif N==USimode.dp: U.formatUnit.divUnit(V.formatUnit.powUnit(W.toTuple))
    else:""
  when ut!=u.U:
    const usiU =strSimpleSiUnit ut
    const siU = strSimpleSiUnit u.U
    usiU==siU
type AutoUSi3*[T;N:static[USimode];U,V,W,X:static[string]]=concept u
  u is Unit
  u.T is T
  const ut=
    when N==USimode.mmm: U.formatUnit.mulUnit(V.formatUnit).mulUnit(W.formatUnit).mulUnit(X.formatUnit)
    elif N==USimode.mmd: U.formatUnit.mulUnit(V.formatUnit).mulUnit(W.formatUnit).divUnit(X.formatUnit)
    elif N==USimode.mdd: U.formatUnit.mulUnit(V.formatUnit).divUnit(W.formatUnit).divUnit(X.formatUnit)
    elif N==USimode.ddd: U.formatUnit.divUnit(V.formatUnit).divUnit(W.formatUnit).divUnit(X.formatUnit)
    # 幂操作基础系列 (1+6+21+16=44种)
    elif N==USimode.pmp: U.formatUnit.powUnit(V.toTuple).mulUnit(W.formatUnit.powUnit(X.toTuple))
    elif N==USimode.pdp: U.formatUnit.powUnit(V.toTuple).divUnit(W.formatUnit.powUnit(X.toTuple))

    elif N==USimode.pmm: U.formatUnit.powUnit(V.toTuple).mulUnit(W.formatUnit).mulUnit(X.formatUnit)
    elif N==USimode.mpm: U.formatUnit.mulUnit(V.formatUnit.powUnit(W.toTuple)).mulUnit(X.formatUnit)
    elif N==USimode.mmp: U.formatUnit.mulUnit(V.formatUnit).mulUnit(W.formatUnit.powUnit(X.toTuple))
    elif N==USimode.pmd: U.formatUnit.powUnit(V.toTuple).mulUnit(W.formatUnit).divUnit(X.formatUnit)
    elif N==USimode.mpd: U.formatUnit.mulUnit(V.formatUnit.powUnit(W.toTuple)).divUnit(X.formatUnit)
    elif N==USimode.mdp: U.formatUnit.mulUnit(V.formatUnit).divUnit(W.formatUnit.powUnit(X.toTuple))
    elif N==USimode.pdd: U.formatUnit.powUnit(V.toTuple).divUnit(W.formatUnit).divUnit(X.formatUnit)
    elif N==USimode.dpd: U.formatUnit.divUnit(V.formatUnit.powUnit(W.toTuple)).divUnit(X.formatUnit)
    elif N==USimode.ddp: U.formatUnit.divUnit(V.formatUnit).divUnit(W.formatUnit.powUnit(X.toTuple))
    else:""
  when ut!=u.U:
    const usiU =strSimpleSiUnit ut
    const siU = strSimpleSiUnit u.U
    usiU==siU
type AutoUSi4*[T;N:static[USimode];U,V,W,X,Y:static[string]]=concept u
  u is Unit
  u.T is T
  const ut=
    when N==USimode.mmmm: U.formatUnit.mulUnit(V.formatUnit).mulUnit(W.formatUnit).mulUnit(X.formatUnit).mulUnit(Y.formatUnit)
    elif N==USimode.mmmd: U.formatUnit.mulUnit(V.formatUnit).mulUnit(W.formatUnit).mulUnit(X.formatUnit).divUnit(Y.formatUnit)
    elif N==USimode.mmdd: U.formatUnit.mulUnit(V.formatUnit).mulUnit(W.formatUnit).divUnit(X.formatUnit).divUnit(Y.formatUnit)
    elif N==USimode.mddd: U.formatUnit.mulUnit(V.formatUnit).divUnit(W.formatUnit).divUnit(X.formatUnit).divUnit(Y.formatUnit)
    elif N==USimode.dddd: U.formatUnit.divUnit(V.formatUnit).divUnit(W.formatUnit).divUnit(X.formatUnit).divUnit(Y.formatUnit)

    elif N==USimode.pmpm: U.formatUnit.powUnit(V.toTuple).mulUnit(W.formatUnit.powUnit(X.toTuple)).mulUnit(Y.formatUnit)
    elif N==USimode.pmmp: U.formatUnit.powUnit(V.toTuple).mulUnit(W.formatUnit).mulUnit(X.formatUnit.powUnit(Y.toTuple))
    elif N==USimode.mpmp: U.formatUnit.mulUnit(V.formatUnit.powUnit(W.toTuple)).mulUnit(X.formatUnit.powUnit(Y.toTuple))
    elif N==USimode.pmpd: U.formatUnit.powUnit(V.toTuple).mulUnit(W.formatUnit.powUnit(X.toTuple)).divUnit(Y.formatUnit)
    elif N==USimode.pmdp: U.formatUnit.powUnit(V.toTuple).mulUnit(W.formatUnit).divUnit(X.formatUnit.powUnit(Y.toTuple))
    elif N==USimode.mpdp: U.formatUnit.mulUnit(V.formatUnit.powUnit(W.toTuple)).divUnit(X.formatUnit.powUnit(Y.toTuple))
    elif N==USimode.pdpd: U.formatUnit.powUnit(V.toTuple).divUnit(W.formatUnit.powUnit(X.toTuple)).divUnit(Y.formatUnit)
    elif N==USimode.pddp: U.formatUnit.powUnit(V.toTuple).divUnit(W.formatUnit).divUnit(X.formatUnit.powUnit(Y.toTuple))
    elif N==USimode.dpdp: U.formatUnit.divUnit(V.formatUnit.powUnit(W.toTuple)).divUnit(X.formatUnit.powUnit(Y.toTuple))

    elif N==USimode.pddp: U.formatUnit.powUnit(V.toTuple).divUnit(W.formatUnit).divUnit(X.formatUnit.powUnit(Y.toTuple))
    elif N==USimode.dpdd: U.formatUnit.divUnit(V.formatUnit.powUnit(W.toTuple)).divUnit(X.formatUnit).divUnit(Y.formatUnit)
    elif N==USimode.dddp: U.formatUnit.divUnit(V.formatUnit).divUnit(W.formatUnit).divUnit(X.formatUnit.powUnit(Y.toTuple))


    # pmmm系列
    elif N==USimode.pmmm: U.formatUnit.powUnit(V.toTuple).mulUnit(W.formatUnit).mulUnit(X.formatUnit).mulUnit(Y.formatUnit)
    elif N==USimode.mpmm: U.formatUnit.mulUnit(V.formatUnit.powUnit(W.toTuple)).mulUnit(X.formatUnit).mulUnit(Y.formatUnit)
    elif N==USimode.mmpm: U.formatUnit.mulUnit(V.formatUnit).mulUnit(W.formatUnit.powUnit(X.toTuple)).mulUnit(Y.formatUnit)
    elif N==USimode.mmmp: U.formatUnit.mulUnit(V.formatUnit).mulUnit(W.formatUnit).mulUnit(X.formatUnit.powUnit(Y.toTuple))
    elif N==USimode.pmmd: U.formatUnit.powUnit(V.toTuple).mulUnit(W.formatUnit).mulUnit(X.formatUnit).divUnit(Y.formatUnit)
    elif N==USimode.mpmd: U.formatUnit.mulUnit(V.formatUnit.powUnit(W.toTuple)).mulUnit(X.formatUnit).divUnit(Y.formatUnit)
    elif N==USimode.mmpd: U.formatUnit.mulUnit(V.formatUnit).mulUnit(W.formatUnit.powUnit(X.toTuple)).divUnit(Y.formatUnit)
    elif N==USimode.mmdp: U.formatUnit.mulUnit(V.formatUnit).mulUnit(W.formatUnit).divUnit(X.formatUnit.powUnit(Y.toTuple))

    # pmdd系列
    elif N==USimode.pmdd: U.formatUnit.powUnit(V.toTuple).mulUnit(W.formatUnit).divUnit(X.formatUnit).divUnit(Y.formatUnit)
    elif N==USimode.mpdd: U.formatUnit.mulUnit(V.formatUnit.powUnit(W.toTuple)).divUnit(X.formatUnit).divUnit(Y.formatUnit)
    elif N==USimode.mdpd: U.formatUnit.mulUnit(V.formatUnit).divUnit(W.formatUnit.powUnit(X.toTuple)).divUnit(Y.formatUnit)
    elif N==USimode.mddp: U.formatUnit.mulUnit(V.formatUnit).divUnit(W.formatUnit).divUnit(X.formatUnit.powUnit(Y.toTuple))
    elif N==USimode.pddd: U.formatUnit.powUnit(V.toTuple).divUnit(W.formatUnit).divUnit(X.formatUnit).divUnit(Y.formatUnit)
    elif N==USimode.dpdd: U.formatUnit.divUnit(V.formatUnit.powUnit(W.toTuple)).divUnit(X.formatUnit).divUnit(Y.formatUnit)
    elif N==USimode.ddpd: U.formatUnit.divUnit(V.formatUnit).divUnit(W.formatUnit.powUnit(X.toTuple)).divUnit(Y.formatUnit)
    elif N==USimode.dddp: U.formatUnit.divUnit(V.formatUnit).divUnit(W.formatUnit).divUnit(X.formatUnit.powUnit(Y.toTuple))
    else:""
  when ut!=u.U:
    const usiU =strSimpleSiUnit ut
    const siU = strSimpleSiUnit u.U
    usiU==siU
type AutoUSi5*[T;N:static[USimode];U,V,W,X,Y,Z:static[string]]=concept u
  u is Unit
  u.T is T
  const ut=
    when N==USimode.mmmmm: U.formatUnit.mulUnit(V.formatUnit).mulUnit(W.formatUnit).mulUnit(X.formatUnit).mulUnit(Y.formatUnit).mulUnit(Z.formatUnit)
    elif N==USimode.mmmmd: U.formatUnit.mulUnit(V.formatUnit).mulUnit(W.formatUnit).mulUnit(X.formatUnit).mulUnit(Y.formatUnit).divUnit(Z.formatUnit)
    elif N==USimode.mmmdd: U.formatUnit.mulUnit(V.formatUnit).mulUnit(W.formatUnit).mulUnit(X.formatUnit).divUnit(Y.formatUnit).divUnit(Z.formatUnit)
    elif N==USimode.mmddd: U.formatUnit.mulUnit(V.formatUnit).mulUnit(W.formatUnit).divUnit(X.formatUnit).divUnit(Y.formatUnit).divUnit(Z.formatUnit)
    elif N==USimode.mdddd: U.formatUnit.mulUnit(V.formatUnit).divUnit(W.formatUnit).divUnit(X.formatUnit).divUnit(Y.formatUnit).divUnit(Z.formatUnit)
    elif N==USimode.ddddd: U.formatUnit.divUnit(V.formatUnit).divUnit(W.formatUnit).divUnit(X.formatUnit).divUnit(Y.formatUnit).divUnit(Z.formatUnit)

    # pmpmm系列
    elif N==USimode.pmpmm: U.formatUnit.powUnit(V.toTuple).mulUnit(W.formatUnit.powUnit(X.toTuple)).mulUnit(Y.formatUnit).mulUnit(Z.formatUnit)
    elif N==USimode.pmmpm: U.formatUnit.powUnit(V.toTuple).mulUnit(W.formatUnit).mulUnit(X.formatUnit.powUnit(Y.toTuple)).mulUnit(Z.formatUnit)
    elif N==USimode.pmmmp: U.formatUnit.powUnit(V.toTuple).mulUnit(W.formatUnit).mulUnit(X.formatUnit).mulUnit(Y.formatUnit.powUnit(Z.toTuple))
    elif N==USimode.mpmpm: U.formatUnit.mulUnit(V.formatUnit.powUnit(W.toTuple)).mulUnit(X.formatUnit.powUnit(Y.toTuple)).mulUnit(Z.formatUnit)
    elif N==USimode.mpmmp: U.formatUnit.mulUnit(V.formatUnit.powUnit(W.toTuple)).mulUnit(X.formatUnit).mulUnit(Y.formatUnit.powUnit(Z.toTuple))
    elif N==USimode.mmpmp: U.formatUnit.mulUnit(V.formatUnit).mulUnit(W.formatUnit.powUnit(X.toTuple)).mulUnit(Y.formatUnit.powUnit(Z.toTuple))

    # pmpmd系列
    elif N==USimode.pmpmd: U.formatUnit.powUnit(V.toTuple).mulUnit(W.formatUnit.powUnit(X.toTuple)).mulUnit(Y.formatUnit).divUnit(Z.formatUnit)
    elif N==USimode.pmmpd: U.formatUnit.powUnit(V.toTuple).mulUnit(W.formatUnit).mulUnit(X.formatUnit.powUnit(Y.toTuple)).divUnit(Z.formatUnit)
    elif N==USimode.pmmdp: U.formatUnit.powUnit(V.toTuple).mulUnit(W.formatUnit).mulUnit(X.formatUnit).divUnit(Y.formatUnit.powUnit(Z.toTuple))
    elif N==USimode.mpmpd: U.formatUnit.mulUnit(V.formatUnit.powUnit(W.toTuple)).mulUnit(X.formatUnit.powUnit(Y.toTuple)).divUnit(Z.formatUnit)
    elif N==USimode.mpmdp: U.formatUnit.mulUnit(V.formatUnit.powUnit(W.toTuple)).mulUnit(X.formatUnit).divUnit(Y.formatUnit.powUnit(Z.toTuple))
    elif N==USimode.mmpdp: U.formatUnit.mulUnit(V.formatUnit).mulUnit(W.formatUnit.powUnit(X.toTuple)).divUnit(Y.formatUnit.powUnit(Z.toTuple))

    # pmpdd系列
    elif N==USimode.pmpdd: U.formatUnit.powUnit(V.toTuple).mulUnit(W.formatUnit.powUnit(X.toTuple)).divUnit(Y.formatUnit).divUnit(Z.formatUnit)
    elif N==USimode.pmdpd: U.formatUnit.powUnit(V.toTuple).mulUnit(W.formatUnit).divUnit(X.formatUnit.powUnit(Y.toTuple)).divUnit(Z.formatUnit)
    elif N==USimode.pmddp: U.formatUnit.powUnit(V.toTuple).mulUnit(W.formatUnit).divUnit(X.formatUnit).divUnit(Y.formatUnit.powUnit(Z.toTuple))
    elif N==USimode.mpdpd: U.formatUnit.mulUnit(V.formatUnit.powUnit(W.toTuple)).divUnit(X.formatUnit.powUnit(Y.toTuple)).divUnit(Z.formatUnit)
    elif N==USimode.mpddp: U.formatUnit.mulUnit(V.formatUnit.powUnit(W.toTuple)).divUnit(X.formatUnit).divUnit(Y.formatUnit.powUnit(Z.toTuple))
    elif N==USimode.mdpdp: U.formatUnit.mulUnit(V.formatUnit).divUnit(W.formatUnit.powUnit(X.toTuple)).divUnit(Y.formatUnit.powUnit(Z.toTuple))

    # pdpdd系列
    elif N==USimode.pdpdd: U.formatUnit.powUnit(V.toTuple).divUnit(W.formatUnit.powUnit(X.toTuple)).divUnit(Y.formatUnit).divUnit(Z.formatUnit)
    elif N==USimode.pddpd: U.formatUnit.powUnit(V.toTuple).divUnit(W.formatUnit).divUnit(X.formatUnit.powUnit(Y.toTuple)).divUnit(Z.formatUnit)
    elif N==USimode.pdddp: U.formatUnit.powUnit(V.toTuple).divUnit(W.formatUnit).divUnit(X.formatUnit).divUnit(Y.formatUnit.powUnit(Z.toTuple))
    elif N==USimode.dpdpd: U.formatUnit.divUnit(V.formatUnit.powUnit(W.toTuple)).divUnit(X.formatUnit.powUnit(Y.toTuple)).divUnit(Z.formatUnit)
    elif N==USimode.dpddp: U.formatUnit.divUnit(V.formatUnit.powUnit(W.toTuple)).divUnit(X.formatUnit).divUnit(Y.formatUnit.powUnit(Z.toTuple))
    elif N==USimode.ddpdp: U.formatUnit.divUnit(V.formatUnit).divUnit(W.formatUnit.powUnit(X.toTuple)).divUnit(Y.formatUnit.powUnit(Z.toTuple))
    else:""
  when ut!=u.U:
    const usiU =strSimpleSiUnit ut
    const siU = strSimpleSiUnit u.U
    usiU==siU
type AutoUSi6*[T;N:static[USimode];U,V,W,X,Y,Z,A:static[string]]=concept u
  u is Unit
  u.T is T
  const ut=
    when N==USimode.mmmmmm: U.formatUnit.mulUnit(V.formatUnit).mulUnit(W.formatUnit).mulUnit(X.formatUnit).mulUnit(Y.formatUnit).mulUnit(Z.formatUnit).mulUnit(A.formatUnit)
    elif N==USimode.mmmmmd: U.formatUnit.mulUnit(V.formatUnit).mulUnit(W.formatUnit).mulUnit(X.formatUnit).mulUnit(Y.formatUnit).mulUnit(Z.formatUnit).divUnit(A.formatUnit)
    elif N==USimode.mmmmdd: U.formatUnit.mulUnit(V.formatUnit).mulUnit(W.formatUnit).mulUnit(X.formatUnit).mulUnit(Y.formatUnit).divUnit(Z.formatUnit).divUnit(A.formatUnit)
    elif N==USimode.mmmddd: U.formatUnit.mulUnit(V.formatUnit).mulUnit(W.formatUnit).mulUnit(X.formatUnit).divUnit(Y.formatUnit).divUnit(Z.formatUnit).divUnit(A.formatUnit)
    elif N==USimode.mmdddd: U.formatUnit.mulUnit(V.formatUnit).mulUnit(W.formatUnit).divUnit(X.formatUnit).divUnit(Y.formatUnit).divUnit(Z.formatUnit).divUnit(A.formatUnit)
    elif N==USimode.mddddd: U.formatUnit.mulUnit(V.formatUnit).divUnit(W.formatUnit).divUnit(X.formatUnit).divUnit(Y.formatUnit).divUnit(Z.formatUnit).divUnit(A.formatUnit)
    elif N==USimode.dddddd: U.formatUnit.divUnit(V.formatUnit).divUnit(W.formatUnit).divUnit(X.formatUnit).divUnit(Y.formatUnit).divUnit(Z.formatUnit).divUnit(A.formatUnit)

    # pmpmpm系列
    elif N==USimode.pmpmpm: U.formatUnit.powUnit(V.toTuple).mulUnit(W.formatUnit.powUnit(X.toTuple)).mulUnit(Y.formatUnit.powUnit(Z.toTuple)).mulUnit(A.formatUnit)
    elif N==USimode.pmpmmp: U.formatUnit.powUnit(V.toTuple).mulUnit(W.formatUnit.powUnit(X.toTuple)).mulUnit(Y.formatUnit).mulUnit(Z.formatUnit.powUnit(A.toTuple))
    elif N==USimode.pmmpmp: U.formatUnit.powUnit(V.toTuple).mulUnit(W.formatUnit).mulUnit(X.formatUnit.powUnit(Y.toTuple)).mulUnit(Z.formatUnit.powUnit(A.toTuple))
    elif N==USimode.mpmpmp: U.formatUnit.mulUnit(V.formatUnit.powUnit(W.toTuple)).mulUnit(X.formatUnit.powUnit(Y.toTuple)).mulUnit(Z.formatUnit.powUnit(A.toTuple))

    # pmpmpd系列
    elif N==USimode.pmpmpd: U.formatUnit.powUnit(V.toTuple).mulUnit(W.formatUnit.powUnit(X.toTuple)).mulUnit(Y.formatUnit.powUnit(Z.toTuple)).divUnit(A.formatUnit)
    elif N==USimode.pmpmdp: U.formatUnit.powUnit(V.toTuple).mulUnit(W.formatUnit.powUnit(X.toTuple)).mulUnit(Y.formatUnit).divUnit(Z.formatUnit.powUnit(A.toTuple))
    elif N==USimode.pmmpdp: U.formatUnit.powUnit(V.toTuple).mulUnit(W.formatUnit).mulUnit(X.formatUnit.powUnit(Y.toTuple)).divUnit(Z.formatUnit.powUnit(A.toTuple))
    elif N==USimode.mpmpdp: U.formatUnit.mulUnit(V.formatUnit.powUnit(W.toTuple)).mulUnit(X.formatUnit.powUnit(Y.toTuple)).divUnit(Z.formatUnit.powUnit(A.toTuple))

    # pmpdpd系列
    elif N==USimode.pmpdpd: U.formatUnit.powUnit(V.toTuple).mulUnit(W.formatUnit.powUnit(X.toTuple)).divUnit(Y.formatUnit.powUnit(Z.toTuple)).divUnit(A.formatUnit)
    elif N==USimode.pmpddp: U.formatUnit.powUnit(V.toTuple).mulUnit(W.formatUnit.powUnit(X.toTuple)).divUnit(Y.formatUnit).divUnit(Z.formatUnit.powUnit(A.toTuple))
    elif N==USimode.pmdpdp: U.formatUnit.powUnit(V.toTuple).mulUnit(W.formatUnit).divUnit(X.formatUnit.powUnit(Y.toTuple)).divUnit(Z.formatUnit.powUnit(A.toTuple))
    elif N==USimode.mpdpdp: U.formatUnit.mulUnit(V.formatUnit.powUnit(W.toTuple)).divUnit(X.formatUnit.powUnit(Y.toTuple)).divUnit(Z.formatUnit.powUnit(A.toTuple))

    # pdpdpd系列
    elif N==USimode.pdpdpd: U.formatUnit.powUnit(V.toTuple).divUnit(W.formatUnit.powUnit(X.toTuple)).divUnit(Y.formatUnit.powUnit(Z.toTuple)).divUnit(A.formatUnit)
    elif N==USimode.pdpddp: U.formatUnit.powUnit(V.toTuple).divUnit(W.formatUnit.powUnit(X.toTuple)).divUnit(Y.formatUnit).divUnit(Z.formatUnit.powUnit(A.toTuple))
    elif N==USimode.pddpdp: U.formatUnit.powUnit(V.toTuple).divUnit(W.formatUnit).divUnit(X.formatUnit.powUnit(Y.toTuple)).divUnit(Z.formatUnit.powUnit(A.toTuple))
    elif N==USimode.dpdpdp: U.formatUnit.divUnit(V.formatUnit.powUnit(W.toTuple)).divUnit(X.formatUnit.powUnit(Y.toTuple)).divUnit(Z.formatUnit.powUnit(A.toTuple))
    else:""
  when ut!=u.U:
    const usiU =strSimpleSiUnit ut
    const siU = strSimpleSiUnit u.U
    usiU==siU
type AutoUSi7*[T;N:static[USimode];U,V,W,X,Y,Z,A,B:static[string]]=concept u
  u is Unit
  u.T is T
  const ut=
    when N==USimode.pmpmpmp: U.formatUnit.powUnit(V.toTuple).mulUnit(W.formatUnit.powUnit(X.toTuple)).mulUnit(Y.formatUnit.powUnit(Z.toTuple)).mulUnit(A.formatUnit.powUnit(B.toTuple))
    elif N==USimode.pmpmpdp: U.formatUnit.powUnit(V.toTuple).mulUnit(W.formatUnit.powUnit(X.toTuple)).mulUnit(Y.formatUnit.powUnit(Z.toTuple)).divUnit(A.formatUnit.powUnit(B.toTuple))
    elif N==USimode.pmpdpdp: U.formatUnit.powUnit(V.toTuple).mulUnit(W.formatUnit.powUnit(X.toTuple)).divUnit(Y.formatUnit.powUnit(Z.toTuple)).divUnit(A.formatUnit.powUnit(B.toTuple))
    elif N==USimode.pdpdpdp: U.formatUnit.powUnit(V.toTuple).divUnit(W.formatUnit.powUnit(X.toTuple)).divUnit(Y.formatUnit.powUnit(Z.toTuple)).divUnit(A.formatUnit.powUnit(B.toTuple))
    else:""
  when ut!=u.U:
    const usiU =strSimpleSiUnit ut
    const siU = strSimpleSiUnit u.U
    usiU==siU



