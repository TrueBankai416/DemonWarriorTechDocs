@echo off
setlocal enabledelayedexpansion

REM ========================================
REM CloudFlare DDNS Log Cleanup Script
REM ========================================
REM This script cleans up old CloudFlare DDNS log files to prevent disk space issues

REM Configuration
set LOG_DIR=logs
set LOG_FILE=%LOG_DIR%\cloudflare-ddns.log
set DAYS_TO_KEEP=30
set MAX_LOG_FILES=10

echo [%date% %time%] Starting log cleanup...

REM Check if logs directory exists
if not exist "%LOG_DIR%" (
    echo [%date% %time%] No logs directory found, nothing to clean
    goto :end
)

REM Clean up old .old log files (keep only the most recent ones)
echo [%date% %time%] Cleaning up old log files...

REM Count .old files
for /f %%C in ('dir /b "%LOG_DIR%\cloudflare-ddns.log.old*" 2^>nul ^| find /c /v ""') do set OLD_COUNT=%%C
if not defined OLD_COUNT set OLD_COUNT=0

if %OLD_COUNT% gtr %MAX_LOG_FILES% (
    echo [%date% %time%] Found %OLD_COUNT% old log files, keeping only %MAX_LOG_FILES% most recent
    
    REM Delete oldest files (simple approach - delete all then keep recent ones)
    for /f "skip=%MAX_LOG_FILES%" %%F in ('dir "%LOG_DIR%\cloudflare-ddns.log.old*" /b /o-d 2^>nul') do (
        echo [%date% %time%] Deleting old log file: %%F
        del "%LOG_DIR%\%%F" 2>nul
    )
) else (
    echo [%date% %time%] Found %OLD_COUNT% old log files (within limit of %MAX_LOG_FILES%)
)

REM Clean up temporary files that might be left behind
echo [%date% %time%] Cleaning up temporary files...
del temp_ip.txt 2>nul
del zone_response.json 2>nul
del records_response.json 2>nul
del zone_id.txt 2>nul

REM Check current log file size
if exist "%LOG_FILE%" (
    for %%F in ("%LOG_FILE%") do (
        set LOG_SIZE=%%~zF
        set /a LOG_SIZE_MB=!LOG_SIZE!/1048576
        echo [%date% %time%] Current log file size: !LOG_SIZE_MB! MB
        
        if !LOG_SIZE! gtr 52428800 (
            echo [%date% %time%] WARNING: Log file is larger than 50MB, consider rotating
        )
    )
) else (
    echo [%date% %time%] No current log file found
)

:end
echo [%date% %time%] Log cleanup completed

endlocal
