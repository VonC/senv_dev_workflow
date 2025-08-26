@echo off

for %%i in ("%~dp0") do SET "init_workflow_dir=%%~fi"
set "init_workflow_dir=%init_workflow_dir:~0,-1%"
REM Get parent directory of init_workflow_dir
for %%i in ("%init_workflow_dir%\..") do set "parent_dir=%%~fi"
rem echo Parent directory is: %parent_dir%

REM https://stackoverflow.com/questions/57131654/using-utf-8-encoding-chcp-65001-in-command-prompt-windows-powershell-window
REM But should still work in Windows terminal (https://www.microsoft.com/p/windows-terminal/9n0dx20hk701, https://github.com/microsoft/terminal)
REM https://github.com/microsoft/terminal/blob/4a243f044572146e18e0051badb1b5b3f3c28ac8/src/tools/ansi-color/README.md?plain=1#L20-L22
REM https://github.com/microsoft/terminal/blob/4a243f044572146e18e0051badb1b5b3f3c28ac8/src/tools/ansi-color/ansi-color.cmd#L400-L448
REM For emojis support:
chcp 65001 >nul


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

if not exist "%init_workflow_dir%\shcolors\echos" (
    echo [dev_workflow] FATAL: Submodule shcolors not properly added
    call:iExitBatch 7
) else (
  set "okInit=%okInit:batcolors=batcolors and shcolors%"
)

if not defined okInit (
  echo [dev_workflow] FATAL: Submodules not properly initialized
  call:iExitBatch 6
)

if not exist "%parent_dir%\batcolors" (
  mklink /J "%parent_dir%\batcolors" "%init_workflow_dir%\batcolors"
)

if defined okInit (
  if not defined QUIET_PRJ ( %_ok% "%okInit%" )
  set "okInit="
)

::##################################################
::  CHECK PRESENCE OF REQUIRED ENV VARIABLE AND FILES
::##################################################
if not defined PRJ_DIR (
  %_fatal% "[dev_workflow] The project dir variable 'PRJ_DIR' is not set. Make sure it exists before running the workflow" 1
)

if not defined PRJ_DIR_NAME (
  %_fatal% "[dev_workflow] The project dir name variable 'PRJ_DIR_NAME' is not set. Make sure it exists before running the workflow" 2
)

if not exist "%PRJ_DIR%\changelog-header.md" (
  %_fatal% "[dev_workflow] The changelog header file is missing at '%PRJ_DIR%\changelog-header.md'" 3
)

set "filter_smudge="
for /f "tokens=* delims=" %%i in ('git -C "%PRJ_DIR%" config filter."changelog".smudge') do SET "filter_smudge=%%~ni"
if not defined filter_smudge (
  %_task% "[dev_workflow] Must set git config filter.changelog filter for changelog diff"
  git  -C "%PRJ_DIR%" config filter.changelog.smudge "cat"
  git  -C "%PRJ_DIR%" config filter.changelog.clean "sed -E 's/(## \[v.*?-SNAPSHOT unreleased\].*-).*$/\1/'"
  if errorlevel 1 (
    %_fatal% "[dev_workflow] git  -C '%PRJ_DIR%' config filter.changelog filters failed for changelog diff" 231
  )
  %_ok% "[dev_workflow] git  -C '%PRJ_DIR%' config filter.changelog filters set for changelog diff"
)

::##################################################
::  DEFINE PROJECT ALIASES
::##################################################
doskey a="%PRJ_DIR%\all.bat" $*
doskey b="%PRJ_DIR%\build.bat" $*
doskey brel="%PRJ_DIR%\build.bat" rel $*
doskey br="%PRJ_DIR%\build.bat" rel $*
doskey t="%PRJ_DIR%\test.bat" $*
doskey s="%PRJ_DIR%\setup.bat" $*
doskey i="%PRJ_DIR%\install.bat" $*
doskey p="%PRJ_DIR%\publish.bat" $*
doskey d="%PRJ_DIR%\deploy.bat" $*
doskey r="%PRJ_DIR%\run.bat" $*
doskey crel=bash -c "git tag --sort=-creatordate | head -n 1 | xargs -I {} sh -c 'git reset $(git rev-list -n 1 {}^); git tag -d {}'"

doskey fsenv=set "NO_MORE_SENV_%PRJ_DIR_NAME%=" ^& "%PRJ_DIR%\senv.bat" force $*

doskey lsenv="%project_dir%\senv.bat" local $*
doskey psenve="%PRGS%\vscodes\current\bin\code.cmd" "%~dp0senv.local.bat"
doskey senv="%project_dir%\senv.bat" $*
doskey psenv="%project_dir%\senv.bat" $*
doskey hsenv=%HOME%\bin\senv.bat $*
doskey hlsenv=%HOME%\bin\lsenv.bat $*
doskey usenv="%project_dir%\senv.bat" unset

doskey cdp=cd /d "%PRJ_DIR%"

doskey gv=call "%PRJ_DIR%\tools\dev_workflow\get-version.bat" ^& cmd /v /c echo Project version from '%PRJ_DIR%\version.txt': '!project_version!'

::##################################################
::  SET PROJECT DIRECTORY
::##################################################
for /f "tokens=* delims=" %%i in ('cygpath -u "%PRJ_DIR%"') do SET "PRJ_DIR_unix=%%~i"
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

doskey uc="%DEV_WORKFLOW_DIR%\update-changelog.bat" $*
doskey uv="%DEV_WORKFLOW_DIR%\update-version.bat" $*
doskey uvr="%DEV_WORKFLOW_DIR%\update-version" rel $*
doskey uvf=cmd /V /C "set "FORCE_UC=1" && "%DEV_WORKFLOW_DIR%\update-version.bat" $*"
doskey gv="%DEV_WORKFLOW_DIR%\get-version.bat"

::  ===============================================
::  CONFIGURE LOCAL PATH MESSAGE
::  ===============================================
set "local_path="
set "local_path_msg="
if "%~1"=="local" ( set "local_path=1" )
echo "%PATH%" | findstr /C:"%PRJ_DIR%\tools" >NUL 2>&1
if not errorlevel 1 ( set "local_path=1" && set "local_path_msg= preserved")
if defined local_path (
  set "local_path_msg= [local%local_path_msg%]"
)
if "%~1"=="force" (
  set "local_path_msg= [forced]"
  set local_path=
)

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
