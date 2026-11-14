// Harness tampilan: me-render layar kunci ke PNG tanpa emulator, dan sekaligus
// menjadi GERBANG DESAIN bagian 3: tes "tidak meluap" untuk layar kunci pada
// tiga ukuran dan dua tema.
//
// Ukuran gerbang: HP 392×852, HP sempit 320×640 dengan huruf 1,3×, tablet
// 840×1200. HP 360×800 (ukuran lama) ikut dirender bila PNG diminta, supaya
// gambar bisa dibandingkan dengan bukti sebelumnya.
// Tema: terang dan gelap. Font Inter dimuat dari aset (`siapkanTesFitur`),
// jadi lebar teks sama dengan di HP, bukan kotak Ahem.
//
// Layar kunci (`kunci: true`) SELALU dijalankan di tiga ukuran gerbang x dua
// tema, dengan PNG atau tanpa. Pada HP 392 dan HP sempit, layar kunci juga
// diperiksa pedoman sasaran sentuh 48 dp dan label semantik (Flutter
// `androidTapTargetGuideline` dan `labeledTapTargetGuideline`), di viewport
// biasa dan (tema terang) di viewport 3000 dp supaya butir di bawah lipatan
// ikut terbangun. Layar lain
// hanya dijalankan di HP sempit dan tablet (terang) bila PNG tidak diminta.
//
// GAGAL bila ada luapan (RenderFlex overflowed) atau galat lain saat
// build/layout/paint. Luapan lama yang diketahui dicatat di [_utangLuapan]
// (batas px per `layar|ukuran`): tidak boleh bertambah parah, dan tes gagal
// bila utangnya sudah lunas supaya daftarnya dibersihkan. Hari ini kosong.
//
// PNG hanya ditulis bila `SIDIK_PNG_DIR` diisi (folder di luar repo):
//
//   SIDIK_PNG_DIR=/tmp/desain flutter test test/tampilan/render_layar_test.dart
//
// Beberapa layar saja: `SIDIK_LAYAR=beranda,alat flutter test ...`.
//
// TIDAK ada golden baseline: gambar dari Windows tidak boleh dijadikan acuan
// (baseline hanya lahir lewat CI macOS bila konvensinya ada; repo ini belum
// punya golden maupun workflow `golden-baru`).
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
import 'package:sidik_pelanggan/providers/koneksi_provider.dart';
import 'package:sidik_pelanggan/providers/sesi_provider.dart';
import 'package:sidik_pelanggan/screens/akun/anggota_screen.dart';
import 'package:sidik_pelanggan/screens/akun/bantuan_screen.dart';
import 'package:sidik_pelanggan/screens/akun/preferensi_notifikasi_screen.dart';
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

  http.Response _json(Object isi, [int status = 200]) => http.Response(
    jsonEncode(isi),
    status,
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
    if (jalur == '/preferensi-notifikasi') return _preferensi(r);
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

  /// Saklar notifikasi (kontrak §14.4). Perusahaan 6: GET 500 (galat muat);
  /// 4: PUT 403 (baca-saja); 5: PUT 500 (gagal simpan); lainnya normal.
  http.Response _preferensi(http.Request r) {
    final pt = r.headers['X-Perusahaan-Id'];
    if (r.method == 'GET' && pt == '6') {
      return _json({'message': 'Terjadi kendala di server.'}, 500);
    }
    if (r.method == 'PUT' && pt == '4') {
      return _json({
        'message': 'Akun ini belum boleh membuka bagian ini.',
      }, 403);
    }
    if (r.method == 'PUT' && pt == '5') {
      return _json({'message': 'Terjadi kendala di server.'}, 500);
    }
    return _json({
      'data': {
        'pengingat_jadwal': true,
        'status_permintaan': true,
        'pesan_lab': true,
        'ringkasan_email_mingguan': false,
        'tahap_alat': true,
        ...?(r.method == 'PUT'
            ? jsonDecode(r.body) as Map<String, dynamic>
            : null),
      },
    });
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
        model: 'CD-15CPX',
        serial: '2201-0457',
        sedangDikerjakan: sedangDikerjakanJson(),
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
      alatJson(
        2,
        'Timbangan Analitik',
        hari: 12,
        status: 'mendekati_jadwal',
        merk: 'Mettler Toledo',
        model: 'XPR205',
        serial: 'B419223017',
      ),
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
      paketJson(
        21,
        'ORD/ALFA/2026/0021',
        jumlahSelesai: 1,
        alat: [
          // Tahap paket (Sedang dikalibrasi) = alat paling tertinggal.
          alatPaketJson(1, 'Jangka Sorong Digital', equipmentId: 1),
          alatPaketJson(
            2,
            'Timbangan Analitik',
            tahap: 'sertifikat_terbit',
            label: 'Sertifikat sudah terbit',
            equipmentId: 2,
          ),
          alatPaketJson(3, 'Termometer Digital', equipmentId: 3),
          alatPaketJson(
            4,
            'Manometer 0–10 bar',
            tahap: 'menunggu_pemeriksaan',
            label: 'Hasil sedang diperiksa',
            equipmentId: 4,
          ),
        ],
      ),
      paketJson(
        22,
        'ORD/ALFA/2026/0020',
        tahap: 'siap_diambil',
        label: 'Siap diambil',
        jumlahSelesai: 2,
        alat: [
          alatPaketJson(
            5,
            'Timbangan Platform 300 kg',
            tahap: 'siap_diambil',
            label: 'Siap diambil',
            equipmentId: 5,
          ),
          alatPaketJson(
            6,
            'Anak Timbangan F1',
            tahap: 'siap_diambil',
            label: 'Siap diambil',
            equipmentId: 6,
          ),
        ],
      ),
    ],
  ),
  4: DataPerusahaan(nama: 'PT Beta Teknik'),
  5: DataPerusahaan(nama: 'PT Kosong'),
  // Keadaan tenang: tidak ada yang lewat jadwal atau segera, tidak ada paket.
  6: DataPerusahaan(
    nama: 'PT Tenang Sentosa',
    alat: [
      alatJson(31, 'Manometer 0–10 bar', hari: 45),
      alatJson(32, 'Termometer Digital', hari: 120),
      alatJson(33, 'Mikrometer Sekrup', hari: 200),
    ],
    sertifikat: [
      sertifikatJson(
        41,
        'CAL/TENANG/2026/0041',
        namaAlat: 'Manometer 0–10 bar',
        diterbitkan: -60,
      ),
    ],
  ),
  // Server lama: tanpa `sedang_dikerjakan` di alat dan tanpa `alat[]` di paket.
  7: DataPerusahaan(
    nama: 'PT Server Lama',
    alat: [
      alatJson(51, 'Jangka Sorong Digital', hari: -4, status: 'lewat_jadwal'),
      alatJson(52, 'Timbangan Analitik', hari: 12, status: 'mendekati_jadwal'),
    ],
    sertifikat: [
      sertifikatJson(61, 'CAL/LAMA/2026/0061', namaAlat: 'Timbangan Analitik'),
    ],
    paket: [
      Map<String, dynamic>.of(paketJson(71, 'ORD/LAMA/2026/0071'))
        ..remove('alat'),
    ],
  ),
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

/// Akun anggota SATU perusahaan (nama PT tidak tampil di Beranda).
Sesi _sesiSatu(int aktif) => Sesi(
  akun: Akun.dariJson({
    'id': 7,
    'nama': 'Rina Wulandari',
    'email': 'rina@majusejahtera.example',
    'jabatan': 'Manajer Mutu',
    'status': 'aktif',
    'butuh_verifikasi': false,
    'keanggotaan': [
      {'customer_id': aktif, 'nama_perusahaan': 'PT Satu', 'peran': 'staf'},
    ],
  }),
  perusahaanId: aktif,
);

enum _Ukuran {
  // Ukuran lama; hanya dirender bila PNG diminta.
  hp('hp', 360, 800, 1.0, 2.0, gerbang: false),
  hp392('hp392', 392, 852, 1.0, 2.0),
  sempit('sempit', 320, 640, 1.3, 2.0),
  tablet('tablet', 840, 1200, 1.0, 1.5);

  const _Ukuran(
    this.nama,
    this.lebar,
    this.tinggi,
    this.skala,
    this.piksel, {
    this.gerbang = true,
  });
  final String nama;
  final double lebar;
  final double tinggi;
  final double skala;
  final double piksel;

  /// Ikut gerbang (selalu dijalankan untuk layar kunci).
  final bool gerbang;

  /// Pedoman sentuh dan label diperiksa di ukuran ini (layar kunci).
  bool get periksaPedoman => this == hp392 || this == sempit;
}

typedef _Layar = ({
  String nama,
  Widget Function() bangun,
  int? tab,
  int perusahaan,
  bool galat,
  bool satuPt,
  bool kunci,
  Future<void> Function(WidgetTester tester)? sesudah,
});

_Layar _layar(
  String nama,
  Widget Function() bangun, {
  int? tab,
  int perusahaan = 3,
  bool galat = false,
  // Akun anggota satu perusahaan (tanpa nama PT di Beranda).
  bool satuPt = false,
  // Layar kunci: selalu dijalankan di tiga ukuran gerbang dan kedua tema (dan
  // diperiksa pedoman sentuh + label), bukan hanya bila PNG diminta.
  bool kunci = false,
  // Langkah sesudah layar siap (mis. mengetuk segmen).
  Future<void> Function(WidgetTester tester)? sesudah,
}) => (
  nama: nama,
  bangun: bangun,
  tab: tab,
  perusahaan: perusahaan,
  galat: galat,
  satuPt: satuPt,
  kunci: kunci,
  sesudah: sesudah,
);

/// Tinggi viewport (dp) untuk lintasan pedoman sentuh yang memuat butir di bawah
/// lipatan daftar. Butir lebih jauh dari ini (mis. daftar sangat panjang) tetap
/// tidak terperiksa: lihat `docs/standar-kualitas-desain.md` bagian 8.
const _tinggiPanjang = 3000.0;

/// UTANG SENTUH di viewport tinggi: jumlah target < 48 dp yang SUDAH ada di
/// bawah lipatan sebelum lintasan itu ada, per `layar|ukuran`. Boleh mengecil,
/// tidak boleh bertambah, dan tes gagal bila utangnya sudah lunas.
///
/// - `akun|hp392`: kaki Akun (versi + build + ID pengguna, S17) adalah
///   `SelectableText` dengan aksi tekan-lama 360x40 dp di HP 392. Di HP sempit
///   (huruf 1,3x) teksnya membungkus lebih tinggi dan lolos. Dibereskan di
///   paket layar Akun, bukan di PR gerbang.
const _utangSentuhPanjang = <String, int>{'akun|hp392': 1};

/// Bandingkan jumlah target < 48 dp di [alasan] (teks `Evaluation.reason` dari
/// `androidTapTargetGuideline`, `null` bila lolos) dengan [utang]. Mengembalikan
/// daftar pelanggaran; kosong berarti lolos.
List<String> periksaSentuhPanjang(String? alasan, int utang) {
  final n = 'expected tap target size'.allMatches(alasan ?? '').length;
  if (n > utang) {
    return ['$n target < 48 dp (utang tercatat $utang):\n$alasan'];
  }
  if (n < utang) {
    return [
      'hanya $n target < 48 dp, utang tercatat $utang: perbarui '
          '_utangSentuhPanjang',
    ];
  }
  return const [];
}

/// UTANG LUAPAN: kombinasi `layar|ukuran` yang SUDAH meluap sebelum gerbang
/// ini ada. Nilainya batas luapan (px) yang diizinkan. Hari ini KOSONG: 138
/// render sebelum redesain semuanya tanpa luapan. Bila nanti perlu diisi, itu
/// utang yang harus disebut di PR, hanya boleh mengecil, dan tes gagal bila
/// utangnya sudah lunas supaya daftar ini dibersihkan.
const _utangLuapan = <String, double>{};

/// Periksa galat render [unik] terhadap [utang] (batas px, atau `null` bila
/// kombinasi ini tidak punya utang). Mengembalikan daftar pelanggaran; kosong
/// berarti lolos.
List<String> periksaLuapan(List<String> unik, double? utang) {
  if (utang == null) {
    return [for (final g in unik) 'galat saat render: $g'];
  }
  if (unik.isEmpty) {
    return ['sudah tidak meluap: hapus dari _utangLuapan'];
  }
  final hasil = <String>[];
  for (final g in unik) {
    final cocok = RegExp(r'overflowed by ([0-9.]+) pixels').firstMatch(g);
    if (cocok == null) {
      hasil.add('galat bukan luapan: $g');
    } else if (double.parse(cocok.group(1)!) > utang + 0.05) {
      hasil.add('meluap lebih parah dari $utang px: $g');
    }
  }
  return hasil;
}

/// Ketuk saklar "Perubahan tahap alat" (server palsu menolaknya).
Future<void> _ketukSaklarTahap(WidgetTester tester) async {
  final saklar = find.descendant(
    of: find.byKey(const ValueKey('saklar-tahap_alat')),
    matching: find.byType(Switch),
  );
  // Di HP sempit baris ini di bawah lipatan: gulirkan dulu supaya hasilnya
  // (alasan gagal / panel baca-saja) ikut terpotret.
  await tester.ensureVisible(saklar);
  await tester.pumpAndSettle();
  await tester.tap(saklar);
}

final _layarKunci = <_Layar>[
  _layar('sambutan', () => const SambutanScreen()),
  _layar('masuk', () => const MasukScreen(), kunci: true),
  _layar('terima_undangan', () => const TerimaUndanganScreen()),
  _layar(
    'pemeliharaan',
    () => const LayarPemeliharaan(
      pesan: 'Kami sedang memperbarui layanan. Mohon coba beberapa saat lagi.',
    ),
  ),
  _layar('pilih_perusahaan', () => const PilihPerusahaanScreen()),
  _layar('beranda', () => const Rangka(), tab: IndeksTab.beranda, kunci: true),
  _layar(
    'beranda_galat',
    () => const Rangka(),
    tab: IndeksTab.beranda,
    galat: true,
    kunci: true,
  ),
  // Tenang: kalimat "Semua alat Anda berlaku.", jadwal terdekat, satu PT.
  _layar(
    'beranda_tenang',
    () => const Rangka(),
    tab: IndeksTab.beranda,
    perusahaan: 6,
    satuPt: true,
    kunci: true,
  ),
  // Server lama tanpa field baru: tanpa tahap per alat, tik dari jumlah.
  _layar(
    'beranda_server_lama',
    () => const Rangka(),
    tab: IndeksTab.beranda,
    perusahaan: 7,
    satuPt: true,
    kunci: true,
  ),
  // Offline: banner data terakhir di atas isi yang tetap terbaca.
  _layar(
    'beranda_offline',
    () => const Rangka(),
    tab: IndeksTab.beranda,
    kunci: true,
    sesudah: (tester) async {
      ProviderScope.containerOf(
        tester.element(find.byType(Rangka)),
      ).read(koneksiProvider.notifier).offline(DateTime(2026, 11, 12, 8, 12));
    },
  ),
  _layar('alat', () => const Rangka(), tab: IndeksTab.alat, kunci: true),
  _layar(
    'alat_kosong',
    () => const Rangka(),
    tab: IndeksTab.alat,
    perusahaan: 5,
    kunci: true,
  ),
  _layar('alat_detail', () => const AlatDetailScreen(id: 1), kunci: true),
  _layar(
    'sertifikat',
    () => const Rangka(),
    tab: IndeksTab.sertifikat,
    kunci: true,
  ),
  // Segmen Arsip terpilih di tab Sertifikat (centang di segmen terpilih).
  _layar(
    'sertifikat_arsip',
    () => const Rangka(),
    tab: IndeksTab.sertifikat,
    kunci: true,
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
  _layar(
    'sertifikat_detail',
    () => const SertifikatDetailScreen(id: 12),
    kunci: true,
  ),
  _layar('sertifikat_digantikan', () => const SertifikatDetailScreen(id: 9)),
  _layar('sertifikat_gagal', () => const SertifikatDetailScreen(id: 11)),
  _layar(
    'notifikasi',
    () => const Rangka(),
    tab: IndeksTab.notifikasi,
    kunci: true,
  ),
  _layar('akun', () => const Rangka(), tab: IndeksTab.akun, kunci: true),
  _layar('bantuan', () => const BantuanScreen()),
  _layar('paket_detail', () => const PaketDetailScreen(id: 21), kunci: true),
  _layar('anggota', () => const AnggotaScreen()),
  // Pengaturan notifikasi (Akun > Pengaturan notifikasi). Perusahaan 4/5/6
  // memicu baca-saja, gagal simpan, dan galat muat di server palsu.
  _layar('preferensi', () => const PreferensiNotifikasiScreen(), kunci: true),
  _layar(
    'preferensi_galat',
    () => const PreferensiNotifikasiScreen(),
    perusahaan: 6,
    kunci: true,
  ),
  _layar(
    'preferensi_gagal',
    () => const PreferensiNotifikasiScreen(),
    perusahaan: 5,
    kunci: true,
    sesudah: _ketukSaklarTahap,
  ),
  _layar(
    'preferensi_baca_saja',
    () => const PreferensiNotifikasiScreen(),
    perusahaan: 4,
    kunci: true,
    sesudah: _ketukSaklarTahap,
  ),
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
  // `SIDIK_LAYAR=beranda,alat` membatasi ke layar bernama (untuk memotret ulang).
  final hanya = Platform.environment['SIDIK_LAYAR']?.split(',').toSet();

  // Layar kunci: selalu tiga ukuran gerbang x dua tema. Layar lain tanpa PNG
  // cukup dua ukuran paling berisiko (HP sempit 1,3× dan tablet) di tema
  // terang: luapan tidak bergantung pada tema. Matriks penuh (semua layar,
  // semua ukuran termasuk HP 360, kedua tema) hanya bila gambar diminta,
  // supaya suite CI tidak berat.
  for (final u in _Ukuran.values) {
    for (final gelap in const [false, true]) {
      for (final l in _layarKunci) {
        if (hanya != null && !hanya.contains(l.nama)) continue;
        final jalan = folder != null
            ? true
            : l.kunci
            ? u.gerbang
            : !gelap && (u == _Ukuran.sempit || u == _Ukuran.tablet);
        if (!jalan) continue;
        final tema = gelap ? 'gelap' : 'terang';
        testWidgets('${l.nama} · ${u.nama} · $tema', (tester) async {
          layarHp(tester, lebar: u.lebar, tinggi: u.tinggi);
          // Galat render dikumpulkan sendiri (bukan hanya `takeException`)
          // supaya beberapa luapan sekaligus terhitung dan bisa dibandingkan
          // dengan [_utangLuapan].
          final galat = <String>[];
          final periksa = l.kunci && u.periksaPedoman;
          final semantik = periksa ? tester.ensureSemantics() : null;
          try {
            final bawaan = FlutterError.onError;
            FlutterError.onError = (d) =>
                galat.add(d.exceptionAsString().split('\n').first);
            try {
              final kunci = GlobalKey();
              final server = _ServerRender(_data());
              if (l.galat) server.gagal.add('/beranda');
              final override = <Override>[
                ...overrideFitur(
                  server,
                  perusahaan: l.perusahaan,
                  sesi: l.satuPt
                      ? _sesiSatu(l.perusahaan)
                      : _sesi(l.perusahaan),
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
            } finally {
              // Kembalikan SEBELUM expect() apa pun. Bila expect() gagal selagi
              // `onError` masih diganti, flutter_test menegaskan dan tes
              // MENGGANTUNG (tidak gagal) sampai CI habis waktu.
              FlutterError.onError = bawaan;
            }
            expect(tester.takeException(), isNull);
            final luapan = periksaLuapan(
              galat.toSet().toList(),
              _utangLuapan['${l.nama}|${u.nama}'],
            );
            expect(
              luapan,
              isEmpty,
              reason: '${l.nama} · ${u.nama} · $tema:\n${luapan.join('\n')}',
            );
            if (periksa) {
              await expectLater(
                tester,
                meetsGuideline(androidTapTargetGuideline),
              );
              await expectLater(
                tester,
                meetsGuideline(labeledTapTargetGuideline),
              );
              if (!gelap) {
                // Lintasan viewport TINGGI: `ListView` membangun butir secara
                // malas, jadi target di bawah lipatan tidak ada di pohon
                // semantik viewport biasa dan lolos tak terperiksa. Ukuran
                // target tidak bergantung tema, jadi cukup satu tema.
                tester.view.physicalSize = Size(u.lebar, _tinggiPanjang);
                await tester.pumpAndSettle();
                final sentuh = await androidTapTargetGuideline.evaluate(tester);
                final pelanggaranSentuh = periksaSentuhPanjang(
                  sentuh.reason,
                  _utangSentuhPanjang['${l.nama}|${u.nama}'] ?? 0,
                );
                expect(
                  pelanggaranSentuh,
                  isEmpty,
                  reason:
                      '${l.nama} · ${u.nama} (viewport tinggi):\n'
                      '${pelanggaranSentuh.join('\n')}',
                );
                await expectLater(
                  tester,
                  meetsGuideline(labeledTapTargetGuideline),
                );
              }
            }
          } finally {
            semantik?.dispose();
          }
          // Lepas pohon: pewaktu layar (mis. periksa ulang pemeliharaan) ikut
          // dibuang.
          await tester.pumpWidget(const SizedBox());
        });
      }
    }
  }

  group('periksaSentuhPanjang: utang sentuh tercatat', () {
    const satu =
        'SemanticsNode#1: expected tap target size of at least Size(48.0, 48.0)';
    const dua = '$satu\n$satu';

    test('tanpa utang: bersih lolos, satu target kecil gagal', () {
      expect(periksaSentuhPanjang(null, 0), isEmpty);
      expect(periksaSentuhPanjang(satu, 0), isNotEmpty);
    });

    test('dengan utang: sama lolos, lebih banyak gagal, lunas gagal', () {
      expect(periksaSentuhPanjang(satu, 1), isEmpty);
      expect(periksaSentuhPanjang(dua, 1), isNotEmpty);
      final lunas = periksaSentuhPanjang(null, 1);
      expect(lunas, isNotEmpty);
      expect(lunas.single, contains('perbarui _utangSentuhPanjang'));
    });
  });

  group('periksaLuapan: utang luapan tercatat', () {
    const luap = 'A RenderFlex overflowed by 8.3 pixels on the right.';
    const luapParah = 'A RenderFlex overflowed by 12.0 pixels on the right.';

    test('tanpa utang: bersih lolos, luapan sekecil apa pun gagal', () {
      expect(periksaLuapan(const [], null), isEmpty);
      expect(periksaLuapan(const [luap], null), isNotEmpty);
      expect(periksaLuapan(const ['Bad state: No element'], null), isNotEmpty);
    });

    test('dengan utang: sama atau lebih ringan lolos, lebih parah gagal', () {
      expect(periksaLuapan(const [luap], 8.3), isEmpty);
      expect(periksaLuapan(const [luapParah], 8.3), isNotEmpty);
    });

    test('dengan utang: galat selain luapan gagal', () {
      expect(periksaLuapan(const ['Bad state: No element'], 8.3), isNotEmpty);
    });

    test('dengan utang: utang lunas (tidak meluap lagi) gagal', () {
      final p = periksaLuapan(const [], 8.3);
      expect(p, isNotEmpty);
      expect(p.single, contains('hapus dari _utangLuapan'));
    });
  });
}
