@echo off
setlocal enabledelayedexpansion

echo ===================================================
echo             Arrow Flow - Local Run
echo ===================================================
echo.

cd /d "%~dp0"

REM Step 1: Ensure Web build exists
if not exist "build\web\index.html" (
    echo [1/3] Building Web release with offline resources...
    call flutter build web --no-web-resources-cdn
    if errorlevel 1 (
        echo [ERROR] Flutter web build failed.
        pause
        exit /b 1
    )
) else (
    echo [1/3] Web build found at build\web.
)

REM Step 2: Check if port 8080 is already active
netstat -ano | findstr ":8080" | findstr "LISTENING" >nul 2>&1
if errorlevel 1 (
    echo [2/3] Starting multi-threaded local HTTP server on http://localhost:8080/ ...
    start /B python tool\serve.py 8080 >nul 2>&1
    timeout /t 2 /nobreak >nul
) else (
    echo [2/3] Server already running on http://localhost:8080/.
)

REM Step 3: Launch in standalone mobile window mode
echo [3/3] Launching Arrow Flow in mobile app window (430x932)...

REM Try Chrome in App Mode
where chrome >nul 2>&1
if not errorlevel 1 (
    start chrome --app="http://localhost:8080/" --window-size=430,932
    goto done
)

if exist "%ProgramFiles%\Google\Chrome\Application\chrome.exe" (
    start "" "%ProgramFiles%\Google\Chrome\Application\chrome.exe" --app="http://localhost:8080/" --window-size=430,932
    goto done
)

if exist "%ProgramFiles(x86)%\Google\Chrome\Application\chrome.exe" (
    start "" "%ProgramFiles(x86)%\Google\Chrome\Application\chrome.exe" --app="http://localhost:8080/" --window-size=430,932
    goto done
)

if exist "%LocalAppData%\Google\Chrome\Application\chrome.exe" (
    start "" "%LocalAppData%\Google\Chrome\Application\chrome.exe" --app="http://localhost:8080/" --window-size=430,932
    goto done
)

REM Try Edge in App Mode
where msedge >nul 2>&1
if not errorlevel 1 (
    start msedge --app="http://localhost:8080/" --window-size=430,932
    goto done
)

if exist "%ProgramFiles(x86)%\Microsoft\Edge\Application\msedge.exe" (
    start "" "%ProgramFiles(x86)%\Microsoft\Edge\Application\msedge.exe" --app="http://localhost:8080/" --window-size=430,932
    goto done
)

REM Fallback to default browser
start http://localhost:8080/

:done
echo.
echo ===================================================
echo  Arrow Flow is now running!
echo  URL: http://localhost:8080/
echo  Press any key to close this launcher window.
echo ===================================================
pause >nul
