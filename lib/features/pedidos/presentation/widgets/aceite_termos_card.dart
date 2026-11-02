import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/signature_pad_dialog.dart';
import '../../../institucional/presentation/pages/termos_condicoes_page.dart';

/// Aceite dos Termos e Condições com a assinatura desenhada.
///
/// Marcar a caixa abre o modal de assinatura. Sem assinar a caixa
/// continua desmarcada, e quem usa o card só libera o pedido quando
/// [assinatura] não é nula.
class AceiteTermosCard extends StatelessWidget {
  const AceiteTermosCard({
    super.key,
    required this.assinatura,
    required this.onChanged,
    this.habilitado = true,
  });

  /// PNG da assinatura, ou `null` enquanto não houve aceite.
  final Uint8List? assinatura;
  final ValueChanged<Uint8List?> onChanged;
  final bool habilitado;

  bool get _aceito => assinatura != null;

  Future<void> _alternar(BuildContext context) async {
    if (_aceito) {
      onChanged(null);
      return;
    }

    final desenho = await mostrarAssinatura(
      context,
      titulo: 'Assine o contrato',
      instrucao:
          'Ao assinar, você aceita os Termos e Condições e o contrato de '
          'locação.',
    );

    // Cancelou: a caixa continua desmarcada.
    if (desenho != null) onChanged(desenho);
  }

  void _abrirTermos(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const TermosCondicoesPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(8, 8, 14, 12),
      decoration: BoxDecoration(
        color: AppColors.lightGray,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _aceito ? AppColors.green : AppColors.border,
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                key: const Key('aceite_termos_checkbox'),
                value: _aceito,
                activeColor: AppColors.green,
                onChanged: habilitado ? (_) => _alternar(context) : null,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const Text(
                        'Li e aceito os ',
                        style: TextStyle(fontSize: 14, height: 1.35),
                      ),
                      GestureDetector(
                        key: const Key('aceite_termos_link'),
                        onTap: () => _abrirTermos(context),
                        child: const Text(
                          'Termos e Condições',
                          style: TextStyle(
                            color: AppColors.green,
                            fontSize: 14,
                            height: 1.35,
                            fontWeight: FontWeight.w800,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                      const Text(
                        ' e o contrato de locação. Preciso assinar para '
                        'continuar.',
                        style: TextStyle(fontSize: 14, height: 1.35),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (_aceito) ...[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Row(
                children: [
                  Container(
                    width: 120,
                    height: 40,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Image.memory(
                      assinatura!,
                      key: const Key('aceite_termos_previa'),
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(width: 10),
                  TextButton(
                    key: const Key('aceite_termos_refazer'),
                    onPressed: habilitado
                        ? () async {
                            final novo = await mostrarAssinatura(
                              context,
                              titulo: 'Refazer assinatura',
                            );
                            if (novo != null) onChanged(novo);
                          }
                        : null,
                    child: const Text('Refazer'),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
