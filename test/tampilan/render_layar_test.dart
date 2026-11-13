// Harness tampilan: me-render layar kunci ke PNG tanpa emulator, dan sekaligus
// menjadi tes "tidak meluap" untuk tiap layar utama pada tiga ukuran dan dua
// tema.
//
// Ukuran: HP 360×800, HP sempit 320×640 dengan huruf 1,3×, tablet 840×1200.
// Tema: terang dan gelap. Font Inter dimuat dari aset (`siapkanTesFitur`),
// jadi lebar teks sama dengan di HP, bukan kotak Ahem.
//
// PNG hanya ditulis bila `SIDIK_PNG_DIR` diisi (folder di luar repo):
//
//   SIDIK_PNG_DIR=/tmp/desain flutter test test/tampilan/render_layar_test.dart
//
// Tanpa variabel itu tes tetap me-render dan memeriksa luapan (HP sempit 1,3×
// dan tablet, tema terang), hanya tidak menyimpan gambar. TIDAK ada golden baseline: gambar dari Windows tidak boleh
// dijadikan acuan (baseline hanya lahir lewat CI macOS bila konvensinya ada).
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'package:sidik_pelanggan/core/konfigurasi.dart';
import 'package:sidik_pelanggan/core/tema/tema_sidik.dart';
import 'package:sidik_pelanggan/models/akun.dart';
import 'package:sidik_pelanggan/models/arsip.dart';
import 'package:sidik_pelanggan/providers/sesi_provider.dart';
import 'package:sidik_pelanggan/screens/akun/anggota_screen.dart';
import 'package:sidik_pelanggan/screens/akun/bantuan_screen.dart';
import 'package:sidik_pelanggan/screens/alat/alat_detail_screen.dart';
import 'package:sidik_pelanggan/screens/auth/masuk_screen.dart';
import 'package:sidik_pelanggan/screens/auth/sambutan_screen.dart';
import 'package:sidik_pelanggan/screens/auth/terima_undangan_screen.dart';
import 'package:sidik_pelanggan/screens/gerbang.dart';
import 'package:sidik_pelanggan/screens/paket/paket_detail_screen.dart';
import 'package:sidik_pelanggan/screens/rangka.dart';
import 'package:sidik_pelanggan/screens/sertifikat/arsip_screen.dart';
import 'package:sidik_pelanggan/screens/sertifikat/sertifikat_detail_screen.dart';
import 'package:sidik_pelanggan/widgets/logo_sidik.dart';

import '../dukungan/fixture_arsip.dart';
import '../dukungan/fixture_fitur.dart';
import '../dukungan/layar_uji.dart';

/// Server palsu dengan data yang lebih lengkap daripada fixture bersama:
/// notifikasi dan jumlah belum dibaca.
class _ServerRender extends ServerFitur {
  _ServerRender(super.data);

  http.Response _json(Object isi) => http.Response(
    jsonEncode(isi),
    200,
    headers: {'content-type': 'application/json'},
  );

  @override
  Future<http.Response> tangani(http.Request r) async {
    final jalur = r.url.path.replaceFirst(Konfigurasi.prefix, '');
    if (jalur == '/sertifikat/garis-waktu') {
      // Perusahaan 5 ("PT Kosong") belum punya sertifikat di arsip.
      if (r.headers['X-Perusahaan-Id'] == '5') {
        return _json(jawabanArsip(tingkat: 'tahun', total: 0));
      }
      return _json(switch (r.url.queryParameters['tingkat']) {
        'bulan' => arsipBulan(),
        'pekan' => arsipPekanNovember(),
        'hari' => arsipHari(),
        _ => arsipTahun(),
      });
    }
    if (jalur == '/notifikasi/jumlah') {
      return _json({
        'data': {'belum_dibaca': 2},
      });
    }
    if (jalur == '/notifikasi') {
      final isi = [
        _notif(
          'n1',
          'Alat segera jatuh tempo',
          'Timbangan Analitik jatuh tempo kalibrasi dalam 12 hari.',
          'pelanggan_alat_jatuh_tempo',
          0,
          false,
        ),
        _notif(
          'n2',
          'Sertifikat baru terbit',
          'Sertifikat CAL/ALFA/0002 untuk Timbangan Analitik sudah tersedia.',
          'pelanggan_sertifikat_terbit',
          0,
          false,
        ),
        _notif(
          'n3',
          'Sertifikat direvisi',
          'CAL/ALFA/0001 digantikan oleh CAL/ALFA/0003.',
          'pelanggan_sertifikat_revisi',
          -1,
          true,
        ),
        _notif(
          'n4',
          'Pengingat jadwal kalibrasi',
          'Jangka Sorong melewati jadwal kalibrasi ulang.',
          'pelanggan_alat_jatuh_tempo',
          -4,
          true,
        ),
      ];
      return _json({
        'data': isi,
        'meta': {
          'current_page': 1,
          'last_page': 1,
          'total': isi.length,
          'per_page': 20,
        },
      });
    }
    if (jalur == '/paket/21') {
      return _json({
        'data': {
          ...paketJson(21, 'ORD/ALFA/2026/0021'),
          'alat': [
            {
              'id': 1,
              'nama': 'Jangka Sorong Digital',
              'merk': 'Mitutoyo',
              'serial': 'SN-1',
              'tahap': 'sertifikat_terbit',
              'tahap_label': 'Sertifikat terbit',
              'sertifikat_id': 12,
            },
            {
              'id': 2,
              'nama': 'Timbangan Analitik',
              'merk': 'Mettler',
              'serial': 'SN-2',
              'tahap': 'dikalibrasi',
              'tahap_label': 'Sedang dikalibrasi',
            },
            {
              'id': 3,
              'nama': 'Termometer Digital',
              'serial': 'SN-3',
              'tahap': 'diterima',
              'tahap_label': 'Diterima',
            },
          ],
        },
        'garis_waktu': [
          {
            'kode': 'diterima',
            'label': 'Diterima lab',
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
            'label': 'Pemeriksaan',
            'lewat': false,
            'sekarang': false,
          },
          {
            'kode': 'siap_diambil',
            'label': 'Siap diambil',
            'lewat': false,
            'sekarang': false,
          },
        ],
      });
    }
    if (jalur == '/anggota') {
      return _json({
        'data': {
          'saya': {'peran': 'pic_utama'},
          'maks_anggota': 50,
          'anggota': [
            {
              'id': 1,
              'peran': 'pic_utama',
              'status': 'aktif',
              'saya': true,
              'orang': {
                'nama': 'Rina Wulandari',
                'email': 'rina@majusejahtera.example',
                'jabatan': 'Manajer Mutu',
              },
            },
            {
              'id': 2,
              'peran': 'staf',
              'status': 'aktif',
              'saya': false,
              'orang': {
                'nama': 'Sari Staf',
                'email': 'sari@majusejahtera.example',
              },
            },
            {
              'id': 3,
              'peran': 'staf',
              'status': 'nonaktif',
              'saya': false,
              'orang': {'nama': 'Dedi Lama'},
            },
          ],
          'undangan_menunggu': [
            {
              'id': 9,
              'email': 'baru@majusejahtera.example',
              'peran': 'staf',
              'kedaluwarsa_pada': tanggalUji(5),
            },
          ],
        },
      });
    }
    return super.tangani(r);
  }

  static Map<String, dynamic> _notif(
    String id,
    String judul,
    String isi,
    String kategori,
    int hari,
    bool dibaca,
  ) => {
    'id': id,
    'judul': judul,
    'isi': isi,
    'kategori': kategori,
    'dibaca': dibaca,
    'dibuat_pada': '${tanggalUji(hari)}T08:30:00+07:00',
  };
}

/// Data perusahaan contoh yang cukup beragam untuk dinilai mata.
Map<int, DataPerusahaan> _data() => {
  3: DataPerusahaan(
    nama: 'PT Maju Sejahtera Abadi',
    alat: [
      alatJson(
        1,
        'Jangka Sorong Digital',
        hari: -4,
        status: 'lewat_jadwal',
        riwayat: [
          sertifikatJson(
            2,
            'CAL/ALFA/2026/0002',
            diterbitkan: -30,
            berlakuSampai: 335,
            keputusan: 'PASS',
          ),
          sertifikatJson(
            1,
            'CAL/ALFA/2025/0114',
            diterbitkan: -395,
            berlakuSampai: -30,
            status: 'digantikan',
            digantikanOleh: {'id': 2, 'nomor': 'CAL/ALFA/2026/0002'},
          ),
        ],
      ),
      alatJson(2, 'Timbangan Analitik', hari: 12, status: 'mendekati_jadwal'),
      alatJson(3, 'Termometer Digital', hari: 45),
      alatJson(4, 'Manometer 0–10 bar', hari: 75),
      alatJson(5, 'Mikrometer Sekrup', hari: 200),
      alatJson(6, 'Alat Tidak Aktif', hari: 10, status: 'nonaktif'),
      alatJson(7, 'Pengukur Kelembapan', status: 'belum_pernah'),
    ],
    sertifikat: [
      sertifikatJson(
        12,
        'CAL/ALFA/2026/0012',
        namaAlat: 'Timbangan Analitik',
        diterbitkan: -12,
      ),
      sertifikatJson(
        11,
        'CAL/ALFA/2026/0011',
        namaAlat: 'Termometer Digital',
        diterbitkan: -40,
        keputusan: 'FAIL',
      ),
      sertifikatJson(
        10,
        'CAL/ALFA/2026/0010',
        namaAlat: 'Manometer 0–10 bar',
        diterbitkan: -90,
      ),
      sertifikatJson(
        9,
        'CAL/ALFA/2025/0114',
        namaAlat: 'Jangka Sorong Digital',
        diterbitkan: -395,
        status: 'digantikan',
        digantikanOleh: {'id': 12, 'nomor': 'CAL/ALFA/2026/0012'},
      ),
      sertifikatJson(
        8,
        'CAL/ALFA/2025/0090',
        namaAlat: 'Mikrometer Sekrup',
        diterbitkan: -500,
        status: 'dibatalkan',
        dibatalkanPada: -100,
      ),
    ],
    paket: [
      paketJson(21, 'ORD/ALFA/2026/0021'),
      paketJson(
        22,
        'ORD/ALFA/2026/0020',
        tahap: 'siap_diambil',
        label: 'Siap diambil',
      ),
    ],
  ),
  4: DataPerusahaan(nama: 'PT Beta Teknik'),
  5: DataPerusahaan(nama: 'PT Kosong'),
};

Sesi _sesi(int aktif) => Sesi(
  akun: Akun.dariJson({
    'id': 7,
    'nama': 'Rina Wulandari',
    'email': 'rina@majusejahtera.example',
    'jabatan': 'Manajer Mutu',
    'status': 'aktif',
    'butuh_verifikasi': false,
    'keanggotaan': [
      {
        'customer_id': 3,
        'nama_perusahaan': 'PT Maju Sejahtera Abadi',
        'peran': 'pic_utama',
      },
      {'customer_id': 4, 'nama_perusahaan': 'PT Beta Teknik', 'peran': 'staf'},
    ],
  }),
  perusahaanId: aktif,
);

enum _Ukuran {
  hp('hp', 360, 800, 1.0, 2.0),
  sempit('sempit', 320, 640, 1.3, 2.0),
  tablet('tablet', 840, 1200, 1.0, 1.5);

  const _Ukuran(this.nama, this.lebar, this.tinggi, this.skala, this.piksel);
  final String nama;
  final double lebar;
  final double tinggi;
  final double skala;
  final double piksel;
}

typedef _Layar = ({
  String nama,
  Widget Function() bangun,
  int? tab,
  int perusahaan,
  bool galat,
  bool matriksPenuh,
  Future<void> Function(WidgetTester tester)? sesudah,
});

_Layar _layar(
  String nama,
  Widget Function() bangun, {
  int? tab,
  int perusahaan = 3,
  bool galat = false,
  // Selalu dijalankan di semua ukuran dan kedua tema, bukan hanya bila PNG
  // diminta.
  bool matriksPenuh = false,
  // Langkah sesudah layar siap (mis. mengetuk segmen).
  Future<void> Function(WidgetTester tester)? sesudah,
}) => (
  nama: nama,
  bangun: bangun,
  tab: tab,
  perusahaan: perusahaan,
  galat: galat,
  matriksPenuh: matriksPenuh,
  sesudah: sesudah,
);

final _layarKunci = <_Layar>[
  _layar('sambutan', () => const SambutanScreen()),
  _layar('masuk', () => const MasukScreen()),
  _layar('terima_undangan', () => const TerimaUndanganScreen()),
  _layar(
    'pemeliharaan',
    () => const LayarPemeliharaan(
      pesan: 'Kami sedang memperbarui layanan. Mohon coba beberapa saat lagi.',
    ),
  ),
  _layar('pilih_perusahaan', () => const PilihPerusahaanScreen()),
  _layar('beranda', () => const Rangka(), tab: IndeksTab.beranda),
  _layar(
    'beranda_galat',
    () => const Rangka(),
    tab: IndeksTab.beranda,
    galat: true,
  ),
  _layar('alat', () => const Rangka(), tab: IndeksTab.alat),
  _layar(
    'alat_kosong',
    () => const Rangka(),
    tab: IndeksTab.alat,
    perusahaan: 5,
  ),
  _layar('alat_detail', () => const AlatDetailScreen(id: 1)),
  _layar('sertifikat', () => const Rangka(), tab: IndeksTab.sertifikat),
  // Segmen Arsip terpilih di tab Sertifikat (centang di segmen terpilih).
  _layar(
    'sertifikat_arsip',
    () => const Rangka(),
    tab: IndeksTab.sertifikat,
    matriksPenuh: true,
    sesudah: (tester) => tester.tap(find.text('Arsip')),
  ),
  _layar('arsip', () => const ArsipScreen()),
  _layar('arsip_kosong', () => const ArsipScreen(), perusahaan: 5),
  _layar(
    'arsip_hari',
    () => ArsipScreen(
      parameter: HasilArsip.dariJson(
        arsipPekanNovember(),
      ).kelompok.first.parameter,
      judul: 'Pekan 46 (9–15 Nov 2026)',
    ),
  ),
  _layar('sertifikat_detail', () => const SertifikatDetailScreen(id: 12)),
  _layar('sertifikat_digantikan', () => const SertifikatDetailScreen(id: 9)),
  _layar('sertifikat_gagal', () => const SertifikatDetailScreen(id: 11)),
  _layar('notifikasi', () => const Rangka(), tab: IndeksTab.notifikasi),
  _layar('akun', () => const Rangka(), tab: IndeksTab.akun),
  _layar('bantuan', () => const BantuanScreen()),
  _layar('paket_detail', () => const PaketDetailScreen(id: 21)),
  _layar('anggota', () => const AnggotaScreen()),
];

/// Font ikon Material dari SDK Flutter. Tanpa ini ikon tampil sebagai kotak di
/// PNG. Dilewati diam-diam bila berkasnya tidak ditemukan (tes tetap berjalan).
Future<void> _muatFontIkon() async {
  final akar = Platform.environment['FLUTTER_ROOT'];
  final calon = [
    if (akar != null) '$akar/bin/cache/artifacts/material_fonts',
    '${File(Platform.resolvedExecutable).parent.parent.parent.parent.path}'
        '/artifacts/material_fonts',
  ];
  for (final folder in calon) {
    final berkas = File('$folder/materialicons-regular.otf');
    if (!berkas.existsSync()) continue;
    final pemuat = FontLoader('MaterialIcons')
      ..addFont(Future.value(ByteData.sublistView(berkas.readAsBytesSync())));
    await pemuat.load();
    return;
  }
}

void main() {
  setUpAll(() async {
    await siapkanTesFitur();
    await _muatFontIkon();
  });

  final folder = Platform.environment['SIDIK_PNG_DIR'];
  if (folder != null) Directory(folder).createSync(recursive: true);

  // Tanpa PNG cukup dua ukuran paling berisiko (HP sempit 1,3× dan tablet) di
  // tema terang: luapan tidak bergantung pada tema. Matriks penuh hanya bila
  // gambar diminta, supaya suite CI tidak berat.
  // Layar `matriksPenuh` tetap dijalankan di semua ukuran dan kedua tema.
  for (final u in _Ukuran.values) {
    for (final gelap in const [false, true]) {
      for (final l in _layarKunci) {
        final ringan = folder == null && !l.matriksPenuh;
        if (ringan && (gelap || (u != _Ukuran.sempit && u != _Ukuran.tablet))) {
          continue;
        }
        final tema = gelap ? 'gelap' : 'terang';
        testWidgets('${l.nama} · ${u.nama} · $tema', (tester) async {
          layarHp(tester, lebar: u.lebar, tinggi: u.tinggi);
          final kunci = GlobalKey();
          final server = _ServerRender(_data());
          if (l.galat) server.gagal.add('/beranda');
          final override = <Override>[
            ...overrideFitur(
              server,
              perusahaan: l.perusahaan,
              sesi: _sesi(l.perusahaan),
            ),
            infoAplikasiProvider.overrideWith(
              (ref) async => InfoAplikasi.dariJson({
                'organisasi': {
                  'nama': 'PT Sistem Dirgantara Inovasi Teknologi',
                  'alamat': 'Jl. Kalibrasi No. 285, Jakarta',
                },
                'kontak': {
                  'whatsapp': '+62 812-0000-0285',
                  'whatsapp_url': 'https://wa.me/628120000285',
                  'email': 'lab@ptsidik.example',
                  'jam_layanan': 'Senin–Jumat, 08.00–16.00 WIB',
                },
                'dokumen': {
                  'kebijakan_privasi': {
                    'url': 'https://ptsidik.example/privasi',
                    'versi': '1.0',
                  },
                  'syarat_ketentuan': {
                    'url': 'https://ptsidik.example/syarat',
                    'versi': '1.0',
                  },
                },
              }),
            ),
          ];

          await tester.pumpWidget(
            ProviderScope(
              overrides: override,
              child: MaterialApp(
                debugShowCheckedModeBanner: false,
                theme: TemaSidik.terang,
                darkTheme: TemaSidik.gelap,
                themeMode: gelap ? ThemeMode.dark : ThemeMode.light,
                builder: (context, child) => RepaintBoundary(
                  key: kunci,
                  child: MediaQuery.withClampedTextScaling(
                    minScaleFactor: u.skala,
                    maxScaleFactor: u.skala,
                    child: child!,
                  ),
                ),
                home: l.bangun(),
              ),
            ),
          );
          // Logo: gambar didekode di luar waktu palsu `testWidgets`.
          await tester.runAsync(
            () => precacheImage(
              const AssetImage(LogoSidik.aset),
              tester.element(find.byType(MaterialApp)),
            ),
          );
          await tester.pumpAndSettle();
          if (l.tab != null) {
            ProviderScope.containerOf(
              tester.element(find.byType(Rangka)),
            ).read(tabProvider.notifier).pilih(l.tab!);
            await tester.pumpAndSettle();
          }
          if (l.sesudah != null) {
            await l.sesudah!(tester);
            await tester.pumpAndSettle();
          }
          expect(tester.takeException(), isNull);

          if (folder != null) {
            final batas = tester.renderObject<RenderRepaintBoundary>(
              find.byKey(kunci),
            );
            await tester.runAsync(() async {
              final gambar = await batas.toImage(pixelRatio: u.piksel);
              final data = await gambar.toByteData(
                format: ui.ImageByteFormat.png,
              );
              File(
                '$folder/${l.nama}_${u.nama}_$tema.png',
              ).writeAsBytesSync(data!.buffer.asUint8List());
            });
          }

          // Lepas pohon: pewaktu layar (mis. periksa ulang pemeliharaan) ikut
          // dibuang.
          await tester.pumpWidget(const SizedBox());
        });
      }
    }
  }
}
