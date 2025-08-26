# WordPress Installation - Download and Install All Components (PowerShell)
Write-Host "WordPress Installation - Download and Install All Components" -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan

# Check what's already installed BEFORE downloading
Write-Host "Checking existing installations..." -ForegroundColor Yellow

# Check PHP
$phpInstalled = $false
try {
    $phpVersion = & php --version 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ PHP is already installed" -ForegroundColor Green
        $phpInstalled = $true
    } else {
        Write-Host "❌ PHP not installed" -ForegroundColor Red
    }
} catch {
    Write-Host "❌ PHP not installed" -ForegroundColor Red
}

# Check MariaDB
$mariaInstalled = $false
try {
    $mariaService = Get-Service -Name "MariaDB" -ErrorAction SilentlyContinue
    if ($mariaService) {
        Write-Host "✅ MariaDB service found (MariaDB)" -ForegroundColor Green
        $mariaInstalled = $true
    } else {
        Write-Host "❌ MariaDB not installed" -ForegroundColor Red
    }
} catch {
    Write-Host "❌ MariaDB not installed" -ForegroundColor Red
}

# Check WordPress - Better detection method
$wpInstalled = $false
$wpLocations = @(
    "C:\inetpub\wwwroot\wordpress",
    "C:\Tools\WordPress",
    "C:\xampp\htdocs\wordpress",
    "C:\wamp\www\wordpress"
)

$wpFound = $false
foreach ($location in $wpLocations) {
    if (Test-Path "$location\wp-includes\version.php") {
        Write-Host "✅ WordPress installation found at $location" -ForegroundColor Green
        $wpInstalled = $true
        $wpFound = $true
        break
    } elseif (Test-Path "$location\index.php") {
        $indexContent = Get-Content "$location\index.php" -Raw -ErrorAction SilentlyContinue
        if ($indexContent -and $indexContent.Contains("wp-blog-header.php")) {
            Write-Host "✅ WordPress installation found at $location" -ForegroundColor Green
            $wpInstalled = $true
            $wpFound = $true
            break
        }
    }
}

if (-not $wpFound) {
    Write-Host "❌ WordPress not installed" -ForegroundColor Red
}

# Determine what needs to be downloaded
$needsDownload = @()
if (-not $phpInstalled) { $needsDownload += "PHP" }
if (-not $mariaInstalled) { $needsDownload += "MariaDB" }
if (-not $wpInstalled) { $needsDownload += "WordPress" }

Write-Host ""
if ($needsDownload.Count -eq 0) {
    Write-Host "🎉 All components are already installed!" -ForegroundColor Green
    Write-Host "No downloads needed. You may still want to install Caddy using the dedicated guide." -ForegroundColor Yellow
    return
} else {
    Write-Host "Components to download: $($needsDownload -join ', ')" -ForegroundColor Yellow
    Write-Host "Starting selective download process..." -ForegroundColor Yellow
    Write-Host ""
}

# Download PHP only if needed
if (-not $phpInstalled) {
    Write-Host "[1/?] Getting latest PHP 8.x version..." -ForegroundColor Green
    
    # Check if already downloaded
    $phpFiles = Get-ChildItem "$env:TEMP\php-*-nts-Win32-vs16-x64.zip" -ErrorAction SilentlyContinue
    if ($phpFiles) {
        $phpFile = $phpFiles | Select-Object -First 1
        $phpVersion = $phpFile.Name -replace "php-(\d+\.\d+\.\d+)-nts-Win32-vs16-x64\.zip", '$1'
        Write-Host "⚡ PHP $phpVersion already downloaded" -ForegroundColor Cyan
    } else {
        try {
            # Get latest PHP 8.x version dynamically
            $releases = Invoke-RestMethod 'https://www.php.net/releases/?json&version=8'
            $latestVersion = $releases.PSObject.Properties.Name | Sort-Object {[Version]$_} -Descending | Select-Object -First 1
            Write-Host "Latest PHP version: $latestVersion" -ForegroundColor White
            
            $phpUrl = "https://windows.php.net/downloads/releases/php-$latestVersion-nts-Win32-vs16-x64.zip"
            $phpFile = "$env:TEMP\php-$latestVersion-nts-Win32-vs16-x64.zip"
            
            Write-Host "Downloading PHP $latestVersion..." -ForegroundColor Yellow
            Invoke-WebRequest -Uri $phpUrl -OutFile $phpFile -UseBasicParsing
            Write-Host "✅ PHP $latestVersion downloaded" -ForegroundColor Green
        } catch {
            Write-Host "❌ PHP download failed: $($_.Exception.Message)" -ForegroundColor Red
            Write-Host "Error details: $($_.Exception)" -ForegroundColor Red
        }
    }
}

# Download MariaDB only if needed
if (-not $mariaInstalled) {
    Write-Host ""
    Write-Host "[2/?] Getting latest MariaDB version..." -ForegroundColor Green
    
    # Check if already downloaded
    if (Test-Path "$env:TEMP\mariadb-latest-winx64.msi") {
        Write-Host "⚡ MariaDB already downloaded" -ForegroundColor Cyan
    } else {
        try {
            # Get latest MariaDB LTS version
            $mariaApi = Invoke-RestMethod 'https://downloads.mariadb.org/rest-api/mariadb/'
            $latestLTS = $mariaApi.major_releases | Where-Object { $_.release_status -eq 'Stable' } | Sort-Object release_id -Descending | Select-Object -First 1
            $mariaVersion = $latestLTS.release_id
            Write-Host "Latest MariaDB LTS: $mariaVersion" -ForegroundColor White
            
            # Get download URL for latest version
            $mariaDownloads = Invoke-RestMethod "https://downloads.mariadb.org/rest-api/mariadb/$mariaVersion/?type=win64"
            $latestRelease = $mariaDownloads.releases.PSObject.Properties.Name | Sort-Object {[Version]$_} -Descending | Select-Object -First 1
            $mariaFile = $mariaDownloads.releases.$latestRelease.files | Where-Object { $_.file_name -like '*winx64.msi' } | Select-Object -First 1
            
            if ($mariaFile -and $mariaFile.mirror_url) {
                Write-Host "Downloading MariaDB $mariaVersion..." -ForegroundColor Yellow
                Invoke-WebRequest -Uri $mariaFile.mirror_url -OutFile "$env:TEMP\mariadb-latest-winx64.msi" -UseBasicParsing
                Write-Host "✅ MariaDB $mariaVersion downloaded" -ForegroundColor Green
            } else {
                Write-Host "❌ Could not find MariaDB download URL" -ForegroundColor Red
            }
        } catch {
            Write-Host "❌ MariaDB download failed: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
}

# Download WordPress only if needed
if (-not $wpInstalled) {
    Write-Host ""
    Write-Host "[3/?] Downloading latest WordPress..." -ForegroundColor Green
    
    # Check if already downloaded
    if (Test-Path "$env:TEMP\wordpress-latest.zip") {
        Write-Host "⚡ WordPress already downloaded" -ForegroundColor Cyan
    } else {
        try {
            Write-Host "Downloading WordPress..." -ForegroundColor Yellow
            Invoke-WebRequest -Uri "https://wordpress.org/latest.zip" -OutFile "$env:TEMP\wordpress-latest.zip" -UseBasicParsing
            Write-Host "✅ WordPress downloaded" -ForegroundColor Green
        } catch {
            Write-Host "❌ WordPress download failed: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
}

Write-Host ""
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "All downloads completed successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "Downloaded versions:" -ForegroundColor Yellow

# Extract PHP version from downloaded file
$phpFile = Get-ChildItem "$env:TEMP\php-*-nts-Win32-vs16-x64.zip" -ErrorAction SilentlyContinue | Select-Object -First 1
if ($phpFile) {
    $phpVersionFromFile = $phpFile.Name -replace "php-(\d+\.\d+\.\d+)-nts-Win32-vs16-x64\.zip", '$1'
    Write-Host "- PHP: $phpVersionFromFile" -ForegroundColor White
} else {
    Write-Host "- PHP: Not downloaded" -ForegroundColor Gray
}

# Extract MariaDB version from downloaded file or variable
$mariaFile = Get-ChildItem "$env:TEMP\mariadb-*.msi" -ErrorAction SilentlyContinue | Select-Object -First 1
if ($mariaFile -and $mariaVersion) {
    Write-Host "- MariaDB: $mariaVersion" -ForegroundColor White
} else {
    Write-Host "- MariaDB: Not downloaded" -ForegroundColor Gray
}

# WordPress version
$wpFile = Get-ChildItem "$env:TEMP\wordpress-latest.zip" -ErrorAction SilentlyContinue
if ($wpFile) {
    Write-Host "- WordPress: Latest" -ForegroundColor White
} else {
    Write-Host "- WordPress: Not downloaded" -ForegroundColor Gray
}

Write-Host ""
Write-Host "Files saved to: $env:TEMP" -ForegroundColor Yellow
Write-Host "================================================================" -ForegroundColor Cyan

# Ask user if they want to proceed with installation
$needsInstall = @()
if (-not $phpInstalled) { $needsInstall += "PHP" }
if (-not $mariaInstalled) { $needsInstall += "MariaDB" }
if (-not $wpInstalled) { $needsInstall += "WordPress" }

Write-Host ""
if ($needsInstall.Count -eq 0) {
    Write-Host "🎉 All components are already installed!" -ForegroundColor Green
    Write-Host "Installation complete!" -ForegroundColor Green
    return
} else {
    Write-Host "Components to install: $($needsInstall -join ', ')" -ForegroundColor Yellow
    $install = Read-Host "Would you like to install the missing components? (y/N)"
}

if ($install -match '^[Yy]') {
    Write-Host ""
    Write-Host "Starting installation process..." -ForegroundColor Green
    Write-Host ""
    
    # Install only missing components
    if (-not $phpInstalled) {
        Write-Host "Installing PHP..." -ForegroundColor Yellow
        try {
            $phpScript = "$env:TEMP\install-php.ps1"
            Invoke-WebRequest -Uri "https://raw.githubusercontent.com/TrueBankai416/DemonWarriorTechDocs/mentat-2%233/scripts/install-php.ps1" -OutFile $phpScript -UseBasicParsing
            & $phpScript
            Remove-Item $phpScript -ErrorAction SilentlyContinue
        } catch {
            Write-Host "❌ PHP installation failed: $($_.Exception.Message)" -ForegroundColor Red
        }
        Write-Host ""
    } else {
        Write-Host "⏭️  Skipping PHP installation (already installed)" -ForegroundColor Cyan
    }
    
    if (-not $mariaInstalled) {
        Write-Host "Installing MariaDB..." -ForegroundColor Yellow
        try {
            $mariaScript = "$env:TEMP\install-mariadb.ps1"
            Invoke-WebRequest -Uri "https://raw.githubusercontent.com/TrueBankai416/DemonWarriorTechDocs/mentat-2%233/scripts/install-mariadb.ps1" -OutFile $mariaScript -UseBasicParsing
            & $mariaScript
            Remove-Item $mariaScript -ErrorAction SilentlyContinue
        } catch {
            Write-Host "❌ MariaDB installation failed: $($_.Exception.Message)" -ForegroundColor Red
        }
        Write-Host ""
    } else {
        Write-Host "⏭️  Skipping MariaDB installation (already installed)" -ForegroundColor Cyan
    }
    
    if (-not $wpInstalled) {
        Write-Host "Installing WordPress..." -ForegroundColor Yellow
        try {
            $wpScript = "$env:TEMP\install-wordpress.ps1"
            Invoke-WebRequest -Uri "https://raw.githubusercontent.com/TrueBankai416/DemonWarriorTechDocs/mentat-2%233/scripts/install-wordpress.ps1" -OutFile $wpScript -UseBasicParsing
            & $wpScript
            Remove-Item $wpScript -ErrorAction SilentlyContinue
        } catch {
            Write-Host "❌ WordPress installation failed: $($_.Exception.Message)" -ForegroundColor Red
        }
        Write-Host ""
    } else {
        Write-Host "⏭️  Skipping WordPress installation (already installed)" -ForegroundColor Cyan
    }
    
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host "Installation process completed!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Yellow
    Write-Host "1. Install Caddy web server using our dedicated guide" -ForegroundColor White
    Write-Host "2. Configure your WordPress site" -ForegroundColor White
    Write-Host "3. Set up SSL certificates (handled by Caddy)" -ForegroundColor White
    Write-Host "================================================================" -ForegroundColor Cyan
} else {
    Write-Host ""
    Write-Host "Installation skipped by user." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "You can install components individually using:" -ForegroundColor Cyan
    if (-not $phpInstalled) {
        Write-Host "- PHP: .\install-php.ps1" -ForegroundColor White
    }
    if (-not $mariaInstalled) {
        Write-Host "- MariaDB: .\install-mariadb.ps1" -ForegroundColor White
    }
    if (-not $wpInstalled) {
        Write-Host "- WordPress: .\install-wordpress.ps1" -ForegroundColor White
    }
}
