// Layar "Hubungi PT SIDIK" (P5d, PR-A; REVISI-2 butir 12): identitas dan
// akreditasi, kanal ringkas dengan salin satu ketuk, tautan sekunder, tombol
// yang field-nya null tersembunyi, hanya skema https/mailto/tel yang dibuka, dan
// jalan masuknya dari Akun, pemeliharaan, dan akun belum aktif.
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import 'package:sidik_pelanggan/core/api_pelanggan.dart';
import 'package:sidik_pelanggan/core/tema/tema_sidik.dart';
import 'package:sidik_pelanggan/models/akun.dart';
import 'package:sidik_pelanggan/providers/sesi_provider.dart';
import 'package:sidik_pelanggan/providers/tautan_provider.dart';
import 'package:sidik_pelanggan/screens/akun/hubungi_screen.dart';
import 'package:sidik_pelanggan/screens/gerbang.dart';
import 'package:sidik_pelanggan/widgets/lencana_kan.dart';
import 'package:sidik_pelanggan/widgets/tombol_sidik.dart';

import 'dukungan/fixture_fitur.dart';
import 'dukungan/layar_uji.dart';

const _alamat =
    'Komplek Nuansa Mas Estate, Blk. E No.2, Cipamokolan, Rancasari, '
    'Bandung 40292';
const _ruangLingkup =
    'https://pt-sidik.com/wp-content/uploads/2026/11/'
    'Ruang-Lingkup-SIDIK-ILK-285-IDN-L-Amd-1-30Sep2026.pdf';

Map<String, dynamic> _json({
  Map<String, dynamic>? kontak,
  Map<String, dynamic>? organisasi,
  Map<String, dynamic>? dokumen,
}) => {
  'organisasi':
      organisasi ??
      {
        'nama': 'PT Sistem Dirgantara Inovasi Teknologi (SIDIK)',
        'alamat': _alamat,
        'telepon': '082260060037',
      },
  'kontak':
      kontak ??
      {
        'whatsapp': '+62 822-6006-0037',
        'whatsapp_url': 'https://wa.me/6282260060037',
        'email': 'sidikkalibrasi@pt-sidik.com',
        'jam_layanan': null,
        'email_pemasaran': 'marketingkalibrasi@pt-sidik.com',
        'instagram_url': 'https://www.instagram.com/ptsidikbdg/',
        'linkedin_url':
            'https://www.linkedin.com/company/'
            'pt-sistem-dirgantara-inovasi-teknologi-sidik',
      },
  'dokumen': dokumen ?? {'ruang_lingkup_url': _ruangLingkup},
  'petunjuk_pengemasan': null,
};

InfoAplikasi _info([Map<String, dynamic>? j]) =>
    InfoAplikasi.dariJson(j ?? _json());

/// Cara membuka layar: info diberikan lewat override, tautan yang dibuka dicatat.
class _Uji {
  _Uji(this.info, {this.berhasilBuka = true});

  final InfoAplikasi info;
  final bool berhasilBuka;
  final dibuka = <Uri>[];
  final tersalin = <String>[];

  List<Override> get overrides => [
    infoAplikasiProvider.overrideWith((ref) async => info),
    pembukaTautanProvider.overrideWithValue((uri) async {
      dibuka.add(uri);
      return berhasilBuka;
    }),
  ];

  void pasangPapanKlip(WidgetTester tester) {
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
  }

  Future<void> buka(
    WidgetTester tester, {
    Widget layar = const HubungiScreen(),
    double skala = 1.0,
    bool gelap = false,
  }) async {
    pasangPapanKlip(tester);
    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides,
        child: MaterialApp(
          theme: TemaSidik.terang,
          darkTheme: TemaSidik.gelap,
          themeMode: gelap ? ThemeMode.dark : ThemeMode.light,
          builder: (context, child) => MediaQuery.withClampedTextScaling(
            minScaleFactor: skala,
            maxScaleFactor: skala,
            child: child!,
          ),
          home: layar,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }
}

Finder _baris(String judul) => find.bySemanticsLabel(RegExp('^$judul, '));

void main() {
  setUpAll(siapkanTesFitur);

  group('isi lengkap dari situs resmi', () {
    testWidgets('identitas, akreditasi, tombol utama, kanal, dan tautan', (
      tester,
    ) async {
      final semantik = tester.ensureSemantics();
      layarHp(tester, lebar: 392, tinggi: 1600);
      await _Uji(_info()).buka(tester);

      expect(find.text('Hubungi PT SIDIK'), findsOneWidget, reason: 'judul');
      expect(
        find.text('PT Sistem Dirgantara Inovasi Teknologi (SIDIK)'),
        findsOneWidget,
      );
      expect(find.byType(LencanaKan), findsOneWidget);
      expect(find.textContaining('LK-285-IDN'), findsOneWidget);
      expect(find.text('Chat dengan admin'), findsOneWidget);
      expect(find.text('WhatsApp +62 822-6006-0037'), findsOneWidget);
      for (final k in [
        'Telepon',
        'Email',
        'Email pemasaran',
        'Alamat',
        'Instagram',
        'LinkedIn',
        'Ruang lingkup akreditasi',
      ]) {
        expect(_baris(k), findsOneWidget, reason: k);
      }
      expect(find.text('082260060037'), findsOneWidget);
      expect(find.text('sidikkalibrasi@pt-sidik.com'), findsOneWidget);
      expect(find.text('marketingkalibrasi@pt-sidik.com'), findsOneWidget);
      expect(find.text(_alamat), findsOneWidget);
      expect(find.text('www.instagram.com/ptsidikbdg'), findsOneWidget);
      // Jam layanan TIDAK dikarang: server mengirim null.
      expect(find.textContaining('Jam layanan'), findsNothing);
      // Satu tombol utama saja.
      expect(
        tester
            .widgetList<TombolSidik>(find.byType(TombolSidik))
            .where((t) => t.ragam == RagamTombol.utama),
        hasLength(1),
      );
      semantik.dispose();
    });

    testWidgets('jam layanan hanya bila server mengirimnya', (tester) async {
      layarHp(tester, lebar: 392, tinggi: 1600);
      final j = _json();
      (j['kontak'] as Map)['jam_layanan'] = 'Senin–Jumat, 08.00–16.00 WIB';
      await _Uji(_info(j)).buka(tester);
      expect(
        find.text('Jam layanan: Senin–Jumat, 08.00–16.00 WIB'),
        findsOneWidget,
      );
    });

    testWidgets('mengetuk tiap kanal membuka tautan yang benar', (
      tester,
    ) async {
      layarHp(tester, lebar: 392, tinggi: 1600);
      final u = _Uji(_info());
      await u.buka(tester);

      Future<Uri> ketuk(Finder f) async {
        final sebelum = u.dibuka.length;
        await tester.ensureVisible(f);
        await tester.tap(f);
        await tester.pump();
        expect(u.dibuka.length, sebelum + 1);
        return u.dibuka.last;
      }

      expect(
        (await ketuk(find.text('Chat dengan admin'))).toString(),
        'https://wa.me/6282260060037',
      );
      expect(
        (await ketuk(find.text('082260060037'))).toString(),
        'tel:082260060037',
      );
      expect(
        (await ketuk(find.text('sidikkalibrasi@pt-sidik.com'))).toString(),
        'mailto:sidikkalibrasi@pt-sidik.com',
      );
      expect(
        (await ketuk(find.text('marketingkalibrasi@pt-sidik.com'))).toString(),
        'mailto:marketingkalibrasi@pt-sidik.com',
      );
      final peta = await ketuk(find.text(_alamat));
      expect(peta.host, 'www.google.com');
      expect(peta.path, '/maps/search/');
      expect(peta.queryParameters['query'], _alamat);
      expect(
        (await ketuk(find.text('www.instagram.com/ptsidikbdg'))).toString(),
        'https://www.instagram.com/ptsidikbdg/',
      );
      expect(
        (await ketuk(find.textContaining('www.linkedin.com/company/'))).host,
        'www.linkedin.com',
      );
      expect(
        (await ketuk(
          find.text('Dokumen PDF, dibuka di aplikasi lain'),
        )).toString(),
        _ruangLingkup,
      );
    });
  });

  group('salin satu ketuk + konfirmasi', () {
    for (final kasus in [
      (
        tip: 'Salin nomor telepon',
        isi: '082260060037',
        konfirmasi: 'Nomor telepon disalin.',
      ),
      (
        tip: 'Salin alamat email',
        isi: 'sidikkalibrasi@pt-sidik.com',
        konfirmasi: 'Alamat email disalin.',
      ),
      (
        tip: 'Salin alamat email pemasaran',
        isi: 'marketingkalibrasi@pt-sidik.com',
        konfirmasi: 'Alamat email pemasaran disalin.',
      ),
      (tip: 'Salin alamat', isi: _alamat, konfirmasi: 'Alamat disalin.'),
    ]) {
      testWidgets('${kasus.tip}: papan klip berisi nilai, ada konfirmasi', (
        tester,
      ) async {
        layarHp(tester, lebar: 392, tinggi: 1600);
        final u = _Uji(_info());
        await u.buka(tester);
        final tombol = find.byTooltip(kasus.tip);
        expect(tombol, findsOneWidget);
        expect(tester.getSize(tombol).width, greaterThanOrEqualTo(48));
        expect(tester.getSize(tombol).height, greaterThanOrEqualTo(48));
        await tester.ensureVisible(tombol);
        await tester.tap(tombol);
        await tester.pump();
        expect(u.tersalin, [kasus.isi]);
        expect(find.text(kasus.konfirmasi), findsOneWidget);
        expect(u.dibuka, isEmpty, reason: 'menyalin tidak membuka apa pun');
      });
    }
  });

  group('field null disembunyikan; server lama tetap jalan', () {
    testWidgets('semua kosong: kalimat jujur, nol tombol kontak', (
      tester,
    ) async {
      layarHp(tester, lebar: 392, tinggi: 1600);
      await _Uji(InfoAplikasi.kosong).buka(tester);
      expect(find.text('Informasi kontak belum tersedia.'), findsOneWidget);
      expect(find.text('Chat dengan admin'), findsNothing);
      expect(find.byType(TombolSidik), findsNothing);
      expect(find.byTooltip('Salin nomor telepon'), findsNothing);
      // Tanpa nama dari server: tetap judul PT SIDIK, tanpa nama karangan.
      expect(find.text('PT SIDIK'), findsOneWidget);
    });

    testWidgets('server lama (tanpa email pemasaran, sosial, dokumen)', (
      tester,
    ) async {
      layarHp(tester, lebar: 392, tinggi: 1600);
      final lama = _json(
        kontak: {
          'whatsapp': '+62 822-6006-0037',
          'whatsapp_url': 'https://wa.me/6282260060037',
          'email': 'sidikkalibrasi@pt-sidik.com',
          'jam_layanan': null,
        },
        dokumen: {},
      );
      await _Uji(_info(lama)).buka(tester);
      expect(find.text('Chat dengan admin'), findsOneWidget);
      expect(_baris('Telepon'), findsOneWidget);
      expect(_baris('Email'), findsOneWidget);
      for (final k in [
        'Email pemasaran',
        'Instagram',
        'LinkedIn',
        'Ruang lingkup akreditasi',
      ]) {
        expect(_baris(k), findsNothing, reason: k);
      }
      expect(
        find.text('Tautan'),
        findsNothing,
        reason: 'tanpa judul bagian kosong',
      );
    });

    testWidgets('hanya email: hanya baris Email, tanpa tombol utama', (
      tester,
    ) async {
      layarHp(tester, lebar: 392, tinggi: 1600);
      await _Uji(
        _info(
          _json(
            kontak: {'email': 'sidikkalibrasi@pt-sidik.com'},
            organisasi: {},
            dokumen: {},
          ),
        ),
      ).buka(tester);
      expect(_baris('Email'), findsOneWidget);
      expect(_baris('Telepon'), findsNothing);
      expect(_baris('Alamat'), findsNothing);
      expect(find.text('Chat dengan admin'), findsNothing);
    });
  });

  group('URL aneh atau berbahaya dari server tidak pernah dibuka', () {
    testWidgets('semua isian berbahaya: tidak ada tombol, tidak ada tautan', (
      tester,
    ) async {
      layarHp(tester, lebar: 392, tinggi: 1600);
      final jahat = _json(
        kontak: {
          'whatsapp': '+62 822-6006-0037',
          'whatsapp_url': 'javascript:alert(1)',
          'email': 'a@b',
          'email_pemasaran': 'x@y.com\r\nBcc: z@w.com',
          'instagram_url': 'http://www.instagram.com/ptsidikbdg/',
          'linkedin_url': 'file:///sdcard/rahasia',
        },
        organisasi: {'telepon': 'abc', 'alamat': '   '},
        dokumen: {'ruang_lingkup_url': 'https://pt-sidik.com@evil.test/x.pdf'},
      );
      final info = _info(jahat);
      expect(info.adaKontak, isFalse);
      expect(info.bisaTanyaAdmin, isFalse);
      final u = _Uji(info);
      await u.buka(tester);
      expect(find.text('Chat dengan admin'), findsNothing);
      for (final k in [
        'Telepon',
        'Email',
        'Email pemasaran',
        'Alamat',
        'Instagram',
        'LinkedIn',
        'Ruang lingkup akreditasi',
      ]) {
        expect(_baris(k), findsNothing, reason: k);
      }
      expect(find.text('Informasi kontak belum tersedia.'), findsOneWidget);
      expect(u.dibuka, isEmpty);
    });

    testWidgets('tautan WhatsApp ke host lain disembunyikan; sisanya tetap', (
      tester,
    ) async {
      layarHp(tester, lebar: 392, tinggi: 1600);
      final j = _json();
      (j['kontak'] as Map)['whatsapp_url'] = 'https://wa.me.evil.test/628';
      await _Uji(_info(j)).buka(tester);
      expect(find.text('Chat dengan admin'), findsNothing);
      expect(_baris('Telepon'), findsOneWidget);
    });
  });

  group('aplikasi tujuan tidak ada', () {
    testWidgets('WhatsApp tidak terpasang: pesan jelas, bukan diam', (
      tester,
    ) async {
      layarHp(tester, lebar: 392, tinggi: 1600);
      final u = _Uji(_info(), berhasilBuka: false);
      await u.buka(tester);
      await tester.tap(find.text('Chat dengan admin'));
      await tester.pump();
      expect(find.text('WhatsApp belum terpasang di HP ini.'), findsOneWidget);
    });

    testWidgets('kanal lain tanpa aplikasi: pesan umum', (tester) async {
      layarHp(tester, lebar: 392, tinggi: 1600);
      final u = _Uji(_info(), berhasilBuka: false);
      await u.buka(tester);
      await tester.tap(find.text('sidikkalibrasi@pt-sidik.com'));
      await tester.pump();
      expect(find.text('Tidak ada aplikasi untuk membukanya.'), findsOneWidget);
    });
  });

  group('info lama tetap tampil bila pemuatan ulang gagal', () {
    testWidgets('kontak yang pernah terbaca tidak diganti layar galat', (
      tester,
    ) async {
      layarHp(tester, lebar: 392, tinggi: 1600);
      var panggilan = 0;
      final container = ProviderContainer(
        retry: (_, _) => null,
        overrides: [
          infoAplikasiProvider.overrideWith((ref) async {
            panggilan++;
            if (panggilan > 1) {
              throw const GalatApi(status: 503, pesan: 'Server tidur.');
            }
            return _info();
          }),
          pembukaTautanProvider.overrideWithValue((_) async => true),
        ],
      );
      addTearDown(container.dispose);
      await container.read(infoAplikasiProvider.future);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: TemaSidik.terang,
            home: const HubungiScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(panggilan, greaterThan(1), reason: 'dimuat ulang saat dibuka');
      expect(find.text('Chat dengan admin'), findsOneWidget);
      expect(find.text('Server tidur.'), findsNothing);
    });
  });

  group('semantik dan ukuran', () {
    testWidgets('tiap kanal = tombol berlabel penuh; salin = tombol sendiri', (
      tester,
    ) async {
      final semantik = tester.ensureSemantics();
      layarHp(tester, lebar: 392, tinggi: 1600);
      await _Uji(_info()).buka(tester);
      final telepon = tester
          .getSemantics(
            find.bySemanticsLabel(
              'Telepon, 082260060037. Ketuk untuk menelepon.',
            ),
          )
          .getSemanticsData();
      expect(telepon.flagsCollection.isButton, isTrue);
      expect(telepon.hasAction(SemanticsAction.tap), isTrue);
      final salin = tester
          .getSemantics(find.byTooltip('Salin nomor telepon'))
          .getSemanticsData();
      expect(salin.flagsCollection.isButton, isTrue);
      expect(salin.tooltip, 'Salin nomor telepon');
      semantik.dispose();
    });

    for (final gelap in [false, true]) {
      for (final lebar in [320.0, 360.0]) {
        testWidgets(
          '${gelap ? 'gelap' : 'terang'} $lebar dp x 1,3: tanpa luapan, '
          'baris >= 48',
          (tester) async {
            layarHp(tester, lebar: lebar, tinggi: 2400);
            await _Uji(_info()).buka(tester, skala: 1.3, gelap: gelap);
            expect(tester.takeException(), isNull);
            for (final k in [
              'Telepon',
              'Email',
              'Alamat',
              'Ruang lingkup akreditasi',
            ]) {
              expect(
                tester.getSize(_baris(k)).height,
                greaterThanOrEqualTo(48),
                reason: k,
              );
            }
            final utama = find.widgetWithText(TombolSidik, 'Chat dengan admin');
            expect(tester.getSize(utama).height, greaterThanOrEqualTo(48));
          },
        );
      }
    }
  });

  group('jalan masuk: pemeliharaan dan akun belum aktif', () {
    testWidgets('pemeliharaan: tombol Hubungi PT SIDIK membuka layar Hubungi', (
      tester,
    ) async {
      layarHp(tester, lebar: 392, tinggi: 1000);
      await _Uji(_info()).buka(
        tester,
        layar: const LayarPemeliharaan(pesan: 'Sedang diperbarui.'),
      );
      expect(find.text('Periksa lagi'), findsOneWidget);
      final tombol = find.text('Hubungi PT SIDIK');
      expect(tombol, findsOneWidget);
      await tester.tap(tombol);
      await tester.pumpAndSettle();
      expect(find.byType(HubungiScreen), findsOneWidget);
      expect(find.text('Chat dengan admin'), findsOneWidget);
    });

    testWidgets('pemeliharaan tanpa kontak (info kosong atau tak aman): '
        'tidak ada tombol Hubungi', (tester) async {
      layarHp(tester, lebar: 392, tinggi: 1000);
      await _Uji(InfoAplikasi.kosong).buka(
        tester,
        layar: const LayarPemeliharaan(pesan: 'Sedang diperbarui.'),
      );
      expect(find.text('Hubungi PT SIDIK'), findsNothing);
      expect(find.text('Periksa lagi'), findsOneWidget);
    });
  });
}
