import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/sinkron_provider.dart';
import 'akun/akun_screen.dart';
import 'alat/alat_screen.dart';
import 'beranda/beranda_screen.dart';
import 'permintaan/permintaan_screen.dart';
import 'sertifikat/sertifikat_screen.dart';

/// Tab yang sedang aktif — dipegang provider supaya beranda bisa melompat ke
/// tab Alat dengan saringan "lewat jatuh tempo" dari kartu ringkasan.
final tabProvider = NotifierProvider<TabAktif, int>(TabAktif.new);

class TabAktif extends Notifier<int> {
  @override
  int build() => 0;

  void pilih(int i) => state = i;
}

/// Saringan awal tab Alat saat dibuka dari beranda (`lewat` / `segera` /
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

/// Rangka lima tab: tahu kondisi (Beranda), cek alat, AJUKAN & pantau
/// permintaan, ambil sertifikat, urus akun. Notifikasi bukan tab — dia lonceng
/// di kanan atas beranda.
///
/// Permintaan menggantikan tab Paket, bukan menambah tab keenam: bilah bawah
/// Material maksimal lima tujuan, dan paket memang kelanjutan permintaan yang
/// diterima. Pelacakan paket tetap utuh — dari ikon truk di layar Permintaan,
/// kartu "Paket di lab" di Beranda, dan tombol "Lacak paket" di detail
/// permintaan yang sudah diterima.
class Rangka extends ConsumerWidget {
  const Rangka({super.key});

  static const _tab = <Widget>[
    BerandaScreen(),
    AlatScreen(),
    PermintaanScreen(),
    SertifikatScreen(),
    AkunScreen(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Hidup selama pengguna masuk: tarik ulang data waktu aplikasi dibuka lagi
    // atau push masuk, supaya HP ini menyusul perubahan dari HP lain.
    ref.watch(sinkronProvider);
    final aktif = ref.watch(tabProvider);
    return Scaffold(
      body: IndexedStack(index: aktif, children: _tab),
      bottomNavigationBar: NavigationBar(
        selectedIndex: aktif,
        onDestinationSelected: ref.read(tabProvider.notifier).pilih,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.space_dashboard_outlined),
            selectedIcon: Icon(Icons.space_dashboard),
            label: 'Beranda',
          ),
          NavigationDestination(
            icon: Icon(Icons.straighten_outlined),
            selectedIcon: Icon(Icons.straighten),
            label: 'Alat',
          ),
          NavigationDestination(
            icon: Icon(Icons.assignment_outlined),
            selectedIcon: Icon(Icons.assignment),
            label: 'Permintaan',
          ),
          NavigationDestination(
            icon: Icon(Icons.description_outlined),
            selectedIcon: Icon(Icons.description),
            label: 'Sertifikat',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Akun',
          ),
        ],
      ),
    );
  }
}
