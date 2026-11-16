// Layar 03 "Sertifikat" (P5c, diarahkan ulang oleh REVISI-1/REVISI-2 16 Nov
// 2026): segmen Daftar | Arsip, kolom cari, baris sakelar "Tampilkan juga yang
// sudah direvisi", baris sertifikat ringkas (permukaan putih netral, garis
// tipis, badge status ikon + kata), dan empat keadaan (memuat statis, kosong,
// galat, tanpa koneksi). Yang dijaga: urutan info per baris, warna hanya pada
// badge status (keputusan null netral, FAIL tidak dilunakkan), jumlah di
// kepala hanya dari data yang terbaca (memuat/gagal bukan "0"), satu sumber
// hitungan (pil = provider daftar yang sama), cari/sakelar/paginasi tetap
// memakai provider dan kunci yang sama, kerangka tanpa gerak berulang,
// "kurangi gerak", huruf 1,3x di 320 dp, Semantics, sasaran sentuh, dan papan
// ketik.
//
// Perilaku tab Daftar | Arsip (berpindah, keadaan bertahan) dijaga juga oleh
// grup "tab Sertifikat" di `arsip_screen_test.dart`.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sidik_pelanggan/core/api_pelanggan.dart';
import 'package:sidik_pelanggan/core/format.dart';
import 'package:sidik_pelanggan/core/tema/bentuk.dart';
import 'package:sidik_pelanggan/core/tema/elevasi.dart';
import 'package:sidik_pelanggan/core/tema/spasi.dart';
import 'package:sidik_pelanggan/core/tema/tema_sidik.dart';
import 'package:sidik_pelanggan/core/tema/ukuran.dart';
import 'package:sidik_pelanggan/core/tema/warna_sidik.dart';
import 'package:sidik_pelanggan/models/data_pelanggan.dart';
import 'package:sidik_pelanggan/providers/koneksi_provider.dart';
import 'package:sidik_pelanggan/providers/paginasi.dart';
import 'package:sidik_pelanggan/providers/sesi_provider.dart';
import 'package:sidik_pelanggan/screens/alat/daftar_alat_bagian.dart'
    show CatatanLuring;
import 'package:sidik_pelanggan/screens/sertifikat/daftar_sertifikat_bagian.dart';
import 'package:sidik_pelanggan/screens/sertifikat/sertifikat_detail_screen.dart';
import 'package:sidik_pelanggan/screens/sertifikat/sertifikat_screen.dart';
import 'package:sidik_pelanggan/services/layanan_pelanggan.dart';
import 'package:sidik_pelanggan/widgets/chip_status.dart';
import 'package:sidik_pelanggan/widgets/dasar/cincin_fokus.dart';
import 'package:sidik_pelanggan/widgets/keadaan_galat.dart';
import 'package:sidik_pelanggan/widgets/kartu_sertifikat.dart';
import 'package:sidik_pelanggan/widgets/kartu_sidik.dart';
import 'package:sidik_pelanggan/widgets/kolom_cari_utuh.dart';
import 'package:sidik_pelanggan/widgets/segmen_pil.dart';
import 'package:sidik_pelanggan/widgets/stempel.dart';
import 'package:sidik_pelanggan/widgets/tombol_sidik.dart';

import 'dukungan/dukungan.dart';
import 'dukungan/fixture_fitur.dart';
import 'dukungan/layar_uji.dart';

/// Sertifikat dari JSON server; [serial] null = alat tanpa nomor seri.
Sertifikat _s(
  int id,
  String nomor, {
  String nama = 'Jangka Sorong',
  String? serial = 'SN-1',
  String? keputusan = 'PASS',
  String status = 'berlaku',
  int? diterbitkan = -300,
  int? berlakuSampai = 65,
}) {
  final json = sertifikatJson(
    id,
    nomor,
    namaAlat: nama,
    keputusan: keputusan,
    status: status,
    diterbitkan: diterbitkan ?? -300,
    berlakuSampai: berlakuSampai,
    dibatalkanPada: status == 'dibatalkan' ? -5 : null,
    digantikanOleh: status == 'digantikan'
        ? {'id': 99, 'nomor': 'CAL/2026/11/0099'}
        : null,
  );
  json['alat'] = {...(json['alat']! as Map), 'serial': serial};
  // `diterbitkan` null = server tidak mengirim tanggal terbit.
  if (diterbitkan == null) json['diterbitkan_pada'] = null;
  return Sertifikat.dariJson(json);
}

/// Lima sertifikat: PASS, FAIL, tanpa keputusan, digantikan, dibatalkan.
List<Sertifikat> _semua() => [
  _s(1, 'CAL/2026/09/0001', nama: 'Jangka Sorong', serial: 'JS-001'),
  _s(
    2,
    'CAL/2026/09/0002',
    nama: 'Timbangan Analitik',
    serial: 'TA-224',
    keputusan: 'FAIL',
  ),
  _s(
    3,
    'CAL/2026/09/0003',
    nama: 'Termometer Digital',
    serial: null,
    keputusan: null,
    berlakuSampai: null,
  ),
  _s(
    4,
    'CAL/2026/08/0004',
    nama: 'Manometer',
    serial: 'MN-04',
    status: 'digantikan',
  ),
  _s(
    5,
    'CAL/2026/07/0005',
    nama: 'Oven Memmert',
    serial: 'OV-05',
    status: 'dibatalkan',
  ),
];

/// Layanan palsu: mencatat parameter yang dikirim layar, menyaring seperti
/// server (kata cari, sakelar revisi), membagi halaman, dan bisa ditahan atau
/// digagalkan.
class _Layanan extends LayananPelanggan {
  _Layanan(this.isi) : super(ApiPelanggan());

  /// Semua sertifikat di server; yang berstatus digantikan hanya muncul bila
  /// sakelar revisi menyala.
  List<Sertifikat> isi;
  static const perHalaman = 20;

  /// Bila terisi, `total` yang dilaporkan server (bukan jumlah sebenarnya).
  int? totalLapor;

  /// Ditunda sampai selesai; null = langsung.
  Completer<void>? tahan;

  /// Dilempar bila terisi.
  Object? galat;

  final panggilan = <({String cari, bool digantikan, int halaman})>[];

  @override
  Future<Halaman<Sertifikat>> daftarSertifikat({
    String? cari,
    bool termasukDigantikan = false,
    int halaman = 1,
  }) async {
    panggilan.add((
      cari: cari ?? '',
      digantikan: termasukDigantikan,
      halaman: halaman,
    ));
    await tahan?.future;
    if (galat != null) throw galat!;
    final kata = (cari ?? '').toLowerCase();
    final cocok = [
      for (final s in isi)
        if ((termasukDigantikan || !s.digantikan) &&
            (kata.isEmpty ||
                '${s.nomor} ${s.namaAlat} ${s.serial}'.toLowerCase().contains(
                  kata,
                )))
          s,
    ];
    return Halaman(
      isi: cocok.skip((halaman - 1) * perHalaman).take(perHalaman).toList(),
      halaman: halaman,
      halamanTerakhir: cocok.isEmpty ? 1 : (cocok.length / perHalaman).ceil(),
      total: totalLapor ?? cocok.length,
    );
  }

  @override
  Future<Sertifikat> sertifikat(int id) async =>
      isi.firstWhere((s) => s.id == id);

  int get halamanTerakhirDiminta =>
      panggilan.map((p) => p.halaman).fold(0, (a, b) => a > b ? a : b);
}

/// Seperti `Gerbang` produksi: layar baru tampil setelah sesi selesai
/// dipulihkan, jadi provider data tidak dibangun dua kali.
class _Gerbang extends ConsumerWidget {
  const _Gerbang(this.anak);

  final Widget anak;

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      ref.watch(sesiProvider).hasValue ? anak : const SizedBox();
}

Widget _app(
  _Layanan layanan, {
  Widget anak = const SertifikatScreen(),
  bool gelap = false,
  double skala = 1.0,
}) => ProviderScope(
  key: UniqueKey(),
  // Tanpa pengulangan otomatis Riverpod: galat langsung tampil.
  retry: (_, _) => null,
  overrides: overrideDasar(
    tambahan: [layananProvider.overrideWithValue(layanan)],
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
    home: _Gerbang(anak),
  ),
);

/// "Kurangi gerak" menyala di sistem (dipulihkan otomatis).
void _kurangiGerak(WidgetTester tester) {
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
}

Future<void> _buka(
  WidgetTester tester,
  _Layanan layanan, {
  bool gelap = false,
  double skala = 1.0,
  double lebar = 390,
  double tinggi = 3200,
}) async {
  layarHp(tester, lebar: lebar, tinggi: tinggi);
  await tester.pumpWidget(_app(layanan, gelap: gelap, skala: skala));
  await tester.pumpAndSettle();
}

Finder _baris(String nomor) => find.widgetWithText(BarisSertifikat, nomor);

Finder get _semuaBaris => find.byType(BarisSertifikat);

Finder get _sakelar => find.byType(BarisSakelar);

/// Ketuk sel segmen. Lapisan ketuk SegmenPil menutupi kata di bawahnya, jadi
/// ketukan tidak "mengenai" Text itu sendiri (peringatan `warnIfMissed`).
Future<void> _pilihSegmen(WidgetTester tester, String label) async {
  await tester.tap(find.text(label), warnIfMissed: false);
  await tester.pumpAndSettle();
}

Future<void> _ketik(WidgetTester tester, String kata) async {
  await tester.enterText(find.byType(TextField), kata);
  await tester.pump(KolomCariUtuh.jeda + const Duration(milliseconds: 50));
  await tester.pumpAndSettle();
}

List<String> _nomorTampil(WidgetTester tester) => [
  for (final u in tester.widgetList<BarisSertifikat>(_semuaBaris))
    u.sertifikat.nomor,
];

List<String> _stempelDi(WidgetTester tester, Finder ubin) => [
  for (final s in tester.widgetList<Stempel>(
    find.descendant(of: ubin, matching: find.byType(Stempel)),
  ))
    s.status.label,
];

Color _latarBaris(WidgetTester tester, Finder ubin) => tester
    .widget<Material>(
      find.descendant(of: ubin, matching: find.byType(Material)).first,
    )
    .color!;

/// Warna latar pil Stempel pertama di [ubin].
Color _latarStempel(WidgetTester tester, Finder ubin) {
  final kotak = tester.widget<DecoratedBox>(
    find
        .descendant(
          of: find.descendant(of: ubin, matching: find.byType(Stempel)),
          matching: find.byType(DecoratedBox),
        )
        .first,
  );
  return (kotak.decoration as BoxDecoration).color!;
}

/// Pil jumlah di kepala, atau null bila tidak digambar.
String? _teksPil(WidgetTester tester) {
  final pil = find.byType(PilJumlahSertifikat);
  if (pil.evaluate().isEmpty) return null;
  return tester
      .widget<Text>(find.descendant(of: pil, matching: find.byType(Text)))
      .data;
}

void main() {
  setUpAll(siapkanTesFitur);

  group('susunan (REVISI-1/REVISI-2)', () {
    testWidgets(
      'kepala, segmen, kolom cari, sakelar, lalu baris; tanpa komponen lama',
      (tester) async {
        await _buka(tester, _Layanan(_semua()));

        expect(find.text('Sertifikat'), findsOneWidget);
        expect(find.byType(SegmenPil), findsOneWidget);
        expect(find.byType(KolomCariUtuh), findsOneWidget);
        expect(_sakelar, findsOneWidget);
        // Yang digantikan disembunyikan, yang dibatalkan tetap tampil: 4 dari 5.
        expect(_semuaBaris, findsNWidgets(4));
        expect(
          find.byWidgetPredicate((w) => w is SegmentedButton),
          findsNothing,
        );
        expect(find.byType(SwitchListTile), findsNothing);
        expect(find.byType(KartuSertifikat), findsNothing);
        expect(find.byType(KartuSidik), findsNothing);
        expect(find.byType(ChipStatus), findsNothing);
        expect(tester.widget<SegmenPil>(find.byType(SegmenPil)).pilihan, [
          'Daftar',
          'Arsip',
        ]);

        // Urutan menurun: segmen, kolom cari, sakelar, baris pertama.
        double atas(Finder f) => tester.getTopLeft(f).dy;
        expect(
          atas(find.byType(SegmenPil)),
          lessThan(atas(find.byType(KolomCariUtuh))),
        );
        expect(atas(find.byType(KolomCariUtuh)), lessThan(atas(_sakelar)));
        expect(atas(_sakelar), lessThan(atas(_semuaBaris.first)));
        // Urutan server tidak diubah layar.
        expect(_nomorTampil(tester), [
          'CAL/2026/09/0001',
          'CAL/2026/09/0002',
          'CAL/2026/09/0003',
          'CAL/2026/07/0005',
        ]);
      },
    );

    testWidgets('judul halaman 22-24, bukan 28', (tester) async {
      await _buka(tester, _Layanan(_semua()));
      final ukuran = tester
          .widget<Text>(find.text('Sertifikat'))
          .style!
          .fontSize!;
      expect(ukuran, inInclusiveRange(22, 24));
    });

    testWidgets(
      'baris: putih netral, sudut 16, garis tipis, padding 16, ringkas',
      (tester) async {
        await _buka(tester, _Layanan(_semua()));
        final baris = _baris('CAL/2026/09/0001');
        final s = Theme.of(tester.element(baris)).colorScheme;

        final bahan = tester.widget<Material>(
          find.descendant(of: baris, matching: find.byType(Material)).first,
        );
        final bentuk = bahan.shape! as RoundedRectangleBorder;
        expect(bentuk.borderRadius, Bentuk.sudutKontrol);
        expect(Bentuk.kontrol, inInclusiveRange(12, 16));
        expect(bentuk.side.width, Elevasi.garis);
        expect(bentuk.side.color, s.outlineVariant);
        expect(bahan.color, s.surface);
        expect(bahan.elevation, 0);
        // Padding kartu 16: teks pertama 16 dari tepi kiri baris.
        expect(
          tester.getTopLeft(find.text('Jangka Sorong')).dx -
              tester.getTopLeft(baris).dx,
          Spasi.lg,
        );
        // Ringkas dan >= 48 dp. Baris ini (PASS, tanggal terbit sebaris
        // dengan badge, ditambah baris kecil "Jadwal kalibrasi ulang") 134 dp
        // di lebar 390: batas lama 130 sengaja dinaikkan satu baris metadata
        // 12 dp; satu baris lagi akan melewati 140.
        final tinggi = tester.getSize(baris).height;
        expect(tinggi, greaterThanOrEqualTo(AreaSentuh.minimum));
        expect(tinggi, lessThan(140));
        // Satu tombol: satu InkWell, tanpa tombol kedua di dalamnya.
        expect(
          find.descendant(of: baris, matching: find.byType(InkWell)),
          findsOneWidget,
        );
      },
    );

    testWidgets('urutan info: nama alat, nomor, nomor seri, tanggal terbit, '
        'badge status', (tester) async {
      await _buka(tester, _Layanan(_semua()));
      final baris = _baris('CAL/2026/09/0001');
      final data = tester.widget<BarisSertifikat>(baris).sertifikat;

      Finder teks(String t) =>
          find.descendant(of: baris, matching: find.text(t));
      final nama = teks('Jangka Sorong');
      final nomor = teks('CAL/2026/09/0001');
      // "SN" hanya di layar; nomor seri sendiri tetap utuh di data.
      final seri = teks('SN JS-001');
      expect(data.serial, 'JS-001');
      final terbit = teks('Terbit ${Format.tanggal(data.diterbitkan)}');
      final badge = find.descendant(of: baris, matching: find.byType(Stempel));
      for (final f in [nama, nomor, seri, terbit, badge]) {
        expect(f, findsOneWidget);
      }
      double y(Finder f) => tester.getTopLeft(f).dy;
      expect(y(nama), lessThan(y(nomor)));
      expect(y(nomor), lessThan(y(terbit)));
      // Nomor seri sebaris dengan nomor sertifikat bila muat, di kanannya.
      expect(y(seri), y(nomor));
      expect(
        tester.getTopLeft(seri).dx,
        greaterThan(tester.getTopLeft(nomor).dx),
      );
      // Badge sesudah tanggal terbit: di kanannya bila satu baris, atau di
      // bawahnya bila tidak muat.
      final sebaris =
          (tester.getCenter(badge).dy - tester.getCenter(terbit).dy).abs() < 4;
      if (sebaris) {
        expect(
          tester.getTopLeft(badge).dx,
          greaterThan(tester.getTopLeft(terbit).dx),
        );
      } else {
        expect(y(badge), greaterThan(y(terbit)));
      }
      // Nama alat paling menonjol: lebih besar dari nomor dan tanggal.
      double ukuran(Finder f) => tester.widget<Text>(f).style!.fontSize!;
      expect(ukuran(nama), greaterThan(ukuran(nomor)));
      expect(ukuran(nama), greaterThan(ukuran(terbit)));
      // `berlaku_sampai` tampil sebagai "Jadwal kalibrasi ulang <tanggal>"
      // (REVISI-2 butir 5), teks tersendiri yang lebih kecil dari tanggal
      // terbit (12-13), sesudah tanggal terbit dan sebelum badge. Kata
      // "Berlaku sampai" tidak dipakai (tertukar dengan status dokumen).
      expect(data.berlakuSampai, isNotNull);
      final jadwal = teks(
        'Jadwal kalibrasi ulang ${Format.tanggal(data.berlakuSampai)}',
      );
      expect(jadwal, findsOneWidget);
      expect(ukuran(jadwal), inInclusiveRange(12, 13));
      expect(ukuran(jadwal), lessThan(ukuran(terbit)));
      expect(
        find.descendant(of: baris, matching: find.textContaining('Berlaku')),
        findsNothing,
      );
      // Jadwal paling akhir: di bawah tanggal terbit DAN badge (badge sebaris
      // dengan terbit atau di bawahnya, tidak pernah menimpa jadwal).
      expect(y(jadwal), greaterThanOrEqualTo(tester.getBottomLeft(terbit).dy));
      expect(y(jadwal), greaterThanOrEqualTo(tester.getBottomLeft(badge).dy));

      // Tanpa nomor seri: barisnya tidak ada, bukan "SN null".
      final tanpa = _baris('CAL/2026/09/0003');
      expect(
        find.descendant(of: tanpa, matching: find.textContaining('SN ')),
        findsNothing,
      );
      expect(
        find.descendant(of: tanpa, matching: find.textContaining('Terbit')),
        findsOneWidget,
      );
    });

    testWidgets('jadwal kalibrasi ulang: hanya bila server mengirimnya; tanpa '
        'tanggal tidak ada teks kosong dan tidak ada baris ekstra; terbit '
        'tetap terpisah dan berlabel benar', (tester) async {
      await _buka(
        tester,
        _Layanan([
          _s(1, 'CAL/2026/09/0001', keputusan: null),
          _s(2, 'CAL/2026/09/0002', keputusan: null, berlakuSampai: null),
          _s(3, 'CAL/2026/09/0003', keputusan: null, diterbitkan: null),
        ]),
      );
      final ada = _baris('CAL/2026/09/0001');
      final tanpa = _baris('CAL/2026/09/0002');
      final tanpaTerbit = _baris('CAL/2026/09/0003');
      Finder teks(Finder b, String t) =>
          find.descendant(of: b, matching: find.text(t));
      Finder semuaTeks(Finder b) =>
          find.descendant(of: b, matching: find.byType(Text));
      BarisSertifikat data(Finder b) => tester.widget<BarisSertifikat>(b);

      final terbit =
          'Terbit ${Format.tanggal(data(ada).sertifikat.diterbitkan)}';
      final jadwal =
          'Jadwal kalibrasi ulang '
          '${Format.tanggal(data(ada).sertifikat.berlakuSampai)}';
      // Ada: dua teks TERPISAH (bukan satu kalimat), masing-masing utuh.
      expect(teks(ada, terbit), findsOneWidget);
      expect(teks(ada, jadwal), findsOneWidget);
      expect(
        find.descendant(of: ada, matching: find.textContaining('·')),
        findsNothing,
      );
      expect(data(ada).kalimat, contains('$terbit. $jadwal'));

      // Null: tidak ada teks "Jadwal", tidak ada teks kosong, dan tidak ada
      // baris ekstra di bawah tanggal terbit (isi kartu berakhir di situ).
      expect(
        find.descendant(of: tanpa, matching: find.textContaining('Jadwal')),
        findsNothing,
      );
      expect(data(tanpa).kalimat, isNot(contains('Jadwal')));
      for (final t in tester.widgetList<Text>(semuaTeks(tanpa))) {
        expect((t.data ?? t.textSpan?.toPlainText() ?? '').trim(), isNotEmpty);
      }
      double dasarKartu(Finder b) => tester
          .getRect(find.descendant(of: b, matching: find.byType(InkWell)))
          .bottom;
      expect(
        dasarKartu(tanpa) -
            tester
                .getRect(
                  teks(
                    tanpa,
                    'Terbit ${Format.tanggal(data(tanpa).sertifikat.diterbitkan)}',
                  ),
                )
                .bottom,
        closeTo(Spasi.lg, 0.01),
      );

      // Hanya jadwal (tanggal terbit tidak dikirim): tidak ada "Terbit" dan
      // tidak ada teks kosong sebagai gantinya.
      expect(data(tanpaTerbit).sertifikat.diterbitkan, isNull);
      expect(
        find.descendant(
          of: tanpaTerbit,
          matching: find.textContaining('Terbit'),
        ),
        findsNothing,
      );
      expect(
        teks(
          tanpaTerbit,
          'Jadwal kalibrasi ulang '
          '${Format.tanggal(data(tanpaTerbit).sertifikat.berlakuSampai)}',
        ),
        findsOneWidget,
      );
      expect(data(tanpaTerbit).kalimat, isNot(contains('Terbit')));
      for (final t in tester.widgetList<Text>(semuaTeks(tanpaTerbit))) {
        expect((t.data ?? t.textSpan?.toPlainText() ?? '').trim(), isNotEmpty);
      }
    });

    test('jadwal kalibrasi ulang hanya untuk sertifikat yang berlaku: yang '
        'dibatalkan atau digantikan sudah usang, jadi tidak disebut', () {
      String kalimat(String status) => BarisSertifikat(
        sertifikat: _s(1, 'CAL/2026/09/0001', status: status),
        onTap: () {},
      ).kalimat;

      expect(kalimat('berlaku'), contains('Jadwal kalibrasi ulang'));
      expect(kalimat('dibatalkan'), isNot(contains('Jadwal')));
      expect(kalimat('digantikan'), isNot(contains('Jadwal')));
      // Statusnya sendiri tetap disebut.
      expect(kalimat('dibatalkan'), contains('Status:'));
      expect(kalimat('digantikan'), contains('Status:'));
    });

    testWidgets('tata letak di lebar telepon: badge sebaris dengan terbit '
        'atau turun ke baris sendiri, jadwal selalu di bawahnya, tanpa '
        'tumpang tindih', (tester) async {
      final layanan = _Layanan([
        _s(1, 'CAL/2026/09/0001'),
        _s(2, 'CAL/2026/09/0002', keputusan: 'FAIL'),
      ]);
      final tinggi = <double, List<double>>{};
      for (final lebar in [360.0, 390.0, 412.0]) {
        await _buka(tester, layanan, lebar: lebar);
        for (final nomor in ['CAL/2026/09/0001', 'CAL/2026/09/0002']) {
          final b = _baris(nomor);
          Finder di(Finder f) => find.descendant(of: b, matching: f);
          final terbit = di(find.textContaining('Terbit'));
          final jadwal = di(find.textContaining('Jadwal kalibrasi ulang'));
          final badge = di(find.byType(Stempel));
          final alasan = 'lebar $lebar $nomor';
          final sebaris =
              (tester.getCenter(badge).dy - tester.getCenter(terbit).dy).abs() <
              4;
          if (sebaris) {
            expect(
              tester.getTopLeft(badge).dx,
              greaterThan(tester.getBottomRight(terbit).dx),
              reason: alasan,
            );
          } else {
            expect(
              tester.getTopLeft(badge).dy,
              greaterThanOrEqualTo(tester.getBottomLeft(terbit).dy),
              reason: alasan,
            );
          }
          expect(
            tester.getTopLeft(jadwal).dy,
            greaterThanOrEqualTo(tester.getBottomLeft(badge).dy),
            reason: alasan,
          );
          expect(
            tester.getTopLeft(jadwal).dy,
            greaterThanOrEqualTo(tester.getBottomLeft(terbit).dy),
            reason: alasan,
          );
          // Semua isi di dalam kartu.
          final kartu = tester.getRect(di(find.byType(InkWell)));
          for (final f in [terbit, jadwal, badge]) {
            expect(
              kartu.contains(tester.getRect(f).bottomRight),
              isTrue,
              reason: alasan,
            );
          }
          tinggi.putIfAbsent(lebar, () => []).add(tester.getSize(b).height);
        }
        expect(tester.takeException(), isNull);
      }
      // Lencana status kini lebih kecil (24 dp, 12/600): "Memenuhi toleransi"
      // masih muat di samping tanggal terbit sedangkan "Tidak memenuhi
      // toleransi" lebih lebar dan turun: tinggi baris mengikuti isi, FAIL
      // tidak pernah lebih pendek dari PASS.
      for (final h in tinggi.values) {
        expect(h[1], greaterThanOrEqualTo(h[0]));
      }
    });

    testWidgets('badge: PASS hijau, FAIL koral tidak dilunakkan, null tanpa '
        'badge (netral, tidak pernah hijau); warna hanya di badge', (
      tester,
    ) async {
      await _buka(tester, _Layanan(_semua()));
      final w = WarnaSidik.terang;

      final lulus = _baris('CAL/2026/09/0001');
      expect(_stempelDi(tester, lulus), ['Memenuhi toleransi']);
      expect(_latarStempel(tester, lulus), w.ubinLulus);

      final gagal = _baris('CAL/2026/09/0002');
      expect(_stempelDi(tester, gagal), ['Tidak memenuhi toleransi']);
      expect(_latarStempel(tester, gagal), w.ubinGagal);
      expect(
        find.descendant(
          of: gagal,
          matching: find.byIcon(Icons.cancel_outlined),
        ),
        findsOneWidget,
      );

      // Keputusan null: tidak ada badge sama sekali, jadi tidak ada yang hijau.
      final kosong = _baris('CAL/2026/09/0003');
      expect(_stempelDi(tester, kosong), isEmpty);
      expect(
        find.descendant(of: kosong, matching: find.byType(Stempel)),
        findsNothing,
      );

      // Permukaan semua baris sama (netral): warna tidak pindah ke kartu.
      final putih = Theme.of(tester.element(lulus)).colorScheme.surface;
      for (final b in [lulus, gagal, kosong]) {
        expect(_latarBaris(tester, b), putih);
      }

      // Dibatalkan: hanya statusnya, hasil teknis PASS lamanya tidak ikut.
      final batal = _baris('CAL/2026/07/0005');
      expect(_stempelDi(tester, batal), ['Dibatalkan']);
      expect(_latarStempel(tester, batal), w.ubinGagal);
      expect(_latarBaris(tester, batal), putih);
    });

    testWidgets('sakelar menyalakan yang digantikan: hasil teknis dan status '
        'dokumen sama-sama bersuara', (tester) async {
      final layanan = _Layanan(_semua());
      await _buka(tester, layanan);
      expect(_baris('CAL/2026/08/0004'), findsNothing);

      await tester.tap(_sakelar);
      await tester.pumpAndSettle();

      final baris = _baris('CAL/2026/08/0004');
      expect(baris, findsOneWidget);
      expect(_stempelDi(tester, baris), ['Memenuhi toleransi', 'Digantikan']);
      expect(_semuaBaris, findsNWidgets(5));
    });

    testWidgets('sakelar: kartu putih netral, tinggi >= 48, sudut 16', (
      tester,
    ) async {
      await _buka(tester, _Layanan(_semua()));
      final bahan = tester.widget<Material>(
        find.descendant(of: _sakelar, matching: find.byType(Material)).first,
      );
      expect(
        (bahan.shape! as RoundedRectangleBorder).borderRadius,
        Bentuk.sudutKontrol,
      );
      expect(
        bahan.color,
        Theme.of(tester.element(_sakelar)).colorScheme.surface,
      );
      final tinggi = tester.getSize(_sakelar).height;
      expect(tinggi, greaterThanOrEqualTo(AreaSentuh.minimum));
      expect(tinggi, lessThan(UkuranKontrol.segmenLuar + Spasi.lg));
    });
  });

  group('empat keadaan', () {
    testWidgets(
      'memuat: kerangka statis, tanpa gerak berulang dan tanpa angka',
      (tester) async {
        final semantik = tester.ensureSemantics();
        layarHp(tester, tinggi: 3200);
        final tahan = Completer<void>();
        final layanan = _Layanan(_semua())..tahan = tahan;
        await tester.pumpWidget(_app(layanan));
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.byType(KerangkaSertifikat), findsOneWidget);
        expect(find.byType(BarisKerangkaSertifikat), findsNWidgets(6));
        expect(_semuaBaris, findsNothing);
        expect(find.bySemanticsLabel('Memuat'), findsOneWidget);
        // Tidak ada animasi yang menjadwalkan frame terus-menerus (denyut lama
        // memakai `repeat`).
        await tester.pump(const Duration(milliseconds: 100));
        expect(tester.binding.hasScheduledFrame, isFalse);
        // Yang belum terbaca tidak tampil sebagai nol.
        expect(find.byType(PilJumlahSertifikat), findsNothing);
        expect(find.textContaining('0 sertifikat'), findsNothing);
        // Segmen, kolom cari, dan sakelar sudah ada selama memuat.
        expect(find.byType(SegmenPil), findsOneWidget);
        expect(find.byType(KolomCariUtuh), findsOneWidget);
        expect(_sakelar, findsOneWidget);
        // Kerangka berbentuk baris: kartu putih netral, bukan blok besar.
        final kerangka = find.byType(BarisKerangkaSertifikat).first;
        expect(tester.getSize(kerangka).height, lessThan(130));
        expect(
          _latarBaris(tester, kerangka),
          Theme.of(tester.element(kerangka)).colorScheme.surface,
        );

        tahan.complete();
        await tester.pumpAndSettle();
        expect(find.byType(KerangkaSertifikat), findsNothing);
        expect(_semuaBaris, findsNWidgets(4));
        semantik.dispose();
      },
    );

    testWidgets(
      'kosong: belum ada sertifikat, lalu hasil cari kosong (kata, ikon, dan '
      'filter aktif berbeda)',
      (tester) async {
        await _buka(tester, _Layanan(const []));

        final kosong = find.byType(PanelKosongSertifikat);
        expect(kosong, findsOneWidget);
        expect(find.text('Belum ada sertifikat'), findsOneWidget);
        expect(
          find.text(
            'Sertifikat muncul di sini begitu diterbitkan dan disahkan '
            'laboratorium.',
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: kosong,
            matching: find.byIcon(Icons.description_outlined),
          ),
          findsOneWidget,
        );
        expect(_semuaBaris, findsNothing);
        // Panel netral: putih, bukan bidang kuning; tanpa tombol hapus (tidak
        // ada pencarian yang bisa dihapus).
        expect(
          _latarBaris(tester, kosong),
          Theme.of(tester.element(kosong)).colorScheme.surface,
        );
        expect(find.text('Hapus pencarian'), findsNothing);
        expect(find.textContaining('Kata cari'), findsNothing);
        // "Belum ada sertifikat" bukan hasil cari: tidak ada filter yang bisa
        // dilepas, jadi tidak ada tawaran menampilkan yang digantikan.
        expect(
          find.text('Sertifikat yang sudah digantikan disembunyikan'),
          findsNothing,
        );
        expect(find.text('Tampilkan yang sudah digantikan'), findsNothing);
        // Nol yang TERBACA (daftar kosong dari server) boleh tampil.
        expect(_teksPil(tester), '0 sertifikat');

        // Hasil cari kosong: dikatakan "tidak cocok", bukan "belum ada", dengan
        // filter yang aktif.
        await _ketik(tester, 'zzz');
        expect(find.text('Tidak ada yang cocok'), findsOneWidget);
        expect(find.text('Belum ada sertifikat'), findsNothing);
        expect(
          find.text('Coba nomor atau nama alat yang lain.'),
          findsOneWidget,
        );
        expect(find.text('Kata cari: “zzz”'), findsOneWidget);
        expect(find.text('Termasuk yang sudah direvisi'), findsNothing);
        // Filter bawaan (sakelar mati) ikut disebut, dengan aksi melepasnya.
        expect(
          find.text('Sertifikat yang sudah digantikan disembunyikan'),
          findsOneWidget,
        );
        expect(find.text('Tampilkan yang sudah digantikan'), findsOneWidget);
        expect(
          find.descendant(
            of: find.byType(PanelKosongSertifikat),
            matching: find.byIcon(Icons.search_off_outlined),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: find.byType(PanelKosongSertifikat),
            matching: find.byIcon(Icons.description_outlined),
          ),
          findsNothing,
        );
        expect(find.text('Hapus pencarian'), findsOneWidget);

        // Sakelar menyala ikut disebut sebagai filter; filter bawaan dan
        // tawarannya hilang karena sudah tidak berlaku.
        await tester.tap(_sakelar);
        await tester.pumpAndSettle();
        expect(find.text('Termasuk yang sudah direvisi'), findsOneWidget);
        expect(
          find.text('Sertifikat yang sudah digantikan disembunyikan'),
          findsNothing,
        );
        expect(find.text('Tampilkan yang sudah digantikan'), findsNothing);
        expect(find.text('Hapus pencarian'), findsOneWidget);
      },
    );

    testWidgets('hasil cari kosong menyebut filter bawaan (yang digantikan '
        'disembunyikan) dan menawarkan menampilkannya', (tester) async {
      final layanan = _Layanan(_semua());
      await _buka(tester, layanan);

      // "manometer" hanya ada di sertifikat yang digantikan: tersembunyi oleh
      // filter bawaan, jadi panel menyebut KEDUA penyebab dan aksinya.
      await _ketik(tester, 'manometer');
      final panel = find.byType(PanelKosongSertifikat);
      expect(panel, findsOneWidget);
      expect(
        find.descendant(
          of: panel,
          matching: find.text('Kata cari: “manometer”'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: panel,
          matching: find.text('Sertifikat yang sudah digantikan disembunyikan'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(of: panel, matching: find.text('Hapus pencarian')),
        findsOneWidget,
      );
      expect(layanan.panggilan.last.digantikan, isFalse);

      // Aksi menyalakan sakelar: kata cari tetap, hasilnya muncul, filter
      // bawaan dan panel hilang.
      await tester.tap(find.text('Tampilkan yang sudah digantikan'));
      await tester.pumpAndSettle();
      expect(layanan.panggilan.last.digantikan, isTrue);
      expect(layanan.panggilan.last.cari, 'manometer');
      expect(tester.widget<BarisSakelar>(_sakelar).nilai, isTrue);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'manometer',
      );
      expect(panel, findsNothing);
      expect(
        find.text('Sertifikat yang sudah digantikan disembunyikan'),
        findsNothing,
      );
      expect(_nomorTampil(tester), ['CAL/2026/08/0004']);
    });

    testWidgets('hasil cari kosong dengan sakelar menyala: tanpa tawaran '
        'menampilkan yang digantikan', (tester) async {
      await _buka(tester, _Layanan(_semua()));
      await tester.tap(_sakelar);
      await tester.pumpAndSettle();
      await _ketik(tester, 'zzz');
      expect(find.byType(PanelKosongSertifikat), findsOneWidget);
      expect(find.text('Termasuk yang sudah direvisi'), findsOneWidget);
      expect(find.text('Tampilkan yang sudah digantikan'), findsNothing);
      expect(
        find.text('Sertifikat yang sudah digantikan disembunyikan'),
        findsNothing,
      );
    });

    testWidgets('hasil cari kosong: "Hapus pencarian" mengosongkan isian dan '
        'daftar kembali', (tester) async {
      final layanan = _Layanan(_semua());
      await _buka(tester, layanan);
      await _ketik(tester, 'zzz');
      expect(find.byType(PanelKosongSertifikat), findsOneWidget);

      await tester.tap(find.text('Hapus pencarian'));
      await tester.pumpAndSettle();

      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        isEmpty,
      );
      expect(layanan.panggilan.last.cari, '');
      expect(find.byType(PanelKosongSertifikat), findsNothing);
      expect(_semuaBaris, findsNWidgets(4));
      expect(_teksPil(tester), '4 sertifikat');
      // Kolom cari tetap bisa dipakai sesudahnya.
      await _ketik(tester, 'timbangan');
      expect(_nomorTampil(tester), ['CAL/2026/09/0002']);
    });

    testWidgets('galat: pesan server, Coba lagi; bagian gagal tidak terbaca '
        'nol', (tester) async {
      final layanan = _Layanan(_semua())
        // 4xx: provider sertifikat tidak mengulang otomatis (`_ulangiBilaMungkin`),
        // jadi galat langsung tampil; 5xx dan jaringan diulang dengan jeda.
        ..galat = const GalatApi(
          status: 429,
          pesan: 'Terlalu banyak permintaan. Coba lagi sebentar lagi.',
        );
      await _buka(tester, layanan);

      expect(find.byType(KeadaanGalat), findsOneWidget);
      expect(
        find.text('Terlalu banyak permintaan. Coba lagi sebentar lagi.'),
        findsOneWidget,
      );
      expect(_semuaBaris, findsNothing);
      expect(find.byType(PanelKosongSertifikat), findsNothing);
      expect(find.byType(PilJumlahSertifikat), findsNothing);
      // Kolom cari dan sakelar tetap ada, supaya kata cari bisa diubah.
      expect(find.byType(KolomCariUtuh), findsOneWidget);
      expect(_sakelar, findsOneWidget);

      final sebelum = layanan.panggilan.length;
      layanan.galat = null;
      await tester.tap(find.text('Coba lagi'));
      await tester.pumpAndSettle();
      expect(layanan.panggilan.length, sebelum + 1);
      expect(find.byType(KeadaanGalat), findsNothing);
      expect(_semuaBaris, findsNWidgets(4));
      expect(_teksPil(tester), '4 sertifikat');
    });

    testWidgets('tanpa koneksi: catatan di atas daftar yang tersimpan', (
      tester,
    ) async {
      final semantik = tester.ensureSemantics();
      await _buka(tester, _Layanan(_semua()));
      final koneksi = ProviderScope.containerOf(
        tester.element(find.byType(SertifikatScreen)),
      ).read(koneksiProvider.notifier);
      expect(find.byType(CatatanLuring), findsNothing);

      // Offline tanpa waktu data terakhir: tidak ada klaim "terakhir diperbarui".
      koneksi.offline(null);
      await tester.pump();
      expect(find.byType(CatatanLuring), findsNothing);

      final waktu = DateTime(2026, 11, 12, 8, 12);
      koneksi.offline(waktu);
      await tester.pump();
      final teks =
          'Tanpa koneksi. Terakhir diperbarui ${Format.jamAtauTanggal(waktu)}';
      expect(find.byType(CatatanLuring), findsOneWidget);
      expect(find.text(teks), findsOneWidget);
      expect(teks, contains('08.12'));
      expect(find.bySemanticsLabel(teks), findsOneWidget);
      // Daftar yang tersimpan tetap tampil, di bawah catatan.
      expect(_semuaBaris, findsNWidgets(4));
      expect(
        tester.getTopLeft(find.byType(CatatanLuring)).dy,
        lessThan(tester.getTopLeft(_semuaBaris.first).dy),
      );

      koneksi.online();
      await tester.pump();
      expect(find.byType(CatatanLuring), findsNothing);
      semantik.dispose();
    });

    testWidgets('tanpa koneksi dan daftar kosong: catatan tetap di atas panel '
        'kosong', (tester) async {
      await _buka(tester, _Layanan(const []));
      final koneksi = ProviderScope.containerOf(
        tester.element(find.byType(SertifikatScreen)),
      ).read(koneksiProvider.notifier);
      koneksi.offline(DateTime(2026, 11, 12, 8, 12));
      await tester.pump();
      expect(find.byType(CatatanLuring), findsOneWidget);
      expect(
        tester.getTopLeft(find.byType(CatatanLuring)).dy,
        lessThan(tester.getTopLeft(find.byType(PanelKosongSertifikat)).dy),
      );
    });
  });

  group('jumlah di layar hanya dari data yang terbaca', () {
    testWidgets('pil = daftar yang tampil; ikut sakelar dan kata cari', (
      tester,
    ) async {
      await _buka(tester, _Layanan(_semua()));
      expect(_teksPil(tester), '4 sertifikat');
      expect(_semuaBaris, findsNWidgets(4));

      await tester.tap(_sakelar);
      await tester.pumpAndSettle();
      expect(_teksPil(tester), '5 sertifikat');
      expect(_semuaBaris, findsNWidgets(5));

      await _ketik(tester, 'timbangan');
      expect(_teksPil(tester), '1 sertifikat');
      expect(_semuaBaris, findsNWidgets(1));
    });

    testWidgets('pil dan daftar memakai provider yang sama: satu permintaan '
        'untuk satu kunci', (tester) async {
      final layanan = _Layanan(_semua());
      await _buka(tester, layanan);
      expect(layanan.panggilan, hasLength(1));
      expect(layanan.panggilan.single.halaman, 1);
      expect(layanan.panggilan.single.digantikan, isFalse);
    });

    testWidgets('pil hanya di tab Daftar, tidak di Arsip', (tester) async {
      await _buka(tester, _Layanan(_semua()));
      expect(_teksPil(tester), '4 sertifikat');

      await _pilihSegmen(tester, 'Arsip');
      expect(find.byType(PilJumlahSertifikat), findsNothing);

      await _pilihSegmen(tester, 'Daftar');
      expect(_teksPil(tester), '4 sertifikat');
    });

    testWidgets('paginasi tidak berubah: total server diklaim, halaman '
        'berikut saat ujung terlihat', (tester) async {
      final layanan = _Layanan([
        for (var i = 1; i <= 45; i++)
          _s(i, 'CAL/2026/10/${'$i'.padLeft(4, '0')}'),
      ]);
      await _buka(tester, layanan, tinggi: 800);

      // Halaman 1 dari 3: total server (45) yang diklaim, bukan 20 yang termuat.
      expect(layanan.halamanTerakhirDiminta, 1);
      expect(_teksPil(tester), '45 sertifikat');
      expect(find.byType(UjungDaftarSertifikat), findsNothing);

      // Digulir ke ujung: pemuat statis dan halaman berikutnya diminta.
      layanan.tahan = Completer<void>();
      final gulir = find.descendant(
        of: find.byType(DaftarBarisSertifikat),
        matching: find.byType(Scrollable),
      );
      await tester.fling(gulir, const Offset(0, -9000), 9000);
      await tester.pumpAndSettle();
      expect(find.byType(UjungDaftarSertifikat), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(UjungDaftarSertifikat),
          matching: find.byType(BarisKerangkaSertifikat),
        ),
        findsOneWidget,
      );
      expect(layanan.halamanTerakhirDiminta, 2);
      expect(tester.binding.hasScheduledFrame, isFalse);

      layanan.tahan!.complete();
      layanan.tahan = null;
      await tester.pumpAndSettle();
      for (var i = 0; i < 12; i++) {
        await tester.fling(gulir, const Offset(0, -9000), 9000);
        await tester.pumpAndSettle();
        if (find
            .text('Semua 45 sertifikat sudah tampil.')
            .evaluate()
            .isNotEmpty) {
          break;
        }
      }
      expect(find.text('Semua 45 sertifikat sudah tampil.'), findsOneWidget);
      expect(layanan.halamanTerakhirDiminta, 3);
      expect(_teksPil(tester), '45 sertifikat');
    });

    testWidgets('total server tidak bisa dipercaya: tidak ada klaim jumlah', (
      tester,
    ) async {
      // Server melaporkan total sebesar satu halaman padahal masih ada halaman
      // berikut: pil tidak boleh menyebut "20".
      final layanan = _Layanan([
        for (var i = 1; i <= 30; i++)
          _s(i, 'CAL/2026/10/${'$i'.padLeft(4, '0')}'),
      ])..totalLapor = 20;
      await _buka(tester, layanan, tinggi: 800);
      expect(find.byType(PilJumlahSertifikat), findsNothing);
      expect(_teksPil(tester), isNull);
      // Daftarnya sendiri tetap tampil.
      expect(_semuaBaris, findsWidgets);
    });

    testWidgets('penutup memakai angka yang sama dengan pil: yang sungguh '
        'termuat, bukan total mentah server', (tester) async {
      // Server melaporkan total 20, padahal ada 30 sertifikat (dua halaman).
      final layanan = _Layanan([
        for (var i = 1; i <= 30; i++)
          _s(i, 'CAL/2026/10/${'$i'.padLeft(4, '0')}'),
      ])..totalLapor = 20;
      await _buka(tester, layanan, tinggi: 800);
      final gulir = find.descendant(
        of: find.byType(DaftarBarisSertifikat),
        matching: find.byType(Scrollable),
      );
      for (var i = 0; i < 12; i++) {
        await tester.fling(gulir, const Offset(0, -9000), 9000);
        await tester.pumpAndSettle();
        if (find.textContaining('sudah tampil').evaluate().isNotEmpty) break;
      }
      expect(layanan.halamanTerakhirDiminta, 2);
      expect(find.text('Semua 30 sertifikat sudah tampil.'), findsOneWidget);
      expect(find.textContaining('Semua 20'), findsNothing);
      // Satu definisi: pil dan penutup menyebut angka yang sama.
      expect(_teksPil(tester), '30 sertifikat');
    });

    test('jumlahSertifikatTerbaca: selesai, total sah, total tak sah', () {
      final tiga = [for (var i = 1; i <= 3; i++) _s(i, 'N$i')];
      expect(
        jumlahSertifikatTerbaca(
          DataBerhalaman<Sertifikat>(isi: tiga, halaman: 1, halamanTerakhir: 1),
        ),
        3,
      );
      expect(
        jumlahSertifikatTerbaca(
          DataBerhalaman<Sertifikat>(
            isi: tiga,
            halaman: 1,
            halamanTerakhir: 2,
            total: 25,
          ),
        ),
        25,
      );
      expect(
        jumlahSertifikatTerbaca(
          DataBerhalaman<Sertifikat>(
            isi: tiga,
            halaman: 1,
            halamanTerakhir: 2,
            total: 3,
          ),
        ),
        isNull,
      );
    });

    testWidgets('tarik-segarkan memuat ulang daftar dan pil dengan SATU '
        'permintaan; galat tarik tidak jadi galat tak tertangkap', (
      tester,
    ) async {
      final layanan = _Layanan(_semua());
      // Layar pendek: ambang tarik RefreshIndicator = seperempat tinggi layar.
      layarHp(tester, tinggi: 900);
      await tester.pumpWidget(_app(layanan));
      await tester.pumpAndSettle();
      expect(_teksPil(tester), '4 sertifikat');
      expect(layanan.panggilan, hasLength(1));

      // Yang baru terbit ada di urutan teratas (baris lebih tinggi sejak
      // jadwal kalibrasi ulang tampil, jadi yang di ujung bawah tak terbangun
      // di layar 900 dp).
      layanan.isi = [
        _s(6, 'CAL/2026/11/0006', nama: 'Mikrometer'),
        ...layanan.isi,
      ];
      Future<void> tarik() async {
        await tester.fling(
          find
              .descendant(
                of: find.byType(RefreshIndicator),
                matching: find.byType(ListView),
              )
              .first,
          const Offset(0, 400),
          1000,
        );
        await tester.pumpAndSettle();
      }

      await tarik();
      expect(layanan.panggilan, hasLength(2));
      expect(_baris('CAL/2026/11/0006'), findsOneWidget);
      expect(_teksPil(tester), '5 sertifikat');

      layanan.galat = const GalatApi(status: 403, pesan: 'Akses ditolak.');
      await tarik();
      expect(tester.takeException(), isNull);
      expect(find.byType(KeadaanGalat), findsOneWidget);
      expect(find.byType(PilJumlahSertifikat), findsNothing);
    });
  });

  group('cari, sakelar, dan tab tetap memakai provider yang sama', () {
    testWidgets('kata cari dikirim sekali, 350 ms sesudah ketikan terakhir', (
      tester,
    ) async {
      final layanan = _Layanan(_semua());
      await _buka(tester, layanan);
      expect(KolomCariUtuh.jeda, const Duration(milliseconds: 350));

      await tester.enterText(find.byType(TextField), '0002');
      await tester.pump(const Duration(milliseconds: 200));
      expect(layanan.panggilan.last.cari, '');
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();

      expect(layanan.panggilan.last.cari, '0002');
      expect(layanan.panggilan.last.halaman, 1);
      expect(_nomorTampil(tester), ['CAL/2026/09/0002']);
    });

    testWidgets('sakelar mengirim termasuk_digantikan dan kata cari ikut', (
      tester,
    ) async {
      final layanan = _Layanan(_semua());
      await _buka(tester, layanan);

      await _ketik(tester, 'manometer');
      expect(_semuaBaris, findsNothing);
      expect(find.text('Tidak ada yang cocok'), findsOneWidget);

      await tester.tap(_sakelar);
      await tester.pumpAndSettle();
      expect(layanan.panggilan.last.digantikan, isTrue);
      expect(layanan.panggilan.last.cari, 'manometer');
      expect(_nomorTampil(tester), ['CAL/2026/08/0004']);

      await tester.tap(_sakelar);
      await tester.pumpAndSettle();
      expect(layanan.panggilan.last.digantikan, isFalse);
      expect(_semuaBaris, findsNothing);
    });

    testWidgets('kata cari dan sakelar bertahan waktu berpindah ke Arsip dan '
        'kembali, dan waktu kembali dari detail', (tester) async {
      final layanan = _Layanan(_semua());
      await _buka(tester, layanan);
      await _ketik(tester, 'ab');
      await tester.tap(_sakelar);
      await tester.pumpAndSettle();
      final permintaan = layanan.panggilan.length;

      await _pilihSegmen(tester, 'Arsip');
      await _pilihSegmen(tester, 'Daftar');

      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'ab',
      );
      expect(tester.widget<BarisSakelar>(_sakelar).nilai, isTrue);
      expect(layanan.panggilan.length, permintaan);

      // Dari detail kembali ke daftar yang sama: kata cari masih ada.
      await _ketik(tester, '0001');
      expect(_nomorTampil(tester), ['CAL/2026/09/0001']);
      await tester.tap(_semuaBaris.first);
      await tester.pumpAndSettle();
      expect(find.byType(SertifikatDetailScreen), findsOneWidget);
      Navigator.of(tester.element(find.byType(SertifikatDetailScreen))).pop();
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        '0001',
      );
      expect(_nomorTampil(tester), ['CAL/2026/09/0001']);
    });
  });

  group('ketuk baris', () {
    testWidgets('baris kedua dan terakhir membuka sertifikat yang diketuk', (
      tester,
    ) async {
      await _buka(tester, _Layanan(_semua()));
      // Urutan server: 1, 2, 3, 5 (4 digantikan, disembunyikan).
      final id = tester
          .widgetList<BarisSertifikat>(_semuaBaris)
          .map((u) => u.sertifikat.id)
          .toList();
      expect(id, [1, 2, 3, 5]);

      int idDetail() => tester
          .widget<SertifikatDetailScreen>(find.byType(SertifikatDetailScreen))
          .id;
      Future<void> kembali() async {
        Navigator.of(tester.element(find.byType(SertifikatDetailScreen))).pop();
        await tester.pumpAndSettle();
        expect(find.byType(SertifikatDetailScreen), findsNothing);
      }

      await tester.tap(_semuaBaris.at(1));
      await tester.pumpAndSettle();
      expect(idDetail(), 2);
      await kembali();

      await tester.tap(_semuaBaris.last);
      await tester.pumpAndSettle();
      expect(idDetail(), 5);
    });

    testWidgets('seluruh permukaan baris menerima ketukan (tepi dan sudut)', (
      tester,
    ) async {
      await _buka(tester, _Layanan(_semua()));
      final r = tester.getRect(_semuaBaris.at(1));
      // Dekat sudut kiri bawah baris kedua: masih di dalam kartu.
      await tester.tapAt(r.bottomLeft + const Offset(8, -8));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<SertifikatDetailScreen>(find.byType(SertifikatDetailScreen))
            .id,
        2,
      );
    });
  });

  group('gerak, huruf besar, tema gelap', () {
    testWidgets('baris tidak punya animasi masuk: langsung tampil penuh', (
      tester,
    ) async {
      layarHp(tester, tinggi: 3200);
      await tester.pumpWidget(_app(_Layanan(_semua())));
      for (var i = 0; i < 300; i++) {
        if (_semuaBaris.evaluate().isNotEmpty) break;
        await tester.pump(const Duration(milliseconds: 10));
      }
      expect(_semuaBaris, findsWidgets);
      expect(
        find.descendant(
          of: _semuaBaris.first,
          matching: find.byType(FadeTransition),
        ),
        findsNothing,
      );
    });

    Finder tombolSakelar() => find.descendant(
      of: _sakelar,
      matching: find.byWidgetPredicate(
        (w) =>
            w is SizedBox &&
            w.width == UkuranKontrol.sakelarTombol &&
            w.height == UkuranKontrol.sakelarTombol,
      ),
    );

    Finder relSakelar() =>
        find.descendant(of: _sakelar, matching: find.byType(AnimatedContainer));

    testWidgets('sakelar: tombol bergeser 120 ms dan belum sampai di frame '
        'pertama', (tester) async {
      await _buka(tester, _Layanan(_semua()));
      final awal = tester.getCenter(tombolSakelar()).dx;

      await tester.tap(_sakelar);
      await tester.pump();
      // Frame pertama sesudah ketukan: animasi baru mulai.
      expect(tester.getCenter(tombolSakelar()).dx, closeTo(awal, 1));
      await tester.pump(const Duration(milliseconds: 60));
      final tengah = tester.getCenter(tombolSakelar()).dx;
      expect(tengah, greaterThan(awal + 1));
      await tester.pumpAndSettle();
      expect(tester.getCenter(tombolSakelar()).dx, greaterThan(tengah));
    });

    testWidgets('kurangi gerak: tombol sakelar langsung di ujung', (
      tester,
    ) async {
      _kurangiGerak(tester);
      await _buka(tester, _Layanan(_semua()));
      final rel = tester.getRect(relSakelar());
      final awal = tester.getCenter(tombolSakelar()).dx;
      // Mati: tombol di ujung awal rel (padding 4 + setengah tombol 14).
      expect(awal, closeTo(rel.left + 4 + 14, 1));

      await tester.tap(_sakelar);
      await tester.pump();
      expect(
        tester.getCenter(tombolSakelar()).dx,
        closeTo(rel.right - 4 - 14, 1),
      );
      expect(tester.widget<BarisSakelar>(_sakelar).nilai, isTrue);
    });

    testWidgets('sakelar: ukuran rel 56 x 36, tombol 28, warna dari tema', (
      tester,
    ) async {
      await _buka(tester, _Layanan(_semua()));
      final tema = TemaSidik.terang.switchTheme;
      Color rel() =>
          (tester.widget<AnimatedContainer>(relSakelar()).decoration!
                  as BoxDecoration)
              .color!;
      Color tombol() =>
          (tester
                      .widget<DecoratedBox>(
                        find.descendant(
                          of: tombolSakelar(),
                          matching: find.byType(DecoratedBox),
                        ),
                      )
                      .decoration
                  as BoxDecoration)
              .color!;

      expect(tester.getSize(relSakelar()), const Size(56, 36));
      expect(tester.getSize(tombolSakelar()), const Size(28, 28));
      expect(rel(), tema.trackColor!.resolve({}));
      expect(tombol(), tema.thumbColor!.resolve({}));
      expect(
        find.descendant(
          of: tombolSakelar(),
          matching: find.byIcon(Icons.check),
        ),
        findsNothing,
      );

      await tester.tap(_sakelar);
      await tester.pumpAndSettle();
      expect(rel(), tema.trackColor!.resolve({WidgetState.selected}));
      expect(tombol(), tema.thumbColor!.resolve({WidgetState.selected}));
      // Keadaan nyala tidak hanya warna: ada centang di tombol.
      expect(
        find.descendant(
          of: tombolSakelar(),
          matching: find.byIcon(Icons.check),
        ),
        findsOneWidget,
      );
      expect(rel(), isNot(tema.trackColor!.resolve({})));
    });

    testWidgets('320 dp dengan huruf 1,3x: tanpa luapan, badge utuh di dalam '
        'baris', (tester) async {
      final layanan = _Layanan([
        _s(
          1,
          'CAL/2026/09/0001',
          nama: 'Digital Pressure Calibrator Multifungsi Presisi Tinggi 2271A',
          serial: 'FLK-2271A-0000000001',
          keputusan: 'FAIL',
          status: 'digantikan',
        ),
        _s(2, 'CAL/2026/09/0002', nama: 'Timbangan'),
      ]);
      await _buka(tester, layanan, skala: 1.3, lebar: 320, tinggi: 1800);
      // Sakelar revisi dinyalakan supaya yang digantikan ikut tampil.
      await tester.tap(_sakelar);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // Judul utuh (tidak dipotong "...") dan pil jumlah utuh di kanannya.
      final judul = tester.renderObject<RenderParagraph>(
        find.text('Sertifikat').first,
      );
      expect(judul.didExceedMaxLines, isFalse);
      final pil = tester.getRect(
        find
            .descendant(
              of: find.byType(PilJumlahSertifikat),
              matching: find.byType(Material),
            )
            .first,
      );
      expect(pil.right, lessThanOrEqualTo(320 - Spasi.sisi + 0.5));
      expect(
        tester.getRect(find.text('Sertifikat').first).right,
        lessThanOrEqualTo(pil.left),
      );
      expect(_teksPil(tester), '2 sertifikat');

      // Dua badge dan nomor di dalam baris, tidak keluar batas.
      final baris = tester.getRect(_baris('CAL/2026/09/0001'));
      expect(baris.height, greaterThanOrEqualTo(AreaSentuh.minimum));
      final badge = find.descendant(
        of: _baris('CAL/2026/09/0001'),
        matching: find.byType(Stempel),
      );
      expect(badge, findsNWidgets(2));
      for (var i = 0; i < 2; i++) {
        final r = tester.getRect(badge.at(i));
        expect(r.left, greaterThanOrEqualTo(baris.left));
        expect(r.right, lessThanOrEqualTo(baris.right));
        expect(r.top, greaterThanOrEqualTo(baris.top));
        expect(r.bottom, lessThanOrEqualTo(baris.bottom));
      }
      // Nomor utuh di satu baris (tidak putus di tengah).
      final nomor = tester.getRect(
        find.descendant(
          of: _baris('CAL/2026/09/0001'),
          matching: find.text('CAL/2026/09/0001'),
        ),
      );
      expect(nomor.right, lessThanOrEqualTo(baris.right));
      expect(nomor.height, lessThan(30));
      // Nama alat panjang dipotong di dua baris, tidak meluap.
      final nama = tester.widget<Text>(
        find.descendant(
          of: _baris('CAL/2026/09/0001'),
          matching: find.textContaining('Digital Pressure'),
        ),
      );
      expect(nama.maxLines, 2);

      // Sasaran sentuh 48 dp: segmen dan sakelar.
      expect(
        tester.getSize(find.byType(SegmenPil)).height,
        greaterThanOrEqualTo(AreaSentuh.minimum),
      );
      expect(
        tester.getSize(_sakelar).height,
        greaterThanOrEqualTo(AreaSentuh.minimum),
      );
    });

    testWidgets('320 dp dengan huruf 1,3x: kosong, hasil cari kosong, dan '
        'memuat tanpa luapan', (tester) async {
      await _buka(
        tester,
        _Layanan(const []),
        skala: 1.3,
        lebar: 320,
        tinggi: 1400,
      );
      expect(tester.takeException(), isNull);
      expect(find.byType(PanelKosongSertifikat), findsOneWidget);
      await _ketik(tester, 'zzz');
      expect(tester.takeException(), isNull);
      expect(find.text('Hapus pencarian'), findsOneWidget);
      // Dua aksi dan filter bawaan membungkus rapi: semuanya di dalam kartu.
      expect(find.text('Tampilkan yang sudah digantikan'), findsOneWidget);
      expect(
        find.text('Sertifikat yang sudah digantikan disembunyikan'),
        findsOneWidget,
      );
      final panel = tester.getRect(find.byType(PanelKosongSertifikat));
      for (final t in [
        'Hapus pencarian',
        'Tampilkan yang sudah digantikan',
        'Sertifikat yang sudah digantikan disembunyikan',
      ]) {
        final r = tester.getRect(find.text(t));
        expect(r.left, greaterThanOrEqualTo(panel.left), reason: t);
        expect(r.right, lessThanOrEqualTo(panel.right), reason: t);
      }
      for (final t in ['Hapus pencarian', 'Tampilkan yang sudah digantikan']) {
        final tombol = find.ancestor(
          of: find.text(t),
          matching: find.byType(TombolSidik),
        );
        expect(
          tester.getSize(tombol).height,
          greaterThanOrEqualTo(AreaSentuh.minimum),
          reason: t,
        );
      }

      layarHp(tester, lebar: 320, tinggi: 1400);
      final tahan = Completer<void>();
      await tester.pumpWidget(
        _app(_Layanan(_semua())..tahan = tahan, skala: 1.3),
      );
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(KerangkaSertifikat), findsOneWidget);
      expect(tester.takeException(), isNull);
      tahan.complete();
      await tester.pumpAndSettle();
    });

    testWidgets('tema gelap: baris dan panel memakai permukaan tema, badge '
        'mengikuti tema (latar gelap bernada status), tanpa luapan', (
      tester,
    ) async {
      await _buka(tester, _Layanan(_semua()), gelap: true);
      expect(tester.takeException(), isNull);
      final w = WarnaSidik.gelap;
      final gelap = TemaSidik.gelap.colorScheme;
      expect(_latarBaris(tester, _baris('CAL/2026/09/0001')), gelap.surface);
      expect(_latarStempel(tester, _baris('CAL/2026/09/0001')), w.lulusLatar);
      expect(_latarStempel(tester, _baris('CAL/2026/09/0002')), w.gagalLatar);

      await _buka(tester, _Layanan(const []), gelap: true);
      expect(
        _latarBaris(tester, find.byType(PanelKosongSertifikat)),
        gelap.surface,
      );
    });
  });

  group('Semantics dan sasaran sentuh', () {
    testWidgets('judul, segmen, sakelar, dan baris satu tombol berkalimat', (
      tester,
    ) async {
      final semantik = tester.ensureSemantics();
      await _buka(tester, _Layanan(_semua()));

      expect(find.bySemanticsLabel('Tampilan sertifikat'), findsOneWidget);
      bool? terpilih(String label) => tester
          .getSemantics(find.bySemanticsLabel(label))
          .getSemanticsData()
          .flagsCollection
          .isSelected
          .toBoolOrNull();
      expect(terpilih('Daftar'), isTrue);
      expect(terpilih('Arsip'), isFalse);

      // Sakelar: satu simpul berlabel dengan keadaan nyala/mati.
      const label = 'Tampilkan juga yang sudah direvisi';
      bool? nyala() => tester
          .getSemantics(find.bySemanticsLabel(label))
          .getSemanticsData()
          .flagsCollection
          .isToggled
          .toBoolOrNull();
      expect(nyala(), isFalse);
      tester.semantics.tap(find.semantics.byLabel(label));
      await tester.pumpAndSettle();
      expect(nyala(), isTrue);
      expect(_baris('CAL/2026/08/0004'), findsOneWidget);
      tester.semantics.tap(find.semantics.byLabel(label));
      await tester.pumpAndSettle();
      expect(nyala(), isFalse);

      // Baris: SATU simpul, urutan sama dengan tampilan (alat, nomor, seri,
      // terbit, status, jadwal kalibrasi ulang).
      final kalimat = tester
          .getSemantics(
            find.bySemanticsLabel(RegExp('Sertifikat CAL/2026/09/0002')),
          )
          .getSemanticsData()
          .label;
      final data = tester
          .widget<BarisSertifikat>(_baris('CAL/2026/09/0002'))
          .sertifikat;
      expect(
        kalimat,
        'Timbangan Analitik. Sertifikat CAL/2026/09/0002. '
        'Nomor seri TA-224. Terbit ${Format.tanggal(data.diterbitkan)}. '
        'Status: Tidak memenuhi toleransi. '
        'Jadwal kalibrasi ulang ${Format.tanggal(data.berlakuSampai)}',
      );
      // Nomor serinya saja: "SN" hanya di layar.
      expect(kalimat, isNot(contains('SN')));

      // Baris bisa diaktifkan lewat pembaca layar.
      tester.semantics.tap(
        find.semantics.byLabel(RegExp('Sertifikat CAL/2026/09/0002')),
      );
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<SertifikatDetailScreen>(find.byType(SertifikatDetailScreen))
            .id,
        2,
      );
      semantik.dispose();
    });

    testWidgets('kalimat baris: keputusan null tidak mengaku apa pun; yang '
        'dibatalkan tidak membawa hasil teknis', (tester) async {
      final semantik = tester.ensureSemantics();
      await _buka(tester, _Layanan(_semua()));
      String kalimat(String nomor) => tester
          .getSemantics(find.bySemanticsLabel(RegExp('Sertifikat $nomor')))
          .getSemanticsData()
          .label;

      expect(kalimat('CAL/2026/09/0003'), isNot(contains('Status')));
      expect(kalimat('CAL/2026/09/0003'), isNot(contains('toleransi')));
      expect(kalimat('CAL/2026/07/0005'), contains('Status: Dibatalkan'));
      expect(kalimat('CAL/2026/07/0005'), isNot(contains('toleransi')));
      semantik.dispose();
    });

    testWidgets('pedoman Flutter: sasaran sentuh 48 dp dan semua berlabel', (
      tester,
    ) async {
      final semantik = tester.ensureSemantics();
      layarHp(tester, lebar: 390, tinggi: 3200);
      await tester.pumpWidget(_app(_Layanan(_semua())));
      await tester.pumpAndSettle();
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      semantik.dispose();
    });

    testWidgets('keadaan kosong dan hasil cari kosong memberi pedoman yang '
        'sama; judul panel terbaca sebagai judul', (tester) async {
      final semantik = tester.ensureSemantics();
      layarHp(tester, lebar: 390, tinggi: 1400);
      await tester.pumpWidget(_app(_Layanan(const [])));
      await tester.pumpAndSettle();
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      expect(
        tester
            .getSemantics(find.text('Belum ada sertifikat'))
            .getSemanticsData()
            .flagsCollection
            .isHeader,
        isTrue,
      );

      await _ketik(tester, 'zzz');
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      for (final t in ['Hapus pencarian', 'Tampilkan yang sudah digantikan']) {
        expect(
          tester
              .getSemantics(find.text(t))
              .getSemanticsData()
              .flagsCollection
              .isButton,
          isTrue,
          reason: t,
        );
      }
      semantik.dispose();
    });
  });

  group('papan ketik', () {
    testWidgets('sakelar: Tab memfokuskan, cincin di luar kartu, Enter dan '
        'Spasi membalik', (tester) async {
      var nilai = false;
      layarHp(tester, tinggi: 600);
      await tester.pumpWidget(
        MaterialApp(
          theme: TemaSidik.terang,
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => BarisSakelar(
                label: 'Tampilkan juga yang sudah direvisi',
                nilai: nilai,
                onUbah: (v) => setState(() => nilai = v),
              ),
            ),
          ),
        ),
      );
      FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.alwaysTraditional;
      addTearDown(
        () => FocusManager.instance.highlightStrategy =
            FocusHighlightStrategy.automatic,
      );
      expect(find.byKey(CincinFokus.kunciCincin), findsNothing);

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(find.byKey(CincinFokus.kunciCincin), findsOneWidget);
      // Cincin lebih besar dari kartu di semua sisi (di luar isi).
      final kartu = tester.getRect(
        find.descendant(
          of: find.byType(BarisSakelar),
          matching: find.byType(InkWell),
        ),
      );
      final cincin = tester.getRect(find.byKey(CincinFokus.kunciCincin));
      expect(cincin.left, lessThan(kartu.left));
      expect(cincin.right, greaterThan(kartu.right));
      expect(cincin.top, lessThan(kartu.top));
      expect(cincin.bottom, greaterThan(kartu.bottom));

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(nilai, isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      expect(nilai, isFalse);
    });

    testWidgets('baris sertifikat: Tab memfokuskan dengan cincin di luar '
        'kartu, Enter membuka detail', (tester) async {
      layarHp(tester, tinggi: 1400);
      await tester.pumpWidget(_app(_Layanan(_semua())));
      await tester.pumpAndSettle();
      FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.alwaysTraditional;
      addTearDown(
        () => FocusManager.instance.highlightStrategy =
            FocusHighlightStrategy.automatic,
      );
      // Tab berjalan: segmen, kolom cari, tombol cari, sakelar, baru baris
      // pertama. Berhenti begitu cincin fokus muncul di baris itu.
      final cincin = find.descendant(
        of: _semuaBaris.first,
        matching: find.byKey(CincinFokus.kunciCincin),
      );
      for (var i = 0; i < 15 && cincin.evaluate().isEmpty; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
      }
      expect(cincin, findsOneWidget);
      final kartu = tester.getRect(_semuaBaris.first);
      final tepi = tester.getRect(cincin);
      expect(tepi.left, lessThan(kartu.left));
      expect(tepi.top, lessThan(kartu.top));

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(find.byType(SertifikatDetailScreen), findsOneWidget);
      expect(
        tester
            .widget<SertifikatDetailScreen>(find.byType(SertifikatDetailScreen))
            .id,
        1,
      );
    });
  });

  group('layar lebar', () {
    testWidgets('isi dipusatkan dan dibatasi 720 dp', (tester) async {
      await _buka(tester, _Layanan(_semua()), lebar: 1200, tinggi: 3200);
      final baris = tester.getRect(_baris('CAL/2026/09/0001'));
      expect(baris.width, lessThanOrEqualTo(Spasi.lebarKonten));
      expect(baris.center.dx, closeTo(600, 1));
      expect(tester.takeException(), isNull);
    });
  });
}
