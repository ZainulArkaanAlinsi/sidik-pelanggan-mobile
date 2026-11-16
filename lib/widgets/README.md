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
| `navigasi_utama.dart` | `NavigasiUtama` + `TujuanNavigasi` + `BilahNavigasi`: di HP bilah bawah SOLID (REVISI-2 butir 13): putih selebar layar, garis 1 dp di atas, tanpa bayangan, SEMUA menu berlabel, indikator aktif biru muda 56 x 32 + ikon terisi + kata semibold, lencana notifikasi merah galat; tepi sistem di dalam permukaan; banner pembaruan menempel di atasnya dan isi berakhir di atas keduanya; label mengikuti huruf sistem sampai 1,3x lalu mengecil (tidak terpotong). Rel samping di >= 600 dp (`LayoutBuilder`, tanpa paket). |
| `bagian_sidik.dart` | `BagianSidik` (judul bagian) dan `AksiBagian` ("Lihat semua"). |

## Isi

| Berkas | Komponen |
|---|---|
| `kartu_sidik.dart` | `KartuSidik`: kartu datar; diketuk = ripple standar. |
| `kartu_alat.dart`, `kartu_sertifikat.dart`, `kartu_paket.dart` | Kartu domain di daftar dan Beranda. Daftar "Sertifikat" tidak memakai `KartuSertifikat` lagi (kini `BarisSertifikat`, baris ringkas lokal di `lib/screens/sertifikat/daftar_sertifikat_bagian.dart`); `KartuSertifikat` tinggal untuk Arsip sampai langkah desainnya. |
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
| `panel_sidik.dart` | `PanelSidik`: satu panel sudut 16, butir dipisah garis halus. Satu butir = satu baris. `padding`: `paddingBaris` (4) atau `paddingIsi` (16); bawaan nol. | `KartuSidik` per butir |
| `baris_sidik.dart` | `BarisSidik` + `tataLetakKompak`: baris min 64 dp, slot angka/judul/keterangan/akhir, kompak di < 340 dp atau huruf > 1,15x, `gayaNomor`. | `KartuPaket`, `KartuSertifikat`, `BarisMenu` |
| `baris_alat.dart` | `BarisAlat`: sisa hari memimpin, nama dan merk paling banyak 2 baris, nomor seri sendiri, jejak tahap bila di lab; belum ada jadwal = satu baris di atas nama. Daftar "Alat saya" tidak memakainya lagi (kini `UbinAlat`). | kartu alat lama |
| `angka_hari.dart` | `AngkaHari` (kolom, kompak, bintang 44) dan `AngkaKata`. | ikon kalender + `Format.sisaHari` |
| `stempel.dart` | `Stempel` (lencana status): tinggi 24, sudut 6, ikon 14 + kata 12/600, tinta GELAP di atas warna MUDA statusnya (tema gelap: pastel di atas latar gelap); `tenang` = tanpa latar; `diAtasUbin` = navy di atas putih untuk lencana di atas ubin berwarna muda. | `ChipStatus` |
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
| `kolom_cari_utuh.dart` | `KolomCariUtuh`: kotak 48 bersudut 10 dengan tombol bulat "Cari" 36 (area ketuk 48), petunjuk membungkus (tidak terpotong "Cari nama, merk, at..."), `aktif` mematikan isian. | `KolomCari` |
| `bagian.dart` | `Bagian`: judul 17/24, jumlah redup, tautan teks 48 dp. | `BagianSidik` |
| `tautan_baris.dart` | `TautanBaris`: tautan teks + panah, 48 dp. | tombol outline lebar |
| `keadaan_teks.dart` | `KeadaanTeks` (rata kiri, tanpa ikon) + `BannerDataTerakhir`. | `KeadaanKosong`, `KeadaanGalat` |

## Komponen bersama gelombang P2 (diselaraskan ke REVISI 16 Nov: tenang, formal, ringkas)

Spesifikasi lama (Bento Lab): `docs/desain-ulang/KOMPONEN.md`, `UKURAN.md`, `GERAK.md`;
bila bertentangan, `docs/desain-ulang/REVISI-16NOV.md` dan `tokens.json` menang. Angka dari
`UkuranKontrol`, `UkuranUbin`, `UkuranVisual`, `UkuranFokus` (`lib/core/tema/ukuran.dart`);
warna dari `ColorScheme` dan `WarnaSidik` (ubin ringkasan berwarna muda dan tinta navy
yang SAMA di terang dan gelap: `StatusTampil.ubin`, `ubinDari`, `diAtasUbin`). Gerak dari
`lib/core/motion/gerak_bento.dart` (`MasukBerurutan`, `TekanSkala`, `VisualMasuk`,
`AngkaNaik`). Tiap komponen: tes di `test/widgets/komponen_bento_test.dart` dan
galeri halaman `bento` di `test/dukungan/galeri_komponen.dart`.

| Berkas | Komponen | Menggantikan |
|---|---|---|
| `tombol_bulat.dart` | `TombolBulat`: `.cari` 36 biru, `.kembali` 48 putih, `.aksi` 52 biru muda/navy, `.hiasan` (tanpa ketukan, untuk di dalam ubin). Label baca wajib, area sentuh 48. | `IconButton`, ikon di app bar |
| `saringan_pil.dart` | `SaringanPil` + `PilihanPil`: saringan 40 bersudut 12, terpilih = biru muda + tepi biru, bulatan jumlah 24 (biru saat terpilih, warna status saat tidak), baris bergulir mendatar. | `SaringanTeks`, `ChoiceChip` |
| `segmen_pil.dart` | `SegmenPil`: wadah 48, penanda biru muda bertepi biru 40 bergeser 240 ms, dua sampai beberapa pilihan. Dipakai tab Sertifikat (Daftar \| Arsip). | `SegmentedButton`, `SaringanTeks` sebagai "Daftar / Arsip" |
| `ubin_alat.dart` | `UbinAlat`: kartu NETRAL 144 (Beranda 160), status hanya di lencana: lencana, nama, merk, nomor seri (IBM Plex Mono), lokasi (hanya bila terisi), angka sisa hari (mono), visual di kanan bawah. `KartuAlat` (`kartu_alat.dart`) tinggal pembungkus tipis `Alat` ke `UbinAlat` untuk daftar "Alat saya". | `BarisAlat`, kartu alat lama |
| `ubin_ringkas.dart` | `UbinRingkas`: ubin pasangan 132 (putih atau warna muda status), judul, kalimat, "Lihat semua". | kartu ringkasan |
| `ubin_menu.dart` | `UbinMenu`: ubin menu 124, judul, penanda bulat 40, visual atau tumpukan avatar. | `BarisMenu` besar |

Pembantu internal di `dasar/` (jangan dipakai layar langsung): `cincin_fokus.dart`
(`CincinFokus`: cincin papan ketik di LUAR isi, 3:1 di dua tema),
`kontrol_ketuk.dart` (`KontrolKetuk`: semantik, area sentuh 48, skala tekan, fokus),
`dasar_ubin.dart` (`DasarUbin`: kerangka ubin, visual keluar tepi dan dipotong).
Saringan dan ubin yang bisa diketuk tidak bersarang: tombol di dalam ubin adalah
penanda (`TombolBulat.hiasan`), bukan tombol kedua.

Catatan a11y: komponen yang bisa diketuk memasang `onTap` pada `Semantics`
pembungkusnya, bukan hanya pada `InkWell`: `excludeSemantics` membuang aksi
ketuk milik `InkWell`, dan tombol berlabel tanpa aksi ketuk tidak bisa
diaktifkan pembaca layar (`KartuSidik` lama memakai pola itu; lihat laporan PR).

## Aksi dan masukan

| Berkas | Komponen |
|---|---|
| `tombol_sidik.dart` | `TombolSidik` (`RagamTombol`: utama, sekunder, teks, bahaya). Satu `utama` per layar. Persegi bersudut 10, tinggi 48; `jumlah` = lencana bulat 28 putih bertinta biru di tombol utama; skala tekan 0,97; cincin fokus papan ketik. |
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
