import 'package:flutter/material.dart';

import '../../../../core/models/chat.dart';
import '../../../../core/theme/app_colors.dart';
import '../chat_formatos.dart';

const _fundoDaConversa = Color(0xFFEFEAE2);
const _bolhaMinha = Color(0xFFDCF8C6);

/// Fundo da área de mensagens.
const fundoDoChat = _fundoDaConversa;

/// Mensagem em bolha: minhas à direita (verde), do outro lado à
/// esquerda (branca), com a hora e, nas minhas, o "lida".
class BolhaMensagem extends StatelessWidget {
  const BolhaMensagem({super.key, required this.mensagem});

  final Mensagem mensagem;

  @override
  Widget build(BuildContext context) {
    final minha = mensagem.minha;
    final largura = MediaQuery.sizeOf(context).width;

    return Align(
      alignment: minha ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: largura * 0.78),
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        padding: const EdgeInsets.fromLTRB(10, 6, 10, 4),
        decoration: BoxDecoration(
          color: minha ? _bolhaMinha : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(12),
            topRight: const Radius.circular(12),
            bottomLeft: Radius.circular(minha ? 12 : 3),
            bottomRight: Radius.circular(minha ? 3 : 12),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (mensagem.remetenteNome != null)
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    mensagem.remetenteNome!,
                    style: const TextStyle(
                      color: AppColors.green,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            Align(
              alignment: Alignment.centerLeft,
              child: SelectableText(
                mensagem.texto,
                style: const TextStyle(fontSize: 15, height: 1.3),
              ),
            ),
            const SizedBox(height: 2),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  formatarHora(mensagem.criadaEm),
                  style: const TextStyle(fontSize: 11, color: Colors.black54),
                ),
                if (minha) ...[
                  const SizedBox(width: 3),
                  Icon(
                    mensagem.lida ? Icons.done_all : Icons.done,
                    key: Key(
                      mensagem.lida ? 'mensagem_lida' : 'mensagem_enviada',
                    ),
                    size: 15,
                    color: mensagem.lida
                        ? const Color(0xFF34B7F1)
                        : Colors.black45,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Etiqueta de dia entre as mensagens ("Hoje", "Ontem", "25/10/2026").
class SeparadorDeDia extends StatelessWidget {
  const SeparadorDeDia({super.key, required this.dia, this.agora});

  final DateTime dia;
  final DateTime? agora;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFE1F3FB),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          formatarDiaDaConversa(dia, agora: agora),
          style: const TextStyle(
            fontSize: 12,
            color: Colors.black54,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
