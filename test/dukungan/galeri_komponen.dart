// Galeri komponen bersama (`lib/widgets`) untuk harness render: tiap komponen
// dalam semua keadaannya (normal, kosong, panjang, galat). Dipakai
// `test/tampilan/render_komponen_test.dart`, yang memeriksa luapan, kontras,
// pedoman sentuh+label, dan menulis PNG. Data sintetis, tanpa pelanggan nyata.
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show OverflowBoxFit;

import 'package:sidik_pelanggan/core/tema/spasi.dart';
import 'package:sidik_pelanggan/models/data_pelanggan.dart';
import 'package:sidik_pelanggan/models/status_berlaku.dart';
import 'package:sidik_pelanggan/widgets/angka_hari.dart';
import 'package:sidik_pelanggan/widgets/bagian.dart';
import 'package:sidik_pelanggan/widgets/baris_alat.dart';
import 'package:sidik_pelanggan/widgets/baris_sidik.dart';
import 'package:sidik_pelanggan/widgets/fakta.dart';
import 'package:sidik_pelanggan/widgets/garis_waktu_tahap.dart';
import 'package:sidik_pelanggan/widgets/jejak_tahap.dart';
import 'package:sidik_pelanggan/widgets/kalimat_utama.dart';
import 'package:sidik_pelanggan/widgets/keadaan_teks.dart';
import 'package:sidik_pelanggan/widgets/kolom_cari_utuh.dart';
import 'package:sidik_pelanggan/widgets/nomor_sidik.dart';
import 'package:sidik_pelanggan/widgets/panel_sidik.dart';
import 'package:sidik_pelanggan/widgets/pemetaan_status.dart';
import 'package:sidik_pelanggan/widgets/peta_jatuh_tempo.dart';
import 'package:sidik_pelanggan/widgets/plat_nama.dart';
import 'package:sidik_pelanggan/widgets/ringkasan_perhatian.dart';
import 'package:sidik_pelanggan/widgets/saringan_teks.dart';
import 'package:sidik_pelanggan/widgets/skala_tempo.dart';
import 'package:sidik_pelanggan/widgets/status_tampil.dart';
import 'package:sidik_pelanggan/widgets/stempel.dart';
import 'package:sidik_pelanggan/widgets/tautan_baris.dart';
import 'package:sidik_pelanggan/widgets/tik_paket.dart';

import 'fixture_komponen.dart';

/// Caption kecil di atas tiap contoh (hanya untuk galeri; bukan komponen).
class _Catatan extends StatelessWidget {
  const _Catatan(this.teks);
  final String teks;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: Spasi.xl, bottom: Spasi.sm),
    child: Text(teks, style: Theme.of(context).textTheme.bodySmall),
  );
}

/// Komponen yang membawa margin halamannya sendiri ([SaringanTeks],
/// [KolomCariUtuh]) dilepas dari margin galeri, supaya tidak berlipat dua.
class _TepiPenuh extends StatelessWidget {
  const _TepiPenuh({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, b) {
      final lebar = b.maxWidth + 2 * Spasi.sisi;
      return OverflowBox(
        minWidth: lebar,
        maxWidth: lebar,
        fit: OverflowBoxFit.deferToChild,
        child: child,
      );
    },
  );
}

Widget _dalamPanel(Widget anak) => PanelSidik(
  anak: [Padding(padding: Spasi.kartu, child: anak)],
);

BarisAlat _alat({
  String nama = 'Jangka Sorong Digital',
  String? merk = 'Mitutoyo',
  String? model = 'CD-15CPX',
  String? serial = '2201-0457',
  int? hari = -4,
  String? kode,
  String? label,
}) => BarisAlat(
  nama: nama,
  merk: merk,
  model: model,
  serial: serial,
  hari: hari,
  garisWaktu: kode == null ? null : garisWaktuUji(sekarang: 1),
  kodeTahap: kode,
  labelTahap: label,
  onTap: () {},
);

/// Halaman A: baris (Beranda "Perlu perhatian", daftar alat), stempel, nomor.
Widget galeriBaris() => Column(
  crossAxisAlignment: CrossAxisAlignment.stretch,
  children: [
    const _Catatan('RingkasanPerhatian (Beranda)'),
    RingkasanPerhatian(
      butir: [
        _alat(kode: 'dikalibrasi', label: 'Sedang dikalibrasi'),
        _alat(
          nama: 'Timbangan Analitik',
          merk: 'Mettler Toledo',
          model: 'XPR205',
          serial: 'B419223017',
          hari: 12,
        ),
        BarisSidik(
          awal: (k) =>
              AngkaKata('2', 'alat', nada: NadaStatus.lulus, kompak: k),
          judul: 'Paket siap diambil',
          semantik: 'Paket siap diambil, 2 alat',
          onTap: () {},
          baris: const [
            Fakta('Order', nomorOrderUji, nomor: true, tumpuk: true),
            Text('Timbangan Platform 300 kg dan 1 alat lain'),
          ],
        ),
      ],
      total: 3,
      teksLihatSemua: 'Lihat semua alat (9)',
      semantikLihatSemua: 'Lihat semua alat, sembilan',
      onLihatSemua: () {},
    ),
    const _Catatan('BarisAlat: normal, panjang, kosong, jauh, siap diambil'),
    PanelSidik(
      anak: [
        _alat(
          hari: 45,
          kode: 'menunggu_pemeriksaan',
          label: 'Hasil sedang diperiksa',
        ),
        _alat(
          nama: namaAlatPanjang,
          merk: 'Merk Dengan Nama Sangat Panjang Sekali',
          model: 'Model-Seri-Panjang-12345',
          serial: 'SN-0000-1111-2222-3333',
          hari: 3,
        ),
        _alat(
          nama: 'Alat Tanpa Data',
          merk: null,
          model: null,
          serial: null,
          hari: null,
        ),
        _alat(
          nama: 'Mikrometer Sekrup',
          merk: 'Mitutoyo',
          model: '293-240',
          serial: '7740191',
          hari: 200,
        ),
        _alat(
          nama: 'Manometer 0–10 bar',
          merk: 'WIKA',
          model: '232.50',
          serial: 'M-77012',
          hari: 75,
          kode: 'siap_diambil',
          label: 'Siap diambil',
        ),
      ],
    ),
    const _Catatan('Stempel: pengecualian, tenang, panjang'),
    Wrap(
      spacing: Spasi.sm,
      runSpacing: Spasi.sm,
      children: [
        Stempel(statusAlat(StatusKalibrasi.lewat)),
        Stempel(statusKeputusan('FAIL')!),
        Stempel(statusBerlaku(StatusBerlaku.berakhir)),
        Stempel(statusBerlaku(StatusBerlaku.dibatalkan)),
        Stempel(statusBerlaku(StatusBerlaku.berlaku), tenang: true),
        Stempel(statusKeputusan('PASS')!, tenang: true),
        const Stempel(
          StatusTampil(
            'Sertifikat ini telah digantikan oleh revisi yang lebih baru',
            NadaStatus.awas,
            Icons.swap_horiz,
          ),
        ),
      ],
    ),
    const _Catatan('BarisSidik bernomor: tidak putus di tengah'),
    PanelSidik(
      anak: [
        BarisSidik(
          judul: nomorOrderUji,
          gayaNomor: true,
          onTap: () {},
          baris: const [
            Fakta('Target selesai', '16 Nov 2026'),
            TikPaket(tik: [TahapTik.selesai, TahapTik.jalan, TahapTik.baru]),
          ],
        ),
        BarisSidik(
          judul: nomorOrderPanjang,
          gayaNomor: true,
          onTap: () {},
          baris: const [Fakta('Masuk', '9 Nov 2026')],
        ),
        const BarisSidik(
          judul: 'Baris statis tanpa ketuk',
          baris: [Text('Tanpa panah')],
        ),
      ],
    ),
  ],
);

/// Halaman B: jejak tahap, tik paket, garis waktu, skala tempo, peta.
Widget galeriJejak() => Column(
  crossAxisAlignment: CrossAxisAlignment.stretch,
  children: [
    const _Catatan(
      'JejakTahap: enam langkah, tujuh langkah (dikerjakan ulang)',
    ),
    _dalamPanel(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          JejakTahap(
            garisWaktu: garisWaktuUji(sekarang: 1),
            kata: 'Di lab: Sedang dikalibrasi',
          ),
          const SizedBox(height: Spasi.lg),
          JejakTahap(
            garisWaktu: garisWaktuUji(sekarang: 2, tambahUlang: true),
            kata: 'Di lab: Sedang dikerjakan ulang',
          ),
          const SizedBox(height: Spasi.lg),
          JejakTahap(
            garisWaktu: garisWaktuUji(sekarang: 4),
            kata: 'Di lab: Siap diambil',
            nadaKata: NadaStatus.lulus,
          ),
        ],
      ),
    ),
    const _Catatan('TikPaket: empat alat, dari jumlah, seratus alat'),
    _dalamPanel(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TikPaket.dariTahap(const [
            'sertifikat_terbit',
            'dikalibrasi',
            'diterima',
            'diterima',
          ]),
          const SizedBox(height: Spasi.lg),
          TikPaket.dariJumlah(jumlahAlat: 3, jumlahSelesai: 3),
          const SizedBox(height: Spasi.lg),
          TikPaket.dariTahap([
            for (var i = 0; i < 100; i++)
              i < 40
                  ? 'siap_diambil'
                  : i < 70
                  ? 'dikalibrasi'
                  : 'diterima',
          ]),
        ],
      ),
    ),
    const _Catatan('GarisWaktuTahap: tujuh langkah + "Menunggu"'),
    _dalamPanel(
      GarisWaktuTahap(
        langkah: garisWaktuUji(sekarang: 1, tambahUlang: true),
        catatan: GarisWaktuTahap.menunggu(const [
          'Jangka Sorong Digital',
          'Mikrometer Sekrup',
        ]),
      ),
    ),
    const _Catatan(
      'SkalaTempo: lewat jadwal, 12 hari, di luar jendela, hari ini',
    ),
    _dalamPanel(
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SkalaTempo(hari: -4, jadwal: DateTime(2026, 11, 9)),
          const SizedBox(height: Spasi.xl),
          SkalaTempo(hari: 12, jadwal: DateTime(2026, 11, 25)),
          const SizedBox(height: Spasi.xl),
          SkalaTempo(hari: 200, jadwal: DateTime(2027, 6, 1), kata: false),
          const SizedBox(height: Spasi.xl),
          SkalaTempo(hari: 0, jadwal: DateTime(2026, 11, 13)),
          const SizedBox(height: Spasi.xl),
          const AngkaHari(-4, bintang: true),
          const SizedBox(height: Spasi.lg),
          const AngkaHari(null, bintang: true),
        ],
      ),
    ),
    const _Catatan('PetaJatuhTempo: berisi, nol, tiga digit'),
    PetaJatuhTempo(
      onZona: (_) {},
      zona: const [
        ZonaTempo(label: 'Lewat jadwal', jumlah: 1, nada: NadaStatus.gagal),
        ZonaTempo(label: 'Dalam 30 hari', jumlah: 1, nada: NadaStatus.awas),
        ZonaTempo(label: '31 sampai 60 hari', jumlah: 2),
        ZonaTempo(label: '61 sampai 90 hari', jumlah: 1),
      ],
    ),
    const SizedBox(height: Spasi.md),
    PetaJatuhTempo(
      onZona: (_) {},
      zona: const [
        ZonaTempo(label: 'Lewat jadwal', jumlah: 0, nada: NadaStatus.gagal),
        ZonaTempo(label: 'Dalam 30 hari', jumlah: 0, nada: NadaStatus.awas),
        ZonaTempo(label: '31 sampai 60 hari', jumlah: 128),
        ZonaTempo(label: '61 sampai 90 hari', jumlah: 0),
      ],
    ),
  ],
);

/// Halaman C: kalimat utama, plat nama, fakta, saringan, cari, bagian,
/// tautan, keadaan, dan banner.
Widget galeriTeks() => Column(
  crossAxisAlignment: CrossAxisAlignment.stretch,
  children: [
    const _Catatan('KalimatUtama: perhatian dan tenang'),
    const KalimatUtama(
      dateline: 'Jumat, 13 November 2026',
      kalimat: [
        [
          PotonganKalimat('1 alat '),
          PotonganKalimat('lewat jadwal', nada: NadaStatus.gagal),
          PotonganKalimat('.'),
        ],
        [
          PotonganKalimat('1 paket '),
          PotonganKalimat('siap diambil', nada: NadaStatus.lulus),
          PotonganKalimat('.'),
        ],
      ],
    ),
    const SizedBox(height: Spasi.xl),
    const KalimatUtama.tenang(dateline: 'Jumat, 13 November 2026'),
    const _Catatan('PlatNama: lengkap, hanya seri, tanpa seri'),
    const PlatNama(
      seri: '2201-0457',
      fakta: [
        ('No. identifikasi', 'AST-0457'),
        ('Rentang ukur', '0–150 mm'),
        ('Catatan', null),
        ('Lokasi', 'Lab Mutu'),
      ],
    ),
    const SizedBox(height: Spasi.md),
    const PlatNama(seri: 'B419223017'),
    const SizedBox(height: Spasi.md),
    const PlatNama(seri: null, fakta: [('Lokasi', 'Gudang 3')]),
    const SizedBox(height: Spasi.md),
    const PlatNama(
      seri: nomorOrderPanjang,
      fakta: [('No. identifikasi', 'AST-0457-REVISI-DUA')],
    ),
    const _Catatan('Fakta dan NomorSidik'),
    const Fakta('Target selesai', '16 Nov 2026'),
    const SizedBox(height: Spasi.sm),
    const Fakta(
      'Alamat',
      'Jl. Kalibrasi Presisi No. 285, Kawasan Industri Timur, Jakarta 13920',
    ),
    const SizedBox(height: Spasi.sm),
    const Fakta('Catatan', null, kosong: 'Belum dicatat'),
    const SizedBox(height: Spasi.sm),
    const Fakta('Nomor order', nomorOrderUji, nomor: true, tumpuk: true),
    const SizedBox(height: Spasi.sm),
    const Fakta('Nomor order', nomorOrderPanjang, nomor: true, tumpuk: true),
    const SizedBox(height: Spasi.sm),
    const NomorSidik(nomorOrderUji),
    const _Catatan('SaringanTeks dan KolomCariUtuh'),
    _TepiPenuh(
      child: SaringanTeks(
        terpilih: 2,
        onPilih: (_) {},
        pilihan: const [
          PilihanSaringan('Semua', jumlah: 9),
          PilihanSaringan('Lewat jadwal', jumlah: 1),
          PilihanSaringan('Dalam 30 hari', jumlah: 1),
          PilihanSaringan('31 sampai 60 hari', jumlah: 2),
          PilihanSaringan('61 sampai 90 hari', jumlah: 2),
        ],
      ),
    ),
    _TepiPenuh(
      child: KolomCariUtuh(
        petunjuk: 'Cari nama, merk, atau nomor seri',
        onCari: (_) {},
      ),
    ),
    const _Catatan('Bagian dan TautanBaris'),
    Bagian(
      'Sedang dikerjakan di lab',
      jumlah: 3,
      aksi: 'Lihat semua',
      semantikAksi: 'Lihat semua paket di lab',
      onAksi: () {},
      tanpaJarakAtas: true,
    ),
    TautanBaris('Lihat semua alat (9)', onTap: () {}),
    const TautanBaris('Tautan tanpa aksi (mati)'),
    const _Catatan('KeadaanTeks: kosong, galat (aksi utama), tanpa aksi'),
    KeadaanTeks(
      judul: 'Tidak ada alat yang cocok',
      isi: 'Coba kata lain, atau tampilkan semua alat Anda.',
      aksi: 'Tampilkan semua alat',
      onAksi: () {},
    ),
    KeadaanTeks(
      judul: 'Beranda belum bisa dimuat',
      isi: 'Sambungan terputus. Periksa jaringan Anda, lalu coba lagi.',
      aksi: 'Coba lagi',
      onAksi: () {},
      utama: true,
    ),
    const KeadaanTeks(
      judul: 'Belum ada sertifikat',
      isi: 'Sertifikat muncul di sini setelah lab menerbitkannya.',
    ),
    const _Catatan('BannerDataTerakhir'),
    const BannerDataTerakhir(
      teks:
          'Tidak ada sambungan. Yang tampil adalah data terakhir, 12 Nov 2026 '
          '08.12.',
    ),
  ],
);

/// Semua halaman galeri menurut nama (dipakai harness dan tes pendaftaran).
final galeriHalaman = <String, Widget Function()>{
  'baris': galeriBaris,
  'jejak': galeriJejak,
  'teks': galeriTeks,
};
