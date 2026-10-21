// Guard: the customer app is view-only (owner decision 20 Oct 2026).
//
// Scans lib/ for every write call (POST/PUT/PATCH/DELETE) and fails when one
// is not on the allowlist below. Adding a new write route must be a
// deliberate change to this file, reviewed against the view-only rule.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Write routes the app is allowed to call. `{x}` = path parameter.
const _izinTulis = <String>{
  'POST /auth/masuk',
  'POST /auth/terima-undangan',
  'POST /auth/lupa-sandi',
  'POST /auth/atur-ulang-sandi',
  'POST /auth/keluar',
  'POST /auth/keluar-semua',
  'POST /perangkat', // FCM token registration
  'DELETE /perangkat', // FCM token removal
  'POST /notifikasi/{x}/dibaca',
  'POST /notifikasi/dibaca-semua',
};

/// Only file allowed to talk HTTP to OUR API.
const _klienHttp = 'lib/core/api_pelanggan.dart';

/// The in-app updater's GitHub Releases client (manifest + APK download).
/// It is the only other file allowed to import package:http, and it must never
/// see the customer session: see the "update client" test below.
const _klienRilis = 'lib/services/klien_rilis.dart';

final _panggilTulis = RegExp(
  r'(\w+)\s*\.\s*(post|put|patch|delete)\s*\(\s*'
  r"('([^']*)')?",
);

String _normal(String jalur) =>
    jalur.replaceAll(RegExp(r'\$\{[^}]*\}|\$\w+'), '{x}');

List<File> _berkasDart() => Directory('lib')
    .listSync(recursive: true)
    .whereType<File>()
    .where((f) => f.path.endsWith('.dart'))
    .toList();

String _jalur(File f) => f.path.replaceAll(r'\', '/');

void main() {
  test('only the API client imports package:http', () {
    final pelanggar = [
      for (final f in _berkasDart())
        if (_jalur(f) != _klienHttp &&
            _jalur(f) != _klienRilis &&
            f.readAsStringSync().contains('package:http/'))
          _jalur(f),
    ];
    expect(pelanggar, isEmpty);
  });

  test('update client is GET-only and never carries the session', () {
    final isi = File(_klienRilis).readAsStringSync();
    // No path to the bearer token, active company, or API client.
    for (final terlarang in [
      'api_pelanggan.dart',
      'penyimpan_sesi.dart',
      'sesi_provider.dart',
      'ApiPelanggan',
      'Authorization',
      'Bearer',
      'X-Perusahaan',
      'token',
    ]) {
      expect(isi, isNot(contains(terlarang)), reason: terlarang);
    }
    // Requests it builds: only GETs.
    final verba = RegExp(r"Request\(\s*'(\w+)'").allMatches(isi);
    expect(verba.map((m) => m.group(1)).toSet(), {'GET'});
    expect(
      RegExp(r'_client\s*\.\s*(post|put|patch|delete|head)\b').hasMatch(isi),
      isFalse,
    );
  });

  test('every write request is on the allowlist', () {
    final ditemukan = <String>{};
    final pelanggar = <String>[];

    for (final f in _berkasDart()) {
      final p = _jalur(f);
      if (p == _klienHttp) continue;
      final isi = f.readAsStringSync();
      for (final m in _panggilTulis.allMatches(isi)) {
        final penerima = m.group(1)!;
        final verba = m.group(2)!.toUpperCase();
        final baris = '\n'.allMatches(isi.substring(0, m.start)).length + 1;

        // Local storage deletes (cache files, secure storage) are not HTTP.
        if (verba == 'DELETE' &&
            p.startsWith('lib/core/penyimpan_') &&
            penerima != 'api') {
          continue;
        }
        if (penerima != 'api' || m.group(4) == null) {
          pelanggar.add('$p:$baris unrecognised write call: ${m.group(0)}');
          continue;
        }
        final rute = '$verba ${_normal(m.group(4)!)}';
        ditemukan.add(rute);
        if (!_izinTulis.contains(rute)) pelanggar.add('$p:$baris $rute');
      }
    }

    expect(pelanggar, isEmpty, reason: 'write calls outside the allowlist');
    // Not vacuous: the scanner must see the known login/logout calls.
    expect(ditemukan, containsAll(['POST /auth/masuk', 'POST /auth/keluar']));
  });

  test('no equipment write route exists (PATCH /alat removed)', () {
    final pelanggar = [
      for (final f in _berkasDart())
        for (final m in _panggilTulis.allMatches(f.readAsStringSync()))
          if ((m.group(4) ?? '').startsWith('/alat')) '${_jalur(f)}: ${m[0]}',
    ];
    expect(pelanggar, isEmpty);
  });
}
