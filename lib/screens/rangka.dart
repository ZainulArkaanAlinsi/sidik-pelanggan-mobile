import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/data_provider.dart';
import '../providers/pembaruan_provider.dart';
import '../providers/push_provider.dart';
import '../providers/sinkron_provider.dart';
import '../services/push_pelanggan.dart';
import '../widgets/navigasi_utama.dart';
import '../widgets/pembaruan.dart';
import 'akun/akun_screen.dart';
import 'alat/daftar_alat_screen.dart';
import 'beranda/beranda_screen.dart';
import 'notifikasi/notifikasi_screen.dart';
import 'sertifikat/sertifikat_screen.dart';
import 'tautan.dart';

/// Indeks tab. Dipegang di satu tempat supaya lompatan antar-tab (kartu
/// beranda, push) tidak memakai angka telanjang.
abstract final class IndeksTab {
  static const beranda = 0;
  static const alat = 1;
  static const sertifikat = 2;
  static const notifikasi = 3;
  static const akun = 4;
}

/// Tab yang sedang aktif. Dipegang provider supaya Beranda bisa melompat ke
/// daftar sertifikat atau alat dari tautan "Lihat semua".
final tabProvider = NotifierProvider<TabAktif, int>(TabAktif.new);

class TabAktif extends Notifier<int> {
  @override
  int build() => IndeksTab.beranda;

  void pilih(int i) => state = i;
}

/// Rangka lima tab: Beranda (ringkasan jatuh tempo, alat mendesak, sertifikat
/// terbaru, paket), Alat, Sertifikat, Notifikasi, Akun. Di HP navigasinya di
/// bawah; di layar lebar (>= 600 dp) berupa rel di kiri ([NavigasiUtama]).
///
/// Push yang diketuk dibuka DI SINI, karena di sinilah pengguna pasti sudah
/// masuk dan perusahaannya sudah terpilih.
class Rangka extends ConsumerStatefulWidget {
  const Rangka({super.key});

  @override
  ConsumerState<Rangka> createState() => _RangkaState();
}

class _RangkaState extends ConsumerState<Rangka> {
  static const _tab = <Widget>[
    BerandaScreen(),
    DaftarAlatScreen(),
    SertifikatScreen(),
    NotifikasiScreen(),
    AkunScreen(),
  ];

  /// Dialog wajib yang sedang tampil, dipegang supaya bisa DITUTUP sendiri
  /// waktu rilisnya tidak lagi wajib (manifes baru) atau menghilang.
  DialogRoute<void>? _dialogWajib;

  @override
  void initState() {
    super.initState();
    // Push yang membuka aplikasi dari keadaan mati, atau yang diketuk
    // sebelum sesi selesai dipulihkan.
    WidgetsBinding.instance.addPostFrameCallback((_) => _bukaTautan());
    // Rilis `wajib` → dialog yang tidak bisa ditutup, di atas tab mana pun.
    // Tidak wajib lagi / rilisnya hilang → dialog ditutup otomatis.
    ref.listenManual<bool>(
      pembaruanProvider.select((k) => k.wajib),
      (_, _) => WidgetsBinding.instance.addPostFrameCallback(
        (_) => _selaraskanDialogWajib(),
      ),
      fireImmediately: true,
    );
  }

  void _selaraskanDialogWajib() {
    if (!mounted) return;
    final wajib = ref.read(pembaruanProvider).wajib;
    final terbuka = _dialogWajib;
    if (wajib && terbuka == null) {
      final rute = DialogRoute<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const DialogPembaruanWajib(),
      );
      _dialogWajib = rute;
      Navigator.of(context, rootNavigator: true).push(rute).whenComplete(() {
        if (identical(_dialogWajib, rute)) _dialogWajib = null;
      });
    } else if (!wajib && terbuka != null) {
      _dialogWajib = null;
      // removeRoute, bukan pop: dialognya menolak pop (PopScope), dan pop
      // bisa salah sasaran kalau ada rute lain di atasnya.
      if (terbuka.isActive) terbuka.navigator?.removeRoute(terbuka);
    }
  }

  void _bukaTautan() {
    if (!mounted) return;
    final t = ref.read(tautanTertundaProvider.notifier).ambil();
    if (t != null) bukaTautanPush(context, ref, t);
  }

  @override
  Widget build(BuildContext context) {
    // Hidup selama pengguna masuk: tarik ulang data waktu aplikasi dibuka lagi
    // atau push masuk, supaya HP ini menyusul perubahan dari HP lain.
    ref.watch(sinkronProvider);
    // Periksa pembaruan aplikasi: saat masuk, saat dibuka lagi, tiap jam.
    ref.watch(penjadwalPembaruanProvider);
    ref.listen(tautanTertundaProvider, (_, t) {
      if (t != null) _bukaTautan();
    });
    final aktif = ref.watch(tabProvider);
    final belum = ref.watch(jumlahBelumDibacaProvider).value ?? 0;
    return Scaffold(
      body: NavigasiUtama(
        indeks: aktif,
        onPilih: ref.read(tabProvider.notifier).pilih,
        // Banner pembaruan di atas navigasi, bukan di atas layar: AppBar tiap
        // tab sudah memegang jarak status bar.
        penutup: const BannerPembaruan(),
        tujuan: [
          const TujuanNavigasi(
            ikon: Icons.space_dashboard_outlined,
            ikonAktif: Icons.space_dashboard,
            label: 'Beranda',
          ),
          const TujuanNavigasi(
            ikon: Icons.precision_manufacturing_outlined,
            ikonAktif: Icons.precision_manufacturing,
            label: 'Alat',
          ),
          const TujuanNavigasi(
            ikon: Icons.description_outlined,
            ikonAktif: Icons.description,
            label: 'Sertifikat',
          ),
          TujuanNavigasi(
            ikon: Icons.notifications_none,
            ikonAktif: Icons.notifications,
            label: 'Notifikasi',
            tooltip: belum == 0
                ? 'Notifikasi'
                : 'Notifikasi, $belum belum dibaca',
            lencana: belum,
          ),
          const TujuanNavigasi(
            ikon: Icons.person_outline,
            ikonAktif: Icons.person,
            label: 'Akun',
          ),
        ],
        isi: IndexedStack(index: aktif, children: _tab),
      ),
    );
  }
}

/// Buka layar tujuan sebuah push. Tanpa tujuan yang dikenal: pengingat
/// jadwal → Beranda (ringkasan jatuh tempo di atas); selain itu → tab
/// Notifikasi, supaya ketukan tidak pernah berakhir di jalan buntu.
void bukaTautanPush(BuildContext context, WidgetRef ref, TautanPush t) {
  final layar = layarUntukTautan(t.tipe, t.id);
  final navigator = Navigator.of(context);
  navigator.popUntil((r) => r.isFirst);
  if (layar != null) {
    navigator.push(MaterialPageRoute<void>(builder: (_) => layar));
  } else if (t.kategori == 'pelanggan_alat_jatuh_tempo') {
    ref.read(tabProvider.notifier).pilih(IndeksTab.beranda);
  } else {
    ref.read(tabProvider.notifier).pilih(IndeksTab.notifikasi);
  }
}
