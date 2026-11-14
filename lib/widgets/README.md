# lib/widgets — komponen bersama

Satu tanggung jawab per berkas. Layar di `lib/screens/` merakit komponen ini;
gaya (warna, spasi, huruf) datang dari token di `lib/core/tema`, bukan ditulis
ulang di sini. Lihat `lib/core/tema/README.md`.

## Kerangka dan tata letak

| Berkas | Komponen |
|---|---|
| `halaman_sidik.dart` | `HalamanSidik`: Scaffold + AppBar bertema + isi dipusatkan (`lebarMaks` untuk layar dua kolom). Dipakai semua layar. |
| `konten_tengah.dart` | `KontenTengah`: isi dibatasi ±720 dp dan dipusatkan di layar lebar. |
| `kolom_formulir.dart` | `KolomFormulir`: kolom sempit (440 dp) bergulir untuk Sambutan, Masuk, dan layar keadaan penuh. |
| `navigasi_utama.dart` | `NavigasiUtama` + `TujuanNavigasi`: navigasi bawah di HP, rel samping di >= 600 dp (`LayoutBuilder`, tanpa paket). |
| `bagian_sidik.dart` | `BagianSidik` (judul bagian) dan `AksiBagian` ("Lihat semua"). |

## Isi

| Berkas | Komponen |
|---|---|
| `kartu_sidik.dart` | `KartuSidik`: kartu datar; diketuk = ripple standar. |
| `kartu_alat.dart`, `kartu_sertifikat.dart`, `kartu_paket.dart` | Kartu domain di daftar dan Beranda. |
| `kartu_kelompok_arsip.dart` | `KartuKelompokArsip`: satu tahun, bulan, atau pekan di Arsip sertifikat (label dan jumlah dari server, panah buka). |
| `garis_waktu_sertifikat.dart` | Riwayat sertifikat satu alat. |
| `baris_info.dart` | `BarisInfo`: label dan nilai di lembar detail. |
| `baris_menu.dart` | `BarisMenu` + `KelompokBaris`: menu berikon dalam satu kartu. |
| `panel_pemberitahuan.dart` | `PanelPemberitahuan`: ikon, judul, isi, aksi pada latar status. |
| `lencana_kan.dart` | `LencanaKan` "KAN LK-285-IDN". Hanya di sambutan dan detail sertifikat. |
| `logo_sidik.dart` | `LogoSidik`: logo resmi (`assets/images/logo_sidik.png`). |

## Status

| Berkas | Komponen |
|---|---|
| `status_tampil.dart` | `StatusTampil` (label, nada, ikon) dan `NadaStatus`. |
| `pemetaan_status.dart` | SATU pemetaan kode/status → `StatusTampil` (`statusAlat`, `statusSertifikat`, `statusPaket`, ...). Istilah dari `StatusBerlaku.label`: "Lewat jadwal", "Masa berlaku berakhir", bukan "kedaluwarsa". |
| `chip_status.dart` | `ChipStatus`: ikon + teks pada latar tipis. |

## Komponen "Jejak" (Paket 2; dipakai Beranda sejak Paket 3a)

Komponen bersama arah "Jejak" (`docs/standar-kualitas-desain.md`). Dipakai
Beranda (Paket 3a); layar lain menyusul di Paket 3 (menggantikan kartu, chip,
dan `BarisInfo` per layar). Semuanya
dari token, tanpa paket atau font baru; tiap komponen punya tes widget di
`test/widgets/` dan masuk galeri render `test/tampilan/render_komponen_test.dart`
(daftar: `test/dukungan/daftar_komponen.dart`).

| Berkas | Komponen | Menggantikan |
|---|---|---|
| `panel_sidik.dart` | `PanelSidik`: satu panel, butir dipisah garis halus. Satu butir = satu baris. | `KartuSidik` per butir |
| `baris_sidik.dart` | `BarisSidik` + `tataLetakKompak`: baris min 72 dp, slot angka/judul/keterangan/akhir, kompak di < 340 dp atau huruf > 1,15x, `gayaNomor`. | `KartuAlat`, `KartuPaket`, `KartuSertifikat`, `BarisMenu` |
| `baris_alat.dart` | `BarisAlat`: sisa hari memimpin, nama dan merk paling banyak 2 baris, nomor seri sendiri, jejak tahap bila di lab; belum ada jadwal = satu baris di atas nama. | `KartuAlat` |
| `angka_hari.dart` | `AngkaHari` (kolom, kompak, bintang 44) dan `AngkaKata`. | ikon kalender + `Format.sisaHari` |
| `stempel.dart` | `Stempel`: persegi sudut 4, ikon + kata; `tenang` = tanpa latar. | `ChipStatus` |
| `jejak_tahap.dart` | `JejakTahap` + `posisiTahap`: satu tik per langkah `garis_waktu`, kata wajib. | ikon radio/centang bawaan |
| `tik_paket.dart` | `TikPaket`: satu tik per alat dalam paket, "N dari M alat selesai". | teks "N dari M" saja |
| `garis_waktu_tahap.dart` | `GarisWaktuTahap`: garis waktu tegak + `menunggu()` ("Menunggu: A dan B"). | `_Langkah` di paket detail |
| `skala_tempo.dart` | `SkalaTempo`: jendela 90 hari (keputusan desain), kata + dua label berpusat pada tiknya, ekor lewat jadwal paling sedikit 8%. | baris "Lewat 4 hari" |
| `peta_jatuh_tempo.dart` | `PetaJatuhTempo` + `ZonaTempo`: satu penggaris, zona bisa diketuk. | empat ubin KPI (`KartuKpi`, sudah dihapus) |
| `kalimat_utama.dart` | `KalimatUtama` + `PotonganKalimat`: kalimat besar, frasa status berwarna (kata, bukan warna saja). | sapaan + nama PT |
| `ringkasan_perhatian.dart` | `RingkasanPerhatian`: "Perlu perhatian" paling banyak 3 butir + tautan; kosong = tidak digambar. | empat ubin KPI |
| `plat_nama.dart` | `PlatNama`: nomor seri sebagai identitas, hanya fakta terisi. | `BarisInfo` x7 di detail alat |
| `fakta.dart` | `Fakta`: "label  nilai" yang membungkus di 320 dp. | `BarisInfo` |
| `nomor_sidik.dart` | `NomorSidik`: nomor tidak putus di tengah (1 baris, mengecil sampai 12 sp, lalu membungkus di "/"). | nomor order yang putus |
| `saringan_teks.dart` | `SaringanTeks` + `PilihanSaringan`: kata + jumlah, garis bawah terpilih, tepi memudar hanya bila bisa digeser. | `ChoiceChip` x5, `SegmentedButton` |
| `kolom_cari_utuh.dart` | `KolomCariUtuh`: petunjuk membungkus (tidak terpotong "Cari nama, merk, at..."). | `KolomCari` |
| `bagian.dart` | `Bagian`: judul 17/24, jumlah redup, tautan teks 48 dp. | `BagianSidik` |
| `tautan_baris.dart` | `TautanBaris`: tautan teks + panah, 48 dp. | tombol outline lebar |
| `keadaan_teks.dart` | `KeadaanTeks` (rata kiri, tanpa ikon) + `BannerDataTerakhir`. | `KeadaanKosong`, `KeadaanGalat` |

Catatan a11y: komponen yang bisa diketuk memasang `onTap` pada `Semantics`
pembungkusnya, bukan hanya pada `InkWell`: `excludeSemantics` membuang aksi
ketuk milik `InkWell`, dan tombol berlabel tanpa aksi ketuk tidak bisa
diaktifkan pembaca layar (`KartuSidik` lama memakai pola itu; lihat laporan PR).

## Aksi dan masukan

| Berkas | Komponen |
|---|---|
| `tombol_sidik.dart` | `TombolSidik` (`RagamTombol`: utama, sekunder, teks, bahaya). Satu `utama` per layar. |
| `kolom_cari.dart` | `KolomCari`: kolom cari dengan jeda ketik 350 ms. |

## Keadaan

| Berkas | Komponen |
|---|---|
| `kerangka.dart` | `Memuat` dan kerangka berdenyut (`KerangkaDaftar`, `KerangkaDetail`, `KerangkaKartu`). |
| `keadaan_kosong.dart` | `KeadaanKosong` / `KeadaanKosongIsi`. |
| `keadaan_galat.dart` | `KeadaanGalat` + "Coba lagi". |
| `daftar_berhalaman.dart` | Daftar infinite scroll dengan empat keadaan. |

## Infrastruktur (bukan gaya)

`banner.dart` (banner offline dan izin notifikasi), `pembaruan.dart` (banner
dan dialog pembaruan aplikasi), `penampil_pdf.dart` (satu-satunya berkas yang
boleh mengimpor `pdfx`; lihat `docs/pustaka-pdf.md`).

## Menambah komponen

1. Satu berkas, satu tanggung jawab, komentar `///` singkat berbahasa Indonesia.
2. Hanya token dari `lib/core/tema` (tes menolak `Color(0x`, `Colors.*`, dan angka
   telanjang untuk jarak/sudut/huruf).
3. Sentuh >= 48 dp, label `Semantics` untuk ikon tanpa teks, uji pada 320 dp
   dengan huruf 1,3× (`test/widgets/komponen_sidik_test.dart`).
4. Tambahkan layar yang memakainya ke harness
   `test/tampilan/render_layar_test.dart` bila perlu dinilai mata.
