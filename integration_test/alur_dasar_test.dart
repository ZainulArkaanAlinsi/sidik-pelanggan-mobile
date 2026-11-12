// Alur dasar di PERANGKAT (emulator/HP): masuk lewat undangan → daftar
// sertifikat → detail → unduh PDF → keluar. Server, Keystore, folder dokumen,
// dan pembuka PDF dipalsukan; yang jalan asli adalah aplikasi, mesin Flutter
// di perangkat, dan seluruh lapisan layanan.
//
// TIDAK dijalankan di laptop kerja (perlu emulator; laptop ini bluescreen
// kalau emulator dan build jalan bersamaan). Skenario yang sama jalan tanpa
// perangkat di `test/alur_dasar_test.dart` (`flutter test`) — itu yang
// dijalankan lokal dan di CI. Berkas ini untuk saat ada perangkat:
//
//     flutter test integration_test -d <id-perangkat>
//
// CI saat ini (.github/workflows/periksa.yml) hanya analyze + `flutter test`,
// jadi berkas ini baru dijalankan kalau job emulator ditambahkan.
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../test/dukungan/alur_dasar.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() => initializeDateFormatting('id_ID'));

  testWidgets('akun baru: undangan → sertifikat → unduh → keluar', (
    tester,
  ) async {
    final hasil = await jalankanAlurDasar(tester);
    periksaHasilAlur(hasil);
  });

  testWidgets('email sudah punya akun: dialog penjelasan muncul, alur lanjut', (
    tester,
  ) async {
    final hasil = await jalankanAlurDasar(tester, akunSudahAda: true);
    periksaHasilAlur(hasil);
  });
}
