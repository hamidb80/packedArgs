# packedArgs!

## the problem
> Note: Channels are designed for the Thread type. They are unstable when used with spawn
:: [Nim doc for channles](https://nim-lang.org/docs/channels_builtin.html)

> the problem is that spawn can block and programms that use channels usually assume that it cannot block :: [Araq on discord channel](https://discord.com/channels/371759389889003530/371759389889003532/814439926380494878)
>

So this brings us to use [`createThread`](https://nim-lang.org/docs/threads.html#createThread%2CThread%5Bvoid%5D%2Cproc%29).
But the bad thing about `createThread` is that you can't pass multiply arguments when you create a thread. you have to pack the arguments inside a `tuple`/`object`, ... and then pass it.

## the workaround
this library aims to eliminite this limitation via `packedArgs` macro.

Image you have a proc named `myProc` like this and you apply `packedArgs` to it:
```nim
proc myProc(a, b, c: int = 1, d: string = ""): string {.packedArgs.} =
  ...
```

**the generated code gonna be:**
```nim
proc myProc(a, b, c: int = 1, d: string = ""): string =
  ...

type MyProcArgs = tuple[a, b, c: int, d: string]

proc toMyProcArgs(a, b, c: int = 1, d: string = ""): MyProcArgs =
  (a, b, c, d, e)

proc myProcPacked(args: MyProcArgs): string =
  myProc(args.a, args.b, args.c, args.d, args.e)
```

>>>> note on exported <<<<

Sweet! right?

## Features
* [x] export
* [ ] generics 