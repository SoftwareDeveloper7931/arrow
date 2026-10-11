<#
.SYNOPSIS
    Arrow Flow - Local Development & Launch Utility
.DESCRIPTION
    Runs the Arrow Flow puzzle game locally on Windows.
    Options:
      1. Standalone Mobile App Window (Fast release mode via local server)
      2. Flutter Debug Mode (Live code editing & hot reload via Chrome)
      3. Rebuild Production Web Build
      4. Run All Tests
#>

param(
    [ValidateSet("app", "debug", "rebuild", "test")]
    [string]$Mode = "app"
)

$ErrorActionPreference = "Stop"
Set-Location -Path $PSScriptRoot

Write-Host "===================================================" -ForegroundColor Cyan
Write-Host "             Arrow Flow - Local Run                " -ForegroundColor Cyan
Write-Host "===================================================" -ForegroundColor Cyan
Write-Host ""

function Start-AppMode {
    Write-Host "[1/3] Checking web build..." -ForegroundColor Yellow
    if (-not (Test-Path "build\web\index.html")) {
        Write-Host "Building web release bundle..." -ForegroundColor Gray
        flutter build web
    } else {
        Write-Host "Web bundle ready in build\web" -ForegroundColor Green
    }

    Write-Host "[2/3] Checking local server on port 8080..." -ForegroundColor Yellow
    $portActive = $false
    try {
        $tcp = New-Object System.Net.Sockets.TcpClient
        $tcp.Connect("127.0.0.1", 8080)
        $tcp.Close()
        $portActive = $true
    } catch {
        $portActive = $false
    }

    if (-not $portActive) {
        Write-Host "Starting background web server..." -ForegroundColor Gray
        Start-Process python -ArgumentList "-m http.server 8080 --directory build/web" -WindowStyle Hidden
        Start-Sleep -Seconds 2
    } else {
        Write-Host "Server already responding on port 8080" -ForegroundColor Green
    }

    Write-Host "[3/3] Opening standalone mobile frame (430x932)..." -ForegroundColor Yellow
    $launched = $false
    
    # Try Chrome
    $chromePaths = @(
        (Get-Command chrome.exe -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source),
        "$env:ProgramFiles\Google\Chrome\Application\chrome.exe",
        "${env:ProgramFiles(x86)}\Google\Chrome\Application\chrome.exe",
        "$env:LocalAppData\Google\Chrome\Application\chrome.exe"
    )

    foreach ($path in $chromePaths) {
        if ($path -and (Test-Path $path)) {
            Start-Process $path -ArgumentList "--app=http://localhost:8080/","--window-size=430,932"
            $launched = $true
            break
        }
    }

    # Try Edge if Chrome not available
    if (-not $launched) {
        $edgePaths = @(
            (Get-Command msedge.exe -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source),
            "${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe"
        )
        foreach ($path in $edgePaths) {
            if ($path -and (Test-Path $path)) {
                Start-Process $path -ArgumentList "--app=http://localhost:8080/","--window-size=430,932"
                $launched = $true
                break
            }
        }
    }

    # Fallback to default browser
    if (-not $launched) {
        Start-Process "http://localhost:8080/"
    }

    Write-Host ""
    Write-Host "===================================================" -ForegroundColor Green
    Write-Host "  Arrow Flow is running at: http://localhost:8080/  " -ForegroundColor Green
    Write-Host "===================================================" -ForegroundColor Green
}

function Start-DebugMode {
    Write-Host "Launching Flutter with live hot-reload in Chrome..." -ForegroundColor Cyan
    flutter run -d chrome
}

function Invoke-Rebuild {
    Write-Host "Rebuilding production web application..." -ForegroundColor Cyan
    flutter build web
    Write-Host "Web build completed successfully!" -ForegroundColor Green
}

function Invoke-Tests {
    Write-Host "Running Flutter test suite..." -ForegroundColor Cyan
    flutter test
}

switch ($Mode) {
    "app"     { Start-AppMode }
    "debug"   { Start-DebugMode }
    "rebuild" { Invoke-Rebuild }
    "test"    { Invoke-Tests }
}
