# lib/widgets — komponen bersama

Satu tanggung jawab per berkas. Layar di `lib/screens/` merakit komponen ini;
gaya (warna, spasi, huruf) datang dari token di `lib/core/tema`, bukan ditulis
ulang di sini. Lihat `lib/core/tema/README.md`.

## Kerangka dan tata letak

| Berkas | Komponen |
|---|---|
| `halaman_sidik.dart` | `HalamanSidik`: Scaffold + AppBar bertema + isi dipusatkan. Dipakai semua layar. |
| `konten_tengah.dart` | `KontenTengah`: isi dibatasi ±720 dp dan dipusatkan di layar lebar. |
| `kolom_formulir.dart` | `KolomFormulir`: kolom sempit (440 dp) bergulir untuk Sambutan, Masuk, dan layar keadaan penuh. |
| `navigasi_utama.dart` | `NavigasiUtama` + `TujuanNavigasi`: navigasi bawah di HP, rel samping di >= 600 dp (`LayoutBuilder`, tanpa paket). |
| `bagian_sidik.dart` | `BagianSidik` (judul bagian) dan `AksiBagian` ("Lihat semua"). |

## Isi

| Berkas | Komponen |
|---|---|
| `kartu_sidik.dart` | `KartuSidik`: kartu datar; diketuk = ripple standar. |
| `kartu_kpi.dart` | `KartuKpi`: angka ringkasan (ikon, angka, label). |
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
