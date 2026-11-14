// Layar Pengaturan notifikasi: semua keadaan (memuat, galat, kosong, baca-saja,
// data dari simpanan HP, menyimpan, gagal), semantik saklar, 320 dp x huruf 1,3,
// tablet, terang dan gelap.
import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import 'package:sidik_pelanggan/core/tema/tema_sidik.dart';
import 'package:sidik_pelanggan/providers/koneksi_provider.dart';
import 'package:sidik_pelanggan/providers/sesi_provider.dart';
import 'package:sidik_pelanggan/screens/akun/preferensi_notifikasi_screen.dart';
import 'package:sidik_pelanggan/services/layanan_pelanggan.dart';
import 'package:sidik_pelanggan/widgets/keadaan_teks.dart';
import 'package:sidik_pelanggan/widgets/kerangka.dart';
import 'package:sidik_pelanggan/widgets/panel_pemberitahuan.dart';
import 'package:sidik_pelanggan/widgets/stempel.dart';

import 'dukungan/font_ikon.dart';
import 'dukungan/dukungan.dart';
import 'dukungan/fixture_fitur.dart';
import 'dukungan/layanan_preferensi_palsu.dart';
import 'dukungan/layar_uji.dart';
import 'dukungan/ukur_komponen.dart';

final _kunciPotret = GlobalKey();

Widget _app(
  LayananPelanggan palsu, {
  Sesi? sesi,
  bool gelap = false,
  double skala = 1.0,
  Widget? isi,
  List<Override> tambahan = const [],
}) => ProviderScope(
  overrides: overrideDasar(
    tambahan: [
      layananProvider.overrideWithValue(palsu),
      sesiTetap(sesi ?? sesiDuaPerusahaan()),
      ...tambahan,
    ],
  ),
  child: MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: TemaSidik.terang,
    darkTheme: TemaSidik.gelap,
    themeMode: gelap ? ThemeMode.dark : ThemeMode.light,
    builder: (context, child) => RepaintBoundary(
      key: _kunciPotret,
      child: MediaQuery.withClampedTextScaling(
        minScaleFactor: skala,
        maxScaleFactor: skala,
        child: child!,
      ),
    ),
    home: isi ?? const PreferensiNotifikasiScreen(),
  ),
);

Finder _baris(String kunci) => find.byKey(ValueKey('saklar-$kunci'));

Finder _saklar(String kunci) =>
    find.descendant(of: _baris(kunci), matching: find.byType(Switch));

bool _hidup(WidgetTester t, String kunci) =>
    t.widget<Switch>(_saklar(kunci)).value;

Future<void> _buka(
  WidgetTester t,
  LayananPelanggan palsu, {
  double lebar = 392,
  double tinggi = 1400,
  Sesi? sesi,
  bool gelap = false,
  double skala = 1.0,
}) async {
  layarHp(t, lebar: lebar, tinggi: tinggi);
  await t.pumpWidget(_app(palsu, sesi: sesi, gelap: gelap, skala: skala));
  await t.pumpAndSettle();
}

ProviderContainer _wadah(WidgetTester t) => ProviderScope.containerOf(
  t.element(find.byType(PreferensiNotifikasiScreen)),
);

const _kunci4 = [
  'pengingat_jadwal',
  'status_permintaan',
  'tahap_alat',
  'ringkasan_email_mingguan',
];

void main() {
  setUpAll(siapkanTesFitur);

  group('isi', () {
    testWidgets('empat saklar dengan nama dan satu kalimat; pesan_lab tidak', (
      t,
    ) async {
      await _buka(t, LayananPreferensiPalsu());

      expect(find.byType(Switch), findsNWidgets(4));
      for (final k in _kunci4) {
        expect(_baris(k), findsOneWidget, reason: k);
      }
      expect(_baris('pesan_lab'), findsNothing);

      expect(find.text('Pengingat jadwal kalibrasi'), findsOneWidget);
      expect(find.text('Sertifikat terbit'), findsOneWidget);
      expect(find.text('Perubahan tahap alat'), findsOneWidget);
      expect(find.text('Ringkasan mingguan lewat email'), findsOneWidget);
      expect(
        find.textContaining('siap diambil atau sudah diserahkan'),
        findsOneWidget,
      );
      // Nilai bawaan kontrak: tiga menyala, ringkasan email mati.
      expect(_hidup(t, 'pengingat_jadwal'), isTrue);
      expect(_hidup(t, 'status_permintaan'), isTrue);
      expect(_hidup(t, 'tahap_alat'), isTrue);
      expect(_hidup(t, 'ringkasan_email_mingguan'), isFalse);
      // Keadaan juga tertulis sebagai kata, tidak hanya posisi saklar.
      expect(find.text('Aktif'), findsNWidgets(3));
      expect(find.text('Nonaktif'), findsOneWidget);
      // Dan sebagai ikon di bulatan saklar: centang saat aktif, silang saat mati.
      // Bulatan saklar digambar oleh painter, bukan widget: periksa lewat
      // `thumbIcon` milik tiap Switch.
      for (final k in _kunci4) {
        final aktif = _hidup(t, k);
        final ikon = t.widget<Switch>(_saklar(k)).thumbIcon?.resolve({
          if (aktif) WidgetState.selected,
        });
        expect(ikon?.icon, aktif ? Icons.check : Icons.close, reason: k);
      }
      // Saklar di ujung kanan baris, bukan di bawah teks, pada HP biasa.
      for (final k in _kunci4) {
        expect(
          t.getCenter(_saklar(k)).dx,
          greaterThan(t.getCenter(_baris(k)).dx),
          reason: k,
        );
      }
    });

    testWidgets('dua kelompok: kabar di HP dan lewat email', (t) async {
      await _buka(t, LayananPreferensiPalsu());
      expect(find.text('Kabar di HP dan di aplikasi'), findsOneWidget);
      expect(find.text('Lewat email'), findsOneWidget);
    });

    testWidgets('nama PT tampil bila akun punya lebih dari satu perusahaan', (
      t,
    ) async {
      await _buka(t, LayananPreferensiPalsu(), sesi: sesiDuaPerusahaan());
      expect(
        find.textContaining('Pengaturan ini khusus untuk PT Alfa.'),
        findsOneWidget,
      );
    });

    testWidgets('nama PT tidak tampil bila akun hanya punya satu perusahaan', (
      t,
    ) async {
      await _buka(t, LayananPreferensiPalsu(), sesi: sesiUji());
      expect(find.textContaining('khusus untuk'), findsNothing);
      expect(find.textContaining('PT Contoh Pelanggan'), findsNothing);
    });

    testWidgets('tidak ada "matikan semua": hanya empat saklar, tanpa tombol', (
      t,
    ) async {
      await _buka(t, LayananPreferensiPalsu());
      expect(find.byType(Switch), findsNWidgets(4));
      expect(find.byType(FilledButton), findsNothing);
      expect(find.byType(OutlinedButton), findsNothing);
      expect(
        find.textContaining(RegExp('semua', caseSensitive: false)),
        findsNothing,
      );
    });

    testWidgets('kategori tak dikenal dari server tidak digambar', (t) async {
      final palsu = LayananPreferensiPalsu()
        ..jawabanMuat = {
          ...LayananPreferensiPalsu.kunciKontrak,
          'kategori_masa_depan': true,
        };
      await _buka(t, palsu);
      expect(find.byType(Switch), findsNWidgets(4));
      expect(find.textContaining('masa_depan'), findsNothing);
      expect(t.takeException(), isNull);
    });

    testWidgets('server lama tanpa tahap_alat: tiga saklar, tidak jatuh', (
      t,
    ) async {
      final palsu = LayananPreferensiPalsu()
        ..jawabanMuat = {
          'pengingat_jadwal': true,
          'status_permintaan': true,
          'pesan_lab': true,
          'ringkasan_email_mingguan': false,
        };
      await _buka(t, palsu);
      expect(find.byType(Switch), findsNWidgets(3));
      expect(_baris('tahap_alat'), findsNothing);
    });

    testWidgets('catatan kaki: revisi/pembatalan selalu dikirim', (t) async {
      await _buka(t, LayananPreferensiPalsu());
      expect(
        find.textContaining('revisi atau pembatalan sertifikat selalu dikirim'),
        findsOneWidget,
      );
    });
  });

  group('memuat dan galat', () {
    testWidgets('memuat: kerangka, lalu isi', (t) async {
      final palsu = LayananPreferensiPalsu()..bukaMuat = Completer<void>();
      layarHp(t, tinggi: 1400);
      await t.pumpWidget(_app(palsu));
      await t.pump();
      expect(find.byType(Memuat), findsOneWidget);
      expect(find.byType(Switch), findsNothing);

      palsu.bukaMuat!.complete();
      await t.pumpAndSettle();
      expect(find.byType(Memuat), findsNothing);
      expect(find.byType(Switch), findsNWidgets(4));
    });

    testWidgets('tanpa sambungan: judul, langkah berikut, dan Coba lagi', (
      t,
    ) async {
      final palsu = LayananPreferensiPalsu()..galatMuat = galatJaringan();
      await _buka(t, palsu);

      expect(find.byType(KeadaanTeks), findsOneWidget);
      expect(find.text('Tidak ada sambungan'), findsOneWidget);
      expect(find.textContaining('Periksa koneksi internet'), findsOneWidget);
      expect(find.byType(Switch), findsNothing);

      final sebelum = palsu.muat;
      palsu.galatMuat = null;
      await t.tap(find.text('Coba lagi'));
      await t.pumpAndSettle();
      expect(palsu.muat, sebelum + 1, reason: 'Coba lagi memuat ulang');
      expect(find.byType(Switch), findsNWidgets(4));
    });

    testWidgets(
      '403 saat memuat: tidak ada izin, bukan "tidak ada sambungan"',
      (t) async {
        final palsu = LayananPreferensiPalsu()..galatMuat = galatHttp(403);
        await _buka(t, palsu);
        expect(find.text('Pengaturan ini belum bisa dibuka'), findsOneWidget);
        expect(find.textContaining('Hubungi PT Sidik'), findsOneWidget);
        expect(
          find.textContaining('PIC'),
          findsNothing,
          reason: 'PIC tidak bisa memperbaiki 403',
        );
        expect(find.text('Tidak ada sambungan'), findsNothing);
      },
    );

    testWidgets('galat server memuat: pesan server ditampilkan', (t) async {
      final palsu = LayananPreferensiPalsu()
        ..galatMuat = galatHttp(500, 'Terjadi kendala di server. (kode 500)');
      await _buka(t, palsu);
      expect(find.text('Pengaturan belum bisa dimuat'), findsOneWidget);
      expect(find.textContaining('kendala di server'), findsOneWidget);
    });

    testWidgets(
      'server tanpa saklar yang dikenal: keadaan kosong + Muat ulang',
      (t) async {
        final palsu = LayananPreferensiPalsu()..jawabanMuat = {};
        await _buka(t, palsu);
        expect(find.text('Belum ada pengaturan'), findsOneWidget);
        expect(find.byType(Switch), findsNothing);

        palsu.jawabanMuat = null;
        await t.tap(find.text('Muat ulang'));
        await t.pumpAndSettle();
        expect(find.byType(Switch), findsNWidgets(4));
      },
    );
  });

  group('menyimpan', () {
    testWidgets('ketuk: berubah dulu, "Menyimpan…", lalu tenang', (t) async {
      final palsu = LayananPreferensiPalsu()..tahan = true;
      await _buka(t, palsu);

      await t.tap(_saklar('tahap_alat'));
      await t.pump();
      expect(_hidup(t, 'tahap_alat'), isFalse);
      expect(find.text('Menyimpan…'), findsOneWidget);
      expect(palsu.badan, [
        {'tahap_alat': false},
      ]);

      palsu.selesaikan(0);
      await t.pumpAndSettle();
      expect(find.text('Menyimpan…'), findsNothing);
      expect(_hidup(t, 'tahap_alat'), isFalse);
      expect(find.text('Nonaktif'), findsNWidgets(2));
    });

    testWidgets('seluruh baris adalah sasaran ketuk, bukan hanya saklarnya', (
      t,
    ) async {
      final palsu = LayananPreferensiPalsu();
      await _buka(t, palsu);

      await t.tap(find.text('Pengingat jadwal kalibrasi'));
      await t.pumpAndSettle();
      expect(palsu.badan, [
        {'pengingat_jadwal': false},
      ]);
      expect(_hidup(t, 'pengingat_jadwal'), isFalse);

      await t.tap(find.text('Nonaktif').first);
      await t.pumpAndSettle();
      expect(palsu.panggilan, hasLength(2));
    });

    testWidgets('gagal: saklar kembali, alasan di baris itu saja, rinci', (
      t,
    ) async {
      final palsu = LayananPreferensiPalsu()..rencanaGalat.add(galatJaringan());
      await _buka(t, palsu);

      await t.tap(_saklar('tahap_alat'));
      await t.pumpAndSettle();

      expect(_hidup(t, 'tahap_alat'), isTrue, reason: 'dikembalikan');
      final gagal = find.descendant(
        of: _baris('tahap_alat'),
        matching: find.textContaining('Belum tersimpan.'),
      );
      expect(gagal, findsOneWidget);
      expect(
        find.descendant(
          of: _baris('tahap_alat'),
          matching: find.byIcon(Icons.error_outline),
        ),
        findsOneWidget,
        reason: 'galat = ikon + kata, tidak hanya warna',
      );
      // Baris lain bersih.
      for (final k in _kunci4.where((k) => k != 'tahap_alat')) {
        expect(
          find.descendant(
            of: _baris(k),
            matching: find.textContaining('Belum tersimpan'),
          ),
          findsNothing,
          reason: k,
        );
      }
      expect(find.text('Menyimpan…'), findsNothing);

      // Ketuk lagi = coba lagi; berhasil menghapus alasan.
      await t.tap(_saklar('tahap_alat'));
      await t.pumpAndSettle();
      expect(_hidup(t, 'tahap_alat'), isFalse);
      expect(find.textContaining('Belum tersimpan'), findsNothing);
      expect(palsu.panggilan, hasLength(2));
    });

    testWidgets('gagal tidak menghapus pilihan lain yang sudah tersimpan', (
      t,
    ) async {
      final palsu = LayananPreferensiPalsu()
        ..rencanaGalat.addAll([null, galatHttp(429)]);
      await _buka(t, palsu);

      await t.tap(_saklar('pengingat_jadwal'));
      await t.pumpAndSettle();
      await t.tap(_saklar('ringkasan_email_mingguan'));
      await t.pumpAndSettle();

      expect(_hidup(t, 'pengingat_jadwal'), isFalse, reason: 'tetap tersimpan');
      expect(_hidup(t, 'ringkasan_email_mingguan'), isFalse);
      expect(find.textContaining('Terlalu sering mengubah'), findsOneWidget);
    });

    testWidgets('dua ketukan cepat pada dua saklar, jawaban bersilang', (
      t,
    ) async {
      final palsu = LayananPreferensiPalsu()..tahan = true;
      await _buka(t, palsu);

      await t.tap(_saklar('pengingat_jadwal'));
      await t.tap(_saklar('ringkasan_email_mingguan'));
      await t.pump();
      expect(palsu.panggilan, hasLength(2));

      palsu.selesaikan(0);
      await t.pump();
      expect(_hidup(t, 'ringkasan_email_mingguan'), isTrue, reason: 'menunggu');
      palsu.selesaikan(1);
      await t.pumpAndSettle();

      expect(_hidup(t, 'pengingat_jadwal'), isFalse);
      expect(_hidup(t, 'ringkasan_email_mingguan'), isTrue);
      expect(find.text('Menyimpan…'), findsNothing);
    });

    testWidgets('dua ketukan cepat pada saklar yang sama: satu PUT berjalan', (
      t,
    ) async {
      final palsu = LayananPreferensiPalsu()..tahan = true;
      await _buka(t, palsu);

      await t.tap(_saklar('tahap_alat'));
      await t.pump(); // satu frame: saklar sudah menggambar nilai barunya
      await t.tap(_saklar('tahap_alat'));
      await t.pump();
      expect(palsu.panggilan, hasLength(1));
      expect(_hidup(t, 'tahap_alat'), isTrue, reason: 'ketukan kedua membalik');

      palsu.selesaikan(0);
      await t.pumpAndSettle();
      expect(palsu.panggilan, hasLength(2), reason: 'nilai terbaru menyusul');
      palsu.selesaikan(1);
      await t.pumpAndSettle();
      expect(_hidup(t, 'tahap_alat'), isTrue);
      expect(palsu.server['tahap_alat'], isTrue);
    });

    testWidgets('layar ditutup selagi menyimpan: tanpa galat', (t) async {
      final palsu = LayananPreferensiPalsu()..tahan = true;
      final tampil = ValueNotifier(true);
      layarHp(t, tinggi: 1400);
      await t.pumpWidget(
        _app(
          palsu,
          isi: ValueListenableBuilder<bool>(
            valueListenable: tampil,
            builder: (_, v, _) =>
                v ? const PreferensiNotifikasiScreen() : const SizedBox(),
          ),
        ),
      );
      await t.pumpAndSettle();

      await t.tap(_saklar('tahap_alat'));
      await t.pump();
      tampil.value = false;
      await t.pumpAndSettle();
      palsu.selesaikan(0);
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
      expect(palsu.server['tahap_alat'], isFalse);
    });
  });

  group('baca-saja', () {
    testWidgets('server menjawab 403 saat menyimpan: alasan dan saklar mati', (
      t,
    ) async {
      final palsu = LayananPreferensiPalsu()
        ..rencanaGalat.add(galatHttp(403, 'Akun ini belum boleh.'));
      await _buka(t, palsu);

      await t.tap(_saklar('tahap_alat'));
      await t.pumpAndSettle();

      expect(find.byType(PanelPemberitahuan), findsOneWidget);
      expect(find.text('Hanya bisa dibaca'), findsOneWidget);
      expect(find.textContaining('belum bisa mengubah'), findsOneWidget);
      expect(find.textContaining('Hubungi PT Sidik'), findsOneWidget);
      expect(find.textContaining('PIC'), findsNothing);
      expect(find.byIcon(Icons.lock_outline), findsOneWidget);
      // Nilai dikembalikan: "tahap_alat" tetap Aktif.
      expect(
        find.descendant(of: _baris('tahap_alat'), matching: find.text('Aktif')),
        findsOneWidget,
        reason: 'nilai dikembalikan',
      );
      // Bukan saklar disabled (nyaris tak terlihat): penanda statis ikon + kata.
      expect(find.byType(Switch), findsNothing);
      expect(find.byType(Stempel), findsNWidgets(4));

      await t.tap(find.text('Pengingat jadwal kalibrasi'));
      await t.pumpAndSettle();
      expect(palsu.panggilan, hasLength(1), reason: 'tidak ada PUT lagi');
      // Nilai tetap terbaca sebagai kata.
      expect(find.text('Aktif'), findsNWidgets(3));
    });

    testWidgets('semantik baca-saja: tidak aktif, nilainya tetap terbaca', (
      t,
    ) async {
      final semantik = t.ensureSemantics();
      final palsu = LayananPreferensiPalsu()..rencanaGalat.add(galatHttp(403));
      await _buka(t, palsu);
      await t.tap(_saklar('tahap_alat'));
      await t.pumpAndSettle();

      final node = t.getSemantics(_baris('tahap_alat'));
      expect(
        node,
        matchesSemantics(
          label:
              'Perubahan tahap alat. Kabar saat satu alat Anda siap diambil '
              'atau sudah diserahkan, dan tahap lain yang dikabarkan lab. '
              'Setiap alat dikabari sendiri-sendiri.',
          hasToggledState: true,
          isToggled: true,
          hasEnabledState: true,
          isEnabled: false,
        ),
      );
      semantik.dispose();
    });
  });

  group('data dari simpanan HP', () {
    testWidgets('banner waktu, saklar mati, Muat ulang membukanya lagi', (
      t,
    ) async {
      final palsu = LayananPreferensiPalsu();
      layarHp(t, tinggi: 1400);
      await t.pumpWidget(
        _app(
          palsu,
          tambahan: [koneksiProvider.overrideWith(() => _KoneksiOffline())],
        ),
      );
      await t.pumpAndSettle();

      expect(find.textContaining('Tidak ada sambungan.'), findsOneWidget);
      expect(find.textContaining('13 Nov, 08.30'), findsOneWidget);
      expect(
        find.textContaining('bisa berbeda dari yang tersimpan'),
        findsOneWidget,
      );
      expect(find.byType(Switch), findsNothing, reason: 'data lama: baca-saja');
      expect(find.byType(Stempel), findsNWidgets(4));
      await t.tap(find.text('Pengingat jadwal kalibrasi'));
      await t.pumpAndSettle();
      expect(palsu.panggilan, isEmpty);

      palsu.saatMuat = () => _wadah(t).read(koneksiProvider.notifier).online();
      await t.tap(find.text('Muat ulang'));
      await t.pumpAndSettle();
      expect(find.textContaining('Tidak ada sambungan.'), findsNothing);
      for (final k in _kunci4) {
        expect(t.widget<Switch>(_saklar(k)).onChanged, isNotNull, reason: k);
      }
    });
  });

  group(
    'kontras keadaan baca-saja (penanda statis, bukan saklar disabled)',
    () {
      for (final gelap in [false, true]) {
        for (final sumber in ['403 saat menyimpan', 'data dari simpanan HP']) {
          testWidgets(
            '$sumber, ${gelap ? 'gelap' : 'terang'}: kata >= 4,5:1 dan '
            'ikon >= 3:1',
            (t) async {
              if (sumber.startsWith('403')) {
                final palsu = LayananPreferensiPalsu()
                  ..rencanaGalat.add(galatHttp(403));
                await _buka(t, palsu, gelap: gelap);
                await t.tap(_saklar('tahap_alat'));
                await t.pumpAndSettle();
              } else {
                layarHp(t, tinggi: 1400);
                await t.pumpWidget(
                  _app(
                    LayananPreferensiPalsu(),
                    gelap: gelap,
                    tambahan: [
                      koneksiProvider.overrideWith(_KoneksiOffline.new),
                    ],
                  ),
                );
                await t.pumpAndSettle();
              }

              // Empat penanda statis menggantikan empat saklar.
              expect(find.byType(Switch), findsNothing);
              expect(find.byType(Stempel), findsNWidgets(4));

              // Glyph ikon ikut terbaca sebagai teks; saring hanya katanya.
              final kata = ukurTeks(t, find.byType(Stempel))
                  .where((x) => x.teks == 'Aktif' || x.teks == 'Nonaktif')
                  .toList();
              expect(kata.map((x) => x.teks).toSet(), {'Aktif', 'Nonaktif'});
              expect(kata, hasLength(4));
              for (final x in kata) {
                expect(
                  x.rasio,
                  greaterThanOrEqualTo(4.5),
                  reason: '"${x.teks}" ${x.rasio.toStringAsFixed(2)}:1',
                );
              }
              final ikon = t.widgetList<Icon>(
                find.descendant(
                  of: find.byType(Stempel),
                  matching: find.byType(Icon),
                ),
              );
              expect(ikon, hasLength(4));
              for (final i in ikon) {
                final rasio = rasioKontras(
                  i.color!,
                  latarEfektif(t.element(find.byWidget(i))),
                );
                expect(
                  rasio,
                  greaterThanOrEqualTo(3),
                  reason: 'ikon ${i.icon} ${rasio.toStringAsFixed(2)}:1',
                );
              }
              final semua = pelanggaranKontrasTeks(
                t,
                find.byType(PreferensiNotifikasiScreen),
              );
              expect(semua, isEmpty, reason: semua.join('\n'));
            },
          );
        }
      }
    },
  );

  group('semantik', () {
    testWidgets('satu simpul per saklar: nama, keadaan, dan aksi ketuk', (
      t,
    ) async {
      final semantik = t.ensureSemantics();
      await _buka(t, LayananPreferensiPalsu());

      expect(
        t.getSemantics(find.bySemanticsLabel(RegExp('^Pengingat jadwal'))),
        matchesSemantics(
          label:
              'Pengingat jadwal kalibrasi. Kabar saat alat mendekati atau '
              'melewati jadwal kalibrasi ulang.',
          hasToggledState: true,
          isToggled: true,
          hasEnabledState: true,
          isEnabled: true,
          hasTapAction: true,
        ),
      );
      expect(
        t.getSemantics(find.bySemanticsLabel(RegExp('^Ringkasan mingguan'))),
        matchesSemantics(
          label:
              'Ringkasan mingguan lewat email. Email tiap Senin pagi berisi '
              'alat yang mendekati jadwal dan sertifikat terbaru. Tidak '
              'dikirim pada minggu tanpa isi.',
          hasToggledState: true,
          isToggled: false,
          hasEnabledState: true,
          isEnabled: true,
          hasTapAction: true,
        ),
      );
      // Tepat empat simpul bersaklar: saklar Material di dalamnya tidak
      // disuarakan lagi.
      final bersaklar = find.semantics.byPredicate(
        (n) =>
            n.getSemanticsData().flagsCollection.isToggled != ui.Tristate.none,
      );
      expect(bersaklar.evaluate().length, 4);
      semantik.dispose();
    });

    testWidgets('pembaca layar mengaktifkan saklar lewat semantik', (t) async {
      final semantik = t.ensureSemantics();
      final palsu = LayananPreferensiPalsu();
      await _buka(t, palsu);

      t.semantics.tap(find.semantics.byLabel(RegExp('^Perubahan tahap alat')));
      await t.pumpAndSettle();
      expect(palsu.badan, [
        {'tahap_alat': false},
      ]);
      expect(_hidup(t, 'tahap_alat'), isFalse);
      expect(
        t.getSemantics(find.bySemanticsLabel(RegExp('^Perubahan tahap alat'))),
        matchesSemantics(
          label: t.getSemantics(_baris('tahap_alat')).label,
          hasToggledState: true,
          isToggled: false,
          hasEnabledState: true,
          isEnabled: true,
          hasTapAction: true,
        ),
      );
      semantik.dispose();
    });

    testWidgets('menyimpan dan gagal tertulis di label; gagal diumumkan', (
      t,
    ) async {
      final semantik = t.ensureSemantics();
      final palsu = LayananPreferensiPalsu()
        ..tahan = true
        ..rencanaGalat.add(galatJaringan());
      await _buka(t, palsu);

      await t.tap(_saklar('tahap_alat'));
      await t.pump();
      expect(
        t.getSemantics(_baris('tahap_alat')).label,
        endsWith(' Menyimpan.'),
      );

      palsu.selesaikan(0);
      await t.pumpAndSettle();
      final node = t.getSemantics(_baris('tahap_alat'));
      expect(node.label, contains('Belum tersimpan. Tidak ada sambungan.'));
      expect(
        node,
        matchesSemantics(
          label: node.label,
          hasToggledState: true,
          isToggled: true,
          hasEnabledState: true,
          isEnabled: true,
          hasTapAction: true,
          isLiveRegion: true,
        ),
      );
      semantik.dispose();
    });

    for (final (nama, lebar, skala) in [
      ('HP 392', 392.0, 1.0),
      ('HP sempit 320 x 1,3', 320.0, 1.3),
    ]) {
      testWidgets('sasaran sentuh >= 48 dp dan berlabel: $nama', (t) async {
        final semantik = t.ensureSemantics();
        await _buka(
          t,
          LayananPreferensiPalsu(),
          lebar: lebar,
          tinggi: 3000,
          skala: skala,
        );
        await periksaPedomanSentuh(t);
        for (final k in _kunci4) {
          expect(
            t.getSize(_baris(k)).height,
            greaterThanOrEqualTo(72),
            reason: '$k: baris min 72 dp',
          );
        }
        semantik.dispose();
      });
    }
  });

  group('ukuran dan tema', () {
    for (final (nama, lebar, tinggi, skala) in [
      ('HP 392 x 852', 392.0, 852.0, 1.0),
      ('HP sempit 320 x 640, huruf 1,3', 320.0, 640.0, 1.3),
      ('HP sempit 320 x 640, huruf 2,0', 320.0, 640.0, 2.0),
      ('tablet 840 x 1200', 840.0, 1200.0, 1.0),
    ]) {
      for (final gelap in [false, true]) {
        testWidgets('tanpa luapan sampai ujung bawah: $nama '
            '${gelap ? 'gelap' : 'terang'}', (t) async {
          final palsu = LayananPreferensiPalsu()
            ..rencanaGalat.add(galatJaringan());
          await _buka(
            t,
            palsu,
            lebar: lebar,
            tinggi: tinggi,
            gelap: gelap,
            skala: skala,
          );
          // Keadaan terpanjang: satu saklar gagal dengan kalimat alasan.
          await t.tap(_saklar('pengingat_jadwal'), warnIfMissed: false);
          await t.pumpAndSettle();
          await t.drag(find.byType(Scrollable).first, const Offset(0, -4000));
          await t.pumpAndSettle();
          expect(t.takeException(), isNull);
        });
      }
    }

    testWidgets('tablet: isi dibatasi 720 dp dan dipusatkan', (t) async {
      await _buka(t, LayananPreferensiPalsu(), lebar: 840, tinggi: 1200);
      final kiri = t.getTopLeft(_baris('tahap_alat')).dx;
      final kanan = t.getTopRight(_baris('tahap_alat')).dx;
      expect(kanan - kiri, lessThanOrEqualTo(720));
      expect(kiri, greaterThan(0));
    });

    for (final gelap in [false, true]) {
      testWidgets('kontras teks >= 4,5:1 (${gelap ? 'gelap' : 'terang'}), '
          'termasuk alasan gagal', (t) async {
        final palsu = LayananPreferensiPalsu()
          ..rencanaGalat.add(galatHttp(500, 'Terjadi kendala di server.'));
        await _buka(t, palsu, gelap: gelap);
        await t.tap(_saklar('tahap_alat'));
        await t.pumpAndSettle();
        expect(find.textContaining('Belum tersimpan.'), findsOneWidget);

        final pelanggaran = pelanggaranKontrasTeks(
          t,
          find.byType(PreferensiNotifikasiScreen),
        );
        expect(pelanggaran, isEmpty, reason: pelanggaran.join('\n'));
      });
    }

    for (final gelap in [false, true]) {
      testWidgets('kontras saklar >= 3:1 terhadap permukaan baris '
          '(${gelap ? 'gelap' : 'terang'})', (t) async {
        await _buka(t, LayananPreferensiPalsu(), gelap: gelap);
        final s = Theme.of(t.element(find.byType(Switch).first)).colorScheme;
        // Default Material 3 untuk saklar: aktif = lintasan `primary` dengan
        // bulatan `onPrimary`; nonaktif = tepi dan bulatan `outline`.
        expect(rasioKontras(s.primary, s.surface), greaterThanOrEqualTo(3));
        expect(rasioKontras(s.onPrimary, s.primary), greaterThanOrEqualTo(3));
        expect(rasioKontras(s.outline, s.surface), greaterThanOrEqualTo(3));
        // Bulatan nonaktif terhadap lintasannya, dan ikon centang/silang
        // terhadap bulatannya (aktif: onPrimaryContainer di onPrimary;
        // nonaktif: lintasan di bulatan `outline`).
        expect(
          rasioKontras(s.outline, s.surfaceContainerHighest),
          greaterThanOrEqualTo(3),
        );
        expect(
          rasioKontras(s.onPrimaryContainer, s.onPrimary),
          greaterThanOrEqualTo(3),
        );
      });
    }
  });

  // Potret keadaan yang tak bisa dibuat harness `render_layar_test.dart`
  // (menyimpan, data dari simpanan HP). Hanya bila `SIDIK_PNG_DIR` diisi.
  final folder = Platform.environment['SIDIK_PNG_DIR'];
  if (folder != null) {
    group('potret ke PNG', () {
      setUpAll(muatFontIkonMaterial);

      Future<void> potret(WidgetTester t, String nama) async {
        final batas = t.renderObject<RenderRepaintBoundary>(
          find.byKey(_kunciPotret),
        );
        await t.runAsync(() async {
          final gambar = await batas.toImage(pixelRatio: 2.0);
          final data = await gambar.toByteData(format: ui.ImageByteFormat.png);
          Directory(folder).createSync(recursive: true);
          File(
            '$folder/$nama.png',
          ).writeAsBytesSync(data!.buffer.asUint8List());
        });
      }

      for (final (ukuran, lebar, tinggi, skala) in [
        ('hp392', 392.0, 852.0, 1.0),
        ('sempit', 320.0, 640.0, 1.3),
      ]) {
        for (final gelap in [false, true]) {
          final tema = gelap ? 'gelap' : 'terang';
          testWidgets('menyimpan $ukuran $tema', (t) async {
            final palsu = LayananPreferensiPalsu()..tahan = true;
            await _buka(
              t,
              palsu,
              lebar: lebar,
              tinggi: tinggi,
              gelap: gelap,
              skala: skala,
            );
            await t.ensureVisible(_saklar('tahap_alat'));
            await t.pumpAndSettle();
            await t.tap(_saklar('tahap_alat'));
            await t.pump();
            // Jawaban ditahan tidak menjadwalkan frame, jadi animasi saklar
            // selesai dan potret memperlihatkan keadaan akhirnya.
            await t.pumpAndSettle();
            expect(find.text('Menyimpan…'), findsOneWidget);
            await potret(t, 'preferensi_menyimpan_${ukuran}_$tema');
            palsu.selesaikan(0);
            await t.pumpAndSettle();
          });

          testWidgets('data dari simpanan HP $ukuran $tema', (t) async {
            layarHp(t, lebar: lebar, tinggi: tinggi);
            await t.pumpWidget(
              _app(
                LayananPreferensiPalsu(),
                gelap: gelap,
                skala: skala,
                tambahan: [koneksiProvider.overrideWith(_KoneksiOffline.new)],
              ),
            );
            await t.pumpAndSettle();
            await potret(t, 'preferensi_offline_${ukuran}_$tema');
          });
        }
      }
    });
  }
}

/// Penanda offline dengan data simpanan HP sejak 13 Nov 2026 08.30.
class _KoneksiOffline extends KoneksiController {
  @override
  KeadaanKoneksi build() => KeadaanKoneksi(
    offline: true,
    dataTerakhir: DateTime(2026, 11, 13, 8, 30),
  );
}
