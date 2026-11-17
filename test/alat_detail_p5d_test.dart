// Detail alat (P5d-B, REVISI-2 butir 3): identitas, jadwal, status layanan, dan
// riwayat sebagai empat kelompok; nama alat sekali; data kosong "Belum
// tersedia" atau disembunyikan; nomor seri bisa disalin; riwayat terbaru di
// atas dengan akses ke sertifikatnya; alat tidak aktif tanpa hitung mundur.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sidik_pelanggan/core/format.dart';
import 'package:sidik_pelanggan/core/tema/tema_sidik.dart';
import 'package:sidik_pelanggan/models/data_pelanggan.dart';
import 'package:sidik_pelanggan/screens/alat/alat_detail_screen.dart';
import 'package:sidik_pelanggan/screens/paket/paket_detail_screen.dart';
import 'package:sidik_pelanggan/screens/sertifikat/sertifikat_detail_screen.dart';

import 'dukungan/fixture_fitur.dart';
import 'dukungan/layar_uji.dart';

Map<String, dynamic> _oven({
  int hari = 20,
  String status = 'terkalibrasi',
  List<Map<String, dynamic>> riwayat = const [],
  Map<String, dynamic> tambahan = const {},
}) => {
  ...alatJson(
    1,
    'Oven Memmert',
    hari: hari,
    status: status,
    merk: 'Memmert',
    model: 'UF55',
    serial: '0457-2201',
    riwayat: riwayat,
  ),
  'no_identifikasi': 'AST-0457',
  'rentang': {'min': 0, 'max': 300, 'satuan': '°C'},
  'catatan': 'Dipakai di ruang uji 2',
  'tanggal_kalibrasi_terakhir': tanggalUji(-345),
  ...tambahan,
};

class _Uji {
  _Uji(Map<String, dynamic> alat)
    : server = ServerFitur({
        3: DataPerusahaan(nama: 'PT Alfa', alat: [alat]),
      });

  final ServerFitur server;
  final tersalin = <String>[];

  Future<void> buka(
    WidgetTester tester, {
    double lebar = 392,
    double skala = 1.0,
    bool gelap = false,
  }) async {
    layarHp(tester, lebar: lebar, tinggi: 2600);
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          tersalin.add((call.arguments as Map)['text'] as String);
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: overrideFitur(server),
        child: MaterialApp(
          theme: TemaSidik.terang,
          darkTheme: TemaSidik.gelap,
          themeMode: gelap ? ThemeMode.dark : ThemeMode.light,
          builder: (context, child) => MediaQuery.withClampedTextScaling(
            minScaleFactor: skala,
            maxScaleFactor: skala,
            child: child!,
          ),
          home: const AlatDetailScreen(id: 1),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }
}

String _tgl(int hari) => Format.tanggal(DateTime.parse(tanggalUji(hari)));

void main() {
  setUpAll(siapkanTesFitur);

  group('kelompok dan judul', () {
    testWidgets('judul layar "Detail alat"; nama alat HANYA SEKALI; empat '
        'kelompok berurutan', (tester) async {
      final u = _Uji(
        _oven(
          riwayat: [sertifikatJson(31, 'CAL/ALFA/0031', diterbitkan: -345)],
          tambahan: {'sedang_dikerjakan': sedangDikerjakanJson()},
        ),
      );
      await u.buka(tester);
      expect(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.text('Detail alat'),
        ),
        findsOneWidget,
      );
      expect(
        find.text('Oven Memmert'),
        findsOneWidget,
        reason: 'nama alat tidak diulang di judul dan kartu',
      );
      double y(String t) => tester.getTopLeft(find.text(t)).dy;
      expect(y('Oven Memmert'), lessThan(y('Jadwal kalibrasi')));
      expect(y('Jadwal kalibrasi'), lessThan(y('Status layanan')));
      expect(y('Status layanan'), lessThan(y('Riwayat kalibrasi')));
    });

    testWidgets('nama alat adalah judul bagian untuk pembaca layar', (
      tester,
    ) async {
      final semantik = tester.ensureSemantics();
      await _Uji(_oven()).buka(tester);
      final d = tester
          .getSemantics(find.text('Oven Memmert'))
          .getSemanticsData();
      expect(d.flagsCollection.isHeader, isTrue);
      semantik.dispose();
    });
  });

  group('identitas alat', () {
    testWidgets('semua kolom terisi: merk/model, seri, nomor identifikasi, '
        'rentang, lokasi, catatan', (tester) async {
      await _Uji(_oven()).buka(tester);
      expect(find.text('Memmert UF55'), findsOneWidget);
      expect(find.text('0457-2201'), findsOneWidget);
      expect(find.text('AST-0457'), findsOneWidget);
      expect(find.textContaining('300 °C'), findsOneWidget);
      expect(find.text('Gudang 1'), findsOneWidget);
      expect(find.text('Dipakai di ruang uji 2'), findsOneWidget);
      // Tanpa pemisah titik tengah antara merk dan model.
      expect(find.textContaining('·'), findsNothing);
      // Baris bertombol salin sejajar dengan baris tetangganya: label di kiri
      // yang sama, nilai di kolom yang sama (tidak berpindah ke tata letak
      // menumpuk hanya karena ada tombol).
      double x(String t) => tester.getTopLeft(find.text(t)).dx;
      expect(x('Nomor seri'), x('Merk / model'));
      expect(x('0457-2201'), x('Memmert UF55'));
      expect(x('AST-0457'), x('Memmert UF55'));
    });

    testWidgets('data wajib kosong = "Belum tersedia"; kolom opsional yang '
        'kosong DISEMBUNYIKAN', (tester) async {
      final u = _Uji({
        ..._oven(),
        'merk': null,
        'model': null,
        'serial': null,
        'no_identifikasi': null,
        'rentang': null,
        'lokasi': null,
        'catatan': null,
        'tanggal_kalibrasi_terakhir': null,
      });
      await u.buka(tester);
      // Merk/model, nomor seri, dan kalibrasi terakhir selalu ada.
      expect(find.text('Belum tersedia'), findsNWidgets(3));
      for (final k in ['Merk / model', 'Nomor seri', 'Kalibrasi terakhir']) {
        expect(find.text(k), findsOneWidget, reason: k);
      }
      // Opsional: tidak ada barisnya sama sekali (bukan "—" atau kosong).
      for (final k in [
        'No. identifikasi',
        'Rentang ukur',
        'Lokasi',
        'Catatan',
      ]) {
        expect(find.text(k), findsNothing, reason: k);
      }
      expect(find.text('—'), findsNothing);
      // Tidak ada yang bisa disalin tanpa nomor seri.
      expect(find.byTooltip('Salin nomor seri'), findsNothing);
    });

    testWidgets('nomor seri dan nomor identifikasi bisa disalin satu ketuk', (
      tester,
    ) async {
      final u = _Uji(_oven());
      await u.buka(tester);
      final seri = find.byTooltip('Salin nomor seri');
      expect(tester.getSize(seri).width, greaterThanOrEqualTo(48));
      await tester.tap(seri);
      await tester.pump();
      expect(u.tersalin, ['0457-2201']);
      expect(find.text('Nomor seri disalin.'), findsOneWidget);
      // Snackbar pertama habis dulu (yang kedua antre di belakangnya): masuk
      // selesai, waktu tampil habis, keluar selesai.
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Salin nomor identifikasi'));
      await tester.pump();
      expect(u.tersalin.last, 'AST-0457');
      expect(find.text('Nomor identifikasi disalin.'), findsOneWidget);
    });
  });

  group('jadwal kalibrasi', () {
    testWidgets(
      'aktif: lencana berwaktu (kata yang sama dengan kartu), jadwal, '
      'kalibrasi terakhir',
      (tester) async {
        await _Uji(_oven(hari: 20)).buka(tester);
        expect(find.text('Berlaku 20 hari lagi'), findsOneWidget);
        expect(find.text('Jadwal kalibrasi ulang'), findsOneWidget);
        expect(find.text(_tgl(20)), findsOneWidget);
        expect(find.text('Kalibrasi terakhir'), findsOneWidget);
        expect(find.text(_tgl(-345)), findsOneWidget);
      },
    );

    testWidgets('lewat jadwal: "Lewat jadwal 4 hari"', (tester) async {
      await _Uji(_oven(hari: -4, status: 'lewat_jadwal')).buka(tester);
      expect(find.text('Lewat jadwal 4 hari'), findsOneWidget);
    });

    testWidgets('belum ada jadwal: lencana katanya saja, "Belum ada jadwal"', (
      tester,
    ) async {
      final j = _oven();
      j['tanggal_jatuh_tempo'] = null;
      j['hari_ke_jatuh_tempo'] = null;
      await _Uji(j).buka(tester);
      expect(find.text('Belum ada jadwal'), findsOneWidget);
      expect(find.textContaining('hari lagi'), findsNothing);
    });

    for (final hari in [10, -30, 0]) {
      testWidgets('ALAT TIDAK AKTIF (jadwal $hari hari): tanpa hitung mundur, '
          'tanpa kata lewat atau lagi, jadwal hanya konteks', (tester) async {
        await _Uji(_oven(hari: hari, status: 'nonaktif')).buka(tester);
        expect(find.text('Tidak aktif'), findsOneWidget);
        expect(
          find.text('Alat tidak aktif, jadwal tercatat ${_tgl(hari)}.'),
          findsOneWidget,
        );
        for (final kata in ['hari lagi', 'Lewat', 'lewat', 'hari ini']) {
          expect(find.textContaining(kata), findsNothing, reason: kata);
        }
        // Tidak memakai label "Jadwal kalibrasi ulang" yang menyiratkan tugas.
        expect(find.text('Jadwal kalibrasi ulang'), findsNothing);
        expect(find.text('Minta kalibrasi ulang'), findsNothing);
      });
    }

    testWidgets('alat tidak aktif tanpa jadwal: hanya "Alat tidak aktif."', (
      tester,
    ) async {
      final j = _oven(status: 'nonaktif');
      j['tanggal_jatuh_tempo'] = null;
      j['hari_ke_jatuh_tempo'] = null;
      await _Uji(j).buka(tester);
      expect(find.text('Alat tidak aktif.'), findsOneWidget);
    });
  });

  group('status layanan', () {
    testWidgets('di laboratorium: tahap, nomor order, tautan ke paket', (
      tester,
    ) async {
      await _Uji(
        _oven(tambahan: {'sedang_dikerjakan': sedangDikerjakanJson()}),
      ).buka(tester);
      expect(find.text('Status layanan'), findsOneWidget);
      expect(find.text('Sedang di laboratorium'), findsOneWidget);
      expect(find.text('Sedang dikalibrasi'), findsOneWidget);
      expect(find.text('ORD/ALFA/2026/0021'), findsOneWidget);
      await tester.tap(find.text('Lihat paket'));
      await tester.pumpAndSettle();
      expect(find.byType(PaketDetailScreen), findsOneWidget);
    });

    testWidgets('tidak di laboratorium: tidak ada kelompok layanan', (
      tester,
    ) async {
      await _Uji(_oven()).buka(tester);
      expect(find.text('Status layanan'), findsNothing);
      expect(find.text('Sedang di laboratorium'), findsNothing);
    });

    testWidgets('server lama tanpa kunci sedang_dikerjakan tetap jalan', (
      tester,
    ) async {
      final j = _oven()..remove('sedang_dikerjakan');
      await _Uji(j).buka(tester);
      expect(tester.takeException(), isNull);
      expect(find.text('Status layanan'), findsNothing);
    });
  });

  group('riwayat kalibrasi', () {
    List<Map<String, dynamic>> riwayat() => [
      sertifikatJson(31, 'CAL/ALFA/0031', diterbitkan: -345, berlakuSampai: 20),
      sertifikatJson(
        30,
        'CAL/ALFA/0030',
        diterbitkan: -710,
        berlakuSampai: -345,
      ),
    ];

    testWidgets('terbaru di atas WALAU server mengirim terlama dulu', (
      tester,
    ) async {
      // Server mengirim terlama lebih dulu (kebalikan dari kontrak).
      await _Uji(_oven(riwayat: riwayat().reversed.toList())).buka(tester);
      final baru = tester.getTopLeft(find.text('CAL/ALFA/0031')).dy;
      final lama = tester.getTopLeft(find.text('CAL/ALFA/0030')).dy;
      expect(baru, lessThan(lama));
      expect(
        find.text('2 sertifikat, yang terbaru di atas. Ketuk untuk membuka.'),
        findsOneWidget,
      );
    });

    testWidgets('tiap riwayat punya "Buka sertifikat" dan membuka detailnya', (
      tester,
    ) async {
      await _Uji(_oven(riwayat: riwayat())).buka(tester);
      expect(find.text('Buka sertifikat'), findsNWidgets(2));
      await tester.tap(find.text('Buka sertifikat').first);
      await tester.pumpAndSettle();
      expect(find.byType(SertifikatDetailScreen), findsOneWidget);
    });

    testWidgets('jadwal di riwayat bernama "Jadwal kalibrasi ulang", bukan '
        '"Berlaku sampai"', (tester) async {
      await _Uji(_oven(riwayat: riwayat())).buka(tester);
      expect(find.text('Jadwal kalibrasi ulang ${_tgl(20)}'), findsOneWidget);
      expect(find.textContaining('Berlaku sampai'), findsNothing);
    });

    testWidgets('jadwal tampil untuk sertifikat yang berlaku', (tester) async {
      await _Uji(
        _oven(
          riwayat: [
            sertifikatJson(
              31,
              'CAL/ALFA/0031',
              diterbitkan: -345,
              berlakuSampai: 20,
            ),
          ],
        ),
      ).buka(tester);
      expect(find.text('Jadwal kalibrasi ulang ${_tgl(20)}'), findsOneWidget);
    });

    testWidgets('jadwal TIDAK tampil untuk sertifikat dibatalkan maupun '
        'digantikan (sama dengan daftar sertifikat)', (tester) async {
      await _Uji(
        _oven(
          riwayat: [
            sertifikatJson(
              33,
              'CAL/ALFA/0033',
              diterbitkan: -100,
              berlakuSampai: 20,
            ),
            sertifikatJson(
              32,
              'CAL/ALFA/0032',
              diterbitkan: -345,
              berlakuSampai: 11,
              status: 'digantikan',
              digantikanOleh: {'id': 33, 'nomor': 'CAL/ALFA/0033'},
            ),
            sertifikatJson(
              31,
              'CAL/ALFA/0031',
              diterbitkan: -710,
              berlakuSampai: 7,
              status: 'dibatalkan',
              dibatalkanPada: -600,
            ),
          ],
        ),
      ).buka(tester);
      // Yang berlaku tetap menunjukkan jadwalnya.
      expect(find.text('Jadwal kalibrasi ulang ${_tgl(20)}'), findsOneWidget);
      // Jadwal usang pada yang digantikan/dibatalkan bisa dikira masih harus
      // dipenuhi: tidak ditampilkan.
      expect(find.text('Jadwal kalibrasi ulang ${_tgl(11)}'), findsNothing);
      expect(find.text('Jadwal kalibrasi ulang ${_tgl(7)}'), findsNothing);
      // (Label bagian jadwal alat tanpa tanggal, jadi dicocokkan dengan spasi.)
      expect(find.textContaining('Jadwal kalibrasi ulang '), findsOneWidget);
      // Riwayatnya sendiri tetap utuh dengan statusnya.
      expect(find.text('CAL/ALFA/0032'), findsOneWidget);
      expect(find.text('CAL/ALFA/0031'), findsOneWidget);
      expect(find.text('Digantikan oleh CAL/ALFA/0033'), findsOneWidget);
    });

    testWidgets('kosong: penjelasan, bukan kartu kosong tanpa kata', (
      tester,
    ) async {
      await _Uji(_oven()).buka(tester);
      expect(find.text('Belum ada sertifikat'), findsOneWidget);
    });

    test('terbaruDiAtas: tanggal menurun, sama tanggal tetap berurutan, tanpa '
        'tanggal di dasar', () {
      Sertifikat s(int id, int? hari) => Sertifikat.dariJson({
        'id': id,
        'nomor': 'N$id',
        'diterbitkan_pada': hari == null ? null : tanggalUji(hari),
      });
      final hasil = AlatDetailScreen.terbaruDiAtas([
        s(1, null),
        s(2, -10),
        s(3, -5),
        s(4, -10),
        s(5, -5),
      ]);
      expect([for (final x in hasil) x.id], [3, 5, 2, 4, 1]);
      expect(AlatDetailScreen.terbaruDiAtas(const []), isEmpty);
    });
  });

  group('layar sempit dan huruf besar', () {
    for (final gelap in [false, true]) {
      testWidgets('320 dp x 1,3 ${gelap ? 'gelap' : 'terang'}: nama alat '
          'sangat panjang utuh, tanpa luapan', (tester) async {
        final panjang =
            'Alat Ukur Tekanan Digital Presisi Tinggi Untuk Laboratorium '
            'Pusat Dan Cabang ${'Sangat ' * 6}Panjang';
        final u = _Uji({
          ..._oven(
            riwayat: [sertifikatJson(31, 'CAL/ALFA/0031', diterbitkan: -345)],
            tambahan: {
              'sedang_dikerjakan': sedangDikerjakanJson(),
              'catatan': 'Catatan panjang ${'sekali ' * 20}selesai.',
            },
          ),
          'nama': panjang,
        });
        await u.buka(tester, lebar: 320, skala: 1.3, gelap: gelap);
        expect(tester.takeException(), isNull);
        expect(find.text(panjang), findsOneWidget);
        // Kontrol di kelompok identitas: >= 48 dp.
        expect(
          tester.getSize(find.byTooltip('Salin nomor seri')).height,
          greaterThanOrEqualTo(48),
        );
      });
    }
  });
}
