// Beranda "Jejak" (Paket 3a): kalimat utama, perlu perhatian, jejak tahap per
// alat, paket di lab, keadaan (memuat, kosong, galat, 401, offline), server
// lama tanpa field baru, nama PT hanya untuk akun multi-perusahaan, tablet dua
// kolom, teks panjang, sasaran sentuh, dan tanpa kata "kedaluwarsa".
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'package:sidik_pelanggan/core/api_pelanggan.dart';
import 'package:sidik_pelanggan/core/konfigurasi.dart';
import 'package:sidik_pelanggan/core/tema/tema_sidik.dart';
import 'package:sidik_pelanggan/models/akun.dart';
import 'package:sidik_pelanggan/models/data_pelanggan.dart';
import 'package:sidik_pelanggan/models/garis_tahap_pelanggan.dart';
import 'package:sidik_pelanggan/models/paket.dart';
import 'package:sidik_pelanggan/models/status_berlaku.dart';
import 'package:sidik_pelanggan/providers/koneksi_provider.dart';
import 'package:sidik_pelanggan/providers/sesi_provider.dart';
import 'package:sidik_pelanggan/screens/beranda/beranda_kerangka.dart';
import 'package:sidik_pelanggan/screens/beranda/beranda_ringkas.dart';
import 'package:sidik_pelanggan/screens/beranda/beranda_kapsul.dart';
import 'package:sidik_pelanggan/screens/beranda/beranda_screen.dart';
import 'package:sidik_pelanggan/widgets/chip_status.dart';
import 'package:sidik_pelanggan/screens/paket/paket_screen.dart';
import 'package:sidik_pelanggan/widgets/jejak_tahap.dart';
import 'package:sidik_pelanggan/widgets/kalimat_utama.dart';
import 'package:sidik_pelanggan/widgets/keadaan_teks.dart';
import 'package:sidik_pelanggan/widgets/peta_jatuh_tempo.dart';
import 'package:sidik_pelanggan/widgets/status_tampil.dart';
import 'package:sidik_pelanggan/widgets/stempel.dart';
import 'package:sidik_pelanggan/widgets/ubin_alat.dart';
import 'package:sidik_pelanggan/widgets/ubin_ringkas.dart';

import 'dukungan/fixture_fitur.dart';
import 'dukungan/layar_uji.dart';

/// Akun satu perusahaan (nama PT tidak boleh tampil di Beranda).
Sesi _sesiSatu() => Sesi(
  akun: Akun.dariJson({
    'id': 7,
    'nama': 'Rina Wulandari',
    'email': 'rina@contoh.test',
    'status': 'aktif',
    'butuh_verifikasi': false,
    'keanggotaan': [
      {'customer_id': 3, 'nama_perusahaan': 'PT Alfa', 'peran': 'staf'},
    ],
  }),
  perusahaanId: 3,
);

ServerFitur _server({
  List<Map<String, dynamic>> alat = const [],
  List<Map<String, dynamic>> paket = const [],
  List<Map<String, dynamic>> sertifikat = const [],
  int? jumlahPaket,
}) => ServerFitur({
  3: DataPerusahaan(
    nama: 'PT Alfa',
    alat: alat,
    paket: paket,
    sertifikat: sertifikat,
    jumlahPaketBerjalan: jumlahPaket,
  ),
});

/// Server yang menjawab 401 untuk `/beranda` (token dicabut).
class _Server401 extends ServerFitur {
  _Server401() : super({3: DataPerusahaan(nama: 'PT Alfa')});

  @override
  Future<http.Response> tangani(http.Request r) async {
    final jalur = r.url.path.replaceFirst(Konfigurasi.prefix, '');
    if (jalur == '/beranda') {
      return http.Response(
        jsonEncode({'kode': 'sesi_berakhir', 'message': 'Sesi berakhir.'}),
        401,
        headers: {'content-type': 'application/json'},
      );
    }
    return super.tangani(r);
  }
}

Widget _app(
  ServerFitur server, {
  Sesi? sesi,
  double skala = 1.0,
  bool gelap = false,
}) => ProviderScope(
  overrides: overrideFitur(server, sesi: sesi),
  child: MaterialApp(
    theme: TemaSidik.terang,
    darkTheme: TemaSidik.gelap,
    themeMode: gelap ? ThemeMode.dark : ThemeMode.light,
    builder: (context, child) => MediaQuery.withClampedTextScaling(
      minScaleFactor: skala,
      maxScaleFactor: skala,
      child: child!,
    ),
    home: const BerandaScreen(),
  ),
);

/// Semua teks yang tergambar di layar, huruf kecil.
String _semuaTeks(WidgetTester tester) => [
  for (final w in tester.widgetList<Text>(find.byType(Text)))
    (w.data ?? w.textSpan?.toPlainText() ?? '').toLowerCase(),
].join('\n');

/// Garis waktu server untuk pelanggan: PORTASI LANGSUNG
/// `TahapPaket::garisWaktu($tahap, true)` (API d8dc320a), sebagai pembanding
/// bebas untuk [garisWaktuPelanggan].
List<({String kode, bool lewat, bool sekarang})> _garisServer(String tahap) {
  const urutan = [
    'diterima',
    'dikalibrasi',
    'perlu_diulang',
    'menunggu_pemeriksaan',
    'menunggu_pengesahan',
    'sertifikat_terbit',
    'siap_diambil',
    'diserahkan',
  ];
  if (tahap == 'menunggu_pengesahan') tahap = 'menunggu_pemeriksaan';
  final sekarang = urutan.indexOf(tahap);
  return [
    for (var posisi = 0; posisi < urutan.length; posisi++)
      if (urutan[posisi] != 'menunggu_pengesahan' &&
          !(urutan[posisi] == 'perlu_diulang' && tahap != 'perlu_diulang'))
        (
          kode: urutan[posisi],
          lewat: posisi < sekarang,
          sekarang: posisi == sekarang,
        ),
  ];
}

Alat _a(int id, int? hari, {String status = 'terkalibrasi'}) =>
    Alat.dariJson(alatJson(id, 'Alat $id', hari: hari, status: status));

void main() {
  setUpAll(siapkanTesFitur);

  group('kalimat utama: 0, 1, banyak, dan kata berwarna', () {
    String teks(List<List<PotonganKalimat>> k) => [
      for (final s in k) [for (final p in s) p.teks].join(),
    ].join(' | ');

    List<List<PotonganKalimat>> k({
      int alat = 5,
      int lewat = 0,
      int segera = 0,
      int paket = 0,
      bool lebih = false,
      int baru = 0,
      bool baruLebih = false,
      bool berlaku = false,
      int belumPernah = 0,
    }) => kalimatBeranda(
      jumlahAlat: alat,
      lewat: lewat,
      segera: segera,
      paketSiap: paket,
      paketSiapMungkinLebih: lebih,
      sertifikatBaru: baru,
      sertifikatBaruMungkinLebih: baruLebih,
      semuaBerlaku: berlaku,
      alatBelumPernah: belumPernah,
    );

    test('nol: keadaan tenang TANPA klaim "berlaku", dan tanpa alat', () {
      // `jumlah_alat` ikut menghitung alat yang belum pernah dikalibrasi, jadi
      // "tidak ada yang lewat jadwal" bukan "semua berlaku".
      expect(teks(k()), 'Tidak ada alat yang lewat jadwal.');
      expect(teks(k()).toLowerCase(), isNot(contains('berlaku')));
      // Kalimat tenang berwarna `lulus` (kabar baik), bukan merah.
      expect(k().first.first.nada, NadaStatus.lulus);
      expect(teks(k(alat: 0)), 'Belum ada alat.');
    });

    test('"Semua alat Anda berlaku." hanya bila server menjaminnya', () {
      expect(teks(k(berlaku: true)), 'Semua alat Anda berlaku.');
      // Ada yang lewat jadwal: klaim itu tidak pernah muncul.
      expect(teks(k(lewat: 1, berlaku: true)), '1 alat lewat jadwal.');
    });

    test('alat belum pernah dikalibrasi disebut polos, bukan "berlaku"', () {
      expect(
        teks(k(belumPernah: 3)),
        'Tidak ada alat yang lewat jadwal. | 3 alat belum pernah dikalibrasi.',
      );
      expect(
        teks(k(lewat: 1, belumPernah: 3)),
        '1 alat lewat jadwal. | 3 alat belum pernah dikalibrasi.',
      );
    });

    test('sertifikat baru: batas lima dari server, jumlah tidak diklaim', () {
      expect(
        teks(k(lewat: 1, baru: 5, baruLebih: true)),
        '1 alat lewat jadwal. | Ada sertifikat baru terbit.',
      );
      expect(
        teks(k(segera: 1, baru: 4)),
        '1 alat segera jatuh tempo. | 4 sertifikat baru terbit.',
      );
    });

    test('satu dan banyak memakai angka yang sama dengan server', () {
      expect(teks(k(lewat: 1)), '1 alat lewat jadwal.');
      expect(teks(k(lewat: 12)), '12 alat lewat jadwal.');
      expect(teks(k(paket: 1)), '1 paket siap diambil.');
      expect(teks(k(paket: 3)), '3 paket siap diambil.');
      expect(teks(k(segera: 2)), '2 alat segera jatuh tempo.');
    });

    test('prioritas: lewat, paket siap, segera, sertifikat; maksimum dua', () {
      expect(
        teks(k(lewat: 1, paket: 1, segera: 4, baru: 2)),
        '1 alat lewat jadwal. | 1 paket siap diambil.',
      );
      expect(
        teks(k(segera: 4, baru: 2)),
        '4 alat segera jatuh tempo. | 2 sertifikat baru terbit.',
      );
      expect(teks(k(paket: 1, segera: 1, baru: 1)).split(' | ').length, 2);
    });

    test(
      'tenang tetap memberi kabar sertifikat baru sebagai kalimat kedua',
      () {
        expect(
          teks(k(baru: 1)),
          'Tidak ada alat yang lewat jadwal. | 1 sertifikat baru terbit.',
        );
      },
    );

    test('daftar paket dipotong server: jumlah tidak disebut', () {
      expect(teks(k(paket: 1, lebih: true)), 'Ada paket siap diambil.');
    });

    test('frasa berwarna selalu KATA, dengan nada yang sesuai', () {
      final semua = [
        k(lewat: 2, paket: 1),
        k(segera: 1, baru: 1),
        k(),
        k(baru: 1),
        k(paket: 2, lebih: true),
      ];
      for (final kal in semua) {
        for (final s in kal) {
          for (final p in s) {
            expect(p.warnaBerkata, isTrue, reason: p.teks);
            expect(p.teks.toLowerCase(), isNot(contains('kedaluwarsa')));
          }
        }
      }
      PotonganKalimat? cari(List<List<PotonganKalimat>> kal, String t) =>
          kal.expand((s) => s).where((p) => p.teks == t).firstOrNull;
      final kal = k(lewat: 1, paket: 1);
      expect(cari(kal, 'lewat jadwal')?.nada, NadaStatus.gagal);
      expect(cari(kal, 'siap diambil')?.nada, NadaStatus.lulus);
      expect(cari(k(segera: 1), 'segera jatuh tempo')?.nada, NadaStatus.awas);
    });
  });

  group('memilih butir perlu perhatian', () {
    Paket paket(int id, String tahap) =>
        Paket.dariJson(paketJson(id, 'ORD/$id', tahap: tahap));

    test('lewat jadwal terlama dulu, lalu segera terdekat dulu', () {
      final r = RingkasanJatuhTempo.dari([
        _a(1, -2, status: 'lewat_jadwal'),
        _a(2, -9, status: 'lewat_jadwal'),
        _a(3, 20, status: 'mendekati_jadwal'),
        _a(4, 3, status: 'mendekati_jadwal'),
        _a(5, 45),
      ]);
      expect([for (final a in alatPerhatian(r)) a.id], [2, 1, 4, 3]);
    });

    test('satu baris dicadangkan untuk paket siap diambil', () {
      final alat = [for (var i = 1; i <= 5; i++) _a(i, -i)];
      final pilih = pilihPerhatian(alat, [paket(9, 'siap_diambil')]);
      expect(pilih.alat.length, 2);
      expect(pilih.paket.length, 1);
      // Tanpa paket: tiga alat penuh.
      expect(pilihPerhatian(alat, []).alat.length, maksPerhatian);
      // Banyak paket, satu alat: sisanya paket.
      final banyak = pilihPerhatian(
        [alat.first],
        [for (var i = 0; i < 4; i++) paket(10 + i, 'siap_diambil')],
      );
      expect(banyak.alat.length, 1);
      expect(banyak.paket.length, 2);
    });

    test('sertifikat baru: 4, 5, dan 6 data terhadap batas server (5)', () {
      List<Sertifikat> baru(int n, {int lama = 0}) => [
        for (var i = 0; i < n; i++)
          Sertifikat.dariJson(sertifikatJson(i + 1, 'CAL/$i', diterbitkan: -i)),
        for (var i = 0; i < lama; i++)
          Sertifikat.dariJson(
            sertifikatJson(100 + i, 'CAL/L$i', diterbitkan: -300),
          ),
      ];
      // Empat baru dari lima baris: pasti empat (urut terbaru, yang kelima lama).
      var r = ringkasSertifikatBaru(baru(4, lama: 1), hariIniUji);
      expect((r.jumlah, r.mungkinLebih), (4, false));
      // Lima baru = penuh sampai batas: bisa lebih; angka tidak boleh diklaim.
      r = ringkasSertifikatBaru(baru(5), hariIniUji);
      expect((r.jumlah, r.mungkinLebih), (5, true));
      // Enam (tidak mungkin dari server, tetapi tetap aman).
      r = ringkasSertifikatBaru(baru(6), hariIniUji);
      expect(r.mungkinLebih, isTrue);
      // Tiga baru dan dua lama: pasti tiga.
      r = ringkasSertifikatBaru(baru(3, lama: 2), hariIniUji);
      expect((r.jumlah, r.mungkinLebih), (3, false));
      // Hitungan server menang dan pasti, juga di atas lima.
      r = ringkasSertifikatBaru(baru(5), hariIniUji, dariServer: 12);
      expect((r.jumlah, r.mungkinLebih), (12, false));
      r = ringkasSertifikatBaru(const [], hariIniUji, dariServer: 0);
      expect((r.jumlah, r.mungkinLebih), (0, false));
    });

    test('paket siap vs di lab: tahap tidak dikenal ikut di lab', () {
      final semua = [
        paket(1, 'siap_diambil'),
        paket(2, 'dikalibrasi'),
        paket(3, 'tahap_baru_dari_server'),
        paket(4, 'diserahkan'),
        paket(5, ''),
      ];
      expect([for (final p in paketSiapDiambil(semua)) p.id], [1]);
      expect([for (final p in paketDiLab(semua)) p.id], [2, 3, 5]);
    });

    test('sertifikat baru: tujuh hari terakhir saja', () {
      Sertifikat s(int hari) =>
          Sertifikat.dariJson(sertifikatJson(1, 'CAL/1', diterbitkan: hari));
      // hariIniUji = 12 Nov 2026; diterbitkan = hari relatif.
      final daftar = [s(0), s(-7), s(-8), s(-300), s(2)];
      expect(hitungSertifikatBaru(daftar, hariIniUji), 2);
    });
  });

  group('teks galat', () {
    test('401, jaringan, dan galat server memberi langkah berikutnya', () {
      final sesi = teksGalatBeranda(
        const GalatApi(status: 401, pesan: 'Sesi berakhir.'),
      );
      expect(sesi.judul, 'Sesi Anda berakhir');
      expect(sesi.aksi, isNull, reason: 'aplikasi membuka Masuk sendiri');
      final jaringan = teksGalatBeranda(GalatApi.jaringan());
      expect(jaringan.isi, contains('Periksa sinyal'));
      expect(jaringan.aksi, 'Coba lagi');
      final server = teksGalatBeranda(
        const GalatApi(status: 500, pesan: 'Terjadi kendala di server.'),
      );
      expect(server.isi, 'Terjadi kendala di server.');
      expect(
        teksGalatBeranda(StateError('x')).isi,
        'Terjadi kesalahan. Coba lagi.',
      );
    });
  });

  group('garis tahap pelanggan: setara dengan TahapPaket::garisWaktu', () {
    const semuaKode = [
      'diterima',
      'dikalibrasi',
      'perlu_diulang',
      'menunggu_pemeriksaan',
      'menunggu_pengesahan',
      'sertifikat_terbit',
      'siap_diambil',
      'diserahkan',
    ];

    test('delapan kode: urutan, lewat, dan sekarang sama dengan server', () {
      for (final kode in semuaKode) {
        final milik = [
          for (final l in garisWaktuPelanggan(kode))
            (kode: l.kode, lewat: l.lewat, sekarang: l.sekarang),
        ];
        expect(milik, _garisServer(kode), reason: kode);
      }
    });

    test('enam tik, tujuh hanya saat dikerjakan ulang', () {
      for (final kode in semuaKode) {
        expect(
          garisWaktuPelanggan(kode).length,
          kode == 'perlu_diulang' ? 7 : 6,
          reason: kode,
        );
      }
    });

    test(
      'kode tak dikenal atau kosong: tanpa tik "sekarang" yang dikarang',
      () {
        for (final kode in ['tahap_baru', '', null]) {
          final garis = garisWaktuPelanggan(kode);
          expect(garis.any((l) => l.sekarang), isFalse);
          expect(garis.any((l) => l.lewat), isFalse);
          expect(posisiTahap(garis, kode: kode ?? ''), isNull);
        }
      },
    );
  });

  group('SedangDikerjakan: field baru opsional', () {
    test('lima kunci server terbaca', () {
      final s = SedangDikerjakan.dariJson(
        sedangDikerjakanJson(
          paketId: 120,
          itemId: 981,
          nomorOrder: 'ORD/2026/11/0042',
          tahap: 'menunggu_pemeriksaan',
          label: 'Hasil sedang diperiksa',
        ),
      )!;
      expect(s.paketId, 120);
      expect(s.orderItemId, 981);
      expect(s.nomorOrder, 'ORD/2026/11/0042');
      expect(s.tahap, 'menunggu_pemeriksaan');
      expect(s.tahapLabel, 'Hasil sedang diperiksa');
    });

    test('null, hilang, kosong, atau bentuk aneh = tidak ada, tanpa galat', () {
      for (final j in <Object?>[
        null,
        <String, dynamic>{},
        <Object>[],
        'sedang dikalibrasi',
        42,
        {'tahap': 'dikalibrasi'},
        {'tahap_label': 'Sedang dikalibrasi'},
        {'tahap': '  ', 'tahap_label': 'x'},
        {'tahap': null, 'tahap_label': null},
      ]) {
        expect(SedangDikerjakan.dariJson(j), isNull, reason: '$j');
      }
      // Dalam objek alat: kunci hilang dan null sama-sama aman.
      expect(Alat.dariJson(alatJson(1, 'A')).sedangDikerjakan, isNull);
      expect(
        Alat.dariJson(
          alatJson(1, 'A', kunciSedangDikerjakan: true),
        ).sedangDikerjakan,
        isNull,
      );
    });

    test(
      'kunci tambahan, id sebagai teks, dan tipe campur tidak membuat galat',
      () {
        final s = SedangDikerjakan.dariJson({
          'paket_id': '120',
          'order_item_id': null,
          'nomor_order': 12345,
          'tahap': 'dikalibrasi',
          'tahap_label': 'Sedang dikalibrasi',
          'nama_teknisi': 'tidak dibaca',
        })!;
        expect(s.paketId, 120);
        expect(s.orderItemId, isNull);
        expect(s.nomorOrder, '12345');
      },
    );
  });

  // ── P5a (Bento Lab): isi Beranda diganti ubin ───────────────────────────────
  // Bagian di bawah ini disesuaikan dengan LAYAR.md 01: satu ubin alat (bukan
  // daftar "Perlu perhatian" dengan jejak tahap), dua ubin pasangan (bukan
  // daftar paket dan sertifikat), kapsul (bukan `PetaJatuhTempo`). Kalimat
  // utama, klaim jujur, galat, 401, offline, dan teks tanpa "kedaluwarsa"
  // tetap diuji sama kerasnya. Alasan tiap perubahan ada di komentar tes.

  /// Pasang di pohon BARU (ProviderScope lama dibuang) supaya dua `_app`
  /// berurutan dalam satu tes tidak mewarisi data.
  Future<void> pasang(WidgetTester tester, Widget w) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(w);
  }

  /// Kerangka memuat sekarang STATIS (tanpa animasi berulang), jadi
  /// `pumpAndSettle` tidak lagi ikut menunggu percobaan ulang bawaan Riverpod
  /// (10 kali, ±38 detik) sebelum galat tampil: waktu dimajukan eksplisit.
  Future<void> sampaiGalat(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(seconds: 60));
    await tester.pump(const Duration(seconds: 60));
    await tester.pumpAndSettle();
  }

  group('layar: ubin alat paling mendesak dan alat di lab', () {
    final alat = [
      alatJson(
        1,
        'Jangka Sorong Digital',
        hari: -4,
        status: 'lewat_jadwal',
        merk: 'Mitutoyo',
        model: 'CD-15CPX',
        serial: '2201-0457',
        sedangDikerjakan: sedangDikerjakanJson(),
      ),
      alatJson(2, 'Timbangan Analitik', hari: 12, status: 'mendekati_jadwal'),
    ];

    testWidgets('alat di lab: kata server, identitas, nomor seri sendiri', (
      tester,
    ) async {
      layarHp(tester, lebar: 392, tinggi: 2000);
      await tester.pumpWidget(_app(_server(alat: alat), sesi: _sesiSatu()));
      await tester.pumpAndSettle();

      // Tanggal tidak lagi di atas kalimat (sapaan di kepala menggantikannya).
      expect(find.text('Kamis, 12 November 2026'), findsNothing);
      expect(find.text('1 alat lewat jadwal.'), findsOneWidget);
      // Satu ubin untuk alat paling mendesak; ubin tidak punya slot untuk jejak
      // tahap (tik). Tahap alat di lab kini hanya terlihat sebagai kata "Di lab:
      // <tahap>" pada ubin itu, dan per alat di detail paket. Detail alat
      // (`AlatDetailScreen`) tidak menampilkan tahap: isinya identitas, status dan
      // jadwal, serta riwayat sertifikat. `JejakTahap` dan `TikPaket` kini tidak
      // dipakai layar Beranda.
      expect(find.byType(UbinAlat), findsOneWidget);
      expect(find.byType(JejakTahap), findsNothing);
      expect(find.text('Di lab: Sedang dikalibrasi'), findsOneWidget);
      expect(find.textContaining('Di lab'), findsOneWidget);
      // Identitas: nama, merk + model, nomor seri di baris sendiri.
      expect(find.text('Jangka Sorong Digital'), findsOneWidget);
      expect(find.text('Mitutoyo CD-15CPX'), findsOneWidget);
      expect(find.text('2201-0457'), findsOneWidget);
      // Alat yang kurang mendesak tidak digambar sebagai ubin.
      expect(find.text('Timbangan Analitik'), findsNothing);
    });

    testWidgets('tahap tak dikenal: kata server tampil, tanpa galat', (
      tester,
    ) async {
      layarHp(tester, lebar: 392, tinggi: 2000);
      final aneh = [
        alatJson(
          1,
          'Alat Aneh',
          hari: -1,
          status: 'lewat_jadwal',
          sedangDikerjakan: sedangDikerjakanJson(
            tahap: 'tahap_baru_dari_server',
            label: 'Sedang dikemas',
          ),
        ),
      ];
      await tester.pumpWidget(_app(_server(alat: aneh), sesi: _sesiSatu()));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Di lab: Sedang dikemas'), findsOneWidget);
    });

    testWidgets('dikerjakan ulang: kata dari server', (tester) async {
      layarHp(tester, lebar: 392, tinggi: 2000);
      final ulang = [
        alatJson(
          1,
          'Alat Ulang',
          hari: -1,
          status: 'lewat_jadwal',
          sedangDikerjakan: sedangDikerjakanJson(
            tahap: 'perlu_diulang',
            label: 'Sedang dikerjakan ulang',
          ),
        ),
      ];
      await tester.pumpWidget(_app(_server(alat: ulang), sesi: _sesiSatu()));
      await tester.pumpAndSettle();
      expect(find.text('Di lab: Sedang dikerjakan ulang'), findsOneWidget);
    });

    testWidgets('siap diambil di lab: kata, bukan hanya warna', (tester) async {
      layarHp(tester, lebar: 392, tinggi: 2000);
      final siap = [
        alatJson(
          1,
          'Alat Siap',
          hari: -1,
          status: 'lewat_jadwal',
          sedangDikerjakan: sedangDikerjakanJson(
            tahap: 'siap_diambil',
            label: 'Siap diambil',
          ),
        ),
      ];
      await tester.pumpWidget(_app(_server(alat: siap), sesi: _sesiSatu()));
      await tester.pumpAndSettle();
      expect(find.text('Di lab: Siap diambil'), findsOneWidget);
    });
  });

  group('server lama tanpa field baru', () {
    testWidgets('tanpa sedang_dikerjakan dan tanpa alat[] di paket: tampil, '
        'tanpa "Di lab", tanpa kode tahap mentah, tanpa galat', (tester) async {
      layarHp(tester, lebar: 392, tinggi: 2400);
      // `paketJson` memuat `alat: []` dan jumlah 3; hapus kunci yang baru.
      final lama = Map<String, dynamic>.of(paketJson(21, 'ORD/ALFA/2026/0021'))
        ..remove('alat')
        ..remove('tahap_label');
      final server = _server(
        alat: [
          alatJson(1, 'Jangka Sorong', hari: -4, status: 'lewat_jadwal'),
          alatJson(2, 'Timbangan', hari: 12, status: 'mendekati_jadwal'),
        ],
        paket: [lama],
      );
      await tester.pumpWidget(_app(server, sesi: _sesiSatu()));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('1 alat lewat jadwal.'), findsOneWidget);
      expect(find.byType(UbinAlat), findsOneWidget);
      expect(find.byType(JejakTahap), findsNothing);
      expect(find.textContaining('Di lab'), findsNothing);
      // Paket tetap tampil dengan nomornya; label tahap yang jatuh ke kode
      // mentah ("dikalibrasi") tidak ditampilkan sebagai kata.
      final paket = tester.widget<UbinRingkas>(
        find.widgetWithText(UbinRingkas, 'Paket dikerjakan'),
      );
      expect(paket.kalimat, 'ORD/ALFA/2026/0021');
    });

    testWidgets('field baru null atau bentuk aneh: tidak jatuh', (
      tester,
    ) async {
      layarHp(tester, lebar: 392, tinggi: 2400);
      final aneh = Map<String, dynamic>.of(paketJson(21, 'ORD/ALFA/2026/0021'))
        ..['alat'] = null;
      final server = _server(
        alat: [
          alatJson(
            1,
            'A1',
            hari: -4,
            status: 'lewat_jadwal',
            kunciSedangDikerjakan: true,
          ),
          {
            ...alatJson(2, 'A2', hari: 5, status: 'mendekati_jadwal'),
            'sedang_dikerjakan': 'ada',
          },
          {
            ...alatJson(3, 'A3', hari: 6, status: 'mendekati_jadwal'),
            'sedang_dikerjakan': {'tahap': null, 'tahap_label': null},
          },
        ],
        paket: [aneh],
      );
      await tester.pumpWidget(_app(server, sesi: _sesiSatu()));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(JejakTahap), findsNothing);
      expect(find.byType(UbinAlat), findsOneWidget);
      expect(find.textContaining('Di lab'), findsNothing);
    });
  });

  group('nama perusahaan hanya untuk akun multi-perusahaan', () {
    testWidgets('satu perusahaan: nama tidak tampil, tanpa tombol ganti', (
      tester,
    ) async {
      final semantik = tester.ensureSemantics();
      layarHp(tester, lebar: 392, tinggi: 1600);
      await tester.pumpWidget(
        _app(_server(alat: [alatJson(1, 'A', hari: 100)]), sesi: _sesiSatu()),
      );
      await tester.pumpAndSettle();
      expect(find.text('PT Alfa'), findsNothing);
      expect(find.bySemanticsLabel(RegExp('Ganti perusahaan')), findsNothing);
      semantik.dispose();
    });

    testWidgets('dua perusahaan: nama tampil di pil yang bisa mengganti', (
      tester,
    ) async {
      final semantik = tester.ensureSemantics();
      layarHp(tester, lebar: 392, tinggi: 1600);
      await tester.pumpWidget(
        _app(_server(alat: [alatJson(1, 'A', hari: 100)])),
      );
      await tester.pumpAndSettle();
      // Pil perusahaan menggantikan teks + tombol "Ganti" (LAYAR.md 01).
      expect(find.text('PT Alfa'), findsOneWidget);
      expect(
        find.bySemanticsLabel('Ganti perusahaan, sekarang PT Alfa'),
        findsOneWidget,
      );
      semantik.dispose();
    });
  });

  group('keadaan tenang: normal diam', () {
    testWidgets('tidak ada yang perlu perhatian: kalimat tenang, ubin jadwal '
        'terdekat, tanpa chip lama dan tanpa kapsul lama', (tester) async {
      layarHp(tester, lebar: 392, tinggi: 2000);
      final server = _server(
        alat: [
          alatJson(1, 'Manometer', hari: 45),
          alatJson(2, 'Mikro', hari: 200),
        ],
        sertifikat: [sertifikatJson(5, 'CAL/ALFA/0005', diterbitkan: -100)],
      );
      await tester.pumpWidget(_app(server, sesi: _sesiSatu()));
      await tester.pumpAndSettle();

      expect(find.text('Tidak ada alat yang lewat jadwal.'), findsOneWidget);
      // Satu ubin (jadwal terdekat) dengan satu stempel di dalamnya: di ubin
      // alat status selalu tampil (KOMPONEN.md); tidak ada chip lama.
      expect(find.byType(UbinAlat), findsOneWidget);
      expect(find.byType(Stempel), findsOneWidget);
      expect(find.text('Berlaku'), findsOneWidget);
      expect(find.byType(PetaJatuhTempo), findsNothing);
      expect(find.byType(ChipStatus), findsNothing);
      expect(find.byType(JejakTahap), findsNothing);
      // Kapsul tetap memberi konteks 90 hari.
      expect(find.byType(KapsulJatuhTempo), findsOneWidget);
    });
  });

  group('paket', () {
    final paketSiap = paketJson(
      20,
      'ORD/ALFA/2026/0020',
      tahap: 'siap_diambil',
      label: 'Siap diambil',
      jumlahSelesai: 2,
    );
    final paketLab = paketJson(
      21,
      'ORD/ALFA/2026/0021',
      tahap: 'diterima',
      label: 'Alat diterima lab',
      jumlahSelesai: 1,
      terlambat: true,
    );

    testWidgets('siap diambil + paket lab: kalimat dan ubin paket', (
      tester,
    ) async {
      layarHp(tester, lebar: 392, tinggi: 2400);
      await tester.pumpWidget(
        _app(
          _server(
            alat: [alatJson(1, 'Manometer', hari: 100)],
            paket: [paketSiap, paketLab],
          ),
          sesi: _sesiSatu(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('1 paket siap diambil.'), findsOneWidget);
      final ubin = tester.widget<UbinRingkas>(
        find.widgetWithText(UbinRingkas, 'Paket dikerjakan'),
      );
      expect(ubin.kalimat!.split('\n'), [
        'ORD/ALFA/2026/0020',
        'Siap diambil',
        '1 paket siap diambil',
        '2 paket berjalan',
      ]);
    });

    testWidgets('banyak alat lewat jadwal: paket siap diambil tetap disebut', (
      tester,
    ) async {
      layarHp(tester, lebar: 392, tinggi: 2400);
      await tester.pumpWidget(
        _app(
          _server(
            alat: [
              for (var i = 1; i <= 5; i++)
                alatJson(i, 'Alat $i', hari: -i, status: 'lewat_jadwal'),
            ],
            paket: [paketSiap],
          ),
          sesi: _sesiSatu(),
        ),
      );
      await tester.pumpAndSettle();
      // Tidak ada daftar yang bisa menggusur: kalimat menyebut keduanya, ubin
      // alat adalah yang paling lama lewat jadwal, ubin paket menyebut siap.
      expect(find.text('5 alat lewat jadwal.'), findsOneWidget);
      expect(find.text('1 paket siap diambil.'), findsOneWidget);
      expect(find.byType(UbinAlat), findsOneWidget);
      expect(tester.widget<UbinAlat>(find.byType(UbinAlat)).nama, 'Alat 5');
      expect(
        tester
            .widget<UbinRingkas>(
              find.widgetWithText(UbinRingkas, 'Paket dikerjakan'),
            )
            .kalimat,
        contains('1 paket siap diambil'),
      );
    });

    testWidgets('daftar paket dipotong server: kalimat tanpa angka', (
      tester,
    ) async {
      layarHp(tester, lebar: 392, tinggi: 2400);
      await tester.pumpWidget(
        _app(
          _server(
            alat: [alatJson(1, 'Manometer', hari: 100)],
            paket: [paketSiap],
            jumlahPaket: 6,
          ),
          sesi: _sesiSatu(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Ada paket siap diambil.'), findsOneWidget);
      expect(find.text('1 paket siap diambil.'), findsNothing);
    });
  });

  group('keadaan: memuat, galat, 401, offline', () {
    testWidgets('memuat: kerangka statis, lalu isi', (tester) async {
      layarHp(tester, lebar: 392, tinggi: 1600);
      final server = _server(alat: [alatJson(1, 'A', hari: 100)])
        ..jeda = const Duration(seconds: 2);
      await tester.pumpWidget(_app(server, sesi: _sesiSatu()));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(KerangkaBeranda), findsOneWidget);
      // /beranda selesai, lalu /alat (jeda yang sama) menyusul.
      await tester.pump(const Duration(seconds: 3));
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      expect(find.byType(KerangkaBeranda), findsNothing);
      expect(find.text('Tidak ada alat yang lewat jadwal.'), findsOneWidget);
    });

    testWidgets('galat jaringan: kalimat dengan langkah dan Coba lagi', (
      tester,
    ) async {
      layarHp(tester, lebar: 392, tinggi: 1600);
      final server = _server()..gagal.add('/beranda');
      await tester.pumpWidget(_app(server, sesi: _sesiSatu()));
      await sampaiGalat(tester);
      expect(find.byType(KeadaanTeks), findsOneWidget);
      expect(find.text('Beranda belum bisa dimuat'), findsOneWidget);
      expect(find.text('Coba lagi'), findsOneWidget);
    });

    testWidgets('401: sesi berakhir, tanpa tombol yang menyesatkan', (
      tester,
    ) async {
      layarHp(tester, lebar: 392, tinggi: 1600);
      await tester.pumpWidget(_app(_Server401(), sesi: _sesiSatu()));
      await sampaiGalat(tester);
      expect(find.text('Sesi Anda berakhir'), findsOneWidget);
      expect(find.textContaining('Masuk lagi'), findsOneWidget);
      expect(find.text('Coba lagi'), findsNothing);
    });

    testWidgets('offline: pil tanpa koneksi dengan tanggal dan jam', (
      tester,
    ) async {
      layarHp(tester, lebar: 392, tinggi: 1600);
      await tester.pumpWidget(
        _app(_server(alat: [alatJson(1, 'A', hari: 100)]), sesi: _sesiSatu()),
      );
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.wifi_off), findsNothing);

      ProviderScope.containerOf(
        tester.element(find.byType(BerandaScreen)),
      ).read(koneksiProvider.notifier).offline(DateTime(2026, 11, 12, 8, 12));
      await tester.pump();
      // Hari yang sama dengan "hari ini": jam saja.
      expect(find.text('Offline. Data per 08.12.'), findsOneWidget);
      expect(find.byIcon(Icons.wifi_off), findsOneWidget);
      // Data terakhir tetap terbaca di bawah banner.
      expect(find.text('Tidak ada alat yang lewat jadwal.'), findsOneWidget);
    });
  });

  group('tablet: dua kolom, HP: satu kolom', () {
    final data = _server(
      alat: [
        alatJson(1, 'Jangka Sorong', hari: -4, status: 'lewat_jadwal'),
        alatJson(2, 'Timbangan', hari: 12, status: 'mendekati_jadwal'),
      ],
      paket: [
        paketJson(
          21,
          'ORD/ALFA/2026/0021',
          alat: [alatPaketJson(3, 'Mikrometer')],
        ),
      ],
      sertifikat: [sertifikatJson(12, 'CAL/ALFA/0012', diterbitkan: -3)],
    );

    testWidgets('tablet 840: ubin alat dan tombol di kiri; kapsul dan '
        'pasangan di kanan; bantuan penuh di bawah', (tester) async {
      layarTablet(tester);
      await tester.pumpWidget(_app(data, sesi: _sesiSatu()));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final ubin = tester.getTopLeft(find.byType(UbinAlat));
      final kapsul = tester.getTopLeft(find.byType(KapsulJatuhTempo));
      final sertifikat = tester.getTopLeft(
        find.widgetWithText(UbinRingkas, 'Sertifikat terbaru'),
      );
      expect(kapsul.dx, greaterThan(ubin.dx + 200));
      expect(sertifikat.dx, greaterThan(ubin.dx + 200));
      expect(sertifikat.dy, greaterThan(kapsul.dy));
      final hubungi = tester.getTopLeft(
        find.text('Butuh bantuan? Hubungi lab'),
      );
      expect(hubungi.dx, lessThan(kapsul.dx));
      expect(hubungi.dy, greaterThan(sertifikat.dy));
    });

    testWidgets('HP 392: semua bagian satu kolom, menurun', (tester) async {
      layarHp(tester, lebar: 392, tinggi: 2600);
      await tester.pumpWidget(_app(data, sesi: _sesiSatu()));
      await tester.pumpAndSettle();
      final ubin = tester.getTopLeft(find.byType(UbinAlat));
      final kapsul = tester.getTopLeft(find.byType(KapsulJatuhTempo));
      expect(kapsul.dx, lessThan(ubin.dx + 40), reason: "satu kolom");
      expect(kapsul.dy, greaterThan(ubin.dy));
    });
  });

  group('tanpa kata "kedaluwarsa" di keadaan mana pun', () {
    testWidgets('penuh, tenang, kosong, dan galat', (tester) async {
      final kasus = <ServerFitur>[
        _server(
          alat: [alatJson(1, 'A', hari: -4, status: 'lewat_jadwal')],
          sertifikat: [
            sertifikatJson(1, 'CAL/1', berlakuSampai: -5, keputusan: 'FAIL'),
          ],
          paket: [paketJson(2, 'ORD/2', terlambat: true)],
        ),
        _server(alat: [alatJson(1, 'A', hari: 80)]),
        _server(),
        _server()..gagal.add('/beranda'),
      ];
      for (final k in kasus) {
        layarHp(tester, lebar: 392, tinggi: 2600);
        await pasang(tester, _app(k, sesi: _sesiSatu()));
        await sampaiGalat(tester);
        final teks = _semuaTeks(tester);
        expect(teks, isNot(contains('kedaluwarsa')));
        expect(teks, isNot(contains('kadaluarsa')));
        expect(teks, isNot(contains('expired')));
      }
    });

    testWidgets('sertifikat lewat tanggal: "Masa berlaku berakhir" + FAIL '
        'tidak dilunakkan', (tester) async {
      layarHp(tester, lebar: 392, tinggi: 2600);
      await tester.pumpWidget(
        _app(
          _server(
            alat: [alatJson(1, 'A', hari: 100)],
            sertifikat: [
              sertifikatJson(
                1,
                'CAL/1',
                berlakuSampai: -5,
                keputusan: 'FAIL',
                diterbitkan: -400,
              ),
            ],
          ),
          sesi: _sesiSatu(),
        ),
      );
      await tester.pumpAndSettle();
      // Kata-kata ada sebagai stempel (ikon + kata) di ubin "Sertifikat terbaru".
      expect(find.textContaining('Masa berlaku berakhir'), findsOneWidget);
      expect(find.textContaining('Tidak memenuhi toleransi'), findsOneWidget);
    });
  });

  group('klaim jujur: "berlaku" hanya bila server menjaminnya', () {
    testWidgets('pelanggan baru, alat belum pernah dikalibrasi: tidak dibilang '
        '"berlaku"', (tester) async {
      layarHp(tester, lebar: 392, tinggi: 1800);
      await tester.pumpWidget(
        _app(
          _server(
            alat: [
              alatJson(1, 'Alat Baru A', status: 'belum_pernah'),
              alatJson(2, 'Alat Baru B', status: 'belum_pernah'),
            ],
          ),
          sesi: _sesiSatu(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Tidak ada alat yang lewat jadwal.'), findsOneWidget);
      expect(find.text('Semua alat Anda berlaku.'), findsNothing);
      expect(_semuaTeks(tester), isNot(contains('berlaku')));
    });

    testWidgets('server menjamin: alat_berlaku = jumlah_alat', (tester) async {
      layarHp(tester, lebar: 392, tinggi: 1800);
      final server = ServerFitur({
        3: DataPerusahaan(
          nama: 'PT Alfa',
          alat: [alatJson(1, 'A', hari: 100), alatJson(2, 'B', hari: 200)],
          ringkasanTambahan: const {'alat_berlaku': 2, 'alat_belum_pernah': 0},
        ),
      });
      await tester.pumpWidget(_app(server, sesi: _sesiSatu()));
      await tester.pumpAndSettle();
      expect(find.text('Semua alat Anda berlaku.'), findsOneWidget);
    });

    testWidgets(
      'sebagian belum pernah: tanpa klaim, kalimat kedua menyebutnya',
      (tester) async {
        layarHp(tester, lebar: 392, tinggi: 1800);
        final server = ServerFitur({
          3: DataPerusahaan(
            nama: 'PT Alfa',
            alat: [
              alatJson(1, 'A', hari: 100),
              alatJson(2, 'B', status: 'belum_pernah'),
            ],
            ringkasanTambahan: const {
              'alat_berlaku': 1,
              'alat_belum_pernah': 1,
            },
          ),
        });
        await tester.pumpWidget(_app(server, sesi: _sesiSatu()));
        await tester.pumpAndSettle();
        expect(find.text('Semua alat Anda berlaku.'), findsNothing);
        expect(find.text('Tidak ada alat yang lewat jadwal.'), findsOneWidget);
        expect(find.text('1 alat belum pernah dikalibrasi.'), findsOneWidget);
      },
    );
  });

  group('sertifikat baru: batas lima dari server', () {
    ServerFitur dengan(int n, {Map<String, dynamic> ringkasan = const {}}) =>
        ServerFitur({
          3: DataPerusahaan(
            nama: 'PT Alfa',
            alat: [alatJson(1, 'A', hari: 100)],
            sertifikat: [
              for (var i = 1; i <= n; i++)
                sertifikatJson(i, 'CAL/ALFA/$i', diterbitkan: -i),
            ],
            ringkasanTambahan: ringkasan,
          ),
        });

    for (final (n, kalimat) in [
      (4, '4 sertifikat baru terbit.'),
      (5, 'Ada sertifikat baru terbit.'),
      (6, 'Ada sertifikat baru terbit.'),
    ]) {
      testWidgets('$n sertifikat baru dari server: "$kalimat"', (tester) async {
        layarHp(tester, lebar: 392, tinggi: 1800);
        await tester.pumpWidget(_app(dengan(n), sesi: _sesiSatu()));
        await tester.pumpAndSettle();
        expect(find.text(kalimat), findsOneWidget);
        if (n >= 5) {
          expect(find.text('5 sertifikat baru terbit.'), findsNothing);
        }
      });
    }

    testWidgets('hitungan server menang: 12 sertifikat baru (paket 12 alat)', (
      tester,
    ) async {
      layarHp(tester, lebar: 392, tinggi: 1800);
      await tester.pumpWidget(
        _app(
          dengan(5, ringkasan: const {'sertifikat_baru_7_hari': 12}),
          sesi: _sesiSatu(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('12 sertifikat baru terbit.'), findsOneWidget);
    });
  });

  group('paket siap diambil tidak tersingkir diam-diam', () {
    final siap = paketJson(
      20,
      'ORD/ALFA/2026/0020',
      tahap: 'siap_diambil',
      label: 'Siap diambil',
      jumlahSelesai: 1,
      alat: [
        alatPaketJson(
          1,
          'Timbangan',
          tahap: 'siap_diambil',
          label: 'Siap diambil',
        ),
      ],
    );

    testWidgets('paket berjalan lebih banyak dari daftar, tak ada paket siap '
        'terlihat: ubin menyebut jumlahnya dan membuka semua paket', (
      tester,
    ) async {
      final semantik = tester.ensureSemantics();
      layarHp(tester, lebar: 392, tinggi: 1800);
      await tester.pumpWidget(
        _app(
          ServerFitur({
            3: DataPerusahaan(
              nama: 'PT Alfa',
              alat: [alatJson(1, 'A', hari: 100)],
              jumlahPaketBerjalan: 6,
            ),
          }),
          sesi: _sesiSatu(),
        ),
      );
      await tester.pumpAndSettle();
      // Tautan "Lihat semua paket (N)" menjadi ubin "Paket dikerjakan": jumlah
      // di kalimatnya, tujuan di semantiknya.
      expect(
        tester
            .widget<UbinRingkas>(
              find.widgetWithText(UbinRingkas, 'Paket dikerjakan'),
            )
            .kalimat,
        '6 paket berjalan',
      );
      expect(
        find.bySemanticsLabel(RegExp('6 paket berjalan.*Lihat semua paket')),
        findsOneWidget,
      );
      await tester.tap(find.widgetWithText(UbinRingkas, 'Paket dikerjakan'));
      await tester.pumpAndSettle();
      expect(find.byType(PaketScreen), findsOneWidget);
      semantik.dispose();
    });

    testWidgets('lab terlihat dan ada paket tersembunyi: nomor paket terbaru '
        'dan jumlah seluruhnya', (tester) async {
      layarHp(tester, lebar: 392, tinggi: 2000);
      await tester.pumpWidget(
        _app(
          ServerFitur({
            3: DataPerusahaan(
              nama: 'PT Alfa',
              alat: [alatJson(1, 'A', hari: 100)],
              paket: [paketJson(21, 'ORD/ALFA/2026/0021')],
              jumlahPaketBerjalan: 5,
            ),
          }),
          sesi: _sesiSatu(),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<UbinRingkas>(
              find.widgetWithText(UbinRingkas, 'Paket dikerjakan'),
            )
            .kalimat!
            .split('\n'),
        ['ORD/ALFA/2026/0021', 'Sedang dikalibrasi', '5 paket berjalan'],
      );
    });

    testWidgets('tanpa paket tersembunyi dan tanpa paket lab: tidak ada '
        'jumlah tambahan', (tester) async {
      layarHp(tester, lebar: 392, tinggi: 1800);
      await tester.pumpWidget(
        _app(
          _server(alat: [alatJson(1, 'A', hari: 100)], paket: [siap]),
          sesi: _sesiSatu(),
        ),
      );
      await tester.pumpAndSettle();
      // Satu paket berjalan, terlihat semua, sudah siap.
      expect(find.textContaining('paket berjalan'), findsNothing);
      expect(find.text('1 paket siap diambil.'), findsOneWidget);
    });

    testWidgets('hitungan server paket_siap_diambil > yang terlihat: angka '
        'pasti dan jumlah paket', (tester) async {
      layarHp(tester, lebar: 392, tinggi: 2000);
      await tester.pumpWidget(
        _app(
          ServerFitur({
            3: DataPerusahaan(
              nama: 'PT Alfa',
              alat: [alatJson(1, 'A', hari: 100)],
              paket: [siap],
              jumlahPaketBerjalan: 4,
              ringkasanTambahan: const {'paket_siap_diambil': 3},
            ),
          }),
          sesi: _sesiSatu(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('3 paket siap diambil.'), findsOneWidget);
      expect(find.text('Ada paket siap diambil.'), findsNothing);
      expect(
        tester
            .widget<UbinRingkas>(
              find.widgetWithText(UbinRingkas, 'Paket dikerjakan'),
            )
            .kalimat,
        contains('4 paket berjalan'),
      );
    });
  });

  group('garis_waktu dari server (A5): tidak merusak Beranda', () {
    testWidgets('empat langkah dari server: Beranda tampil, tanpa galat', (
      tester,
    ) async {
      layarHp(tester, lebar: 392, tinggi: 1800);
      final alat = alatJson(
        1,
        'Alat Satu',
        hari: -2,
        status: 'lewat_jadwal',
        sedangDikerjakan: {
          ...sedangDikerjakanJson(),
          'garis_waktu': [
            for (final (i, k) in ['diterima', 'dikalibrasi', 'a', 'b'].indexed)
              {'kode': k, 'label': k, 'lewat': i < 1, 'sekarang': i == 1},
          ],
        },
      );
      await tester.pumpWidget(_app(_server(alat: [alat]), sesi: _sesiSatu()));
      await tester.pumpAndSettle();
      // Jumlah tik mengikuti `garis_waktu` server diuji pada widgetnya
      // (`test/widgets/jejak_test.dart`); ubin Beranda tidak menggambar jejak,
      // hanya kata tahapnya.
      expect(tester.takeException(), isNull);
      expect(find.byType(JejakTahap), findsNothing);
      expect(find.text('Di lab: Sedang dikalibrasi'), findsOneWidget);
    });
  });

  group('layar sempit: daftar tidak terdorong keluar layar pertama', () {
    const namaPanjang = 'PT Instrumentasi Presisi Nusantara Sejahtera Abadi';

    /// Tinggi pil "tanpa koneksi" (DecoratedBox terdekat dari teksnya).
    double tinggiBanner(WidgetTester tester, String teks) => tester
        .getSize(
          find
              .ancestor(
                of: find.text(teks),
                matching: find.byType(DecoratedBox),
              )
              .first,
        )
        .height;

    testWidgets('nama PT satu baris (elipsis) di 320 dp x 1,3', (tester) async {
      layarHp(tester, lebar: 320, tinggi: 640);
      await tester.pumpWidget(
        _app(
          ServerFitur({
            3: DataPerusahaan(
              nama: namaPanjang,
              alat: [alatJson(1, 'A', hari: -3, status: 'lewat_jadwal')],
            ),
          }),
          skala: 1.3,
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      // labelMedium 12/16 x 1,3 = 20,8 dp per baris: satu baris.
      expect(tester.getSize(find.text(namaPanjang)).height, lessThan(26));
    });

    testWidgets('banner offline paling banyak dua baris di 320 dp x 1,3', (
      tester,
    ) async {
      layarHp(tester, lebar: 320, tinggi: 640);
      await tester.pumpWidget(
        _app(
          _server(alat: [alatJson(1, 'A', hari: 100)]),
          sesi: _sesiSatu(),
          skala: 1.3,
        ),
      );
      await tester.pumpAndSettle();
      final koneksi = ProviderScope.containerOf(
        tester.element(find.byType(BerandaScreen)),
      ).read(koneksiProvider.notifier);
      // Hari lain dari "hari ini": tanggal ikut tampil (teks paling panjang).
      koneksi.offline(DateTime(2026, 11, 10, 8, 12));
      await tester.pump();
      expect(find.text('Offline. Data per 10 Nov, 08.12.'), findsOneWidget);
      // padding 8 + 8, dua baris bodySmall 20 x 1,3.
      expect(
        tinggiBanner(tester, 'Offline. Data per 10 Nov, 08.12.'),
        lessThanOrEqualTo(16 + 2 * 20 * 1.3 + 0.5),
      );
    });

    testWidgets('offline tanpa waktu data terakhir: tetap dua baris', (
      tester,
    ) async {
      layarHp(tester, lebar: 320, tinggi: 640);
      await tester.pumpWidget(
        _app(
          _server(alat: [alatJson(1, 'A', hari: 100)]),
          sesi: _sesiSatu(),
          skala: 1.3,
        ),
      );
      await tester.pumpAndSettle();
      ProviderScope.containerOf(
        tester.element(find.byType(BerandaScreen)),
      ).read(koneksiProvider.notifier).offline(null);
      await tester.pump();
      expect(find.text('Offline. Data mungkin sudah lama.'), findsOneWidget);
      expect(
        tinggiBanner(tester, 'Offline. Data mungkin sudah lama.'),
        lessThanOrEqualTo(16 + 2 * 20 * 1.3 + 0.5),
      );
    });

    testWidgets('judul ubin "Paket dikerjakan" paling banyak dua baris di '
        '320 dp x 1,3', (tester) async {
      layarHp(tester, lebar: 320, tinggi: 640);
      await tester.pumpWidget(
        _app(
          _server(
            alat: [alatJson(1, 'A', hari: 100)],
            paket: [paketJson(21, 'ORD/ALFA/2026/0021')],
          ),
          sesi: _sesiSatu(),
          skala: 1.3,
        ),
      );
      await tester.pumpAndSettle();
      // titleMedium 17/24 x 1,3 = 31,2 dp per baris.
      expect(
        tester.getSize(find.text('Paket dikerjakan')).height,
        lessThanOrEqualTo(2 * 24 * 1.3 + 0.5),
      );
    });

    testWidgets('tablet: judul ubin paket satu baris', (tester) async {
      layarTablet(tester);
      await tester.pumpWidget(
        _app(
          _server(
            alat: [alatJson(1, 'A', hari: -3, status: 'lewat_jadwal')],
            paket: [paketJson(21, 'ORD/ALFA/2026/0021')],
          ),
          sesi: _sesiSatu(),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester.getSize(find.text('Paket dikerjakan')).height,
        lessThanOrEqualTo(25),
      );
    });
  });

  group('kapsul jadwal: tampil bila ada alat', () {
    testWidgets('ada alat lewat jadwal: kapsul tampil', (tester) async {
      layarHp(tester, lebar: 392, tinggi: 2000);
      await tester.pumpWidget(
        _app(
          _server(alat: [alatJson(1, 'A', hari: -3, status: 'lewat_jadwal')]),
          sesi: _sesiSatu(),
        ),
      );
      await tester.pumpAndSettle();
      // `PetaJatuhTempo` diganti kapsul (KOMPONEN.md Grafik).
      expect(find.byType(KapsulJatuhTempo), findsOneWidget);
      expect(find.byType(PetaJatuhTempo), findsNothing);
    });
  });
}
