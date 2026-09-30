import 'package:flutter_test/flutter_test.dart';

import 'package:sidik_pelanggan/models/akun.dart';
import 'package:sidik_pelanggan/models/anggota.dart';
import 'package:sidik_pelanggan/models/data_pelanggan.dart';

/// Model dibaca dari bentuk respons yang SAMA dengan resource di API
/// (`App\Http\Resources\Pelanggan\*`, fixture `tests/Fixtures/pelanggan/`).
/// Kalau server mengganti nama kunci, test ini yang merah — bukan layar yang
/// diam-diam menampilkan "—".
void main() {
  test('akun dari /auth/masuk', () {
    final a = Akun.dariJson({
      'id': 7,
      'nama': 'Budi Anggota',
      'email': 'budi@contoh.test',
      'telepon': '+628123456789',
      'jabatan': 'QA Manager',
      'status': 'aktif',
      'butuh_verifikasi': false,
      'keanggotaan': [
        {
          'customer_id': 3,
          'nama_perusahaan': 'PT Contoh Pelanggan',
          'peran': 'pic_utama',
        },
      ],
      'pengajuan': null,
    });
    expect(a.punyaPerusahaan, isTrue);
    expect(a.lebihDariSatuPerusahaan, isFalse);
    expect(a.keanggotaan.single.picUtama, isTrue);
  });

  test('versi dibandingkan sebagai angka, bukan teks', () {
    expect(StatusAplikasi.bandingkanVersi('1.2.10', '1.2.9'), greaterThan(0));
    expect(StatusAplikasi.bandingkanVersi('0.1.0+5', '0.1.0'), 0);
    final s = StatusAplikasi.dariJson({
      'versi_minimum': '0.2.0',
      'versi_terbaru': '0.3.0',
      'maintenance': false,
      'pesan_maintenance': '',
    });
    expect(s.wajibPerbarui('0.1.9'), isTrue);
    expect(s.wajibPerbarui('0.2.0'), isFalse);
  });

  test('alat dari /alat — status kalibrasi & sertifikat terakhir', () {
    final a = Alat.dariJson({
      'id': 11,
      'nama': 'Jangka Sorong',
      'merk': 'Mitutoyo',
      'model': '530-312',
      'serial': 'SN-1',
      'no_identifikasi': null,
      'rentang': {'min': 0, 'max': 150, 'satuan': 'mm'},
      'lokasi': 'QC',
      'tanggal_kalibrasi_terakhir': '2025-10-01',
      'tanggal_jatuh_tempo': '2026-10-01',
      'hari_ke_jatuh_tempo': -3,
      'status_kalibrasi': 'lewat_jatuh_tempo',
      'sertifikat_terakhir': {
        'id': 5,
        'nomor': 'CAL/2025/10/0001',
        'diterbitkan_pada': '2025-10-02',
        'berlaku_sampai': '2026-10-01',
      },
    });
    expect(a.status, StatusKalibrasi.lewat);
    expect(a.rentang, '0 – 150 mm');
    expect(a.sertifikatTerakhir?.nomor, 'CAL/2025/10/0001');
  });

  test('sertifikat dari /sertifikat/{id} — revisi & rincian', () {
    final s = Sertifikat.dariJson({
      'id': 9,
      'nomor': 'CAL/2026/09/0002',
      'diterbitkan_pada': '2026-09-20',
      'berlaku_sampai': '2027-09-20',
      'keputusan': 'PASS',
      'alat': {
        'id': 11,
        'nama': 'Jangka Sorong',
        'merk': 'Mitutoyo',
        'model': null,
        'serial': 'SN-1',
      },
      'revisi_dari': {'id': 8, 'nomor': 'CAL/2026/09/0001'},
      'bisa_diunduh': true,
      'tautan_verifikasi': 'https://contoh.test/verify/abc',
      'rincian': {'tanggal_kalibrasi': '2026-09-19', 'metode': 'IK-01'},
      'penanda_tangan': {'nama': 'Dr. Contoh', 'jabatan': 'Manajer Teknis'},
      'digantikan_oleh': null,
    });
    expect(s.revisiDari, 'CAL/2026/09/0001');
    expect(s.digantikan, isFalse);
    expect(s.rincian['Metode'], 'IK-01');
    expect(s.penandaTangan, 'Dr. Contoh, Manajer Teknis');
  });

  test('paket dari /paket/{id} — kemajuan & garis waktu', () {
    final p = Paket.dariJson(
      {
        'id': 1,
        'nomor': 'ORD/2026/09/0001',
        'tanggal_masuk': '2026-09-01',
        'tanggal_janji_selesai': '2026-09-10',
        'terlambat': true,
        'tahap': 'menunggu_pemeriksaan',
        'tahap_label': 'Hasil sedang diperiksa',
        'jumlah_alat': 4,
        'jumlah_selesai': 1,
        'alat': [
          {
            'id': 1,
            'nama': 'Termometer',
            'tahap': 'sertifikat_terbit',
            'tahap_label': 'Sertifikat sudah terbit',
            'sertifikat_id': 3,
          },
        ],
      },
      [
        {
          'kode': 'diterima',
          'label': 'Alat diterima lab',
          'lewat': true,
          'sekarang': false,
        },
        {
          'kode': 'menunggu_pemeriksaan',
          'label': 'Hasil sedang diperiksa',
          'lewat': false,
          'sekarang': true,
        },
      ],
    );
    expect(p.kemajuan, 0.25);
    expect(p.alat.single.sertifikatId, 3);
    expect(
      p.garisWaktu.where((l) => l.sekarang).single.label,
      'Hasil sedang diperiksa',
    );
  });

  test('anggota dari /anggota', () {
    final d = DaftarAnggota.dariJson({
      'data': {
        'anggota': [
          {
            'id': 1,
            'peran': 'pic_utama',
            'status': 'aktif',
            'bergabung_pada': '2026-09-01T00:00:00Z',
            'dinonaktifkan_pada': null,
            'orang': {
              'id': 7,
              'nama': 'Budi PIC',
              'email': 'budi@contoh.test',
              'telepon': null,
              'jabatan': null,
            },
            'saya': true,
          },
        ],
        'undangan_menunggu': [
          {
            'id': 4,
            'email': 'sari@contoh.test',
            'peran': 'staf',
            'kedaluwarsa_pada': '2026-10-01T00:00:00Z',
          },
        ],
        'maks_anggota': 50,
        'saya': {'customer_id': 3, 'member_id': 1, 'peran': 'pic_utama'},
      },
    });
    expect(d.sayaPicUtama, isTrue);
    expect(d.anggota.single.saya, isTrue);
    expect(d.undanganMenunggu.single.email, 'sari@contoh.test');
  });
}
