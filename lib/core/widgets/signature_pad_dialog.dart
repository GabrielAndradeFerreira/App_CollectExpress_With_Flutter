import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:signature/signature.dart';

import '../theme/app_colors.dart';

/// Pontos mínimos para considerar que a pessoa realmente assinou (evita
/// aceitar um toque sem querer).
const kMinimoPontosAssinatura = 12;

/// Proporção largura/altura da área de assinatura e da imagem enviada.
const _proporcao = 3.0;

/// Abre o modal para desenhar a assinatura com o dedo ou o mouse.
///
/// Devolve a imagem PNG (fundo transparente, 900x300) ou `null` se a
/// pessoa cancelar.
Future<Uint8List?> mostrarAssinatura(
  BuildContext context, {
  String titulo = 'Assine aqui',
  String instrucao = 'Desenhe a sua assinatura no quadro abaixo.',
}) {
  return showDialog<Uint8List>(
    context: context,
    barrierDismissible: false,
    builder: (_) => SignaturePadDialog(titulo: titulo, instrucao: instrucao),
  );
}

class SignaturePadDialog extends StatefulWidget {
  const SignaturePadDialog({
    super.key,
    required this.titulo,
    required this.instrucao,
  });

  final String titulo;
  final String instrucao;

  @override
  State<SignaturePadDialog> createState() => _SignaturePadDialogState();
}

class _SignaturePadDialogState extends State<SignaturePadDialog> {
  final _controller = SignatureController(
    penStrokeWidth: 3,
    penColor: Colors.black,
    strokeCap: StrokeCap.round,
    strokeJoin: StrokeJoin.round,
  );

  bool _confirmando = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _confirmar() async {
    setState(() => _confirmando = true);

    final png = await _controller.toPngBytes(width: 900, height: 300);

    if (!mounted) return;

    Navigator.of(context).pop(png);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.titulo,
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
      content: SizedBox(
        width: 460,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.instrucao,
              style: const TextStyle(color: Colors.black54, fontSize: 13),
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final largura = constraints.maxWidth;

                return DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.border, width: 2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Signature(
                      key: const Key('assinatura_area'),
                      controller: _controller,
                      width: largura - 4,
                      height: (largura - 4) / _proporcao,
                      backgroundColor: Colors.white,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          key: const Key('assinatura_limpar'),
          onPressed: _confirmando ? null : _controller.clear,
          child: const Text('Limpar'),
        ),
        TextButton(
          key: const Key('assinatura_cancelar'),
          onPressed: _confirmando ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        // Reage a cada traço para liberar o botão só com assinatura.
        ListenableBuilder(
          listenable: _controller,
          builder: (context, _) {
            final assinou =
                _controller.value.length >= kMinimoPontosAssinatura;

            return ElevatedButton(
              key: const Key('assinatura_confirmar'),
              onPressed: assinou && !_confirmando ? _confirmar : null,
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: AppColors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text(
                'Confirmar',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            );
          },
        ),
      ],
    );
  }
}
