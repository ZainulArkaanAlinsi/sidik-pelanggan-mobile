import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/data_pelanggan.dart';

/// Isi daftar berhalaman yang sudah dimuat sejauh ini (infinite scroll).
@immutable
class DataBerhalaman<T> {
  const DataBerhalaman({
    this.isi = const [],
    this.halaman = 0,
    this.halamanTerakhir = 1,
    this.total = 0,
    this.jumlah = const {},
    this.memuatLagi = false,
    this.galatLagi,
  });

  final List<T> isi;

  /// Halaman terakhir yang SUDAH dimuat.
  final int halaman;
  final int halamanTerakhir;
  final int total;

  /// Angka meta dari halaman terbaru (`belum_dibaca`).
  final Map<String, int> jumlah;

  /// Halaman berikut sedang dimuat — baris pemuat di ujung daftar.
  final bool memuatLagi;

  /// Galat memuat halaman berikut. Isi yang sudah tampil TIDAK dibuang;
  /// ujung daftar menawarkan "Coba lagi".
  final Object? galatLagi;

  bool get adaLagi => halaman < halamanTerakhir;

  DataBerhalaman<T> salin({
    List<T>? isi,
    bool? memuatLagi,
    Object? galatLagi,
    bool hapusGalat = false,
  }) => DataBerhalaman<T>(
    isi: isi ?? this.isi,
    halaman: halaman,
    halamanTerakhir: halamanTerakhir,
    total: total,
    jumlah: jumlah,
    memuatLagi: memuatLagi ?? this.memuatLagi,
    galatLagi: hapusGalat ? null : (galatLagi ?? this.galatLagi),
  );
}

/// Dasar semua daftar ber-paginasi (alat, sertifikat, notifikasi).
///
/// Halaman 1 dimuat di [build] (jadi "tarik untuk muat ulang" dan
/// `invalidate` tetap bekerja seperti provider biasa); halaman berikut
/// ditambahkan [muatLagi] waktu daftar digulir mendekati ujung. Butir yang
/// sudah tampil di halaman sebelumnya tidak diulang ([kunciButir]) — server
/// menyisipkan baris baru di atas, jadi halaman 2 bisa memuat ulang ujung
/// halaman 1.
abstract class PaginasiController<T> extends AsyncNotifier<DataBerhalaman<T>> {
  /// Ambil satu halaman (mulai 1).
  @protected
  Future<Halaman<T>> ambil(int halaman);

  /// Identitas butir untuk membuang duplikat antarhalaman.
  @protected
  Object kunciButir(T butir);

  int _generasi = 0;

  @override
  Future<DataBerhalaman<T>> build() async {
    // Membangun ulang membatalkan `muatLagi` yang sedang di jalan.
    _generasi++;
    final h = await ambil(1);
    return DataBerhalaman<T>(
      isi: h.isi,
      halaman: h.halaman < 1 ? 1 : h.halaman,
      halamanTerakhir: h.halamanTerakhir,
      total: h.total,
      jumlah: h.jumlah,
    );
  }

  /// Muat halaman berikut. Aman dipanggil berkali-kali (mis. tiap piksel
  /// guliran): yang sedang memuat, sudah habis, atau sedang galat diabaikan.
  Future<void> muatLagi({bool ulangiGalat = false}) async {
    final s = state.value;
    if (s == null || state.isLoading || !s.adaLagi || s.memuatLagi) return;
    if (s.galatLagi != null && !ulangiGalat) return;

    final generasi = _generasi;
    state = AsyncData(s.salin(memuatLagi: true, hapusGalat: true));
    try {
      final h = await ambil(s.halaman + 1);
      // Daftar dibangun ulang (tarik untuk muat ulang, ganti perusahaan)
      // selagi halaman ini di jalan: buang hasilnya.
      if (!ref.mounted || generasi != _generasi) return;
      final ada = {for (final b in s.isi) kunciButir(b)};
      state = AsyncData(
        DataBerhalaman<T>(
          isi: [
            ...s.isi,
            for (final b in h.isi)
              if (ada.add(kunciButir(b))) b,
          ],
          halaman: h.halaman <= s.halaman ? s.halaman + 1 : h.halaman,
          // Halaman kosong = ujung daftar, apa pun kata `last_page`.
          halamanTerakhir: h.isi.isEmpty ? s.halaman + 1 : h.halamanTerakhir,
          total: h.total,
          jumlah: h.jumlah.isEmpty ? s.jumlah : h.jumlah,
        ),
      );
    } catch (e) {
      if (!ref.mounted || generasi != _generasi) return;
      state = AsyncData(s.salin(memuatLagi: false, galatLagi: e));
    }
  }
}
