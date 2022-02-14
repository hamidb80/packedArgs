# packedArgs!

## The Problem
> Note: Channels are designed for the Thread type. They are unstable when used with spawn
:: [Nim doc for channles](https://nim-lang.org/docs/channels_builtin.html)

> the problem is that spawn can block and programms that use channels usually assume that it cannot block :: [Araq on discord channel](https://discord.com/channels/371759389889003530/371759389889003532/814439926380494878)
>

So this brings us to [`createThread`](https://nim-lang.org/docs/threads.html#createThread%2CThread%5Bvoid%5D%2Cproc%29).
But the bad thing about `createThread` is that you can't pass multiply arguments for your `proc`. you have to pack them (arguments) inside a `tuple`/`object`, ... and then pass it.

## The Solution
this library aims to eliminite this limitation via `packedArgs` macro.

Assume you have a proc named `myProc` like this and you apply `packedArgs` to it:
```nim
proc myProc(a, b = 1; c: bool): string {.packedArgs.} =
  ...
```

**the generated code will be:**
```nim
proc myProc(a, b = 1; c: bool): string =
  ...

type MyProcArgs = tuple[a, b: typeof 1, c: bool]

proc toMyProcArgs(a, b = 1; c: bool): MyProcArgs =
  (a, b, c)

proc myProcPacked(args: MyProcArgs): string =
  myProc(args.a, args.b, args.c)
```

**usage**:
```nim
myProcPacked(toMyProcArgs(1, 2, true)) # same as myProc(1, 2, true)
```

or there is macro `genPackedArgsFor` to use after routine declaration.
```nim
macro genPackedArgsFor(routineIdent: typed, exported: static[bool]): untyped
```
**usage**:
```nim
proc work(something: bool): float = discard
genPackedArgsFor(work, true)
```

Becuase this is a little trickier, use `unpackArgs` when it's possible.


## Features
* [x] **export**: if the proc exported itself, the generated `type`/`proc`s are exported too
* [x] **generics**: nothing new, see `tests`/`test.nim` to make sure