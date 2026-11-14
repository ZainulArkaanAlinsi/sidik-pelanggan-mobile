// Layanan palsu untuk saklar notifikasi: "server" dengan lima kunci kontrak
// (docs/kontrak-api-pelanggan.md §14.4 di repo API) yang bisa ditahan, supaya
// test bisa mengatur URUTAN jawaban (balapan dua ketukan) dan kegagalan.
import 'dart:async';

import 'package:sidik_pelanggan/core/api_pelanggan.dart';

import 'dukungan.dart';

/// Satu `PUT /preferensi-notifikasi` yang diterima layanan palsu.
class PanggilanSimpan {
  PanggilanSimpan(this.badan, this.galat);

  /// Badan yang dikirim aplikasi (sebagian).
  final Map<String, bool> badan;

  /// Galat yang akan dilempar (`null` = berhasil).
  final Object? galat;

  /// Seluruh set pada saat server memproses panggilan ini (hanya bila berhasil).
  Map<String, bool>? jawaban;

  final gerbang = Completer<void>();
}

class LayananPreferensiPalsu extends LayananUji {
  LayananPreferensiPalsu({Map<String, bool>? awal})
    : server = {...(awal ?? kunciKontrak)};

  /// Persis bentuk contoh di kontrak §14.4.
  static const kunciKontrak = <String, bool>{
    'pengingat_jadwal': true,
    'status_permintaan': true,
    'pesan_lab': true,
    'ringkasan_email_mingguan': false,
    'tahap_alat': true,
  };

  /// Keadaan di server. Panggilan yang berhasil menerapkannya SAAT diproses;
  /// jawabannya baru tiba bila gerbangnya dibuka ([selesaikan]) ketika [tahan].
  Map<String, bool> server;

  /// Tiap `PUT`, berurutan.
  final panggilan = <PanggilanSimpan>[];

  /// Badan tiap `PUT`, berurutan.
  List<Map<String, bool>> get badan => [for (final p in panggilan) p.badan];

  /// Galat untuk `PUT` berikutnya, satu per panggilan (`null` = berhasil).
  final rencanaGalat = <Object?>[];

  /// `true`: tiap `PUT` menunggu [selesaikan].
  bool tahan = false;

  /// Berapa kali `GET` dipanggil.
  int muat = 0;

  /// Dilempar `GET` bila diisi.
  Object? galatMuat;

  /// Menggantikan jawaban `GET` (mis. kunci asing, daftar kosong).
  Map<String, bool>? jawabanMuat;

  /// Set yang dicatat ke cache `GET` (write-through), berurutan.
  final dicatat = <Map<String, bool>>[];

  /// Menimpa nilai di jawaban `PUT` (server yang mengoreksi pilihan).
  Map<String, bool>? jawabanPaksa;

  /// Dipanggil di awal `GET` (mis. mematikan penanda offline).
  void Function()? saatMuat;

  /// Tahan `GET` sampai [bukaMuat] selesai.
  Completer<void>? bukaMuat;

  @override
  Future<Map<String, bool>> preferensiNotifikasi() async {
    muat++;
    // Sesudah satu putaran: `ApiPelanggan` memanggil `saatOnline` setelah
    // jawaban HTTP tiba, tidak sinkron di dalam `build` provider.
    await Future<void>.value();
    saatMuat?.call();
    if (bukaMuat != null) await bukaMuat!.future;
    if (galatMuat != null) throw galatMuat!;
    return {...(jawabanMuat ?? server)};
  }

  @override
  Future<Map<String, bool>> simpanPreferensiNotifikasi(
    Map<String, bool> sebagian,
  ) async {
    final p = PanggilanSimpan(
      Map.of(sebagian),
      rencanaGalat.isEmpty ? null : rencanaGalat.removeAt(0),
    );
    panggilan.add(p);
    if (p.galat == null) {
      server = {...server, ...sebagian};
      p.jawaban = {...server, ...?jawabanPaksa};
    }
    if (tahan) await p.gerbang.future;
    if (p.galat != null) throw p.galat!;
    return p.jawaban!;
  }

  @override
  Future<void> catatPreferensiNotifikasi(Map<String, bool> set) async =>
      dicatat.add(Map.of(set));

  /// Buka gerbang panggilan ke-[i] (mulai dari 0).
  void selesaikan(int i) => panggilan[i].gerbang.complete();
}

/// Galat jaringan seperti yang dilempar `ApiPelanggan`.
GalatApi galatJaringan() => GalatApi.jaringan();

/// Galat HTTP [status] dengan pesan server.
GalatApi galatHttp(int status, [String pesan = 'Ditolak server.']) =>
    GalatApi(status: status, pesan: pesan);
