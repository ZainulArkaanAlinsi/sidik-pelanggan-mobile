import '../core/format.dart';

/// Bentuk data permintaan kalibrasi (`/permintaan`, `/permintaan/{id}/pesan`,
/// `/preferensi-notifikasi`) — cermin `docs/perintah-frontend-permintaan.md`
/// di `sidik-calibration-api`.

int? _int(Object? v) => v is num ? v.toInt() : int.tryParse('${v ?? ''}');

String? _teks(Object? v) {
  final s = v == null ? null : '$v'.trim();
  return s == null || s.isEmpty ? null : s;
}

// ── Status ───────────────────────────────────────────────────────────────

/// Empat status, tidak lebih. Lab yang memutuskan perpindahannya; aplikasi
/// hanya menampilkan. Kode yang belum dikenal jatuh ke [baru] supaya layar
/// tidak pecah kalau server menambah status — tombol batal tetap dijaga
/// `dapatDibatalkan` dari server, bukan dari tebakan di sini.
enum StatusPermintaan {
  baru,
  diterima,
  ditolak,
  dibatalkan;

  static StatusPermintaan dariApi(String? kode) => switch (kode) {
    'diterima' => diterima,
    'ditolak' => ditolak,
    'dibatalkan' => dibatalkan,
    _ => baru,
  };

  String get label => switch (this) {
    baru => 'Menunggu ditinjau',
    diterima => 'Diterima lab',
    ditolak => 'Ditolak',
    dibatalkan => 'Dibatalkan',
  };
}

enum MetodePengantaran {
  diantarSendiri('diantar_sendiri', 'Saya antar sendiri ke lab'),
  diambilLab('diambil_lab', 'Alat diambil tim lab');

  const MetodePengantaran(this.kode, this.label);

  final String kode;
  final String label;

  static MetodePengantaran? dariApi(String? kode) {
    for (final m in values) {
      if (m.kode == kode) return m;
    }
    return null;
  }
}

// ── Permintaan ───────────────────────────────────────────────────────────

class AlatPermintaan {
  const AlatPermintaan({
    required this.id,
    this.alatId,
    required this.baru,
    required this.nama,
    this.merk,
    this.model,
    this.serial,
  });

  /// Id BARIS permintaan — bukan id alat.
  final int id;

  /// `null` selama alat baru belum didaftarkan lab.
  final int? alatId;
  final bool baru;
  final String nama;
  final String? merk;
  final String? model;
  final String? serial;

  String get merkModel =>
      [merk, model].where((s) => s != null && s.isNotEmpty).join(' · ');

  factory AlatPermintaan.dariJson(Map<String, dynamic> j) => AlatPermintaan(
    id: _int(j['id']) ?? 0,
    alatId: _int(j['alat_id']),
    baru: j['baru'] == true,
    nama: '${j['nama'] ?? '-'}',
    merk: _teks(j['merk']),
    model: _teks(j['model']),
    serial: _teks(j['serial']),
  );
}

class Permintaan {
  const Permintaan({
    required this.id,
    required this.nomor,
    required this.status,
    this.metode,
    this.tanggalDari,
    this.tanggalSampai,
    this.catatan,
    this.alasanPenolakan,
    this.diajukan,
    this.diputuskan,
    this.dibatalkan,
    this.dapatDibatalkan = false,
    this.percakapanTerbuka = false,
    this.jumlahPesan = 0,
    this.jumlahAlat = 0,
    this.alat = const [],
    this.paketId,
    this.paketNomor,
  });

  final int id;
  final String nomor;
  final StatusPermintaan status;
  final MetodePengantaran? metode;
  final DateTime? tanggalDari;
  final DateTime? tanggalSampai;
  final String? catatan;

  /// Hanya ada kalau `status == ditolak` (server tidak mengirim kuncinya
  /// untuk status lain).
  final String? alasanPenolakan;
  final DateTime? diajukan;
  final DateTime? diputuskan;
  final DateTime? dibatalkan;

  /// Keputusan server — tombol batal hanya tampil kalau `true`.
  final bool dapatDibatalkan;
  final bool percakapanTerbuka;
  final int jumlahPesan;
  final int jumlahAlat;
  final List<AlatPermintaan> alat;

  /// Terisi setelah `diterima`: pelacakan tahap alat ada di `/paket/{id}`.
  final int? paketId;
  final String? paketNomor;

  factory Permintaan.dariJson(Map<String, dynamic> j) {
    final paket = j['paket'];
    return Permintaan(
      id: _int(j['id']) ?? 0,
      nomor: '${j['nomor'] ?? ''}',
      status: StatusPermintaan.dariApi(j['status'] as String?),
      metode: MetodePengantaran.dariApi(j['metode_pengantaran'] as String?),
      tanggalDari: Format.baca(j['tanggal_diinginkan_dari'] as String?),
      tanggalSampai: Format.baca(j['tanggal_diinginkan_sampai'] as String?),
      catatan: _teks(j['catatan']),
      alasanPenolakan: _teks(j['alasan_penolakan']),
      diajukan: Format.baca(j['diajukan_pada'] as String?),
      diputuskan: Format.baca(j['diputuskan_pada'] as String?),
      dibatalkan: Format.baca(j['dibatalkan_pada'] as String?),
      dapatDibatalkan: j['dapat_dibatalkan'] == true,
      percakapanTerbuka: j['percakapan_terbuka'] == true,
      jumlahPesan: _int(j['jumlah_pesan']) ?? 0,
      jumlahAlat: _int(j['jumlah_alat']) ?? 0,
      alat: [
        for (final a in (j['alat'] as List? ?? const []))
          AlatPermintaan.dariJson(a as Map<String, dynamic>),
      ],
      paketId: paket is Map ? _int(paket['id']) : null,
      paketNomor: paket is Map ? _teks(paket['nomor']) : null,
    );
  }
}

/// Satu halaman daftar + angka tab. `meta.jumlah` terlepas dari tab yang
/// dibuka, jadi "Aktif 3 · Selesai 4" tidak berkedip waktu pindah tab.
class DaftarPermintaan {
  const DaftarPermintaan({
    required this.isi,
    required this.jumlahAktif,
    required this.jumlahSelesai,
    required this.total,
  });

  final List<Permintaan> isi;
  final int jumlahAktif;
  final int jumlahSelesai;
  final int total;

  factory DaftarPermintaan.dariJson(Map<String, dynamic> badan) {
    final meta = (badan['meta'] as Map?) ?? const {};
    final jumlah = (meta['jumlah'] as Map?) ?? const {};
    return DaftarPermintaan(
      isi: [
        for (final x in (badan['data'] as List? ?? const []))
          Permintaan.dariJson(x as Map<String, dynamic>),
      ],
      jumlahAktif: _int(jumlah['aktif']) ?? 0,
      jumlahSelesai: _int(jumlah['selesai']) ?? 0,
      total: _int(meta['total']) ?? 0,
    );
  }
}

// ── Pesan ────────────────────────────────────────────────────────────────

class PesanPermintaan {
  const PesanPermintaan({
    required this.id,
    required this.dariLab,
    required this.dariSaya,
    required this.namaPengirim,
    required this.isi,
    this.dibuat,
  });

  final int id;

  /// `true` = balasan Tim lab (tanpa nama admin — server memang tidak
  /// mengirimnya).
  final bool dariLab;

  /// Hanya pesan yang dikirim AKUN INI. Rekan sekantor tetap `dariLab: false`
  /// tapi `dariSaya: false`.
  final bool dariSaya;
  final String namaPengirim;
  final String isi;
  final DateTime? dibuat;

  factory PesanPermintaan.dariJson(Map<String, dynamic> j) => PesanPermintaan(
    id: _int(j['id']) ?? 0,
    dariLab: j['sisi'] == 'lab',
    dariSaya: j['dari_saya'] == true,
    namaPengirim: '${j['nama_pengirim'] ?? ''}',
    isi: '${j['isi'] ?? ''}',
    dibuat: Format.baca(j['dibuat_pada'] as String?),
  );
}

class UtasPesan {
  const UtasPesan({required this.isi, required this.terbuka});

  final List<PesanPermintaan> isi;

  /// `false` (ditolak/dibatalkan) → sembunyikan kotak ketik, riwayat tetap.
  final bool terbuka;

  factory UtasPesan.dariJson(Map<String, dynamic> badan) => UtasPesan(
    isi: [
      for (final x in (badan['data'] as List? ?? const []))
        PesanPermintaan.dariJson(x as Map<String, dynamic>),
    ],
    terbuka: ((badan['meta'] as Map?)?['percakapan_terbuka']) == true,
  );
}

// ── Preferensi notifikasi ────────────────────────────────────────────────

class PreferensiNotifikasi {
  const PreferensiNotifikasi({
    required this.pengingatJadwal,
    required this.statusPermintaan,
    required this.pesanLab,
    required this.ringkasanEmailMingguan,
  });

  final bool pengingatJadwal;
  final bool statusPermintaan;
  final bool pesanLab;
  final bool ringkasanEmailMingguan;

  /// Kunci yang dipakai API — dipegang di satu tempat supaya layar dan
  /// payload `PUT` tidak bisa berbeda ejaan.
  static const kunciPengingat = 'pengingat_jadwal';
  static const kunciStatus = 'status_permintaan';
  static const kunciPesan = 'pesan_lab';
  static const kunciEmail = 'ringkasan_email_mingguan';

  bool nilai(String kunci) => switch (kunci) {
    kunciPengingat => pengingatJadwal,
    kunciStatus => statusPermintaan,
    kunciPesan => pesanLab,
    kunciEmail => ringkasanEmailMingguan,
    _ => false,
  };

  PreferensiNotifikasi salinDengan(String kunci, bool v) =>
      PreferensiNotifikasi(
        pengingatJadwal: kunci == kunciPengingat ? v : pengingatJadwal,
        statusPermintaan: kunci == kunciStatus ? v : statusPermintaan,
        pesanLab: kunci == kunciPesan ? v : pesanLab,
        ringkasanEmailMingguan: kunci == kunciEmail
            ? v
            : ringkasanEmailMingguan,
      );

  factory PreferensiNotifikasi.dariJson(Map<String, dynamic> j) =>
      PreferensiNotifikasi(
        pengingatJadwal: j[kunciPengingat] != false,
        statusPermintaan: j[kunciStatus] != false,
        pesanLab: j[kunciPesan] != false,
        // Bawaan server: email mingguan mati.
        ringkasanEmailMingguan: j[kunciEmail] == true,
      );
}

// ── Formulir ajukan ──────────────────────────────────────────────────────

/// Alat yang belum terdaftar — isian mengikuti PL_Form_Alat. Foto pelat nama
/// belum ada karena server belum punya endpoint unggahnya.
class AlatBaru {
  const AlatBaru({
    required this.namaAlat,
    this.merk,
    this.model,
    this.serialNumber,
    this.noIdentifikasi,
    this.rentangMin,
    this.rentangMaks,
    this.satuan,
    this.resolusi,
    this.lokasi,
    this.catatan,
  });

  final String namaAlat;
  final String? merk;
  final String? model;
  final String? serialNumber;
  final String? noIdentifikasi;
  final double? rentangMin;
  final double? rentangMaks;
  final String? satuan;
  final double? resolusi;
  final String? lokasi;
  final String? catatan;

  /// Galat per kolom menurut kontrak §2.3. Kunci = nama kolom API.
  Map<String, String> galat() {
    final g = <String, String>{};
    void maks(String kunci, String? v, int batas, String label) {
      if (v != null && v.length > batas) {
        g[kunci] = '$label terlalu panjang (maks. $batas karakter).';
      }
    }

    if (namaAlat.trim().isEmpty) {
      g['nama_alat'] = 'Nama alat wajib diisi.';
    }
    maks('nama_alat', namaAlat, 255, 'Nama alat');
    maks('merk', merk, 255, 'Merk');
    maks('model', model, 255, 'Model');
    maks('serial_number', serialNumber, 255, 'Nomor seri');
    maks('no_identifikasi', noIdentifikasi, 255, 'No. identifikasi');
    maks('lokasi', lokasi, 255, 'Lokasi');
    maks('catatan', catatan, 1000, 'Catatan');
    if ((rentangMin != null || rentangMaks != null) &&
        (satuan == null || satuan!.trim().isEmpty)) {
      g['satuan'] = 'Rentang sudah diisi, jadi satuannya wajib diisi.';
    }
    if (rentangMin != null &&
        rentangMaks != null &&
        rentangMaks! < rentangMin!) {
      g['rentang_maks'] =
          'Rentang maksimum tidak boleh lebih kecil dari minimum.';
    }
    if (resolusi != null && resolusi! < 0) {
      g['resolusi'] = 'Resolusi tidak boleh negatif.';
    }
    return g;
  }

  /// Kolom kosong TIDAK dikirim — server membedakan "tidak ada" dari "".
  Map<String, dynamic> toJson() => {
    'nama_alat': namaAlat.trim(),
    if (_teks(merk) != null) 'merk': merk!.trim(),
    if (_teks(model) != null) 'model': model!.trim(),
    if (_teks(serialNumber) != null) 'serial_number': serialNumber!.trim(),
    if (_teks(noIdentifikasi) != null)
      'no_identifikasi': noIdentifikasi!.trim(),
    'rentang_min': ?rentangMin,
    'rentang_maks': ?rentangMaks,
    if (_teks(satuan) != null) 'satuan': satuan!.trim(),
    'resolusi': ?resolusi,
    if (_teks(lokasi) != null) 'lokasi': lokasi!.trim(),
    if (_teks(catatan) != null) 'catatan': catatan!.trim(),
  };
}

/// Isi formulir ajukan. Validasi di sini hanya untuk menahan kiriman yang
/// PASTI ditolak server; aturan yang bergantung pada data server (alat milik
/// perusahaan lain, nomor seri kembar) tetap dijawab server.
///
/// `customer_id` sengaja tidak ada: perusahaan datang dari header
/// `X-Perusahaan-Id`, dan server yang memeriksa keanggotaannya.
class DraftPermintaan {
  const DraftPermintaan({
    this.metode,
    this.dari,
    this.sampai,
    this.catatan = '',
    this.alatId = const [],
    this.alatBaru = const [],
  });

  static const maksAlat = 50;

  final MetodePengantaran? metode;
  final DateTime? dari;
  final DateTime? sampai;
  final String catatan;
  final List<int> alatId;
  final List<AlatBaru> alatBaru;

  int get jumlahAlat => alatId.length + alatBaru.length;

  static DateTime _hari(DateTime t) => DateTime(t.year, t.month, t.day);

  /// [hariIni] disuntik supaya test tidak bergantung pada jam mesin.
  Map<String, String> galat({DateTime? hariIni}) {
    final g = <String, String>{};
    final sekarang = _hari(hariIni ?? DateTime.now());

    if (metode == null) {
      g['metode_pengantaran'] = 'Pilih cara alat sampai ke lab.';
    }
    if (dari != null && _hari(dari!).isBefore(sekarang)) {
      g['tanggal_diinginkan_dari'] = 'Tanggal tidak boleh sebelum hari ini.';
    }
    if (sampai != null) {
      final batas = dari == null ? sekarang : _hari(dari!);
      if (_hari(sampai!).isBefore(batas)) {
        g['tanggal_diinginkan_sampai'] =
            'Tanggal akhir tidak boleh sebelum tanggal awal.';
      }
    }
    if (catatan.length > 2000) {
      g['catatan'] = 'Catatan terlalu panjang (maks. 2000 karakter).';
    }
    if (jumlahAlat == 0) {
      g['alat_id'] = 'Pilih minimal satu alat, atau tambahkan alat baru.';
    } else if (jumlahAlat > maksAlat) {
      g['alat_id'] = 'Maksimal $maksAlat alat dalam satu permintaan.';
    }
    for (var i = 0; i < alatBaru.length; i++) {
      for (final e in alatBaru[i].galat().entries) {
        g['alat_baru.$i.${e.key}'] = e.value;
      }
    }
    return g;
  }

  static String _tgl(DateTime t) =>
      '${t.year.toString().padLeft(4, '0')}-'
      '${t.month.toString().padLeft(2, '0')}-'
      '${t.day.toString().padLeft(2, '0')}';

  Map<String, dynamic> toJson() => {
    'metode_pengantaran': metode?.kode,
    if (dari != null) 'tanggal_diinginkan_dari': _tgl(dari!),
    if (sampai != null) 'tanggal_diinginkan_sampai': _tgl(sampai!),
    if (catatan.trim().isNotEmpty) 'catatan': catatan.trim(),
    if (alatId.isNotEmpty) 'alat_id': alatId,
    if (alatBaru.isNotEmpty)
      'alat_baru': [for (final a in alatBaru) a.toJson()],
  };
}
