import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:sidik_pelanggan/core/api_pelanggan.dart';
import 'package:sidik_pelanggan/core/penyimpan_sesi.dart';
import 'package:sidik_pelanggan/core/theme/sidik_theme.dart';
import 'package:sidik_pelanggan/models/permintaan.dart';
import 'package:sidik_pelanggan/providers/sesi_provider.dart';
import 'package:sidik_pelanggan/screens/akun/preferensi_screen.dart';
import 'package:sidik_pelanggan/screens/permintaan/ajukan_screen.dart';
import 'package:sidik_pelanggan/screens/permintaan/permintaan_detail_screen.dart';
import 'package:sidik_pelanggan/screens/permintaan/permintaan_screen.dart';
import 'package:sidik_pelanggan/services/layanan_pelanggan.dart';

Map<String, dynamic> _json({
  int id = 12,
  String status = 'baru',
  bool dapatDibatalkan = true,
  bool terbuka = true,
  String? alasan,
}) => {
  'id': id,
  'nomor': 'PMT/2026/09/00$id',
  'status': status,
  'metode_pengantaran': 'diantar_sendiri',
  'tanggal_diinginkan_dari': '2026-10-05',
  'tanggal_diinginkan_sampai': '2026-10-09',
  'catatan': 'Tolong diprioritaskan.',
  'diajukan_pada': '2026-09-30T02:11:05Z',
  'diputuskan_pada': null,
  'dibatalkan_pada': null,
  'dapat_dibatalkan': dapatDibatalkan,
  'percakapan_terbuka': terbuka,
  'jumlah_pesan': 1,
  'jumlah_alat': 2,
  'alat': [
    {
      'id': 31,
      'alat_id': 88,
      'baru': false,
      'nama': 'Timbangan Ohaus PX224',
      'merk': 'Ohaus',
      'model': 'PX224',
      'serial': 'C3349',
    },
    {
      'id': 32,
      'alat_id': null,
      'baru': true,
      'nama': 'pH Meter',
      'merk': 'Hanna',
      'model': 'HI2211',
      'serial': 'HI2211-0419',
    },
  ],
  'paket': null,
  'alasan_penolakan': ?alasan,
};

/// Layanan palsu: mencatat panggilan tulis, tanpa jaringan.
class _Palsu extends LayananPelanggan {
  _Palsu() : super(ApiPelanggan());

  Permintaan detail = Permintaan.dariJson(_json());
  DaftarPermintaan daftar = DaftarPermintaan.dariJson({
    'data': [_json(), _json(id: 13, status: 'diterima')],
    'meta': {
      'total': 2,
      'jumlah': {'aktif': 3, 'selesai': 4},
    },
  });
  bool terbuka = true;
  List<PesanPermintaan> pesan = [
    PesanPermintaan.dariJson({
      'id': 5,
      'sisi': 'lab',
      'dari_saya': false,
      'nama_pengirim': 'Tim PT Sidik',
      'isi': 'Alat sudah kami terima.',
      'dibuat_pada': '2026-09-22T03:00:00Z',
    }),
  ];
  PreferensiNotifikasi pref = PreferensiNotifikasi.dariJson({
    'pengingat_jadwal': true,
    'status_permintaan': true,
    'pesan_lab': true,
    'ringkasan_email_mingguan': false,
  });

  final salinanDraft = <DraftPermintaan>[];
  final batal = <int>[];
  final pesanTerkirim = <String>[];
  final simpanPref = <Map<String, bool>>[];
  Object? galatSimpanPref;
  String? saringTerakhir;

  @override
  Future<DaftarPermintaan> daftarPermintaan({String saring = 'aktif'}) async {
    saringTerakhir = saring;
    return daftar;
  }

  @override
  Future<Permintaan> permintaan(int id) async => detail;

  @override
  Future<Permintaan> ajukanPermintaan(DraftPermintaan draft) async {
    salinanDraft.add(draft);
    return detail;
  }

  @override
  Future<Permintaan> batalkanPermintaan(int id) async {
    batal.add(id);
    detail = Permintaan.dariJson(
      _json(status: 'dibatalkan', dapatDibatalkan: false, terbuka: false),
    );
    terbuka = false;
    return detail;
  }

  @override
  Future<UtasPesan> pesanPermintaan(int id) async =>
      UtasPesan(isi: List.of(pesan), terbuka: terbuka);

  @override
  Future<PesanPermintaan> kirimPesan(int id, String isi) async {
    pesanTerkirim.add(isi);
    final baru = PesanPermintaan.dariJson({
      'id': 99,
      'sisi': 'pelanggan',
      'dari_saya': true,
      'nama_pengirim': 'Budi',
      'isi': isi,
      'dibuat_pada': '2026-09-22T03:10:00Z',
    });
    pesan = [...pesan, baru];
    return baru;
  }

  @override
  Future<PreferensiNotifikasi> preferensiNotifikasi() async => pref;

  @override
  Future<PreferensiNotifikasi> simpanPreferensi(
    Map<String, bool> perubahan,
  ) async {
    simpanPref.add(perubahan);
    if (galatSimpanPref != null) throw galatSimpanPref!;
    final e = perubahan.entries.single;
    pref = pref.salinDengan(e.key, e.value);
    return pref;
  }
}

class _SesiKosong extends PenyimpanSesi {
  @override
  Future<String?> token() async => null;
}

Future<void> _pasang(WidgetTester tester, _Palsu palsu, Widget layar) async {
  // Layar tinggi supaya seluruh isi ListView terbangun tanpa menggulir.
  tester.view.physicalSize = const Size(800, 3200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        layananProvider.overrideWithValue(palsu),
        penyimpanSesiProvider.overrideWithValue(_SesiKosong()),
      ],
      child: MaterialApp(
        theme: SidikTheme.terang,
        locale: const Locale('id', 'ID'),
        supportedLocales: const [Locale('id', 'ID')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: layar,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() => initializeDateFormatting('id_ID'));

  group('model', () {
    test('permintaan dibaca dari bentuk kontrak', () {
      final p = Permintaan.dariJson(_json());
      expect(p.status, StatusPermintaan.baru);
      expect(p.metode, MetodePengantaran.diantarSendiri);
      expect(p.dapatDibatalkan, isTrue);
      expect(p.alat, hasLength(2));
      expect(p.alat.last.baru, isTrue);
      expect(p.alat.last.alatId, isNull);
      expect(p.paketId, isNull);
    });

    test('paket & alasan penolakan hanya ada bila dikirim server', () {
      final diterima = Permintaan.dariJson({
        ..._json(status: 'diterima', dapatDibatalkan: false),
        'paket': {'id': 7, 'nomor': 'ORD/2026/09/0007'},
      });
      expect(diterima.paketId, 7);
      expect(diterima.alasanPenolakan, isNull);

      final ditolak = Permintaan.dariJson(
        _json(status: 'ditolak', alasan: 'Di luar cakupan lab.'),
      );
      expect(ditolak.alasanPenolakan, 'Di luar cakupan lab.');
    });

    test('daftar membawa angka tab dari meta.jumlah', () {
      final d = DaftarPermintaan.dariJson({
        'data': [_json()],
        'meta': {
          'total': 1,
          'jumlah': {'aktif': 3, 'selesai': 4},
        },
      });
      expect(d.jumlahAktif, 3);
      expect(d.jumlahSelesai, 4);
      expect(d.isi, hasLength(1));
    });

    test('preferensi: kunci tak dikirim memakai bawaan server', () {
      final p = PreferensiNotifikasi.dariJson({'pesan_lab': false});
      expect(p.pengingatJadwal, isTrue);
      expect(p.pesanLab, isFalse);
      expect(p.ringkasanEmailMingguan, isFalse);
    });
  });

  group('validasi formulir ajukan', () {
    final hariIni = DateTime(2026, 10, 1);

    test('kosong: cara pengantaran dan alat wajib', () {
      final g = const DraftPermintaan().galat(hariIni: hariIni);
      expect(g.keys, containsAll(['metode_pengantaran', 'alat_id']));
    });

    test('tanggal tidak boleh kemarin, akhir tidak boleh sebelum awal', () {
      final g = DraftPermintaan(
        metode: MetodePengantaran.diambilLab,
        dari: DateTime(2026, 9, 30),
        sampai: DateTime(2026, 9, 29),
        alatId: const [1],
      ).galat(hariIni: hariIni);
      expect(g, contains('tanggal_diinginkan_dari'));
      expect(g, contains('tanggal_diinginkan_sampai'));
    });

    test('maksimal 50 alat, terhitung alat terdaftar + alat baru', () {
      final g = DraftPermintaan(
        metode: MetodePengantaran.diambilLab,
        alatId: List.generate(50, (i) => i + 1),
        alatBaru: const [AlatBaru(namaAlat: 'pH Meter')],
      ).galat(hariIni: hariIni);
      expect(g['alat_id'], contains('50'));
    });

    test('alat baru: nama wajib, satuan wajib bila rentang diisi', () {
      final g = DraftPermintaan(
        metode: MetodePengantaran.diambilLab,
        alatBaru: const [
          AlatBaru(namaAlat: ' ', rentangMin: 0, rentangMaks: 14),
        ],
      ).galat(hariIni: hariIni);
      expect(g, contains('alat_baru.0.nama_alat'));
      expect(g, contains('alat_baru.0.satuan'));
    });

    test('rentang maks tidak boleh lebih kecil dari min', () {
      const a = AlatBaru(
        namaAlat: 'pH Meter',
        rentangMin: 10,
        rentangMaks: 2,
        satuan: 'pH',
      );
      expect(a.galat(), contains('rentang_maks'));
    });

    test('nomor seri boleh kosong', () {
      const a = AlatBaru(namaAlat: 'Timbangan');
      expect(a.galat(), isEmpty);
    });
  });

  group('payload ke server', () {
    Future<Map<String, dynamic>> kirim(DraftPermintaan d) async {
      late http.Request diterima;
      final klien = MockClient((r) async {
        diterima = r;
        return http.Response(jsonEncode({'data': _json()}), 201);
      });
      final api = ApiPelanggan(klien: klien, token: 't', perusahaanId: 3);
      await LayananPelanggan(api).ajukanPermintaan(d);
      expect(diterima.method, 'POST');
      expect(diterima.url.path, endsWith('/api/pelanggan/v1/permintaan'));
      // Perusahaan dipilih lewat header, bukan badan.
      expect(diterima.headers['X-Perusahaan-Id'], '3');
      return jsonDecode(diterima.body) as Map<String, dynamic>;
    }

    test('tanpa customer_id; kolom kosong tidak dikirim', () async {
      final badan = await kirim(
        DraftPermintaan(
          metode: MetodePengantaran.diantarSendiri,
          dari: DateTime(2026, 10, 5),
          sampai: DateTime(2026, 10, 9),
          catatan: '  Tolong diprioritaskan.  ',
          alatId: const [88, 91],
          alatBaru: const [
            AlatBaru(
              namaAlat: 'pH Meter',
              merk: 'Hanna',
              rentangMin: 0,
              rentangMaks: 14,
              satuan: 'pH',
              resolusi: 0.01,
            ),
          ],
        ),
      );

      expect(badan.containsKey('customer_id'), isFalse);
      expect(jsonEncode(badan), isNot(contains('customer')));
      expect(badan['metode_pengantaran'], 'diantar_sendiri');
      expect(badan['tanggal_diinginkan_dari'], '2026-10-05');
      expect(badan['tanggal_diinginkan_sampai'], '2026-10-09');
      expect(badan['catatan'], 'Tolong diprioritaskan.');
      expect(badan['alat_id'], [88, 91]);
      final baru = (badan['alat_baru'] as List).single as Map;
      expect(baru['nama_alat'], 'pH Meter');
      expect(baru['rentang_min'], 0);
      expect(baru['rentang_maks'], 14);
      expect(baru['resolusi'], 0.01);
      expect(baru.containsKey('serial_number'), isFalse);
      expect(baru.containsKey('model'), isFalse);
    });

    test('tanpa alat terdaftar, kunci alat_id tidak dikirim', () async {
      final badan = await kirim(
        const DraftPermintaan(
          metode: MetodePengantaran.diambilLab,
          alatBaru: [AlatBaru(namaAlat: 'Timbangan')],
        ),
      );
      expect(badan.containsKey('alat_id'), isFalse);
      expect(badan.containsKey('catatan'), isFalse);
      expect(badan['metode_pengantaran'], 'diambil_lab');
    });
  });

  group('daftar permintaan', () {
    testWidgets('menampilkan angka tab dan kartu, tab Semua menarik ulang', (
      tester,
    ) async {
      final palsu = _Palsu();
      await _pasang(tester, palsu, const PermintaanScreen());

      expect(find.text('Aktif 3'), findsOneWidget);
      expect(find.text('Selesai 4'), findsOneWidget);
      expect(find.text('PMT/2026/09/0012'), findsOneWidget);
      expect(palsu.saringTerakhir, 'aktif');

      await tester.tap(find.text('Semua'));
      await tester.pumpAndSettle();
      expect(palsu.saringTerakhir, 'semua');
    });

    testWidgets('kosong pada tab Aktif menawarkan mengajukan', (tester) async {
      final palsu = _Palsu()
        ..daftar = const DaftarPermintaan(
          isi: [],
          jumlahAktif: 0,
          jumlahSelesai: 0,
          total: 0,
        );
      await _pasang(tester, palsu, const PermintaanScreen());

      expect(find.text('Belum ada permintaan yang berjalan'), findsOneWidget);
      expect(find.text('Ajukan kalibrasi'), findsOneWidget);
    });
  });

  group('ajukan', () {
    testWidgets('formulir kosong ditahan di aplikasi dengan pesan jelas', (
      tester,
    ) async {
      final palsu = _Palsu();
      await _pasang(tester, palsu, const AjukanScreen());

      await tester.tap(find.text('Kirim permintaan'));
      await tester.pumpAndSettle();

      expect(
        find.text('Pilih minimal satu alat, atau tambahkan alat baru.'),
        findsOneWidget,
      );
      expect(find.text('Pilih cara alat sampai ke lab.'), findsOneWidget);
      expect(palsu.salinanDraft, isEmpty);
    });

    testWidgets('alat baru + cara pengantaran terkirim tanpa customer_id', (
      tester,
    ) async {
      final palsu = _Palsu();
      await _pasang(tester, palsu, const AjukanScreen());

      await tester.tap(find.text('Tambah alat baru'));
      await tester.pumpAndSettle();
      // Nama wajib: simpan kosong ditolak.
      await tester.tap(find.text('Simpan alat'));
      await tester.pumpAndSettle();
      expect(find.text('Nama alat wajib diisi.'), findsOneWidget);

      await tester.enterText(
        find.widgetWithText(TextField, 'Nama alat *'),
        'pH Meter',
      );
      await tester.enterText(find.widgetWithText(TextField, 'Merk'), 'Hanna');
      await tester.tap(find.text('Simpan alat'));
      await tester.pumpAndSettle();

      expect(find.text('pH Meter'), findsOneWidget);
      await tester.tap(find.text('Saya antar sendiri ke lab'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Kirim permintaan'));
      await tester.pumpAndSettle();

      final draft = palsu.salinanDraft.single;
      expect(draft.metode, MetodePengantaran.diantarSendiri);
      expect(draft.alatBaru.single.namaAlat, 'pH Meter');
      expect(draft.alatBaru.single.merk, 'Hanna');
      expect(jsonEncode(draft.toJson()), isNot(contains('customer_id')));
      // Berhasil → berpindah ke detail permintaan yang baru lahir.
      expect(find.byType(PermintaanDetailScreen), findsOneWidget);
    });
  });

  group('detail permintaan', () {
    testWidgets('menampilkan alat, pesan, dan tombol batal saat baru', (
      tester,
    ) async {
      final palsu = _Palsu();
      await _pasang(tester, palsu, const PermintaanDetailScreen(id: 12));

      expect(find.text('Timbangan Ohaus PX224'), findsOneWidget);
      expect(find.text('Alat baru'), findsOneWidget);
      expect(find.text('Menunggu ditinjau Tim lab'), findsOneWidget);
      expect(find.text('Alat sudah kami terima.'), findsOneWidget);
      expect(find.text('Batalkan permintaan'), findsOneWidget);
    });

    testWidgets('batal meminta konfirmasi lalu memanggil server', (
      tester,
    ) async {
      final palsu = _Palsu();
      await _pasang(tester, palsu, const PermintaanDetailScreen(id: 12));

      await tester.tap(find.text('Batalkan permintaan'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(palsu.batal, isEmpty);

      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Batalkan permintaan'),
        ),
      );
      await tester.pumpAndSettle();

      expect(palsu.batal, [12]);
      // Sesudah dibatalkan: tombol hilang, percakapan ditutup.
      expect(find.text('Batalkan permintaan'), findsNothing);
      expect(find.text('Dibatalkan'), findsWidgets);
      expect(find.text('Tulis pesan ke lab'), findsNothing);
    });

    testWidgets('kembali dari dialog tidak membatalkan', (tester) async {
      final palsu = _Palsu();
      await _pasang(tester, palsu, const PermintaanDetailScreen(id: 12));

      await tester.tap(find.text('Batalkan permintaan'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Kembali'));
      await tester.pumpAndSettle();

      expect(palsu.batal, isEmpty);
      expect(find.text('Batalkan permintaan'), findsOneWidget);
    });

    testWidgets('tanpa dapat_dibatalkan tidak ada tombol batal', (
      tester,
    ) async {
      final palsu = _Palsu()
        ..detail = Permintaan.dariJson(
          _json(status: 'diterima', dapatDibatalkan: false),
        );
      await _pasang(tester, palsu, const PermintaanDetailScreen(id: 12));

      expect(find.text('Batalkan permintaan'), findsNothing);
    });

    testWidgets('ditolak: alasan tampil dan percakapan ditutup', (
      tester,
    ) async {
      final palsu = _Palsu()
        ..detail = Permintaan.dariJson(
          _json(
            status: 'ditolak',
            dapatDibatalkan: false,
            terbuka: false,
            alasan: 'Di luar cakupan akreditasi.',
          ),
        )
        ..terbuka = false;
      await _pasang(tester, palsu, const PermintaanDetailScreen(id: 12));

      expect(find.text('ALASAN DARI LAB'), findsOneWidget);
      expect(find.text('Di luar cakupan akreditasi.'), findsOneWidget);
      expect(find.text('Tulis pesan ke lab'), findsNothing);
      expect(find.textContaining('Percakapan ditutup'), findsOneWidget);
      // Riwayat tetap terbaca.
      expect(find.text('Alat sudah kami terima.'), findsOneWidget);
    });

    testWidgets('kirim pesan: terkirim, kotak dikosongkan, pesan muncul', (
      tester,
    ) async {
      final palsu = _Palsu();
      await _pasang(tester, palsu, const PermintaanDetailScreen(id: 12));

      await tester.enterText(find.byType(TextField), 'Baik, terima kasih.');
      await tester.tap(find.byTooltip('Kirim pesan'));
      await tester.pumpAndSettle();

      expect(palsu.pesanTerkirim, ['Baik, terima kasih.']);
      expect(find.text('Baik, terima kasih.'), findsOneWidget);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        '',
      );
    });

    testWidgets('pesan kosong tidak dikirim', (tester) async {
      final palsu = _Palsu();
      await _pasang(tester, palsu, const PermintaanDetailScreen(id: 12));

      await tester.enterText(find.byType(TextField), '   ');
      await tester.tap(find.byTooltip('Kirim pesan'));
      await tester.pumpAndSettle();

      expect(palsu.pesanTerkirim, isEmpty);
    });
  });

  group('preferensi notifikasi', () {
    testWidgets('memuat dari server dan menampilkan empat saklar', (
      tester,
    ) async {
      final palsu = _Palsu()
        ..pref = PreferensiNotifikasi.dariJson({
          'pengingat_jadwal': true,
          'status_permintaan': false,
          'pesan_lab': true,
          'ringkasan_email_mingguan': true,
        });
      await _pasang(tester, palsu, const PreferensiScreen());

      final saklar = tester
          .widgetList<SwitchListTile>(find.byType(SwitchListTile))
          .toList();
      expect(saklar.map((s) => s.value), [true, false, true, true]);
      expect(saklar.every((s) => s.onChanged != null), isTrue);
    });

    testWidgets('satu ketukan = satu kunci ke server', (tester) async {
      final palsu = _Palsu();
      await _pasang(tester, palsu, const PreferensiScreen());

      await tester.tap(find.text('Pesan dari lab'));
      await tester.pumpAndSettle();

      expect(palsu.simpanPref, [
        {'pesan_lab': false},
      ]);
      final saklar = tester
          .widgetList<SwitchListTile>(find.byType(SwitchListTile))
          .toList();
      expect(saklar[2].value, isFalse);
      expect(saklar[0].value, isTrue);
    });

    testWidgets('gagal menyimpan mengembalikan saklar ke nilai server', (
      tester,
    ) async {
      final palsu = _Palsu()..galatSimpanPref = GalatApi.jaringan();
      await _pasang(tester, palsu, const PreferensiScreen());

      await tester.tap(find.text('Status permintaan'));
      await tester.pumpAndSettle();

      expect(palsu.simpanPref, hasLength(1));
      final saklar = tester
          .widgetList<SwitchListTile>(find.byType(SwitchListTile))
          .toList();
      expect(saklar[1].value, isTrue);
      expect(find.textContaining('Tidak bisa terhubung'), findsOneWidget);
    });
  });
}
