import 'package:flutter/material.dart';

import '../../../../core/models/reciclagem.dart';
import '../../../../core/utils/formatters.dart';

/// Folha com os dados da coleta ligada à conversa (sem telefone nem
/// e-mail).
Future<void> mostrarDadosDaColeta(BuildContext context, Coleta coleta) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    builder: (_) => _DadosDaColeta(coleta: coleta),
  );
}

class _DadosDaColeta extends StatelessWidget {
  const _DadosDaColeta({required this.coleta});

  final Coleta coleta;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.8,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 0, 22, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Coleta ${coleta.codigo}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 14),
              _Linha('Situação', coleta.status.label),
              _Linha('Retirada em', formatDateTime(coleta.dataAgendada)),
              _Linha('Material', coleta.materiais.join(', ')),
              _Linha('Descrição', coleta.descricao),
              _Linha('Quantidade', coleta.quantidadeEstimada),
              _Linha('Quem entrega', coleta.geradorNome),
              _Linha('Parceiro', coleta.parceiroNome),
              _Linha('Local', coleta.enderecoTexto),
            ],
          ),
        ),
      ),
    );
  }
}

class _Linha extends StatelessWidget {
  const _Linha(this.rotulo, this.valor);

  final String rotulo;
  final String valor;

  @override
  Widget build(BuildContext context) {
    if (valor.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 112,
            child: Text(
              rotulo,
              style: const TextStyle(color: Colors.black54, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              valor,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
