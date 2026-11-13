// Data sintetis untuk tes dan harness komponen bersama. Tidak ada pelanggan,
// alat, nomor, atau orang nyata.
import 'package:sidik_pelanggan/models/paket.dart';

/// Kode dan label tahap seperti `garis_waktu` versi pelanggan dari server
/// (`TahapPaket::garisWaktu`): enam langkah.
const urutanTahapUji = <(String, String)>[
  ('diterima', 'Alat diterima lab'),
  ('dikalibrasi', 'Sedang dikalibrasi'),
  ('menunggu_pemeriksaan', 'Hasil sedang diperiksa'),
  ('sertifikat_terbit', 'Sertifikat sudah terbit'),
  ('siap_diambil', 'Siap diambil'),
  ('diserahkan', 'Sudah diserahkan'),
];

/// `garis_waktu` dengan tahap [sekarang] (indeks) ditandai; yang sebelumnya
/// `lewat`. [tambahUlang] menyisipkan "Sedang dikerjakan ulang" (tujuh langkah)
/// seperti server saat alat dikerjakan ulang.
List<LangkahPaket> garisWaktuUji({int sekarang = 1, bool tambahUlang = false}) {
  final daftar = [...urutanTahapUji];
  if (tambahUlang) {
    daftar.insert(2, ('perlu_diulang', 'Sedang dikerjakan ulang'));
  }
  return [
    for (final (i, (kode, label)) in daftar.indexed)
      LangkahPaket(
        kode: kode,
        label: label,
        lewat: i < sekarang,
        sekarang: i == sekarang,
      ),
  ];
}

/// Garis waktu dengan [n] langkah generik (untuk membuktikan jumlah tik
/// mengikuti server, bukan angka 6).
List<LangkahPaket> garisWaktuSepanjang(int n, {int sekarang = 0}) => [
  for (var i = 0; i < n; i++)
    LangkahPaket(
      kode: 'tahap_$i',
      label: 'Tahap $i',
      lewat: i < sekarang,
      sekarang: i == sekarang,
    ),
];

const namaAlatPanjang =
    'Alat Ukur Tekanan Digital Presisi Tinggi Multi Rentang dengan Sensor '
    'Ganda dan Penyimpan Data Internal';

const nomorOrderUji = 'ORD/ALFA/2026/0021';
const nomorOrderPanjang = 'ORD/ALFA/2026/0021/REVISI/TAMBAHAN/000123';
