import '../core/format.dart';

/// Bentuk data slice F (`/beranda`, `/alat`, `/sertifikat`, `/paket`,
/// `/notifikasi`) — cermin resource `App\Http\Resources\Pelanggan\*` di API.

int? _int(Object? v) => v is num ? v.toInt() : int.tryParse('${v ?? ''}');

// ── Alat ─────────────────────────────────────────────────────────────────

enum StatusKalibrasi {
  aman,
  segera,
  lewat,
  nonaktif,
  belumAda;

  static StatusKalibrasi dariApi(String? kode) => switch (kode) {
    'aman' => aman,
    'segera_jatuh_tempo' => segera,
    'lewat_jatuh_tempo' => lewat,
    'nonaktif' => nonaktif,
    _ => belumAda,
  };

  String get label => switch (this) {
    aman => 'Aman',
    segera => 'Segera jatuh tempo',
    lewat => 'Lewat jatuh tempo',
    nonaktif => 'Tidak aktif',
    belumAda => 'Belum ada jadwal',
  };
}

class RingkasSertifikat {
  const RingkasSertifikat({
    required this.id,
    required this.nomor,
    this.diterbitkan,
    this.berlakuSampai,
  });

  final int id;
  final String nomor;
  final DateTime? diterbitkan;
  final DateTime? berlakuSampai;

  static RingkasSertifikat? dariJson(Object? j) {
    if (j is! Map<String, dynamic>) return null;
    return RingkasSertifikat(
      id: _int(j['id']) ?? 0,
      nomor: '${j['nomor'] ?? ''}',
      diterbitkan: Format.baca(j['diterbitkan_pada'] as String?),
      berlakuSampai: Format.baca(j['berlaku_sampai'] as String?),
    );
  }
}

class Alat {
  const Alat({
    required this.id,
    required this.nama,
    this.merk,
    this.model,
    this.serial,
    this.noIdentifikasi,
    this.rentang,
    this.lokasi,
    this.kalibrasiTerakhir,
    this.jatuhTempo,
    this.hariKeJatuhTempo,
    required this.status,
    this.sertifikatTerakhir,
    this.riwayat = const [],
  });

  final int id;
  final String nama;
  final String? merk;
  final String? model;
  final String? serial;
  final String? noIdentifikasi;
  final String? rentang;
  final String? lokasi;
  final DateTime? kalibrasiTerakhir;
  final DateTime? jatuhTempo;
  final int? hariKeJatuhTempo;
  final StatusKalibrasi status;
  final RingkasSertifikat? sertifikatTerakhir;
  final List<Sertifikat> riwayat;

  String get merkModel =>
      [merk, model].where((s) => s != null && s.isNotEmpty).join(' · ');

  factory Alat.dariJson(Map<String, dynamic> j) {
    final r = j['rentang'];
    String? rentang;
    if (r is Map && (r['min'] != null || r['max'] != null)) {
      rentang = '${r['min'] ?? '?'} – ${r['max'] ?? '?'} ${r['satuan'] ?? ''}'
          .trim();
    }
    return Alat(
      id: _int(j['id']) ?? 0,
      nama: '${j['nama'] ?? '-'}',
      merk: j['merk'] as String?,
      model: j['model'] as String?,
      serial: j['serial'] as String?,
      noIdentifikasi: j['no_identifikasi'] as String?,
      rentang: rentang,
      lokasi: j['lokasi'] as String?,
      kalibrasiTerakhir: Format.baca(
        j['tanggal_kalibrasi_terakhir'] as String?,
      ),
      jatuhTempo: Format.baca(j['tanggal_jatuh_tempo'] as String?),
      hariKeJatuhTempo: _int(j['hari_ke_jatuh_tempo']),
      status: StatusKalibrasi.dariApi(j['status_kalibrasi'] as String?),
      sertifikatTerakhir: RingkasSertifikat.dariJson(j['sertifikat_terakhir']),
      riwayat: [
        for (final s in (j['riwayat_sertifikat'] as List? ?? const []))
          Sertifikat.dariJson(s as Map<String, dynamic>),
      ],
    );
  }
}

// ── Sertifikat ───────────────────────────────────────────────────────────

class Sertifikat {
  const Sertifikat({
    required this.id,
    required this.nomor,
    this.diterbitkan,
    this.berlakuSampai,
    this.keputusan,
    this.alatId,
    this.namaAlat,
    this.merk,
    this.model,
    this.serial,
    this.revisiDari,
    this.digantikanOleh,
    required this.bisaDiunduh,
    this.tautanVerifikasi,
    this.rincian = const {},
    this.penandaTangan,
  });

  final int id;
  final String nomor;
  final DateTime? diterbitkan;
  final DateTime? berlakuSampai;

  /// `PASS` / `FAIL` / null (alat yang memang tidak divonis).
  final String? keputusan;
  final int? alatId;
  final String? namaAlat;
  final String? merk;
  final String? model;
  final String? serial;
  final String? revisiDari;
  final RingkasSertifikat? digantikanOleh;
  final bool bisaDiunduh;
  final String? tautanVerifikasi;
  final Map<String, String> rincian;
  final String? penandaTangan;

  bool get digantikan => digantikanOleh != null;

  factory Sertifikat.dariJson(Map<String, dynamic> j) {
    final alat = (j['alat'] as Map?) ?? const {};
    final rincian = <String, String>{};
    final r = j['rincian'];
    if (r is Map) {
      const label = {
        'nomor_order': 'Nomor order',
        'tanggal_terima': 'Tanggal diterima',
        'tanggal_kalibrasi': 'Tanggal kalibrasi',
        'lokasi_kalibrasi': 'Lokasi kalibrasi',
        'metode': 'Metode',
        'kondisi_lingkungan': 'Kondisi lingkungan',
      };
      for (final e in label.entries) {
        final v = r[e.key];
        if (v != null && '$v'.isNotEmpty) rincian[e.value] = '$v';
      }
    }
    final ttd = j['penanda_tangan'];
    return Sertifikat(
      id: _int(j['id']) ?? 0,
      nomor: '${j['nomor'] ?? ''}',
      diterbitkan: Format.baca(j['diterbitkan_pada'] as String?),
      berlakuSampai: Format.baca(j['berlaku_sampai'] as String?),
      keputusan: j['keputusan'] as String?,
      alatId: _int(alat['id']),
      namaAlat: alat['nama'] as String?,
      merk: alat['merk'] as String?,
      model: alat['model'] as String?,
      serial: alat['serial'] as String?,
      revisiDari: (j['revisi_dari'] as Map?)?['nomor'] as String?,
      digantikanOleh: RingkasSertifikat.dariJson(j['digantikan_oleh']),
      bisaDiunduh: j['bisa_diunduh'] == true,
      tautanVerifikasi: j['tautan_verifikasi'] as String?,
      rincian: rincian,
      penandaTangan: ttd is Map && ttd['nama'] != null
          ? [ttd['nama'], ttd['jabatan']].where((s) => s != null).join(', ')
          : null,
    );
  }
}

// ── Paket ────────────────────────────────────────────────────────────────

class AlatPaket {
  const AlatPaket({
    required this.nama,
    this.merk,
    this.serial,
    required this.tahap,
    required this.tahapLabel,
    this.diserahkanKepada,
    this.sertifikatId,
  });

  final String nama;
  final String? merk;
  final String? serial;
  final String tahap;
  final String tahapLabel;
  final String? diserahkanKepada;
  final int? sertifikatId;

  factory AlatPaket.dariJson(Map<String, dynamic> j) => AlatPaket(
    nama: '${j['nama'] ?? '-'}',
    merk: j['merk'] as String?,
    serial: j['serial'] as String?,
    tahap: '${j['tahap'] ?? ''}',
    tahapLabel: '${j['tahap_label'] ?? ''}',
    diserahkanKepada: j['diserahkan_kepada'] as String?,
    sertifikatId: _int(j['sertifikat_id']),
  );
}

class LangkahWaktu {
  const LangkahWaktu({
    required this.label,
    required this.lewat,
    required this.sekarang,
  });

  final String label;
  final bool lewat;
  final bool sekarang;

  factory LangkahWaktu.dariJson(Map<String, dynamic> j) => LangkahWaktu(
    label: '${j['label'] ?? ''}',
    lewat: j['lewat'] == true,
    sekarang: j['sekarang'] == true,
  );
}

class Paket {
  const Paket({
    required this.id,
    required this.nomor,
    this.masuk,
    this.janjiSelesai,
    required this.terlambat,
    required this.tahap,
    required this.tahapLabel,
    required this.jumlahAlat,
    required this.jumlahSelesai,
    required this.alat,
    this.garisWaktu = const [],
  });

  final int id;
  final String nomor;
  final DateTime? masuk;
  final DateTime? janjiSelesai;
  final bool terlambat;
  final String tahap;
  final String tahapLabel;
  final int jumlahAlat;
  final int jumlahSelesai;
  final List<AlatPaket> alat;
  final List<LangkahWaktu> garisWaktu;

  double get kemajuan => jumlahAlat == 0 ? 0 : jumlahSelesai / jumlahAlat;

  factory Paket.dariJson(Map<String, dynamic> j, [List? garisWaktu]) => Paket(
    id: _int(j['id']) ?? 0,
    nomor: '${j['nomor'] ?? ''}',
    masuk: Format.baca(j['tanggal_masuk'] as String?),
    janjiSelesai: Format.baca(j['tanggal_janji_selesai'] as String?),
    terlambat: j['terlambat'] == true,
    tahap: '${j['tahap'] ?? ''}',
    tahapLabel: '${j['tahap_label'] ?? ''}',
    jumlahAlat: _int(j['jumlah_alat']) ?? 0,
    jumlahSelesai: _int(j['jumlah_selesai']) ?? 0,
    alat: [
      for (final a in (j['alat'] as List? ?? const []))
        AlatPaket.dariJson(a as Map<String, dynamic>),
    ],
    garisWaktu: [
      for (final l in (garisWaktu ?? const []))
        LangkahWaktu.dariJson(l as Map<String, dynamic>),
    ],
  );
}

// ── Beranda ──────────────────────────────────────────────────────────────

class Beranda {
  const Beranda({
    required this.namaPerusahaan,
    required this.jumlahAlat,
    required this.lewatJatuhTempo,
    required this.segeraJatuhTempo,
    required this.paketBerjalan,
    required this.notifikasiBelumDibaca,
    required this.perluPerhatian,
    required this.sertifikatTerbaru,
    required this.daftarPaket,
    required this.jendelaHari,
  });

  final String namaPerusahaan;
  final int jumlahAlat;
  final int lewatJatuhTempo;
  final int segeraJatuhTempo;
  final int paketBerjalan;
  final int notifikasiBelumDibaca;
  final List<Alat> perluPerhatian;
  final List<Sertifikat> sertifikatTerbaru;
  final List<Paket> daftarPaket;
  final int jendelaHari;

  factory Beranda.dariJson(Map<String, dynamic> badan) {
    final d = badan['data'] as Map<String, dynamic>;
    final r = (d['ringkasan'] as Map?) ?? const {};
    return Beranda(
      namaPerusahaan: '${(d['perusahaan'] as Map?)?['nama'] ?? ''}',
      jumlahAlat: _int(r['jumlah_alat']) ?? 0,
      lewatJatuhTempo: _int(r['lewat_jatuh_tempo']) ?? 0,
      segeraJatuhTempo: _int(r['segera_jatuh_tempo']) ?? 0,
      paketBerjalan: _int(r['paket_berjalan']) ?? 0,
      notifikasiBelumDibaca: _int(r['notifikasi_belum_dibaca']) ?? 0,
      perluPerhatian: [
        for (final a in (d['perlu_perhatian'] as List? ?? const []))
          Alat.dariJson(a as Map<String, dynamic>),
      ],
      sertifikatTerbaru: [
        for (final s in (d['sertifikat_terbaru'] as List? ?? const []))
          Sertifikat.dariJson(s as Map<String, dynamic>),
      ],
      daftarPaket: [
        for (final p in (d['paket_berjalan'] as List? ?? const []))
          Paket.dariJson(p as Map<String, dynamic>),
      ],
      jendelaHari: _int((badan['meta'] as Map?)?['jendela_segera_hari']) ?? 30,
    );
  }
}

// ── Notifikasi ───────────────────────────────────────────────────────────

class Notifikasi {
  const Notifikasi({
    required this.id,
    required this.judul,
    this.isi,
    required this.kategori,
    required this.dibaca,
    this.dibuat,
  });

  final String id;
  final String judul;
  final String? isi;
  final String kategori;
  final bool dibaca;
  final DateTime? dibuat;

  Notifikasi tandaiDibaca() => Notifikasi(
    id: id,
    judul: judul,
    isi: isi,
    kategori: kategori,
    dibaca: true,
    dibuat: dibuat,
  );

  factory Notifikasi.dariJson(Map<String, dynamic> j) => Notifikasi(
    id: '${j['id']}',
    judul: '${j['judul'] ?? 'Pemberitahuan'}',
    isi: j['isi'] as String?,
    kategori: '${j['kategori'] ?? 'umum'}',
    dibaca: j['dibaca'] == true,
    dibuat: Format.baca(j['dibuat_pada'] as String?),
  );
}

/// Satu halaman hasil ber-paginasi.
class Halaman<T> {
  const Halaman({
    required this.isi,
    required this.halaman,
    required this.halamanTerakhir,
    required this.total,
  });

  final List<T> isi;
  final int halaman;
  final int halamanTerakhir;
  final int total;

  bool get adaLagi => halaman < halamanTerakhir;

  static Halaman<T> dariJson<T>(
    Map<String, dynamic> badan,
    T Function(Map<String, dynamic>) ubah,
  ) {
    final meta = (badan['meta'] as Map?) ?? const {};
    return Halaman<T>(
      isi: [
        for (final x in (badan['data'] as List? ?? const []))
          ubah(x as Map<String, dynamic>),
      ],
      halaman: _int(meta['current_page']) ?? 1,
      halamanTerakhir: _int(meta['last_page']) ?? 1,
      total: _int(meta['total']) ?? 0,
    );
  }
}
