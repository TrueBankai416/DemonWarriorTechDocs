@echo off
REM Log cleanup script for CloudFlare DDNS
REM Keeps only the last 30 days of logs

setlocal enabledelayedexpansion

set SCRIPT_DIR=%~dp0
set LOG_DIR=%SCRIPT_DIR%logs
set LOG_FILE=%LOG_DIR%\cloudflare-ddns.log
set DAYS_TO_KEEP=30

REM Auto-detect PowerShell path (try PATH first, fallback to full path)
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    set "POWERSHELL_PATH=powershell"
) else (
    set "POWERSHELL_PATH=%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe"
)

REM Create logs directory if it doesn't exist
if not exist "%LOG_DIR%" (
    exit /b 0
)

REM Check if log file exists
if not exist "%LOG_FILE%" (
    REM Still clean up old backup files even if current log doesn't exist
    goto :cleanup_old_files
)

REM Get file size in bytes
for %%A in ("%LOG_FILE%") do set LOG_SIZE=%%~zA

REM If log file is larger than 10MB (10485760 bytes), rotate it
if %LOG_SIZE% GTR 10485760 (
    echo Log file is larger than 10MB, rotating...
    
    REM Get current timestamp for backup using PowerShell
    for /f "usebackq delims=" %%t in (`%POWERSHELL_PATH% -NoProfile -Command "Get-Date -Format 'yyyyMMdd_HHmm'"`) do set "backup_timestamp=%%t"
    
    REM Move current log to backup
    move "%LOG_FILE%" "%LOG_DIR%\cloudflare-ddns_%backup_timestamp%.log"
    
    REM Create new empty log file with current timestamp
    for /f "usebackq delims=" %%t in (`%POWERSHELL_PATH% -NoProfile -Command "Get-Date -Format 'yyyy-MM-dd HH:mm'"`) do set "current_time=%%t"
    echo Log rotated on !current_time! > "%LOG_FILE%"
)

:cleanup_old_files
REM Clean up old backup log files (older than 30 days)
if exist "%LOG_DIR%\cloudflare-ddns_*.log" (
    forfiles /p "%LOG_DIR%" /m "cloudflare-ddns_*.log" /d -%DAYS_TO_KEEP% /c "cmd /c del @path" 2>nul
)

echo Log cleanup completed.
