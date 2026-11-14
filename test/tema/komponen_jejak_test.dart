import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:sidik_pelanggan/core/tema/ukuran.dart';

import '../dukungan/daftar_komponen.dart';
import '../dukungan/pemindai_token.dart';

/// Gerbang komponen bersama "Jejak" (Paket 2), pelengkap `token_only_test`,
/// `anti_slop_test`, dan `kontras_tema_test`:
///
/// - PENDAFTARAN: tiap berkas komponen ada, mendeklarasikan kelasnya, diimpor
///   galeri render (jadi masuk harness), punya tes widget, dan tercatat di
///   `lib/widgets/README.md`. Komponen belum dipakai layar (Paket 3); repo
///   tidak punya pemeriksa berkas yatim di `tool/` atau CI, jadi daftar +
///   galeri inilah yang menjaganya.
/// - TOKEN SAJA di komponen: tanpa angka mentah pada parameter ukuran
///   (`width`, `height`, `dimension`, `radius`, `EdgeInsets.*`, `fontSize`),
///   tanpa warna mentah, tanpa " · ", tanpa "kedaluwarsa".
/// - SENTUH + LABEL: berkas yang punya `InkWell` memakai ukuran sentuh dari
///   token (`AreaSentuh.minimum`/`UkuranBaris.minimum`) dan `Semantics`.
void main() {
  String kode(String berkas) => PemindaiToken.buangKomentar(
    File('lib/widgets/$berkas.dart').readAsStringSync(),
  );

  group('pendaftaran: tak satu pun komponen yatim', () {
    final galeri = File(
      'test/dukungan/galeri_komponen.dart',
    ).readAsStringSync();
    final readme = File('lib/widgets/README.md').readAsStringSync();
    final tesWidget = [
      for (final f in Directory('test/widgets').listSync().whereType<File>())
        if (f.path.endsWith('_test.dart')) f.readAsStringSync(),
    ].join('\n');

    for (final e in daftarKomponenJejak.entries) {
      test('${e.key}.dart: ada, kelas dideklarasikan, diimpor galeri, dites, '
          'tercatat di README', () {
        final sumber = File('lib/widgets/${e.key}.dart');
        expect(sumber.existsSync(), isTrue, reason: '${e.key}.dart tidak ada');
        final isi = sumber.readAsStringSync();
        for (final kelas in e.value) {
          expect(
            RegExp('\\b(class|enum) $kelas\\b').hasMatch(isi),
            isTrue,
            reason: '$kelas tidak dideklarasikan di ${e.key}.dart',
          );
        }
        expect(
          galeri,
          contains("package:sidik_pelanggan/widgets/${e.key}.dart"),
          reason:
              '${e.key}.dart tidak diimpor galeri render (yatim dari harness)',
        );
        expect(
          readme,
          contains('${e.key}.dart'),
          reason: '${e.key}.dart tidak tercatat di lib/widgets/README.md',
        );
        final utama = e.value.first;
        expect(
          RegExp('\\b$utama\\b').hasMatch(tesWidget),
          isTrue,
          reason: '$utama tidak punya tes widget di test/widgets',
        );
      });
    }

    test('daftar mencakup semua berkas komponen Jejak (tanpa berkas liar)', () {
      // Berkas baru di lib/widgets yang bukan komponen lama harus masuk daftar
      // atau dikecualikan sengaja: tes ini menghitung berkasnya.
      final lama = {
        'bagian_sidik',
        'banner',
        'baris_info',
        'baris_menu',
        'chip_status',
        'daftar_berhalaman',
        'garis_waktu_sertifikat',
        'halaman_sidik',
        'kartu_alat',
        'kartu_kelompok_arsip',
        'kartu_paket',
        'kartu_sertifikat',
        'kartu_sidik',
        'keadaan_galat',
        'keadaan_kosong',
        'kerangka',
        'kolom_cari',
        'kolom_formulir',
        'konten_tengah',
        'lencana_kan',
        'logo_sidik',
        'navigasi_utama',
        'panel_pemberitahuan',
        'pembaruan',
        'pemetaan_status',
        'penampil_pdf',
        'status_tampil',
        'tombol_sidik',
      };
      final semua = {
        for (final f in Directory('lib/widgets').listSync().whereType<File>())
          if (f.path.endsWith('.dart'))
            f.uri.pathSegments.last.replaceAll('.dart', ''),
      };
      expect(
        semua.difference(lama).difference(daftarKomponenJejak.keys.toSet()),
        isEmpty,
        reason:
            'berkas baru di lib/widgets yang belum masuk daftarKomponenJejak',
      );
    });
  });

  group('token saja di komponen Jejak', () {
    // Parameter ukuran yang tidak boleh berisi angka (selain nol).
    final ukuranMentah = RegExp(
      r'\b(width|height|minHeight|maxHeight|minWidth|maxWidth|dimension|radius|'
      r'thickness|spacing|runSpacing|indent|endIndent|fontSize)\s*:\s*'
      r'[^,;)]*?(?<=[:?]\s*)[1-9]\d*(\.\d+)?(?![\w.])',
    );
    final jarakMentah = RegExp(
      r'EdgeInsets(Directional)?\.\w+\([^)]*(?<=[(:,?]\s*)[1-9]\d*(\.\d+)?(?![\w.])',
    );

    for (final berkas in daftarKomponenJejak.keys) {
      test('$berkas.dart', () {
        final c = kode(berkas);
        expect(
          ukuranMentah.allMatches(c).map((m) => m.group(0)).toList(),
          isEmpty,
          reason:
              'angka mentah pada parameter ukuran: pakai Spasi, UkuranTik, '
              'UkuranBaris, AreaSentuh, UkuranIkon, Bentuk',
        );
        expect(
          jarakMentah.allMatches(c).map((m) => m.group(0)).toList(),
          isEmpty,
          reason: 'angka mentah pada EdgeInsets: pakai Spasi',
        );
        expect(RegExp(r'\bColors\.(?!transparent)\w+').hasMatch(c), isFalse);
        expect(RegExp(r'\bColor\(').hasMatch(c), isFalse);
        expect(RegExp(r'#[0-9A-Fa-f]{6}').hasMatch(c), isFalse);
        expect(c.contains(' · '), isFalse, reason: 'rangkaian A · B · C');
        expect(
          c.toLowerCase(),
          isNot(anyOf(contains('daluwarsa'), contains('adaluarsa'))),
          reason: 'istilah terlarang (K3): "Lewat jadwal", bukan kedaluwarsa',
        );
      });
    }

    test('pola pendeteksi angka mentah bekerja pada contoh', () {
      expect(ukuranMentah.hasMatch('SizedBox.square(dimension: 14)'), isTrue);
      expect(ukuranMentah.hasMatch('Container(height: 6 + x)'), isTrue);
      expect(ukuranMentah.hasMatch('width: UkuranTik.batang'), isFalse);
      expect(
        ukuranMentah.hasMatch('height: i == p ? UkuranTik.a : UkuranTik.b'),
        isFalse,
      );
      expect(ukuranMentah.hasMatch('width: double.infinity'), isFalse);
      expect(jarakMentah.hasMatch('EdgeInsets.all(12)'), isTrue);
      expect(jarakMentah.hasMatch('EdgeInsets.symmetric(vertical: 4)'), isTrue);
      expect(jarakMentah.hasMatch('EdgeInsets.all(Spasi.lg)'), isFalse);
      expect(
        jarakMentah.hasMatch('EdgeInsets.only(bottom: t ? 0 : Spasi.lg)'),
        isFalse,
      );
    });
  });

  group('sentuh dan label di komponen yang bisa diketuk', () {
    for (final berkas in daftarKomponenJejak.keys) {
      final c = kode(berkas);
      if (!c.contains('InkWell(')) continue;
      test('$berkas.dart: ukuran sentuh dari token + Semantics', () {
        expect(
          c.contains('AreaSentuh.minimum') || c.contains('UkuranBaris.minimum'),
          isTrue,
          reason: 'InkWell tanpa tinggi minimum dari token (48 dp)',
        );
        expect(c.contains('Semantics('), isTrue, reason: 'InkWell tanpa label');
        expect(
          c.contains('onTap:'),
          isTrue,
          reason:
              'Semantics tanpa aksi ketuk: excludeSemantics membuang aksi '
              'InkWell, pembaca layar tidak bisa mengaktifkannya',
        );
      });
    }
  });

  group('token baru Paket 2', () {
    test('geometri jejak dan batas huruf besar', () {
      expect(UkuranTik.simpul, 14);
      expect(
        UkuranTik.simpulSekarang,
        UkuranTik.simpul + 2 * UkuranTik.lingkar,
      );
      expect(UkuranTik.batang, 2);
      expect(UkuranTik.garisBawah, 3);
      expect(UkuranTik.penanda, 24);
      expect(UkuranTik.tikPaketMaksimum, 24);
      expect(SkalaHuruf.batasBesar, 1.15);
      expect(SkalaHuruf.nomorMinimum, 12);
    });
  });
}
