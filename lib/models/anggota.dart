import '../core/format.dart';

/// `GET /anggota` (fixture `anggota.json` di repo API).
class DaftarAnggota {
  const DaftarAnggota({
    required this.anggota,
    required this.undanganMenunggu,
    required this.maksAnggota,
    required this.sayaPicUtama,
  });

  final List<Anggota> anggota;
  final List<UndanganMenunggu> undanganMenunggu;
  final int maksAnggota;
  final bool sayaPicUtama;

  factory DaftarAnggota.dariJson(Map<String, dynamic> badan) {
    final d = badan['data'] as Map<String, dynamic>;
    return DaftarAnggota(
      anggota: [
        for (final a in (d['anggota'] as List? ?? const []))
          Anggota.dariJson(a as Map<String, dynamic>),
      ],
      undanganMenunggu: [
        for (final u in (d['undangan_menunggu'] as List? ?? const []))
          UndanganMenunggu.dariJson(u as Map<String, dynamic>),
      ],
      maksAnggota: (d['maks_anggota'] as num?)?.toInt() ?? 0,
      sayaPicUtama: (d['saya'] as Map?)?['peran'] == 'pic_utama',
    );
  }
}

class Anggota {
  const Anggota({
    required this.id,
    required this.nama,
    required this.email,
    this.jabatan,
    required this.peran,
    required this.aktif,
    required this.saya,
    this.bergabung,
  });

  final int id;
  final String nama;
  final String email;
  final String? jabatan;
  final String peran;
  final bool aktif;
  final bool saya;
  final DateTime? bergabung;

  String get labelPeran => peran == 'pic_utama' ? 'PIC utama' : 'Staf';

  factory Anggota.dariJson(Map<String, dynamic> j) {
    final o = (j['orang'] as Map?) ?? const {};
    return Anggota(
      id: (j['id'] as num).toInt(),
      nama: '${o['nama'] ?? ''}',
      email: '${o['email'] ?? ''}',
      jabatan: o['jabatan'] as String?,
      peran: '${j['peran'] ?? 'staf'}',
      aktif: j['status'] == 'aktif',
      saya: j['saya'] == true,
      bergabung: Format.baca(j['bergabung_pada'] as String?),
    );
  }
}

class UndanganMenunggu {
  const UndanganMenunggu({
    required this.id,
    required this.email,
    required this.peran,
    this.kedaluwarsa,
  });

  final int id;
  final String email;
  final String peran;
  final DateTime? kedaluwarsa;

  factory UndanganMenunggu.dariJson(Map<String, dynamic> j) => UndanganMenunggu(
    id: (j['id'] as num).toInt(),
    email: '${j['email'] ?? ''}',
    peran: '${j['peran'] ?? 'staf'}',
    kedaluwarsa: Format.baca(j['kedaluwarsa_pada'] as String?),
  );
}
