@echo off

setlocal enabledelayedexpansion

for %%i in ("%~dp0") do SET "run_dir=%%~fi"
echo update-changelog
set "QUIET_PRJ=true"
call <NUL "%PRJ_DIR%\senv.bat"

if errorlevel 1 ( %_fatal% "unable to cd to '%run_dir%'" 1 )
bash -c "\"$(cygpath -u "${PRJ_DIR}")/update-changelog.sh\" %*"