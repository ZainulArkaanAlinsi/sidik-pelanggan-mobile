import '../core/format.dart';

/// Bentuk `GET /anggota` (kontrak §3) — cermin `AnggotaResource` di API.
///
/// Telepon anggota SENGAJA tidak dibaca walau server mengirimnya: layar ini
/// butuh nama, jabatan, dan email rekan; nomor HP orang lain tidak perlu
/// sampai ke memori layar yang tidak memakainya.

String? _teks(Object? v) {
  final s = v == null ? null : '$v'.trim();
  return s == null || s.isEmpty ? null : s;
}

class Anggota {
  const Anggota({
    required this.id,
    required this.nama,
    this.email,
    this.jabatan,
    required this.peran,
    required this.aktif,
    required this.saya,
    this.bergabung,
    this.dinonaktifkan,
  });

  /// ID keanggotaan (`customer_members.id`), bukan ID akun. Inilah yang
  /// dipakai `POST /anggota/{id}/nonaktifkan`.
  final int id;
  final String nama;
  final String? email;
  final String? jabatan;

  /// `pic_utama` atau `staf`.
  final String peran;
  final bool aktif;

  /// Dijawab SERVER — baris ini milik pemanggil. Jangan dihitung dari ID
  /// lokal.
  final bool saya;
  final DateTime? bergabung;
  final DateTime? dinonaktifkan;

  bool get picUtama => peran == 'pic_utama';

  String get labelPeran => picUtama ? 'PIC utama' : 'Staf';

  factory Anggota.dariJson(Map<String, dynamic> j) {
    final orang = (j['orang'] as Map?) ?? const {};
    return Anggota(
      id: (j['id'] as num).toInt(),
      nama: _teks(orang['nama']) ?? 'Tanpa nama',
      email: _teks(orang['email']),
      jabatan: _teks(orang['jabatan']),
      peran: '${j['peran'] ?? 'staf'}',
      aktif: j['status'] == 'aktif',
      saya: j['saya'] == true,
      bergabung: Format.baca(j['bergabung_pada'] as String?),
      dinonaktifkan: Format.baca(j['dinonaktifkan_pada'] as String?),
    );
  }
}

/// Undangan yang belum ditukar. Hanya dibaca; layar ini tidak membuat atau
/// membatalkan undangan.
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

  String get labelPeran => peran == 'pic_utama' ? 'PIC utama' : 'Staf';

  factory UndanganMenunggu.dariJson(Map<String, dynamic> j) => UndanganMenunggu(
    id: (j['id'] as num).toInt(),
    email: '${j['email'] ?? ''}',
    peran: '${j['peran'] ?? 'staf'}',
    kedaluwarsa: Format.baca(j['kedaluwarsa_pada'] as String?),
  );
}

class DaftarAnggota {
  const DaftarAnggota({
    required this.anggota,
    required this.undangan,
    required this.maksAnggota,
    required this.peranSaya,
  });

  final List<Anggota> anggota;
  final List<UndanganMenunggu> undangan;

  /// 0 = tanpa batas yang dikirim server.
  final int maksAnggota;

  /// Peran pemanggil di perusahaan aktif, menurut server (`data.saya.peran`).
  final String peranSaya;

  /// Hanya PIC utama yang boleh menonaktifkan anggota. Ini untuk MENYEMBUNYI-
  /// KAN tombol; yang menegakkan aturannya server (`peran:pic_utama`).
  bool get sayaPicUtama => peranSaya == 'pic_utama';

  int get jumlahAktif => anggota.where((a) => a.aktif).length;

  factory DaftarAnggota.dariJson(Map<String, dynamic> j) {
    final peranSaya = '${(j['saya'] as Map?)?['peran'] ?? 'staf'}';
    return DaftarAnggota(
      anggota: [
        for (final a in (j['anggota'] as List? ?? const []))
          Anggota.dariJson(a as Map<String, dynamic>),
      ],
      // Server mengirim `undangan_menunggu` ke semua peran. Alamat email
      // orang yang sedang diundang bukan urusan staf, jadi di sisi aplikasi
      // dibuang di sini, sebelum sampai ke layar mana pun. (Pembatasan di
      // server diminta di docs/kebutuhan-api-pelanggan.md.)
      undangan: peranSaya != 'pic_utama'
          ? const []
          : [
              for (final u in (j['undangan_menunggu'] as List? ?? const []))
                UndanganMenunggu.dariJson(u as Map<String, dynamic>),
            ],
      maksAnggota: (j['maks_anggota'] as num?)?.toInt() ?? 0,
      peranSaya: peranSaya,
    );
  }
}
