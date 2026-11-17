// PembangunPesanAdmin (P5d, PR-A): pesan "Tanya admin tentang ini". Teks yang
// dibuka di WhatsApp/email harus persis yang disepakati (string emas), hanya
// memuat data yang tampil di layar, dan aman dari karakter kendali.
import 'package:flutter_test/flutter_test.dart';

import 'package:sidik_pelanggan/core/pesan_admin.dart';

String _gabung(List<String> baris) => baris.join('\n');

void main() {
  group('string emas', () {
    test('Minta kalibrasi ulang (detail alat)', () {
      final p = PembangunPesanAdmin.kalibrasiUlang(
        perusahaan: 'PT Maju Jaya',
        namaAlat: 'Jangka Sorong Digital',
        merkTipe: 'Mitutoyo CD-15CPX',
        serial: '2201-0457',
        jadwal: '12 Mar 2027',
      );
      expect(
        p.isi,
        _gabung([
          'Halo admin PT SIDIK,',
          '',
          'Kami dari PT Maju Jaya ingin meminta kalibrasi ulang alat berikut:',
          '- Alat: Jangka Sorong Digital',
          '- Merk/model: Mitutoyo CD-15CPX',
          '- Nomor seri: 2201-0457',
          '- Jadwal kalibrasi ulang: 12 Mar 2027',
          '',
          'Mohon informasi langkah berikutnya. Terima kasih.',
        ]),
      );
      expect(
        p.subjek,
        'Permintaan kalibrasi ulang: Jangka Sorong Digital (SN 2201-0457)',
      );
    });

    test('Tanya tentang sertifikat ini (detail sertifikat)', () {
      final p = PembangunPesanAdmin.tanyaSertifikat(
        perusahaan: 'PT Maju Jaya',
        nomor: 'CAL/2026/11/0012',
        namaAlat: 'Jangka Sorong Digital',
        serial: '2201-0457',
        status: 'Berlaku',
      );
      expect(
        p.isi,
        _gabung([
          'Halo admin PT SIDIK,',
          '',
          'Kami dari PT Maju Jaya ingin bertanya tentang sertifikat berikut:',
          '- Nomor sertifikat: CAL/2026/11/0012',
          '- Alat: Jangka Sorong Digital',
          '- Nomor seri: 2201-0457',
          '- Status: Berlaku',
          '',
          'Pertanyaan kami:',
        ]),
      );
      expect(p.subjek, 'Pertanyaan tentang sertifikat CAL/2026/11/0012');
    });

    test('Laporkan data yang keliru (detail sertifikat)', () {
      final p = PembangunPesanAdmin.laporkanDataKeliru(
        perusahaan: 'PT Maju Jaya',
        nomor: 'CAL/2026/11/0012',
        namaAlat: 'Jangka Sorong Digital',
        serial: '2201-0457',
        status: 'Digantikan',
      );
      expect(
        p.isi,
        _gabung([
          'Halo admin PT SIDIK,',
          '',
          'Kami dari PT Maju Jaya menemukan data yang tampaknya keliru pada '
              'sertifikat berikut:',
          '- Nomor sertifikat: CAL/2026/11/0012',
          '- Alat: Jangka Sorong Digital',
          '- Nomor seri: 2201-0457',
          '- Status: Digantikan',
          '',
          'Data yang keliru dan seharusnya:',
        ]),
      );
      expect(p.subjek, 'Data keliru pada sertifikat CAL/2026/11/0012');
    });
  });

  group('data kosong tidak dikarang', () {
    test('butir kosong dilewati (tanpa "Belum tersedia" atau tanda strip)', () {
      final p = PembangunPesanAdmin.kalibrasiUlang(
        perusahaan: null,
        namaAlat: 'Oven',
        merkTipe: '',
        serial: '   ',
        jadwal: null,
      );
      expect(
        p.isi,
        _gabung([
          'Halo admin PT SIDIK,',
          '',
          'Kami ingin meminta kalibrasi ulang alat berikut:',
          '- Alat: Oven',
          '',
          'Mohon informasi langkah berikutnya. Terima kasih.',
        ]),
      );
      expect(p.subjek, 'Permintaan kalibrasi ulang: Oven');
      expect(p.isi.contains('Belum tersedia'), isFalse);
      expect(p.isi.contains('null'), isFalse);
    });

    test('sertifikat tanpa alat dan seri: hanya nomor dan status', () {
      final p = PembangunPesanAdmin.tanyaSertifikat(
        nomor: 'S-1',
        status: 'Dibatalkan',
      );
      expect(p.isi.contains('- Alat:'), isFalse);
      expect(p.isi.contains('- Nomor seri:'), isFalse);
      expect(p.isi, contains('- Nomor sertifikat: S-1'));
      expect(p.isi, contains('- Status: Dibatalkan'));
      expect(p.isi, contains('Kami ingin bertanya'));
    });
  });

  group('bersihkan: satu baris, tanpa kendali, terpotong', () {
    test('baris baru, tab, dan arah teks menjadi spasi lalu dilipat', () {
      expect(PembangunPesanAdmin.bersihkan('A\nB\r\nC\tD'), 'A B C D');
      expect(PembangunPesanAdmin.bersihkan('  a   b  '), 'a b');
      expect(
        PembangunPesanAdmin.bersihkan('x\u202Ey\u200Bz\u2066w'),
        'x y z w',
      );
      expect(PembangunPesanAdmin.bersihkan(''), isNull);
      expect(PembangunPesanAdmin.bersihkan(' \n\t '), isNull);
      expect(PembangunPesanAdmin.bersihkan(null), isNull);
    });

    test('baris baru di data tidak bisa menyelipkan baris pesan atau header '
        'email', () {
      final p = PembangunPesanAdmin.kalibrasiUlang(
        perusahaan: 'PT X\nBcc: jahat@contoh.test',
        namaAlat: 'Oven\r\nSubject: palsu',
        serial: '1\n- Alat: palsu',
      );
      expect(p.subjek.contains('\n'), isFalse);
      expect(p.subjek.contains('\r'), isFalse);
      // Butir yang disusupi tetap SATU baris di dalam butirnya.
      final baris = p.isi.split('\n');
      expect(baris.where((b) => b.startsWith('- Alat:')).length, 1);
      expect(baris.where((b) => b.startsWith('Bcc:')).length, 0);
      expect(baris.where((b) => b.startsWith('Subject:')).length, 0);
    });

    test('butir panjang dipotong di 120 karakter dengan "…", tidak membelah '
        'emoji', () {
      final panjang = 'A' * 500;
      final c = PembangunPesanAdmin.bersihkan(panjang)!;
      expect(c.runes.length, PembangunPesanAdmin.maksPanjangButir);
      expect(c.endsWith('…'), isTrue);
      final emoji = '😀' * 300;
      final e = PembangunPesanAdmin.bersihkan(emoji)!;
      expect(e.runes.length, PembangunPesanAdmin.maksPanjangButir);
      expect(e.runes.every((r) => r == 0x1F600 || r == 0x2026), isTrue);
      // Tepat di batas: tidak dipotong.
      expect(PembangunPesanAdmin.bersihkan('B' * 120), 'B' * 120);
    });

    test('pesan terburuk tetap pendek (batas panjang tautan)', () {
      final x = 'N' * 1000;
      final p = PembangunPesanAdmin.laporkanDataKeliru(
        perusahaan: x,
        nomor: x,
        namaAlat: x,
        serial: x,
        status: x,
      );
      expect(p.isi.length, lessThan(1000));
    });
  });

  test(
    'pesan memuat data layar saja: tanpa token, email, atau ID internal',
    () {
      final semua = [
        PembangunPesanAdmin.kalibrasiUlang(
          perusahaan: 'PT Maju Jaya',
          namaAlat: 'Oven',
          merkTipe: 'Memmert UF55',
          serial: '0457',
          jadwal: '12 Mar 2027',
        ),
        PembangunPesanAdmin.tanyaSertifikat(
          perusahaan: 'PT Maju Jaya',
          nomor: 'CAL/1',
          namaAlat: 'Oven',
          serial: '0457',
          status: 'Berlaku',
        ),
      ];
      for (final p in semua) {
        for (final kata in ['@', 'token', 'Bearer', 'http', 'id=', 'ID ']) {
          expect(p.isi.contains(kata), isFalse, reason: kata);
        }
      }
    },
  );
}
