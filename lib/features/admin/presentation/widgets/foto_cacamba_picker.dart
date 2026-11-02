import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/cacamba_image.dart';

/// Maior tamanho aceito pela API para a foto (1,5 MB).
const kTamanhoMaximoFoto = 1536 * 1024;

/// Foto escolhida pelo fornecedor, pronta para ir à API em base64.
class FotoSelecionada {
  const FotoSelecionada(this.bytes, this.mime);

  final Uint8List bytes;

  /// `image/jpeg`, `image/png` ou `image/webp`.
  final String mime;

  /// Data URI aceito pelo campo `foto_base64` da API.
  String get dataUri => 'data:$mime;base64,${base64Encode(bytes)}';
}

/// Erro com mensagem pronta para mostrar à pessoa.
class FotoInvalidaException implements Exception {
  const FotoInvalidaException(this.mensagem);

  final String mensagem;

  @override
  String toString() => mensagem;
}

/// Identifica o formato pelos primeiros bytes (a extensão do arquivo e o
/// tipo informado pelo sistema não são confiáveis).
String? detectarMimeDaImagem(Uint8List bytes) {
  if (bytes.length > 3 &&
      bytes[0] == 0xFF &&
      bytes[1] == 0xD8 &&
      bytes[2] == 0xFF) {
    return 'image/jpeg';
  }

  if (bytes.length > 8 &&
      bytes[0] == 0x89 &&
      bytes[1] == 0x50 &&
      bytes[2] == 0x4E &&
      bytes[3] == 0x47) {
    return 'image/png';
  }

  if (bytes.length > 12 &&
      String.fromCharCodes(bytes.sublist(0, 4)) == 'RIFF' &&
      String.fromCharCodes(bytes.sublist(8, 12)) == 'WEBP') {
    return 'image/webp';
  }

  return null;
}

/// Confere formato e tamanho antes de enviar.
FotoSelecionada validarFoto(Uint8List bytes) {
  final mime = detectarMimeDaImagem(bytes);

  if (mime == null) {
    throw const FotoInvalidaException('Escolha uma imagem JPG, PNG ou WebP.');
  }

  if (bytes.length > kTamanhoMaximoFoto) {
    throw const FotoInvalidaException(
      'A imagem é grande demais. Escolha uma foto de até 1,5 MB.',
    );
  }

  return FotoSelecionada(bytes, mime);
}

/// Abre a galeria. A imagem já sai reduzida (até 1600 px, qualidade 85),
/// o que mantém o envio em base64 pequeno.
///
/// Devolve `null` se a pessoa cancelar. Lança [FotoInvalidaException]
/// quando o arquivo não serve.
Future<FotoSelecionada?> escolherFotoDaGaleria() async {
  final arquivo = await ImagePicker().pickImage(
    source: ImageSource.gallery,
    maxWidth: 1600,
    maxHeight: 1600,
    imageQuality: 85,
  );

  if (arquivo == null) return null;

  return validarFoto(await arquivo.readAsBytes());
}

/// Campo de foto da caçamba: prévia, escolher/trocar e remover.
class FotoCacambaPicker extends StatelessWidget {
  const FotoCacambaPicker({
    super.key,
    required this.foto,
    required this.onChanged,
    required this.tamanhoM3,
    this.fotoAtualUrl,
    this.escolher = escolherFotoDaGaleria,
    this.erro,
  });

  /// Foto escolhida agora, ainda não enviada.
  final FotoSelecionada? foto;

  /// Foto que a caçamba já tem na API, se houver.
  final String? fotoAtualUrl;

  /// Tamanho usado para a imagem padrão quando não há foto.
  final double tamanhoM3;

  final ValueChanged<FotoSelecionada?> onChanged;

  /// Troca em testes para não abrir a galeria de verdade.
  final Future<FotoSelecionada?> Function() escolher;

  /// Erro devolvido pela API para o campo da foto.
  final String? erro;

  Future<void> _escolher(BuildContext context) async {
    try {
      final escolhida = await escolher();
      if (escolhida != null) onChanged(escolhida);
    } on FotoInvalidaException catch (error) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.mensagem)),
      );
    } catch (_) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível abrir a galeria de fotos.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final temFoto = foto != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: AspectRatio(
            aspectRatio: 2.2,
            child: temFoto
                ? Image.memory(
                    foto!.bytes,
                    key: const Key('foto_cacamba_previa'),
                    fit: BoxFit.cover,
                    // Alguns formatos (ex.: WebP) podem não abrir em todo
                    // aparelho; o envio continua valendo.
                    errorBuilder: (_, _, _) => Container(
                      color: AppColors.lightGray,
                      alignment: Alignment.center,
                      child: const Text(
                        'Foto selecionada',
                        style: TextStyle(color: Colors.black54),
                      ),
                    ),
                  )
                : CacambaImage(fotoUrl: fotoAtualUrl, tamanhoM3: tamanhoM3),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            OutlinedButton.icon(
              key: const Key('foto_cacamba_escolher'),
              onPressed: () => _escolher(context),
              icon: const Icon(Icons.photo_library_outlined, size: 19),
              label: Text(temFoto ? 'Trocar foto' : 'Escolher foto'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.green,
                side: const BorderSide(color: AppColors.green),
              ),
            ),
            if (temFoto) ...[
              const SizedBox(width: 8),
              TextButton(
                key: const Key('foto_cacamba_remover'),
                onPressed: () => onChanged(null),
                child: const Text('Remover'),
              ),
            ],
          ],
        ),
        if (erro != null) ...[
          const SizedBox(height: 6),
          Text(
            erro!,
            style: const TextStyle(color: Colors.red, fontSize: 12),
          ),
        ],
      ],
    );
  }
}
