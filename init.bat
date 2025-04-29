@echo off

for %%i in ("%~dp0") do SET "init_workflow_dir=%%~fi"
set "init_workflow_dir=%init_workflow_dir:~0,-1%"

REM https://stackoverflow.com/questions/57131654/using-utf-8-encoding-chcp-65001-in-command-prompt-windows-powershell-window
REM But should still work in Windows terminal (https://www.microsoft.com/p/windows-terminal/9n0dx20hk701, https://github.com/microsoft/terminal)
REM https://github.com/microsoft/terminal/blob/4a243f044572146e18e0051badb1b5b3f3c28ac8/src/tools/ansi-color/README.md?plain=1#L20-L22
REM https://github.com/microsoft/terminal/blob/4a243f044572146e18e0051badb1b5b3f3c28ac8/src/tools/ansi-color/ansi-color.cmd#L400-L448
REM For emojis support:
chcp 65001 >nul

::##################################################
::  CHECK PRESENCE OF REQUIRED ENV VARIABLE AND FILES
::##################################################
if not defined PRJ_DIR (
  %_fatal% "The project dir variable 'PRJ_DIR' is not set. Make sure it exists before running the workflow" 1
)

if not defined PRJ_DIR_NAME (
  %_fatal% "The project dir name variable 'PRJ_DIR_NAME' is not set. Make sure it exists before running the workflow" 2
)

if not exist "%PRJ_DIR%\changelog-header.md" (
  %_fatal% "The changelog header file is missing at '%PRJ_DIR%\changelog-header.md'" 3
)
::##################################################
::  CHECK BATCOLORS SUBMODULE
::##################################################
set "okInit="
if not exist "%init_workflow_dir%\batcolors\echos.bat" (
    echo [dev_workflow] WARN: Missing submodules
    if not exist "%init_workflow_dir%\.gitmodules" (
          echo [dev_workflow] FATAL: Submodule batcolors not properly added
          call:iExitBatch 6
    ) else (
      echo [dev_workflow] INFO: Executing 'git submodule update --init' in '%init_workflow_dir%'
      git -C "%init_workflow_dir%" submodule update --init
      if errorlevel 1 (
          echo FATAL: Submodules not properly initialized
          call:iExitBatch 6
      )
    )
    call  "%init_workflow_dir%\batcolors\echos_macros.bat" export
    set "okInit=[dev_workflow] OK: Submodules initialized"
) else (
  call  "%init_workflow_dir%\batcolors\echos_macros.bat" export
  set "okInit=[dev_workflow] Submodule batcolors already initialized"
)
if not defined okInit (
  echo [dev_workflow] FATAL: Submodules not properly initialized
  call:iExitBatch 6
)

if not exist "%PRJ_DIR%\tools\batcolors" (
  mklink /J "%PRJ_DIR%\tools\batcolors" "%init_workflow_dir%\batcolors"
)

if defined okInit (
  if not defined QUIET_PRJ ( %_ok% "%okInit%" )
  set "okInit="
)

::##################################################
::  SET PROJECT DIRECTORY
::##################################################
set "workflow_dir=%init_workflow_dir%"

%_info% "[dev_workflow] Workflow directory is '%workflow_dir%'"
::##################################################
::  SETTING PATHS
::##################################################
set "VERSION_TXT_FILE=%PRJ_DIR%\version.txt"
set "POM_FILE=%PRJ_DIR%\pom.xml"
set "PACKAGE_JSON_FILE=%PRJ_DIR%\package.json"
set "DEV_WORKFLOW_DIR=%PRJ_DIR%\tools\dev_workflow"
set "HEADER_CHANGELOG_FILE=%PRJ_DIR%\changelog-header.md"

if not exist %DEV_WORKFLOW_DIR% (
  %_fatal% "[dev_workflow] Your submodule dev_workflow is not named correctly" 10
)

set "INIT_DONE=1"
goto:eof

:iExitBatch - Cleanly exit batch processing, regardless how many CALLs
@echo off
if not exist "%temp%\ExitBatchYes.txt" call :ibuildYes
call :iCtrlC <"%temp%\ExitBatchYes.txt" 1>nul 2>&1
:iCtrlC
cmd /c exit -1073741510%1
goto:eof

:ibuildYes - Establish a Yes file for the language used by the OS
pushd "%temp%"
set "yes="
if exist ExitBatchYes.txt (
  del ExitBatchYes.txt
)
copy nul ExitBatchYes.txt >nul
for /f "delims=(/ tokens=2" %%Y in (
  '"copy /-y nul ExitBatchYes.txt <nul"'
) do if not defined yes set "yes=%%Y"
echo %yes%>ExitBatchYes.txt
popd
exit /b

:call_echos_stack
if not defined ECHOS_STACK ( set "CURRENT_SCRIPT=%~nx0" & goto:eof ) else ( call "%PRJ_DIR%\tools\batcolors\echos.bat" :stack %~nx0 )
goto:eof