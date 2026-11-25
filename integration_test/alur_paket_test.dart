// Alur pelacakan paket (P-4) di PERANGKAT (emulator/HP): masuk lewat undangan →
// Akun → Pelacakan paket → detail → Lihat sertifikat → riwayat Selesai. Server
// dipalsukan; yang jalan asli adalah aplikasi, mesin Flutter di perangkat, dan
// seluruh lapisan layanan.
//
// TIDAK dijalankan di laptop kerja (perlu emulator; laptop ini bluescreen kalau
// emulator dan build jalan bersamaan). Skenario yang sama jalan tanpa perangkat
// di `test/alur_paket_test.dart` (`flutter test`) — itu yang dijalankan lokal
// dan di CI. Berkas ini untuk saat ada perangkat:
//
//     flutter test integration_test/alur_paket_test.dart -d <id-perangkat>
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../test/dukungan/alur_dasar.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() => initializeDateFormatting('id_ID'));

  testWidgets('pelacakan paket: daftar → detail → sertifikat → riwayat', (
    tester,
  ) async {
    final hasil = await jalankanAlurPaket(tester);
    periksaHasilAlurPaket(hasil);
  });
}
