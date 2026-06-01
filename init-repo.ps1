# =============================================================
# MOSIP Repository Setup Script
# =============================================================
# Run this script ONCE from the root: D:\Data\Docs\Programming\GIT\Mosip
# Usage: .\init-repo.ps1 -RemoteUrl "https://github.com/<your-username>/<your-repo>.git"
# =============================================================

param(
    [Parameter(Mandatory = $false)]
    [string]$RemoteUrl = "",

    [Parameter(Mandatory = $false)]
    [string]$Branch = "main"
)

$ErrorActionPreference = "Stop"
$Root = $PSScriptRoot

Write-Host "`n========================================================" -ForegroundColor Cyan
Write-Host "  MOSIP Repo Initializer" -ForegroundColor Cyan
Write-Host "========================================================`n" -ForegroundColor Cyan

# ---------------------------------------------------------------
# STEP 1: Remove nested .git directories (embedded repo fix)
# ---------------------------------------------------------------
Write-Host "[1/5] Removing nested .git directories..." -ForegroundColor Yellow

$nestedGits = @(
    "commons",
    "esignet-mock-services",
    "registration"
)

foreach ($dir in $nestedGits) {
    $gitPath = Join-Path $Root "$dir\.git"
    if (Test-Path $gitPath) {
        Write-Host "  Removing $gitPath" -ForegroundColor Gray
        Remove-Item -Recurse -Force $gitPath
        Write-Host "  OK: $dir\.git removed" -ForegroundColor Green
    } else {
        Write-Host "  SKIP: $dir\.git not found (already clean)" -ForegroundColor DarkGray
    }
}

# ---------------------------------------------------------------
# STEP 2: Remove cached entries from git index (if any)
# ---------------------------------------------------------------
Write-Host "`n[2/5] Clearing any cached embedded repo entries from git index..." -ForegroundColor Yellow

foreach ($dir in $nestedGits) {
    $result = git -C $Root ls-files --error-unmatch $dir 2>&1
    if ($LASTEXITCODE -eq 0) {
        git -C $Root rm --cached -r $dir 2>&1 | Out-Null
        Write-Host "  Removed cached: $dir" -ForegroundColor Green
    } else {
        Write-Host "  SKIP: $dir not in index" -ForegroundColor DarkGray
    }
}

# ---------------------------------------------------------------
# STEP 3: Stage all files
# ---------------------------------------------------------------
Write-Host "`n[3/5] Staging all files..." -ForegroundColor Yellow
git -C $Root add --all
if ($LASTEXITCODE -ne 0) {
    Write-Host "  ERROR: git add failed" -ForegroundColor Red
    exit 1
}
Write-Host "  All files staged successfully" -ForegroundColor Green

# Show what will be committed
Write-Host "`n  Files to be committed:" -ForegroundColor DarkCyan
git -C $Root status --short

# ---------------------------------------------------------------
# STEP 4: Commit
# ---------------------------------------------------------------
Write-Host "`n[4/5] Committing..." -ForegroundColor Yellow
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm"
git -C $Root commit -m "chore: initial commit — MOSIP ID Generator service ($timestamp)"
if ($LASTEXITCODE -ne 0) {
    Write-Host "  Nothing to commit or commit failed." -ForegroundColor DarkYellow
}

# ---------------------------------------------------------------
# STEP 5: Set remote and push (optional)
# ---------------------------------------------------------------
Write-Host "`n[5/5] Remote & Push..." -ForegroundColor Yellow

if ($RemoteUrl -ne "") {
    # Check if remote 'origin' already exists
    $existingRemote = git -C $Root remote get-url origin 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  Remote 'origin' already set to: $existingRemote" -ForegroundColor DarkCyan
        Write-Host "  Updating remote URL to: $RemoteUrl" -ForegroundColor DarkCyan
        git -C $Root remote set-url origin $RemoteUrl
    } else {
        Write-Host "  Adding remote 'origin': $RemoteUrl" -ForegroundColor DarkCyan
        git -C $Root remote add origin $RemoteUrl
    }

    Write-Host "  Pushing to $Branch..." -ForegroundColor DarkCyan
    git -C $Root push -u origin $Branch
    if ($LASTEXITCODE -ne 0) {
        Write-Host "`n  Push failed. If the branch doesn't exist yet, try:" -ForegroundColor Red
        Write-Host "    git push --set-upstream origin $Branch" -ForegroundColor White
    } else {
        Write-Host "  Pushed successfully!" -ForegroundColor Green
    }
} else {
    Write-Host "  No -RemoteUrl provided. Skipping push." -ForegroundColor DarkYellow
    Write-Host "  To push manually, run:" -ForegroundColor White
    Write-Host "    git remote add origin https://github.com/<user>/<repo>.git" -ForegroundColor Cyan
    Write-Host "    git push -u origin $Branch" -ForegroundColor Cyan
}

Write-Host "`n========================================================" -ForegroundColor Cyan
Write-Host "  Done! Repository is clean and ready." -ForegroundColor Green
Write-Host "========================================================`n" -ForegroundColor Cyan
