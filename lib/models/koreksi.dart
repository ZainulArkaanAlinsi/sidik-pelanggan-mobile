import '../core/format.dart';
import 'data_pelanggan.dart';

/// Permintaan koreksi dari pelanggan (`/koreksi`, `/alat/{id}/minta-koreksi`,
/// `/sertifikat/{id}/minta-koreksi`) — cermin §B4 `docs/perintah-frontend-
/// revisi-koreksi.md` di `sidik-calibration-api`.
///
/// Bentuk pelanggan TANPA `pelanggan` dan `ditinjau_oleh`: nama orang lab tidak
/// pernah dikirim ke sini, jadi tidak ada yang bisa ditampilkan.

int? _int(Object? v) => v is num ? v.toInt() : int.tryParse('${v ?? ''}');

String? _teks(Object? v) {
  final s = v == null ? null : '$v'.trim();
  return s == null || s.isEmpty ? null : s;
}

enum StatusKoreksi {
  menunggu,
  diterima,
  ditolak;

  /// Kode yang belum dikenal jatuh ke [menunggu] — tindakan pelanggan di
  /// layar (tambah foto) tetap dijaga server.
  static StatusKoreksi dariApi(String? kode) => switch (kode) {
    'diterima' => diterima,
    'ditolak' => ditolak,
    _ => menunggu,
  };

  String get label => switch (this) {
    menunggu => 'Menunggu ditinjau',
    diterima => 'Diterima',
    ditolak => 'Ditolak',
  };
}

class PerubahanKoreksi {
  const PerubahanKoreksi({
    required this.field,
    required this.label,
    this.lama,
    this.baru,
  });

  final String field;
  final String label;
  final String? lama;
  final String? baru;

  factory PerubahanKoreksi.dariJson(Map<String, dynamic> j) => PerubahanKoreksi(
    field: '${j['field'] ?? ''}',
    label: '${j['label'] ?? j['field'] ?? ''}',
    lama: _teks(j['lama']),
    baru: _teks(j['baru']),
  );
}

class Koreksi {
  const Koreksi({
    required this.id,
    required this.jenis,
    required this.status,
    this.diajukanOleh,
    this.diajukanPada,
    this.alatId,
    this.namaAlat,
    this.serialAlat,
    this.sertifikatId,
    this.nomorSertifikat,
    this.perubahan = const [],
    this.catatan,
    this.foto = const [],
    this.tanggapan,
    this.ditinjauPada,
    this.revisiId,
    this.nomorRevisi,
  });

  final int id;

  /// `alat` | `sertifikat`.
  final String jenis;
  final StatusKoreksi status;
  final String? diajukanOleh;
  final DateTime? diajukanPada;
  final int? alatId;
  final String? namaAlat;
  final String? serialAlat;
  final int? sertifikatId;
  final String? nomorSertifikat;
  final List<PerubahanKoreksi> perubahan;
  final String? catatan;
  final List<FotoPelanggan> foto;

  /// Jawaban lab — hanya ada sesudah diputus.
  final String? tanggapan;
  final DateTime? ditinjauPada;

  /// Sertifikat pengganti, kalau koreksi sertifikat diterima.
  final int? revisiId;
  final String? nomorRevisi;

  bool get menunggu => status == StatusKoreksi.menunggu;
  bool get untukSertifikat => jenis == 'sertifikat';

  String get judul => untukSertifikat
      ? 'Sertifikat ${nomorSertifikat ?? ''}'.trim()
      : (namaAlat ?? 'Alat');

  factory Koreksi.dariJson(Map<String, dynamic> j) {
    final alat = j['alat'];
    final sert = j['sertifikat'];
    final revisi = j['revisi'];
    final oleh = j['diajukan_oleh'];
    return Koreksi(
      id: _int(j['id']) ?? 0,
      jenis: '${j['jenis'] ?? 'alat'}',
      status: StatusKoreksi.dariApi(j['status'] as String?),
      diajukanOleh: oleh is Map ? _teks(oleh['nama']) : null,
      diajukanPada: Format.baca(j['diajukan_pada'] as String?),
      alatId: alat is Map ? _int(alat['id']) : null,
      namaAlat: alat is Map ? _teks(alat['nama']) : null,
      serialAlat: alat is Map ? _teks(alat['serial']) : null,
      sertifikatId: sert is Map ? _int(sert['id']) : null,
      nomorSertifikat: sert is Map ? _teks(sert['nomor']) : null,
      perubahan: [
        for (final p in (j['perubahan'] as List? ?? const []))
          if (p is Map<String, dynamic>) PerubahanKoreksi.dariJson(p),
      ],
      catatan: _teks(j['catatan']),
      foto: FotoPelanggan.daftar(j['foto']),
      tanggapan: _teks(j['tanggapan']),
      ditinjauPada: Format.baca(j['ditinjau_pada'] as String?),
      revisiId: revisi is Map ? _int(revisi['id']) : null,
      nomorRevisi: revisi is Map ? _teks(revisi['nomor']) : null,
    );
  }
}
