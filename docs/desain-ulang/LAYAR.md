# LAYAR — susunan per layar (lebar acuan 390, margin 16)

Urutan dari atas ke bawah; angka dalam kurung = jarak ke unsur sebelumnya.
Rujukan markup: `referensi-html/<Nama>.dc.html`.

## 01 Beranda — `lib/screens/beranda/`
1. Kepala T 48: avatar inisial 48 (navy, teks kuning 16/800) · sapaan 12
   `teksKedua` + nama 16/700 · pil perusahaan T 40 putih (ikon 14 + 12/700).
   Pil perusahaan HANYA bila akun punya > 1 perusahaan (aturan lama, tetap).
2. (20) Kalimat utama 32/38/800: frasa status navy, frasa kedua `teksKedua`.
   Tetap dari `KalimatUtama` + `PotonganKalimat`.
3. (20) Ubin alat paling mendesak, T 232 → ke detail alat.
   Bila tidak ada yang perlu perhatian: ubin hijau "Semua alat berlaku".
4. (12) Tombol utama "Lihat semua alat" + lencana jumlah.
5. (12) Panel "Jatuh tempo kalibrasi" (radius 32, padding 18): judul 17/800 +
   "90 hari ke depan" 12 `teksKedua`; (14) kapsul jatuh tempo.
6. (12) Ubin pasangan: Sertifikat terbaru (kuning, visual sertifikat) ·
   Paket dikerjakan (hijau, visual paket). Saat ada data: baris pertama
   menampilkan nomor/nama terbaru, bukan kalimat kosong.
7. (12) Baris bantuan: T 76, radius pil, langit; judul 16/800 + keterangan
   12/500; tombol bulat 52 navy di kanan.
8. Dock.
Tablet (≥ 600): dua kolom seperti sekarang (`Spasi.lebarLebar`), ubin alat +
tombol di kiri, panel + pasangan di kanan.

## 02 Alat saya — `daftar_alat_screen.dart`
Kepala (judul + pil "N alat") → (14) kolom cari → (12) saringan bergulir
[Semua · Lewat jadwal · ≤ 30 hari · …] → (16) daftar ubin alat T 196, jarak 12.
Daftar berhalaman (`daftar_berhalaman.dart`) tetap; kerangka memuat = ubin
abu `latar` radius 32 berdenyut seperti `KerangkaKartu`.

## 03 Sertifikat — `sertifikat_screen.dart`
Kepala → (14) segmen Daftar/Arsip → (12) kolom cari → (12) baris sakelar
"Tampilkan juga yang sudah direvisi" → (16) isi.
Kosong: ubin kosong kuning + visual sertifikat diputar −8°.
Berisi: ubin sertifikat T 132 radius 28 putih: nomor 14/700 `.nomor` → nama
alat 17/800 → tanggal terbit 14/500; stempel keputusan di kanan atas
("Tidak memenuhi toleransi" TIDAK dilunakkan: stempel navy di atas koral).

## 04 Akun — `akun_screen.dart`
Kepala → (14) ubin profil langit T 208: stempel peran (kiri atas), lingkaran
putih 190 keluar sudut kanan atas, avatar 88 navy di dalamnya; nama 28/800 dan
email 14/500 di bawah → (12) panel perusahaan T 88: ubin ikon 48 radius 16 +
"Perusahaan aktif" 12 + nama 17/800 + stempel "PIC utama" hijau →
(24) "Perusahaan": ubin menu ×2 (Pelacakan paket hijau · Anggota kuning) →
(24) "Akun": panel 2 baris menu → (24) "Bantuan": panel 2 baris menu →
(24) tombol utama "Keluar" (ikon di kiri teks, rata tengah) → (4) tombol teks
"Keluar dari semua perangkat" T 48 → (4) versi 12 `teksKedua` tengah → dock.
Label bagian: 14/700 `teksKedua`, margin 4 kiri, 10 ke isi.

## 05 Anggota perusahaan — `anggota_screen.dart`
Kepala anak → (16) ubin navy: nama PT 14/700 + pil kuning "N kursi tersisa" →
(18) angka sorot 64 + "dari 50 anggota aktif" 16/600 `navyTeks` → (18) titik
kursi → (24) "Anggota aktif": panel radius 28 padding 16 per anggota: avatar 56
langit, nama 16/800 "(Anda)" 500, peran 14, email 14, stempel "PIC utama" →
(24) "Undangan menunggu": ubin kuning radius 28 padding 18: ikon bulat 48 navy
+ email 16/800 + "Diundang sebagai …" 14/500; garis putus navy 2; "Berlaku
sampai …" 14/700 + pil putih "N hari lagi".

## 06 Pelacakan paket — `paket_screen.dart`
Kepala anak → (16) kolom cari → (12) segmen Berjalan/Selesai → (16) isi.
Kosong: ubin kosong hijau T 470 + jejak tahap kosong + visual paket 270.
Berisi: ubin paket putih radius 28: nomor order (`NomorSidik`) → `JejakTahap`
asli → "N dari M alat selesai" (`TikPaket`) → stempel tahap dari server.

## 07 Kalibrasi (teknisi) — repo Lab, `kalibrasi_teknisi_screen.dart`
Kepala: judul 28/800 + tombol bulat 48 putih notifikasi dengan lencana koral.
(14) ubin navy T 132 "Mulai kalibrasi" 28/800 + "Lembar kerja baru" 12
`navyTeks`; meter setengah lingkaran (tik kuning/`navyLembut`, jarum putih) di
kanan. (22) "Draf" + lencana → deret mendatar kartu draf 196 × 132, jarak 10.
(22) "Terkirim terakhir" + lencana → panel baris daftar T 72.
Dock 2 butir, keduanya berlabel.
Catatan: repo Lab punya tema sendiri (`palet_lab.dart`, `bentuk_lab.dart`) dan
aturan sel angka radius 8. Hanya layar ini yang ikut Bento; lembar kerja dan
layar angka TIDAK diubah.

## Keadaan yang wajib ada di tiap layar
memuat (kerangka), kosong (ubin kosong), galat (`KeadaanGalat` + "Coba lagi"),
luring (banner yang ada), huruf sistem 1,3×, lebar 320 dp, tablet ≥ 600 dp.
