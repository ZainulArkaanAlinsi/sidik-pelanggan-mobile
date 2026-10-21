import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:sidik_pelanggan/core/api_pelanggan.dart';
import 'package:sidik_pelanggan/core/penyimpan_perangkat.dart';
import 'package:sidik_pelanggan/core/penyimpan_sesi.dart';
import 'package:sidik_pelanggan/core/theme/sidik_theme.dart';
import 'package:sidik_pelanggan/models/data_pelanggan.dart';
import 'package:sidik_pelanggan/providers/perangkat_provider.dart';
import 'package:sidik_pelanggan/providers/push_provider.dart';
import 'package:sidik_pelanggan/providers/sesi_provider.dart';
import 'package:sidik_pelanggan/screens/alat/alat_detail_screen.dart';
import 'package:sidik_pelanggan/screens/beranda/beranda_screen.dart';
import 'package:sidik_pelanggan/screens/rangka.dart';
import 'package:sidik_pelanggan/screens/sertifikat/sertifikat_screen.dart';
import 'package:sidik_pelanggan/services/layanan_pelanggan.dart';
import 'package:sidik_pelanggan/services/push_pelanggan.dart';

class _Sunyi extends PenyimpanSesi {
  @override
  Future<String?> token() async => null;
}

class _Perangkat extends PenyimpanPerangkat {
  @override
  Future<bool> sudahLihatSambutan() async => true;

  @override
  Future<String?> tema() async => null;
}

Alat _alat(int id, String nama, int? hari, String status) => Alat.dariJson({
  'id': id,
  'nama': nama,
  'merk': 'Mitutoyo',
  'serial': 'SN-$id',
  'hari_ke_jatuh_tempo': hari,
  'tanggal_jatuh_tempo': hari == null ? null : '2026-11-01',
  'status_alat': status,
});

Sertifikat _sertifikat(int id, String nomor) => Sertifikat.dariJson({
  'id': id,
  'nomor': nomor,
  'diterbitkan_pada': '2026-09-20',
  'alat': {'id': 1, 'nama': 'Jangka Sorong'},
  'bisa_diunduh': true,
});

Halaman<T> _halaman<T>(List<T> isi) =>
    Halaman(isi: isi, halaman: 1, halamanTerakhir: 1, total: isi.length);

/// Layanan palsu: mencatat parameter yang dikirim layar.
class _Palsu extends LayananPelanggan {
  _Palsu() : super(ApiPelanggan());

  final cariSertifikat = <String>[];
  final saringAlat = <String?>[];

  @override
  Future<Beranda> beranda() async => Beranda.dariJson({
    'data': {
      'perusahaan': {'nama': 'PT Contoh'},
      'ringkasan': {
        'jumlah_alat': 6,
        'lewat_jatuh_tempo': 1,
        'segera_jatuh_tempo': 2,
        'notifikasi_belum_dibaca': 3,
      },
    },
    'meta': {'jendela_segera_hari': 30},
  });

  @override
  Future<Halaman<Alat>> daftarAlat({
    String? cari,
    String? saring,
    int halaman = 1,
  }) async {
    saringAlat.add(saring);
    return _halaman([
      _alat(1, 'Jangka Sorong', -3, 'lewat_jadwal'),
      _alat(2, 'Timbangan', 12, 'mendekati_jadwal'),
      _alat(3, 'Termometer', 200, 'terkalibrasi'),
    ]);
  }

  @override
  Future<Alat> alat(int id) async => Alat.dariJson({
    'id': id,
    'nama': 'Jangka Sorong',
    'hari_ke_jatuh_tempo': 12,
    'tanggal_jatuh_tempo': '2026-11-01',
    'status_alat': 'mendekati_jadwal',
    'riwayat_sertifikat': [
      {
        'id': 9,
        'nomor': 'CAL/2026/09/0002',
        'alat': {'id': id, 'nama': 'Jangka Sorong'},
        'bisa_diunduh': true,
      },
    ],
  });

  @override
  Future<Halaman<Sertifikat>> daftarSertifikat({
    String? cari,
    bool termasukDigantikan = false,
    int halaman = 1,
  }) async {
    cariSertifikat.add(cari ?? '');
    final semua = [
      _sertifikat(9, 'CAL/2026/09/0002'),
      _sertifikat(8, 'CAL/2026/09/0001'),
    ];
    return _halaman([
      for (final s in semua)
        if (cari == null || cari.isEmpty || s.nomor.contains(cari)) s,
    ]);
  }

  @override
  Future<Halaman<Notifikasi>> daftarNotifikasi({int halaman = 1}) async =>
      _halaman(<Notifikasi>[]);

  @override
  Future<int> jumlahNotifikasiBelumDibaca() async => 3;
}

Widget _bungkus(Widget anak, _Palsu layanan) => ProviderScope(
  overrides: [
    penyimpanSesiProvider.overrideWithValue(_Sunyi()),
    penyimpanPerangkatProvider.overrideWithValue(_Perangkat()),
    layananProvider.overrideWithValue(layanan),
    infoPaketProvider.overrideWith((ref) async => (versi: '1.0.0', build: '1')),
    izinNotifikasiProvider.overrideWith(
      (ref) async => IzinNotifikasi.tidakTersedia,
    ),
  ],
  child: MaterialApp(theme: SidikTheme.terang, home: anak),
);

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID');
    // Font asli aplikasi: font bawaan flutter_test (Ahem) selebar kotak dan
    // membuat lencana status "meluap" yang tidak terjadi di HP.
    final inter = FontLoader('Inter');
    for (final f in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
      inter.addFont(
        Future.value(
          ByteData.sublistView(
            File('assets/fonts/Inter-$f.ttf').readAsBytesSync(),
          ),
        ),
      );
    }
    await inter.load();
  });

  testWidgets('Beranda: angka jatuh tempo, daftar alat dengan hitung mundur', (
    tester,
  ) async {
    await tester.pumpWidget(_bungkus(const BerandaScreen(), _Palsu()));
    await tester.pumpAndSettle();

    expect(find.text('PT Contoh'), findsOneWidget);
    // aman = 6 - 1 - 2
    expect(find.text('3'), findsWidgets);
    expect(find.text('Jangka Sorong'), findsOneWidget);
    expect(find.textContaining('Lewat 3 hari'), findsOneWidget);
    expect(find.textContaining('12 hari lagi'), findsOneWidget);
    // Fitur yang dibuang tidak ada lagi di layar.
    expect(find.textContaining('Ajukan'), findsNothing);
    expect(find.textContaining('Permintaan'), findsNothing);
  });

  testWidgets('Beranda: saringan "Lewat jadwal" mengirim saring=lewat', (
    tester,
  ) async {
    final palsu = _Palsu();
    await tester.pumpWidget(_bungkus(const BerandaScreen(), palsu));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ChoiceChip, 'Lewat jadwal'));
    await tester.pumpAndSettle();

    expect(palsu.saringAlat.last, 'lewat');
  });

  testWidgets('Detail alat: hitung mundur + riwayat, tanpa ubah/ajukan', (
    tester,
  ) async {
    await tester.pumpWidget(_bungkus(const AlatDetailScreen(id: 1), _Palsu()));
    await tester.pumpAndSettle();

    expect(find.text('12 hari lagi'), findsOneWidget);
    expect(find.text('RIWAYAT KALIBRASI'), findsOneWidget);
    expect(find.text('CAL/2026/09/0002'), findsOneWidget);
    expect(find.byIcon(Icons.edit_outlined), findsNothing);
    expect(find.textContaining('Ajukan'), findsNothing);
  });

  testWidgets('Sertifikat: cari nomor mengirim q, daftar tersaring', (
    tester,
  ) async {
    final palsu = _Palsu();
    await tester.pumpWidget(_bungkus(const SertifikatScreen(), palsu));
    await tester.pumpAndSettle();
    expect(find.text('CAL/2026/09/0001'), findsOneWidget);
    expect(find.text('CAL/2026/09/0002'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '0002');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(palsu.cariSertifikat.last, '0002');
    expect(find.text('CAL/2026/09/0001'), findsNothing);
    expect(find.text('CAL/2026/09/0002'), findsOneWidget);
  });

  testWidgets('Rangka: empat tab Beranda, Sertifikat, Notifikasi, Akun', (
    tester,
  ) async {
    await tester.pumpWidget(_bungkus(const Rangka(), _Palsu()));
    await tester.pumpAndSettle();

    final nav = find.byType(NavigationBar);
    for (final label in ['Beranda', 'Sertifikat', 'Notifikasi', 'Akun']) {
      expect(
        find.descendant(of: nav, matching: find.text(label)),
        findsOneWidget,
      );
    }
    expect(
      find.descendant(of: nav, matching: find.text('Permintaan')),
      findsNothing,
    );
    expect(find.descendant(of: nav, matching: find.text('Alat')), findsNothing);
  });
}
