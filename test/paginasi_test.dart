import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sidik_pelanggan/core/api_pelanggan.dart';
import 'package:sidik_pelanggan/core/penyimpan_sesi.dart';
import 'package:sidik_pelanggan/models/data_pelanggan.dart';
import 'package:sidik_pelanggan/providers/data_provider.dart';
import 'package:sidik_pelanggan/providers/sesi_provider.dart';
import 'package:sidik_pelanggan/services/layanan_pelanggan.dart';

class _Sunyi extends PenyimpanSesi {
  @override
  Future<String?> token() async => null;
}

Alat _a(int id) => Alat.dariJson({'id': id, 'nama': 'Alat $id'});

/// Dua halaman; halaman 2 mengulang satu butir halaman 1 (id 2).
class _DuaHalaman extends LayananPelanggan {
  _DuaHalaman() : super(ApiPelanggan());

  final diminta = <int>[];

  @override
  Future<Halaman<Alat>> daftarAlat({
    String? cari,
    String? saring,
    int halaman = 1,
  }) async {
    diminta.add(halaman);
    return Halaman(
      isi: halaman == 1 ? [_a(1), _a(2)] : [_a(2), _a(3)],
      halaman: halaman,
      halamanTerakhir: 2,
      total: 3,
    );
  }
}

void main() {
  test('infinite scroll: halaman berikut disambung, duplikat dibuang, berhenti '
      'di halaman terakhir', () async {
    final palsu = _DuaHalaman();
    final c = ProviderContainer(
      overrides: [
        penyimpanSesiProvider.overrideWithValue(_Sunyi()),
        layananProvider.overrideWithValue(palsu),
        infoPaketProvider.overrideWith(
          (ref) async => (versi: '1.0.0', build: '1'),
        ),
      ],
    );
    addTearDown(c.dispose);
    // Sesi dipulihkan dulu: daftar dibangun ulang saat sesi selesai dimuat.
    await c.read(sesiProvider.future);
    const kunci = (cari: '', saring: null);
    final sub = c.listen(daftarAlatProvider(kunci), (_, _) {});
    addTearDown(sub.close);

    var d = await c.read(daftarAlatProvider(kunci).future);
    expect(d.isi.map((a) => a.id), [1, 2]);
    expect(d.adaLagi, isTrue);

    await c.read(daftarAlatProvider(kunci).notifier).muatLagi();
    d = c.read(daftarAlatProvider(kunci)).value!;
    expect(d.isi.map((a) => a.id), [1, 2, 3]);
    expect(d.adaLagi, isFalse);

    await c.read(daftarAlatProvider(kunci).notifier).muatLagi();
    expect(palsu.diminta, [1, 2], reason: 'tidak meminta halaman ke-3');
  });
}
