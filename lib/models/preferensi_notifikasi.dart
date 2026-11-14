import 'package:flutter/foundation.dart';

import '../core/api_pelanggan.dart';

/// Kelompok kategori di layar: kabar yang masuk ke HP dan kotak Notifikasi,
/// atau yang dikirim lewat email.
enum KelompokKabar { notifikasi, email }

/// Satu kategori kabar yang boleh diatur pelanggan. [kunci] persis kunci
/// `GET/PUT /preferensi-notifikasi` (kontrak API §14.4); [judul] dan
/// [penjelasan] bahasa pelanggan, bukan nama kolom.
@immutable
class KategoriKabar {
  const KategoriKabar(this.kunci, this.kelompok, this.judul, this.penjelasan);

  final String kunci;
  final KelompokKabar kelompok;
  final String judul;
  final String penjelasan;

  /// Kategori yang SEKARANG mengatur sesuatu di server, berurutan seperti di
  /// layar. Kunci lain di jawaban server tidak ditampilkan dan tidak pernah
  /// dikirim balik: `PUT` hanya menerima kunci yang ia kenal, jadi saklar untuk
  /// kunci asing tidak bisa disimpan.
  ///
  /// - `pesan_lab` sengaja TIDAK ada: permintaan kalibrasi dicabut (K-50-09)
  ///   dan tidak ada lagi pengirimnya; nilainya di server dibiarkan apa adanya.
  /// - `status_permintaan` kini memegang kabar sertifikat terbit (kontrak §8);
  ///   kunci lamanya dipertahankan, labelnya mengikuti isinya.
  /// - `tahap_alat` (13 Nov 2026) bawaan menyala. Kalimatnya menyebut dua tahap
  ///   fisik yang pasti dikabarkan di server mana pun ("siap diambil", "sudah
  ///   diserahkan") dan "tahap lain yang dikabarkan lab": kabar tahap turunan
  ///   ("sedang dikalibrasi") baru ada bila server menyalakannya
  ///   (`KABAR_TAHAP_TURUNAN`), jadi kalimat ini benar di kedua keadaan.
  static const daftar = <KategoriKabar>[
    KategoriKabar(
      'pengingat_jadwal',
      KelompokKabar.notifikasi,
      'Pengingat jadwal kalibrasi',
      'Kabar saat alat mendekati atau melewati jadwal kalibrasi ulang.',
    ),
    KategoriKabar(
      'status_permintaan',
      KelompokKabar.notifikasi,
      'Sertifikat terbit',
      'Kabar saat sertifikat alat perusahaan Anda sudah terbit.',
    ),
    KategoriKabar(
      'tahap_alat',
      KelompokKabar.notifikasi,
      'Perubahan tahap alat',
      'Kabar saat satu alat Anda siap diambil atau sudah diserahkan, dan tahap '
          'lain yang dikabarkan lab. Setiap alat dikabari sendiri-sendiri.',
    ),
    KategoriKabar(
      'ringkasan_email_mingguan',
      KelompokKabar.email,
      'Ringkasan mingguan lewat email',
      'Email tiap Senin pagi berisi alat yang mendekati jadwal dan sertifikat '
          'terbaru. Tidak dikirim pada minggu tanpa isi.',
    ),
  ];

  static bool dikenal(String kunci) => daftar.any((k) => k.kunci == kunci);
}

/// Di mana satu saklar berada dalam siklus simpan.
enum TahapSimpan {
  /// Nilai di layar = nilai yang dikonfirmasi server.
  diam,

  /// Sudah tampil di layar (optimistis), menunggu server.
  menyimpan,

  /// Server menolak atau tidak terjangkau; nilai sudah dikembalikan.
  gagal,
}

/// Seluruh keadaan layar pengaturan notifikasi sesudah data termuat.
@immutable
class KeadaanPreferensi {
  const KeadaanPreferensi({
    required this.nilai,
    this.tahap = const {},
    this.pesanGagal = const {},
    this.alasanBacaSaja,
    this.dataTerakhir,
  });

  /// Nilai yang TAMPIL per kunci kategori yang dikenal (optimistis selama
  /// menyimpan).
  final Map<String, bool> nilai;
  final Map<String, TahapSimpan> tahap;

  /// Kalimat galat per kunci yang tahapnya [TahapSimpan.gagal].
  final Map<String, String> pesanGagal;

  /// Bila diisi, layar hanya bisa dibaca dan inilah alasannya (server menolak
  /// perubahan dari akun ini dengan 403).
  final String? alasanBacaSaja;

  /// Bila diisi, nilai berasal dari simpanan HP (tidak ada sambungan) dan ini
  /// waktunya. Nilai itu bisa lebih lama daripada yang ada di server, jadi
  /// tidak boleh diubah dari sini.
  final DateTime? dataTerakhir;

  bool get dariCache => dataTerakhir != null;

  /// Saklar boleh diketuk.
  bool get bisaUbah => alasanBacaSaja == null && !dariCache;

  TahapSimpan tahapDari(String kunci) => tahap[kunci] ?? TahapSimpan.diam;

  KeadaanPreferensi salin({
    Map<String, bool>? nilai,
    Map<String, TahapSimpan>? tahap,
    Map<String, String>? pesanGagal,
    String? alasanBacaSaja,
  }) => KeadaanPreferensi(
    nilai: nilai ?? this.nilai,
    tahap: tahap ?? this.tahap,
    pesanGagal: pesanGagal ?? this.pesanGagal,
    alasanBacaSaja: alasanBacaSaja ?? this.alasanBacaSaja,
    dataTerakhir: dataTerakhir,
  );
}

/// Alasan layar jadi baca-saja (server menjawab 403 pada simpan).
const alasanTanpaIzinUbah =
    'Akun Anda belum bisa mengubah pengaturan ini. Pilihan di bawah hanya '
    'bisa dibaca. Hubungi PT Sidik bila ini keliru.';

/// Kalimat untuk satu saklar yang gagal disimpan. Selalu diawali "Belum
/// tersimpan" supaya jelas bahwa nilai di layar sudah dikembalikan.
String pesanGagalSimpan(Object galat) {
  const awal = 'Belum tersimpan. ';
  if (galat is GalatApi) {
    if (galat.jaringan) {
      return '${awal}Tidak ada sambungan. Periksa koneksi internet Anda, lalu '
          'ketuk lagi.';
    }
    return switch (galat.status) {
      429 =>
        '${awal}Terlalu sering mengubah. Tunggu sebentar, lalu ketuk lagi.',
      422 =>
        '${awal}Pilihan ini ditolak server. Tutup layar ini, buka lagi, lalu '
            'coba lagi.',
      _ => '$awal${galat.pesan}',
    };
  }
  return '${awal}Terjadi kendala di HP ini. Ketuk lagi untuk mencoba.';
}

/// Ringkasan galat MEMUAT untuk layar (judul, isi) menurut jenisnya.
({String judul, String isi}) pesanGagalMuat(Object galat) {
  if (galat is GalatApi) {
    if (galat.jaringan) {
      return (
        judul: 'Tidak ada sambungan',
        isi:
            'Pengaturan notifikasi belum bisa dimuat. Periksa koneksi '
            'internet Anda, lalu coba lagi.',
      );
    }
    if (galat.status == 403) {
      return (
        judul: 'Pengaturan ini belum bisa dibuka',
        isi:
            'Server menolak permintaan ini untuk akun Anda. Hubungi PT Sidik bila '
            'ini keliru.',
      );
    }
    return (judul: 'Pengaturan belum bisa dimuat', isi: galat.pesan);
  }
  return (
    judul: 'Pengaturan belum bisa dimuat',
    isi: 'Terjadi kesalahan di HP ini. Coba lagi.',
  );
}
