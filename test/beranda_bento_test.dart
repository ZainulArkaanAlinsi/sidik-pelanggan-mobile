// Beranda Bento Lab (P5a): logika klaim, kapsul jatuh tempo, ubin, kepala,
// empat keadaan (memuat, kosong, galat, tanpa koneksi), kurangi gerak, skala
// huruf 1,3 di 320 dp, semantik, target sentuh, dan kontras di dua tema.
//
// Tes keadaan memeriksa HASIL (teks, jenis ubin, warna token, flag semantik,
// ukuran), bukan hanya "tidak jatuh". Klaim jujur diuji dengan server yang
// menahan atau menggagalkan `GET /alat`: bagian yang belum terbaca tidak
// boleh tampil sebagai nol atau "tidak ada".
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'package:sidik_pelanggan/core/motion/gerak_bento.dart';
import 'package:sidik_pelanggan/core/konfigurasi.dart';
import 'package:sidik_pelanggan/core/tema/tema_sidik.dart';
import 'package:sidik_pelanggan/core/tema/ukuran.dart';
import 'package:sidik_pelanggan/core/tema/warna_sidik.dart';
import 'package:sidik_pelanggan/models/akun.dart';
import 'package:sidik_pelanggan/models/data_pelanggan.dart';
import 'package:sidik_pelanggan/models/paket.dart';
import 'package:sidik_pelanggan/models/status_berlaku.dart';
import 'package:sidik_pelanggan/providers/koneksi_provider.dart';
import 'package:sidik_pelanggan/providers/sesi_provider.dart';
import 'package:sidik_pelanggan/screens/akun/bantuan_screen.dart';
import 'package:sidik_pelanggan/screens/alat/alat_detail_screen.dart';
import 'package:sidik_pelanggan/screens/alat/daftar_alat_screen.dart';
import 'package:sidik_pelanggan/screens/beranda/beranda_kapsul.dart';
import 'package:sidik_pelanggan/screens/beranda/beranda_kerangka.dart';
import 'package:sidik_pelanggan/screens/beranda/beranda_ringkas.dart';
import 'package:sidik_pelanggan/screens/beranda/beranda_screen.dart';
import 'package:sidik_pelanggan/screens/gerbang.dart';
import 'package:sidik_pelanggan/screens/paket/paket_screen.dart';
import 'package:sidik_pelanggan/screens/rangka.dart';
import 'package:sidik_pelanggan/widgets/dasar/kontrol_ketuk.dart';
import 'package:sidik_pelanggan/widgets/kalimat_utama.dart';
import 'package:sidik_pelanggan/widgets/keadaan_teks.dart';
import 'package:sidik_pelanggan/widgets/kerangka.dart';
import 'package:sidik_pelanggan/widgets/pemetaan_status.dart';
import 'package:sidik_pelanggan/widgets/status_tampil.dart';
import 'package:sidik_pelanggan/widgets/stempel.dart';
import 'package:sidik_pelanggan/widgets/tombol_sidik.dart';
import 'package:sidik_pelanggan/widgets/ubin_alat.dart';
import 'package:sidik_pelanggan/widgets/ubin_ringkas.dart';

import 'dukungan/fixture_fitur.dart';
import 'dukungan/layar_uji.dart';
import 'dukungan/ukur_komponen.dart';

// ── Pembantu ────────────────────────────────────────────────────────────────

Sesi _sesiSatu() => Sesi(
  akun: Akun.dariJson({
    'id': 7,
    'nama': 'Rina Wulandari',
    'email': 'rina@contoh.test',
    'status': 'aktif',
    'butuh_verifikasi': false,
    'keanggotaan': [
      {'customer_id': 3, 'nama_perusahaan': 'PT Alfa', 'peran': 'staf'},
    ],
  }),
  perusahaanId: 3,
);

ServerFitur _server({
  List<Map<String, dynamic>> alat = const [],
  List<Map<String, dynamic>> paket = const [],
  List<Map<String, dynamic>> sertifikat = const [],
  int? jumlahPaket,
  Map<String, dynamic> ringkasan = const {},
}) => ServerFitur({
  3: DataPerusahaan(
    nama: 'PT Alfa',
    alat: alat,
    paket: paket,
    sertifikat: sertifikat,
    jumlahPaketBerjalan: jumlahPaket,
    ringkasanTambahan: ringkasan,
  ),
});

/// Server yang menahan `GET /alat` (daftar jatuh tempo) sampai [lepas]
/// selesai: `GET /beranda` sudah terbaca, daftar alatnya belum.
class _ServerAlatTertahan extends ServerFitur {
  _ServerAlatTertahan(super.data);

  final lepas = Completer<void>();

  @override
  Future<http.Response> tangani(http.Request r) async {
    final jalur = r.url.path.replaceFirst(Konfigurasi.prefix, '');
    if (jalur == '/alat') await lepas.future;
    return super.tangani(r);
  }
}

/// Server yang menunda HANYA `GET /alat` sebesar [jedaAlat] (null = tanpa
/// jeda). `ServerFitur.jeda` menunda semua rute sekaligus, jadi tidak bisa
/// membuat keadaan "`GET /beranda` baru sudah tiba, `GET /alat` baru belum".
class _ServerAlatLambat extends ServerFitur {
  _ServerAlatLambat(super.data);

  Duration? jedaAlat;

  @override
  Future<http.Response> tangani(http.Request r) async {
    if (jedaAlat != null && r.url.path.endsWith('/alat')) {
      await Future<void>.delayed(jedaAlat!);
    }
    return super.tangani(r);
  }
}

Widget _app(
  ServerFitur server, {
  Sesi? sesi,
  double skala = 1.0,
  bool gelap = false,
  bool kurangiGerak = false,
  DateTime? jamHp,
}) => ProviderScope(
  overrides: overrideFitur(server, sesi: sesi, jamHp: jamHp),
  child: MaterialApp(
    theme: TemaSidik.terang,
    darkTheme: TemaSidik.gelap,
    themeMode: gelap ? ThemeMode.dark : ThemeMode.light,
    builder: (context, child) => MediaQuery.withClampedTextScaling(
      minScaleFactor: skala,
      maxScaleFactor: skala,
      child: MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: kurangiGerak),
        child: child!,
      ),
    ),
    home: const BerandaScreen(),
  ),
);

/// Pasang [w] di pohon BARU: ProviderScope lama (dan keadaannya) dibuang dulu,
/// jadi dua `_app` berurutan dalam satu tes tidak saling mewarisi data.
Future<void> _pasang(WidgetTester tester, Widget w) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pumpWidget(w);
}

/// Provider data Beranda memakai percobaan ulang bawaan Riverpod (10 kali,
/// ±38 detik) sebelum galat tampil. Kerangka memuat sekarang STATIS, jadi
/// `pumpAndSettle` tidak lagi ikut menunggu: waktu dimajukan secara eksplisit.
/// Memberi waktu pada permintaan yang masih terbang (jeda server) sampai selesai,
/// supaya tes tidak berakhir dengan pewaktu tertunda.
Future<void> _selesaikan(WidgetTester tester) async {
  for (var i = 0; i < 4; i++) {
    await tester.pump(const Duration(seconds: 3));
  }
  await tester.pumpAndSettle();
}

Future<void> _sampaiGalat(WidgetTester tester) async {
  await tester.pump();
  // Dua tahap: `GET /beranda` lalu `GET /alat` (baru dimulai saat isi dibangun).
  await tester.pump(const Duration(seconds: 60));
  await tester.pump(const Duration(seconds: 60));
  await tester.pumpAndSettle();
}

/// Maju frame demi frame sampai ubin alat pertama kali tampil (daftar alat
/// terbaca); animasi masuknya baru dimulai pada frame itu.
Future<void> _sampaiUbin(WidgetTester tester) async {
  for (var i = 0; i < 60 && find.byType(UbinAlat).evaluate().isEmpty; i++) {
    await tester.pump(const Duration(milliseconds: 1));
  }
}

WarnaSidik _w(bool gelap) =>
    (gelap ? TemaSidik.gelap : TemaSidik.terang).extension<WarnaSidik>()!;

ColorScheme _s(bool gelap) =>
    (gelap ? TemaSidik.gelap : TemaSidik.terang).colorScheme;

/// Warna latar ubin: `Material` pertama di bawah [ubin].
Color _latarUbin(WidgetTester tester, Finder ubin) => tester
    .widgetList<Material>(
      find.descendant(of: ubin, matching: find.byType(Material)),
    )
    .first
    .color!;

Alat _a(int id, int? hari, {String status = 'terkalibrasi'}) =>
    Alat.dariJson(alatJson(id, 'Alat $id', hari: hari, status: status));

/// Kata pada [Stempel] di dalam [ubin], berurutan.
List<String> _kataStempel(WidgetTester t, Finder ubin) => [
  for (final w in t.widgetList<Stempel>(
    find.descendant(of: ubin, matching: find.byType(Stempel)),
  ))
    w.status.label,
];

/// Ikon yang digambar [Stempel] pertama di dalam [ubin].
IconData? _ikonStempel(WidgetTester t, Finder ubin) => t
    .widget<Icon>(
      find
          .descendant(
            of: find.descendant(of: ubin, matching: find.byType(Stempel)),
            matching: find.byType(Icon),
          )
          .first,
    )
    .icon;

ProviderContainer _kontainer(WidgetTester t) =>
    ProviderScope.containerOf(t.element(find.byType(BerandaScreen)));

/// Skenario "ada yang mendesak": A paling lama lewat jadwal (dan sedang di
/// lab), B lewat jadwal lebih baru, C segera jatuh tempo.
List<Map<String, dynamic>> _alatMendesak() => [
  alatJson(
    1,
    'Jangka Sorong Digital',
    hari: -9,
    status: 'lewat_jadwal',
    merk: 'Mitutoyo',
    model: 'CD-15CPX',
    serial: '2201-0457',
    sedangDikerjakan: sedangDikerjakanJson(),
  ),
  alatJson(2, 'Timbangan Analitik', hari: -4, status: 'lewat_jadwal'),
  alatJson(3, 'Manometer', hari: 12, status: 'mendekati_jadwal'),
];

void main() {
  setUpAll(siapkanTesFitur);

  // ── Logika murni ──────────────────────────────────────────────────────────
  group('sapaan dan inisial', () {
    test('sapaan menurut jam: batas pagi, siang, sore, malam', () {
      String s(int jam, [int menit = 0]) =>
          sapaanWaktu(DateTime(2026, 11, 12, jam, menit));
      expect(s(3, 59), 'Selamat malam');
      expect(s(4), 'Selamat pagi');
      expect(s(10, 59), 'Selamat pagi');
      expect(s(11), 'Selamat siang');
      expect(s(14, 59), 'Selamat siang');
      expect(s(15), 'Selamat sore');
      expect(s(17, 59), 'Selamat sore');
      expect(s(18), 'Selamat malam');
      expect(s(0), 'Selamat malam');
    });

    test('inisial: dua kata pertama, kapital, kosong bila tanpa nama', () {
      expect(inisialNama('Budi Anggota'), 'BA');
      expect(inisialNama('  zainul   arkaan '), 'ZA');
      expect(inisialNama('Ani Budi Citra'), 'AB');
      expect(inisialNama('Rina'), 'R');
      expect(inisialNama('Érik Åke'), 'ÉÅ');
      expect(inisialNama('   '), '');
      expect(inisialNama(''), '');
    });
  });

  group('pilihUbinAlat: apa yang boleh diklaim', () {
    final lewat = RingkasanJatuhTempo.dari([
      _a(1, -2, status: 'lewat_jadwal'),
      _a(2, -9, status: 'lewat_jadwal'),
      _a(3, 20, status: 'mendekati_jadwal'),
    ]);
    final jauh = RingkasanJatuhTempo.dari([_a(4, 45), _a(5, 75)]);
    const kosongDaftar = RingkasanJatuhTempo();

    ({JenisUbinAlat jenis, Alat? alat}) pilih({
      bool adaAlat = true,
      bool semuaBerlaku = false,
      bool menunggu = false,
      RingkasanJatuhTempo? daftar,
      bool memuat = false,
    }) => pilihUbinAlat(
      adaAlat: adaAlat,
      semuaBerlaku: semuaBerlaku,
      menungguAlat: menunggu,
      daftar: daftar,
      daftarMemuat: memuat,
    );

    test('tanpa alat: kosong, apa pun jawaban lainnya', () {
      expect(pilih(adaAlat: false).jenis, JenisUbinAlat.kosong);
      expect(
        pilih(adaAlat: false, semuaBerlaku: true, daftar: lewat).jenis,
        JenisUbinAlat.kosong,
      );
    });

    test('yang mendesak = lewat jadwal TERLAMA, bukan urutan daftar', () {
      final p = pilih(daftar: lewat, menunggu: true);
      expect(p.jenis, JenisUbinAlat.alatMendesak);
      expect(p.alat!.id, 2);
      // Menang atas "semua berlaku" dari server bila daftar menunjukkan lain.
      expect(
        pilih(daftar: lewat, semuaBerlaku: true).jenis,
        JenisUbinAlat.alatMendesak,
      );
    });

    test('tidak ada yang mendesak: jadwal terdekat, dan klaim "semua '
        'berlaku" HANYA dari jaminan server', () {
      final tanpa = pilih(daftar: jauh);
      expect(tanpa.jenis, JenisUbinAlat.jadwalTerdekat);
      expect(tanpa.alat!.id, 4);
      final dengan = pilih(daftar: jauh, semuaBerlaku: true);
      expect(dengan.jenis, JenisUbinAlat.semuaBerlakuTerdekat);
      expect(dengan.alat!.id, 4);
      expect(
        pilih(daftar: kosongDaftar, semuaBerlaku: true).jenis,
        JenisUbinAlat.semuaBerlaku,
      );
      expect(pilih(daftar: kosongDaftar).jenis, JenisUbinAlat.tidakAda);
    });

    test('daftar memuat atau gagal TIDAK dibaca sebagai "tidak ada"', () {
      for (final menunggu in [true, false]) {
        final memuat = pilih(memuat: true, menunggu: menunggu);
        expect(memuat.jenis, JenisUbinAlat.memuat);
        expect(memuat.alat, isNull);
      }
      expect(pilih(menunggu: true).jenis, JenisUbinAlat.gagal);
      // Gagal tanpa hitungan mendesak dan tanpa jaminan: tidak mengklaim apa pun.
      expect(pilih().jenis, JenisUbinAlat.tidakAda);
      // Dengan jaminan server, klaim itu tetap sah walau daftar tak terbaca.
      expect(pilih(semuaBerlaku: true).jenis, JenisUbinAlat.semuaBerlaku);
    });

    test('tanpa jaminan server TIDAK PERNAH memilih ubin "semua berlaku"', () {
      final daftarUji = <RingkasanJatuhTempo?>[null, kosongDaftar, jauh, lewat];
      for (final daftar in daftarUji) {
        for (final memuat in [true, false]) {
          for (final menunggu in [true, false]) {
            final j = pilih(
              daftar: daftar,
              memuat: memuat,
              menunggu: menunggu,
            ).jenis;
            expect(
              j,
              isNot(
                anyOf(
                  JenisUbinAlat.semuaBerlaku,
                  JenisUbinAlat.semuaBerlakuTerdekat,
                ),
              ),
              reason: 'daftar=$daftar memuat=$memuat menunggu=$menunggu',
            );
          }
        }
      }
    });
  });

  group('isi ubin: tanggal, merk, sertifikat, paket', () {
    test('tanggal ubin alat: sejak, jatuh tempo, di lab, tanpa jadwal', () {
      final lewat = _a(1, -3, status: 'lewat_jadwal');
      expect(tanggalUbinAlat(lewat), 'sejak 9 Nov 2026');
      expect(tanggalUbinAlat(_a(2, 20)), 'jatuh tempo 2 Des 2026');
      expect(tanggalUbinAlat(_a(3, 0)), 'jatuh tempo 12 Nov 2026');
      expect(tanggalUbinAlat(_a(4, null)), isNull);
      final dilab = Alat.dariJson(
        alatJson(
          5,
          'Alat Lab',
          hari: -3,
          status: 'lewat_jadwal',
          sedangDikerjakan: sedangDikerjakanJson(label: 'Hasil diperiksa'),
        ),
      );
      expect(tanggalUbinAlat(dilab), 'Di lab: Hasil diperiksa');
    });

    test('merk dan model dipisah spasi; kosong = null', () {
      Alat dengan(String? merk, String? model) =>
          Alat.dariJson(alatJson(1, 'A', hari: 5, merk: merk, model: model));
      expect(merkTipeAlat(dengan('Mitutoyo', 'CD-15CPX')), 'Mitutoyo CD-15CPX');
      expect(merkTipeAlat(dengan('Mitutoyo', null)), 'Mitutoyo');
      expect(merkTipeAlat(dengan(null, 'CD-15CPX')), 'CD-15CPX');
      expect(merkTipeAlat(dengan(' ', '')), isNull);
      expect(merkTipeAlat(dengan(null, null)), isNull);
    });

    test('sertifikat: teks hanya nomor dan alat; pengecualian = status (ikon '
        '+ kata) dari pemetaan, PASS dan null diam', () {
      Sertifikat s({
        String? keputusan,
        int? berlakuSampai = 65,
        String status = 'berlaku',
        Map<String, dynamic>? digantikanOleh,
      }) => Sertifikat.dariJson(
        sertifikatJson(
          1,
          'CAL/ALFA/0001',
          keputusan: keputusan,
          berlakuSampai: berlakuSampai,
          status: status,
          digantikanOleh: digantikanOleh,
        ),
      );
      List<String> baris(Sertifikat x) => barisUbinSertifikat([x]);
      List<StatusTampil> status(Sertifikat x) =>
          statusUbinSertifikat([x], hariIniUji);
      List<String> kata(Sertifikat x) => [for (final t in status(x)) t.label];

      expect(barisUbinSertifikat(const []), isEmpty);
      expect(statusUbinSertifikat(const [], hariIniUji), isEmpty);
      // Kata keputusan dan masa berlaku BUKAN lagi baris teks polos.
      for (final x in [
        s(keputusan: 'PASS'),
        s(),
        s(keputusan: 'FAIL', berlakuSampai: -5),
      ]) {
        expect(baris(x), ['CAL/ALFA/0001', 'Jangka Sorong']);
      }
      // Keputusan null dan PASS: netral, tidak disebut sama sekali.
      expect(status(s(keputusan: 'PASS')), isEmpty);
      expect(status(s()), isEmpty);

      final gagal = status(s(keputusan: 'FAIL')).single;
      expect(gagal.label, 'Tidak memenuhi toleransi');
      expect(gagal.nada, NadaStatus.gagal);
      expect(gagal.ikon, statusKeputusan('FAIL')!.ikon);

      final berakhir = status(s(berlakuSampai: -5)).single;
      expect(berakhir.label, 'Masa berlaku berakhir');
      expect(berakhir.nada, NadaStatus.netral);
      expect(berakhir.ikon, statusBerlaku(StatusBerlaku.berakhir).ikon);

      final batal = status(s(status: 'dibatalkan')).single;
      expect(batal.label, 'Dibatalkan');
      expect(batal.nada, NadaStatus.gagal);
      expect(batal.ikon, statusBerlaku(StatusBerlaku.dibatalkan).ikon);

      final ganti = status(
        s(status: 'digantikan', digantikanOleh: {'id': 2, 'nomor': 'X'}),
      ).single;
      expect(ganti.label, 'Digantikan');
      expect(ganti.nada, NadaStatus.awas);
      expect(ganti.ikon, statusBerlaku(StatusBerlaku.digantikan).ikon);

      // FAIL dan masa berlaku berakhir bersama: dua kata, tidak saling menimpa.
      expect(kata(s(keputusan: 'FAIL', berlakuSampai: -5)), [
        'Tidak memenuhi toleransi',
        'Masa berlaku berakhir',
      ]);
    });

    test('nada ubin sertifikat: kuning menurut desain, koral bila ada yang '
        'gagal, TIDAK PERNAH hijau', () {
      Sertifikat s({String? keputusan, String status = 'berlaku'}) =>
          Sertifikat.dariJson(
            sertifikatJson(
              1,
              'CAL/ALFA/0001',
              keputusan: keputusan,
              status: status,
            ),
          );
      NadaStatus nada(Sertifikat x) =>
          nadaUbinSertifikat(statusUbinSertifikat([x], hariIniUji));

      expect(nadaUbinSertifikat(const []), NadaStatus.awas);
      expect(nada(s()), NadaStatus.awas);
      expect(nada(s(keputusan: 'PASS')), NadaStatus.awas);
      expect(nada(s(keputusan: 'FAIL')), NadaStatus.gagal);
      expect(nada(s(status: 'dibatalkan')), NadaStatus.gagal);
      for (final x in [
        s(),
        s(keputusan: 'PASS'),
        s(keputusan: 'FAIL'),
        s(status: 'dibatalkan'),
      ]) {
        expect(nada(x), isNot(NadaStatus.lulus));
      }
    });

    test('baris paket: nomor, tahap, terlambat, siap diambil, jumlah', () {
      Paket p(int id, {bool terlambat = false, String label = 'Diterima'}) =>
          Paket.dariJson(
            paketJson(id, 'ORD/$id', label: label, terlambat: terlambat),
          );
      List<String> baris(
        List<Paket> berjalan, {
        int? jumlah,
        int siap = 0,
        bool lebih = false,
      }) => barisUbinPaket(
        berjalan: berjalan,
        jumlah: jumlah ?? berjalan.length,
        siap: siap,
        siapMungkinLebih: lebih,
      );

      expect(baris(const []), isEmpty);
      expect(baris([p(1)]), ['ORD/1', 'Diterima']);
      // Terlambat BUKAN baris teks polos: status (ikon + kata + nada).
      expect(baris([p(1, terlambat: true)]), ['ORD/1', 'Diterima']);
      expect(statusUbinPaket(const []), isEmpty);
      expect(statusUbinPaket([p(1)]), isEmpty);
      final lambat = statusUbinPaket([p(1, terlambat: true)]).single;
      expect(lambat.label, 'Melewati target selesai');
      expect(lambat.nada, NadaStatus.awas);
      expect(lambat.ikon, Icons.schedule);
      expect(baris([p(1), p(2)], siap: 1), [
        'ORD/1',
        'Diterima',
        '1 paket siap diambil',
        '2 paket berjalan',
      ]);
      // Daftar dipotong server tanpa hitungan siap: jumlahnya tidak diklaim.
      expect(baris([p(1)], jumlah: 6, siap: 1, lebih: true), [
        'ORD/1',
        'Diterima',
        'Ada paket siap diambil',
        '6 paket berjalan',
      ]);
      // Hanya hitungan server (tanpa daftar): jumlah tetap disebut.
      expect(baris(const [], jumlah: 3), ['3 paket berjalan']);
    });

    test('paket diserahkan disaring seperti layar lama: tidak jadi paket '
        'pertama dan terlambatnya tidak dipakai; siap diambil tetap', () {
      Paket p(
        int id, {
        bool terlambat = false,
        String tahap = 'diterima',
        String label = 'Diterima',
      }) => Paket.dariJson(
        paketJson(
          id,
          'ORD/$id',
          tahap: tahap,
          label: label,
          terlambat: terlambat,
        ),
      );
      final serah = p(
        9,
        tahap: 'diserahkan',
        label: 'Sudah diserahkan',
        terlambat: true,
      );
      List<String> baris(List<Paket> berjalan, {int jumlah = 1}) =>
          barisUbinPaket(
            berjalan: berjalan,
            jumlah: jumlah,
            siap: 0,
            siapMungkinLebih: false,
          );

      expect(baris([serah, p(1)]), ['ORD/1', 'Diterima']);
      expect(statusUbinPaket([serah, p(1)]), isEmpty);
      // Hanya paket diserahkan di daftar: tidak ada paket pertama dan tidak
      // ada status terlambat; hitungan server tetap yang bicara.
      expect(baris([serah], jumlah: 0), isEmpty);
      expect(statusUbinPaket([serah]), isEmpty);
      // Siap diambil bukan diserahkan: tetap paket pertama.
      final siap = p(2, tahap: 'siap_diambil', label: 'Siap diambil');
      expect(baris([siap]), ['ORD/2', 'Siap diambil']);
    });

    test('nada ubin paket: hijau bila tenang, mengikuti status terlambat '
        '(kuning), tidak hijau bila terlambat', () {
      Paket p({bool terlambat = false}) =>
          Paket.dariJson(paketJson(1, 'ORD/1', terlambat: terlambat));
      expect(nadaUbinPaket(statusUbinPaket(const [])), NadaStatus.lulus);
      expect(nadaUbinPaket(statusUbinPaket([p()])), NadaStatus.lulus);
      expect(
        nadaUbinPaket(statusUbinPaket([p(terlambat: true)])),
        NadaStatus.awas,
      );
    });
  });

  // ── Kapsul jatuh tempo ────────────────────────────────────────────────────
  group('kapsul jatuh tempo', () {
    test('tinggi isi: 40 + 60 x (n / terbesar); nol 40; satu kolom 80', () {
      double h(int n, int maks, int kolom) =>
          tinggiIsiKapsul(jumlah: n, terbesar: maks, kolomBernilai: kolom);
      expect(UkuranUbin.kapsulMin, 40);
      expect(UkuranUbin.kapsulRel, 100);
      expect(h(0, 10, 2), 40);
      expect(h(10, 10, 2), 100);
      expect(h(5, 10, 2), 70);
      expect(h(1, 4, 3), 55);
      // Hanya satu kolom bernilai: 80, bukan 100.
      expect(h(7, 7, 1), 80);
      expect(h(0, 7, 1), 40);
      // Semuanya nol: tidak ada pembagian dengan nol.
      expect(h(0, 0, 0), 40);
    });

    ZonaKapsul z(String label, int n, NadaStatus nada, {String? semantik}) =>
        ZonaKapsul(label: label, jumlah: n, nada: nada, semantik: semantik);

    final empat = [
      z('Lewat jadwal', 4, NadaStatus.gagal),
      z('≤ 30 hari', 2, NadaStatus.awas, semantik: 'Dalam 30 hari'),
      z('31–60 hari', 0, NadaStatus.tunggu),
      z('61–90 hari', 1, NadaStatus.lulus),
    ];

    Widget bungkus(
      List<ZonaKapsul> zona, {
      ValueChanged<int>? onZona,
      bool animasi = false,
      double skala = 1.0,
      bool gelap = false,
      bool kurangiGerak = false,
    }) => MaterialApp(
      theme: TemaSidik.terang,
      darkTheme: TemaSidik.gelap,
      themeMode: gelap ? ThemeMode.dark : ThemeMode.light,
      builder: (context, child) => MediaQuery.withClampedTextScaling(
        minScaleFactor: skala,
        maxScaleFactor: skala,
        child: MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(disableAnimations: kurangiGerak),
          child: child!,
        ),
      ),
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: KapsulJatuhTempo(zona: zona, onZona: onZona, animasi: animasi),
        ),
      ),
    );

    double isi(WidgetTester t, int i) =>
        t.getSize(find.byKey(ValueKey<String>('kapsul-isi-$i'))).height;

    testWidgets('tinggi isi di layar mengikuti rumus dan warna nada', (
      tester,
    ) async {
      layarHp(tester, lebar: 392, tinggi: 800);
      await tester.pumpWidget(bungkus(empat));
      // terbesar 4; bernilai 3 kolom: 40 + 60 x n / 4.
      expect(isi(tester, 0), 100);
      expect(isi(tester, 1), 70);
      expect(isi(tester, 2), 40);
      expect(isi(tester, 3), 55);
      // Warna isi: merah muda, krem, biru kelabu, hijau muda (sama di dua tema).
      final w = _w(false);
      final warna = [
        for (var i = 0; i < 4; i++)
          (tester
                      .widget<DecoratedBox>(
                        find.descendant(
                          of: find.byKey(ValueKey<String>('kapsul-isi-$i')),
                          matching: find.byType(DecoratedBox),
                        ),
                      )
                      .decoration
                  as BoxDecoration)
              .color,
      ];
      expect(warna, [w.ubinGagal, w.ubinAwas, w.ubinTunggu, w.ubinLulus]);
    });

    testWidgets('satu kolom bernilai: isinya 80; semua nol: semuanya 40', (
      tester,
    ) async {
      layarHp(tester, lebar: 392, tinggi: 800);
      await tester.pumpWidget(
        bungkus([
          z('Lewat jadwal', 3, NadaStatus.gagal),
          z('≤ 30 hari', 0, NadaStatus.awas),
        ]),
      );
      expect(isi(tester, 0), 80);
      expect(isi(tester, 1), 40);
      await tester.pumpWidget(
        bungkus([
          z('Lewat jadwal', 0, NadaStatus.gagal),
          z('≤ 30 hari', 0, NadaStatus.awas),
        ]),
      );
      expect(isi(tester, 0), 40);
      expect(isi(tester, 1), 40);
    });

    testWidgets('angka dan kata: bernilai 24 tebal, nol 16; label kata', (
      tester,
    ) async {
      layarHp(tester, lebar: 392, tinggi: 800);
      await tester.pumpWidget(bungkus(empat));
      double ukuran(String teks) =>
          tester.widget<Text>(find.text(teks)).style!.fontSize!;
      expect(ukuran('4'), 24);
      expect(ukuran('0'), 16);
      for (final k in ['Lewat jadwal', '≤ 30 hari', '31–60 hari']) {
        expect(find.text(k), findsOneWidget);
      }
    });

    testWidgets('tiap kolom: tombol berlabel, sentuh >= 48, ketukan sampai', (
      tester,
    ) async {
      final semantik = tester.ensureSemantics();
      layarHp(tester, lebar: 320, tinggi: 800);
      final diketuk = <int>[];
      await tester.pumpWidget(bungkus(empat, onZona: diketuk.add));
      for (final e in find.byType(KontrolKetuk).evaluate()) {
        final u = tester.getSize(find.byWidget(e.widget));
        expect(u.width, greaterThanOrEqualTo(48));
        expect(u.height, greaterThanOrEqualTo(48));
      }
      final simpul = tester.getSemantics(
        find.bySemanticsLabel('Dalam 30 hari: 2 alat'),
      );
      expect(simpul.getSemanticsData().flagsCollection.isButton, isTrue);
      expect(simpul.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
      expect(find.bySemanticsLabel('Lewat jadwal: 4 alat'), findsOneWidget);
      expect(find.bySemanticsLabel('31–60 hari: 0 alat'), findsOneWidget);
      // Ketuk di sudut kiri atas kolom ke-4 (jauh dari angkanya).
      final kolom = find.bySemanticsLabel('61–90 hari: 1 alat');
      await tester.tapAt(tester.getTopLeft(kolom) + const Offset(2, 2));
      await tester.tap(find.bySemanticsLabel('Lewat jadwal: 4 alat'));
      expect(diketuk, [3, 0]);
      semantik.dispose();
    });

    testWidgets('tanpa onZona: kolom mati (enabled false), label tetap', (
      tester,
    ) async {
      final semantik = tester.ensureSemantics();
      layarHp(tester, lebar: 392, tinggi: 800);
      await tester.pumpWidget(bungkus(empat));
      final d = tester
          .getSemantics(find.bySemanticsLabel('Lewat jadwal: 4 alat'))
          .getSemanticsData();
      expect(d.hasAction(SemanticsAction.tap), isFalse);
      semantik.dispose();
    });

    testWidgets('320 dp x huruf 1,3 dan angka 4 digit: tanpa luapan, angka '
        'di dalam kapsulnya', (tester) async {
      layarHp(tester, lebar: 320, tinggi: 800);
      await tester.pumpWidget(
        bungkus([
          z('Lewat jadwal', 1288, NadaStatus.gagal),
          z('≤ 30 hari', 340, NadaStatus.awas),
          z('31–60 hari', 7, NadaStatus.tunggu),
          z('61–90 hari', 0, NadaStatus.lulus),
        ], skala: 1.3),
      );
      expect(tester.takeException(), isNull);
      // Angka 4 digit mengecil (FittedBox) sampai muat di lebar kolomnya; ia
      // mulai di bawah tepi atas isi (padding atas 12).
      for (final (i, n) in [(0, '1288'), (1, '340'), (2, '7')]) {
        final angka = tester.getRect(find.text(n));
        final kapsul = tester.getRect(
          find.byKey(ValueKey<String>('kapsul-isi-$i')),
        );
        expect(angka.left, greaterThanOrEqualTo(kapsul.left - 0.5), reason: n);
        expect(angka.right, lessThanOrEqualTo(kapsul.right + 0.5), reason: n);
        expect(angka.top, greaterThanOrEqualTo(kapsul.top), reason: n);
      }
    });

    testWidgets(
      'animasi: tumbuh dari 0 sekali; kurangi gerak = langsung akhir',
      (tester) async {
        layarHp(tester, lebar: 392, tinggi: 800);
        // Gerak normal: kolom pertama mulai dari 0 lalu mencapai 100.
        await tester.pumpWidget(bungkus(empat, animasi: true));
        expect(isi(tester, 0), 0);
        await tester.pump(const Duration(milliseconds: 120));
        expect(isi(tester, 0), inExclusiveRange(0, 100));
        await tester.pumpAndSettle();
        expect(isi(tester, 0), 100);
        expect(isi(tester, 3), 55);

        // Kurangi gerak: langsung keadaan akhir pada frame pertama.
        await _pasang(
          tester,
          bungkus(empat, animasi: true, kurangiGerak: true),
        );
        expect(isi(tester, 0), 100);
        expect(isi(tester, 1), 70);
        expect(isi(tester, 3), 55);
      },
    );

    testWidgets('kontras angka dan label di dua tema (>= 4,5:1)', (
      tester,
    ) async {
      layarHp(tester, lebar: 392, tinggi: 800);
      for (final gelap in [false, true]) {
        await tester.pumpWidget(bungkus(empat, gelap: gelap));
        await tester.pumpAndSettle();
        expect(
          pelanggaranKontrasTeks(tester, find.byType(KapsulJatuhTempo)),
          isEmpty,
          reason: gelap ? 'tema gelap' : 'tema terang',
        );
      }
    });
  });

  // ── Kepala ────────────────────────────────────────────────────────────────
  group('kepala: avatar, sapaan, nama, pil perusahaan', () {
    testWidgets('inisial, sapaan menurut jam, dan nama akun', (tester) async {
      layarHp(tester, lebar: 392, tinggi: 2400);
      await tester.pumpWidget(
        _app(_server(), jamHp: DateTime(2026, 11, 12, 9)),
      );
      await tester.pumpAndSettle();
      expect(find.text('BA'), findsOneWidget);
      expect(find.text('Selamat pagi,'), findsOneWidget);
      expect(find.text('Budi Anggota'), findsOneWidget);

      await _pasang(
        tester,
        _app(_server(), jamHp: DateTime(2026, 11, 12, 20), sesi: _sesiSatu()),
      );
      await tester.pumpAndSettle();
      expect(find.text('RW'), findsOneWidget);
      expect(find.text('Selamat malam,'), findsOneWidget);
      expect(find.text('Rina Wulandari'), findsOneWidget);
    });

    testWidgets('pil perusahaan: HANYA akun multi-PT, tombol berlabel >= 48, '
        'membuka pilihan perusahaan', (tester) async {
      final semantik = tester.ensureSemantics();
      layarHp(tester, lebar: 392, tinggi: 2400);
      await tester.pumpWidget(
        _app(_server(alat: [alatJson(1, 'A', hari: 100)])),
      );
      await tester.pumpAndSettle();
      final label = find.bySemanticsLabel('Ganti perusahaan, sekarang PT Alfa');
      expect(label, findsOneWidget);
      final d = tester.getSemantics(label).getSemanticsData();
      expect(d.flagsCollection.isButton, isTrue);
      expect(d.hasAction(SemanticsAction.tap), isTrue);
      final pil = find.ancestor(
        of: find.text('PT Alfa'),
        matching: find.byType(KontrolKetuk),
      );
      expect(tester.getSize(pil).height, greaterThanOrEqualTo(48));
      expect(tester.getSize(pil).width, greaterThanOrEqualTo(48));

      await tester.tap(find.text('PT Alfa'));
      await tester.pumpAndSettle();
      expect(find.byType(PilihPerusahaanScreen), findsOneWidget);
      semantik.dispose();
    });

    testWidgets('satu perusahaan: tanpa pil dan tanpa nama PT', (tester) async {
      final semantik = tester.ensureSemantics();
      layarHp(tester, lebar: 392, tinggi: 2400);
      await tester.pumpWidget(
        _app(_server(alat: [alatJson(1, 'A', hari: 100)]), sesi: _sesiSatu()),
      );
      await tester.pumpAndSettle();
      expect(find.text('PT Alfa'), findsNothing);
      expect(find.byType(KontrolKetuk), findsWidgets);
      expect(find.bySemanticsLabel(RegExp('Ganti perusahaan')), findsNothing);
      semantik.dispose();
    });

    testWidgets('sapaan teks kedua dan nama di atas latar: kontras >= 4,5', (
      tester,
    ) async {
      layarHp(tester, lebar: 392, tinggi: 2400);
      for (final gelap in [false, true]) {
        await _pasang(
          tester,
          _app(_server(alat: [alatJson(1, 'A', hari: 100)]), gelap: gelap),
        );
        await tester.pumpAndSettle();
        final s = _s(gelap);
        final bg = Theme.of(
          tester.element(find.byType(Scaffold).first),
        ).scaffoldBackgroundColor;
        final sapaan = tester.widget<Text>(find.text('Selamat pagi,'));
        expect(sapaan.style!.color, s.onSurfaceVariant);
        expect(rasioKontras(s.onSurfaceVariant, bg), greaterThanOrEqualTo(4.5));
        // Inisial putih di atas navy tetap di dua tema (hiasan, terbaca).
        expect(
          rasioKontras(_w(gelap).kertasUbin, _w(gelap).tintaUbin),
          greaterThanOrEqualTo(4.5),
        );
      }
    });
  });

  // ── Kalimat utama ─────────────────────────────────────────────────────────
  group('kalimat utama', () {
    testWidgets('tanpa dateline; kalimat pertama tegas, kedua teks kedua', (
      tester,
    ) async {
      layarHp(tester, lebar: 392, tinggi: 2400);
      final paketSiap = paketJson(
        20,
        'ORD/ALFA/2026/0020',
        tahap: 'siap_diambil',
        label: 'Siap diambil',
      );
      await tester.pumpWidget(
        _app(
          _server(alat: _alatMendesak(), paket: [paketSiap]),
          sesi: _sesiSatu(),
        ),
      );
      await tester.pumpAndSettle();
      // Hari dan tanggal tidak lagi di atas kalimat (sapaan menggantikannya).
      expect(find.text('Kamis, 12 November 2026'), findsNothing);
      final s = _s(false);
      final potongan = {
        for (final x in ukurTeks(tester, find.byType(KalimatUtama))) x.teks: x,
      };
      expect(potongan['2 alat ']!.warna, s.onSurface);
      expect(potongan['1 paket ']!.warna, s.onSurfaceVariant);
      expect(potongan['2 alat ']!.ukuran, 24);
      // Frasa status tetap KATA ber-nada (bukan hanya warna), di dua kalimat.
      expect(potongan.keys, containsAll(['lewat jadwal', 'siap diambil']));
      expect(potongan['lewat jadwal']!.warna, _w(false).gagal);
      expect(potongan['siap diambil']!.warna, _w(false).lulus);
    });
  });

  // ── Ubin alat ─────────────────────────────────────────────────────────────
  group('ubin alat: satu alat paling mendesak', () {
    testWidgets('lewat jadwal terlama: kartu netral >= 160, lencana, angka, '
        'kata, identitas, dan "Di lab"', (tester) async {
      layarHp(tester, lebar: 392, tinggi: 2400);
      await tester.pumpWidget(
        _app(_server(alat: _alatMendesak()), sesi: _sesiSatu()),
      );
      await tester.pumpAndSettle();

      final ubin = find.byType(UbinAlat);
      expect(ubin, findsOneWidget, reason: 'hanya SATU ubin alat');
      final u = tester.widget<UbinAlat>(ubin);
      expect(u.nama, 'Jangka Sorong Digital');
      expect(u.beranda, isTrue);
      expect(u.status.label, StatusBerlaku.lewatJadwal.label);
      expect(u.status.nada, NadaStatus.gagal);
      expect(
        _latarUbin(tester, ubin),
        _s(false).surface,
        reason: 'kartu alat netral; status hanya di lencana',
      );
      expect(
        tester.getSize(ubin).height,
        greaterThanOrEqualTo(UkuranUbin.alatBeranda),
      );

      for (final teks in [
        'Lewat jadwal',
        '9',
        'hari lewat',
        'Mitutoyo CD-15CPX',
        '2201-0457',
        'Di lab: Sedang dikalibrasi',
      ]) {
        expect(
          find.descendant(of: ubin, matching: find.text(teks)),
          findsOneWidget,
          reason: teks,
        );
      }
      // Alat yang kurang mendesak tidak digambar sebagai ubin.
      expect(find.text('Timbangan Analitik'), findsNothing);
      expect(find.text('Manometer'), findsNothing);
    });

    testWidgets('segera jatuh tempo: kartu netral, "hari lagi", tanggal', (
      tester,
    ) async {
      layarHp(tester, lebar: 392, tinggi: 2400);
      await tester.pumpWidget(
        _app(
          _server(
            alat: [
              alatJson(3, 'Manometer', hari: 12, status: 'mendekati_jadwal'),
            ],
          ),
          sesi: _sesiSatu(),
        ),
      );
      await tester.pumpAndSettle();
      final ubin = find.byType(UbinAlat);
      expect(tester.widget<UbinAlat>(ubin).status.label, 'Segera jatuh tempo');
      expect(_latarUbin(tester, ubin), _s(false).surface);
      expect(find.text('hari lagi'), findsOneWidget);
      expect(find.text('jatuh tempo 24 Nov 2026'), findsOneWidget);
    });

    testWidgets(
      'seluruh ubin satu tombol berlabel: ketuk membuka detail alat',
      (tester) async {
        final semantik = tester.ensureSemantics();
        layarHp(tester, lebar: 392, tinggi: 2400);
        await tester.pumpWidget(
          _app(_server(alat: _alatMendesak()), sesi: _sesiSatu()),
        );
        await tester.pumpAndSettle();
        final d = tester
            .getSemantics(
              find.bySemanticsLabel(RegExp('^Jangka Sorong Digital')),
            )
            .getSemanticsData();
        expect(d.flagsCollection.isButton, isTrue);
        expect(d.hasAction(SemanticsAction.tap), isTrue);
        expect(d.label, contains('Status: Lewat jadwal'));
        // Ketuk di kanan bawah ubin (di luar teksnya, di dalam sudut bulatnya).
        final r = tester.getRect(find.byType(UbinAlat));
        await tester.tapAt(r.bottomRight - const Offset(24, 24));
        await tester.pumpAndSettle();
        expect(find.byType(AlatDetailScreen), findsOneWidget);
        semantik.dispose();
      },
    );

    testWidgets('tenang dan server MENJAMIN: "Semua alat berlaku" + jadwal '
        'terdekat', (tester) async {
      layarHp(tester, lebar: 392, tinggi: 2400);
      await tester.pumpWidget(
        _app(
          _server(
            alat: [
              alatJson(1, 'Mikro', hari: 200),
              alatJson(2, 'Manometer', hari: 45),
            ],
            ringkasan: const {'alat_berlaku': 2, 'alat_belum_pernah': 0},
          ),
          sesi: _sesiSatu(),
        ),
      );
      await tester.pumpAndSettle();
      final ubin = find.byType(UbinAlat);
      expect(tester.widget<UbinAlat>(ubin).nama, 'Semua alat berlaku');
      expect(tester.widget<UbinAlat>(ubin).merkTipe, 'Berikutnya: Manometer');
      expect(_latarUbin(tester, ubin), _s(false).surface);
      expect(find.text('45'), findsOneWidget);
      expect(find.text('Semua alat Anda berlaku.'), findsOneWidget);
    });

    testWidgets(
      'tenang TANPA jaminan server: tidak ada klaim "semua berlaku"',
      (tester) async {
        layarHp(tester, lebar: 392, tinggi: 2400);
        await tester.pumpWidget(
          _app(
            _server(alat: [alatJson(2, 'Manometer', hari: 45)]),
            sesi: _sesiSatu(),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Semua alat berlaku'), findsNothing);
        expect(find.text('Semua alat Anda berlaku.'), findsNothing);
        // Yang tampil adalah alat itu sendiri dengan statusnya sendiri.
        expect(
          tester.widget<UbinAlat>(find.byType(UbinAlat)).nama,
          'Manometer',
        );
      },
    );
  });

  // ── Ubin pasangan, tombol, panel, bantuan ────────────────────────────────
  group('ubin pasangan, tombol utama, bantuan', () {
    final sertifikat = [
      sertifikatJson(
        12,
        'CAL/ALFA/0002',
        namaAlat: 'Timbangan Analitik',
        diterbitkan: -3,
      ),
      sertifikatJson(11, 'CAL/ALFA/0001', diterbitkan: -300),
    ];
    final paketLab = paketJson(
      21,
      'ORD/ALFA/2026/0021',
      tahap: 'diterima',
      label: 'Alat diterima lab',
      terlambat: true,
    );

    testWidgets('kosong: kalimat kosong yang jujur, warna kuning dan hijau', (
      tester,
    ) async {
      layarHp(tester, lebar: 392, tinggi: 2400);
      await tester.pumpWidget(
        _app(_server(alat: [alatJson(1, 'A', hari: 100)]), sesi: _sesiSatu()),
      );
      await tester.pumpAndSettle();
      final sert = find.widgetWithText(UbinRingkas, 'Sertifikat terbaru');
      final pak = find.widgetWithText(UbinRingkas, 'Paket dikerjakan');
      expect(
        find.descendant(
          of: sert,
          matching: find.text('Belum ada sertifikat yang terbit.'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: pak,
          matching: find.text('Tidak ada paket yang sedang dikerjakan.'),
        ),
        findsOneWidget,
      );
      expect(_latarUbin(tester, sert), _w(false).ubinAwas);
      expect(_latarUbin(tester, pak), _w(false).ubinLulus);
      // Berdampingan, tinggi sama (grid bento).
      expect(tester.getTopLeft(sert).dy, tester.getTopLeft(pak).dy);
      expect(tester.getSize(sert).height, tester.getSize(pak).height);
      expect(
        tester.getSize(sert).height,
        greaterThanOrEqualTo(UkuranUbin.pasangan),
      );
    });

    testWidgets('berisi: baris pertama = nomor dan nama terbaru; FAIL dan '
        'terlambat bersuara', (tester) async {
      layarHp(tester, lebar: 392, tinggi: 2400);
      final gagal = [
        sertifikatJson(
          12,
          'CAL/ALFA/0002',
          namaAlat: 'Timbangan Analitik',
          keputusan: 'FAIL',
          diterbitkan: -3,
        ),
      ];
      await tester.pumpWidget(
        _app(
          _server(
            alat: [alatJson(1, 'A', hari: 100)],
            sertifikat: gagal,
            paket: [paketLab],
            jumlahPaket: 4,
          ),
          sesi: _sesiSatu(),
        ),
      );
      await tester.pumpAndSettle();
      final sertUbin = find.widgetWithText(UbinRingkas, 'Sertifikat terbaru');
      final sert = tester.widget<UbinRingkas>(sertUbin);
      expect(sert.kalimat!.split('\n'), [
        'CAL/ALFA/0002',
        'Timbangan Analitik',
      ]);
      // FAIL = stempel (ikon + kata) dan ubin koral, bukan baris teks polos.
      expect(_kataStempel(tester, sertUbin), ['Tidak memenuhi toleransi']);
      expect(_ikonStempel(tester, sertUbin), Icons.cancel_outlined);
      expect(_latarUbin(tester, sertUbin), _w(false).ubinGagal);
      final pakUbin = find.widgetWithText(UbinRingkas, 'Paket dikerjakan');
      final pak = tester.widget<UbinRingkas>(pakUbin);
      expect(pak.kalimat!.split('\n'), [
        'ORD/ALFA/2026/0021',
        'Alat diterima lab',
        '4 paket berjalan',
      ]);
      // Terlambat = stempel kuning, ubin TIDAK hijau.
      expect(_kataStempel(tester, pakUbin), ['Melewati target selesai']);
      expect(_ikonStempel(tester, pakUbin), Icons.schedule);
      expect(_latarUbin(tester, pakUbin), _w(false).ubinAwas);
      expect(_latarUbin(tester, pakUbin), isNot(_w(false).ubinLulus));
    });

    testWidgets('keputusan null: netral, tidak ada kata keputusan', (
      tester,
    ) async {
      layarHp(tester, lebar: 392, tinggi: 2400);
      await tester.pumpWidget(
        _app(
          _server(
            alat: [alatJson(1, 'A', hari: 100)],
            sertifikat: [sertifikatJson(5, 'CAL/ALFA/0005', keputusan: null)],
          ),
          sesi: _sesiSatu(),
        ),
      );
      await tester.pumpAndSettle();
      final sertUbin = find.widgetWithText(UbinRingkas, 'Sertifikat terbaru');
      final sert = tester.widget<UbinRingkas>(sertUbin);
      expect(sert.kalimat, 'CAL/ALFA/0005\nJangka Sorong');
      expect(find.textContaining('toleransi'), findsNothing);
      // Tanpa keputusan: tidak ada stempel, dan ubin tidak pernah hijau.
      expect(_kataStempel(tester, sertUbin), isEmpty);
      expect(_latarUbin(tester, sertUbin), _w(false).ubinAwas);
      expect(_latarUbin(tester, sertUbin), isNot(_w(false).ubinLulus));
    });

    testWidgets('masa berlaku berakhir, digantikan, dibatalkan: stempel ikon + '
        'kata dari pemetaan status, bukan teks polos', (tester) async {
      layarHp(tester, lebar: 392, tinggi: 2400);
      final kasus = <(Map<String, dynamic>, String, IconData, Color)>[
        (
          sertifikatJson(1, 'CAL/1', berlakuSampai: -5),
          'Masa berlaku berakhir',
          statusBerlaku(StatusBerlaku.berakhir).ikon,
          _w(false).ubinAwas,
        ),
        (
          sertifikatJson(
            2,
            'CAL/2',
            status: 'digantikan',
            digantikanOleh: {'id': 9, 'nomor': 'CAL/9'},
          ),
          'Digantikan',
          statusBerlaku(StatusBerlaku.digantikan).ikon,
          _w(false).ubinAwas,
        ),
        (
          sertifikatJson(3, 'CAL/3', status: 'dibatalkan'),
          'Dibatalkan',
          statusBerlaku(StatusBerlaku.dibatalkan).ikon,
          _w(false).ubinGagal,
        ),
      ];
      for (final (json, kata, ikon, latar) in kasus) {
        await _pasang(
          tester,
          _app(
            _server(alat: [alatJson(1, 'A', hari: 100)], sertifikat: [json]),
            sesi: _sesiSatu(),
          ),
        );
        await tester.pumpAndSettle();
        final ubin = find.widgetWithText(UbinRingkas, 'Sertifikat terbaru');
        expect(_kataStempel(tester, ubin), [kata], reason: kata);
        expect(_ikonStempel(tester, ubin), ikon, reason: kata);
        expect(_latarUbin(tester, ubin), latar, reason: kata);
        expect(
          tester.widget<UbinRingkas>(ubin).kalimat,
          isNot(contains(kata)),
          reason: 'kata hanya di stempel, tidak ganda di baris teks',
        );
      }
    });

    testWidgets('paket diserahkan di daftar tidak jadi paket pertama dan '
        'tidak membuat ubin terlambat', (tester) async {
      layarHp(tester, lebar: 392, tinggi: 2400);
      await tester.pumpWidget(
        _app(
          _server(
            alat: [alatJson(1, 'A', hari: 100)],
            paket: [
              paketJson(
                30,
                'ORD/ALFA/2026/0030',
                tahap: 'diserahkan',
                label: 'Sudah diserahkan',
                terlambat: true,
              ),
              paketJson(
                21,
                'ORD/ALFA/2026/0021',
                tahap: 'diterima',
                label: 'Alat diterima lab',
              ),
            ],
            jumlahPaket: 1,
          ),
          sesi: _sesiSatu(),
        ),
      );
      await tester.pumpAndSettle();
      final ubin = find.widgetWithText(UbinRingkas, 'Paket dikerjakan');
      expect(
        tester.widget<UbinRingkas>(ubin).kalimat,
        'ORD/ALFA/2026/0021\n'
        'Alat diterima lab',
      );
      expect(find.textContaining('ORD/ALFA/2026/0030'), findsNothing);
      expect(find.textContaining('Sudah diserahkan'), findsNothing);
      expect(_kataStempel(tester, ubin), isEmpty);
      expect(_latarUbin(tester, ubin), _w(false).ubinLulus);
    });

    testWidgets('semantik ubin menyebut status stempel; ubin tetap satu '
        'tombol berlabel', (tester) async {
      final semantik = tester.ensureSemantics();
      layarHp(tester, lebar: 392, tinggi: 2400);
      await tester.pumpWidget(
        _app(
          _server(
            alat: [alatJson(1, 'A', hari: 100)],
            sertifikat: [
              sertifikatJson(
                12,
                'CAL/ALFA/0002',
                namaAlat: 'Timbangan Analitik',
                keputusan: 'FAIL',
              ),
            ],
            paket: [paketLab],
          ),
          sesi: _sesiSatu(),
        ),
      );
      await tester.pumpAndSettle();
      for (final (awal, status) in [
        ('Sertifikat terbaru', 'Status: Tidak memenuhi toleransi'),
        ('Paket dikerjakan', 'Status: Melewati target selesai'),
      ]) {
        final d = tester
            .getSemantics(find.bySemanticsLabel(RegExp('^$awal')))
            .getSemanticsData();
        expect(d.flagsCollection.isButton, isTrue, reason: awal);
        expect(d.hasAction(SemanticsAction.tap), isTrue, reason: awal);
        expect(d.label, contains(status), reason: awal);
      }
      semantik.dispose();
    });

    testWidgets('paket siap diambil: hitungan server menang; daftar dipotong '
        'tanpa hitungan = tidak diklaim', (tester) async {
      layarHp(tester, lebar: 392, tinggi: 2400);
      final siap = paketJson(
        20,
        'ORD/ALFA/2026/0020',
        tahap: 'siap_diambil',
        label: 'Siap diambil',
      );
      await tester.pumpWidget(
        _app(
          _server(
            alat: [alatJson(1, 'A', hari: 100)],
            paket: [siap],
            jumlahPaket: 6,
            ringkasan: const {'paket_siap_diambil': 3},
          ),
          sesi: _sesiSatu(),
        ),
      );
      await tester.pumpAndSettle();
      var pak = tester.widget<UbinRingkas>(
        find.widgetWithText(UbinRingkas, 'Paket dikerjakan'),
      );
      expect(pak.kalimat, contains('3 paket siap diambil'));
      expect(pak.kalimat, contains('6 paket berjalan'));
      expect(find.text('3 paket siap diambil.'), findsOneWidget);

      await _pasang(
        tester,
        _app(
          _server(
            alat: [alatJson(1, 'A', hari: 100)],
            paket: [siap],
            jumlahPaket: 6,
          ),
          sesi: _sesiSatu(),
        ),
      );
      await tester.pumpAndSettle();
      pak = tester.widget<UbinRingkas>(
        find.widgetWithText(UbinRingkas, 'Paket dikerjakan'),
      );
      expect(pak.kalimat, contains('Ada paket siap diambil'));
      expect(pak.kalimat, isNot(contains('1 paket siap diambil')));
      expect(find.text('Ada paket siap diambil.'), findsOneWidget);
    });

    testWidgets('ketuk: sertifikat ke tab Sertifikat, paket ke layar paket', (
      tester,
    ) async {
      layarHp(tester, lebar: 392, tinggi: 2400);
      await tester.pumpWidget(
        _app(
          _server(
            alat: [alatJson(1, 'A', hari: 100)],
            sertifikat: sertifikat,
            paket: [paketLab],
          ),
          sesi: _sesiSatu(),
        ),
      );
      await tester.pumpAndSettle();
      expect(_kontainer(tester).read(tabProvider), IndeksTab.beranda);
      await tester.tap(find.widgetWithText(UbinRingkas, 'Sertifikat terbaru'));
      await tester.pumpAndSettle();
      expect(_kontainer(tester).read(tabProvider), IndeksTab.sertifikat);

      await tester.tap(find.widgetWithText(UbinRingkas, 'Paket dikerjakan'));
      await tester.pumpAndSettle();
      expect(find.byType(PaketScreen), findsOneWidget);
    });

    testWidgets('tombol utama "Lihat semua alat" berlencana jumlah server', (
      tester,
    ) async {
      final semantik = tester.ensureSemantics();
      layarHp(tester, lebar: 392, tinggi: 2400);
      await tester.pumpWidget(
        _app(
          _server(
            alat: [
              for (var i = 1; i <= 7; i++)
                alatJson(i, 'Alat $i', hari: 100 + i),
            ],
          ),
          sesi: _sesiSatu(),
        ),
      );
      await tester.pumpAndSettle();
      final tombol = tester.widget<TombolSidik>(find.byType(TombolSidik));
      expect(tombol.label, 'Lihat semua alat');
      expect(tombol.ragam, RagamTombol.utama);
      expect(tombol.jumlah, 7);
      expect(tombol.satuanJumlah, 'alat');
      expect(tombol.penuh, isTrue);
      expect(
        tester.getSize(find.byType(TombolSidik)).height,
        greaterThanOrEqualTo(UkuranBaris.tombolUtama),
      );
      // Pembaca layar mendengar angka BESERTA satuannya: "7 alat", bukan "7".
      final label = find.bySemanticsLabel('Lihat semua alat, 7 alat');
      expect(label, findsOneWidget);
      expect(find.bySemanticsLabel('Lihat semua alat, 7'), findsNothing);
      final d = tester.getSemantics(label).getSemanticsData();
      expect(d.flagsCollection.isButton, isTrue);
      expect(d.hasAction(SemanticsAction.tap), isTrue);
      await tester.tap(find.byType(TombolSidik));
      await tester.pump();
      expect(_kontainer(tester).read(tabProvider), IndeksTab.alat);
      semantik.dispose();
    });

    testWidgets(
      'baris bantuan: tombol berlabel, tinggi >= 76, membuka bantuan',
      (tester) async {
        final semantik = tester.ensureSemantics();
        layarHp(tester, lebar: 392, tinggi: 2400);
        await tester.pumpWidget(
          _app(_server(alat: [alatJson(1, 'A', hari: 100)]), sesi: _sesiSatu()),
        );
        await tester.pumpAndSettle();
        final label = find.bySemanticsLabel(
          'Hubungi lab: tanya jadwal, sertifikat, atau paket',
        );
        final d = tester.getSemantics(label).getSemanticsData();
        expect(d.flagsCollection.isButton, isTrue);
        expect(d.hasAction(SemanticsAction.tap), isTrue);
        final baris = find.ancestor(
          of: find.text('Butuh bantuan? Hubungi lab'),
          matching: find.byType(KontrolKetuk),
        );
        expect(tester.getSize(baris).height, greaterThanOrEqualTo(76));
        expect(
          tester.getSize(baris).width,
          closeTo(392 - 2 * 16, 1),
          reason: 'selebar kolom',
        );
        await tester.tap(find.text('Tanya jadwal, sertifikat, atau paket'));
        await tester.pumpAndSettle();
        expect(find.byType(BantuanScreen), findsOneWidget);
        semantik.dispose();
      },
    );
  });

  // ── Panel kapsul di layar: klaim jujur ───────────────────────────────────
  group('panel Jatuh tempo kalibrasi: hitungan server dan klaim jujur', () {
    ServerFitur datar() => _server(
      alat: [
        alatJson(1, 'Lewat 1', hari: -5, status: 'lewat_jadwal'),
        alatJson(2, 'Lewat 2', hari: -2, status: 'lewat_jadwal'),
        alatJson(3, 'Segera', hari: 12, status: 'mendekati_jadwal'),
        alatJson(4, 'Tengah', hari: 45),
        alatJson(5, 'Jauh A', hari: 75),
        alatJson(6, 'Jauh B', hari: 80),
        alatJson(7, 'Luar', hari: 200),
      ],
    );

    testWidgets('empat kolom dengan hitungan benar dan label kata', (
      tester,
    ) async {
      final semantik = tester.ensureSemantics();
      layarHp(tester, lebar: 392, tinggi: 2400);
      await tester.pumpWidget(_app(datar(), sesi: _sesiSatu()));
      await tester.pumpAndSettle();
      expect(find.text('Jatuh tempo kalibrasi'), findsOneWidget);
      expect(find.text('90 hari ke depan'), findsOneWidget);
      expect(find.bySemanticsLabel('Lewat jadwal: 2 alat'), findsOneWidget);
      expect(find.bySemanticsLabel('Dalam 30 hari: 1 alat'), findsOneWidget);
      expect(find.bySemanticsLabel('31–60 hari: 1 alat'), findsOneWidget);
      expect(find.bySemanticsLabel('61–90 hari: 2 alat'), findsOneWidget);
      for (final k in [
        'Lewat jadwal',
        '≤ 30 hari',
        '31–60 hari',
        '61–90 hari',
      ]) {
        expect(
          find.descendant(
            of: find.byType(KapsulJatuhTempo),
            matching: find.text(k),
          ),
          findsOneWidget,
          reason: k,
        );
      }
      // Ketuk kolom 61-90 membuka daftar yang tersaring.
      await tester.tap(find.bySemanticsLabel('61–90 hari: 2 alat'));
      await tester.pumpAndSettle();
      expect(find.byType(DaftarAlatScreen), findsOneWidget);
      semantik.dispose();
    });

    testWidgets('daftar alat MASIH dimuat: dua kolom server saja, ubin alat '
        'berupa kerangka, bukan nol atau "tidak ada"', (tester) async {
      layarHp(tester, lebar: 392, tinggi: 2400);
      final server = _ServerAlatTertahan(datar().data);
      addTearDown(() {
        if (!server.lepas.isCompleted) server.lepas.complete();
      });
      await tester.pumpWidget(_app(server, sesi: _sesiSatu()));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump();

      // Hitungan server sudah ada.
      expect(find.text('2 alat lewat jadwal.'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(KapsulJatuhTempo),
          matching: find.byType(KontrolKetuk),
        ),
        findsNWidgets(2),
      );
      expect(find.text('31–60 hari'), findsNothing);
      expect(find.text('61–90 hari'), findsNothing);
      // Ubin alat = kerangka statis; BUKAN ubin alat dan BUKAN "tidak ada".
      expect(find.byType(UbinAlatMemuat), findsOneWidget);
      expect(find.byType(UbinAlat), findsNothing);
      expect(find.text('Semua alat berlaku'), findsNothing);
      expect(find.textContaining('belum bisa dimuat'), findsNothing);

      server.lepas.complete();
      await tester.pumpAndSettle();
      expect(find.byType(UbinAlatMemuat), findsNothing);
      expect(find.byType(UbinAlat), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(KapsulJatuhTempo),
          matching: find.byType(KontrolKetuk),
        ),
        findsNWidgets(4),
      );
    });

    testWidgets('daftar alat GAGAL: dua kolom, satu catatan, tanpa ubin alat', (
      tester,
    ) async {
      layarHp(tester, lebar: 392, tinggi: 2400);
      await tester.pumpWidget(
        _app(datar()..gagal.add('/alat'), sesi: _sesiSatu()),
      );
      await _sampaiGalat(tester);
      expect(find.textContaining('belum bisa dimuat'), findsOneWidget);
      expect(find.byType(UbinAlat), findsNothing);
      expect(find.byType(UbinAlatMemuat), findsNothing);
      expect(find.text('2 alat lewat jadwal.'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(KapsulJatuhTempo),
          matching: find.byType(KontrolKetuk),
        ),
        findsNWidgets(2),
      );
      expect(find.text('31–60 hari'), findsNothing);
    });
  });

  // ── Ganti perusahaan: daftar alat lama tidak boleh bocor ─────────────────
  group('ganti perusahaan: hitungan daftar alat PT lama', () {
    testWidgets('/beranda PT baru sudah tiba, /alat PT baru belum: alat PT '
        'lama TIDAK tampil di ubin atau kapsul', (tester) async {
      layarHp(tester, lebar: 392, tinggi: 2400);
      final server = _ServerAlatLambat({
        3: DataPerusahaan(nama: 'PT Alfa', alat: _alatMendesak()),
        4: DataPerusahaan(
          nama: 'PT Beta',
          alat: [
            alatJson(31, 'Barometer Beta', hari: -2, status: 'lewat_jadwal'),
          ],
        ),
      });
      await tester.pumpWidget(_app(server));
      await tester.pumpAndSettle();
      // Keadaan awal: ubin alat dan kolom 31-90 hari milik PT Alfa.
      expect(
        find.widgetWithText(UbinAlat, 'Jangka Sorong Digital'),
        findsOneWidget,
      );
      expect(find.text('31–60 hari'), findsOneWidget);

      // Ganti perusahaan; hanya `GET /alat` yang lambat. `jatuhTempoProvider`
      // dimuat ulang (`isReloading`) dan masih memegang nilai PT Alfa.
      server.jedaAlat = const Duration(seconds: 5);
      (_kontainer(tester).read(sesiProvider.notifier) as SesiBisaGanti)
          .pilihPerusahaan(4);
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('PT Beta'), findsOneWidget, reason: 'beranda PT Beta');
      expect(
        find.textContaining('Jangka Sorong'),
        findsNothing,
        reason: 'alat PT Alfa bocor selagi /alat PT Beta dimuat',
      );
      expect(find.byType(UbinAlat), findsNothing);
      expect(
        find.byType(UbinAlatMemuat),
        findsOneWidget,
        reason: 'daftar yang dimuat ulang = kerangka, bukan alat lama',
      );
      expect(
        find.text('31–60 hari'),
        findsNothing,
        reason: 'kolom 31-90 hari dari daftar PT Alfa tidak boleh digambar',
      );

      await _selesaikan(tester);
      expect(find.widgetWithText(UbinAlat, 'Barometer Beta'), findsOneWidget);
      expect(find.byType(UbinAlatMemuat), findsNothing);
    });
  });

  // ── Empat keadaan ─────────────────────────────────────────────────────────
  group('empat keadaan', () {
    testWidgets('memuat: kerangka STATIS berbentuk isi, satu kabar "Memuat"', (
      tester,
    ) async {
      final semantik = tester.ensureSemantics();
      layarHp(tester, lebar: 392, tinggi: 2400);
      final server = _server(alat: [alatJson(1, 'A', hari: 100)])
        ..jeda = const Duration(seconds: 2);
      await tester.pumpWidget(_app(server, sesi: _sesiSatu()));
      await tester.pump(const Duration(milliseconds: 100));
      final kerangka = find.byType(KerangkaBeranda);
      expect(kerangka, findsOneWidget);
      expect(find.bySemanticsLabel('Memuat'), findsOneWidget);
      // Statis: tanpa balok berdenyut, tanpa pewaktu animasi, tanpa teks.
      expect(find.byType(BalokKerangka), findsNothing);
      expect(
        find.descendant(of: kerangka, matching: find.byType(FadeTransition)),
        findsNothing,
      );
      expect(
        find.descendant(of: kerangka, matching: find.byType(Text)),
        findsNothing,
      );
      expect(tester.hasRunningAnimations, isFalse);
      // Bentuknya meniru isi: ubin alat 232 dan baris bantuan lebar penuh.
      final tinggiAwal = tester.getSize(kerangka).height;
      await tester.pump(const Duration(milliseconds: 500));
      expect(tester.hasRunningAnimations, isFalse);
      expect(tester.getSize(kerangka).height, tinggiAwal);
      semantik.dispose();
      await _selesaikan(tester);
    });

    testWidgets('memuat di 320 dp x huruf 1,3 dan di tablet: tanpa luapan', (
      tester,
    ) async {
      final server = _server(alat: [alatJson(1, 'A', hari: 100)])
        ..jeda = const Duration(seconds: 2);
      layarHp(tester, lebar: 320, tinggi: 640);
      await tester.pumpWidget(_app(server, sesi: _sesiSatu(), skala: 1.3));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(KerangkaBeranda), findsOneWidget);
      expect(tester.takeException(), isNull);
      layarTablet(tester);
      await _pasang(tester, _app(server, sesi: _sesiSatu()));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(KerangkaBeranda), findsOneWidget);
      expect(tester.takeException(), isNull);
      await _selesaikan(tester);
    });

    testWidgets('kosong: kalimat, ubin kosong kuning, pasangan dan bantuan '
        'tetap ada; tanpa tombol, panel, atau pil', (tester) async {
      layarHp(tester, lebar: 392, tinggi: 2400);
      await tester.pumpWidget(_app(_server(), sesi: _sesiSatu()));
      await tester.pumpAndSettle();
      expect(find.text('Belum ada alat.'), findsOneWidget);
      final kosong = find.widgetWithText(
        UbinRingkas,
        'Belum ada alat terdaftar',
      );
      expect(kosong, findsOneWidget);
      expect(_latarUbin(tester, kosong), _w(false).ubinAwas);
      expect(
        find.text('Alat yang pernah dikalibrasi di PT Sidik muncul di sini.'),
        findsOneWidget,
      );
      expect(find.byType(UbinAlat), findsNothing);
      expect(find.byType(TombolSidik), findsNothing);
      expect(find.byType(KapsulJatuhTempo), findsNothing);
      expect(find.text('Sertifikat terbaru'), findsOneWidget);
      expect(find.text('Butuh bantuan? Hubungi lab'), findsOneWidget);
      // Tidak ada klaim "berlaku" apa pun.
      expect(find.textContaining('berlaku'), findsNothing);
    });

    testWidgets(
      'galat: kepala, kalimat langkah berikutnya, Coba lagi memulihkan',
      (tester) async {
        layarHp(tester, lebar: 392, tinggi: 2400);
        final server = _server(alat: [alatJson(1, 'A', hari: 100)])
          ..gagal.add('/beranda');
        await tester.pumpWidget(_app(server, sesi: _sesiSatu()));
        await _sampaiGalat(tester);
        expect(find.byType(KeadaanTeks), findsOneWidget);
        expect(find.text('Beranda belum bisa dimuat'), findsOneWidget);
        expect(find.text('Rina Wulandari'), findsOneWidget);
        expect(find.byType(UbinAlat), findsNothing);
        expect(find.byType(KapsulJatuhTempo), findsNothing);
        expect(find.text('Coba lagi'), findsOneWidget);

        server.gagal.clear();
        await tester.tap(find.text('Coba lagi'));
        await tester.pump();
        await tester.pumpAndSettle();
        expect(find.byType(KeadaanTeks), findsNothing);
        expect(find.byType(KapsulJatuhTempo), findsOneWidget);
      },
    );

    testWidgets('tanpa koneksi: pil navy + ikon wifi coret + kata, data '
        'terakhir tetap terbaca', (tester) async {
      final semantik = tester.ensureSemantics();
      layarHp(tester, lebar: 392, tinggi: 2400);
      await tester.pumpWidget(
        _app(_server(alat: _alatMendesak()), sesi: _sesiSatu()),
      );
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.wifi_off), findsNothing);

      _kontainer(
        tester,
      ).read(koneksiProvider.notifier).offline(DateTime(2026, 11, 12, 8, 12));
      await tester.pump();
      expect(find.text('Offline. Data per 08.12.'), findsOneWidget);
      expect(find.byIcon(Icons.wifi_off), findsOneWidget);
      final pil = find.ancestor(
        of: find.text('Offline. Data per 08.12.'),
        matching: find.byType(DecoratedBox),
      );
      final dekor =
          tester.widget<DecoratedBox>(pil.first).decoration as BoxDecoration;
      expect(dekor.color, _s(false).primary);
      expect(tester.getSize(pil.first).height, greaterThanOrEqualTo(48));
      final d = tester
          .getSemantics(find.bySemanticsLabel('Offline. Data per 08.12.'))
          .getSemanticsData();
      expect(d.flagsCollection.isLiveRegion, isTrue);
      // Data terakhir tetap terbaca di bawah banner.
      expect(find.text('2 alat lewat jadwal.'), findsOneWidget);
      expect(find.byType(UbinAlat), findsOneWidget);
      semantik.dispose();
    });

    testWidgets('tanpa koneksi dan galat: banner di atas teks galat', (
      tester,
    ) async {
      layarHp(tester, lebar: 392, tinggi: 2400);
      await tester.pumpWidget(
        _app(_server()..gagal.add('/beranda'), sesi: _sesiSatu()),
      );
      await _sampaiGalat(tester);
      _kontainer(tester).read(koneksiProvider.notifier).offline(null);
      await tester.pump();
      expect(find.text('Offline. Data mungkin sudah lama.'), findsOneWidget);
      expect(find.text('Beranda belum bisa dimuat'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('Offline. Data mungkin sudah lama.')).dy,
        lessThan(tester.getTopLeft(find.text('Beranda belum bisa dimuat')).dy),
      );
    });
  });

  // ── Gerak, skala huruf, target sentuh, tema gelap ────────────────────────
  group('gerak masuk', () {
    testWidgets('gerak normal: ubin masuk dengan animasi; kurangi gerak: '
        'langsung akhir', (tester) async {
      layarHp(tester, lebar: 392, tinggi: 2400);
      final masukUbin = find.ancestor(
        of: find.byType(UbinAlat),
        matching: find.byType(MasukBerurutan),
      );
      double opasitas(WidgetTester t) => t
          .widget<FadeTransition>(
            find
                .descendant(
                  of: masukUbin.first,
                  matching: find.byType(FadeTransition),
                )
                .first,
          )
          .opacity
          .value;

      await tester.pumpWidget(
        _app(_server(alat: _alatMendesak()), sesi: _sesiSatu()),
      );
      await _sampaiUbin(tester);
      await tester.pump(const Duration(milliseconds: 10));
      expect(find.byType(UbinAlat), findsOneWidget);
      expect(opasitas(tester), lessThan(1));
      await tester.pumpAndSettle();
      expect(opasitas(tester), 1);

      await _pasang(
        tester,
        _app(
          _server(alat: _alatMendesak()),
          sesi: _sesiSatu(),
          kurangiGerak: true,
        ),
      );
      await _sampaiUbin(tester);
      expect(find.byType(UbinAlat), findsOneWidget);
      expect(opasitas(tester), 1, reason: 'kurangi gerak: tanpa animasi');
    });

    testWidgets('disegarkan: animasi masuk TIDAK terulang; dibuat ulang '
        '(ganti perusahaan): langsung tampil', (tester) async {
      layarHp(tester, lebar: 392, tinggi: 900);
      final server = ServerFitur({
        3: DataPerusahaan(nama: 'PT Alfa', alat: _alatMendesak()),
        4: DataPerusahaan(
          nama: 'PT Beta',
          alat: [
            alatJson(31, 'Barometer Beta', hari: -2, status: 'lewat_jadwal'),
          ],
        ),
      });
      await tester.pumpWidget(_app(server));
      await tester.pumpAndSettle();
      final masukUbin = find.ancestor(
        of: find.byType(UbinAlat),
        matching: find.byType(MasukBerurutan),
      );
      expect(
        masukUbin,
        findsOneWidget,
        reason: 'pertama kali: ada animasi masuk',
      );

      // Tarik-untuk-segarkan sungguhan: data dimuat ulang, ubin yang ada
      // tidak boleh menyala dari nol lagi (opasitas tidak pernah turun).
      final sebelum = server.yang('GET', '/alat').length;
      server.jeda = const Duration(seconds: 1);
      await tester.fling(
        find.byType(ListView).first,
        const Offset(0, 400),
        1000,
      );
      for (var i = 0; i < 40; i++) {
        await tester.pump(const Duration(milliseconds: 100));
        for (final e
            in find
                .descendant(
                  of: masukUbin,
                  matching: find.byType(FadeTransition),
                )
                .evaluate()) {
          expect(
            (e.widget as FadeTransition).opacity.value,
            1,
            reason: 'frame $i: animasi masuk terulang saat disegarkan',
          );
        }
      }
      await tester.pumpAndSettle();
      expect(server.yang('GET', '/alat').length, greaterThan(sebelum));

      // Berganti perusahaan: Beranda jadi kerangka lalu ubin LAHIR ULANG;
      // yang lahir ulang langsung tampil, tanpa animasi masuk.
      server.jeda = const Duration(seconds: 1);
      (_kontainer(tester).read(sesiProvider.notifier) as SesiBisaGanti)
          .pilihPerusahaan(4);
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(UbinAlat), findsNothing, reason: 'sedang dimuat');
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(seconds: 1));
      }
      await tester.pumpAndSettle();
      expect(find.text('Barometer Beta'), findsOneWidget);
      expect(masukUbin, findsNothing, reason: 'lahir ulang: tanpa animasi');
    });
  });

  group('skala huruf 1,3 di 320 dp, tablet, dan tema gelap', () {
    final penuh = ServerFitur({
      3: DataPerusahaan(
        nama: 'PT Instrumentasi Presisi Nusantara Sejahtera Abadi',
        alat: [
          alatJson(
            1,
            'Digital Pressure Calibrator Multifungsi Presisi Tinggi',
            hari: -365,
            status: 'lewat_jadwal',
            merk: 'Fluke Calibration International',
            serial: 'SN-2026-0000000000000001',
            sedangDikerjakan: sedangDikerjakanJson(
              tahap: 'menunggu_pemeriksaan',
              label: 'Hasil sedang diperiksa oleh penyelia laboratorium',
            ),
          ),
          alatJson(2, 'Timbangan', hari: 12, status: 'mendekati_jadwal'),
          alatJson(3, 'Termometer', hari: 45),
        ],
        sertifikat: [
          sertifikatJson(
            9,
            'CAL/2026/09/000123-REV.2',
            namaAlat: 'Digital Pressure Calibrator Multifungsi',
            keputusan: 'FAIL',
            diterbitkan: -2,
          ),
        ],
        paket: [
          paketJson(
            21,
            'ORD/2026/11/000777-PANJANG',
            tahap: 'diterima',
            label: 'Alat diterima lab dan menunggu giliran kalibrasi',
            terlambat: true,
          ),
        ],
        jumlahPaketBerjalan: 6,
      ),
    });

    testWidgets('320 x 1,3: seluruh isi digulir tanpa luapan; sentuh >= 48', (
      tester,
    ) async {
      layarHp(tester, lebar: 320, tinggi: 640);
      await tester.pumpWidget(_app(penuh, skala: 1.3));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      for (var i = 0; i < 12; i++) {
        await tester.drag(find.byType(ListView).first, const Offset(0, -300));
        await tester.pump();
        expect(tester.takeException(), isNull, reason: 'gulir ke-$i');
      }
      await tester.pumpAndSettle();
      // Ubin pasangan bertumpuk di bawah 340 dp: lebar sama dengan kolom.
      final sert = tester.getRect(
        find.widgetWithText(UbinRingkas, 'Sertifikat terbaru'),
      );
      final pak = tester.getRect(
        find.widgetWithText(UbinRingkas, 'Paket dikerjakan'),
      );
      expect(pak.top, greaterThan(sert.bottom));
      expect(sert.width, closeTo(320 - 32, 1));
      for (final e in find.byType(KontrolKetuk).evaluate()) {
        final u = tester.getSize(find.byWidget(e.widget));
        expect(u.width, greaterThanOrEqualTo(48));
        expect(u.height, greaterThanOrEqualTo(48));
      }
    });

    testWidgets('nama PT panjang: satu baris dengan elipsis di 320 x 1,3', (
      tester,
    ) async {
      layarHp(tester, lebar: 320, tinggi: 640);
      await tester.pumpWidget(_app(penuh, skala: 1.3));
      await tester.pumpAndSettle();
      const nama = 'PT Instrumentasi Presisi Nusantara Sejahtera Abadi';
      expect(tester.getSize(find.text(nama)).height, lessThan(26));
      expect(
        tester.getSize(find.text(nama)).width,
        lessThanOrEqualTo(320 * 0.45),
      );
    });

    testWidgets('pedoman Flutter: sasaran sentuh 48 dan label, HP dan 1,3x', (
      tester,
    ) async {
      final semantik = tester.ensureSemantics();
      layarHp(tester, lebar: 392, tinggi: 2400);
      await tester.pumpWidget(_app(penuh, sesi: _sesiSatu()));
      await tester.pumpAndSettle();
      await periksaPedomanSentuh(tester);
      layarHp(tester, lebar: 320, tinggi: 2400);
      await _pasang(tester, _app(penuh, skala: 1.3));
      await tester.pumpAndSettle();
      await periksaPedomanSentuh(tester);
      semantik.dispose();
    });

    testWidgets('tablet: dua kolom (ubin + tombol kiri; panel + pasangan '
        'kanan), bantuan penuh di bawah', (tester) async {
      layarTablet(tester);
      await tester.pumpWidget(_app(penuh, sesi: _sesiSatu()));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final ubin = tester.getTopLeft(find.byType(UbinAlat));
      final tombol = tester.getTopLeft(find.byType(TombolSidik));
      final panel = tester.getTopLeft(find.byType(KapsulJatuhTempo));
      final sert = tester.getTopLeft(
        find.widgetWithText(UbinRingkas, 'Sertifikat terbaru'),
      );
      final bantuan = tester.getTopLeft(
        find.text('Butuh bantuan? Hubungi lab'),
      );
      expect(tombol.dx, closeTo(ubin.dx, 1));
      expect(panel.dx, greaterThan(ubin.dx + 200));
      expect(sert.dx, greaterThan(ubin.dx + 200));
      expect(bantuan.dx, lessThan(panel.dx));
      expect(bantuan.dy, greaterThan(sert.dy));
    });

    testWidgets('HP 392: satu kolom menurun', (tester) async {
      layarHp(tester, lebar: 392, tinggi: 2600);
      await tester.pumpWidget(_app(penuh, sesi: _sesiSatu()));
      await tester.pumpAndSettle();
      final y = [
        for (final f in [
          find.byType(KalimatUtama),
          find.byType(UbinAlat),
          find.byType(TombolSidik),
          find.byType(KapsulJatuhTempo),
          find.widgetWithText(UbinRingkas, 'Sertifikat terbaru'),
          find.text('Butuh bantuan? Hubungi lab'),
        ])
          tester.getTopLeft(f).dy,
      ];
      expect([...y]..sort(), y, reason: 'urutan atas ke bawah sesuai LAYAR.md');
      // Pasangan berdampingan di 392.
      expect(
        tester
            .getTopLeft(find.widgetWithText(UbinRingkas, 'Paket dikerjakan'))
            .dy,
        tester
            .getTopLeft(find.widgetWithText(UbinRingkas, 'Sertifikat terbaru'))
            .dy,
      );
    });

    testWidgets(
      'tema gelap: kartu alat mengikuti permukaan tema, ubin ringkasan '
      'tetap muda, tanpa luapan, teks terbaca',
      (tester) async {
        layarHp(tester, lebar: 392, tinggi: 2600);
        await tester.pumpWidget(_app(penuh, sesi: _sesiSatu(), gelap: true));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(_latarUbin(tester, find.byType(UbinAlat)), _s(true).surface);
        expect(_w(true).ubinGagal, _w(false).ubinGagal);
        expect(pelanggaranKontrasTeks(tester, find.byType(UbinAlat)), isEmpty);
        expect(
          pelanggaranKontrasTeks(tester, find.byType(KapsulJatuhTempo)),
          isEmpty,
        );
        expect(
          pelanggaranKontrasTeks(
            tester,
            find.widgetWithText(UbinRingkas, 'Sertifikat terbaru'),
          ),
          isEmpty,
        );
        expect(
          pelanggaranKontrasTeks(tester, find.byType(KalimatUtama)),
          isEmpty,
        );
      },
    );

    testWidgets('tema terang: kontras ubin, kalimat, bantuan, banner offline', (
      tester,
    ) async {
      layarHp(tester, lebar: 392, tinggi: 2600);
      await tester.pumpWidget(_app(penuh, sesi: _sesiSatu()));
      await tester.pumpAndSettle();
      _kontainer(tester).read(koneksiProvider.notifier).offline(null);
      await tester.pump();
      expect(pelanggaranKontrasTeks(tester, find.byType(UbinAlat)), isEmpty);
      expect(
        pelanggaranKontrasTeks(tester, find.byType(KalimatUtama)),
        isEmpty,
      );
      expect(
        pelanggaranKontrasTeks(
          tester,
          find
              .ancestor(
                of: find.text('Offline. Data mungkin sudah lama.'),
                matching: find.byType(DecoratedBox),
              )
              .first,
        ),
        isEmpty,
      );
      expect(
        pelanggaranKontrasTeks(
          tester,
          find.ancestor(
            of: find.text('Butuh bantuan? Hubungi lab'),
            matching: find.byType(KontrolKetuk),
          ),
        ),
        isEmpty,
      );
    });
  });
}
