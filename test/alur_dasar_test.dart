// Alur dasar seluruh aplikasi tanpa emulator: masuk lewat undangan → daftar
// sertifikat → detail → unduh PDF → keluar. Skenarionya sama dengan
// `integration_test/alur_dasar_test.dart` (yang butuh perangkat); versi ini
// jalan di `flutter test` — lokal dan di CI.
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'dukungan/alur_dasar.dart';

void main() {
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
