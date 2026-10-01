import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

enum SumberFoto { kamera, galeri }

/// Kompres foto di HP sebelum diunggah: sisi terpanjang maks. [sisiMaks] px,
/// JPEG mutu [mutu].
///
/// Semua metadata EXIF — termasuk lokasi GPS — DIBUANG dari hasil
/// (PL_Form_Alat: "Lokasi GPS di foto dihapus otomatis"). Orientasi dipanggang
/// dulu ke piksel supaya foto dari kamera yang ditahan miring tidak tampil
/// rebah setelah EXIF-nya hilang.
///
/// Lempar [FormatException] kalau berkasnya bukan gambar yang bisa dibaca.
Uint8List kompresFoto(Uint8List asli, {int sisiMaks = 1600, int mutu = 80}) {
  img.Image? gambar;
  try {
    gambar = img.decodeImage(asli);
  } catch (_) {
    // Decoder melempar macam-macam galat untuk byte yang bukan gambar.
    gambar = null;
  }
  if (gambar == null) {
    throw const FormatException('Berkas ini bukan gambar yang bisa dibaca.');
  }
  var hasil = img.bakeOrientation(gambar);
  final terpanjang = hasil.width > hasil.height ? hasil.width : hasil.height;
  if (terpanjang > sisiMaks) {
    hasil = img.copyResize(
      hasil,
      width: hasil.width >= hasil.height ? sisiMaks : null,
      height: hasil.height > hasil.width ? sisiMaks : null,
      interpolation: img.Interpolation.average,
    );
  }
  // `encodeJpg` MENULIS EXIF milik gambar kalau ada, dan `bakeOrientation` /
  // `copyResize` tidak membuangnya — tanpa baris ini GPS ikut terkirim.
  hasil.exif = img.ExifData();
  hasil.iccProfile = null;
  return Uint8List.fromList(img.encodeJpg(hasil, quality: mutu));
}

/// Mengambil foto dari kamera/galeri lalu mengompresnya. Dipisah jadi kelas
/// supaya test bisa menggantinya (plugin kamera tidak jalan di test).
class PemilihFoto {
  const PemilihFoto();

  /// `null` = pengguna membatalkan. Lempar [FormatException] kalau hasilnya
  /// bukan gambar.
  Future<Uint8List?> ambil(SumberFoto sumber) async {
    final berkas = await ImagePicker().pickImage(
      source: sumber == SumberFoto.kamera
          ? ImageSource.camera
          : ImageSource.gallery,
      // Metadata lengkap tidak dibutuhkan (dan akan dibuang), jadi tidak perlu
      // izin membaca lokasi media.
      requestFullMetadata: false,
    );
    if (berkas == null) return null;
    final byte = await berkas.readAsBytes();
    // Decode+encode JPEG itu berat: jangan di isolate UI.
    return compute(kompresFoto, byte);
  }
}

final pemilihFotoProvider = Provider<PemilihFoto>((ref) => const PemilihFoto());
