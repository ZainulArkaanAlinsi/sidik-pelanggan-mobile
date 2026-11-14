// Alur dasar seluruh aplikasi terhadap server palsu: masuk lewat undangan,
// daftar sertifikat, buka detail, unduh PDF, lalu keluar.
//
// Dipakai DUA pintu masuk dengan skenario yang sama:
// - `test/alur_dasar_test.dart` — `flutter test`, tanpa emulator (dijalankan
//   lokal dan di CI);
// - `integration_test/alur_dasar_test.dart` — `flutter test integration_test
//   -d <perangkat>`, perlu emulator/HP (tidak dijalankan di laptop kerja).
//
// Yang palsu hanya batas luarnya: HTTP (`MockClient`), Keystore, folder
// dokumen, dan pembuka PDF. Aplikasi, Riverpod, layanan, dan `ApiPelanggan`
// (header, galat, cache) adalah yang asli.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:open_filex/open_filex.dart';

import 'package:sidik_pelanggan/app.dart';
import 'package:sidik_pelanggan/core/api_pelanggan.dart';
import 'package:sidik_pelanggan/core/konfigurasi.dart';
import 'package:sidik_pelanggan/core/penyimpan_pratinjau.dart';
import 'package:sidik_pelanggan/providers/koneksi_provider.dart';
import 'package:sidik_pelanggan/providers/sesi_provider.dart';
import 'package:sidik_pelanggan/services/layanan_pelanggan.dart';
import 'package:sidik_pelanggan/widgets/tombol_sidik.dart';

import 'dukungan.dart';
import 'layar_uji.dart';

/// Server palsu `/api/pelanggan/v1`. Menolak (401) semua rute bertoken yang
/// tidak membawa `Authorization: Bearer <token>` yang pernah dikeluarkannya —
/// jadi alur yang lupa memasang token gagal, bukan lolos diam-diam.
class ServerPalsu {
  ServerPalsu({this.akunSudahAda = false});

  static const token = 'tkn-uji-bukan-rahasia';

  /// Jawab terima-undangan seperti email yang sudah punya akun: nama lama,
  /// dua perusahaan, isian nama diabaikan.
  final bool akunSudahAda;

  final permintaan = <http.Request>[];
  bool _masuk = false;

  static final pdf = utf8.encode('%PDF-1.4\n% berkas uji alur dasar\n');

  Map<String, dynamic> get _user => {
    'id': 7,
    'nama': akunSudahAda ? 'Budi Lama' : 'Budi Diundang',
    'email': 'budi@contoh.test',
    'status': 'aktif',
    'butuh_verifikasi': false,
    'keanggotaan': [
      {
        'customer_id': 3,
        'nama_perusahaan': 'PT Contoh Pelanggan',
        'peran': 'staf',
      },
      if (akunSudahAda)
        {
          'customer_id': 4,
          'nama_perusahaan': 'PT Lain Pelanggan',
          'peran': 'staf',
        },
    ],
  };

  Map<String, dynamic> _sertifikat(int id) => {
    'id': id,
    'nomor': 'CAL/2026/11/000$id',
    'diterbitkan_pada': '2026-11-05',
    'berlaku_sampai': '2027-11-05',
    'status': 'berlaku',
    'alat': {'id': 20 + id, 'nama': 'Jangka Sorong $id', 'merk': 'Mitutoyo'},
    'bisa_diunduh': true,
  };

  http.Response _json(Object isi, [int status = 200]) => http.Response(
    jsonEncode(isi),
    status,
    headers: {'content-type': 'application/json'},
  );

  Future<http.Response> tangani(http.Request r) async {
    permintaan.add(r);
    final jalur = r.url.path.replaceFirst(Konfigurasi.prefix, '');
    final m = r.method;

    // ── Tanpa token ──
    if (m == 'GET' && jalur == '/app/status') {
      return _json({
        'data': {
          'versi_minimum': '0.0.0',
          'versi_terbaru': '0.2.2',
          'maintenance': false,
          'pesan_maintenance': '',
        },
      });
    }
    if (m == 'GET' && jalur == '/app/info') {
      return _json({
        'data': {'organisasi': {}, 'kontak': {}, 'dokumen': {}},
      });
    }
    if (m == 'POST' && jalur == '/auth/terima-undangan') {
      final b = jsonDecode(r.body) as Map<String, dynamic>;
      if (b['kode'] != 'K7M2QP4R' || b['setuju_syarat'] != true) {
        return _json({
          'kode': 'undangan_tidak_berlaku',
          'message':
              'Kode undangan tidak cocok, sudah dipakai, atau sudah kedaluwarsa.',
        }, 422);
      }
      _masuk = true;
      return _json({
        'data': {'token': token, 'kemampuan': 'pelanggan', 'user': _user},
      }, 201);
    }

    // ── Bertoken ──
    if (r.headers['Authorization'] != 'Bearer $token' || !_masuk) {
      return _json({'kode': 'sesi_berakhir', 'message': 'Sesi berakhir.'}, 401);
    }
    if (m == 'GET' && jalur == '/saya') return _json({'data': _user});
    if (m == 'GET' && jalur == '/beranda') {
      return _json({
        'data': {
          'perusahaan': {'nama': 'PT Contoh Pelanggan'},
          'ringkasan': {
            'jumlah_alat': 2,
            'lewat_jatuh_tempo': 0,
            'segera_jatuh_tempo': 0,
            'notifikasi_belum_dibaca': 0,
          },
        },
        'meta': {'jendela_segera_hari': 30},
      });
    }
    if (m == 'GET' && jalur == '/alat') {
      return _json({
        'data': <Object>[],
        'meta': {'current_page': 1, 'last_page': 1, 'total': 0},
      });
    }
    if (m == 'GET' && jalur == '/sertifikat') {
      return _json({
        'data': [_sertifikat(2), _sertifikat(1)],
        'meta': {'current_page': 1, 'last_page': 1, 'total': 2},
      });
    }
    final detail = RegExp(r'^/sertifikat/(\d+)$').firstMatch(jalur);
    if (m == 'GET' && detail != null) {
      return _json({'data': _sertifikat(int.parse(detail.group(1)!))});
    }
    if (m == 'GET' && RegExp(r'^/sertifikat/\d+/unduh$').hasMatch(jalur)) {
      return http.Response.bytes(
        pdf,
        200,
        headers: {'content-type': 'application/pdf'},
      );
    }
    if (m == 'GET' && jalur == '/notifikasi') {
      return _json({
        'data': <Object>[],
        'meta': {'current_page': 1, 'last_page': 1, 'total': 0},
      });
    }
    if (m == 'GET' && jalur == '/notifikasi/jumlah') {
      return _json({
        'data': {'belum_dibaca': 0},
      });
    }
    if (m == 'POST' && jalur == '/auth/keluar') {
      _masuk = false;
      return _json({'message': 'Anda sudah keluar.'});
    }
    return _json({'kode': 'tidak_ada', 'message': 'Tidak ditemukan.'}, 404);
  }
}

/// Hasil yang dicatat selama alur, untuk dicek test.
class HasilAlur {
  HasilAlur(this.server);

  final ServerPalsu server;

  /// Path berkas yang diserahkan ke pembuka PDF.
  final dibuka = <String>[];

  /// Isi berkas itu pada saat dibuka.
  final isiDibuka = <List<int>>[];
}

/// Pembungkus: seluruh aplikasi dengan batas luar yang dipalsukan.
Widget aplikasiUji(ServerPalsu server, HasilAlur hasil, Directory folder) {
  final klien = MockClient(server.tangani);
  return ProviderScope(
    overrides: [
      ...overrideDasar(),
      apiProvider.overrideWith((ref) {
        final koneksi = ref.read(koneksiProvider.notifier);
        return ApiPelanggan(
          klien: klien,
          cache: ref.watch(penyimpanCacheProvider),
          saatOffline: koneksi.offline,
          saatOnline: koneksi.online,
          jedaUlang: const [],
        );
      }),
      layananProvider.overrideWith(
        (ref) => LayananPelanggan(
          ref.watch(apiProvider),
          penyimpan: PenyimpanPratinjau(akar: () async => folder),
          pembukaBerkas: (path) async {
            hasil.dibuka.add(path);
            hasil.isiDibuka.add(File(path).readAsBytesSync());
            return OpenResult(type: ResultType.done);
          },
        ),
      ),
    ],
    child: const SidikPelangganApp(),
  );
}

Future<void> _gulirKe(WidgetTester tester, Finder sasaran) async {
  await tester.scrollUntilVisible(
    sasaran,
    200,
    scrollable: find
        .descendant(
          of: find.byType(ListView).first,
          matching: find.byType(Scrollable),
        )
        .first,
  );
  await tester.pumpAndSettle();
}

Future<void> _isi(WidgetTester tester, String label, String nilai) async {
  final kolom = find.widgetWithText(TextField, label);
  await _gulirKe(tester, kolom);
  await tester.enterText(kolom, nilai);
  await tester.pump();
}

/// Seluruh alur. [akunSudahAda] = email undangan sudah punya akun, jadi
/// dialog "Email ini sudah punya akun" muncul dan harus ditutup.
Future<HasilAlur> jalankanAlurDasar(
  WidgetTester tester, {
  bool akunSudahAda = false,
}) async {
  // Sinkron: IO asli yang asinkron tidak selesai di zona testWidgets.
  final folder = Directory.systemTemp.createTempSync('alur_dasar_');
  addTearDown(() {
    if (folder.existsSync()) folder.deleteSync(recursive: true);
  });
  final server = ServerPalsu(akunSudahAda: akunSudahAda);
  final hasil = HasilAlur(server);

  // Alur HP: navigasi bawah (di layar >= 600 dp berganti jadi rel samping).
  layarHp(tester);
  await tester.pumpWidget(aplikasiUji(server, hasil, folder));
  await tester.pumpAndSettle();

  // 1. Belum masuk → layar Masuk.
  final pakaiKode = find.text('Pakai kode undangan');
  await _gulirKe(tester, pakaiKode);
  expect(pakaiKode, findsOneWidget);
  await tester.tap(pakaiKode);
  await tester.pumpAndSettle();

  // 2. Terima undangan.
  await _isi(tester, 'Email', 'budi@contoh.test');
  await _isi(tester, 'Kode undangan', 'K7M2QP4R');
  await _isi(tester, 'Nama lengkap', 'Budi Diundang');
  await _isi(tester, 'Nomor HP', '081234567890');
  await _isi(tester, 'Buat sandi', 'Kalibrasi#2026Sidik');
  final setuju = find.byType(CheckboxListTile);
  await _gulirKe(tester, setuju);
  await tester.tap(setuju);
  await tester.pump();
  final kirim = find.text('Buat akun & masuk');
  await _gulirKe(tester, kirim);
  await tester.tap(kirim);
  await tester.pumpAndSettle();

  if (akunSudahAda) {
    expect(find.text('Email ini sudah punya akun'), findsOneWidget);
    await tester.tap(find.text('Mengerti'));
    await tester.pumpAndSettle();
  } else {
    expect(find.text('Email ini sudah punya akun'), findsNothing);
  }

  // Akun di dua perusahaan: pilih dulu perusahaan yang dibuka.
  if (akunSudahAda) {
    expect(find.text('Pilih perusahaan'), findsOneWidget);
    await tester.tap(find.text('PT Contoh Pelanggan'));
    await tester.pumpAndSettle();
  }

  // 3. Masuk ke Rangka (Beranda).
  expect(find.byType(NavigationBar), findsOneWidget);
  // Beranda terbuka (kalimat utama; nama PT hanya tampil untuk akun
  // multi-perusahaan, jadi bukan penandanya).
  expect(find.text('Tidak ada alat yang lewat jadwal.'), findsOneWidget);

  // 4. Daftar sertifikat.
  await tester.tap(
    find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text('Sertifikat'),
    ),
  );
  await tester.pumpAndSettle();
  expect(find.text('CAL/2026/11/0002'), findsOneWidget);
  expect(find.text('CAL/2026/11/0001'), findsOneWidget);

  // 5. Detail + unduh.
  await tester.tap(find.text('CAL/2026/11/0002'));
  await tester.pumpAndSettle();
  final unduh = find.text('Unduh PDF');
  await _gulirKe(tester, unduh);
  await tester.tap(unduh);
  // Menulis PDF ke disk adalah IO asli; beri event loop asli waktu selesai.
  for (var i = 0; i < 60 && hasil.dibuka.isEmpty; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump();
  }
  await tester.pumpAndSettle();

  // 6. Keluar (tab Akun).
  await tester.binding.handlePopRoute();
  await tester.pumpAndSettle();
  await tester.tap(
    find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text('Akun'),
    ),
  );
  await tester.pumpAndSettle();
  final keluar = find.widgetWithText(TombolSidik, 'Keluar');
  await _gulirKe(tester, keluar);
  await tester.tap(keluar);
  await tester.pumpAndSettle();
  await tester.tap(find.widgetWithText(TextButton, 'Keluar'));
  await tester.pumpAndSettle();
  expect(find.text('Email'), findsOneWidget);
  expect(find.text('Lupa sandi?'), findsOneWidget);

  // Lepas aplikasi: timer di dalamnya ikut dibuang.
  await tester.pumpWidget(const SizedBox());
  return hasil;
}

/// Pemeriksaan sesudah alur: apa yang dilihat server dan pembuka PDF.
void periksaHasilAlur(HasilAlur hasil) {
  final server = hasil.server;
  final host = Uri.parse(Konfigurasi.apiBaseUrl).host;

  // Sesudah keluar, penyedia yang mendengarkan sesi sempat memuat ulang satu
  // kali sebelum layarnya dilepas (jumlah notifikasi) — tanpa token, dan
  // memang tak punya token lagi. Yang diperiksa: semua sampai keluar.
  final iKeluar = server.permintaan.indexWhere(
    (r) => r.method == 'POST' && r.url.path.endsWith('/auth/keluar'),
  );
  expect(iKeluar, isNonNegative, reason: 'keluar harus sampai ke server');
  final sebelumKeluar = server.permintaan.take(iKeluar + 1);

  // Semua panggilan hanya ke server kita; bertoken kecuali tiga rute publik.
  for (final r in sebelumKeluar) {
    expect(r.url.host, host, reason: '${r.method} ${r.url}');
    expect(r.headers['X-Request-Id'], isNotNull);
    expect(r.headers['X-App-Versi'], isNotNull);
    final jalur = r.url.path.replaceFirst(Konfigurasi.prefix, '');
    final publik = {'/app/status', '/app/info', '/auth/terima-undangan'};
    if (!publik.contains(jalur)) {
      expect(
        r.headers['Authorization'],
        'Bearer ${ServerPalsu.token}',
        reason: '${r.method} $jalur',
      );
    }
  }

  // Unduhan: lewat rute unduh milik sertifikat yang dibuka, PDF-nya sampai.
  final rute = server.permintaan.map((r) => '${r.method} ${r.url.path}');
  expect(rute, contains('GET ${Konfigurasi.prefix}/sertifikat/2/unduh'));
  expect(hasil.dibuka, hasLength(1));
  expect(hasil.dibuka.single, endsWith('.pdf'));
  expect(hasil.isiDibuka.single, ServerPalsu.pdf);

  // Keluar mencabut token di server.
  expect(rute, contains('POST ${Konfigurasi.prefix}/auth/keluar'));
}
