import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';

/// Entrega um PDF para a pessoa: baixa no navegador (web) ou abre a
/// folha de compartilhamento (Android/iOS). Fica num provider para os
/// testes trocarem por um espião.
final compartilharPdfProvider =
    Provider<Future<void> Function(Uint8List bytes, String nomeDoArquivo)>(
      (ref) =>
          (bytes, nome) => Printing.sharePdf(bytes: bytes, filename: nome),
    );
