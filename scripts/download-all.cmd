@echo off
echo WordPress Installation - Download All Components (CMD Version)
echo ================================================================

REM Check what's already installed BEFORE downloading
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
) else (
    if exist "C:\Tools\WordPress\wp-config.php" (
        echo ✅ WordPress installation found
        set WP_INSTALLED=true
    ) else (
        if exist "C:\inetpub\wwwroot\wordpress\index.php" (
            echo ⚠️  WordPress files found but not configured
            set WP_INSTALLED=true
        ) else (
            if exist "C:\Tools\WordPress\index.php" (
                echo ⚠️  WordPress files found but not configured
                set WP_INSTALLED=true
            ) else (
                echo ❌ WordPress not installed
            )
        )
    )
)

REM Determine what needs to be downloaded
set NEEDS_DOWNLOAD=
if "%PHP_INSTALLED%"=="false" set NEEDS_DOWNLOAD=%NEEDS_DOWNLOAD% PHP
if "%MARIA_INSTALLED%"=="false" set NEEDS_DOWNLOAD=%NEEDS_DOWNLOAD% MariaDB
if "%WP_INSTALLED%"=="false" set NEEDS_DOWNLOAD=%NEEDS_DOWNLOAD% WordPress

echo.
if "%NEEDS_DOWNLOAD%"=="" (
    echo 🎉 All components are already installed!
    echo No downloads needed. You may still want to install Caddy using the dedicated guide.
    goto :eof
) else (
    echo Components to download:%NEEDS_DOWNLOAD%
    echo Starting selective download process...
    echo.
)

REM Download PHP only if needed
if "%PHP_INSTALLED%"=="false" (
    echo [1/?] Getting latest PHP 8.x version...
    
    REM Check if already downloaded
    if exist "%TEMP%\php-*-nts-Win32-vs16-x64.zip" (
        echo ⚡ PHP already downloaded
    ) else (
        for /f "usebackq delims=" %%i in (`powershell -NoProfile -Command "try { $releases = Invoke-RestMethod \"https://www.php.net/releases/?json^&version=8\"; $latest = $releases.PSObject.Properties.Name ^| Where-Object { $_ -match \"^\d+\.\d+\.\d+$\" } ^| Sort-Object {[Version]$_} -Descending ^| Select-Object -First 1; if (-not $latest) { $latest = \"8.3.24\" }; Write-Output $latest } catch { Write-Output \"8.3.24\" }"`) do set PHP_VERSION=%%i
        echo Latest PHP version: %PHP_VERSION%
        curl -L -o "%TEMP%\php-%PHP_VERSION%-nts-Win32-vs16-x64.zip" "https://windows.php.net/downloads/releases/php-%PHP_VERSION%-nts-Win32-vs16-x64.zip"
        if %ERRORLEVEL% EQU 0 (
            echo ✅ Downloaded PHP %PHP_VERSION%
        ) else (
            echo ❌ PHP download failed
        )
    )
)

REM Download MariaDB only if needed
if "%MARIA_INSTALLED%"=="false" (
    echo.
    echo [2/?] Getting latest MariaDB version...
    
    REM Check if already downloaded
    if exist "%TEMP%\mariadb-latest-winx64.msi" (
        echo ⚡ MariaDB already downloaded
    ) else (
        echo Fetching latest MariaDB version...
        REM Get latest MariaDB version using PowerShell (CMD doesn't have good JSON parsing)
        for /f "usebackq delims=" %%i in (`powershell -NoProfile -Command "try { $releases = Invoke-RestMethod 'https://api.github.com/repos/MariaDB/server/releases'; $latest = $releases ^| Where-Object { $_.prerelease -eq $false -and $_.tag_name -match '^\d+\.\d+\.\d+$' } ^| Select-Object -First 1; if ($latest) { Write-Output $latest.tag_name } else { Write-Output '11.4.3' } } catch { Write-Output '11.4.3' }"`) do set MARIA_VERSION=%%i
        
        echo Latest MariaDB version: %MARIA_VERSION%
        echo Downloading from MariaDB archive...
        curl -L -o "%TEMP%\mariadb-latest-winx64.msi" "https://archive.mariadb.org/mariadb-%MARIA_VERSION%/winx64-packages/mariadb-%MARIA_VERSION%-winx64.msi"
        if %ERRORLEVEL% EQU 0 (
            echo ✅ Downloaded MariaDB %MARIA_VERSION%
        ) else (
            echo ⚠️  Archive download failed, trying fallback...
            set MARIA_VERSION=11.4.3
            curl -L -o "%TEMP%\mariadb-latest-winx64.msi" "https://archive.mariadb.org/mariadb-11.4.3/winx64-packages/mariadb-11.4.3-winx64.msi"
            if %ERRORLEVEL% EQU 0 (
                echo ✅ Downloaded MariaDB %MARIA_VERSION% (fallback)
            ) else (
                echo ❌ MariaDB download failed
            )
        )
    )
)

REM Download WordPress only if needed
if "%WP_INSTALLED%"=="false" (
    echo.
    echo [3/?] Downloading latest WordPress...
    
    REM Check if already downloaded
    if exist "%TEMP%\wordpress-latest.zip" (
        echo ⚡ WordPress already downloaded
    ) else (
        curl -L -o "%TEMP%\wordpress-latest.zip" "https://wordpress.org/latest.zip"
        if %ERRORLEVEL% EQU 0 (
            echo ✅ Downloaded WordPress (latest)
        ) else (
            echo ❌ WordPress download failed
        )
    )
)

echo.
echo ================================================================
echo Downloads completed successfully!
echo.
echo Files saved to: %TEMP%
echo ================================================================

REM Ask user if they want to proceed with installation
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
        curl -s https://raw.githubusercontent.com/TrueBankai416/DemonWarriorTechDocs/mentat-2%233/scripts/install-php.cmd | cmd
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
        curl -s https://raw.githubusercontent.com/TrueBankai416/DemonWarriorTechDocs/mentat-2%233/scripts/install-mariadb.cmd | cmd
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
    echo - PHP: curl -s https://raw.githubusercontent.com/TrueBankai416/DemonWarriorTechDocs/mentat-2%%233/scripts/install-php.cmd ^| cmd
    echo - MariaDB: curl -s https://raw.githubusercontent.com/TrueBankai416/DemonWarriorTechDocs/mentat-2%%233/scripts/install-mariadb.cmd ^| cmd
    echo - Caddy: Follow the guide at the link above
)
