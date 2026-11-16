import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/motion/gerak_bento.dart';
import '../../core/tema/bentuk.dart';
import '../../core/tema/elevasi.dart';
import '../../core/tema/spasi.dart';
import '../../core/tema/tipografi.dart';
import '../../core/tema/ukuran.dart';
import '../../core/tema/warna_sidik.dart';
import '../../models/data_pelanggan.dart';
import '../../models/status_berlaku.dart';
import '../../providers/data_provider.dart';
import '../../providers/koneksi_provider.dart';
import '../../providers/push_provider.dart';
import '../../providers/sesi_provider.dart';
import '../../widgets/banner.dart';
import '../../widgets/dasar/kontrol_ketuk.dart';
import '../../widgets/halaman_sidik.dart';
import '../../widgets/kalimat_utama.dart';
import '../../widgets/keadaan_teks.dart';
import '../../widgets/panel_sidik.dart';
import '../../widgets/pemetaan_status.dart';
import '../../widgets/status_tampil.dart';
import '../../widgets/tombol_bulat.dart';
import '../../widgets/tombol_sidik.dart';
import '../../widgets/ubin_alat.dart';
import '../../widgets/ubin_ringkas.dart';
import '../akun/bantuan_screen.dart';
import '../alat/alat_detail_screen.dart';
import '../alat/daftar_alat_screen.dart';
import '../gerbang.dart';
import '../paket/paket_screen.dart';
import '../rangka.dart';
import 'beranda_kapsul.dart';
import 'beranda_kerangka.dart';
import 'beranda_ringkas.dart';

/// Beranda Bento Lab (`docs/desain-ulang/LAYAR.md` 01): jawaban "apa yang
/// perlu saya perhatikan hari ini", lalu ringkasan dalam ubin.
///
/// Dari atas: kepala (avatar inisial, sapaan, nama; pil perusahaan HANYA untuk
/// akun anggota lebih dari satu perusahaan), kalimat utama dengan frasa status
/// ("1 alat lewat jadwal. 1 paket siap diambil."), ubin alat paling mendesak
/// (232; berwarna menurut statusnya), tombol "Lihat semua alat" berlencana
/// jumlah, panel "Jatuh tempo kalibrasi" (kapsul 90 hari), dua ubin pasangan
/// (sertifikat terbaru, paket dikerjakan), dan baris bantuan. Di tablet dua
/// kolom: ubin alat + tombol di kiri, panel + pasangan di kanan.
///
/// Empat keadaan: memuat ([KerangkaBeranda], statis), kosong (belum ada alat),
/// galat (`KeadaanTeks` dengan langkah berikutnya), dan tanpa koneksi (pil
/// "Offline. Data per ..." di atas data terakhir yang tetap terbaca).
///
/// Klaim di layar hanya dari data yang terbaca: "Semua alat berlaku" hanya
/// bila server menjaminnya, dan bagian yang masih dimuat atau gagal TIDAK
/// dibaca sebagai nol (kolom kapsul yang tak terbaca tidak digambar; ubin alat
/// menjadi kerangka atau catatan gagal).
///
/// Data: `GET /beranda` (angka, sertifikat terbaru, paket berjalan) dan
/// `GET /alat` (alat 0 sampai 90 hari, [jatuhTempoProvider]; membawa
/// `sedang_dikerjakan` per alat). Tarik layar untuk memuat ulang.
class BerandaScreen extends ConsumerStatefulWidget {
  const BerandaScreen({super.key});

  @override
  ConsumerState<BerandaScreen> createState() => _BerandaScreenState();
}

class _BerandaScreenState extends ConsumerState<BerandaScreen> {
  bool _izinDitawarkan = false;

  /// Animasi masuk ubin hanya saat isi pertama kali ditampilkan, bukan tiap
  /// data disegarkan (GERAK.md). Diubah [_Isi] begitu isi lengkap tampil.
  bool _sudahMasuk = false;

  Future<void> _segarkan() async {
    ref.invalidate(berandaProvider);
    ref.invalidate(jatuhTempoProvider);
    ref.invalidate(jumlahBelumDibacaProvider);
    try {
      await ref.read(berandaProvider.future);
    } catch (_) {
      // Galatnya tampil di layar (KeadaanTeks); jangan dilempar ke pemicu tarik.
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(berandaProvider);
    // Selama dimuat ulang karena perusahaan/akun berganti (`isReloading`),
    // nilai lama MASIH ada di `async.value`. Jangan dipakai: nama perusahaan
    // lama tidak boleh tampil sambil menunggu yang baru. Tarik-untuk-segarkan
    // (`isRefreshing`) tetap menampilkan data yang ada.
    final beranda = async.isReloading ? null : async.value;
    // Momen kontekstual izin notifikasi (REQ-NTF-08): begitu pengguna melihat
    // alatnya untuk pertama kali, pengingat jadwal punya alasan yang jelas.
    // `tawarkanNotifikasi` sendiri sekali per HP dan diam kalau izin sudah ada.
    if (!_izinDitawarkan && (beranda?.jumlahAlat ?? 0) > 0) {
      _izinDitawarkan = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) tawarkanNotifikasi(context, ref);
      });
    }
    final adaBannerIzin = ref.watch(bannerIzinProvider);

    return HalamanSidik(
      lebarMaks: Spasi.lebarLebar,
      // Tanpa app bar: kepala Beranda ada di dalam isi, jadi tepi atas sistem
      // dijaga di sini.
      isi: SafeArea(
        bottom: false,
        child: Column(
          children: [
            if (adaBannerIzin)
              const Padding(
                padding: EdgeInsets.fromLTRB(
                  Spasi.sisi,
                  Spasi.lg,
                  Spasi.sisi,
                  0,
                ),
                child: BannerIzinNotifikasi(),
              ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _segarkan,
                child: async.when(
                  loading: () => const KerangkaBeranda(),
                  error: (e, _) => _GalatBeranda(
                    galat: e,
                    cobaLagi: () => ref.invalidate(berandaProvider),
                  ),
                  data: (b) => _Isi(
                    beranda: b,
                    bolehAnimasi: () => !_sudahMasuk,
                    tandaiMasuk: () => _sudahMasuk = true,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Teks banner offline, dipakai isi dan keadaan galat. Pendek SENGAJA: dua
/// baris paling banyak di 320 dp x huruf 1,3, supaya isi di bawahnya tidak
/// terdorong keluar dari layar pertama. [sekarang] = hari ini (jam HP hanya
/// untuk memilih "08.12" atau "10 Nov, 08.12").
String _teksOffline(KeadaanKoneksi k, DateTime sekarang) =>
    k.dataTerakhir == null
    ? 'Offline. Data mungkin sudah lama.'
    : 'Offline. Data per '
          '${Format.jamAtauTanggal(k.dataTerakhir!, sekarang: sekarang)}.';

/// Bagian lebar baris kepala yang boleh dipakai pil perusahaan.
const double _bagianPil = 0.45;

/// Kepala layar (T 48): avatar inisial, sapaan, nama, dan pil perusahaan bila
/// ada. Nama dan sapaan dari akun yang masuk, bukan dari data perusahaan.
class _KepalaBeranda extends StatelessWidget {
  const _KepalaBeranda({
    required this.sapaan,
    required this.nama,
    this.perusahaan,
    this.onGanti,
  });

  final String sapaan;
  final String nama;

  /// Nama perusahaan aktif; null = tanpa pil (akun satu perusahaan).
  final String? perusahaan;
  final VoidCallback? onGanti;

  @override
  Widget build(BuildContext context) {
    final t = context.teks;
    final s = context.skema;
    return LayoutBuilder(
      builder: (context, batas) => Row(
        children: [
          _Avatar(inisial: inisialNama(nama)),
          const SizedBox(width: Spasi.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nama.isEmpty ? sapaan : '$sapaan,',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: t.labelMedium?.copyWith(
                    color: s.onSurfaceVariant,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                if (nama.isNotEmpty)
                  Text(
                    nama,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: t.titleSmall,
                  ),
              ],
            ),
          ),
          if (perusahaan != null) ...[
            const SizedBox(width: Spasi.sm),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: batas.maxWidth * _bagianPil,
              ),
              child: _PilPerusahaan(nama: perusahaan!, onTap: onGanti),
            ),
          ],
        ],
      ),
    );
  }
}

/// Avatar inisial 48: navy, inisial putih (sama di dua tema). Hiasan: nama ada
/// di sebelahnya.
class _Avatar extends StatelessWidget {
  const _Avatar({required this.inisial});

  final String inisial;

  @override
  Widget build(BuildContext context) {
    final w = context.warna;
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: UkuranUbin.avatar,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: context.warna.tintaUbin,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: inisial.isEmpty
                ? Icon(
                    Icons.person_outline,
                    size: UkuranIkon.sedang,
                    color: w.kertasUbin,
                  )
                : Text(
                    inisial,
                    style: context.teks.titleSmall?.copyWith(
                      color: w.kertasUbin,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

/// Chip perusahaan (T 40 putih, sudut 12; ikon 14 + nama 12/600) yang membuka pilihan
/// perusahaan. Area sentuh 48 dp ([KontrolKetuk]); nama panjang satu baris.
class _PilPerusahaan extends StatelessWidget {
  const _PilPerusahaan({required this.nama, required this.onTap});

  final String nama;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final s = context.skema;
    return Semantics(
      container: true,
      child: KontrolKetuk(
        onTap: onTap,
        semantik: 'Ganti perusahaan, sekarang $nama',
        warna: s.surface,
        sudut: Bentuk.sudutKapsul,
        sisi: BorderSide(color: s.outlineVariant, width: Elevasi.garis),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: UkuranKontrol.tombolBulatUbin,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: Spasi.md),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.business_outlined,
                  size: UkuranIkon.stempel,
                  color: s.onSurface,
                ),
                const SizedBox(width: UkuranKontrol.stempelJarak),
                Flexible(
                  child: Text(
                    nama,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.teks.labelMedium?.copyWith(
                      color: s.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Keadaan tanpa koneksi: pil navy dengan ikon wifi coret dan kata. Data
/// terakhir tetap terbaca di bawahnya. Tumbuh ke bawah bila teks membungkus.
class _BannerTanpaKoneksi extends StatelessWidget {
  const _BannerTanpaKoneksi({required this.teks});

  final String teks;

  @override
  Widget build(BuildContext context) {
    final s = context.skema;
    return Semantics(
      container: true,
      liveRegion: true,
      label: teks,
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: s.primary,
          borderRadius: Bentuk.sudutKapsul,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AreaSentuh.minimum),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Spasi.lg,
              vertical: Spasi.sm,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.wifi_off,
                  size: UkuranIkon.sedang,
                  color: s.onPrimary,
                ),
                const SizedBox(width: Spasi.md),
                Expanded(
                  child: Text(
                    teks,
                    style: context.teks.bodySmall?.copyWith(
                      color: s.onPrimary,
                      fontWeight: TipografiSidik.beratLabel,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Beranda yang gagal dimuat: kepala + teks yang memberi langkah berikutnya.
class _GalatBeranda extends ConsumerWidget {
  const _GalatBeranda({required this.galat, required this.cobaLagi});

  final Object galat;
  final VoidCallback cobaLagi;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final koneksi = ref.watch(koneksiProvider);
    final nama = ref.watch(
      sesiProvider.select((s) => s.value?.akun.nama ?? ''),
    );
    final teks = teksGalatBeranda(galat);
    final sekarang = ref.read(jamHpProvider)();
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: Spasi.denganTepiBawah(
        context,
        const EdgeInsets.fromLTRB(Spasi.sisi, Spasi.lg, Spasi.sisi, Spasi.xl),
      ),
      children: [
        if (koneksi.offline) ...[
          _BannerTanpaKoneksi(teks: _teksOffline(koneksi, sekarang)),
          const SizedBox(height: Spasi.lg),
        ],
        _KepalaBeranda(sapaan: sapaanWaktu(sekarang), nama: nama),
        KeadaanTeks(
          judul: teks.judul,
          isi: teks.isi,
          aksi: teks.aksi,
          onAksi: teks.aksi == null ? null : cobaLagi,
          utama: true,
        ),
      ],
    );
  }
}

/// Isi Beranda (data terbaca). [bolehAnimasi] dibaca LANGSUNG setiap kali ubin
/// dibuat (lihat [_MasukSekali]); [tandaiMasuk] dipanggil begitu isi lengkap
/// (daftar alat tidak lagi memuat) sudah tampil, sesudahnya tidak ada lagi
/// animasi masuk.
class _Isi extends ConsumerStatefulWidget {
  const _Isi({
    required this.beranda,
    required this.bolehAnimasi,
    required this.tandaiMasuk,
  });

  final Beranda beranda;
  final bool Function() bolehAnimasi;
  final VoidCallback tandaiMasuk;

  @override
  ConsumerState<_Isi> createState() => _IsiState();
}

class _IsiState extends ConsumerState<_Isi> {
  /// Bagian yang masuk berurutan ke-[i]; [kunci] membuatnya lahir ulang bila
  /// isinya berganti jenis (kerangka -> ubin alat).
  Widget _masuk(int i, Widget anak, {Object? kunci}) => _MasukSekali(
    key: kunci == null ? null : ValueKey<Object>(kunci),
    indeks: i,
    boleh: widget.bolehAnimasi,
    child: anak,
  );

  @override
  Widget build(BuildContext context) {
    final b = widget.beranda;
    final koneksi = ref.watch(koneksiProvider);
    final jt = ref.watch(jatuhTempoProvider);
    // Hitungan perusahaan lama tidak boleh bocor saat hitungan perusahaan baru
    // masih dimuat.
    final r = jt.isReloading ? null : jt.value;
    final banyakPerusahaan = ref.watch(
      sesiProvider.select(
        (s) => s.value?.akun.lebihDariSatuPerusahaan ?? false,
      ),
    );
    final nama = ref.watch(
      sesiProvider.select((s) => s.value?.akun.nama ?? ''),
    );
    final jamHp = ref.read(jamHpProvider)();
    // "Hari ini" menurut server bila ada alat berjadwal (BR-08); jam HP hanya
    // cadangan.
    final sekarang =
        r?.urut.map((a) => a.hariIniServer).whereType<DateTime>().firstOrNull ??
        jamHp;

    void buka(Widget layar) => Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => layar));
    void keTabAlat() => ref.read(tabProvider.notifier).pilih(IndeksTab.alat);
    void keTabSertifikat() =>
        ref.read(tabProvider.notifier).pilih(IndeksTab.sertifikat);

    final paketSiap = paketSiapDiambil(b.paketBerjalan);
    final adaAlat = b.jumlahAlat > 0;

    // Server membatasi `paket_berjalan` (tiga terbaru) dan `sertifikat_terbaru`
    // (lima). Hitungan dari server (`ringkasan.*`, bila ada) menang dan pasti;
    // tanpa itu angka dari daftar hanya batas bawah dan tidak diklaim lebih.
    // Paket yang sudah diserahkan tidak "berjalan": tidak ikut hitungan daftar.
    final jumlahPaket = math.max(
      b.jumlahPaketBerjalan,
      paketBelumDiserahkan(b.paketBerjalan).length,
    );
    final paketTerpotong = jumlahPaket > b.paketBerjalan.length;
    final siapJumlah = b.paketSiapDiambil ?? paketSiap.length;
    final siapMungkinLebih = b.paketSiapDiambil == null && paketTerpotong;
    final baru = ringkasSertifikatBaru(
      b.sertifikatTerbaru,
      sekarang,
      dariServer: b.sertifikatBaru7Hari,
    );
    // "Berlaku" hanya bila server bilang semua alat berlaku; `jumlah_alat`
    // ikut menghitung alat yang belum pernah dikalibrasi.
    final semuaBerlaku = adaAlat && b.alatBerlaku == b.jumlahAlat;

    final kalimat = kalimatBeranda(
      jumlahAlat: b.jumlahAlat,
      lewat: b.lewatJatuhTempo,
      segera: b.segeraJatuhTempo,
      paketSiap: siapJumlah,
      paketSiapMungkinLebih: siapMungkinLebih,
      sertifikatBaru: baru.jumlah,
      sertifikatBaruMungkinLebih: baru.mungkinLebih,
      semuaBerlaku: semuaBerlaku,
      alatBelumPernah: b.alatBelumPernah ?? 0,
    );

    // ── Susunan bagian ───────────────────────────────────────────────────
    final kepala = _KepalaBeranda(
      sapaan: sapaanWaktu(jamHp),
      nama: nama,
      perusahaan: banyakPerusahaan && b.namaPerusahaan.isNotEmpty
          ? b.namaPerusahaan
          : null,
      onGanti: () => buka(const PilihPerusahaanScreen(bisaKembali: true)),
    );

    final kalimatUtama = KalimatUtama(
      dateline: '',
      kalimat: kalimat,
      kalimatKeduaRedup: true,
    );

    final pilihan = pilihUbinAlat(
      adaAlat: adaAlat,
      semuaBerlaku: semuaBerlaku,
      menungguAlat: b.lewatJatuhTempo + b.segeraJatuhTempo > 0,
      daftar: r,
      daftarMemuat: r == null && jt.isLoading,
    );
    // Isi lengkap sudah tampil (bukan kerangka): sesudah frame ini tidak ada lagi
    // animasi masuk, jadi ubin yang dibuat ulang karena data disegarkan
    // langsung tampil.
    if (pilihan.jenis != JenisUbinAlat.memuat) {
      WidgetsBinding.instance.addPostFrameCallback((_) => widget.tandaiMasuk());
    }
    final ubinAlatIsi = _ubinAlat(pilihan, buka);
    final ubinAlat =
        ubinAlatIsi == null || pilihan.jenis == JenisUbinAlat.memuat
        ? ubinAlatIsi
        : _masuk(0, ubinAlatIsi, kunci: pilihan.jenis);

    final tombolSemua = adaAlat
        ? _masuk(
            1,
            TombolSidik(
              label: 'Lihat semua alat',
              ragam: RagamTombol.utama,
              penuh: true,
              jumlah: b.jumlahAlat,
              satuanJumlah: 'alat',
              onPressed: keTabAlat,
            ),
          )
        : null;

    final panelKapsul = adaAlat
        ? _masuk(2, _panelJatuhTempo(b, r, buka))
        : null;

    final barisSertifikat = barisUbinSertifikat(b.sertifikatTerbaru);
    final stempelSertifikat = statusUbinSertifikat(
      b.sertifikatTerbaru,
      sekarang,
    );
    final barisPaket = barisUbinPaket(
      berjalan: b.paketBerjalan,
      jumlah: jumlahPaket,
      siap: siapJumlah,
      siapMungkinLebih: siapMungkinLebih,
    );
    final stempelPaket = statusUbinPaket(b.paketBerjalan);
    final pasangan = _pasangan(
      sertifikat: _masuk(
        3,
        UbinRingkas(
          judul: 'Sertifikat terbaru',
          kalimat: _kalimatUbin(barisSertifikat, teksSertifikatKosong),
          stempel: stempelSertifikat,
          aksi: 'Lihat semua',
          nada: nadaUbinSertifikat(stempelSertifikat),
          onTap: keTabSertifikat,
          semantik: _semantikUbin(
            'Sertifikat terbaru',
            barisSertifikat,
            stempelSertifikat,
            teksSertifikatKosong,
            'Lihat semua sertifikat',
          ),
        ),
      ),
      paket: _masuk(
        4,
        UbinRingkas(
          judul: 'Paket dikerjakan',
          kalimat: _kalimatUbin(barisPaket, teksPaketKosong),
          stempel: stempelPaket,
          aksi: 'Lihat semua',
          nada: nadaUbinPaket(stempelPaket),
          onTap: () => buka(const PaketScreen()),
          semantik: _semantikUbin(
            'Paket dikerjakan',
            barisPaket,
            stempelPaket,
            teksPaketKosong,
            'Lihat semua paket',
          ),
        ),
      ),
    );

    final bantuan = _masuk(
      5,
      _BarisBantuan(onTap: () => buka(const BantuanScreen())),
    );

    const jarak = SizedBox(height: Spasi.antarUbin);
    final banner = <Widget>[
      if (koneksi.offline) ...[
        _BannerTanpaKoneksi(teks: _teksOffline(koneksi, jamHp)),
        const SizedBox(height: Spasi.lg),
      ],
    ];

    return LayoutBuilder(
      builder: (context, batas) {
        final duaKolom = batas.maxWidth >= batasDuaKolomBeranda;
        final atas = <Widget>[
          ...banner,
          kepala,
          const SizedBox(height: jarakKalimatBeranda),
          kalimatUtama,
          const SizedBox(height: jarakKalimatBeranda),
        ];
        final kiri = <Widget>[
          ?ubinAlat,
          if (ubinAlat != null && tombolSemua != null) jarak,
          ?tombolSemua,
        ];
        final kanan = <Widget>[
          ?panelKapsul,
          if (panelKapsul != null) jarak,
          pasangan,
        ];
        return ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: Spasi.denganTepiBawah(
            context,
            const EdgeInsets.fromLTRB(
              Spasi.sisi,
              Spasi.lg,
              Spasi.sisi,
              Spasi.xxl,
            ),
          ),
          children: duaKolom
              ? [
                  ...atas,
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: kiri,
                        ),
                      ),
                      const SizedBox(width: Spasi.xl),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: kanan,
                        ),
                      ),
                    ],
                  ),
                  jarak,
                  bantuan,
                ]
              : [
                  ...atas,
                  ...kiri,
                  if (kiri.isNotEmpty) jarak,
                  ...kanan,
                  jarak,
                  bantuan,
                ],
        );
      },
    );
  }

  /// Ubin besar menurut [pilihUbinAlat]; null = tidak ada ubin.
  Widget? _ubinAlat(
    ({JenisUbinAlat jenis, Alat? alat}) pilihan,
    void Function(Widget) buka,
  ) {
    final a = pilihan.alat;
    switch (pilihan.jenis) {
      case JenisUbinAlat.kosong:
        return UbinRingkas(
          judul: 'Belum ada alat terdaftar',
          kalimat: 'Alat yang pernah dikalibrasi di PT Sidik muncul di sini.',
          // Keadaan kosong bukan peringatan: netral (krem = "perlu diperiksa").
        );
      case JenisUbinAlat.alatMendesak || JenisUbinAlat.jadwalTerdekat:
        return UbinAlat(
          beranda: true,
          nama: a!.nama,
          status: statusAlat(a.status),
          merkTipe: merkTipeAlat(a),
          serial: a.serial,
          hari: a.hariKeJatuhTempo,
          tanggal: tanggalUbinAlat(a),
          onTap: () => buka(AlatDetailScreen(id: a.id)),
        );
      case JenisUbinAlat.semuaBerlakuTerdekat:
        return UbinAlat(
          beranda: true,
          nama: 'Semua alat berlaku',
          status: statusBerlaku(StatusBerlaku.berlaku),
          merkTipe: 'Berikutnya: ${a!.nama}',
          hari: a.hariKeJatuhTempo,
          tanggal: tanggalUbinAlat(a),
          onTap: () => buka(AlatDetailScreen(id: a.id)),
        );
      case JenisUbinAlat.semuaBerlaku:
        return UbinRingkas(judul: 'Semua alat berlaku', nada: NadaStatus.lulus);
      case JenisUbinAlat.memuat:
        return const UbinAlatMemuat();
      case JenisUbinAlat.gagal:
        return const PanelSidik(
          padding: PanelSidik.paddingIsi,
          anak: [_CatatanGagal()],
        );
      case JenisUbinAlat.tidakAda:
        return null;
    }
  }

  /// Panel "Jatuh tempo kalibrasi": judul dan kapsul. Kolom 31–90 hari hanya
  /// bila daftar alat terbaca; tanpa itu tidak digambar (bukan angka nol).
  Widget _panelJatuhTempo(
    Beranda b,
    RingkasanJatuhTempo? r,
    void Function(Widget) buka,
  ) {
    const urutanFilter = [
      FilterAlat.lewatJadwal,
      FilterAlat.hari30,
      FilterAlat.hari60,
      FilterAlat.hari90,
    ];
    return PanelSidik(
      padding: PanelSidik.paddingIsi,
      anak: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: Spasi.sm,
              runSpacing: Spasi.xs,
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    'Jatuh tempo kalibrasi',
                    style: context.teks.titleMedium,
                  ),
                ),
                Text(
                  '90 hari ke depan',
                  style: context.teks.labelMedium?.copyWith(
                    color: context.skema.onSurfaceVariant,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
            const SizedBox(height: Spasi.md),
            KapsulJatuhTempo(
              animasi: widget.bolehAnimasi(),
              zona: [
                ZonaKapsul(
                  label: FilterAlat.lewatJadwal.label,
                  jumlah: b.lewatJatuhTempo,
                  nada: NadaStatus.gagal,
                ),
                ZonaKapsul(
                  label: '≤ 30 hari',
                  semantik: FilterAlat.hari30.label,
                  jumlah: b.segeraJatuhTempo,
                  nada: NadaStatus.awas,
                ),
                // 31 sampai 90 hari dihitung dari daftar alat; tanpa daftar
                // itu dua kolom terakhir tidak digambar.
                if (r != null) ...[
                  ZonaKapsul(
                    label: '31–60 hari',
                    jumlah: r.kelompok2.length,
                    nada: NadaStatus.tunggu,
                  ),
                  ZonaKapsul(
                    label: '61–90 hari',
                    jumlah: r.kelompok3.length,
                    nada: NadaStatus.lulus,
                  ),
                ],
              ],
              onZona: (i) =>
                  buka(DaftarAlatScreen(filterAwal: urutanFilter[i])),
            ),
          ],
        ),
      ],
    );
  }

  /// Dua ubin pasangan berdampingan; di bawah 340 dp bertumpuk. Tinggi
  /// disamakan supaya grid bento tidak bergerigi.
  Widget _pasangan({required Widget sertifikat, required Widget paket}) {
    const jarak = SizedBox(height: Spasi.antarUbin);
    if (MediaQuery.sizeOf(context).width < Spasi.batasKompak) {
      return Column(children: [sertifikat, jarak, paket]);
    }
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: sertifikat),
          const SizedBox(width: Spasi.antarUbin),
          Expanded(child: paket),
        ],
      ),
    );
  }

  String _kalimatUbin(List<String> baris, String kosong) =>
      baris.isEmpty ? kosong : baris.join('\n');

  String _semantikUbin(
    String judul,
    List<String> baris,
    List<StatusTampil> status,
    String kosong,
    String aksi,
  ) => [
    judul,
    ...(baris.isEmpty ? [kosong] : baris),
    for (final s in status) 'Status: ${s.label}',
    aksi,
  ].join('. ');
}

/// Daftar alat (31 sampai 90 hari dan alat yang mendesak) tidak terbaca.
class _CatatanGagal extends StatelessWidget {
  const _CatatanGagal();

  @override
  Widget build(BuildContext context) => Text(
    'Daftar alat belum bisa dimuat. Tarik layar ke bawah untuk mencoba '
    'lagi.',
    style: context.teks.bodyMedium?.copyWith(
      color: context.skema.onSurfaceVariant,
    ),
  );
}

/// Baris bantuan (T 76, pil, langit): judul, keterangan, dan penanda bulat 52
/// navy di kanan. Seluruh baris satu tombol; tumbuh bila teks membungkus.
class _BarisBantuan extends StatelessWidget {
  const _BarisBantuan({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (tinta, latar) = StatusTampil.ubinDari(context, NadaStatus.tunggu);
    final t = context.teks;
    return Semantics(
      container: true,
      child: KontrolKetuk(
        onTap: onTap,
        semantik: 'Hubungi lab: tanya jadwal, sertifikat, atau paket',
        warna: latar,
        sudut: Bentuk.sudutPanel,
        child: SizedBox(
          width: double.infinity,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: UkuranKontrol.tombolBulatBesar + 2 * Spasi.md,
            ),
            child: Padding(
              padding: const EdgeInsetsDirectional.only(
                start: Spasi.lg + Spasi.xs,
                end: Spasi.md,
                top: Spasi.sm,
                bottom: Spasi.sm,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Butuh bantuan? Hubungi lab',
                          style: t.titleSmall?.copyWith(color: tinta),
                        ),
                        Text(
                          'Tanya jadwal, sertifikat, atau paket',
                          style: t.labelMedium?.copyWith(
                            color: tinta,
                            fontWeight: TipografiSidik.beratKeterangan,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: Spasi.md),
                  const TombolBulat.hiasan(
                    ikon: Icons.headset_mic_outlined,
                    ukuran: UkuranTombolBulat.besar,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Membungkus bagian Beranda dengan masuk berurutan (pudar + naik 12 dp,
/// 35 ms per [indeks]) HANYA bila [boleh] mengizinkan saat bagian ini lahir:
/// Beranda belum pernah menampilkan isinya. Keputusannya diambil SEKALI dan
/// tidak berubah selama bagian itu hidup, jadi susunan pohonnya stabil (tidak
/// ada loncatan di tengah animasi); bagian yang dibuat ulang karena data
/// disegarkan langsung tampil. "Kurangi gerak" ditangani [MasukBerurutan].
class _MasukSekali extends StatefulWidget {
  const _MasukSekali({
    super.key,
    required this.indeks,
    required this.boleh,
    required this.child,
  });

  final int indeks;
  final bool Function() boleh;
  final Widget child;

  @override
  State<_MasukSekali> createState() => _MasukSekaliState();
}

class _MasukSekaliState extends State<_MasukSekali> {
  late final bool _animasi = widget.boleh();

  @override
  Widget build(BuildContext context) => _animasi
      ? MasukBerurutan(indeks: widget.indeks, child: widget.child)
      : widget.child;
}
