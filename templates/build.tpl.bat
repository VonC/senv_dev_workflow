@echo off

::********************************************************************
:: Script Name:  build.bat
:: Description:  Builds the project and handles version updates.
::
:: Parameters:
::    %1 - Build parameters (e.g., rel, rel_title)
::
:: Usage:
::    build.bat rel
::    build.bat rel "rel_title=Release Title"
::    build.bat prj_error: fail the build (for testing)
::
::    With aliases b or brel:
::    b a b "cc dd" "rel_title=my title" "ee ff" gg    # no release made, rel missing
::    b rel
::    brel "rel_title=Initial project template"
::    brel a "e f" "rel_title=Initial project template" "g t h"
::    b a rel "e f" "rel_title=Initial project template" "g t h"
::    b a rel "e f" prj_error "rel_title=Initial project template" "g t h"
::
:: Return Value: 0 - Success, 1 - Error
::********************************************************************

::  ===============================================
::  INITIAL SETUP
::  ===============================================
for %%i in ("%~dp0") do SET "build_dir=%%~fi"
set "build_dir=%build_dir:~0,-1%"

call "%build_dir%\senv.bat"
call "%build_dir%\tools\dev_workflow\t_build.bat" :pre-processing %*

REM Unicode characters would render the file unusable if interpreted as commands too early
REM So exit early to avoid CMD to interpret the rest of the file as commands
call:_build_project
exit /b

:_build_project
::  ===============================================
::  BUILD PROJECT
::  ===============================================
%_stack_call% "%build_dir%\tools\dev_workflow\get-version.bat"

rem Pre-build steps here, if needed. For instance:
rem call:update_tailwindcss_if_needed
rem call:setup_security_certificates_if_needed
rem call: any_other_pre_build_step_function...

%_info% "----------------------------------------"
%_info% "Build the project '%PRJ_DIR_NAME%', version '%project_version%'"
%_info% "----------------------------------------"

set "params=%*"

REM build_params_echos is set by tools\dev_workflow\t_build.bat :pre-processing
REM it replaces " by ‟: the "Double High-Reversed-9 Quotation Mark" (U+201F) for preserving double quotes in params

%_task% "Start build of '%PRJ_DIR_NAME%' with build_params '%build_params_echos%'"

REM you build commands here. For instance:
rem set "cmd=mvn -U clean install %build_params%"
set "cmd=echo my build command here with params %build_params%"
%_info% "%cmd:"=‟%"
set "QUIET_PRJ=true"
call <NUL %cmd%
set "build_status=%ERRORLEVEL%"
set "QUIET_PRJ=true"
REM check if this build is a release build for which a "valid" marker needs to be created
REM The marker is set on the tag created for that release for which the build has just been done.
call "%build_dir%\tools\dev_workflow\t_build.bat" :post-processing %build_status%
call:build_unset
goto:eof


::##################################################
::  CLEANUP
::##################################################

:build_unset
set "cmd="
call "%build_dir%\senv.bat" unset
call "%build_dir%\tools\dev_workflow\t_build.bat" :build_unset
set "build_dir="
goto:eof

::##################################################
::  ECHOS STACK (called by echos.bat)
::##################################################

:call_echos_stack
if not defined ECHOS_STACK ( set "CURRENT_SCRIPT=%~nx0" & goto:eof ) else ( call "%PRJ_DIR%\tools\batcolors\echos.bat" :stack %~nx0 )
goto:eof
