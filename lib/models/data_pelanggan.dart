import '../core/format.dart';

/// Bentuk data (`/beranda`, `/alat`, `/sertifikat`, `/notifikasi`) — cermin resource `App\Http\Resources\Pelanggan\*` di API.

int? _int(Object? v) => v is num ? v.toInt() : int.tryParse('${v ?? ''}');

/// Angka dari server bisa datang sebagai string desimal (`"0.01000000"` dari
/// MySQL). Untuk ditampilkan/diedit: buang nol di belakang koma, pakai koma.
String? angkaRapi(Object? v) {
  if (v == null) return null;
  final n = v is num ? v.toDouble() : double.tryParse('$v'.trim());
  if (n == null) {
    final t = '$v'.trim();
    return t.isEmpty ? null : t;
  }
  var t = n == n.roundToDouble() ? n.toInt().toString() : n.toString();
  if (t.contains('.') && t.contains('e') == false) {
    t = t.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
  }
  return t.replaceAll('.', ',');
}

String? _teksBersih(Object? v) {
  final s = v == null ? null : '$v'.trim();
  return s == null || s.isEmpty ? null : s;
}

// ── Alat ─────────────────────────────────────────────────────────────────

/// Status kalibrasi alat menurut REQ-ALT-05 / 04-UI-UX §5. DIHITUNG SERVER
/// (`status_alat`); aplikasi hanya menerjemahkan kode jadi tampilan.
enum StatusKalibrasi {
  terkalibrasi,
  mendekati,
  lewat,
  belumPernah,
  dalamProses,
  nonaktif;

  /// [statusAlat] = `status_alat` (kontrak §4.1, kode REQ-ALT-05).
  /// [statusLama] = `status_kalibrasi` (`aman`, `segera_jatuh_tempo`,
  /// `lewat_jatuh_tempo`, `nonaktif`, `belum_ada_jadwal`) — dipakai hanya
  /// kalau server belum mengirim [statusAlat]. `belum_ada_jadwal` lama tidak
  /// membedakan "belum pernah dikalibrasi" dari "bersertifikat tanpa tanggal
  /// ulang"; [adaSertifikat] yang memilah.
  static StatusKalibrasi dariApi(
    String? statusAlat, {
    String? statusLama,
    bool adaSertifikat = false,
  }) => switch (statusAlat) {
    'terkalibrasi' => terkalibrasi,
    'mendekati_jadwal' => mendekati,
    'lewat_jadwal' => lewat,
    'belum_pernah' => belumPernah,
    'dalam_proses' => dalamProses,
    'nonaktif' => nonaktif,
    _ => switch (statusLama) {
      'aman' => terkalibrasi,
      'segera_jatuh_tempo' => mendekati,
      'lewat_jatuh_tempo' => lewat,
      'nonaktif' => nonaktif,
      _ => adaSertifikat ? terkalibrasi : belumPernah,
    },
  };

  /// Label 04-UI-UX §5. [hari] = `hari_ke_jatuh_tempo` (negatif = lewat).
  String label([int? hari]) => switch (this) {
    terkalibrasi => 'Terkalibrasi',
    mendekati =>
      hari == null
          ? 'Mendekati jadwal'
          : hari <= 0
          ? 'Kalibrasi ulang hari ini'
          : 'Kalibrasi ulang dalam $hari hari',
    lewat =>
      hari == null || hari >= 0 ? 'Lewat jadwal' : 'Lewat jadwal ${-hari} hari',
    belumPernah => 'Belum pernah dikalibrasi',
    dalamProses => 'Sedang diproses',
    nonaktif => 'Tidak aktif',
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
    this.catatan,
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

  /// Riwayat kalibrasi alat ini (sertifikat, terbaru di atas) — hanya di detail.
  final List<Sertifikat> riwayat;
  final String? catatan;

  /// Label status lengkap dengan sisa hari ("Kalibrasi ulang dalam 12 hari").
  String get labelStatus => status.label(hariKeJatuhTempo);

  String get merkModel =>
      [merk, model].where((s) => s != null && s.isNotEmpty).join(' · ');

  factory Alat.dariJson(Map<String, dynamic> j) {
    final r = j['rentang'];
    String? rentang;
    if (r is Map && (r['min'] != null || r['max'] != null)) {
      rentang =
          '${angkaRapi(r['min']) ?? '?'} – ${angkaRapi(r['max']) ?? '?'} ${r['satuan'] ?? ''}'
              .trim();
    }
    final sertifikatTerakhir = RingkasSertifikat.dariJson(
      j['sertifikat_terakhir'],
    );
    final riwayat = [
      for (final s in (j['riwayat_sertifikat'] as List? ?? const []))
        Sertifikat.dariJson(s as Map<String, dynamic>),
    ];
    final status = StatusKalibrasi.dariApi(
      j['status_alat'] as String?,
      statusLama: j['status_kalibrasi'] as String?,
      adaSertifikat:
          sertifikatTerakhir != null ||
          riwayat.isNotEmpty ||
          j['tanggal_kalibrasi_terakhir'] != null,
    );
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
      status: status,
      sertifikatTerakhir: sertifikatTerakhir,
      riwayat: riwayat,
      catatan: _teksBersih(j['catatan']),
    );
  }
}

// ── Sertifikat ───────────────────────────────────────────────────────────

/// Status dokumen sertifikat. Dihitung server; kode yang belum dikenal jatuh
/// ke [berlaku] supaya layar tidak pecah kalau server menambah status.
enum StatusDokumen {
  berlaku,
  digantikan,
  dibatalkan;

  static StatusDokumen? dariApi(String? kode) => switch (kode) {
    'berlaku' => berlaku,
    'digantikan' => digantikan,
    'dibatalkan' => dibatalkan,
    _ => null,
  };

  String get label => switch (this) {
    berlaku => 'Berlaku',
    digantikan => 'Digantikan',
    dibatalkan => 'Dibatalkan',
  };
}

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
    this.status = StatusDokumen.berlaku,
    this.dibatalkanPada,
    this.catatanPelanggan,
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
  final StatusDokumen status;
  final DateTime? dibatalkanPada;

  /// Catatan lab untuk pelanggan (pada `digantikan`: catatan revisinya; pada
  /// `dibatalkan`: catatan pembatalan).
  final String? catatanPelanggan;

  bool get digantikan => status == StatusDokumen.digantikan;
  bool get dibatalkan => status == StatusDokumen.dibatalkan;

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
    final pengganti = RingkasSertifikat.dariJson(j['digantikan_oleh']);
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
      digantikanOleh: pengganti,
      // Server lama tidak mengirim `status`: yang punya pengganti = digantikan.
      status:
          StatusDokumen.dariApi(j['status'] as String?) ??
          (pengganti != null
              ? StatusDokumen.digantikan
              : StatusDokumen.berlaku),
      dibatalkanPada: Format.baca(j['dibatalkan_pada'] as String?),
      catatanPelanggan: _teksBersih(j['catatan_pelanggan']),
      bisaDiunduh: j['bisa_diunduh'] == true,
      tautanVerifikasi: j['tautan_verifikasi'] as String?,
      rincian: rincian,
      penandaTangan: ttd is Map && ttd['nama'] != null
          ? [ttd['nama'], ttd['jabatan']].where((s) => s != null).join(', ')
          : null,
    );
  }
}

// ── Beranda ──────────────────────────────────────────────────────────────

class Beranda {
  const Beranda({
    required this.namaPerusahaan,
    required this.jumlahAlat,
    required this.lewatJatuhTempo,
    required this.segeraJatuhTempo,
    required this.notifikasiBelumDibaca,
    required this.jendelaHari,
  });

  final String namaPerusahaan;
  final int jumlahAlat;
  final int lewatJatuhTempo;
  final int segeraJatuhTempo;
  final int notifikasiBelumDibaca;
  final int jendelaHari;

  /// Alat yang jadwalnya aman = sisanya (server tidak punya saringan `aman`).
  int get aman {
    final n = jumlahAlat - lewatJatuhTempo - segeraJatuhTempo;
    return n < 0 ? 0 : n;
  }

  factory Beranda.dariJson(Map<String, dynamic> badan) {
    final d = badan['data'] as Map<String, dynamic>;
    final r = (d['ringkasan'] as Map?) ?? const {};
    return Beranda(
      namaPerusahaan: '${(d['perusahaan'] as Map?)?['nama'] ?? ''}',
      jumlahAlat: _int(r['jumlah_alat']) ?? 0,
      lewatJatuhTempo: _int(r['lewat_jatuh_tempo']) ?? 0,
      segeraJatuhTempo: _int(r['segera_jatuh_tempo']) ?? 0,
      notifikasiBelumDibaca: _int(r['notifikasi_belum_dibaca']) ?? 0,
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
    this.tautanTipe,
    this.tautanId,
  });

  final String id;
  final String judul;
  final String? isi;
  final String kategori;
  final bool dibaca;
  final DateTime? dibuat;

  /// Tujuan ketukan (`{"tipe":"pelanggan_sertifikat","id":12}`). Kosong untuk
  /// notifikasi yang tidak punya layar tujuan.
  final String? tautanTipe;
  final int? tautanId;

  Notifikasi tandaiDibaca() => Notifikasi(
    id: id,
    judul: judul,
    isi: isi,
    kategori: kategori,
    dibaca: true,
    dibuat: dibuat,
    tautanTipe: tautanTipe,
    tautanId: tautanId,
  );

  factory Notifikasi.dariJson(Map<String, dynamic> j) => Notifikasi(
    id: '${j['id']}',
    judul: '${j['judul'] ?? 'Pemberitahuan'}',
    isi: j['isi'] as String?,
    kategori: '${j['kategori'] ?? 'umum'}',
    dibaca: j['dibaca'] == true,
    dibuat: Format.baca(j['dibuat_pada'] as String?),
    tautanTipe: j['tautan'] is Map
        ? (j['tautan'] as Map)['tipe'] as String?
        : null,
    tautanId: j['tautan'] is Map ? _int((j['tautan'] as Map)['id']) : null,
  );
}

/// Satu halaman hasil ber-paginasi.
class Halaman<T> {
  const Halaman({
    required this.isi,
    required this.halaman,
    required this.halamanTerakhir,
    required this.total,
    this.jumlah = const {},
  });

  final List<T> isi;
  final int halaman;
  final int halamanTerakhir;
  final int total;

  /// Angka dari `meta` yang tidak bergantung halaman: `jumlah.*` (tab
  /// dan `belum_dibaca` (notifikasi).
  final Map<String, int> jumlah;

  bool get adaLagi => halaman < halamanTerakhir;

  static Halaman<T> dariJson<T>(
    Map<String, dynamic> badan,
    T Function(Map<String, dynamic>) ubah,
  ) {
    final meta = (badan['meta'] as Map?) ?? const {};
    final isi = [
      for (final x in (badan['data'] as List? ?? const []))
        ubah(x as Map<String, dynamic>),
    ];
    return Halaman<T>(
      isi: isi,
      halaman: _int(meta['current_page']) ?? 1,
      halamanTerakhir: _int(meta['last_page']) ?? 1,
      total: _int(meta['total']) ?? isi.length,
      jumlah: angkaMeta(meta),
    );
  }
}

/// `meta.jumlah.*` dan `meta.belum_dibaca` jadi satu peta angka.
Map<String, int> angkaMeta(Map meta) {
  final hasil = <String, int>{};
  final jumlah = meta['jumlah'];
  if (jumlah is Map) {
    for (final e in jumlah.entries) {
      final v = _int(e.value);
      if (v != null) hasil['${e.key}'] = v;
    }
  }
  final belum = _int(meta['belum_dibaca']);
  if (belum != null) hasil['belum_dibaca'] = belum;
  return hasil;
}
