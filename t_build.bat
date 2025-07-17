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
rem echo First param '%~1'
if "%~1"=="" goto:end
if "%~1"=="rel" (
    set "build_params-uv=!build_params-uv!!sp-uv!^"%~1^""
    set "sp-uv= "
    goto:continue
)
if "%~1"=="snap" (
    set "build_params-uv=!build_params-uv!!sp-uv!^"%~1^""
    set "sp-uv= "
    rem echo added
    goto:continue
)
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

:continue
shift
rem echo build_params-uv='!build_params-uv!'
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
  call "%DEV_WORKFLOW_DIR%\batcolors\echos.bat" :fatal "update-version FAILED, code '%ERRORLEVEL%'" 3
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
  if not "%project_version:-SNAPSHOT=%"=="%project_version%" (
    %_info% "Snapshot version (v%project_version%'), no tag to validate"
    goto:eof
  )
  %_task% "Must check if tag 'v%project_version%' is already marked as valid..."
  call:is_tag_valid "v%project_version%"
  if "!IS_VALID!"=="true" (
      %_ok% "Tag 'v%project_version%' is already marked as valid. No action needed."
  ) else (
      %_warning% "Tag 'v%project_version%' is not marked as valid."
      %_task% "Must update Tag 'v%project_version%' as valid..."
      call:make_tag_valid "v%project_version%"
      if errorlevel 1 (
        %_fatal% "Unable to update Tag 'v%project_version%' as valid" 165
      )
      %_ok% "Tag 'v%project_version%' is now marked as valid."
  )
) else (
  %_error% "project '%PRJ_DIR_NAME%' build FAILED for version '%project_version%' (code '%~1')"
  if "%project_version:-SNAPSHOT=%"=="%project_version%" (
    call:is_tag_valid "v%project_version%"
    call:has_a_release_just_been_made
    if defined a_release_has_just_been_made (
      if "!IS_VALID!"=="false" (
        %_warning% "A release has just been made, but the tag 'v%project_version%' is not marked as valid ('!IS_VALID!'): cancel release"
        set "a_release_has_just_been_made="
        rem %_fatal% "Stop before :reset_pre_release: IS_VALID='%IS_VALID%', with delay: '!IS_VALID!'"
        call:reset_pre_release
      ) else (
        %_warning% "A release has just been made, but the tag 'v%project_version%' is marked as valid ('!IS_VALID!'): do NOT cancel release"
      )
    ) else (
      %_warning% "No release was just made, just unset build"
    )
  ) else (
    %_info% "Snapshot version (v%project_version%'), no tag to invalidate"
  )
  call:build_unset
  call "%DEV_WORKFLOW_DIR%\batcolors\echos.bat" :fatal "project '%PRJ_DIR_NAME%' build FAILED, code '%ERRORLEVEL%'" 3
)
goto:eof

::##################################################
::  MAKE TAG VALID
::  Updates a Git tag to include the [valid] marker
::
::  Parameters:
::    %1 - Tag name to validate (e.g., "v1.2.3")
::
::  Return Value:
::    errorlevel - 0 for success, non-zero for failure
::##################################################
:make_tag_valid
set "TAG_NAME=%~1"
set "TEMP_TAG_FILE=%t_build_dir%\temp_tag_message.txt"
%_info% "Dumping tag '%TAG_NAME%' message to a temporary file..."
:: Get the full, multi-line tag message and save it to a file.
git -C "%PRJ_DIR%" tag -n9999 --format="%%(contents)" %TAG_NAME% > "%TEMP_TAG_FILE%"
if errorlevel 1 (
  %_fatal% "Unable to dump tag '%TAG_NAME%' message to temporary file '%TEMP_TAG_FILE%'" 151
)
%_info% "Appending '[valid]' marker to the file..."
:: Append the validation marker to the message file.
echo.>> "%TEMP_TAG_FILE%"
echo [valid]>> "%TEMP_TAG_FILE%"
if errorlevel 1 (
  %_fatal% "Unable to append '[valid]' marker to the temporary file '%TEMP_TAG_FILE%'" 152
)

%_info% "Re-tagging '%TAG_NAME%' with the updated message..."
:: Force-update the annotated tag using the content from the file.
git -C "%PRJ_DIR%" tag -a -f %TAG_NAME% -F "%TEMP_TAG_FILE%"
if errorlevel 1 (
  %_fatal% "Unable to Force-update the annotated tag '%TAG_NAME%' using the content from the temporary file '%TEMP_TAG_FILE%'" 153
)
goto:eof

::##################################################
::  IS TAG VALID
::  Checks if a Git tag contains the [valid] marker
::
::  Parameters:
::    %1 - Tag name to validate (e.g., "v1.2.3")
::
::  Return Value:
::    Sets IS_VALID=true if the tag is valid,
::    IS_VALID=false otherwise
::##################################################
:is_tag_valid
set "TAG_NAME=%~1"
set "IS_VALID=false"
:: Check if the tag's annotated message contains the '[valid]' marker.
git -C "%PRJ_DIR%" tag -l --format="%%(contents)" %TAG_NAME% | findstr /C:"[valid]" >nul 2>&1
if %errorlevel% equ 0 (
    set "IS_VALID=true"
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
