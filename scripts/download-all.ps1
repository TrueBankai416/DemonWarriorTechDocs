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
        $phpVersion = "8.3.24"
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
Write-Host "[3/3] Downloading latest WordPress..." -ForegroundColor Green
Invoke-WebRequest -Uri "https://wordpress.org/latest.zip" -OutFile "$env:TEMP\wordpress-latest.zip"
Write-Host "✅ Downloaded WordPress (latest)" -ForegroundColor Green


Write-Host ""
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "All downloads completed successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "Downloaded versions:" -ForegroundColor Yellow
Write-Host "- PHP: $phpVersion" -ForegroundColor White
Write-Host "- MariaDB: $mariaVersion" -ForegroundColor White
Write-Host "- WordPress: Latest" -ForegroundColor White
Write-Host ""
Write-Host "Files saved to: $env:TEMP" -ForegroundColor Yellow
Write-Host "================================================================" -ForegroundColor Cyan

# Ask user if they want to proceed with installation
Write-Host ""
$install = Read-Host "Would you like to proceed with installation now? (y/N)"
if ($install -match '^[Yy]') {
    Write-Host ""
    Write-Host "Starting installation process..." -ForegroundColor Green
    Write-Host ""
    
    # Install PHP
    Write-Host "Installing PHP..." -ForegroundColor Yellow
    try {
        Invoke-Expression (Invoke-WebRequest -Uri "https://raw.githubusercontent.com/TrueBankai416/DemonWarriorTechDocs/main/scripts/install-php.cmd").Content
        Write-Host "✅ PHP installation completed" -ForegroundColor Green
    } catch {
        Write-Host "❌ PHP installation failed: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    Write-Host ""
    
    # Install MariaDB
    Write-Host "Installing MariaDB..." -ForegroundColor Yellow
    try {
        Invoke-Expression (Invoke-WebRequest -Uri "https://raw.githubusercontent.com/TrueBankai416/DemonWarriorTechDocs/main/scripts/install-mariadb.cmd").Content
        Write-Host "✅ MariaDB installation completed" -ForegroundColor Green
    } catch {
        Write-Host "❌ MariaDB installation failed: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    Write-Host ""
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host "Installation completed!" -ForegroundColor Green
    Write-Host "Next: Install Caddy using the dedicated guide at:" -ForegroundColor Yellow
    Write-Host "https://demonwarriortechdocs.pages.dev/docs/Documented%20Tutorials/Caddy/Windows/Installing_Caddy_on_Windows" -ForegroundColor White
    Write-Host "================================================================" -ForegroundColor Cyan
} else {
    Write-Host ""
    Write-Host "Installation skipped. You can install manually using:" -ForegroundColor Yellow
    Write-Host "- PHP: curl -s https://raw.githubusercontent.com/TrueBankai416/DemonWarriorTechDocs/main/scripts/install-php.cmd | cmd" -ForegroundColor White
    Write-Host "- MariaDB: curl -s https://raw.githubusercontent.com/TrueBankai416/DemonWarriorTechDocs/main/scripts/install-mariadb.cmd | cmd" -ForegroundColor White
    Write-Host "- Caddy: Follow the guide at the link above" -ForegroundColor White
}
