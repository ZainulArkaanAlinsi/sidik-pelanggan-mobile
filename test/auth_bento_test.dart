// Layar auth (R1b): Sambutan, Masuk, Lupa sandi, Terima undangan, arah
// tenang-formal (REVISI-2 butir 1): kepala ringkas (logo kecil + nama aplikasi)
// di atas latar halaman, SATU kartu putih bergaris halus, isian berlabel
// PERMANEN di atas kolom (`KolomIsian`), pesan galat dekat isian, satu tombol
// utama. Yang diuji: tata letak dari token (dua tema, HP dan tablet), tiap
// keadaan layar (awal, sibuk, galat, kosong, ada/tidak ada kontak), bahwa
// logika lama TIDAK berubah (siapa memanggil apa, tombol mati/hidup), Semantics
// (judul, label isian, galat diumumkan, tombol kembali), sasaran sentuh >= 48
// dp, kontras, "kurangi gerak", huruf 1,3x dan 2,0x tanpa luapan, dan papan
// ketik yang tidak menutupi tombol utama.
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
import 'package:sidik_pelanggan/widgets/kolom_isian.dart';
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

/// Kolom (TextField) milik [KolomIsian] berlabel [label].
Finder _kolom(String label) => find.descendant(
  of: find.widgetWithText(KolomIsian, label, skipOffstage: false),
  matching: find.byType(TextField),
  skipOffstage: false,
);

Future<void> _isi(WidgetTester tester, String label, String nilai) async {
  final kolom = _kolom(label);
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

  group('susunan tenang: kepala ringkas, kartu putih, tanpa bidang berwarna', () {
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
          final skema = _tema(gelap).colorScheme;
          final w = _tema(gelap).extension<WarnaSidik>()!;

          // Tanpa bidang berwarna: latar layar = latar halaman tema, tidak ada
          // kepala biru muda (dulu 240 dp) di belakang logo.
          final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
          expect(
            scaffold.backgroundColor ?? _tema(gelap).scaffoldBackgroundColor,
            _tema(gelap).scaffoldBackgroundColor,
          );
          expect(
            find.byWidgetPredicate(
              (x) => x is ColoredBox && x.color == w.ubinBiru,
            ),
            findsNothing,
            reason: 'tidak ada blok biru muda lagi',
          );

          // Logo kecil di plat putih bergaris halus: 48 dp (dulu 80).
          final plat = tester.widget<DecoratedBox>(
            find.byKey(KerangkaAuth.kunciPlat),
          );
          final dekor = plat.decoration as BoxDecoration;
          expect(dekor.color, w.kertasUbin);
          expect(dekor.borderRadius, Bentuk.sudutIkon);
          expect(
            tester.getSize(find.byKey(KerangkaAuth.kunciPlat)),
            const Size.square(UkuranAuth.platLogo),
          );
          expect(UkuranAuth.platLogo, 48);
          expect(find.text('SIDIK Pelanggan'), findsOneWidget);

          // Kartu putih: permukaan tema, garis halus, sudut 16 (bukan ekstrem).
          final kartu = tester.widget<Material>(
            find.byKey(KerangkaAuth.kunciKartu),
          );
          expect(kartu.color, skema.surface);
          final bentuk = kartu.shape! as RoundedRectangleBorder;
          expect(bentuk.borderRadius, Bentuk.sudutPanel);
          expect(bentuk.side.color, skema.outlineVariant);

          // Kepala ringkas di atas kartu; kartu selebar kolom dengan margin 16.
          final kepala = tester.getRect(find.byKey(KerangkaAuth.kunciKepala));
          final k = tester.getRect(find.byKey(KerangkaAuth.kunciKartu));
          expect(
            kepala.height,
            lessThanOrEqualTo(AreaSentuh.minimum + Spasi.sm),
          );
          expect(kepala.bottom, lessThan(k.top));
          expect(
            k.top,
            lessThan(UkuranUbin.alatRingkas + Spasi.xl),
            reason: 'kartu langsung di bawah kepala, bukan di bawah 240 dp',
          );
          expect(k.left, Spasi.sisi);
          expect(k.right, 392 - Spasi.sisi);

          expect(
            pelanggaranKontrasTeks(tester, find.byType(Scaffold)),
            isEmpty,
            reason: '$judul $nama',
          );
        });
      }
    }

    testWidgets('tablet 840: kartu 440 di tengah, latar tetap polos', (
      tester,
    ) async {
      layarTablet(tester);
      await _pasang(tester, const MasukScreen());
      final k = tester.getRect(find.byKey(KerangkaAuth.kunciKartu));
      expect(k.width, KolomFormulir.lebarMaks);
      expect(k.center.dx, 420);
    });

    testWidgets('layar anak: plat 40 sebelah tombol kembali (hanya bila bisa '
        'ditutup)', (tester) async {
      _layarTinggi(tester);
      final semantik = tester.ensureSemantics();
      await _pasang(tester, const LupaSandiScreen(), dorong: true);

      expect(
        tester.getSize(find.byKey(KerangkaAuth.kunciPlat)),
        const Size.square(UkuranAuth.platLogoAnak),
      );
      final kembali = find.byType(TombolBulat);
      expect(kembali, findsOneWidget);
      expect(
        tester.getRect(kembali).right,
        lessThan(tester.getRect(find.byKey(KerangkaAuth.kunciPlat)).left),
        reason: 'tombol kembali di kiri plat logo',
      );
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
      expect(judul.label, 'Masuk ke SIDIK');
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
              of: _kolom('Sandi'),
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
      // Galat DEKAT isian: di dalam kolom "Kode undangan" (tepat di bawahnya),
      // bukan di kolom lain dan bukan di dasar kartu.
      final kode = find.widgetWithText(KolomIsian, 'Kode undangan');
      final galat = find.descendant(
        of: kode,
        matching: find.text('Kode salah atau kedaluwarsa.'),
      );
      expect(galat, findsOneWidget);
      expect(
        tester.getTopLeft(galat).dy -
            tester.getRect(_kolom('Kode undangan')).bottom,
        lessThan(Spasi.lg),
      );
      for (final lain in ['Email', 'Nama lengkap', 'Nomor HP', 'Buat sandi']) {
        expect(
          find.descendant(
            of: find.widgetWithText(KolomIsian, lain),
            matching: find.text('Kode salah atau kedaluwarsa.'),
          ),
          findsNothing,
          reason: lain,
        );
      }
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

  group(
    '320 dp x huruf 1,3 dan 2,0: tanpa luapan, sentuh >= 48 dp, kontras',
    () {
      final kasus = <(String, Widget Function(), bool, InfoAplikasi)>[
        ('Sambutan', () => const SambutanScreen(), false, _kontak),
        ('Masuk', () => const MasukScreen(), false, InfoAplikasi.kosong),
        (
          'Lupa sandi',
          () => const LupaSandiScreen(),
          true,
          InfoAplikasi.kosong,
        ),
        ('Terima undangan', () => const TerimaUndanganScreen(), true, _dokumen),
      ];
      for (final skala in [1.3, 2.0]) {
        for (final gelap in [false, true]) {
          for (final (nama, bangun, dorong, info) in kasus) {
            testWidgets('$nama, ${gelap ? 'gelap' : 'terang'}, huruf $skala', (
              tester,
            ) async {
              _layarTinggi(tester, lebar: 320);
              final semantik = tester.ensureSemantics();
              await _pasang(
                tester,
                bangun(),
                gelap: gelap,
                skala: skala,
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
                expect(
                  find.text('Minta kode baru ke PT Sidik'),
                  findsOneWidget,
                );
              }
              expect(tester.takeException(), isNull);
              await periksaPedomanSentuh(tester);
              expect(
                pelanggaranKontrasTeks(
                  tester,
                  find.byKey(KerangkaAuth.kunciKartu),
                ),
                isEmpty,
              );
              semantik.dispose();
            });
          }
        }
      }
    },
  );

  group('label isian permanen di atas kolom (keempat layar)', () {
    Future<void> periksa(WidgetTester tester, List<String> label) async {
      // Tidak ada TextField berlabel mengambang di layar auth.
      for (final f in tester.widgetList<TextField>(find.byType(TextField))) {
        expect(f.decoration!.labelText, isNull);
        expect(f.decoration!.label, isNull);
      }
      for (final l in label) {
        final kolom = _kolom(l);
        expect(kolom, findsOneWidget, reason: l);
        final teks = find.descendant(
          of: find.widgetWithText(KolomIsian, l, skipOffstage: false),
          matching: find.text(l, skipOffstage: false),
          skipOffstage: false,
        );
        expect(teks, findsOneWidget, reason: '$l: label tampil');
        expect(
          tester.getRect(teks).bottom,
          lessThanOrEqualTo(tester.getRect(kolom).top),
          reason: '$l: label di atas kolom',
        );
        expect(
          tester.getSize(kolom).height,
          greaterThanOrEqualTo(UkuranKontrol.kolomCari),
          reason: '$l: kolom >= 48',
        );
      }
    }

    testWidgets('Masuk: Email dan Sandi', (tester) async {
      _layarTinggi(tester);
      await _pasang(tester, const MasukScreen());
      await periksa(tester, ['Email', 'Sandi']);
      // Terisi: label tetap tampil (bukan petunjuk yang menguap).
      await _isi(tester, 'Email', 'budi@contoh.test');
      await _isi(tester, 'Sandi', 'rahasia');
      await periksa(tester, ['Email', 'Sandi']);
    });

    testWidgets('Lupa sandi: Email; sesudah kode terkirim tiga isian', (
      tester,
    ) async {
      _layarTinggi(tester);
      await _pasang(tester, const LupaSandiScreen(), dorong: true);
      await periksa(tester, ['Email']);
      await _isi(tester, 'Email', 'budi@contoh.test');
      await tester.tap(find.widgetWithText(TombolSidik, 'Kirim kode'));
      await tester.pumpAndSettle();
      await periksa(tester, ['Email', 'Kode dari email', 'Sandi baru']);
      // Email dikunci sesudah kode terkirim: tetap berlabel, tidak bisa diubah.
      expect(tester.widget<TextField>(_kolom('Email')).enabled, isFalse);
    });

    testWidgets('Terima undangan: enam isian', (tester) async {
      _layarTinggi(tester);
      await _pasang(tester, const TerimaUndanganScreen());
      await periksa(tester, [
        'Email',
        'Kode undangan',
        'Nama lengkap',
        'Nomor HP',
        'Jabatan (opsional)',
        'Buat sandi',
      ]);
      // Bantuan di bawah kolomnya, tetap terbaca selagi terisi.
      for (final bantuan in [
        'Ada di email undangan',
        'Contoh: 0812 3456 7890',
        'Minimal 10 karakter',
      ]) {
        expect(find.text(bantuan), findsOneWidget, reason: bantuan);
      }
    });

    testWidgets('logika tidak berubah: isian lewat label yang sama sampai ke '
        'sesi (Masuk)', (tester) async {
      _layarTinggi(tester);
      final sesi = _Sesi();
      await _pasang(tester, const MasukScreen(), sesi: sesi);
      await _isi(tester, 'Email', ' budi@contoh.test ');
      await _isi(tester, 'Sandi', 'Kalibrasi#2026');
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();
      expect(sesi.masukDipanggil, [' budi@contoh.test |Kalibrasi#2026']);
    });
  });

  group('papan ketik tidak menutupi tombol utama', () {
    testWidgets('Masuk: kolom Sandi fokus, tombol Masuk tetap terlihat di atas '
        'papan ketik 300 dp (HP 360 x 640)', (tester) async {
      layarHp(tester, lebar: 360, tinggi: 640);
      addTearDown(tester.view.resetViewInsets);
      await _pasang(tester, const MasukScreen());
      // Kolom Sandi terlihat sebelum papan ketik; tombol di bawahnya belum
      // tertutup. Ketuk kolom, lalu papan ketik muncul.
      await tester.tap(_kolom('Sandi'));
      await tester.pump();
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      await tester.pumpAndSettle();
      final tombol = tester.getRect(find.byType(FilledButton));
      expect(
        tombol.bottom,
        lessThanOrEqualTo(640 - 300),
        reason: 'tombol utama di atas papan ketik',
      );
      expect(tombol.top, greaterThan(0));
      expect(tester.getRect(_kolom('Sandi')).bottom, lessThan(tombol.top));
      // Isian pertama juga terjangkau dengan menggulir.
      await tester.ensureVisible(_kolom('Email'));
      await tester.pumpAndSettle();
      expect(tester.getRect(_kolom('Email')).top, greaterThanOrEqualTo(0));
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'Terima undangan: kolom terakhir fokus, tombol utama terjangkau '
      'di atas papan ketik (HP 360 x 640, huruf 1,3)',
      (tester) async {
        layarHp(tester, lebar: 360, tinggi: 640);
        addTearDown(tester.view.resetViewInsets);
        await _pasang(tester, const TerimaUndanganScreen(), skala: 1.3);
        await tester.ensureVisible(_kolom('Buat sandi'));
        await tester.pumpAndSettle();
        await tester.tap(_kolom('Buat sandi'));
        await tester.pump();
        tester.view.viewInsets = const FakeViewPadding(bottom: 300);
        await tester.pumpAndSettle();
        // Sesudah kolom terakhir: persetujuan, lalu tombol; gulirkan ke tombol:
        // ia bisa dibawa ke atas papan ketik (tidak terkubur).
        final tombol = find.widgetWithText(TombolSidik, 'Buat akun & masuk');
        await tester.ensureVisible(tombol);
        await tester.pumpAndSettle();
        expect(tester.getRect(tombol).bottom, lessThanOrEqualTo(640 - 300));
        expect(tester.takeException(), isNull);
      },
    );
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
