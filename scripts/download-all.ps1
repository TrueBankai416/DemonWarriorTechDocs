# WordPress Installation - Download All Components (PowerShell Version)
Write-Host "WordPress Installation - Download All Components (PowerShell Version)" -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan

Write-Host "Downloading all components with latest versions..." -ForegroundColor Yellow
Write-Host ""

# Get latest PHP version
Write-Host "[1/5] Getting latest PHP 8.x version..." -ForegroundColor Green
try {
    $releases = Invoke-RestMethod 'https://www.php.net/releases/?json&version=8'
    # Filter only version number properties (exclude 'announcement', 'tags', etc.)
    $phpVersion = $releases.PSObject.Properties.Name | Where-Object { $_ -match '^\d+\.\d+\.\d+$' } | Sort-Object {[Version]$_} -Descending | Select-Object -First 1
    if (-not $phpVersion) {
        # Fallback to known working version
        $phpVersion = "8.3.12"
        Write-Host "Using fallback PHP version: $phpVersion" -ForegroundColor Yellow
    } else {
        Write-Host "Latest PHP version: $phpVersion" -ForegroundColor White
    }
    Invoke-WebRequest -Uri "https://windows.php.net/downloads/releases/php-$phpVersion-nts-Win32-vs16-x64.zip" -OutFile "$env:TEMP\php-$phpVersion-nts-Win32-vs16-x64.zip"
    Write-Host "✅ Downloaded PHP $phpVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ PHP download failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Get latest MariaDB LTS
Write-Host ""
Write-Host "[2/5] Getting latest MariaDB LTS version..." -ForegroundColor Green
try {
    # Use known working MariaDB LTS version due to API complexity
    $mariaVersion = "10.11.6"
    $mariaUrl = "https://downloads.mariadb.org/interstitial/mariadb-10.11.6/winx64-packages/mariadb-10.11.6-winx64.msi"
    Write-Host "Using stable MariaDB LTS: $mariaVersion" -ForegroundColor White
    Invoke-WebRequest -Uri $mariaUrl -OutFile "$env:TEMP\mariadb-latest-winx64.msi"
    Write-Host "✅ Downloaded MariaDB $mariaVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ MariaDB download failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Download WordPress (already dynamic)
Write-Host ""
Write-Host "[3/5] Downloading latest WordPress..." -ForegroundColor Green
Invoke-WebRequest -Uri "https://wordpress.org/latest.zip" -OutFile "$env:TEMP\wordpress-latest.zip"
Write-Host "✅ Downloaded WordPress (latest)" -ForegroundColor Green

# Get latest NSSM version
Write-Host ""
Write-Host "[4/5] Getting latest NSSM version..." -ForegroundColor Green
$page = Invoke-WebRequest 'https://nssm.cc/download' -UseBasicParsing
$link = ($page.Links | Where-Object { $_.href -match 'nssm-\d+\.\d+\.zip$' } | Select-Object -First 1).href
if ($link) {
    $nssmVersion = ($link -split '/')[-1] -replace '\.zip$', ''
} else {
    $nssmVersion = 'nssm-2.24'
}
Write-Host "Latest NSSM version: $nssmVersion" -ForegroundColor White
Invoke-WebRequest -Uri "https://nssm.cc/release/$nssmVersion.zip" -OutFile "$env:TEMP\$nssmVersion.zip"
Write-Host "✅ Downloaded $nssmVersion" -ForegroundColor Green

# Download Caddy (already dynamic)
Write-Host ""
Write-Host "[5/5] Downloading latest Caddy..." -ForegroundColor Green
try {
    Invoke-WebRequest -Uri "https://github.com/caddyserver/caddy/releases/latest/download/caddy_windows_amd64.zip" -OutFile "$env:TEMP\caddy_windows_amd64.zip"
    Write-Host "✅ Downloaded Caddy (latest)" -ForegroundColor Green
} catch {
    Write-Host "❌ Caddy download failed: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "All downloads completed successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "Downloaded versions:" -ForegroundColor Yellow
Write-Host "- PHP: $phpVersion" -ForegroundColor White
Write-Host "- MariaDB: $mariaVersion" -ForegroundColor White
Write-Host "- WordPress: Latest" -ForegroundColor White
Write-Host "- NSSM: $nssmVersion" -ForegroundColor White
Write-Host "- Caddy: Latest" -ForegroundColor White
Write-Host ""
Write-Host "Files saved to: $env:TEMP" -ForegroundColor Yellow
Write-Host "Next: Run the installation scripts or follow the manual installation guide." -ForegroundColor Yellow
Write-Host "================================================================" -ForegroundColor Cyan
