// Fitur 2 + 3 (rencana §14.1): daftar alat dengan status, dan riwayat
// sertifikat per alat sebagai garis waktu di detail alat.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sidik_pelanggan/app.dart';
import 'package:sidik_pelanggan/core/tema/tema_sidik.dart';
import 'package:sidik_pelanggan/models/data_pelanggan.dart';
import 'package:sidik_pelanggan/models/status_berlaku.dart';
import 'package:sidik_pelanggan/screens/alat/alat_detail_screen.dart';
import 'package:sidik_pelanggan/screens/alat/daftar_alat_screen.dart';
import 'package:sidik_pelanggan/screens/sertifikat/sertifikat_detail_screen.dart';
import 'package:sidik_pelanggan/widgets/garis_waktu_sertifikat.dart';
import 'package:sidik_pelanggan/widgets/kartu_sidik.dart';
import 'package:sidik_pelanggan/widgets/kartu_alat.dart';

import 'dukungan/fixture_fitur.dart';

ServerFitur _server() => ServerFitur({
  3: DataPerusahaan(
    nama: 'PT Alfa',
    alat: [
      alatJson(1, 'Jangka Sorong', hari: -5, status: 'lewat_jadwal'),
      alatJson(2, 'Timbangan Analitik', hari: 12, status: 'mendekati_jadwal'),
      alatJson(3, 'Termometer', hari: 45),
      alatJson(4, 'Manometer', hari: 75),
      alatJson(5, 'Mikrometer', hari: 200),
      alatJson(6, 'Alat Nonaktif', hari: 10, status: 'nonaktif'),
      alatJson(7, 'Tanpa Jadwal', status: 'belum_pernah'),
      // Riwayat lengkap: revisi, digantikan, lama, dibatalkan, FAIL.
      alatJson(
        10,
        'Alat Riwayat',
        hari: 20,
        status: 'mendekati_jadwal',
        riwayat: [
          sertifikatJson(
            24,
            'CAL/2026/10/0024-R1',
            alatId: 10,
            diterbitkan: -20,
            berlakuSampai: 20,
            revisiDari: 'CAL/2026/10/0024',
          ),
          sertifikatJson(
            23,
            'CAL/2026/10/0024',
            alatId: 10,
            diterbitkan: -40,
            berlakuSampai: 40,
            status: 'digantikan',
            digantikanOleh: {
              'id': 24,
              'nomor': 'CAL/2026/10/0024-R1',
              'diterbitkan_pada': tanggalUji(-20),
            },
          ),
          sertifikatJson(
            22,
            'CAL/2025/10/0010',
            alatId: 10,
            diterbitkan: -400,
            berlakuSampai: -35,
          ),
          sertifikatJson(
            21,
            'CAL/2024/10/0005',
            alatId: 10,
            diterbitkan: -800,
            berlakuSampai: -430,
            status: 'dibatalkan',
            dibatalkanPada: -700,
            keputusan: 'FAIL',
          ),
          sertifikatJson(
            20,
            'CAL/2023/10/0001',
            alatId: 10,
            diterbitkan: -1200,
            berlakuSampai: -800,
            keputusan: 'FAIL',
          ),
        ],
      ),
      alatJson(11, 'Alat Baru Tanpa Sertifikat', status: 'belum_pernah'),
      // Tanpa jadwal: payload tidak membawa acuan "hari ini" dari server.
      alatJson(
        13,
        'Alat Tanpa Acuan Server',
        status: 'terkalibrasi',
        riwayat: [
          sertifikatJson(
            40,
            'CAL/2026/01/0040',
            alatId: 13,
            diterbitkan: -300,
            berlakuSampai: -10,
          ),
        ],
      ),
      alatJson(
        12,
        'Alat Satu Sertifikat Lewat',
        hari: -50,
        status: 'lewat_jadwal',
        riwayat: [
          sertifikatJson(
            30,
            'CAL/2025/09/0030',
            alatId: 12,
            diterbitkan: -415,
            berlakuSampai: -50,
          ),
        ],
      ),
    ],
    sertifikat: [
      for (final id in [20, 21, 22, 23, 24, 30])
        sertifikatJson(id, 'CAL/UJI/$id', alatId: 10),
    ],
  ),
  5: DataPerusahaan(nama: 'PT Kosong'),
});

Widget _app(
  Widget anak,
  ServerFitur server, {
  int perusahaan = 3,
  bool skalaHp = false,
  DateTime? jamHp,
}) => ProviderScope(
  key: UniqueKey(),
  overrides: overrideFitur(server, perusahaan: perusahaan, jamHp: jamHp),
  child: MaterialApp(
    theme: TemaSidik.terang,
    builder: skalaHp
        ? (context, child) => MediaQuery.withClampedTextScaling(
            minScaleFactor: batasSkalaHuruf.max,
            maxScaleFactor: batasSkalaHuruf.max,
            child: child!,
          )
        : null,
    home: anak,
  ),
);

void _layar(WidgetTester t, {double lebar = 800, double tinggi = 3000}) {
  t.view.physicalSize = Size(lebar, tinggi);
  t.view.devicePixelRatio = 1.0;
  addTearDown(t.view.resetPhysicalSize);
  addTearDown(t.view.resetDevicePixelRatio);
}

/// Lencana (teks) di dalam kartu alat bernama [nama].
Finder _teksDi(Finder kartu, String teks) =>
    find.descendant(of: kartu, matching: find.text(teks));

Finder _kartuAlat(String nama) => find.widgetWithText(KartuAlat, nama);

Finder _simpul(String nomor) =>
    find.ancestor(of: find.text(nomor), matching: find.byType(KartuSidik));

void main() {
  setUpAll(siapkanTesFitur);

  group('daftar alat dengan status', () {
    testWidgets('tiap alat memakai kata status rencana, bukan kode API', (
      tester,
    ) async {
      _layar(tester);
      await tester.pumpWidget(_app(const DaftarAlatScreen(), _server()));
      await tester.pumpAndSettle();

      expect(find.text('Alat saya'), findsOneWidget);
      expect(
        _teksDi(_kartuAlat('Jangka Sorong'), 'Lewat jadwal'),
        findsOneWidget,
      );
      expect(
        _teksDi(_kartuAlat('Timbangan Analitik'), 'Segera jatuh tempo'),
        findsOneWidget,
      );
      expect(_teksDi(_kartuAlat('Termometer'), 'Berlaku'), findsOneWidget);
      expect(
        _teksDi(_kartuAlat('Alat Nonaktif'), 'Tidak aktif'),
        findsOneWidget,
      );
      expect(
        _teksDi(_kartuAlat('Tanpa Jadwal'), 'Belum pernah dikalibrasi'),
        findsOneWidget,
      );
      // Sisa hari tetap ada, di baris tanggal.
      expect(find.textContaining('Lewat 5 hari'), findsWidgets);
      expect(find.textContaining('12 hari lagi'), findsWidgets);
      // Urutan server: paling mendesak di atas.
      final urutan = [
        for (final k in tester.widgetList<KartuAlat>(find.byType(KartuAlat)))
          k.alat.nama,
      ];
      // Yang paling lewat dulu, lalu yang terdekat, tanpa jadwal paling bawah.
      int di(String n) => urutan.indexOf(n);
      expect(urutan.first, 'Alat Satu Sertifikat Lewat');
      expect(di('Jangka Sorong'), lessThan(di('Timbangan Analitik')));
      expect(di('Timbangan Analitik'), lessThan(di('Termometer')));
      expect(di('Mikrometer'), lessThan(di('Tanpa Jadwal')));
      for (final kode in ['lewat_jadwal', 'mendekati_jadwal', 'terkalibrasi']) {
        expect(find.textContaining(kode), findsNothing);
      }
    });

    testWidgets('chip Lewat jadwal: saring=lewat dikirim ke server', (
      tester,
    ) async {
      _layar(tester);
      final server = _server();
      await tester.pumpWidget(_app(const DaftarAlatScreen(), server));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ChoiceChip, 'Lewat jadwal'));
      await tester.pumpAndSettle();

      expect(
        server.yang('GET', '/alat').last.url.queryParameters['saring'],
        'lewat',
      );
      expect(find.byType(KartuAlat), findsWidgets);
      expect(_kartuAlat('Jangka Sorong'), findsOneWidget);
      expect(_kartuAlat('Termometer'), findsNothing);
    });

    testWidgets('chip 61–90 hari: dihitung di HP, tanpa permintaan baru', (
      tester,
    ) async {
      _layar(tester);
      final server = _server();
      await tester.pumpWidget(_app(const DaftarAlatScreen(), server));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ChoiceChip, 'Dalam 61–90 hari'));
      await tester.pumpAndSettle();

      expect(_kartuAlat('Manometer'), findsOneWidget);
      expect(_kartuAlat('Termometer'), findsNothing);
      expect(_kartuAlat('Mikrometer'), findsNothing);
      // Rentang ini bukan saringan server: tak ada `saring` aneh yang dikirim.
      final saring = {
        for (final r in server.yang('GET', '/alat'))
          r.url.queryParameters['saring'],
      };
      expect(saring.difference({null, 'lewat', 'segera'}), isEmpty);
    });

    testWidgets(
      'cari di rentang yang dihitung HP, dan hasil kosong yang jelas',
      (tester) async {
        _layar(tester);
        await tester.pumpWidget(
          _app(
            const DaftarAlatScreen(filterAwal: FilterAlat.hari60),
            _server(),
          ),
        );
        await tester.pumpAndSettle();
        expect(_kartuAlat('Termometer'), findsOneWidget);

        await tester.enterText(find.byType(TextField), 'zzz');
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pumpAndSettle();
        expect(find.text('Tidak ada yang cocok'), findsOneWidget);
        expect(find.byType(KartuAlat), findsNothing);
      },
    );

    testWidgets('cari di daftar server mengirim q', (tester) async {
      _layar(tester);
      final server = _server();
      await tester.pumpWidget(_app(const DaftarAlatScreen(), server));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Termo');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      expect(
        server.yang('GET', '/alat').last.url.queryParameters['q'],
        'Termo',
      );
      expect(_kartuAlat('Termometer'), findsOneWidget);
      expect(_kartuAlat('Jangka Sorong'), findsNothing);
    });

    testWidgets('kosong: judul sesuai filter dan satu kalimat penjelasan', (
      tester,
    ) async {
      _layar(tester);
      await tester.pumpWidget(
        _app(const DaftarAlatScreen(), _server(), perusahaan: 5),
      );
      await tester.pumpAndSettle();
      expect(find.text('Belum ada alat'), findsOneWidget);
      expect(
        find.textContaining('muncul di sini'),
        findsOneWidget,
        reason: 'keterangan, bukan layar putih',
      );

      await tester.tap(find.widgetWithText(ChoiceChip, 'Lewat jadwal'));
      await tester.pumpAndSettle();
      expect(find.text('Tidak ada alat yang lewat jadwal'), findsOneWidget);

      await tester.tap(find.widgetWithText(ChoiceChip, 'Dalam 31–60 hari'));
      await tester.pumpAndSettle();
      expect(
        find.text('Tidak ada alat yang jatuh tempo dalam 31–60 hari'),
        findsOneWidget,
      );
    });

    testWidgets('galat server: pesan jelas dan Coba lagi', (tester) async {
      _layar(tester);
      final server = _server()..gagal.add('/alat');
      await tester.pumpWidget(_app(const DaftarAlatScreen(), server));
      await tester.pumpAndSettle();
      expect(find.textContaining('Terjadi kendala di server'), findsOneWidget);

      server.gagal.clear();
      await tester.tap(find.text('Coba lagi'));
      await tester.pumpAndSettle();
      expect(_kartuAlat('Jangka Sorong'), findsOneWidget);
    });

    testWidgets('tarik untuk segarkan', (tester) async {
      _layar(tester, tinggi: 900);
      final server = _server();
      await tester.pumpWidget(_app(const DaftarAlatScreen(), server));
      await tester.pumpAndSettle();
      final sebelum = server.yang('GET', '/alat').length;

      await tester.fling(
        find.byType(ListView).first,
        const Offset(0, 400),
        1000,
      );
      await tester.pumpAndSettle();

      expect(server.yang('GET', '/alat').length, sebelum + 1);
    });

    testWidgets('ketuk kartu membuka detail alat', (tester) async {
      _layar(tester);
      await tester.pumpWidget(_app(const DaftarAlatScreen(), _server()));
      await tester.pumpAndSettle();

      await tester.tap(_kartuAlat('Alat Riwayat'));
      await tester.pumpAndSettle();
      expect(find.byType(AlatDetailScreen), findsOneWidget);
    });

    testWidgets('320 dp / 1,3×: tanpa luapan, chip tetap bisa digulir', (
      tester,
    ) async {
      _layar(tester, lebar: 320, tinggi: 640);
      final server = ServerFitur({
        3: DataPerusahaan(
          nama: 'PT Panjang Sekali Namanya Perusahaan Ini',
          alat: [
            alatJson(
              1,
              'Digital Pressure Calibrator Multifungsi Presisi Tinggi 2271A',
              hari: -365,
              status: 'lewat_jadwal',
              merk: 'Fluke Calibration International',
            ),
            alatJson(2, 'Timbangan', hari: 12, status: 'mendekati_jadwal'),
          ],
        ),
      });
      await tester.pumpWidget(
        _app(const DaftarAlatScreen(), server, skalaHp: true),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.drag(
        find.byType(SingleChildScrollView).first,
        const Offset(-600, 0),
      );
      await tester.pumpAndSettle();
      expect(
        find.widgetWithText(ChoiceChip, 'Dalam 61–90 hari'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      // Chip: target sentuh ≥ 48 dp.
      expect(
        tester
            .getSize(find.widgetWithText(ChoiceChip, 'Dalam 61–90 hari'))
            .height,
        greaterThanOrEqualTo(48),
      );
    });
  });

  group('riwayat sertifikat per alat (garis waktu)', () {
    testWidgets('terbaru di atas, tiap simpul dengan status dan hubungannya', (
      tester,
    ) async {
      _layar(tester);
      await tester.pumpWidget(_app(const AlatDetailScreen(id: 10), _server()));
      await tester.pumpAndSettle();

      expect(find.byType(GarisWaktuSertifikat), findsOneWidget);
      const urutan = [
        'CAL/2026/10/0024-R1',
        'CAL/2026/10/0024',
        'CAL/2025/10/0010',
        'CAL/2024/10/0005',
        'CAL/2023/10/0001',
      ];
      final y = [for (final n in urutan) tester.getTopLeft(find.text(n)).dy];
      expect(y, orderedEquals([...y]..sort()), reason: 'terbaru di atas');
      expect(y.toSet().length, urutan.length);

      // Yang berlaku sekarang: jatuh tempo dalam 20 hari.
      expect(
        _teksDi(_simpul('CAL/2026/10/0024-R1'), 'Segera jatuh tempo'),
        findsOneWidget,
      );
      expect(find.text('Merevisi CAL/2026/10/0024'), findsOneWidget);
      // Yang digantikan revisi, dengan nomor penggantinya.
      expect(
        _teksDi(_simpul('CAL/2026/10/0024'), 'Digantikan'),
        findsOneWidget,
      );
      expect(find.text('Digantikan oleh CAL/2026/10/0024-R1'), findsOneWidget);
      // Tanggal lewat dan sudah ada sertifikat yang lebih baru: netral.
      expect(
        _teksDi(_simpul('CAL/2025/10/0010'), 'Masa berlaku berakhir'),
        findsOneWidget,
      );
      // Tidak ada kata "kedaluwarsa" di mana pun di layar (K3, BR-09).
      expect(
        find.textContaining(
          RegExp('kedaluwarsa|kadaluarsa', caseSensitive: false),
        ),
        findsNothing,
      );
      // Dibatalkan: tanggalnya tampil; vonisnya tidak dipajang.
      expect(
        _teksDi(_simpul('CAL/2024/10/0005'), 'Dibatalkan'),
        findsOneWidget,
      );
      expect(
        _teksDi(_simpul('CAL/2024/10/0005'), 'Tidak memenuhi toleransi'),
        findsNothing,
      );
      // FAIL tidak dilunakkan.
      expect(
        _teksDi(_simpul('CAL/2023/10/0001'), 'Tidak memenuhi toleransi'),
        findsOneWidget,
      );
      expect(find.textContaining('valid_until'), findsNothing);
    });

    testWidgets(
      'satu-satunya sertifikat yang tanggalnya lewat: Masa berlaku berakhir',
      (tester) async {
        _layar(tester);
        await tester.pumpWidget(
          _app(const AlatDetailScreen(id: 12), _server()),
        );
        await tester.pumpAndSettle();
        expect(
          _teksDi(_simpul('CAL/2025/09/0030'), 'Masa berlaku berakhir'),
          findsOneWidget,
        );
        // Peringatannya ada di status ALAT (dari server), bukan di sertifikat.
        expect(find.text('Lewat jadwal'), findsOneWidget);
      },
    );

    testWidgets('alat tanpa sertifikat: keadaan kosong yang menjelaskan', (
      tester,
    ) async {
      _layar(tester);
      await tester.pumpWidget(_app(const AlatDetailScreen(id: 11), _server()));
      await tester.pumpAndSettle();
      expect(find.text('Belum ada sertifikat'), findsOneWidget);
      expect(find.textContaining('setelah alat dikalibrasi'), findsOneWidget);
      expect(find.byType(GarisWaktuSertifikat), findsNothing);
    });

    testWidgets('ketuk simpul membuka detail sertifikat itu', (tester) async {
      _layar(tester);
      final server = _server();
      await tester.pumpWidget(_app(const AlatDetailScreen(id: 10), server));
      await tester.pumpAndSettle();

      await tester.tap(find.text('CAL/2025/10/0010'));
      await tester.pumpAndSettle();

      expect(find.byType(SertifikatDetailScreen), findsOneWidget);
      expect(
        server.yang('GET', RegExp(r'^/sertifikat/22$')).length,
        1,
        reason: 'membuka sertifikat id 22',
      );
    });

    testWidgets('tarik untuk segarkan memuat ulang alat', (tester) async {
      _layar(tester, tinggi: 900);
      final server = _server();
      await tester.pumpWidget(_app(const AlatDetailScreen(id: 10), server));
      await tester.pumpAndSettle();
      final sebelum = server.yang('GET', RegExp(r'^/alat/10$')).length;

      await tester.fling(
        find.byType(ListView).first,
        const Offset(0, 400),
        1000,
      );
      await tester.pumpAndSettle();
      expect(server.yang('GET', RegExp(r'^/alat/10$')).length, sebelum + 1);
    });

    testWidgets('alat perusahaan lain: 404 umum, tanpa membocorkan apa pun', (
      tester,
    ) async {
      _layar(tester);
      // Alat 10 milik perusahaan 3; sesi ini perusahaan 5.
      await tester.pumpWidget(
        _app(const AlatDetailScreen(id: 10), _server(), perusahaan: 5),
      );
      await tester.pumpAndSettle();
      expect(
        find.textContaining('tidak ditemukan atau Anda tidak punya akses'),
        findsOneWidget,
      );
      expect(find.text('Alat Riwayat'), findsNothing);
      expect(find.byType(GarisWaktuSertifikat), findsNothing);
    });

    group('"hari ini" dari server, bukan jam HP (BR-08)', () {
      const urutan = [
        'CAL/2026/10/0024-R1',
        'CAL/2026/10/0024',
        'CAL/2025/10/0010',
        'CAL/2024/10/0005',
        'CAL/2023/10/0001',
      ];

      /// Label status tiap simpul riwayat alat 10 untuk jam HP [jam].
      Future<List<List<String>>> statusRiwayat(
        WidgetTester tester,
        DateTime jam,
      ) async {
        await tester.pumpWidget(
          _app(const AlatDetailScreen(id: 10), _server(), jamHp: jam),
        );
        await tester.pumpAndSettle();
        return [
          for (final n in urutan)
            [
              for (final v in StatusBerlaku.values)
                if (_teksDi(_simpul(n), v.label).evaluate().isNotEmpty) v.label,
            ],
        ];
      }

      testWidgets(
        'HP 2030 dan HP 2020 = status yang sama dengan HP yang benar',
        (tester) async {
          _layar(tester);
          final benar = await statusRiwayat(tester, hariIniUji);
          expect(benar, [
            [StatusBerlaku.segera.label],
            [StatusBerlaku.digantikan.label],
            [StatusBerlaku.berakhir.label],
            [StatusBerlaku.dibatalkan.label],
            [StatusBerlaku.berakhir.label],
          ]);
          expect(await statusRiwayat(tester, DateTime(2030, 1, 1)), benar);
          expect(await statusRiwayat(tester, DateTime(2020, 1, 1)), benar);
        },
      );

      testWidgets(
        'HP mundur ke 2020 tidak membuat sertifikat lewat tampil Berlaku',
        (tester) async {
          _layar(tester);
          await tester.pumpWidget(
            _app(
              const AlatDetailScreen(id: 12),
              _server(),
              jamHp: DateTime(2020, 1, 1),
            ),
          );
          await tester.pumpAndSettle();
          expect(
            _teksDi(_simpul('CAL/2025/09/0030'), 'Masa berlaku berakhir'),
            findsOneWidget,
          );
          expect(_teksDi(_simpul('CAL/2025/09/0030'), 'Berlaku'), findsNothing);
        },
      );

      testWidgets(
        'tanpa acuan server (alat tanpa jadwal): jam HP jadi cadangan',
        (tester) async {
          _layar(tester);
          await tester.pumpWidget(
            _app(const AlatDetailScreen(id: 13), _server(), jamHp: hariIniUji),
          );
          await tester.pumpAndSettle();
          expect(
            _teksDi(_simpul('CAL/2026/01/0040'), 'Masa berlaku berakhir'),
            findsOneWidget,
          );

          // Cadangan memang mengikuti HP: dengan HP 2020 tanggalnya belum lewat.
          await tester.pumpWidget(
            _app(
              const AlatDetailScreen(id: 13),
              _server(),
              jamHp: DateTime(2020, 1, 1),
            ),
          );
          await tester.pumpAndSettle();
          expect(
            _teksDi(_simpul('CAL/2026/01/0040'), 'Berlaku'),
            findsOneWidget,
          );
        },
      );

      test('Alat.hariIniServer = jatuh tempo dikurangi sisa hari', () {
        DateTime? hariIni(String? tempo, int? hari) => Alat.dariJson({
          'id': 1,
          'nama': 'A',
          'tanggal_jatuh_tempo': tempo,
          'hari_ke_jatuh_tempo': hari,
        }).hariIniServer;
        expect(hariIni('2026-12-02', 20), DateTime(2026, 11, 12));
        expect(hariIni('2026-12-02', 5), DateTime(2026, 11, 27));
        expect(hariIni('2026-11-12', -5), DateTime(2026, 11, 17));
        expect(hariIni('2027-01-03', 5), DateTime(2026, 12, 29));
        expect(hariIni(null, null), isNull);
        expect(hariIni('2026-12-02', null), isNull);
      });
    });

    testWidgets('320 dp / 1,3×: garis waktu tanpa luapan', (tester) async {
      _layar(tester, lebar: 320, tinggi: 640);
      await tester.pumpWidget(
        _app(const AlatDetailScreen(id: 10), _server(), skalaHp: true),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      for (var i = 0; i < 12; i++) {
        await tester.drag(find.byType(ListView).first, const Offset(0, -300));
        await tester.pump();
        expect(tester.takeException(), isNull, reason: 'gulir ke-$i');
      }
      await tester.pumpAndSettle();
      expect(find.text('CAL/2023/10/0001'), findsOneWidget);
      // Simpul bisa disentuh: tinggi kartu jauh di atas 48 dp.
      expect(
        tester.getSize(_simpul('CAL/2023/10/0001').first).height,
        greaterThanOrEqualTo(48),
      );
    });
  });
}
