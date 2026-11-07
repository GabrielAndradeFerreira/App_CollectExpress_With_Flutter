import 'package:flutter/material.dart';

import '../../../../core/models/chat.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';

/// Folha com os dados do pedido ligado à conversa (sem telefone).
Future<void> mostrarDadosDoPedido(
  BuildContext context,
  PedidoDaConversa pedido,
) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    builder: (_) => _DadosDoPedido(pedido: pedido),
  );
}

class _DadosDoPedido extends StatelessWidget {
  const _DadosDoPedido({required this.pedido});

  final PedidoDaConversa pedido;

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
                'Pedido ${pedido.codigo}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 14),
              _Linha('Situação', pedido.status?.label ?? '-'),
              _Linha('Pagamento', pedido.pagamento?.label ?? '-'),
              _Linha('Pedido feito em', formatDate(pedido.dataPedido)),
              _Linha('Início do aluguel', formatDate(pedido.dataInicio)),
              _Linha('Duração', formatDias(pedido.diasAluguel)),
              _Linha('Entrega em', pedido.enderecoTexto),
              const Divider(height: 28),
              const Text(
                'Itens',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              for (final item in pedido.itens)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          '${item.quantidade}× ${item.nome} '
                          '(${formatVolume(item.tamanhoM3)})',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '${formatDias(item.diasAluguel)} · '
                        '${formatMoney(item.precoDiaria)}/dia',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              const Divider(height: 24),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Total',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Text(
                    formatMoney(pedido.precoFinal),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.green,
                    ),
                  ),
                ],
              ),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 128,
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
