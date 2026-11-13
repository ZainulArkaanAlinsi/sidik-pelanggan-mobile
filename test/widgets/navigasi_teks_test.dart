// SaringanTeks, KolomCariUtuh, Bagian, TautanBaris, KeadaanTeks, dan
// BannerDataTerakhir: saringan yang tidak terpotong, placeholder cari yang utuh,
// judul bagian, tautan 48 dp, dan keadaan kosong/galat sebagai teks. Terang/
// gelap, 320 dp x huruf 1,3, tablet, sasaran sentuh >= 48 dp, label baca.
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sidik_pelanggan/core/tema/bentuk.dart';
import 'package:sidik_pelanggan/core/tema/tema_sidik.dart';
import 'package:sidik_pelanggan/core/tema/ukuran.dart';
import 'package:sidik_pelanggan/widgets/bagian.dart';
import 'package:sidik_pelanggan/widgets/keadaan_teks.dart';
import 'package:sidik_pelanggan/widgets/kolom_cari_utuh.dart';
import 'package:sidik_pelanggan/widgets/saringan_teks.dart';
import 'package:sidik_pelanggan/widgets/tautan_baris.dart';

import '../dukungan/fixture_fitur.dart';
import '../dukungan/layar_uji.dart';
import '../dukungan/ukur_komponen.dart';

ThemeData _tema(bool gelap) => gelap ? TemaSidik.gelap : TemaSidik.terang;

const _pilihan = [
  PilihanSaringan('Semua', jumlah: 9),
  PilihanSaringan('Lewat jadwal', jumlah: 1),
  PilihanSaringan('Dalam 30 hari', jumlah: 1),
  PilihanSaringan('31 sampai 60 hari', jumlah: 2),
  PilihanSaringan('61 sampai 90 hari', jumlah: 2),
];

/// Kotak berwarna garis bawah terpilih (kobalt) pada satu pilihan.
Finder _garisBawahTerpilih(Color primary) => find.descendant(
  of: find.byType(SaringanTeks),
  matching: find.byWidgetPredicate((w) {
    if (w is! DecoratedBox || w.decoration is! BoxDecoration) return false;
    final b = (w.decoration as BoxDecoration).border;
    return b is Border &&
        b.bottom.color == primary &&
        b.bottom.width == UkuranTik.garisBawah;
  }),
);

bool _adaLanjut(WidgetTester tester) =>
    (tester.state(find.byType(SaringanTeks)) as dynamic).adaLanjut as bool;

void main() {
  setUpAll(siapkanTesFitur);

  group('SaringanTeks', () {
    testWidgets(
      'kata + jumlah; terpilih tebal 700 dengan garis bawah kobalt 3 dp',
      (tester) async {
        final s = TemaSidik.terang.colorScheme;
        layarHp(tester, lebar: 392, tinggi: 640);
        await tester.pumpWidget(
          aplikasiUji(
            const SaringanTeks(pilihan: _pilihan, terpilih: 1),
            bergulir: false,
          ),
        );
        expect(
          find.textContaining('Semua', findRichText: true),
          findsOneWidget,
        );
        expect(find.text('Semua  9', findRichText: true), findsOneWidget);
        // Tepat satu garis bawah kobalt, di pilihan terpilih.
        expect(_garisBawahTerpilih(s.primary), findsOneWidget);
        final terpilih = ukurTeks(
          tester,
          find.byType(SaringanTeks),
        ).firstWhere((x) => x.teks == 'Lewat jadwal');
        final lain = ukurTeks(
          tester,
          find.byType(SaringanTeks),
        ).firstWhere((x) => x.teks == 'Semua');
        expect(terpilih.warna, s.onSurface);
        expect(lain.warna, s.onSurfaceVariant);
        final gayaTerpilih = tester
            .widget<RichText>(
              find.textContaining('Lewat jadwal', findRichText: true),
            )
            .text
            .style!;
        expect(gayaTerpilih.fontWeight, FontWeight.w700);
        final gayaLain = tester
            .widget<RichText>(find.textContaining('Semua', findRichText: true))
            .text
            .style!;
        expect(gayaLain.fontWeight, FontWeight.w500);
      },
    );

    testWidgets('mengetuk pilihan meneruskan indeksnya', (tester) async {
      layarHp(tester, lebar: 392, tinggi: 640);
      final dipilih = <int>[];
      await tester.pumpWidget(
        aplikasiUji(
          SaringanTeks(pilihan: _pilihan, terpilih: 0, onPilih: dipilih.add),
          bergulir: false,
        ),
      );
      await tester.tap(find.textContaining('Lewat jadwal', findRichText: true));
      await tester.tap(find.textContaining('Semua', findRichText: true));
      expect(dipilih, [1, 0]);
    });

    testWidgets(
      'label baca: kata + jumlah, terpilih (selected), bisa diaktifkan',
      (tester) async {
        final semantik = tester.ensureSemantics();
        layarHp(tester, lebar: 392, tinggi: 640);
        final dipilih = <int>[];
        await tester.pumpWidget(
          aplikasiUji(
            SaringanTeks(pilihan: _pilihan, terpilih: 1, onPilih: dipilih.add),
            bergulir: false,
          ),
        );
        expect(
          tester.getSemantics(find.bySemanticsLabel('Lewat jadwal, 1')),
          matchesSemantics(
            label: 'Lewat jadwal, 1',
            isButton: true,
            isSelected: true,
            hasSelectedState: true,
            hasTapAction: true,
          ),
        );
        expect(
          tester.getSemantics(find.bySemanticsLabel('Semua, 9')),
          matchesSemantics(
            label: 'Semua, 9',
            isButton: true,
            hasSelectedState: true,
            hasTapAction: true,
          ),
        );
        tester.semantics.tap(find.semantics.byLabel('Dalam 30 hari, 1'));
        expect(dipilih, [2]);
        semantik.dispose();
      },
    );

    testWidgets(
      'tanpa onPilih: bukan tombol (tanpa aksi), tetap terbaca terpilih',
      (tester) async {
        final semantik = tester.ensureSemantics();
        layarHp(tester, lebar: 392, tinggi: 640);
        await tester.pumpWidget(
          aplikasiUji(
            const SaringanTeks(pilihan: _pilihan, terpilih: 1),
            bergulir: false,
          ),
        );
        expect(
          tester.getSemantics(find.bySemanticsLabel('Lewat jadwal, 1')),
          matchesSemantics(
            label: 'Lewat jadwal, 1',
            isSelected: true,
            hasSelectedState: true,
          ),
        );
        semantik.dispose();
      },
    );

    testWidgets('tanpa jumlah: label baca hanya kata', (tester) async {
      final semantik = tester.ensureSemantics();
      await tester.pumpWidget(
        aplikasiUji(
          const SaringanTeks(
            pilihan: [PilihanSaringan('Daftar'), PilihanSaringan('Arsip')],
            terpilih: 0,
          ),
          bergulir: false,
        ),
      );
      expect(find.bySemanticsLabel('Daftar'), findsOneWidget);
      expect(find.bySemanticsLabel('Arsip'), findsOneWidget);
      semantik.dispose();
    });

    for (final (nama, lebar, skala) in [
      ('HP 392', 392.0, 1.0),
      ('320 dp x huruf 1,3', 320.0, 1.3),
    ]) {
      for (final gelap in [false, true]) {
        testWidgets('$nama: tiap pilihan utuh satu baris, >= 48 dp, pedoman '
            'sentuh+label, kontras (${gelap ? 'gelap' : 'terang'})', (
          tester,
        ) async {
          layarHp(tester, lebar: lebar, tinggi: 640);
          final semantik = tester.ensureSemantics();
          await tester.pumpWidget(
            aplikasiUji(
              const SaringanTeks(pilihan: _pilihan, terpilih: 0),
              gelap: gelap,
              skala: skala,
              bergulir: false,
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          // Tiap kata tampil UTUH: satu baris, tanpa elipsis.
          for (final rt
              in find
                  .descendant(
                    of: find.byType(SaringanTeks),
                    matching: find.byType(RichText),
                  )
                  .evaluate()) {
            final p = tester.renderObject<RenderParagraph>(
              find.byWidget(rt.widget),
            );
            expect(p.didExceedMaxLines, isFalse, reason: p.text.toPlainText());
            expect(barisTeks(p).length, 1, reason: p.text.toPlainText());
          }
          for (final ink
              in find
                  .descendant(
                    of: find.byType(SaringanTeks),
                    matching: find.byType(InkWell),
                  )
                  .evaluate()) {
            final u = tester.getSize(find.byWidget(ink.widget));
            expect(u.height, greaterThanOrEqualTo(48));
            expect(u.width, greaterThanOrEqualTo(48));
          }
          await periksaPedomanSentuh(tester);
          expect(
            pelanggaranKontrasTeks(tester, find.byType(SaringanTeks)),
            isEmpty,
          );
          semantik.dispose();
        });
      }
    }

    testWidgets(
      'bilah setinggi 52 dp pada huruf biasa dan tumbuh bersama huruf',
      (tester) async {
        layarHp(tester, lebar: 392, tinggi: 640);
        await tester.pumpWidget(
          aplikasiUji(
            const SaringanTeks(pilihan: _pilihan, terpilih: 0),
            bergulir: false,
          ),
        );
        expect(
          tester.getSize(find.byType(SaringanTeks)).height,
          greaterThanOrEqualTo(AreaSentuh.minimum + 4),
        );
        await tester.pumpWidget(
          aplikasiUji(
            const SaringanTeks(pilihan: _pilihan, terpilih: 0),
            bergulir: false,
            skala: 1.3,
          ),
        );
        expect(
          tester.getSize(find.byType(SaringanTeks)).height,
          greaterThan(AreaSentuh.minimum + 4),
        );
      },
    );

    testWidgets(
      'melebihi lebar: bisa digeser dan tepi kanan memudar; semua muat: '
      'tanpa pemudaran (tablet)',
      (tester) async {
        layarHp(tester, lebar: 320, tinggi: 640);
        await tester.pumpWidget(
          aplikasiUji(
            const SaringanTeks(pilihan: _pilihan, terpilih: 0),
            bergulir: false,
            skala: 1.3,
          ),
        );
        await tester.pumpAndSettle();
        expect(_adaLanjut(tester), isTrue);
        final gulir = tester.state<ScrollableState>(find.byType(Scrollable));
        expect(gulir.position.maxScrollExtent, greaterThan(0));

        // Menggeser sampai ujung: pemudaran hilang.
        await tester.drag(find.byType(Scrollable), const Offset(-2000, 0));
        await tester.pumpAndSettle();
        expect(_adaLanjut(tester), isFalse);

        layarTablet(tester);
        await tester.pumpWidget(
          aplikasiUji(
            const SaringanTeks(pilihan: _pilihan, terpilih: 0),
            bergulir: false,
          ),
        );
        await tester.pumpAndSettle();
        expect(_adaLanjut(tester), isFalse);
        expect(
          tester
              .state<ScrollableState>(find.byType(Scrollable))
              .position
              .maxScrollExtent,
          0,
        );
      },
    );

    testWidgets('pilihan terpilih yang di luar layar digulirkan ke dalam', (
      tester,
    ) async {
      layarHp(tester, lebar: 320, tinggi: 640);
      await tester.pumpWidget(
        aplikasiUji(
          const SaringanTeks(pilihan: _pilihan, terpilih: 4),
          bergulir: false,
          skala: 1.3,
        ),
      );
      await tester.pumpAndSettle();
      final r = tester.getRect(
        find.textContaining('61 sampai 90 hari', findRichText: true),
      );
      expect(r.left, greaterThanOrEqualTo(0));
      expect(r.right, lessThanOrEqualTo(320));
    });

    testWidgets('gulir seminimal mungkin: yang sudah terlihat tidak digeser; '
        'yang digulirkan memudarkan tepi kiri', (tester) async {
      layarHp(tester, lebar: 392, tinggi: 640);
      Widget bangun(int terpilih, double skala) => aplikasiUji(
        SaringanTeks(pilihan: _pilihan, terpilih: terpilih),
        bergulir: false,
        skala: skala,
      );
      await tester.pumpWidget(bangun(1, 1.0));
      await tester.pumpAndSettle();
      final tanpaGulir = tester
          .state<ScrollableState>(find.byType(Scrollable))
          .position
          .pixels;
      expect(tanpaGulir, 0);
      expect(
        (tester.state(find.byType(SaringanTeks)) as dynamic).adaSebelum,
        isFalse,
      );

      layarHp(tester, lebar: 320, tinggi: 640);
      await tester.pumpWidget(bangun(3, 1.3));
      await tester.pumpAndSettle();
      expect(
        tester.state<ScrollableState>(find.byType(Scrollable)).position.pixels,
        greaterThan(0),
      );
      final state = tester.state(find.byType(SaringanTeks)) as dynamic;
      expect(state.adaSebelum, isTrue);
      expect(state.adaLanjut, isTrue);
    });

    testWidgets('mengganti pilihan menggulirkan pilihan baru ke dalam layar', (
      tester,
    ) async {
      layarHp(tester, lebar: 320, tinggi: 640);
      Widget bangun(int terpilih) => aplikasiUji(
        SaringanTeks(pilihan: _pilihan, terpilih: terpilih),
        bergulir: false,
        skala: 1.3,
      );
      await tester.pumpWidget(bangun(0));
      await tester.pumpAndSettle();
      await tester.pumpWidget(bangun(3));
      await tester.pumpAndSettle();
      final r = tester.getRect(
        find.textContaining('31 sampai 60 hari', findRichText: true),
      );
      expect(r.left, greaterThanOrEqualTo(0));
      expect(r.right, lessThanOrEqualTo(320));
    });

    testWidgets('posisi gulir pengguna tidak hilang saat dibangun ulang', (
      tester,
    ) async {
      layarHp(tester, lebar: 320, tinggi: 640);
      Widget bangun() => aplikasiUji(
        const SaringanTeks(pilihan: _pilihan, terpilih: 0),
        bergulir: false,
        skala: 1.3,
      );
      await tester.pumpWidget(bangun());
      await tester.pumpAndSettle();
      await tester.drag(find.byType(Scrollable), const Offset(-120, 0));
      await tester.pumpAndSettle();
      final sebelum = tester
          .state<ScrollableState>(find.byType(Scrollable))
          .position
          .pixels;
      expect(sebelum, greaterThan(0));
      await tester.pumpWidget(bangun());
      await tester.pumpAndSettle();
      expect(
        tester.state<ScrollableState>(find.byType(Scrollable)).position.pixels,
        sebelum,
      );
    });

    testWidgets('daftar kosong dan satu pilihan tidak merusak', (tester) async {
      await tester.pumpWidget(
        aplikasiUji(
          const SaringanTeks(pilihan: [], terpilih: 0),
          bergulir: false,
        ),
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(
        aplikasiUji(
          const SaringanTeks(pilihan: [PilihanSaringan('Semua')], terpilih: 0),
          bergulir: false,
        ),
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('KolomCariUtuh', () {
    const petunjuk = 'Cari nama, merk, atau nomor seri';

    testWidgets('onCari sekali per kata, 350 ms setelah ketikan, dipangkas', (
      tester,
    ) async {
      final kata = <String>[];
      await tester.pumpWidget(
        aplikasiUji(KolomCariUtuh(petunjuk: petunjuk, onCari: kata.add)),
      );
      await tester.enterText(find.byType(TextField), '  jangka ');
      await tester.pump(const Duration(milliseconds: 349));
      expect(kata, isEmpty);
      await tester.enterText(find.byType(TextField), '  jangka sorong ');
      await tester.pump(const Duration(milliseconds: 349));
      expect(kata, isEmpty, reason: 'ketikan baru memulai ulang jeda');
      await tester.pump(const Duration(milliseconds: 2));
      expect(kata, ['jangka sorong']);
    });

    for (final (nama, lebar, skala) in [
      ('HP 392', 392.0, 1.0),
      ('320 dp x huruf 1,3', 320.0, 1.3),
    ]) {
      testWidgets('$nama: petunjuk UTUH (tidak dipotong), tinggi >= 48 dp', (
        tester,
      ) async {
        layarHp(tester, lebar: lebar, tinggi: 640);
        // Tanpa SingleChildScrollView pembungkus: komponen sudah membawa margin
        // halamannya sendiri (20 dp), seperti di layar sungguhan.
        await tester.pumpWidget(
          aplikasiUji(
            KolomCariUtuh(petunjuk: petunjuk, onCari: (_) {}),
            skala: skala,
            bergulir: false,
          ),
        );
        expect(tester.takeException(), isNull);
        final hint = tester.renderObject<RenderParagraph>(find.text(petunjuk));
        expect(hint.didExceedMaxLines, isFalse, reason: 'petunjuk terpotong');
        expect(barisTeks(hint).join(), petunjuk);
        expect(
          tester.getSize(find.byType(TextField)).height,
          greaterThanOrEqualTo(48),
        );
      });
    }

    testWidgets(
      'SATU node text-field berlabel petunjuk (tanpa pembungkus ganda)',
      (tester) async {
        final semantik = tester.ensureSemantics();
        await tester.pumpWidget(
          aplikasiUji(
            KolomCariUtuh(petunjuk: petunjuk, onCari: (_) {}),
            bergulir: false,
          ),
        );
        final node = nodeTextField(tester);
        expect(
          node.length,
          1,
          reason: 'dua node text-field = TalkBack fokus dua kali',
        );
        expect(node.single.label, contains(petunjuk));
        semantik.dispose();
      },
    );

    testWidgets('petunjuk sangat panjang membungkus paling banyak dua baris', (
      tester,
    ) async {
      layarHp(tester, lebar: 320, tinggi: 640);
      const panjang =
          'Cari menurut nama alat, merk, model, nomor seri, atau nomor '
          'identifikasi alat milik perusahaan Anda';
      await tester.pumpWidget(
        aplikasiUji(
          KolomCariUtuh(petunjuk: panjang, onCari: (_) {}),
          skala: 1.3,
          bergulir: false,
        ),
      );
      expect(tester.takeException(), isNull);
      final hint = tester.renderObject<RenderParagraph>(find.text(panjang));
      expect(
        barisTeks(hint).length,
        lessThanOrEqualTo(KolomCariUtuh.petunjukBaris),
      );
    });

    for (final gelap in [false, true]) {
      testWidgets('label baca, pedoman sentuh, kontras petunjuk '
          '(${gelap ? 'gelap' : 'terang'})', (tester) async {
        final semantik = tester.ensureSemantics();
        layarHp(tester, lebar: 392, tinggi: 640);
        await tester.pumpWidget(
          aplikasiUji(
            KolomCariUtuh(petunjuk: petunjuk, onCari: (_) {}),
            gelap: gelap,
          ),
        );
        expect(find.bySemanticsLabel(petunjuk), findsWidgets);
        await periksaPedomanSentuh(tester);
        final t = _tema(gelap);
        final hintGaya = t.inputDecorationTheme.hintStyle!;
        expect(
          rasioKontras(hintGaya.color!, t.inputDecorationTheme.fillColor!),
          greaterThanOrEqualTo(4.5),
        );
        semantik.dispose();
        await tester.pumpWidget(const SizedBox());
      });
    }
  });

  group('Bagian', () {
    testWidgets(
      'judul + jumlah redup + tautan teks; jarak 32 atas dan 12 bawah',
      (tester) async {
        var dibuka = 0;
        await tester.pumpWidget(
          aplikasiUji(
            Bagian(
              'Sedang dikerjakan di lab',
              jumlah: 3,
              aksi: 'Lihat semua',
              onAksi: () => dibuka++,
            ),
          ),
        );
        expect(
          find.textContaining('Sedang dikerjakan di lab', findRichText: true),
          findsOneWidget,
        );
        expect(find.textContaining('3', findRichText: true), findsOneWidget);
        await tester.tap(find.text('Lihat semua'));
        expect(dibuka, 1);
        final kotak = tester.getRect(find.byType(Bagian));
        final judul = tester.getRect(
          find.textContaining('Sedang dikerjakan di lab', findRichText: true),
        );
        expect(judul.top - kotak.top, greaterThanOrEqualTo(32));
        expect(kotak.bottom - judul.bottom, greaterThanOrEqualTo(12));
      },
    );

    testWidgets('tanpaJarakAtas menghapus jarak 32', (tester) async {
      await tester.pumpWidget(
        aplikasiUji(const Bagian('Alat', tanpaJarakAtas: true)),
      );
      final kotak = tester.getRect(find.byType(Bagian));
      final judul = tester.getRect(find.text('Alat', findRichText: true));
      expect(judul.top - kotak.top, lessThan(32));
    });

    testWidgets(
      'judul adalah header untuk pembaca layar; aksi berlabel penuh',
      (tester) async {
        final semantik = tester.ensureSemantics();
        await tester.pumpWidget(
          aplikasiUji(
            Bagian(
              'Sertifikat terbaru',
              aksi: 'Lihat semua',
              onAksi: () {},
              semantikAksi: 'Lihat semua sertifikat',
            ),
          ),
        );
        expect(
          tester.getSemantics(find.bySemanticsLabel('Sertifikat terbaru')),
          matchesSemantics(label: 'Sertifikat terbaru', isHeader: true),
        );
        expect(find.bySemanticsLabel('Lihat semua sertifikat'), findsOneWidget);
        semantik.dispose();
      },
    );

    for (final (nama, lebar, skala) in [
      ('HP 392', 392.0, 1.0),
      ('320 dp x huruf 1,3', 320.0, 1.3),
    ]) {
      for (final gelap in [false, true]) {
        testWidgets('$nama: judul panjang membungkus, tautan >= 48 dp, pedoman '
            'sentuh+label, kontras (${gelap ? 'gelap' : 'terang'})', (
          tester,
        ) async {
          layarHp(tester, lebar: lebar, tinggi: 640);
          final semantik = tester.ensureSemantics();
          await tester.pumpWidget(
            aplikasiUji(
              Bagian(
                'Sedang dikerjakan di laboratorium kalibrasi',
                jumlah: 12,
                aksi: 'Lihat semua',
                onAksi: () {},
              ),
              gelap: gelap,
              skala: skala,
            ),
          );
          expect(tester.takeException(), isNull);
          expect(
            tester.getSize(find.byType(TextButton)).height,
            greaterThanOrEqualTo(48),
          );
          await periksaPedomanSentuh(tester);
          expect(pelanggaranKontrasTeks(tester, find.byType(Bagian)), isEmpty);
          semantik.dispose();
        });
      }
    }
  });

  group('TautanBaris', () {
    testWidgets('sentuh >= 48 dp, panah, label baca, bisa diaktifkan', (
      tester,
    ) async {
      final semantik = tester.ensureSemantics();
      var dibuka = 0;
      await tester.pumpWidget(
        aplikasiUji(TautanBaris('Lihat semua alat (9)', onTap: () => dibuka++)),
      );
      expect(
        tester.getSize(find.byType(TautanBaris)).height,
        greaterThanOrEqualTo(48),
      );
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
      await tester.tap(find.text('Lihat semua alat (9)'));
      expect(dibuka, 1);
      tester.semantics.tap(find.semantics.byLabel('Lihat semua alat (9)'));
      expect(dibuka, 2);
      expect(
        tester.getSemantics(find.bySemanticsLabel('Lihat semua alat (9)')),
        matchesSemantics(
          label: 'Lihat semua alat (9)',
          isButton: true,
          hasEnabledState: true,
          isEnabled: true,
          hasTapAction: true,
        ),
      );
      semantik.dispose();
    });

    testWidgets('tanpa onTap: tampil mati, bukan tautan palsu', (tester) async {
      final semantik = tester.ensureSemantics();
      await tester.pumpWidget(aplikasiUji(const TautanBaris('Lihat semua')));
      expect(
        tester.getSemantics(find.bySemanticsLabel('Lihat semua')),
        matchesSemantics(
          label: 'Lihat semua',
          isButton: true,
          hasEnabledState: true,
        ),
      );
      semantik.dispose();
    });

    testWidgets('label baca khusus menggantikan tulisan pendek', (
      tester,
    ) async {
      final semantik = tester.ensureSemantics();
      await tester.pumpWidget(
        aplikasiUji(
          TautanBaris(
            'Lihat semua',
            onTap: () {},
            semantik: 'Lihat semua alat Anda',
          ),
        ),
      );
      expect(find.bySemanticsLabel('Lihat semua alat Anda'), findsOneWidget);
      semantik.dispose();
    });

    for (final (nama, lebar, skala) in [
      ('HP 392', 392.0, 1.0),
      ('320 dp x huruf 1,3', 320.0, 1.3),
      ('tablet', 840.0, 1.0),
    ]) {
      for (final gelap in [false, true]) {
        testWidgets('$nama: teks panjang membungkus, tanpa luapan, pedoman '
            'sentuh+label, kontras (${gelap ? 'gelap' : 'terang'})', (
          tester,
        ) async {
          layarHp(tester, lebar: lebar, tinggi: lebar > 600 ? 1200 : 640);
          final semantik = tester.ensureSemantics();
          await tester.pumpWidget(
            aplikasiUji(
              TautanBaris(
                'Lihat semua alat yang lewat jadwal dan segera jatuh tempo (128)',
                onTap: () {},
              ),
              gelap: gelap,
              skala: skala,
            ),
          );
          expect(tester.takeException(), isNull);
          expect(
            tester.getSize(find.byType(TautanBaris)).height,
            greaterThanOrEqualTo(48),
          );
          await periksaPedomanSentuh(tester);
          expect(
            pelanggaranKontrasTeks(tester, find.byType(TautanBaris)),
            isEmpty,
          );
          semantik.dispose();
        });
      }
    }
  });

  group('KeadaanTeks', () {
    testWidgets('judul, satu kalimat, satu tindakan; rata kiri; tanpa ikon', (
      tester,
    ) async {
      var ditekan = 0;
      await tester.pumpWidget(
        aplikasiUji(
          KeadaanTeks(
            judul: 'Tidak ada alat yang cocok',
            isi: 'Coba kata lain, atau tampilkan semua alat Anda.',
            aksi: 'Tampilkan semua alat',
            onAksi: () => ditekan++,
          ),
        ),
      );
      expect(find.text('Tidak ada alat yang cocok'), findsOneWidget);
      expect(
        find.text('Coba kata lain, atau tampilkan semua alat Anda.'),
        findsOneWidget,
      );
      expect(find.byType(Icon), findsNothing);
      expect(find.byType(Image), findsNothing);
      await tester.tap(find.text('Tampilkan semua alat'));
      expect(ditekan, 1);
      // Rata kiri: judul dan isi mulai di tepi kiri yang sama.
      final judul = tester.getRect(find.text('Tidak ada alat yang cocok'));
      final isi = tester.getRect(
        find.text('Coba kata lain, atau tampilkan semua alat Anda.'),
      );
      final tombol = tester.getRect(find.byType(OutlinedButton));
      expect(isi.left, judul.left);
      expect(tombol.left, judul.left);
      expect(
        tester.widget<Text>(find.text('Tidak ada alat yang cocok')).textAlign,
        isNull,
      );
    });

    testWidgets('aksi sekunder 48 dp; utama 56 dp; tanpa aksi: tanpa tombol', (
      tester,
    ) async {
      await tester.pumpWidget(
        aplikasiUji(
          KeadaanTeks(judul: 'J', isi: 'I', aksi: 'Aksi', onAksi: () {}),
        ),
      );
      expect(
        tester.getSize(find.byType(OutlinedButton)).height,
        greaterThanOrEqualTo(48),
      );
      expect(find.byType(FilledButton), findsNothing);
      await tester.pumpWidget(
        aplikasiUji(
          KeadaanTeks(
            judul: 'J',
            isi: 'I',
            aksi: 'Coba lagi',
            onAksi: () {},
            utama: true,
          ),
        ),
      );
      expect(
        tester.getSize(find.byType(FilledButton)).height,
        UkuranBaris.tombolUtama,
      );
      await tester.pumpWidget(
        aplikasiUji(const KeadaanTeks(judul: 'J', isi: 'I')),
      );
      expect(find.byType(OutlinedButton), findsNothing);
      expect(find.byType(FilledButton), findsNothing);
    });

    testWidgets('judul adalah header untuk pembaca layar', (tester) async {
      final semantik = tester.ensureSemantics();
      await tester.pumpWidget(
        aplikasiUji(
          const KeadaanTeks(
            judul: 'Beranda belum bisa dimuat',
            isi: 'Coba lagi nanti.',
          ),
        ),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('Beranda belum bisa dimuat')),
        matchesSemantics(label: 'Beranda belum bisa dimuat', isHeader: true),
      );
      semantik.dispose();
    });

    for (final (nama, lebar, skala) in [
      ('HP 392', 392.0, 1.0),
      ('320 dp x huruf 1,3', 320.0, 1.3),
      ('tablet', 840.0, 1.0),
    ]) {
      for (final gelap in [false, true]) {
        testWidgets('$nama: teks panjang, pedoman sentuh+label, kontras, tanpa '
            'luapan (${gelap ? 'gelap' : 'terang'})', (tester) async {
          layarHp(tester, lebar: lebar, tinggi: lebar > 600 ? 1200 : 800);
          final semantik = tester.ensureSemantics();
          await tester.pumpWidget(
            aplikasiUji(
              KeadaanTeks(
                judul: 'Daftar alat belum bisa dimuat dari server laboratorium',
                isi:
                    'Sambungan terputus sebelum data selesai diterima. Periksa '
                    'jaringan Anda, lalu coba lagi beberapa saat.',
                aksi: 'Coba lagi sekarang juga',
                onAksi: () {},
                utama: true,
              ),
              gelap: gelap,
              skala: skala,
            ),
          );
          expect(tester.takeException(), isNull);
          await periksaPedomanSentuh(tester);
          expect(
            pelanggaranKontrasTeks(tester, find.byType(KeadaanTeks)),
            isEmpty,
          );
          semantik.dispose();
        });
      }
    }
  });

  group('BannerDataTerakhir', () {
    const teks =
        'Tidak ada sambungan. Yang tampil adalah data terakhir, 12 Nov 2026 '
        '08.12.';

    testWidgets('latar tinggi, ikon awan, sudut 4, label baca = teks', (
      tester,
    ) async {
      final semantik = tester.ensureSemantics();
      final s = TemaSidik.terang.colorScheme;
      await tester.pumpWidget(
        aplikasiUji(const BannerDataTerakhir(teks: teks)),
      );
      expect(find.text(teks), findsOneWidget);
      expect(find.byIcon(Icons.cloud_off_outlined), findsOneWidget);
      final d =
          tester
                  .widget<DecoratedBox>(
                    find.descendant(
                      of: find.byType(BannerDataTerakhir),
                      matching: find.byType(DecoratedBox),
                    ),
                  )
                  .decoration
              as BoxDecoration;
      expect(d.color, s.surfaceContainerHigh);
      expect(d.borderRadius, Bentuk.sudutKecil);
      expect(find.bySemanticsLabel(teks), findsOneWidget);
      semantik.dispose();
    });

    for (final gelap in [false, true]) {
      testWidgets(
        'kontras dan 320 dp x huruf 1,3 (${gelap ? 'gelap' : 'terang'})',
        (tester) async {
          layarHp(tester, lebar: 320, tinggi: 640);
          final t = _tema(gelap);
          await tester.pumpWidget(
            aplikasiUji(
              const BannerDataTerakhir(teks: teks),
              gelap: gelap,
              skala: 1.3,
            ),
          );
          expect(tester.takeException(), isNull);
          expect(
            pelanggaranKontrasTeks(tester, find.byType(BannerDataTerakhir)),
            isEmpty,
          );
          final ikon = tester.widget<Icon>(
            find.byIcon(Icons.cloud_off_outlined),
          );
          expect(
            rasioKontras(ikon.color!, t.colorScheme.surfaceContainerHigh),
            greaterThanOrEqualTo(3),
          );
        },
      );
    }
  });
}
