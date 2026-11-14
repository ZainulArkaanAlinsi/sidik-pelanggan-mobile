# Kebutuhan API untuk aplikasi pelanggan

Ditulis 12 Nov 2026 (tugas P-1/P-4/P-5). Semua rujukan di bawah ada di **repo
API** (`sidik-calibration-api`), bukan di repo ini: `routes/api_pelanggan.php`
pada `origin/main` (`006f1b68`), `docs/kontrak-api-pelanggan.md` §3 dan §6, dan
keputusan pemilik 20 Okt 2026 di `docs/permintaan-user-7.md` §53.

Aplikasi tidak memanggil apa pun yang tidak ada di `routes/api_pelanggan.php`.
Bagian 3 dan 4 adalah yang BELUM ada di server; isinya usulan, bukan kontrak.

## 1. Rute yang sekarang punya layar

| Rute | Layar | Catatan |
|---|---|---|
| `POST /saya/ganti-sandi` | Akun > Ganti sandi | `sandi_lama_salah` ditampilkan di kolomnya; sesi di HP ini tetap hidup |
| `GET`/`PUT /preferensi-notifikasi` | Akun > Pengaturan notifikasi | Empat saklar yang masih punya pengirim (termasuk `tahap_alat`); `pesan_lab` tidak ditampilkan (lihat 4.b dan 7) |
| `GET /anggota` | Akun > Anggota perusahaan | Semua peran. Telepon rekan tidak dibaca; daftar undangan hanya dirender untuk PIC utama |
| `POST /anggota/{id}/nonaktifkan` | tombol di layar yang sama | Hanya tampil bila `data.saya.peran = pic_utama`, tidak untuk baris milik sendiri |
| `GET /paket`, `GET /paket/{id}` | Akun > Pelacakan paket | Hanya baca. `?q=` nomor order dan `?selesai=1` dipakai |

Semua 404 (data perusahaan lain atau tidak ada) ditampilkan sebagai satu kalimat
umum; tidak ada layar yang mengatakan "akses ditolak".

## 2. Rute ada dan diizinkan keputusan §53, tapi belum ada layarnya

Tidak diminta pada tugas ini, jadi tidak dibangun dan TIDAK masuk allow-list
`test/guard_tulis_test.dart`. Masukkan ke allow-list bersamaan dengan layarnya.

- `PATCH /saya` (ubah nama, telepon, jabatan) dan `DELETE /saya` (hapus akun).
  Hapus akun saat ini lewat tautan `dokumen.hapus_akun_url` di Bantuan.
- `POST /anggota/undangan` dan `DELETE /anggota/undangan/{id}` (PIC utama
  mengundang / membatalkan). Layar Anggota sudah menampilkan undangan yang menunggu.

## 3. BUTUH API: penanda "akun sudah ada" pada terima-undangan

Masalah: `POST /auth/terima-undangan` untuk email yang sudah punya akun
menambahkan perusahaan ke akun lama dan membalas 201 biasa, dengan `nama` dan
`sandi` isian diabaikan (kontrak §1). Aplikasi tidak punya penanda dan hanya
menebak dari jawabannya: lebih dari satu keanggotaan, atau nama di jawaban
berbeda dari yang diketik (`tampakAkunLama` di `lib/services/layanan_pelanggan.dart`).
Akun lama yang kebetulan bernama sama dan baru punya satu perusahaan tidak
terdeteksi, jadi penggunanya tidak diberi tahu bahwa sandi barunya tidak dipakai.

Usulan (additive, tidak merusak v1): tambahkan `data.akun_sudah_ada: true|false`
pada balasan 201 `terima-undangan`, di sebelah `token`/`user`. Setelah ada,
`tampakAkunLama` diganti membaca field itu. Tidak perlu `nama` akun lama atau
perusahaan lain di balasan.

## 4. BUTUH API / KEPUTUSAN

### a. Order atau permintaan kalibrasi dari pelanggan

Tidak ada rute. `/permintaan*`, `/koreksi*`, dan `/foto*` dicabut (K-50-09,
15-16 Okt 2026) dan aplikasi pelanggan diputuskan hanya membaca. `GET /paket`
hanya melacak order yang dibuat lab. Aplikasi tidak membuat order dan tidak
mengarang endpoint untuk itu.

Kalau pemilik membalik K-50-09, yang dibutuhkan (usulan, belum ada):

- Keputusan tertulis pemilik yang membalik K-50-09 (cabang baru di
  `PengecualianTulisPelangganTest` dan `test/guard_tulis_test.dart` ikut berubah
  oleh keputusan itu, bukan sebaliknya).
- Satu rute buat, mis. `POST /permintaan`, di `routes/api_pelanggan.php`, grup
  `pelanggan.aktif` + `perusahaan`. Isi: daftar `alat_id` (milik perusahaan
  aktif), tanggal rencana serah, catatan. `customer_id` dari `Konteks`, bukan body.
  `alat_id` milik perusahaan lain dijawab 404, bukan 403 atau 422 yang
  membedakan "tidak ada" dari "bukan milikmu".
- Status penerimaan lab (diterima/ditolak + alasan untuk pelanggan) dan
  hubungannya ke `GET /paket`, supaya satu tempat pelacakan.
- Throttle sendiri, audit (pelaku, waktu), kasus di `IsolasiPerusahaanTest`,
  migrasi additive, dan `kode` galat bernama di tabel kontrak §0.

### b. Saklar `pesan_lab`

`GET /preferensi-notifikasi` masih mengirim `pesan_lab`, tetapi tidak ada
pengirim yang memakainya sejak permintaan dicabut (`grep PESAN_LAB app/` hanya
menemukan konstantanya). Aplikasi menyembunyikannya. Mohon dikonfirmasi:
dihapus dari respons (perubahan v2) atau dibiarkan sebagai nilai tersimpan.
Label saklar `status_permintaan` di aplikasi ditulis "Sertifikat terbit" karena
sekarang itu satu-satunya isinya (kontrak §8).

### c. Penjadwal ringkasan mingguan

Saklar `ringkasan_email_mingguan` ditampilkan karena `RingkasanMingguan` dan
`Schedule::command('pelanggan:ringkasan-mingguan')->weeklyOn(1, '07:15')` ada di
kode. Apakah scheduler dan mailer di produksi benar-benar berjalan tidak
diverifikasi dari sisi aplikasi.

### d. `GET /anggota`: batasi data yang dikirim ke staf

Dua hal di sisi server yang sekarang dikirim ke SEMUA peran:

1. `data.undangan_menunggu` (email orang yang sedang diundang) — dibangun di
   `AnggotaController::index` (sekitar baris 70-86) tanpa melihat peran
   pemanggil. Usulan: kirim hanya bila pemanggil `pic_utama`; untuk staf kosongkan
   atau hilangkan. Aplikasi sudah membuangnya sendiri untuk staf
   (`DaftarAnggota.dariJson`), tapi datanya tetap sampai ke HP.
2. `orang.telepon` rekan di `AnggotaResource` (sekitar baris 34). Aplikasi tidak
   membaca atau menampilkannya. Perlu keputusan: tetap dikirim (kontrak §3
   menyebut hanya email yang memang untuk saling menghubungi) atau dibuang dari
   resource. Usulan: buang, karena tidak ada layar yang memerlukannya.

Keduanya perubahan additive/penyempit pada data, bukan pada bentuk; periksa
`KontrakResponsPelangganTest` dan fixture `tests/Fixtures/pelanggan/anggota.json`.

## 5. Beranda ringkasan, status alat, riwayat, pratinjau PDF (12 Nov 2026)

Fitur 1–4 rencana §14.1 dibangun **tanpa rute baru**: hanya memakai
`GET /beranda`, `GET /alat` (daftar dan `{id}`), `GET /sertifikat/{id}`, dan
`GET /sertifikat/{id}/unduh`. Dua hal dihitung di aplikasi karena server belum
mengirimnya; keduanya usulan additive (tidak merusak v1).

### a. Hitungan alat jatuh tempo 31–60 dan 61–90 hari

Server hanya punya `ringkasan.lewat_jatuh_tempo` dan `ringkasan.segera_jatuh_tempo`
(0–30 hari, `meta.jendela_segera_hari`) dan saringan `GET /alat?saring=segera|lewat`.
Beranda butuh kotak 30/60/90 hari. Untuk 31–60 dan 61–90 hari aplikasi sekarang
menarik `GET /alat?per_page=100` (halaman 1, lanjut hanya bila halaman itu masih
punya alat dalam jendela 90 hari, paling banyak 10 halaman) dan mengelompokkan
dari `hari_ke_jatuh_tempo` kiriman server, setiap Beranda dibuka atau ditarik.
Aman untuk 51 alat; boros untuk perusahaan dengan ratusan alat.

Usulan: tambahkan ke `data.ringkasan` di `GET /beranda`
`jatuh_tempo_31_60` dan `jatuh_tempo_61_90` (hitungan eksklusif, alat aktif
dengan status dinilai seperti `segera_jatuh_tempo`), dan terima
`saring=hari_60` / `saring=hari_90` pada `GET /alat` supaya daftarnya juga
disaring server. Setelah ada, `alatMenujuJatuhTempo` dan `jatuhTempoProvider`
di aplikasi dihapus.

### b. Status masa berlaku sertifikat

Resource sertifikat hanya mengirim `status` dokumen (`berlaku|digantikan|dibatalkan`)
dan `berlaku_sampai`. Garis waktu riwayat per alat perlu "Berlaku / Segera jatuh
tempo / Masa berlaku berakhir" per sertifikat, jadi aplikasi menghitungnya
(`StatusBerlaku.dariSertifikat`, jendela "segera" 30 hari tetap).

"Hari ini" untuk hitungan itu BUKAN jam HP (BR-08 mewajibkan hari ini
Asia/Jakarta; jam HP yang mundur membuat sertifikat lewat tampil "Berlaku").
Aplikasi memakai jangkar dari server di payload `GET /alat/{id}`:
`tanggal_jatuh_tempo` dikurangi `hari_ke_jatuh_tempo` = tanggal "hari ini"
menurut server saat data dikirim (`Alat.hariIniServer`). Jam HP hanya cadangan
untuk alat tanpa jadwal jatuh tempo (payload tidak membawa jangkar). Data dari
cache offline membawa jangkar hari ia diambil, sama dengan sisa hari yang
ditampilkan di sebelahnya.

Usulan (tanpa mengubah API sekarang): tambahkan `status_masa_berlaku`
(`berlaku|segera|berakhir`) dan `hari_ke_berlaku_sampai` pada
`SertifikatPelangganResource`, dihitung server dengan jendela yang sama dengan
`status_alat` (`PengingatJatuhTempoPelanggan::TANGGA_HARI[0]`). Setelah ada,
hitungan di aplikasi dan jangkar di atas dihapus, termasuk untuk alat tanpa
jadwal.

### c. Istilah: "Kedaluwarsa" DITAHAN (keputusan K3 masih terbuka)

Rencana §14.1 menyebut status "kedaluwarsa". Itu bertabrakan dengan keputusan K3
yang masih terbuka di repo API: `docs/pelanggan/02-SRS.md` BR-09,
`docs/pelanggan/00-BACA-DULU.md` (baris 50 dan 62), dan risiko R-F02. ISO/IEC
17025 §7.8.4.3 melarang sertifikat atau label memuat rekomendasi interval
kalibrasi ulang kecuali disepakati dengan pelanggan; "kedaluwarsa" terbaca
sebagai lab menyatakan sertifikat tidak berlaku lagi. Di aplikasi pelanggan yang
ada adalah "jadwal kalibrasi ulang / jatuh tempo" (tanggal yang ditentukan
admin), dan kata "kadaluarsa" tidak dipakai.

Keputusan sementara (default aman, sampai K3 dijawab):

| Untuk | Kata di layar | Asal |
|---|---|---|
| Alat yang jadwalnya lewat | **Lewat jadwal** | sama dengan kode server `lewat_jadwal` |
| Sertifikat yang tanggalnya lewat | **Masa berlaku berakhir** | `StatusBerlaku.berakhir` |

Semua kata status ditulis di SATU tempat, `StatusBerlaku.label`
(`lib/models/status_berlaku.dart`); lencana, chip, kotak ringkasan, dan teks
kosong membacanya dari sana (`FilterAlat.label` hanya menambah rentang hari).
Bila K3 memutuskan lain, ubah string itu saja. `test/beranda_ringkasan_test.dart`
dan `test/alat_status_riwayat_test.dart` menjaga agar kata "kedaluwarsa" tidak
muncul di layar.

### d. Pratinjau PDF dicatat sebagai unduhan

Pratinjau di aplikasi memanggil `GET /sertifikat/{id}/unduh` (pratinjau diunduh
ulang tiap dibuka supaya sertifikat yang baru dibatalkan tidak tampil dari
salinan lama). Server mencatatnya sebagai aksi audit `ACTION_DIUNDUH_PELANGGAN` ("Diunduh dari
aplikasi pelanggan") dan membatasi 30 permintaan/menit/pengguna
(`pelanggan-unduh`). Bila lab perlu membedakan melihat dari mengunduh, butuh
parameter (mis. `?tujuan=pratinjau`) dan aksi audit terpisah.

### e. Riwayat per alat dibatasi 50

`GET /alat/{id}` mengirim paling banyak 50 sertifikat di `riwayat_sertifikat`
dan aplikasi menampilkan semuanya. Belum ada saringan alat di `GET /sertifikat`;
bila ada alat dengan lebih dari 50 sertifikat, butuh `GET /sertifikat?alat_id=`.
Tidak mendesak: data produksi saat ini 48 pelanggan dengan 51 alat seluruhnya.

### f. Dicatat, belum dikerjakan (hasil tinjauan 12 Nov 2026)

- **Audit tiap pratinjau** (butir d): usulan server `?tujuan=pratinjau` dengan
  aksi audit terpisah dari unduhan.
- **Paging hitungan 31–90 hari** (butir a): `alatMenujuJatuhTempo` membaca paling
  banyak 10 halaman × 100 = 1000 alat; perusahaan dengan lebih banyak alat
  terhitung kurang. Penyelesaiannya hitungan di server (butir a), bukan
  menaikkan batas di aplikasi.
- **`Content-Type` unduhan PDF**: aplikasi menerima `application/pdf` dan jenis
  biner umum (`application/octet-stream`, `binary/octet-stream`) selama isinya
  diawali `%PDF-`; jenis lain ditolak. Bila server memastikan selalu mengirim
  `application/pdf` (disk `arsip` S3 tanpa metadata bisa mengirim octet-stream),
  pelonggaran ini bisa dicabut di `ApiPelanggan._jenisBolehPdf`.

## 6. Arsip sertifikat (13 Nov 2026)

Arsip (`GET /sertifikat/garis-waktu`) dan pencariannya sudah punya layar:
segmen "Arsip" di tab Sertifikat.

### a. "Satu sertifikat per instrumen": diterima apa adanya, terbuka untuk "terbaru per serial"

Keputusan: perilaku server sekarang diterima. Revisi yang sudah digantikan
disembunyikan (bawaan, sama dengan daftar Sertifikat); siklus kalibrasi yang
berbeda pada nomor seri yang sama tampil masing-masing menurut tanggal
terbitnya. Itu riwayat yang benar, bukan duplikat. Aplikasi TIDAK mengelompokkan
atau menyaring per nomor seri (hitungan adalah tampilan server).

Terbuka: bila pemilik kelak meminta "hanya yang terbaru per nomor seri", itu
butuh parameter di server (mis. `?terbaru_per_serial=1`) pada garis waktu dan
daftar sertifikat; sisi aplikasi cukup meneruskannya.

### b. Pencarian Arsip = daftar datar lewat `GET /sertifikat?q=`

Kolom cari di Arsip (minimal 2 karakter, jeda ketik 350 ms, maksimal 100
karakter) memakai daftar sertifikat biasa, bukan `?q=` garis waktu, supaya
hasilnya satu daftar datar dengan satu permintaan. Kata kosong kembali ke garis
waktu. Hal yang perlu diketahui:

- `GET /sertifikat?q=` mencocokkan SECARA HARFIAH (bukan format-agnostik):
  `cal-2026-10-0001` tidak menemukan `CAL/2026/10/0001`. Pencocokan yang
  menyamakan format hanya ada di `?q=` garis waktu (kontrak §4).
- Cakupan `q` di `GET /sertifikat` tidak tertulis di kontrak Arsip & Pencarian
  (hanya "tidak diubah"). Kode `SertifikatController::index` pada branch
  `feat/arsip-cari-terpadu-20261112` mencocokkan nomor sertifikat, nama alat,
  nomor seri TERDAFTAR, dan nomor order (`calibration_sessions.nomor_order`
  serta `orders.nomor`); di `main` API belum ada nomor order. Nomor seri yang
  hanya diketik teknisi di lembar kerja tidak tercakup di jalur ini.
- Baris `GET /sertifikat` tidak memuat `nomor_order`, jadi kartu hasil tidak
  menunjukkan order yang cocok.
- **Permintaan ke API (pekerjaan terpisah, belum dikerjakan): normalisasi `q`
  di `GET /sertifikat?q=`**, seperti `?q=` garis waktu: huruf besar-kecil, `/`,
  `-`, dan spasi diabaikan (`CAL-2026-10-0001` = `CAL/2026/10/0001`), dan nomor
  seri yang diketik teknisi ikut dicocokkan. Sampai itu ada, keputusan produk:
  pencarian tetap harfiah dan aplikasi jujur soal itu. Petunjuk di bawah kolom
  cari ("Tulis nomor persis seperti di sertifikat.") dan keadaan "Tidak ada yang
  cocok" menyebutnya, dan keadaan kosong juga memberi tahu bahwa sertifikat yang
  sudah direvisi ada di Daftar lewat sakelar "Tampilkan juga yang sudah
  direvisi" (hasil cari Arsip tidak menyertakan revisi lama).
- Penelusuran garis waktu memang tetap tanpa kata cari di aplikasi; bila
  kelak butuh "persempit hitungan per periode", `?q=` garis waktu sudah ada
  di server.

## 7. Saklar notifikasi (14 Nov 2026)

Layar Pengaturan notifikasi memakai `GET` dan `PUT /preferensi-notifikasi`
(kontrak §14.4): satu `PUT` sebagian per saklar, sebanyak satu permintaan
berjalan per kunci. Dua kunci berbeda bisa terkirim bersamaan.

- **Permintaan ke API (tindak lanjut additive, belum dikerjakan): upsert di
  `PreferensiNotifikasi::simpan`.** Sekarang `firstOrNew` + `save()` tanpa
  transaksi, dengan `unique(customer_member_id)` di tabelnya. Pada tulis
  PERTAMA seorang anggota yang mengetuk dua saklar dalam satu waktu tempuh,
  kedua `PUT` bisa sama-sama melihat "belum ada baris" dan sama-sama `INSERT`;
  yang kalah mendapat 500. Aplikasi menjawabnya dengan benar (saklar itu
  dikembalikan dan tertulis "Belum tersimpan", bisa diketuk lagi), tetapi 500 itu
  tidak perlu ada: `updateOrCreate` atau `upsert` menutupnya. Baris yang sudah
  ada tidak terpengaruh.
- 403 di rute ini hanya `akun_belum_diverifikasi` (`PelangganAktif`); anggota
  yang dinonaktifkan atau header perusahaan yang salah dijawab 404
  (`KonteksPerusahaan`). Aplikasi menerjemahkan 403 sebagai "hanya bisa dibaca,
  hubungi PT Sidik" dan 404 sebagai kegagalan simpan biasa.
- Tautan notifikasi `pelanggan_paket` (kontrak §14.4) kini dipetakan
  (`lib/screens/tautan.dart`) ke detail paket `GET /paket/{id}`, dipakai bersama
  oleh ketukan baris kotak masuk dan ketukan push.
- Cache `GET /preferensi-notifikasi` ditulis ulang aplikasi sesudah tiap simpan
  yang dikonfirmasi server (keadaan lokal, bukan jawaban `PUT`: jawaban untuk
  satu kunci bisa tiba sesudah jawaban kunci lain dan membawa nilai usang).
