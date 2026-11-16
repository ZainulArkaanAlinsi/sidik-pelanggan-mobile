import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sidik_pelanggan/core/tema/bentuk.dart';
import 'package:sidik_pelanggan/core/tema/palet_sidik.dart';
import 'package:sidik_pelanggan/core/tema/spasi.dart';
import 'package:sidik_pelanggan/core/tema/tema_sidik.dart';
import 'package:sidik_pelanggan/core/tema/tipografi.dart';
import 'package:sidik_pelanggan/core/tema/ukuran.dart';
import 'package:sidik_pelanggan/core/tema/warna_sidik.dart';

/// Gerbang desain Pelanggan, bagian 5: token Dart = `docs/desain-ulang/tokens.json`.
///
/// Berkas itu (diselaraskan ke REVISI 16 Nov 2026, lihat
/// `docs/desain-ulang/REVISI-16NOV.md`) menulis semua angka desain di satu
/// tempat. Tes ini mencocokkan nilainya dengan token di `lib/core/tema/`,
/// supaya angka di kode tidak diam-diam menyimpang dari desain (atau
/// sebaliknya). Mengubah salah satunya = keputusan desain: ubah dua-duanya dan
/// jelaskan di PR. (Nama berkas tes dipertahankan dari arah lama.)
///
/// Yang SENGAJA tidak sama dengan tokens.json dicatat di tes bernama
/// "penyimpangan" di bawah, lengkap dengan alasannya.
void main() {
  final json =
      jsonDecode(File('docs/desain-ulang/tokens.json').readAsStringSync())
          as Map<String, dynamic>;
  Map<String, dynamic> bagian(String k) => json[k] as Map<String, dynamic>;

  String hex(Color c) =>
      '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

  group('warna: PaletSidik = tokens.json', () {
    test('teks, aksi, latar, status muda, dan netral', () {
      final w = bagian('warna');
      final dart = <String, Color>{
        'navy': PaletSidik.navy,
        'biru': PaletSidik.biru,
        'biruMuda': PaletSidik.biruMuda,
        'navyLembut': PaletSidik.navyLembut,
        'navyTeks': PaletSidik.navyTeks,
        'kuning': PaletSidik.kuning,
        'koral': PaletSidik.koral,
        'hijau': PaletSidik.hijau,
        'langit': PaletSidik.langit,
        'latar': PaletSidik.latar,
        'kartu': PaletSidik.kartu,
        'latarTinggi': PaletSidik.latarTinggi,
        'teksKedua': PaletSidik.teksKedua,
        'garis': PaletSidik.garis,
        'kobaltLogo': PaletSidik.kobaltLogo,
      };
      expect(dart.keys.toSet(), w.keys.toSet());
      for (final e in dart.entries) {
        expect(hex(e.value), (w[e.key] as String).toUpperCase(), reason: e.key);
      }
    });

    test('REVISI-1 §2: nilai persis dari dokumen revisi', () {
      expect(hex(PaletSidik.latar), '#F4F7FB');
      expect(hex(PaletSidik.kartu), '#FFFFFF');
      expect(hex(PaletSidik.navy), '#102A43');
      expect(hex(PaletSidik.teksKedua), '#526477');
      expect(hex(PaletSidik.biru), '#1769C2');
      expect(hex(PaletSidik.biruMuda), '#EAF3FF');
      expect(hex(PaletSidik.garis), '#DCE5EE');
      // Skema tema terang memakainya: aksi biru, teks navy, pilihan biru muda.
      final s = TemaSidik.terang.colorScheme;
      expect(s.primary, PaletSidik.biru);
      expect(s.onSurface, PaletSidik.navy);
      expect(s.onSurfaceVariant, PaletSidik.teksKedua);
      expect(s.primaryContainer, PaletSidik.biruMuda);
      expect(s.surface, PaletSidik.kartu);
      expect(TemaSidik.terang.scaffoldBackgroundColor, PaletSidik.latar);
      expect(s.outlineVariant, PaletSidik.garis);
    });

    test('status terang: tinta gelap di atas latar muda', () {
      final st = bagian('status');
      final warna = bagian('warna');
      final tinta = bagian('tintaStatus');
      final dart = WarnaSidik.terang;
      final pasangan = <String, (Color, Color)>{
        'lulus': (dart.lulus, dart.lulusLatar),
        'awas': (dart.awas, dart.awasLatar),
        'gagal': (dart.gagal, dart.gagalLatar),
        'tunggu': (dart.tunggu, dart.tungguLatar),
      };
      for (final e in pasangan.entries) {
        final spek = st[e.key] as Map<String, dynamic>;
        expect(
          hex(e.value.$2),
          (warna[spek['latar']] as String).toUpperCase(),
          reason: '${e.key}: latar',
        );
        expect(
          hex(e.value.$1),
          (tinta[spek['tinta']] as String).toUpperCase(),
          reason: '${e.key}: tinta',
        );
        // Tinta GELAP (bukan navy sama-rata): status dibedakan ikon + kata +
        // tinta yang berjenjang terangnya.
        expect(e.value.$1, isNot(PaletSidik.navy), reason: e.key);
      }
    });
  });

  group('bentuk, spasi, dan ukuran = tokens.json', () {
    test('sudut', () {
      final s = bagian('sudut');
      expect(<String, num>{
        'stempel': Bentuk.stempel,
        'tombol': Bentuk.tombol,
        'ikon': Bentuk.ikon,
        'kapsul': Bentuk.kapsul,
        'panel': Bentuk.panel,
        'ubin': Bentuk.ubin,
        'penanda': Bentuk.penanda,
        'pil': Bentuk.pil,
      }, s);
    });

    test('REVISI-1 §3: kartu 12-16, tombol dan isian 8-12', () {
      for (final r in [Bentuk.panel, Bentuk.ubin]) {
        expect(r, inInclusiveRange(12, 16));
      }
      for (final r in [Bentuk.tombol, Bentuk.ikon, Bentuk.kapsul]) {
        expect(r, inInclusiveRange(8, 12));
      }
    });

    test('spasi', () {
      final s = bagian('spasi');
      expect(<String, num>{
        'xs': Spasi.xs,
        'sm': Spasi.sm,
        'md': Spasi.md,
        'lg': Spasi.lg,
        'xl': Spasi.xl,
        'xxl': Spasi.xxl,
        'sisi': Spasi.sisi,
        'antarUbin': Spasi.antarUbin,
      }, s);
    });

    test('ukuran', () {
      final u = bagian('ukuran');
      final dart = <String, Object>{
        'tombolUtama': UkuranBaris.tombolUtama,
        'tombolBulatKecil': UkuranKontrol.tombolBulatKecil,
        'tombolBulat': UkuranKontrol.tombolBulat,
        'tombolBulatBesar': UkuranKontrol.tombolBulatBesar,
        'saringan': UkuranKontrol.saringan,
        'segmenLuar': UkuranKontrol.segmenLuar,
        'segmenDalam': UkuranKontrol.segmenDalam,
        'kolomCari': UkuranKontrol.kolomCari,
        'sakelar': [
          UkuranKontrol.sakelarLebar,
          UkuranKontrol.sakelarTinggi,
          UkuranKontrol.sakelarTombol,
        ],
        'stempel': UkuranKontrol.stempel,
        'barisMenu': UkuranUbin.barisMenu,
        'barisDaftar': UkuranUbin.barisDaftar,
        'ubinIkon': UkuranUbin.ubinIkon,
        'avatar': UkuranUbin.avatar,
        'avatarBesar': UkuranUbin.avatarBesar,
        'bilah': UkuranBilah.tinggi,
        'indikatorBilah': [
          UkuranBilah.indikatorLebar,
          UkuranBilah.indikatorTinggi,
        ],
        'ubinAlat': UkuranUbin.alat,
        'ubinAlatBeranda': UkuranUbin.alatBeranda,
        'ubinPasangan': UkuranUbin.pasangan,
        'ubinMenu': UkuranUbin.menu,
        'kapsulRel': UkuranUbin.kapsulRel,
        'kapsulMin': UkuranUbin.kapsulMin,
        'visualAlat': UkuranVisual.alat,
        'visualAlatBeranda': UkuranVisual.alatBeranda,
        'visualUbinKecil': UkuranVisual.ubinKecil,
      };
      expect(dart.keys.toSet(), u.keys.toSet());
      for (final e in dart.entries) {
        expect(e.value, u[e.key], reason: e.key);
      }
      // Baris daftar sama di dua token (tidak boleh menyimpang).
      expect(UkuranUbin.barisDaftar, UkuranBaris.minimum);
    });

    test('REVISI-1 §3: tombol dan isian utama 44-48 dp', () {
      expect(UkuranBaris.tombolUtama, inInclusiveRange(44, 48));
      expect(UkuranKontrol.kolomCari, inInclusiveRange(44, 48));
      expect(UkuranKontrol.segmenLuar, inInclusiveRange(44, 48));
      expect(AreaSentuh.minimum, greaterThanOrEqualTo(44));
    });
  });

  group('huruf: TextTheme dan angka sorot = tokens.json', () {
    test('ukuran, tinggi baris, dan berat', () {
      final h = bagian('huruf');
      final t = TemaSidik.terang.textTheme;
      final sorot = TipografiSidik.angkaSorot(teks: PaletSidik.navy);
      final dart = <String, TextStyle?>{
        'angkaSorot': sorot,
        'angkaKartu': t.displayLarge,
        'kalimat': t.displayMedium,
        'judulLayar': t.displaySmall,
        'nama': t.headlineMedium,
        'judulBar': t.titleLarge,
        'judulBagian': t.titleMedium,
        'label': t.titleSmall,
        'isiBacaan': t.bodyLarge,
        'isi': t.bodyMedium,
        'keterangan': t.bodySmall,
        'stempel': t.labelMedium,
      };
      expect(h['keluarga'], TipografiSidik.keluarga);
      expect(h['keluargaAngka'], TipografiSidik.keluargaAngka);
      for (final e in dart.entries) {
        final spek = (h[e.key] as List).cast<num>();
        final g = e.value!;
        expect(g.fontSize, spek[0], reason: '${e.key}: ukuran');
        expect(
          g.height! * g.fontSize!,
          closeTo(spek[1], 1e-9),
          reason: '${e.key}: tinggi baris',
        );
        expect(
          g.fontWeight ?? FontWeight.w400,
          FontWeight.values[(spek[2].toInt() ~/ 100) - 1],
          reason: '${e.key}: berat',
        );
      }
      // Tanpa spasi huruf negatif (judul besar yang dirapatkan menyempit di
      // layar sempit dengan huruf diperbesar).
      for (final e in dart.entries) {
        expect(e.value!.letterSpacing ?? 0, 0, reason: '${e.key}: spasi huruf');
      }
    });

    test('REVISI-1 §3: judul halaman 22-24, judul bagian 16-18, isi 14-16, '
        'metadata 12-13', () {
      final t = TemaSidik.terang.textTheme;
      expect(t.displaySmall!.fontSize, inInclusiveRange(22, 24));
      expect(t.titleMedium!.fontSize, inInclusiveRange(16, 18));
      expect(t.bodyLarge!.fontSize, inInclusiveRange(14, 16));
      expect(t.bodyMedium!.fontSize, inInclusiveRange(14, 16));
      expect(t.bodySmall!.fontSize, inInclusiveRange(12, 13));
      expect(t.labelMedium!.fontSize, inInclusiveRange(12, 13));
    });

    test(
      'angka (sisa hari, KPI) memakai IBM Plex Mono; teks memakai Inter',
      () {
        final t = TemaSidik.terang.textTheme;
        expect(t.displayLarge!.fontFamily, TipografiSidik.keluargaAngka);
        expect(
          TipografiSidik.angkaSorot(teks: PaletSidik.navy).fontFamily,
          TipografiSidik.keluargaAngka,
        );
        expect(t.bodyMedium!.fontFamily, TipografiSidik.keluarga);
        expect(t.bodyMedium!.nomor.fontFamily, TipografiSidik.keluargaAngka);
      },
    );
  });

  group('penyimpangan sadar dari tokens.json', () {
    test('tepi kontrol = garisTegas, bukan garis (WCAG 3:1)', () {
      // tokens.json `garis` (#DCE5EE) dipakai untuk pemisah dan garis halus.
      // Tepi isian, tombol sekunder, dan sakelar mati memakai garisTegas
      // (#66788A) agar lolos 3:1; lihat kontras_tema_test.dart.
      expect(TemaSidik.terang.colorScheme.outlineVariant, PaletSidik.garis);
      expect(TemaSidik.terang.colorScheme.outline, PaletSidik.garisTegas);
    });

    test('tema gelap: tinta status pastel, bukan tinta gelap tema terang', () {
      // Tinta status juga dipakai langsung sebagai teks di atas halaman, jadi
      // di tema gelap tinta = pastel dan latar = nada gelap yang sama.
      final g = WarnaSidik.gelap;
      expect(g.lulus, PaletSidik.hijauTintaGelap);
      expect(g.awas, PaletSidik.kuningTintaGelap);
      expect(g.gagal, PaletSidik.koralTintaGelap);
      expect(g.tunggu, PaletSidik.biruDiGelap);
      expect(g.lulus, isNot(WarnaSidik.terang.lulus));
    });

    test('error: merah tua galat, bukan merah muda', () {
      // Merah muda (`koral`) = latar status gagal. Galat isian dan tombol
      // bahaya memakai merah tua #A3261A agar lolos 4,5:1; tinta status gagal
      // di tema terang memakai warna yang sama.
      expect(hex(PaletSidik.galat), '#A3261A');
      expect(TemaSidik.terang.colorScheme.error, PaletSidik.galat);
      expect(WarnaSidik.terang.gagal, PaletSidik.galat);
    });

    test('UbinBiru (kepala layar masuk) sama di dua tema', () {
      expect(WarnaSidik.terang.ubinBiru, PaletSidik.biruMuda);
      expect(WarnaSidik.gelap.ubinBiru, PaletSidik.biruMuda);
    });
  });
}
