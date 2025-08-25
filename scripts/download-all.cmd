@echo off
echo WordPress Installation - Download All Components (CMD Version)
echo ================================================================

echo Downloading all components with latest versions...
echo.

REM Get latest PHP version
echo [1/5] Getting latest PHP 8.x version...
for /f "usebackq delims=" %%i in (`powershell -NoProfile -Command "try { $releases = Invoke-RestMethod \"https://www.php.net/releases/?json^&version=8\"; $latest = $releases.PSObject.Properties.Name ^| Where-Object { $_ -match \"^\d+\.\d+\.\d+$\" } ^| Sort-Object {[Version]$_} -Descending ^| Select-Object -First 1; if (-not $latest) { $latest = \"8.3.24\" }; Write-Output $latest } catch { Write-Output \"8.3.24\" }"`) do set PHP_VERSION=%%i
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
echo [3/3] Downloading latest WordPress...
curl -L -o "%TEMP%\wordpress-latest.zip" "https://wordpress.org/latest.zip"
echo ✅ Downloaded WordPress (latest)

echo.
echo ================================================================
echo All downloads completed successfully!
echo.
echo Downloaded versions:
echo - PHP: %PHP_VERSION%
echo - MariaDB: %MARIA_VERSION%
echo - WordPress: Latest
echo.
echo Files saved to: %TEMP%
echo ================================================================

REM Check what's already installed
echo.
echo Checking existing installations...

REM Check PHP
set PHP_INSTALLED=false
php -v >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo ✅ PHP is already installed and in PATH
    set PHP_INSTALLED=true
) else (
    if exist "C:\Tools\PHP\php.exe" (
        echo ⚠️  PHP found at C:\Tools\PHP but not in PATH
        set PHP_INSTALLED=true
    ) else (
        echo ❌ PHP not installed
    )
)

REM Check MariaDB
set MARIA_INSTALLED=false
sc query MariaDB >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo ✅ MariaDB service found
    set MARIA_INSTALLED=true
) else (
    REM Check if MariaDB is installed but service not created
    if exist "C:\Program Files\MariaDB*" (
        echo ⚠️  MariaDB installation found but service not configured
        set MARIA_INSTALLED=true
    ) else (
        echo ❌ MariaDB not installed
    )
)

REM Check WordPress
set WP_INSTALLED=false
if exist "C:\inetpub\wwwroot\wordpress\wp-config.php" (
    echo ✅ WordPress installation found
    set WP_INSTALLED=true
) else if exist "C:\Tools\WordPress\wp-config.php" (
    echo ✅ WordPress installation found
    set WP_INSTALLED=true
) else if exist "C:\inetpub\wwwroot\wordpress\index.php" (
    echo ⚠️  WordPress files found but not configured
    set WP_INSTALLED=true
) else if exist "C:\Tools\WordPress\index.php" (
    echo ⚠️  WordPress files found but not configured
    set WP_INSTALLED=true
) else (
    echo ❌ WordPress not installed
)

REM Determine what needs to be installed
set NEEDS_INSTALL=
if "%PHP_INSTALLED%"=="false" set NEEDS_INSTALL=%NEEDS_INSTALL% PHP
if "%MARIA_INSTALLED%"=="false" set NEEDS_INSTALL=%NEEDS_INSTALL% MariaDB
if "%WP_INSTALLED%"=="false" set NEEDS_INSTALL=%NEEDS_INSTALL% WordPress

echo.
if "%NEEDS_INSTALL%"=="" (
    echo 🎉 All components are already installed!
    echo You may still want to install Caddy using the dedicated guide.
    set install=n
) else (
    echo Components to install:%NEEDS_INSTALL%
    set /p install="Would you like to install the missing components? (y/N): "
)
if /i "%install%"=="y" (
    echo.
    echo Starting installation process...
    echo.
    
    REM Install only missing components
    if "%PHP_INSTALLED%"=="false" (
        echo Installing PHP...
        curl -s https://raw.githubusercontent.com/TrueBankai416/DemonWarriorTechDocs/main/scripts/install-php.cmd | cmd
        if %ERRORLEVEL% EQU 0 (
            echo ✅ PHP installation completed
        ) else (
            echo ❌ PHP installation failed
        )
        echo.
    ) else (
        echo ⏭️  Skipping PHP installation (already installed)
    )
    
    if "%MARIA_INSTALLED%"=="false" (
        echo Installing MariaDB...
        curl -s https://raw.githubusercontent.com/TrueBankai416/DemonWarriorTechDocs/main/scripts/install-mariadb.cmd | cmd
        if %ERRORLEVEL% EQU 0 (
            echo ✅ MariaDB installation completed
        ) else (
            echo ❌ MariaDB installation failed
        )
        echo.
    ) else (
        echo ⏭️  Skipping MariaDB installation (already installed)
    )
    
    echo.
    echo ================================================================
    echo Installation completed!
    echo Next: Install Caddy using the dedicated guide at:
    echo https://demonwarriortechdocs.pages.dev/docs/Documented%%20Tutorials/Caddy/Windows/Installing_Caddy_on_Windows
    echo ================================================================
) else (
    echo.
    echo Installation skipped. You can install manually using:
    echo - PHP: curl -s https://raw.githubusercontent.com/TrueBankai416/DemonWarriorTechDocs/main/scripts/install-php.cmd ^| cmd
    echo - MariaDB: curl -s https://raw.githubusercontent.com/TrueBankai416/DemonWarriorTechDocs/main/scripts/install-mariadb.cmd ^| cmd
    echo - Caddy: Follow the guide at the link above
)
