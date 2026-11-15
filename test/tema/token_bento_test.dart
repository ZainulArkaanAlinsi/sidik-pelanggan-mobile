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
/// Paket desain Bento Lab menulis semua angkanya di satu berkas. Tes ini
/// mencocokkan nilai itu dengan token di `lib/core/tema/`, supaya angka di
/// kode tidak diam-diam menyimpang dari desain (atau sebaliknya). Mengubah
/// salah satunya = keputusan desain: ubah dua-duanya dan jelaskan di PR.
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
    test('merek, ubin, dan netral', () {
      final w = bagian('warna');
      final dart = <String, Color>{
        'navy': PaletSidik.navy,
        'navyLembut': PaletSidik.navyLembut,
        'navyTeks': PaletSidik.navyTeks,
        'kuning': PaletSidik.kuning,
        'koral': PaletSidik.koral,
        'hijau': PaletSidik.hijau,
        'langit': PaletSidik.langit,
        'latar': PaletSidik.latar,
        'kartu': PaletSidik.kartu,
        'teksKedua': PaletSidik.teksKedua,
        'garis': PaletSidik.garis,
        'kobaltLogo': PaletSidik.kobaltLogo,
      };
      expect(dart.keys.toSet(), w.keys.toSet());
      for (final e in dart.entries) {
        expect(hex(e.value), (w[e.key] as String).toUpperCase(), reason: e.key);
      }
    });

    test('status terang: latar = ubin, tinta = navy', () {
      final st = bagian('status');
      final warna = bagian('warna');
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
          (warna[spek['tinta']] as String).toUpperCase(),
          reason: '${e.key}: tinta',
        );
      }
    });
  });

  group('bentuk, spasi, dan ukuran = tokens.json', () {
    test('sudut', () {
      final s = bagian('sudut');
      expect(<String, num>{
        'ikon': Bentuk.ikon,
        'kapsul': Bentuk.kapsul,
        'panel': Bentuk.panel,
        'ubin': Bentuk.ubin,
        'dock': Bentuk.dock,
        'pil': Bentuk.pil,
      }, s);
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
        'dock': UkuranDock.tinggi,
        'butirDock': UkuranDock.butir,
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
      // Dock dari bawah ada di tokens.json sebagai "melayang 16" (UKURAN.md).
      expect(UkuranDock.dariBawah, 16);
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
        'keterangan': t.bodySmall,
        'stempel': t.labelMedium,
      };
      expect(h['keluarga'], 'Inter');
      for (final e in dart.entries) {
        final spek = (h[e.key] as List).cast<num>();
        final g = e.value!;
        expect(g.fontSize, spek[0], reason: '${e.key}: ukuran');
        expect(
          g.height! * g.fontSize!,
          closeTo(spek[1], 1e-9),
          reason: '${e.key}: tinggi baris',
        );
        // PENYIMPANGAN (utang): tokens.json meminta 800 untuk tingkat tebal,
        // tetapi Inter yang dibundel tak punya 800: tampil sebagai
        // `TipografiSidik.beratTebal` (700). Lihat tema_sidik_test.dart.
        final berat = spek[2].toInt();
        final tampil = berat == 800
            ? TipografiSidik.beratTebal
            : FontWeight.values[(berat ~/ 100) - 1];
        expect(g.fontWeight, tampil, reason: '${e.key}: berat');
      }
    });
  });

  group('penyimpangan sadar dari tokens.json / DESIGN.md', () {
    test('tepi kontrol = garisTegas, bukan garis (WCAG 3:1)', () {
      // tokens.json `garis` (#D5DAE3) dipakai untuk pemisah dan garis halus.
      // Tepi isian, tombol sekunder, dan sakelar mati memakai garisTegas
      // (#6B7588, nilai Jejak) agar lolos 3:1; lihat kontras_tema_test.dart.
      expect(TemaSidik.terang.colorScheme.outlineVariant, PaletSidik.garis);
      expect(TemaSidik.terang.colorScheme.outline, PaletSidik.garisTegas);
    });

    test('tema gelap: tinta status pastel, bukan navy', () {
      // DESIGN.md §Mode gelap: "ubin tetap terang, tinta navy". Tinta status
      // juga dipakai langsung sebagai teks di atas halaman, jadi di tema
      // gelap tinta = pastel dan latar = nada gelap yang sama.
      final g = WarnaSidik.gelap;
      expect(g.lulus, PaletSidik.hijau);
      expect(g.awas, PaletSidik.kuning);
      expect(g.gagal, PaletSidik.koral);
      expect(g.tunggu, PaletSidik.langit);
      expect(g.lulus, isNot(PaletSidik.navy));
    });

    test('error: merah tua galat (ELEMEN.md), bukan koral', () {
      // Koral = status gagal (ubin). Galat isian dan tombol bahaya memakai
      // merah tua #A3261A (ELEMEN.md §Dialog konfirmasi) agar lolos 4,5:1.
      expect(hex(PaletSidik.galat), '#A3261A');
      expect(TemaSidik.terang.colorScheme.error, PaletSidik.galat);
    });
  });
}
