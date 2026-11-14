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

## 3. Arah visual: "Jejak"

Satu keluarga dengan Lab (kobalt `#043EA1`, netral dingin, Inter, grid 4/8,
stempel persegi radius 4), tetapi lebih tenang dan lega.

1. **Kalimat utama + angka sebagai penunjuk.** Beranda dibuka dengan satu kalimat
   besar ("1 alat lewat jadwal. 1 paket siap diambil."); sisa hari menjadi angka
   di awal baris alat, bukan ubin KPI.
2. **Jejak tahap.** Satu motif tik, satu tik per langkah `garis_waktu` dari
   server, dipakai di Beranda, daftar alat, detail alat, dan paket. Jumlah tik
   = panjang `garis_waktu`, tidak pernah angka 6 yang dikeraskan di kode.
3. **Normal diam, pengecualian bersuara.** "Berlaku" dan "Memenuhi toleransi"
   tanpa stempel; hanya "Lewat jadwal", "Tidak memenuhi toleransi", dan sejenisnya
   yang berstempel.

Keputusan pemilik: stempel status persegi radius 4 (bukan pil) dan tombol utama
56 dp (dua hal yang mengubah tabel brief Lab, berlaku juga di sini). Nama PT
hanya tampil bila akun punya lebih dari satu perusahaan. Tanpa IBM Plex Mono:
angka memakai Inter selebar tetap + nol bergaris (`GayaAngka.nomor`).

**Tanda yang dihindari** (bawaan generik): gradien ungu-biru, semua panel satu
bentuk dan satu bayangan, semua rata tengah, teks abu di atas latar berwarna,
emoji sebagai ikon, ilustrasi stok, lima warna aksen bersaing, kartu di dalam
kartu, ubin ikon dekoratif di atas judul, chip pil di tiap baris, dan "A · B · C"
sebagai pemisah teks.

## 4. Token (satu sumber)

Nilai mentah hanya ditulis di `lib/core/tema/palet_sidik.dart` (warna) dan
berkas token lain di folder itu. Layar membaca lewat `context.skema`
(`ColorScheme`), `context.warna` (`WarnaSidik`: status), `context.teks`
(`TextTheme`), `Spasi`, `Bentuk`, `UkuranIkon`, `AreaSentuh`, `UkuranBaris`,
`UkuranTik`.

### Warna

| Peran | Terang | Gelap |
|---|---|---|
| Kobalt (aksi, fokus, tautan) | `#043EA1` | `#8CB0FF` |
| Kobalt tipis | `#DCE6FA` | `#14306F` |
| Latar layar | `#F2F4F8` | `#0E1320` |
| Permukaan (panel, baris, isian) | `#FFFFFF` | `#171D2B` |
| Tinta | `#111827` | `#E6EAF2` |
| Tinta kedua | `#475467` | `#A9B2C3` |
| Garis tegas (tepi isian dan tombol) | `#6B7588` | `#7C879B` |
| Garis halus (pemisah, dekoratif) | `#DDE2EB` | `#2C3548` |

Status (tinta di atas latar tipis; satu keluarga dengan Lab):

| Status | Terang | Gelap |
|---|---|---|
| Berlaku (lulus) | `#125739` / `#E1F0E8` | `#6FD3A0` / `#12301F` |
| Segera, perlu perhatian (awas) | `#8C5C0A` / `#FBF0DA` | `#DB9A2B` / `#33260C` |
| Gagal, lewat jadwal | `#A81B33` / `#FBE4E8` | `#FF8FA0` / `#3A1720` |
| Diproses (tunggu) | `#344054` / `#E6EAF2` | `#C3CAD8` / `#262E40` |

Amber berubah dari `#7A4F08`/`#F2B655` ke nilai di atas (sama dengan Lab):
nilai lama nyaris sama terangnya dengan merah (terang, selisih luminans 0,004)
dan dengan hijau (gelap, 0,005), sehingga fotokopi hitam-putih dan mata
deuteranopia tak bisa membedakan "awas" dari "gagal"/"lulus". Pengaman utamanya
tetap ikon + kata; aturan beda terang adalah lapis kedua.

**Ini menyimpang dari brief desain Pelanggan**, yang menyatakan tidak ada nilai
warna berubah (tabel kontras brief bagian 8.1 dihitung dengan amber lama).
Penyimpangan dipilih sadar dan sama dengan Lab; gerbang kontras sendiri yang
menemukan amber lama melanggar aturan beda terang. Rasio WCAG yang berubah
(dihitung ulang, semua tetap >= 4,5:1):

| Pasangan | Amber lama | Amber baru |
|---|---|---|
| terang: awas / putih | 7,12 | 5,75 |
| terang: awas / latar layar | 6,47 | 5,22 |
| terang: stempel awas (tinta / latar tipis) | 6,30 | 5,09 |
| gelap: awas / permukaan | 9,30 | 6,95 |
| gelap: stempel awas (tinta / latar tipis) | 8,15 | 6,09 |

Selisih luminans: terang lulus-gagal 0,0211 (nilai lama, tidak diubah; tipis
terhadap ambang 0,02), gagal-awas 0,0390, lulus-awas 0,0601; gelap lulus-gagal
0,0906, gagal-awas 0,0510, lulus-awas 0,1416.

### Bentuk (`Bentuk`)

Stempel, tik, dan plat nama 4; isian dan tombol sekunder 10; panel dan tombol
utama 16; lembar bawah dan dialog 20; pil 999 hanya untuk lencana angka (dan
chip saring sampai diganti komponen baru). Radius bervariasi dengan alasan.

### Ukuran sentuh

- **Aksi utama 56 dp** (`UkuranBaris.tombolUtama`): `FilledButton`. Satu per
  layar.
- **Semua aksi lain 48 dp** (`AreaSentuh.minimum`): tombol sekunder, tombol
  teks, tombol ikon, segmen, baris yang diketuk.
- Baris daftar minimum 72 dp (`UkuranBaris.minimum`).

### Tipografi (Inter; `TipografiSidik.skala`)

Sembilan ukuran, daftar izin eksplisit di `test/tema/tema_sidik_test.dart`:
`{44, 32, 28, 22, 20, 17, 16, 14, 12}`. Minimum **12 sp**, tanpa pengecualian.

| Tingkat | Ukuran/baris | Berat | Slot |
|---|---|---|---|
| angka bintang | 44/48 | 700, selebar tetap | displayLarge |
| kalimat utama | 32/38 | 700 | displayMedium |
| tampilan | 28/34 | 700 | displaySmall |
| judul | 22/28 | 600 | headline* |
| app bar | 20/26 | 600 | titleLarge |
| subjudul | 17/24 | 600 | titleMedium |
| isi | 16/24 | 400 (600 untuk nama) | body*, titleSmall, labelLarge |
| keterangan | 14/20 | 400, tinta kedua | bodySmall |
| label | 12/16 | 600 | labelMedium, labelSmall |

Nomor sertifikat, order, dan seri: `GayaAngka.nomor` (digit selebar tetap + nol
bergaris, fitur Inter yang sudah dibundel).

### Spasi

Grid 4/8 (`Spasi.xs` 4 sampai `xxl` 32). Margin halaman `Spasi.sisi` 20, jarak
antar-bagian `Spasi.bagian` 32, kolom angka pindah ke atas judul di bawah
`Spasi.batasKompak` 340 dp. Nama-nama baru ini baru dipakai paket komponen.

## 5. Aturan kontras (WCAG 2.x)

- Teks dan ikon yang membawa makna: **>= 4,5:1** terhadap latarnya.
- Komponen UI (tepi isian, tepi tombol, isi tombol utama terhadap latar, ikon
  penting, tik): **>= 3:1**.
- Garis halus (`outlineVariant`) dan batas panel terhadap latar (sekitar 1,1 sampai
  1,3:1) hanya pemisah dekoratif; arti selalu diulang oleh kata, panah, atau
  tautan. Jangan jadikan satu-satunya penanda sebuah kontrol.
- Status selalu ikon + kata, tidak pernah warna saja. Lulus, gagal, dan awas
  beda terangnya (luminans relatif selisih > 0,02), `tunggu` dikecualikan
  (abu tanpa rona).

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
| Kontras | `test/tema/kontras_tema_test.dart` | pasangan token, `ThemeData`, atau label `TombolSidik` (semua ragam) di bawah 4,5:1 (teks) atau 3:1 (komponen), terang atau gelap; atau lulus/gagal/awas selisih luminans <= 0,02 |
| Token tema | `test/tema/token_tema_test.dart` + `tema_sidik_test.dart` | huruf < 12 sp atau di luar daftar izin, tinggi tombol bukan 56 (utama) / 48, radius di luar set, elevasi di kartu/app bar/navigasi, stempel tanpa ikon atau kata, istilah "kedaluwarsa" |
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
harus lahir lewat CI macOS, bukan render Windows.

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
