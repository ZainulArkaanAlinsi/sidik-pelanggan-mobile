// Detail sertifikat (P5d-B, REVISI-2 butir 5): lima kelompok (identitas
// dokumen, alat, status dokumen, hasil teknis, tindakan), "Jadwal kalibrasi
// ulang" (bukan "Berlaku sampai"), pengganti dengan tautan, dibatalkan dengan
// pesan SEBELUM tombolnya, dan hasil tidak memenuhi tetap tampil apa adanya.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sidik_pelanggan/core/format.dart';
import 'package:sidik_pelanggan/core/tema/tema_sidik.dart';
import 'package:sidik_pelanggan/models/akun.dart';
import 'package:sidik_pelanggan/models/data_pelanggan.dart';
import 'package:sidik_pelanggan/providers/sesi_provider.dart';
import 'package:sidik_pelanggan/providers/tautan_provider.dart';
import 'package:sidik_pelanggan/screens/sertifikat/sertifikat_detail_screen.dart';
import 'package:sidik_pelanggan/widgets/bagian_sidik.dart';
import 'package:sidik_pelanggan/widgets/pemetaan_status.dart';
import 'package:sidik_pelanggan/widgets/tombol_sidik.dart';

import 'dukungan/fixture_fitur.dart';
import 'dukungan/layar_uji.dart';

Map<String, dynamic> _sert(
  int id, {
  String status = 'berlaku',
  String? keputusan = 'PASS',
  Map<String, dynamic>? digantikanOleh,
  int? dibatalkanPada,
  bool bisaDiunduh = true,
  Map<String, dynamic> tambahan = const {},
}) => {
  ...sertifikatJson(
    id,
    'CAL/ALFA/2026/00$id',
    namaAlat: 'Jangka Sorong Digital',
    status: status,
    keputusan: keputusan,
    digantikanOleh: digantikanOleh,
    dibatalkanPada: dibatalkanPada,
    bisaDiunduh: bisaDiunduh,
  ),
  ...tambahan,
};

class _Uji {
  _Uji(List<Map<String, dynamic>> sertifikat, {this.info, this.pembuka})
    : server = ServerFitur({
        3: DataPerusahaan(nama: 'PT Alfa', sertifikat: sertifikat),
      });

  final ServerFitur server;
  final InfoAplikasi? info;
  final PembukaTautan? pembuka;
  final tersalin = <String>[];

  Future<void> buka(
    WidgetTester tester,
    int id, {
    double lebar = 392,
    double skala = 1.0,
    bool gelap = false,
  }) async {
    layarHp(tester, lebar: lebar, tinggi: 3000);
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
        overrides: overrideFitur(
          server,
          tambahan: [
            if (info != null)
              infoAplikasiProvider.overrideWith((ref) async => info!),
            if (pembuka != null)
              pembukaTautanProvider.overrideWithValue(pembuka!),
          ],
        ),
        child: MaterialApp(
          theme: TemaSidik.terang,
          darkTheme: TemaSidik.gelap,
          themeMode: gelap ? ThemeMode.dark : ThemeMode.light,
          builder: (context, child) => MediaQuery.withClampedTextScaling(
            minScaleFactor: skala,
            maxScaleFactor: skala,
            child: child!,
          ),
          home: SertifikatDetailScreen(id: id),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }
}

InfoAplikasi _info() => InfoAplikasi.dariJson({
  'kontak': {
    'whatsapp_url': 'https://wa.me/6282260060037',
    'email': 'sidikkalibrasi@pt-sidik.com',
  },
});

String _tgl(int hari) => Format.tanggal(DateTime.parse(tanggalUji(hari)));

double _y(WidgetTester tester, Finder f) => tester.getTopLeft(f).dy;

void main() {
  setUpAll(siapkanTesFitur);

  group('kelompok informasi', () {
    testWidgets('berlaku dan memenuhi: lima kelompok berurutan dengan isinya', (
      tester,
    ) async {
      await _Uji([_sert(12)]).buka(tester, 12);
      final urutan = [
        'Identitas dokumen',
        'Alat',
        'Status dokumen',
        'Hasil teknis',
        'Tindakan',
      ];
      // Judul kelompok (BagianSidik), bukan baris berlabel sama.
      Finder bagian(String t) =>
          find.descendant(of: find.byType(BagianSidik), matching: find.text(t));
      for (var i = 0; i + 1 < urutan.length; i++) {
        expect(
          _y(tester, bagian(urutan[i])),
          lessThan(_y(tester, bagian(urutan[i + 1]))),
          reason: '${urutan[i]} sebelum ${urutan[i + 1]}',
        );
      }
      // Identitas dokumen.
      expect(find.text('Nomor sertifikat'), findsOneWidget);
      expect(find.text('CAL/ALFA/2026/0012'), findsOneWidget);
      expect(find.text('Diterbitkan'), findsOneWidget);
      expect(find.textContaining('LK-285-IDN'), findsOneWidget);
      // Baris bertombol salin sejajar dengan tetangganya (nilai di kolom sama).
      double x(String t) => tester.getTopLeft(find.text(t)).dx;
      expect(x('CAL/ALFA/2026/0012'), x(_tgl(-300)));
      expect(x('SN-1'), x('Mitutoyo'));
      // Alat.
      expect(find.text('Nama alat'), findsOneWidget);
      expect(find.text('Jangka Sorong Digital'), findsOneWidget);
      expect(find.text('Mitutoyo'), findsOneWidget);
      expect(find.text('SN-1'), findsOneWidget);
      // Status dokumen dan jadwal kalibrasi ulang.
      expect(
        find.text(statusDokumen(StatusDokumen.berlaku).label),
        findsOneWidget,
      );
      expect(find.text('Jadwal kalibrasi ulang'), findsOneWidget);
      expect(find.text(_tgl(65)), findsOneWidget);
      expect(find.textContaining('Berlaku sampai'), findsNothing);
      // Hasil teknis.
      expect(find.text(statusKeputusan('PASS')!.label), findsOneWidget);
      // Tindakan: satu aksi utama.
      expect(
        tester
            .widgetList<TombolSidik>(find.byType(TombolSidik))
            .where((t) => t.ragam == RagamTombol.utama),
        hasLength(1),
      );
      expect(find.text('Lihat PDF'), findsOneWidget);
      expect(find.text('Unduh PDF'), findsOneWidget);
    });

    testWidgets('rincian kalibrasi: kelompok sendiri hanya bila ada', (
      tester,
    ) async {
      await _Uji([
        _sert(
          12,
          tambahan: {
            'rincian': {'metode': 'IK-01', 'lokasi_kalibrasi': 'Laboratorium'},
          },
        ),
        _sert(13),
      ]).buka(tester, 12);
      expect(find.text('Rincian kalibrasi'), findsOneWidget);
      expect(find.text('Metode'), findsOneWidget);
      expect(find.text('IK-01'), findsOneWidget);
      expect(find.text('Lokasi kalibrasi'), findsOneWidget);
    });

    testWidgets('tanpa rincian: tidak ada kelompok kosong', (tester) async {
      await _Uji([_sert(12)]).buka(tester, 12);
      expect(find.text('Rincian kalibrasi'), findsNothing);
    });

    testWidgets('nomor sertifikat dan nomor seri bisa disalin satu ketuk', (
      tester,
    ) async {
      final u = _Uji([_sert(12)]);
      await u.buka(tester, 12);
      await tester.tap(find.byTooltip('Salin nomor sertifikat'));
      await tester.pump();
      expect(u.tersalin, ['CAL/ALFA/2026/0012']);
      expect(find.text('Nomor sertifikat disalin.'), findsOneWidget);
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Salin nomor seri'));
      await tester.pump();
      expect(u.tersalin.last, 'SN-1');
    });

    testWidgets('data alat kosong: "Belum tersedia", tanpa tombol salin', (
      tester,
    ) async {
      await _Uji([
        _sert(
          12,
          tambahan: {
            'alat': {'id': 1, 'nama': null, 'merk': null, 'serial': null},
          },
        ),
      ]).buka(tester, 12);
      expect(find.text('Belum tersedia'), findsNWidgets(3));
      expect(find.byTooltip('Salin nomor seri'), findsNothing);
    });

    testWidgets('hasil tidak dinyatakan: tidak ada kelompok Hasil teknis', (
      tester,
    ) async {
      await _Uji([_sert(12, keputusan: null)]).buka(tester, 12);
      expect(find.text('Hasil teknis'), findsNothing);
    });

    testWidgets('TIDAK MEMENUHI tetap tampil apa adanya (REQ-SRT-04)', (
      tester,
    ) async {
      await _Uji([_sert(13, keputusan: 'FAIL')]).buka(tester, 13);
      expect(find.text('Hasil teknis'), findsOneWidget);
      expect(find.text(statusKeputusan('FAIL')!.label), findsOneWidget);
      expect(find.text('Tidak memenuhi toleransi.'), findsOneWidget);
    });
  });

  group('status dokumen', () {
    testWidgets('digantikan: tautan ke pengganti, status Digantikan, PDF lama '
        'tetap bisa dibuka dan dijelaskan SEBELUM tombolnya', (tester) async {
      final u = _Uji([
        _sert(
          9,
          status: 'digantikan',
          digantikanOleh: {'id': 12, 'nomor': 'CAL/ALFA/2026/0012'},
        ),
        _sert(12),
      ]);
      await u.buka(tester, 9);
      expect(find.text('Sertifikat ini sudah digantikan'), findsOneWidget);
      expect(
        find.text(statusDokumen(StatusDokumen.digantikan).label),
        findsOneWidget,
      );
      final catatan = find.text(
        'PDF lama tetap bisa dibuka dan diunduh sebagai riwayat.',
      );
      expect(catatan, findsOneWidget);
      expect(
        _y(tester, catatan),
        lessThan(_y(tester, find.text('Lihat PDF'))),
        reason: 'penjelasan sebelum tombol',
      );
      await tester.tap(find.text('Buka yang berlaku'));
      await tester.pumpAndSettle();
      expect(find.text('CAL/ALFA/2026/0012'), findsOneWidget);
    });

    testWidgets('dibatalkan: pesan jelas SEBELUM membuka atau mengunduh, '
        'tombol mati, tanpa jadwal dan hasil', (tester) async {
      final u = _Uji([
        _sert(11, status: 'dibatalkan', dibatalkanPada: -2, bisaDiunduh: false),
      ], info: _info());
      await u.buka(tester, 11);
      expect(find.textContaining('Dibatalkan pada'), findsOneWidget);
      expect(
        find.text(statusDokumen(StatusDokumen.dibatalkan).label),
        findsOneWidget,
      );
      final catatan = find.text(
        'Sertifikat yang dibatalkan tidak bisa dibuka maupun diunduh.',
      );
      expect(catatan, findsOneWidget);
      expect(_y(tester, catatan), lessThan(_y(tester, find.text('Lihat PDF'))));
      for (final k in ['Lihat PDF', 'Unduh PDF']) {
        expect(
          tester
              .widget<TombolSidik>(find.widgetWithText(TombolSidik, k))
              .onPressed,
          isNull,
          reason: k,
        );
      }
      // Yang dibatalkan tidak membawa jadwal maupun hasil teknis.
      expect(find.text('Jadwal kalibrasi ulang'), findsNothing);
      expect(find.text('Hasil teknis'), findsNothing);
      // Tanya admin tetap ada (kontak tersedia).
      expect(find.text('Tanya tentang sertifikat ini'), findsOneWidget);
      expect(find.text('Laporkan data yang keliru'), findsOneWidget);
    });

    testWidgets('belum siap diunduh: dijelaskan sebelum tombol', (
      tester,
    ) async {
      await _Uji([_sert(12, bisaDiunduh: false)]).buka(tester, 12);
      final catatan = find.text(
        'PDF sedang disiapkan laboratorium. Coba lagi nanti.',
      );
      expect(catatan, findsOneWidget);
      expect(_y(tester, catatan), lessThan(_y(tester, find.text('Lihat PDF'))));
    });
  });

  group('layar sempit dan huruf besar', () {
    for (final gelap in [false, true]) {
      testWidgets('320 dp x 1,3 ${gelap ? 'gelap' : 'terang'}: semua kelompok '
          'tanpa luapan, kontrol >= 48 dp', (tester) async {
        final u = _Uji([
          _sert(
            12,
            tambahan: {
              'rincian': {
                'metode': 'IK-01 ${'metode panjang ' * 5}',
                'kondisi_lingkungan': 'Suhu 20 °C, kelembapan 50 %',
              },
              'penanda_tangan': {
                'nama': 'Manajer Teknis Dengan Nama Sangat Panjang',
                'jabatan': 'Manajer Teknis',
              },
            },
          ),
        ], info: _info());
        await u.buka(tester, 12, lebar: 320, skala: 1.3, gelap: gelap);
        expect(tester.takeException(), isNull);
        for (final k in ['Salin nomor sertifikat', 'Salin nomor seri']) {
          expect(
            tester.getSize(find.byTooltip(k)).height,
            greaterThanOrEqualTo(48),
            reason: k,
          );
        }
        for (final tombol in tester.widgetList<TombolSidik>(
          find.byType(TombolSidik),
        )) {
          expect(
            tester
                .getSize(find.widgetWithText(TombolSidik, tombol.label))
                .height,
            greaterThanOrEqualTo(48),
            reason: tombol.label,
          );
        }
      });
    }
  });

  group('halaman verifikasi', () {
    // Tautan datang dari server: hanya https bertuan rumah yang dibuka, dan
    // tautan rusak tidak boleh melempar (tombol ini dulu memanggil
    // `launchUrl(Uri.parse(...))` langsung).
    Future<List<Uri>> ketuk(WidgetTester tester, String tautan) async {
      final dibuka = <Uri>[];
      final u = _Uji(
        [
          _sert(7, tambahan: {'tautan_verifikasi': tautan}),
        ],
        pembuka: (uri) async {
          dibuka.add(uri);
          return true;
        },
      );
      await u.buka(tester, 7);
      await tester.tap(find.text('Buka halaman verifikasi'));
      await tester.pumpAndSettle();
      return dibuka;
    }

    testWidgets('https yang benar dibuka lewat pembuka tautan', (tester) async {
      final dibuka = await ketuk(tester, 'https://pt-sidik.com/verify/abc');
      expect(dibuka, [Uri.parse('https://pt-sidik.com/verify/abc')]);
      expect(tester.takeException(), isNull);
      expect(find.text('Tidak ada aplikasi untuk membukanya.'), findsNothing);
    });

    for (final jelek in [
      'javascript:alert(1)',
      'http://pt-sidik.com/verify/abc',
      'intent://scan#Intent;scheme=zxing;end',
      'file:///sdcard/x.pdf',
      'https://[::1',
      'https://',
      'https://user:sandi@pt-sidik.com/verify/abc',
      'https://pt-sidik.com/verify/ab c',
      '%zz',
    ]) {
      testWidgets('ditolak tanpa melempar dan tanpa membuka: $jelek', (
        tester,
      ) async {
        final dibuka = await ketuk(tester, jelek);
        expect(dibuka, isEmpty);
        expect(tester.takeException(), isNull);
        expect(
          find.text('Tidak ada aplikasi untuk membukanya.'),
          findsOneWidget,
        );
      });
    }
  });
}
