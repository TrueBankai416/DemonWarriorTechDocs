@echo off
echo WordPress Installation - Install PHP (CMD Version)
echo ==================================================

echo Installing PHP from downloaded files...
echo.

REM Create directories
echo [1/4] Creating directories...
mkdir "C:\Tools" 2>nul
mkdir "C:\Tools\PHP" 2>nul
mkdir "C:\Tools\PHP\logs" 2>nul
mkdir "C:\Tools\PHP\tmp" 2>nul
mkdir "C:\Tools\PHP\sessions" 2>nul
echo ✅ Directories created

REM Extract PHP
echo.
echo [2/4] Extracting PHP...
set EXTRACT_SUCCESS=false
for %%f in ("%TEMP%\php-*-nts-Win32-vs16-x64.zip") do (
    echo Found PHP file: %%~nxf
    echo Using PowerShell to extract archive...
    powershell -NoProfile -Command "try { Expand-Archive -Path '%%f' -DestinationPath 'C:\Tools\PHP' -Force; exit 0 } catch { Write-Host 'Extraction failed: $_'; exit 1 }"
    if %ERRORLEVEL% EQU 0 (
        set EXTRACT_SUCCESS=true
        echo ✅ PHP extracted to C:\Tools\PHP
    ) else (
        echo ❌ Failed to extract PHP archive
        exit /b 1
    )
)

if "%EXTRACT_SUCCESS%"=="false" (
    echo ❌ No PHP archive found in %TEMP%
    exit /b 1
)

REM Verify extraction worked
if not exist "C:\Tools\PHP\php.exe" (
    echo ❌ PHP extraction failed - php.exe not found
    exit /b 1
)

REM Copy php.ini template
echo.
echo [3/4] Configuring PHP...
copy "C:\Tools\PHP\php.ini-production" "C:\Tools\PHP\php.ini"
if %ERRORLEVEL% NEQ 0 (
    echo ❌ Failed to copy php.ini template
    exit /b 1
)
echo ; ---------- WordPress Custom Configuration ---------- >> "C:\Tools\PHP\php.ini"
echo ; Memory and Performance >> "C:\Tools\PHP\php.ini"
echo memory_limit = 512M >> "C:\Tools\PHP\php.ini"
echo max_execution_time = 300 >> "C:\Tools\PHP\php.ini"
echo max_input_time = 300 >> "C:\Tools\PHP\php.ini"
echo post_max_size = 64M >> "C:\Tools\PHP\php.ini"
echo upload_max_filesize = 64M >> "C:\Tools\PHP\php.ini"
echo max_file_uploads = 20 >> "C:\Tools\PHP\php.ini"
echo. >> "C:\Tools\PHP\php.ini"
echo ; Error Reporting >> "C:\Tools\PHP\php.ini"
echo display_errors = Off >> "C:\Tools\PHP\php.ini"
echo log_errors = On >> "C:\Tools\PHP\php.ini"
echo error_log = C:\Tools\PHP\logs\php_errors.log >> "C:\Tools\PHP\php.ini"
echo. >> "C:\Tools\PHP\php.ini"
echo ; Extensions >> "C:\Tools\PHP\php.ini"
echo extension_dir = "ext" >> "C:\Tools\PHP\php.ini"
echo extension=bz2 >> "C:\Tools\PHP\php.ini"
echo extension=curl >> "C:\Tools\PHP\php.ini"
echo extension=fileinfo >> "C:\Tools\PHP\php.ini"
echo extension=gd >> "C:\Tools\PHP\php.ini"
echo extension=gettext >> "C:\Tools\PHP\php.ini"
echo extension=intl >> "C:\Tools\PHP\php.ini"
echo extension=mbstring >> "C:\Tools\PHP\php.ini"
echo extension=exif >> "C:\Tools\PHP\php.ini"
echo extension=mysqli >> "C:\Tools\PHP\php.ini"
echo extension=openssl >> "C:\Tools\PHP\php.ini"
echo extension=pdo_mysql >> "C:\Tools\PHP\php.ini"
echo extension=zip >> "C:\Tools\PHP\php.ini"
echo extension=opcache >> "C:\Tools\PHP\php.ini"
echo. >> "C:\Tools\PHP\php.ini"
echo ; OPcache Configuration >> "C:\Tools\PHP\php.ini"
echo opcache.enable=1 >> "C:\Tools\PHP\php.ini"
echo opcache.enable_cli=1 >> "C:\Tools\PHP\php.ini"
echo opcache.memory_consumption=256 >> "C:\Tools\PHP\php.ini"
echo opcache.interned_strings_buffer=8 >> "C:\Tools\PHP\php.ini"
echo opcache.max_accelerated_files=10000 >> "C:\Tools\PHP\php.ini"
echo opcache.revalidate_freq=2 >> "C:\Tools\PHP\php.ini"
echo opcache.fast_shutdown=1 >> "C:\Tools\PHP\php.ini"
echo. >> "C:\Tools\PHP\php.ini"
echo ; Session Configuration >> "C:\Tools\PHP\php.ini"
echo session.save_handler = files >> "C:\Tools\PHP\php.ini"
echo session.save_path = "C:\Tools\PHP\tmp" >> "C:\Tools\PHP\php.ini"
echo session.gc_maxlifetime = 1440 >> "C:\Tools\PHP\php.ini"
echo. >> "C:\Tools\PHP\php.ini"
echo ; CGI Configuration >> "C:\Tools\PHP\php.ini"
echo cgi.force_redirect = 0 >> "C:\Tools\PHP\php.ini"
echo cgi.fix_pathinfo = 1 >> "C:\Tools\PHP\php.ini"
echo fastcgi.impersonate = 1 >> "C:\Tools\PHP\php.ini"
echo ✅ PHP configuration updated

REM Add to PATH
echo.
echo [4/4] Adding PHP to system PATH...
echo %PATH% | find /i "C:\Tools\PHP" >nul
if errorlevel 1 (
    setx PATH "%PATH%;C:\Tools\PHP" /M
    echo ✅ PHP added to system PATH
) else (
    echo ✅ PHP already in system PATH
)

echo.
echo ==================================================
echo PHP installation completed successfully!
echo.
echo Please restart Command Prompt and run: php --version
echo ==================================================
