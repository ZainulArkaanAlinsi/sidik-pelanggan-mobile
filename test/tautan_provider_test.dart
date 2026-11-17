// bukaTautanLuar (P5d): satu-satunya pintu ke url_launcher. Diuji pada
// peluncur NYATA dengan kanal platformnya diganti perekam, bukan lewat
// pembuka palsu: yang dibuktikan di sini adalah gerbang `bolehDibuka` di
// depan peluncur. Tautan yang ditolak tidak boleh sampai ke platform.
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sidik_pelanggan/core/tautan_luar.dart';
import 'package:sidik_pelanggan/providers/tautan_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const kanal = MethodChannel('plugins.flutter.io/url_launcher');
  final diluncurkan = <String>[];
  var peluncurMelempar = false;

  void pasangKanal() => TestDefaultBinaryMessengerBinding
      .instance
      .defaultBinaryMessenger
      .setMockMethodCallHandler(kanal, (call) async {
        if (call.method != 'launch') return null;
        if (peluncurMelempar) {
          throw PlatformException(code: 'ACTIVITY_NOT_FOUND');
        }
        diluncurkan.add((call.arguments as Map)['url'] as String);
        return true;
      });

  setUp(() {
    diluncurkan.clear();
    peluncurMelempar = false;
    pasangKanal();
  });
  tearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(kanal, null),
  );

  test('kontrol: tautan sah sampai ke peluncur platform', () async {
    for (final u in [
      'https://pt-sidik.com/verify/abc',
      'https://wa.me/6282260060037?text=Halo%20admin',
      'mailto:sidikkalibrasi@pt-sidik.com?subject=S&body=I',
      'tel:082260060037',
    ]) {
      expect(await bukaTautanLuar(Uri.parse(u)), isTrue, reason: u);
    }
    expect(diluncurkan, [
      'https://pt-sidik.com/verify/abc',
      'https://wa.me/6282260060037?text=Halo%20admin',
      'mailto:sidikkalibrasi@pt-sidik.com?subject=S&body=I',
      'tel:082260060037',
    ]);
  });

  test('yang ditolak gerbang tidak pernah sampai ke peluncur', () async {
    for (final u in [
      'javascript:alert(1)',
      'http://pt-sidik.com/verify/abc',
      'file:///sdcard/x.pdf',
      'content://com.android.contacts',
      'intent://scan/#Intent;scheme=zxing;end',
      'data:text/html,<script>1</script>',
      'sms:082260060037',
      'whatsapp://send?phone=6282260060037',
      'market://details?id=x',
      'https:///jalur',
      'https://u:p@pt-sidik.com/x',
      'https://pt-sidik.com@evil.test/',
      'mailto:',
      'tel:',
      // Host ber-% (spasi, lebar-nol, atau bidi yang di-encode Dart): bukan
      // nama DNS sah.
      'https://exa mple.com/',
      'https://exa​mple.com/',
      'https://‮pt-sidik.com/',
    ]) {
      expect(await bukaTautanLuar(Uri.parse(u)), isFalse, reason: u);
    }
    expect(diluncurkan, isEmpty);
  });

  test('peluncur yang gagal atau melempar = false, bukan galat', () async {
    peluncurMelempar = true;
    expect(await bukaTautanLuar(Uri.parse('https://pt-sidik.com/x')), isFalse);
    expect(diluncurkan, isEmpty);
  });

  test('tautan yang dibangun TautanLuar sendiri lolos gerbang', () async {
    final dibangun = <Uri?>[
      TautanLuar.email('sidikkalibrasi@pt-sidik.com', subjek: 'S', isi: 'I\nJ'),
      TautanLuar.telepon('+62 822-6006-0037'),
      TautanLuar.whatsappDenganPesan('https://wa.me/6282260060037', 'a\nb&c'),
      // Alamat dengan baris baru dan lebar-nol hanya ada di kata cari peta;
      // gerbang tidak boleh menolaknya.
      TautanLuar.peta('Jl. Contoh No. 1\nBandung​ 40292'),
    ];
    for (final u in dibangun) {
      expect(u, isNotNull);
      expect(await bukaTautanLuar(u!), isTrue, reason: '$u');
    }
    expect(diluncurkan, hasLength(dibangun.length));
  });
}
