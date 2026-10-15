import 'package:flutter/widgets.dart';

import 'alat/alat_detail_screen.dart';
import 'sertifikat/sertifikat_detail_screen.dart';

/// `tautan.tipe` (kotak notifikasi) / `tautan_tipe` (data push) → layar
/// tujuan. Satu tempat untuk keduanya, supaya mengetuk push dan mengetuk
/// baris kotak masuk membuka layar yang sama.
///
/// Tipe yang belum dikenal (server lebih baru dari aplikasi, atau tipe lama
/// seperti permintaan yang sudah tidak ada di aplikasi) → `null`; pemanggil
/// yang memutuskan jatuh ke mana (push → kotak masuk).
Widget? layarUntukTautan(String? tipe, int? id) => switch (tipe) {
  'pelanggan_sertifikat' when id != null => SertifikatDetailScreen(id: id),
  'pelanggan_alat' when id != null => AlatDetailScreen(id: id),
  _ => null,
};
