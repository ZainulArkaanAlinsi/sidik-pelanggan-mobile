// Alur pelacakan paket (P-4) tanpa emulator: masuk lewat undangan → Akun →
// Pelacakan paket → detail → Lihat sertifikat → riwayat Selesai. Skenarionya
// sama dengan `integration_test/alur_paket_test.dart` (yang butuh perangkat);
// versi ini jalan di `flutter test` — lokal dan di CI.
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'dukungan/alur_dasar.dart';

void main() {
  setUpAll(() => initializeDateFormatting('id_ID'));

  testWidgets('pelacakan paket: daftar → detail → sertifikat → riwayat', (
    tester,
  ) async {
    final hasil = await jalankanAlurPaket(tester);
    periksaHasilAlurPaket(hasil);
  });
}
