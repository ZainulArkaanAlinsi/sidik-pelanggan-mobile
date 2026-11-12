// P-1a: terima-undangan dengan email yang sudah punya akun harus memberi tahu.
// P-1b: dialog pembaruan wajib punya jalan keluar akun.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:sidik_pelanggan/core/api_pelanggan.dart';
import 'package:sidik_pelanggan/models/akun.dart';
import 'package:sidik_pelanggan/models/rilis_aplikasi.dart';
import 'package:sidik_pelanggan/providers/pembaruan_provider.dart';
import 'package:sidik_pelanggan/providers/sesi_provider.dart';
import 'package:sidik_pelanggan/screens/auth/terima_undangan_screen.dart';
import 'package:sidik_pelanggan/screens/gerbang.dart';
import 'package:sidik_pelanggan/screens/rangka.dart';
import 'package:sidik_pelanggan/services/klien_rilis.dart';
import 'package:sidik_pelanggan/services/layanan_pelanggan.dart';

import 'dukungan/dukungan.dart';

Map<String, dynamic> _akunJson({
  String nama = 'Budi Diundang',
  List<String> perusahaan = const ['PT Contoh Pelanggan'],
}) => {
  'id': 7,
  'nama': nama,
  'email': 'budi@contoh.test',
  'status': 'aktif',
  'butuh_verifikasi': false,
  'keanggotaan': [
    for (final (i, p) in perusahaan.indexed)
      {'customer_id': 10 + i, 'nama_perusahaan': p, 'peran': 'staf'},
  ],
};

Akun _akun({
  String nama = 'Budi Diundang',
  List<String> perusahaan = const ['PT Contoh Pelanggan'],
}) => Akun.dariJson(_akunJson(nama: nama, perusahaan: perusahaan));

/// Layanan palsu yang menjawab terima-undangan dengan [akun], dan merekam
/// panggilan keluar.
class _Palsu extends LayananUji {
  _Palsu(this.akun, {this.galat});

  final Akun akun;
  final GalatApi? galat;
  int keluarDipanggil = 0;

  @override
  Future<SesiBaru> terimaUndangan({
    required String email,
    required String kode,
    required String nama,
    required String telepon,
    String? jabatan,
    required String sandi,
    required bool setujuSyarat,
  }) async {
    if (galat != null) throw galat!;
    return SesiBaru(
      'token-uji',
      akun,
      akunSudahAda: tampakAkunLama(nama, akun),
    );
  }

  @override
  Future<void> keluar() async => keluarDipanggil++;

  @override
  Future<Akun> saya() async => akun;
}

class _KlienWajib extends KlienRilisMati {
  @override
  Future<RilisAplikasi?> ambilTerbaru() async => RilisAplikasi(
    versi: '2.0.0',
    build: 2,
    url: Uri.parse('https://github.com/x/y/releases/download/v2/a.apk'),
    sha256: 'a' * 64,
    wajib: true,
  );
}

Future<void> _isiFormulir(WidgetTester tester, {required String nama}) async {
  Future<void> isi(String label, String nilai) => tester.enterText(
    find.widgetWithText(TextField, label, skipOffstage: false),
    nilai,
  );
  await isi('Email', 'budi@contoh.test');
  await isi('Kode undangan', 'K7M2QP4R');
  await isi('Nama lengkap', nama);
  await isi('Nomor HP', '081234567890');
  await isi('Buat sandi', 'Kalibrasi#2026Sidik');
  final cek = find.byType(CheckboxListTile);
  await tester.tap(cek);
  await tester.pump();
}

Widget _layarUndangan(_Palsu palsu) => bungkus(
  Builder(
    builder: (context) => Scaffold(
      body: Center(
        child: TextButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const TerimaUndanganScreen(),
            ),
          ),
          child: const Text('buka-undangan'),
        ),
      ),
    ),
  ),
  override: overrideDasar(tambahan: [layananProvider.overrideWithValue(palsu)]),
);

Future<void> _kirim(WidgetTester tester) async {
  final tombol = find.text('Buat akun & masuk');
  await tester.tap(tombol);
  await tester.pumpAndSettle();
}

/// Layar tinggi: formulir undangan panjang dan ListView membangun butirnya
/// malas, jadi kotak centang / tombol bawah tidak ada di pohon kalau luput.
void _layarTinggi(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  setUpAll(() => initializeDateFormatting('id_ID'));

  group('P-1a deteksi akun lama', () {
    test('akun baru: satu perusahaan dan nama sama (spasi/huruf besar tak '
        'dihitung) = bukan akun lama', () {
      expect(tampakAkunLama('Budi Diundang', _akun()), isFalse);
      expect(tampakAkunLama('  budi   diundang ', _akun()), isFalse);
    });

    test('nama di jawaban beda dari isian = akun lama', () {
      expect(tampakAkunLama('Nama Baru Diabaikan', _akun()), isTrue);
    });

    test('lebih dari satu perusahaan = akun lama walau nama sama', () {
      final a = _akun(perusahaan: ['PT Satu', 'PT Dua']);
      expect(tampakAkunLama('Budi Diundang', a), isTrue);
    });

    test(
      'LayananPelanggan.terimaUndangan: kirim isian, tandai akun lama',
      () async {
        late http.Request diterima;
        final klien = MockClient((r) async {
          diterima = r;
          return http.Response(
            jsonEncode({
              'data': {'token': 'tkn', 'user': _akunJson(nama: 'Budi Lama')},
            }),
            201,
            headers: {'content-type': 'application/json'},
          );
        });
        final layanan = LayananPelanggan(
          ApiPelanggan(klien: klien, jedaUlang: const []),
        );
        final sesi = await layanan.terimaUndangan(
          email: ' budi@contoh.test ',
          kode: 'K7M2QP4R',
          nama: 'Nama Baru Diabaikan',
          telepon: '0812',
          sandi: 'Kalibrasi#2026Sidik',
          setujuSyarat: true,
        );
        expect(diterima.url.path, endsWith('/auth/terima-undangan'));
        expect(jsonDecode(diterima.body)['email'], 'budi@contoh.test');
        expect(sesi.akunSudahAda, isTrue);
        expect(sesi.token, 'tkn');
      },
    );
  });

  group('P-1a layar terima undangan', () {
    testWidgets('akun lama: dialog menjelaskan, lalu layar menyingkir', (
      tester,
    ) async {
      _layarTinggi(tester);
      await tester.pumpWidget(_layarUndangan(_Palsu(_akun(nama: 'Budi Lama'))));
      await tester.tap(find.text('buka-undangan'));
      await tester.pumpAndSettle();

      await _isiFormulir(tester, nama: 'Nama Yang Baru Diketik');
      await _kirim(tester);

      expect(find.text('Email ini sudah punya akun'), findsOneWidget);
      expect(find.textContaining('tidak dipakai'), findsOneWidget);
      // Tidak membocorkan nama akun lama maupun perusahaan.
      expect(find.textContaining('Budi Lama'), findsNothing);
      expect(find.textContaining('PT Contoh'), findsNothing);

      await tester.tap(find.text('Mengerti'));
      await tester.pumpAndSettle();
      expect(find.text('Pakai kode undangan'), findsNothing);
    });

    testWidgets(
      'email akun internal ditolak server: pesan server tampil, layar tetap',
      (tester) async {
        _layarTinggi(tester);
        final palsu = _Palsu(
          _akun(),
          galat: const GalatApi(
            status: 422,
            kode: 'undangan_akun_internal',
            pesan:
                'Email ini terdaftar sebagai akun internal PT Sidik dan tidak bisa menerima undangan.',
          ),
        );
        await tester.pumpWidget(_layarUndangan(palsu));
        await tester.tap(find.text('buka-undangan'));
        await tester.pumpAndSettle();

        await _isiFormulir(tester, nama: 'Budi Diundang');
        await _kirim(tester);

        expect(find.textContaining('akun internal PT Sidik'), findsOneWidget);
        expect(find.text('Email ini sudah punya akun'), findsNothing);
        expect(find.text('Pakai kode undangan'), findsOneWidget);
      },
    );

    testWidgets('akun baru: tanpa dialog, layar langsung menyingkir', (
      tester,
    ) async {
      _layarTinggi(tester);
      await tester.pumpWidget(_layarUndangan(_Palsu(_akun())));
      await tester.tap(find.text('buka-undangan'));
      await tester.pumpAndSettle();

      await _isiFormulir(tester, nama: 'Budi Diundang');
      await _kirim(tester);

      expect(find.text('Email ini sudah punya akun'), findsNothing);
      expect(find.text('Pakai kode undangan'), findsNothing);
    });
  });

  group('P-1b dialog pembaruan wajib', () {
    testWidgets('punya Keluar dari akun: konfirmasi, keluar, dialog tertutup', (
      tester,
    ) async {
      final palsu = _Palsu(_akun());
      final sesi = PenyimpanSesiMemori(tokenAwal: 'tkn', penggunaAwal: 7);
      _layarTinggi(tester);
      await tester.pumpWidget(
        bungkus(
          const Rangka(),
          override: overrideDasar(
            sesi: sesi,
            pembaruanAktif: true,
            tambahan: [
              layananProvider.overrideWithValue(palsu),
              klienRilisProvider.overrideWithValue(_KlienWajib()),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Pembaruan wajib'), findsOneWidget);
      expect(find.text('Keluar dari akun'), findsOneWidget);

      // Konfirmasi dulu; Batal tidak mengeluarkan siapa pun.
      await tester.tap(find.text('Keluar dari akun'));
      await tester.pumpAndSettle();
      expect(find.text('Keluar dari akun?'), findsOneWidget);
      await tester.tap(find.text('Batal'));
      await tester.pumpAndSettle();
      expect(palsu.keluarDipanggil, 0);
      expect(find.text('Pembaruan wajib'), findsOneWidget);

      await tester.tap(find.text('Keluar dari akun'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Keluar'));
      await tester.pumpAndSettle();

      expect(palsu.keluarDipanggil, 1);
      expect(sesi.tokenAwal, isNull, reason: 'token lokal dibuang');
      expect(find.text('Pembaruan wajib'), findsNothing);

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('dialog tetap tidak bisa ditutup dengan tombol kembali', (
      tester,
    ) async {
      _layarTinggi(tester);
      await tester.pumpWidget(
        bungkus(
          const Rangka(),
          override: overrideDasar(
            sesi: PenyimpanSesiMemori(tokenAwal: 'tkn', penggunaAwal: 7),
            pembaruanAktif: true,
            tambahan: [
              layananProvider.overrideWithValue(_Palsu(_akun())),
              klienRilisProvider.overrideWithValue(_KlienWajib()),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Pembaruan wajib'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });
  });

  test(
    'keluar sebelum sesi dipulihkan: POST /auth/keluar tetap membawa token',
    () async {
      final masuk = <http.Request>[];
      final klien = MockClient((q) async {
        masuk.add(q);
        if (q.url.path.endsWith('/saya')) {
          return http.Response(
            jsonEncode({'kode': 'versi_aplikasi_usang', 'message': 'usang'}),
            426,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('{}', 200);
      });
      final c = ProviderContainer(
        overrides: overrideDasar(
          sesi: PenyimpanSesiMemori(tokenAwal: 'tkn-uji', penggunaAwal: 7),
          tambahan: [
            apiProvider.overrideWithValue(
              ApiPelanggan(klien: klien, jedaUlang: const []),
            ),
          ],
        ),
      );
      addTearDown(c.dispose);

      // Sesi TIDAK dibaca/ditunggu: persis keadaan layar gerbang.
      await c.read(sesiProvider.notifier).keluar();

      final keluar = masuk.where((r) => r.url.path.endsWith('/auth/keluar'));
      expect(keluar, hasLength(1));
      expect(keluar.single.headers['Authorization'], 'Bearer tkn-uji');
    },
  );

  group('P-1b layar wajib perbarui (gerbang versi minimum)', () {
    Future<void> buka(
      WidgetTester tester,
      _PalsuGerbang palsu,
      PenyimpanSesiMemori sesi,
    ) async {
      await tester.pumpWidget(
        bungkus(
          const LayarWajibPerbarui(terpasang: '0.1.0', terbaru: '9.9.9'),
          override: overrideDasar(
            sesi: sesi,
            tambahan: [layananProvider.overrideWithValue(palsu)],
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets(
      'ada token: tombol keluar; keluar menunggu pemulihan sesi (GET /saya '
      'yang dijawab 426) lalu mencabut token',
      (tester) async {
        final palsu = _PalsuGerbang();
        final sesi = PenyimpanSesiMemori(tokenAwal: 'tkn', penggunaAwal: 7);
        await buka(tester, palsu, sesi);

        // Sesi belum disentuh siapa pun: pemulihannya baru jalan saat keluar.
        expect(palsu.urutan, isEmpty);
        expect(find.text('Keluar dari akun'), findsOneWidget);

        await tester.tap(find.text('Keluar dari akun'));
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(TextButton, 'Keluar'));
        await tester.pumpAndSettle();

        // `keluar` TIDAK boleh mendahului pemulihan: saat itu token belum
        // terpasang di klien dan POST-nya melayang tanpa token.
        expect(palsu.urutan, ['saya-mulai', 'saya-426', 'keluar']);
        expect(sesi.tokenAwal, isNull);
        expect(find.text('Keluar dari akun'), findsNothing);
        // Layarnya tetap layar wajib perbarui (bukan rute yang bisa ditutup).
        expect(find.byType(LayarWajibPerbarui), findsOneWidget);
      },
    );

    testWidgets('tanpa token tersimpan: tidak ada tombol keluar', (
      tester,
    ) async {
      final palsu = _PalsuGerbang();
      await buka(tester, palsu, PenyimpanSesiMemori());

      expect(find.text('Keluar dari akun'), findsNothing);
      expect(palsu.urutan, isEmpty, reason: 'tidak ada panggilan jaringan');
    });
  });
}

/// Server untuk versi usang: `GET /saya` dijawab 426, bukan sesi.
class _PalsuGerbang extends LayananUji {
  final urutan = <String>[];

  @override
  Future<Akun> saya() async {
    urutan.add('saya-mulai');
    await Future<void>.delayed(const Duration(milliseconds: 100));
    urutan.add('saya-426');
    throw const GalatApi(
      status: 426,
      kode: 'versi_aplikasi_usang',
      pesan: 'Versi aplikasi sudah tidak didukung.',
    );
  }

  @override
  Future<void> keluar() async => urutan.add('keluar');
}
