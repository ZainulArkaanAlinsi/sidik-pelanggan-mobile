import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:sidik_pelanggan/app.dart';
import 'package:sidik_pelanggan/core/api_pelanggan.dart';
import 'package:sidik_pelanggan/core/penyimpan_perangkat.dart';
import 'package:sidik_pelanggan/core/penyimpan_sesi.dart';
import 'package:sidik_pelanggan/core/theme/sidik_theme.dart';
import 'package:sidik_pelanggan/models/akun.dart';
import 'package:sidik_pelanggan/models/data_pelanggan.dart';
import 'package:sidik_pelanggan/models/rilis_aplikasi.dart';
import 'package:sidik_pelanggan/providers/pembaruan_provider.dart';
import 'package:sidik_pelanggan/providers/perangkat_provider.dart';
import 'package:sidik_pelanggan/providers/push_provider.dart';
import 'package:sidik_pelanggan/providers/sesi_provider.dart';
import 'package:sidik_pelanggan/screens/akun/akun_screen.dart';
import 'package:sidik_pelanggan/screens/auth/masuk_screen.dart';
import 'package:sidik_pelanggan/screens/beranda/beranda_screen.dart';
import 'package:sidik_pelanggan/screens/gerbang.dart';
import 'package:sidik_pelanggan/screens/rangka.dart';
import 'package:sidik_pelanggan/screens/sertifikat/sertifikat_detail_screen.dart';
import 'package:sidik_pelanggan/services/klien_rilis.dart';
import 'package:sidik_pelanggan/services/layanan_pelanggan.dart';
import 'package:sidik_pelanggan/services/pemasang_apk.dart';
import 'package:sidik_pelanggan/services/push_pelanggan.dart';

/// HP murah: layar 320 dp + huruf diperbesar pemiliknya. Aplikasi menjepit
/// skala huruf ke 1,3× (`batasSkalaHuruf` di app.dart); layar kunci harus
/// tetap tanpa luapan (overflow) di batas itu.

class _Perangkat extends PenyimpanPerangkat {
  @override
  Future<bool> sudahLihatSambutan() async => true;

  @override
  Future<String?> tema() async => null;
}

class _Sunyi extends PenyimpanSesi {
  @override
  Future<String?> token() async => null;
}

/// Nama dan nilai panjang sengaja: itulah yang meluap di layar sempit.
const _perusahaan = 'PT Instrumentasi Presisi Nusantara Sejahtera Abadi';

Akun _akun() => Akun.dariJson({
  'id': 7,
  'nama': 'Bernadette Kusumawardhani Wicaksono',
  'email': 'bernadette.kusumawardhani@instrumentasi-nusantara.co.id',
  'telepon': '+62 812 3456 7890',
  'jabatan': 'Koordinator Mutu & Kalibrasi',
  'status': 'aktif',
  'keanggotaan': [
    {'customer_id': 3, 'nama_perusahaan': _perusahaan, 'peran': 'pic'},
  ],
});

class _SesiTetap extends SesiController {
  @override
  Future<Sesi?> build() async => Sesi(akun: _akun(), perusahaanId: 3);
}

class _Palsu extends LayananPelanggan {
  _Palsu() : super(ApiPelanggan());

  @override
  Future<Beranda> beranda() async => Beranda.dariJson({
    'data': {
      'perusahaan': {'nama': _perusahaan},
      'ringkasan': {
        'jumlah_alat': 1288,
        'lewat_jatuh_tempo': 120,
        'segera_jatuh_tempo': 340,
        'notifikasi_belum_dibaca': 999,
      },
    },
    'meta': {'jendela_segera_hari': 30},
  });

  @override
  Future<Halaman<Alat>> daftarAlat({
    String? cari,
    String? saring,
    int halaman = 1,
  }) async => Halaman(
    isi: [
      for (final (i, hari, status) in [
        (1, -365, 'lewat_jadwal'),
        (2, 12, 'mendekati_jadwal'),
        (3, 200, 'terkalibrasi'),
      ])
        Alat.dariJson({
          'id': i,
          'nama': 'Digital Pressure Calibrator Multifungsi $i',
          'merk': 'Fluke Calibration',
          'serial': 'SN-2026-000000$i',
          'hari_ke_jatuh_tempo': hari,
          'tanggal_jatuh_tempo': '2026-11-01',
          'status_alat': status,
        }),
    ],
    halaman: 1,
    halamanTerakhir: 1,
    total: 3,
  );

  @override
  Future<Sertifikat> sertifikat(int id) async => Sertifikat.dariJson({
    'id': id,
    'nomor': 'CAL/2026/09/000123-REV.2',
    'diterbitkan_pada': '2026-09-20',
    'berlaku_sampai': '2027-09-20',
    'keputusan': 'sesuai',
    'status': 'digantikan',
    'digantikan_oleh': {'id': 99, 'nomor': 'CAL/2026/10/000456-REV.3'},
    'catatan_pelanggan': 'Koreksi penulisan nomor seri pada halaman 1.',
    'alat': {
      'id': 1,
      'nama': 'Digital Pressure Calibrator Multifungsi',
      'merk': 'Fluke Calibration',
      'model': '2271A-NA-P30M-P70M',
      'serial': 'SN-2026-0000001-ABCDEFGH',
    },
    'rincian': {
      'nomor_order': 'ORD/2026/09/000777',
      'tanggal_terima': '2026-09-10',
      'tanggal_kalibrasi': '2026-09-15',
      'lokasi_kalibrasi': 'Laboratorium Tekanan PT Sidik, Gedung B lantai 2',
      'metode': 'IK-TKN-01 (DKD-R 6-1) perbandingan langsung',
      'kondisi_lingkungan': '(23,0 ± 1,0) °C; (55 ± 10) %RH',
    },
    'penanda_tangan': {'nama': 'Dr. Ir. Raden Ayu Kusumaningrum, M.Sc.'},
    'bisa_diunduh': true,
  });
}

class _KlienRilis extends KlienRilisMati {
  _KlienRilis({required this.wajib});

  final bool wajib;

  @override
  Future<RilisAplikasi?> ambilTerbaru() async => RilisAplikasi(
    versi: '12.10.3',
    build: 99,
    url: Uri.parse('https://github.com/x/y/releases/download/v2/a.apk'),
    sha256: 'a' * 64,
    wajib: wajib,
    catatan: 'Perbaikan tampilan di HP layar kecil dan unduhan sertifikat.',
  );
}

final _dasar = <Override>[
  pemasangApkProvider.overrideWithValue(const PemasangApkMati()),
  penyimpanPerangkatProvider.overrideWithValue(_Perangkat()),
  infoPaketProvider.overrideWith((ref) async => (versi: '1.0.0', build: '1')),
  versiAplikasiProvider.overrideWith((ref) async => '1.0.0'),
  izinNotifikasiProvider.overrideWith(
    (ref) async => IzinNotifikasi.tidakTersedia,
  ),
];

/// Layar tanpa `SidikPelangganApp`: skala 1,3 dipasang lewat builder yang
/// sama bentuknya.
Widget _bungkus(Widget anak, {List<Override> tambahan = const []}) =>
    ProviderScope(
      overrides: [
        ..._dasar,
        ...tambahan,
        sesiProvider.overrideWith(_SesiTetap.new),
        layananProvider.overrideWithValue(_Palsu()),
      ],
      child: MaterialApp(
        theme: SidikTheme.terang,
        builder: (context, child) => MediaQuery.withClampedTextScaling(
          minScaleFactor: batasSkalaHuruf.max,
          maxScaleFactor: batasSkalaHuruf.max,
          child: child!,
        ),
        home: anak,
      ),
    );

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID');
    // Font asli: Ahem bawaan flutter_test selebar kotak dan tidak mewakili
    // lebar teks di HP.
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

  void layarSempit(WidgetTester tester, {double tinggi = 640}) {
    tester.view.physicalSize = Size(320, tinggi);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  void hurufHp(WidgetTester tester, double skala) {
    tester.platformDispatcher.textScaleFactorTestValue = skala;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  }

  Widget aplikasi({String versiMinimum = '0.0.0'}) => ProviderScope(
    overrides: [
      ..._dasar,
      penyimpanSesiProvider.overrideWithValue(_Sunyi()),
      statusAplikasiProvider.overrideWith(
        (ref) async => StatusAplikasi(
          versiMinimum: versiMinimum,
          versiTerbaru: '12.10.3',
          pemeliharaan: false,
          pesanPemeliharaan: '',
        ),
      ),
    ],
    child: const SidikPelangganApp(),
  );

  testWidgets('aplikasi menjepit huruf HP 2,0× ke 1,3×; Masuk tanpa luapan', (
    tester,
  ) async {
    layarSempit(tester);
    hurufHp(tester, 2.0);
    await tester.pumpWidget(aplikasi());
    await tester.pumpAndSettle();

    expect(find.byType(MasukScreen), findsOneWidget);
    final konteks = tester.element(find.byType(MasukScreen));
    expect(MediaQuery.textScalerOf(konteks).scale(10), closeTo(13, 1e-9));
    expect(tester.takeException(), isNull);
  });

  testWidgets('huruf HP 0,5× dinaikkan ke 0,8×', (tester) async {
    layarSempit(tester);
    hurufHp(tester, 0.5);
    await tester.pumpWidget(aplikasi());
    await tester.pumpAndSettle();

    final konteks = tester.element(find.byType(MasukScreen));
    expect(MediaQuery.textScalerOf(konteks).scale(10), closeTo(8, 1e-9));
  });

  testWidgets('layar wajib perbarui (gerbang) tanpa luapan di 1,3×', (
    tester,
  ) async {
    layarSempit(tester, tinggi: 560);
    hurufHp(tester, 2.0);
    await tester.pumpWidget(aplikasi(versiMinimum: '9.0.0'));
    await tester.pumpAndSettle();

    expect(find.byType(LayarWajibPerbarui), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Beranda tanpa luapan di 320 dp / 1,3×', (tester) async {
    layarSempit(tester);
    await tester.pumpWidget(_bungkus(const BerandaScreen()));
    await tester.pumpAndSettle();

    expect(find.text(_perusahaan), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Detail sertifikat tanpa luapan di 320 dp / 1,3×', (
    tester,
  ) async {
    layarSempit(tester);
    await tester.pumpWidget(_bungkus(const SertifikatDetailScreen(id: 1)));
    await tester.pumpAndSettle();

    expect(find.textContaining('CAL/2026/09/000123'), findsWidgets);
    // Seluruh isi digulir: luapan di bagian bawah juga harus ketahuan.
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -3000));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('Akun tanpa luapan di 320 dp / 1,3×', (tester) async {
    layarSempit(tester);
    await tester.pumpWidget(_bungkus(const AkunScreen()));
    await tester.pumpAndSettle();

    expect(find.textContaining('Bernadette'), findsWidgets);
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -3000));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('banner pembaruan di atas navigasi tanpa luapan', (tester) async {
    layarSempit(tester);
    await tester.pumpWidget(
      _bungkus(
        const Rangka(),
        tambahan: [
          pembaruanAktifProvider.overrideWithValue(true),
          klienRilisProvider.overrideWithValue(_KlienRilis(wajib: false)),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('banner-pembaruan')), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('dialog pembaruan wajib tanpa luapan', (tester) async {
    layarSempit(tester, tinggi: 560);
    await tester.pumpWidget(
      _bungkus(
        const Rangka(),
        tambahan: [
          pembaruanAktifProvider.overrideWithValue(true),
          klienRilisProvider.overrideWithValue(_KlienRilis(wajib: true)),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Pembaruan wajib'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('layar penuh memberi ruang navigasi sistem (edge-to-edge)', (
    tester,
  ) async {
    layarSempit(tester);
    // Navigasi tiga tombol: 48 dp di bawah.
    tester.view.padding = const FakeViewPadding(bottom: 48);
    tester.view.viewPadding = const FakeViewPadding(bottom: 48);
    addTearDown(tester.view.resetPadding);
    addTearDown(tester.view.resetViewPadding);

    await tester.pumpWidget(_bungkus(const SertifikatDetailScreen(id: 1)));
    await tester.pumpAndSettle();

    final daftar = tester.widget<ListView>(find.byType(ListView).first);
    expect(daftar.padding!.resolve(TextDirection.ltr).bottom, 32 + 48);
  });
}
