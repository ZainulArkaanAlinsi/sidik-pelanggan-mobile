import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/tema/spasi.dart';
import '../../core/tema/ukuran.dart';
import '../../core/tema/warna_sidik.dart';
import '../../models/data_pelanggan.dart';
import '../../providers/data_provider.dart';
import '../../providers/koneksi_provider.dart';
import '../../widgets/halaman_sidik.dart';
import '../../widgets/keadaan_galat.dart';
import '../../widgets/kolom_cari_utuh.dart';
import '../../widgets/segmen_pil.dart';
import '../alat/daftar_alat_bagian.dart' show CatatanLuring;
import 'arsip_screen.dart';
import 'daftar_sertifikat_bagian.dart';
import 'sertifikat_detail_screen.dart';

/// Dua tampilan di tab Sertifikat.
enum _Tampilan {
  daftar('Daftar'),
  arsip('Arsip');

  const _Tampilan(this.label);

  final String label;
}

/// Tab Sertifikat (arah REVISI-1/REVISI-2, 16 Nov 2026): kepala (judul + pil
/// "N sertifikat") → [SegmenPil] Daftar | Arsip → salah satu isinya.
///
/// - Daftar: [KolomCariUtuh] → baris sakelar → baris sertifikat
///   ([BarisSertifikat]: nama alat, nomor, nomor seri, tanggal terbit, badge
///   status, jadwal kalibrasi ulang) dengan cari + infinite scroll. Dibuka
///   dari Beranda ("Lihat semua") dan tab Alat. Bawaannya cuma yang MASIH
///   BERLAKU sebagai dokumen: yang sudah digantikan revisi disembunyikan
///   supaya nomor lama tidak terkirim ke auditor. Satu sakelar untuk
///   menampilkannya.
/// - Arsip: sertifikat menurut tanggal terbit ([ArsipIsi]; tampilannya
///   menyusul di langkah desain berikutnya).
///
/// Kedua isi tetap hidup waktu berpindah (kata cari, sakelar, dan posisi
/// penelusuran tidak hilang). Arsip baru dibangun saat pertama dibuka, jadi
/// membuka tab Sertifikat tidak meminta arsip yang belum dilihat.
///
/// Empat keadaan Daftar: memuat (kerangka statis tanpa gerak), kosong (panel
/// kosong; "belum ada sertifikat" dan hasil cari kosong berbeda kata dan ikon,
/// dan hasil cari kosong menyebut filter aktif, termasuk yang bawaan, beserta
/// tombol "Hapus pencarian" dan "Tampilkan yang sudah digantikan"), galat
/// (`KeadaanGalat` + "Coba lagi"), tanpa koneksi (catatan di atas daftar yang
/// tersimpan).
///
/// Jumlah di kepala hanya dari daftar yang sedang tampil dan sudah terbaca
/// (provider yang SAMA dengan daftarnya, jadi tidak pernah dua angka untuk satu
/// kata): memuat atau gagal = tanpa pil, bukan "0 sertifikat". Pil tidak
/// tampil di Arsip, yang punya ringkasannya sendiri.
class SertifikatScreen extends ConsumerStatefulWidget {
  const SertifikatScreen({super.key});

  @override
  ConsumerState<SertifikatScreen> createState() => _SertifikatScreenState();
}

class _SertifikatScreenState extends ConsumerState<SertifikatScreen> {
  _Tampilan _tampilan = _Tampilan.daftar;
  bool _arsipDibuka = false;

  /// Kata cari dan sakelar Daftar dipegang di sini (bukan di daftarnya) supaya
  /// pil jumlah di kepala membaca provider berkunci sama dengan daftar.
  String _kata = '';
  bool _termasukDigantikan = false;

  /// Naik tiap "Hapus pencarian": kolom cari dibangun ulang dengan isian kosong.
  int _kunciCari = 0;

  KunciSertifikat get _kunci =>
      (cari: _kata, termasukDigantikan: _termasukDigantikan);

  void _hapusPencarian() => setState(() {
    _kata = '';
    _kunciCari++;
  });

  void _pilih(_Tampilan t) => setState(() {
    _tampilan = t;
    if (t == _Tampilan.arsip) _arsipDibuka = true;
  });

  /// Jumlah sertifikat di daftar yang tampil; null bila belum terbaca (memuat,
  /// gagal, atau halaman server belum memberi total yang bisa dipercaya).
  int? _jumlahTampil() => switch (ref.watch(daftarSertifikatProvider(_kunci))) {
    AsyncData(:final value) => jumlahSertifikatTerbaca(value),
    _ => null,
  };

  @override
  Widget build(BuildContext context) {
    final jumlah = _jumlahTampil();
    return HalamanSidik(
      judulKustom: const _JudulLayar(),
      aksi: [
        if (jumlah != null && _tampilan == _Tampilan.daftar)
          PilJumlahSertifikat(jumlah: jumlah),
      ],
      isi: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Spasi.sisi,
              Spasi.md,
              Spasi.sisi,
              0,
            ),
            child: Semantics(
              container: true,
              explicitChildNodes: true,
              label: 'Tampilan sertifikat',
              child: SegmenPil(
                pilihan: [for (final t in _Tampilan.values) t.label],
                terpilih: _tampilan.index,
                onPilih: (i) => _pilih(_Tampilan.values[i]),
              ),
            ),
          ),
          Expanded(
            child: IndexedStack(
              index: _tampilan.index,
              children: [
                _DaftarSertifikat(
                  kunci: _kunci,
                  kunciCari: _kunciCari,
                  onCari: (kata) => setState(() => _kata = kata),
                  onSakelar: (v) => setState(() => _termasukDigantikan = v),
                  onHapusPencarian: _hapusPencarian,
                ),
                if (_arsipDibuka) const ArsipIsi() else const SizedBox.shrink(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Judul kepala: "Sertifikat" 22/28, satu baris, dijepit pada huruf besar
/// ([SkalaHuruf.batasBesar]); pembaca layar menerimanya sebagai judul.
class _JudulLayar extends StatelessWidget {
  const _JudulLayar();

  @override
  Widget build(BuildContext context) => Semantics(
    header: true,
    child: MediaQuery.withClampedTextScaling(
      maxScaleFactor: SkalaHuruf.batasBesar,
      child: Text(
        'Sertifikat',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: context.teks.headlineMedium,
      ),
    ),
  );
}

class _DaftarSertifikat extends ConsumerWidget {
  const _DaftarSertifikat({
    required this.kunci,
    required this.kunciCari,
    required this.onCari,
    required this.onSakelar,
    required this.onHapusPencarian,
  });

  final KunciSertifikat kunci;
  final int kunciCari;
  final ValueChanged<String> onCari;
  final ValueChanged<bool> onSakelar;
  final VoidCallback onHapusPencarian;

  void _buka(BuildContext context, Sertifikat s) => Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => SertifikatDetailScreen(id: s.id)),
  );

  /// Catatan "tanpa koneksi" di atas daftar yang tersimpan (kosong bila
  /// tersambung atau bila tidak ada waktu data terakhir).
  List<Widget> _kepalaLuring(KeadaanKoneksi koneksi) => [
    if (koneksi.offline && koneksi.dataTerakhir != null)
      CatatanLuring(
        teks:
            'Tanpa koneksi. Terakhir diperbarui '
            '${Format.jamAtauTanggal(koneksi.dataTerakhir!)}',
      ),
  ];

  /// Panel kosong di dalam daftar bergulir (tarik-untuk-muat-ulang tetap jalan).
  Widget _kosong(BuildContext context, List<Widget> kepala) {
    final adaKata = kunci.cari.isNotEmpty;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: Spasi.daftar(context),
      children: [
        ...kepala,
        PanelKosongSertifikat(
          ikon: adaKata
              ? Icons.search_off_outlined
              : Icons.description_outlined,
          judul: adaKata ? 'Tidak ada yang cocok' : 'Belum ada sertifikat',
          keterangan: adaKata
              ? 'Coba nomor atau nama alat yang lain.'
              : 'Sertifikat muncul di sini begitu diterbitkan dan disahkan '
                    'laboratorium.',
          // Semua filter yang menyempitkan hasil disebut, termasuk yang bawaan
          // (yang sudah digantikan disembunyikan), supaya nomor lama yang
          // dicari tidak berakhir di "tidak ada yang cocok" tanpa petunjuk.
          filter: [
            if (adaKata) 'Kata cari: “${kunci.cari}”',
            if (adaKata && kunci.termasukDigantikan)
              'Termasuk yang sudah direvisi',
            if (adaKata && !kunci.termasukDigantikan)
              'Sertifikat yang sudah digantikan disembunyikan',
          ],
          onReset: adaKata ? onHapusPencarian : null,
          onLonggarkan: adaKata && !kunci.termasukDigantikan
              ? () => onSakelar(true)
              : null,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = daftarSertifikatProvider(kunci);
    final async = ref.watch(provider);
    final koneksi = ref.watch(koneksiProvider);

    return Column(
      children: [
        KolomCariUtuh(
          key: ValueKey<int>(kunciCari),
          petunjuk: 'Cari nomor sertifikat, alat, atau nomor seri',
          onCari: onCari,
        ),
        BarisSakelar(
          label: 'Tampilkan juga yang sudah direvisi',
          nilai: kunci.termasukDigantikan,
          onUbah: onSakelar,
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(provider);
              try {
                await ref.read(provider.future);
              } catch (_) {
                // Galat tampil sebagai `KeadaanGalat` + "Coba lagi"; tarik
                // layar yang gagal tidak boleh jadi galat tak tertangkap.
              }
            },
            child: async.when(
              loading: () => const KerangkaSertifikat(),
              error: (e, _) => KeadaanGalat(
                galat: e,
                cobaLagi: () => ref.invalidate(provider),
              ),
              data: (d) {
                final kepala = _kepalaLuring(koneksi);
                if (d.isi.isEmpty) return _kosong(context, kepala);
                return DaftarBarisSertifikat(
                  sertifikat: d.isi,
                  onBuka: (s) => _buka(context, s),
                  kepala: kepala,
                  ujung: UjungDaftarSertifikat(
                    data: d,
                    muatLagi: ({ulangiGalat = false}) => ref
                        .read(provider.notifier)
                        .muatLagi(ulangiGalat: ulangiGalat),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
