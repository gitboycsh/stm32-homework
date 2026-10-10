@echo off
setlocal
cd /d "%~dp0"

set "GIT=D:\Git\Git\cmd\git.exe"
if not exist "%GIT%" set "GIT=git"

echo ============================================================
echo   一键提交本周作业到 GitHub
echo   仓库: gitboycsh/stm32-homework
echo ============================================================
echo.

echo --- 当前改动 ---
"%GIT%" status --short
echo.

set "MSG="
set /p "MSG=请输入本周提交信息 (例如 T2: 定时器中断让 LED 闪烁): "
if "%MSG%"=="" goto NOINFO

echo.
echo --- [1/3] 暂存所有改动 ---
"%GIT%" add .
if errorlevel 1 goto FAIL

echo --- [2/3] 提交 ---
"%GIT%" -c i18n.commitEncoding=UTF-8 commit -m "%MSG%"
if errorlevel 1 echo [提示] 没有新改动需要提交, 直接尝试推送。

echo --- [3/3] 推送到 GitHub ---
"%GIT%" push
if errorlevel 1 goto FAIL

echo.
echo ============================================================
echo   [OK] 提交并推送成功!
echo   查看: https://github.com/gitboycsh/stm32-homework
echo ============================================================
echo.
echo --- 最近 3 次提交 ---
"%GIT%" log --oneline -3
echo.
pause
exit /b 0

:NOINFO
echo.
echo [X] 提交信息不能为空, 已取消。
echo.
pause
exit /b 1

:FAIL
echo.
echo [X] 操作失败。常见原因:
echo     - 网络不通 (试试能否打开 github.com)
echo     - 需要重新登录 GitHub (会弹出浏览器窗口让你授权)
echo.
pause
exit /b 1
