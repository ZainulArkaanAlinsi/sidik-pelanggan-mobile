import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/penyimpan_perangkat.dart';

final penyimpanPerangkatProvider = Provider<PenyimpanPerangkat>(
  (ref) => PenyimpanPerangkat(),
);

/// Sudah pernah melihat layar sambutan di HP ini? Dibaca sekali saat
/// aplikasi dibuka; [SambutanController.tandai] dipanggil begitu pengguna
/// memilih salah satu pintu.
final sambutanProvider = AsyncNotifierProvider<SambutanController, bool>(
  SambutanController.new,
);

class SambutanController extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    try {
      return await ref.read(penyimpanPerangkatProvider).sudahLihatSambutan();
    } catch (_) {
      // Penyimpanan rusak jangan mengurung pengguna di sambutan selamanya.
      return true;
    }
  }

  Future<void> tandai() async {
    state = const AsyncData(true);
    try {
      await ref.read(penyimpanPerangkatProvider).tandaiSambutan();
    } catch (_) {
      // Gagal menyimpan cuma berarti sambutan muncul lagi di peluncuran berikut.
    }
  }
}

/// Pilihan tema per HP. Default ikut sistem.
final temaProvider = AsyncNotifierProvider<TemaController, ThemeMode>(
  TemaController.new,
);

class TemaController extends AsyncNotifier<ThemeMode> {
  @override
  Future<ThemeMode> build() async {
    try {
      return switch (await ref.read(penyimpanPerangkatProvider).tema()) {
        'terang' => ThemeMode.light,
        'gelap' => ThemeMode.dark,
        _ => ThemeMode.system,
      };
    } catch (_) {
      return ThemeMode.system;
    }
  }

  Future<void> atur(ThemeMode mode) async {
    // Terapkan dulu, simpan belakangan: pengguna melihat hasilnya seketika.
    state = AsyncData(mode);
    final nilai = switch (mode) {
      ThemeMode.light => 'terang',
      ThemeMode.dark => 'gelap',
      ThemeMode.system => 'sistem',
    };
    try {
      await ref.read(penyimpanPerangkatProvider).simpanTema(nilai);
    } catch (_) {
      // Tema tetap berlaku di sesi ini; hanya tidak diingat setelah aplikasi ditutup.
    }
  }
}
