import std/[unittest, macros]
import packedArgs

proc myProc*(a, b, c = 1,
  d: string = "--", e: bool = false): string {.packedArgs.} =

  $a & $b & $c & d & $e


test "all args provided":
  check myProc(1, 2, 3, "no", true) == myProcPacked(toMyProcArgs(1, 2, 3, "no", true))

test "partial args":
  check myProc(1, 2, 3) == myProcPacked(toMyProcArgs(1, 2, 3))

test "named args":
  check myProc(b = 2, e = true) == myProcPacked(toMyProcArgs(b = 2, e = true))
