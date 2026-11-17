/// Pesan terisi untuk "Tanya admin tentang ini": dibangun dari data yang SEDANG
/// tampil di layar (nama alat, merk, nomor seri, nomor sertifikat, jadwal,
/// status, nama perusahaan aktif), tidak ada yang dikarang. Tanpa token, tanpa
/// email atau telepon pribadi, tanpa ID internal.
///
/// Pesan ditampilkan dulu di lembar bawah dan dibuka di WhatsApp (atau email)
/// sebagai TEKS yang bisa disunting pengguna; aplikasi tidak mengirim apa pun ke
/// server. Fungsi murni (tanpa Flutter) supaya string emasnya mudah diuji.
class PesanAdmin {
  const PesanAdmin({required this.subjek, required this.isi});

  /// Subjek email (WhatsApp tidak memakainya).
  final String subjek;

  /// Isi pesan, Bahasa Indonesia, beberapa baris.
  final String isi;

  @override
  String toString() => 'PesanAdmin($subjek)';
}

abstract final class PembangunPesanAdmin {
  /// Batas panjang satu butir data. Nama atau nomor seri yang aneh panjang
  /// tidak boleh membuat tautan WhatsApp/email terlalu panjang.
  static const int maksPanjangButir = 120;

  static final RegExp _tidakTampil = RegExp(
    r'[\u0000-\u001F\u007F-\u009F\u200B-\u200F\u2028-\u202F\u2060-\u206F\uFEFF]',
  );

  /// Satu butir data sebagai SATU baris: kendali (baris baru, tab, arah teks,
  /// lebar-nol) jadi spasi, spasi berulang dilipat, dipangkas, dan dipotong di
  /// [maksPanjangButir] karakter dengan "…". `null` bila kosong, sehingga baris
  /// butirnya tidak ditulis ("Belum tersedia" tidak dikirim ke admin).
  static String? bersihkan(String? nilai) {
    if (nilai == null) return null;
    final satu = nilai
        .replaceAll(_tidakTampil, ' ')
        .replaceAll(RegExp(r' {2,}'), ' ')
        .trim();
    if (satu.isEmpty) return null;
    final huruf = satu.runes.toList();
    if (huruf.length <= maksPanjangButir) return satu;
    return '${String.fromCharCodes(huruf.take(maksPanjangButir - 1)).trimRight()}…';
  }

  static String _baris(String label, String? nilai) {
    final b = bersihkan(nilai);
    return b == null ? '' : '- $label: $b\n';
  }

  static String _pembuka(String? perusahaan, String kalimat) {
    final p = bersihkan(perusahaan);
    return 'Halo admin PT SIDIK,\n\n'
        '${p == null ? 'Kami' : 'Kami dari $p'} $kalimat';
  }

  /// Detail alat: "Minta kalibrasi ulang".
  ///
  /// [jadwal] sudah berupa tanggal tampilan ("12 Mar 2027"), [merkTipe] sudah
  /// "merk model".
  static PesanAdmin kalibrasiUlang({
    String? perusahaan,
    required String namaAlat,
    String? merkTipe,
    String? serial,
    String? jadwal,
  }) {
    final nama = bersihkan(namaAlat) ?? 'alat';
    final sn = bersihkan(serial);
    final isi =
        '${_pembuka(perusahaan, 'ingin meminta kalibrasi ulang alat berikut:')}\n'
        '${_baris('Alat', nama)}'
        '${_baris('Merk/model', merkTipe)}'
        '${_baris('Nomor seri', serial)}'
        '${_baris('Jadwal kalibrasi ulang', jadwal)}'
        '\nMohon informasi langkah berikutnya. Terima kasih.';
    return PesanAdmin(
      subjek:
          'Permintaan kalibrasi ulang: $nama${sn == null ? '' : ' (SN $sn)'}',
      isi: isi,
    );
  }

  /// Detail sertifikat: "Tanya tentang sertifikat ini".
  static PesanAdmin tanyaSertifikat({
    String? perusahaan,
    required String nomor,
    String? namaAlat,
    String? serial,
    String? status,
  }) => _sertifikat(
    perusahaan: perusahaan,
    nomor: nomor,
    namaAlat: namaAlat,
    serial: serial,
    status: status,
    kalimat: 'ingin bertanya tentang sertifikat berikut:',
    penutup: 'Pertanyaan kami:',
    subjekAwal: 'Pertanyaan tentang sertifikat',
  );

  /// Detail sertifikat: "Laporkan data yang keliru".
  static PesanAdmin laporkanDataKeliru({
    String? perusahaan,
    required String nomor,
    String? namaAlat,
    String? serial,
    String? status,
  }) => _sertifikat(
    perusahaan: perusahaan,
    nomor: nomor,
    namaAlat: namaAlat,
    serial: serial,
    status: status,
    kalimat: 'menemukan data yang tampaknya keliru pada sertifikat berikut:',
    penutup: 'Data yang keliru dan seharusnya:',
    subjekAwal: 'Data keliru pada sertifikat',
  );

  static PesanAdmin _sertifikat({
    String? perusahaan,
    required String nomor,
    String? namaAlat,
    String? serial,
    String? status,
    required String kalimat,
    required String penutup,
    required String subjekAwal,
  }) {
    final no = bersihkan(nomor) ?? '-';
    final isi =
        '${_pembuka(perusahaan, kalimat)}\n'
        '${_baris('Nomor sertifikat', no)}'
        '${_baris('Alat', namaAlat)}'
        '${_baris('Nomor seri', serial)}'
        '${_baris('Status', status)}'
        '\n$penutup';
    return PesanAdmin(subjek: '$subjekAwal $no', isi: isi);
  }
}
