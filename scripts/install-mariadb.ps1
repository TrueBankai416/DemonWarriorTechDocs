# WordPress Installation - Install MariaDB (PowerShell)
Write-Host "WordPress Installation - Install MariaDB (PowerShell)" -ForegroundColor Cyan
Write-Host "====================================================" -ForegroundColor Cyan

Write-Host "Installing MariaDB from downloaded files..." -ForegroundColor Yellow
Write-Host ""

# Generate random root password for security using built-in PowerShell
Write-Host "Generating secure root password..." -ForegroundColor Yellow
$chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#$^&*"
$rootPassword = -join ((1..16) | ForEach-Object { $chars[(Get-Random -Maximum $chars.Length)] })
Write-Host "Root password generated: $rootPassword" -ForegroundColor White
Write-Host ""

# Install MariaDB silently
Write-Host "[1/3] Installing MariaDB..." -ForegroundColor Green
if (-not (Test-Path "$env:TEMP\mariadb-latest-winx64.msi")) {
    Write-Host "❌ MariaDB installer not found in $env:TEMP" -ForegroundColor Red
    exit 1
}

try {
    $msiArgs = @(
        "/i", "`"$env:TEMP\mariadb-latest-winx64.msi`"",
        "/quiet",
        "/norestart",
        "SERVICENAME=MariaDB",
        "PASSWORD=`"$rootPassword`"",
        "UTF8=1"
    )
    
    $process = Start-Process -FilePath "msiexec.exe" -ArgumentList $msiArgs -Wait -PassThru
    
    if ($process.ExitCode -ne 0) {
        Write-Host "❌ MariaDB installation failed (exit code: $($process.ExitCode))" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "❌ MariaDB installation failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Wait for service to start and verify installation
Write-Host ""
Write-Host "[2/3] Waiting for MariaDB service to start..." -ForegroundColor Green
Start-Sleep -Seconds 15

# Verify MariaDB service is running
try {
    $mariaService = Get-Service -Name "MariaDB" -ErrorAction SilentlyContinue
    if ($mariaService -and $mariaService.Status -eq "Running") {
        Write-Host "✅ MariaDB installed and service is running" -ForegroundColor Green
    } else {
        Write-Host "❌ MariaDB installation failed - service not running" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "❌ MariaDB installation failed - service not found" -ForegroundColor Red
    exit 1
}

# Create WordPress database and user
Write-Host ""
Write-Host "[3/3] Creating WordPress database..." -ForegroundColor Green

$sqlCommands = @"
CREATE DATABASE wordpress CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER 'wordpress'@'localhost' IDENTIFIED BY 'WordPressPassword123!';
GRANT ALL PRIVILEGES ON wordpress.* TO 'wordpress'@'localhost';
FLUSH PRIVILEGES;
"@

$sqlFile = "$env:TEMP\setup_db.sql"
$sqlCommands | Out-File -FilePath $sqlFile -Encoding UTF8

# Execute database setup (find MariaDB installation dynamically)
$dbCreated = $false
$mariaDBPaths = Get-ChildItem "C:\Program Files\MariaDB*" -Directory -ErrorAction SilentlyContinue

foreach ($mariaPath in $mariaDBPaths) {
    $mysqlPath = Join-Path $mariaPath.FullName "bin\mysql.exe"
    if (Test-Path $mysqlPath) {
        try {
            $process = Start-Process -FilePath $mysqlPath -ArgumentList @("-u", "root", "-p$rootPassword") -RedirectStandardInput $sqlFile -Wait -PassThru -NoNewWindow
            if ($process.ExitCode -eq 0) {
                Write-Host "✅ WordPress database created" -ForegroundColor Green
                $dbCreated = $true
                break
            } else {
                Write-Host "❌ Failed to create WordPress database (exit code: $($process.ExitCode))" -ForegroundColor Red
            }
        } catch {
            Write-Host "❌ Failed to create WordPress database: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
}

if (-not $dbCreated) {
    Write-Host "❌ MariaDB installation not found in Program Files or database creation failed" -ForegroundColor Red
    exit 1
}

# Clean up
Remove-Item $sqlFile -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "====================================================" -ForegroundColor Cyan
Write-Host "MariaDB installation completed successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "Database: wordpress" -ForegroundColor White
Write-Host "Username: wordpress" -ForegroundColor White
Write-Host "Password: WordPressPassword123!" -ForegroundColor White
Write-Host ""
Write-Host "⚠️  IMPORTANT: SAVE THIS ROOT PASSWORD SAFELY! ⚠️" -ForegroundColor Red
Write-Host "Root Password: $rootPassword" -ForegroundColor Yellow
Write-Host ""
Write-Host "🔒 This password was randomly generated for security." -ForegroundColor Cyan
Write-Host "📝 Save it in a secure password manager immediately!" -ForegroundColor Cyan
Write-Host "🚨 You will need this password for database administration." -ForegroundColor Cyan
Write-Host "====================================================" -ForegroundColor Cyan
