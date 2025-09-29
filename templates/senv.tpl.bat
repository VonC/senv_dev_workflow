@echo off

::  ******************************************************************
:: Script Name:  senv.bat
:: Description:  environment setup for the project
::
:: Parameters:
::    none
::
:: Usage:
::    First script to be called to setup the environment for the project
::    Copy this script to the root of your project (remove the .tpl in the name)
::
:: Return Value: 0 - Success, 1 - Error
::
::  ******************************************************************
@echo off

for %%i in ("%~dp0") do SET "PRJ_DIR=%%~fi"
set "PRJ_DIR=%PRJ_DIR:~0,-1%"
for %%i in ("%PRJ_DIR%") do SET "PRJ_DIR_NAME=%%~nxi"

if defined NO_MORE_SENV_%PRJ_DIR_NAME% ( goto:eof )

call %~dp0tools\init.bat $*

REM Your project specific settings here

if exist "%PRJ_DIR%\senv.local.bat" (
  REM Can override variables from senv.bat
  %_info% "Loading local environment variables from '%PRJ_DIR%\senv.local.bat'"
  call "%PRJ_DIR%\senv.local.bat"
) else (
  %_info% "No local environment variables file (senv.local.bat) found in '%PRJ_DIR%'"
)

REM Set project-specific flag when done
REM Next call to senv.bat will be skipped
set "NO_MORE_SENV_%PRJ_DIR_NAME%=true"

%_info% "senv applied for '%PRJ_DIR_NAME%'"

goto:eof

:call_echos_stack
if not defined ECHOS_STACK ( set "CURRENT_SCRIPT=%~nx0" & goto:eof ) else ( call "%PRJ_DIR%\tools\batcolors\echos.bat" :stack %~nx0 )
goto:eof
