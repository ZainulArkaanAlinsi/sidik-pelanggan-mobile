// Font ikon Material dari SDK Flutter untuk render PNG: tanpa ini ikon tampil
// sebagai kotak di gambar. Dilewati diam-diam bila berkasnya tidak ditemukan
// (tes tetap jalan; hanya gambarnya yang berbeda).
import 'dart:io';

import 'package:flutter/services.dart';

Future<void> muatFontIkonMaterial() async {
  final akar = Platform.environment['FLUTTER_ROOT'];
  final calon = [
    if (akar != null) '$akar/bin/cache/artifacts/material_fonts',
    '${File(Platform.resolvedExecutable).parent.parent.parent.parent.path}'
        '/artifacts/material_fonts',
  ];
  for (final folder in calon) {
    final berkas = File('$folder/materialicons-regular.otf');
    if (!berkas.existsSync()) continue;
    final pemuat = FontLoader('MaterialIcons')
      ..addFont(Future.value(ByteData.sublistView(berkas.readAsBytesSync())));
    await pemuat.load();
    return;
  }
}
