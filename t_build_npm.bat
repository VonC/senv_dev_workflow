@echo off

:: t_build_npm.bat - NPM version management utility
:: Usage:
::    "  t_build_npm.bat get            - Gets the current version from package.json"
::    "  t_build_npm.bat set version    - Sets the version in package.json"
::    "  t_build_npm.bat check-snapshot - Checks if version contains -SNAPSHOT"

::  ===============================================
::  INITIAL SETUP
::  ===============================================
for %%i in ("%~dp0") do SET "t_build_npm_dir=%%~fi"
set "t_build_npm_dir=%t_build_npm_dir:~0,-1%"

call <NUL "%PRJ_DIR%\senv.bat"

if not exist %PACKAGE_JSON_FILE% ( %_fatal% "Error: '%PACKAGE_JSON_FILE%' not found in the current directory." 1)

::  ===============================================
::  ARGS PARSING
::  ===============================================

if "%~1"=="" (
    %_info% "Usage:"
    %_info% "  t_build_npm.bat get            - Gets the current version from %PACKAGE_JSON_FILE%"
    %_info% "  t_build_npm.bat set version    - Sets the version in %PACKAGE_JSON_FILE%"
    %_info% "  t_build_npm.bat check-snapshot - Checks if version contains -SNAPSHOT"
    exit /b 1
)

if /i "%~1"=="get" (
    call :get_version
    exit /b 0
)

if /i "%~1"=="set" (
    if "%~2"=="" (
        %_error% "Error: Version parameter is required for 'set' mode."
        %_fatal% "Usage: t_build_npm.bat set version" 2
    )
    call :set_version "%~2"
    exit /b 0
)

if /i "%~1"=="check-snapshot" (
    call :check_snapshot
    exit /b %ERRORLEVEL%
)

%_info% "Usage:"
%_info% "  t_build_npm.bat get           - Gets the current version from '%PACKAGE_JSON_FILE%'"
%_info% "  t_build_npm.bat set version   - Sets the version in '%PACKAGE_JSON_FILE%'"
%_fatal% "Unknown command: '%~1'" 3

::  ===============================================
::  GET VERSION
::  ===============================================
:get_version
    %_task% "Must get version from '%PACKAGE_JSON_FILE%'"
    
    setlocal EnableDelayedExpansion
    set "version_npm="

    for /f "tokens=* usebackq" %%a in (`sed -n 's/.*"version": "\(.*\)"/\1/p' "%PACKAGE_JSON_FILE%" ^| sed "s/,//g"`) do (
    set "version_npm=%%a"
    goto :version_found
)
	%_fatal% "Error: Could not find version information in '%PACKAGE_JSON_FILE%'" 4
	exit /b 1

:version_found
    if defined version_npm (
        %_ok% "Current version: !version_npm!"
        endlocal & set "version_npm=%version_npm%"
    ) else (
        endlocal
        %_fatal% "Error: Could not find version information in '%PACKAGE_JSON_FILE%'" 4
    )
    exit /b 0

::  ===============================================
::  SET VERSION
::  ===============================================
:set_version
    set "new_version=%~1"
    
    %_task% "Must set version to '%new_version%'"

	sed -i "s/\"version\": \".*\"/\"version\": \"%new_version%\"/" %PACKAGE_JSON_FILE%
    if %ERRORLEVEL% neq 0 (
        %_fatal% "Error: Failed to update version in '%PACKAGE_JSON_FILE%'" 5
        exit /b 1
    )
    
    %_ok% "NPM version successfully updated to '%new_version%'"
    exit /b 0

::  ===============================================
::  CHECK IF VERSION IS A SNAPSHOT
::  ===============================================
:check_snapshot
    call :get_version
    if %ERRORLEVEL% neq 0 exit /b %ERRORLEVEL%
    
    echo %version_npm% | findstr /C:"-SNAPSHOT" >nul
    if %ERRORLEVEL% equ 0 (
        %_info% "Current version is a SNAPSHOT: '%version_npm%'"
        exit /b 0
    ) else (
        %_info% "Current version is not a SNAPSHOT: '%version_npm%'"
        exit /b 1
    )

:call_echos_stack
if not defined ECHOS_STACK ( set "CURRENT_SCRIPT=%~nx0" & goto:eof ) else ( call "%project_dir%\tools\batcolors\echos.bat" :stack %~nx0 )
goto:eof