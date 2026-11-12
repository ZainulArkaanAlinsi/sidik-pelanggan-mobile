import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api_pelanggan.dart';
import '../core/tema/spasi.dart';
import '../core/tema/warna_sidik.dart';
import '../providers/paginasi.dart';
import 'keadaan_galat.dart';
import 'kerangka.dart';
import 'tombol_sidik.dart';

/// Daftar dengan infinite scroll di atas [DataBerhalaman].
///
/// Halaman berikut diminta begitu baris UJUNG daftar dibangun — artinya
/// pengguna sudah menggulir sampai sekitar satu layar dari akhir (ListView
/// membangun butir dalam `cacheExtent`). Cara ini juga menutup kasus daftar
/// yang lebih pendek dari layar: ujungnya langsung terbangun, halaman 2
/// langsung dimuat.
///
/// Empat keadaan 04-UI-UX §1.2: memuat (kerangka), kosong ([kosong]), gagal
/// ([KeadaanGalat] + coba lagi), dan offline — cache dari `ApiPelanggan`
/// tampil sebagai data biasa, banner offline di atas aplikasi.
class DaftarBerhalaman<T> extends StatelessWidget {
  const DaftarBerhalaman({
    super.key,
    required this.async,
    required this.muatLagi,
    required this.cobaLagi,
    required this.kosong,
    required this.butir,
    this.jarakButir = Spasi.md,
    this.padding = const EdgeInsets.fromLTRB(
      Spasi.lg,
      Spasi.sm,
      Spasi.lg,
      Spasi.xl,
    ),
    this.pemisah,
    this.kepala = const [],
    this.kosongDiBawahKepala,
    this.namaButir = 'data',
  });

  final AsyncValue<DataBerhalaman<T>> async;

  /// Muat halaman berikut. `ulangiGalat` = dari tombol "Coba lagi".
  final void Function({bool ulangiGalat}) muatLagi;

  /// Muat ulang seluruh daftar (galat halaman 1).
  final VoidCallback cobaLagi;
  final Widget kosong;
  final Widget Function(BuildContext context, T butir) butir;
  final double jarakButir;
  final EdgeInsetsGeometry padding;

  /// Pengganti jarak antar-butir (mis. `Divider` di notifikasi).
  final Widget? pemisah;

  /// Widget di atas butir pertama (mis. bagian usulan alat).
  final List<Widget> kepala;

  /// Pengganti [kosong] kalau [kepala] tidak kosong — harus widget biasa,
  /// BUKAN daftar bergulir ([kosong] umumnya `ListView`).
  final Widget? kosongDiBawahKepala;

  /// "alat", "sertifikat", … untuk kalimat di ujung daftar.
  final String namaButir;

  @override
  Widget build(BuildContext context) => async.when(
    loading: () => KerangkaDaftar(padding: padding),
    error: (e, _) => KeadaanGalat(galat: e, cobaLagi: cobaLagi),
    data: (d) {
      final n = d.isi.length;
      if (n == 0) {
        if (kepala.isEmpty) return kosong;
        return ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: padding,
          children: [...kepala, ?kosongDiBawahKepala],
        );
      }
      return ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: padding,
        itemCount: kepala.length + n * 2 - 1 + 1,
        itemBuilder: (context, i) {
          if (i < kepala.length) return kepala[i];
          final j = i - kepala.length;
          if (j < n * 2 - 1) {
            if (j.isOdd) return pemisah ?? SizedBox(height: jarakButir);
            return butir(context, d.isi[j ~/ 2]);
          }
          return _Ujung<T>(data: d, muatLagi: muatLagi, namaButir: namaButir);
        },
      );
    },
  );
}

class _Ujung<T> extends StatelessWidget {
  const _Ujung({
    required this.data,
    required this.muatLagi,
    required this.namaButir,
  });

  final DataBerhalaman<T> data;
  final void Function({bool ulangiGalat}) muatLagi;
  final String namaButir;

  @override
  Widget build(BuildContext context) {
    final t = context.teks;
    if (data.galatLagi != null) {
      final e = data.galatLagi;
      return Padding(
        padding: const EdgeInsets.only(top: Spasi.lg),
        child: Column(
          children: [
            Text(
              e is GalatApi ? e.pesan : 'Halaman berikutnya gagal dimuat.',
              textAlign: TextAlign.center,
              style: t.bodySmall,
            ),
            const SizedBox(height: Spasi.sm),
            TombolSidik(
              label: 'Coba lagi',
              ikon: Icons.refresh,
              ragam: RagamTombol.teks,
              onPressed: () => muatLagi(ulangiGalat: true),
            ),
          ],
        ),
      );
    }
    if (data.adaLagi) {
      if (!data.memuatLagi) {
        // Dibangun = sudah dekat ujung. Minta halaman berikut sesudah frame
        // ini (tidak boleh mengubah state di tengah build).
        WidgetsBinding.instance.addPostFrameCallback((_) => muatLagi());
      }
      return const Padding(
        padding: EdgeInsets.only(top: Spasi.md),
        child: KerangkaKartu(),
      );
    }
    if (data.halaman > 1) {
      return Padding(
        padding: const EdgeInsets.only(top: Spasi.lg),
        child: Text(
          'Semua ${data.total} $namaButir sudah tampil.',
          textAlign: TextAlign.center,
          style: t.bodySmall,
        ),
      );
    }
    return const SizedBox.shrink();
  }
}
