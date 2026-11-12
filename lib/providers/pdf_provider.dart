import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../widgets/penampil_pdf.dart';

/// Pembangun penampil PDF. Bawaannya `pdfx`; tes memasang yang palsu karena
/// `pdfx` butuh plugin platform yang tidak ada di `flutter test`.
final penampilPdfProvider = Provider<PembangunPenampilPdf>(
  (ref) => bangunPenampilPdfx,
);
