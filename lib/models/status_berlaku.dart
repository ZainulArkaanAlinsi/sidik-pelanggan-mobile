import 'data_pelanggan.dart';

/// Status masa berlaku yang dilihat pelanggan — SATU daftar untuk alat DAN
/// sertifikat, supaya kata yang sama tidak punya dua arti di dua layar.
///
/// [label] di sini adalah SATU-SATUNYA tempat kata-kata ini ditulis. Lencana
/// (`statusBerlaku()` di `widgets/pemetaan_status.dart`), chip dan kotak ringkasan
/// (`FilterAlat`), dan teks kosong semuanya membacanya dari sini; mengubah satu
/// istilah berarti mengubah satu string.
///
/// ISTILAH (keputusan K3, masih terbuka di API `docs/pelanggan/02-SRS.md`
/// BR-09, risiko R-F02, ISO/IEC 17025 §7.8.4.3): aplikasi pelanggan tidak
/// memakai "kedaluwarsa" / "kadaluarsa"; yang ada adalah jadwal kalibrasi ulang
/// / jatuh tempo. Jadi alat yang terlambat disebut [lewatJadwal] (sama dengan
/// kode server `lewat_jadwal`), dan sertifikat yang tanggalnya lewat disebut
/// [berakhir]. Alasan lengkap: `docs/kebutuhan-api-pelanggan.md` §5c.
///
/// Asal nilainya beda, dan itu disengaja:
/// - ALAT: dihitung SERVER (`status_alat`, `hari_ke_jatuh_tempo`); aplikasi
///   cuma menerjemahkan ([dariAlat]).
/// - SERTIFIKAT: server mengirim status dokumen (`berlaku`/`digantikan`/
///   `dibatalkan`) dan tanggal `berlaku_sampai`, tapi belum mengirim status
///   masa berlakunya. Bagian itu dihitung di sini ([dariSertifikat]) terhadap
///   "hari ini" menurut SERVER (`Alat.hariIniServer`), bukan jam HP; permintaan
///   field server ada di `docs/kebutuhan-api-pelanggan.md`.
enum StatusBerlaku {
  /// Masih dalam masa berlaku.
  berlaku('Berlaku'),

  /// Jatuh tempo dalam [jendela] hari (bawaan 30).
  segera('Segera jatuh tempo'),

  /// Alat: jadwal kalibrasi ulang sudah lewat.
  lewatJadwal('Lewat jadwal'),

  /// Ada revisi sertifikat yang berlaku sebagai gantinya.
  digantikan('Digantikan'),

  /// Dibatalkan lab. Tidak sah dan PDF-nya tidak bisa diunduh.
  dibatalkan('Dibatalkan'),

  /// Sertifikat: tanggal "berlaku sampai" sudah lewat. Netral (bukan merah):
  /// peringatan jadwal ada di status alatnya ([lewatJadwal]).
  berakhir('Masa berlaku berakhir'),

  /// Alat belum pernah dikalibrasi di PT Sidik.
  belumPernah('Belum pernah dikalibrasi'),

  /// Alat sedang diproses lab.
  diproses('Sedang diproses'),

  /// Alat dinonaktifkan.
  tidakAktif('Tidak aktif');

  const StatusBerlaku(this.label);

  /// Kata yang tampil di layar.
  final String label;

  /// Terjemahan `status_alat` (sudah dihitung server).
  static StatusBerlaku dariAlat(StatusKalibrasi s) => switch (s) {
    StatusKalibrasi.terkalibrasi => berlaku,
    StatusKalibrasi.mendekati => segera,
    StatusKalibrasi.lewat => lewatJadwal,
    StatusKalibrasi.belumPernah => belumPernah,
    StatusKalibrasi.dalamProses => diproses,
    StatusKalibrasi.nonaktif => tidakAktif,
  };

  /// Terjemahan status dokumen yang dikirim server.
  static StatusBerlaku dariDokumen(StatusDokumen s) => switch (s) {
    StatusDokumen.berlaku => berlaku,
    StatusDokumen.digantikan => digantikan,
    StatusDokumen.dibatalkan => dibatalkan,
  };

  /// Status satu sertifikat pada "hari ini" = [sekarang].
  ///
  /// Status dokumen dari server menang: dibatalkan dan digantikan tidak
  /// ditimpa oleh tanggal. Sisanya dinilai dari `berlaku_sampai` (tanggal
  /// saja, jam diabaikan); sertifikat tanpa tanggal dianggap [berlaku]. Tanggal
  /// lewat = [berakhir].
  ///
  /// [sekarang] harus "hari ini" menurut server (`Alat.hariIniServer`), dengan
  /// jam HP hanya sebagai cadangan: BR-08 mewajibkan hari ini Asia/Jakarta, dan
  /// jam HP yang mundur membuat sertifikat lewat tampil "Berlaku".
  ///
  /// [adaPenerus]: di riwayat alat sudah ada sertifikat lain yang berlaku dan
  /// lebih baru. Tidak ada peringatan [segera] untuk yang lama, karena alatnya
  /// sudah ditutup sertifikat yang baru.
  static StatusBerlaku dariSertifikat(
    Sertifikat s, {
    required DateTime sekarang,
    int jendela = 30,
    bool adaPenerus = false,
  }) {
    if (s.dibatalkan) return dibatalkan;
    if (s.digantikan) return digantikan;
    final hari = hariSampai(s.berlakuSampai, sekarang);
    if (hari == null) return berlaku;
    if (hari < 0) return berakhir;
    if (adaPenerus) return berlaku;
    return hari <= jendela ? segera : berlaku;
  }

  /// Selisih hari kalender dari [sekarang] ke [tanggal]; negatif = sudah
  /// lewat, `null` kalau tidak ada tanggal. Memakai tanggal kalender (bukan
  /// 24 jam) supaya "hari ini" tidak berubah menurut jam.
  static int? hariSampai(DateTime? tanggal, DateTime sekarang) {
    if (tanggal == null) return null;
    final a = DateTime.utc(tanggal.year, tanggal.month, tanggal.day);
    final b = DateTime.utc(sekarang.year, sekarang.month, sekarang.day);
    return a.difference(b).inDays;
  }
}

/// Alat yang menuju jatuh tempo, dikelompokkan untuk Beranda dan daftar alat.
///
/// Dihitung di aplikasi dari daftar alat (server baru memberi hitungan untuk
/// "lewat jadwal" dan "dalam [jendela] hari"). Yang dihitung hanya `hari_ke_
/// jatuh_tempo` kiriman server, bukan tanggal HP, jadi jam HP yang salah tidak
/// menggeser alat ke kelompok lain.
class RingkasanJatuhTempo {
  const RingkasanJatuhTempo({
    this.lewatJadwal = const [],
    this.kelompok1 = const [],
    this.kelompok2 = const [],
    this.kelompok3 = const [],
  });

  /// Jadwal kalibrasi ulang sudah lewat ([StatusBerlaku.lewatJadwal]).
  final List<Alat> lewatJadwal;

  /// 0 sampai [batas1] hari lagi.
  final List<Alat> kelompok1;

  /// [batas1] + 1 sampai [batas2] hari lagi.
  final List<Alat> kelompok2;

  /// [batas2] + 1 sampai [batas3] hari lagi.
  final List<Alat> kelompok3;

  static const batas2 = 60;
  static const batas3 = 90;

  /// Alat paling mendesak lebih dulu: yang sudah lewat, lalu yang terdekat.
  List<Alat> get urut => [
    ...lewatJadwal,
    ...kelompok1,
    ...kelompok2,
    ...kelompok3,
  ];

  /// [batas1] = jendela "segera" dari server (30 hari). Alat nonaktif, belum
  /// pernah dikalibrasi, atau tanpa jadwal tidak masuk kelompok mana pun.
  factory RingkasanJatuhTempo.dari(List<Alat> alat, {int batas1 = 30}) {
    final lewat = <Alat>[], k1 = <Alat>[], k2 = <Alat>[], k3 = <Alat>[];
    for (final a in alat) {
      final hari = a.hariKeJatuhTempo;
      final dinilai =
          a.status == StatusKalibrasi.terkalibrasi ||
          a.status == StatusKalibrasi.mendekati ||
          a.status == StatusKalibrasi.lewat;
      if (hari == null || !dinilai) continue;
      if (hari < 0) {
        lewat.add(a);
      } else if (hari <= batas1) {
        k1.add(a);
      } else if (hari <= batas2) {
        k2.add(a);
      } else if (hari <= batas3) {
        k3.add(a);
      }
    }
    return RingkasanJatuhTempo(
      lewatJadwal: lewat,
      kelompok1: k1,
      kelompok2: k2,
      kelompok3: k3,
    );
  }
}
