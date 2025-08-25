@echo off
echo WordPress Installation - Download All Components (CMD Version)
echo ================================================================

echo Downloading all components with latest versions...
echo.

REM Get latest PHP version
echo [1/5] Getting latest PHP 8.x version...
for /f "delims=" %%i in ('powershell -command "try { $releases = Invoke-RestMethod 'https://www.php.net/releases/?json&version=8'; $latest = $releases.PSObject.Properties.Name | Where-Object { $_ -match '^\d+\.\d+\.\d+$' } | Sort-Object {[Version]$_} -Descending | Select-Object -First 1; if (-not $latest) { $latest = '8.3.24' }; Write-Output $latest } catch { Write-Output '8.3.24' }"') do set PHP_VERSION=%%i
echo Latest PHP version: %PHP_VERSION%
curl -L -o "%TEMP%\php-%PHP_VERSION%-nts-Win32-vs16-x64.zip" "https://windows.php.net/downloads/releases/php-%PHP_VERSION%-nts-Win32-vs16-x64.zip"
if %ERRORLEVEL% EQU 0 (
    echo ✅ Downloaded PHP %PHP_VERSION%
) else (
    echo ❌ PHP download failed
)

REM Get latest MariaDB LTS
echo.
echo [2/5] Using stable MariaDB LTS version...
set MARIA_VERSION=10.11.6
echo Using stable MariaDB LTS: %MARIA_VERSION%
curl -L -o "%TEMP%\mariadb-latest-winx64.msi" "https://downloads.mariadb.org/interstitial/mariadb-10.11.6/winx64-packages/mariadb-10.11.6-winx64.msi"
if %ERRORLEVEL% EQU 0 (
    echo ✅ Downloaded MariaDB %MARIA_VERSION%
) else (
    echo ❌ MariaDB download failed
)

REM Download WordPress (already dynamic)
echo.
echo [3/5] Downloading latest WordPress...
curl -L -o "%TEMP%\wordpress-latest.zip" "https://wordpress.org/latest.zip"
echo ✅ Downloaded WordPress (latest)

REM Get latest NSSM version
echo.
echo [4/5] Getting latest NSSM version...
for /f "delims=" %%i in ('powershell -command "$page = Invoke-WebRequest 'https://nssm.cc/download' -UseBasicParsing; $link = ($page.Links | Where-Object { $_.href -match 'nssm-\d+\.\d+\.zip$' } | Select-Object -First 1).href; if ($link) { $version = ($link -split '/')[-1] -replace '\.zip$', ''; Write-Output $version } else { Write-Output 'nssm-2.24' }"') do set NSSM_VERSION=%%i
echo Latest NSSM version: %NSSM_VERSION%
curl -L -o "%TEMP%\%NSSM_VERSION%.zip" "https://nssm.cc/release/%NSSM_VERSION%.zip"
echo ✅ Downloaded %NSSM_VERSION%

REM Download Caddy (already dynamic)
echo.
echo [5/5] Downloading latest Caddy...
curl -L -o "%TEMP%\caddy_windows_amd64.zip" "https://github.com/caddyserver/caddy/releases/latest/download/caddy_windows_amd64.zip"
if %ERRORLEVEL% EQU 0 (
    echo ✅ Downloaded Caddy (latest)
) else (
    echo ❌ Caddy download failed
)

echo.
echo ================================================================
echo All downloads completed successfully!
echo.
echo Downloaded versions:
echo - PHP: %PHP_VERSION%
echo - MariaDB: %MARIA_VERSION%
echo - WordPress: Latest
echo - NSSM: %NSSM_VERSION%
echo - Caddy: Latest
echo.
echo Files saved to: %TEMP%
echo Next: Run the installation scripts or follow the manual installation guide.
echo ================================================================
