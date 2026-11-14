import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/tema/spasi.dart';
import '../../core/tema/ukuran.dart';
import '../../core/tema/warna_sidik.dart';
import '../../models/data_pelanggan.dart';
import '../../models/garis_tahap_pelanggan.dart';
import '../../models/paket.dart';
import '../../models/status_berlaku.dart';
import '../../providers/data_provider.dart';
import '../../providers/koneksi_provider.dart';
import '../../providers/push_provider.dart';
import '../../providers/sesi_provider.dart';
import '../../widgets/angka_hari.dart';
import '../../widgets/bagian.dart';
import '../../widgets/banner.dart';
import '../../widgets/baris_alat.dart';
import '../../widgets/baris_sidik.dart';
import '../../widgets/fakta.dart';
import '../../widgets/halaman_sidik.dart';
import '../../widgets/kalimat_utama.dart';
import '../../widgets/keadaan_teks.dart';
import '../../widgets/logo_sidik.dart';
import '../../widgets/panel_sidik.dart';
import '../../widgets/pemetaan_status.dart';
import '../../widgets/peta_jatuh_tempo.dart';
import '../../widgets/ringkasan_perhatian.dart';
import '../../widgets/status_tampil.dart';
import '../../widgets/stempel.dart';
import '../../widgets/tautan_baris.dart';
import '../../widgets/tik_paket.dart';
import '../akun/bantuan_screen.dart';
import '../alat/alat_detail_screen.dart';
import '../alat/daftar_alat_screen.dart';
import '../gerbang.dart';
import '../paket/paket_detail_screen.dart';
import '../paket/paket_screen.dart';
import '../rangka.dart';
import '../sertifikat/sertifikat_detail_screen.dart';
import 'beranda_kerangka.dart';
import 'beranda_ringkas.dart';

/// Beranda: jawaban "apa yang perlu saya perhatikan hari ini", lalu sisanya.
///
/// Dari atas: satu kalimat besar dengan frasa status berwarna ("1 alat lewat
/// jadwal. 1 paket siap diambil."), "Perlu perhatian" (alat lewat jadwal atau
/// segera, paket siap diambil; paling banyak tiga), "Sedang dikerjakan di lab"
/// (paket yang belum siap, satu tik per alat), peta jadwal 90 hari, sertifikat
/// terbaru, dan "Hubungi lab". Tanpa ubin KPI, tanpa chip di keadaan normal;
/// nama perusahaan hanya bila akun anggota lebih dari satu perusahaan. Di
/// tablet dua kolom.
///
/// Data: `GET /beranda` (angka, sertifikat terbaru, paket berjalan) dan
/// `GET /alat` (alat 0 sampai 90 hari, [jatuhTempoProvider]; membawa
/// `sedang_dikerjakan` per alat). Field baru itu opsional: server lama tanpa
/// `sedang_dikerjakan` atau `alat[]` di paket tetap tampil, tanpa tahap per
/// alat. Tarik layar untuk memuat ulang.
class BerandaScreen extends ConsumerStatefulWidget {
  const BerandaScreen({super.key});

  @override
  ConsumerState<BerandaScreen> createState() => _BerandaScreenState();
}

class _BerandaScreenState extends ConsumerState<BerandaScreen> {
  bool _izinDitawarkan = false;

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

    return HalamanSidik(
      judulKustom: const _JudulMerek(),
      lebarMaks: Spasi.lebarLebar,
      isi: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(Spasi.sisi, Spasi.md, Spasi.sisi, 0),
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
                data: (b) => _Isi(beranda: b),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Judul app bar Beranda: logo kecil + nama aplikasi.
class _JudulMerek extends StatelessWidget {
  const _JudulMerek();

  @override
  Widget build(BuildContext context) => Row(
    children: [
      const LogoSidik(tinggi: UkuranIkon.besar),
      const SizedBox(width: Spasi.md),
      Flexible(
        child: Text(
          'SIDIK Pelanggan',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: context.teks.titleMedium,
        ),
      ),
    ],
  );
}

/// Lebar area isi mulai mana Beranda dua kolom (lebar area isi, bukan layar:
/// di tablet 840 dp rel navigasi memakan sekitar 80 dp).
const double _batasDuaKolom = 680;

/// Teks banner offline, dipakai isi dan keadaan galat. Pendek SENGAJA: dua
/// baris paling banyak di 320 dp x huruf 1,3, supaya daftar di bawahnya tidak
/// terdorong keluar dari layar pertama. [sekarang] = hari ini (jam HP hanya
/// untuk memilih "08.12" atau "10 Nov, 08.12").
String _teksOffline(KeadaanKoneksi k, DateTime sekarang) =>
    k.dataTerakhir == null
    ? 'Offline. Data mungkin sudah lama.'
    : 'Offline. Data per '
          '${Format.jamAtauTanggal(k.dataTerakhir!, sekarang: sekarang)}.';

/// Beranda yang gagal dimuat: teks yang memberi langkah berikutnya.
class _GalatBeranda extends ConsumerWidget {
  const _GalatBeranda({required this.galat, required this.cobaLagi});

  final Object galat;
  final VoidCallback cobaLagi;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final koneksi = ref.watch(koneksiProvider);
    final teks = teksGalatBeranda(galat);
    final sekarang = ref.read(jamHpProvider)();
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: Spasi.denganTepiBawah(
        context,
        const EdgeInsets.fromLTRB(Spasi.sisi, Spasi.lg, Spasi.sisi, Spasi.xl),
      ),
      children: [
        if (koneksi.offline)
          BannerDataTerakhir(teks: _teksOffline(koneksi, sekarang)),
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

class _Isi extends ConsumerWidget {
  const _Isi({required this.beranda});

  final Beranda beranda;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final b = beranda;
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
    // "Hari ini" menurut server bila ada alat berjadwal (BR-08); jam HP hanya
    // cadangan.
    final sekarang =
        r?.urut.map((a) => a.hariIniServer).whereType<DateTime>().firstOrNull ??
        ref.read(jamHpProvider)();

    void buka(Widget layar) => Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => layar));
    void keTabAlat() => ref.read(tabProvider.notifier).pilih(IndeksTab.alat);

    final alatP = r == null ? const <Alat>[] : alatPerhatian(r);
    final paketSiap = paketSiapDiambil(b.paketBerjalan);
    final paketLab = paketDiLab(b.paketBerjalan).take(maksPaketDiLab).toList();
    final adaAlat = b.jumlahAlat > 0;

    // Server membatasi `paket_berjalan` (tiga terbaru) dan `sertifikat_terbaru`
    // (lima). Hitungan dari server (`ringkasan.*`, bila ada) menang dan pasti;
    // tanpa itu angka dari daftar hanya batas bawah dan tidak diklaim lebih.
    final jumlahPaket = math.max(b.jumlahPaketBerjalan, b.paketBerjalan.length);
    final paketTerpotong = jumlahPaket > b.paketBerjalan.length;
    final siapJumlah = b.paketSiapDiambil ?? paketSiap.length;
    final siapMungkinLebih = b.paketSiapDiambil == null && paketTerpotong;
    // Paket siap yang tidak terlihat: tautan ke semua paket (paket terlama
    // tidak boleh tersingkir diam-diam dari tiga paket terbaru).
    final tautanPaket = b.paketSiapDiambil != null
        ? b.paketSiapDiambil! > paketSiap.length
        : paketTerpotong && paketSiap.isEmpty;
    final baru = ringkasSertifikatBaru(
      b.sertifikatTerbaru,
      sekarang,
      dariServer: b.sertifikatBaru7Hari,
    );
    // "Berlaku" hanya bila server bilang semua alat berlaku; `jumlah_alat`
    // ikut menghitung alat yang belum pernah dikalibrasi.
    final semuaBerlaku = adaAlat && b.alatBerlaku == b.jumlahAlat;
    final tenang =
        b.lewatJatuhTempo == 0 && b.segeraJatuhTempo == 0 && siapJumlah == 0;

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

    // ── Perlu perhatian ──────────────────────────────────────────────────
    final pilih = pilihPerhatian(alatP, paketSiap);
    final butir = <Widget>[
      for (final a in pilih.alat)
        _barisAlat(a, () => buka(AlatDetailScreen(id: a.id))),
      for (final p in pilih.paket)
        _BarisPaketSiap(
          paket: p,
          onTap: () => buka(PaketDetailScreen(id: p.id)),
        ),
    ];
    final menungguAlat = b.lewatJatuhTempo + b.segeraJatuhTempo > 0;
    final List<Widget> perhatian;
    if (r == null && jt.isLoading && menungguAlat) {
      perhatian = const [
        Bagian('Perlu perhatian'),
        ExcludeSemantics(
          child: PanelSidik(anak: [BarisKerangka(), BarisKerangka()]),
        ),
      ];
    } else if (r == null && jt.hasError) {
      perhatian = [
        if (menungguAlat || butir.isNotEmpty) ...[
          Bagian(
            'Perlu perhatian',
            jumlah: butir.isEmpty ? null : butir.length,
          ),
          if (menungguAlat) const _CatatanGagal(),
          if (butir.isNotEmpty) PanelSidik(anak: butir),
        ],
      ];
    } else if (butir.isNotEmpty) {
      perhatian = [
        RingkasanPerhatian(butir: butir, total: alatP.length + siapJumlah),
      ];
    } else if (r != null && r.urut.isNotEmpty) {
      // Tenang: tidak ada yang perlu perhatian; tampilkan jadwal terdekat.
      final terdekat = r.urut.first;
      perhatian = [
        const Bagian('Jadwal terdekat'),
        PanelSidik(
          anak: [
            _barisAlat(terdekat, () => buka(AlatDetailScreen(id: terdekat.id))),
          ],
        ),
      ];
    } else {
      perhatian = const [];
    }

    // ── Susunan bagian ───────────────────────────────────────────────────
    final kiri = <Widget>[
      if (banyakPerusahaan && b.namaPerusahaan.isNotEmpty)
        _BarisPerusahaan(
          nama: b.namaPerusahaan,
          onGanti: () => buka(const PilihPerusahaanScreen(bisaKembali: true)),
        ),
      KalimatUtama(dateline: hariTanggal(sekarang), kalimat: kalimat),
      if (!adaAlat)
        Padding(
          padding: const EdgeInsets.only(top: Spasi.md),
          child: Text(
            'Alat yang pernah dikalibrasi di PT Sidik muncul di sini.',
            style: context.teks.bodyLarge?.copyWith(
              color: context.skema.onSurfaceVariant,
            ),
          ),
        ),
      ...perhatian,
      if (adaAlat)
        TautanBaris(
          'Lihat semua alat (${b.jumlahAlat})',
          onTap: keTabAlat,
          semantik: 'Lihat semua alat, ${b.jumlahAlat} alat',
        ),
    ];

    // Judul tanpa tautan di sisinya (patah jadi dua sampai tiga baris di
    // tablet dan di 320 dp x huruf 1,3); tautan di barisnya sendiri di bawah.
    final lab = <Widget>[
      if (paketLab.isNotEmpty) ...[
        const Bagian('Sedang dikerjakan di lab'),
        PanelSidik(
          anak: [
            for (final p in paketLab)
              _BarisPaketLab(
                paket: p,
                onTap: () => buka(PaketDetailScreen(id: p.id)),
              ),
          ],
        ),
      ],
      if (paketLab.isNotEmpty || tautanPaket)
        TautanBaris(
          'Lihat semua paket ($jumlahPaket)',
          onTap: () => buka(const PaketScreen()),
          semantik: 'Lihat semua paket, $jumlahPaket paket berjalan',
        ),
    ];

    // Keadaan tenang: tanpa peta. Empat angka sejajar terbaca seperti baris
    // KPI, dan "Jadwal terdekat" sudah menjawab.
    final peta = <Widget>[
      if (adaAlat && !tenang) ...[
        const Bagian('Jadwal 90 hari ke depan'),
        PetaJatuhTempo(
          zona: [
            ZonaTempo(
              label: FilterAlat.lewatJadwal.label,
              jumlah: b.lewatJatuhTempo,
              nada: NadaStatus.gagal,
            ),
            ZonaTempo(
              label: FilterAlat.hari30.label,
              jumlah: b.segeraJatuhTempo,
              nada: NadaStatus.awas,
            ),
            // 31 sampai 90 hari dihitung dari daftar alat; tanpa daftar itu
            // dua zona terakhir tidak digambar (bukan angka karangan).
            // Label singkat ("31–60 hari"): "Dalam 31–60 hari" patah di tanda
            // pisah ("Dalam 31–" / "60 hari") di kolom sesempit zona ini.
            if (r != null) ...[
              ZonaTempo(label: '31–60 hari', jumlah: r.kelompok2.length),
              ZonaTempo(label: '61–90 hari', jumlah: r.kelompok3.length),
            ],
          ],
          onZona: (i) => buka(
            DaftarAlatScreen(
              filterAwal: const [
                FilterAlat.lewatJadwal,
                FilterAlat.hari30,
                FilterAlat.hari60,
                FilterAlat.hari90,
              ][i],
            ),
          ),
        ),
      ],
    ];

    final sertifikat = <Widget>[
      Bagian(
        'Sertifikat terbaru',
        aksi: 'Lihat semua',
        semantikAksi: 'Lihat semua sertifikat',
        onAksi: () =>
            ref.read(tabProvider.notifier).pilih(IndeksTab.sertifikat),
      ),
      if (b.sertifikatTerbaru.isEmpty)
        Text(
          'Belum ada sertifikat yang terbit.',
          style: context.teks.bodyLarge?.copyWith(
            color: context.skema.onSurfaceVariant,
          ),
        )
      else
        PanelSidik(
          anak: [
            for (final s in b.sertifikatTerbaru.take(maksPerhatian))
              _BarisSertifikat(
                sertifikat: s,
                sekarang: sekarang,
                onTap: () => buka(SertifikatDetailScreen(id: s.id)),
              ),
          ],
        ),
    ];

    final kaki = <Widget>[
      const SizedBox(height: Spasi.xl),
      TautanBaris(
        'Hubungi lab',
        onTap: () => buka(const BantuanScreen()),
        semantik: 'Hubungi lab: tanya jadwal, sertifikat, atau paket',
      ),
    ];

    final banner = <Widget>[
      if (koneksi.offline) ...[
        BannerDataTerakhir(teks: _teksOffline(koneksi, sekarang)),
        const SizedBox(height: Spasi.lg),
      ],
    ];

    return LayoutBuilder(
      builder: (context, batas) {
        final duaKolom = batas.maxWidth >= _batasDuaKolom;
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
                  ...banner,
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 10,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [...kiri, ...peta],
                        ),
                      ),
                      const SizedBox(width: Spasi.xl),
                      Expanded(
                        flex: 9,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: Spasi.bagian),
                            ...lab,
                            ...sertifikat,
                          ],
                        ),
                      ),
                    ],
                  ),
                  ...kaki,
                ]
              : [...banner, ...kiri, ...lab, ...peta, ...sertifikat, ...kaki],
        );
      },
    );
  }

  /// Satu alat di "Perlu perhatian" / "Jadwal terdekat". Tahap di lab hanya
  /// bila server mengirim `sedang_dikerjakan`.
  Widget _barisAlat(Alat a, VoidCallback onTap) {
    final sd = a.sedangDikerjakan;
    return BarisAlat(
      nama: a.nama,
      merk: a.merk,
      model: a.model,
      serial: a.serial,
      hari: a.hariKeJatuhTempo,
      garisWaktu: sd == null
          ? null
          : (sd.garisWaktu ?? garisWaktuPelanggan(sd.tahap)),
      kodeTahap: sd?.tahap,
      labelTahap: sd?.tahapLabel,
      onTap: onTap,
    );
  }
}

/// Nama perusahaan aktif + "Ganti": hanya untuk akun yang anggota lebih dari
/// satu perusahaan (supaya jelas data siapa yang dibaca).
class _BarisPerusahaan extends StatelessWidget {
  const _BarisPerusahaan({required this.nama, required this.onGanti});

  final String nama;
  final VoidCallback onGanti;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: Spasi.sm),
    child: Row(
      children: [
        Expanded(
          child: Text(
            nama,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.teks.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        TextButton(
          onPressed: onGanti,
          child: Text(
            'Ganti',
            semanticsLabel: 'Ganti perusahaan, sekarang $nama',
          ),
        ),
      ],
    ),
  );
}

/// Daftar alat (31 sampai 90 hari dan "Perlu perhatian") tidak terbaca.
class _CatatanGagal extends StatelessWidget {
  const _CatatanGagal();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: Spasi.md),
    child: Text(
      'Daftar alat belum bisa dimuat. Tarik layar ke bawah untuk mencoba '
      'lagi.',
      style: context.teks.bodyMedium?.copyWith(
        color: context.skema.onSurfaceVariant,
      ),
    ),
  );
}

/// Paket yang sudah siap diambil, di "Perlu perhatian". Jumlah alat sebagai
/// angka di awal baris; nama alat pertama (dan sisanya) bila server
/// mengirim daftar alatnya.
class _BarisPaketSiap extends StatelessWidget {
  const _BarisPaketSiap({required this.paket, required this.onTap});

  final Paket paket;
  final VoidCallback onTap;

  /// "Timbangan Platform 300 kg dan 1 alat lain"; `null` tanpa daftar alat.
  String? get _ringkas {
    if (paket.alat.isEmpty) return null;
    final lain = paket.alat.length - 1;
    return lain <= 0
        ? paket.alat.first.nama
        : '${paket.alat.first.nama} dan $lain alat lain';
  }

  @override
  Widget build(BuildContext context) {
    final ringkas = _ringkas;
    final jumlah = paket.jumlahAlat > 0 ? '${paket.jumlahAlat}' : '–';
    return BarisSidik(
      awal: (kompak) => AngkaKata(
        jumlah,
        'alat',
        nada: NadaStatus.lulus,
        kompak: kompak,
        semantik: paket.jumlahAlat > 0
            ? '$jumlah alat'
            : 'Jumlah alat belum ada',
      ),
      judul: 'Paket siap diambil',
      onTap: onTap,
      semantik:
          'Paket siap diambil. Order ${paket.nomor}.'
          '${ringkas == null ? '' : ' $ringkas.'}',
      baris: [
        Fakta('Order', paket.nomor, nomor: true, tumpuk: true),
        if (ringkas != null) Text(ringkas, style: context.teks.bodyMedium),
      ],
    );
  }
}

/// Satu paket yang masih dikerjakan lab: nomor order (selebar tetap, tidak
/// putus), target selesai, tahap paket (alat yang paling tertinggal), dan satu
/// tik per alat. Melewati target = satu-satunya stempel di baris ini.
class _BarisPaketLab extends StatelessWidget {
  const _BarisPaketLab({required this.paket, required this.onTap});

  final Paket paket;
  final VoidCallback onTap;

  static const _lewatTarget = StatusTampil(
    'Melewati target selesai',
    NadaStatus.awas,
    Icons.schedule,
  );

  @override
  Widget build(BuildContext context) {
    final p = paket;
    final targetTeks = Format.tanggal(p.tanggalJanjiSelesai, kosong: '');
    final tahapLengkap = p.alat.isNotEmpty && p.alat.length == p.jumlahAlat;
    final tik = tahapLengkap
        ? TikPaket.dariTahap([for (final a in p.alat) a.tahap])
        : TikPaket.dariJumlah(
            jumlahAlat: p.jumlahAlat,
            jumlahSelesai: p.jumlahSelesai,
          );
    return BarisSidik(
      judul: p.nomor,
      gayaNomor: true,
      onTap: onTap,
      semantik:
          'Paket ${p.nomor}. Tahap: ${p.tahapLabel}. '
          '${p.jumlahSelesai} dari ${p.jumlahAlat} alat selesai.'
          '${targetTeks.isEmpty ? '' : ' Target selesai $targetTeks.'}'
          '${p.terlambat ? ' Melewati target selesai.' : ''}',
      baris: [
        Fakta('Target selesai', targetTeks),
        Fakta('Tahap', p.tahapLabel),
        if (p.terlambat)
          const Padding(
            padding: EdgeInsets.only(top: Spasi.xs),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: Stempel(_lewatTarget),
            ),
          ),
        Padding(
          padding: const EdgeInsets.only(top: Spasi.sm),
          child: tik,
        ),
      ],
    );
  }
}

/// Satu sertifikat terbaru: nomor (selebar tetap), alat, masa berlaku, dan
/// tanggal terbit di ujung. Normal diam: stempel hanya untuk pengecualian
/// (tidak memenuhi toleransi, masa berlaku berakhir, digantikan, dibatalkan).
class _BarisSertifikat extends StatelessWidget {
  const _BarisSertifikat({
    required this.sertifikat,
    required this.sekarang,
    required this.onTap,
  });

  final Sertifikat sertifikat;
  final DateTime sekarang;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.teks;
    final s = sertifikat;
    final status = StatusBerlaku.dariSertifikat(s, sekarang: sekarang);
    final pengecualian = <StatusTampil>[
      if (s.keputusan == 'FAIL') statusKeputusan('FAIL')!,
      if (status == StatusBerlaku.berakhir ||
          status == StatusBerlaku.digantikan ||
          status == StatusBerlaku.dibatalkan)
        statusBerlaku(status),
    ];
    final terbit = Format.tanggal(s.diterbitkan, kosong: '');
    final berlaku = Format.tanggal(s.berlakuSampai, kosong: '');
    return BarisSidik(
      judul: s.nomor,
      gayaNomor: true,
      onTap: onTap,
      semantik:
          'Sertifikat ${s.nomor}'
          '${(s.namaAlat ?? '').isEmpty ? '' : ', ${s.namaAlat}'}'
          '${terbit.isEmpty ? '' : ', terbit $terbit'}'
          '${berlaku.isEmpty ? '' : ', berlaku sampai $berlaku'}'
          '${[for (final x in pengecualian) ', ${x.label.toLowerCase()}'].join()}',
      baris: [
        if ((s.namaAlat ?? '').isNotEmpty)
          Text(s.namaAlat!, style: t.bodyMedium),
        Fakta('Berlaku sampai', berlaku),
        for (final x in pengecualian)
          Padding(
            padding: const EdgeInsets.only(top: Spasi.sm),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: Stempel(x),
            ),
          ),
      ],
      akhir: s.diterbitkan == null
          ? null
          : Text(tanggalSingkat(s.diterbitkan), style: t.bodySmall),
    );
  }
}
