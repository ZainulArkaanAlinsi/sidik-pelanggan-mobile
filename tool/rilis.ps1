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
  [string]$Repo = 'ZainulArkaanAlinsi/sidik-pelanggan-mobile',
  # Potongan DN sertifikat RILIS yang wajib ada di APK. APK bertanda tangan
  # sertifikat lain (mis. "CN=Android Debug") tidak bisa dipasang di atas APK
  # yang sudah dipegang pelanggan.
  [string]$DnRilis = 'CN=SIDIK Pelanggan'
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

# `gh release view` membedakan "belum ada rilis" (pesan 'release not found')
# dari galat lain (jaringan, auth, repo salah). Yang kedua MENGGAGALKAN skrip:
# menganggapnya "belum ada" bisa melewatkan pemeriksaan build/tag.
function Lihat-Rilis([string[]]$argumen) {
  $keluaran = & gh release view @argumen --repo $Repo 2>&1
  $kode = $LASTEXITCODE
  $teks = ($keluaran | ForEach-Object { "$_" }) -join "`n"
  if ($kode -eq 0) { return @{ Ada = $true; Teks = $teks } }
  if ($teks -match 'release not found') { return @{ Ada = $false; Teks = '' } }
  Gagal "gh release view $($argumen -join ' ') gagal: $teks"
}

# Baca android/key.properties tanpa pernah mencetak nilainya.
function Periksa-KunciRilis {
  $berkas = 'android/key.properties'
  if (-not (Test-Path $berkas)) {
    Gagal "$berkas tidak ada: APK akan bertanda tangan kunci debug."
  }
  $nilai = @{}
  foreach ($b in Get-Content $berkas -ErrorAction Stop) {
    if ($b -match '^\s*([A-Za-z]+)\s*=\s*(.*?)\s*$') { $nilai[$Matches[1]] = $Matches[2] }
  }
  foreach ($k in 'storeFile', 'storePassword', 'keyAlias', 'keyPassword') {
    if ([string]::IsNullOrWhiteSpace($nilai[$k])) { Gagal "$berkas`: '$k' kosong atau tidak ada." }
  }
  # Gradle membaca storeFile relatif ke folder android/ (rootProject).
  $toko = $nilai['storeFile']
  if (-not [System.IO.Path]::IsPathRooted($toko)) { $toko = Join-Path 'android' $toko }
  if (-not (Test-Path -LiteralPath $toko)) { Gagal "$berkas`: berkas keystore (storeFile) tidak ditemukan." }
  Write-Host 'key.properties lengkap, keystore ada.' -ForegroundColor Green
}

function Cari-Apksigner {
  $akarSdk = @($env:ANDROID_HOME, $env:ANDROID_SDK_ROOT, (Join-Path $env:LOCALAPPDATA 'Android\Sdk')) |
    Where-Object { $_ -and (Test-Path (Join-Path $_ 'build-tools')) } | Select-Object -First 1
  if (-not $akarSdk) { Gagal 'Android SDK build-tools tidak ditemukan (ANDROID_HOME / %LOCALAPPDATA%\Android\Sdk).' }
  # Versi stabil terbaru dulu (folder -rc dilewati).
  $alat = Get-ChildItem (Join-Path $akarSdk 'build-tools') -Directory |
    Where-Object { $_.Name -match '^\d+\.\d+\.\d+$' } |
    Sort-Object { [version]$_.Name } -Descending |
    ForEach-Object { Join-Path $_.FullName 'apksigner.bat' } |
    Where-Object { Test-Path $_ } | Select-Object -First 1
  if (-not $alat) { Gagal "apksigner.bat tidak ditemukan di $akarSdkuild-tools." }
  return $alat
}

# APK harus lolos `apksigner verify` DAN bertanda tangan sertifikat rilis.
function Periksa-TandaTangan([string]$jalurApk) {
  $apksigner = Cari-Apksigner
  $keluaran = & $apksigner verify --print-certs $jalurApk 2>&1
  $kode = $LASTEXITCODE
  $teks = ($keluaran | ForEach-Object { "$_" }) -join "`n"
  if ($kode -ne 0) { Gagal "apksigner verify gagal:`n$teks" }
  $dn = @($teks -split "`n" | Where-Object { $_ -match 'certificate DN:' })
  if ($dn.Count -eq 0) { Gagal 'apksigner tidak menampilkan DN sertifikat.' }
  Write-Host ($dn -join "`n")
  if ($teks -match 'Android Debug') { Gagal 'APK bertanda tangan sertifikat DEBUG. Periksa android/key.properties.' }
  if (-not ($dn -join "`n").Contains($DnRilis)) {
    Gagal "DN sertifikat APK tidak memuat '$DnRilis'. Bukan kunci rilis SIDIK Pelanggan?"
  }
  Write-Host 'Tanda tangan rilis OK.' -ForegroundColor Green
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
Periksa-KunciRilis
gh auth status 2>$null | Out-Null
if ($LASTEXITCODE -ne 0) { Gagal "gh belum login (jalankan 'gh auth login')." }

if ((Lihat-Rilis @($tag)).Ada) { Gagal "Rilis $tag sudah ada." }

# Build harus lebih besar dari rilis terakhir, kalau tidak HP tidak ditawari.
$latest = Lihat-Rilis @('--json', 'tagName', '-q', '.tagName')
if (-not $latest.Ada) {
  Write-Host 'Belum ada rilis di repo ini: ini rilis pertama.' -ForegroundColor Yellow
} else {
  $terakhir = $latest.Teks.Trim()
  if ($terakhir -notmatch '\+([0-9]+)$') { Gagal "Tag rilis terakhir '$terakhir' tidak berformat v<versi>+<build>." }
  if ([int]$Matches[1] -ge $build) {
    Gagal "Build $build tidak lebih besar dari rilis terakhir $terakhir. Naikkan angka sesudah '+' di pubspec.yaml."
  }
}

if (git status --porcelain) {
  Write-Host 'PERINGATAN: ada perubahan yang belum di-commit; APK dibangun dari working tree.' -ForegroundColor Yellow
}

# --- Build ---------------------------------------------------------------------
# Hanya ARM 32 + 64 bit: HP pelanggan memang ARM, dan x86_64 cuma untuk
# emulator; membuangnya memangkas ukuran APK (unduhan pembaruan lewat data
# seluler) tanpa kehilangan satu HP pun. `android-arm` WAJIB tetap ada: HP
# murah/lama banyak yang ROM-nya 32-bit walau prosesornya 64-bit.
flutter build apk --release --target-platform android-arm,android-arm64
if ($LASTEXITCODE -ne 0) { Gagal 'flutter build apk gagal.' }

$keluaran = 'build/app/outputs/flutter-apk/app-release.apk'
if (-not (Test-Path $keluaran)) { Gagal "$keluaran tidak ada." }

$folder = 'build/rilis'
New-Item -ItemType Directory -Force -Path $folder -ErrorAction Stop | Out-Null
$apk = Join-Path $folder 'sidik-pelanggan.apk'
$manifes = Join-Path $folder 'versi-pelanggan.json'
Copy-Item $keluaran $apk -Force -ErrorAction Stop

# --- Tanda tangan: harus sertifikat rilis, bukan debug ---------------------------
Periksa-TandaTangan $apk

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
$terjangkau = $false
try {
  $r = Invoke-WebRequest -Uri $url -Method Head -MaximumRedirection 5 -UseBasicParsing
  $terjangkau = ($r.StatusCode -eq 200)
  $status = $r.StatusCode
} catch {
  $status = $_.Exception.Message
}
if (-not $terjangkau) {
  Gagal ("URL APK di versi-pelanggan.json TIDAK terjangkau ($status): $url`n" +
    "Rilis $tag SUDAH terbit dan sekarang 'latest': HP pelanggan akan melihat pembaruan tapi gagal mengunduh.`n" +
    "Perbaiki segera: gh release delete '$tag' --repo $Repo --cleanup-tag, lalu jalankan ulang skrip ini.")
}
Write-Host "URL manifes terjangkau (HTTP $status)." -ForegroundColor Green

Write-Host "Selesai: https://github.com/$Repo/releases/tag/$tagUrl" -ForegroundColor Green
