import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/tautan_luar.dart';

/// Pembuka tautan: `true` bila diserahkan ke aplikasi luar.
typedef PembukaTautan = Future<bool> Function(Uri uri);

/// Buka tautan di aplikasi luar (WhatsApp, email, telepon, peta, peramban).
/// `false` kalau skemanya tidak diizinkan ([TautanLuar.bolehDibuka]: hanya
/// `https`, `mailto`, `tel`) atau HP tidak punya aplikasi untuk membukanya.
/// Satu-satunya pintu keluar aplikasi ke `launchUrl`.
Future<bool> bukaTautanLuar(Uri uri) async {
  if (!TautanLuar.bolehDibuka(uri)) return false;
  try {
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    return false;
  }
}

/// Pembuka tautan yang dipakai layar; tes menggantinya untuk memeriksa tautan
/// yang dibuka tanpa meluncurkan aplikasi sungguhan.
final pembukaTautanProvider = Provider<PembukaTautan>((ref) => bukaTautanLuar);

/// Buka [uri]; bila null atau tidak ada aplikasi untuk membukanya, tampilkan
/// [galat] di snackbar (tidak pernah diam).
Future<void> bukaAtauBeritahu(
  BuildContext context,
  WidgetRef ref,
  Uri? uri, {
  String galat = 'Tidak ada aplikasi untuk membukanya.',
}) async {
  final pesan = ScaffoldMessenger.of(context);
  final buka = ref.read(pembukaTautanProvider);
  final berhasil = uri != null && await buka(uri);
  if (!berhasil) pesan.showSnackBar(SnackBar(content: Text(galat)));
}

/// Salin [teks] ke papan klip dan beri konfirmasi ([konfirmasi]) di snackbar.
Future<void> salinDenganKonfirmasi(
  BuildContext context,
  String teks,
  String konfirmasi,
) async {
  final pesan = ScaffoldMessenger.of(context);
  await Clipboard.setData(ClipboardData(text: teks));
  pesan.showSnackBar(SnackBar(content: Text(konfirmasi)));
}
