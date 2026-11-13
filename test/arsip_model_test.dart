// Model arsip (`GET /sertifikat/garis-waktu`): membaca jawaban server apa
// adanya, menyusun parameter dari `telusuri`, dan merapikan kata cari.
// Tidak ada hitungan tanggal di sisi aplikasi: label, jumlah, dan urutan dari
// server.
import 'package:flutter_test/flutter_test.dart';

import 'package:sidik_pelanggan/models/arsip.dart';
import 'package:sidik_pelanggan/models/data_pelanggan.dart';

import 'dukungan/fixture_arsip.dart';
import 'dukungan/fixture_fitur.dart';

void main() {
  group('HasilArsip.dariJson', () {
    test('tingkat tahun: kelompok, label, jumlah, rentang, telusuri', () {
      final h = HasilArsip.dariJson(arsipTahun());

      expect(h.tingkat, TingkatArsip.tahun);
      expect(h.totalDokumen, 6);
      expect(h.kelompok.map((k) => k.kunci), [
        '2026',
        '2025',
      ], reason: 'urutan');
      final k = h.kelompok.first;
      expect(k.label, '2026');
      expect(k.jumlah, 5);
      expect(k.mulai, '2026-01-01');
      expect(k.selesai, '2026-12-31');
      // Persis dari server, nilai angka menjadi teks query.
      expect(k.telusuri, {'tingkat': 'bulan', 'tahun': '2026'});
      expect(h.item, isEmpty);
    });

    test('label pekan datang dari server, tidak dihitung ulang', () {
      final h = HasilArsip.dariJson(arsipPekanNovember());

      expect(h.tingkat, TingkatArsip.pekan);
      expect(h.kelompok.map((k) => k.label), [
        'Pekan 46 (9–15 Nov 2026)',
        'Pekan 44 (1 Nov 2026)',
      ]);
      // Pekan 44 dipotong server di batas bulan: mulai = selesai = 1 Nov.
      expect(h.kelompok.last.mulai, '2026-11-01');
      expect(h.kelompok.last.selesai, '2026-11-01');
    });

    test('tingkat hari: item = baris sertifikat + nomor_order, dan meta', () {
      final h = HasilArsip.dariJson(
        arsipHari(
          meta: {'current_page': 2, 'last_page': 9, 'per_page': 3, 'total': 25},
        ),
      );

      expect(h.tingkat, TingkatArsip.hari);
      expect(h.item, hasLength(3), reason: 'satu halaman');
      expect(h.halaman, 2);
      expect(h.halamanTerakhir, 9);
      expect(h.total, 25, reason: 'meta.total = seluruh halaman, bukan 3');
      final s = h.item.first;
      expect(s.nomor, 'ISO/CNT/0003');
      expect(s.nomorOrder, 'PO-2026-0042');
      expect(s.serial, 'PL-0001');
      expect(s.namaAlat, 'Busur Derajat');
      // Tanggal kalender polos: tidak bergeser sehari oleh zona waktu.
      expect(s.diterbitkan, DateTime(2026, 11, 12));
      // `nomor_order: null` = tidak ada.
      expect(h.item[1].nomorOrder, isNull);
    });

    test('jawaban kosong atau rusak tidak melempar', () {
      for (final badan in <Map<String, dynamic>>[
        {},
        {'data': null, 'meta': null},
        {'data': <Object>[], 'meta': 'x'},
        {
          'data': {
            'kelompok': 'bukan-daftar',
            'item': [1, 'a', null],
          },
        },
      ]) {
        final h = HasilArsip.dariJson(badan);
        expect(h.kelompok, isEmpty, reason: '$badan');
        expect(h.item, isEmpty, reason: '$badan');
        expect(h.halaman, 1);
        expect(h.halamanTerakhir, 1);
      }
    });

    test('kelompok tanpa label memakai kunci; jumlah teks dibaca angka', () {
      final k = KelompokArsip.dariJson({'kunci': '2024', 'jumlah': '3'});
      expect(k.label, '2024');
      expect(k.jumlah, 3);
      expect(k.telusuri, isEmpty);
    });
  });

  group('Halaman baris (sebagaiHalaman)', () {
    test(
      'tahun/bulan/pekan: satu kartu kelompok per kelompok, tanpa paging',
      () {
        for (final (jawaban, tingkat) in [
          (arsipTahun(), TingkatArsip.tahun),
          (arsipBulan(), TingkatArsip.bulan),
          (arsipPekanNovember(), TingkatArsip.pekan),
        ]) {
          final hal = HasilArsip.dariJson(jawaban).sebagaiHalaman;
          expect(hal.isi, hasLength(2));
          expect(hal.isi.every((b) => b is BarisKelompok), isTrue);
          expect((hal.isi.first as BarisKelompok).tingkat, tingkat);
          expect(hal.adaLagi, isFalse);
          expect(hal.halaman, 1);
        }
      },
    );

    test('total_dokumen dibawa sebagai angka meta', () {
      final hal = HasilArsip.dariJson(arsipTahun()).sebagaiHalaman;
      expect(hal.jumlah, {'total_dokumen': 6});
      final tanpa = HasilArsip.dariJson({
        'data': {'tingkat': 'tahun', 'kelompok': <Object>[]},
      }).sebagaiHalaman;
      expect(tanpa.jumlah, isEmpty, reason: 'tidak ada angka dikarang');
    });

    test('tahun yang menjawab last_page 2 tetap SATU halaman', () {
      // Kelompok tidak dipaginasi server; jangan memuat halaman yang sama lagi.
      final jawaban = arsipTahun();
      (jawaban['meta'] as Map)['last_page'] = 2;
      final hal = HasilArsip.dariJson(jawaban).sebagaiHalaman;
      expect(hal.adaLagi, isFalse);
    });

    test('hari: judul hari disisipkan di tiap pergantian tanggal terbit', () {
      final hal = HasilArsip.dariJson(arsipHari()).sebagaiHalaman;

      expect(hal.isi.map((b) => b.kunci), [
        'h:2026-11-12',
        's:7',
        's:6',
        'h:2026-11-09',
        's:5',
      ]);
      final judul = hal.isi.first as BarisHari;
      expect(judul.kelompok.label, 'Kamis, 12 Nov 2026');
      expect(judul.kelompok.jumlah, 2);
      expect(hal.total, 3, reason: 'total = jumlah sertifikat, bukan baris');
    });

    test('hari: halaman dan paging dari meta dibawa ke daftar', () {
      final hal = HasilArsip.dariJson(
        arsipHari(
          meta: {'current_page': 2, 'last_page': 3, 'per_page': 3, 'total': 25},
        ),
      ).sebagaiHalaman;
      expect(hal.halaman, 2);
      expect(hal.halamanTerakhir, 3);
      expect(hal.total, 25);
      expect(hal.adaLagi, isTrue);
    });

    test('hari: kunci hari dari teks mentah, tidak digeser zona', () {
      // 23.30 di UTC-5 = 13 Nov dini hari di UTC dan di Jakarta: bila kunci
      // dihitung dari DateTime, judul "12 Nov" hilang atau salah hari.
      final h = HasilArsip.dariJson(
        arsipHari(
          item: [
            itemArsipJson(7, 'A', tanggal: '2026-11-12T23:30:00-05:00'),
            itemArsipJson(5, 'B', tanggal: '2026-11-09'),
          ],
        ),
      );
      expect(h.tanggalItem, ['2026-11-12', '2026-11-09']);
      expect(h.sebagaiHalaman.isi.map((b) => b.kunci), [
        'h:2026-11-12',
        's:7',
        'h:2026-11-09',
        's:5',
      ]);
    });

    test(
      'hari: tanggal yang bukan tanggal tidak punya judul, tidak melempar',
      () {
        final h = HasilArsip.dariJson(
          arsipHari(
            item: [
              itemArsipJson(7, 'A', tanggal: 'bukan-tanggal'),
              itemArsipJson(6, 'B', tanggal: '2026-1-5'),
              itemArsipJson(5, 'C', tanggal: ''),
            ],
          ),
        );
        expect(h.tanggalItem, [null, null, null]);
        expect(h.sebagaiHalaman.isi.map((b) => b.kunci), ['s:7', 's:6', 's:5']);
      },
    );

    test('hari: tanggal tanpa kelompok tampil tanpa judul, tidak melempar', () {
      final jawaban = arsipHari(
        item: [itemArsipJson(9, 'ISO/CNT/0009', tanggal: '2026-11-10')],
      );
      final hal = HasilArsip.dariJson(jawaban).sebagaiHalaman;
      expect(hal.isi.map((b) => b.kunci), ['s:9']);
    });

    test('hari: judul yang berlanjut ke halaman 2 punya kunci yang sama', () {
      // Kunci sama = dibuang oleh PaginasiController, jadi hari yang terbelah
      // dua halaman tidak punya dua judul.
      final h1 = HasilArsip.dariJson(
        arsipHari(item: [itemArsipJson(7, 'A', tanggal: '2026-11-12')]),
      ).sebagaiHalaman;
      final h2 = HasilArsip.dariJson(
        arsipHari(item: [itemArsipJson(6, 'B', tanggal: '2026-11-12')]),
      ).sebagaiHalaman;
      expect(h1.isi.first.kunci, h2.isi.first.kunci);
      expect(h1.isi.first, isA<BarisHari>());
    });
  });

  group('ParameterArsip', () {
    test('akar: tanpa parameter penelusuran, hanya halaman', () {
      expect(ParameterArsip.akar.adalahAkar, isTrue);
      expect(ParameterArsip.akar.tingkat, TingkatArsip.tahun);
      expect(ParameterArsip.akar.query(), {'page': '1'});
    });

    test('parameter turunan = telusuri server APA ADANYA + page', () {
      final h = HasilArsip.dariJson(arsipPekanNovember());
      final p = h.kelompok.first.parameter;

      expect(p.adalahAkar, isFalse);
      expect(p.tingkat, TingkatArsip.hari);
      expect(p.query(halaman: 3), {
        'tingkat': 'hari',
        'tahun': '2026',
        'bulan': '11',
        'pekan': '46',
        'page': '3',
      });
    });

    test('tanggal tingkat hari ikut bila server mengirimnya', () {
      final h = HasilArsip.dariJson(arsipHari());
      final p = h.kelompok.first.parameter;
      expect(p.query()['tanggal'], '2026-11-12');
    });

    test(
      'kesamaan: kunci provider sama persis = sama, urutan kunci tak berarti',
      () {
        final a = KelompokArsip.dariJson({
          'kunci': 'x',
          'telusuri': {'tingkat': 'bulan', 'tahun': 2026},
        });
        final b = KelompokArsip.dariJson({
          'kunci': 'x',
          'telusuri': {'tahun': 2026, 'tingkat': 'bulan'},
        });
        final lain = KelompokArsip.dariJson({
          'kunci': 'x',
          'telusuri': {'tingkat': 'bulan', 'tahun': 2025},
        });
        expect(a.parameter, b.parameter);
        expect(a.parameter.hashCode, b.parameter.hashCode);
        expect(a.parameter, isNot(lain.parameter));
        expect(a.parameter, isNot(ParameterArsip.akar));
      },
    );
  });

  group('KataCari', () {
    test('dipangkas, minimal 2 karakter, maksimal 100', () {
      expect(KataCari.rapikan(''), '');
      expect(KataCari.rapikan('   '), '');
      expect(KataCari.rapikan('a'), '', reason: '1 huruf tidak dikirim');
      expect(KataCari.rapikan(' a '), '');
      expect(KataCari.rapikan('ab'), 'ab');
      expect(KataCari.rapikan('  sn-0204  '), 'sn-0204');
      expect(KataCari.rapikan('a' * 100), 'a' * 100);
      expect(KataCari.rapikan('a' * 101), 'a' * 100);
    });

    test('dikirim APA ADANYA: / - spasi dan huruf tidak diubah', () {
      for (final kata in [
        'CAL/2026/10/0001',
        'cal-2026-10-0001',
        'cal 2026 10 0001',
        'Sn-0204',
      ]) {
        expect(KataCari.rapikan(kata), kata);
      }
    });

    test('batas 2 dan 100 adalah angka kontrak', () {
      expect(KataCari.minimal, 2);
      expect(KataCari.maksimal, 100);
    });
  });

  group('Sertifikat.nomorOrder', () {
    test('baris arsip membawa nomor order; null atau kosong = tidak ada', () {
      final h = HasilArsip.dariJson(arsipHari());
      expect(h.item.map((s) => s.nomorOrder), [
        'PO-2026-0042',
        null,
        'PO-2026-0042',
      ]);
      final kosong = Sertifikat.dariJson(
        itemArsipJson(1, 'X/1', nomorOrder: '  '),
      );
      expect(kosong.nomorOrder, isNull);
    });

    test('baris GET /sertifikat biasa tidak punya nomor order', () {
      final s = Sertifikat.dariJson(sertifikatJson(1, 'CAL/1'));
      expect(s.nomorOrder, isNull);
    });
  });
}
