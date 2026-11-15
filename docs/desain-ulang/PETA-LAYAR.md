# PETA LAYAR — app Pelanggan (`sidik-pelanggan-mobile`)

| Berkas | Status | Rujukan |
|---|---|---|
| `rangka.dart` | **DESAIN** | dock navy melayang (KOMPONEN.md §Dock), rel ≥ 600 dp tetap |
| `gerbang.dart`, `tautan.dart` | **LOGIKA** | tanpa tampilan sendiri; layar keadaan memakai ELEMEN.md |
| `beranda/beranda_screen.dart`, `beranda_ringkas.dart`, `beranda_kerangka.dart` | **DESAIN** | 01 Beranda; kerangka memuat = ELEMEN.md §Keadaan |
| `alat/daftar_alat_screen.dart` | **DESAIN** | 02 Alat saya |
| `alat/alat_detail_screen.dart` | **POLA** | ubin alat besar (Beranda 232) di atas + `PlatNama` + garis waktu sertifikat |
| `sertifikat/sertifikat_screen.dart` | **DESAIN** | 03 Sertifikat |
| `sertifikat/arsip_screen.dart` | **POLA** | segmen "Arsip" di 03 + kartu kelompok (radius 24) |
| `sertifikat/sertifikat_detail_screen.dart` | **POLA** | detail: identitas + stempel keputusan + aksi unduh |
| `sertifikat/pratinjau_pdf_screen.dart` | **BEKU** (isi PDF) | hanya kepala layar + bilah aksi yang baru |
| `akun/akun_screen.dart` | **DESAIN** | 04 Akun |
| `akun/anggota_screen.dart` | **DESAIN** | 05 Anggota perusahaan |
| `akun/bantuan_screen.dart`, `ganti_sandi_screen.dart`, `preferensi_notifikasi_screen.dart` | **POLA** | panel baris menu 64 / formulir (isian 56 radius 16) |
| `paket/paket_screen.dart` | **DESAIN** | 06 Pelacakan paket |
| `paket/paket_detail_screen.dart` | **POLA** | identitas paket + `GarisWaktuTahap` + `TikPaket` |
| `notifikasi/notifikasi_screen.dart` | **POLA** | panel baris 72, titik belum dibaca, ikon jenis di ubin 44 |
| `auth/sambutan_screen.dart`, `masuk_screen.dart`, `lupa_sandi_screen.dart`, `terima_undangan_screen.dart` | **POLA** | susunan E0 Masuk (canvas Lab) dengan palet Bento: hero kuning, plat logo putih, kartu putih radius 32 |

Splash Android (`android/app/src/main/res`): latar #EEF0F3 + logo di plat putih
(Android 12+ splash API membatasi animasi; timeline E1 hanya di layar Flutter pertama bila ada).
