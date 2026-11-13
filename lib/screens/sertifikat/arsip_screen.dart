import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_pelanggan.dart';
import '../../core/tema/spasi.dart';
import '../../core/tema/warna_sidik.dart';
import '../../models/arsip.dart';
import '../../models/data_pelanggan.dart';
import '../../providers/data_provider.dart';
import '../../widgets/bagian_sidik.dart';
import '../../widgets/daftar_berhalaman.dart';
import '../../widgets/halaman_sidik.dart';
import '../../widgets/kartu_kelompok_arsip.dart';
import '../../widgets/kartu_sertifikat.dart';
import '../../widgets/keadaan_kosong.dart';
import '../../widgets/kolom_cari.dart';
import '../../widgets/tombol_sidik.dart';
import 'sertifikat_detail_screen.dart';

/// Satu tingkat Arsip sertifikat sebagai layar penuh (tahun, bulan, pekan,
/// atau hari). Tingkat awal hidup di tab Sertifikat sebagai [ArsipIsi]; layar
/// ini dibuka untuk tiap tingkat di bawahnya, dengan judul = label kelompok
/// yang dibuka. Judul panjang ("Pekan 46 (9–15 Nov 2026)") mengecil secukupnya
/// supaya terbaca utuh di layar sempit, tidak dipotong.
class ArsipScreen extends StatelessWidget {
  const ArsipScreen({
    super.key,
    this.parameter = ParameterArsip.akar,
    this.judul = 'Arsip sertifikat',
  });

  /// Tampilan yang dibuka; tingkat berikutnya lewat [KelompokArsip.parameter].
  final ParameterArsip parameter;
  final String judul;

  @override
  Widget build(BuildContext context) => HalamanSidik(
    judulKustom: FittedBox(
      fit: BoxFit.scaleDown,
      alignment: AlignmentDirectional.centerStart,
      child: Text(judul, maxLines: 1),
    ),
    isi: ArsipIsi(parameter: parameter),
  );
}

/// Isi Arsip sertifikat tanpa kerangka layar, supaya bisa ditaruh di tab
/// Sertifikat maupun di [ArsipScreen].
///
/// Arsip disusun menurut tanggal terbit: tahun, lalu bulan, pekan, dan hari
/// beserta sertifikatnya. Dibuka bertahap — tiap ketukan memuat SATU tingkat
/// dari server (`GET /sertifikat/garis-waktu`), tidak pernah seluruh arsip.
/// Pengelompokan, label, jumlah, dan urutan dari server.
///
/// Pencarian (hanya di tingkat awal): bila kata cari terisi (minimal 2
/// karakter, jeda ketik [KolomCari.jeda]) isi berganti jadi DAFTAR DATAR hasil
/// dari daftar sertifikat (`GET /sertifikat?q=`, jalur yang sama dengan tab
/// Sertifikat), satu permintaan per kata, tanpa permintaan garis waktu. Kata
/// kosong kembali ke garis waktu. Server mencocokkan `q` apa adanya (bukan
/// disamakan formatnya), jadi nomor perlu ditulis persis seperti di sertifikat.
///
/// Hanya baca: tidak ada aksi yang mengubah data di sini.
class ArsipIsi extends ConsumerStatefulWidget {
  const ArsipIsi({super.key, this.parameter = ParameterArsip.akar});

  final ParameterArsip parameter;

  @override
  ConsumerState<ArsipIsi> createState() => _ArsipIsiState();
}

class _ArsipIsiState extends ConsumerState<ArsipIsi> {
  /// Ketikan terakhir di kolom cari (sudah dipangkas), termasuk yang terlalu
  /// pendek untuk dikirim.
  String _kata = '';

  bool get _akar => widget.parameter.adalahAkar;

  /// Kata yang boleh dikirim ([KataCari.rapikan]); kosong = tampilkan arsip.
  String get _cari => _akar ? KataCari.rapikan(_kata) : '';

  void _bukaKelompok(KelompokArsip k) {
    // Tanpa `telusuri` tidak ada tingkat di bawahnya (jawaban rusak): tanpa
    // ini parameter kosong = tingkat awal lagi, layar yang sama bertumpuk.
    if (k.telusuri.isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ArsipScreen(parameter: k.parameter, judul: k.label),
      ),
    );
  }

  void _bukaSertifikat(int id) => Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => SertifikatDetailScreen(id: id)),
  );

  @override
  Widget build(BuildContext context) {
    final cari = _cari;
    // Terlalu pendek untuk dikirim: petunjuk, tampilan tidak berubah.
    final terlaluPendek = _akar && _kata.isNotEmpty && cari.isEmpty;
    // Server mencocokkan kata apa adanya (bukan menyamakan format), jadi
    // pengguna diberi tahu sebelum mengetik.
    final catatan = terlaluPendek
        ? 'Ketik minimal ${KataCari.minimal} karakter untuk mencari.'
        : (_akar && cari.isEmpty
              ? 'Tulis nomor persis seperti di sertifikat.'
              : null);
    return Column(
      children: [
        if (_akar)
          KolomCari(
            petunjuk: 'Seri, sertifikat, order',
            onCari: (kata) => setState(() => _kata = kata),
          ),
        if (catatan != null)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                Spasi.lg,
                Spasi.sm,
                Spasi.lg,
                0,
              ),
              child: Text(catatan, style: context.teks.bodySmall),
            ),
          ),
        Expanded(
          child: cari.isEmpty
              ? _Garis(
                  parameter: widget.parameter,
                  akar: _akar,
                  onBukaKelompok: _bukaKelompok,
                  onBukaSertifikat: _bukaSertifikat,
                )
              : _Hasil(cari: cari, onBukaSertifikat: _bukaSertifikat),
        ),
      ],
    );
  }
}

/// 404 = data tidak ada atau bukan milik perusahaan ini: bukan kerusakan, jadi
/// tidak ditawari "Coba lagi". `null` bila [async] bukan 404.
///
/// Aksinya bergantung tempatnya: di tingkat bawah ([akar] false) layar ini
/// rute yang bisa ditutup, jadi "Kembali"; di tingkat awal ia hidup di tab
/// (tidak ada rute untuk ditutup), jadi "Muat ulang" ([muatUlang]).
Widget? _tidakDitemukan(
  BuildContext context,
  AsyncValue<Object?> async, {
  required bool akar,
  required VoidCallback muatUlang,
}) {
  final galat = async.error;
  if (async.isLoading || galat is! GalatApi || !galat.tidakDitemukan) {
    return null;
  }
  return KeadaanKosong(
    ikon: Icons.search_off,
    judul: 'Tidak ditemukan',
    keterangan: galat.pesan,
    aksi: akar
        ? TombolSidik(
            label: 'Muat ulang',
            ikon: Icons.refresh,
            onPressed: muatUlang,
          )
        : TombolSidik(
            label: 'Kembali',
            ikon: Icons.arrow_back,
            onPressed: () => Navigator.of(context).maybePop(),
          ),
  );
}

/// Garis waktu satu tingkat (tanpa kata cari).
class _Garis extends ConsumerWidget {
  const _Garis({
    required this.parameter,
    required this.akar,
    required this.onBukaKelompok,
    required this.onBukaSertifikat,
  });

  final ParameterArsip parameter;
  final bool akar;
  final void Function(KelompokArsip kelompok) onBukaKelompok;
  final void Function(int id) onBukaSertifikat;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(garisWaktuProvider(parameter));
    final tidakAda = _tidakDitemukan(
      context,
      async,
      akar: akar,
      muatUlang: () => ref.invalidate(garisWaktuProvider(parameter)),
    );
    if (tidakAda != null) return tidakAda;

    final data = async.value;
    final total = data?.jumlah['total_dokumen'];
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(garisWaktuProvider(parameter));
        try {
          await ref.read(garisWaktuProvider(parameter).future);
        } catch (_) {
          // Galatnya sudah tampil di layar (KeadaanGalat); tarik-muat-ulang
          // tidak perlu melempar lagi.
        }
      },
      child: DaftarBerhalaman<BarisArsip>(
        async: async,
        namaButir: 'sertifikat',
        padding: Spasi.daftar(context),
        muatLagi: ({ulangiGalat = false}) => ref
            .read(garisWaktuProvider(parameter).notifier)
            .muatLagi(ulangiGalat: ulangiGalat),
        cobaLagi: () => ref.invalidate(garisWaktuProvider(parameter)),
        kepala: [
          if (total != null && data!.isi.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: Spasi.sm),
              child: Text(
                akar
                    ? '$total sertifikat, disusun menurut tanggal terbit'
                    : '$total sertifikat',
                style: context.teks.bodySmall,
              ),
            ),
        ],
        kosong: const KeadaanKosong(
          ikon: Icons.folder_open_outlined,
          judul: 'Belum ada sertifikat di arsip',
          keterangan:
              'Sertifikat muncul di sini begitu diterbitkan dan disahkan laboratorium.',
        ),
        butir: (context, baris) => switch (baris) {
          BarisKelompok(:final kelompok, :final tingkat) => KartuKelompokArsip(
            kelompok: kelompok,
            tingkat: tingkat,
            onTap: () => onBukaKelompok(kelompok),
          ),
          BarisHari(:final kelompok) => BagianSidik(
            kelompok.label,
            aksi: Text(
              '${kelompok.jumlah} sertifikat',
              style: context.teks.bodySmall,
            ),
          ),
          BarisSertifikat(:final sertifikat) => KartuSertifikat(
            sertifikat: sertifikat,
            onTap: () => onBukaSertifikat(sertifikat.id),
          ),
        },
      ),
    );
  }
}

/// Hasil pencarian sebagai daftar datar, lewat daftar sertifikat yang sama
/// dengan tab Sertifikat. Revisi yang sudah digantikan tidak ikut (bawaan
/// server).
class _Hasil extends ConsumerWidget {
  const _Hasil({required this.cari, required this.onBukaSertifikat});

  final String cari;
  final void Function(int id) onBukaSertifikat;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kunci = (cari: cari, termasukDigantikan: false);
    final async = ref.watch(daftarSertifikatProvider(kunci));
    // Pencarian hanya ada di tingkat awal (di tab): selalu "Muat ulang".
    final tidakAda = _tidakDitemukan(
      context,
      async,
      akar: true,
      muatUlang: () => ref.invalidate(daftarSertifikatProvider(kunci)),
    );
    if (tidakAda != null) return tidakAda;

    final data = async.value;
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(daftarSertifikatProvider(kunci));
        try {
          await ref.read(daftarSertifikatProvider(kunci).future);
        } catch (_) {
          // Galatnya sudah tampil di layar (KeadaanGalat).
        }
      },
      child: DaftarBerhalaman<Sertifikat>(
        async: async,
        namaButir: 'sertifikat',
        padding: Spasi.daftar(context),
        muatLagi: ({ulangiGalat = false}) => ref
            .read(daftarSertifikatProvider(kunci).notifier)
            .muatLagi(ulangiGalat: ulangiGalat),
        cobaLagi: () => ref.invalidate(daftarSertifikatProvider(kunci)),
        kepala: [
          if (data != null && data.isi.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: Spasi.sm),
              child: Text(
                '${data.total} sertifikat cocok',
                style: context.teks.bodySmall,
              ),
            ),
        ],
        kosong: const KeadaanKosong(
          ikon: Icons.search_off,
          judul: 'Tidak ada yang cocok',
          keterangan:
              'Coba nomor seri, nomor sertifikat, atau nomor order yang lain, '
              'dan tulis persis seperti di sertifikat. Sertifikat yang sudah '
              'direvisi ada di Daftar: nyalakan "Tampilkan juga yang sudah '
              'direvisi".',
        ),
        butir: (context, s) =>
            KartuSertifikat(sertifikat: s, onTap: () => onBukaSertifikat(s.id)),
      ),
    );
  }
}
