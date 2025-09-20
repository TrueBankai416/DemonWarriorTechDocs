@echo off
setlocal enabledelayedexpansion

REM ========================================
REM CloudFlare DDNS Automated Update Script
REM ========================================
REM This script automatically updates CloudFlare DNS records with your current public IP
REM Supports multiple domains and provides comprehensive logging

REM Configuration - Edit these values
set CF_TOKEN=your-cloudflare-api-token
set CF_ZONE=yourdomain.com
REM Note: CF_ZONE should be your root domain (e.g., demonwarriortech.com)

REM Dry-run mode - set to "true" to see what would be updated without making changes
set DRY_RUN=true

REM Advanced Configuration
set LOG_DIR=logs
set LOG_FILE=%LOG_DIR%\cloudflare-ddns.log
set MAX_LOG_SIZE=10485760
set CURL_TIMEOUT=30

REM Create logs directory if it doesn't exist
if not exist "%LOG_DIR%" mkdir "%LOG_DIR%"

REM Function to write to log with timestamp
:log
echo [%date% %time%] %~1 >> "%LOG_FILE%"
echo [%date% %time%] %~1
goto :eof

REM Check if running as administrator
net session >nul 2>&1
if %errorLevel% neq 0 (
    call :log "ERROR: This script must be run as Administrator"
    call :log "Please right-click and select 'Run as administrator'"
    exit /b 1
)

call :log "========================================"
call :log "Starting CloudFlare DDNS update..."

REM Validate configuration
if "%CF_TOKEN%"=="your-cloudflare-api-token" (
    call :log "ERROR: Please configure your CloudFlare API token"
    exit /b 1
)

if "%CF_ZONE%"=="yourdomain.com" (
    call :log "ERROR: Please configure your domain name"
    exit /b 1
)

if "%DRY_RUN%"=="true" (
    call :log "WARNING: DRY RUN MODE ENABLED - No changes will be made"
)

REM Get current public IP
call :log "Detecting current public IP..."

REM Try primary IP detection service
curl -s --connect-timeout %CURL_TIMEOUT% "https://ipv4.icanhazip.com" > temp_ip.txt 2>nul
if %errorLevel% neq 0 (
    call :log "DEBUG: Primary IP service failed, trying fallback..."
    
    REM Try fallback service
    curl -s --connect-timeout %CURL_TIMEOUT% "https://api.ipify.org" > temp_ip.txt 2>nul
    if %errorLevel% neq 0 (
        call :log "DEBUG: curl services failed, trying PowerShell fallback..."
        
        REM PowerShell fallback
        powershell -Command "(Invoke-WebRequest -Uri 'https://ipv4.icanhazip.com' -UseBasicParsing).Content.Trim()" > temp_ip.txt 2>nul
        if %errorLevel% neq 0 (
            call :log "ERROR: Failed to detect public IP address"
            if exist temp_ip.txt del temp_ip.txt
            exit /b 1
        )
    )
)

set /p CURRENT_IP=<temp_ip.txt
del temp_ip.txt

REM Validate IP format
echo %CURRENT_IP% | findstr /R "^[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*$" >nul
if %errorLevel% neq 0 (
    call :log "ERROR: Invalid IP address detected: %CURRENT_IP%"
    exit /b 1
)

call :log "Current public IP: %CURRENT_IP%"

REM Get CloudFlare Zone ID
call :log "Getting CloudFlare Zone ID for %CF_ZONE%..."

curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=%CF_ZONE%" ^
     -H "Authorization: Bearer %CF_TOKEN%" ^
     -H "Content-Type: application/json" > zone_response.json

REM Extract Zone ID using PowerShell
powershell -Command "$json = Get-Content 'zone_response.json' | ConvertFrom-Json; if($json.success -and $json.result.Count -gt 0) { $json.result[0].id } else { 'ERROR' }" > zone_id.txt
set /p ZONE_ID=<zone_id.txt

if "%ZONE_ID%"=="ERROR" (
    call :log "ERROR: Failed to get Zone ID for %CF_ZONE%"
    call :log "Please check your API token and domain name"
    del zone_response.json zone_id.txt
    exit /b 1
)

call :log "DEBUG: Zone ID: %ZONE_ID:~0,8%***********%ZONE_ID:~-3%"
del zone_response.json zone_id.txt

REM Get all A records in the zone
call :log "Discovering all A records in zone..."

curl -s -X GET "https://api.cloudflare.com/client/v4/zones/%ZONE_ID%/dns_records?type=A" ^
     -H "Authorization: Bearer %CF_TOKEN%" ^
     -H "Content-Type: application/json" > records_response.json

call :log "Analyzing A records for updates..."

REM Process records using PowerShell
powershell -Command "
$json = Get-Content 'records_response.json' | ConvertFrom-Json
$currentIP = '%CURRENT_IP%'
$dryRun = '%DRY_RUN%' -eq 'true'
$logFile = '%LOG_FILE%'
$cfToken = '%CF_TOKEN%'
$zoneId = '%ZONE_ID%'

function Write-Log($message) {
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $logEntry = \"[$timestamp] $message\"
    Add-Content -Path $logFile -Value $logEntry
    Write-Host $logEntry
}

if ($json.success) {
    foreach ($record in $json.result) {
        $name = $record.name
        $currentRecordIP = $record.content
        $proxied = $record.proxied
        $recordId = $record.id
        
        Write-Log \"DEBUG: Found A record: $name -> $currentRecordIP (Proxied: $proxied)\"
        
        if ($currentRecordIP -ne $currentIP) {
            Write-Log \"INFO: Record needs update: $name ($currentRecordIP -> $currentIP)\"
            
            if (-not $dryRun) {
                Write-Log \"INFO: Updating DNS record for $name...\"
                
                $updateData = @{
                    type = 'A'
                    name = $name
                    content = $currentIP
                    proxied = $proxied
                } | ConvertTo-Json
                
                try {
                    $response = Invoke-RestMethod -Uri \"https://api.cloudflare.com/client/v4/zones/$zoneId/dns_records/$recordId\" -Method PUT -Headers @{
                        'Authorization' = \"Bearer $cfToken\"
                        'Content-Type' = 'application/json'
                    } -Body $updateData
                    
                    if ($response.success) {
                        Write-Log \"SUCCESS: Updated $name to $currentIP\"
                    } else {
                        Write-Log \"ERROR: Failed to update $name - $($response.errors[0].message)\"
                    }
                } catch {
                    Write-Log \"ERROR: Exception updating $name - $($_.Exception.Message)\"
                }
            } else {
                Write-Log \"DRY RUN: Would update $name from $currentRecordIP to $currentIP\"
            }
        } else {
            Write-Log \"INFO: Record $name is already up to date ($currentRecordIP)\"
        }
    }
} else {
    Write-Log \"ERROR: Failed to retrieve DNS records\"
    exit 1
}
"

del records_response.json

if "%DRY_RUN%"=="true" (
    call :log "DRY RUN COMPLETED - No changes were made"
    call :log "To apply changes, set DRY_RUN=false in the script"
) else (
    call :log "CloudFlare DDNS update completed"
)

call :log "========================================"

REM Cleanup old logs if they get too large
for %%F in ("%LOG_FILE%") do (
    if %%~zF gtr %MAX_LOG_SIZE% (
        call :log "Log file size exceeded %MAX_LOG_SIZE% bytes, rotating..."
        if exist "%LOG_FILE%.old" del /f /q "%LOG_FILE%.old"
        move "%LOG_FILE%" "%LOG_FILE%.old"
    )
)

endlocal
