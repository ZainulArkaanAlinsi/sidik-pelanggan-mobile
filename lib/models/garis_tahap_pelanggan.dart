import 'paket.dart';

/// Urutan tahap yang DILIHAT pelanggan, dari paling awal ke paling akhir.
///
/// SALINAN KLIEN dari `TahapPaket::garisWaktu($tahap, true)` di API (commit
/// `d8dc320a`): "Alat diterima lab", "Sedang dikalibrasi", "Hasil sedang
/// diperiksa" (pengesahan sudah dilipat ke sini), "Sertifikat sudah terbit",
/// "Siap diambil", "Sudah diserahkan". `perlu_diulang` ("Sedang dikerjakan
/// ulang") TIDAK ada di sini: server menyisipkannya hanya saat sedang terjadi
/// (lihat [garisWaktuPelanggan]).
const _urutanPelanggan = <String>[
  'diterima',
  'dikalibrasi',
  'menunggu_pemeriksaan',
  'sertifikat_terbit',
  'siap_diambil',
  'diserahkan',
];

/// Garis waktu untuk `JejakTahap` pada layar yang datanya TIDAK membawa
/// `garis_waktu`: `GET /beranda` dan `GET /alat` hanya mengirim `tahap` dan
/// `tahap_label` per alat (`sedang_dikerjakan`), sedangkan `garis_waktu`
/// hanya ada di `GET /paket/{id}`.
///
/// Ini jalan keluar sementara, bukan sumber kebenaran: server memegang urutan
/// tahap (`TahapPaket::URUTAN`), dan salinan ini harus ikut bila server
/// menambah tahap. Penggantinya: server mengirim `garis_waktu`/`posisi` per
/// alat (A5 di brief desain). Tiga pengaman supaya salinan yang basi tidak
/// menyesatkan:
///
/// - jumlah tik = panjang daftar ini (tidak ada angka 6 di kode lain);
/// - kode yang tidak dikenal TIDAK mendapat tik "sekarang" (`posisiTahap`
///   menghasilkan `null`): hanya kata dari server yang tampil, tanpa
///   karangan;
/// - label langkah tidak dipakai `JejakTahap` (hanya kata dari server), jadi
///   salinan ini tidak membawa teks pelanggan sendiri.
///
/// Aturan sama dengan server: `menunggu_pengesahan` dilipat ke
/// `menunggu_pemeriksaan`; `perlu_diulang` disisipkan sesudah `dikalibrasi`
/// hanya bila itu tahap sekarang (jadi 7 tik, bukan 6); tahap sebelum yang
/// sekarang `lewat`, yang sekarang `sekarang`.
List<LangkahPaket> garisWaktuPelanggan(String? kodeSekarang) {
  var kode = kodeSekarang ?? '';
  if (kode == 'menunggu_pengesahan') kode = 'menunggu_pemeriksaan';
  final urutan = [
    for (final k in _urutanPelanggan) ...[
      k,
      if (k == 'dikalibrasi' && kode == 'perlu_diulang') 'perlu_diulang',
    ],
  ];
  final posisi = urutan.indexOf(kode);
  return [
    for (var i = 0; i < urutan.length; i++)
      LangkahPaket(
        kode: urutan[i],
        // Tidak dipakai `JejakTahap`; kode saja, bukan teks karangan.
        label: urutan[i],
        lewat: posisi >= 0 && i < posisi,
        sekarang: i == posisi,
      ),
  ];
}
