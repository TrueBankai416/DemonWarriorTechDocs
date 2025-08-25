@echo off
echo WordPress Installation - Install MariaDB (CMD Version)
echo =====================================================

echo Installing MariaDB from downloaded files...
echo.

REM Install MariaDB silently
echo [1/3] Installing MariaDB...
msiexec /i "%TEMP%\mariadb-latest-winx64.msi" /quiet SERVICENAME=MariaDB PASSWORD=SecureRootPassword123! UTF8=1
echo ✅ MariaDB installed

REM Wait for service to start
echo.
echo [2/3] Waiting for MariaDB service to start...
timeout /t 10 /nobreak

REM Create WordPress database and user
echo.
echo [3/3] Creating WordPress database...
echo CREATE DATABASE wordpress CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci; > "%TEMP%\setup_db.sql"
echo CREATE USER 'wordpress'@'localhost' IDENTIFIED BY 'WordPressPassword123!'; >> "%TEMP%\setup_db.sql"
echo GRANT ALL PRIVILEGES ON wordpress.* TO 'wordpress'@'localhost'; >> "%TEMP%\setup_db.sql"
echo FLUSH PRIVILEGES; >> "%TEMP%\setup_db.sql"

REM Execute database setup (find MariaDB installation dynamically)
for /d %%i in ("C:\Program Files\MariaDB*") do (
    "%%i\bin\mysql.exe" -u root -p"SecureRootPassword123!" < "%TEMP%\setup_db.sql"
    echo ✅ WordPress database created
)

REM Clean up
del "%TEMP%\setup_db.sql"

echo.
echo =====================================================
echo MariaDB installation completed successfully!
echo.
echo Database: wordpress
echo Username: wordpress  
echo Password: WordPressPassword123!
echo Root Password: SecureRootPassword123!
echo =====================================================
