$ErrorActionPreference = "Stop"
try {
    iex (iwr "https://raw.githubusercontent.com/TrueBankai416/DemonWarriorTechDocs/mentat-2%233/scripts/download-all.ps1").Content
} catch {
    Write-Host "CRASH DETAILS:" -ForegroundColor Red
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Yellow
    Write-Host "Line: $($_.InvocationInfo.ScriptLineNumber)" -ForegroundColor Yellow
    Write-Host "Command: $($_.InvocationInfo.Line)" -ForegroundColor Yellow
    Write-Host "Category: $($_.CategoryInfo.Category)" -ForegroundColor Yellow
    Read-Host "Press Enter to see full error"
    Write-Host $_.Exception -ForegroundColor Red
}
