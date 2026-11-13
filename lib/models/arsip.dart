import 'data_pelanggan.dart';

/// Bentuk `GET /sertifikat/garis-waktu` (arsip sertifikat menurut tanggal
/// terbit: tahun, bulan, pekan, hari) — cermin kontrak "Arsip & Pencarian".
///
/// SEMUA hitungan datang dari server: pengelompokan, nomor pekan ISO, label
/// ("Pekan 46 (9–15 Nov 2026)"), dan jumlah. Berkas ini hanya membaca jawaban
/// dan menyusun parameter permintaan berikutnya dari `telusuri` yang dikirim
/// server; tidak ada tanggal yang dihitung atau digeser zona di sini.
///
/// Pencarian TIDAK lewat garis waktu: kata cari memakai daftar sertifikat
/// (`GET /sertifikat?q=`) agar hasilnya langsung berupa daftar datar. Garis
/// waktu hanya menampilkan arsip tanpa kata cari.

int? _bulat(Object? v) => v is num ? v.toInt() : int.tryParse('${v ?? ''}');

String? _teks(Object? v) {
  final s = v == null ? null : '$v'.trim();
  return s == null || s.isEmpty ? null : s;
}

/// Daftar objek JSON; butir yang bukan objek dilewati, bukan melempar.
List<Map<String, dynamic>> _daftarPeta(Object? v) => [
  if (v is List)
    for (final x in v)
      if (x is Map<String, dynamic>) x,
];

/// Tingkat penelusuran arsip, dari yang paling kasar.
enum TingkatArsip {
  tahun,
  bulan,
  pekan,
  hari;

  /// Kode di jawaban server. Kode yang tidak dikenal dibaca [tahun] (tingkat
  /// bawaan server) supaya layar tidak pecah bila server menambah tingkat.
  static TingkatArsip dariApi(Object? kode) => switch (kode) {
    'bulan' => bulan,
    'pekan' => pekan,
    'hari' => hari,
    _ => tahun,
  };
}

/// Aturan kata cari yang dikirim ke server, satu tempat untuk pencarian arsip.
///
/// Satu huruf mencocokkan hampir semua baris, jadi tidak dikirim (kontrak
/// "Arsip & Pencarian" §1: kirim `q` hanya bila minimal 2 karakter sesudah
/// `trim`; kosong = jangan kirim parameternya). Di atas 100 karakter server
/// menjawab 422, jadi kata dipotong. Kata dikirim APA ADANYA sesudah itu:
/// `/`, `-`, spasi, dan huruf besar-kecil tidak diubah.
abstract final class KataCari {
  /// Kata cari terpendek yang dikirim.
  static const minimal = 2;

  /// Kata cari terpanjang yang diterima server.
  static const maksimal = 100;

  /// [kata] yang boleh dikirim: dipangkas, kosong bila kurang dari [minimal]
  /// karakter, dan dipotong di [maksimal] karakter.
  static String rapikan(String kata) {
    final t = kata.trim();
    final huruf = t.runes.toList();
    if (huruf.length < minimal) return '';
    return huruf.length <= maksimal
        ? t
        : String.fromCharCodes(huruf.take(maksimal));
  }
}

/// Satu langkah penelusuran: parameter query yang MENGANTAR ke satu tampilan
/// arsip. Dipakai sebagai kunci provider, jadi sama persis berarti `==`.
///
/// Parameter penelusuran TIDAK disusun di aplikasi: [KelompokArsip.parameter]
/// meneruskan `telusuri` dari server apa adanya. Hanya [akar] (tingkat tahun,
/// tanpa induk) yang dibuat langsung, dan ia tidak mengirim parameter apa pun.
class ParameterArsip {
  const ParameterArsip._(this._telusuri);

  /// Tampilan awal: kelompok per tahun, seluruh arsip perusahaan.
  static const akar = ParameterArsip._({});

  final Map<String, String> _telusuri;

  /// Tampilan awal tanpa induk (hanya ini yang menampilkan kolom cari).
  bool get adalahAkar => _telusuri.isEmpty;

  TingkatArsip get tingkat => TingkatArsip.dariApi(_telusuri['tingkat']);

  /// Query `GET /sertifikat/garis-waktu`: `telusuri` server + nomor halaman.
  Map<String, String?> query({int halaman = 1}) => {
    ..._telusuri,
    'page': '$halaman',
  };

  String get _kunci {
    final kunci = _telusuri.keys.toList()..sort();
    return [for (final k in kunci) '$k=${_telusuri[k]}'].join('&');
  }

  @override
  bool operator ==(Object other) =>
      other is ParameterArsip && other._kunci == _kunci;

  @override
  int get hashCode => _kunci.hashCode;

  @override
  String toString() => 'ParameterArsip($_kunci)';
}

/// Satu kelompok di jawaban: satu tahun, bulan, pekan, atau hari.
class KelompokArsip {
  const KelompokArsip({
    required this.kunci,
    required this.label,
    required this.jumlah,
    this.mulai,
    this.selesai,
    this.telusuri = const {},
  });

  /// `"2026"`, `"2026-11"`, `"2026-W46"`, atau `"2026-11-12"`.
  final String kunci;

  /// Sudah berbahasa Indonesia dari server; tidak dihitung ulang.
  final String label;

  /// Jumlah sertifikat di kelompok ini (hitungan server).
  final int jumlah;

  /// Rentang kelompok sebagai tanggal polos `YYYY-MM-DD` (pekan sudah dipotong
  /// ke bulannya). Dibiarkan teks: tidak diurai supaya tidak bergeser zona.
  final String? mulai;
  final String? selesai;

  /// Query tingkat berikutnya, persis dari server.
  final Map<String, String> telusuri;

  /// Penelusuran ke dalam kelompok ini.
  ParameterArsip get parameter => ParameterArsip._(telusuri);

  factory KelompokArsip.dariJson(Map<String, dynamic> j) {
    final kunci = _teks(j['kunci']) ?? '';
    final telusuri = <String, String>{};
    final t = j['telusuri'];
    if (t is Map) {
      for (final e in t.entries) {
        final v = _teks(e.value);
        if (v != null) telusuri['${e.key}'] = v;
      }
    }
    return KelompokArsip(
      kunci: kunci,
      label: _teks(j['label']) ?? kunci,
      jumlah: _bulat(j['jumlah']) ?? 0,
      mulai: _teks(j['mulai']),
      selesai: _teks(j['selesai']),
      telusuri: Map.unmodifiable(telusuri),
    );
  }
}

/// Satu halaman jawaban garis waktu.
///
/// [kelompok] selalu ada di setiap tingkat; [item] hanya terisi di tingkat
/// [TingkatArsip.hari] dan berpaginasi (`meta`). Di tingkat lain `meta.total`
/// nol dan tidak ada halaman berikutnya.
class HasilArsip {
  const HasilArsip({
    required this.tingkat,
    this.totalDokumen,
    this.kelompok = const [],
    this.item = const [],
    this.tanggalItem = const [],
    this.halaman = 1,
    this.halamanTerakhir = 1,
    this.total = 0,
  });

  final TingkatArsip tingkat;

  /// `data.total_dokumen`: jumlah sertifikat dalam lingkup ini. `null` bila
  /// server tidak mengirimnya.
  final int? totalDokumen;
  final List<KelompokArsip> kelompok;

  /// Baris persis `GET /sertifikat` ditambah `nomor_order`
  /// ([Sertifikat.nomorOrder]); terbaru dulu (urutan server).
  final List<Sertifikat> item;

  /// Tanggal terbit tiap [item] (sejajar urutannya) sebagai `YYYY-MM-DD`,
  /// diambil dari 10 karakter pertama teks mentah server (tanggal kalender
  /// polos). Sengaja bukan dari `Sertifikat.diterbitkan`: itu `DateTime`
  /// yang bisa bergeser sehari bila server kelak mengirim cap waktu
  /// bersama zona. `null` = teksnya bukan tanggal.
  final List<String?> tanggalItem;
  final int halaman;
  final int halamanTerakhir;

  /// `meta.total`: jumlah [item] seluruh halaman.
  final int total;

  factory HasilArsip.dariJson(Map<String, dynamic> badan) {
    final data = badan['data'] is Map<String, dynamic>
        ? badan['data'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final meta = badan['meta'] is Map
        ? badan['meta'] as Map
        : const <String, dynamic>{};
    final mentah = _daftarPeta(data['item']);
    final item = [for (final s in mentah) Sertifikat.dariJson(s)];
    return HasilArsip(
      tingkat: TingkatArsip.dariApi(data['tingkat']),
      totalDokumen: _bulat(data['total_dokumen']),
      kelompok: [
        for (final k in _daftarPeta(data['kelompok']))
          KelompokArsip.dariJson(k),
      ],
      item: item,
      tanggalItem: [for (final s in mentah) _kunciHari(s['diterbitkan_pada'])],
      halaman: _bulat(meta['current_page']) ?? 1,
      halamanTerakhir: _bulat(meta['last_page']) ?? 1,
      total: _bulat(meta['total']) ?? item.length,
    );
  }

  /// Kunci `YYYY-MM-DD` dari teks tanggal mentah: 10 karakter pertama bila
  /// berbentuk tanggal. Tidak ada `DateTime` dan zona waktu di sini, jadi
  /// tanggal terbit tidak pernah bergeser sehari.
  static String? _kunciHari(Object? mentah) {
    final t = mentah is String ? mentah.trim() : '';
    if (t.length < 10) return null;
    final hari = t.substring(0, 10);
    return RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(hari) ? hari : null;
  }

  /// Jawaban ini sebagai satu halaman baris untuk daftar berhalaman.
  ///
  /// - Tingkat tahun, bulan, dan pekan: satu [BarisKelompok] per kelompok,
  ///   tanpa halaman berikutnya (server tidak memaginasi kelompok).
  /// - Tingkat hari: sertifikat ([BarisSertifikat]) berurut seperti dari server,
  ///   dengan [BarisHari] (label dan jumlah dari server) disisipkan di tiap
  ///   pergantian tanggal terbit. Kelompok hari yang kebetulan tidak punya
  ///   sertifikat di halaman ini tidak ditampilkan; sertifikat yang tanggalnya
  ///   tidak cocok dengan kelompok mana pun tampil tanpa judul hari.
  ///
  /// Nama hari/pekan dan jumlah TIDAK dihitung di sini; yang dikerjakan hanya
  /// mencocokkan kunci tanggal.
  Halaman<BarisArsip> get sebagaiHalaman {
    final jumlah = {'total_dokumen': ?totalDokumen};
    if (tingkat != TingkatArsip.hari) {
      final baris = <BarisArsip>[
        for (final k in kelompok) BarisKelompok(k, tingkat),
      ];
      return Halaman(
        isi: baris,
        halaman: 1,
        halamanTerakhir: 1,
        total: baris.length,
        jumlah: jumlah,
      );
    }
    final perHari = {for (final k in kelompok) k.kunci: k};
    final baris = <BarisArsip>[];
    String? sebelumnya;
    for (final (i, s) in item.indexed) {
      final hari = i < tanggalItem.length ? tanggalItem[i] : null;
      if (hari != null && hari != sebelumnya) {
        sebelumnya = hari;
        final k = perHari[hari];
        if (k != null) baris.add(BarisHari(k));
      }
      baris.add(BarisSertifikat(s));
    }
    return Halaman(
      isi: baris,
      halaman: halaman,
      halamanTerakhir: halamanTerakhir,
      total: total,
      jumlah: jumlah,
    );
  }
}

/// Satu baris daftar arsip. [kunci] membuang duplikat antarhalaman (judul hari
/// yang berlanjut ke halaman berikut tidak muncul dua kali).
sealed class BarisArsip {
  const BarisArsip();

  String get kunci;
}

/// Kelompok yang bisa dibuka (tahun, bulan, pekan). [tingkat] = tingkat
/// jawaban asalnya, untuk memilih ikon.
final class BarisKelompok extends BarisArsip {
  const BarisKelompok(this.kelompok, this.tingkat);

  final KelompokArsip kelompok;
  final TingkatArsip tingkat;

  @override
  String get kunci => 'k:${kelompok.kunci}';
}

/// Judul satu hari di atas sertifikat yang terbit pada hari itu.
final class BarisHari extends BarisArsip {
  const BarisHari(this.kelompok);

  final KelompokArsip kelompok;

  @override
  String get kunci => 'h:${kelompok.kunci}';
}

/// Satu sertifikat di tingkat hari.
final class BarisSertifikat extends BarisArsip {
  const BarisSertifikat(this.sertifikat);

  final Sertifikat sertifikat;

  @override
  String get kunci => 's:${sertifikat.id}';
}
