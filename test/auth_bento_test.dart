// Layar auth Bento Lab (P3a): Sambutan, Masuk, Lupa sandi, Terima undangan
// memakai susunan E0 Masuk (hero kuning, plat logo putih, kartu putih sudut 32
// yang menumpang). Yang diuji: tata letak dari token (dua tema, HP dan tablet),
// tiap keadaan layar (awal, sibuk, galat, kosong, ada/tidak ada kontak), bahwa
// logika lama TIDAK berubah (siapa memanggil apa, tombol mati/hidup), Semantics
// (judul, galat diumumkan, tombol kembali), sasaran sentuh >= 48 dp, kontras,
// "kurangi gerak", dan 320 dp x huruf 1,3 tanpa luapan.
//
// Alur menyeluruh layar-layar ini sudah dijaga `alur_dasar_test.dart`,
// `sambutan_test.dart`, `perbaikan_p1_test.dart`, dan harness
// `tampilan/render_layar_test.dart`; berkas ini menambah yang baru dari desain.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sidik_pelanggan/core/api_pelanggan.dart';
import 'package:sidik_pelanggan/core/penyimpan_perangkat.dart';
import 'package:sidik_pelanggan/core/tema/bentuk.dart';
import 'package:sidik_pelanggan/core/tema/palet_sidik.dart';
import 'package:sidik_pelanggan/core/tema/spasi.dart';
import 'package:sidik_pelanggan/core/tema/tema_sidik.dart';
import 'package:sidik_pelanggan/core/tema/ukuran.dart';
import 'package:sidik_pelanggan/core/tema/warna_sidik.dart';
import 'package:sidik_pelanggan/models/akun.dart';
import 'package:sidik_pelanggan/providers/perangkat_provider.dart';
import 'package:sidik_pelanggan/providers/sesi_provider.dart';
import 'package:sidik_pelanggan/screens/auth/kerangka_auth.dart';
import 'package:sidik_pelanggan/screens/auth/lupa_sandi_screen.dart';
import 'package:sidik_pelanggan/screens/auth/masuk_screen.dart';
import 'package:sidik_pelanggan/screens/auth/sambutan_screen.dart';
import 'package:sidik_pelanggan/screens/auth/terima_undangan_screen.dart';
import 'package:sidik_pelanggan/widgets/kolom_formulir.dart';
import 'package:sidik_pelanggan/widgets/lencana_kan.dart';
import 'package:sidik_pelanggan/widgets/panel_pemberitahuan.dart';
import 'package:sidik_pelanggan/widgets/tombol_bulat.dart';
import 'package:sidik_pelanggan/widgets/tombol_sidik.dart';

import 'dukungan/dukungan.dart';
import 'dukungan/fixture_fitur.dart';
import 'dukungan/layar_uji.dart';
import 'dukungan/ukur_komponen.dart';

/// Penyimpan perangkat di memori: yang ditandai Sambutan bisa dibaca balik.
class _Perangkat extends PenyimpanPerangkat {
  final isi = <String, String>{};

  @override
  Future<bool> sudahLihatSambutan() async => isi['sambutan'] == '1';

  @override
  Future<void> tandaiSambutan() async => isi['sambutan'] = '1';
}

/// Sesi palsu: mencatat panggilan Masuk/undangan; dapat menahan jawabannya
/// ([tahan]) atau menolaknya ([galat]).
class _Sesi extends SesiController {
  _Sesi({this.galat, this.tahan});

  final GalatApi? galat;
  final Completer<void>? tahan;
  final masukDipanggil = <String>[];
  final undanganDipanggil = <String>[];

  @override
  Future<Sesi?> build() async => null;

  @override
  Future<void> masuk(String email, String sandi) async {
    masukDipanggil.add('$email|$sandi');
    await tahan?.future;
    if (galat != null) throw galat!;
  }

  @override
  Future<bool> terimaUndangan({
    required String email,
    required String kode,
    required String nama,
    required String telepon,
    String? jabatan,
    required String sandi,
    required bool setujuSyarat,
  }) async {
    undanganDipanggil.add('$email|$kode|$setujuSyarat');
    if (galat != null) throw galat!;
    return false;
  }
}

/// Layanan palsu untuk Lupa sandi.
class _Layanan extends LayananUji {
  _Layanan({this.galat});

  final GalatApi? galat;
  final kodeDiminta = <String>[];
  final sandiDiatur = <String>[];

  @override
  Future<void> lupaSandi(String email) async {
    kodeDiminta.add(email);
    if (galat != null) throw galat!;
  }

  @override
  Future<void> aturUlangSandi({
    required String email,
    required String otp,
    required String sandi,
  }) async {
    sandiDiatur.add('$email|$otp|$sandi');
  }
}

const _kontak = InfoAplikasi(email: 'lab@contoh.test');
const _dokumen = InfoAplikasi(
  email: 'lab@contoh.test',
  kebijakanPrivasiUrl: 'https://contoh.test/privasi',
  syaratUrl: 'https://contoh.test/syarat',
);

/// Pasang [layar]. [dorong] = layar dibuka dari layar lain (seperti di app:
/// Lupa sandi dari Masuk), supaya ia bisa ditutup dan punya tombol kembali.
Future<void> _pasang(
  WidgetTester tester,
  Widget layar, {
  bool gelap = false,
  double skala = 1.0,
  bool dorong = false,
  InfoAplikasi info = InfoAplikasi.kosong,
  _Sesi? sesi,
  _Layanan? layanan,
  _Perangkat? perangkat,
}) async {
  final home = dorong
      ? Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => Navigator.of(
                  context,
                ).push(MaterialPageRoute<void>(builder: (_) => layar)),
                child: const Text('buka-layar'),
              ),
            ),
          ),
        )
      : layar;
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        infoAplikasiProvider.overrideWith((ref) async => info),
        sesiProvider.overrideWith(() => sesi ?? _Sesi()),
        layananProvider.overrideWithValue(layanan ?? _Layanan()),
        penyimpanPerangkatProvider.overrideWithValue(perangkat ?? _Perangkat()),
      ],
      child: MaterialApp(
        theme: TemaSidik.terang,
        darkTheme: TemaSidik.gelap,
        themeMode: gelap ? ThemeMode.dark : ThemeMode.light,
        builder: (context, child) => MediaQuery.withClampedTextScaling(
          minScaleFactor: skala,
          maxScaleFactor: skala,
          child: child!,
        ),
        home: home,
      ),
    ),
  );
  await tester.pumpAndSettle();
  if (dorong) {
    await tester.tap(find.text('buka-layar'));
    await tester.pumpAndSettle();
  }
}

Future<void> _isi(WidgetTester tester, String label, String nilai) async {
  final kolom = find.widgetWithText(TextField, label, skipOffstage: false);
  await tester.ensureVisible(kolom);
  await tester.enterText(kolom, nilai);
  await tester.pump();
}

/// Tinggi 2400: ListView membangun butirnya malas, jadi isi bawah lipatan
/// tidak ada di pohon kalau luput.
void _layarTinggi(WidgetTester tester, {double lebar = 392}) =>
    layarHp(tester, lebar: lebar, tinggi: 2400);

/// "Kurangi gerak" menyala di sistem (dipulihkan otomatis).
void _kurangiGerak(WidgetTester tester) {
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
}

bool? _aktif(WidgetTester tester, Finder f) => tester
    .getSemantics(f)
    .getSemanticsData()
    .flagsCollection
    .isEnabled
    .toBoolOrNull();

ThemeData _tema(bool gelap) => gelap ? TemaSidik.gelap : TemaSidik.terang;

void main() {
  setUpAll(siapkanTesFitur);

  group('susunan E0: hero kuning, plat putih, kartu putih menumpang', () {
    for (final gelap in [false, true]) {
      final nama = gelap ? 'gelap' : 'terang';
      for (final (judul, layar) in <(String, Widget)>[
        ('Masuk', const MasukScreen()),
        ('Sambutan', const SambutanScreen()),
      ]) {
        testWidgets('$judul, $nama: warna dan ukuran dari token', (
          tester,
        ) async {
          layarHp(tester, lebar: 392, tinggi: 852);
          await _pasang(tester, layar, gelap: gelap);
          final w = _tema(gelap).extension<WarnaSidik>()!;

          // Kepala biru muda tetap terang di tema gelap: warna yang SAMA.
          final hero = tester.widget<ColoredBox>(
            find.byKey(KerangkaAuth.kunciHero),
          );
          expect(hero.color, w.ubinBiru);
          expect(hero.color, PaletSidik.biruMuda);

          final plat = tester.widget<DecoratedBox>(
            find.byKey(KerangkaAuth.kunciPlat),
          );
          expect((plat.decoration as BoxDecoration).color, w.kertasUbin);
          expect(
            tester.getSize(find.byKey(KerangkaAuth.kunciPlat)),
            const Size.square(UkuranAuth.platLogo),
          );

          final kartu = tester.widget<Material>(
            find.byKey(KerangkaAuth.kunciKartu),
          );
          expect(kartu.color, _tema(gelap).colorScheme.surface);
          expect(
            (kartu.shape! as RoundedRectangleBorder).borderRadius,
            Bentuk.sudutUbin,
          );

          final h = tester.getRect(find.byKey(KerangkaAuth.kunciHero));
          final k = tester.getRect(find.byKey(KerangkaAuth.kunciKartu));
          final t = tester.getRect(find.byKey(KerangkaAuth.kunciTumpang));
          expect(h.left, 0);
          expect(h.width, 392, reason: 'hero penuh lebar layar');
          expect(h.top, 0, reason: 'hero dari tepi atas layar');
          expect(h.height, UkuranAuth.hero - UkuranAuth.kartuTumpang);
          expect(k.top, h.bottom, reason: 'kartu mulai di tepi hero');
          expect(t.top, k.top);
          expect(t.height, UkuranAuth.kartuTumpang);
          expect(
            t.bottom,
            UkuranAuth.hero,
            reason: 'biru muda berakhir 240 dp dari atas; kartu menumpang 24',
          );
          expect(k.left, Spasi.sisi);
          expect(k.right, 392 - Spasi.sisi);

          expect(
            pelanggaranKontrasTeks(tester, find.byKey(KerangkaAuth.kunciHero)),
            isEmpty,
          );
          expect(
            pelanggaranKontrasTeks(tester, find.byKey(KerangkaAuth.kunciKartu)),
            isEmpty,
          );
        });
      }
    }

    testWidgets('tablet 840: kartu 440 di tengah, hero tetap penuh lebar', (
      tester,
    ) async {
      layarTablet(tester);
      await _pasang(tester, const MasukScreen());
      final h = tester.getRect(find.byKey(KerangkaAuth.kunciHero));
      final k = tester.getRect(find.byKey(KerangkaAuth.kunciKartu));
      expect(h.width, 840);
      expect(k.width, KolomFormulir.lebarMaks);
      expect(k.center.dx, 420);
    });

    testWidgets('layar anak: hero pendek, plat 80, tombol kembali bila bisa '
        'ditutup', (tester) async {
      _layarTinggi(tester);
      final semantik = tester.ensureSemantics();
      await _pasang(tester, const LupaSandiScreen(), dorong: true);

      expect(
        tester.getSize(find.byKey(KerangkaAuth.kunciPlat)),
        const Size.square(UkuranAuth.platLogoAnak),
      );
      expect(
        tester.getRect(find.byKey(KerangkaAuth.kunciHero)).height,
        lessThan(UkuranAuth.hero - UkuranAuth.kartuTumpang),
        reason: 'formulir panjang tidak dikubur hero setinggi 330',
      );
      final kembali = find.byType(TombolBulat);
      expect(kembali, findsOneWidget);
      expect(
        tester.getSemantics(find.bySemanticsLabel('Kembali')),
        matchesSemantics(
          label: 'Kembali',
          isButton: true,
          hasEnabledState: true,
          isEnabled: true,
          hasTapAction: true,
        ),
      );
      expect(
        tester.getSize(kembali).shortestSide,
        greaterThanOrEqualTo(AreaSentuh.minimum),
      );
      await tester.tap(kembali);
      await tester.pumpAndSettle();
      expect(find.byType(LupaSandiScreen), findsNothing);
      expect(find.text('buka-layar'), findsOneWidget);
      semantik.dispose();
    });

    testWidgets(
      'layar anak tanpa layar di bawahnya: tidak ada tombol kembali',
      (tester) async {
        _layarTinggi(tester);
        await _pasang(tester, const TerimaUndanganScreen());
        expect(find.byType(TombolBulat), findsNothing);
        expect(find.text('Pakai kode undangan'), findsOneWidget);
      },
    );

    testWidgets('judul kartu dibaca sebagai judul; hanya satu tombol utama', (
      tester,
    ) async {
      final semantik = tester.ensureSemantics();
      await _pasang(tester, const MasukScreen());
      final judul = tester
          .getSemantics(find.byType(JudulAuth))
          .getSemanticsData();
      expect(judul.label, 'Masuk');
      expect(judul.flagsCollection.isHeader, isTrue);
      final utama = find.byType(FilledButton);
      expect(utama, findsOneWidget, reason: 'satu tombol utama per layar');
      semantik.dispose();
    });
  });

  group('Sambutan: logika sama, dua keadaan kontak', () {
    testWidgets('Masuk menandai sambutan; kode undangan menandai dan membuka '
        'layar undangan', (tester) async {
      final perangkat = _Perangkat();
      await _pasang(tester, const SambutanScreen(), perangkat: perangkat);
      expect(perangkat.isi, isEmpty);
      await tester.tap(find.widgetWithText(TombolSidik, 'Masuk'));
      await tester.pumpAndSettle();
      expect(perangkat.isi['sambutan'], '1');

      final p2 = _Perangkat();
      await _pasang(tester, const SambutanScreen(), perangkat: p2);
      await tester.tap(find.text('Pakai kode undangan'));
      await tester.pumpAndSettle();
      expect(find.byType(TerimaUndanganScreen), findsOneWidget);
      expect(p2.isi['sambutan'], '1');
    });

    testWidgets('tanpa kontak lab: tidak ada tombol Hubungi', (tester) async {
      await _pasang(tester, const SambutanScreen());
      expect(
        find.widgetWithText(TombolSidik, 'Hubungi PT Sidik'),
        findsNothing,
      );
    });

    testWidgets('dengan kontak lab: tombol Hubungi tampil; nama PT dan lencana '
        'KAN di bawah kartu', (tester) async {
      _layarTinggi(tester);
      await _pasang(tester, const SambutanScreen(), info: _kontak);
      expect(
        find.widgetWithText(TombolSidik, 'Hubungi PT Sidik'),
        findsOneWidget,
      );
      final kartu = tester.getRect(find.byKey(KerangkaAuth.kunciKartu));
      expect(
        tester
            .getTopLeft(find.text('PT Sistem Dirgantara Inovasi Teknologi'))
            .dy,
        greaterThan(kartu.bottom),
      );
      expect(find.byType(LencanaKan), findsOneWidget);
    });
  });

  group('Masuk: keadaan', () {
    testWidgets('awal: tombol hidup, tanpa pesan galat, tanpa panel sesi', (
      tester,
    ) async {
      final semantik = tester.ensureSemantics();
      await _pasang(tester, const MasukScreen());
      expect(_aktif(tester, find.byType(FilledButton)), isTrue);
      expect(find.byType(PesanGalatAuth), findsNothing);
      expect(find.byType(PanelPemberitahuan), findsNothing);
      semantik.dispose();
    });

    testWidgets('isian kosong: pesan dengan ikon, diumumkan, tanpa memanggil '
        'sesi', (tester) async {
      final semantik = tester.ensureSemantics();
      final sesi = _Sesi();
      await _pasang(tester, const MasukScreen(), sesi: sesi);
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      expect(find.text('Isi email dan sandi Anda.'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(PesanGalatAuth),
          matching: find.byIcon(Icons.error_outline),
        ),
        findsOneWidget,
        reason: 'galat = ikon + kalimat, bukan warna saja',
      );
      expect(
        tester
            .getSemantics(find.byType(PesanGalatAuth))
            .getSemanticsData()
            .flagsCollection
            .isLiveRegion,
        isTrue,
        reason: 'pembaca layar harus mengumumkan galat',
      );
      expect(sesi.masukDipanggil, isEmpty);
      semantik.dispose();
    });

    testWidgets('sibuk: tombol mati dengan pemutar, hidup lagi sesudahnya', (
      tester,
    ) async {
      final semantik = tester.ensureSemantics();
      final tahan = Completer<void>();
      final sesi = _Sesi(tahan: tahan);
      await _pasang(tester, const MasukScreen(), sesi: sesi);
      await _isi(tester, 'Email', 'budi@contoh.test');
      await _isi(tester, 'Sandi', 'sandi-rahasia-1');
      await tester.tap(find.byType(FilledButton));
      await tester.pump();

      expect(sesi.masukDipanggil, ['budi@contoh.test|sandi-rahasia-1']);
      expect(_aktif(tester, find.byType(FilledButton)), isFalse);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      tahan.complete();
      await tester.pumpAndSettle();
      expect(_aktif(tester, find.byType(FilledButton)), isTrue);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      semantik.dispose();
    });

    testWidgets('galat server: pesan dari server tampil dengan ikon', (
      tester,
    ) async {
      final sesi = _Sesi(
        galat: const GalatApi(status: 401, pesan: 'Email atau sandi salah.'),
      );
      await _pasang(tester, const MasukScreen(), sesi: sesi);
      await _isi(tester, 'Email', 'budi@contoh.test');
      await _isi(tester, 'Sandi', 'salah');
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();
      expect(find.text('Email atau sandi salah.'), findsOneWidget);
      expect(find.byType(PesanGalatAuth), findsOneWidget);
    });

    testWidgets('tanpa koneksi: pesan jaringan yang sama dari GalatApi', (
      tester,
    ) async {
      final sesi = _Sesi(galat: GalatApi.jaringan());
      await _pasang(tester, const MasukScreen(), sesi: sesi);
      await _isi(tester, 'Email', 'budi@contoh.test');
      await _isi(tester, 'Sandi', 'apa-saja-1');
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();
      expect(find.textContaining('Tidak bisa terhubung'), findsOneWidget);
    });

    testWidgets('sesi berakhir: panel pemberitahuan tampil di dalam kartu', (
      tester,
    ) async {
      await _pasang(tester, const MasukScreen());
      ProviderScope.containerOf(
        tester.element(find.byType(MasukScreen)),
      ).read(sesiBerakhirProvider.notifier).atur(true);
      await tester.pump();
      expect(
        find.descendant(
          of: find.byKey(KerangkaAuth.kunciKartu),
          matching: find.text('Sesi Anda berakhir. Silakan masuk lagi.'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('Tampilkan sandi: tooltip dan isian berganti', (tester) async {
      await _pasang(tester, const MasukScreen());
      bool tersembunyi() => tester
          .widget<EditableText>(
            find.descendant(
              of: find.widgetWithText(TextField, 'Sandi'),
              matching: find.byType(EditableText),
            ),
          )
          .obscureText;
      expect(tersembunyi(), isTrue);
      await tester.tap(find.byTooltip('Tampilkan sandi'));
      await tester.pump();
      expect(tersembunyi(), isFalse);
      expect(find.byTooltip('Sembunyikan sandi'), findsOneWidget);
    });

    testWidgets('Lupa sandi? membuka layar atur ulang dengan email terisi; '
        'Pakai kode undangan membuka layar undangan', (tester) async {
      await _pasang(tester, const MasukScreen());
      await _isi(tester, 'Email', 'budi@contoh.test');
      await tester.tap(find.text('Lupa sandi?'));
      await tester.pumpAndSettle();
      expect(find.byType(LupaSandiScreen), findsOneWidget);
      expect(find.text('budi@contoh.test'), findsOneWidget);

      await tester.tap(find.byType(TombolBulat));
      await tester.pumpAndSettle();
      expect(find.byType(LupaSandiScreen), findsNothing);

      await tester.ensureVisible(find.text('Pakai kode undangan'));
      await tester.tap(find.text('Pakai kode undangan'));
      await tester.pumpAndSettle();
      expect(find.byType(TerimaUndanganScreen), findsOneWidget);
    });
  });

  group('Lupa sandi: dua langkah di satu layar', () {
    testWidgets('minta kode lalu simpan sandi baru; layar menutup', (
      tester,
    ) async {
      _layarTinggi(tester);
      final layanan = _Layanan();
      await _pasang(
        tester,
        const LupaSandiScreen(),
        dorong: true,
        layanan: layanan,
      );
      expect(find.text('Kode dari email'), findsNothing);
      await _isi(tester, 'Email', 'budi@contoh.test');
      await tester.tap(find.widgetWithText(TombolSidik, 'Kirim kode'));
      await tester.pumpAndSettle();
      expect(layanan.kodeDiminta, ['budi@contoh.test']);
      expect(find.textContaining('kode 6 digit sudah dikirim'), findsOneWidget);
      expect(find.text('Kode dari email'), findsOneWidget);

      await _isi(tester, 'Kode dari email', '123456');
      await _isi(tester, 'Sandi baru', 'Kalibrasi#2026Sidik');
      await tester.tap(find.widgetWithText(TombolSidik, 'Simpan sandi baru'));
      await tester.pumpAndSettle();
      expect(layanan.sandiDiatur, [
        'budi@contoh.test|123456|Kalibrasi#2026Sidik',
      ]);
      expect(find.byType(LupaSandiScreen), findsNothing);
    });

    testWidgets('galat per kolom tampil di kolomnya, bukan sebagai pesan '
        'umum', (tester) async {
      _layarTinggi(tester);
      final layanan = _Layanan(
        galat: const GalatApi(
          status: 422,
          pesan: 'Data tidak valid.',
          isian: {'email': 'Format email tidak benar.'},
        ),
      );
      await _pasang(tester, const LupaSandiScreen(), layanan: layanan);
      await _isi(tester, 'Email', 'bukan-email');
      await tester.tap(find.widgetWithText(TombolSidik, 'Kirim kode'));
      await tester.pumpAndSettle();
      expect(find.text('Format email tidak benar.'), findsOneWidget);
      expect(find.byType(PesanGalatAuth), findsNothing);
      expect(find.text('Kode dari email'), findsNothing);
    });

    testWidgets('galat umum (server/jaringan): pesan dengan ikon, kolom kode '
        'belum muncul', (tester) async {
      _layarTinggi(tester);
      final layanan = _Layanan(galat: GalatApi.jaringan());
      await _pasang(tester, const LupaSandiScreen(), layanan: layanan);
      await _isi(tester, 'Email', 'budi@contoh.test');
      await tester.tap(find.widgetWithText(TombolSidik, 'Kirim kode'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Tidak bisa terhubung'), findsOneWidget);
      expect(find.byType(PesanGalatAuth), findsOneWidget);
      expect(find.text('Kode dari email'), findsNothing);
    });
  });

  group('Terima undangan: keadaan', () {
    testWidgets('tombol mati sampai syarat disetujui (Semantics enabled)', (
      tester,
    ) async {
      _layarTinggi(tester);
      final semantik = tester.ensureSemantics();
      final sesi = _Sesi();
      await _pasang(tester, const TerimaUndanganScreen(), sesi: sesi);
      final kirim = find.widgetWithText(TombolSidik, 'Buat akun & masuk');
      final tombol = find.descendant(
        of: kirim,
        matching: find.byType(FilledButton),
      );
      expect(_aktif(tester, tombol), isFalse);
      await tester.tap(kirim);
      await tester.pump();
      expect(sesi.undanganDipanggil, isEmpty, reason: 'mati: tak terkirim');

      await _isi(tester, 'Email', 'budi@contoh.test');
      await _isi(tester, 'Kode undangan', 'K7M2QP4R');
      await tester.tap(find.byType(CheckboxListTile));
      await tester.pump();
      expect(_aktif(tester, tombol), isTrue);
      await tester.tap(kirim);
      await tester.pumpAndSettle();
      expect(sesi.undanganDipanggil, ['budi@contoh.test|K7M2QP4R|true']);
      semantik.dispose();
    });

    testWidgets('galat per kolom di bawah kolomnya; tanpa kontak lab tidak '
        'ada Minta kode baru', (tester) async {
      _layarTinggi(tester);
      final sesi = _Sesi(
        galat: const GalatApi(
          status: 422,
          pesan: 'Data tidak valid.',
          isian: {'kode': 'Kode salah atau kedaluwarsa.'},
        ),
      );
      await _pasang(tester, const TerimaUndanganScreen(), sesi: sesi);
      await tester.tap(find.byType(CheckboxListTile));
      await tester.pump();
      await tester.tap(find.widgetWithText(TombolSidik, 'Buat akun & masuk'));
      await tester.pumpAndSettle();
      expect(find.text('Kode salah atau kedaluwarsa.'), findsOneWidget);
      expect(find.byType(PesanGalatAuth), findsNothing);
      expect(find.text('Minta kode baru ke PT Sidik'), findsNothing);
    });

    testWidgets('dengan kontak lab: galat kode menawarkan Minta kode baru', (
      tester,
    ) async {
      _layarTinggi(tester);
      final sesi = _Sesi(
        galat: const GalatApi(
          status: 422,
          pesan: 'Data tidak valid.',
          isian: {'kode': 'Kode salah atau kedaluwarsa.'},
        ),
      );
      await _pasang(
        tester,
        const TerimaUndanganScreen(),
        sesi: sesi,
        info: _kontak,
      );
      expect(find.text('Minta kode baru ke PT Sidik'), findsNothing);
      await tester.tap(find.byType(CheckboxListTile));
      await tester.pump();
      await tester.tap(find.widgetWithText(TombolSidik, 'Buat akun & masuk'));
      await tester.pumpAndSettle();
      expect(find.text('Minta kode baru ke PT Sidik'), findsOneWidget);
    });

    testWidgets('galat umum: pesan dengan ikon di dalam kartu', (tester) async {
      _layarTinggi(tester);
      final sesi = _Sesi(galat: GalatApi.jaringan());
      await _pasang(tester, const TerimaUndanganScreen(), sesi: sesi);
      await tester.tap(find.byType(CheckboxListTile));
      await tester.pump();
      await tester.tap(find.widgetWithText(TombolSidik, 'Buat akun & masuk'));
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byKey(KerangkaAuth.kunciKartu),
          matching: find.byType(PesanGalatAuth),
        ),
        findsOneWidget,
      );
    });
  });

  group('320 dp x huruf 1,3: tanpa luapan, sentuh >= 48 dp, kontras', () {
    final kasus = <(String, Widget Function(), bool, InfoAplikasi)>[
      ('Sambutan', () => const SambutanScreen(), false, _kontak),
      ('Masuk', () => const MasukScreen(), false, InfoAplikasi.kosong),
      ('Lupa sandi', () => const LupaSandiScreen(), true, InfoAplikasi.kosong),
      ('Terima undangan', () => const TerimaUndanganScreen(), true, _dokumen),
    ];
    for (final gelap in [false, true]) {
      for (final (nama, bangun, dorong, info) in kasus) {
        testWidgets('$nama, ${gelap ? 'gelap' : 'terang'}', (tester) async {
          _layarTinggi(tester, lebar: 320);
          final semantik = tester.ensureSemantics();
          await _pasang(
            tester,
            bangun(),
            gelap: gelap,
            skala: 1.3,
            dorong: dorong,
            info: info,
            sesi: _Sesi(galat: GalatApi.jaringan()),
          );
          // Keadaan galat ikut: pesan umum tampil di layar yang punya tombol
          // kirim.
          if (nama == 'Masuk') {
            await tester.tap(find.byType(FilledButton));
            await tester.pumpAndSettle();
            ProviderScope.containerOf(
              tester.element(find.byType(MasukScreen)),
            ).read(sesiBerakhirProvider.notifier).atur(true);
            await tester.pump();
            expect(find.byType(PesanGalatAuth), findsOneWidget);
            expect(find.byType(PanelPemberitahuan), findsOneWidget);
          }
          if (nama == 'Terima undangan') {
            await tester.tap(find.byType(CheckboxListTile));
            await tester.pump();
            await tester.tap(find.byType(FilledButton));
            await tester.pumpAndSettle();
            expect(find.byType(PesanGalatAuth), findsOneWidget);
            expect(find.text('Minta kode baru ke PT Sidik'), findsOneWidget);
          }
          expect(tester.takeException(), isNull);
          await periksaPedomanSentuh(tester);
          expect(
            pelanggaranKontrasTeks(tester, find.byKey(KerangkaAuth.kunciKartu)),
            isEmpty,
          );
          semantik.dispose();
        });
      }
    }
  });

  group('kurangi gerak dan tanpa animasi berulang', () {
    for (final kurangi in [false, true]) {
      testWidgets(
        'kerangka tidak menjalankan animasi (kurangi gerak: $kurangi)',
        (tester) async {
          if (kurangi) _kurangiGerak(tester);
          await _pasang(tester, const MasukScreen());
          expect(
            tester.hasRunningAnimations,
            isFalse,
            reason: 'tidak ada animasi berulang di layar auth',
          );
          // pumpAndSettle selesai = tidak ada yang berulang.
          await tester.pumpAndSettle();
        },
      );
    }

    testWidgets('kurangi gerak: tombol utama tanpa skala tekan', (
      tester,
    ) async {
      _kurangiGerak(tester);
      await _pasang(tester, const MasukScreen());
      final skala = tester.widget<AnimatedScale>(
        find.descendant(
          of: find.byType(TombolSidik).first,
          matching: find.byType(AnimatedScale),
        ),
      );
      expect(skala.duration, Duration.zero);
    });
  });
}
