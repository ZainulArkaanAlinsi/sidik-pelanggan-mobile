// KolomIsian (R1b, REVISI-1 §5 dan §9, REVISI-2 butir 1): label PERMANEN di atas
// kolom, bantuan dan galat tepat di bawahnya, tinggi kolom 48, satu simpul
// semantik, tahan huruf besar, dan ruang agar tombol di bawah kolom tidak
// tertutup papan ketik.
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderParagraph;
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sidik_pelanggan/core/tema/spasi.dart';
import 'package:sidik_pelanggan/core/tema/tema_sidik.dart';
import 'package:sidik_pelanggan/core/tema/ukuran.dart';
import 'package:sidik_pelanggan/widgets/kolom_isian.dart';

import '../dukungan/fixture_fitur.dart';
import '../dukungan/layar_uji.dart';
import '../dukungan/ukur_komponen.dart';

Widget _app(Widget anak, {bool gelap = false, double skala = 1.0}) =>
    aplikasiUji(anak, gelap: gelap, skala: skala, bergulir: false);

KolomIsian _kolom({
  String label = 'Email',
  TextEditingController? pengendali,
  String? bantuan,
  String? galat,
  bool aktif = true,
  bool rahasia = false,
  String? petunjuk,
}) => KolomIsian(
  label: label,
  pengendali: pengendali ?? TextEditingController(),
  bantuan: bantuan,
  galat: galat,
  aktif: aktif,
  rahasia: rahasia,
  petunjuk: petunjuk,
);

Finder get _isian => find.byType(TextField);

/// Teks yang diketik (EditableText): tepi atas/bawahnya = isi kolom, tanpa
/// teks bantuan/galat di bawah kolom yang ikut dihitung `TextField`.
Finder get _teksKolom => find.descendant(
  of: find.byType(TextField),
  matching: find.byType(EditableText),
);

void main() {
  setUpAll(siapkanTesFitur);

  group('label permanen di atas kolom', () {
    testWidgets('label tampil saat kosong, fokus, dan terisi; di atas kolom, '
        'bukan labelText yang mengambang', (tester) async {
      layarHp(tester, lebar: 392, tinggi: 800);
      final p = TextEditingController();
      await tester.pumpWidget(_app(_kolom(pengendali: p)));
      final dekor = tester.widget<TextField>(_isian).decoration!;
      expect(dekor.labelText, isNull, reason: 'label bukan labelText di dalam');
      expect(dekor.label, isNull);

      void periksa(String keadaan) {
        expect(find.text('Email'), findsOneWidget, reason: keadaan);
        // Label tepat di atas kolom: bawah label + jarak = atas kolom.
        final label = tester.getRect(find.text('Email'));
        final kolom = tester.getRect(_isian);
        expect(label.bottom, lessThanOrEqualTo(kolom.top), reason: keadaan);
        expect(
          kolom.top - label.bottom,
          lessThanOrEqualTo(KolomIsian.jarakLabel + 4),
          reason: keadaan,
        );
        expect(
          label.left,
          kolom.left,
          reason: '$keadaan: rata kiri dengan kolom',
        );
      }

      periksa('kosong');
      await tester.tap(_isian);
      await tester.pump();
      periksa('fokus');
      await tester.enterText(_isian, 'budi@contoh.test');
      await tester.pump();
      periksa('terisi');
      // Label kata permanen: berwarna teks utama, bukan petunjuk yang pudar.
      expect(
        tester.widget<Text>(find.text('Email')).style!.color,
        TemaSidik.terang.colorScheme.onSurface,
      );
    });

    testWidgets('petunjuk hanya contoh isi: hilang saat terisi, label tetap', (
      tester,
    ) async {
      final p = TextEditingController();
      await tester.pumpWidget(
        _app(_kolom(pengendali: p, petunjuk: 'nama@perusahaan.test')),
      );
      double opasitasPetunjuk() => tester
          .widget<AnimatedOpacity>(
            find
                .ancestor(
                  of: find.text('nama@perusahaan.test'),
                  matching: find.byType(AnimatedOpacity),
                )
                .first,
          )
          .opacity;
      expect(opasitasPetunjuk(), 1);
      await tester.enterText(_isian, 'x');
      await tester.pumpAndSettle();
      expect(opasitasPetunjuk(), 0, reason: 'contoh isi hilang saat terisi');
      expect(find.text('Email'), findsOneWidget, reason: 'label tetap');
    });

    testWidgets('tinggi kolom >= 48 (sentuh), bantuan di bawah kolom', (
      tester,
    ) async {
      layarHp(tester, lebar: 392, tinggi: 800);
      expect(UkuranKontrol.kolomCari, 48);
      // Tanpa bantuan: TextField = kolomnya saja.
      await tester.pumpWidget(_app(_kolom(label: 'Buat sandi')));
      expect(
        tester.getSize(_isian).height,
        greaterThanOrEqualTo(UkuranKontrol.kolomCari),
      );
      // Dengan bantuan: teks bantuan di bawah teks isi kolom.
      await tester.pumpWidget(
        _app(_kolom(label: 'Buat sandi', bantuan: 'Minimal 10 karakter')),
      );
      expect(
        tester.getTopLeft(find.text('Minimal 10 karakter')).dy,
        greaterThanOrEqualTo(tester.getRect(_teksKolom).bottom),
      );
    });
  });

  group('galat dekat isian', () {
    testWidgets('galat menggantikan bantuan, tepat di bawah kolom, merah galat '
        'dengan garis kolom merah', (tester) async {
      layarHp(tester, lebar: 392, tinggi: 800);
      await tester.pumpWidget(
        _app(
          _kolom(
            label: 'Kode undangan',
            bantuan: 'Ada di email undangan',
            galat: 'Kode salah atau sudah tidak berlaku.',
          ),
        ),
      );
      expect(find.text('Ada di email undangan'), findsNothing);
      final galat = find.text('Kode salah atau sudah tidak berlaku.');
      expect(galat, findsOneWidget);
      final kolom = tester.getRect(_teksKolom);
      final g = tester.getRect(galat);
      expect(g.top, greaterThanOrEqualTo(kolom.bottom));
      expect(
        g.top - kolom.bottom,
        lessThan(Spasi.xl),
        reason: 'tepat di bawah',
      );
      expect(
        tester.widget<Text>(galat).style!.color,
        TemaSidik.terang.colorScheme.error,
      );
      // Galat dibaca bersama labelnya, tidak di simpul sendiri yang terpisah.
      expect(pelanggaranKontrasTeks(tester, find.byType(KolomIsian)), isEmpty);
    });

    testWidgets('tanpa galat: bantuan kembali', (tester) async {
      await tester.pumpWidget(
        _app(_kolom(bantuan: 'Contoh: nama@perusahaan.test')),
      );
      expect(find.text('Contoh: nama@perusahaan.test'), findsOneWidget);
    });
  });

  group('Semantics', () {
    testWidgets('SATU simpul kolom teks bernama label; label tidak dibaca dua '
        'kali; isi, bantuan, dan galat ikut', (tester) async {
      final semantik = tester.ensureSemantics();
      final p = TextEditingController(text: 'budi@contoh.test');
      await tester.pumpWidget(
        _app(_kolom(pengendali: p, galat: 'Format email tidak benar.')),
      );
      expect(find.bySemanticsLabel(RegExp('^Email')), findsOneWidget);
      final d = tester.getSemantics(find.byType(KolomIsian)).getSemanticsData();
      expect(d.flagsCollection.isTextField, isTrue);
      expect(d.label, contains('Email'));
      expect(d.label, contains('Format email tidak benar.'));
      expect(d.value, 'budi@contoh.test');
      // Kata "Email" hanya sekali di label simpul.
      expect('Email'.allMatches(d.label).length, 1);
      semantik.dispose();
    });

    // A1 (tinjauan R1b): `MergeSemantics` menyerap tombol di ujung kolom ke simpul
    // kolom (kolom jadi tombol + tooltip ganda). Tombol tampil-sandi harus tetap
    // simpul tombol SENDIRI yang bisa diaktifkan, dan kolom tetap bernama label.
    group('ikonAkhir (tombol tampilkan sandi)', () {
      Widget kolomSandi(VoidCallback onTekan, {String? galat}) => KolomIsian(
        label: 'Sandi',
        pengendali: TextEditingController(),
        rahasia: true,
        galat: galat,
        ikonAkhir: IconButton(
          tooltip: 'Tampilkan sandi',
          icon: const Icon(Icons.visibility_outlined),
          onPressed: onTekan,
        ),
      );

      testWidgets('kolom = simpul kolom teks bernama label, BUKAN tombol dan '
          'tanpa tooltip tombol; tombol = simpul tombol sendiri', (
        tester,
      ) async {
        final semantik = tester.ensureSemantics();
        await tester.pumpWidget(_app(kolomSandi(() {})));
        final kolom = tester.getSemantics(_isian).getSemanticsData();
        expect(kolom.flagsCollection.isTextField, isTrue);
        expect(
          kolom.flagsCollection.isButton,
          isFalse,
          reason: 'kolom tidak boleh menyerap tombol',
        );
        expect(kolom.tooltip, isEmpty, reason: 'tooltip milik tombol');
        expect(kolom.label, contains('Sandi'));
        expect(kolom.label, isNot(contains('Tampilkan sandi')));

        final tombol = tester
            .getSemantics(find.byType(IconButton))
            .getSemanticsData();
        expect(tombol.flagsCollection.isButton, isTrue);
        expect(tombol.flagsCollection.isTextField, isFalse);
        expect(tombol.tooltip, 'Tampilkan sandi');
        expect(
          tester.getSemantics(find.byType(IconButton)).id,
          isNot(tester.getSemantics(_isian).id),
          reason: 'dua simpul berbeda',
        );
        semantik.dispose();
      });

      testWidgets('nama tombol hanya sekali di seluruh pohon semantik', (
        tester,
      ) async {
        final semantik = tester.ensureSemantics();
        await tester.pumpWidget(_app(kolomSandi(() {})));
        var jumlah = 0;
        void telusuri(SemanticsNode n) {
          final d = n.getSemanticsData();
          if (d.tooltip == 'Tampilkan sandi' || d.label == 'Tampilkan sandi') {
            jumlah++;
          }
          n.visitChildren((c) {
            telusuri(c);
            return true;
          });
        }

        // Akar pohon semantik: naik dari simpul kolom sampai tak punya induk.
        var akar = tester.getSemantics(_isian);
        while (akar.parent != null) {
          akar = akar.parent!;
        }
        telusuri(akar);
        expect(jumlah, 1, reason: 'tombol terbaca dua kali = simpul ganda');
        semantik.dispose();
      });

      testWidgets('tombol bisa diaktifkan lewat aksi ketuk pembaca layar', (
        tester,
      ) async {
        final semantik = tester.ensureSemantics();
        var ditekan = 0;
        await tester.pumpWidget(_app(kolomSandi(() => ditekan++)));
        // Aksi ketuk seperti yang dikirim TalkBack ke simpul tombol itu sendiri.
        tester.semantics.performAction(
          find.semantics.byPredicate(
            (n) => n.getSemanticsData().tooltip == 'Tampilkan sandi',
          ),
          SemanticsAction.tap,
        );
        await tester.pump();
        expect(ditekan, 1);
        semantik.dispose();
      });

      testWidgets('galat tetap terbaca (simpul kolom atau anaknya) dan label '
          'kolom utuh', (tester) async {
        final semantik = tester.ensureSemantics();
        await tester.pumpWidget(
          _app(kolomSandi(() {}, galat: 'Sandi belum diisi.')),
        );
        expect(find.text('Sandi belum diisi.'), findsOneWidget);
        expect(
          find.bySemanticsLabel(RegExp('Sandi belum diisi')),
          findsWidgets,
        );
        expect(
          tester.getSemantics(_isian).getSemanticsData().label,
          contains('Sandi'),
        );
        semantik.dispose();
      });
    });

    testWidgets(
      'kolom mati: tidak bisa diisi, label diredupkan ke teks kedua',
      (tester) async {
        final semantik = tester.ensureSemantics();
        await tester.pumpWidget(_app(_kolom(aktif: false)));
        expect(tester.widget<TextField>(_isian).enabled, isFalse);
        expect(
          tester.widget<Text>(find.text('Email')).style!.color,
          TemaSidik.terang.colorScheme.onSurfaceVariant,
        );
        expect(
          tester
              .getSemantics(find.byType(KolomIsian))
              .getSemanticsData()
              .flagsCollection
              .isEnabled
              .toBoolOrNull(),
          isFalse,
        );
        semantik.dispose();
      },
    );
  });

  group('huruf besar dan layar sempit', () {
    for (final skala in [1.3, 2.0]) {
      testWidgets('320 dp x $skala: label panjang membungkus utuh, kolom tetap '
          '>= 48, bantuan dan galat tidak terpotong', (tester) async {
        layarHp(tester, lebar: 320, tinggi: 1200);
        const label =
            'Nama lengkap sesuai kartu identitas yang dipakai di perusahaan';
        await tester.pumpWidget(
          _app(
            Padding(
              padding: const EdgeInsets.all(Spasi.sisi),
              child: _kolom(
                label: label,
                bantuan:
                    'Tulis nama panjang seperti di dokumen, jangan '
                    'disingkat, supaya sertifikat memakai nama yang sama.',
              ),
            ),
            skala: skala,
          ),
        );
        expect(tester.takeException(), isNull);
        final paragraf = tester.renderObject<RenderParagraph>(
          find
              .descendant(of: find.text(label), matching: find.byType(RichText))
              .first,
        );
        expect(paragraf.didExceedMaxLines, isFalse);
        expect(
          tester.getSize(_isian).height,
          greaterThanOrEqualTo(UkuranKontrol.kolomCari),
        );
        final kolom = tester.getRect(find.byType(KolomIsian));
        expect(kolom.right, lessThanOrEqualTo(320 - Spasi.sisi + 0.5));
      });
    }

    for (final gelap in [false, true]) {
      testWidgets('kontras label, isi, dan bantuan >= 4,5:1 '
          '(${gelap ? 'gelap' : 'terang'})', (tester) async {
        await tester.pumpWidget(
          _app(_kolom(bantuan: 'Contoh: nama@perusahaan.test'), gelap: gelap),
        );
        expect(
          pelanggaranKontrasTeks(tester, find.byType(KolomIsian)),
          isEmpty,
        );
      });
    }
  });

  group('papan ketik tidak menutupi tombol di bawah kolom', () {
    testWidgets('kolom fokus + tombol utama di bawahnya terlihat di atas papan '
        'ketik 300 dp (ruangTombol)', (tester) async {
      layarHp(tester, lebar: 360, tinggi: 640);
      addTearDown(tester.view.resetViewInsets);
      // Kolom di 260 dp: terlihat sebelum papan ketik muncul; tombol di
      // bawahnya (332..380) baru tertutup papan ketik (badan 340 dp).
      await tester.pumpWidget(
        _app(
          ListView(
            padding: Spasi.halaman,
            children: [
              const SizedBox(height: 260),
              _kolom(label: 'Sandi'),
              const SizedBox(height: Spasi.xl),
              const SizedBox(
                height: UkuranBaris.tombolUtama,
                child: FilledButton(onPressed: null, child: Text('Masuk')),
              ),
              const SizedBox(height: 600),
            ],
          ),
        ),
      );
      await tester.tap(_isian);
      await tester.pump();
      // Papan ketik muncul sesudah kolom fokus.
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      await tester.pumpAndSettle();
      final tombol = tester.getRect(find.text('Masuk'));
      expect(
        tombol.bottom,
        lessThanOrEqualTo(640 - 300),
        reason: 'tombol di atas papan ketik',
      );
      expect(tester.getRect(_isian).top, greaterThanOrEqualTo(0));
      expect(
        KolomIsian.ruangTombol,
        UkuranBaris.tombolUtama + Spasi.xl + Spasi.lg,
      );
    });
  });
}
