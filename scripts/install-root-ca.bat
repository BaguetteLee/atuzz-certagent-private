@echo off
rem ==============================================================================
rem Atuzz CertAgent Private - Enterprise Root CA Windows Silent Installer
rem Environments: Windows 10 / 11 / Windows Server 2012 / 2016 / 2019 / 2022 (IIS)
rem ==============================================================================

chcp 65001 >nul 2>&1
setlocal enabledelayedexpansion

echo ============================================================
echo   Atuzz CertAgent Private - Root CA Trust Store Installer
echo ============================================================
echo.

rem 1. Check Administrator privileges
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [!] Requesting administrative privileges. Please click YES on the UAC prompt...
    powershell -Command "Start-Process cmd -ArgumentList '/c \"\"%~f0\" %*\"' -Verb RunAs"
    exit /b
)

set "SCRIPT_DIR=%~dp0"
set "TARGET_CRT=%SCRIPT_DIR%root-ca.crt"
set "SERVER_URL=%~1"
if "!SERVER_URL!"=="" (
    set "INJECTED_HUB_URL=__HUB_URL_PLACEHOLDER__"
    if not "!INJECTED_HUB_URL!"=="__HUB_URL_PLACEHOLDER__" (
        set "SERVER_URL=!INJECTED_HUB_URL!"
    )
)

rem 2. If root-ca.crt does not exist locally, download from server
if not exist "!TARGET_CRT!" (
    if "!SERVER_URL!"=="" (
        echo [!] root-ca.crt not found in current directory.
        set /p SERVER_URL="Please enter CertAgent Hub URL (e.g. http://192.168.1.100:3000): "
    )

    if not "!SERVER_URL!"=="" (
        echo [*] Downloading Root CA from !SERVER_URL!...
        set "DOWNLOAD_URL=!SERVER_URL!/api/ca/root-cert?download=1&format=der"
        powershell -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; try { (New-Object System.Net.WebClient).DownloadFile('!DOWNLOAD_URL!', '!TARGET_CRT!'); Write-Host '[+] Root CA downloaded successfully' } catch { Write-Host '[-] Download failed: ' $_.Exception.Message; exit 1 }"
        if !errorLevel! neq 0 (
            echo [-] Failed to download Root CA. Please check network connection or Hub URL.
            pause
            exit /b 1
        )
    ) else (
        echo [-] Missing root CA certificate and no Hub URL provided. Aborted.
        pause
        exit /b 1
    )
)

echo [*] Importing Root CA into Trusted Root Certification Authorities (LocalMachine\Root)...
certutil -addstore -f "Root" "!TARGET_CRT!" >nul 2>&1

if %errorLevel% equ 0 (
    echo.
    echo ============================================================
    echo  [√] Enterprise Root CA installation complete!
    echo ============================================================
    echo  - Browsers (Chrome, Edge) will now display green locks for internal HTTPS sites.
    echo  - IIS host and local inter-service calls will trust certificates issued by this CA.
    echo.
) else (
    echo.
    echo [-] Failed to import certificate, exit code: %errorLevel%
    echo     Please try running manually: certutil -addstore -f "Root" "!TARGET_CRT!"
    echo.
)

if "%~2"=="/silent" goto :EOF
pause
