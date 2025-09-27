@echo off
REM CloudFlare DDNS Automated Script
REM Runs every 5 minutes via Task Scheduler

setlocal enabledelayedexpansion

REM Configuration - Edit these values
set CF_TOKEN=your-cloudflare-api-token
set CF_ZONE=yourdomain.com
REM Note: CF_ZONE should be your root domain (e.g., demonwarriortech.com)

REM Dry-run mode - set to "true" to see what would be updated without making changes
set DRY_RUN=false

REM Set paths and variables
set SCRIPT_DIR=%~dp0
set LOG_DIR=%SCRIPT_DIR%logs
set LOG_FILE=%LOG_DIR%\cloudflare-ddns.log

REM Auto-detect PowerShell path (try PATH first, fallback to full path)
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    set "POWERSHELL_PATH=powershell"
) else (
    set "POWERSHELL_PATH=%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe"
)

REM No external DDNS tool needed - using CloudFlare API directly

REM Create logs directory if it doesn't exist
if not exist "%LOG_DIR%" mkdir "%LOG_DIR%"

REM Get current timestamp using PowerShell (more reliable than WMIC)
for /f "usebackq delims=" %%t in (`%POWERSHELL_PATH% -NoProfile -Command "Get-Date -Format 'yyyy-MM-dd HH:mm:ss'"`) do set "timestamp=%%t"

REM Log start
echo [%timestamp%] Starting CloudFlare DDNS update... >> "%LOG_FILE%"

REM No external tools needed - using CloudFlare API directly

REM Get current public IP
for /f "usebackq delims=" %%t in (`%POWERSHELL_PATH% -NoProfile -Command "Get-Date -Format 'yyyy-MM-dd HH:mm:ss'"`) do set "timestamp=%%t"
echo [!timestamp!] Detecting current public IP... >> "%LOG_FILE%"

REM Try primary IP service
for /f "delims=" %%i in ('curl -4 -s --connect-timeout 10 https://api.ipify.org 2^>nul') do set "CURRENT_IP=%%i"
if "!CURRENT_IP!"=="" (
    for /f "usebackq delims=" %%t in (`%POWERSHELL_PATH% -NoProfile -Command "Get-Date -Format 'yyyy-MM-dd HH:mm:ss'"`) do set "timestamp=%%t"
    echo [!timestamp!] DEBUG: Primary IP service failed, trying fallback... >> "%LOG_FILE%"
    REM Try fallback IP service
    for /f "delims=" %%i in ('curl -4 -s --connect-timeout 10 https://icanhazip.com 2^>nul') do set "CURRENT_IP=%%i"
)

if "!CURRENT_IP!"=="" (
    for /f "usebackq delims=" %%t in (`%POWERSHELL_PATH% -NoProfile -Command "Get-Date -Format 'yyyy-MM-dd HH:mm:ss'"`) do set "timestamp=%%t"
    echo [!timestamp!] DEBUG: curl services failed, trying PowerShell fallback... >> "%LOG_FILE%"
    REM Try PowerShell fallback (in case curl is not available)
    for /f "usebackq delims=" %%i in (`%POWERSHELL_PATH% -NoProfile -Command "try { (Invoke-RestMethod -UseBasicParsing -Uri 'https://api.ipify.org').ToString().Trim() } catch { 'PS_ERROR' }" 2^>nul`) do set "CURRENT_IP=%%i"
    if "!CURRENT_IP!"=="PS_ERROR" set "CURRENT_IP="
)

if "!CURRENT_IP!"=="" (
    for /f "usebackq delims=" %%t in (`%POWERSHELL_PATH% -NoProfile -Command "Get-Date -Format 'yyyy-MM-dd HH:mm:ss'"`) do set "timestamp=%%t"
    echo [!timestamp!] WARNING: Could not detect current public IP with any method >> "%LOG_FILE%"
    set "CURRENT_IP=Unknown"
) else (
    REM Clean up IP (remove any whitespace/newlines)
    for /f "tokens=*" %%a in ("!CURRENT_IP!") do set "CURRENT_IP=%%a"
    for /f "usebackq delims=" %%t in (`%POWERSHELL_PATH% -NoProfile -Command "Get-Date -Format 'yyyy-MM-dd HH:mm:ss'"`) do set "timestamp=%%t"
    echo [!timestamp!] Current public IP: !CURRENT_IP! >> "%LOG_FILE%"
)

REM Get CloudFlare Zone ID
for /f "usebackq delims=" %%t in (`%POWERSHELL_PATH% -NoProfile -Command "Get-Date -Format 'yyyy-MM-dd HH:mm:ss'"`) do set "timestamp=%%t"
echo [!timestamp!] Getting CloudFlare Zone ID for %CF_ZONE%... >> "%LOG_FILE%"

for /f "usebackq delims=" %%i in (`%POWERSHELL_PATH% -NoProfile -Command "$headers = @{'Authorization' = 'Bearer ' + $env:CF_TOKEN; 'Content-Type' = 'application/json'}; try { $response = Invoke-RestMethod -Uri ('https://api.cloudflare.com/client/v4/zones?name=' + $env:CF_ZONE) -Headers $headers -Method GET; if ($response.success -and $response.result.Count -gt 0) { $response.result[0].id } else { 'ZONE_ERROR' } } catch { 'ZONE_ERROR' }" 2^>nul`) do set "CF_ZONE_ID=%%i"

if "!CF_ZONE_ID!"=="ZONE_ERROR" (
    for /f "usebackq delims=" %%t in (`%POWERSHELL_PATH% -NoProfile -Command "Get-Date -Format 'yyyy-MM-dd HH:mm:ss'"`) do set "timestamp=%%t"
    echo [!timestamp!] ERROR: Could not get Zone ID for %CF_ZONE% >> "%LOG_FILE%"
    echo [!timestamp!] DEBUG: Check your API token permissions and zone name >> "%LOG_FILE%"
    endlocal & exit /b 1
)

for /f "usebackq delims=" %%t in (`%POWERSHELL_PATH% -NoProfile -Command "Get-Date -Format 'yyyy-MM-dd HH:mm:ss'"`) do set "timestamp=%%t"
echo [!timestamp!] DEBUG: Zone ID: !CF_ZONE_ID! >> "%LOG_FILE%"

REM Get all A records in the zone
for /f "usebackq delims=" %%t in (`%POWERSHELL_PATH% -NoProfile -Command "Get-Date -Format 'yyyy-MM-dd HH:mm:ss'"`) do set "timestamp=%%t"
echo [!timestamp!] Discovering all A records in zone... >> "%LOG_FILE%"

REM Create temporary file for records data
set "TEMP_RECORDS=%TEMP%\cf_records_%RANDOM%.json"

%POWERSHELL_PATH% -NoProfile -Command "$headers = @{'Authorization' = 'Bearer ' + $env:CF_TOKEN; 'Content-Type' = 'application/json'}; try { $response = Invoke-RestMethod -Uri ('https://api.cloudflare.com/client/v4/zones/' + $env:CF_ZONE_ID + '/dns_records?type=A&per_page=100') -Headers $headers -Method GET; if ($response.success) { $response.result | ConvertTo-Json -Depth 10 | Out-File -FilePath $env:TEMP_RECORDS -Encoding UTF8 } else { Set-Content -Path $env:TEMP_RECORDS -Value 'API_ERROR' -Encoding ASCII } } catch { Set-Content -Path $env:TEMP_RECORDS -Value 'API_ERROR' -Encoding ASCII }" 2>nul

REM Check if API call was successful
for /f "usebackq delims=" %%i in ("%TEMP_RECORDS%") do set "FIRST_LINE=%%i"
if "!FIRST_LINE!"=="API_ERROR" (
    for /f "usebackq delims=" %%t in (`%POWERSHELL_PATH% -NoProfile -Command "Get-Date -Format 'yyyy-MM-dd HH:mm:ss'"`) do set "timestamp=%%t"
    echo [!timestamp!] ERROR: Could not retrieve DNS records from CloudFlare API >> "%LOG_FILE%"
    del "%TEMP_RECORDS%" 2>nul
    endlocal & exit /b 1
)

REM Process records and find ones that need updating
for /f "usebackq delims=" %%t in (`%POWERSHELL_PATH% -NoProfile -Command "Get-Date -Format 'yyyy-MM-dd HH:mm:ss'"`) do set "timestamp=%%t"
echo [!timestamp!] Analyzing A records for updates... >> "%LOG_FILE%"

set "RECORDS_TO_UPDATE=0"
set "RECORDS_FOUND=0"

REM Use PowerShell to parse JSON and find records to update
%POWERSHELL_PATH% -NoProfile -Command "$records = Get-Content $env:TEMP_RECORDS | ConvertFrom-Json; $currentIP = $env:CURRENT_IP; $recordsFound = 0; $recordsToUpdate = 0; $updateList = @(); $statsPath = Join-Path $env:TEMP 'cf_stats.txt'; $updatesPath = Join-Path $env:TEMP 'cf_updates.json'; foreach ($record in $records) { $recordsFound++; Add-Content -Path $env:LOG_FILE -Value ('[' + (Get-Date -Format 'yyyy-MM-dd HH:mm:ss') + '] DEBUG: Found A record: ' + $record.name + ' -> ' + $record.content + ' (Proxied: ' + $record.proxied + ')'); if ($record.content -ne $currentIP -and $currentIP -ne 'Unknown') { $recordsToUpdate++; $updateList += $record; Add-Content -Path $env:LOG_FILE -Value ('[' + (Get-Date -Format 'yyyy-MM-dd HH:mm:ss') + '] INFO: Record needs update: ' + $record.name + ' (' + $record.content + ' -> ' + $currentIP + ')') } else { Add-Content -Path $env:LOG_FILE -Value ('[' + (Get-Date -Format 'yyyy-MM-dd HH:mm:ss') + '] INFO: Record up to date: ' + $record.name + ' (' + $record.content + ')') } }; Set-Content -Path $statsPath -Value ('RECORDS_FOUND=' + $recordsFound); Add-Content -Path $statsPath -Value ('RECORDS_TO_UPDATE=' + $recordsToUpdate); $updateList | ConvertTo-Json -Depth 10 | Out-File -FilePath $updatesPath -Encoding UTF8" 2>nul

REM Read statistics
if not exist "%TEMP%\cf_stats.txt" (
    for /f "usebackq delims=" %%t in (`%POWERSHELL_PATH% -NoProfile -Command "Get-Date -Format 'yyyy-MM-dd HH:mm:ss'"`) do set "timestamp=%%t"
    echo [!timestamp!] ERROR: Failed to analyze DNS records - cf_stats.txt not created >> "%LOG_FILE%"
    endlocal & exit /b 1
)

for /f "usebackq tokens=1,2 delims==" %%a in ("%TEMP%\cf_stats.txt") do (
    if "%%a"=="RECORDS_FOUND" set "RECORDS_FOUND=%%b"
    if "%%a"=="RECORDS_TO_UPDATE" set "RECORDS_TO_UPDATE=%%b"
)

for /f "usebackq delims=" %%t in (`%POWERSHELL_PATH% -NoProfile -Command "Get-Date -Format 'yyyy-MM-dd HH:mm:ss'"`) do set "timestamp=%%t"
echo [!timestamp!] Found !RECORDS_FOUND! A records, !RECORDS_TO_UPDATE! need updating >> "%LOG_FILE%"

REM Update records via CloudFlare API
set "RC=0"
set "UPDATED_COUNT=0"
set "FAILED_COUNT=0"

if !RECORDS_TO_UPDATE! GTR 0 (
    for /f "usebackq delims=" %%t in (`%POWERSHELL_PATH% -NoProfile -Command "Get-Date -Format 'yyyy-MM-dd HH:mm:ss'"`) do set "timestamp=%%t"
    
    if /i "%DRY_RUN%"=="true" (
        echo [!timestamp!] DRY-RUN: Would update !RECORDS_TO_UPDATE! A records via CloudFlare API >> "%LOG_FILE%"
        
        REM Show what would be updated in dry-run mode
        %POWERSHELL_PATH% -NoProfile -Command "$currentIP = $env:CURRENT_IP; $updatesPath = Join-Path $env:TEMP 'cf_updates.json'; try { $updateList = Get-Content $updatesPath | ConvertFrom-Json; if ($updateList -is [System.Array]) { $records = $updateList } else { $records = @($updateList) }; foreach ($record in $records) { Add-Content -Path $env:LOG_FILE -Value ('[' + (Get-Date -Format 'yyyy-MM-dd HH:mm:ss') + '] DRY-RUN: Would update ' + $record.name + ' from ' + $record.content + ' to ' + $currentIP + ' (Proxied: ' + $record.proxied + ')') } } catch { Add-Content -Path $env:LOG_FILE -Value ('[' + (Get-Date -Format 'yyyy-MM-dd HH:mm:ss') + '] DRY-RUN: Error processing update list: ' + $_.Exception.Message) }" 2>nul
        
        for /f "usebackq delims=" %%t in (`%POWERSHELL_PATH% -NoProfile -Command "Get-Date -Format 'yyyy-MM-dd HH:mm:ss'"`) do set "timestamp=%%t"
        echo [!timestamp!] DRY-RUN: No actual changes made - set DRY_RUN=false to perform updates >> "%LOG_FILE%"
        set "UPDATED_COUNT=0"
        set "FAILED_COUNT=0"
        
    ) else (
        echo [!timestamp!] Updating !RECORDS_TO_UPDATE! A records via CloudFlare API... >> "%LOG_FILE%"
        
        REM Update each record using PowerShell
        %POWERSHELL_PATH% -NoProfile -Command "$headers = @{'Authorization' = 'Bearer ' + $env:CF_TOKEN; 'Content-Type' = 'application/json'}; $currentIP = $env:CURRENT_IP; $zoneId = $env:CF_ZONE_ID; $updatedCount = 0; $failedCount = 0; $updatesPath = Join-Path $env:TEMP 'cf_updates.json'; $resultsPath = Join-Path $env:TEMP 'cf_results.txt'; try { $updateList = Get-Content $updatesPath | ConvertFrom-Json; if ($updateList -is [System.Array]) { $records = $updateList } else { $records = @($updateList) }; foreach ($record in $records) { $updateData = @{ type = 'A'; name = $record.name; content = $currentIP; ttl = $record.ttl; proxied = $record.proxied } | ConvertTo-Json; try { $response = Invoke-RestMethod -Uri ('https://api.cloudflare.com/client/v4/zones/' + $zoneId + '/dns_records/' + $record.id) -Headers $headers -Method PUT -Body $updateData; if ($response.success) { $updatedCount++; Add-Content -Path $env:LOG_FILE -Value ('[' + (Get-Date -Format 'yyyy-MM-dd HH:mm:ss') + '] SUCCESS: Updated ' + $record.name + ' to ' + $currentIP + ' (Proxied: ' + $record.proxied + ')') } else { $failedCount++; Add-Content -Path $env:LOG_FILE -Value ('[' + (Get-Date -Format 'yyyy-MM-dd HH:mm:ss') + '] ERROR: Failed to update ' + $record.name + ': ' + $response.errors[0].message) } } catch { $failedCount++; Add-Content -Path $env:LOG_FILE -Value ('[' + (Get-Date -Format 'yyyy-MM-dd HH:mm:ss') + '] ERROR: Failed to update ' + $record.name + ': ' + $_.Exception.Message) } } } catch { Add-Content -Path $env:LOG_FILE -Value ('[' + (Get-Date -Format 'yyyy-MM-dd HH:mm:ss') + '] ERROR: Failed to process update list: ' + $_.Exception.Message); $failedCount = 999 }; Set-Content -Path $resultsPath -Value ('UPDATED_COUNT=' + $updatedCount); Add-Content -Path $resultsPath -Value ('FAILED_COUNT=' + $failedCount)" 2>nul
        
        REM Read results
        if not exist "%TEMP%\cf_results.txt" (
            for /f "usebackq delims=" %%t in (`%POWERSHELL_PATH% -NoProfile -Command "Get-Date -Format 'yyyy-MM-dd HH:mm:ss'"`) do set "timestamp=%%t"
            echo [!timestamp!] ERROR: Failed to update DNS records - cf_results.txt not created >> "%LOG_FILE%"
            set "UPDATED_COUNT=0"
            set "FAILED_COUNT=999"
        ) else (
            for /f "usebackq tokens=1,2 delims==" %%a in ("%TEMP%\cf_results.txt") do (
                if "%%a"=="UPDATED_COUNT" set "UPDATED_COUNT=%%b"
                if "%%a"=="FAILED_COUNT" set "FAILED_COUNT=%%b"
            )
        )
        
        for /f "usebackq delims=" %%t in (`%POWERSHELL_PATH% -NoProfile -Command "Get-Date -Format 'yyyy-MM-dd HH:mm:ss'"`) do set "timestamp=%%t"
        echo [!timestamp!] Update results: !UPDATED_COUNT! successful, !FAILED_COUNT! failed >> "%LOG_FILE%"
        
        if !FAILED_COUNT! GTR 0 set "RC=1"
    )
    
) else (
    for /f "usebackq delims=" %%t in (`%POWERSHELL_PATH% -NoProfile -Command "Get-Date -Format 'yyyy-MM-dd HH:mm:ss'"`) do set "timestamp=%%t"
    if /i "%DRY_RUN%"=="true" (
        echo [!timestamp!] DRY-RUN: No A records need updating - all are current >> "%LOG_FILE%"
    ) else (
        echo [!timestamp!] No A records need updating - all are current >> "%LOG_FILE%"
    )
)

REM Cleanup temporary files
del "%TEMP_RECORDS%" 2>nul
del "%TEMP%\cf_stats.txt" 2>nul
del "%TEMP%\cf_updates.json" 2>nul
del "%TEMP%\cf_results.txt" 2>nul

REM Add separator line
echo ---------------------------------------- >> "%LOG_FILE%"

REM Run log cleanup automatically (suppress output)
call "%SCRIPT_DIR%log-cleanup.bat" >nul 2>&1

REM Exit with the same code as the DDNS tool for Task Scheduler tracking
endlocal & exit /b %RC%
