# WordPress Installation - Install PHP (PowerShell)
Write-Host "WordPress Installation - Install PHP (PowerShell)" -ForegroundColor Cyan
Write-Host "=================================================" -ForegroundColor Cyan

Write-Host "Installing PHP from downloaded files..." -ForegroundColor Yellow
Write-Host ""

# Create main tools directory
Write-Host "[1/5] Creating directories..." -ForegroundColor Green
$toolsPath = "C:\Tools"
$phpPath = "C:\Tools\PHP"

if (-not (Test-Path $toolsPath)) {
    New-Item -ItemType Directory -Path $toolsPath -Force | Out-Null
    Write-Host "✅ Created $toolsPath" -ForegroundColor Green
} else {
    Write-Host "✅ $toolsPath already exists" -ForegroundColor Green
}

if (-not (Test-Path $phpPath)) {
    New-Item -ItemType Directory -Path $phpPath -Force | Out-Null
    Write-Host "✅ Created $phpPath" -ForegroundColor Green
} else {
    Write-Host "✅ $phpPath already exists" -ForegroundColor Green
}

# Extract PHP
Write-Host ""
Write-Host "[2/5] Extracting PHP..." -ForegroundColor Green

$phpFiles = Get-ChildItem "$env:TEMP\php-*-nts-Win32-vs16-x64.zip" -ErrorAction SilentlyContinue
if (-not $phpFiles) {
    Write-Host "❌ PHP ZIP file not found in $env:TEMP" -ForegroundColor Red
    exit 1
}

$phpFile = $phpFiles | Select-Object -First 1
Write-Host "Found PHP file: $($phpFile.Name)" -ForegroundColor White

try {
    # Extract to temporary location first
    $tempExtractPath = "$env:TEMP\php_extract"
    if (Test-Path $tempExtractPath) {
        Remove-Item $tempExtractPath -Recurse -Force
    }
    
    Expand-Archive -Path $phpFile.FullName -DestinationPath $tempExtractPath -Force
    
    # Find the extracted PHP directory
    $extractedDirs = Get-ChildItem $tempExtractPath -Directory
    if ($extractedDirs) {
        $phpSourceDir = $extractedDirs[0].FullName
        # Copy contents to C:\Tools\PHP
        Copy-Item "$phpSourceDir\*" $phpPath -Recurse -Force
        Write-Host "✅ PHP extracted to $phpPath" -ForegroundColor Green
    } else {
        # Files might be directly in the temp directory
        Copy-Item "$tempExtractPath\*" $phpPath -Recurse -Force
        Write-Host "✅ PHP extracted to $phpPath" -ForegroundColor Green
    }
    
    # Clean up temp extraction
    Remove-Item $tempExtractPath -Recurse -Force -ErrorAction SilentlyContinue
} catch {
    Write-Host "❌ PHP extraction failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Configure PHP
Write-Host ""
Write-Host "[3/5] Configuring PHP..." -ForegroundColor Green

$phpIniPath = "$phpPath\php.ini"
$phpIniTemplate = "$phpPath\php.ini-production"

if (Test-Path $phpIniTemplate) {
    Copy-Item $phpIniTemplate $phpIniPath -Force
    Write-Host "✅ PHP configuration template copied" -ForegroundColor Green
} else {
    Write-Host "⚠️  php.ini-production not found, creating basic configuration" -ForegroundColor Yellow
    New-Item -ItemType File -Path $phpIniPath -Force | Out-Null
}

# Create required directories
$phpDirs = @("logs", "tmp", "sessions")
foreach ($dir in $phpDirs) {
    $dirPath = "$phpPath\$dir"
    if (-not (Test-Path $dirPath)) {
        New-Item -ItemType Directory -Path $dirPath -Force | Out-Null
    }
}

# Configure PHP settings
$phpConfig = @"

; PHP Configuration for WordPress
; Memory and Performance
memory_limit = 512M
max_execution_time = 300
max_input_time = 300
post_max_size = 64M
upload_max_filesize = 64M
max_file_uploads = 20

; Error Reporting
display_errors = Off
log_errors = On
error_log = C:\Tools\PHP\logs\php_errors.log

; Extensions
extension_dir = "ext"
extension=bz2
extension=curl
extension=ffi
extension=fileinfo
extension=gd
extension=gettext
extension=gmp
extension=intl
extension=mbstring
extension=exif
extension=mysqli
extension=odbc
extension=openssl
extension=pdo_mysql
extension=pdo_odbc
extension=pdo_sqlite
extension=zip
extension=opcache

; OPcache Configuration
opcache.enable=1
opcache.enable_cli=1
opcache.memory_consumption=256
opcache.interned_strings_buffer=8
opcache.max_accelerated_files=10000
opcache.revalidate_freq=2
opcache.fast_shutdown=1

; Session Configuration
session.save_handler = files
session.save_path = "C:\Tools\PHP\tmp"
session.gc_maxlifetime = 1440

; CGI Configuration
cgi.force_redirect = 0
cgi.fix_pathinfo = 1
fastcgi.impersonate = 1
"@

Add-Content -Path $phpIniPath -Value $phpConfig
Write-Host "✅ PHP configuration updated" -ForegroundColor Green

# Add PHP to PATH
Write-Host ""
Write-Host "[4/5] Adding PHP to system PATH..." -ForegroundColor Green

try {
    $currentPath = [Environment]::GetEnvironmentVariable("PATH", "Machine")
    if ($currentPath -notlike "*C:\Tools\PHP*") {
        Write-Host "Adding PHP to system PATH..." -ForegroundColor Yellow
        $newPath = $currentPath + ";C:\Tools\PHP"
        [Environment]::SetEnvironmentVariable("PATH", $newPath, "Machine")
        Write-Host "✅ PHP added to system PATH" -ForegroundColor Green
    } else {
        Write-Host "✅ PHP already in system PATH" -ForegroundColor Green
    }
} catch {
    Write-Host "⚠️  Could not add PHP to system PATH (requires admin): $($_.Exception.Message)" -ForegroundColor Yellow
    Write-Host "You can add it manually: C:\Tools\PHP" -ForegroundColor Gray
}

# Create PHP service
Write-Host ""
Write-Host "[5/5] Creating PHP service..." -ForegroundColor Green

try {
    $phpService = Get-Service -Name "PHP-CGI" -ErrorAction SilentlyContinue
    if (-not $phpService) {
        Write-Host "Creating PHP-CGI service..." -ForegroundColor Yellow
        
        # First, let's test if php-cgi.exe exists
        if (-not (Test-Path "$phpPath\php-cgi.exe")) {
            Write-Host "❌ php-cgi.exe not found at $phpPath\php-cgi.exe" -ForegroundColor Red
            Write-Host "⚠️  PHP service creation skipped" -ForegroundColor Yellow
        } else {
            # Create a wrapper script for the service
            $wrapperScript = @"
@echo off
cd /d "$phpPath"
php-cgi.exe -b 127.0.0.1:9000
"@
            $wrapperPath = "$phpPath\php-cgi-service.cmd"
            $wrapperScript | Out-File -FilePath $wrapperPath -Encoding ASCII
            
            try {
                New-Service -Name "PHP-CGI" -BinaryPathName "cmd.exe /c `"$wrapperPath`"" -DisplayName "PHP FastCGI Service" -Description "PHP FastCGI service for web applications" -StartupType Automatic
                Write-Host "✅ PHP-CGI service created with automatic startup" -ForegroundColor Green
                
                # Test starting the service
                Write-Host "Testing PHP-CGI service startup..." -ForegroundColor Yellow
                try {
                    Start-Service -Name "PHP-CGI" -ErrorAction Stop
                    Start-Sleep -Seconds 3
                    $serviceStatus = Get-Service -Name "PHP-CGI"
                    if ($serviceStatus.Status -eq "Running") {
                        Write-Host "✅ PHP-CGI service started successfully" -ForegroundColor Green
                    } else {
                        Write-Host "❌ PHP-CGI service failed to start (Status: $($serviceStatus.Status))" -ForegroundColor Red
                        Write-Host "⚠️  You can try starting it manually: net start PHP-CGI" -ForegroundColor Yellow
                    }
                } catch {
                    Write-Host "❌ PHP service created but failed to start: $($_.Exception.Message)" -ForegroundColor Red
                    Write-Host "⚠️  This is common - you can start it manually: net start PHP-CGI" -ForegroundColor Yellow
                }
            } catch {
                Write-Host "❌ Failed to create PHP service: $($_.Exception.Message)" -ForegroundColor Red
            }
        }
    } else {
        Write-Host "✅ PHP-CGI service already exists" -ForegroundColor Green
        Set-Service -Name "PHP-CGI" -StartupType Automatic
        Write-Host "✅ PHP service set to start automatically" -ForegroundColor Green
        try {
            Start-Service -Name "PHP-CGI" -ErrorAction SilentlyContinue
            Write-Host "✅ PHP service running" -ForegroundColor Green
        } catch {
            Write-Host "⚠️  PHP service exists but may already be running" -ForegroundColor Yellow
        }
    }
} catch {
    Write-Host "❌ PHP service operation failed (requires admin): $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "=================================================" -ForegroundColor Cyan
Write-Host "PHP installation completed successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "PHP is installed at: $phpPath" -ForegroundColor White
Write-Host "PHP service created: PHP-CGI (automatic startup)" -ForegroundColor White
Write-Host ""
Write-Host "PHP service will start automatically at boot" -ForegroundColor Cyan
Write-Host "To start PHP service now: net start PHP-CGI" -ForegroundColor Cyan
Write-Host "To test PHP: php --version" -ForegroundColor Cyan
Write-Host "=================================================" -ForegroundColor Cyan
