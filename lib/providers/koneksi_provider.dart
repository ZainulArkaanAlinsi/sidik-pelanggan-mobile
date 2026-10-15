import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Keadaan jaringan yang TERAMATI dari panggilan API (bukan dari plugin
/// konektivitas): yang penting buat pelanggan bukan "Wi-Fi menyala", tapi
/// "server bisa dijangkau".
@immutable
class KeadaanKoneksi {
  const KeadaanKoneksi({this.offline = false, this.dataTerakhir});

  static const online = KeadaanKoneksi();

  final bool offline;

  /// Waktu data cache yang sedang tampil (banner "Menampilkan data terakhir
  /// ({jam})"). `null` kalau layar yang gagal tidak punya cache.
  final DateTime? dataTerakhir;

  @override
  bool operator ==(Object other) =>
      other is KeadaanKoneksi &&
      other.offline == offline &&
      other.dataTerakhir == dataTerakhir;

  @override
  int get hashCode => Object.hash(offline, dataTerakhir);
}

final koneksiProvider = NotifierProvider<KoneksiController, KeadaanKoneksi>(
  KoneksiController.new,
);

class KoneksiController extends Notifier<KeadaanKoneksi> {
  @override
  KeadaanKoneksi build() => KeadaanKoneksi.online;

  /// Jaringan putus. [dataTerakhir] = waktu cache yang disajikan; kalau
  /// beberapa layar menyajikan cache berbeda, yang PALING LAMA yang
  /// ditampilkan — banner tidak boleh membuat data terlihat lebih segar dari
  /// kenyataannya.
  void offline(DateTime? dataTerakhir) {
    final lama = state;
    DateTime? waktu = dataTerakhir;
    if (lama.offline && lama.dataTerakhir != null) {
      waktu = dataTerakhir == null || lama.dataTerakhir!.isBefore(dataTerakhir)
          ? lama.dataTerakhir
          : dataTerakhir;
    }
    final baru = KeadaanKoneksi(offline: true, dataTerakhir: waktu);
    if (baru != lama) state = baru;
  }

  void online() {
    if (state.offline) state = KeadaanKoneksi.online;
  }
}
