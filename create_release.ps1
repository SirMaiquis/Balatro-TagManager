# TagManager Mod Release Builder
# This script creates a zip file containing the mod assets and lua file

param(
    [string]$versionName
)

# Prompt for version name if not provided as parameter
if ([string]::IsNullOrWhiteSpace($versionName)) {
    $versionName = Read-Host "Enter version name (e.g., v1.0.0)"
}

# Validate input
if ([string]::IsNullOrWhiteSpace($versionName)) {
    Write-Host "Error: Version name cannot be empty!" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

# Clean up version name (remove any invalid filename characters)
$cleanVersionName = $versionName -replace '[<>:"/\\|?*]', '_'

# Create releases directory and version subdirectory
$releasesDir = "releases"
$versionDir = Join-Path $releasesDir $cleanVersionName

# Create releases directory if it doesn't exist
if (-not (Test-Path $releasesDir)) {
    New-Item -ItemType Directory -Path $releasesDir -Force | Out-Null
    Write-Host "Created releases directory" -ForegroundColor Cyan
}

# Clean version directory if it exists, or create it
if (Test-Path $versionDir) {
    Write-Host "Version directory already exists, cleaning..." -ForegroundColor Yellow
    Remove-Item -Path "$versionDir\*" -Recurse -Force
}
else {
    New-Item -ItemType Directory -Path $versionDir -Force | Out-Null
}

# Define output filenames with full paths
$zipFileName = Join-Path $versionDir "TagManager-$cleanVersionName.zip"
$zipFileNameTS = Join-Path $versionDir "TagManager-$cleanVersionName-TS.zip"

Write-Host "Creating releases in: $versionDir" -ForegroundColor Green
Write-Host "  1. TagManager-$cleanVersionName.zip (mod only)" -ForegroundColor Cyan
Write-Host "  2. TagManager-$cleanVersionName-TS.zip (full package)" -ForegroundColor Cyan

# Check if required files exist
$requiredFiles = @("mod.lua", "tagManager.json", "config.lua", "localization", "src")
$requiredFilesTS = @("CHANGELOG.md", "icon.png", "LICENSE", "manifest.json", "README.md", "mod.lua", "tagManager.json", "config.lua", "localization", "src")

foreach ($file in $requiredFiles) {
    if (-not (Test-Path $file)) {
        Write-Host "Error: $file not found!" -ForegroundColor Red
        Read-Host "Press Enter to exit"
        exit 1
    }
}

foreach ($file in $requiredFilesTS) {
    if (-not (Test-Path $file)) {
        Write-Host "Warning: $file not found for TS package!" -ForegroundColor Yellow
    }
}

# Remove existing zip files if they exist
if (Test-Path $zipFileName) {
    Write-Host "Removing existing $zipFileName..." -ForegroundColor Yellow
    Remove-Item $zipFileName -Force
}

if (Test-Path $zipFileNameTS) {
    Write-Host "Removing existing $zipFileNameTS..." -ForegroundColor Yellow
    Remove-Item $zipFileNameTS -Force
}

try {
    Write-Host ""
    Write-Host "Creating mod-only package..." -ForegroundColor Green
    
    # Create temporary directory for staging files (mod only)
    $tempDir1 = "temp_release_mod_$((Get-Date).Ticks)"
    New-Item -ItemType Directory -Path $tempDir1 -Force | Out-Null
    
    # Create TagManager folder inside temp directory
    $tagManagerFolder = Join-Path $tempDir1 "TagManager"
    New-Item -ItemType Directory -Path $tagManagerFolder -Force | Out-Null
    
    # Copy localization folder and mod.lua to TagManager folder
    Copy-Item -Path "localization" -Destination $tagManagerFolder -Recurse -Force
    Copy-Item -Path "src" -Destination $tagManagerFolder -Recurse -Force
    Copy-Item -Path "mod.lua" -Destination $tagManagerFolder -Force
    Copy-Item -Path "tagManager.json" -Destination $tagManagerFolder -Force
    Copy-Item -Path "config.lua" -Destination $tagManagerFolder -Force
    
    # Create first zip file from temp directory contents
    Compress-Archive -Path "$tempDir1\*" -DestinationPath $zipFileName -Force
    
    # Clean up temp directory
    Remove-Item -Path $tempDir1 -Recurse -Force
    
    Write-Host "Successfully created $zipFileName" -ForegroundColor Green
    Write-Host "Contents:" -ForegroundColor Cyan
    Write-Host "  - TagManager/" -ForegroundColor Gray
    Write-Host "    - assets/" -ForegroundColor Gray
    Write-Host "    - mod.lua" -ForegroundColor Gray
    Write-Host "    - tagManager.json" -ForegroundColor Gray
    Write-Host "    - config.lua" -ForegroundColor Gray
    Write-Host "    - localization/" -ForegroundColor Gray
    Write-Host "    - src/" -ForegroundColor Gray
    
    Write-Host ""
    Write-Host "Creating full package..." -ForegroundColor Green
    
    # Create temporary directory for staging files (full package)
    $tempDir2 = "temp_release_full_$((Get-Date).Ticks)"
    New-Item -ItemType Directory -Path $tempDir2 -Force | Out-Null
    
    # Copy all files for TS package
    $tsFiles = @("CHANGELOG.md", "icon.png", "LICENSE", "manifest.json", "README.md", "mod.lua", "tagManager.json", "config.lua")
    foreach ($file in $tsFiles) {
        if (Test-Path $file) {
            Copy-Item -Path $file -Destination $tempDir2 -Force
        }
    }
    
    # Copy folder structures
    if (Test-Path "localization") {
        Copy-Item -Path "localization" -Destination $tempDir2 -Recurse -Force
    }
    if (Test-Path "src") {
        Copy-Item -Path "src" -Destination $tempDir2 -Recurse -Force
    }
    
    # Create second zip file from temp directory contents
    Compress-Archive -Path "$tempDir2\*" -DestinationPath $zipFileNameTS -Force
    
    # Clean up temp directory
    Remove-Item -Path $tempDir2 -Recurse -Force
    
    Write-Host "Successfully created $zipFileNameTS" -ForegroundColor Green
    Write-Host "Contents:" -ForegroundColor Cyan
    Write-Host "  - CHANGELOG.md" -ForegroundColor Gray
    Write-Host "  - icon.png" -ForegroundColor Gray
    Write-Host "  - LICENSE" -ForegroundColor Gray
    Write-Host "  - manifest.json" -ForegroundColor Gray
    Write-Host "  - README.md" -ForegroundColor Gray
    Write-Host "  - mod.lua" -ForegroundColor Gray
    Write-Host "  - localization/" -ForegroundColor Gray
    Write-Host "  - src/" -ForegroundColor Gray
    Write-Host "  - tagManager.json" -ForegroundColor Gray
    Write-Host "  - config.lua" -ForegroundColor Gray
}
catch {
    Write-Host "Error creating zip files: $($_.Exception.Message)" -ForegroundColor Red
    # Clean up temp directories if they exist
    if (Test-Path $tempDir1) {
        Remove-Item -Path $tempDir1 -Recurse -Force
    }
    if (Test-Path $tempDir2) {
        Remove-Item -Path $tempDir2 -Recurse -Force
    }
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  Both release builds complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Created files in releases/$cleanVersionName/:" -ForegroundColor Cyan
Write-Host "  * TagManager-$cleanVersionName.zip (mod only)" -ForegroundColor White
Write-Host "  * TagManager-$cleanVersionName-TS.zip (full package)" -ForegroundColor White
Write-Host ""
Read-Host "Press Enter to exit" 