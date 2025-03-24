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
  ::  ===============================================
  ::  INITIALIZE DEFAULT VERSION
  ::  ===============================================
  set "project_version=0.1.0-SNAPSHOT"
  echo !project_version!>"%VERSION_TXT_FILE%"
  goto:eof
)

::  ===============================================
::  READ VERSION/TITLE/RELEASE NOTE FROM FILE
::  ===============================================
for /f "tokens=1* delims=- " %%i in ('head -1 "%VERSION_TXT_FILE%"') do (
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