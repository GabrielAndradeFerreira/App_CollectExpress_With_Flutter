import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/async_value_view.dart';
import '../../pedidos/presentation/compartilhar_pdf.dart';
import '../data/reciclagem_repository.dart';
import 'reciclagem_providers.dart';

void _atualizarListas(WidgetRef ref) {
  ref.invalidate(coletasProvider);
  ref.invalidate(coletaProvider);
  ref.invalidate(minhasOfertasProvider);
  ref.invalidate(resumoColetasProvider);
  ref.invalidate(ofertasDisponiveisProvider);
}

/// Baixa o termo de coleta (PDF com as 3 assinaturas e o código de
/// autenticação) e entrega para a pessoa salvar ou compartilhar.
Future<void> baixarDocumentoDaColeta(
  BuildContext context,
  WidgetRef ref, {
  required String coletaId,
  required String codigo,
}) async {
  try {
    final bytes = await ref
        .read(reciclagemRepositoryProvider)
        .documento(coletaId);

    await ref.read(compartilharPdfProvider)(bytes, 'termo-coleta-$codigo.pdf');
  } on ApiException catch (erro) {
    if (context.mounted) showApiError(context, erro);
  } catch (_) {
    if (context.mounted) {
      showApiError(context, 'Não foi possível abrir o documento.');
    }
  }
}

/// Pergunta o motivo e cancela a coleta. Devolve `true` se cancelou.
///
/// Quem entrega ([geradorPodeEncerrar]) escolhe se a sinalização volta
/// para a vitrine (padrão) ou é encerrada junto.
Future<bool> cancelarColetaComConfirmacao(
  BuildContext context,
  WidgetRef ref, {
  required String coletaId,
  required bool geradorPodeEncerrar,
}) async {
  final resposta = await showDialog<({String motivo, bool encerrar})>(
    context: context,
    builder: (_) => _CancelarDialog(geradorPodeEncerrar: geradorPodeEncerrar),
  );

  if (resposta == null || !context.mounted) return false;

  try {
    await ref
        .read(reciclagemRepositoryProvider)
        .cancelarColeta(
          coletaId,
          motivo: resposta.motivo,
          encerrarSinalizacao: resposta.encerrar,
        );

    _atualizarListas(ref);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Coleta cancelada. A outra parte foi avisada.'),
          backgroundColor: AppColors.green,
        ),
      );
    }

    return true;
  } on ApiException catch (erro) {
    if (context.mounted) showApiError(context, erro);
    return false;
  }
}

class _CancelarDialog extends StatefulWidget {
  const _CancelarDialog({required this.geradorPodeEncerrar});

  final bool geradorPodeEncerrar;

  @override
  State<_CancelarDialog> createState() => _CancelarDialogState();
}

class _CancelarDialogState extends State<_CancelarDialog> {
  final _motivo = TextEditingController();
  bool _encerrar = false;

  @override
  void dispose() {
    _motivo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Cancelar coleta?'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.geradorPodeEncerrar
                  ? 'O parceiro será avisado por e-mail. Se você não '
                        'encerrar a sinalização, ela volta para a vitrine '
                        'e outro parceiro pode agendar.'
                  : 'Quem entrega o material será avisado por e-mail.',
              style: const TextStyle(fontSize: 13, color: Colors.black54),
            ),
            const SizedBox(height: 14),
            TextField(
              key: const Key('cancelar_motivo'),
              controller: _motivo,
              maxLength: 300,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Motivo (opcional)',
                border: OutlineInputBorder(),
              ),
            ),
            if (widget.geradorPodeEncerrar)
              CheckboxListTile(
                key: const Key('cancelar_encerrar'),
                value: _encerrar,
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: const Text(
                  'Encerrar também a sinalização',
                  style: TextStyle(fontSize: 14),
                ),
                onChanged: (valor) =>
                    setState(() => _encerrar = valor ?? false),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Voltar'),
        ),
        ElevatedButton(
          key: const Key('cancelar_confirmar'),
          onPressed: () =>
              Navigator.of(context)
                  .pop((motivo: _motivo.text.trim(), encerrar: _encerrar)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          child: const Text('Cancelar coleta'),
        ),
      ],
    );
  }
}

/// Pergunta o peso real (opcional) e conclui a coleta. Devolve `true` se
/// concluiu.
Future<bool> concluirColetaComPeso(
  BuildContext context,
  WidgetRef ref, {
  required String coletaId,
}) async {
  final resposta = await showDialog<({double? peso})>(
    context: context,
    builder: (_) => const _ConcluirDialog(),
  );

  if (resposta == null || !context.mounted) return false;

  try {
    await ref
        .read(reciclagemRepositoryProvider)
        .concluirColeta(coletaId, pesoRealKg: resposta.peso);

    _atualizarListas(ref);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Coleta concluída.'),
          backgroundColor: AppColors.green,
        ),
      );
    }

    return true;
  } on ApiException catch (erro) {
    if (context.mounted) showApiError(context, erro);
    return false;
  }
}

class _ConcluirDialog extends StatefulWidget {
  const _ConcluirDialog();

  @override
  State<_ConcluirDialog> createState() => _ConcluirDialogState();
}

class _ConcluirDialogState extends State<_ConcluirDialog> {
  final _peso = TextEditingController();
  String? _erro;

  @override
  void dispose() {
    _peso.dispose();
    super.dispose();
  }

  void _confirmar() {
    final texto = _peso.text.trim();

    if (texto.isEmpty) {
      Navigator.of(context).pop((peso: null));
      return;
    }

    var normalizado = texto;
    if (normalizado.contains(',')) {
      normalizado = normalizado.replaceAll('.', '').replaceAll(',', '.');
    }

    final kg = double.tryParse(normalizado);

    if (kg == null || kg <= 0 || kg > 10000000) {
      setState(() => _erro = 'Informe um peso válido em kg.');
      return;
    }

    Navigator.of(context).pop((peso: kg));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Concluir coleta'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Confirme que o material foi retirado. Se quiser, informe o peso '
            'real coletado.',
            style: TextStyle(fontSize: 13, color: Colors.black54),
          ),
          const SizedBox(height: 14),
          TextField(
            key: const Key('concluir_peso'),
            controller: _peso,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Peso real (opcional)',
              suffixText: 'kg',
              errorText: _erro,
              border: const OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Voltar'),
        ),
        ElevatedButton(
          key: const Key('concluir_confirmar'),
          onPressed: _confirmar,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.green,
            foregroundColor: Colors.white,
          ),
          child: const Text('Concluir'),
        ),
      ],
    );
  }
}
