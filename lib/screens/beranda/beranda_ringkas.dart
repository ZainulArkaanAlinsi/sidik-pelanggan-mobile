import 'package:flutter/material.dart' show Icons;
import 'package:intl/intl.dart';

import '../../core/api_pelanggan.dart';
import '../../core/format.dart';
import '../../models/data_pelanggan.dart';
import '../../models/paket.dart';
import '../../models/status_berlaku.dart';
import '../../widgets/kalimat_utama.dart';
import '../../widgets/pemetaan_status.dart';
import '../../widgets/status_tampil.dart';

/// Logika murni Beranda: apa yang masuk kalimat utama, apa yang perlu
/// perhatian, paket mana yang di lab. Dipisah dari layar supaya bisa diuji
/// tanpa membangun widget.

/// Judul halaman Beranda (REVISI-1 §6).
const String judulBeranda = 'Kalibrasi Anda';

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

// ── Bento Lab (P5a): isi kepala, ubin alat, dan ubin pasangan ──────────────
// Semuanya logika murni (tanpa widget) supaya tiap keputusan "apa yang boleh
// diklaim layar" bisa diuji sendiri.

/// Sapaan menurut jam di HP (hanya penyapa, bukan angka kalibrasi): pagi
/// 04–10, siang 11–14, sore 15–17, malam 18–03.
String sapaanWaktu(DateTime jam) {
  final j = jam.hour;
  if (j >= 4 && j < 11) return 'Selamat pagi';
  if (j >= 11 && j < 15) return 'Selamat siang';
  if (j >= 15 && j < 18) return 'Selamat sore';
  return 'Selamat malam';
}

/// Inisial avatar: huruf pertama dari dua kata pertama nama ("Budi Anggota" ->
/// "BA"). Nama kosong = teks kosong (layar menggambar ikon orang).
String inisialNama(String nama) {
  final kata = nama.trim().split(RegExp(r'\s+')).where((k) => k.isNotEmpty);
  String awal(String k) => String.fromCharCode(k.runes.first).toUpperCase();
  return kata.take(2).map(awal).join();
}

/// Isi ubin besar di bawah kalimat utama.
enum JenisUbinAlat {
  /// Akun belum punya alat: ubin kosong.
  kosong,

  /// Alat paling mendesak (lewat jadwal terlama, lalu segera terdekat).
  alatMendesak,

  /// Tidak ada yang mendesak: alat dengan jadwal terdekat.
  jadwalTerdekat,

  /// Server menjamin semua alat berlaku (`alat_berlaku` = `jumlah_alat`),
  /// ditambah jadwal terdekat bila daftarnya terbaca.
  semuaBerlakuTerdekat,

  /// Server menjamin semua alat berlaku; daftar alat tidak terbaca.
  semuaBerlaku,

  /// Daftar alat masih dimuat: kerangka, BUKAN "tidak ada".
  memuat,

  /// Daftar alat gagal dimuat padahal hitungan server bilang ada yang
  /// lewat/segera: catatan gagal, BUKAN "tidak ada".
  gagal,

  /// Tidak ada yang bisa diklaim dan tidak ada yang bisa ditampilkan.
  tidakAda,
}

/// Memilih isi ubin besar. Aturan klaim:
/// - "Semua alat berlaku" HANYA bila [semuaBerlaku] (server yang menjamin);
///   alat yang belum pernah dikalibrasi ikut dihitung `jumlah_alat`.
/// - Daftar yang memuat atau gagal TIDAK dibaca sebagai "tidak ada alat
///   mendesak": [JenisUbinAlat.memuat] atau [JenisUbinAlat.gagal].
/// - [daftar] null = belum terbaca (memuat, gagal, atau dimuat ulang).
({JenisUbinAlat jenis, Alat? alat}) pilihUbinAlat({
  required bool adaAlat,
  required bool semuaBerlaku,
  required bool menungguAlat,
  required RingkasanJatuhTempo? daftar,
  required bool daftarMemuat,
}) {
  if (!adaAlat) return (jenis: JenisUbinAlat.kosong, alat: null);
  if (daftar != null) {
    final mendesak = alatPerhatian(daftar).firstOrNull;
    if (mendesak != null) {
      return (jenis: JenisUbinAlat.alatMendesak, alat: mendesak);
    }
    final terdekat = daftar.urut.firstOrNull;
    if (terdekat != null) {
      return (
        jenis: semuaBerlaku
            ? JenisUbinAlat.semuaBerlakuTerdekat
            : JenisUbinAlat.jadwalTerdekat,
        alat: terdekat,
      );
    }
    return (
      jenis: semuaBerlaku ? JenisUbinAlat.semuaBerlaku : JenisUbinAlat.tidakAda,
      alat: null,
    );
  }
  if (daftarMemuat) return (jenis: JenisUbinAlat.memuat, alat: null);
  if (menungguAlat) return (jenis: JenisUbinAlat.gagal, alat: null);
  return (
    jenis: semuaBerlaku ? JenisUbinAlat.semuaBerlaku : JenisUbinAlat.tidakAda,
    alat: null,
  );
}

/// "Mitutoyo CD-15CPX": merk dan model dipisah spasi; null bila keduanya kosong.
String? merkTipeAlat(Alat a) {
  final s = [a.merk, a.model]
      .whereType<String>()
      .map((x) => x.trim())
      .where((x) => x.isNotEmpty)
      .join(' ');
  return s.isEmpty ? null : s;
}

/// Tanggal jadwal alat untuk kartu alat ("8 Nov 2026"); null bila alat tidak
/// punya jadwal. Kata depannya ("sejak" bila sudah lewat, "jatuh tempo" bila
/// belum) ditambahkan kartu alat sendiri dari sisa harinya, dan tahap alat yang
/// sedang di lab menjadi lencana tersendiri di kartu.
String? tanggalUbinAlat(Alat a) {
  final tempo = a.jatuhTempo;
  return tempo == null ? null : Format.tanggal(tempo);
}

/// Kalimat kosong ubin sertifikat dan paket.
const String teksSertifikatKosong = 'Belum ada sertifikat yang terbit.';
const String teksPaketKosong = 'Tidak ada paket yang sedang dikerjakan.';

/// Baris teks ubin "Sertifikat terbaru": nomor dan alat sertifikat terbaru.
/// Kosong = belum ada sertifikat yang terbaca. Pengecualian yang HARUS
/// bersuara ada di [statusUbinSertifikat] (ikon + kata, bukan teks polos).
List<String> barisUbinSertifikat(List<Sertifikat> terbaru) {
  final s = terbaru.firstOrNull;
  if (s == null) return const [];
  return [s.nomor, if ((s.namaAlat ?? '').isNotEmpty) s.namaAlat!];
}

/// Pengecualian sertifikat terbaru, tiap satu sebagai status (ikon + kata +
/// nada) dari `pemetaan_status.dart`: keputusan FAIL (tidak dilunakkan,
/// REQ-SRT-04), masa berlaku berakhir, digantikan, dibatalkan. Keputusan null
/// dan PASS tidak disebut: tanpa keputusan tidak ada klaim, apalagi hijau.
List<StatusTampil> statusUbinSertifikat(
  List<Sertifikat> terbaru,
  DateTime sekarang,
) {
  final s = terbaru.firstOrNull;
  if (s == null) return const [];
  final status = StatusBerlaku.dariSertifikat(s, sekarang: sekarang);
  return [
    if (s.keputusan == 'FAIL') statusKeputusan('FAIL')!,
    if (status == StatusBerlaku.berakhir ||
        status == StatusBerlaku.digantikan ||
        status == StatusBerlaku.dibatalkan)
      statusBerlaku(status),
  ];
}

/// Nada ubin sertifikat. Krem (awas) berarti "perlu diperiksa" (REVISI-1), jadi
/// HANYA dipakai bila ada pengecualian bernada awas (masa berlaku berakhir,
/// digantikan); merah muda (gagal) bila ada pengecualian bernada gagal (FAIL,
/// dibatalkan); selain itu NETRAL (putih). Tidak pernah hijau: sertifikat
/// terbaru tidak membuktikan apa pun tentang alat lain.
NadaStatus nadaUbinSertifikat(List<StatusTampil> status) =>
    status.any((s) => s.nada == NadaStatus.gagal)
    ? NadaStatus.gagal
    : status.any((s) => s.nada == NadaStatus.awas)
    ? NadaStatus.awas
    : NadaStatus.netral;

/// Paket yang terlambat: istilah dan ikon yang sama dengan kartu paket dan
/// detail paket.
const StatusTampil statusLewatTarget = StatusTampil(
  'Melewati target selesai',
  NadaStatus.awas,
  Icons.schedule,
);

/// Tahap paket yang berarti sudah selesai di tangan pelanggan.
const String tahapDiserahkan = 'diserahkan';

/// Paket yang masih berjalan: tanpa yang sudah diserahkan. Siap diambil tetap
/// ikut (masih menunggu pelanggan, dan disebut tersendiri di ubin).
List<Paket> paketBelumDiserahkan(List<Paket> semua) => [
  for (final p in semua)
    if (p.tahap != tahapDiserahkan) p,
];

/// Baris teks ubin "Paket dikerjakan": nomor dan tahap paket terbaru yang
/// belum diserahkan; paket siap diambil; jumlah paket berjalan. [jumlah] =
/// hitungan server (atau panjang daftar bila lebih besar), [siap] = paket siap
/// diambil. [siapMungkinLebih] = daftar dipotong server dan hitungan server
/// tidak ada: jumlahnya tidak diklaim ("Ada paket siap diambil"). Kosong =
/// tidak ada paket berjalan. Terlambat ada di [statusUbinPaket].
List<String> barisUbinPaket({
  required List<Paket> berjalan,
  required int jumlah,
  required int siap,
  required bool siapMungkinLebih,
}) {
  final pertama = paketBelumDiserahkan(berjalan).firstOrNull;
  return [
    if (pertama != null) ...[
      pertama.nomor,
      // Server lama tanpa `tahap_label`: label jatuh ke kode mentah; kode bukan kata.
      if (pertama.tahapLabel.isNotEmpty && pertama.tahapLabel != pertama.tahap)
        pertama.tahapLabel,
    ],
    if (siap > 0)
      siapMungkinLebih ? 'Ada paket siap diambil' : '$siap paket siap diambil',
    if (jumlah > 1 || (pertama == null && jumlah > 0)) '$jumlah paket berjalan',
  ];
}

/// Pengecualian paket terbaru yang belum diserahkan: melewati target selesai
/// (ikon + kata, bukan teks polos).
List<StatusTampil> statusUbinPaket(List<Paket> berjalan) => [
  if (paketBelumDiserahkan(berjalan).firstOrNull?.terlambat ?? false)
    statusLewatTarget,
];

/// Nada ubin paket (R1b): NETRAL bila tenang. Hijau (lulus) hanya bila ada
/// paket siap diambil ([siap] > 0: kabar baik yang menunggu tindakan
/// pelanggan); bila ada pengecualian ubin mengikuti nadanya (terlambat = krem):
/// ubin yang membawa kata "Melewati target selesai" tidak boleh hijau. Dulu
/// hijau juga saat tidak ada paket sama sekali, arti palsu: hijau = selesai.
NadaStatus nadaUbinPaket(List<StatusTampil> status, {int siap = 0}) =>
    status.isNotEmpty
    ? status.first.nada
    : siap > 0
    ? NadaStatus.lulus
    : NadaStatus.netral;
