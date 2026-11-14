import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/tema/spasi.dart';
import '../../core/tema/ukuran.dart';
import '../../core/tema/warna_sidik.dart';
import '../../models/preferensi_notifikasi.dart';
import '../../providers/preferensi_notifikasi_provider.dart';
import '../../providers/sesi_provider.dart';
import '../../widgets/bagian.dart';
import '../../widgets/baris_sidik.dart';
import '../../widgets/halaman_sidik.dart';
import '../../widgets/keadaan_teks.dart';
import '../../widgets/kerangka.dart';
import '../../widgets/panel_pemberitahuan.dart';
import '../../widgets/panel_sidik.dart';
import '../../widgets/stempel.dart';
import '../../widgets/status_tampil.dart';
import '../../widgets/tautan_baris.dart';

/// Pengaturan notifikasi: satu saklar per kategori kabar
/// ([KategoriKabar.daftar]), disimpan per saklar begitu diketuk. Server
/// menyimpannya per anggota per perusahaan, jadi akun di dua perusahaan punya
/// dua set; nama perusahaannya hanya ditulis bila akun punya lebih dari satu.
///
/// Keadaan: memuat (kerangka), galat muat (jenis galat + "Coba lagi"), data
/// dari simpanan HP saat tidak ada sambungan (baca-saja, nilainya bisa lebih
/// lama daripada server), baca-saja karena server menolak (403), dan per
/// saklar: menyimpan, gagal (nilai dikembalikan, alasannya ditulis di baris).
class PreferensiNotifikasiScreen extends ConsumerWidget {
  const PreferensiNotifikasiScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(preferensiNotifikasiProvider);
    void muatUlang() => ref.invalidate(preferensiNotifikasiProvider);
    return HalamanSidik(
      judul: 'Pengaturan notifikasi',
      isi: async.when(
        loading: () => const Memuat(),
        error: (galat, _) => _GalatMuat(galat: galat, cobaLagi: muatUlang),
        data: (keadaan) => _Isi(keadaan: keadaan, muatUlang: muatUlang),
      ),
    );
  }
}

class _GalatMuat extends StatelessWidget {
  const _GalatMuat({required this.galat, required this.cobaLagi});

  final Object galat;
  final VoidCallback cobaLagi;

  @override
  Widget build(BuildContext context) {
    final pesan = pesanGagalMuat(galat);
    return ListView(
      padding: Spasi.daftar(context),
      children: [
        KeadaanTeks(
          judul: pesan.judul,
          isi: pesan.isi,
          aksi: 'Coba lagi',
          onAksi: cobaLagi,
          utama: true,
        ),
      ],
    );
  }
}

class _Isi extends ConsumerWidget {
  const _Isi({required this.keadaan, required this.muatUlang});

  final KeadaanPreferensi keadaan;
  final VoidCallback muatUlang;

  static const _judulKelompok = {
    KelompokKabar.notifikasi: 'Kabar di HP dan di aplikasi',
    KelompokKabar.email: 'Lewat email',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sesi = ref.watch(sesiProvider).value;
    final namaPt = sesi?.keanggotaanAktif?.namaPerusahaan;
    final banyakPt = sesi?.akun.lebihDariSatuPerusahaan ?? false;
    final t = context.teks;

    // Hanya kategori yang dikenal DAN dikirim server yang digambar.
    final baris = {
      for (final k in KategoriKabar.daftar)
        if (keadaan.nilai.containsKey(k.kunci)) k.kunci: k,
    };
    if (baris.isEmpty) {
      return ListView(
        padding: Spasi.daftar(context),
        children: [
          KeadaanTeks(
            judul: 'Belum ada pengaturan',
            isi:
                'Server belum mengirim pengaturan yang bisa Anda ubah. Coba '
                'muat ulang beberapa saat lagi.',
            aksi: 'Muat ulang',
            onAksi: muatUlang,
          ),
        ],
      );
    }

    final atas = <Widget>[
      if (keadaan.dariCache) ...[
        BannerDataTerakhir(
          teks:
              'Tidak ada sambungan. Yang tampil adalah pilihan terakhir yang '
              'terbaca (${Format.jamAtauTanggal(keadaan.dataTerakhir!)}) dan '
              'bisa berbeda dari yang tersimpan di server. Perubahan baru '
              'bisa disimpan setelah tersambung.',
        ),
        TautanBaris('Muat ulang', onTap: muatUlang),
        const SizedBox(height: Spasi.md),
      ],
      if (keadaan.alasanBacaSaja != null) ...[
        PanelPemberitahuan(
          nada: NadaStatus.netral,
          ikon: Icons.lock_outline,
          judul: 'Hanya bisa dibaca',
          isi: keadaan.alasanBacaSaja,
        ),
        const SizedBox(height: Spasi.md),
      ],
      if (banyakPt && namaPt != null)
        Text(
          'Pengaturan ini khusus untuk $namaPt. Perusahaan lain di akun Anda '
          'punya pengaturan sendiri.',
          style: t.bodyMedium,
        ),
    ];

    final kelompok = <Widget>[];
    for (final jenis in KelompokKabar.values) {
      final isi = [
        for (final k in baris.values)
          if (k.kelompok == jenis) k,
      ];
      if (isi.isEmpty) continue;
      kelompok
        ..add(
          Bagian(
            _judulKelompok[jenis]!,
            tanpaJarakAtas: atas.isEmpty && kelompok.isEmpty,
          ),
        )
        ..add(
          PanelSidik(
            anak: [
              for (final k in isi)
                _BarisSaklar(
                  key: ValueKey('saklar-${k.kunci}'),
                  kategori: k,
                  nilai: keadaan.nilai[k.kunci]!,
                  tahap: keadaan.tahapDari(k.kunci),
                  pesanGagal: keadaan.pesanGagal[k.kunci],
                  bisaUbah: keadaan.bisaUbah,
                  onUbah: (v) => ref
                      .read(preferensiNotifikasiProvider.notifier)
                      .ubah(k.kunci, v),
                ),
            ],
          ),
        );
    }

    return ListView(
      padding: Spasi.daftar(context),
      children: [
        ...atas,
        ...kelompok,
        const SizedBox(height: Spasi.lg),
        Text(
          'Kabar tentang revisi atau pembatalan sertifikat selalu dikirim dan '
          'tidak bisa dimatikan. Bila Anda mematikan notifikasi lewat '
          'pengaturan HP, kabar tetap masuk ke kotak Notifikasi di aplikasi.',
          style: t.bodySmall,
        ),
      ],
    );
  }
}

/// Ikon di bulatan saklar: centang saat aktif, silang saat nonaktif, supaya
/// keadaannya tidak hanya terbaca dari warna.
final _ikonSaklar = WidgetStateProperty.resolveWith<Icon?>(
  (keadaan) =>
      Icon(keadaan.contains(WidgetState.selected) ? Icons.check : Icons.close),
);

/// Keadaan saklar sebagai status statis (ikon + kata) untuk layar baca-saja.
StatusTampil _statusStatis(bool aktif) => aktif
    ? const StatusTampil('Aktif', NadaStatus.lulus, Icons.check)
    : const StatusTampil('Nonaktif', NadaStatus.netral, Icons.close);

/// Satu baris saklar. Seluruh baris adalah sasaran ketuk (setinggi baris,
/// tidak hanya saklarnya), dan pembaca layar menerima SATU simpul: label
/// (nama, penjelasan, serta "Menyimpan." atau alasan gagal), keadaan hidup/mati
/// (`toggled`), dan aksi ketuk. Saklar di dalamnya tidak ikut disuarakan
/// sendiri supaya tidak terbaca dua kali. Pada keadaan baca-saja saklar diganti
/// penanda statis (ikon + kata) yang berkontras penuh.
class _BarisSaklar extends StatelessWidget {
  const _BarisSaklar({
    super.key,
    required this.kategori,
    required this.nilai,
    required this.tahap,
    required this.pesanGagal,
    required this.bisaUbah,
    required this.onUbah,
  });

  final KategoriKabar kategori;
  final bool nilai;
  final TahapSimpan tahap;
  final String? pesanGagal;
  final bool bisaUbah;
  final ValueChanged<bool> onUbah;

  @override
  Widget build(BuildContext context) {
    final t = context.teks;
    final s = context.skema;
    final menyimpan = tahap == TahapSimpan.menyimpan;
    final gagal = tahap == TahapSimpan.gagal && pesanGagal != null;
    final label = StringBuffer('${kategori.judul}. ${kategori.penjelasan}');
    if (menyimpan) label.write(' Menyimpan.');
    if (gagal) label.write(' $pesanGagal');

    return Semantics(
      container: true,
      label: label.toString(),
      toggled: nilai,
      enabled: bisaUbah,
      onTap: bisaUbah ? () => onUbah(!nilai) : null,
      // Kegagalan diumumkan begitu muncul; "Menyimpan." tidak (terlalu ramai).
      liveRegion: gagal,
      excludeSemantics: true,
      child: BarisSidik(
        kompak: false,
        panah: false,
        judul: kategori.judul,
        onTap: bisaUbah ? () => onUbah(!nilai) : null,
        baris: [
          Text(kategori.penjelasan, style: t.bodySmall),
          if (menyimpan) Text('Menyimpan…', style: t.bodySmall),
          if (gagal) _PesanGagal(pesan: pesanGagal!),
        ],
        // Baca-saja: bukan saklar yang dimatikan (gaya disabled Material 3
        // hampir tak terlihat), melainkan penanda statis berkontras penuh.
        akhir: bisaUbah
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ExcludeFocus(
                    child: Switch(
                      value: nilai,
                      onChanged: onUbah,
                      thumbIcon: _ikonSaklar,
                    ),
                  ),
                  Text(
                    nilai ? 'Aktif' : 'Nonaktif',
                    style: t.labelMedium?.copyWith(color: s.onSurfaceVariant),
                  ),
                ],
              )
            : Stempel(_statusStatis(nilai), tenang: true),
      ),
    );
  }
}

class _PesanGagal extends StatelessWidget {
  const _PesanGagal({required this.pesan});

  final String pesan;

  @override
  Widget build(BuildContext context) {
    final gagal = context.warna.gagal;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.error_outline, size: UkuranIkon.kecil, color: gagal),
        const SizedBox(width: Spasi.xs),
        Expanded(
          child: Text(
            pesan,
            style: context.teks.bodySmall?.copyWith(color: gagal),
          ),
        ),
      ],
    );
  }
}
