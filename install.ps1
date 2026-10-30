$ErrorActionPreference = 'Stop'
$version = '0.3.3'
$base = "https://github.com/purrkey-ai/cli/releases/download/v$version"

if ([Environment]::OSVersion.Platform -ne [PlatformID]::Win32NT) {
    throw 'Use install.sh on macOS or Linux.'
}
if ([System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture -ne [System.Runtime.InteropServices.Architecture]::X64) {
    throw 'The Windows CLI package currently supports x64 only.'
}

$archive = "purrkey-$version-windows-amd64.zip"
$stage = Join-Path ([IO.Path]::GetTempPath()) ([Guid]::NewGuid().ToString())
$pending = $null
New-Item -ItemType Directory -Path $stage | Out-Null
try {
    $archivePath = Join-Path $stage $archive
    Invoke-WebRequest -UseBasicParsing -Uri "$base/$archive" -OutFile $archivePath
    $sumsPath = Join-Path $stage 'SHA256SUMS'
    Invoke-WebRequest -UseBasicParsing -Uri "$base/SHA256SUMS" -OutFile $sumsPath
    $sums = Get-Content -LiteralPath $sumsPath -Raw
    $pattern = '^([0-9a-fA-F]{64})\s+' + [Regex]::Escape($archive) + '$'
    $checksums = @($sums -split '\r?\n' | Where-Object { $_ -match $pattern })
    if ($checksums.Count -ne 1) {
        throw "Release must contain exactly one checksum for $archive."
    }
    $expected = ($checksums[0] -split '\s+')[0]
    if ((Get-FileHash -Algorithm SHA256 -Path $archivePath).Hash -ne $expected) {
        throw 'CLI archive SHA256 verification failed.'
    }
    Expand-Archive -LiteralPath $archivePath -DestinationPath (Join-Path $stage 'unpacked')
    $installDir = if ($env:ATX_INSTALL_DIR) { $env:ATX_INSTALL_DIR } else { Join-Path $env:LOCALAPPDATA 'Purrkey\bin' }
    New-Item -ItemType Directory -Force -Path $installDir | Out-Null
    $pending = Join-Path $installDir ('.purrkey-' + [Guid]::NewGuid().ToString() + '.exe')
    Copy-Item -LiteralPath (Join-Path $stage 'unpacked\purrkey.exe') -Destination $pending
    $actual = & $pending version
    if ($LASTEXITCODE -ne 0 -or $actual -ne $version) {
        throw 'Downloaded CLI version does not match this installer.'
    }
    Move-Item -LiteralPath $pending -Destination (Join-Path $installDir 'purrkey.exe') -Force
    $pending = $null
    $env:Path = "$installDir;$env:Path"
    Write-Output "Installed Purrkey CLI $version in $installDir."
    Write-Output 'Add this directory to your user PATH for future terminals.'
} finally {
    if ($pending -and (Test-Path -LiteralPath $pending)) {
        Remove-Item -LiteralPath $pending -Force
    }
    Remove-Item -LiteralPath $stage -Recurse -Force
}
