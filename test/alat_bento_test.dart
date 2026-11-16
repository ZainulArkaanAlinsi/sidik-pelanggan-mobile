// Layar 02 "Alat saya" Bento Lab (P5b): kolom cari pil, saringan pil, ubin alat
// berwarna status, dan empat keadaan (memuat statis, kosong, galat, tanpa
// koneksi). Yang dijaga: susunan dari token, jumlah di layar hanya dari data
// yang terbaca (memuat/gagal bukan "0"), pencarian/saringan/paginasi tetap
// memakai provider dan kunci yang sama, kerangka tanpa gerak berulang,
// "kurangi gerak", huruf 1,3x di 320 dp, Semantics, sasaran sentuh, dan baris
// saringan yang bisa digeser dengan mouse di layar lebar.
//
// Perilaku cari/saring/paginasi lama dijaga `alat_status_riwayat_test.dart`.
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sidik_pelanggan/core/format.dart';
import 'package:sidik_pelanggan/core/tema/bentuk.dart';
import 'package:sidik_pelanggan/core/tema/spasi.dart';
import 'package:sidik_pelanggan/core/tema/tema_sidik.dart';
import 'package:sidik_pelanggan/core/tema/ukuran.dart';
import 'package:sidik_pelanggan/core/tema/warna_sidik.dart';
import 'package:sidik_pelanggan/models/data_pelanggan.dart';
import 'package:sidik_pelanggan/providers/data_provider.dart';
import 'package:sidik_pelanggan/providers/koneksi_provider.dart';
import 'package:sidik_pelanggan/screens/alat/alat_detail_screen.dart';
import 'package:sidik_pelanggan/screens/alat/daftar_alat_bagian.dart';
import 'package:sidik_pelanggan/screens/alat/daftar_alat_screen.dart';
import 'package:sidik_pelanggan/widgets/chip_status.dart';
import 'package:sidik_pelanggan/widgets/dasar/kontrol_ketuk.dart';
import 'package:sidik_pelanggan/widgets/keadaan_galat.dart';
import 'package:sidik_pelanggan/widgets/kartu_alat.dart';
import 'package:sidik_pelanggan/widgets/kartu_sidik.dart';
import 'package:sidik_pelanggan/widgets/kolom_cari_utuh.dart';
import 'package:sidik_pelanggan/widgets/saringan_pil.dart';
import 'package:sidik_pelanggan/widgets/status_tampil.dart';
import 'package:sidik_pelanggan/widgets/stempel.dart';
import 'package:sidik_pelanggan/widgets/ubin_alat.dart';

import 'dukungan/fixture_fitur.dart';
import 'dukungan/layar_uji.dart';

/// Server palsu: perusahaan 3 punya tujuh alat (satu per kelompok) ditambah
/// [banyak] alat jauh dari jatuh tempo (untuk paginasi); perusahaan 5 kosong.
/// Angka yang diharapkan: lewat jadwal 1 (Oven), dalam 30 hari 1 (Timbangan;
/// "Alat Nonaktif" tidak dihitung server), 31–60 hari 1 (Termometer),
/// 61–90 hari 1 (Manometer).
ServerFitur _server({int banyak = 0}) => ServerFitur({
  3: DataPerusahaan(
    nama: 'PT Alfa',
    alat: [
      alatJson(
        1,
        'Oven Memmert',
        hari: -88,
        status: 'lewat_jadwal',
        merk: 'Memmert',
        model: 'UN55',
        serial: 'MM-UN55-19',
      ),
      alatJson(
        2,
        'Timbangan Analitik',
        hari: 12,
        status: 'mendekati_jadwal',
        merk: 'Ohaus',
        model: 'PA224',
      ),
      alatJson(3, 'Termometer', hari: 45),
      alatJson(4, 'Manometer', hari: 75),
      alatJson(5, 'Mikrometer', hari: 200),
      alatJson(6, 'Alat Nonaktif', hari: 10, status: 'nonaktif'),
      alatJson(7, 'Tanpa Jadwal', status: 'belum_pernah'),
      for (var i = 0; i < banyak; i++)
        alatJson(100 + i, 'Alat Massal $i', hari: 300 + i),
    ],
  ),
  5: DataPerusahaan(nama: 'PT Kosong'),
});

Widget _app(
  Widget anak,
  ServerFitur server, {
  int perusahaan = 3,
  bool gelap = false,
  double skala = 1.0,
}) => ProviderScope(
  key: UniqueKey(),
  // Tanpa pengulangan otomatis Riverpod: galat langsung tampil, tidak menunggu
  // jeda yang makin panjang.
  retry: (_, _) => null,
  overrides: overrideFitur(server, perusahaan: perusahaan),
  child: MaterialApp(
    theme: TemaSidik.terang,
    darkTheme: TemaSidik.gelap,
    themeMode: gelap ? ThemeMode.dark : ThemeMode.light,
    builder: (context, child) => MediaQuery.withClampedTextScaling(
      minScaleFactor: skala,
      maxScaleFactor: skala,
      child: child!,
    ),
    home: anak,
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
  ServerFitur server, {
  int perusahaan = 3,
  bool gelap = false,
  double skala = 1.0,
  double lebar = 390,
  double tinggi = 3200,
}) async {
  layarHp(tester, lebar: lebar, tinggi: tinggi);
  await tester.pumpWidget(
    _app(
      const DaftarAlatScreen(),
      server,
      perusahaan: perusahaan,
      gelap: gelap,
      skala: skala,
    ),
  );
  await tester.pumpAndSettle();
}

Finder _ubin(String nama) => find.widgetWithText(UbinAlat, nama);

Finder _pil(String label) =>
    find.descendant(of: find.byType(SaringanPil), matching: find.text(label));

Future<void> _ketukPil(WidgetTester tester, String label) async {
  await tester.ensureVisible(_pil(label));
  await tester.pumpAndSettle();
  await tester.tap(_pil(label));
  await tester.pumpAndSettle();
}

List<PilihanPil> _pilihan(WidgetTester tester) =>
    tester.widget<SaringanPil>(find.byType(SaringanPil)).pilihan;

int? _jumlahPil(WidgetTester tester, String label) =>
    _pilihan(tester).firstWhere((p) => p.label == label).jumlah;

Color _latarUbin(WidgetTester tester, Finder ubin) => tester
    .widget<Material>(
      find.descendant(of: ubin, matching: find.byType(Material)).first,
    )
    .color!;

Alat _alat(Map<String, dynamic> j) => Alat.dariJson(j);

void main() {
  setUpAll(siapkanTesFitur);

  group('susunan Bento Lab', () {
    testWidgets(
      'kolom cari pil, saringan pil, ubin alat; tanpa komponen lama',
      (tester) async {
        await _buka(tester, _server());

        expect(find.byType(KolomCariUtuh), findsOneWidget);
        expect(find.byType(SaringanPil), findsOneWidget);
        expect(find.byType(UbinAlat), findsNWidgets(7));
        expect(find.byType(ChoiceChip), findsNothing);
        expect(find.byType(KartuSidik), findsNothing);
        expect(find.byType(ChipStatus), findsNothing);
        expect(
          [for (final p in _pilihan(tester)) p.label],
          [
            'Semua',
            'Lewat jadwal',
            'Dalam 30 hari',
            'Dalam 31–60 hari',
            'Dalam 61–90 hari',
          ],
        );

        // Urutan server (paling mendesak di atas) tidak diubah layar.
        final urutan = [
          for (final u in tester.widgetList<UbinAlat>(find.byType(UbinAlat)))
            u.nama,
        ];
        expect(urutan.first, 'Oven Memmert');
        expect(urutan.last, 'Tanpa Jadwal');
        expect(
          urutan.indexOf('Timbangan Analitik'),
          lessThan(urutan.indexOf('Termometer')),
        );

        // Ubin: tinggi minimum 196 dan sudut 32 dari token.
        final ubin = _ubin('Oven Memmert');
        expect(
          tester.getSize(ubin).height,
          greaterThanOrEqualTo(UkuranUbin.alat),
        );
        final bahan = tester.widget<Material>(
          find.descendant(of: ubin, matching: find.byType(Material)).first,
        );
        expect(
          (bahan.shape! as RoundedRectangleBorder).borderRadius,
          Bentuk.sudutUbin,
        );
      },
    );

    testWidgets('isi ubin dari data: status, merk, seri, angka hari, tanggal', (
      tester,
    ) async {
      await _buka(tester, _server());

      final oven = tester.widget<UbinAlat>(_ubin('Oven Memmert'));
      expect(oven.status.label, 'Lewat jadwal');
      expect(oven.status.nada, NadaStatus.gagal);
      expect(oven.merkTipe, 'Memmert UN55');
      // Nomor seri apa adanya; awalan "SN" hanya tampilan.
      expect(oven.serial, 'MM-UN55-19');
      expect(oven.awalanSerial, 'SN');
      expect(
        find.descendant(
          of: _ubin('Oven Memmert'),
          matching: find.text('SN MM-UN55-19'),
        ),
        findsOneWidget,
      );
      expect(oven.hari, -88);
      expect(oven.tanggal, Format.tanggal(DateTime.parse(tanggalUji(-88))));
      // Lokasi tampil di ubin (pembeda alat sejenis); nomor identifikasi tidak.
      expect(oven.lokasi, 'Gudang 1');
      expect(
        find.descendant(
          of: _ubin('Oven Memmert'),
          matching: find.text('Gudang 1'),
        ),
        findsOneWidget,
      );

      // Kata + ikon status, bukan warna saja.
      expect(
        find.descendant(
          of: _ubin('Oven Memmert'),
          matching: find.byIcon(Icons.error_outline),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: _ubin('Oven Memmert'),
          matching: find.text('hari lewat'),
        ),
        findsOneWidget,
      );

      // Warna ubin mengikuti status (pastel tetap, terang maupun gelap).
      final w = WarnaSidik.terang;
      expect(_latarUbin(tester, _ubin('Oven Memmert')), w.ubinGagal);
      expect(_latarUbin(tester, _ubin('Timbangan Analitik')), w.ubinAwas);
      expect(_latarUbin(tester, _ubin('Termometer')), w.ubinLulus);

      // Tanpa jadwal: netral (putih), tanpa angka hari dan tanggal; nonaktif
      // juga netral. Keadaan belum ada keputusan/jadwal tidak pernah hijau.
      final tanpa = tester.widget<UbinAlat>(_ubin('Tanpa Jadwal'));
      expect(tanpa.status.label, 'Belum pernah dikalibrasi');
      expect(tanpa.status.nada, NadaStatus.netral);
      expect(tanpa.hari, isNull);
      expect(tanpa.tanggal, isNull);
      expect(
        _latarUbin(tester, _ubin('Tanpa Jadwal')),
        TemaSidik.terang.colorScheme.surface,
      );
      expect(
        find.descendant(of: _ubin('Tanpa Jadwal'), matching: find.text('–')),
        findsOneWidget,
      );
      expect(
        tester.widget<UbinAlat>(_ubin('Alat Nonaktif')).status.nada,
        NadaStatus.netral,
      );
    });

    testWidgets('lokasi membedakan dua alat sejenis tanpa nomor seri; tanpa '
        'lokasi tidak ada baris kosong', (tester) async {
      final semantik = tester.ensureSemantics();
      // Timbangan yang sama persis (merk, tipe, status, jadwal), tanpa nomor
      // seri; hanya lokasinya yang berbeda.
      Map<String, dynamic> timbangan(int id, String nama, String? lokasi) => {
        ...alatJson(
          id,
          nama,
          hari: 12,
          status: 'mendekati_jadwal',
          merk: 'Ohaus',
          model: 'PA224',
        ),
        'serial': null,
        'lokasi': lokasi,
      };
      final server = ServerFitur({
        3: DataPerusahaan(
          nama: 'PT Alfa',
          alat: [
            timbangan(1, 'Timbangan Ohaus', 'Gudang A'),
            timbangan(2, 'Timbangan Ohaus', 'Lab Lantai 2'),
            timbangan(3, 'Timbangan Polos', null),
            timbangan(4, 'Timbangan Spasi', '   '),
          ],
        ),
      });
      await _buka(tester, server);
      expect(find.byType(UbinAlat), findsNWidgets(4));

      final a = find.widgetWithText(UbinAlat, 'Gudang A');
      final b = find.widgetWithText(UbinAlat, 'Lab Lantai 2');
      expect(a, findsOneWidget);
      expect(b, findsOneWidget);
      final ua = tester.widget<UbinAlat>(a);
      final ub = tester.widget<UbinAlat>(b);
      // Selain lokasi, keduanya tak terbedakan.
      expect(ua.nama, ub.nama);
      expect(ua.merkTipe, ub.merkTipe);
      expect(ua.serial, isNull);
      expect(ub.serial, isNull);
      expect(ua.hari, ub.hari);
      expect(ua.tanggal, ub.tanggal);
      expect(ua.status.label, ub.status.label);

      // Secara visual: tiap ubin menampilkan lokasinya sendiri.
      Finder teks(Finder ubin, String t) =>
          find.descendant(of: ubin, matching: find.text(t));
      expect(teks(a, 'Gudang A'), findsOneWidget);
      expect(teks(a, 'Lab Lantai 2'), findsNothing);
      expect(teks(b, 'Lab Lantai 2'), findsOneWidget);
      expect(teks(b, 'Gudang A'), findsNothing);

      // Secara semantik: dua kalimat berbeda, masing-masing menyebut lokasinya.
      String kalimat(Pattern p) => tester
          .getSemantics(find.bySemanticsLabel(p))
          .getSemanticsData()
          .label;
      final kalimatA = kalimat(RegExp('Lokasi Gudang A'));
      final kalimatB = kalimat(RegExp('Lokasi Lab Lantai 2'));
      expect(kalimatA, isNot(kalimatB));
      expect(kalimatA, startsWith('Timbangan Ohaus. Status: '));
      expect(kalimatB, startsWith('Timbangan Ohaus. Status: '));
      expect(kalimatA, isNot(contains('Nomor seri')));

      // Tanpa lokasi (null atau spasi saja): tidak ada baris tambahan dan tidak
      // ada kata "Lokasi" di kalimat.
      int jumlahTeks(Finder ubin) => tester
          .widgetList(find.descendant(of: ubin, matching: find.byType(Text)))
          .length;
      for (final nama in ['Timbangan Polos', 'Timbangan Spasi']) {
        final u = _ubin(nama);
        expect(jumlahTeks(u), jumlahTeks(a) - 1, reason: nama);
        expect(
          find.descendant(
            of: u,
            matching: find.byWidgetPredicate(
              (w) => w is Text && (w.data ?? '').trim().isEmpty,
            ),
          ),
          findsNothing,
          reason: nama,
        );
        expect(kalimat(RegExp('^$nama')), isNot(contains('Lokasi')));
      }
      semantik.dispose();
    });

    testWidgets(
      'KartuAlat: tanpa jadwal tidak membawa angka hari dan tanggal',
      (tester) async {
        layarHp(tester);
        await tester.pumpWidget(
          _app(
            Scaffold(
              body: Column(
                children: [
                  // hari ada tetapi jatuh_tempo kosong: tidak boleh jadi angka.
                  KartuAlat(
                    alat: _alat({
                      'id': 1,
                      'nama': 'Tanpa Tanggal',
                      'hari_ke_jatuh_tempo': 5,
                      'status_alat': 'belum_pernah',
                    }),
                    onTap: () {},
                  ),
                  KartuAlat(
                    alat: _alat(alatJson(2, 'Berjadwal', hari: 9)),
                    onTap: () {},
                  ),
                ],
              ),
            ),
            _server(),
          ),
        );
        await tester.pumpAndSettle();
        final a = tester.widget<UbinAlat>(_ubin('Tanpa Tanggal'));
        expect(a.hari, isNull);
        expect(a.tanggal, isNull);
        final b = tester.widget<UbinAlat>(_ubin('Berjadwal'));
        expect(b.hari, 9);
        expect(b.tanggal, isNotNull);
      },
    );
  });

  group('empat keadaan', () {
    testWidgets(
      'memuat: kerangka statis, tanpa gerak berulang dan tanpa angka',
      (tester) async {
        final semantik = tester.ensureSemantics();
        layarHp(tester, tinggi: 3200);
        final server = _server()..jeda = const Duration(seconds: 3);
        await tester.pumpWidget(_app(const DaftarAlatScreen(), server));
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.byType(KerangkaAlat), findsOneWidget);
        expect(find.byType(UbinKerangkaAlat), findsNWidgets(3));
        expect(find.byType(UbinAlat), findsNothing);
        expect(find.bySemanticsLabel('Memuat'), findsOneWidget);
        // Tidak ada animasi yang menjadwalkan frame terus-menerus (denyut lama
        // memakai `repeat`).
        await tester.pump(const Duration(milliseconds: 100));
        expect(tester.binding.hasScheduledFrame, isFalse);
        // Yang belum terbaca tidak tampil sebagai nol: tanpa pil jumlah, tanpa
        // bulatan di saringan.
        expect(find.byType(PilJumlahAlat), findsNothing);
        expect(find.textContaining('0 alat'), findsNothing);
        expect(_pilihan(tester).every((p) => p.jumlah == null), isTrue);
        // Saringan dan kolom cari sudah ada selama memuat.
        expect(find.byType(KolomCariUtuh), findsOneWidget);

        await tester.pump(const Duration(seconds: 4));
        await tester.pumpAndSettle();
        expect(find.byType(KerangkaAlat), findsNothing);
        expect(find.byType(UbinAlat), findsNWidgets(7));
        semantik.dispose();
      },
    );

    testWidgets(
      'kosong: belum ada alat, lalu saringan kosong, lalu cari kosong',
      (tester) async {
        await _buka(tester, _server(), perusahaan: 5);

        // Tanpa alat sama sekali.
        expect(find.byType(UbinKosongAlat), findsOneWidget);
        expect(find.text('Belum ada alat'), findsOneWidget);
        expect(find.textContaining('muncul di sini'), findsOneWidget);
        expect(
          find.descendant(
            of: find.byType(UbinKosongAlat),
            matching: find.byIcon(Icons.straighten_outlined),
          ),
          findsOneWidget,
        );
        expect(find.byType(UbinAlat), findsNothing);
        final ubinKosong = find.byType(UbinKosongAlat);
        expect(
          tester.getSize(ubinKosong).height,
          greaterThanOrEqualTo(UbinKosongAlat.tinggiMin),
        );
        expect(UbinKosongAlat.tinggiMin, greaterThanOrEqualTo(420));
        final (_, kuning) = StatusTampil.ubinDari(
          tester.element(ubinKosong),
          NadaStatus.awas,
        );
        expect(_latarUbin(tester, ubinKosong), kuning);
        // Nol yang TERBACA (daftar kosong dari server) boleh tampil.
        expect(find.text('0 alat'), findsOneWidget);

        // Saringan tanpa isi: kata lain dan ikon lain.
        await _ketukPil(tester, 'Lewat jadwal');
        expect(find.text('Tidak ada alat yang lewat jadwal'), findsOneWidget);
        expect(find.text('Belum ada alat'), findsNothing);
        expect(
          find.descendant(
            of: find.byType(UbinKosongAlat),
            matching: find.byIcon(Icons.event_available_outlined),
          ),
          findsOneWidget,
        );

        // Hasil cari kosong: dikatakan "tidak cocok", bukan "tidak ada alat yang
        // lewat jadwal" (kata cari menyempitkan hasilnya).
        await tester.enterText(find.byType(TextField), 'zzz');
        await tester.pump(
          KolomCariUtuh.jeda + const Duration(milliseconds: 50),
        );
        await tester.pumpAndSettle();
        expect(find.text('Tidak ada yang cocok'), findsOneWidget);
        expect(find.text('Tidak ada alat yang lewat jadwal'), findsNothing);
        expect(
          find.descendant(
            of: find.byType(UbinKosongAlat),
            matching: find.byIcon(Icons.search_off_outlined),
          ),
          findsOneWidget,
        );
        expect(find.textContaining('pilih "Semua"'), findsOneWidget);
      },
    );

    testWidgets(
      'galat: pesan server, Coba lagi; bagian gagal tidak terbaca nol',
      (tester) async {
        final server = _server()..gagal.add('/alat');
        await _buka(tester, server);

        expect(find.byType(KeadaanGalat), findsOneWidget);
        expect(
          find.textContaining('Terjadi kendala di server'),
          findsOneWidget,
        );
        expect(find.byType(UbinAlat), findsNothing);
        expect(find.byType(PilJumlahAlat), findsNothing);
        // Ringkasan Beranda terbaca; hitungan 31–90 hari (dari /alat) tidak.
        // "Semua" memang tanpa bulatan (lihat 'Semua tanpa bulatan' di bawah).
        expect(_jumlahPil(tester, 'Semua'), isNull);
        expect(_jumlahPil(tester, 'Lewat jadwal'), 1);
        expect(_jumlahPil(tester, 'Dalam 30 hari'), 1);
        expect(_jumlahPil(tester, 'Dalam 31–60 hari'), isNull);
        expect(_jumlahPil(tester, 'Dalam 61–90 hari'), isNull);

        server.gagal.clear();
        await tester.tap(find.text('Coba lagi'));
        await tester.pumpAndSettle();
        expect(find.byType(KeadaanGalat), findsNothing);
        expect(find.byType(UbinAlat), findsNWidgets(7));
        expect(find.text('7 alat'), findsOneWidget);
      },
    );

    testWidgets('tanpa koneksi: catatan di atas daftar yang tersimpan', (
      tester,
    ) async {
      final semantik = tester.ensureSemantics();
      await _buka(tester, _server());
      final koneksi = ProviderScope.containerOf(
        tester.element(find.byType(DaftarAlatScreen)),
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
      // Daftar yang tersimpan tetap tampil di bawahnya.
      expect(find.byType(UbinAlat), findsNWidgets(7));
      expect(
        tester.getTopLeft(find.byType(CatatanLuring)).dy,
        lessThan(tester.getTopLeft(_ubin('Oven Memmert')).dy),
      );

      koneksi.online();
      await tester.pump();
      expect(find.byType(CatatanLuring), findsNothing);
      semantik.dispose();
    });
  });

  group('jumlah di layar hanya dari data yang terbaca', () {
    test(
      'jumlahTerbaca: semua halaman termuat, atau total server yang masuk akal',
      () {
        final dua = [_alat(alatJson(1, 'A')), _alat(alatJson(2, 'B'))];
        // Semua halaman sudah dimuat: yang tampil itulah jumlahnya.
        expect(
          jumlahTerbaca(DataBerhalaman<Alat>(isi: dua, halaman: 1, total: 99)),
          2,
        );
        // Masih ada halaman: total server dipakai bila lebih besar dari yang termuat.
        expect(
          jumlahTerbaca(
            DataBerhalaman<Alat>(
              isi: dua,
              halaman: 1,
              halamanTerakhir: 3,
              total: 50,
            ),
          ),
          50,
        );
        // Masih ada halaman tetapi total tidak lebih besar (server tidak
        // mengirimnya): tidak ada klaim.
        expect(
          jumlahTerbaca(
            DataBerhalaman<Alat>(
              isi: dua,
              halaman: 1,
              halamanTerakhir: 3,
              total: 2,
            ),
          ),
          isNull,
        );
        expect(
          jumlahTerbaca(
            DataBerhalaman<Alat>(isi: dua, halaman: 1, halamanTerakhir: 3),
          ),
          isNull,
        );
      },
    );

    testWidgets('pil kepala dan bulatan saringan cocok dengan data', (
      tester,
    ) async {
      await _buka(tester, _server());
      expect(find.byType(PilJumlahAlat), findsOneWidget);
      expect(find.text('7 alat'), findsOneWidget);
      expect(_jumlahPil(tester, 'Semua'), isNull);
      expect(_jumlahPil(tester, 'Lewat jadwal'), 1);
      expect(_jumlahPil(tester, 'Dalam 30 hari'), 1);
      expect(_jumlahPil(tester, 'Dalam 31–60 hari'), 1);
      expect(_jumlahPil(tester, 'Dalam 61–90 hari'), 1);
      // Nada bulatan: lewat jadwal koral, 30 hari kuning, selebihnya netral.
      expect(
        {for (final p in _pilihan(tester)) p.label: p.nada},
        {
          'Semua': null,
          'Lewat jadwal': NadaStatus.gagal,
          'Dalam 30 hari': NadaStatus.awas,
          'Dalam 31–60 hari': null,
          'Dalam 61–90 hari': null,
        },
      );

      // Saringan dipilih: pil kepala = jumlah daftar yang tampil.
      await _ketukPil(tester, 'Dalam 31–60 hari');
      expect(find.text('1 alat'), findsOneWidget);
      expect(find.byType(UbinAlat), findsOneWidget);
      await _ketukPil(tester, 'Lewat jadwal');
      expect(find.text('1 alat'), findsOneWidget);
      expect(_ubin('Oven Memmert'), findsOneWidget);
    });

    testWidgets('Semua tanpa bulatan: jumlah_alat server (2) beda dari /alat (3) '
        'tidak menjadi dua angka', (tester) async {
      // Server menjawab "2" (hanya alat aktif) di ringkasan Beranda, sedangkan
      // GET /alat tanpa saringan memuat semua status: tiga.
      final server = ServerFitur({
        3: DataPerusahaan(
          nama: 'PT Alfa',
          alat: [
            alatJson(1, 'Oven', hari: -10, status: 'lewat_jadwal'),
            alatJson(2, 'Timbangan', hari: 12, status: 'mendekati_jadwal'),
            alatJson(3, 'Alat Nonaktif', hari: 100, status: 'nonaktif'),
          ],
          ringkasanTambahan: {'jumlah_alat': 2},
        ),
      });
      await _buka(tester, server);
      final wadah = ProviderScope.containerOf(
        tester.element(find.byType(DaftarAlatScreen)),
      );
      expect(wadah.read(berandaProvider).value!.jumlahAlat, 2);
      expect(find.byType(UbinAlat), findsNWidgets(3));

      // Terpilih dan tidak terpilih sama: tanpa bulatan, tidak pernah 2 atau 3.
      expect(find.text('3 alat'), findsOneWidget);
      expect(_jumlahPil(tester, 'Semua'), isNull);
      await _ketukPil(tester, 'Lewat jadwal');
      expect(find.text('1 alat'), findsOneWidget);
      expect(_jumlahPil(tester, 'Semua'), isNull);
      expect(_jumlahPil(tester, 'Lewat jadwal'), 1);
      await _ketukPil(tester, 'Semua');
      expect(find.text('3 alat'), findsOneWidget);
      expect(_jumlahPil(tester, 'Semua'), isNull);
      // Pembaca layar: kata saja, tanpa angka.
      expect(
        _pilihan(tester).firstWhere((p) => p.label == 'Semua').semantik,
        'Semua',
      );
    });

    for (final (awal, nama) in [
      (FilterAlat.semua, 'Semua'),
      (FilterAlat.hari60, 'Dalam 31–60 hari'),
    ]) {
      testWidgets('tarik-segarkan di $nama menyegarkan bulatan Lewat jadwal '
          'dan 31–60 (bukan hanya daftar)', (tester) async {
        final server = _server();
        // Layar pendek: ambang tarik RefreshIndicator = seperempat tinggi layar.
        layarHp(tester, tinggi: 900);
        await tester.pumpWidget(
          _app(DaftarAlatScreen(filterAwal: awal), server),
        );
        await tester.pumpAndSettle();
        expect(_jumlahPil(tester, 'Lewat jadwal'), 1);
        expect(_jumlahPil(tester, 'Dalam 31–60 hari'), 1);

        // Sesudah layar terbuka, server mendapat satu alat lewat jadwal dan
        // satu alat 31–60 hari.
        server.data[3]!.alat.addAll([
          alatJson(50, 'Oven Baru', hari: -3, status: 'lewat_jadwal'),
          alatJson(51, 'Termometer Baru', hari: 50),
        ]);
        final sebelumBeranda = server.yang('GET', '/beranda').length;
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

        expect(server.yang('GET', '/beranda').length, sebelumBeranda + 1);
        expect(_jumlahPil(tester, 'Lewat jadwal'), 2);
        expect(_jumlahPil(tester, 'Dalam 31–60 hari'), 2);
      });
    }

    testWidgets('paginasi tidak berubah: halaman berikut saat ujung terlihat', (
      tester,
    ) async {
      final server = _server(banyak: 45);
      await _buka(tester, server, tinggi: 800);

      List<String?> halaman() => [
        for (final r in server.yang('GET', '/alat'))
          if (r.url.queryParameters['per_page'] == null)
            r.url.queryParameters['page'],
      ];
      // Halaman 1 dari 3: total server (52) yang diklaim, bukan 20 yang termuat.
      // (Sesi yang baru terbaca membangun ulang provider: halaman 1 boleh
      // diminta dua kali; yang dijaga: belum ada halaman 2.)
      expect(halaman().toSet(), {'1'});
      expect(find.text('52 alat'), findsOneWidget);
      expect(find.byType(UjungDaftarAlat), findsNothing);

      // Ujung belum terlihat: baru halaman 1 yang diminta; digulir ke ujung:
      // pemuat statis dan halaman berikutnya diminta.
      server.jeda = const Duration(seconds: 2);
      await tester.fling(find.byType(ListView), const Offset(0, -6000), 6000);
      await tester.pumpAndSettle();
      expect(find.byType(UjungDaftarAlat), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(UjungDaftarAlat),
          matching: find.byType(UbinKerangkaAlat),
        ),
        findsOneWidget,
      );
      expect(tester.binding.hasScheduledFrame, isFalse);

      server.jeda = null;
      await tester.pump(const Duration(seconds: 3));
      for (var i = 0; i < 12; i++) {
        await tester.fling(find.byType(ListView), const Offset(0, -6000), 6000);
        await tester.pumpAndSettle();
        if (find.text('Semua 52 alat sudah tampil.').evaluate().isNotEmpty) {
          break;
        }
      }
      expect(find.text('Semua 52 alat sudah tampil.'), findsOneWidget);
      expect(halaman().toSet(), {'1', '2', '3'});
      expect(find.text('52 alat'), findsOneWidget);
    });
  });

  group('gerak, huruf besar, tema gelap', () {
    testWidgets(
      'ubin masuk berurutan: yang ke-4 belum penuh di frame pertama',
      (tester) async {
        layarHp(tester, tinggi: 3200);
        await tester.pumpWidget(_app(const DaftarAlatScreen(), _server()));
        for (var i = 0; i < 300; i++) {
          if (find.byType(UbinAlat).evaluate().isNotEmpty) break;
          await tester.pump(const Duration(milliseconds: 10));
        }
        final f = tester.widget<FadeTransition>(
          find
              .descendant(
                of: _ubin('Termometer'),
                matching: find.byType(FadeTransition),
              )
              .first,
        );
        expect(f.opacity.value, lessThan(1));
        await tester.pumpAndSettle();
        expect(f.opacity.value, 1);
      },
    );

    testWidgets('kurangi gerak: ubin langsung tampil penuh', (tester) async {
      _kurangiGerak(tester);
      layarHp(tester, tinggi: 3200);
      await tester.pumpWidget(_app(const DaftarAlatScreen(), _server()));
      for (var i = 0; i < 300; i++) {
        if (find.byType(UbinAlat).evaluate().isNotEmpty) break;
        await tester.pump(const Duration(milliseconds: 10));
      }
      expect(find.byType(UbinAlat), findsWidgets);
      final f = tester.widget<FadeTransition>(
        find
            .descendant(
              of: _ubin('Termometer'),
              matching: find.byType(FadeTransition),
            )
            .first,
      );
      expect(f.opacity.value, 1);
    });

    testWidgets('320 dp dengan huruf 1,3x: tanpa luapan, tidak terpotong', (
      tester,
    ) async {
      final server = ServerFitur({
        3: DataPerusahaan(
          nama: 'PT Panjang',
          alat: [
            alatJson(
              1,
              'Digital Pressure Calibrator Multifungsi Presisi Tinggi 2271A',
              hari: -365,
              status: 'lewat_jadwal',
              merk: 'Fluke Calibration International',
              model: 'Series 2271A',
              serial: 'FLK-2271A-0000000001',
            ),
            alatJson(2, 'Timbangan', hari: 12, status: 'mendekati_jadwal'),
          ],
        ),
      });
      await _buka(tester, server, skala: 1.3, lebar: 320, tinggi: 1400);
      expect(tester.takeException(), isNull);

      // Pil jumlah di kepala utuh: di dalam layar, di kanan judul, tidak
      // terpotong klip app bar.
      final pil = tester.getRect(
        find
            .descendant(
              of: find.byType(PilJumlahAlat),
              matching: find.byType(Material),
            )
            .first,
      );
      expect(pil.right, lessThanOrEqualTo(320 - Spasi.sisi + 0.5));
      expect(
        tester.getRect(find.text('Alat saya')).right,
        lessThanOrEqualTo(pil.left),
      );
      expect(find.text('2 alat'), findsOneWidget);

      // Stempel di dalam ubin dan utuh (tidak keluar dari batas ubin).
      final ubin = tester.getRect(find.byType(UbinAlat).first);
      final stempel = tester.getRect(find.byType(Stempel).first);
      expect(stempel.top, greaterThanOrEqualTo(ubin.top));
      expect(stempel.left, greaterThanOrEqualTo(ubin.left));
      expect(stempel.right, lessThanOrEqualTo(ubin.right));
      expect(ubin.height, greaterThanOrEqualTo(UkuranUbin.alat));

      // Pil saringan terakhir bisa dijangkau dan sasaran sentuhnya >= 48.
      await tester.ensureVisible(_pil('Dalam 61–90 hari'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final kontrol = find.byType(KontrolKetuk);
      for (var i = 0; i < kontrol.evaluate().length; i++) {
        final u = tester.getSize(kontrol.at(i));
        expect(u.height, greaterThanOrEqualTo(AreaSentuh.minimum));
        expect(u.width, greaterThanOrEqualTo(AreaSentuh.minimum));
      }
    });

    testWidgets('tema gelap: ubin tetap pastel terang, tanpa luapan', (
      tester,
    ) async {
      await _buka(tester, _server(), gelap: true);
      expect(tester.takeException(), isNull);
      final w = WarnaSidik.terang;
      expect(_latarUbin(tester, _ubin('Oven Memmert')), w.ubinGagal);
      expect(_latarUbin(tester, _ubin('Termometer')), w.ubinLulus);
    });
  });

  group('Semantics dan sasaran sentuh', () {
    testWidgets('judul, saringan terpilih, ubin satu tombol berkalimat', (
      tester,
    ) async {
      final semantik = tester.ensureSemantics();
      await _buka(tester, _server());

      expect(find.bySemanticsLabel('Saring alat'), findsOneWidget);
      bool? terpilih(String label) => tester
          .getSemantics(find.bySemanticsLabel(label))
          .getSemanticsData()
          .flagsCollection
          .isSelected
          .toBoolOrNull();
      expect(terpilih('Semua'), isTrue);
      expect(terpilih('Lewat jadwal, 1'), isFalse);

      // Pil bisa diaktifkan lewat pembaca layar dan terpilihnya berpindah.
      tester.semantics.tap(find.semantics.byLabel('Lewat jadwal, 1'));
      await tester.pumpAndSettle();
      expect(terpilih('Lewat jadwal, 1'), isTrue);
      expect(terpilih('Semua'), isFalse);
      expect(_ubin('Oven Memmert'), findsOneWidget);
      expect(_ubin('Termometer'), findsNothing);
      tester.semantics.tap(find.semantics.byLabel('Semua'));
      await tester.pumpAndSettle();

      // Ubin: SATU simpul berisi nama, status, seri, sisa hari, tanggal.
      final kalimat = tester
          .getSemantics(find.bySemanticsLabel(RegExp(r'^Oven Memmert')))
          .getSemanticsData()
          .label;
      expect(kalimat, contains('Status: Lewat jadwal'));
      expect(kalimat, contains('Memmert UN55'));
      // Nomor serinya saja: "SN" hanya di layar, supaya tidak terbaca "S N" dua
      // kali ("Nomor seri SN ...").
      expect(kalimat, contains('Nomor seri MM-UN55-19'));
      expect(kalimat, isNot(contains('SN')));
      expect(kalimat, contains('Lokasi Gudang 1'));
      expect(kalimat, contains('Lewat 88 hari'));
      tester.semantics.tap(find.semantics.byLabel(RegExp(r'^Oven Memmert')));
      await tester.pumpAndSettle();
      expect(find.byType(AlatDetailScreen), findsOneWidget);
      expect(
        tester.widget<AlatDetailScreen>(find.byType(AlatDetailScreen)).id,
        1,
      );
      semantik.dispose();
    });

    testWidgets('ketuk ubin kedua dan terakhir membuka alat yang diketuk', (
      tester,
    ) async {
      await _buka(tester, _server());
      final kartu = tester
          .widgetList<KartuAlat>(find.byType(KartuAlat))
          .toList();
      // Urutan server: Oven (1), lalu Alat Nonaktif (6), ..., Tanpa Jadwal (7).
      expect(kartu.first.alat.id, 1);
      expect(kartu[1].alat.id, 6);
      expect(kartu.last.alat.id, 7);

      int idDetail() =>
          tester.widget<AlatDetailScreen>(find.byType(AlatDetailScreen)).id;
      Future<void> kembali() async {
        Navigator.of(tester.element(find.byType(AlatDetailScreen))).pop();
        await tester.pumpAndSettle();
        expect(find.byType(AlatDetailScreen), findsNothing);
      }

      await tester.tap(find.byType(KartuAlat).at(1));
      await tester.pumpAndSettle();
      expect(idDetail(), 6);
      await kembali();

      await tester.tap(find.byType(KartuAlat).last);
      await tester.pumpAndSettle();
      expect(idDetail(), 7);
    });

    testWidgets('pedoman Flutter: sasaran sentuh 48 dp dan semua berlabel', (
      tester,
    ) async {
      final semantik = tester.ensureSemantics();
      layarHp(tester, lebar: 390, tinggi: 3200);
      await tester.pumpWidget(_app(const DaftarAlatScreen(), _server()));
      await tester.pumpAndSettle();
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      semantik.dispose();
    });
  });

  group('layar lebar', () {
    testWidgets(
      'baris saringan digeser mouse, ber-Scrollbar, tiap pil terjangkau',
      (tester) async {
        await _buka(tester, _server(), lebar: 1200, tinggi: 900);

        final saringan = find.byType(SaringanPil);
        expect(
          find.ancestor(of: saringan, matching: find.byType(Scrollbar)),
          findsOneWidget,
        );
        final posisi = tester
            .state<ScrollableState>(
              find.descendant(of: saringan, matching: find.byType(Scrollable)),
            )
            .position;
        // Isi saringan lebih lebar dari kolom isi (720): ada yang tersembunyi.
        expect(posisi.maxScrollExtent, greaterThan(0));
        expect(posisi.pixels, 0);

        final geser = await tester.startGesture(
          tester.getCenter(saringan),
          kind: PointerDeviceKind.mouse,
        );
        await geser.moveBy(const Offset(-120, 0));
        await geser.moveBy(const Offset(-120, 0));
        await geser.up();
        await tester.pumpAndSettle();
        expect(posisi.pixels, greaterThan(0));

        // Pil terakhir terjangkau dan bisa dipilih.
        await _ketukPil(tester, 'Dalam 61–90 hari');
        expect(find.text('1 alat'), findsOneWidget);
        expect(_ubin('Manometer'), findsOneWidget);
      },
    );

    testWidgets('isi dipusatkan dan dibatasi 720 dp', (tester) async {
      await _buka(tester, _server(), lebar: 1200, tinggi: 3200);
      final ubin = tester.getRect(_ubin('Oven Memmert'));
      expect(ubin.width, lessThanOrEqualTo(Spasi.lebarKonten));
      expect(ubin.center.dx, closeTo(600, 1));
    });
  });
}
