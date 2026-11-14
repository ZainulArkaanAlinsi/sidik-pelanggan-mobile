// Provider saklar notifikasi: memuat, mengubah (optimistis), gagal dan
// pulihkan, balapan ketukan, baca-saja, data dari simpanan HP, penutupan layar
// di tengah simpan, dan pergantian perusahaan di tengah simpan.

import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:sidik_pelanggan/core/api_pelanggan.dart';
import 'package:sidik_pelanggan/core/penyimpan_cache.dart';
import 'package:sidik_pelanggan/models/preferensi_notifikasi.dart';
import 'package:sidik_pelanggan/providers/koneksi_provider.dart';
import 'package:sidik_pelanggan/providers/preferensi_notifikasi_provider.dart';
import 'package:sidik_pelanggan/providers/sesi_provider.dart';
import 'package:sidik_pelanggan/services/layanan_pelanggan.dart';

import 'dukungan/dukungan.dart';
import 'dukungan/fixture_fitur.dart';
import 'dukungan/layanan_preferensi_palsu.dart';

ProviderContainer _wadah(
  LayananPelanggan layanan, {
  Sesi? sesi,
  bool sesiBisaGanti = false,
}) {
  final c = ProviderContainer(
    overrides: overrideDasar(
      tambahan: [
        layananProvider.overrideWithValue(layanan),
        if (sesiBisaGanti)
          sesiProvider.overrideWith(
            () => SesiBisaGanti(sesi ?? sesiDuaPerusahaan()),
          )
        else
          sesiTetap(sesi ?? sesiUji()),
      ],
    ),
  );
  addTearDown(c.dispose);
  return c;
}

/// Pasang pendengar supaya provider autoDispose tetap hidup, lalu tunggu muat.
Future<KeadaanPreferensi> _muat(ProviderContainer c) async {
  // Sesi sudah termuat saat layar ini dibuka di aplikasi sungguhan.
  await c.read(sesiProvider.future);
  c.listen(preferensiNotifikasiProvider, (_, _) {});
  return c.read(preferensiNotifikasiProvider.future);
}

KeadaanPreferensi _kini(ProviderContainer c) =>
    c.read(preferensiNotifikasiProvider).requireValue;

PreferensiNotifikasiController _aksi(ProviderContainer c) =>
    c.read(preferensiNotifikasiProvider.notifier);

Future<void> _giliran() => Future<void>.delayed(Duration.zero);

void main() {
  group('memuat', () {
    test('lima kunci kontrak: yang dikenal tampil, pesan_lab tidak', () async {
      final c = _wadah(LayananPreferensiPalsu());
      final k = await _muat(c);

      expect(k.nilai, {
        'pengingat_jadwal': true,
        'status_permintaan': true,
        'tahap_alat': true,
        'ringkasan_email_mingguan': false,
      });
      expect(k.nilai.containsKey('pesan_lab'), isFalse);
      expect(k.bisaUbah, isTrue);
      expect(k.dariCache, isFalse);
      expect(k.alasanBacaSaja, isNull);
    });

    test(
      'kategori tak dikenal dari server diabaikan, tidak menjatuhkan',
      () async {
        final palsu = LayananPreferensiPalsu()
          ..jawabanMuat = {
            ...LayananPreferensiPalsu.kunciKontrak,
            'kategori_masa_depan': true,
            'x': false,
          };
        final c = _wadah(palsu);
        final k = await _muat(c);

        expect(k.nilai.keys, isNot(contains('kategori_masa_depan')));
        expect(k.nilai.keys, isNot(contains('x')));
        expect(k.nilai.length, 4);
        // Dan tidak pernah bisa diubah dari aplikasi.
        _aksi(c).ubah('kategori_masa_depan', false);
        await _giliran();
        expect(palsu.panggilan, isEmpty);
      },
    );

    test(
      'kunci dikenal yang tidak dikirim server tidak ada di state',
      () async {
        final palsu = LayananPreferensiPalsu()
          ..jawabanMuat = {'pengingat_jadwal': false};
        final c = _wadah(palsu);
        final k = await _muat(c);

        expect(k.nilai, {'pengingat_jadwal': false});
        _aksi(c).ubah('tahap_alat', false);
        await _giliran();
        expect(
          palsu.panggilan,
          isEmpty,
          reason: 'server lama tanpa tahap_alat',
        );
      },
    );

    test('galat memuat tidak diulang otomatis', () async {
      final palsu = LayananPreferensiPalsu()..galatMuat = galatJaringan();
      final c = _wadah(palsu);
      await c.read(sesiProvider.future);
      c.listen(preferensiNotifikasiProvider, (_, _) {});
      await expectLater(
        c.read(preferensiNotifikasiProvider.future),
        throwsA(isA<GalatApi>()),
      );
      // Bawaan Riverpod 3 mengulang dengan jeda 200 ms dst.
      await Future<void>.delayed(const Duration(milliseconds: 700));
      expect(palsu.muat, 1);
      expect(c.read(preferensiNotifikasiProvider).hasError, isTrue);
    });
  });

  group('mengubah', () {
    test('optimistis: tampil dulu, badan PUT hanya satu kunci', () async {
      final palsu = LayananPreferensiPalsu()..tahan = true;
      final c = _wadah(palsu);
      await _muat(c);

      _aksi(c).ubah('tahap_alat', false);
      // Belum ada jawaban server, nilai sudah berubah.
      expect(_kini(c).nilai['tahap_alat'], isFalse);
      expect(_kini(c).tahapDari('tahap_alat'), TahapSimpan.menyimpan);
      expect(palsu.badan, [
        {'tahap_alat': false},
      ]);

      palsu.selesaikan(0);
      await _giliran();
      expect(_kini(c).nilai['tahap_alat'], isFalse);
      expect(_kini(c).tahapDari('tahap_alat'), TahapSimpan.diam);
      expect(palsu.server['tahap_alat'], isFalse);
    });

    test(
      'ketukan pada nilai yang sama dengan yang tampil tidak mengirim',
      () async {
        final palsu = LayananPreferensiPalsu();
        final c = _wadah(palsu);
        await _muat(c);

        _aksi(c).ubah('tahap_alat', true);
        await _giliran();
        expect(palsu.panggilan, isEmpty);
      },
    );

    test(
      'gagal: HANYA kunci itu kembali, kunci lain utuh, ada alasan',
      () async {
        final palsu = LayananPreferensiPalsu()
          ..tahan = true
          ..rencanaGalat.addAll([null, galatJaringan()]);
        final c = _wadah(palsu);
        await _muat(c);

        _aksi(c).ubah('pengingat_jadwal', false); // berhasil
        _aksi(c).ubah('tahap_alat', false); // gagal
        palsu.selesaikan(0);
        palsu.selesaikan(1);
        await _giliran();

        final k = _kini(c);
        expect(
          k.nilai['pengingat_jadwal'],
          isFalse,
          reason: 'yang berhasil tetap',
        );
        expect(
          k.nilai['tahap_alat'],
          isTrue,
          reason: 'yang gagal dikembalikan',
        );
        expect(k.tahapDari('tahap_alat'), TahapSimpan.gagal);
        expect(k.pesanGagal['tahap_alat'], startsWith('Belum tersimpan.'));
        expect(k.pesanGagal['tahap_alat'], contains('Tidak ada sambungan'));
        expect(k.tahapDari('pengingat_jadwal'), TahapSimpan.diam);
        expect(k.alasanBacaSaja, isNull);
        expect(
          palsu.server['tahap_alat'],
          isTrue,
          reason: 'server tak berubah',
        );
      },
    );

    test(
      'A gagal SELAGI B masih jalan: B tetap tampil nilai barunya',
      () async {
        final palsu = LayananPreferensiPalsu()
          ..tahan = true
          ..rencanaGalat.addAll([galatHttp(500, 'x'), null]);
        final c = _wadah(palsu);
        await _muat(c);

        _aksi(c).ubah('pengingat_jadwal', false); // PUT 0: gagal
        _aksi(c).ubah('ringkasan_email_mingguan', true); // PUT 1: masih ditahan
        palsu.selesaikan(0);
        await _giliran();
        await _giliran();

        final k = _kini(c);
        expect(k.tahapDari('pengingat_jadwal'), TahapSimpan.gagal);
        expect(k.nilai['pengingat_jadwal'], isTrue);
        expect(k.tahapDari('ringkasan_email_mingguan'), TahapSimpan.menyimpan);
        expect(
          k.nilai['ringkasan_email_mingguan'],
          isTrue,
          reason:
              'kegagalan A tidak boleh memulihkan saklar B yang masih jalan',
        );

        palsu.selesaikan(1);
        await _giliran();
        expect(
          _kini(c).tahapDari('ringkasan_email_mingguan'),
          TahapSimpan.diam,
        );
        expect(_kini(c).nilai['ringkasan_email_mingguan'], isTrue);
      },
    );

    test('sesudah gagal, ketuk lagi: kirim ulang dan alasan hilang', () async {
      final palsu = LayananPreferensiPalsu()
        ..rencanaGalat.add(galatHttp(500, 'Terjadi kendala di server.'));
      final c = _wadah(palsu);
      await _muat(c);

      _aksi(c).ubah('tahap_alat', false);
      await _giliran();
      expect(_kini(c).tahapDari('tahap_alat'), TahapSimpan.gagal);
      expect(_kini(c).pesanGagal['tahap_alat'], contains('kendala di server'));

      _aksi(c).ubah('tahap_alat', false);
      await _giliran();
      expect(palsu.panggilan, hasLength(2));
      expect(_kini(c).nilai['tahap_alat'], isFalse);
      expect(_kini(c).tahapDari('tahap_alat'), TahapSimpan.diam);
      expect(_kini(c).pesanGagal, isEmpty);
    });

    test('kalimat gagal menurut jenis galat', () {
      expect(pesanGagalSimpan(galatHttp(429)), contains('Terlalu sering'));
      expect(pesanGagalSimpan(galatHttp(422)), contains('ditolak server'));
      expect(
        pesanGagalSimpan(galatJaringan()),
        contains('Tidak ada sambungan'),
      );
      expect(
        pesanGagalSimpan(galatHttp(500, 'Kendala.')),
        'Belum tersimpan. Kendala.',
      );
      expect(pesanGagalSimpan(StateError('x')), startsWith('Belum tersimpan.'));
    });

    test(
      '403: layar jadi baca-saja, nilai kembali, ketukan berikut diabaikan',
      () async {
        final palsu = LayananPreferensiPalsu()
          ..rencanaGalat.add(galatHttp(403, 'Akun ini belum boleh.'));
        final c = _wadah(palsu);
        await _muat(c);

        _aksi(c).ubah('tahap_alat', false);
        await _giliran();

        final k = _kini(c);
        expect(k.alasanBacaSaja, alasanTanpaIzinUbah);
        expect(k.bisaUbah, isFalse);
        expect(k.nilai['tahap_alat'], isTrue);
        expect(
          k.pesanGagal,
          isEmpty,
          reason: 'alasannya satu, di tingkat layar',
        );

        _aksi(c).ubah('pengingat_jadwal', false);
        await _giliran();
        expect(palsu.panggilan, hasLength(1));
        expect(_kini(c).nilai['pengingat_jadwal'], isTrue);
      },
    );
  });

  group('balapan ketukan', () {
    test('dua kunci: jawaban A (tanpa B) tidak menimpa ketukan B', () async {
      final palsu = LayananPreferensiPalsu()..tahan = true;
      final c = _wadah(palsu);
      await _muat(c);

      _aksi(c).ubah('pengingat_jadwal', false); // A
      _aksi(c).ubah('ringkasan_email_mingguan', true); // B
      // Server memproses A lebih dulu: jawaban A memuat B yang MASIH lama.
      expect(palsu.panggilan[0].jawaban!['ringkasan_email_mingguan'], isFalse);

      palsu.selesaikan(0);
      await _giliran();
      expect(_kini(c).nilai['pengingat_jadwal'], isFalse);
      expect(
        _kini(c).nilai['ringkasan_email_mingguan'],
        isTrue,
        reason:
            'ketukan B masih menunggu dan tidak boleh kembali ke nilai lama',
      );
      expect(
        _kini(c).tahapDari('ringkasan_email_mingguan'),
        TahapSimpan.menyimpan,
      );

      palsu.selesaikan(1);
      await _giliran();
      expect(_kini(c).nilai['ringkasan_email_mingguan'], isTrue);
      expect(_kini(c).tahapDari('ringkasan_email_mingguan'), TahapSimpan.diam);
      expect(_kini(c).nilai['pengingat_jadwal'], isFalse);
    });

    test('dua kunci, jawaban terbalik: akhirnya sama dengan server', () async {
      final palsu = LayananPreferensiPalsu()..tahan = true;
      final c = _wadah(palsu);
      await _muat(c);

      _aksi(c).ubah('pengingat_jadwal', false);
      _aksi(c).ubah('ringkasan_email_mingguan', true);
      palsu.selesaikan(1);
      await _giliran();
      palsu.selesaikan(0);
      await _giliran();

      for (final e in _kini(c).nilai.entries) {
        expect(e.value, palsu.server[e.key], reason: e.key);
      }
      expect(_kini(c).tahap.values.every((t) => t == TahapSimpan.diam), isTrue);
    });

    test(
      'satu kunci dua kali cepat: SATU PUT berjalan, nilai akhir menang',
      () async {
        final palsu = LayananPreferensiPalsu()..tahan = true;
        final c = _wadah(palsu);
        await _muat(c);

        _aksi(c).ubah('tahap_alat', false);
        _aksi(c).ubah('tahap_alat', true);
        _aksi(c).ubah('tahap_alat', false);
        expect(
          palsu.panggilan,
          hasLength(1),
          reason: 'tidak ada PUT bersamaan',
        );
        expect(_kini(c).nilai['tahap_alat'], isFalse);

        palsu.selesaikan(0);
        await _giliran();
        // Nilai terbaru (false) sama dengan yang baru dikonfirmasi: selesai.
        expect(palsu.panggilan, hasLength(1));
        expect(_kini(c).tahapDari('tahap_alat'), TahapSimpan.diam);
        expect(palsu.server['tahap_alat'], isFalse);
      },
    );

    test(
      'satu kunci berbalik di tengah: PUT kedua dikirim sesudah jawaban pertama',
      () async {
        final palsu = LayananPreferensiPalsu()..tahan = true;
        final c = _wadah(palsu);
        await _muat(c);

        _aksi(c).ubah('tahap_alat', false);
        _aksi(c).ubah('tahap_alat', true);
        expect(palsu.panggilan, hasLength(1));

        palsu.selesaikan(0);
        await _giliran();
        expect(palsu.badan, [
          {'tahap_alat': false},
          {'tahap_alat': true},
        ], reason: 'berurutan, bukan bersamaan');
        expect(
          _kini(c).nilai['tahap_alat'],
          isTrue,
          reason: 'jawaban pertama tidak menimpa ketukan kedua',
        );
        expect(_kini(c).tahapDari('tahap_alat'), TahapSimpan.menyimpan);

        palsu.selesaikan(1);
        await _giliran();
        expect(_kini(c).nilai['tahap_alat'], isTrue);
        expect(_kini(c).tahapDari('tahap_alat'), TahapSimpan.diam);
        expect(palsu.server['tahap_alat'], isTrue);
      },
    );

    test(
      'PUT pertama gagal selagi ketukan kedua menunggu: kembali ke yang dikonfirmasi',
      () async {
        final palsu = LayananPreferensiPalsu()
          ..tahan = true
          ..rencanaGalat.add(galatHttp(500));
        final c = _wadah(palsu);
        await _muat(c);

        _aksi(c).ubah('tahap_alat', false);
        _aksi(c).ubah('tahap_alat', true);
        _aksi(c).ubah('tahap_alat', false);
        palsu.selesaikan(0);
        await _giliran();

        expect(
          palsu.panggilan,
          hasLength(1),
          reason: 'tidak mengirim ketukan basi',
        );
        expect(
          _kini(c).nilai['tahap_alat'],
          isTrue,
          reason: 'nilai dikonfirmasi server',
        );
        expect(_kini(c).tahapDari('tahap_alat'), TahapSimpan.gagal);
        expect(palsu.server['tahap_alat'], isTrue);
      },
    );

    test(
      'kunci A gagal, B berhasil, jawaban bersilang: masing-masing benar',
      () async {
        final palsu = LayananPreferensiPalsu()
          ..tahan = true
          ..rencanaGalat.addAll([galatHttp(429), null]);
        final c = _wadah(palsu);
        await _muat(c);

        _aksi(c).ubah('pengingat_jadwal', false); // gagal
        _aksi(c).ubah('ringkasan_email_mingguan', true); // berhasil
        palsu.selesaikan(1);
        await _giliran();
        palsu.selesaikan(0);
        await _giliran();

        expect(_kini(c).nilai['pengingat_jadwal'], isTrue);
        expect(_kini(c).tahapDari('pengingat_jadwal'), TahapSimpan.gagal);
        expect(
          _kini(c).pesanGagal['pengingat_jadwal'],
          contains('Terlalu sering'),
        );
        expect(_kini(c).nilai['ringkasan_email_mingguan'], isTrue);
        expect(
          _kini(c).tahapDari('ringkasan_email_mingguan'),
          TahapSimpan.diam,
        );
      },
    );

    test('jawaban hanya dipercaya untuk kunci yang dikirim', () async {
      final palsu = LayananPreferensiPalsu();
      final c = _wadah(palsu);
      await _muat(c);

      // HP lain mematikan pengingat: jawaban PUT ini membawanya, tetapi layar
      // ini tidak menyentuh kunci itu (terbaca saat layar dibuka lagi).
      palsu.server = {...palsu.server, 'pengingat_jadwal': false};
      _aksi(c).ubah('tahap_alat', false);
      await _giliran();

      expect(_kini(c).nilai['tahap_alat'], isFalse);
      expect(_kini(c).nilai['pengingat_jadwal'], isTrue);
    });

    test(
      'server mengoreksi nilai kunci yang dikirim: layar mengikuti server',
      () async {
        final palsu = LayananPreferensiPalsu()
          ..jawabanPaksa = {'tahap_alat': true};
        final c = _wadah(palsu);
        await _muat(c);

        _aksi(c).ubah('tahap_alat', false);
        await _giliran();

        expect(_kini(c).nilai['tahap_alat'], isTrue);
        expect(_kini(c).tahapDari('tahap_alat'), TahapSimpan.diam);
      },
    );
  });

  group('cache GET sesudah menyimpan (write-through)', () {
    test(
      'tiap simpan yang dikonfirmasi mencatat set lengkap, kunci tak digambar utuh',
      () async {
        final palsu = LayananPreferensiPalsu();
        final c = _wadah(palsu);
        await _muat(c);

        _aksi(c).ubah('tahap_alat', false);
        await _giliran();

        expect(palsu.dicatat, hasLength(1));
        expect(palsu.dicatat.single, {
          'pengingat_jadwal': true,
          'status_permintaan': true,
          'pesan_lab': true,
          'ringkasan_email_mingguan': false,
          'tahap_alat': false,
        });
      },
    );

    test(
      'dua kunci, jawaban bersilang: yang dicatat keadaan lokal, bukan jawaban usang',
      () async {
        final palsu = LayananPreferensiPalsu()..tahan = true;
        final c = _wadah(palsu);
        await _muat(c);

        _aksi(c).ubah('pengingat_jadwal', false); // A
        _aksi(c).ubah('ringkasan_email_mingguan', true); // B
        palsu.selesaikan(1);
        await _giliran();
        palsu.selesaikan(0); // jawaban A (membawa B lama) tiba terakhir
        await _giliran();

        expect(palsu.dicatat.last['pengingat_jadwal'], isFalse);
        expect(palsu.dicatat.last['ringkasan_email_mingguan'], isTrue);
      },
    );

    test('simpan yang gagal tidak mencatat apa pun', () async {
      final palsu = LayananPreferensiPalsu()..rencanaGalat.add(galatHttp(500));
      final c = _wadah(palsu);
      await _muat(c);

      _aksi(c).ubah('tahap_alat', false);
      await _giliran();

      expect(palsu.dicatat, isEmpty);
    });

    test(
      'ujung ke ujung: simpan, lalu offline, lalu buka lagi: tampil pilihan terakhir',
      () async {
        var putus = false;
        var tahapAlat = true;
        final klien = MockClient((r) async {
          if (putus) throw http.ClientException('putus');
          if (r.method == 'PUT') {
            final badan = jsonDecode(r.body) as Map<String, dynamic>;
            tahapAlat = badan['tahap_alat'] as bool? ?? tahapAlat;
          }
          return http.Response(
            jsonEncode({
              'data': {
                ...LayananPreferensiPalsu.kunciKontrak,
                'tahap_alat': tahapAlat,
              },
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        });
        late final ProviderContainer c;
        final api = ApiPelanggan(
          klien: klien,
          token: 'tkn-uji',
          perusahaanId: 3,
          cache: PenyimpanCacheMemori(),
          lingkupCache: 'u7',
          jedaUlang: const [],
          saatOffline: (d) => c.read(koneksiProvider.notifier).offline(d),
          saatOnline: () => c.read(koneksiProvider.notifier).online(),
        );
        c = ProviderContainer(
          overrides: overrideDasar(
            tambahan: [
              apiProvider.overrideWithValue(api),
              sesiTetap(sesiUji()),
            ],
          ),
        );
        addTearDown(c.dispose);

        expect((await _muat(c)).nilai['tahap_alat'], isTrue);
        _aksi(c).ubah('tahap_alat', false);
        await _giliran();
        await _giliran();
        expect(_kini(c).tahapDari('tahap_alat'), TahapSimpan.diam);

        // Sambungan putus; layar dibuka lagi (dibangun ulang dari nol).
        putus = true;
        c.invalidate(preferensiNotifikasiProvider);
        final k = await c.read(preferensiNotifikasiProvider.future);

        expect(k.dariCache, isTrue);
        expect(
          k.nilai['tahap_alat'],
          isFalse,
          reason: 'cache GET harus memuat pilihan terakhir yang dikonfirmasi',
        );
      },
    );
  });

  group('data dari simpanan HP (offline)', () {
    test('GET yang disajikan dari cache: baca-saja dengan waktunya', () async {
      final c = _wadah(LayananPreferensiPalsu());
      final waktu = DateTime(2026, 11, 13, 8, 30);
      c.read(koneksiProvider.notifier).offline(waktu);
      final k = await _muat(c);

      expect(k.dataTerakhir, waktu);
      expect(k.dariCache, isTrue);
      expect(k.bisaUbah, isFalse);
    });

    test('tidak boleh diubah: tanpa PUT, nilai tetap', () async {
      final palsu = LayananPreferensiPalsu();
      final c = _wadah(palsu);
      c.read(koneksiProvider.notifier).offline(DateTime(2026, 11, 13, 8, 30));
      await _muat(c);

      _aksi(c).ubah('tahap_alat', false);
      await _giliran();
      expect(palsu.panggilan, isEmpty);
      expect(_kini(c).nilai['tahap_alat'], isTrue);
    });

    test(
      'offline tanpa waktu cache (bukan data lama): tetap bisa diubah',
      () async {
        final c = _wadah(LayananPreferensiPalsu());
        c.read(koneksiProvider.notifier).offline(null);
        final k = await _muat(c);
        expect(k.dariCache, isFalse);
        expect(k.bisaUbah, isTrue);
      },
    );

    test('online sesudah muat ulang: bisa diubah lagi', () async {
      final palsu = LayananPreferensiPalsu();
      final c = _wadah(palsu);
      c.read(koneksiProvider.notifier).offline(DateTime(2026, 11, 13, 8, 30));
      await _muat(c);
      expect(_kini(c).bisaUbah, isFalse);

      // GET sungguhan yang berhasil memanggil `saatOnline`.
      palsu.saatMuat = () => c.read(koneksiProvider.notifier).online();
      c.invalidate(preferensiNotifikasiProvider);
      await c.read(preferensiNotifikasiProvider.future);
      expect(_kini(c).bisaUbah, isTrue);
    });
  });

  group('siklus hidup', () {
    test('layar ditutup selagi menyimpan: PUT selesai, tanpa galat', () async {
      final palsu = LayananPreferensiPalsu()..tahan = true;
      final c = _wadah(palsu);
      final langganan = c.listen(preferensiNotifikasiProvider, (_, _) {});
      await c.read(preferensiNotifikasiProvider.future);

      _aksi(c).ubah('tahap_alat', false);
      langganan.close(); // layar ditutup
      await _giliran();
      palsu.selesaikan(0);
      await _giliran();
      await _giliran();

      expect(palsu.panggilan, hasLength(1));
      expect(palsu.server['tahap_alat'], isFalse);
    });

    test(
      'layar ditutup selagi antrean berisi dua nilai: keduanya terkirim berurutan',
      () async {
        final palsu = LayananPreferensiPalsu()..tahan = true;
        final c = _wadah(palsu);
        final langganan = c.listen(preferensiNotifikasiProvider, (_, _) {});
        await c.read(preferensiNotifikasiProvider.future);

        _aksi(c).ubah('tahap_alat', false);
        _aksi(c).ubah('tahap_alat', true); // menunggu giliran
        langganan.close(); // layar ditutup
        await _giliran();
        palsu.selesaikan(0);
        await _giliran();
        // Tanpa penahan, provider sudah dibuang dan nilai kedua tak terkirim:
        // di server tinggal "false" padahal yang terakhir diketuk "true".
        expect(palsu.badan, [
          {'tahap_alat': false},
          {'tahap_alat': true},
        ]);
        palsu.selesaikan(1);
        await _giliran();
        expect(palsu.server['tahap_alat'], isTrue);
      },
    );

    test('layar ditutup, lalu PUT gagal: tanpa galat tak tertangani', () async {
      final palsu = LayananPreferensiPalsu()
        ..tahan = true
        ..rencanaGalat.add(galatJaringan());
      final c = _wadah(palsu);
      final langganan = c.listen(preferensiNotifikasiProvider, (_, _) {});
      await c.read(preferensiNotifikasiProvider.future);

      _aksi(c).ubah('tahap_alat', false);
      langganan.close();
      palsu.selesaikan(0);
      await _giliran();
      await _giliran();
      // Tiba di sini tanpa melempar: gagal setelah layar tertutup diam saja.
      expect(palsu.panggilan, hasLength(1));
    });

    test('pindah perusahaan selagi menyimpan: jawaban lama dibuang', () async {
      final palsu = LayananPreferensiPalsu()..tahan = true;
      final c = _wadah(palsu, sesiBisaGanti: true);
      await c.read(sesiProvider.future);
      await _muat(c);

      _aksi(c).ubah('tahap_alat', false);
      // Pengguna berpindah ke PT lain: provider dibangun ulang dari nol.
      (c.read(sesiProvider.notifier) as SesiBisaGanti).pilihPerusahaan(4);
      palsu.server = {...LayananPreferensiPalsu.kunciKontrak};
      await c.read(preferensiNotifikasiProvider.future);
      expect(palsu.muat, 2);
      expect(_kini(c).nilai['tahap_alat'], isTrue, reason: 'PT baru, set baru');

      palsu.selesaikan(0); // jawaban untuk PT lama tiba terlambat
      await _giliran();
      await _giliran();
      expect(_kini(c).nilai['tahap_alat'], isTrue);
      expect(_kini(c).tahapDari('tahap_alat'), TahapSimpan.diam);
      expect(_kini(c).pesanGagal, isEmpty);

      // `_tersimpan` PT baru tidak boleh tercemar jawaban PT lama: ketukan
      // berikutnya benar-benar dikirim (bukan dianggap sudah tersimpan).
      _aksi(c).ubah('tahap_alat', false);
      expect(palsu.panggilan, hasLength(2));
      expect(palsu.badan.last, {'tahap_alat': false});
      palsu.selesaikan(1);
      await _giliran();
      expect(_kini(c).nilai['tahap_alat'], isFalse);
      expect(_kini(c).tahapDari('tahap_alat'), TahapSimpan.diam);
    });

    test(
      'katalog kategori: kunci unik, kalimat tak kosong, bahasa pelanggan',
      () {
        final kunci = KategoriKabar.daftar.map((k) => k.kunci).toList();
        expect(kunci.toSet().length, kunci.length);
        expect(
          kunci,
          containsAll(['pengingat_jadwal', 'status_permintaan', 'tahap_alat']),
        );
        for (final k in KategoriKabar.daftar) {
          expect(k.judul.trim(), isNotEmpty);
          expect(k.penjelasan.trim(), isNotEmpty);
          expect(k.judul, isNot(contains('_')), reason: 'bukan nama kolom');
          expect(k.penjelasan, endsWith('.'));
        }
        expect(KategoriKabar.dikenal('tahap_alat'), isTrue);
        expect(KategoriKabar.dikenal('pesan_lab'), isFalse);
      },
    );
  });
}
