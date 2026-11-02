import 'package:flutter/material.dart';

import '../../../../core/models/aluguel.dart';
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

BoxDecoration _decoracao({Color cor = AppColors.border}) {
  return BoxDecoration(
    color: Colors.white,
    border: Border.all(color: cor),
    borderRadius: BorderRadius.circular(18),
  );
}

/// Baixar o contrato de locação em PDF.
class ContratoCard extends StatelessWidget {
  const ContratoCard({
    super.key,
    required this.onBaixar,
    this.baixando = false,
  });

  final VoidCallback onBaixar;
  final bool baixando;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _decoracao(),
      child: Row(
        children: [
          const Icon(Icons.description_outlined, color: AppColors.green),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Contrato de locação',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                ),
                SizedBox(height: 2),
                Text(
                  'PDF assinado, também enviado por e-mail.',
                  style: TextStyle(color: Colors.black54, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            key: const Key('baixar_contrato'),
            onPressed: baixando ? null : onBaixar,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.green,
              side: const BorderSide(color: AppColors.green),
            ),
            child: baixando
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Baixar PDF'),
          ),
        ],
      ),
    );
  }
}

/// Estado do pedido de extensão e botões para estender ou pagar.
class ExtensaoCard extends StatelessWidget {
  const ExtensaoCard({
    super.key,
    required this.resumo,
    required this.onEstender,
    required this.onPagar,
    this.ocupado = false,
  });

  final ResumoExtensao resumo;

  /// Abre a escolha de dias e envia o pedido.
  final VoidCallback onEstender;

  /// Paga a extensão aceita; recebe o id dela.
  final ValueChanged<String> onPagar;

  final bool ocupado;

  /// Vale mostrar o card? Sem permissão e sem histórico, não há o que dizer.
  static bool deveAparecer(Aluguel pedido) {
    final extensao = pedido.extensao;

    return extensao != null &&
        (extensao.permiteExtensao || extensao.atual != null);
  }

  @override
  Widget build(BuildContext context) {
    final atual = resumo.atual;
    final status = atual?.status;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _decoracao(
        cor: status == StatusExtensao.aguardandoPagamento
            ? AppColors.green
            : AppColors.border,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.update, color: AppColors.green),
              SizedBox(width: 10),
              Text(
                'Estender aluguel',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ..._conteudo(atual, status),
        ],
      ),
    );
  }

  List<Widget> _conteudo(Extensao? atual, StatusExtensao? status) {
    if (atual != null && status == StatusExtensao.solicitada) {
      return [
        Text(
          'Pedido de +${formatDias(atual.diasAdicionais)} '
          '(${formatMoney(atual.valor)}) enviado ao fornecedor.',
          key: const Key('extensao_solicitada'),
          style: const TextStyle(fontSize: 14),
        ),
        const SizedBox(height: 4),
        Text(
          'Ele responde até ${_dataHora(atual.solicitacaoExpiraEm)}. '
          'Avisaremos você por e-mail.',
          style: const TextStyle(color: Colors.black54, fontSize: 12),
        ),
      ];
    }

    if (atual != null && status == StatusExtensao.aguardandoPagamento) {
      return [
        Text(
          'O fornecedor aceitou +${formatDias(atual.diasAdicionais)}. '
          'Pague ${formatMoney(atual.valor)} até '
          '${_dataHora(atual.pagamentoExpiraEm)} ou a renovação será '
          'cancelada.',
          key: const Key('extensao_aguardando_pagamento'),
          style: const TextStyle(fontSize: 14, height: 1.35),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            key: const Key('pagar_extensao'),
            onPressed: ocupado ? null : () => onPagar(atual.id),
            style: ElevatedButton.styleFrom(
              elevation: 0,
              backgroundColor: AppColors.green,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.pix),
            label: const Text(
              'Pagar extensão',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ),
      ];
    }

    return [
      if (atual != null)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text(
            'Último pedido (+${formatDias(atual.diasAdicionais)}): '
            '${atual.status?.label ?? '-'}.',
            key: const Key('extensao_ultimo'),
            style: const TextStyle(color: Colors.black54, fontSize: 13),
          ),
        ),
      if (resumo.diasExtra > 0)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text(
            'Já estendido em ${formatDias(resumo.diasExtra)}.',
            style: const TextStyle(fontSize: 13),
          ),
        ),
      if (resumo.podeEstender)
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            key: const Key('estender_aluguel'),
            onPressed: ocupado ? null : onEstender,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.green,
              side: const BorderSide(color: AppColors.green),
            ),
            icon: const Icon(Icons.add_circle_outline),
            label: const Text(
              'Estender aluguel',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        )
      else
        Text(
          _motivo(resumo.motivoBloqueio),
          key: const Key('extensao_indisponivel'),
          style: const TextStyle(color: Colors.black54, fontSize: 12),
        ),
    ];
  }

  static String _motivo(String? codigo) {
    return switch (codigo) {
      'EXTENSION_INVALID_STATUS' =>
        'A extensão fica disponível enquanto a caçamba está em uso.',
      'ORDER_NOT_PAID' => 'Pague o pedido para poder estendê-lo.',
      'EXTENSION_LIMIT_EXCEEDED' =>
        'O aluguel já chegou ao limite de dias.',
      'EXTENSION_NOT_ALLOWED' => 'Esta caçamba não permite extensão.',
      _ => 'No momento não é possível estender este aluguel.',
    };
  }
}

/// Pergunta quantos dias estender. Devolve `null` se cancelar.
Future<int?> mostrarEscolhaDeDias(
  BuildContext context,
  ResumoExtensao resumo,
) {
  return showDialog<int>(
    context: context,
    builder: (_) => _EscolhaDeDiasDialog(resumo: resumo),
  );
}

class _EscolhaDeDiasDialog extends StatefulWidget {
  const _EscolhaDeDiasDialog({required this.resumo});

  final ResumoExtensao resumo;

  @override
  State<_EscolhaDeDiasDialog> createState() => _EscolhaDeDiasDialogState();
}

class _EscolhaDeDiasDialogState extends State<_EscolhaDeDiasDialog> {
  int _dias = 1;

  int get _maximo =>
      widget.resumo.maxDiasPorExtensao.clamp(1, 30).toInt();

  @override
  Widget build(BuildContext context) {
    final total = widget.resumo.diariaTotal * _dias;

    return AlertDialog(
      title: const Text(
        'Estender aluguel',
        style: TextStyle(fontWeight: FontWeight.w800),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quantos dias a mais? O fornecedor recebe o pedido por e-mail e '
            'decide se aceita. Se aceitar, você terá 24 horas para pagar.',
            style: TextStyle(fontSize: 13, height: 1.35),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton.outlined(
                key: const Key('extensao_menos'),
                onPressed: _dias > 1 ? () => setState(() => _dias--) : null,
                icon: const Icon(Icons.remove),
              ),
              SizedBox(
                width: 110,
                child: Text(
                  formatDias(_dias),
                  key: const Key('extensao_dias'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              IconButton.outlined(
                key: const Key('extensao_mais'),
                onPressed: _dias < _maximo ? () => setState(() => _dias++) : null,
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Center(
            child: Text(
              'Valor da extensão: ${formatMoney(total)}',
              key: const Key('extensao_valor'),
              style: const TextStyle(
                color: AppColors.green,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          key: const Key('extensao_enviar'),
          onPressed: () => Navigator.of(context).pop(_dias),
          style: ElevatedButton.styleFrom(
            elevation: 0,
            backgroundColor: AppColors.green,
            foregroundColor: Colors.white,
          ),
          child: const Text(
            'Enviar pedido',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }
}
