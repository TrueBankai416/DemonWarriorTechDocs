# WordPress Installation - Install WordPress (PowerShell)
Write-Host "WordPress Installation - Install WordPress (PowerShell)" -ForegroundColor Cyan
Write-Host "======================================================" -ForegroundColor Cyan

Write-Host "Installing WordPress from downloaded files..." -ForegroundColor Yellow
Write-Host ""

# Create web directory
Write-Host "[1/2] Creating web directory..." -ForegroundColor Green
$webRoot = "C:\inetpub\wwwroot"
$wpPath = "$webRoot\wordpress"

if (-not (Test-Path $webRoot)) {
    New-Item -ItemType Directory -Path $webRoot -Force | Out-Null
    Write-Host "✅ Created $webRoot" -ForegroundColor Green
} else {
    Write-Host "✅ $webRoot already exists" -ForegroundColor Green
}

if (-not (Test-Path $wpPath)) {
    New-Item -ItemType Directory -Path $wpPath -Force | Out-Null
    Write-Host "✅ Created $wpPath" -ForegroundColor Green
} else {
    Write-Host "✅ $wpPath already exists" -ForegroundColor Green
}

# Extract WordPress
Write-Host ""
Write-Host "[2/2] Extracting WordPress..." -ForegroundColor Green

$wpFile = "$env:TEMP\wordpress-latest.zip"
if (-not (Test-Path $wpFile)) {
    Write-Host "❌ WordPress ZIP file not found at $wpFile" -ForegroundColor Red
    exit 1
}

try {
    # Extract to temporary location first
    $tempExtractPath = "$env:TEMP\wordpress_extract"
    if (Test-Path $tempExtractPath) {
        Remove-Item $tempExtractPath -Recurse -Force
    }
    
    Expand-Archive -Path $wpFile -DestinationPath $tempExtractPath -Force
    
    # WordPress extracts to a 'wordpress' subdirectory
    $wpSourceDir = "$tempExtractPath\wordpress"
    if (Test-Path $wpSourceDir) {
        # Copy contents to web directory
        Copy-Item "$wpSourceDir\*" $wpPath -Recurse -Force
        Write-Host "✅ WordPress extracted to $wpPath" -ForegroundColor Green
    } else {
        Write-Host "❌ WordPress extraction failed - wordpress directory not found" -ForegroundColor Red
        exit 1
    }
    
    # Clean up temp extraction
    Remove-Item $tempExtractPath -Recurse -Force -ErrorAction SilentlyContinue
} catch {
    Write-Host "❌ WordPress extraction failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Set proper permissions (if possible)
try {
    # Give IIS_IUSRS full control over WordPress directory
    $acl = Get-Acl $wpPath
    $accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule("IIS_IUSRS", "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow")
    $acl.SetAccessRule($accessRule)
    Set-Acl -Path $wpPath -AclObject $acl
    Write-Host "✅ Set permissions for IIS_IUSRS" -ForegroundColor Green
} catch {
    Write-Host "⚠️  Could not set permissions: $($_.Exception.Message)" -ForegroundColor Yellow
    Write-Host "You may need to set permissions manually for your web server" -ForegroundColor Gray
}

Write-Host ""
Write-Host "======================================================" -ForegroundColor Cyan
Write-Host "WordPress installation completed successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "WordPress is installed at: $wpPath" -ForegroundColor White
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Configure your web server (Caddy/IIS/Apache) to serve from $wpPath" -ForegroundColor White
Write-Host "2. Create wp-config.php with your database settings:" -ForegroundColor White
Write-Host "   - Database: wordpress" -ForegroundColor Gray
Write-Host "   - Username: wordpress" -ForegroundColor Gray
Write-Host "   - Password: WordPressPassword123!" -ForegroundColor Gray
Write-Host "   - Host: localhost" -ForegroundColor Gray
Write-Host "3. Complete WordPress setup through web interface" -ForegroundColor White
Write-Host "======================================================" -ForegroundColor Cyan
