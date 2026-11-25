param(
    [Parameter(Mandatory = $true)]
    [string]$Version,
    [switch]$Push
)

$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
Push-Location $repoRoot
try {
    $tag = if ($Version.StartsWith("v")) { $Version } else { "v$Version" }

    # 1. Validate AHK syntax if AutoHotkey64.exe is installed
    $ahkCandidates = @(
        "$env:LOCALAPPDATA\Programs\AutoHotkey\v2\AutoHotkey64.exe",
        "C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe"
    )
    $ahk = $ahkCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1
    if ($ahk) {
        Write-Host "Validating AHK scripts with $ahk ..."
        & $ahk /ErrorStdOut /Validate "rustdesk_desktop_switch.ahk"
        if ($LASTEXITCODE -ne 0) { throw "Validation failed for rustdesk_desktop_switch.ahk" }
        & $ahk /ErrorStdOut /Validate "rd_switch_worker.ahk"
        if ($LASTEXITCODE -ne 0) { throw "Validation failed for rd_switch_worker.ahk" }
    } else {
        Write-Warning "AutoHotkey64.exe not found; skipping syntax validation."
    }

    # 2. Check clean working tree
    $status = git status --porcelain
    if ($status) {
        throw "Working tree is not clean. Please commit or stash changes first:`n$status"
    }

    # 3. Package release zip + sha256
    $distDir = Join-Path $repoRoot "dist"
    New-Item -ItemType Directory -Force -Path $distDir | Out-Null
    $zipName = "rustdesk-desktop-switch-$tag.zip"
    $zipPath = Join-Path $distDir $zipName
    Compress-Archive -Path @(
        "rustdesk_desktop_switch.ahk",
        "rd_switch_worker.ahk",
        "README.md",
        "CHANGELOG.md",
        "LICENSE"
    ) -DestinationPath $zipPath -Force

    $hash = (Get-FileHash -Algorithm SHA256 $zipPath).Hash.ToLower()
    "$hash  $zipName" | Out-File -Encoding ascii "$zipPath.sha256"
    Write-Host "Built: $zipPath (SHA256: $hash)"

    # 4. Create annotated git tag if it does not exist
    $existingTag = git tag -l $tag
    if (-not $existingTag) {
        git tag -a $tag -m "Release $tag"
        Write-Host "Created tag: $tag"
    } else {
        Write-Host "Tag $tag already exists."
    }

    # 5. Optional push
    if ($Push) {
        $remotes = git remote
        if (-not $remotes) {
            throw "No git remote configured. Add one first: git remote add origin <url>"
        }
        git push origin HEAD
        git push origin $tag
        Write-Host "Pushed HEAD and $tag to origin."
    }
}
finally {
    Pop-Location
}
