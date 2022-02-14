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

func packedArgsImpl(routineDef: NimNode): NimNode =
  let
    n = routineDef[RoutineName]
    genericParams = routineDef[RoutineGenericParams]
    shouldExport = isExportedIdent n
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
    `routineDef`
    `argsTupleDef`
    `toPackedArgsDef`
    `packedArgsProcDef`

macro packedArgs*(routineDef) =
  expectKind routineDef, {nnkProcDef, nnkFuncDef}
  result = packedArgsImpl(routineDef)

  # echo repr result
  # echo treeRepr result
