import std/[sequtils, strutils]
import macros, macroplus

func getIdentName(n: NimNode): string =
  if n.kind == nnkPostfix:
    getIdentName n[1]
  else:
    n.strVal

func exportIf(n: NimNode, shoudExport: bool): NimNode =
  if shoudExport: exported n
  else: n

func listIdentsInIdentDefs(idfs: seq[NimNode]): seq[NimNode] =
  for idf in idfs:
    result.add idf[IdentDefNames]

func toGenericIdent(id: NimNode, genericParams: NimNode): NimNode =
  if genericParams.kind == nnkEmpty:
    id
  else:
    newTree(nnkBracketExpr, id).add:
      listIdentsInIdentDefs genericParams.toseq

func packedArgsImpl(routineDef: NimNode, forceExport: bool): NimNode =
  let
    n = routineDef[RoutineName]
    genericParams = routineDef[RoutineGenericParams]
    shouldExport = forceExport or isExportedIdent n
    routineName = getIdentName n

  var tupleFieldsGroup: seq[NimNode]

  for arg in routineDef.RoutineArguments:
    let `type` =
      if arg[IdentDefType].kind == nnkEmpty:
        let default = arg[IdentDefDefaultVal]
        inlineQuote(typeof `default`)
      else:
        arg[IdentDefType]

    tupleFieldsGroup.add newTree(nnkIdentDefs)
      .add(arg[IdentDefNames])
      .add(`type`)
      .add(newEmptyNode())


  let
    tupleFieldNamesList = listIdentsInIdentDefs tupleFieldsGroup

    argsTupleIdent = ident routineName.capitalizeAscii & "Args"
    argsTupleDef = newTree(nnkTypeSection,
      newTree(nnkTypeDef, exportIf(argsTupleIdent, shouldExport),
      newEmptyNode(), newTree(nnkTupleTy).add(tupleFieldsGroup)
    ))

    generalArgsTupleIdent = toGenericIdent(argsTupleIdent, genericParams)

    argsIdent = ident "args"
    packedArgsProcDef = newproc(exportif(
      ident(routineName & "Packed"), shouldExport),
      [
        routineDef.RoutineReturnType,
        newIdentDefs(argsIdent, generalArgsTupleIdent)
      ],
      newtree(nnkCall, routineName.ident).add(
        tupleFieldNamesList.mapIt newDotExpr(argsIdent, it)
      ),
      routineDef.kind)

    toPackedArgsDef = newProc(exportIf(
      ident("to" & routineName.capitalizeAscii & "Args"), shouldExport),
      @[generalArgsTupleIdent] & routineDef.RoutineArguments,
      newtree(nnkTupleConstr).add(tupleFieldNamesList),
      routineDef.kind
    )

  argsTupleDef[0][TypeDefGenericParams] = genericParams
  packedArgsProcDef[RoutineGenericParams] = genericParams
  toPackedArgsDef[RoutineGenericParams] = genericParams

  return quote:
    `argsTupleDef`
    `toPackedArgsDef`
    `packedArgsProcDef`

macro packedArgs*(routineDef) =
  expectKind routineDef, {nnkProcDef, nnkFuncDef}
  let heplers = packedArgsImpl(routineDef, false)

  result = quote:
    `routineDef`
    `heplers`

  # echo repr result
  # echo treeRepr result

macro genPackedArgsFor*(routineIdent: typed, exported: static[bool]): untyped =
  var routineDef = copy getImpl routineIdent

  # convert Sym to Ident
  for i in 1 ..< routineDef[RoutineFormalParams].len:
    var ra = routineDef[RoutineFormalParams][i]
    for ia in 0..(ra.len - 3):
      if ra[ia].kind == nnkSym:
        ra[ia] = ident ra[ia].strVal

  # make generic params format valid + convert Sym to Ident
  if routineDef[RoutineGenericParams].kind != nnkEmpty:
    for i in 0..<routineDef[RoutineGenericParams].len:
      routineDef[RoutineGenericParams][i] = newIdentDefs(
        ident routineDef[RoutineGenericParams][i].strval,
        newEmptyNode())

  result = packedArgsImpl(routineDef, exported)

  # echo repr result
  # echo treeRepr result
