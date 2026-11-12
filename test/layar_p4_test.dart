// P-4: layar yang sebelumnya tidak ada — ganti sandi, pengaturan notifikasi,
// anggota perusahaan (lihat + nonaktifkan oleh PIC utama), dan pelacakan paket.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:sidik_pelanggan/core/api_pelanggan.dart';
import 'package:sidik_pelanggan/core/theme/sidik_theme.dart';
import 'package:sidik_pelanggan/models/anggota.dart';
import 'package:sidik_pelanggan/models/data_pelanggan.dart';
import 'package:sidik_pelanggan/models/paket.dart';
import 'package:sidik_pelanggan/providers/sesi_provider.dart';
import 'package:sidik_pelanggan/screens/akun/akun_screen.dart';
import 'package:sidik_pelanggan/screens/akun/anggota_screen.dart';
import 'package:sidik_pelanggan/screens/akun/ganti_sandi_screen.dart';
import 'package:sidik_pelanggan/screens/akun/preferensi_notifikasi_screen.dart';
import 'package:sidik_pelanggan/screens/paket/paket_detail_screen.dart';
import 'package:sidik_pelanggan/screens/paket/paket_screen.dart';
import 'package:sidik_pelanggan/services/layanan_pelanggan.dart';
import 'package:sidik_pelanggan/widgets/sidik/sidik_tombol.dart';

import 'dukungan/dukungan.dart';

// ── Fixture (bentuk mengikuti docs/kontrak-api-pelanggan.md) ──────────────

Map<String, dynamic> _anggota(
  int id,
  String nama, {
  String peran = 'staf',
  String status = 'aktif',
  bool saya = false,
}) => {
  'id': id,
  'peran': peran,
  'status': status,
  'bergabung_pada': '2026-09-01T03:00:00+00:00',
  'dinonaktifkan_pada': null,
  'orang': {
    'id': 100 + id,
    'nama': nama,
    'email': '${nama.split(' ').first.toLowerCase()}@contoh.test',
    'telepon': '+62812000$id',
    'jabatan': 'Analis',
  },
  'saya': saya,
};

Map<String, dynamic> _daftarAnggotaJson({String peranSaya = 'pic_utama'}) => {
  'anggota': [
    _anggota(1, 'Budi PIC', peran: 'pic_utama', saya: true),
    _anggota(2, 'Sari Staf'),
    _anggota(3, 'Dedi Lama', status: 'nonaktif'),
  ],
  'undangan_menunggu': [
    {
      'id': 5,
      'email': 'baru@contoh.test',
      'peran': 'staf',
      'kedaluwarsa_pada': '2026-11-19T00:00:00+00:00',
    },
  ],
  'maks_anggota': 50,
  'saya': {'customer_id': 3, 'member_id': 1, 'peran': peranSaya},
};

Map<String, dynamic> _paketJson({
  int id = 1,
  String nomor = 'ORD/2026/11/0001',
  String tahap = 'dikalibrasi',
  String label = 'Sedang dikalibrasi',
  bool terlambat = false,
}) => {
  'id': id,
  'nomor': nomor,
  'tanggal_masuk': '2026-11-03',
  'tanggal_janji_selesai': '2026-11-20',
  'terlambat': terlambat,
  'tahap': tahap,
  'tahap_label': label,
  'jumlah_alat': 2,
  'jumlah_selesai': 1,
  'alat': [
    {
      'id': 11,
      'nama': 'Jangka Sorong',
      'merk': 'Mitutoyo',
      'serial': 'SN-11',
      'tahap': 'sertifikat_terbit',
      'tahap_label': 'Sertifikat sudah terbit',
      'diserahkan_kepada': null,
      'sertifikat_id': 55,
    },
    {
      'id': 12,
      'nama': 'Timbangan Analitik',
      'merk': null,
      'serial': null,
      'tahap': 'dikalibrasi',
      'tahap_label': 'Sedang dikalibrasi',
      'diserahkan_kepada': null,
      'sertifikat_id': null,
    },
  ],
};

Map<String, dynamic> _detailPaketJson() => {
  'data': _paketJson(),
  'garis_waktu': [
    {
      'kode': 'diterima',
      'label': 'Alat diterima lab',
      'lewat': true,
      'sekarang': false,
    },
    {
      'kode': 'dikalibrasi',
      'label': 'Sedang dikalibrasi',
      'lewat': false,
      'sekarang': true,
    },
    {
      'kode': 'menunggu_pemeriksaan',
      'label': 'Hasil sedang diperiksa',
      'lewat': false,
      'sekarang': false,
    },
  ],
};

// ── Layanan palsu ────────────────────────────────────────────────────────

class _Palsu extends LayananUji {
  _Palsu({
    this.peranSaya = 'pic_utama',
    this.galatNonaktifkan,
    this.galatSimpanPreferensi,
    this.galatGantiSandi,
  });

  final String peranSaya;
  final GalatApi? galatNonaktifkan;
  final GalatApi? galatSimpanPreferensi;
  final GalatApi? galatGantiSandi;

  int muatAnggota = 0;
  final dinonaktifkan = <int>[];
  final disimpan = <Map<String, bool>>[];
  final sandi = <({String lama, String baru})>[];
  final cariPaket = <({String? cari, bool selesai})>[];
  var saklar = <String, bool>{
    'pengingat_jadwal': true,
    'status_permintaan': true,
    'pesan_lab': true,
    'ringkasan_email_mingguan': false,
  };

  @override
  Future<DaftarAnggota> anggota() async {
    muatAnggota++;
    return DaftarAnggota.dariJson(_daftarAnggotaJson(peranSaya: peranSaya));
  }

  @override
  Future<void> nonaktifkanAnggota(int idAnggota) async {
    dinonaktifkan.add(idAnggota);
    if (galatNonaktifkan != null) throw galatNonaktifkan!;
  }

  @override
  Future<Map<String, bool>> preferensiNotifikasi() async => saklar;

  @override
  Future<Map<String, bool>> simpanPreferensiNotifikasi(
    Map<String, bool> sebagian,
  ) async {
    disimpan.add(sebagian);
    if (galatSimpanPreferensi != null) throw galatSimpanPreferensi!;
    saklar = {...saklar, ...sebagian};
    return saklar;
  }

  @override
  Future<int> gantiSandi({
    required String sandiLama,
    required String sandiBaru,
  }) async {
    sandi.add((lama: sandiLama, baru: sandiBaru));
    if (galatGantiSandi != null) throw galatGantiSandi!;
    return 2;
  }

  @override
  Future<Halaman<Paket>> daftarPaket({
    String? cari,
    bool selesai = false,
    int halaman = 1,
  }) async {
    cariPaket.add((cari: cari, selesai: selesai));
    return halamanUji([
      Paket.dariJson(_paketJson()),
      Paket.dariJson(
        _paketJson(
          id: 2,
          nomor: 'ORD/2026/11/0002',
          tahap: 'siap_diambil',
          label: 'Siap diambil',
          terlambat: true,
        ),
      ),
    ]);
  }

  @override
  Future<DetailPaket> paket(int id) async {
    if (id == 99) {
      throw const GalatApi(
        status: 404,
        kode: null,
        pesan: ApiPelanggan.pesan404,
      );
    }
    return DetailPaket.dariJson(_detailPaketJson());
  }
}

Widget _layar(Widget layar, _Palsu palsu, {String peran = 'pic_utama'}) =>
    bungkus(
      layar,
      override: overrideDasar(
        tambahan: [
          layananProvider.overrideWithValue(palsu),
          sesiTetap(sesiUji(peran: peran)),
        ],
      ),
    );

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID');
    // Font asli: Ahem bawaan flutter_test selebar kotak dan tidak mewakili
    // lebar teks di HP.
    final inter = FontLoader('Inter');
    for (final f in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
      inter.addFont(
        Future.value(
          ByteData.sublistView(
            File('assets/fonts/Inter-$f.ttf').readAsBytesSync(),
          ),
        ),
      );
    }
    await inter.load();
  });

  group('layanan HTTP', () {
    late http.Request diterima;

    LayananPelanggan layanan(Object jawaban, {int status = 200}) {
      final klien = MockClient((r) async {
        diterima = r;
        return http.Response(
          jsonEncode(jawaban),
          status,
          headers: {'content-type': 'application/json'},
        );
      });
      return LayananPelanggan(ApiPelanggan(klien: klien, jedaUlang: const []));
    }

    test(
      'ganti sandi: POST /saya/ganti-sandi dengan sandi_lama & sandi',
      () async {
        final n = await layanan({
          'message': 'Sandi berhasil diganti.',
          'data': {'sesi_dicabut': 3},
        }).gantiSandi(sandiLama: 'lama-lama-1', sandiBaru: 'baru-baru-22');
        expect(diterima.method, 'POST');
        expect(diterima.url.path, endsWith('/saya/ganti-sandi'));
        expect(jsonDecode(diterima.body), {
          'sandi_lama': 'lama-lama-1',
          'sandi': 'baru-baru-22',
        });
        expect(n, 3);
      },
    );

    test('preferensi: PUT sebagian, jawaban jadi peta bool', () async {
      final hasil = await layanan({
        'data': {
          'pengingat_jadwal': true,
          'status_permintaan': true,
          'pesan_lab': true,
          'ringkasan_email_mingguan': true,
        },
      }).simpanPreferensiNotifikasi({'ringkasan_email_mingguan': true});
      expect(diterima.method, 'PUT');
      expect(diterima.url.path, endsWith('/preferensi-notifikasi'));
      expect(jsonDecode(diterima.body), {'ringkasan_email_mingguan': true});
      expect(hasil['ringkasan_email_mingguan'], isTrue);
    });

    test('nonaktifkan anggota: POST /anggota/{id}/nonaktifkan', () async {
      await layanan({
        'message': 'Anggota dinonaktifkan.',
      }).nonaktifkanAnggota(2);
      expect(diterima.method, 'POST');
      expect(diterima.url.path, endsWith('/anggota/2/nonaktifkan'));
    });

    test('daftar paket: q, selesai, page di query', () async {
      final h = await layanan({
        'data': [_paketJson()],
        'meta': {'current_page': 1, 'last_page': 1, 'total': 1},
      }).daftarPaket(cari: 'ORD/2026', selesai: true, halaman: 2);
      expect(diterima.method, 'GET');
      expect(diterima.url.path, endsWith('/paket'));
      expect(diterima.url.queryParameters, {
        'q': 'ORD/2026',
        'selesai': '1',
        'page': '2',
      });
      expect(h.isi.single.nomor, 'ORD/2026/11/0001');
    });

    test(
      'paket milik PT lain / tidak ada: kalimat umum, tanpa nama model',
      () async {
        final l = layanan({
          'message': 'No query results for model [App\\Models\\Order] 99',
        }, status: 404);
        await expectLater(
          l.paket(99),
          throwsA(
            isA<GalatApi>()
                .having((e) => e.status, 'status', 404)
                .having((e) => e.pesan, 'pesan', ApiPelanggan.pesan404)
                .having(
                  (e) => e.pesan,
                  'tanpa Order',
                  isNot(contains('Order')),
                ),
          ),
        );
      },
    );
  });

  group('model', () {
    test('DaftarAnggota: peran saya dari server, telepon tidak dibaca', () {
      final d = DaftarAnggota.dariJson(_daftarAnggotaJson());
      expect(d.sayaPicUtama, isTrue);
      expect(d.jumlahAktif, 2);
      expect(d.anggota.where((a) => a.saya).single.nama, 'Budi PIC');
      expect(d.anggota.firstWhere((a) => a.id == 3).aktif, isFalse);
      expect(
        DaftarAnggota.dariJson(
          _daftarAnggotaJson(peranSaya: 'staf'),
        ).sayaPicUtama,
        isFalse,
      );
    });

    test('DetailPaket: garis waktu dan alat', () {
      final d = DetailPaket.dariJson(_detailPaketJson());
      expect(d.garisWaktu.map((l) => l.sekarang), [false, true, false]);
      expect(d.paket.alat.first.sertifikatId, 55);
      expect(d.paket.alat.last.sertifikatId, isNull);
    });
  });

  group('Anggota perusahaan', () {
    testWidgets(
      'PIC utama: tombol Nonaktifkan hanya untuk anggota aktif lain',
      (tester) async {
        final palsu = _Palsu();
        await tester.pumpWidget(_layar(const AnggotaScreen(), palsu));
        await tester.pumpAndSettle();

        expect(find.text('Budi PIC (Anda)'), findsOneWidget);
        expect(find.text('Sari Staf'), findsOneWidget);
        expect(find.text('Dedi Lama'), findsOneWidget);
        // Satu saja: Sari. Bukan diri sendiri, bukan yang sudah nonaktif.
        expect(find.text('Nonaktifkan'), findsOneWidget);
        // Nomor HP rekan tidak ditampilkan; undangan terlihat oleh PIC.
        expect(find.textContaining('+62812'), findsNothing);
        expect(find.text('baru@contoh.test'), findsOneWidget);
        expect(find.textContaining('2 dari 50 anggota aktif'), findsOneWidget);
      },
    );

    testWidgets('staf: tanpa tombol ubah dan tanpa daftar undangan', (
      tester,
    ) async {
      final palsu = _Palsu(peranSaya: 'staf');
      await tester.pumpWidget(
        _layar(const AnggotaScreen(), palsu, peran: 'staf'),
      );
      await tester.pumpAndSettle();

      expect(find.text('Sari Staf'), findsOneWidget);
      expect(find.text('Nonaktifkan'), findsNothing);
      expect(find.text('baru@contoh.test'), findsNothing);
      expect(
        find.textContaining('hanya bisa dilakukan PIC utama'),
        findsOneWidget,
      );
    });

    testWidgets(
      'nonaktifkan: konfirmasi dulu, lalu panggil server dan muat ulang',
      (tester) async {
        final palsu = _Palsu();
        await tester.pumpWidget(_layar(const AnggotaScreen(), palsu));
        await tester.pumpAndSettle();
        final awal = palsu.muatAnggota;

        await tester.tap(find.text('Nonaktifkan'));
        await tester.pumpAndSettle();
        expect(find.text('Nonaktifkan Sari Staf?'), findsOneWidget);

        await tester.tap(find.text('Batal'));
        await tester.pumpAndSettle();
        expect(palsu.dinonaktifkan, isEmpty);

        await tester.tap(find.text('Nonaktifkan'));
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(TextButton, 'Nonaktifkan'));
        await tester.pumpAndSettle();

        expect(palsu.dinonaktifkan, [2]);
        expect(palsu.muatAnggota, awal + 1, reason: 'daftar dimuat ulang');
        expect(find.text('Sari Staf dinonaktifkan.'), findsOneWidget);
      },
    );

    testWidgets('galat server ditampilkan, daftar tetap dimuat ulang', (
      tester,
    ) async {
      final palsu = _Palsu(
        galatNonaktifkan: const GalatApi(
          status: 422,
          kode: 'sudah_nonaktif',
          pesan: 'Anggota ini sudah nonaktif.',
        ),
      );
      await tester.pumpWidget(_layar(const AnggotaScreen(), palsu));
      await tester.pumpAndSettle();
      final awal = palsu.muatAnggota;
      await tester.tap(find.text('Nonaktifkan'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Nonaktifkan'));
      await tester.pumpAndSettle();

      expect(find.text('Anggota ini sudah nonaktif.'), findsOneWidget);
      expect(
        palsu.muatAnggota,
        greaterThan(awal),
        reason: 'tetap dimuat ulang',
      );
    });
  });

  group('Pengaturan notifikasi', () {
    bool nilai(WidgetTester t, String kunci) =>
        t.widget<SwitchListTile>(find.byKey(ValueKey('saklar-$kunci'))).value;

    testWidgets('menampilkan saklar yang berfungsi, menyimpan satu kunci', (
      tester,
    ) async {
      final palsu = _Palsu();
      await tester.pumpWidget(
        _layar(const PreferensiNotifikasiScreen(), palsu),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('PT Contoh Pelanggan'), findsOneWidget);
      expect(find.byType(SwitchListTile), findsNWidgets(3));
      expect(find.byKey(const ValueKey('saklar-pesan_lab')), findsNothing);
      expect(nilai(tester, 'ringkasan_email_mingguan'), isFalse);

      await tester.tap(
        find.byKey(const ValueKey('saklar-ringkasan_email_mingguan')),
      );
      await tester.pumpAndSettle();

      expect(palsu.disimpan, [
        {'ringkasan_email_mingguan': true},
      ]);
      expect(nilai(tester, 'ringkasan_email_mingguan'), isTrue);
      expect(nilai(tester, 'pengingat_jadwal'), isTrue);
    });

    testWidgets('gagal simpan: saklar kembali dan pesan tampil', (
      tester,
    ) async {
      final palsu = _Palsu(galatSimpanPreferensi: GalatApi.jaringan());
      await tester.pumpWidget(
        _layar(const PreferensiNotifikasiScreen(), palsu),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('saklar-pengingat_jadwal')));
      await tester.pumpAndSettle();

      expect(nilai(tester, 'pengingat_jadwal'), isTrue, reason: 'dikembalikan');
      expect(find.textContaining('Tidak bisa terhubung'), findsOneWidget);
    });
  });

  group('Ganti sandi', () {
    Future<void> isi(
      WidgetTester t,
      String lama,
      String baru,
      String ulang,
    ) async {
      await t.enterText(find.widgetWithText(TextField, 'Sandi saat ini'), lama);
      await t.enterText(find.widgetWithText(TextField, 'Sandi baru'), baru);
      await t.enterText(
        find.widgetWithText(TextField, 'Ulangi sandi baru'),
        ulang,
      );
      await t.pump();
    }

    Future<void> simpan(WidgetTester t) async {
      await t.tap(find.text('Simpan sandi baru'));
      await t.pumpAndSettle();
    }

    Widget induk(_Palsu palsu) => _layar(
      Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const GantiSandiScreen()),
            ),
            child: const Text('buka'),
          ),
        ),
      ),
      palsu,
    );

    testWidgets('tombol mati sampai ketiga kolom terisi', (tester) async {
      await tester.pumpWidget(_layar(const GantiSandiScreen(), _Palsu()));
      SidikTombol tombol() =>
          tester.widget<SidikTombol>(find.byType(SidikTombol));

      expect(tombol().onPressed, isNull);
      await tester.enterText(
        find.widgetWithText(TextField, 'Sandi saat ini'),
        'x',
      );
      await tester.enterText(find.widgetWithText(TextField, 'Sandi baru'), 'y');
      await tester.pump();
      expect(tombol().onPressed, isNull);
      await tester.enterText(
        find.widgetWithText(TextField, 'Ulangi sandi baru'),
        'y',
      );
      await tester.pump();
      expect(tombol().onPressed, isNotNull);
    });

    testWidgets('pemeriksaan lokal: terlalu pendek dan tidak sama', (
      tester,
    ) async {
      final palsu = _Palsu();
      await tester.pumpWidget(_layar(const GantiSandiScreen(), palsu));

      await isi(tester, 'sandi-lama-1', 'pendek', 'pendek');
      await simpan(tester);
      expect(find.text('Minimal 10 karakter.'), findsOneWidget);

      await isi(tester, 'sandi-lama-1', 'sandi-baru-123', 'sandi-baru-124');
      await simpan(tester);
      expect(find.text('Sandi baru tidak sama.'), findsOneWidget);

      expect(palsu.sandi, isEmpty, reason: 'tidak ada yang dikirim ke server');
    });

    testWidgets('sandi lama salah: galat di kolomnya, layar tetap terbuka', (
      tester,
    ) async {
      final palsu = _Palsu(
        galatGantiSandi: const GalatApi(
          status: 422,
          kode: 'sandi_lama_salah',
          pesan: 'Sandi lama tidak cocok.',
        ),
      );
      await tester.pumpWidget(_layar(const GantiSandiScreen(), palsu));
      await isi(tester, 'sandi-lama-1', 'sandi-baru-123', 'sandi-baru-123');
      await simpan(tester);

      expect(find.text('Sandi lama tidak cocok.'), findsOneWidget);
      expect(find.byType(GantiSandiScreen), findsOneWidget);
    });

    testWidgets(
      'berhasil: kirim kedua sandi, tutup layar, beri tahu sesi lain',
      (tester) async {
        final palsu = _Palsu();
        await tester.pumpWidget(induk(palsu));
        await tester.tap(find.text('buka'));
        await tester.pumpAndSettle();

        await isi(tester, 'sandi-lama-1', 'sandi-baru-123', 'sandi-baru-123');
        await simpan(tester);

        expect(palsu.sandi.single, (
          lama: 'sandi-lama-1',
          baru: 'sandi-baru-123',
        ));
        expect(find.byType(GantiSandiScreen), findsNothing);
        expect(
          find.text('Sandi diganti. 2 sesi di perangkat lain diakhiri.'),
          findsOneWidget,
        );
        // Sandi tidak tampil di mana pun di layar.
        expect(find.textContaining('sandi-baru-123'), findsNothing);
      },
    );
  });

  group('Pelacakan paket', () {
    testWidgets('daftar: nomor, tahap dari server, saklar Selesai', (
      tester,
    ) async {
      final palsu = _Palsu();
      await tester.pumpWidget(_layar(const PaketScreen(), palsu));
      await tester.pumpAndSettle();

      expect(find.text('ORD/2026/11/0001'), findsOneWidget);
      expect(find.text('Sedang dikalibrasi'), findsOneWidget);
      expect(find.text('Siap diambil'), findsOneWidget);
      expect(find.text('1 dari 2 alat selesai'), findsNWidgets(2));
      expect(find.text('Melewati target selesai'), findsOneWidget);
      expect(palsu.cariPaket.last, (cari: '', selesai: false));

      await tester.tap(find.widgetWithText(ChoiceChip, 'Selesai'));
      await tester.pumpAndSettle();
      expect(palsu.cariPaket.last.selesai, isTrue);
    });

    testWidgets(
      'detail: garis waktu, alat, dan tautan sertifikat hanya bila terbit',
      (tester) async {
        tester.view.physicalSize = const Size(800, 2400);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final palsu = _Palsu();
        await tester.pumpWidget(_layar(const PaketScreen(), palsu));
        await tester.pumpAndSettle();
        await tester.tap(find.text('ORD/2026/11/0001'));
        await tester.pumpAndSettle();

        expect(find.text('Perkembangan'.toUpperCase()), findsOneWidget);
        expect(find.text('Alat diterima lab'), findsOneWidget);
        expect(find.text('Sekarang'), findsOneWidget);
        expect(find.text('Jangka Sorong'), findsOneWidget);
        expect(find.text('Timbangan Analitik'), findsOneWidget);
        expect(find.text('Lihat sertifikat'), findsOneWidget);
      },
    );

    testWidgets('detail paket yang tidak boleh dilihat: kalimat umum', (
      tester,
    ) async {
      await tester.pumpWidget(
        _layar(const PaketDetailScreen(id: 99), _Palsu()),
      );
      await tester.pumpAndSettle();
      expect(find.text(ApiPelanggan.pesan404), findsOneWidget);
      expect(find.textContaining('403'), findsNothing);
      expect(find.textContaining('ditolak'), findsNothing);
    });
  });

  group('menu Akun', () {
    testWidgets('membuka keempat layar baru', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final palsu = _Palsu();

      for (final (judul, tipe) in <(String, Type)>[
        ('Pelacakan paket', PaketScreen),
        ('Anggota perusahaan', AnggotaScreen),
        ('Pengaturan notifikasi', PreferensiNotifikasiScreen),
        ('Ganti sandi', GantiSandiScreen),
      ]) {
        await tester.pumpWidget(_layar(const AkunScreen(), palsu));
        await tester.pumpAndSettle();
        await tester.tap(find.text(judul));
        await tester.pumpAndSettle();
        expect(find.byType(tipe), findsOneWidget, reason: judul);
        await tester.pumpWidget(const SizedBox());
      }
    });
  });

  group('layar ditutup selagi permintaan berjalan', () {
    // Pemakai menekan Kembali sebelum server menjawab. Tidak boleh ada
    // pemakaian `ref`/`Navigator` milik State yang sudah dilepas.
    Widget induk(Widget layar, _PalsuTertahan palsu) => _layar(
      Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute<void>(builder: (_) => layar)),
            child: const Text('buka'),
          ),
        ),
      ),
      palsu,
    );

    testWidgets('Anggota: nonaktifkan lalu layar ditutup, jawaban datang', (
      tester,
    ) async {
      final palsu = _PalsuTertahan();
      await tester.pumpWidget(induk(const AnggotaScreen(), palsu));
      await tester.tap(find.text('buka'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Nonaktifkan'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Nonaktifkan'));
      await tester.pump();
      expect(palsu.dinonaktifkan, [2], reason: 'permintaan sedang berjalan');

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(AnggotaScreen), findsNothing);

      palsu.tahan.complete();
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Sari Staf dinonaktifkan.'), findsOneWidget);
    });

    testWidgets('Ganti sandi: layar ditutup sebelum server menjawab', (
      tester,
    ) async {
      final palsu = _PalsuTertahan();
      await tester.pumpWidget(induk(const GantiSandiScreen(), palsu));
      await tester.tap(find.text('buka'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextField, 'Sandi saat ini'),
        'sandi-lama-1',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Sandi baru'),
        'sandi-baru-123',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Ulangi sandi baru'),
        'sandi-baru-123',
      );
      await tester.pump();
      await tester.tap(find.text('Simpan sandi baru'));
      await tester.pump();
      expect(palsu.sandi, hasLength(1));

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(GantiSandiScreen), findsNothing);

      palsu.tahan.complete();
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      // Induk tetap berdiri: tidak ada pop kedua yang menutup yang salah.
      expect(find.text('buka'), findsOneWidget);
    });
  });

  group('undangan menunggu hanya untuk PIC utama', () {
    test('staf: daftar undangan dibuang di model', () {
      final staf = DaftarAnggota.dariJson(
        _daftarAnggotaJson(peranSaya: 'staf'),
      );
      expect(staf.undangan, isEmpty);
      final pic = DaftarAnggota.dariJson(_daftarAnggotaJson());
      expect(pic.undangan.single.email, 'baru@contoh.test');
    });
  });

  group('layar sempit: 320 dp, huruf 1,3×', () {
    // Nama dan nomor panjang sengaja: itulah yang meluap di HP murah.
    const panjang = 'Bernadette Kusumawardhani Wicaksono Prabandaru';

    void sempit(WidgetTester tester) {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
    }

    Widget bungkusSempit(Widget layar, _Palsu palsu) => ProviderScope(
      overrides: overrideDasar(
        tambahan: [
          layananProvider.overrideWithValue(palsu),
          sesiTetap(sesiUji(peran: 'pic_utama')),
        ],
      ),
      child: MaterialApp(
        theme: SidikTheme.terang,
        builder: (context, child) => MediaQuery.withClampedTextScaling(
          minScaleFactor: 1.3,
          maxScaleFactor: 1.3,
          child: child!,
        ),
        home: layar,
      ),
    );

    Future<void> periksa(WidgetTester t, Widget layar, _Palsu palsu) async {
      sempit(t);
      await t.pumpWidget(bungkusSempit(layar, palsu));
      await t.pumpAndSettle();
      // Gulir sampai bawah: luapan di ujung daftar juga harus ketahuan.
      await t.drag(find.byType(Scrollable).first, const Offset(0, -3000));
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
    }

    testWidgets('Anggota perusahaan', (tester) async {
      await periksa(tester, const AnggotaScreen(), _PalsuPanjang(panjang));
    });

    testWidgets('Pengaturan notifikasi', (tester) async {
      await periksa(
        tester,
        const PreferensiNotifikasiScreen(),
        _PalsuPanjang(panjang),
      );
    });

    testWidgets('Ganti sandi', (tester) async {
      await periksa(tester, const GantiSandiScreen(), _PalsuPanjang(panjang));
    });

    testWidgets('Pelacakan paket (daftar)', (tester) async {
      await periksa(tester, const PaketScreen(), _PalsuPanjang(panjang));
    });

    testWidgets('Detail paket', (tester) async {
      await periksa(
        tester,
        const PaketDetailScreen(id: 1),
        _PalsuPanjang(panjang),
      );
    });
  });
}

/// Fixture dengan nama, nomor, dan label yang sangat panjang.
class _PalsuPanjang extends _Palsu {
  _PalsuPanjang(this.panjang);

  final String panjang;

  @override
  Future<DaftarAnggota> anggota() async => DaftarAnggota.dariJson({
    ..._daftarAnggotaJson(),
    'anggota': [
      _anggota(1, panjang, peran: 'pic_utama', saya: true),
      _anggota(2, '$panjang Kedua'),
      _anggota(3, '$panjang Ketiga', status: 'nonaktif'),
    ],
  });

  Map<String, dynamic> _paketPanjang() => {
    ..._paketJson(
      nomor: 'ORD/2026/11/0001-REVISI-TAMBAHAN-PANJANG-SEKALI-0001',
      label: 'Sedang dikerjakan ulang oleh laboratorium',
      terlambat: true,
    ),
    'alat': [
      {
        'id': 11,
        'nama': 'Digital Pressure Calibrator Multifungsi Presisi Tinggi',
        'merk': 'Fluke Calibration International',
        'serial': 'SN-2026-0000001-ABCDEFGH-IJKLMN',
        'tahap': 'diserahkan',
        'tahap_label': 'Sudah diserahkan kepada pemilik alat',
        'diserahkan_kepada': panjang,
        'sertifikat_id': 55,
      },
    ],
  };

  @override
  Future<Halaman<Paket>> daftarPaket({
    String? cari,
    bool selesai = false,
    int halaman = 1,
  }) async => halamanUji([Paket.dariJson(_paketPanjang())]);

  @override
  Future<DetailPaket> paket(int id) async => DetailPaket.dariJson({
    'data': _paketPanjang(),
    'garis_waktu': [
      {
        'kode': 'dikalibrasi',
        'label': 'Sedang dikerjakan ulang oleh laboratorium',
        'lewat': false,
        'sekarang': true,
      },
    ],
  });
}

/// Permintaan tulis yang baru selesai ketika test menyuruhnya ([tahan]).
class _PalsuTertahan extends _Palsu {
  final tahan = Completer<void>();

  @override
  Future<void> nonaktifkanAnggota(int idAnggota) async {
    dinonaktifkan.add(idAnggota);
    await tahan.future;
  }

  @override
  Future<int> gantiSandi({
    required String sandiLama,
    required String sandiBaru,
  }) async {
    sandi.add((lama: sandiLama, baru: sandiBaru));
    await tahan.future;
    return 1;
  }
}
