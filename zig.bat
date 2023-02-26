@echo off
set zigup_zig_root=C:\standalone_programs\zigup.windows-v2022_08_25-x86_64\zig

rem set zigup_zig_version=0.10.0-dev.3258+9734e643f
rem set zigup_zig_version=0.10.0-dev.3362+e863292fe
rem set zigup_zig_version=0.10.0-dev.3559+d2342370f
rem set zigup_zig_version=0.10.0
set zigup_zig_version=0.10.1
set /p zigup_zig_version=<%zigup_zig_root%\master

set zig_exe=%zigup_zig_root%\%zigup_zig_version%\files\zig.exe
rem set zig_exe=C:\Users\Michael\dev\open_source\contributing\zig\stage3\bin\zig.exe
set zig_exe=C:\Users\Michael\dev\open_source\contributing\zig\build\stage3\bin\zig.exe

rem set zig_invocation=%zig_exe% %* -fstage1
set zig_invocation=%zig_exe% %*

echo %zig_invocation%
%zig_invocation%
