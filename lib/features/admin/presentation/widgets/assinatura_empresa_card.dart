import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/async_value_view.dart';
import '../../data/fornecedor_repository.dart';
import 'foto_cacamba_picker.dart';

/// Regras do arquivo de assinatura da empresa (as mesmas da API).
const kAssinaturaMaxBytes = 300 * 1024;
const kAssinaturaLarguraMin = 300;
const kAssinaturaLarguraMax = 1200;
const kAssinaturaAlturaMin = 100;
const kAssinaturaAlturaMax = 400;

/// Assinatura padrão da empresa, ou `null` se ainda não foi enviada.
final assinaturaEmpresaProvider = FutureProvider.autoDispose<Uint8List?>((ref) {
  return ref.watch(fornecedorRepositoryProvider).assinaturaEmpresa();
});

/// Lê largura e altura de um PNG pelo cabeçalho (chunk IHDR).
({int largura, int altura})? dimensoesDoPng(Uint8List bytes) {
  const assinatura = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A];

  if (bytes.length < 24) return null;

  for (var i = 0; i < assinatura.length; i++) {
    if (bytes[i] != assinatura[i]) return null;
  }

  final dados = ByteData.sublistView(bytes);

  return (largura: dados.getUint32(16), altura: dados.getUint32(20));
}

/// Confere formato, tamanho, dimensões e proporção 3:1 antes de enviar,
/// para a pessoa ver o motivo na hora em vez de esperar a resposta da API.
void validarAssinaturaEmpresa(Uint8List bytes) {
  final dimensoes = dimensoesDoPng(bytes);

  if (dimensoes == null) {
    throw const FotoInvalidaException(
      'A assinatura precisa ser um arquivo PNG.',
    );
  }

  if (bytes.length > kAssinaturaMaxBytes) {
    throw const FotoInvalidaException(
      'O arquivo é maior que 300 KB. Reduza a imagem e tente de novo.',
    );
  }

  final (:largura, :altura) = dimensoes;

  if (largura < kAssinaturaLarguraMin ||
      largura > kAssinaturaLarguraMax ||
      altura < kAssinaturaAlturaMin ||
      altura > kAssinaturaAlturaMax) {
    throw FotoInvalidaException(
      'Tamanho inválido ($largura×$altura px). Use de '
      '$kAssinaturaLarguraMin×$kAssinaturaAlturaMin até '
      '$kAssinaturaLarguraMax×$kAssinaturaAlturaMax px.',
    );
  }

  if (((largura / altura) - 3).abs() / 3 > 0.05) {
    throw const FotoInvalidaException(
      'A proporção precisa ser 3:1 (largura três vezes a altura), '
      'por exemplo 900×300 px.',
    );
  }
}

/// Abre a galeria e devolve os bytes do arquivo escolhido (sem reduzir:
/// a assinatura precisa manter o tamanho exato).
Future<Uint8List?> escolherArquivoDeAssinatura() async {
  final arquivo = await ImagePicker().pickImage(source: ImageSource.gallery);

  return arquivo?.readAsBytes();
}

/// Card do perfil da loja para enviar, trocar e remover a assinatura que
/// vai nos contratos de locação.
class AssinaturaEmpresaCard extends ConsumerStatefulWidget {
  const AssinaturaEmpresaCard({
    super.key,
    this.escolherArquivo = escolherArquivoDeAssinatura,
  });

  /// Troca em testes para não abrir a galeria de verdade.
  final Future<Uint8List?> Function() escolherArquivo;

  @override
  ConsumerState<AssinaturaEmpresaCard> createState() =>
      _AssinaturaEmpresaCardState();
}

class _AssinaturaEmpresaCardState extends ConsumerState<AssinaturaEmpresaCard> {
  bool _salvando = false;

  void _aviso(String texto, {bool sucesso = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(texto),
        backgroundColor: sucesso ? AppColors.green : null,
      ),
    );
  }

  Future<void> _enviar() async {
    final Uint8List? bytes;

    try {
      bytes = await widget.escolherArquivo();
    } catch (_) {
      if (mounted) _aviso('Não foi possível abrir a galeria de arquivos.');
      return;
    }

    if (bytes == null || !mounted) return;

    try {
      validarAssinaturaEmpresa(bytes);
    } on FotoInvalidaException catch (erro) {
      _aviso(erro.mensagem);
      return;
    }

    setState(() => _salvando = true);

    try {
      await ref
          .read(fornecedorRepositoryProvider)
          .salvarAssinaturaEmpresa(
            'data:image/png;base64,${base64Encode(bytes)}',
          );
      if (!mounted) return;

      ref.invalidate(assinaturaEmpresaProvider);
      _aviso('Assinatura atualizada.', sucesso: true);
    } on ApiException catch (erro) {
      if (mounted) showApiError(context, erro);
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  Future<void> _remover() async {
    setState(() => _salvando = true);

    try {
      await ref.read(fornecedorRepositoryProvider).removerAssinaturaEmpresa();
      if (!mounted) return;

      ref.invalidate(assinaturaEmpresaProvider);
      _aviso('Assinatura removida.', sucesso: true);
    } on ApiException catch (erro) {
      if (mounted) showApiError(context, erro);
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final assinatura = ref.watch(assinaturaEmpresaProvider);
    final atual = assinatura.value;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Assinatura da empresa',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          const Text(
            'Aparece no contrato de locação de cada pedido novo. Envie um '
            'PNG com fundo transparente, na proporção 3:1 (ex.: 900×300 px), '
            'de 300×100 a 1200×400 px e até 300 KB. Você pode trocar quando '
            'quiser; contratos já emitidos não mudam.',
            style: TextStyle(color: Colors.black54, fontSize: 12, height: 1.4),
          ),
          const SizedBox(height: 14),
          Container(
            height: 90,
            width: double.infinity,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.lightGray,
              borderRadius: BorderRadius.circular(10),
            ),
            child: assinatura.isLoading && atual == null
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : atual != null
                ? Padding(
                    padding: const EdgeInsets.all(8),
                    child: Image.memory(
                      atual,
                      key: const Key('assinatura_empresa_previa'),
                      fit: BoxFit.contain,
                    ),
                  )
                : const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Nenhuma assinatura enviada. O contrato mostrará '
                      '"Assinado eletronicamente via plataforma".',
                      key: Key('assinatura_empresa_vazia'),
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.black54, fontSize: 12),
                    ),
                  ),
          ),
          if (assinatura.hasError) ...[
            const SizedBox(height: 8),
            const Text(
              'Não foi possível carregar a assinatura atual.',
              style: TextStyle(color: Colors.red, fontSize: 12),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              OutlinedButton.icon(
                key: const Key('assinatura_empresa_enviar'),
                onPressed: _salvando ? null : _enviar,
                icon: const Icon(Icons.upload_file, size: 19),
                label: Text(atual == null ? 'Enviar assinatura' : 'Trocar'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.green,
                  side: const BorderSide(color: AppColors.green),
                ),
              ),
              if (atual != null) ...[
                const SizedBox(width: 8),
                TextButton(
                  key: const Key('assinatura_empresa_remover'),
                  onPressed: _salvando ? null : _remover,
                  child: const Text('Remover'),
                ),
              ],
              if (_salvando) ...[
                const SizedBox(width: 12),
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
