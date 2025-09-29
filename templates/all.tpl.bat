@echo off

for %%i in ("%~dp0.") do SET "script_dir=%%~fi"
cd "%script_dir%"
for %%i in ("%~dp0.") do SET "dirname=%%~ni"

call senv.bat

set barg=
if "%1" == "rel" (
    set "barg=rel"
    shift
)

if "%1" == "amd" (
    set "barg=%barg% amd"
    shift
)
call build.bat %barg%
if errorlevel 1 (
    echo ERROR BUILD 1>&2
    exit /b 1
)
set barg=
call deploy.bat

call <NUL run.bat %*
