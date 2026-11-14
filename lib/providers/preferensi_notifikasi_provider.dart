import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api_pelanggan.dart';
import '../models/preferensi_notifikasi.dart';
import 'koneksi_provider.dart';
import 'sesi_provider.dart';

/// Saklar notifikasi anggota ini di perusahaan aktif (server menyimpannya per
/// anggota per perusahaan). Diikat ke akun dan perusahaan aktif: berganti
/// salah satunya = dimuat ulang dari nol, tanpa sisa saklar PT lama.
///
/// Tanpa coba-ulang otomatis: layar punya tombol "Coba lagi", dan tiap ulangan
/// diam-diam membuat skeleton berkedip lama sebelum galatnya terbaca.
final preferensiNotifikasiProvider =
    AsyncNotifierProvider.autoDispose<
      PreferensiNotifikasiController,
      KeadaanPreferensi
    >(PreferensiNotifikasiController.new, retry: (_, _) => null);

/// Aturan simpan (satu kunci = satu antrean):
///
/// - Ketukan langsung terlihat (optimistis), lalu dikirim sebagai `PUT`
///   sebagian `{kunci: nilai}`.
/// - Satu kunci paling banyak SATU permintaan berjalan. Ketukan kedua pada
///   kunci yang sama selagi menunggu hanya mengganti nilai yang diinginkan;
///   sesudah jawaban datang, nilai terbaru dikirim. Dua `PUT` bersamaan untuk
///   kunci yang sama bisa tiba di server dalam urutan terbalik, dan nilai akhir
///   di server tak lagi sama dengan yang tampil.
/// - Jawaban server membawa SELURUH set, tetapi hanya kunci yang dikirim yang
///   dipercaya: jawaban untuk A bisa tiba sesudah jawaban untuk B dan membawa B
///   yang sudah usang.
/// - Gagal: HANYA kunci itu yang dikembalikan ke nilai terakhir yang
///   dikonfirmasi server, dengan kalimat penyebabnya; kunci lain tidak ikut
///   berubah. 403 membuat layar baca-saja.
/// - Penyimpanan diselesaikan walau layar sudah ditutup (provider ditahan
///   selama ada permintaan berjalan). Permintaan yang masih berjalan saat
///   akun/perusahaan berganti dilepas hasilnya (nomor [_generasi]).
class PreferensiNotifikasiController extends AsyncNotifier<KeadaanPreferensi> {
  /// Naik tiap [build] dan tiap provider dibuang; pekerjaan lama yang tiba
  /// terlambat membandingkan nomornya dan berhenti bila sudah usang.
  var _generasi = 0;

  /// Nilai terakhir yang DIKONFIRMASI server per kunci kategori.
  var _tersimpan = <String, bool>{};

  /// Jawaban `GET` apa adanya (termasuk kunci yang tidak digambar), dasar untuk
  /// menulis ulang cache `GET` sesudah tiap simpan yang dikonfirmasi.
  var _mentah = <String, bool>{};

  /// Nilai yang diinginkan pengguna dan belum dikonfirmasi.
  final _diminta = <String, bool>{};

  /// Kunci yang punya permintaan berjalan.
  final _berjalan = <String>{};

  bool _hidup(int generasi) => generasi == _generasi;

  @override
  Future<KeadaanPreferensi> build() async {
    final generasi = ++_generasi;
    ref.onDispose(() => _generasi++);
    _tersimpan = {};
    _mentah = {};
    _diminta.clear();
    _berjalan.clear();

    ref.watch(
      sesiProvider.select((s) => (s.value?.akun.id, s.value?.perusahaanId)),
    );
    final layanan = ref.watch(layananProvider);
    final mentah = await layanan.preferensiNotifikasi();

    // Kunci yang tidak dikenal (kategori baru dari server) dan `pesan_lab`
    // dibuang di sini, jadi layar tidak pernah menggambar saklar yang tidak
    // bisa disimpan. Kunci dikenal yang tidak dikirim server tidak digambar.
    if (_hidup(generasi)) {
      _mentah = mentah;
      _tersimpan = {
        for (final k in KategoriKabar.daftar)
          if (mentah[k.kunci] != null) k.kunci: mentah[k.kunci]!,
      };
    }
    // Jawaban GET yang datang dari simpanan HP menyalakan `offline` bersama
    // waktunya; GET yang berhasil mematikannya.
    final k = ref.read(koneksiProvider);
    return KeadaanPreferensi(
      nilai: Map.of(_tersimpan),
      dataTerakhir: k.offline ? k.dataTerakhir : null,
    );
  }

  /// Ketukan pada saklar [kunci]. Tidak melempar: hasilnya (tersimpan, atau
  /// dikembalikan beserta penyebabnya) ada di state.
  void ubah(String kunci, bool nilai) {
    final kini = state.value;
    if (kini == null || state.isLoading || !KategoriKabar.dikenal(kunci)) {
      return;
    }
    if (!kini.bisaUbah || !kini.nilai.containsKey(kunci)) return;
    if (kini.nilai[kunci] == nilai &&
        kini.tahapDari(kunci) != TahapSimpan.gagal) {
      return;
    }

    _diminta[kunci] = nilai;
    state = AsyncData(
      kini.salin(
        nilai: {...kini.nilai, kunci: nilai},
        tahap: {...kini.tahap, kunci: TahapSimpan.menyimpan},
        pesanGagal: {...kini.pesanGagal}..remove(kunci),
      ),
    );
    if (_berjalan.add(kunci)) unawaited(_kirim(kunci, _generasi));
  }

  /// Antrean satu kunci: kirim nilai yang diinginkan sampai tidak ada lagi
  /// yang berbeda dari yang dikonfirmasi server.
  Future<void> _kirim(String kunci, int generasi) async {
    final tahan = ref.keepAlive();
    final layanan = ref.read(layananProvider);
    try {
      while (_hidup(generasi)) {
        final mau = _diminta[kunci];
        if (mau == null) return;
        if (mau == _tersimpan[kunci]) {
          // Dibatalkan sendiri sebelum terkirim (diketuk dua kali).
          _diminta.remove(kunci);
          _setel(kunci, TahapSimpan.diam);
          return;
        }
        final Map<String, bool> jawaban;
        try {
          jawaban = await layanan.simpanPreferensiNotifikasi({kunci: mau});
        } catch (galat) {
          if (_hidup(generasi)) _gagal(kunci, galat);
          return;
        }
        if (!_hidup(generasi)) return;
        _terima(kunci, mau, jawaban);
      }
    } finally {
      if (_hidup(generasi)) _berjalan.remove(kunci);
      tahan.close();
    }
  }

  void _terima(String kunci, bool dikirim, Map<String, bool> jawaban) {
    final kini = state.value;
    if (kini == null) return;
    // Hanya kunci yang dikirim yang dipercaya dari jawaban ini. Jawaban memuat
    // seluruh set, tetapi jawaban untuk A bisa tiba SESUDAH jawaban untuk B
    // (dua sambungan, urutan tiba terbalik) dan membawa B yang sudah usang.
    // Perubahan dari HP lain terbaca saat layar dibuka lagi.
    _tersimpan[kunci] = jawaban[kunci] ?? dikirim;
    unawaited(_catatKeCache());

    // Selesai bila tidak ada ketukan yang lebih baru untuk kunci ini; kalau
    // ada, nilai yang tampil tetap ketukan itu dan antrean mengirimnya.
    if (_diminta[kunci] != dikirim) return;
    _diminta.remove(kunci);
    state = AsyncData(
      kini.salin(
        nilai: {...kini.nilai, kunci: _tersimpan[kunci]!},
        tahap: {...kini.tahap, kunci: TahapSimpan.diam},
      ),
    );
  }

  /// `PUT` tidak menyegarkan cache `GET`: tulis keadaan terkonfirmasi di HP ini
  /// (set GET terakhir + kunci yang sudah dikonfirmasi) supaya layar yang dibuka
  /// offline tidak menampilkan pilihan sebelum ketukan terakhir. Dari keadaan
  /// lokal, bukan dari jawaban PUT: jawaban untuk A bisa tiba sesudah jawaban
  /// untuk B dan membawa B yang usang.
  Future<void> _catatKeCache() async {
    try {
      await ref.read(layananProvider).catatPreferensiNotifikasi({
        ..._mentah,
        ..._tersimpan,
      });
    } catch (_) {}
  }

  void _gagal(String kunci, Object galat) {
    final kini = state.value;
    if (kini == null) return;
    _diminta.remove(kunci);
    final tanpaIzin = galat is GalatApi && galat.status == 403;
    final pesan = {...kini.pesanGagal};
    if (tanpaIzin) {
      pesan.remove(kunci);
    } else {
      pesan[kunci] = pesanGagalSimpan(galat);
    }
    state = AsyncData(
      kini.salin(
        // Kembali ke nilai terakhir yang dikonfirmasi; kunci lain tidak ikut.
        nilai: {
          ...kini.nilai,
          if (_tersimpan.containsKey(kunci)) kunci: _tersimpan[kunci]!,
        },
        tahap: {
          ...kini.tahap,
          kunci: tanpaIzin ? TahapSimpan.diam : TahapSimpan.gagal,
        },
        pesanGagal: pesan,
        alasanBacaSaja: tanpaIzin ? alasanTanpaIzinUbah : null,
      ),
    );
  }

  void _setel(String kunci, TahapSimpan tahap) {
    final kini = state.value;
    if (kini == null) return;
    state = AsyncData(kini.salin(tahap: {...kini.tahap, kunci: tahap}));
  }
}
