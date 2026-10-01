import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_pelanggan.dart';
import '../../core/format.dart';
import '../../core/theme/sidik_material.dart';
import '../../models/permintaan.dart';
import '../../providers/data_provider.dart';
import '../../providers/sesi_provider.dart';
import '../../widgets/foto_pelat.dart';
import '../../widgets/permintaan.dart';
import '../../widgets/resi.dart';
import '../../widgets/sidik/sidik_permukaan.dart';
import '../../widgets/sidik/sidik_status.dart';
import '../../widgets/sidik/sidik_tombol.dart';
import '../../widgets/umum.dart';
import '../paket/paket_detail_screen.dart';

/// Detail permintaan: garis waktu status, alat, alasan bila ditolak, tombol
/// batal selagi masih `baru`, dan utas pesan dengan Tim lab.
///
/// Semua keputusan "boleh atau tidak" (batal, kirim pesan) dibaca dari
/// server (`dapat_dibatalkan`, `percakapan_terbuka`) — aplikasi tidak
/// menebaknya dari status.
class PermintaanDetailScreen extends ConsumerWidget {
  const PermintaanDetailScreen({super.key, required this.id});

  final int id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(detailPermintaanProvider(id));

    return Scaffold(
      appBar: AppBar(title: Text(async.value?.nomor ?? 'Permintaan')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(detailPermintaanProvider(id));
          ref.invalidate(pesanPermintaanProvider(id));
          await ref.read(detailPermintaanProvider(id).future);
        },
        child: async.when(
          loading: () => const Memuat(),
          error: (e, _) => KeadaanGalat(
            galat: e,
            cobaLagi: () => ref.invalidate(detailPermintaanProvider(id)),
          ),
          data: (p) => _Isi(permintaan: p),
        ),
      ),
    );
  }
}

class _Isi extends ConsumerStatefulWidget {
  const _Isi({required this.permintaan});

  final Permintaan permintaan;

  @override
  ConsumerState<_Isi> createState() => _IsiState();
}

class _IsiState extends ConsumerState<_Isi> {
  bool _membatalkan = false;

  Future<void> _batal() async {
    final yakin = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('Batalkan permintaan?'),
        content: const Text(
          'Permintaan ini tidak akan ditinjau lab. Anda bisa mengajukan yang baru kapan saja.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(d, false),
            child: const Text('Kembali'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(d, true),
            child: const Text('Batalkan permintaan'),
          ),
        ],
      ),
    );
    if (yakin != true || !mounted) return;

    setState(() => _membatalkan = true);
    final pesan = ScaffoldMessenger.of(context);
    final id = widget.permintaan.id;
    try {
      await ref.read(layananProvider).batalkanPermintaan(id);
      ref.invalidate(detailPermintaanProvider(id));
      ref.invalidate(pesanPermintaanProvider(id));
      ref.invalidate(daftarPermintaanProvider);
      pesan.showSnackBar(
        const SnackBar(content: Text('Permintaan dibatalkan.')),
      );
    } on GalatApi catch (e) {
      // 422 = status sudah berubah (mis. lab sempat menerimanya). Tarik ulang
      // supaya tombolnya hilang sesuai keadaan sebenarnya.
      ref.invalidate(detailPermintaanProvider(id));
      pesan.showSnackBar(SnackBar(content: Text(e.isian['status'] ?? e.pesan)));
    } catch (_) {
      pesan.showSnackBar(
        const SnackBar(content: Text('Gagal membatalkan. Coba lagi.')),
      );
    } finally {
      if (mounted) setState(() => _membatalkan = false);
    }
  }

  Future<void> _isiResi() async {
    final p = widget.permintaan;
    final hasil = await tampilkanIsiResi(
      context,
      awal: p.resi,
      kirim: (kurir, nomor) =>
          ref.read(layananProvider).isiResi(p.id, kurir, nomor),
    );
    if (hasil == null || !mounted) return;
    ref.invalidate(detailPermintaanProvider(p.id));
    ref.invalidate(daftarPermintaanProvider);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Nomor resi tersimpan. Lab sudah diberi tahu.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.permintaan;
    final t = Theme.of(context).textTheme;
    final m = SidikMaterial.of(context);
    final jadwal = barisJadwal(p.jadwal);

    return ListView(
      padding: const EdgeInsets.fromLTRB(jarak, 8, jarak, 32),
      children: [
        Kertas(
          padding: const EdgeInsets.all(jarak),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SidikLencana(lencanaPermintaan(p)),
              const SizedBox(height: 10),
              BarisInfo('Cara pengantaran', p.metode?.label),
              BarisInfo(
                'Tanggal diinginkan',
                p.tanggalDari == null
                    ? null
                    : '${Format.tanggal(p.tanggalDari)}'
                          '${p.tanggalSampai == null ? '' : ' – ${Format.tanggal(p.tanggalSampai)}'}',
              ),
              BarisInfo('Catatan', p.catatan),
            ],
          ),
        ),
        if (p.perluTindakan && p.pesanTindakan != null) ...[
          const SizedBox(height: 12),
          Kertas(
            warna: m.awasTipis,
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.priority_high, color: m.awas),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    p.pesanTindakan!,
                    style: t.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        ],
        if (p.progres != null && p.progres!.total > 0) ...[
          const SizedBox(height: 12),
          Kertas(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: p.progres!.selesai / p.progres!.total,
                    minHeight: 8,
                    backgroundColor: m.kertas2,
                    color: m.lulus,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${p.progres!.selesai}/${p.progres!.total} alat selesai',
                  style: t.bodySmall,
                ),
              ],
            ),
          ),
        ],
        if (jadwal != null) ...[
          const JudulSeksi('Jadwal teknisi'),
          Kertas(
            padding: const EdgeInsets.all(jarak),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.event_outlined, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        jadwal,
                        style: t.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                if (p.jadwal?.catatan != null) ...[
                  const SizedBox(height: 6),
                  Text(p.jadwal!.catatan!, style: t.bodySmall),
                ],
              ],
            ),
          ),
        ],
        if (p.bisaIsiResi || p.resi != null) ...[
          const JudulSeksi('Pengiriman alat'),
          Kertas(
            padding: const EdgeInsets.all(jarak),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (p.resi != null) ...[
                  BarisInfo('Kurir', p.resi!.kurir),
                  BarisInfo('Nomor resi', p.resi!.nomor),
                  if (p.resi!.diisiPada != null)
                    BarisInfo('Diisi', Format.tanggalJam(p.resi!.diisiPada)),
                ] else
                  Text(
                    'Belum ada nomor resi. Isi kalau alat sudah dikirim ke lab.',
                    style: t.bodyMedium,
                  ),
                if (p.alatTiba != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Alat tiba di lab ${Format.tanggal(p.alatTiba)}.',
                    style: t.bodySmall,
                  ),
                ],
                if (p.bisaIsiResi) ...[
                  const SizedBox(height: 10),
                  SidikTombol(
                    label: p.resi == null
                        ? 'Isi nomor resi'
                        : 'Ubah nomor resi',
                    ikon: Icons.local_shipping_outlined,
                    ragam: p.resi == null
                        ? RagamTombol.utama
                        : RagamTombol.biasa,
                    penuh: true,
                    onPressed: _isiResi,
                  ),
                ],
              ],
            ),
          ),
        ],
        if (p.status == StatusPermintaan.ditolak) ...[
          const JudulSeksi('Alasan dari lab'),
          Kertas(
            padding: const EdgeInsets.all(jarak),
            child: Text(
              p.alasanPenolakan ?? 'Lab tidak mencantumkan alasan.',
              style: t.bodyMedium,
            ),
          ),
        ],
        const JudulSeksi('Perjalanan permintaan'),
        Kertas(
          padding: const EdgeInsets.symmetric(horizontal: jarak, vertical: 8),
          child: Column(children: _garisWaktu(p, m)),
        ),
        if (p.paketId != null) ...[
          const SizedBox(height: 10),
          SidikTombol(
            label: 'Lacak paket ${p.paketNomor ?? ''}'.trim(),
            ikon: Icons.local_shipping_outlined,
            penuh: true,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => PaketDetailScreen(id: p.paketId!),
              ),
            ),
          ),
        ],
        JudulSeksi('Alat (${p.alat.isEmpty ? p.jumlahAlat : p.alat.length})'),
        for (final a in p.alat)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Kertas(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(a.nama, style: t.titleSmall),
                            Text(
                              [
                                a.merkModel,
                                if (a.serial != null) 'SN ${a.serial}',
                              ].where((s) => s.isNotEmpty).join(' · '),
                              style: t.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      if (a.baru && a.alatId == null)
                        Text('Alat baru', style: t.bodySmall),
                    ],
                  ),
                  // Selagi permintaan `baru`, foto alat baru masih bisa
                  // ditambah/diganti (menyusul yang gagal saat mengajukan).
                  if (a.baru &&
                      a.alatId == null &&
                      p.status == StatusPermintaan.baru) ...[
                    const SizedBox(height: 10),
                    GridFotoPelat(
                      key: ValueKey('foto-alat-${a.id}'),
                      awal: a.foto,
                      unggah: (b) => ref
                          .read(layananProvider)
                          .unggahFotoItem(p.id, a.id, b),
                    ),
                  ] else if (a.foto.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    DeretanFoto(foto: a.foto),
                  ],
                ],
              ),
            ),
          ),
        if (p.dapatDibatalkan) ...[
          const SizedBox(height: 6),
          SidikTombol(
            label: 'Batalkan permintaan',
            ragam: RagamTombol.bahaya,
            penuh: true,
            sibuk: _membatalkan,
            onPressed: _batal,
          ),
        ],
        const JudulSeksi('Pesan dengan Tim lab'),
        _Utas(permintaan: p),
      ],
    );
  }

  List<Widget> _garisWaktu(Permintaan p, SidikMaterial m) {
    // Status terakhir ditentukan server; di sini cuma urutan tampilan.
    final langkah = <(String, String?, _Keadaan)>[
      ('Diajukan', Format.tanggal(p.diajukan), _Keadaan.lewat),
      switch (p.status) {
        StatusPermintaan.baru => (
          'Menunggu ditinjau Tim lab',
          null,
          _Keadaan.sekarang,
        ),
        StatusPermintaan.diterima => (
          'Diterima lab',
          Format.tanggal(p.diputuskan),
          _Keadaan.lewat,
        ),
        StatusPermintaan.ditolak => (
          'Ditolak lab',
          Format.tanggal(p.diputuskan),
          _Keadaan.gagal,
        ),
        StatusPermintaan.dibatalkan => (
          'Dibatalkan',
          Format.tanggal(p.dibatalkan),
          _Keadaan.gagal,
        ),
      },
    ];
    return [
      for (final (label, keterangan, keadaan) in langkah)
        _Langkah(label: label, keterangan: keterangan, keadaan: keadaan),
    ];
  }
}

enum _Keadaan { lewat, sekarang, gagal }

class _Langkah extends StatelessWidget {
  const _Langkah({
    required this.label,
    required this.keterangan,
    required this.keadaan,
  });

  final String label;
  final String? keterangan;
  final _Keadaan keadaan;

  @override
  Widget build(BuildContext context) {
    final m = SidikMaterial.of(context);
    final t = Theme.of(context).textTheme;
    final (ikon, warna) = switch (keadaan) {
      _Keadaan.lewat => (Icons.check_circle, m.lulus),
      _Keadaan.sekarang => (Icons.radio_button_checked, m.biruTinta),
      _Keadaan.gagal => (Icons.cancel, m.gagal),
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(ikon, color: warna, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: t.bodyMedium?.copyWith(
                fontWeight: keadaan == _Keadaan.sekarang
                    ? FontWeight.w700
                    : FontWeight.w500,
              ),
            ),
          ),
          if (keterangan != null) Text(keterangan!, style: t.bodySmall),
        ],
      ),
    );
  }
}

/// Utas pesan + kotak ketik. Kotak ketik hanya ada selagi server bilang
/// percakapan terbuka; riwayat tetap terbaca sesudah ditolak/dibatalkan.
class _Utas extends ConsumerWidget {
  const _Utas({required this.permintaan});

  final Permintaan permintaan;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(pesanPermintaanProvider(permintaan.id));
    final t = Theme.of(context).textTheme;

    return async.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(jarak),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Kertas(
        padding: const EdgeInsets.all(jarak),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              e is GalatApi ? e.pesan : 'Pesan belum bisa dimuat.',
              style: t.bodyMedium,
            ),
            const SizedBox(height: 8),
            SidikTombol(
              label: 'Coba lagi',
              kecil: true,
              onPressed: () =>
                  ref.invalidate(pesanPermintaanProvider(permintaan.id)),
            ),
          ],
        ),
      ),
      data: (utas) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (utas.isi.isEmpty)
            Kertas(
              padding: const EdgeInsets.all(jarak),
              child: Text(
                utas.terbuka
                    ? 'Belum ada pesan. Tulis di bawah kalau ada yang perlu disampaikan ke lab.'
                    : 'Tidak ada pesan.',
                style: t.bodyMedium,
              ),
            )
          else
            for (final s in utas.isi) _Gelembung(pesan: s),
          const SizedBox(height: 8),
          if (utas.terbuka)
            KotakPesan(permintaanId: permintaan.id)
          else
            Text(
              'Percakapan ditutup karena permintaan ini sudah '
              '${permintaan.status == StatusPermintaan.ditolak ? 'ditolak' : 'dibatalkan'}.',
              style: t.bodySmall,
            ),
        ],
      ),
    );
  }
}

class _Gelembung extends StatelessWidget {
  const _Gelembung({required this.pesan});

  final PesanPermintaan pesan;

  @override
  Widget build(BuildContext context) {
    final m = SidikMaterial.of(context);
    final t = Theme.of(context).textTheme;
    final milikku = pesan.dariSaya;
    return Align(
      alignment: milikku ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.8,
        ),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: milikku ? m.biruTinta.withValues(alpha: 0.12) : m.kertas2,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(pesan.isi, style: t.bodyMedium),
              const SizedBox(height: 4),
              Text(
                '${pesan.namaPengirim} · ${Format.tanggalJam(pesan.dibuat)}',
                style: t.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Kotak ketik pesan. Controller-nya milik State ini sendiri — dibuang
/// bersama widget, bukan di pemanggil.
class KotakPesan extends ConsumerStatefulWidget {
  const KotakPesan({super.key, required this.permintaanId});

  final int permintaanId;

  @override
  ConsumerState<KotakPesan> createState() => _KotakPesanState();
}

class _KotakPesanState extends ConsumerState<KotakPesan> {
  final _isi = TextEditingController();
  bool _kirim = false;

  @override
  void dispose() {
    _isi.dispose();
    super.dispose();
  }

  Future<void> _kirimPesan() async {
    final teks = _isi.text.trim();
    if (teks.isEmpty || _kirim) return;
    if (teks.length > 2000) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pesan terlalu panjang (maks. 2000 karakter).'),
        ),
      );
      return;
    }
    setState(() => _kirim = true);
    final pesan = ScaffoldMessenger.of(context);
    try {
      await ref.read(layananProvider).kirimPesan(widget.permintaanId, teks);
      _isi.clear();
      ref.invalidate(pesanPermintaanProvider(widget.permintaanId));
      ref.invalidate(detailPermintaanProvider(widget.permintaanId));
    } on GalatApi catch (e) {
      // Teks TIDAK dihapus: pelanggan tidak perlu mengetik ulang.
      pesan.showSnackBar(SnackBar(content: Text(e.isian['isi'] ?? e.pesan)));
    } catch (_) {
      pesan.showSnackBar(
        const SnackBar(content: Text('Pesan belum terkirim. Coba lagi.')),
      );
    } finally {
      if (mounted) setState(() => _kirim = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: TextField(
            controller: _isi,
            minLines: 1,
            maxLines: 4,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(hintText: 'Tulis pesan ke lab'),
          ),
        ),
        const SizedBox(width: 8),
        SidikTombolIkon(
          ikon: Icons.send,
          label: 'Kirim pesan',
          onPressed: _kirim ? null : _kirimPesan,
        ),
      ],
    );
  }
}
