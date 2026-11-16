# lib/core/tema — token dan tema

Satu-satunya tempat warna, spasi, sudut, elevasi, ukuran ikon, dan huruf
ditentukan. Layar dan widget **tidak** menulis `Color(0x...)`, `Colors.*`,
`SizedBox(height: 12)`, atau `fontSize: 14`; semuanya lewat token di bawah.
Gerbang desain menjaga aturan ini: `test/tema/token_only_test.dart` (ratchet),
`kontras_tema_test.dart`, `token_tema_test.dart`, `tema_sidik_test.dart`,
`token_bento_test.dart` (mencocokkan kode ke `docs/desain-ulang/tokens.json`),
`anti_slop_test.dart`. Standar lengkap: `docs/standar-kualitas-desain.md`.

Arah desain: **tenang, formal, ringkas** (REVISI 16 Nov 2026; catatan
penerapan di `docs/desain-ulang/REVISI-16NOV.md`; menggantikan "Bento Lab").
Latar abu kebiruan sangat muda `#F4F7FB`, permukaan putih, navy `#102A43` untuk
judul dan teks, biru `#1769C2` untuk tombol utama dan tindakan, biru muda
`#EAF3FF` untuk pilihan aktif (selalu dengan tepi biru atau indikator), empat
status bertinta GELAP di atas warna MUDA (hijau, krem/amber, merah muda, biru
kelabu), selalu ikon + kata. Warna hanya untuk status dan tindakan; kartu
netral. Kartu 16, tombol 10, isian dan saringan 12, lencana 6; lingkaran
sungguhan saja yang pil. Material 3 datar tanpa bayangan. Kobalt `#043EA1`
(warna logo PT Sidik) hanya untuk aset merek. Mode terang dan gelap (gelap:
titik awal, belum ikut ditinjau di revisi).

| Berkas | Isi |
|---|---|
| `palet_sidik.dart` | Warna mentah. SATU-SATUNYA berkas boleh `Color(0x...)`. Teks dan aksi (`navy`, `biru`, `biruMuda`), status muda (`hijau`, `kuning`, `koral`, `langit`) + tintanya (`hijauTinta`, `kuningTinta`, `langitTinta`, `galat`), netral terang (`latar`, `kartu`, `latarTinggi`, `teksKedua`, `garis`, `garisTegas`), tema gelap, `kobaltLogo`. Nama lama (`kuning`, `koral`, ...) dipertahankan tetapi nilainya sekarang warna MUDA status. |
| `warna_sidik.dart` | `WarnaSidik` (ThemeExtension): status halaman (`lulus`/`awas`/`gagal`/`tunggu` = tinta, `...Latar` = latar muda), warna ubin ringkasan (`ubinLulus`... sama di dua tema; `tintaUbin` navy; `kertasUbin` putih; `ubinBiru` kepala layar masuk), merah KAN; pintasan `context.warna`, `context.skema`, `context.teks`. Pasangannya: `StatusTampil.warna` (halaman), `ubinDari`, `diAtasUbin`. |
| `spasi.dart` | `Spasi.xs/sm/md/lg/xl/xxl` (4/8/12/16/24/32), `Spasi.sisi` (margin halaman 16), `Spasi.antarUbin` (12), `Spasi.bagian`, `Spasi.batasKompak` (340 dp), `Spasi.daftar(context)`, batas tablet (600 dp), lebar isi (720 dp), dan `lebarLebar` (1040 dp, layar dua kolom: Beranda). |
| `bentuk.dart` | `Bentuk.stempel/tombol/ikon/kapsul/panel/ubin/penanda/pil` (6/10/12/12/16/16/8/999). `pil` HANYA untuk lingkaran sungguhan. Nama lama dipertahankan: `kontrol` = ikon, `kartu` = panel, `utama` = tombol, `lembar` = panel; `kecil` tetap 4 (tik, tooltip). |
| `elevasi.dart` | `Elevasi.datar/rendah/lembar/garis`. Kedalaman dari garis halus, tidak ada bayangan (bilah navigasi = garis atas 1 dp). |
| `ukuran.dart` | `UkuranIkon`, `AreaSentuh.minimum` (48 dp), `UkuranBaris` (baris 64, tombol utama 48, kolom angka 48), `UkuranTik`, `SkalaHuruf`, `UkuranKontrol` (tombol bulat, saringan 40, segmen 48, kolom cari 48, lencana 24), `UkuranUbin` (baris menu 56, ubin alat 144/160, ubin pasangan 132, ubin menu 124, kapsul), `UkuranBilah` (bilah navigasi bawah: tinggi 64, ikon 24, indikator 56 x 32, label sampai 1,3x), `UkuranFokus` (cincin fokus papan ketik), `UkuranVisual`, `UkuranAuth` (kepala layar masuk 240). |
| `tipografi.dart` | Inter 400/500/600 untuk teks dan IBM Plex Mono untuk angka dan kode. `.tabular` untuk angka selebar tetap, `.nomor` untuk nomor (IBM Plex Mono + nol bergaris). `beratTebal` = 600. |
| `tema_sidik.dart` | `TemaSidik.terang` / `TemaSidik.gelap`: `ThemeData` yang menema semua komponen Material. |

## Cara pakai

```dart
final t = context.teks;      // TextTheme
final s = context.skema;     // ColorScheme (primary = biru aksi)
final w = context.warna;     // WarnaSidik (status, merah KAN)

Padding(
  padding: Spasi.kartu,
  child: Text('Nomor', style: t.titleSmall?.nomor),
);

// Angka sorot (32/36 mono): bukan slot TextTheme.
Text('12', style: TipografiSidik.angkaSorot(teks: s.onSurface));
```

## Skala tipografi

| Tingkat | Ukuran/baris | Berat | Untuk |
|---|---|---|---|
| angka sorot | 32/36 mono | 600 | sisa hari di kartu alat Beranda (`angkaSorot`) |
| angka kartu | 28/32 mono | 600 | sisa hari di kartu alat dan detail alat (displayLarge) |
| kalimat utama | 24/30 | 600 | kalimat utama Beranda dan paket (displayMedium) |
| judul layar | 24/30 | 600 | judul layar tab, angka KPI, sambutan (displaySmall) |
| nama | 20/26 | 600 | nama alat/akun, nomor order (headline*) |
| judul app bar | 18/24 | 600 | judul app bar dan dialog (titleLarge) |
| judul bagian | 16/22 | 600 | judul bagian dan ubin (titleMedium) |
| label | 14/20 | 500 | label tombol dan baris (titleSmall, labelLarge) |
| isi bacaan | 16/24 | 400 | teks bacaan (bodyLarge) |
| isi | 14/20 | 400 | teks isi (bodyMedium) |
| keterangan | 13/18 | 400 | merk, tanggal, nomor seri, bantuan (bodySmall) |
| lencana | 12/16 | 600 | lencana status, label bilah navigasi (labelMedium/Small) |

Bold (700) tidak dipakai (Inter-Bold masih dibundel; boleh dibuang di PR bersih-
bersih). `tema_sidik_test.dart` menjaga agar tak ada berat yang tak punya
berkasnya. Daftar izin ukuran `{32, 28, 24, 20, 18, 16, 14, 13, 12}`; minimum 12
sp. IBM Plex Mono dibundel di `assets/fonts` (SIL OFL, lisensi di
`LICENSE-IBMPlexMono.txt`), tidak diunduh saat jalan.

## Aturan warna

- Status: `lulus` (berlaku, selesai), `awas` (segera jatuh tempo), `gagal`
  (lewat jadwal, dibatalkan, tidak memenuhi toleransi), `tunggu` (diproses),
  netral (tidak aktif, riwayat). Selalu dengan ikon dan teks. Tema terang: tinta
  gelap (hijau gelap, amber gelap, merah gelap, biru tua) di atas warna muda
  status; tinta berjenjang terangnya (selisih > 0,02) supaya tetap terbaca di
  cetakan hitam-putih. Tema gelap: tinta pastel di atas latar gelap.
- Merah KAN (`WarnaSidik.kanMerah`) HANYA untuk `LencanaKan`; bukan warna galat.
  Galat isian dan tombol bahaya: `ColorScheme.error` (`PaletSidik.galat`).
- `garis` bukan tepi kontrol (1,3:1): pakai `garisTegas` (`ColorScheme.outline`).
  `biruMuda` bukan satu-satunya penanda pilihan aktif (1,1:1): selalu dengan tepi
  biru, ikon terisi, atau indikator.
- Mengubah satu nilai di `palet_sidik.dart`: jalankan `flutter test test/tema`.
  `token_bento_test.dart` mencocokkan nilai dengan
  `docs/desain-ulang/tokens.json`; ubah keduanya bersama.

Aset terkait di luar Dart: `android/app/src/main/res` (ikon adaptif, splash)
dan `assets/images/logo_sidik.png`.
