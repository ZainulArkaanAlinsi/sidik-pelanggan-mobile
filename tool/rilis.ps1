<#
.SYNOPSIS
  Rilis SIDIK Pelanggan ke GitHub Releases: build APK, tulis manifes
  versi-pelanggan.json (sha256 + ukuran), lalu `gh release create`.

.DESCRIPTION
  Aplikasi terpasang membaca
  https://github.com/ZainulArkaanAlinsi/sidik-pelanggan-mobile/releases/latest/download/versi-pelanggan.json
  dan menawarkan pembaruan kalau `build` di manifes > build terpasang.

  Sebelum menjalankan:
    1. Naikkan `version:` di pubspec.yaml (build sesudah '+' WAJIB naik).
    2. android/key.properties + keystore rilis ada (APK bertanda tangan kunci
       debug tidak bisa dipasang di atas APK rilis dan tidak boleh dibagikan).
    3. `gh auth status` sudah masuk dengan akses tulis ke repo.

.EXAMPLE
  powershell -ExecutionPolicy Bypass -File tool/rilis.ps1 -Catatan "Perbaikan unduh sertifikat"
  powershell -ExecutionPolicy Bypass -File tool/rilis.ps1 -Catatan "Wajib: format API baru" -Wajib
#>
param(
  [Parameter(Mandatory = $true)][string]$Catatan,
  [switch]$Wajib,
  [string]$Repo = 'ZainulArkaanAlinsi/sidik-pelanggan-mobile'
)

# 'Continue', bukan 'Stop': di PowerShell 5.1 stderr perintah native (gh,
# flutter) yang dialihkan memicu NativeCommandError di mode Stop. Kegagalan
# diperiksa lewat $LASTEXITCODE dan -ErrorAction Stop per cmdlet.
$ErrorActionPreference = 'Continue'
$akar = Split-Path -Parent $PSScriptRoot
Set-Location $akar

function Gagal([string]$pesan) {
  Write-Host "GAGAL: $pesan" -ForegroundColor Red
  exit 1
}

# --- Versi dari pubspec.yaml -------------------------------------------------
$baris = Select-String -Path 'pubspec.yaml' -Pattern '^version:\s*([0-9]+\.[0-9]+\.[0-9]+)\+([0-9]+)\s*$' |
  Select-Object -First 1
if (-not $baris) { Gagal "pubspec.yaml: 'version: X.Y.Z+BUILD' tidak ditemukan." }
$versi = $baris.Matches[0].Groups[1].Value
$build = [int]$baris.Matches[0].Groups[2].Value
$tag = "v$versi+$build"
Write-Host "Rilis $tag ($Repo)" -ForegroundColor Cyan

# --- Pemeriksaan awal ---------------------------------------------------------
if (-not (Test-Path 'android/key.properties')) {
  Gagal 'android/key.properties tidak ada: APK akan bertanda tangan kunci debug.'
}
gh auth status 2>$null | Out-Null
if ($LASTEXITCODE -ne 0) { Gagal "gh belum login (jalankan 'gh auth login')." }

gh release view $tag --repo $Repo 2>$null | Out-Null
if ($LASTEXITCODE -eq 0) { Gagal "Rilis $tag sudah ada." }

# Build harus lebih besar dari rilis terakhir, kalau tidak HP tidak ditawari.
$terakhir = gh release view --repo $Repo --json tagName -q .tagName 2>$null
if ($LASTEXITCODE -eq 0 -and $terakhir -match '\+([0-9]+)$') {
  if ([int]$Matches[1] -ge $build) {
    Gagal "Build $build tidak lebih besar dari rilis terakhir $terakhir. Naikkan angka sesudah '+' di pubspec.yaml."
  }
}

if (git status --porcelain) {
  Write-Host 'PERINGATAN: ada perubahan yang belum di-commit; APK dibangun dari working tree.' -ForegroundColor Yellow
}

# --- Build ---------------------------------------------------------------------
flutter build apk --release
if ($LASTEXITCODE -ne 0) { Gagal 'flutter build apk gagal.' }

$keluaran = 'build/app/outputs/flutter-apk/app-release.apk'
if (-not (Test-Path $keluaran)) { Gagal "$keluaran tidak ada." }

$folder = 'build/rilis'
New-Item -ItemType Directory -Force -Path $folder -ErrorAction Stop | Out-Null
$apk = Join-Path $folder 'sidik-pelanggan.apk'
$manifes = Join-Path $folder 'versi-pelanggan.json'
Copy-Item $keluaran $apk -Force -ErrorAction Stop

# --- Manifes -------------------------------------------------------------------
$sha = (Get-FileHash -Algorithm SHA256 $apk -ErrorAction Stop).Hash.ToLowerInvariant()
$ukuran = (Get-Item $apk).Length
# '+' di tag ditulis %2B supaya URL-nya tidak bergantung pada cara GitHub
# membaca '+' di path.
$tagUrl = [uri]::EscapeDataString($tag)
$url = "https://github.com/$Repo/releases/download/$tagUrl/sidik-pelanggan.apk"

$isi = [ordered]@{
  versi   = $versi
  build   = $build
  url     = $url
  sha256  = $sha
  ukuran  = $ukuran
  wajib   = [bool]$Wajib
  catatan = $Catatan
} | ConvertTo-Json -Compress

# UTF-8 TANPA BOM (Set-Content -Encoding UTF8 di PowerShell 5 menulis BOM).
[System.IO.File]::WriteAllText((Resolve-Path -LiteralPath $folder).Path + '\versi-pelanggan.json', $isi, (New-Object System.Text.UTF8Encoding($false)))

Write-Host "APK     : $apk ($ukuran byte)"
Write-Host "SHA-256 : $sha"
Write-Host "Manifes : $isi"

# --- GitHub Release --------------------------------------------------------------
$judul = "SIDIK Pelanggan $versi (build $build)"
$catatanRilis = $Catatan
if ($Wajib) { $catatanRilis = "**Pembaruan wajib.**`n`n$Catatan" }

gh release create $tag $apk $manifes --repo $Repo --title $judul --notes $catatanRilis --latest
if ($LASTEXITCODE -ne 0) { Gagal 'gh release create gagal.' }

# --- Periksa ulang: URL di manifes harus menunjuk aset yang benar-benar ada. --------
$aset = (gh release view $tag --repo $Repo --json assets | ConvertFrom-Json).assets |
  Where-Object { $_.name -eq 'sidik-pelanggan.apk' } | ForEach-Object { $_.url }
Write-Host "Aset APK di GitHub: $aset"
try {
  $r = Invoke-WebRequest -Uri $url -Method Head -MaximumRedirection 5 -UseBasicParsing
  Write-Host "URL manifes terjangkau (HTTP $($r.StatusCode))." -ForegroundColor Green
} catch {
  Write-Host "PERINGATAN: URL di manifes tidak terjangkau: $url" -ForegroundColor Yellow
  Write-Host 'HP pelanggan akan gagal mengunduh. Periksa aset rilis sebelum mengumumkan.' -ForegroundColor Yellow
}

Write-Host "Selesai: https://github.com/$Repo/releases/tag/$tagUrl" -ForegroundColor Green
