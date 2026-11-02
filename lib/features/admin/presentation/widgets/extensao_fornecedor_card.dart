import 'package:flutter/material.dart';

import '../../../../core/models/extensao.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';

String _dataHora(DateTime? data) {
  if (data == null) return '-';

  final local = data.toLocal();
  String dois(int n) => n.toString().padLeft(2, '0');

  return '${dois(local.day)}/${dois(local.month)} às '
      '${dois(local.hour)}:${dois(local.minute)}';
}

/// Pedido de extensão de aluguel visto pelo fornecedor: aceitar ou
/// recusar enquanto está aberto, e o andamento depois disso.
class ExtensaoFornecedorCard extends StatelessWidget {
  const ExtensaoFornecedorCard({
    super.key,
    required this.extensao,
    required this.onResponder,
    this.ocupado = false,
  });

  final Extensao extensao;

  /// `true` para aceitar, `false` para recusar.
  final ValueChanged<bool> onResponder;
  final bool ocupado;

  @override
  Widget build(BuildContext context) {
    final status = extensao.status;
    final aberta = status == StatusExtensao.solicitada;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: aberta ? AppColors.yellow : AppColors.border,
          width: aberta ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.update, color: AppColors.green),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Pedido de extensão: +${formatDias(extensao.diasAdicionais)}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Valor: ${formatMoney(extensao.valor)}',
            style: const TextStyle(
              color: AppColors.green,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _situacao(extensao),
            key: const Key('extensao_situacao'),
            style: const TextStyle(color: Colors.black54, fontSize: 13),
          ),
          if (aberta) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      key: const Key('extensao_aceitar'),
                      onPressed: ocupado ? null : () => onResponder(true),
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: AppColors.green,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text(
                        'Aceitar',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: OutlinedButton(
                      key: const Key('extensao_recusar'),
                      onPressed: ocupado ? null : () => onResponder(false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                      ),
                      child: const Text(
                        'Recusar',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  static String _situacao(Extensao extensao) {
    return switch (extensao.status) {
      StatusExtensao.solicitada =>
        'Responda até ${_dataHora(extensao.solicitacaoExpiraEm)}. '
            'Se aceitar, o cliente terá 24 horas para pagar.',
      StatusExtensao.aguardandoPagamento =>
        'Aceita. O cliente tem até '
            '${_dataHora(extensao.pagamentoExpiraEm)} para pagar.',
      StatusExtensao.paga => 'Paga. O aluguel foi estendido.',
      StatusExtensao.recusada => 'Você recusou este pedido.',
      StatusExtensao.expirada => 'Expirou sem resposta ou sem pagamento.',
      StatusExtensao.cancelada => 'Cancelado.',
      null => '',
    };
  }
}
