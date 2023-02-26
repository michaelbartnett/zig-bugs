# Zig Bugs

This will crash in zig build-exe intermittently

Most recent version tried is Zig master, 0.11.0-dev.1812+26196be34

Run:

```cmd
rmdir /S /Q build zig-out zig-cache
zig build
```

The program it builds shouldn't do anything, maybe open a window or just crash since it's been stripped bare.

When it crashes with segfaults at address 0xffffffffffffffff here's a typical callstack:

```
[0x0]   zig!ZNK4llvm5APInt13compareSignedERKS0_ + 0x4a   
[0x1]   zig!ZN4llvm15SmallVectorImplINS_8SwitchCG11BitTestCaseEEaSEOS3_ + 0x626   
[0x2]   zig!ZN4llvm8SwitchCG15sortAndRangeifyERNSt3__16vectorINS0_11CaseClusterENS1_9allocatorIS3_EEEE + 0x4f   
[0x3]   zig!ZN4llvm19SelectionDAGBuilder11visitSwitchERKNS_10SwitchInstE + 0x48f   
[0x4]   zig!ZN4llvm19SelectionDAGBuilder5visitERKNS_11InstructionE + 0x73   
[0x5]   zig!ZN4llvm16SelectionDAGISel16SelectBasicBlockENS_14ilist_iteratorINS_12ilist_detail12node_optionsINS_11InstructionELb0ELb0EvEELb0ELb1EEES6_Rb + 0x147   
[0x6]   zig!ZN4llvm16SelectionDAGISel20SelectAllBasicBlocksERKNS_8FunctionE + 0x1543   
[0x7]   zig!ZN4llvm16SelectionDAGISel20runOnMachineFunctionERNS_15MachineFunctionE + 0x640   
[0x8]   zig!ZN4llvm16createX86ISelDagERNS_16X86TargetMachineENS_10CodeGenOpt5LevelE + 0xed   
[0x9]   zig!ZN4llvm19MachineFunctionPass13runOnFunctionERNS_8FunctionE + 0x22b   
[0xa]   zig!ZN4llvm13FPPassManager13runOnFunctionERNS_8FunctionE + 0x445   
[0xb]   zig!ZN4llvm13FPPassManager11runOnModuleERNS_6ModuleE + 0x33   
[0xc]   zig!ZN4llvm6legacy15PassManagerImpl3runERNS_6ModuleE + 0x463   
[0xd]   zig!ZigLLVMTargetMachineEmitToFile + 0x10b4   
[0xe]   zig!flushModule + 0x10d8   
[0xf]   zig!flushModule + 0x6e   
[0x10]   zig!linkWithLLD + 0x32d   
[0x11]   zig!flush + 0x100   
[0x12]   zig!flush + 0x54e   
[0x13]   zig!flush + 0x4f   
[0x14]   zig!update + 0x2fd4   
[0x15]   zig!updateModule + 0x5c   
[0x16]   zig!buildOutputType + 0x26c8c   
[0x17]   zig!mainArgs + 0x196   
[0x18]   zig!main + 0xff   
[0x19]   zig!callMain + 0xc   
[0x1a]   zig!initEventLoopAndCallMain + 0xc   
[0x1b]   zig!callMainWithArgs + 0x84   
[0x1c]   zig!main + 0x2a1   
[0x1d]   zig!WinMainCRTStartup + 0x2c6   
[0x1e]   zig!mainCRTStartup + 0x1c   
[0x1f]   KERNEL32!BaseThreadInitThunk + 0x14   
[0x20]   ntdll!RtlUserThreadStart + 0x21   
```

Here are some crash outputs from a debug build of Zig (built with ZigDevKit and the CMake + Ninja option):

```
C:\Users\Michael\dev\open_source\contributing\zig\build\stage3\bin\zig.exe build
info: Zig version: 0.11.0
thread 5448 panic: Segmentation fault at address 0xffffffffffffffff
error: zig-bugs...
error: The following command exited with error code 3:
C:\Users\Michael\dev\open_source\contributing\zig\build\stage3\bin\zig.exe build-exe C:\Users\Michael\dev\zignoodles\zig-bugs\libs\main\src\main.zig c:\Users\Michael\dev\zignoodles\zig-bugs\zig-cache\o\84a887eb457f5001cb221b1a99b85c3d\sokol.lib -lkernel32 -luser32 -lgdi32 -lole32 -ld3d11 -ldxgi -lc --cache-dir c:\Users\Michael\dev\zignoodles\zig-bugs\zig-cache --global-cache-dir C:\Users\Michael\AppData\Local\zig --name zig-bugs --mod sokol::C:\Users\Michael\dev\zignoodles\zig-bugs\vendor\sokol-zig\src\sokol\sokol.zig --deps sokol --enable-cache 
error: the following build command failed with exit code 3:
c:\Users\Michael\dev\zignoodles\zig-bugs\zig-cache\o\9be489b0bb122efe85587f4c332b309e\build.exe C:\Users\Michael\dev\open_source\contributing\zig\build\stage3\bin\zig.exe c:\Users\Michael\dev\zignoodles\zig-bugs c:\Users\Michael\dev\zignoodles\zig-bugs\zig-cache C:\Users\Michael\AppData\Local\zig
```

```
C:\Users\Michael\dev\open_source\contributing\zig\build\stage3\bin\zig.exe build
info: Zig version: 0.11.0
Segmentation fault at address 0x0
C:\Users\Michael\dev\open_source\contributing\zig\build\stage3\lib\zig\std\mem\Allocator.zig:216:53: 0x7ff7c9ad78cc in allocAdvancedWithRetAddr__anon_9712 (zig-bugs.exe.obj)
    const byte_ptr = self.rawAlloc(byte_count, log2a(a), return_address) orelse return Error.OutOfMemory;
                                                    ^
???:?:?: 0x5e767fe62f in ??? (???)
???:?:?: 0x15f in ??? (???)
???:?:?: 0x800d967439b1e2f in ??? (???)

Compilation exited abnormally with code 3 at Sat Feb 25 16:00:36
```

```
C:\Users\Michael\dev\open_source\contributing\zig\build\stage3\bin\zig.exe build
info: Zig version: 0.11.0
Segmentation fault at address 0x0
C:\Users\Michael\dev\open_source\contributing\zig\build\stage3\lib\zig\std\mem\Allocator.zig:216:53: 0x7ff7425e78cc in allocAdvancedWithRetAddr__anon_9712 (zig-bugs.exe.obj)
    const byte_ptr = self.rawAlloc(byte_count, log2a(a), return_address) orelse return Error.OutOfMemory;
                                                    ^
???:?:?: 0xa8b17fed8f in ??? (???)
???:?:?: 0x15f in ??? (???)
error.Unexpected: GetLastError(87): The parameter is incorrect.

C:\Users\Michael\dev\open_source\contributing\zig\build\stage3\lib\zig\std\os\windows.zig:1528:49: 0x7ff7426011c6 in VirtualQuery (zig-bugs.exe.obj)
            else => |err| return unexpectedError(err),
                                                ^
C:\Users\Michael\dev\open_source\contributing\zig\build\stage3\lib\zig\std\debug.zig:502:83: 0x7ff7425fcc47 in isValidMemory (zig-bugs.exe.obj)
            const rc = w.VirtualQuery(aligned_memory, &memory_info, aligned_memory.len) catch {
                                                                                  ^
C:\Users\Michael\dev\open_source\contributing\zig\build\stage3\lib\zig\std\debug.zig:528:77: 0x7ff7425f4ed6 in next_internal (zig-bugs.exe.obj)
        if (fp == 0 or !mem.isAligned(fp, @alignOf(usize)) or !isValidMemory(fp))
                                                                            ^
C:\Users\Michael\dev\open_source\contributing\zig\build\stage3\lib\zig\std\debug.zig:464:41: 0x7ff7425ec771 in next (zig-bugs.exe.obj)
        var address = self.next_internal() orelse return null;
                                        ^
C:\Users\Michael\dev\open_source\contributing\zig\build\stage3\lib\zig\std\debug.zig:188:23: 0x7ff7425d8955 in dumpStackTraceFromBase (zig-bugs.exe.obj)
        while (it.next()) |return_address| {
                      ^
C:\Users\Michael\dev\open_source\contributing\zig\build\stage3\lib\zig\std\debug.zig:2036:45: 0x7ff7425c226b in handleSegfaultWindowsExtra__anon_8229 (zig-bugs.exe.obj)
        dumpStackTraceFromBase(regs.bp, regs.ip);
                                            ^
C:\Users\Michael\dev\open_source\contributing\zig\build\stage3\lib\zig\std\debug.zig:2013:73: 0x7ff742587290 in handleSegfaultWindows (zig-bugs.exe.obj)
        windows.EXCEPTION_ACCESS_VIOLATION => handleSegfaultWindowsExtra(info, 1, null),
                                                                        ^
???:?:?: 0x7ffdce088b4b in ??? (???)
???:?:?: 0x7ffdce0612c5 in ??? (???)
???:?:?: 0x7ffdce0b0f4d in ??? (???)
C:\Users\Michael\dev\open_source\contributing\zig\build\stage3\lib\zig\std\mem\Allocator.zig:216:53: 0x7ff7425e78cb in allocAdvancedWithRetAddr__anon_9712 (zig-bugs.exe.obj)
    const byte_ptr = self.rawAlloc(byte_count, log2a(a), return_address) orelse return Error.OutOfMemory;
                                                    ^
C:\Users\Michael\dev\open_source\contributing\zig\build\stage3\lib\zig\std\mem\Allocator.zig:192:41: 0x7ff7425d5d15 in alignedAlloc__anon_9126 (zig-bugs.exe.obj)
    return self.allocAdvancedWithRetAddr(T, alignment, n, @returnAddress());
                                        ^
C:\Users\Michael\dev\open_source\contributing\zig\build\stage3\lib\zig\std\hash_map.zig:1555:53: 0x7ff74260224c in allocate (zig-bugs.exe.obj)
            const slice = try allocator.alignedAlloc(u8, max_align, total_size);
                                                    ^
C:\Users\Michael\dev\open_source\contributing\zig\build\stage3\lib\zig\std\hash_map.zig:1515:29: 0x7ff7425ffec2 in grow (zig-bugs.exe.obj)
            try map.allocate(allocator, new_cap);
                            ^
C:\Users\Michael\dev\open_source\contributing\zig\build\stage3\lib\zig\std\hash_map.zig:1465:70: 0x7ff7425fad8d in growIfNeeded (zig-bugs.exe.obj)
                try self.grow(allocator, capacityForSize(self.load() + new_count), ctx);
                                                                     ^
C:\Users\Michael\dev\open_source\contributing\zig\build\stage3\lib\zig\std\hash_map.zig:1287:30: 0x7ff7425f27fe in getOrPutContextAdapted__anon_10021 (zig-bugs.exe.obj)
            self.growIfNeeded(allocator, 1, ctx) catch |err| {
                             ^
C:\Users\Michael\dev\open_source\contributing\zig\build\stage3\lib\zig\std\hash_map.zig:1275:56: 0x7ff7425e75f1 in getOrPutContext (zig-bugs.exe.obj)
            const gop = try self.getOrPutContextAdapted(allocator, key, ctx, ctx);
                                                       ^
C:\Users\Michael\dev\open_source\contributing\zig\build\stage3\lib\zig\std\hash_map.zig:479:76: 0x7ff7425d7c64 in getOrPut (zig-bugs.exe.obj)
            return self.unmanaged.getOrPutContext(self.allocator, key, self.ctx);
                                                                           ^
C:\Users\Michael\dev\zignoodles\zig-bugs\libs\main\src\app013_scenelinks\resources.zig:563:64: 0x7ff7425c031a in addUnloadCallback__anon_8167 (zig-bugs.exe.obj)
        var list_gop = unload_callbacks.getOrPut(RuntimeType.id(T)) catch unreachable;
                                                               ^
C:\Users\Michael\dev\zignoodles\zig-bugs\libs\main\src\app013_scenelinks\app.zig:329:67: 0x7ff742583e7a in initSelf (zig-bugs.exe.obj)
        Resources.addUnloadCallback(SpriteDesc, onResourceUnload, @ptrToInt(self));
                                                                  ^
C:\Users\Michael\dev\zignoodles\zig-bugs\libs\main\src\app013_scenelinks\app.zig:284:44: 0x7ff74258251e in postInit (zig-bugs.exe.obj)
        self.sprite_render_globals.initSelf(alloc);
                                           ^
C:\Users\Michael\dev\zignoodles\zig-bugs\libs\main\src\app013_scenelinks\app.zig:65:25: 0x7ff74258142d in init (zig-bugs.exe.obj)
        globals.postInit(alloc);
                        ^
C:\Users\Michael\dev\zignoodles\zig-bugs\libs\main\src\main.zig:12:55: 0x7ff742581386 in main (zig-bugs.exe.obj)
    var app013 = app_scenelinks.App.init(gpa.allocator());
                                                      ^
C:\Users\Michael\dev\open_source\contributing\zig\build\stage3\lib\zig\std\start.zig:516:80: 0x7ff742581842 in main (zig-bugs.exe.obj)
    return @call(.always_inline, callMainWithArgs, .{ @intCast(usize, c_argc), @ptrCast([*][*:0]u8, c_argv), envp });
                                                                               ^
Unable to dump stack trace: InvalidDebugInfo

Compilation exited abnormally with code 3 at Sat Feb 25 15:59:38

```
