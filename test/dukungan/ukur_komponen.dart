// Perkakas ukur untuk tes komponen bersama (`lib/widgets`): pembungkus aplikasi
// dengan tema Pelanggan, kontras WCAG dari POHON widget (bukan sampel piksel,
// yang sering salah menandai), pemeriksa pedoman sentuh + label, dan pemecah
// baris teks. Dipakai `test/widgets/*` dan harness `render_komponen_test.dart`.
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sidik_pelanggan/core/tema/spasi.dart';
import 'package:sidik_pelanggan/core/tema/tema_sidik.dart';

/// Aplikasi uji: tema Pelanggan, [skala] huruf, dan [anak] di dalam halaman
/// bergulir bermargin 20 dp (lebar isi = lebar layar dikurangi 40), seperti
/// layar sungguhan.
Widget aplikasiUji(
  Widget anak, {
  bool gelap = false,
  double skala = 1.0,
  bool bergulir = true,
}) => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: TemaSidik.terang,
  darkTheme: TemaSidik.gelap,
  themeMode: gelap ? ThemeMode.dark : ThemeMode.light,
  builder: (context, child) => MediaQuery.withClampedTextScaling(
    minScaleFactor: skala,
    maxScaleFactor: skala,
    child: child!,
  ),
  home: Scaffold(
    body: bergulir
        ? SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: Spasi.sisi),
            child: anak,
          )
        : anak,
  ),
);

/// Rasio kontras WCAG 2.x antara dua warna buram.
double rasioKontras(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final terang = la > lb ? la : lb;
  final gelap = la > lb ? lb : la;
  return (terang + 0.05) / (gelap + 0.05);
}

/// Warna latar yang terlihat di belakang [elemen]: `Material`, kotak berlatar,
/// `ColoredBox`, atau `Scaffold` terdekat ke atas.
Color latarEfektif(Element elemen) {
  Color? hasil;
  elemen.visitAncestorElements((a) {
    final w = a.widget;
    Color? c;
    if (w is Material && w.type != MaterialType.transparency) {
      c = w.color;
    } else if (w is DecoratedBox && w.decoration is BoxDecoration) {
      c = (w.decoration as BoxDecoration).color;
    } else if (w is ColoredBox) {
      c = w.color;
    } else if (w is Scaffold) {
      c = w.backgroundColor ?? Theme.of(a).scaffoldBackgroundColor;
    }
    if (c != null && c.a > 0) {
      hasil = c;
      return false;
    }
    return true;
  });
  return hasil ?? Theme.of(elemen).scaffoldBackgroundColor;
}

/// Satu potong teks beserta warna dan latarnya yang terlihat.
typedef TeksTerukur = ({
  String teks,
  Color warna,
  Color latar,
  double ukuran,
  double rasio,
});

void _kumpul(
  InlineSpan span,
  TextStyle? ortu,
  void Function(String teks, TextStyle gaya) catat,
) {
  if (span is! TextSpan) return;
  final gaya = ortu == null
      ? span.style
      : (span.style == null ? ortu : ortu.merge(span.style));
  final teks = span.text;
  if (teks != null && teks.trim().isNotEmpty && gaya != null) {
    catat(teks, gaya);
  }
  for (final c in span.children ?? const <InlineSpan>[]) {
    _kumpul(c, gaya, catat);
  }
}

/// Semua teks di bawah [dalam] dengan rasio kontras terhadap latarnya.
List<TeksTerukur> ukurTeks(WidgetTester tester, Finder dalam) {
  final hasil = <TeksTerukur>[];
  final kotak = tester.widgetList<RichText>(
    find.descendant(of: dalam, matching: find.byType(RichText)),
  );
  for (final rt in kotak) {
    final elemen = tester.element(find.byWidget(rt));
    final latar = latarEfektif(elemen);
    _kumpul(rt.text, null, (teks, gaya) {
      final warna = gaya.color;
      if (warna == null) return;
      final nyata = Color.alphaBlend(warna, latar);
      hasil.add((
        teks: teks,
        warna: nyata,
        latar: latar,
        ukuran: gaya.fontSize ?? 0,
        rasio: rasioKontras(nyata, latar),
      ));
    });
  }
  return hasil;
}

/// Pelanggaran kontras teks (< [minimum]) di bawah [dalam]; kosong = lolos.
List<String> pelanggaranKontrasTeks(
  WidgetTester tester,
  Finder dalam, {
  double minimum = 4.5,
}) {
  final semua = ukurTeks(tester, dalam);
  expect(semua, isNotEmpty, reason: 'tidak ada teks berwarna yang terukur');
  return [
    for (final x in semua)
      if (x.rasio < minimum)
        '"${x.teks}" ${x.rasio.toStringAsFixed(2)}:1 < $minimum '
            '(teks ${x.warna} di latar ${x.latar})',
  ];
}

/// Pedoman Flutter: sasaran sentuh Android >= 48 dp dan label untuk setiap
/// sasaran sentuh. Wajib dipanggil di antara `ensureSemantics()` dan `dispose()`
/// milik pemanggil, dan sebelum `pumpWidget`.
Future<void> periksaPedomanSentuh(WidgetTester tester) async {
  await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
  await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
}

/// Pecah teks satu paragraf menjadi baris-baris yang dilihat pengguna
/// (karakter dikelompokkan menurut tinggi kotaknya).
List<String> barisTeks(RenderParagraph p) {
  final teks = p.text.toPlainText();
  final baris = <String>[];
  final sekarang = StringBuffer();
  double? atasTerakhir;
  for (var i = 0; i < teks.length; i++) {
    final kotak = p.getBoxesForSelection(
      TextSelection(baseOffset: i, extentOffset: i + 1),
    );
    if (kotak.isNotEmpty) {
      final atas = kotak.first.top;
      if (atasTerakhir != null && atas - atasTerakhir > 1) {
        baris.add(sekarang.toString());
        sekarang.clear();
      }
      atasTerakhir = atas;
    }
    sekarang.write(teks[i]);
  }
  if (sekarang.isNotEmpty) baris.add(sekarang.toString());
  return baris;
}

/// Semua teks (gabungan) yang tampil di bawah [dalam].
String semuaTeks(WidgetTester tester, Finder dalam) => tester
    .widgetList<RichText>(
      find.descendant(of: dalam, matching: find.byType(RichText)),
    )
    .map((r) => r.text.toPlainText())
    .join('\n');

/// Node semantik text-field di seluruh pohon (semantik harus sudah menyala:
/// `tester.ensureSemantics()` sebelum `pumpWidget`).
List<SemanticsNode> nodeTextField(WidgetTester tester) => find.semantics
    .byPredicate((n) => n.getSemanticsData().flagsCollection.isTextField)
    .evaluate()
    .toList();
