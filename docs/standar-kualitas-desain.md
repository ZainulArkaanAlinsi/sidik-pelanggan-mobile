# Standar kualitas desain: app Pelanggan (sidik-pelanggan-mobile)

Berlaku untuk setiap perubahan tampilan di app Pelanggan (`lib/screens`,
`lib/widgets`, `lib/core/tema`). Ringkasan standar kualitas desain Sidik yang
disesuaikan untuk Pelanggan; Lab punya versinya sendiri di repo
`sidik-calibration-mobile`. Gerbang otomatis ada di "Cara menjalankan gerbang".

## 1. Untuk siapa dan dalam kondisi apa

Pelanggan dipakai staf perusahaan pemilik alat, di HP, dalam keadaan tenang:
membaca, bukan mengisi. Tugasnya hanya tiga: tahu alat mana yang perlu
perhatian, tahu alatnya sedang diapakan di lab, dan mengambil sertifikat.
Akibatnya:

- Jawaban dulu, statistik belakangan. Layar dibuka dengan hal yang perlu
  diperhatikan.
- Tepercaya: tidak ada hiasan yang tidak membawa informasi. Hasil FAIL tidak
  dilunakkan ("Tidak memenuhi toleransi").
- Aplikasi baca-saja (`test/guard_tulis_test.dart` tidak boleh dilonggarkan).
- Tidak meluap di HP murah (320 dp, huruf 1,3x) dan terbaca di tablet, terang
  maupun gelap.

## 2. Keputusan teknologi

**Material 3 + satu berkas tema terpusat (`lib/core/tema/`).** Tanpa library UI,
font, atau paket baru. Mengganti library berarti menulis ulang seluruh UI tanpa
manfaat terukur. Layar tidak menyusun gaya dari `Container`+`Padding`+`Text`
mentah: pakai widget bawaan yang sudah ditema atau komponen di `lib/widgets/`.
Warna, huruf, radius, dan jarak hanya dari token.

## 3. Arah visual: "Bento Lab"

Menggantikan arah "Jejak" (keputusan pemilik, paket desain 14 Nov 2026; sumber:
`docs/desain-ulang/`, mulai dari `README.md`, `DESIGN.md`, `UKURAN.md`,
`tokens.json`). Satu kalimat: **navy korporat + ubin pastel bermakna + visual
alat**. Kesan formal dijaga navy (teks, aksi, dock), Inter tebal, dan disiplin
grid; kesan segar datang dari ubin besar membulat dan visual alat.

1. **Satu ubin = satu hal.** Tidak ada kartu di dalam kartu.
2. **Warna ubin bukan hiasan.** Koral = lewat jadwal/gagal, kuning = awas dan
   aksen, hijau = berlaku/selesai, langit = info/diproses, putih = netral. Tiap
   warna terikat ke satu makna status.
3. **Angka memimpin.** Sisa hari ditulis besar (44, di Beranda 64), kata
   menjelaskan di sebelahnya.
4. **Satu aksi utama per layar** (pil navy 56 dp).
5. **Visual alat** duduk di sudut kanan bawah ubin dan tidak pernah menimpa teks
   (komponen dan gambar menyusul di P2/P3; token ukurannya sudah ada).
6. **Jejak tahap** (satu tik per langkah `garis_waktu` server) tetap motifnya
   sampai paket komponen mengganti bentuknya; jumlah tik tidak pernah dikeraskan.

Yang berubah dari "Jejak", dan keputusannya sudah diambil pemilik:

| Aturan Jejak | Bento Lab |
|---|---|
| Kobalt `#043EA1` warna utama | Navy `#0B1F4B` utama; kobalt hanya di logo (`PaletSidik.kobaltLogo`) |
| Stempel persegi radius 4 | Stempel pil radius 15 (komponen: P2; token `Bentuk.stempel` sudah ada) |
| Datar, radius 16, aksi 56 dp | Ubin 28-32, tombol pil; aksi utama tetap 56 dp |
| "Lima warna aksen bersaing" dihindari | Empat warna ubin, masing-masing terikat ke satu makna |
| "Ilustrasi stok / ubin ikon dekoratif" dihindari | Visual alat per jenis (milik sendiri, satu gaya), bukan stok |
| Skala huruf `{44, 32, 28, 22, 20, 17, 16, 14, 12}` | Sama, plus SATU ukuran baru: 64 (angka sorot) |
| "Normal diam, pengecualian bersuara" | Dilonggarkan: di ubin alat status selalu tampil (ubin sudah berwarna, stempel menyebut katanya); di baris daftar padat tetap satu stempel per baris |

Yang TIDAK berubah: aplikasi tetap baca-saja, tanpa paket/font baru, status
selalu ikon + kata, area sentuh minimum 48 dp, `AppMotion` dan "kurangi gerak".
Nama PT hanya tampil bila akun punya lebih dari satu perusahaan. Tanpa IBM Plex
Mono: angka memakai Inter selebar tetap + nol bergaris (`GayaAngka.nomor`).

**Tanda yang dihindari** (bawaan generik): gradien ungu-biru, semua panel satu
bentuk dan satu bayangan, semua rata tengah, teks abu di atas latar berwarna,
emoji sebagai ikon, ilustrasi stok, kartu di dalam kartu, ubin ikon dekoratif
di atas judul, chip pil di tiap baris, dan "A · B · C" sebagai pemisah teks.
(Anti-slop ratchet di `anti_slop_test.dart` tetap berlaku sampai P5/P6
menurunkan angkanya.)

### Status penerapan

P1 (token) ada; layar dan widget BELUM diubah. Selama P2-P6 belum selesai,
widget "Jejak" yang ada memakai token baru lewat nama lamanya, jadi tampilannya
setengah jalan: warna, panel, tombol, dan jarak sudah Bento Lab; stempel masih
persegi 4, status masih bertinta navy di semua nada, dan grafik status
(`PetaJatuhTempo`, `SkalaTempo`) kehilangan beda warna tintanya (kata dan ikon
tetap membawa arti).

## 4. Token (satu sumber)

Nilai mentah hanya ditulis di `lib/core/tema/palet_sidik.dart` (warna) dan
berkas token lain di folder itu. Layar membaca lewat `context.skema`
(`ColorScheme`), `context.warna` (`WarnaSidik`: status), `context.teks`
(`TextTheme`), `Spasi`, `Bentuk`, `UkuranIkon`, `AreaSentuh`, `UkuranBaris`,
`UkuranTik`, `UkuranKontrol`, `UkuranUbin`, `UkuranDock`, `UkuranVisual`,
`TipografiSidik.angkaSorot`. `test/tema/token_bento_test.dart` mencocokkan semua
token itu dengan `docs/desain-ulang/tokens.json`.

### Warna

| Peran | Terang | Gelap |
|---|---|---|
| Aksi (tombol utama, fokus, tautan) = `primary` | navy `#0B1F4B` | navyTeks `#C9D3EA` |
| Di atas aksi (`onPrimary`) | putih `#FFFFFF` | navy `#0B1F4B` |
| Ubin ikon pastel (`primaryContainer`) | langit `#BCE0F0` (teks navy) | navyLembut `#2B4380` (teks `#E8ECF6`) |
| Aksen (`secondary`: butir dock aktif, lencana, tombol sakelar) | kuning `#F6D36B` | kuning `#F6D36B` |
| Latar layar | `#EEF0F3` | `#0A1226` |
| Permukaan (panel, baris, isian) | `#FFFFFF` | `#131E3A` |
| Tinta | navy `#0B1F4B` | `#E8ECF6` |
| Tinta kedua | `#4A5672` | `#C9D3EA` |
| Garis tegas (tepi isian, tombol sekunder, sakelar mati) | `#6B7588` | `#7C879B` |
| Garis halus (pemisah, dekoratif) | `#D5DAE3` | `#26385F` |
| Galat isian dan tombol bahaya (`error`) | `#A3261A` | koral `#F2957A` |
| Kobalt logo (hanya aset merek) | `#043EA1` | `#043EA1` |

Status. **Tema terang:** tinta keempat status sama, navy, di atas ubin berwarna.
Pembeda status adalah LATAR + IKON + KATA, tidak pernah warna saja.
**Tema gelap:** tinta = warna pastel di atas latar gelap bernada sama (titik
awal, belum final).

| Status | Ubin / tinta terang | Tinta / latar gelap |
|---|---|---|
| Berlaku (lulus) | hijau `#CBE7B8` / navy | `#CBE7B8` / `#12301F` |
| Segera, perlu perhatian (awas) | kuning `#F6D36B` / navy | `#F6D36B` / `#33260C` |
| Gagal, lewat jadwal | koral `#F2957A` / navy | `#F2957A` / `#3A1720` |
| Diproses (tunggu) | langit `#BCE0F0` / navy | `#BCE0F0` / `#262E40` |
| Netral | putih `#FFFFFF` / navy | `#131E3A` / `#E8ECF6` |

**Penyimpangan sadar dari paket desain** (dicatat di `token_bento_test.dart`
dan perlu keputusan pemilik bila ingin dicabut):

1. Tepi kontrol memakai `garisTegas` (`#6B7588`, nilai Jejak), bukan `garis`
   (`#D5DAE3`): garis Bento Lab cuma 1,4:1 di atas putih dan gagal 3:1
   (komponen UI). `garis` tetap untuk pemisah dan tepi panel.
2. Galat isian dan tombol bahaya memakai merah tua `#A3261A` (ELEMEN.md,
   dialog bahaya), bukan koral: koral hanya 2,2:1 di atas putih sebagai teks.
3. Tema gelap: tinta status pastel, bukan navy. DESIGN.md menyarankan ubin
   tetap terang dengan tinta navy; tetapi tinta status juga dipakai langsung
   sebagai teks dan ikon di atas halaman, dan navy di atas halaman gelap tidak
   terbaca. Memisahkan "tinta ubin" dan "tinta halaman" di `WarnaSidik` adalah
   keputusan komponen (P2).
4. `teksKedua` TIDAK dipakai di atas koral (3,3:1): pakai navy.

Kontras yang dihitung (WCAG 2.x, `test/tema/kontras_tema_test.dart`):

| Pasangan | Rasio | Ambang |
|---|---|---|
| navy / putih, latar, kuning, hijau, langit, koral | 16,0 / 14,0 / 11,0 / 11,9 / 11,5 / 7,1 | 4,5 (teks) |
| teksKedua / putih, latar, kuning, hijau, langit | 7,3 / 6,4 / 5,0 / 5,5 / 5,3 | 4,5 |
| teksKedua / koral (DILARANG) | 3,3 | gagal 4,5 sengaja |
| putih / navy, navyTeks / navy | 16,0 / 10,7 | 4,5 |
| kuning / navy (butir dock, tombol sakelar) | 11,0 | 3 (komponen) |
| garisTegas / putih, latar, garis | 4,6 / 4,1 / 3,3 | 3 |
| garis / putih (DILARANG sebagai tepi kontrol) | 1,4 | gagal 3 sengaja |
| galat `#A3261A` / putih, latar | 7,4 / 6,5 | 4,5 |
| gelap: tinta / latar, permukaan | 15,8 / 13,9 | 4,5 |
| gelap: pastel status / latar tipisnya | 7,1 sampai 10,7 | 4,5 |

Luminans ubin (pembawa makna di tema terang): hijau 0,733, langit 0,703, kuning
0,672, koral 0,418. Selisih terdekat: hijau-langit 0,030 dan langit-kuning 0,031,
lolos tipis terhadap ambang 0,02. Karena itu ikon + kata wajib; warna tidak
pernah satu-satunya penanda.

### Bentuk (`Bentuk`)

| Token | dp | Pakai |
|---|---|---|
| `ikon` | 16 | ubin ikon persegi, isian |
| `kapsul` | 22 | kapsul grafik, segmen, saringan, toast |
| `panel` | 28 | panel putih, ubin kecil (sampai 188), dialog |
| `ubin` | 32 | ubin besar, sudut atas lembar bawah |
| `dock` | 36 | dock navigasi |
| `pil` | 999 | tombol, stempel, kolom cari, avatar |
| `stempel` | 15 | stempel pil setinggi 30 (dipakai komponen P2) |

Nama lama dipertahankan agar widget Jejak tetap memakai token yang sama:
`kontrol` = `ikon` (dulu 10), `kartu` = `panel` (dulu 16), `utama` = `pil` (dulu
16), `lembar` = `panel` (dulu 20). `kecil` tetap 4: tik jejak, tooltip, balok
kerangka, dan (sampai P2) stempel. Alias dihapus di paket bersih-bersih (P7).

### Ukuran sentuh dan komponen

- **Aksi utama 56 dp** (`UkuranBaris.tombolUtama`): `FilledButton`, pil. Satu per
  layar.
- **Semua aksi lain 48 dp** (`AreaSentuh.minimum`): tombol sekunder, tombol
  teks, tombol ikon, segmen, baris yang diketuk.
- Baris daftar minimum 72 dp (`UkuranBaris.minimum` = `UkuranUbin.barisDaftar`).
- Ukuran komponen Bento Lab ada di `ukuran.dart`: `UkuranKontrol` (tombol
  bulat 44/48/52, saringan 44, segmen 56/44, kolom cari 56, sakelar 56x36,
  stempel 30), `UkuranUbin` (baris menu 64, ubin alat 196/232, ubin pasangan
  188, ubin menu 140, kapsul 124/44, avatar 48/88), `UkuranDock` (64/48, 16 dari
  bawah), `UkuranVisual` (160/176/112). Tinggi ubin adalah MINIMUM
  (`ConstrainedBox(minHeight:)`); pada huruf sistem > 1,0 ubin tumbuh.

### Tipografi (Inter; `TipografiSidik.skala`)

Sepuluh ukuran, daftar izin eksplisit di `test/tema/tema_sidik_test.dart`:
`{64, 44, 32, 28, 22, 20, 17, 16, 14, 12}`. Minimum **12 sp**, tanpa pengecualian.
Sembilan ukuran ada di `TextTheme`; 64 hidup di `TipografiSidik.angkaSorot`
(bukan slot).

| Tingkat | Ukuran/baris | Berat desain | Spasi huruf | Slot |
|---|---|---|---|---|
| angka sorot | 64/60 | 800, selebar tetap | -0,04 em | `TipografiSidik.angkaSorot` |
| angka kartu | 44/48 | 800, selebar tetap | -0,04 em | displayLarge |
| kalimat utama | 32/38 | 800 | -0,03 em | displayMedium |
| judul layar | 28/34 | 800 | -0,03 em | displaySmall |
| nama alat/akun | 22/28 | 800 | -0,02 em | headline* |
| judul app bar | 20/26 | 800 | -0,02 em | titleLarge |
| judul bagian/ubin | 17/24 | 800 | -0,01 em | titleMedium |
| label tombol/baris | 16/24 | 700 | 0 | titleSmall, labelLarge |
| isi bacaan | 16/24 | 400 | 0 | bodyLarge, bodyMedium |
| keterangan | 14/20 | 500, tinta kedua | 0 | bodySmall |
| stempel/label | 12/16 | 700, tinta kedua | 0 | labelMedium, labelSmall |

**UTANG DESAIN: berat 800.** Bento Lab meminta 800 (ExtraBold) untuk tingkat
tebal, tetapi Inter yang dibundel hanya punya 400/500/600/700 dan font baru
dilarang. Tingkat tebal tampil **700** lewat satu konstanta
(`TipografiSidik.beratTebal`). Bila pemilik menambah `Inter-ExtraBold.ttf`
(keluarga yang sama) ke `assets/fonts/` dan `pubspec.yaml`, ubah konstanta itu
ke `FontWeight.w800`; `tema_sidik_test.dart` menyuruhnya begitu dan menolak
berat apa pun tanpa berkas fontnya.

Spasi huruf dalam em di tabel dihitung ke dp (ukuran x em) karena Flutter
memakai dp. Nomor sertifikat, order, dan seri: `GayaAngka.nomor` (digit selebar
tetap + nol bergaris, fitur Inter yang sudah dibundel).

### Spasi

Grid 4/8 (`Spasi.xs` 4 sampai `xxl` 32). Margin halaman `Spasi.sisi` **16**
(dulu 20), jarak antar-ubin `Spasi.antarUbin` 12, jarak antar-bagian
`Spasi.bagian` 32, kolom angka pindah ke atas judul di bawah
`Spasi.batasKompak` 340 dp.

### Komponen Material (`TemaSidik`)

Tombol utama dan sekunder pil (56 / 48), tombol teks pil, isian radius 16 dengan
tepi `garisTegas`, kartu dan panel 28, dialog 28, lembar bawah 32 (sudut atas),
toast/snack 22 berlatar navy, saringan (`Chip`) dan segmen terpilih navy + teks
putih, sakelar nyala rel navy + tombol kuning, app bar setara latar halaman
tanpa garis bawah. Navigasi bawah masih bawaan Material (dock melayang: P4).

## 5. Aturan kontras (WCAG 2.x)

- Teks dan ikon yang membawa makna: **>= 4,5:1** terhadap latarnya.
- Komponen UI (tepi isian, tepi tombol, isi tombol utama terhadap latar, ikon
  penting, tik): **>= 3:1**.
- Garis halus (`outlineVariant`) dan batas panel terhadap latar (sekitar 1,1 sampai
  1,3:1) hanya pemisah dekoratif; arti selalu diulang oleh kata, panah, atau
  tautan. Jangan jadikan satu-satunya penanda sebuah kontrol.
- Status selalu ikon + kata, tidak pernah warna saja. Lulus, gagal, awas, dan
  tunggu beda terangnya (luminans relatif selisih > 0,02), diukur pada warna
  yang membawa makna: UBIN di tema terang (tinta status sama, navy), TINTA di
  tema gelap.
- `teksKedua` tidak dipakai di atas koral (3,3:1); `garis` (1,4:1) tidak boleh
  jadi satu-satunya tepi kontrol: pakai `garisTegas`. Keduanya dipegang sebagai
  tes negatif di `kontras_tema_test.dart`.

## 6. Aturan menulis tampilan

1. Satu aksi utama per layar. Satu butir = satu baris; kartu hanya untuk grup.
2. Rancang semua keadaan: memuat, kosong, galat, offline, tanpa izin. Teks
   keadaan memberi langkah berikutnya.
3. Tidak ada kartu di dalam kartu, tidak ada ubin ikon dekoratif, tidak ada
   "A · B · C": tiap fakta di baris sendiri, nomor seri berdiri sendiri.
4. Teks Indonesia baku, pendek, aktif; sentence case. Istilah **"Lewat jadwal"**
   untuk alat dan **"Masa berlaku berakhir"** untuk sertifikat, **bukan**
   "Kedaluwarsa" (keputusan K3 belum final).
5. Tangguh: tanpa overflow di 320 dp x huruf 1,3, di tablet 840 x 1200, di terang
   dan gelap; label `Semantics` untuk apa pun yang bisa diketuk.
6. Server memegang urutan tahap dan label versi pelanggan; aplikasi hanya
   menggambar.

## 7. Cara menjalankan gerbang

Enam kelompok tes deterministik, semuanya ikut `flutter test` dan CI
(`.github/workflows/periksa.yml`).

| Tes | Berkas | Gagal bila |
|---|---|---|
| Token-only (ratchet dua arah) | `test/tema/token_only_test.dart` + `token_only_baseline.json` (pemindai: `test/dukungan/pemindai_token.dart`) | di `lib/`: ada berkas BARU atau hitungan NAIK atau TURUN (tanpa baseline ikut diturunkan) untuk hex mentah, `Color(0x`, `Color.fromARGB/fromRGBO/from(`, `Colors.*`, `fontSize` < 12 (literal, variabel literal, atau ekspresi campuran yang memuat angka pengecil), radius angka atau ekspresi (juga `radius:` di pemanggil widget), tinggi tombol literal < 48 (`minimumSize`, `SizedBox`, `ConstrainedBox`). Daftar berkas yang dilewati harus kosong dan jumlah berkas dipindai >= 90 |
| Kontras | `test/tema/kontras_tema_test.dart` | pasangan token, `ThemeData`, atau label `TombolSidik` (semua ragam) di bawah 4,5:1 (teks) atau 3:1 (komponen), terang atau gelap; atau lulus/gagal/awas/tunggu selisih luminans <= 0,02; dua pasangan DILARANG (teksKedua/koral, garis/putih) mendadak lolos |
| Token tema | `test/tema/token_tema_test.dart` + `tema_sidik_test.dart` + `token_bento_test.dart` | huruf < 12 sp atau di luar daftar izin (termasuk 64), berat huruf tanpa berkas font, spasi/tinggi baris menyimpang dari DESIGN.md, tinggi tombol bukan 56 (utama) / 48, radius di luar set, elevasi di kartu/app bar/navigasi, stempel tanpa ikon atau kata, istilah "kedaluwarsa", atau token Dart berbeda dari `docs/desain-ulang/tokens.json` |
| Anti-slop | `test/tema/anti_slop_test.dart` | di seluruh `lib/`: `KartuSidik(`, `ChipStatus(`, ` · ` pemisah, atau ubin ikon bertambah (atau berkurang tanpa angka diturunkan). Ratchet utang SIMBOL, bukan detektor slop: `Card(`, `Chip(`, atau pemisah lain tidak terlihat |
| Komponen Jejak | `test/tema/komponen_jejak_test.dart` + `test/dukungan/daftar_komponen.dart` | berkas komponen di `lib/widgets` tak diimpor galeri render, tak punya tes widget, atau tak tercatat di README; ada angka mentah pada parameter ukuran (`width`, `height`, `dimension`, `EdgeInsets.*`), warna mentah, " · ", atau "kedaluwarsa"; berkas ber-`InkWell` tanpa tinggi sentuh dari token, `Semantics`, atau `onTap` pada `Semantics` |
| Render | `test/tampilan/render_layar_test.dart` | layar kunci meluap (RenderFlex) atau galat saat render pada HP 392x852, 320 dp x huruf 1,3, tablet 840x1200, terang atau gelap; atau gagal pedoman sasaran sentuh 48 dp / label semantik di HP 392 dan HP sempit (viewport biasa, dan 3000 dp tinggi di tema terang agar butir di bawah lipatan ikut terbangun) |
| Render komponen | `test/tampilan/render_komponen_test.dart` | galeri komponen (semua keadaan) meluap, kontras teks < 4,5:1 (dari pohon widget), sasaran sentuh < 48 dp atau tanpa label (HP 392 dan HP sempit), atau memuat "kedaluwarsa" / " · ", pada HP 392, 320 dp x huruf 1,3, tablet 840, terang atau gelap |

```bash
flutter test test/tema
flutter test test/tampilan/render_layar_test.dart
flutter test test/tampilan/render_komponen_test.dart
```

**Ratchet.** Pelanggaran lama dibekukan per berkas di
`token_only_baseline.json`; hanya boleh mengecil. Pelanggaran yang berkurang
tetapi baseline belum diturunkan juga gagal (sisa angka adalah ruang untuk
menyelipkan pelanggaran baru). Setelah memperbaiki, turunkan:

```bash
SIDIK_TULIS_BASELINE=1 flutter test test/tema/token_only_test.dart
```

Perintah itu menolak menulis bila ada hitungan yang naik atau berkas baru.
**Kenaikan baseline wajib disebut di deskripsi PR dan dicek peninjau.**
Tes tidak bisa membandingkan dengan `origin/main`: baseline dan `_ringkasan`
bisa dinaikkan dengan suntingan tangan dan tes tetap hijau, jadi diff pada
`token_only_baseline.json` (dan angka di `anti_slop_test.dart`) harus dibaca
orang di tiap PR. Isi baseline hari ini: `penyimpan_cache.dart` (empat
konstanta hash FNV-1a yang bukan warna, positif palsu); utang radius
ekspresi di `kerangka.dart` sudah lunas (`BalokKerangka` memakai token
`Bentuk.sudut*`). Pemindai membaca teks, bukan pohon
sintaks; ia menangkap bentuk yang umum, bukan semua cara menyelipkan angka
(mis. tombol yang dibungkus `Center` di dalam `SizedBox`, atau nilai yang
disusun lewat pemanggilan fungsi).

**Render ke PNG** (untuk dilihat mata; tidak ada golden dari mesin non-macOS):

```bash
SIDIK_PNG_DIR=/folder/di/luar/repo flutter test test/tampilan/render_layar_test.dart
SIDIK_LAYAR=beranda,alat SIDIK_PNG_DIR=... flutter test test/tampilan/render_layar_test.dart
```

Nama berkas: `<layar>_<ukuran>_<tema>.png` (ukuran: `hp` 360x800, `hp392`,
`sempit`, `tablet`). Layar kunci ditandai `kunci: true` di `_layarKunci`;
tambahkan layar baru di sana begitu ia punya fixture.

**Utang luapan.** Kombinasi yang sudah meluap sebelum gerbang ada dicatat di
`_utangLuapan` pada harness (nilai = batas px). Hari ini kosong: semua render
sebelum redesain tanpa luapan. Tidak boleh bertambah parah, dan tes gagal bila
utangnya sudah lunas.

**Golden.** Repo ini belum punya golden (`matchesGoldenFile`) dan belum punya
workflow `golden-baru`; satu-satunya workflow adalah `periksa.yml`. Perubahan
token tidak mematahkan golden mana pun. Bila golden diperkenalkan, baseline
harus lahir lewat CI macOS, bukan render Windows. Render PNG manual (di atas)
adalah satu-satunya bukti visual; PNG tidak di-commit.

## 8. Ukuran yang bisa dites, dan yang tidak

Dites mesin: token (nilai, set radius, daftar izin huruf, minimum 12 sp),
kontras (semua pasangan, dua tema), sasaran sentuh dan label semantik di layar
kunci, luapan di tiga ukuran, tanda slop yang bisa dihitung. Batas yang perlu
diketahui: pedoman sentuh/label Flutter melewati node yang menyentuh tepi layar
atau tepi daftar bergulir dan node yang semantiknya tergabung ke wadah besar,
dan area sentuh tombol Material otomatis dilebarkan ke 48 dp. Daftar bergulir
dibangun malas, jadi harness memeriksa juga di viewport 3000 dp; butir yang
lebih jauh dari itu (daftar sangat panjang) tidak dinilai. Lintasan itu sudah
menemukan satu utang nyata: kaki Akun (versi, build, ID pengguna) adalah
`SelectableText` dengan aksi tekan-lama 360x40 dp di HP 392. Ia dicatat di
`_utangSentuhPanjang` (boleh mengecil, tidak boleh bertambah) dan dibereskan di
paket layar Akun. Ia jaring pengaman
untuk tombol sungguhan, bukan bukti bahwa semua target >= 48 dp. **Tidak dites
mesin, dan wajib dilihat mata:** hierarki, irama, apakah arahnya tidak generik.
Bukti render PNG per PR, tinjauan agen yang bukan perancangnya, dan mata pemilik
di perangkat tetap diperlukan; angka hijau saja tidak cukup.

## 9. Status migrasi

- Paket 0 (gerbang) dan Paket 1 (nilai token baru di bawah nama lama): ada.
- P1 Bento Lab (token): ada. Palet, `WarnaSidik`, `Bentuk`, `UkuranKontrol/
  Ubin/Dock/Visual`, `Spasi.sisi` 16, `TipografiSidik.angkaSorot`, dan `TemaSidik`
  memakai nilai Bento Lab. Layar dan widget belum diubah. Berikutnya: P2
  (komponen), P3 (elemen, gambar alat, splash, masuk), P4 (dock), P5 (layar),
  P6 (sapu pola), P7 (bersih-bersih). Rencana: `docs/desain-ulang/PROMPT.md`.
- Paket 2 (komponen bersama): ada, 20 berkas baru di `lib/widgets` (daftar di
  `lib/widgets/README.md`): `PanelSidik`, `BarisSidik`, `BarisAlat`, `AngkaHari`,
  `Stempel`, `JejakTahap`, `TikPaket`, `GarisWaktuTahap`, `SkalaTempo`,
  `PetaJatuhTempo`, `KalimatUtama`, `RingkasanPerhatian`, `PlatNama`, `Fakta`,
  `NomorSidik`, `SaringanTeks`, `KolomCariUtuh`, `Bagian`, `TautanBaris`,
  `KeadaanTeks`. Token geometri baru di `ukuran.dart`
  (`UkuranTik.simpul/batang/...`, `SkalaHuruf`).
- Paket 3a (Beranda): ada. `BerandaScreen` memakai `KalimatUtama`,
  `RingkasanPerhatian`, `BarisAlat` + `JejakTahap`, `BarisSidik`, `TikPaket`,
  `PetaJatuhTempo`, `Bagian`, `TautanBaris`, `KeadaanTeks`, `BannerDataTerakhir`.
  `KartuKpi` dan `KotakJatuhTempo` dipensiunkan (tidak ada pemakai lain);
  `Spasi.lebarLebar` (1040) dan `HalamanSidik.lebarMaks` dipakai untuk dua kolom
  di tablet.
- Berikutnya: layar satu per satu memakai komponen itu (detail paket,
  daftar alat, detail alat, sertifikat, notifikasi, akun); tiap layar menurunkan
  angka ratchet `KartuSidik`/`ChipStatus`/" · ".
- Yang masih memakai bentuk lama sampai paketnya tiba: 22 pemakaian `KartuSidik`,
  14 `ChipStatus` (pil, bukan stempel persegi), 10 pemisah ` · ` (satu di model
  `Alat.merkModel`), 2 widget berubin ikon (4 kemunculan rumus ubin),
  deretan chip saring yang terpotong, nomor order yang putus di 320 dp x 1,3
  (lihat tabel di `anti_slop_test.dart`).

### Utang komponen Jejak (diketahui, belum dikerjakan)

- Tablet: komponen mengisi lebar induk (tanpa batas lebar baca; `PlatNama` dan `Fakta` ikut melebar), belum ada varian dua kolom atau master-detail, dan `SaringanTeks` dengan tujuh pilihan masih menyisakan pilihan tergulir di 840 dp. Batas lebar baca dan dua kolom dikerjakan per layar di Paket 3 (Beranda 3a, daftar alat 3c); layar membungkus isi dengan `KontenTengah` (720 dp). Beranda sudah dua kolom di area isi >= 680 dp (`HalamanSidik.lebarMaks: Spasi.lebarLebar`); layar lain belum.
- `SkalaTempo` di luar jendela (jadwal lebih dari 90 hari lagi): batang abu tanpa penanda "hari ini" selain label kiri; arti dibawa kata. Penanda hari ini bisa ditambahkan bila peninjau mata meminta.
- `PetaJatuhTempo` tema gelap: batang zona netral memakai garis tegas (abu), tidak lebih terang dari batang status; dinilai mata di Beranda (PNG `beranda_*_gelap`), belum dinilai di perangkat.
- Jejak tahap per alat di Beranda memakai SALINAN KLIEN urutan tahap (`lib/models/garis_tahap_pelanggan.dart`), karena `GET /beranda` dan `GET /alat` hanya mengirim `tahap` + `tahap_label` per alat (`sedang_dikerjakan`), bukan `garis_waktu` (hanya di `GET /paket/{id}`). Dijaga tes paritas terhadap `TahapPaket::garisWaktu` (API `d8dc320a`); kode tahap yang tidak dikenal tidak mendapat tik "sekarang". Penggantinya: server mengirim `garis_waktu`/`posisi` per alat (A5). Layar alat (3c, 3d) memakai fungsi yang sama.
- Beranda: "paket siap diambil", "sertifikat baru", dan klaim "berlaku" hanya sejujur data `GET /beranda` yang ada: `paket_berjalan` dibatasi tiga dan `sertifikat_terbaru` lima, dan `jumlah_alat` ikut menghitung alat yang belum pernah dikalibrasi. Tanpa hitungan baru dari server: kalimat tidak menyebut angka bila daftar terpotong ("Ada paket siap diambil.", "Ada sertifikat baru terbit."), tenang = "Tidak ada alat yang lewat jadwal." (tanpa "berlaku"), dan bila paket berjalan lebih banyak dari daftar tampil tautan "Lihat semua paket (N)". Aplikasi sudah membaca `ringkasan.paket_siap_diambil`, `alat_berlaku`, `alat_belum_pernah`, `sertifikat_baru_7_hari`, dan `sedang_dikerjakan.garis_waktu` bila ada; permintaan API dan usul tes penjaga ada di `docs/kebutuhan-api-pelanggan.md` §7.
- Beranda tablet: dua kolom (kiri: kalimat, perhatian, peta jadwal; kanan: lab dan sertifikat); keadaan tenang tanpa peta.
- Ekor "lewat N hari" di `SkalaTempo` dilebarkan sampai 8% supaya terlihat (posisi sebenarnya tetap di `SkalaTempo.posisi`); angka tidak berubah karena batang bukan pembawa arti.
- Pola `Semantics(excludeSemantics: true, child: InkWell)` di `KartuSidik`, `AksiBagian`, dan layar lama membuang aksi ketuk bagi pembaca layar: periksa per layar di Paket 3.
