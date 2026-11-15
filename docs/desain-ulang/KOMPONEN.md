# KOMPONEN — ukuran dan padanan kode

Semua dp. "L" = lebar, "T" = tinggi. Tinggi ubin = minimum, boleh tumbuh.
Nama berkas mengikuti kebiasaan `lib/widgets/` (bahasa Indonesia, satu
tanggung jawab per berkas). Tiap komponen baru: tes widget + masuk galeri render.

## Aksi dan masukan
| Komponen | Ukuran | Gaya | Di kode |
|---|---|---|---|
| Tombol utama | L penuh × T 56, radius pil, padding 22 kiri / 8 kanan | navy, teks putih 16/700; lencana jumlah opsional: bulat 40 kuning, 16/800 | `TombolSidik(ragam: utama)` diubah gayanya |
| Tombol sekunder | T 48, radius pil, padding 0 20 | putih + garis 1 `garis`, teks navy 16/700 | `TombolSidik(ragam: sekunder)` |
| Tombol teks | T 48 | navy 14/700 bergaris bawah | `TautanBaris` |
| Tombol bulat | 44 / 48 / 52 | 44 navy (cari), 48 putih (kembali), 52 kuning/navy (aksi ubin); ikon 20–22 | BARU `tombol_bulat.dart` |
| Kolom cari | L penuh × T 56, radius pil, padding 20 kiri / 6 kanan | putih, petunjuk 14/400 `teksKedua`, tombol bulat 44 navy di kanan | `KolomCariUtuh` diubah gayanya (jeda ketik 350 ms tetap) |
| Saringan | T 44, radius 22, padding 16 kiri / 6 kanan, jarak 8 | aktif: navy + teks putih, jumlah bulat 32 kuning; tidak aktif: putih, jumlah 32 berwarna status / `latar` | `SaringanTeks` → BARU `saringan_pil.dart`; baris bergulir mendatar |
| Segmen (2 pilihan) | luar T 56 padding 6 radius pil; dalam T 44 radius 22 | luar putih; terpilih navy + putih 14/700; pil bergeser 240 ms | BARU `segmen_pil.dart` |
| Sakelar | 56 × 36, tombol 28, padding 4; barisnya T 56 radius pil | mati: rel `latar`, tombol `teksKedua`; nyala: rel navy, tombol kuning | tema `SwitchThemeData` |

## Status
| Komponen | Ukuran | Gaya | Di kode |
|---|---|---|---|
| Stempel | T 30, radius 15, padding 0 12, ikon 14, jarak 6, 12/700 | latar = warna status, tinta navy. Di ATAS ubin berwarna: navy+putih (gagal) atau putih+navy (lulus) | `Stempel` (ganti bentuk persegi → pil); `pemetaan_status.dart` tidak berubah |
| Lencana jumlah | bulat min 24–26, 12/800 | kuning atau putih | `Badge` bertema |

Aturan "normal diam, pengecualian bersuara" DILONGGARKAN: di ubin alat status
selalu tampil (ubin sudah berwarna, stempel menyebut katanya). Di baris daftar
padat (teknisi) tetap satu stempel per baris.

## Ubin
| Komponen | Ukuran | Isi | Di kode |
|---|---|---|---|
| Ubin alat | L penuh × T 196 (Beranda 232), radius 32, padding 18 | stempel (atas kiri) → nama 22/28/800 (maks 2 baris) → merk+tipe 14/500 → nomor seri 14/500 `.nomor` (baris sendiri) → [dorong ke bawah] angka 44/800 (Beranda 64) + "hari terlewat"/"hari lagi" 12/700 + tanggal 12/500. Visual 160 (Beranda 176) di kanan bawah, keluar 10–20 dari tepi, dipotong radius ubin | BARU `ubin_alat.dart`, menggantikan `BarisAlat`/`KartuAlat` di Beranda dan daftar |
| Ubin pasangan | 2 kolom, jarak 12, T 188, radius 28, padding 16 | judul 17/800 → kalimat 12–14/500 → [bawah] "Lihat semua" 12/800 bergaris bawah; visual 112 kanan bawah | BARU `ubin_ringkas.dart` |
| Ubin menu | 2 kolom, T 140, radius 28, padding 16 | judul 17/800 (maks 2 baris, L maks ±100) + tombol bulat 40 navy kiri bawah + visual 100 / tumpukan avatar 40 kanan bawah | BARU `ubin_menu.dart` |
| Ubin kosong | L penuh × T ≥ 420, radius 32, padding 22 | judul 28/800 (L maks 220–260) + kalimat 14/20/500 (L maks 250) + visual 270–280 kanan bawah | `KeadaanKosong` diubah; `KeadaanTeks` tetap untuk galat |
| Panel | radius 28, putih, padding 6 (berisi baris) atau 18–20 | — | `PanelSidik` (radius 16 → 28) |
| Ubin navy | radius 32, padding 20, teks putih, teks kedua `navyTeks` | kapasitas anggota, "Mulai kalibrasi" | `PanelSidik(nada: navy)` |

Warna ubin alat dari status: gagal → koral, awas → kuning, lulus → hijau,
tunggu (di lab) → langit, tanpa jadwal → putih.

## Baris
| Komponen | Ukuran | Di kode |
|---|---|---|
| Baris menu | T 64, padding 0 10, ubin ikon bulat 44 (warna pastel), jarak 14, label 16/700, panah 20 `teksKedua`; pemisah 1 dp `latar` mulai x 68 | `BarisMenu`/`BarisSidik` |
| Baris daftar (teknisi) | T min 72, judul 16/800, nomor 12/700 `.nomor`, stempel di kanan | `BarisSidik` |
| Kartu draf (teknisi) | 196 × 132, radius 26, padding 16: nomor 12/700 → nama 16/20/800 (maks 2 baris) → [bawah] perusahaan 12, satu baris terpotong | di repo Lab |
| Kepala layar tab | T 48: judul 28/800 kiri, opsional pil putih T 36 di kanan | `HalamanSidik` |
| Kepala layar anak | T 48: tombol bulat 48 putih (kembali) + jarak 12 + judul 20/800 | `HalamanSidik` |

## Grafik
**Kapsul jatuh tempo** (ganti `PetaJatuhTempo` di Beranda): 4 kolom, jarak 8.
Rel T 124 radius 22 warna `latar`; isi menempel bawah, radius 22.
Tinggi isi = 44 + 80 × (nilai ÷ nilai terbesar); nilai 0 → 44. Bila hanya satu
kolom bernilai > 0, isinya 88 (bukan 124) supaya angka tetap di dalam kapsul.
Angka di dalam isi: 28/800 (nilai > 0, rata atas, padding atas 12) atau 17/800
(nilai 0, tengah). Warna isi: lewat jadwal koral, ≤30 kuning, 31–60 langit,
61–90 hijau. Label di bawah rel, jarak 8, 12/700 (kolom bernilai) atau 12/400
`teksKedua`. Tiap kolom tetap bisa diketuk (zona) seperti `ZonaTempo`.

**Titik kursi** (Anggota): 2 baris × 25 titik, diameter 9, jarak pusat 12,83,
jarak baris 22; terisi kuning, kosong `navyLembut`. Di atas 50 kursi ganti ke
batang bersegmen (sama seperti aturan `TikPaket`).

**Jejak tahap kosong** (Paket kosong): 4 simpul bulat 16 putih bergaris navy 2,
dihubungkan garis putus 3/7. Hanya hiasan keadaan kosong; jejak tahap asli
tetap dari `garis_waktu` server (jumlah simpul tidak dikeraskan).

## Dock navigasi (`NavigasiUtama`, hanya < 600 dp)
T 64, radius 36, padding 8, jarak 4, navy, bayangan (0,16,32, navy 28%).
Dipusatkan mendatar, melayang 16 dp di atas tepi sistem
(`MediaQuery.paddingOf(context).bottom + 16`). Butir 48 × 48, ikon 22 putih,
garis 1,8. Butir aktif: pil kuning T 48, padding 0 16, ikon 20 + label 14/800
navy; pil bergeser 240 ms. Butir tidak aktif tanpa label tetapi wajib
`Semantics(label:)` + tooltip. Lencana notifikasi: `Badge` koral di butir.
Isi layar diberi padding bawah 64 + 16 + 16 supaya tidak tertutup dock.
≥ 600 dp: rel samping yang ada, hanya ganti warna.

## Visual alat (`VisualAlat`)
Sumber: `aset/visual/*.svg`, kanvas 240 × 240, cahaya kiri atas, bayangan
lantai lonjong, tanpa merek. Tanpa paket baru, jadi pilih salah satu:
(a) ekspor PNG transparan 1×/2×/3× ke `assets/images/visual/` (paling cepat), atau
(b) gambar ulang dengan `CustomPainter`.
`VisualAlat(jenis)` memetakan jenis alat → aset; jenis tak dikenal → tidak
menggambar apa-apa (ubin polos). `ExcludeSemantics`: murni dekoratif.
Ukuran: 176 (ubin Beranda), 160 (ubin alat), 112 (ubin pasangan), 100 (ubin
menu), 270–280 (keadaan kosong).
