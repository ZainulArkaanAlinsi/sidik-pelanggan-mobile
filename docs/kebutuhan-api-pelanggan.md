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
| `GET`/`PUT /preferensi-notifikasi` | Akun > Pengaturan notifikasi | Hanya tiga saklar yang masih punya pengirim; `pesan_lab` tidak ditampilkan (lihat 4.b) |
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
