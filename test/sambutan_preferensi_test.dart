import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sidik_pelanggan/app.dart';
import 'package:sidik_pelanggan/core/penyimpan_perangkat.dart';
import 'package:sidik_pelanggan/core/penyimpan_sesi.dart';
import 'package:sidik_pelanggan/models/akun.dart';
import 'package:sidik_pelanggan/providers/perangkat_provider.dart';
import 'package:sidik_pelanggan/providers/sesi_provider.dart';
import 'package:sidik_pelanggan/screens/akun/preferensi_screen.dart';
import 'package:sidik_pelanggan/screens/auth/masuk_screen.dart';
import 'package:sidik_pelanggan/screens/auth/sambutan_screen.dart';
import 'package:sidik_pelanggan/screens/auth/terima_undangan_screen.dart';

/// Penyimpan di memori: test tidak boleh menyentuh Keystore sungguhan, dan
/// dua "peluncuran" di test berbagi satu instans ini supaya bisa membuktikan
/// nilai benar-benar diingat.
class _PerangkatMemori extends PenyimpanPerangkat {
  final Map<String, String> isi = {};

  @override
  Future<bool> sudahLihatSambutan() async => isi['sambutan'] == '1';

  @override
  Future<void> tandaiSambutan() async => isi['sambutan'] = '1';

  @override
  Future<String?> tema() async => isi['tema'];

  @override
  Future<void> simpanTema(String nilai) async => isi['tema'] = nilai;
}

/// Belum ada token → sesi `null` → gerbang jatuh ke Sambutan/Masuk.
class _SesiKosong extends PenyimpanSesi {
  @override
  Future<String?> token() async => null;
}

const _normal = StatusAplikasi(
  versiMinimum: '0.0.0',
  versiTerbaru: '1.0.0',
  pemeliharaan: false,
  pesanPemeliharaan: '',
);

Widget _aplikasi(
  _PerangkatMemori perangkat, {
  StatusAplikasi status = _normal,
}) => ProviderScope(
  overrides: [
    penyimpanPerangkatProvider.overrideWithValue(perangkat),
    penyimpanSesiProvider.overrideWithValue(_SesiKosong()),
    statusAplikasiProvider.overrideWith((ref) async => status),
    versiAplikasiProvider.overrideWith((ref) async => '1.0.0'),
  ],
  child: const SidikPelangganApp(),
);

void main() {
  testWidgets('peluncuran pertama menampilkan sambutan, bukan Masuk', (
    tester,
  ) async {
    await tester.pumpWidget(_aplikasi(_PerangkatMemori()));
    await tester.pumpAndSettle();

    expect(find.byType(SambutanScreen), findsOneWidget);
    expect(find.byType(MasukScreen), findsNothing);
  });

  testWidgets('peluncuran kedua melewati sambutan', (tester) async {
    final perangkat = _PerangkatMemori()..isi['sambutan'] = '1';
    await tester.pumpWidget(_aplikasi(perangkat));
    await tester.pumpAndSettle();

    expect(find.byType(SambutanScreen), findsNothing);
    expect(find.byType(MasukScreen), findsOneWidget);
  });

  testWidgets('tombol Masuk menandai sambutan dan membuka layar Masuk', (
    tester,
  ) async {
    final perangkat = _PerangkatMemori();
    await tester.pumpWidget(_aplikasi(perangkat));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Masuk'));
    await tester.pumpAndSettle();

    expect(find.byType(MasukScreen), findsOneWidget);
    expect(perangkat.isi['sambutan'], '1');
  });

  testWidgets('Pakai kode undangan membuka layar undangan, kembali ke Masuk', (
    tester,
  ) async {
    final perangkat = _PerangkatMemori();
    await tester.pumpWidget(_aplikasi(perangkat));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Pakai kode undangan'));
    await tester.pumpAndSettle();
    expect(find.byType(TerimaUndanganScreen), findsOneWidget);
    expect(perangkat.isi['sambutan'], '1');

    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    navigator.pop();
    await tester.pumpAndSettle();
    expect(find.byType(MasukScreen), findsOneWidget);
    expect(find.byType(SambutanScreen), findsNothing);
  });

  testWidgets('pemeliharaan menang atas sambutan', (tester) async {
    await tester.pumpWidget(
      _aplikasi(
        _PerangkatMemori(),
        status: const StatusAplikasi(
          versiMinimum: '0.0.0',
          versiTerbaru: '1.0.0',
          pemeliharaan: true,
          pesanPemeliharaan: 'Server diperbarui.',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Sedang dalam perbaikan'), findsOneWidget);
    expect(find.byType(SambutanScreen), findsNothing);
  });

  testWidgets('versi wajib perbarui menang atas sambutan', (tester) async {
    await tester.pumpWidget(
      _aplikasi(
        _PerangkatMemori(),
        status: const StatusAplikasi(
          versiMinimum: '2.0.0',
          versiTerbaru: '2.0.0',
          pemeliharaan: false,
          pesanPemeliharaan: '',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Perbarui aplikasi'), findsOneWidget);
    expect(find.byType(SambutanScreen), findsNothing);
  });

  group('preferensi', () {
    Future<void> bukaPreferensi(WidgetTester tester) async {
      final konteks = tester.element(find.byType(Scaffold).first);
      Navigator.of(
        konteks,
      ).push(MaterialPageRoute<void>(builder: (_) => const PreferensiScreen()));
      await tester.pumpAndSettle();
    }

    Brightness kecerahan(WidgetTester tester) =>
        Theme.of(tester.element(find.byType(PreferensiScreen))).brightness;

    testWidgets('memilih Gelap langsung berlaku dan disimpan', (tester) async {
      final perangkat = _PerangkatMemori()..isi['sambutan'] = '1';
      await tester.pumpWidget(_aplikasi(perangkat));
      await tester.pumpAndSettle();
      await bukaPreferensi(tester);
      expect(kecerahan(tester), Brightness.light);

      await tester.tap(find.text('Gelap'));
      await tester.pumpAndSettle();

      expect(kecerahan(tester), Brightness.dark);
      expect(perangkat.isi['tema'], 'gelap');
    });

    testWidgets('pilihan tema diingat di peluncuran berikutnya', (
      tester,
    ) async {
      final perangkat = _PerangkatMemori()
        ..isi['sambutan'] = '1'
        ..isi['tema'] = 'gelap';
      await tester.pumpWidget(_aplikasi(perangkat));
      await tester.pumpAndSettle();
      await bukaPreferensi(tester);

      expect(kecerahan(tester), Brightness.dark);
      final grup = tester.widget<RadioGroup<ThemeMode>>(
        find.byType(RadioGroup<ThemeMode>),
      );
      expect(grup.groupValue, ThemeMode.dark);
    });
    // Sakelar notifikasi kini disimpan di server — ujinya di permintaan_test.dart
    // (grup 'preferensi notifikasi') dengan layanan palsu.
  });
}
