param([switch]$Restore, [switch]$Check, [switch]$NoLaunch)
$ErrorActionPreference = 'Stop'
$manifest = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'patch-manifest.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$installDir = Join-Path $env:LOCALAPPDATA 'oopz'
$appFile = Join-Path $installDir 'data\app.so'
$backupDir = Join-Path $env:LOCALAPPDATA 'OOPZ-Clean\backups'
$backupFile = Join-Path $backupDir ($manifest.original_sha256 + '.so')
function Hash-Bytes([byte[]]$Bytes) {
    $algorithm = [Security.Cryptography.SHA256]::Create()
    try { return ([BitConverter]::ToString($algorithm.ComputeHash($Bytes))).Replace('-', '').ToLowerInvariant() }
    finally { $algorithm.Dispose() }
}
function From-Hex([string]$Hex) {
    [byte[]]$result = New-Object byte[] ($Hex.Length / 2)
    for ($i = 0; $i -lt $result.Length; $i++) { $result[$i] = [Convert]::ToByte($Hex.Substring($i * 2, 2), 16) }
    return ,$result
}
[byte[]]$current = [IO.File]::ReadAllBytes($appFile)
$currentHash = Hash-Bytes $current
if ($Check) {
    if ($currentHash -eq $manifest.patched_sha256) { Write-Output 'PATCHED: all changes verified by SHA-256'; exit 0 }
    if ($currentHash -eq $manifest.original_sha256) { Write-Output 'ORIGINAL: supported version, patch not applied'; exit 2 }
    throw 'Unsupported version. No file was changed. A new version needs analysis before patching.'
}
if ($Restore) {
    if ($currentHash -eq $manifest.original_sha256) { Write-Output 'Already original.'; exit 0 }
    if ($currentHash -ne $manifest.patched_sha256) { throw 'Unsupported current version. Restore refused to avoid overwriting a newer client.' }
    [byte[]]$replacement = [IO.File]::ReadAllBytes($backupFile)
    if ((Hash-Bytes $replacement) -ne $manifest.original_sha256) { throw 'Backup integrity check failed.' }
} else {
    if ($currentHash -eq $manifest.patched_sha256) { Write-Output 'Already patched.'; exit 0 }
    if ($currentHash -ne $manifest.original_sha256) { throw 'Unsupported version. No file was changed. A new version needs analysis before patching.' }
    [byte[]]$replacement = $current.Clone()
    foreach ($patch in $manifest.patches) {
        [byte[]]$before = From-Hex $patch.before
        [byte[]]$after = From-Hex $patch.after
        if ($before.Length -ne $after.Length -or $patch.offset -lt 0 -or ($patch.offset + $after.Length) -gt $replacement.Length) { throw "Invalid patch: $($patch.name)" }
        for ($i = 0; $i -lt $before.Length; $i++) {
            if ($replacement[$patch.offset + $i] -ne $before[$i]) { throw "Original bytes mismatch: $($patch.name)" }
        }
        [Array]::Copy($after, 0, $replacement, [int]$patch.offset, $after.Length)
    }
    if ((Hash-Bytes $replacement) -ne $manifest.patched_sha256) { throw 'Patched output integrity check failed.' }
    New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
    if (Test-Path -LiteralPath $backupFile) {
        if ((Hash-Bytes ([IO.File]::ReadAllBytes($backupFile))) -ne $manifest.original_sha256) { throw 'Existing backup integrity check failed.' }
    } else { [IO.File]::WriteAllBytes($backupFile, $current) }
}
Get-Process -Name oopz -ErrorAction SilentlyContinue | Where-Object { $_.Path -eq (Join-Path $installDir 'oopz.exe') } | Stop-Process -Force
Start-Sleep -Milliseconds 700
[IO.File]::WriteAllBytes($appFile, $replacement)
if ((Hash-Bytes ([IO.File]::ReadAllBytes($appFile))) -ne (Hash-Bytes $replacement)) { throw 'Written file integrity check failed.' }
if ($Restore) { Write-Output 'Restored original client.' } else { Write-Output "Applied $($manifest.patches.Count) changes. Original saved in $backupFile" }
if (-not $NoLaunch) { Start-Process -FilePath (Join-Path $installDir 'oopz.exe') -WorkingDirectory $installDir -WindowStyle Normal }

