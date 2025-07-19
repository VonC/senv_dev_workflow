@echo off

setlocal enabledelayedexpansion

for %%i in ("%~dp0") do SET "_git_config_dir=%%~fi"
set "_git_config_dir=%_git_config_dir:~0,-1%"
for %%i in ("%_git_config_dir%\..") do set "dev_workflow_dir=%%~fi"

if not defined _info ( call "%dev_workflow_dir%\batcolors\echos_macros.bat" export )

set "label=%~1"
shift

if not defined label (
  %_fatal% "No label :xxx provided for git_config.bat"
  exit /b 1
)

if "%label::=%"=="%label%" (
  %_fatal% "Invalid label '%label%' provided for git_config.bat, should start with ':'"
  exit /b 1
)

call%label% %*
goto:_eof

:add_prj_config_if_missing
shift
set "git_prj_dir=%PRJ_DIR%"
set "key=%~1"
set "value=%~2"

call:add_config_if_missing "%git_prj_dir%" "%key%" "%value%"
goto:_eof

:add_config_if_missing
set "git_prj_dir=%~1"
set "key=%~2"
set "value=%~3"

%_task% "Must add git config '%key%' if missing, value '%value%', at '%git_prj_dir%'"

pushd "%git_prj_dir%"
if errorlevel 1 (
  %_fatal% "Unable to access directory '%git_prj_dir%'" 11
)

git config get --local "%key%" >NUL
if "%ERRORLEVEL%"=="0" (
  git config get --local %key%
  %_ok% "key '%key%' already present in '%git_prj_dir%\.git\config'"
  popd
  goto:_eof
)

git config "%key%" "%value%"
if errorlevel 1 (
  %_fatal% "Unable to set git config '%key%' with value '%value%' at '%git_prj_dir%'" 12
)
sed -i "s,＂,\\\\\",g" "%git_prj_dir%\.git\config"
if errorlevel 1 (
  %_fatal% "Unable to replace quotes in '%git_prj_dir%\.git\config'" 13
)
sed -i "s,＼,\\\\\\\\,g" "%git_prj_dir%\.git\config"
if errorlevel 1 (
  %_fatal% "Unable to replace solidus in '%git_prj_dir%\.git\config'" 14
)



%_ok% "key '%key%' set to '%value%' in '%git_prj_dir%\.git\config'"

popd
goto:_eof


:_eof
endlocal
goto:eof
