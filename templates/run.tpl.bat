@echo off

for %%i in ("%~dp0") do SET "run_dir=%%~fi"
set "run_dir=%run_dir:~0,-1%"

REM ========================================
REM INITIALIZATION
REM ========================================
set "SKIP_LOCAL=1"
call "%run_dir%\senv.bat"
if exist "%run_dir%\props.bat" (
    call "%run_dir%\props.bat"
)

REM ========================================
REM MAIN EXECUTION LOGIC
REM ========================================

REM Your logic here.
%_info% "Running '%PRJ_DIR_NAME%'"
goto:eof

:call_echos_stack
if not defined ECHOS_STACK ( set "CURRENT_SCRIPT=%~nx0" & goto:eof ) else ( call "%project_dir%\tools\batcolors\echos.bat" :stack %~nx0 )
goto:eof
