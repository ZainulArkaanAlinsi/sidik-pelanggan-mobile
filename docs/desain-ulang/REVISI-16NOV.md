# REVISI 16 Nov 2026 — arah tenang, formal, ringkas (menggantikan Bento Lab)

Sumber: dua dokumen revisi pemilik (REVISI-1 arahan umum, REVISI-2 app
Pelanggan). Berkas ini mencatat bagaimana revisi itu diterapkan di kode. Di mana
`DESIGN.md`, `ELEMEN.md`, `KOMPONEN.md`, `UKURAN.md`, dan `VISUAL.md` (arah Bento
Lab) bertentangan dengan berkas ini, **berkas ini menang**. Berkas lama itu
dibiarkan sebagai arsip sampai layar terakhir selesai dipoles.

Yang TIDAK berubah: logika, alur, API, peran, rute, isi data, dan aturan
baca-saja (`test/guard_tulis_test.dart`).

## Token (sumber satu: `lib/core/tema/`, dicocokkan ke `tokens.json`)

| Penggunaan | Sebelum (Bento Lab) | Sekarang |
|---|---|---|
| Latar halaman | `#EEF0F3` | `#F4F7FB` |
| Permukaan kartu | `#FFFFFF` | `#FFFFFF` |
| Judul dan teks utama (`navy`) | `#0B1F4B` (juga warna tombol) | `#102A43` (hanya teks) |
| Aksi: tombol utama, tautan, tab aktif (`biru`) | navy | `#1769C2` (putih di atasnya 5,5:1) |
| Pilihan aktif (`biruMuda`) | pil navy / kuning | `#EAF3FF`, dipadukan tepi biru atau indikator |
| Teks pendukung | `#4A5672` | `#526477` (6,1:1 di atas putih) |
| Garis halus | `#D5DAE3` | `#DCE5EE` |
| Tepi kontrol (`garisTegas`) | `#6B7588` | `#66788A` (4,5:1 di atas putih) |
| Status | pastel jenuh bertinta navy (koral, kuning, hijau, langit) | tinta GELAP di atas warna MUDA: hijau gelap di hijau muda, amber gelap di krem, merah gelap di merah muda, biru tua di biru kelabu muda; selalu ikon + kata |
| Radius | 16 / 22 / 28 / 32 / 36 / pil | kartu dan ubin 16, tombol 10, isian dan saringan 12, lencana 6; pil (999) hanya untuk lingkaran sungguhan |
| Tombol utama | pil 56 | persegi bersudut 10, tinggi 48 |
| Lencana status | pil 30 | 24, sudut 6, ikon 14 + kata 12/600 |
| Huruf | Inter 800 (jatuh ke 700), 64/44/32/28/22/20/17/16/14/12 | Inter 400/500/600; angka sorot 32 dan angka kartu 28 (IBM Plex Mono), kalimat dan judul layar 24, nama 20, judul bar 18, judul bagian 16, label 14, isi 16 dan 14, keterangan 13, lencana 12; tanpa spasi huruf negatif |
| Angka dan kode | Inter tabular | IBM Plex Mono (nomor sertifikat, order, seri, sisa hari). Dibundel di `assets/fonts` (SIL OFL, `LICENSE-IBMPlexMono.txt`), berkas yang sama dengan `sidik-calibration-mobile`; tidak diunduh saat jalan |
| Bayangan | dock navy 0/16/32 | tidak ada; garis 1 dp |

Nama token lama dipertahankan di kode bila artinya masih dekat (`PaletSidik.kuning`
sekarang = krem status awas, `WarnaSidik.ubinGagal` = merah muda, dst.) supaya PR
ini tidak menyentuh puluhan pemakai. Pembersihan nama menyusul.

## Komponen bersama

- **Bilah navigasi bawah** (`BilahNavigasi`, menggantikan `DockNavigasi`): permukaan
  putih selebar layar, garis 1 dp di atas, semua menu berlabel, indikator aktif biru
  muda 56 x 32 + ikon terisi + kata semibold, lencana notifikasi merah galat. Tepi
  sistem ditambahkan di dalam permukaan. Banner pembaruan duduk tepat di atasnya;
  isi tab berakhir di atas keduanya. Urutan, rute, dan semantik (label, `selected`,
  "Tab n dari m") sama seperti dock.
- **Kartu netral**: `UbinAlat` (Beranda dan Alat saya) putih dengan garis halus;
  status hanya di lencana. `UbinRingkas`/`UbinMenu` boleh membawa warna muda status
  (ringkasan, bukan daftar).
- **Saringan dan segmen terpilih**: biru muda + tepi biru + kata navy (bukan pil navy
  penuh); bulatan jumlah biru berangka putih.
- **Kolom cari**: kotak bersudut 10 setinggi 48, tombol cari bulat 36 (area ketuk 48).
- **Kepala layar masuk** (sambutan, masuk, undangan, lupa sandi): biru muda, lebih
  rendah (240), plat logo 80. Penyusunan ulang layar auth ada di PR berikutnya.

## Putaran perbaikan 1 (tinjauan independen)

- Ikon dialog: `dialogTheme.iconColor = primary` (bawaan = `secondary` = putih).
- Label bilah: uji anti-potong memakai lebar alami paragraf (`getMaxIntrinsicWidth`).
- Krem hanya untuk "perlu diperiksa": ubin Sertifikat terbaru (Beranda), keadaan kosong
  Beranda, dan keadaan kosong Alat saya kini netral. Pemakai krem yang tersisa semuanya
  bermakna peringatan: segera jatuh tempo (<= 30 hari), perlu diulang, digantikan,
  paket melewati target, banner offline dan notifikasi mati, sesi berakhir, kartu galat
  darurat, saringan "Dalam 30 hari".
- Papan ketik terbuka menyembunyikan bilah dan banner (HP); bobot 700 diganti semibold
  di kode (Inter-Bold tetap dibundel).
- Tidak dikerjakan di putaran itu: `ChipStatus` masih pil 999 (kini selesai, lihat R1b);
  tinta status "berjenjang" bukan bukti aksesibilitas (hanya pelengkap ikon + kata); tema
  gelap dengan ubin pastel terang terasa silau (PR tema gelap).

## R1b: poles layar yang sudah rilis (Alat saya, Beranda, auth, lencana)

Sumber: REVISI-1 butir 5/6/9/11, REVISI-2 butir 1/2/12. Logika, alur, API, peran, rute,
data, dan aturan baca-saja tidak berubah.

- **Kartu alat ringkas** (`UbinAlat`, dipakai Alat saya DAN Beranda): lima baris (nama
  menonjol; "merk model · SN seri" dengan seri IBM Plex Mono; lokasi; lencana status;
  "Lihat detail →" + tanggal jadwal). Waktunya ikut di kata lencana untuk tiga status
  jadwal ("Lewat jadwal 4 hari", "Segera jatuh tempo 12 hari lagi", "Berlaku 120 hari
  lagi"); alat di lab membawa tahapnya sebagai lencana kedua. Angka hari besar, visual
  kanan bawah, dan varian Beranda 232/160 dibuang.
- **Alat nonaktif (keputusan perlakuan)**: tanpa hitung mundur sama sekali (tidak di
  lencana, tidak di keterangan, tidak di kalimat pembaca layar). Lencana tetap "Tidak
  aktif" (netral), namanya diredupkan ke teks kedua, dan jadwal yang tercatat tampil
  sebagai konteks "Alat nonaktif, jadwal tercatat 22 Nov 2026". Alasan: server tetap
  mengirim jadwalnya, tetapi alat nonaktif tidak boleh terbaca sebagai tindakan yang harus
  segera dilakukan. Dijaga `alat_bento_test` (kartu ringkas R1b) dan
  `komponen_bento_ubin_test`.
- **Keadaan Alat saya**: kosong = kartu netral ringkas (ikon biru muda, judul 18) dan, bila
  saringan yang menyempitkan daftar, satu tombol "Tampilkan semua alat"; kerangka memuat
  mengikuti bentuk kartu ringkas; lencana jumlah dan catatan luring bersudut 12 (bukan pil
  999).
- **Beranda**: judul "Kalibrasi Anda" (24) di atas ringkasan (18, bukan dua kalimat 24);
  kartu alat ringkas yang sama dengan Alat saya; kapsul jatuh tempo rel 80 (dulu 100);
  ubin Paket netral saat tenang/kosong (hijau hanya bila ada paket siap diambil, krem bila
  terlambat); baris bantuan netral (permukaan + garis, ikon biru muda) bukan biru kelabu
  status; catatan offline tenang (abu muda) karena bingkai aplikasi sudah memasang
  peringatan krem.
- **Auth** (Sambutan, Masuk, Undangan, Lupa sandi): kepala biru muda 240 dp dan plat logo
  80 diganti kepala ringkas (logo 48 + nama aplikasi) di atas latar halaman, satu kartu
  putih bergaris halus sudut 16; judul 24 ("Masuk ke SIDIK"); isian memakai `KolomIsian`
  (label PERMANEN di atas kolom, bantuan dan galat tepat di bawahnya, kolom 48, satu
  simpul semantik, ruang agar tombol tidak tertutup papan ketik).
- **Lencana bersama**: `ChipStatus` mendelegasikan ke `Stempel` (24, sudut 6, ikon 14);
  kata panjang membungkus, tidak dipotong.
- **Pemisah "merk model · SN seri"**: REVISI-2 butir 2 menetapkan baris itu, sedangkan
  penjaga desain lama (`anti_slop_test`, `komponen_jejak_test`, gerbang token, galeri
  render) melarang string " · " di teks. Penjaganya TIDAK dilonggarkan: baris dibangun
  dari dua potongan yang membungkus utuh (`Text("Mitutoyo CD-15CPX ·")` dan
  `Text("SN 2201-0457")` mono), jadi tidak ada string " · " di kode, dan "SN seri" tidak
  pernah terbelah di layar sempit.

## Belum dikerjakan (PR berikutnya)

Poles layar: detail alat, sertifikat, paket, akun (termasuk Ganti sandi: label permanen
lewat `KolomIsian`), anggota, preferensi, notifikasi, bantuan, dan kondisi sistem. Sertifikat
(daftar) sudah di #31. Tema gelap masih titik awal (belum ditinjau). Pembersihan token Bento
yang tak dipakai lagi (`UkuranUbin.alat/alatBeranda`, `UkuranVisual.alat*`, nama token yang
menyesatkan) menyusul di PR bersih-bersih.
