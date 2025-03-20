@echo off
::********************************************************************
:: Script Name:  get-version.bat
:: Description:  Retrieves or initializes the project version.
::
:: Parameters:   None
::
:: Usage:        get-version.bat
::
:: Returns:      Sets the 'project_version' variable.
::********************************************************************

setlocal enableextensions enabledelayedexpansion

::  ===============================================
::  INITIALIZE PROJECT VARIABLE AND PATH
::  ===============================================
set "QUIET_PRJ=true"
call <NUL "%~dp0..\senv.bat"
set "QUIET_PRJ="

::  ===============================================
::  CHECK IF VERSION FILE EXISTS
::  ===============================================
if not exist "%project_dir%\version.txt" (
  ::  ===============================================
  ::  INITIALIZE DEFAULT VERSION
  ::  ===============================================
  set "project_version=0.1.0-SNAPSHOT"
  echo !project_version!>"%project_dir%\version.txt"
  goto:eof
)

::  ===============================================
::  READ VERSION/TITLE/RELEASE NOTE FROM FILE
::  ===============================================
for /f "tokens=1* delims=- " %%i in ('head -1 "%project_dir%\version.txt"') do (
  SET "project_version=%%i"
  SET "project_title=%%j"
)
if not "%project_title:SNAPSHOT -- =%"=="%project_title%" (
  SET "project_version=%project_version%-SNAPSHOT"
  SET "project_title=%project_title:SNAPSHOT -- =%"
)
set "project_release_notes="
for /f "delims=" %%a in ('tail -n +3 "%project_dir%\version.txt"') do (
      set "project_release_notes=!project_release_notes!%%a\n"
)
endlocal & set "project_version=%project_version%" & set "project_title=%project_title%" & set "project_release_notes=%project_release_notes%"
goto:eof