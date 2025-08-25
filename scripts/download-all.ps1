# WordPress Installation - Download All Components (PowerShell Version)
Write-Host "WordPress Installation - Download All Components (PowerShell Version)" -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan

Write-Host "Downloading all components with latest versions..." -ForegroundColor Yellow
Write-Host ""

# Get latest PHP version
Write-Host "[1/5] Getting latest PHP 8.x version..." -ForegroundColor Green
$releases = Invoke-RestMethod 'https://www.php.net/releases/?json&version=8'
$phpVersion = $releases.PSObject.Properties.Name | Sort-Object {[Version]$_} -Descending | Select-Object -First 1
Write-Host "Latest PHP version: $phpVersion" -ForegroundColor White
Invoke-WebRequest -Uri "https://windows.php.net/downloads/releases/php-$phpVersion-nts-Win32-vs16-x64.zip" -OutFile "$env:TEMP\php-$phpVersion-nts-Win32-vs16-x64.zip"
Write-Host "✅ Downloaded PHP $phpVersion" -ForegroundColor Green

# Get latest MariaDB LTS
Write-Host ""
Write-Host "[2/5] Getting latest MariaDB LTS version..." -ForegroundColor Green
$api = Invoke-RestMethod 'https://downloads.mariadb.org/rest-api/mariadb/'
$mariaVersion = $api.major_releases | Where-Object { $_.release_status -eq 'Stable' } | Sort-Object release_id -Descending | Select-Object -First 1 -ExpandProperty release_id
Write-Host "Latest MariaDB LTS: $mariaVersion" -ForegroundColor White
$dl = Invoke-RestMethod "https://downloads.mariadb.org/rest-api/mariadb/$mariaVersion?type=win64"
$latest = $dl.releases.PSObject.Properties.Name | Sort-Object {[Version]$_} -Descending | Select-Object -First 1
$file = $dl.releases.$latest.files | Where-Object { $_.file_name -like '*winx64.msi' } | Select-Object -First 1
Invoke-WebRequest -Uri $file.mirror_url -OutFile "$env:TEMP\mariadb-latest-winx64.msi"
Write-Host "✅ Downloaded MariaDB $mariaVersion" -ForegroundColor Green

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
Invoke-WebRequest -Uri "https://github.com/caddyserver/caddy/releases/latest/download/caddy_windows_amd64.zip" -OutFile "$env:TEMP\caddy_windows_amd64.zip"
Write-Host "✅ Downloaded Caddy (latest)" -ForegroundColor Green

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
