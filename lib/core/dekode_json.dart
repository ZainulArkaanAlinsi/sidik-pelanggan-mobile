import 'dart:convert';
import 'dart:isolate';

/// Batas panjang teks (karakter) yang masih diurai di isolate UI.
///
/// Mengurai ~200 KB JSON di HP murah (2 GB RAM, CPU kelas bawah) sudah makan
/// puluhan milidetik: layar tersendat. Di bawah batas ini biaya menyalin teks
/// ke isolate lain malah lebih mahal daripada mengurainya langsung, jadi
/// respons kecil (sebagian besar API) tetap sinkron.
const batasDekodeLatar = 200 * 1024;

/// `jsonDecode` yang memindahkan teks besar ke isolate terpisah.
///
/// Perilakunya sama dengan [jsonDecode], termasuk [FormatException] untuk
/// teks yang bukan JSON — pemanggil yang menangkapnya tidak perlu berubah.
/// Hasil dari [Isolate.run] dipindahkan (bukan disalin ulang) lewat
/// `Isolate.exit`.
Future<Object?> dekodeJson(String teks, {int batas = batasDekodeLatar}) {
  if (teks.length <= batas) {
    try {
      return Future.value(jsonDecode(teks));
    } catch (e, st) {
      return Future.error(e, st);
    }
  }
  return Isolate.run(() => jsonDecode(teks), debugName: 'dekodeJson');
}
