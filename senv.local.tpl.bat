@echo off

::********************************************************************
:: Script Name:  senv.local.bat
:: Description:  Local environment setup for the project
::
:: Parameters:
::    none
::
:: Usage:
::    called by senv.bat automatically
::
:: Return Value: 0 - Success, 1 - Error
::
::********************************************************************

for %%i in ("%~dp0") do SET "PRJ_DIR=%%~fi"
set "PRJ_DIR=%PRJ_DIR:~0,-1%"
for %%i in ("%PRJ_DIR%") do SET "PRJ_DIR_NAME=%%~nxi"

call %~dp0tools\init.bat "%PRJ_DIR%"

REM your local settings here

REM For instance, the project needs to be built and deployed as xxx
REM set "APP_NAME=xxx"

goto:eof

:call_echos_stack
if not defined ECHOS_STACK ( set "CURRENT_SCRIPT=%~nx0" & goto:eof ) else ( call "%project_dir%\tools\batcolors\echos.bat" :stack %~nx0 )
goto:eof
