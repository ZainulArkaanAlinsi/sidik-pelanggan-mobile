/// Akun pelanggan — bentuk `data.user` dari `/auth/masuk` & `/auth/terima-undangan`,
/// dan `data` dari `GET /saya` (fixture `tests/Fixtures/pelanggan/*.json` di
/// repo API).
class Akun {
  const Akun({
    required this.id,
    required this.nama,
    required this.email,
    this.telepon,
    this.jabatan,
    required this.status,
    required this.butuhVerifikasi,
    required this.keanggotaan,
    this.pengajuan,
  });

  final int id;
  final String nama;
  final String email;
  final String? telepon;
  final String? jabatan;
  final String status;
  final bool butuhVerifikasi;
  final List<Keanggotaan> keanggotaan;
  final PengajuanAkun? pengajuan;

  bool get punyaPerusahaan => keanggotaan.isNotEmpty;
  bool get lebihDariSatuPerusahaan => keanggotaan.length > 1;

  factory Akun.dariJson(Map<String, dynamic> j) => Akun(
    id: (j['id'] as num).toInt(),
    nama: '${j['nama'] ?? ''}',
    email: '${j['email'] ?? ''}',
    telepon: j['telepon'] as String?,
    jabatan: j['jabatan'] as String?,
    status: '${j['status'] ?? ''}',
    butuhVerifikasi: j['butuh_verifikasi'] == true,
    keanggotaan: [
      for (final k in (j['keanggotaan'] as List? ?? const []))
        Keanggotaan.dariJson(k as Map<String, dynamic>),
    ],
    pengajuan: j['pengajuan'] is Map<String, dynamic>
        ? PengajuanAkun.dariJson(j['pengajuan'] as Map<String, dynamic>)
        : null,
  );
}

class Keanggotaan {
  const Keanggotaan({
    required this.customerId,
    required this.namaPerusahaan,
    required this.peran,
  });

  final int customerId;
  final String namaPerusahaan;

  /// `pic_utama` atau `staf`.
  final String peran;

  bool get picUtama => peran == 'pic_utama';

  String get labelPeran => picUtama ? 'PIC utama' : 'Staf';

  factory Keanggotaan.dariJson(Map<String, dynamic> j) => Keanggotaan(
    customerId: (j['customer_id'] as num).toInt(),
    namaPerusahaan: '${j['nama_perusahaan'] ?? ''}',
    peran: '${j['peran'] ?? 'staf'}',
  );
}

/// Pengajuan akun lama (sebelum pendaftaran mandiri dicabut 18 Sep 2026).
/// Masih dibaca karena baris lamanya bisa ada.
class PengajuanAkun {
  const PengajuanAkun({
    required this.status,
    this.namaPerusahaan,
    this.alasanTolak,
  });

  final String status;
  final String? namaPerusahaan;
  final String? alasanTolak;

  factory PengajuanAkun.dariJson(Map<String, dynamic> j) => PengajuanAkun(
    status: '${j['status'] ?? ''}',
    namaPerusahaan: j['nama_perusahaan'] as String?,
    alasanTolak: j['alasan_tolak'] as String?,
  );
}

/// `GET /app/status` — dibaca tiap aplikasi dibuka, bahkan sebelum masuk.
class StatusAplikasi {
  const StatusAplikasi({
    required this.versiMinimum,
    required this.versiTerbaru,
    required this.pemeliharaan,
    required this.pesanPemeliharaan,
  });

  final String versiMinimum;
  final String versiTerbaru;
  final bool pemeliharaan;
  final String pesanPemeliharaan;

  factory StatusAplikasi.dariJson(Map<String, dynamic> j) => StatusAplikasi(
    versiMinimum: '${j['versi_minimum'] ?? '0.0.0'}',
    versiTerbaru: '${j['versi_terbaru'] ?? '0.0.0'}',
    pemeliharaan: j['maintenance'] == true,
    pesanPemeliharaan: '${j['pesan_maintenance'] ?? ''}',
  );

  /// Versi terpasang lebih lama dari batas minimum → wajib perbarui.
  bool wajibPerbarui(String terpasang) =>
      bandingkanVersi(terpasang, versiMinimum) < 0;

  /// Bandingkan "1.2.10" dengan "1.2.9" secara angka, bukan teks.
  static int bandingkanVersi(String a, String b) {
    List<int> pecah(String v) =>
        v.split('+').first.split('.').map((s) => int.tryParse(s) ?? 0).toList();
    final x = pecah(a);
    final y = pecah(b);
    for (var i = 0; i < 3; i++) {
      final p = i < x.length ? x[i] : 0;
      final q = i < y.length ? y[i] : 0;
      if (p != q) return p.compareTo(q);
    }
    return 0;
  }
}
