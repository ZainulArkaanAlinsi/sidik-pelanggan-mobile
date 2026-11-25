// P-1 lanjutan: terima-undangan untuk email yang SUDAH punya akun, menurut
// kontrak server sejak 12 Nov 2026 (API `docs/kontrak-api-pelanggan.md` §1 dan
// §11; serah terima ke aplikasi: `docs/perintah-frontend-undangan-akun-lama.md`).
//
// Yang dijaga di sini:
// - `data.akun_sudah_ada` dari server dibaca (bukan ditebak dari jawaban);
// - galat bercabang pada `kode`, bukan pada isi `message`:
//   `sandi_akun_lama_salah` tampil di kolom sandi + jalan ke Lupa sandi;
//   `undangan_organisasi_berbeda`, `akun_nonaktif`, `email_belum_diverifikasi`
//   mengarah ke kontak PT SIDIK (bukan "Minta kode baru");
// - teks DRAF (menunggu persetujuan pemilik per layar): petunjuk di bawah kolom
//   sandi dan teks dialog "Email ini sudah punya akun".
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:sidik_pelanggan/core/api_pelanggan.dart';
import 'package:sidik_pelanggan/models/akun.dart';
import 'package:sidik_pelanggan/providers/sesi_provider.dart';
import 'package:sidik_pelanggan/screens/auth/kerangka_auth.dart';
import 'package:sidik_pelanggan/screens/auth/lupa_sandi_screen.dart';
import 'package:sidik_pelanggan/screens/auth/terima_undangan_screen.dart';
import 'package:sidik_pelanggan/services/layanan_pelanggan.dart';
import 'package:sidik_pelanggan/widgets/kolom_isian.dart';

import 'dukungan/dukungan.dart';
import 'dukungan/layar_uji.dart';

Map<String, dynamic> _akunJson({String nama = 'Budi Diundang'}) => {
  'id': 7,
  'nama': nama,
  'email': 'budi@contoh.test',
  'status': 'aktif',
  'butuh_verifikasi': false,
  'keanggotaan': [
    {'customer_id': 10, 'nama_perusahaan': 'PT Contoh', 'peran': 'staf'},
  ],
};

/// Jawab 201 `terima-undangan` seperti server: [bendera] = isi
/// `data.akun_sudah_ada`, atau `null` = kunci tidak dikirim (server lama).
LayananPelanggan _layananDenganJawaban({
  required String namaDiAkun,
  required bool? bendera,
}) {
  final klien = MockClient(
    (r) async => http.Response(
      jsonEncode({
        'data': {
          'token': 'tkn',
          'user': _akunJson(nama: namaDiAkun),
          'akun_sudah_ada': ?bendera,
        },
      }),
      201,
      headers: {'content-type': 'application/json'},
    ),
  );
  return LayananPelanggan(ApiPelanggan(klien: klien, jedaUlang: const []));
}

Future<SesiBaru> _terima(LayananPelanggan layanan, {String nama = 'Budi'}) =>
    layanan.terimaUndangan(
      email: 'budi@contoh.test',
      kode: 'K7M2QP4R',
      nama: nama,
      telepon: '0812',
      sandi: 'Kalibrasi#2026Sidik',
      setujuSyarat: true,
    );

/// Sesi palsu: menolak dengan [galat] atau menjawab [akunSudahAda].
class _Sesi extends SesiController {
  _Sesi({this.galat, this.akunSudahAda = false});

  final GalatApi? galat;
  final bool akunSudahAda;

  @override
  Future<Sesi?> build() async => null;

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
    if (galat != null) throw galat!;
    return akunSudahAda;
  }
}

const _kontak = InfoAplikasi(email: 'lab@contoh.test');

Widget _layar(_Sesi sesi, {InfoAplikasi info = InfoAplikasi.kosong}) => bungkus(
  const TerimaUndanganScreen(),
  override: overrideDasar(
    tambahan: [
      sesiProvider.overrideWith(() => sesi),
      infoAplikasiProvider.overrideWith((ref) async => info),
      layananProvider.overrideWithValue(LayananUji()),
    ],
  ),
);

Finder _kolom(String label) => find.descendant(
  of: find.widgetWithText(KolomIsian, label, skipOffstage: false),
  matching: find.byType(TextField),
  skipOffstage: false,
);

/// Isi formulir (kecuali nama sandi lama/baru: sama saja bagi layar) dan kirim.
Future<void> _isiDanKirim(WidgetTester tester) async {
  Future<void> isi(String label, String nilai) async {
    await tester.ensureVisible(_kolom(label));
    await tester.enterText(_kolom(label), nilai);
    await tester.pump();
  }

  await isi('Email', 'budi@contoh.test');
  await isi('Kode undangan', 'K7M2QP4R');
  await isi('Nama lengkap', 'Budi Diundang');
  await isi('Nomor HP', '081234567890');
  await isi('Buat sandi', 'Kalibrasi#2026Sidik');
  await tester.tap(find.byType(CheckboxListTile));
  await tester.pump();
  await tester.tap(find.text('Buat akun & masuk'));
  await tester.pumpAndSettle();
}

GalatApi _galat(int status, String kode, String pesan) =>
    GalatApi(status: status, kode: kode, pesan: pesan);

void main() {
  setUpAll(() => initializeDateFormatting('id_ID'));

  group('akun_sudah_ada dibaca dari server (kontrak §1)', () {
    test('true: akun lama walau nama sama dan hanya satu perusahaan '
        '(tebakan lama menjawab false)', () async {
      final sesi = await _terima(
        _layananDenganJawaban(namaDiAkun: 'Budi', bendera: true),
        nama: 'Budi',
      );
      expect(sesi.akunSudahAda, isTrue);
    });

    test('false: akun baru walau nama di jawaban beda dari isian '
        '(tebakan lama menjawab true)', () async {
      final sesi = await _terima(
        _layananDenganJawaban(namaDiAkun: 'Budi Hartono', bendera: false),
        nama: 'Budi',
      );
      expect(sesi.akunSudahAda, isFalse);
    });

    test('kunci tidak dikirim (server lama): cadangan tebakan lama', () async {
      final sesi = await _terima(
        _layananDenganJawaban(namaDiAkun: 'Nama Lain', bendera: null),
        nama: 'Budi',
      );
      expect(sesi.akunSudahAda, isTrue);
    });
  });

  group('galat per kode di layar "Pakai kode undangan"', () {
    testWidgets(
      'sandi_akun_lama_salah: pesan penuh di bawah kolom sandi, formulir lain '
      'utuh, ada jalan ke Lupa sandi',
      (tester) async {
        layarHp(tester, lebar: 392, tinggi: 2400);
        const pesan =
            'Email ini sudah punya akun SIDIK Pelanggan. Isi kolom sandi dengan '
            'sandi akun Anda yang sudah ada, bukan sandi baru.';
        await tester.pumpWidget(
          _layar(
            _Sesi(galat: _galat(422, 'sandi_akun_lama_salah', pesan)),
            info: _kontak,
          ),
        );
        await tester.pumpAndSettle();
        await _isiDanKirim(tester);

        // PENUH (bukan `errorText` kolom yang dibatasi tiga baris dan memotong
        // "...bukan sandi baru"), tepat di bawah kolom sandi dan di atas
        // persetujuan, bukan di dasar kartu.
        final galat = find.widgetWithText(PesanGalatAuth, pesan);
        expect(galat, findsOneWidget);
        expect(find.byType(PesanGalatAuth), findsOneWidget);
        expect(
          tester.getTopLeft(galat).dy,
          greaterThan(tester.getRect(_kolom('Buat sandi')).bottom),
        );
        expect(
          tester.getBottomLeft(galat).dy,
          lessThan(tester.getTopLeft(find.byType(CheckboxListTile)).dy),
        );
        // Kode undangan dan isian lain tidak dikosongkan (undangan masih hidup).
        expect(
          tester.widget<TextField>(_kolom('Kode undangan')).controller!.text,
          'K7M2QP4R',
        );
        // Bukan kasus "kode salah": tidak menawarkan kode baru.
        expect(find.text('Minta kode baru ke PT Sidik'), findsNothing);

        await tester.tap(find.text('Lupa sandi?'));
        await tester.pumpAndSettle();
        expect(find.byType(LupaSandiScreen), findsOneWidget);
        expect(
          tester.widget<TextField>(_kolom('Email')).controller!.text,
          'budi@contoh.test',
          reason: 'email ikut terbawa ke Lupa sandi',
        );
      },
    );

    for (final (kode, status) in [
      ('undangan_organisasi_berbeda', 422),
      ('akun_nonaktif', 403),
      ('email_belum_diverifikasi', 403),
    ]) {
      testWidgets('$kode: pesan server + kontak PT SIDIK, bukan "Minta kode '
          'baru"', (tester) async {
        layarHp(tester, lebar: 392, tinggi: 2400);
        await tester.pumpWidget(
          _layar(
            _Sesi(
              galat: _galat(status, kode, 'Pesan dari server untuk $kode.'),
            ),
            info: _kontak,
          ),
        );
        await tester.pumpAndSettle();
        await _isiDanKirim(tester);

        expect(find.text('Pesan dari server untuk $kode.'), findsOneWidget);
        expect(find.text('Hubungi PT SIDIK'), findsOneWidget);
        expect(find.text('Minta kode baru ke PT Sidik'), findsNothing);
        expect(find.text('Lupa sandi?'), findsNothing);
      });
    }

    testWidgets('undangan_tidak_berlaku: tetap "Minta kode baru" (tidak '
        'berubah)', (tester) async {
      layarHp(tester, lebar: 392, tinggi: 2400);
      await tester.pumpWidget(
        _layar(
          _Sesi(
            galat: _galat(
              422,
              'undangan_tidak_berlaku',
              'Kode undangan tidak cocok, sudah dipakai, atau sudah '
                  'kedaluwarsa.',
            ),
          ),
          info: _kontak,
        ),
      );
      await tester.pumpAndSettle();
      await _isiDanKirim(tester);

      expect(find.text('Minta kode baru ke PT Sidik'), findsOneWidget);
      expect(find.text('Hubungi PT SIDIK'), findsNothing);
    });
  });

  group('teks DRAF (menunggu persetujuan pemilik)', () {
    const petunjuk =
        'Sudah punya akun SIDIK Pelanggan dengan email ini? Isi sandi akun '
        'Anda yang sudah ada.';

    testWidgets('petunjuk di bawah kolom sandi; label dan bantuan yang sudah '
        'disetujui tidak berubah', (tester) async {
      layarHp(tester, lebar: 392, tinggi: 2400);
      await tester.pumpWidget(_layar(_Sesi()));
      await tester.pumpAndSettle();

      expect(find.text(petunjuk), findsOneWidget);
      expect(find.text('Buat sandi'), findsOneWidget);
      expect(find.text('Minimal 10 karakter'), findsOneWidget);
    });

    testWidgets('dialog akun lama: sandi yang diisi dipakai membuktikan akun, '
        'sandi akun tidak berubah', (tester) async {
      layarHp(tester, lebar: 392, tinggi: 2400);
      await tester.pumpWidget(_layar(_Sesi(akunSudahAda: true)));
      await tester.pumpAndSettle();
      await _isiDanKirim(tester);

      expect(find.text('Email ini sudah punya akun'), findsOneWidget);
      expect(
        find.textContaining('sudah ditambahkan ke akun SIDIK Pelanggan Anda'),
        findsOneWidget,
      );
      expect(find.textContaining('Sandi Anda tidak berubah'), findsOneWidget);
      // Kalimat lama menyesatkan: sandi isian justru DIPAKAI server.
      expect(find.textContaining('tidak dipakai'), findsNothing);
      expect(find.textContaining('yang baru Anda isi'), findsNothing);
    });
  });
}
