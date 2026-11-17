// TautanLuar (P5d, PR-A): tautan mana yang BOLEH dibuka aplikasi dan bagaimana
// tautan WhatsApp/email/telepon/peta dibangun. App Pelanggan hanya membuka
// aplikasi luar; semua URL dari server dianggap tidak tepercaya, dan isi pesan
// tidak boleh menyelipkan parameter.
import 'package:flutter_test/flutter_test.dart';

import 'package:sidik_pelanggan/core/tautan_luar.dart';

void main() {
  group('bolehDibuka: hanya https, mailto, tel', () {
    test('skema yang diizinkan', () {
      expect(
        TautanLuar.bolehDibuka(Uri.parse('https://pt-sidik.com/x')),
        isTrue,
      );
      expect(
        TautanLuar.bolehDibuka(Uri.parse('https://wa.me/6282260060037')),
        isTrue,
      );
      expect(
        TautanLuar.bolehDibuka(Uri.parse('mailto:a@pt-sidik.com')),
        isTrue,
      );
      expect(TautanLuar.bolehDibuka(Uri.parse('tel:082260060037')), isTrue);
      expect(TautanLuar.bolehDibuka(Uri.parse('HTTPS://PT-SIDIK.COM')), isTrue);
    });

    test('skema berbahaya atau tak terenkripsi ditolak', () {
      for (final u in [
        'javascript:alert(1)',
        'http://pt-sidik.com',
        'http://pt-sidik.com/halaman',
        'file:///etc/passwd',
        'content://com.android.contacts',
        'intent://scan/#Intent;scheme=zxing;end',
        'data:text/html,<script>1</script>',
        'whatsapp://send?phone=6282260060037',
        'sms:082260060037',
        'ftp://pt-sidik.com/a',
        'market://details?id=x',
        'sidik://buka',
      ]) {
        expect(TautanLuar.bolehDibuka(Uri.parse(u)), isFalse, reason: u);
      }
    });

    test(
      'https tanpa host atau dengan user:sandi@ ditolak; mailto/tel kosong ditolak',
      () {
        expect(TautanLuar.bolehDibuka(Uri.parse('https:///jalur')), isFalse);
        expect(
          TautanLuar.bolehDibuka(Uri.parse('https://pt-sidik.com@evil.test/')),
          isFalse,
        );
        expect(
          TautanLuar.bolehDibuka(Uri.parse('https://u:p@evil.test/')),
          isFalse,
        );
        expect(TautanLuar.bolehDibuka(Uri.parse('mailto:')), isFalse);
        expect(TautanLuar.bolehDibuka(Uri.parse('tel:')), isFalse);
      },
    );
  });

  group('web: tautan dari server', () {
    test('https bertuan rumah lolos', () {
      expect(
        TautanLuar.web('https://www.instagram.com/ptsidikbdg/').toString(),
        'https://www.instagram.com/ptsidikbdg/',
      );
      expect(
        TautanLuar.web('  https://pt-sidik.com/wp-content/a.pdf  ')?.host,
        'pt-sidik.com',
      );
    });

    test('kosong, aneh, atau berbahaya = null (tombol disembunyikan)', () {
      for (final u in <String?>[
        null,
        '',
        '   ',
        'javascript:alert(1)',
        'http://pt-sidik.com',
        'https://',
        'https://pt-sidik.com/a b',
        'https://pt-sidik.com/\u202Eabc',
        'https://pt-sidik.com@evil.test/',
        'file:///sdcard/x',
        'tel:082260060037',
        'mailto:a@b.co',
        'bukan url',
        '//pt-sidik.com/x',
      ]) {
        expect(TautanLuar.web(u), isNull, reason: '$u');
      }
    });
  });

  group('whatsapp dan nomorWhatsapp', () {
    test('wa.me dan api.whatsapp.com dikenal; host lain ditolak', () {
      expect(TautanLuar.whatsapp('https://wa.me/6282260060037'), isNotNull);
      expect(
        TautanLuar.whatsapp(
          'https://api.whatsapp.com/send?phone=6282260060037',
        ),
        isNotNull,
      );
      for (final u in [
        'https://evil.test/6282260060037',
        'https://wa.me.evil.test/6282260060037',
        'https://notwa.me/6282260060037',
        'http://wa.me/6282260060037',
        'whatsapp://send?phone=6282260060037',
      ]) {
        expect(TautanLuar.whatsapp(u), isNull, reason: u);
      }
    });

    test('nomor hanya dari bentuk wa.me/<nomor>', () {
      expect(
        TautanLuar.nomorWhatsapp('https://wa.me/6282260060037'),
        '6282260060037',
      );
      // Query dari server diabaikan (tidak dibawa ke tautan buatan sendiri).
      expect(
        TautanLuar.nomorWhatsapp('https://wa.me/6282260060037?text=JAHAT'),
        '6282260060037',
      );
      for (final u in <String?>[
        null,
        'https://wa.me/',
        'https://wa.me/message/ABCDEF123',
        'https://wa.me/123',
        'https://wa.me/62822600600371234567',
        'https://wa.me/62822abc0037',
        'https://wa.me/6282260060037/x',
        'https://api.whatsapp.com/send?phone=6282260060037',
      ]) {
        expect(TautanLuar.nomorWhatsapp(u), isNull, reason: '$u');
      }
    });
  });

  group(
    'whatsappDenganPesan: isi pesan ter-encode, satu-satunya parameter text',
    () {
      test('bentuk dasar', () {
        final u = TautanLuar.whatsappDenganPesan(
          'https://wa.me/6282260060037',
          'Halo admin',
        )!;
        expect(u.toString(), 'https://wa.me/6282260060037?text=Halo%20admin');
      });

      test(
        'karakter khusus tidak menyelipkan parameter, fragmen, atau baris',
        () {
          const pesan =
              'a&b=c#frag?x=1 %41 😀\nbaris "kutip" \'tunggal\' ü <b> \\ + ;';
          final u = TautanLuar.whatsappDenganPesan(
            'https://wa.me/6282260060037?text=JAHAT&phone=1',
            pesan,
          )!;
          expect(u.scheme, 'https');
          expect(u.host, 'wa.me');
          expect(u.path, '/6282260060037');
          expect(u.fragment, isEmpty);
          expect(u.queryParameters.keys, [
            'text',
          ], reason: 'tak ada parameter lain');
          expect(
            u.queryParameters['text'],
            pesan,
            reason: 'bulat-balik tanpa cacat',
          );
          final mentah = u.toString();
          expect(mentah.contains(' '), isFalse);
          expect(mentah.contains('\n'), isFalse);
          expect(
            mentah.contains('JAHAT'),
            isFalse,
            reason: 'query server dibuang',
          );
          expect(mentah.split('?').length, 2, reason: 'satu tanda tanya');
          expect(mentah.contains('&'), isFalse);
          expect(mentah.contains('#'), isFalse);
          expect(TautanLuar.bolehDibuka(u), isTrue);
        },
      );

      test('pesan panjang tetap terbaca utuh', () {
        final pesan = List.generate(
          80,
          (i) => 'Baris ke-$i: nilai & lain',
        ).join('\n');
        final u = TautanLuar.whatsappDenganPesan(
          'https://wa.me/6282260060037',
          pesan,
        )!;
        expect(u.queryParameters['text'], pesan);
      });

      test(
        'tautan server yang bukan wa.me/<nomor> = null (jatuh ke email)',
        () {
          expect(
            TautanLuar.whatsappDenganPesan('https://wa.me/message/AB', 'x'),
            isNull,
          );
          expect(TautanLuar.whatsappDenganPesan(null, 'x'), isNull);
          expect(
            TautanLuar.whatsappDenganPesan('javascript:alert(1)', 'x'),
            isNull,
          );
        },
      );
    },
  );

  group('email', () {
    test('alamat wajar lolos, aneh ditolak', () {
      expect(
        TautanLuar.alamatEmail(' sidikkalibrasi@pt-sidik.com '),
        'sidikkalibrasi@pt-sidik.com',
      );
      for (final a in <String?>[
        null,
        '',
        'tanpa-at',
        'a@b',
        'a b@c.com',
        'a@b.com, c@d.com',
        'a@b.com\r\nBcc: x@y.zz',
        '@b.com',
        'a@.com',
        'a@b..com',
        '<a@b.com>',
      ]) {
        expect(TautanLuar.alamatEmail(a), isNull, reason: '$a');
      }
    });

    test('bagian lokal tidak boleh memuat ? & # (tidak bisa menyelipkan '
        'header mailto), email sah tetap lolos', () {
      for (final a in <String>[
        'sidik?bcc=evil@x.com',
        'sidik&bcc=evil@x.com',
        'sidik#frag@x.com',
        '?@x.com',
        'a@x.com?bcc=evil@y.com',
      ]) {
        expect(TautanLuar.alamatEmail(a), isNull, reason: a);
        expect(
          TautanLuar.email(a, subjek: 'S', isi: 'I'),
          isNull,
          reason: a,
        );
      }
      for (final a in <String>[
        'sidikkalibrasi@pt-sidik.com',
        'nama.belakang+tag@sub.example.co.id',
        'a_b-c@x.io',
        'o=bounce/srs@x.com',
      ]) {
        expect(TautanLuar.alamatEmail(a), a, reason: a);
        expect(TautanLuar.email(a, subjek: 'S'), isNotNull, reason: a);
      }
      // Satu-satunya "?" di tautan adalah pembuka query yang dibangun sendiri.
      final u = TautanLuar.email(
        'nama.belakang+tag@sub.example.co.id',
        subjek: 'S',
        isi: 'I',
      )!;
      expect(
        u.toString(),
        'mailto:nama.belakang+tag@sub.example.co.id?subject=S&body=I',
      );
    });

    test('mailto dengan subjek dan isi ter-encode', () {
      final u = TautanLuar.email(
        'sidikkalibrasi@pt-sidik.com',
        subjek: 'Halo dunia',
        isi: 'a\nb&c=d',
      )!;
      expect(
        u.toString(),
        'mailto:sidikkalibrasi@pt-sidik.com?subject=Halo%20dunia&body=a%0Ab%26c%3Dd',
      );
      expect(u.queryParameters['subject'], 'Halo dunia');
      expect(u.queryParameters['body'], 'a\nb&c=d');
      expect(
        TautanLuar.email('sidikkalibrasi@pt-sidik.com').toString(),
        'mailto:sidikkalibrasi@pt-sidik.com',
      );
      expect(TautanLuar.email('bukan email', subjek: 'x'), isNull);
    });
  });

  group('telepon dan peta', () {
    test('telepon hanya angka dan plus di depan', () {
      expect(TautanLuar.telepon('082260060037').toString(), 'tel:082260060037');
      expect(
        TautanLuar.telepon('+62 822-6006-0037').toString(),
        'tel:+6282260060037',
      );
      expect(TautanLuar.telepon('(021) 555-0123').toString(), 'tel:0215550123');
      for (final x in <String?>[
        null,
        '',
        '  ',
        '123',
        'abc',
        '0822;rm',
        '1234567890123456',
      ]) {
        expect(TautanLuar.telepon(x), isNull, reason: '$x');
      }
    });

    test('peta: alamat jadi satu-satunya kata cari di tautan Google Maps', () {
      const alamat =
          'Komplek Nuansa Mas Estate, Blk. E No.2, Cipamokolan, Rancasari, '
          'Bandung 40292';
      final u = TautanLuar.peta(alamat)!;
      expect(u.scheme, 'https');
      expect(u.host, 'www.google.com');
      expect(u.path, '/maps/search/');
      expect(u.queryParameters, {'api': '1', 'query': alamat});
      expect(TautanLuar.bolehDibuka(u), isTrue);
      expect(TautanLuar.peta(null), isNull);
      expect(TautanLuar.peta('   '), isNull);
    });
  });
}
