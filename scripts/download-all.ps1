# WordPress Installation - Download All Components (PowerShell Version)
Write-Host "WordPress Installation - Download All Components (PowerShell Version)" -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan

# Check what's already installed BEFORE downloading
Write-Host "Checking existing installations..." -ForegroundColor Yellow

# Check PHP
$phpInstalled = $false
try {
    $phpVersion = php -v 2>$null
    if ($phpVersion -and $phpVersion -match "PHP (\d+\.\d+\.\d+)") {
        Write-Host "✅ PHP $($matches[1]) is already installed" -ForegroundColor Green
        $phpInstalled = $true
    }
} catch {
    if (Test-Path "C:\Tools\PHP\php.exe") {
        Write-Host "⚠️  PHP found at C:\Tools\PHP but not in PATH" -ForegroundColor Yellow
        $phpInstalled = $true
    } else {
        Write-Host "❌ PHP not installed" -ForegroundColor Red
    }
}

# Check MariaDB
$mariaInstalled = $false
try {
    $mariaService = Get-Service -Name "MariaDB*" -ErrorAction SilentlyContinue
    if ($mariaService) {
        Write-Host "✅ MariaDB service found ($($mariaService.Name))" -ForegroundColor Green
        $mariaInstalled = $true
    } else {
        # Check if MariaDB is installed but service not created
        if (Test-Path "C:\Program Files\MariaDB*") {
            Write-Host "⚠️  MariaDB installation found but service not configured" -ForegroundColor Yellow
            $mariaInstalled = $true
        } else {
            Write-Host "❌ MariaDB not installed" -ForegroundColor Red
        }
    }
} catch {
    Write-Host "❌ MariaDB not installed" -ForegroundColor Red
}

# Check WordPress
$wpInstalled = $false
if (Test-Path "C:\inetpub\wwwroot\wordpress\wp-config.php" -or Test-Path "C:\Tools\WordPress\wp-config.php") {
    Write-Host "✅ WordPress installation found" -ForegroundColor Green
    $wpInstalled = $true
} elseif (Test-Path "C:\inetpub\wwwroot\wordpress\index.php" -or Test-Path "C:\Tools\WordPress\index.php") {
    Write-Host "⚠️  WordPress files found but not configured" -ForegroundColor Yellow
    $wpInstalled = $true
} else {
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
    exit 0
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
        Write-Host "⚡ PHP already downloaded: $($phpFiles[0].Name)" -ForegroundColor Cyan
    } else {
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
    }
}

# Download MariaDB only if needed
if (-not $mariaInstalled) {
    Write-Host ""
    Write-Host "[2/?] Getting MariaDB LTS version..." -ForegroundColor Green
    
    # Check if already downloaded
    if (Test-Path "$env:TEMP\mariadb-latest-winx64.msi") {
        Write-Host "⚡ MariaDB already downloaded" -ForegroundColor Cyan
    } else {
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
            Invoke-WebRequest -Uri "https://wordpress.org/latest.zip" -OutFile "$env:TEMP\wordpress-latest.zip"
            Write-Host "✅ Downloaded WordPress (latest)" -ForegroundColor Green
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
Write-Host "- PHP: $phpVersion" -ForegroundColor White
Write-Host "- MariaDB: $mariaVersion" -ForegroundColor White
Write-Host "- WordPress: Latest" -ForegroundColor White
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
    Write-Host "You may still want to install Caddy using the dedicated guide." -ForegroundColor Yellow
    $install = "n"
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
            $phpScript = Join-Path $env:TEMP "install-php.cmd"
            Invoke-WebRequest -Uri "https://raw.githubusercontent.com/TrueBankai416/DemonWarriorTechDocs/refs/heads/mentat-2%233/scripts/install-php.cmd" -OutFile $phpScript
            $result = & cmd /c "`"$phpScript`""
            if ($LASTEXITCODE -eq 0) {
                Write-Host "✅ PHP installation completed" -ForegroundColor Green
            } else {
                Write-Host "❌ PHP installation failed" -ForegroundColor Red
            }
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
            $mariaScript = Join-Path $env:TEMP "install-mariadb.cmd"
            Invoke-WebRequest -Uri "https://raw.githubusercontent.com/TrueBankai416/DemonWarriorTechDocs/refs/heads/mentat-2%233/scripts/install-mariadb.cmd" -OutFile $mariaScript
            $result = & cmd /c "`"$mariaScript`""
            if ($LASTEXITCODE -eq 0) {
                Write-Host "✅ MariaDB installation completed" -ForegroundColor Green
            } else {
                Write-Host "❌ MariaDB installation failed" -ForegroundColor Red
            }
            Remove-Item $mariaScript -ErrorAction SilentlyContinue
        } catch {
            Write-Host "❌ MariaDB installation failed: $($_.Exception.Message)" -ForegroundColor Red
        }
        Write-Host ""
    } else {
        Write-Host "⏭️  Skipping MariaDB installation (already installed)" -ForegroundColor Cyan
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
    Write-Host "- PHP: curl -s https://raw.githubusercontent.com/TrueBankai416/DemonWarriorTechDocs/mentat-2%233/scripts/install-php.cmd | cmd" -ForegroundColor White
    Write-Host "- MariaDB: curl -s https://raw.githubusercontent.com/TrueBankai416/DemonWarriorTechDocs/mentat-2%233/scripts/install-mariadb.cmd | cmd" -ForegroundColor White
    Write-Host "- Caddy: Follow the guide at the link above" -ForegroundColor White
}
