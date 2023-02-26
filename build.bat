@echo off
setlocal
cd /d %~dp0

.\clean & .\zig build
