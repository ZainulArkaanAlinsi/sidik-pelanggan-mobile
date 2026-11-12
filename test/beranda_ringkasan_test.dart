// Fitur 1 + 2 (rencana §14.1): Beranda ringkasan dan satu pemetaan status.
//
// - model: kelompok 30/60/90 hari, status masa berlaku, bentuk `GET /beranda`;
// - layanan: paging `GET /alat` untuk hitungan 31–90 hari;
// - layar: kotak jatuh tempo, alat mendesak, sertifikat terbaru, paket;
//   keadaan kosong/galat/muat, tarik-untuk-segarkan, ganti perusahaan/akun,
//   dan skala huruf 1,3× di layar 320 dp.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';

import 'package:sidik_pelanggan/app.dart';
import 'package:sidik_pelanggan/core/api_pelanggan.dart';
import 'package:sidik_pelanggan/core/konfigurasi.dart';
import 'package:sidik_pelanggan/core/tema/tema_sidik.dart';
import 'package:sidik_pelanggan/models/akun.dart';
import 'package:sidik_pelanggan/models/data_pelanggan.dart';
import 'package:sidik_pelanggan/models/status_berlaku.dart';
import 'package:sidik_pelanggan/providers/sesi_provider.dart';
import 'package:sidik_pelanggan/screens/alat/daftar_alat_screen.dart';
import 'package:sidik_pelanggan/screens/beranda/beranda_screen.dart';
import 'package:sidik_pelanggan/services/layanan_pelanggan.dart';
import 'package:sidik_pelanggan/widgets/status_tampil.dart';
import 'package:sidik_pelanggan/widgets/tombol_sidik.dart';
import 'package:sidik_pelanggan/widgets/pemetaan_status.dart';
import 'package:sidik_pelanggan/widgets/kartu_alat.dart';

import 'dukungan/fixture_fitur.dart';

Alat _a(int id, int? hari, String status) =>
    Alat.dariJson(alatJson(id, 'Alat $id', hari: hari, status: status));

Sertifikat _s({
  String status = 'berlaku',
  int? berlakuSampai,
  Map<String, dynamic>? digantikanOleh,
}) => Sertifikat.dariJson(
  sertifikatJson(
    1,
    'CAL/1',
    status: status,
    berlakuSampai: berlakuSampai,
    digantikanOleh: digantikanOleh,
  ),
);

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
    ],
    sertifikat: [
      sertifikatJson(12, 'CAL/ALFA/0002', namaAlat: 'Timbangan Analitik'),
      sertifikatJson(11, 'CAL/ALFA/0001'),
    ],
    paket: [paketJson(21, 'ORD/ALFA/0001')],
  ),
  4: DataPerusahaan(
    nama: 'PT Beta',
    alat: [
      alatJson(31, 'Barometer Beta', hari: 20, status: 'mendekati_jadwal'),
    ],
    sertifikat: [
      sertifikatJson(41, 'CAL/BETA/0001', namaAlat: 'Barometer Beta'),
    ],
    paket: [paketJson(51, 'ORD/BETA/0001', label: 'Sedang diperiksa')],
  ),
  5: DataPerusahaan(nama: 'PT Kosong'),
});

Widget _app(
  Widget anak,
  ServerFitur server, {
  int perusahaan = 3,
  bool skalaHp = false,
}) => ProviderScope(
  overrides: overrideFitur(server, perusahaan: perusahaan),
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

ProviderContainer _kontainer(WidgetTester t) =>
    ProviderScope.containerOf(t.element(find.byType(BerandaScreen)));

void main() {
  setUpAll(siapkanTesFitur);

  group('kelompok jatuh tempo 30/60/90 hari', () {
    test('batas tiap kelompok, dan yang tidak dinilai dibuang', () {
      final r = RingkasanJatuhTempo.dari([
        _a(1, -1, 'lewat_jadwal'),
        _a(2, 0, 'mendekati_jadwal'),
        _a(3, 30, 'mendekati_jadwal'),
        _a(4, 31, 'terkalibrasi'),
        _a(5, 60, 'terkalibrasi'),
        _a(6, 61, 'terkalibrasi'),
        _a(7, 90, 'terkalibrasi'),
        _a(8, 91, 'terkalibrasi'),
        _a(9, null, 'belum_pernah'),
        _a(10, 15, 'nonaktif'),
        _a(11, 20, 'belum_pernah'),
      ]);
      List<int> id(List<Alat> l) => [for (final a in l) a.id];
      expect(id(r.lewatJadwal), [1]);
      expect(id(r.kelompok1), [2, 3]);
      expect(id(r.kelompok2), [4, 5]);
      expect(id(r.kelompok3), [6, 7]);
      // Paling mendesak lebih dulu.
      expect(id(r.urut), [1, 2, 3, 4, 5, 6, 7]);
    });
  });

  group('status masa berlaku: satu pemetaan', () {
    final sekarang = hariIniUji;

    test('sertifikat: hari ini, 30, 31, lewat', () {
      StatusBerlaku st(int? hari, {bool penerus = false}) =>
          StatusBerlaku.dariSertifikat(
            _s(berlakuSampai: hari),
            sekarang: sekarang,
            adaPenerus: penerus,
          );
      expect(st(null), StatusBerlaku.berlaku, reason: 'tanpa tanggal');
      expect(st(31), StatusBerlaku.berlaku);
      expect(st(30), StatusBerlaku.segera);
      expect(st(0), StatusBerlaku.segera, reason: 'hari ini belum lewat');
      // Tanggal lewat = "Masa berlaku berakhir" (bukan "kedaluwarsa", K3),
      // dengan atau tanpa sertifikat yang lebih baru.
      expect(st(-1), StatusBerlaku.berakhir);
      expect(st(-1, penerus: true), StatusBerlaku.berakhir);
      // Sudah ada sertifikat berlaku yang lebih baru: tanpa peringatan segera.
      expect(st(10, penerus: true), StatusBerlaku.berlaku);
    });

    test('status dokumen dari server menang atas tanggal', () {
      expect(
        StatusBerlaku.dariSertifikat(
          _s(status: 'dibatalkan', berlakuSampai: 200),
          sekarang: sekarang,
        ),
        StatusBerlaku.dibatalkan,
      );
      expect(
        StatusBerlaku.dariSertifikat(
          _s(
            status: 'digantikan',
            berlakuSampai: -100,
            digantikanOleh: {'id': 2, 'nomor': 'CAL/2'},
          ),
          sekarang: sekarang,
        ),
        StatusBerlaku.digantikan,
      );
    });

    test('jam di hari yang sama tidak menggeser status (tanggal kalender)', () {
      final s = _s(berlakuSampai: 0);
      for (final jam in [0, 9, 23]) {
        expect(
          StatusBerlaku.dariSertifikat(
            s,
            sekarang: DateTime(2026, 11, 12, jam, 59),
          ),
          StatusBerlaku.segera,
        );
      }
    });

    test('alat dan sertifikat memakai SATU tabel label, warna, dan ikon', () {
      // Alat Berlaku == sertifikat Berlaku, dst: bukti satu pemetaan.
      expect(
        statusAlat(StatusKalibrasi.terkalibrasi).label,
        statusSertifikat(_s(berlakuSampai: 200), sekarang: hariIniUji).label,
      );
      expect(
        statusAlat(StatusKalibrasi.mendekati).label,
        statusSertifikat(_s(berlakuSampai: 5), sekarang: hariIniUji).label,
      );
      // Lewat jadwal: alat (server) dan sertifikat (tanggal) sengaja beda
      // kata, tapi kata-katanya sama-sama dari StatusBerlaku.label.
      expect(
        statusAlat(StatusKalibrasi.lewat).label,
        StatusBerlaku.lewatJadwal.label,
      );
      expect(
        statusSertifikat(_s(berlakuSampai: -5), sekarang: hariIniUji).label,
        StatusBerlaku.berakhir.label,
      );
      expect(
        statusAlat(StatusKalibrasi.lewat).nada,
        statusBerlaku(StatusBerlaku.lewatJadwal).nada,
      );
      expect(
        statusDokumen(StatusDokumen.digantikan).label,
        statusBerlaku(StatusBerlaku.digantikan).label,
      );
    });

    test('kata status dan nadanya (istilah K3: tanpa "kedaluwarsa")', () {
      final p = {for (final s in StatusBerlaku.values) s: statusBerlaku(s)};
      expect(p[StatusBerlaku.berlaku]!.label, 'Berlaku');
      expect(p[StatusBerlaku.berlaku]!.nada, NadaStatus.lulus);
      expect(p[StatusBerlaku.segera]!.label, 'Segera jatuh tempo');
      expect(p[StatusBerlaku.segera]!.nada, NadaStatus.awas);
      expect(p[StatusBerlaku.lewatJadwal]!.label, 'Lewat jadwal');
      expect(p[StatusBerlaku.lewatJadwal]!.nada, NadaStatus.gagal);
      expect(p[StatusBerlaku.berakhir]!.label, 'Masa berlaku berakhir');
      expect(p[StatusBerlaku.digantikan]!.label, 'Digantikan');
      // Tiap status punya label sendiri; tidak ada dua status yang sama.
      expect({for (final x in p.values) x.label}.length, p.length);
      // Tanpa jargon teknis di layar.
      for (final x in p.values) {
        expect(x.label, isNot(contains('_')));
        expect(x.label, isNot(contains('valid')));
        // K3 (BR-09, R-F02): sertifikat kalibrasi tidak "kedaluwarsa".
        expect(x.label.toLowerCase(), isNot(contains('kedaluwarsa')));
        expect(x.label.toLowerCase(), isNot(contains('kadaluarsa')));
      }
    });
  });

  group('bentuk GET /beranda', () {
    test('membaca sertifikat terbaru dan paket berjalan', () {
      final b = Beranda.dariJson({
        'data': {
          'perusahaan': {'nama': 'PT X'},
          'ringkasan': {
            'jumlah_alat': 4,
            'lewat_jatuh_tempo': 1,
            'segera_jatuh_tempo': 2,
            'paket_berjalan': 5,
            'notifikasi_belum_dibaca': 0,
          },
          'sertifikat_terbaru': [sertifikatJson(1, 'CAL/1')],
          'paket_berjalan': [paketJson(9, 'ORD/9')],
        },
        'meta': {'jendela_segera_hari': 30},
      });
      expect(b.sertifikatTerbaru.single.nomor, 'CAL/1');
      expect(b.paketBerjalan.single.nomor, 'ORD/9');
      expect(b.jumlahPaketBerjalan, 5);
    });

    test('jawaban tanpa bagian itu = daftar kosong, bukan galat', () {
      final b = Beranda.dariJson({
        'data': {
          'perusahaan': {'nama': 'PT X'},
          'ringkasan': {'jumlah_alat': 0},
        },
      });
      expect(b.sertifikatTerbaru, isEmpty);
      expect(b.paketBerjalan, isEmpty);
      expect(b.jumlahPaketBerjalan, 0);
    });
  });

  group('GET /alat untuk hitungan 31–90 hari', () {
    test('berhenti begitu satu halaman penuh di luar jendela', () async {
      final alat = [
        for (var i = 1; i <= 450; i++)
          alatJson(i, 'Alat $i', hari: i, status: 'terkalibrasi'),
      ];
      final server = ServerFitur({
        3: DataPerusahaan(nama: 'PT Besar', alat: alat),
      });
      final api = ApiPelanggan(
        klien: MockClient(server.tangani),
        token: ServerFitur.token,
        perusahaanId: 3,
        jedaUlang: const [],
      );
      final hasil = await LayananPelanggan(api).alatMenujuJatuhTempo();
      final minta = server.yang('GET', '/alat').toList();
      // Halaman 1 (hari 1–100) ada yang ≤ 90 -> lanjut; halaman 2 (101–200)
      // tidak ada -> berhenti. Tidak menarik ke-450 alat.
      expect(minta.length, 2);
      expect(minta.first.url.queryParameters['per_page'], '100');
      expect(minta.first.url.queryParameters['page'], '1');
      expect(minta.last.url.queryParameters['page'], '2');
      expect(hasil.length, 200);
      for (final r in minta) {
        expect(r.method, 'GET', reason: 'tidak ada tulis di fitur ini');
        expect(r.headers['Authorization'], 'Bearer ${ServerFitur.token}');
        expect(r.url.host, Uri.parse(Konfigurasi.apiBaseUrl).host);
      }
    });
  });

  group('layar Beranda', () {
    testWidgets(
      'ringkasan: kotak 30/60/90, tiga alat mendesak, sertifikat, paket',
      (tester) async {
        final semantik = tester.ensureSemantics();
        _layar(tester);
        await tester.pumpWidget(_app(const BerandaScreen(), _server()));
        await tester.pumpAndSettle();

        expect(find.text('PT Alfa'), findsOneWidget, reason: 'judul app bar');
        // Empat kotak, label bahasa awam.
        expect(find.bySemanticsLabel('Lewat jadwal: 1 alat'), findsOneWidget);
        expect(find.bySemanticsLabel('Dalam 30 hari: 1 alat'), findsOneWidget);
        expect(
          find.bySemanticsLabel('Dalam 31–60 hari: 1 alat'),
          findsOneWidget,
        );
        expect(
          find.bySemanticsLabel('Dalam 61–90 hari: 1 alat'),
          findsOneWidget,
        );

        // Tiga alat paling mendesak, urut; yang jauh / nonaktif tidak ikut.
        final kartu = find.byType(KartuAlat);
        expect(kartu, findsNWidgets(3));
        expect(
          [for (final w in tester.widgetList<KartuAlat>(kartu)) w.alat.nama],
          ['Jangka Sorong', 'Timbangan Analitik', 'Termometer'],
        );
        expect(find.text('Manometer'), findsNothing);
        expect(find.text('Alat Nonaktif'), findsNothing);
        // Status memakai kata rencana, bukan kode API.
        expect(find.text('Lewat jadwal'), findsWidgets);
        expect(find.text('Segera jatuh tempo'), findsOneWidget);
        expect(find.textContaining('valid_until'), findsNothing);

        expect(find.text('CAL/ALFA/0002'), findsOneWidget);
        expect(find.text('CAL/ALFA/0001'), findsOneWidget);
        expect(find.text('ORD/ALFA/0001'), findsOneWidget);
        expect(find.text('Sedang dikalibrasi'), findsOneWidget);
        expect(find.text('Lihat semua alat (7)'), findsOneWidget);
        semantik.dispose();
      },
    );

    testWidgets('ketuk kotak 31–60 hari: daftar hanya alat di rentang itu', (
      tester,
    ) async {
      final semantik = tester.ensureSemantics();
      _layar(tester);
      final server = _server();
      await tester.pumpWidget(_app(const BerandaScreen(), server));
      await tester.pumpAndSettle();

      await tester.tap(find.bySemanticsLabel('Dalam 31–60 hari: 1 alat'));
      await tester.pumpAndSettle();

      expect(find.byType(DaftarAlatScreen), findsOneWidget);
      expect(find.text('Alat saya'), findsOneWidget);
      expect(find.widgetWithText(KartuAlat, 'Termometer'), findsOneWidget);
      expect(find.widgetWithText(KartuAlat, 'Manometer'), findsNothing);
      expect(find.widgetWithText(KartuAlat, 'Jangka Sorong'), findsNothing);
      semantik.dispose();
    });

    testWidgets('ketuk kotak Dalam 30 hari: server disaring saring=segera', (
      tester,
    ) async {
      final semantik = tester.ensureSemantics();
      _layar(tester);
      final server = _server();
      await tester.pumpWidget(_app(const BerandaScreen(), server));
      await tester.pumpAndSettle();

      await tester.tap(find.bySemanticsLabel('Dalam 30 hari: 1 alat'));
      await tester.pumpAndSettle();

      final saring = [
        for (final r in server.yang('GET', '/alat'))
          r.url.queryParameters['saring'],
      ];
      expect(saring, contains('segera'));
      expect(
        find.widgetWithText(KartuAlat, 'Timbangan Analitik'),
        findsOneWidget,
      );
      expect(find.widgetWithText(KartuAlat, 'Termometer'), findsNothing);
      semantik.dispose();
    });

    testWidgets('perusahaan tanpa data: keadaan kosong yang menjelaskan', (
      tester,
    ) async {
      _layar(tester);
      await tester.pumpWidget(
        _app(const BerandaScreen(), _server(), perusahaan: 5),
      );
      await tester.pumpAndSettle();

      expect(find.text('Belum ada alat'), findsOneWidget);
      expect(find.text('Belum ada sertifikat yang terbit.'), findsOneWidget);
      expect(
        find.text('Tidak ada paket yang sedang dikerjakan.'),
        findsOneWidget,
      );
      expect(find.byType(KartuAlat), findsNothing);
    });

    testWidgets('galat server: pesan jelas, Coba lagi memulihkan', (
      tester,
    ) async {
      _layar(tester);
      final server = _server()..gagal.add('/beranda');
      await tester.pumpWidget(_app(const BerandaScreen(), server));
      await tester.pumpAndSettle();

      expect(find.textContaining('Terjadi kendala di server'), findsOneWidget);
      expect(find.text('Coba lagi'), findsOneWidget);

      server.gagal.clear();
      await tester.tap(find.text('Coba lagi'));
      await tester.pumpAndSettle();
      expect(find.text('PT Alfa'), findsOneWidget);
      expect(find.byType(KartuAlat), findsNWidgets(3));
    });

    testWidgets('hitungan 31–90 hari gagal: dua kotak server tetap tampil', (
      tester,
    ) async {
      final semantik = tester.ensureSemantics();
      _layar(tester);
      final server = _server()..gagal.add('/alat');
      await tester.pumpWidget(_app(const BerandaScreen(), server));
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel('Lewat jadwal: 1 alat'), findsOneWidget);
      expect(find.bySemanticsLabel('Dalam 30 hari: 1 alat'), findsOneWidget);
      expect(
        find.bySemanticsLabel('Dalam 31–60 hari: belum tersedia'),
        findsOneWidget,
      );
      expect(find.textContaining('belum bisa dimuat'), findsOneWidget);
      semantik.dispose();
    });

    testWidgets('tarik untuk segarkan memuat ulang beranda dan hitungan', (
      tester,
    ) async {
      _layar(tester, tinggi: 900);
      final server = _server();
      await tester.pumpWidget(_app(const BerandaScreen(), server));
      await tester.pumpAndSettle();
      final sebelum = server.yang('GET', '/beranda').length;
      final alatSebelum = server.yang('GET', '/alat').length;
      server.jeda = const Duration(seconds: 2);

      await tester.fling(
        find.byType(ListView).first,
        const Offset(0, 400),
        1000,
      );
      await tester.pumpAndSettle();

      expect(server.yang('GET', '/beranda').length, sebelum + 1);
      expect(server.yang('GET', '/alat').length, alatSebelum + 1);
    });
  });

  group('ganti perusahaan dan akun', () {
    testWidgets('pilih perusahaan lain: tidak ada sisa data perusahaan lama', (
      tester,
    ) async {
      _layar(tester);
      final server = _server();
      await tester.pumpWidget(_app(const BerandaScreen(), server));
      await tester.pumpAndSettle();
      expect(find.text('PT Alfa'), findsOneWidget);
      expect(find.text('Jangka Sorong'), findsOneWidget);
      expect(find.text('CAL/ALFA/0001'), findsOneWidget);

      // Data perusahaan baru datang lambat: selama menunggu, TIDAK BOLEH ada
      // data perusahaan lama di layar (bukan hanya sesudah yang baru tiba).
      server.jeda = const Duration(seconds: 2);
      (_kontainer(tester).read(sesiProvider.notifier) as SesiBisaGanti)
          .pilihPerusahaan(4);
      await tester.pump(const Duration(milliseconds: 500));
      for (final sisa in ['PT Alfa', 'Jangka Sorong', 'CAL/ALFA/0001']) {
        expect(find.text(sisa), findsNothing, reason: 'saat memuat: $sisa');
      }
      await tester.pumpAndSettle();

      expect(find.text('PT Beta'), findsOneWidget);
      expect(find.text('Barometer Beta'), findsOneWidget);
      expect(find.text('CAL/BETA/0001'), findsOneWidget);
      expect(find.text('ORD/BETA/0001'), findsOneWidget);
      // Tidak satu pun milik perusahaan sebelumnya tertinggal di layar.
      for (final sisa in [
        'PT Alfa',
        'Jangka Sorong',
        'Timbangan Analitik',
        'CAL/ALFA/0001',
        'CAL/ALFA/0002',
        'ORD/ALFA/0001',
      ]) {
        expect(find.text(sisa), findsNothing, reason: sisa);
      }
      // Permintaan terakhir memang membawa perusahaan baru.
      expect(server.permintaan.last.headers['X-Perusahaan-Id'], '4');
      expect(
        server.yang('GET', '/beranda').last.headers['X-Perusahaan-Id'],
        '4',
      );
    });

    testWidgets('akun lain masuk di HP yang sama: layar dibangun dari nol', (
      tester,
    ) async {
      _layar(tester);
      final server = _server();
      await tester.pumpWidget(_app(const BerandaScreen(), server));
      await tester.pumpAndSettle();
      expect(find.text('PT Alfa'), findsOneWidget);

      server.jeda = const Duration(seconds: 2);
      (_kontainer(tester).read(sesiProvider.notifier) as SesiBisaGanti).ganti(
        Sesi(
          akun: Akun.dariJson({
            'id': 8,
            'nama': 'Sari Lain',
            'email': 'sari@contoh.test',
            'status': 'aktif',
            'butuh_verifikasi': false,
            'keanggotaan': [
              {
                'customer_id': 5,
                'nama_perusahaan': 'PT Kosong',
                'peran': 'staf',
              },
            ],
          }),
          perusahaanId: 5,
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Jangka Sorong'), findsNothing, reason: 'saat memuat');
      expect(find.text('PT Alfa'), findsNothing, reason: 'saat memuat');
      await tester.pumpAndSettle();

      expect(find.text('PT Kosong'), findsOneWidget);
      expect(find.text('Jangka Sorong'), findsNothing);
      expect(find.text('CAL/ALFA/0001'), findsNothing);
      expect(find.text('Belum ada alat'), findsOneWidget);
      // Permintaan perusahaan lama yang masih terbang selesai tanpa efek.
      await tester.pump(const Duration(seconds: 5));
      expect(find.text('Jangka Sorong'), findsNothing);
    });
  });

  group('skala huruf 1,3× di layar 320 dp', () {
    testWidgets('Beranda penuh tanpa luapan, ukuran sentuh ≥ 48 dp', (
      tester,
    ) async {
      _layar(tester, lebar: 320, tinggi: 640);
      final server = ServerFitur({
        3: DataPerusahaan(
          nama: 'PT Instrumentasi Presisi Nusantara Sejahtera Abadi',
          alat: [
            alatJson(
              1,
              'Digital Pressure Calibrator Multifungsi Presisi Tinggi',
              hari: -365,
              status: 'lewat_jadwal',
              merk: 'Fluke Calibration International',
            ),
            alatJson(2, 'Timbangan', hari: 12, status: 'mendekati_jadwal'),
            alatJson(3, 'Termometer', hari: 45),
          ],
          sertifikat: [
            sertifikatJson(
              9,
              'CAL/2026/09/000123-REV.2',
              namaAlat: 'Digital Pressure Calibrator Multifungsi',
              status: 'digantikan',
              digantikanOleh: {'id': 10, 'nomor': 'CAL/2026/10/000456-REV.3'},
            ),
          ],
          paket: [
            paketJson(
              21,
              'ORD/2026/11/000777-PANJANG',
              label: 'Menunggu pemeriksaan oleh penyelia laboratorium',
            ),
          ],
          jumlahPaketBerjalan: 6,
        ),
      });
      await tester.pumpWidget(
        _app(const BerandaScreen(), server, skalaHp: true),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // Seluruh isi digulir pelan-pelan: luapan di bagian mana pun ketahuan.
      for (var i = 0; i < 12; i++) {
        await tester.drag(find.byType(ListView).first, const Offset(0, -300));
        await tester.pump();
        expect(tester.takeException(), isNull, reason: 'gulir ke-$i');
      }
      await tester.pumpAndSettle();
      expect(find.text('dan 5 paket lainnya'), findsOneWidget);

      // Target sentuh ≥ 48 dp: tombol utama, tombol teks, dan kotak ringkasan.
      await tester.scrollUntilVisible(
        find.widgetWithText(TombolSidik, 'Lihat semua alat (3)'),
        -300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(
        tester
            .getSize(find.widgetWithText(TombolSidik, 'Lihat semua alat (3)'))
            .height,
        greaterThanOrEqualTo(48),
      );
      for (final e in find.byType(TextButton).evaluate()) {
        expect(
          tester.getSize(find.byWidget(e.widget)).height,
          greaterThanOrEqualTo(48),
        );
      }
    });
  });
}
