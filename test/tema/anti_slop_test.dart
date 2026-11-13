import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../dukungan/pemindai_token.dart';

/// Gerbang desain Pelanggan, bagian 4: tanda "AI-slop" yang bisa dihitung mesin.
///
/// Arah "Jejak" membuang tiga kebiasaan generik: kartu untuk setiap butir daftar
/// (`KartuSidik`), chip pil di setiap baris (`ChipStatus`), dan rangkaian
/// "A · B · C" di satu baris teks. Keempat pola di bawah dihitung per berkas di
/// seluruh `lib/` dan dibekukan di sini sebagai ratchet DUA ARAH, sama seperti
/// `token_only_test.dart`:
///
/// - pemakaian di berkas baru atau hitungan NAIK -> gagal,
/// - hitungan TURUN                              -> gagal juga, dengan pesan
///   "turunkan angka di berkas ini". Sisa angka adalah ruang untuk menyelipkan
///   pemakaian baru lewat PR lain.
///
/// Angka-angka ini adalah UTANG desain lama, bukan pemakaian yang diinginkan.
/// Paket komponen dan paket layar (PanelSidik, BarisSidik, Stempel) menurunkan
/// semuanya; tiap PR menurunkan angka di tabel ini.
///
/// Definisi kelasnya sendiri (`kartu_sidik.dart`, `chip_status.dart`) tidak
/// dihitung. `KartuSidik` di brief dihitung 25 karena memasukkan konstruktornya.
///
/// Ini ratchet utang SIMBOL, bukan detektor slop: ia menghitung nama yang
/// diketahui buruk, bukan bentuknya. `Card(`, `Chip(`, atau pemisah lain
/// (`|`, `/`, `•`) tidak terlihat di sini; itu pekerjaan tinjauan manusia dan
/// bukti render. Gerbang ini hanya menjaga agar utang yang sudah tercatat tidak
/// bertambah.
void main() {
  final aturan = <_Aturan>[
    _Aturan(
      nama: 'KartuSidik(',
      alasan: 'satu kartu per butir daftar; kartu hanya untuk GRUP butir',
      pola: RegExp(r'\bKartuSidik\('),
      dikecualikan: 'lib/widgets/kartu_sidik.dart',
      baseline: const {
        'lib/screens/akun/akun_screen.dart': 1,
        'lib/screens/akun/anggota_screen.dart': 2,
        'lib/screens/akun/bantuan_screen.dart': 1,
        'lib/screens/akun/preferensi_notifikasi_screen.dart': 1,
        'lib/screens/alat/alat_detail_screen.dart': 2,
        'lib/screens/beranda/beranda_screen.dart': 2,
        'lib/screens/gerbang.dart': 1,
        'lib/screens/notifikasi/notifikasi_screen.dart': 1,
        'lib/screens/paket/paket_detail_screen.dart': 3,
        'lib/screens/sertifikat/sertifikat_detail_screen.dart': 1,
        'lib/widgets/baris_menu.dart': 1,
        'lib/widgets/garis_waktu_sertifikat.dart': 1,
        'lib/widgets/kartu_alat.dart': 1,
        'lib/widgets/kartu_kelompok_arsip.dart': 1,
        'lib/widgets/kartu_kpi.dart': 1,
        'lib/widgets/kartu_paket.dart': 1,
        'lib/widgets/kartu_sertifikat.dart': 1,
        'lib/widgets/kerangka.dart': 2,
      },
    ),
    _Aturan(
      nama: 'ChipStatus(',
      alasan: 'normal diam, pengecualian bersuara: bukan chip di tiap baris',
      pola: RegExp(r'\bChipStatus\('),
      dikecualikan: 'lib/widgets/chip_status.dart',
      baseline: const {
        'lib/screens/akun/anggota_screen.dart': 1,
        'lib/screens/alat/alat_detail_screen.dart': 1,
        'lib/screens/paket/paket_detail_screen.dart': 3,
        'lib/screens/sertifikat/sertifikat_detail_screen.dart': 2,
        'lib/widgets/garis_waktu_sertifikat.dart': 2,
        'lib/widgets/kartu_alat.dart': 1,
        'lib/widgets/kartu_paket.dart': 2,
        'lib/widgets/kartu_sertifikat.dart': 2,
      },
    ),
    _Aturan(
      nama: "' · ' (titik tengah sebagai pemisah teks)",
      alasan:
          'tiap fakta di baris sendiri; nomor seri tidak tenggelam di A · B',
      pola: RegExp(' · '),
      dikecualikan: '',
      baseline: const {
        'lib/screens/akun/akun_screen.dart': 1,
        'lib/screens/akun/anggota_screen.dart': 1,
        'lib/screens/paket/paket_detail_screen.dart': 1,
        'lib/screens/sertifikat/sertifikat_detail_screen.dart': 1,
        // `Alat.merkModel`: "merk · model" dibentuk di model, bukan di layar.
        'lib/models/data_pelanggan.dart': 1,
        'lib/widgets/kartu_alat.dart': 2,
        'lib/widgets/kartu_paket.dart': 1,
        'lib/widgets/kartu_sertifikat.dart': 2,
      },
    ),
    _Aturan(
      nama: 'AreaSentuh.minimum - Spasi.x (ubin ikon dekoratif)',
      alasan: 'ubin ikon di atas judul tidak membawa informasi',
      pola: RegExp(r'AreaSentuh\.minimum\s*-\s*Spasi\.\w+'),
      dikecualikan: '',
      baseline: const {
        'lib/widgets/kartu_kelompok_arsip.dart': 2,
        'lib/widgets/kartu_kpi.dart': 2,
        'lib/widgets/kartu_sertifikat.dart': 2,
      },
    ),
  ];

  group('pemindai anti-slop: menghitung pada potongan kode contoh', () {
    test('komentar tidak dihitung, string dihitung', () {
      final a = aturan[2];
      expect(a.hitung("// A · B\nfinal s = 'A · B';"), 1);
      expect(a.hitung('/* A · B */ final s = "tanpa pemisah";'), 0);
    });
  });

  for (final a in aturan) {
    test('${a.nama}: tidak naik, tidak ada berkas baru, tidak ada sisa', () {
      final sekarang = <String, int>{};
      final berkas = Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'));
      for (final f in berkas) {
        final jalur = f.path.replaceAll('\\', '/');
        if (jalur == a.dikecualikan) continue;
        final n = a.hitung(f.readAsStringSync());
        if (n > 0) sekarang[jalur] = n;
      }

      final naik = <String>[];
      final sisa = <String>[];
      for (final e in sekarang.entries) {
        final d = a.baseline[e.key];
        if (d == null) {
          naik.add('${e.key}: pemakaian baru (${e.value})');
        } else if (e.value > d) {
          naik.add('${e.key}: $d -> ${e.value}');
        } else if (e.value < d) {
          sisa.add('turunkan angka ${e.key} ke ${e.value} (dulu $d)');
        }
      }
      for (final e in a.baseline.entries) {
        if (!sekarang.containsKey(e.key)) {
          sisa.add(
            'turunkan angka ${e.key} ke 0 (dulu ${e.value}; hapus baris)',
          );
        }
      }
      expect(
        naik,
        isEmpty,
        reason:
            '${a.nama} NAIK. ${a.alasan}. Pakai komponen baru; jangan '
            'menaikkan angka:\n${naik.join('\n')}',
      );
      expect(
        sisa,
        isEmpty,
        reason:
            '${a.nama} berkurang tetapi angka di test/tema/anti_slop_test.dart '
            'belum diturunkan:\n${sisa.join('\n')}',
      );
    });
  }
}

class _Aturan {
  const _Aturan({
    required this.nama,
    required this.alasan,
    required this.pola,
    required this.dikecualikan,
    required this.baseline,
  });

  final String nama;
  final String alasan;
  final RegExp pola;

  /// Berkas yang tidak dihitung (definisi kelasnya sendiri); kosong = tidak ada.
  final String dikecualikan;
  final Map<String, int> baseline;

  int hitung(String sumber) =>
      pola.allMatches(PemindaiToken.buangKomentar(sumber)).length;
}
