import '../core/format.dart';

/// Bentuk `GET /paket` dan `GET /paket/{id}` (pelacakan order dari sisi
/// pelanggan) — cermin `PaketPelangganResource` di API.
///
/// Tahap & labelnya DIHITUNG SERVER (`TahapPaket`, label versi pelanggan);
/// aplikasi tidak menyusun urutan tahapnya sendiri.

String? _teks(Object? v) {
  final s = v == null ? null : '$v'.trim();
  return s == null || s.isEmpty ? null : s;
}

int _int(Object? v) => v is num ? v.toInt() : int.tryParse('${v ?? ''}') ?? 0;

class AlatPaket {
  const AlatPaket({
    required this.id,
    required this.nama,
    this.merk,
    this.serial,
    required this.tahap,
    required this.tahapLabel,
    this.diserahkanKepada,
    this.sertifikatId,
  });

  final int id;
  final String nama;
  final String? merk;
  final String? serial;
  final String tahap;
  final String tahapLabel;
  final String? diserahkanKepada;

  /// Hanya terisi untuk sertifikat berstatus terbit.
  final int? sertifikatId;

  factory AlatPaket.dariJson(Map<String, dynamic> j) => AlatPaket(
    id: _int(j['id']),
    nama: _teks(j['nama']) ?? 'Alat',
    merk: _teks(j['merk']),
    serial: _teks(j['serial']),
    tahap: '${j['tahap'] ?? ''}',
    tahapLabel: _teks(j['tahap_label']) ?? '${j['tahap'] ?? ''}',
    diserahkanKepada: _teks(j['diserahkan_kepada']),
    sertifikatId: j['sertifikat_id'] == null ? null : _int(j['sertifikat_id']),
  );
}

class Paket {
  const Paket({
    required this.id,
    required this.nomor,
    this.tanggalMasuk,
    this.tanggalJanjiSelesai,
    required this.terlambat,
    required this.tahap,
    required this.tahapLabel,
    required this.jumlahAlat,
    required this.jumlahSelesai,
    this.alat = const [],
  });

  final int id;
  final String nomor;
  final DateTime? tanggalMasuk;
  final DateTime? tanggalJanjiSelesai;
  final bool terlambat;
  final String tahap;
  final String tahapLabel;
  final int jumlahAlat;
  final int jumlahSelesai;
  final List<AlatPaket> alat;

  factory Paket.dariJson(Map<String, dynamic> j) => Paket(
    id: _int(j['id']),
    nomor: '${j['nomor'] ?? ''}',
    tanggalMasuk: Format.baca(j['tanggal_masuk'] as String?),
    tanggalJanjiSelesai: Format.baca(j['tanggal_janji_selesai'] as String?),
    terlambat: j['terlambat'] == true,
    tahap: '${j['tahap'] ?? ''}',
    tahapLabel: _teks(j['tahap_label']) ?? '${j['tahap'] ?? ''}',
    jumlahAlat: _int(j['jumlah_alat']),
    jumlahSelesai: _int(j['jumlah_selesai']),
    alat: [
      for (final a in (j['alat'] as List? ?? const []))
        AlatPaket.dariJson(a as Map<String, dynamic>),
    ],
  );
}

/// Satu langkah di garis waktu (`garis_waktu[]` pada detail). Urutan dan
/// penandanya dari server.
class LangkahPaket {
  const LangkahPaket({
    required this.kode,
    required this.label,
    required this.lewat,
    required this.sekarang,
  });

  final String kode;
  final String label;
  final bool lewat;
  final bool sekarang;

  factory LangkahPaket.dariJson(Map<String, dynamic> j) => LangkahPaket(
    kode: '${j['kode'] ?? ''}',
    label: '${j['label'] ?? j['kode'] ?? ''}',
    lewat: j['lewat'] == true,
    sekarang: j['sekarang'] == true,
  );
}

class DetailPaket {
  const DetailPaket({required this.paket, required this.garisWaktu});

  final Paket paket;
  final List<LangkahPaket> garisWaktu;

  factory DetailPaket.dariJson(Map<String, dynamic> badan) => DetailPaket(
    paket: Paket.dariJson(badan['data'] as Map<String, dynamic>),
    garisWaktu: [
      for (final l in (badan['garis_waktu'] as List? ?? const []))
        LangkahPaket.dariJson(l as Map<String, dynamic>),
    ],
  );
}
