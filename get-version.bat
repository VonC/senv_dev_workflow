@echo off
::********************************************************************
:: Script Name:  get-version.bat
:: Description:  Retrieves or initializes the project version.
::
:: Parameters:   --maven    Optional: Read version from pom.xml instead
::
:: Usage:        get-version.bat [--maven]
::
:: Returns:      Sets the 'project_version' variable.
::********************************************************************

setlocal enableextensions enabledelayedexpansion

::  ===============================================
::  CHECKING ARGS
::  ===============================================
set "USE_MAVEN="
if "%~1"=="--maven" set "USE_MAVEN=1"

::  ===============================================
::  INITIALIZE PROJECT VARIABLE AND PATH
::  ===============================================
set "QUIET_PRJ="

::  ===============================================
::  CHECK IF VERSION FILE EXISTS
::  ===============================================
if not exist "%VERSION_TXT_FILE%" (
  REM  ===============================================
  REM  INITIALIZE DEFAULT VERSION
  REM  ===============================================
  set "project_version=0.1.0-SNAPSHOT"
  echo !project_version!>"%VERSION_TXT_FILE%"
  goto:eof
)

set "project_version="
::  ===============================================
::  READ VERSION/TITLE/RELEASE NOTE FROM FILE
::  ===============================================
for /f "delims=" %%a in ('head -1 "%VERSION_TXT_FILE%"') do (
  set "first_line=%%a"
)

:: Remove leading # if present
set "first_line=!first_line:#=!"
:: Trim leading spaces
for /f "tokens=*" %%a in ("!first_line!") do set "first_line=%%a"

:: Now parse for version and title
for /f "tokens=1* delims=- " %%i in ("!first_line!") do (
  SET "project_version=%%i"
  SET "project_title=%%j"
)

if not "%project_title:SNAPSHOT -- =%"=="%project_title%" (
  SET "project_version=%project_version%-SNAPSHOT"
  SET "project_title=%project_title:SNAPSHOT -- =%"
)
set "project_release_notes="
for /f "delims=" %%a in ('tail -n +3 "%VERSION_TXT_FILE%"') do (
      set "project_release_notes=!project_release_notes!%%a\n"
)
endlocal & set "project_version=%project_version%" & set "project_title=%project_title%" & set "project_release_notes=%project_release_notes%"
goto:eof
