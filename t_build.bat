@echo off

::********************************************************************
:: Script Name:  t_build.bat
:: Description:  Builds utilities for pre and post-build processing.
::
:: Parameters:
::    %1 - section, then build parameters (e.g., rel, rel_title)
::
:: Usage:
::    t_build.bat pre-processing rel
::    t_build.bat pre-processing rel_title "Release Title"
::    t_build.bat pre-processing prj_error: fail the build (for testing)
:: Return Value: build_params and build_must_fail
::
::    t_build.bat post-processing build_status
:: Return Value: 0 - Success, 1 - Error
::
::********************************************************************

::  ===============================================
::  INITIAL SETUP
::  ===============================================
for %%i in ("%~dp0") do SET "t_build_dir=%%~fi"
set "t_build_dir=%t_build_dir:~0,-1%"

call <NUL "%PRJ_DIR%\senv.bat"

call %*
exit /b

::##################################################
::  PRE-PROCESSING: PARSE ARGS, CALLS UPDATE-VERSION
::##################################################
:pre-processing

::  ===============================================
::  PARSE PARAMETERS (ones for build, ones for update-version)
::  ===============================================
setlocal enabledelayedexpansion
set "build_params="
set "build_params-uv="
set "sp="
set "sp-uv="
set "PRJ_REL_TITLE="
set "build_must_fail="
:loop
if "%~1"=="" goto:end
if "%~1"=="rel" (
    set "build_params-uv=!build_params-uv!!sp-uv!^"%~1^""
    set "sp-uv= "
) else (
    set "a_param=%~1"
    if "!a_param:rel_title=!" neq "!a_param!" (
      set "PRJ_REL_TITLE=!a_param:rel_title=!"
      set "PRJ_REL_TITLE=!PRJ_REL_TITLE:~1!"
      goto:continue
    )
    if "!a_param!"=="prj_error" (
      set "build_must_fail=fail"
      goto:continue
    )
    set "build_params=!build_params!!sp!^"%~1^""
    set "sp= "
)
:continue
shift
goto loop
:end
endlocal & set "build_params=%build_params%" & set "build_params-uv=%build_params-uv%" & set "PRJ_REL_TITLE=%PRJ_REL_TITLE%" & set "build_must_fail=%build_must_fail%"

set "build_params_echos="
if not defined build_params ( goto:build_params-uv_echos )
setlocal enabledelayedexpansion
  set "build_params_echos=%build_params:"=‟%"
endlocal & set "build_params_echos=%build_params_echos%"

:build_params-uv_echos
set "build_params-uv_echos="
if not defined build_params-uv ( goto:info_params )
  setlocal enabledelayedexpansion
  set "build_params-uv_echos=%build_params-uv:"=‟%"
endlocal & set "build_params-uv_echos=%build_params-uv_echos%"

:info_params
%_info% "build_params for build: '%build_params_echos%'"
%_info% "build_params for update-version (rel for 'make release'): '%build_params-uv_echos%'"
if defined PRJ_REL_TITLE (
  %_info% "Release title PRJ_REL_TITLE: '%PRJ_REL_TITLE%'"
)

::  ===============================================
::  UPDATE VERSION
::  ===============================================
%_stack_call% "%t_build_dir%\update-version.bat" %build_params-uv%
if errorlevel 1 (
  call:build_unset
  call "%~dp0\tools\batcolors\echos.bat" :fatal "update-version FAILED, code '%ERRORLEVEL%'" 3
  goto:eof
)
set "QUIET_PRJ="

goto:eof

::##################################################
::  POST-PROCESSING: CHECK BUILD RESULT, CANCEL RELEASE IF FAILED
::##################################################
:post-processing
if "%~1"=="0" (
  %_ok% "project '%PRJ_DIR_NAME%' build successful"
) else (
  %_error% "project '%PRJ_DIR_NAME%' build FAILED for version '%project_version%'"
  call:has_a_release_just_been_made
  if defined a_release_has_just_been_made (
    set "a_release_has_just_been_made="
    call:reset_pre_release
  )
  call:build_unset
  call "%~dp0batcolors\echos.bat" :fatal "project '%PRJ_DIR_NAME%' build FAILED, code '%ERRORLEVEL%'" 3
)
goto:eof

::##################################################
::  CHECK IF A RELEASE HAS JUST BEEN MADE
::##################################################
:has_a_release_just_been_made
set "a_release_has_just_been_made="

for /f "delims=" %%i in ('git -C "%PRJ_DIR%" tag --points-at HEAD') do (
    if "%%i"=="v%project_version%" (
        set "a_release_has_just_been_made=true"
        %_info% "[%~nx0] A release has just been made"
        goto:eof
    )
)
%_info% "[%~nx0] No release has been made (nothing to cancel/reset)"
goto:eof


::##################################################
::  RESET PRE-RELEASE BECAUSE BUILD FAILED
::##################################################
:reset_pre_release
%_task% "[%~nx0] Must reset pre-release state (build failed): git reset, git tag -d 'v%project_version%'"
git -C "%PRJ_DIR%" reset @~1
if errorlevel 1 ( %_fatal% "[%~nx0] Unable to reset hard to previous commit of '%PRJ_DIR%'" 311 )
%_ok% "[%~nx0] Git repository reset to previous commit"
git -C "%PRJ_DIR%" tag -d "v%project_version%"
if errorlevel 1 ( %_fatal% "[%~nx0] Unable to delete git tag 'v%project_version%' of '%PRJ_DIR%'" 312 )
%_ok% "[%~nx0] Git tag 'v%project_version%' deleted"
goto:eof


::##################################################
::  CLEANUP
::##################################################

:build_unset
set "cmd="
set "build_params="
set "build_params-uv="
set "SKIP_LOCAL="
echo t_build.bat
call <NUL "%PRJ_DIR%\senv.bat" unset
set "t_build_dir="
set "PRJ_REL_TITLE="
set "build_must_fail="
set "called_from_build="
set "build_params_echos="
set "build_params-uv_echos="
set "params-uv="
set "a_release_has_just_been_made="
set "QUIET_PRJ="
goto:eof

:call_echos_stack
if not defined ECHOS_STACK ( set "CURRENT_SCRIPT=%~nx0" & goto:eof ) else ( call "%t_build_dir%\tools\batcolors\echos.bat" :stack %~nx0 )
goto:eof