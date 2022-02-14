import std/[unittest, macros]
import packedArgs


proc myProc(a, b = 1, c: bool): string {.packedArgs.} =
  $a & $b & $c

proc myGeneric[A, B](a: A, b: B): string {.packedArgs.} =
  $a & $b


test "normal":
  check myProc(1, 2, true) == myProcPacked(toMyProcArgs(1, 2, true))

test "generic":
  check myGeneric(0.3, true) == myGenericPacked(tomyGenericArgs(0.3, true))
