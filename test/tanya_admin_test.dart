// "Tanya admin tentang ini" (P5d, PR-A): tombol kontekstual di detail alat dan
// detail sertifikat. Pesan terisi dari data layar, pratinjau di lembar bawah,
// WhatsApp (fallback email), salin; app tetap BACA-SAJA.
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
import 'package:sidik_pelanggan/screens/alat/alat_detail_screen.dart';
import 'package:sidik_pelanggan/screens/sertifikat/sertifikat_detail_screen.dart';
import 'package:sidik_pelanggan/widgets/lembar_tanya_admin.dart';
import 'package:sidik_pelanggan/widgets/pemetaan_status.dart';

import 'dukungan/fixture_fitur.dart';
import 'dukungan/layar_uji.dart';

InfoAplikasi _info({
  String? whatsappUrl = 'https://wa.me/6282260060037',
  String? email = 'sidikkalibrasi@pt-sidik.com',
}) => InfoAplikasi.dariJson({
  'organisasi': {'nama': 'PT SIDIK'},
  'kontak': {'whatsapp_url': whatsappUrl, 'email': email},
});

class _Uji {
  _Uji({
    InfoAplikasi? info,
    this.waTerpasang = true,
    this.emailTerpasang = true,
    List<Map<String, dynamic>>? alat,
    List<Map<String, dynamic>>? sertifikat,
  }) : info = info ?? _info(),
       server = ServerFitur({
         3: DataPerusahaan(
           nama: 'PT Alfa',
           alat:
               alat ??
               [
                 alatJson(
                   1,
                   'Oven Memmert',
                   hari: 20,
                   merk: 'Memmert',
                   model: 'UF55',
                   serial: '0457-2201',
                 ),
               ],
           sertifikat:
               sertifikat ??
               [
                 sertifikatJson(
                   12,
                   'CAL/2026/11/0012',
                   namaAlat: 'Oven Memmert',
                 ),
               ],
         ),
       });

  final InfoAplikasi info;
  final bool waTerpasang;
  final bool emailTerpasang;
  final ServerFitur server;
  final dibuka = <Uri>[];
  final tersalin = <String>[];

  Future<void> buka(WidgetTester tester, Widget layar) async {
    layarHp(tester, lebar: 392, tinggi: 1800);
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
            infoAplikasiProvider.overrideWith((ref) async => info),
            pembukaTautanProvider.overrideWithValue((uri) async {
              dibuka.add(uri);
              if (uri.host == 'wa.me') return waTerpasang;
              if (uri.scheme == 'mailto') return emailTerpasang;
              return true;
            }),
          ],
        ),
        child: MaterialApp(theme: TemaSidik.terang, home: layar),
      ),
    );
    await tester.pumpAndSettle();
  }
}

String _pratinjau(WidgetTester tester) =>
    tester.widget<SelectableText>(find.byType(SelectableText)).data!;

String get _jadwalOven => Format.tanggal(DateTime.parse(tanggalUji(20)));

String _goldenAlat() => [
  'Halo admin PT SIDIK,',
  '',
  'Kami dari PT Alfa ingin meminta kalibrasi ulang alat berikut:',
  '- Alat: Oven Memmert',
  '- Merk/model: Memmert UF55',
  '- Nomor seri: 0457-2201',
  '- Jadwal kalibrasi ulang: $_jadwalOven',
  '',
  'Mohon informasi langkah berikutnya. Terima kasih.',
].join('\n');

void main() {
  setUpAll(siapkanTesFitur);

  group('detail alat: Minta kalibrasi ulang', () {
    testWidgets('tombol -> lembar pratinjau dengan pesan emas dan tombol WA '
        'utama', (tester) async {
      final u = _Uji();
      await u.buka(tester, const AlatDetailScreen(id: 1));
      expect(find.text('Minta kalibrasi ulang'), findsOneWidget);
      await tester.tap(find.text('Minta kalibrasi ulang'));
      await tester.pumpAndSettle();

      expect(find.byType(LembarTanyaAdmin), findsOneWidget);
      expect(_pratinjau(tester), _goldenAlat());
      expect(find.text('Buka WhatsApp'), findsOneWidget);
      expect(find.text('Kirim lewat email'), findsOneWidget);
      expect(find.text('Salin pesan'), findsOneWidget);
      expect(find.text('Batal'), findsOneWidget);
      expect(
        find.textContaining('aplikasi ini tidak mengirim apa pun sendiri'),
        findsOneWidget,
      );
      expect(u.dibuka, isEmpty, reason: 'pratinjau dulu, belum dikirim');
    });

    testWidgets('Buka WhatsApp: tautan wa.me/<nomor>?text=<pesan>, satu '
        'parameter, lembar tertutup', (tester) async {
      final u = _Uji();
      await u.buka(tester, const AlatDetailScreen(id: 1));
      await tester.tap(find.text('Minta kalibrasi ulang'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Buka WhatsApp'));
      await tester.pumpAndSettle();
      expect(u.dibuka, hasLength(1));
      final uri = u.dibuka.single;
      expect(uri.scheme, 'https');
      expect(uri.host, 'wa.me');
      expect(uri.path, '/6282260060037');
      expect(uri.queryParameters.keys, ['text']);
      expect(uri.queryParameters['text'], _goldenAlat());
      expect(find.byType(LembarTanyaAdmin), findsNothing);
    });

    testWidgets('tanpa WhatsApp: email jadi tombol utama; mailto berisi subjek '
        'dan isi', (tester) async {
      final u = _Uji(info: _info(whatsappUrl: null));
      await u.buka(tester, const AlatDetailScreen(id: 1));
      await tester.tap(find.text('Minta kalibrasi ulang'));
      await tester.pumpAndSettle();
      expect(find.text('Buka WhatsApp'), findsNothing);
      expect(
        find.textContaining('Pesan ini dibuka di aplikasi email'),
        findsOneWidget,
      );
      await tester.tap(find.text('Kirim lewat email'));
      await tester.pumpAndSettle();
      final uri = u.dibuka.single;
      expect(uri.scheme, 'mailto');
      expect(uri.path, 'sidikkalibrasi@pt-sidik.com');
      expect(
        uri.queryParameters['subject'],
        'Permintaan kalibrasi ulang: Oven Memmert (SN 0457-2201)',
      );
      expect(uri.queryParameters['body'], _goldenAlat());
    });

    testWidgets('tautan WhatsApp bukan wa.me/<nomor> (mis. tautan bisnis): '
        'jatuh ke email, bukan WhatsApp tanpa pesan', (tester) async {
      final u = _Uji(info: _info(whatsappUrl: 'https://wa.me/message/ABC123'));
      await u.buka(tester, const AlatDetailScreen(id: 1));
      await tester.tap(find.text('Minta kalibrasi ulang'));
      await tester.pumpAndSettle();
      expect(find.text('Buka WhatsApp'), findsNothing);
      expect(find.text('Kirim lewat email'), findsOneWidget);
    });

    testWidgets('kedua kanal kosong atau tak aman: tombol TIDAK ada', (
      tester,
    ) async {
      for (final info in [
        _info(whatsappUrl: null, email: null),
        _info(whatsappUrl: 'javascript:alert(1)', email: 'a@b'),
        InfoAplikasi.kosong,
      ]) {
        final u = _Uji(info: info);
        await u.buka(tester, const AlatDetailScreen(id: 1));
        expect(find.text('Oven Memmert'), findsWidgets);
        expect(find.text('Minta kalibrasi ulang'), findsNothing);
      }
    });

    testWidgets('info belum terbaca (server 404): tombol tidak ada, layar '
        'tetap utuh', (tester) async {
      layarHp(tester, lebar: 392, tinggi: 1800);
      final server = ServerFitur({
        3: DataPerusahaan(
          nama: 'PT Alfa',
          alat: [alatJson(1, 'Oven Memmert', hari: 20)],
        ),
      });
      await tester.pumpWidget(
        ProviderScope(
          overrides: overrideFitur(server),
          child: MaterialApp(
            theme: TemaSidik.terang,
            home: const AlatDetailScreen(id: 1),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Minta kalibrasi ulang'), findsNothing);
      expect(find.text('Riwayat kalibrasi'), findsOneWidget);
    });

    testWidgets('alat tidak aktif: tidak ditawari minta kalibrasi ulang', (
      tester,
    ) async {
      final u = _Uji(
        alat: [alatJson(1, 'Alat Lama', hari: 10, status: 'nonaktif')],
      );
      await u.buka(tester, const AlatDetailScreen(id: 1));
      expect(find.text('Minta kalibrasi ulang'), findsNothing);
    });

    testWidgets('Salin pesan: papan klip berisi pesan utuh, konfirmasi di '
        'dalam lembar', (tester) async {
      final u = _Uji();
      await u.buka(tester, const AlatDetailScreen(id: 1));
      await tester.tap(find.text('Minta kalibrasi ulang'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Salin pesan'));
      await tester.tap(find.text('Salin pesan'));
      await tester.pumpAndSettle();
      expect(u.tersalin, [_goldenAlat()]);
      expect(find.text('Pesan disalin.'), findsOneWidget);
      expect(u.dibuka, isEmpty);
      expect(
        find.byType(LembarTanyaAdmin),
        findsOneWidget,
        reason: 'tetap terbuka',
      );
    });

    testWidgets('WhatsApp tidak terpasang: lembar tetap terbuka dengan '
        'petunjuk salin, email tetap bisa', (tester) async {
      final u = _Uji(waTerpasang: false);
      await u.buka(tester, const AlatDetailScreen(id: 1));
      await tester.tap(find.text('Minta kalibrasi ulang'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Buka WhatsApp'));
      await tester.pumpAndSettle();
      expect(find.byType(LembarTanyaAdmin), findsOneWidget);
      expect(
        find.textContaining('WhatsApp belum terpasang di HP ini'),
        findsOneWidget,
      );
      await tester.ensureVisible(find.text('Kirim lewat email'));
      await tester.tap(find.text('Kirim lewat email'));
      await tester.pumpAndSettle();
      expect(u.dibuka.last.scheme, 'mailto');
      expect(find.byType(LembarTanyaAdmin), findsNothing);
    });

    testWidgets('WhatsApp dan email sama-sama tidak ada: petunjuk salin, pesan '
        'tetap bisa disalin', (tester) async {
      final u = _Uji(waTerpasang: false, emailTerpasang: false);
      await u.buka(tester, const AlatDetailScreen(id: 1));
      await tester.tap(find.text('Minta kalibrasi ulang'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Buka WhatsApp'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Kirim lewat email'));
      await tester.tap(find.text('Kirim lewat email'));
      await tester.pumpAndSettle();
      expect(find.byType(LembarTanyaAdmin), findsOneWidget);
      expect(
        find.textContaining('Tidak ada aplikasi email di HP ini'),
        findsOneWidget,
      );
      await tester.ensureVisible(find.text('Salin pesan'));
      await tester.tap(find.text('Salin pesan'));
      await tester.pumpAndSettle();
      expect(u.tersalin, [_goldenAlat()]);
      expect(find.text('Pesan disalin.'), findsOneWidget);
      expect(
        find.textContaining('Tidak ada aplikasi email'),
        findsNothing,
        reason: 'konfirmasi menggantikan galat',
      );
    });

    testWidgets('Batal menutup lembar tanpa membuka apa pun', (tester) async {
      final u = _Uji();
      await u.buka(tester, const AlatDetailScreen(id: 1));
      await tester.tap(find.text('Minta kalibrasi ulang'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Batal'));
      await tester.tap(find.text('Batal'));
      await tester.pumpAndSettle();
      expect(find.byType(LembarTanyaAdmin), findsNothing);
      expect(u.dibuka, isEmpty);
    });

    testWidgets('data aneh di nama alat (baris baru, &, #, emoji, header '
        'palsu) tidak menyelipkan baris, parameter, atau fragmen', (
      tester,
    ) async {
      final u = _Uji(
        alat: [
          alatJson(
            1,
            'Oven & Tungku #1 😀\nBcc: jahat@contoh.test',
            hari: 20,
            serial: 'SN&text=JAHAT#x%41',
          ),
        ],
      );
      await u.buka(tester, const AlatDetailScreen(id: 1));
      await tester.tap(find.text('Minta kalibrasi ulang'));
      await tester.pumpAndSettle();
      final pesan = _pratinjau(tester);
      expect(pesan.split('\n').any((b) => b.startsWith('Bcc:')), isFalse);
      await tester.tap(find.text('Buka WhatsApp'));
      await tester.pumpAndSettle();
      final uri = u.dibuka.single;
      expect(uri.queryParameters.keys, ['text']);
      expect(uri.queryParameters['text'], pesan, reason: 'bulat-balik');
      expect(uri.fragment, isEmpty);
      expect(uri.toString().contains('JAHAT&'), isFalse);
      expect(uri.toString().contains('&'), isFalse);
    });

    testWidgets('baca-saja: tidak ada permintaan tulis ke server', (
      tester,
    ) async {
      final u = _Uji();
      await u.buka(tester, const AlatDetailScreen(id: 1));
      await tester.tap(find.text('Minta kalibrasi ulang'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Buka WhatsApp'));
      await tester.pumpAndSettle();
      expect(u.server.permintaan, isNotEmpty);
      expect(
        u.server.permintaan.every((r) => r.method == 'GET'),
        isTrue,
        reason: 'hanya GET: tanya admin hanya membuka aplikasi luar',
      );
    });
  });

  group('detail sertifikat: Tanya tentang sertifikat ini / Laporkan data '
      'yang keliru', () {
    String golden(String kalimat, String penutup, String status) => [
      'Halo admin PT SIDIK,',
      '',
      'Kami dari PT Alfa $kalimat',
      '- Nomor sertifikat: CAL/2026/11/0012',
      '- Alat: Oven Memmert',
      '- Nomor seri: SN-1',
      '- Status: $status',
      '',
      penutup,
    ].join('\n');

    testWidgets('tanya: pesan emas, status dari dokumen', (tester) async {
      final u = _Uji();
      await u.buka(tester, const SertifikatDetailScreen(id: 12));
      final tombol = find.text('Tanya tentang sertifikat ini');
      await tester.ensureVisible(tombol);
      await tester.tap(tombol);
      await tester.pumpAndSettle();
      expect(
        _pratinjau(tester),
        golden(
          'ingin bertanya tentang sertifikat berikut:',
          'Pertanyaan kami:',
          statusDokumen(StatusDokumen.berlaku).label,
        ),
      );
      await tester.tap(find.text('Buka WhatsApp'));
      await tester.pumpAndSettle();
      expect(
        u.dibuka.single.queryParameters['text'],
        contains('CAL/2026/11/0012'),
      );
    });

    testWidgets('laporkan: pesan emas', (tester) async {
      final u = _Uji();
      await u.buka(tester, const SertifikatDetailScreen(id: 12));
      final tombol = find.text('Laporkan data yang keliru');
      await tester.ensureVisible(tombol);
      await tester.tap(tombol);
      await tester.pumpAndSettle();
      expect(
        _pratinjau(tester),
        golden(
          'menemukan data yang tampaknya keliru pada sertifikat berikut:',
          'Data yang keliru dan seharusnya:',
          statusDokumen(StatusDokumen.berlaku).label,
        ),
      );
    });

    testWidgets('dua tombol tidak ada bila tidak ada kanal', (tester) async {
      final u = _Uji(info: _info(whatsappUrl: null, email: null));
      await u.buka(tester, const SertifikatDetailScreen(id: 12));
      expect(find.text('Tanya tentang sertifikat ini'), findsNothing);
      expect(find.text('Laporkan data yang keliru'), findsNothing);
      expect(find.text('Lihat PDF'), findsOneWidget);
    });

    testWidgets('sertifikat dibatalkan: status "Dibatalkan" ikut di pesan', (
      tester,
    ) async {
      final u = _Uji(
        sertifikat: [
          sertifikatJson(
            12,
            'CAL/2026/11/0012',
            namaAlat: 'Oven Memmert',
            status: 'dibatalkan',
            dibatalkanPada: -2,
          ),
        ],
      );
      await u.buka(tester, const SertifikatDetailScreen(id: 12));
      final tombol = find.text('Laporkan data yang keliru');
      await tester.ensureVisible(tombol);
      await tester.tap(tombol);
      await tester.pumpAndSettle();
      expect(
        _pratinjau(tester),
        contains('- Status: ${statusDokumen(StatusDokumen.dibatalkan).label}'),
      );
    });
  });
}
