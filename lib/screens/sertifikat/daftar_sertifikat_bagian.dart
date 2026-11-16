import 'package:flutter/material.dart';

import '../../core/api_pelanggan.dart';
import '../../core/format.dart';
import '../../core/motion/app_motion.dart';
import '../../core/tema/bentuk.dart';
import '../../core/tema/elevasi.dart';
import '../../core/tema/spasi.dart';
import '../../core/tema/tipografi.dart';
import '../../core/tema/ukuran.dart';
import '../../core/tema/warna_sidik.dart';
import '../../models/data_pelanggan.dart';
import '../../providers/paginasi.dart';
import '../../widgets/dasar/cincin_fokus.dart';
import '../../widgets/nomor_sidik.dart';
import '../../widgets/pemetaan_status.dart';
import '../../widgets/status_tampil.dart';
import '../../widgets/stempel.dart';
import '../../widgets/tombol_sidik.dart';

// Bagian layar "Sertifikat" (sertifikat_screen.dart) yang hanya dipakai di
// sana: kerangka memuat statis, baris sertifikat, panel kosong, pil jumlah,
// baris sakelar, dan daftar berhalaman. Arah desain: REVISI-1 dan REVISI-2
// (16 Nov 2026), yang menggantikan arah Bento (bidang berwarna besar, sudut
// ekstrem): permukaan putih netral di atas latar abu kebiruan, warna hanya
// untuk status dan tindakan, kartu ringkas bergaris tipis tanpa bayangan.
//
// Daftar ditulis di sini, bukan memakai `DaftarBerhalaman`, karena kerangka
// `kerangka.dart` berdenyut tanpa henti (`repeat`) sedangkan layar ini
// meminta kerangka STATIS; `DaftarBerhalaman`, `kerangka.dart`, dan
// `KartuSertifikat` (dipakai Arsip) tidak diubah. Ukuran dan sudut baris
// memakai token yang ada (sudut 16 = `Bentuk.sudutKontrol`, padding 16);
// penyelarasan token bersama menyusul di langkah lain.

/// Jumlah sertifikat yang boleh DIKLAIM layar dari satu daftar berhalaman,
/// atau null bila belum terbaca utuh.
///
/// Semua halaman sudah dimuat: yang tampil itulah jumlahnya. Masih ada halaman:
/// hanya `total` dari server yang boleh dipercaya, dan hanya bila ia memang
/// lebih besar dari yang sudah dimuat (server yang tidak mengirim `total`
/// menjatuhkannya ke ukuran satu halaman). Selain itu tidak ada klaim.
int? jumlahSertifikatTerbaca(DataBerhalaman<Sertifikat> d) {
  if (!d.adaLagi) return d.isi.length;
  return d.total > d.isi.length ? d.total : null;
}

/// Bentuk kartu ringkas: putih (permukaan), sudut 16, garis tipis, tanpa
/// bayangan.
RoundedRectangleBorder _bentukKartu(BuildContext context) =>
    RoundedRectangleBorder(
      borderRadius: Bentuk.sudutKontrol,
      side: BorderSide(
        color: context.skema.outlineVariant,
        width: Elevasi.garis,
      ),
    );

/// Kerangka memuat STATIS: baris putih seukuran baris sertifikat dengan balok
/// abu sebesar isinya. Tanpa denyut dan tanpa animasi apa pun, jadi tidak ada
/// gerak berulang dan "kurangi gerak" tidak punya yang perlu dimatikan.
/// Pembaca layar menerima satu pengumuman "Memuat".
class KerangkaSertifikat extends StatelessWidget {
  const KerangkaSertifikat({super.key, this.jumlah = 6, this.padding});

  final int jumlah;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Memuat',
    liveRegion: true,
    child: ListView.separated(
      // Tetap bisa ditarik (RefreshIndicator) selama memuat.
      physics: const AlwaysScrollableScrollPhysics(),
      padding: padding ?? Spasi.daftar(context),
      itemCount: jumlah,
      separatorBuilder: (_, _) => const SizedBox(height: Spasi.antarUbin),
      itemBuilder: (_, _) => const BarisKerangkaSertifikat(),
    ),
  );
}

/// Satu baris kerangka: nama, nomor, tanggal, tanpa teks dan tanpa gerak.
class BarisKerangkaSertifikat extends StatelessWidget {
  const BarisKerangkaSertifikat({super.key});

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Material(
      color: context.skema.surface,
      clipBehavior: Clip.antiAlias,
      shape: _bentukKartu(context),
      child: const Padding(
        padding: EdgeInsets.all(Spasi.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Balok(lebar: 0.6, tinggi: Spasi.lg),
            SizedBox(height: Spasi.sm),
            _Balok(lebar: 0.45, tinggi: Spasi.md),
            SizedBox(height: Spasi.sm),
            _Balok(lebar: 0.3, tinggi: Spasi.md),
          ],
        ),
      ),
    ),
  );
}

/// Balok abu statis; [lebar] = bagian dari lebar baris (0 sampai 1).
class _Balok extends StatelessWidget {
  const _Balok({required this.lebar, required this.tinggi});

  final double lebar;
  final double tinggi;

  @override
  Widget build(BuildContext context) => FractionallySizedBox(
    widthFactor: lebar,
    child: SizedBox(
      height: tinggi,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: context.skema.surfaceContainerHigh,
          borderRadius: Bentuk.sudutKecil,
        ),
      ),
    ),
  );
}

/// Baris sertifikat ringkas: kartu putih bergaris tipis, sudut 16, padding 16,
/// satu tombol. Isi dari atas, urutan REVISI-2 butir 4: nama alat 17 (paling
/// banyak dua baris) → nomor sertifikat 14 `.nomor` ([NomorSidik], tidak
/// pernah putus di tengah angka) bersama nomor seri 14 `.nomor` (dua butir
/// sebaris, membungkus bila tidak muat) → tanggal terbit 14 → badge status
/// ([Stempel]: ikon + kata, istilah dari `pemetaan_status.dart`).
///
/// Badge: hasil teknis dulu (`PASS` hijau "Memenuhi toleransi", `FAIL` koral
/// "Tidak memenuhi toleransi", TIDAK dilunakkan; keputusan null = tanpa
/// badge, netral, tidak pernah hijau), lalu status dokumen bila bukan
/// "berlaku" (Digantikan, Dibatalkan). Sertifikat yang dibatalkan tidak
/// membawa hasil teknisnya.
///
/// Metadata kecil terakhir: `Jadwal kalibrasi ulang <tanggal>` 12, hanya bila
/// server mengirim `berlaku_sampai`, teks tersendiri di bawah baris tanggal
/// terbit + badge (di lebar telepon ia tidak muat di samping tanggal terbit:
/// 131 + 216 dp melebihi isi kartu 326 dp pada 390 dp). Maknanya, dicek di
/// API: masa berlaku yang dipilih admin saat menyetujui (bawaan 12 bulan dari
/// tanggal kalibrasi), yang juga jadwal pengingat. Kata "Berlaku sampai"
/// tidak dipakai supaya tidak tertukar dengan status dokumen (REVISI-2 butir
/// 5). Tanpa tanggalnya: tidak ada teks dan tidak ada baris kosong.
///
/// Badge sebaris dengan tanggal terbit bila muat, turun ke baris sendiri bila
/// tidak (pil "Tidak memenuhi toleransi" 207 dp turun sejak 390 dp, "Memenuhi
/// toleransi" 169 dp sejak 360 dp), jadi tinggi baris mengikuti isinya.
///
/// Pembaca layar menerima satu kalimat susunan dari isi baris, dengan aksi
/// ketuk pada simpul itu. Papan ketik: cincin fokus di luar kartu.
class BarisSertifikat extends StatelessWidget {
  const BarisSertifikat({
    super.key,
    required this.sertifikat,
    required this.onTap,
  });

  final Sertifikat sertifikat;
  final VoidCallback onTap;

  String? get _serial {
    final x = sertifikat.serial;
    return x == null || x.isEmpty ? null : x;
  }

  String? get _namaAlat {
    final x = sertifikat.namaAlat;
    return x == null || x.isEmpty ? null : x;
  }

  /// Badge yang tampil: hasil teknis dulu, lalu status dokumen bila bukan
  /// "berlaku".
  List<StatusTampil> get badge {
    final sr = sertifikat;
    final vonis = statusKeputusan(sr.keputusan);
    return [
      if (vonis != null && !sr.dibatalkan) vonis,
      if (sr.status != StatusDokumen.berlaku) statusDokumen(sr.status),
    ];
  }

  /// `Terbit <tanggal>`, atau null bila server tidak mengirim tanggalnya.
  String? get _teksTerbit => sertifikat.diterbitkan == null
      ? null
      : 'Terbit ${Format.tanggal(sertifikat.diterbitkan)}';

  /// `Jadwal kalibrasi ulang <tanggal>` (dari `berlaku_sampai`), atau null
  /// bila tidak ada. Satu sumber untuk tampilan dan kalimat pembaca layar.
  ///
  /// Hanya untuk sertifikat yang masih berlaku: jadwal di sertifikat yang
  /// dibatalkan atau sudah digantikan sudah usang (pengganti membawa jadwal
  /// yang benar) dan bisa dikira masih harus dipenuhi.
  String? get _teksJadwal =>
      sertifikat.berlakuSampai == null ||
          sertifikat.status != StatusDokumen.berlaku
      ? null
      : 'Jadwal kalibrasi ulang ${Format.tanggal(sertifikat.berlakuSampai)}';

  /// Kalimat untuk pembaca layar, urutan sama dengan tampilan.
  String get kalimat {
    final sr = sertifikat;
    return [
      ?_namaAlat,
      'Sertifikat ${sr.nomor}',
      if (_serial != null) 'Nomor seri $_serial',
      ?_teksTerbit,
      for (final s in badge) 'Status: ${s.label}',
      ?_teksJadwal,
    ].join('. ');
  }

  @override
  Widget build(BuildContext context) {
    final s = context.skema;
    final t = context.teks;
    final sr = sertifikat;
    final bentuk = _bentukKartu(context);
    final gayaKet = t.bodySmall?.copyWith(color: s.onSurfaceVariant);
    // Metadata kecil (12): lebih kecil dari tanggal terbit, bobot keterangan.
    final gayaJadwal = t.labelSmall?.copyWith(
      color: s.onSurfaceVariant,
      fontWeight: TipografiSidik.beratKeterangan,
    );
    final badgeAda = badge;
    final terbit = _teksTerbit;
    final jadwal = _teksJadwal;

    // Panah di baris nama (bukan kolom penuh di kanan): sisa isi memakai
    // seluruh lebar kartu, jadi tanggal terbit dan badge muat sebaris.
    final isi = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _namaAlat == null
                  ? const SizedBox.shrink()
                  : Text(
                      _namaAlat!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: t.titleMedium?.copyWith(color: s.onSurface),
                    ),
            ),
            const SizedBox(width: Spasi.sm),
            ExcludeSemantics(
              child: Icon(
                Icons.chevron_right,
                size: UkuranIkon.sedang,
                color: s.onSurfaceVariant,
              ),
            ),
          ],
        ),
        Wrap(
          spacing: Spasi.lg,
          children: [
            NomorSidik(
              sr.nomor,
              gaya: t.bodySmall?.copyWith(
                color: s.onSurface,
                fontWeight: TipografiSidik.beratLabel,
              ),
            ),
            if (_serial != null) Text('SN $_serial', style: gayaKet?.nomor),
          ],
        ),
        if (terbit != null || badgeAda.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: Spasi.sm),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: Spasi.sm,
              runSpacing: Spasi.sm,
              children: [
                if (terbit != null) Text(terbit, style: gayaKet),
                if (badgeAda.isNotEmpty)
                  Wrap(
                    spacing: Spasi.sm,
                    runSpacing: Spasi.xs,
                    children: [for (final x in badgeAda) Stempel(x)],
                  ),
              ],
            ),
          ),
        // Metadata kecil terakhir; tanpa tanggalnya tidak ada baris sama sekali.
        if (jadwal != null)
          Padding(
            padding: EdgeInsets.only(
              top: terbit != null || badgeAda.isNotEmpty ? Spasi.xs : Spasi.sm,
            ),
            child: Text(jadwal, style: gayaJadwal),
          ),
      ],
    );

    return Semantics(
      button: true,
      label: kalimat,
      onTap: onTap,
      excludeSemantics: true,
      child: CincinFokus(
        sudut: Bentuk.sudutKontrol,
        child: Material(
          color: s.surface,
          shape: bentuk,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            customBorder: bentuk,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: AreaSentuh.minimum),
              child: Padding(
                padding: const EdgeInsets.all(Spasi.lg),
                child: isi,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Panel kosong: kartu putih ringkas berisi ikon kecil, judul, satu kalimat,
/// dan (hasil cari kosong) filter yang sedang aktif beserta tombol
/// [labelReset] yang menghapusnya dan, bila ada filter bawaan yang ikut
/// menyempitkan hasil, tombol [labelLonggarkan] yang melepasnya. Dipakai untuk
/// "belum ada sertifikat" dan hasil cari yang kosong; pembedanya kata dan
/// [ikon], keduanya dari pemanggil. [filter] kosong = tanpa daftar filter;
/// [onReset] / [onLonggarkan] null = tanpa tombolnya.
class PanelKosongSertifikat extends StatelessWidget {
  const PanelKosongSertifikat({
    super.key,
    required this.ikon,
    required this.judul,
    required this.keterangan,
    this.filter = const [],
    this.onReset,
    this.labelReset = 'Hapus pencarian',
    this.onLonggarkan,
    this.labelLonggarkan = 'Tampilkan yang sudah digantikan',
  });

  final IconData ikon;
  final String judul;
  final String keterangan;
  final List<String> filter;
  final VoidCallback? onReset;
  final String labelReset;
  final VoidCallback? onLonggarkan;
  final String labelLonggarkan;

  @override
  Widget build(BuildContext context) {
    final s = context.skema;
    final t = context.teks;
    return Material(
      color: s.surface,
      clipBehavior: Clip.antiAlias,
      shape: _bentukKartu(context),
      child: Padding(
        padding: const EdgeInsets.all(Spasi.lg),
        child: Semantics(
          container: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ExcludeSemantics(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: s.surfaceContainer,
                    shape: BoxShape.circle,
                  ),
                  child: SizedBox.square(
                    dimension: UkuranUbin.ubinIkon,
                    child: Icon(
                      ikon,
                      size: UkuranIkon.sedang,
                      color: s.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: Spasi.md),
              Semantics(header: true, child: Text(judul, style: t.titleMedium)),
              const SizedBox(height: Spasi.xs),
              Text(keterangan, style: t.bodySmall),
              if (filter.isNotEmpty) ...[
                const SizedBox(height: Spasi.md),
                for (final f in filter)
                  Text(
                    f,
                    style: t.bodySmall?.copyWith(
                      color: s.onSurface,
                      fontWeight: TipografiSidik.beratLabel,
                    ),
                  ),
              ],
              if (onReset != null || onLonggarkan != null) ...[
                const SizedBox(height: Spasi.lg),
                Wrap(
                  spacing: Spasi.sm,
                  runSpacing: Spasi.sm,
                  children: [
                    if (onReset != null)
                      TombolSidik(
                        label: labelReset,
                        ikon: Icons.close,
                        ragam: RagamTombol.sekunder,
                        onPressed: onReset,
                      ),
                    if (onLonggarkan != null)
                      TombolSidik(
                        label: labelLonggarkan,
                        ikon: Icons.visibility_outlined,
                        ragam: RagamTombol.sekunder,
                        onPressed: onLonggarkan,
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Pil putih di kepala layar: "N sertifikat". Hanya digambar bila [jumlah]
/// benar-benar terbaca; memuat atau gagal = tidak ada pil, bukan "0
/// sertifikat".
class PilJumlahSertifikat extends StatelessWidget {
  const PilJumlahSertifikat({super.key, required this.jumlah});

  final int jumlah;

  /// Tinggi pil kepala: saringan 44 dikurangi 8 (36).
  static const double tinggi = UkuranKontrol.saringan - Spasi.sm;

  @override
  Widget build(BuildContext context) {
    final s = context.skema;
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: Spasi.sisi),
      child: Material(
        color: s.surface,
        shape: RoundedRectangleBorder(
          borderRadius: Bentuk.sudutPil,
          side: BorderSide(color: s.outlineVariant, width: Elevasi.garis),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: tinggi),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: Spasi.md),
            child: Center(
              widthFactor: 1,
              heightFactor: 1,
              child: Text(
                '$jumlah sertifikat',
                style: context.teks.bodySmall?.copyWith(
                  color: s.onSurface,
                  fontWeight: TipografiSidik.beratLabel,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Baris sakelar: kartu putih bergaris tipis, tinggi paling sedikit 48,
/// berisi [label] 14/700 dan rel 56 x 36 dengan tombol 28 (padding 4). Mati:
/// rel `latar` bertepi tegas, tombol `teksKedua`; nyala: rel navy, tombol
/// berisi centang (keadaan tidak hanya warna: letak tombol dan centang ikut
/// berubah). Warna rel dan tombol dibaca dari `SwitchThemeData` tema (satu
/// sumber, termasuk tema gelap).
///
/// Seluruh baris satu sakelar: ketukan di mana pun membalik nilai. Pembaca
/// layar menerima satu simpul berlabel [label] dengan `toggled`. Papan ketik:
/// Enter/Spasi membalik, cincin fokus di luar kartu. Tombol bergeser 120 ms
/// (`AppMotion.kilat`), langsung bila "kurangi gerak" menyala.
class BarisSakelar extends StatelessWidget {
  const BarisSakelar({
    super.key,
    required this.label,
    required this.nilai,
    required this.onUbah,
  });

  final String label;
  final bool nilai;
  final ValueChanged<bool> onUbah;

  @override
  Widget build(BuildContext context) {
    final s = context.skema;
    final tema = Theme.of(context).switchTheme;
    final keadaan = <WidgetState>{if (nilai) WidgetState.selected};
    final rel = tema.trackColor?.resolve(keadaan) ?? s.surfaceContainer;
    final tombol = tema.thumbColor?.resolve(keadaan) ?? s.onSurfaceVariant;
    final tepiRel = tema.trackOutlineColor?.resolve(keadaan) ?? s.outline;
    final bentuk = _bentukKartu(context);
    final durasi = AppMotion.hormati(context, AppMotion.kilat);
    const ruang = UkuranKontrol.sakelarTinggi - UkuranKontrol.sakelarTombol;

    return Padding(
      padding: const EdgeInsets.fromLTRB(Spasi.sisi, 0, Spasi.sisi, Spasi.xs),
      child: Semantics(
        container: true,
        toggled: nilai,
        label: label,
        onTap: () => onUbah(!nilai),
        excludeSemantics: true,
        child: CincinFokus(
          sudut: Bentuk.sudutKontrol,
          child: Material(
            color: s.surface,
            shape: bentuk,
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => onUbah(!nilai),
              customBorder: bentuk,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minHeight: AreaSentuh.minimum,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Spasi.lg,
                    vertical: Spasi.sm,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          label,
                          style: context.teks.bodySmall?.copyWith(
                            color: s.onSurface,
                            fontWeight: TipografiSidik.beratLabel,
                          ),
                        ),
                      ),
                      const SizedBox(width: Spasi.md),
                      AnimatedContainer(
                        duration: durasi,
                        width: UkuranKontrol.sakelarLebar,
                        height: UkuranKontrol.sakelarTinggi,
                        padding: const EdgeInsets.all(ruang / 2),
                        alignment: nilai
                            ? AlignmentDirectional.centerEnd
                            : AlignmentDirectional.centerStart,
                        decoration: BoxDecoration(
                          color: rel,
                          borderRadius: Bentuk.sudutPil,
                        ),
                        foregroundDecoration: BoxDecoration(
                          borderRadius: Bentuk.sudutPil,
                          border: Border.all(
                            color: tepiRel,
                            width: Elevasi.garis,
                          ),
                        ),
                        child: SizedBox.square(
                          dimension: UkuranKontrol.sakelarTombol,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: tombol,
                              shape: BoxShape.circle,
                            ),
                            child: nilai
                                ? Icon(
                                    Icons.check,
                                    size: UkuranIkon.kecil,
                                    color: rel,
                                  )
                                : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Daftar baris sertifikat bergulir: [kepala] di atas, satu [BarisSertifikat]
/// per sertifikat berjarak [Spasi.antarUbin], lalu [ujung] (bila ada) di
/// akhir. Baris berkunci id sertifikat.
class DaftarBarisSertifikat extends StatelessWidget {
  const DaftarBarisSertifikat({
    super.key,
    required this.sertifikat,
    required this.onBuka,
    this.kepala = const [],
    this.ujung,
    this.padding,
  }) : assert(sertifikat.length > 0, 'daftar kosong ditangani pemanggil');

  final List<Sertifikat> sertifikat;
  final ValueChanged<Sertifikat> onBuka;
  final List<Widget> kepala;
  final Widget? ujung;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final n = sertifikat.length;
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: padding ?? Spasi.daftar(context),
      itemCount: kepala.length + (n * 2 - 1) + (ujung == null ? 0 : 1),
      itemBuilder: (context, i) {
        if (i < kepala.length) return kepala[i];
        final j = i - kepala.length;
        if (j < n * 2 - 1) {
          if (j.isOdd) return const SizedBox(height: Spasi.antarUbin);
          final s = sertifikat[j ~/ 2];
          return BarisSertifikat(
            key: ValueKey<int>(s.id),
            sertifikat: s,
            onTap: () => onBuka(s),
          );
        }
        return ujung!;
      },
    );
  }
}

/// Ujung daftar berhalaman: galat halaman berikut ("Coba lagi"), pemuat
/// halaman berikut (baris kerangka statis), atau kalimat penutup. Halaman
/// berikut diminta begitu ujung ini dibangun, artinya pengguna sudah dekat
/// akhir daftar (sama dengan `DaftarBerhalaman`).
class UjungDaftarSertifikat extends StatelessWidget {
  const UjungDaftarSertifikat({
    super.key,
    required this.data,
    required this.muatLagi,
  });

  final DataBerhalaman<Sertifikat> data;
  final void Function({bool ulangiGalat}) muatLagi;

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
        padding: EdgeInsets.only(top: Spasi.antarUbin),
        child: BarisKerangkaSertifikat(),
      );
    }
    if (data.halaman > 1) {
      return Padding(
        padding: const EdgeInsets.only(top: Spasi.lg),
        child: Text(
          // Angka yang sama dengan pil di kepala layar (satu definisi): yang
          // sungguh termuat, bukan `total` mentah dari server.
          'Semua ${jumlahSertifikatTerbaca(data) ?? data.isi.length} '
          'sertifikat sudah tampil.',
          textAlign: TextAlign.center,
          style: t.bodySmall,
        ),
      );
    }
    return const SizedBox.shrink();
  }
}
