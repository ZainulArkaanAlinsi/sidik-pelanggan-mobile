import 'package:intl/intl.dart';

import '../../core/api_pelanggan.dart';
import '../../models/data_pelanggan.dart';
import '../../models/paket.dart';
import '../../models/status_berlaku.dart';
import '../../widgets/kalimat_utama.dart';
import '../../widgets/status_tampil.dart';

/// Logika murni Beranda: apa yang masuk kalimat utama, apa yang perlu
/// perhatian, paket mana yang di lab. Dipisah dari layar supaya bisa diuji
/// tanpa membangun widget.

/// Banyak butir "Perlu perhatian" yang digambar.
const int maksPerhatian = 3;

/// Banyak paket di "Sedang dikerjakan di lab".
const int maksPaketDiLab = 3;

/// Sertifikat yang terbit dalam sekian hari terakhir disebut "baru".
const int hariSertifikatBaru = 7;

/// Batas `sertifikat_terbaru` dari server (`BerandaController::BATAS`). Bila
/// semua sertifikat dalam daftar ini baru, jumlah sebenarnya bisa lebih.
const int batasSertifikatServer = 5;

/// Kode tahap paket yang berarti "siap diambil di lab".
const String tahapSiapDiambil = 'siap_diambil';

/// "Jumat, 13 November 2026".
String hariTanggal(DateTime t) =>
    DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(t);

/// "13 Nov": tanggal singkat di ujung baris (tahunnya ada di baris lain).
String tanggalSingkat(DateTime? t) =>
    t == null ? '' : DateFormat('d MMM', 'id_ID').format(t);

/// Alat yang masuk "Perlu perhatian": lewat jadwal (terlama dulu), lalu yang
/// jatuh tempo dalam jendela "segera" (terdekat dulu). Alat 31 sampai 90 hari
/// tidak ikut: itu tugas peta jadwal.
List<Alat> alatPerhatian(RingkasanJatuhTempo r) {
  int hari(Alat a) => a.hariKeJatuhTempo ?? 0;
  return [
    ...[...r.lewatJadwal]..sort((a, b) => hari(a).compareTo(hari(b))),
    ...[...r.kelompok1]..sort((a, b) => hari(a).compareTo(hari(b))),
  ];
}

/// Paket yang sudah siap diambil.
List<Paket> paketSiapDiambil(List<Paket> semua) => [
  for (final p in semua)
    if (p.tahap == tahapSiapDiambil) p,
];

/// Paket yang masih dikerjakan lab: bukan siap diambil dan bukan sudah
/// diserahkan. Tahap yang tidak dikenal ikut (tidak terbukti selesai).
List<Paket> paketDiLab(List<Paket> semua) => [
  for (final p in semua)
    if (p.tahap != tahapSiapDiambil && p.tahap != 'diserahkan') p,
];

/// Pembagian baris "Perlu perhatian" yang digambar: paling banyak
/// [maksPerhatian], dengan satu baris dicadangkan untuk paket siap diambil
/// bila ada. Tanpa itu, lima alat lewat jadwal menggusur paket yang justru
/// disebut kalimat utama dan tidak muncul di bagian lain.
({List<Alat> alat, List<Paket> paket}) pilihPerhatian(
  List<Alat> alat,
  List<Paket> paketSiap,
) {
  final kuotaAlat = paketSiap.isEmpty ? maksPerhatian : maksPerhatian - 1;
  final alatTampil = alat.take(kuotaAlat).toList();
  final paketTampil = paketSiap.take(maksPerhatian - alatTampil.length);
  return (alat: alatTampil, paket: paketTampil.toList());
}

/// Berapa sertifikat di [terbaru] yang terbit dalam [hariSertifikatBaru] hari
/// terakhir menurut [sekarang].
int hitungSertifikatBaru(List<Sertifikat> terbaru, DateTime sekarang) {
  var n = 0;
  for (final s in terbaru) {
    final h = StatusBerlaku.hariSampai(s.diterbitkan, sekarang);
    if (h != null && h <= 0 && h >= -hariSertifikatBaru) n++;
  }
  return n;
}

/// Sertifikat baru untuk kalimat utama. [dariServer] (`ringkasan.
/// sertifikat_baru_7_hari`) menang dan selalu pasti. Tanpa itu jumlah dihitung
/// dari [terbaru], yang dipotong server di [batasSertifikatServer] (urut dari
/// yang terbaru): bila semuanya baru, jumlah sebenarnya tidak diketahui
/// (`mungkinLebih`), jadi kalimat tidak boleh menyebut angka.
({int jumlah, bool mungkinLebih}) ringkasSertifikatBaru(
  List<Sertifikat> terbaru,
  DateTime sekarang, {
  int? dariServer,
}) {
  if (dariServer != null) return (jumlah: dariServer, mungkinLebih: false);
  final n = hitungSertifikatBaru(terbaru, sekarang);
  return (jumlah: n, mungkinLebih: n >= batasSertifikatServer);
}

/// Kalimat utama Beranda, paling banyak [KalimatUtama.maksimumKalimat].
///
/// Urutan prioritas: (1) alat lewat jadwal, (2) paket siap diambil, (3) alat
/// segera jatuh tempo, (4) sertifikat baru. Frasa berwarna adalah KATA status
/// ("lewat jadwal", "siap diambil"), bukan angka.
///
/// - [paketSiapMungkinLebih]: daftar paket dari server dipotong (tiga
///   terbaru), jadi jumlah paket siap diambil hanya batas bawah; kalimatnya
///   tidak menyebut angka ("Ada paket siap diambil.").
/// - [sertifikatBaruMungkinLebih]: sama untuk sertifikat baru ("Ada sertifikat
///   baru terbit.").
/// - Tanpa (1) sampai (3) dan [jumlahAlat] > 0: "Tidak ada alat yang lewat
///   jadwal." TANPA klaim "berlaku": `jumlah_alat` ikut menghitung alat yang
///   belum pernah dikalibrasi. "Semua alat Anda berlaku." hanya bila
///   [semuaBerlaku] (server mengirim `alat_berlaku` = `jumlah_alat`).
/// - [alatBelumPernah] > 0 (hanya bila server mengirim hitungannya) menyusul
///   sebagai kalimat polos sebelum kabar sertifikat baru.
/// - Tanpa alat sama sekali: "Belum ada alat."
List<List<PotonganKalimat>> kalimatBeranda({
  required int jumlahAlat,
  required int lewat,
  required int segera,
  required int paketSiap,
  required bool paketSiapMungkinLebih,
  required int sertifikatBaru,
  bool sertifikatBaruMungkinLebih = false,
  bool semuaBerlaku = false,
  int alatBelumPernah = 0,
}) {
  final perhatian = <List<PotonganKalimat>>[
    if (lewat > 0)
      [
        PotonganKalimat('$lewat alat '),
        const PotonganKalimat('lewat jadwal', nada: NadaStatus.gagal),
        const PotonganKalimat('.'),
      ],
    if (paketSiap > 0)
      [
        PotonganKalimat(
          paketSiapMungkinLebih ? 'Ada paket ' : '$paketSiap paket ',
        ),
        const PotonganKalimat('siap diambil', nada: NadaStatus.lulus),
        const PotonganKalimat('.'),
      ],
    if (segera > 0)
      [
        PotonganKalimat('$segera alat '),
        const PotonganKalimat('segera jatuh tempo', nada: NadaStatus.awas),
        const PotonganKalimat('.'),
      ],
  ];
  final belumPernah = alatBelumPernah > 0
      ? <PotonganKalimat>[
          PotonganKalimat('$alatBelumPernah alat belum pernah dikalibrasi.'),
        ]
      : null;
  final baru = sertifikatBaru > 0
      ? <PotonganKalimat>[
          PotonganKalimat(
            sertifikatBaruMungkinLebih
                ? 'Ada sertifikat '
                : '$sertifikatBaru sertifikat ',
          ),
          const PotonganKalimat('baru terbit', nada: NadaStatus.lulus),
          const PotonganKalimat('.'),
        ]
      : null;

  if (perhatian.isEmpty) {
    if (jumlahAlat <= 0) {
      return const [
        [PotonganKalimat('Belum ada alat.')],
      ];
    }
    return [
      if (semuaBerlaku)
        const [
          PotonganKalimat('Semua alat Anda '),
          PotonganKalimat('berlaku', nada: NadaStatus.lulus),
          PotonganKalimat('.'),
        ]
      else
        const [
          PotonganKalimat(
            'Tidak ada alat yang lewat jadwal',
            nada: NadaStatus.lulus,
          ),
          PotonganKalimat('.'),
        ],
      ?belumPernah,
      ?baru,
    ].take(KalimatUtama.maksimumKalimat).toList();
  }
  return [
    ...perhatian,
    ?belumPernah,
    ?baru,
  ].take(KalimatUtama.maksimumKalimat).toList();
}

/// Teks keadaan galat Beranda: judul, kalimat dengan langkah berikutnya, dan
/// label tombol (`null` = tidak ada yang bisa diketuk).
typedef TeksGalat = ({String judul, String isi, String? aksi});

TeksGalat teksGalatBeranda(Object galat) {
  if (galat is GalatApi && galat.tokenTidakBerlaku) {
    // Aplikasi menutup sesinya sendiri dan membuka layar Masuk; tidak ada
    // tombol yang berguna di sini.
    return (
      judul: 'Sesi Anda berakhir',
      isi:
          'Masuk lagi untuk melihat Beranda. Layar masuk akan terbuka sendiri.',
      aksi: null,
    );
  }
  if (galat is GalatApi && galat.jaringan) {
    return (
      judul: 'Beranda belum bisa dimuat',
      isi:
          'Tidak ada sambungan ke server. Periksa sinyal atau Wi-Fi, lalu '
          'coba lagi.',
      aksi: 'Coba lagi',
    );
  }
  final pesan = galat is GalatApi ? galat.pesan.trim() : '';
  return (
    judul: 'Beranda belum bisa dimuat',
    isi: pesan.isEmpty ? 'Terjadi kesalahan. Coba lagi.' : pesan,
    aksi: 'Coba lagi',
  );
}
