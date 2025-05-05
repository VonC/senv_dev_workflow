@echo off

setlocal enabledelayedexpansion

for %%i in ("%~dp0") do SET "run_dir=%%~fi"
echo update-tag-message
set "QUIET_PRJ=true"
call <NUL "%PRJ_DIR%\senv.bat"

cd "%run_dir%"
if errorlevel 1 ( %_fatal% "unable to cd to '%run_dir%'" 1 )
bash -c "./update-tag-message.sh %*"