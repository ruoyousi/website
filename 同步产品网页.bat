@echo off
setlocal enabledelayedexpansion
rem ==========================================================================
rem  同步产品网页
rem  把各产品的落地页复制到本目录下的同名子目录，供清单页点击进入。
rem
rem  子目录命名规则：产品英文名
rem    DocMerger / FlowWrite / OffOCR / Lovo / Transly / FocusOn / AI-Prompt-Helper
rem
rem  用法：
rem    同步产品网页.bat                 覆盖复制（保留目标目录中的多余文件）
rem    同步产品网页.bat --clean         先清空目标目录中源不存在的文件，再复制
rem    同步产品网页.bat --no-pause      结束时不等待按键（供脚本调用）
rem    参数可组合，例如： 同步产品网页.bat --clean --no-pause
rem
rem  说明：源仅限各产品的 website 落地页目录，按下面的排除清单剔除
rem        构建产物、助手数据、截图存档、封面文案，以及未被落地页引用的素材。
rem ==========================================================================

rem 源仓库根目录 = 本脚本所在目录的上一级
for %%I in ("%~dp0..") do set "REPO_ROOT=%%~fI"
set "DEST_ROOT=%~dp0"

rem 排除内容
rem   目录：构建产物 / 助手数据 / 截图存档 / 封面
set "EX_DIRS=.build .workbuddy _shots _backup covers __pycache__"
rem   文件：仓库截图 / 文案素材 / 未被落地页引用的宣传片
set "EX_FILES=screenshot.jpeg 文案.txt 视频号文案.md 心流写作-FlowWrite.mp4"

set "PURGE="
set "NOPAUSE="
:ARGS
if "%~1"=="" goto :ARGS_DONE
if /i "%~1"=="--clean"    set "PURGE=/PURGE"
if /i "%~1"=="--no-pause" set "NOPAUSE=1"
shift
goto :ARGS
:ARGS_DONE

set /a OK=0
set /a SKIP=0
set /a FAIL=0

echo.
echo   源仓库：%REPO_ROOT%
echo   输出到：%DEST_ROOT%
if defined PURGE echo   模式：覆盖复制 + 清理目标多余文件（--clean）
echo --------------------------------------------------------------------------

call :SYNC "DocMerger\website"                      DocMerger
call :SYNC "FlowWrite\website"                      FlowWrite
call :SYNC "OffOCR\website"                         OffOCR
call :SYNC "voice-toolbox\website"                  Lovo
call :SYNC "lang-translator\website"                Transly
call :SYNC "personal-workbench\website"             FocusOn
call :SYNC "AI\AI 绘画提示词生成助手\website"        AI-Prompt-Helper

echo --------------------------------------------------------------------------
echo   完成：成功 %OK% 个，跳过 %SKIP% 个，失败 %FAIL% 个
echo.

if defined NOPAUSE goto :END
pause
:END
endlocal
exit /b 0

rem ==========================================================================
rem  :SYNC  <源目录（相对仓库根）>  <目标子目录名>
rem ==========================================================================
:SYNC
setlocal
set "SRC=%~1"
set "DEST=%~2"

if not exist "%REPO_ROOT%\%SRC%\index.html" goto :SYNC_MISSING

rem /E 含空目录 /IS 相同文件也覆盖（源文件时间戳可能更旧） /XD /XF 排除清单
robocopy "%REPO_ROOT%\%SRC%" "%DEST_ROOT%%DEST%" /E /IS %PURGE% /XD %EX_DIRS% /XF %EX_FILES% /R:1 /W:1 /NFL /NDL /NJH /NJS /NP >nul
if errorlevel 8 goto :SYNC_FAIL

echo   [完成] %DEST%\  ^<- %SRC%
endlocal & set /a OK+=1
exit /b

:SYNC_MISSING
echo   [跳过] %DEST%  未找到 %SRC%\index.html
endlocal & set /a SKIP+=1
exit /b

:SYNC_FAIL
echo   [失败] %DEST%  robocopy 错误码 !errorlevel!
endlocal & set /a FAIL+=1
exit /b
