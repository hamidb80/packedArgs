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

func packedArgsImpl(routineDef: NimNode): NimNode =
  let
    n = routineDef[RoutineName]
    shouldExport = isExportedIdent n
    routineName = getIdentName n

  var
    tupleFieldsGroup: seq[NimNode]
    tupleFieldNamesList: seq[NimNode]

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

    tupleFieldNamesList.add arg[IdentDefNames]


  let
    argsTupleIdent = ident routineName & "Args"
    argsTupleDef = newTree(nnkTypeSection,
      newTree(nnkTypeDef, exportIf(argsTupleIdent, shouldExport),
      newEmptyNode(), newTree(nnkTupleTy).add(tupleFieldsGroup)
    ))

    argsIdent = ident "args"
    packedArgsProcDef = newproc(
      exportif(ident(routineName & "Packed"), shouldExport),
      [routineDef.RoutineReturnType, newIdentDefs(argsIdent, argsTupleIdent)],
      newtree(nnkCall, routineName.ident).add(
        tupleFieldNamesList.mapIt newDotExpr(argsIdent, it)
      ),
      routineDef.kind)

    toPackedArgsDef = newProc(
      exportIf(
        ident("to" & routineName.capitalizeAscii & "Args"), shouldExport),
      @[argsTupleIdent] & routineDef.RoutineArguments,
      newtree(nnkTupleConstr).add(tupleFieldNamesList),
      routineDef.kind
    )

  return quote:
    `routineDef`
    `argsTupleDef`
    `toPackedArgsDef`
    `packedArgsProcDef`

macro packedArgs*(routineDef) =
  expectKind routineDef, {nnkProcDef, nnkFuncDef}
  result = packedArgsImpl(routineDef)
  echo repr result
  # TODO add support for generics
