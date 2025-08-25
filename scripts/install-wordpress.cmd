@echo off
echo WordPress Installation - Install WordPress (CMD Version)
echo ========================================================

echo Installing WordPress from downloaded files...
echo.

REM Check if WordPress archive exists
echo [1/2] Checking WordPress archive...
if not exist "%TEMP%\wordpress-latest.zip" (
    echo ❌ WordPress archive not found in %TEMP%
    exit /b 1
)

REM Create web directory
echo Creating web directory...
mkdir "C:\inetpub\wwwroot" 2>nul

REM Extract WordPress
echo.
echo [2/2] Extracting WordPress...
echo Using PowerShell to extract archive...
powershell -NoProfile -Command "try { Expand-Archive -Path '%TEMP%\wordpress-latest.zip' -DestinationPath 'C:\inetpub\wwwroot' -Force; exit 0 } catch { Write-Host 'Extraction failed: $_'; exit 1 }"
if %ERRORLEVEL% EQU 0 (
    echo ✅ WordPress extracted to C:\inetpub\wwwroot\wordpress
) else (
    echo ❌ Failed to extract WordPress archive
    exit /b 1
)

REM Verify extraction worked
if not exist "C:\inetpub\wwwroot\wordpress\index.php" (
    echo ❌ WordPress extraction failed - index.php not found
    exit /b 1
)

echo.
echo ========================================================
echo WordPress installation completed successfully!
echo.
echo WordPress files are now available at:
echo C:\inetpub\wwwroot\wordpress
echo.
echo Next steps:
echo 1. Configure your web server (IIS/Apache) to serve from this directory
echo 2. Create a database and configure wp-config.php
echo 3. Run the WordPress setup wizard in your browser
echo ========================================================
