@echo off

setlocal enabledelayedexpansion

for %%i in ("%~dp0") do SET "run_dir=%%~fi"

set "QUIET_PRJ=true"
call <NUL "%run_dir%\..\senv.bat"

if errorlevel 1 ( %_fatal% "unable to cd to '%run_dir%'" 1 )
bash -c "\"$(cygpath -u "${run_dir}")/update-changelog.sh\" %*"