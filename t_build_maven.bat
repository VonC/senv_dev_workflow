@echo off

:: t_build_maven.bat - Maven version management utility
:: Usage:
::    "  t_build_maven.bat get            - Gets the current version from pom.xml"
::    "  t_build_maven.bat set version    - Sets the version in pom.xml"
::    "  t_build_maven.bat check-snapshot - Checks if version is a SNAPSHOT"

::  ===============================================
::  INITIAL SETUP
::  ===============================================
for %%i in ("%~dp0") do SET "t_build_maven_dir=%%~fi"
set "t_build_maven_dir=%t_build_maven_dir:~0,-1%"

call <NUL "%PRJ_DIR%\senv.bat"

if not exist "%POM_FILE%" ( %_fatal% "Error: '%POM_FILE%' not found in the current directory." 1)


::  ===============================================
::  ARGS PARSING
::  ===============================================

if "%~1"=="" (
    %_info% "Usage:"
    %_info% "  t_build_maven.bat get            - Gets the current version from pom.xml"
    %_info% "  t_build_maven.bat set version    - Sets the version in pom.xml"
	%_info% "  t_build_maven.bat check-snapshot - Checks if version is a SNAPSHOT"
    exit /b 1
)

if /i "%~1"=="get" (
    call :get_version
    exit /b 0
)

if /i "%~1"=="set" (
    if "%~2"=="" (
        %_error% "Error: Version parameter is required for 'set' mode."
        %_fatal% "Usage: t_build_maven.bat set version" 2
    )
    call :set_version "%~2"
    exit /b 0
)

if /i "%~1"=="check-snapshot" (
    call :check_snapshot
    exit /b %ERRORLEVEL%
)

%_info% "Usage:"
%_info% "  t_build_maven.bat get           - Gets the current version from pom.xml"
%_info% "  t_build_maven.bat set version   - Sets the version in pom.xml"
%_fatal% "Unknown command: '%~1'" 3

::  ===============================================
::  GET VERSION
::  ===============================================
:get_version
    %_task% "Must get version from '%POM_FILE%'"
    
    setlocal EnableDelayedExpansion
    set "version_pom="

    for /f "tokens=*" %%a in ('powershell "%DEV_WORKFLOW_DIR%\mvn_get_version.ps1" "%POM_FILE%"') do (
        set "version_pom=%%a"
        goto :version_found
    )

:version_found
    if defined version_pom (
        %_ok% "Current version: !version_pom!"
        endlocal & set "version_pom=%version_pom%"
    ) else (
        endlocal
        %_fatal% "Error: Could not find version information in '%POM_FILE%'" 4
    )
    
    REM Make version_pom globally available
    if not "%version_pom%"=="" (
        set "version_pom=%version_pom%"
    )
    exit /b 0
::  ===============================================
::  SET VERSION
::  ===============================================
:set_version
    set "new_version=%~1"
    set "has_revision="
    
	%_task% "Must get version to '%new_version%'"


    :: Check if version is managed by revision property
    for /f "tokens=*" %%i in ('findstr /C:"<revision>" "%POM_FILE%"') do (
        set "has_revision=1"
    )
    
    if defined has_revision (
        setlocal EnableDelayedExpansion
        %_info% "Updating revision property to %new_version%..."
        :: Using PowerShell for its more powerful text processing capabilities
        sed -i "s/<revision>[^<]*<\/revision>/<revision>%new_version%<\/revision>/g" "%POM_FILE%"
        if !errorlevel! neq 0 (
            endlocal
            %_fatal% "Error: Failed to update revision property." 5
        )
        endlocal
    ) else (
        %_info% "Updating version using Maven..."
        call mvn versions:set -DnewVersion=%new_version% -DgenerateBackupPoms=false
        if !errorlevel! neq 0 (
            %_fatal% "Error: Maven version update failed." 6
            exit /b 1
        )
    )
    
    %_ok% "Maven version successfully updated to %new_version%"
    exit /b 0

::  ===============================================
::  CHECK IF VERSION IS A SNAPSHOT
::  ===============================================
:check_snapshot
    call :get_version
    if %ERRORLEVEL% neq 0 exit /b %ERRORLEVEL%

    echo %version_pom% | findstr /C:"-SNAPSHOT" >nul
    if %ERRORLEVEL% equ 0 (
        %_info% "Current version is a SNAPSHOT: %version_pom%"
        exit /b 0
    ) else (
        %_info% "Current version is not a SNAPSHOT: %version_pom%"
        exit /b 1
    )

:call_echos_stack
if not defined ECHOS_STACK ( set "CURRENT_SCRIPT=%~nx0" & goto:eof ) else ( call "%PRJ_DIR%\tools\batcolors\echos.bat" :stack %~nx0 )
goto:eof