import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/data_provider.dart';
import '../providers/pembaruan_provider.dart';
import '../providers/push_provider.dart';
import '../providers/sinkron_provider.dart';
import '../services/push_pelanggan.dart';
import '../widgets/pembaruan.dart';
import 'akun/akun_screen.dart';
import 'beranda/beranda_screen.dart';
import 'notifikasi/notifikasi_screen.dart';
import 'sertifikat/sertifikat_screen.dart';
import 'tautan.dart';

/// Indeks tab — dipegang di satu tempat supaya lompatan antar-tab (kartu
/// beranda, push) tidak memakai angka telanjang.
abstract final class IndeksTab {
  static const beranda = 0;
  static const sertifikat = 1;
  static const notifikasi = 2;
  static const akun = 3;
}

/// Tab yang sedang aktif — dipegang provider supaya beranda bisa melompat ke
/// daftar alat dengan saringan "lewat jadwal" dari kartu ringkasan.
final tabProvider = NotifierProvider<TabAktif, int>(TabAktif.new);

class TabAktif extends Notifier<int> {
  @override
  int build() => IndeksTab.beranda;

  void pilih(int i) => state = i;
}

/// Saringan awal daftar alat di Beranda saat diatur dari luar (kartu / push) (`lewat` / `segera` /
/// null = semua). Membawa nomor urut supaya mengetuk kartu yang SAMA dua kali
/// (sesudah pengguna sempat mengganti saringan di tab Alat) tetap terasa —
/// nilai yang sama persis tidak membangunkan pendengar.
final saringanAlatAwalProvider =
    NotifierProvider<SaringanAwal, ({String? saring, int urutan})>(
      SaringanAwal.new,
    );

class SaringanAwal extends Notifier<({String? saring, int urutan})> {
  @override
  ({String? saring, int urutan}) build() => (saring: null, urutan: 0);

  void atur(String? s) => state = (saring: s, urutan: state.urutan + 1);
}

/// Rangka empat tab: Beranda (alat + jatuh tempo), Sertifikat, Notifikasi,
/// Akun. Riwayat kalibrasi per alat ada di Detail alat.
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
    SertifikatScreen(),
    NotifikasiScreen(),
    AkunScreen(),
  ];

  bool _dialogWajibTerbuka = false;

  @override
  void initState() {
    super.initState();
    // Push yang membuka aplikasi dari keadaan mati, atau yang diketuk
    // sebelum sesi selesai dipulihkan.
    WidgetsBinding.instance.addPostFrameCallback((_) => _bukaTautan());
    // Rilis `wajib` → dialog yang tidak bisa ditutup, di atas tab mana pun.
    ref.listenManual<bool>(pembaruanProvider.select((k) => k.wajib), (
      _,
      wajib,
    ) {
      if (wajib) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _bukaDialogWajib());
      }
    }, fireImmediately: true);
  }

  void _bukaDialogWajib() {
    if (!mounted || _dialogWajibTerbuka) return;
    _dialogWajibTerbuka = true;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (_) => const DialogPembaruanWajib(),
    ).whenComplete(() => _dialogWajibTerbuka = false);
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
      body: IndexedStack(index: aktif, children: _tab),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Di atas navigasi bawah, bukan di atas layar: AppBar tiap tab
          // sudah memegang jarak status bar.
          const BannerPembaruan(),
          NavigationBar(
            selectedIndex: aktif,
            onDestinationSelected: ref.read(tabProvider.notifier).pilih,
            destinations: [
              const NavigationDestination(
                icon: Icon(Icons.space_dashboard_outlined),
                selectedIcon: Icon(Icons.space_dashboard),
                label: 'Beranda',
              ),
              const NavigationDestination(
                icon: Icon(Icons.description_outlined),
                selectedIcon: Icon(Icons.description),
                label: 'Sertifikat',
              ),
              NavigationDestination(
                icon: Badge(
                  isLabelVisible: belum > 0,
                  label: Text(belum > 99 ? '99+' : '$belum'),
                  child: const Icon(Icons.notifications_none),
                ),
                selectedIcon: const Icon(Icons.notifications),
                label: 'Notifikasi',
                tooltip: belum == 0
                    ? 'Notifikasi'
                    : 'Notifikasi, $belum belum dibaca',
              ),
              const NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person),
                label: 'Akun',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Buka layar tujuan sebuah push. Tanpa tujuan yang dikenal: pengingat
/// jadwal → Beranda (alat diurutkan paling mendesak); selain itu → tab
/// Notifikasi, supaya ketukan tidak pernah berakhir di jalan buntu.
void bukaTautanPush(BuildContext context, WidgetRef ref, TautanPush t) {
  final layar = layarUntukTautan(t.tipe, t.id);
  final navigator = Navigator.of(context);
  navigator.popUntil((r) => r.isFirst);
  if (layar != null) {
    navigator.push(MaterialPageRoute<void>(builder: (_) => layar));
  } else if (t.kategori == 'pelanggan_alat_jatuh_tempo') {
    ref.read(saringanAlatAwalProvider.notifier).atur(null);
    ref.read(tabProvider.notifier).pilih(IndeksTab.beranda);
  } else {
    ref.read(tabProvider.notifier).pilih(IndeksTab.notifikasi);
  }
}
