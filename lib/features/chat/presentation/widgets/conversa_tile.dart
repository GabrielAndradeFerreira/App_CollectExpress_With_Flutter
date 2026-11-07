import 'package:flutter/material.dart';

import '../../../../core/models/chat.dart';
import '../../../../core/theme/app_colors.dart';
import '../chat_formatos.dart';

/// Linha da lista de conversas, no estilo dos aplicativos de chat:
/// avatar, nome, prévia da última mensagem, hora e bolha de não lidas.
class ConversaTile extends StatelessWidget {
  const ConversaTile({
    super.key,
    required this.conversa,
    required this.onTap,
    this.agora,
  });

  final Conversa conversa;
  final VoidCallback onTap;

  /// Só para os testes fixarem "hoje".
  final DateTime? agora;

  @override
  Widget build(BuildContext context) {
    final ultima = conversa.ultimaMensagem;
    final temNaoLidas = conversa.naoLidas > 0;

    final previa = ultima == null
        ? (conversa.contatoDetalhe ?? 'Sem mensagens ainda')
        : '${ultima.minha ? 'Você: ' : ''}${ultima.texto}';

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            _Avatar(nome: conversa.contatoNome, tipo: conversa.tipo),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          conversa.contatoNome,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: temNaoLidas
                                ? FontWeight.w800
                                : FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        formatarAtividade(
                          conversa.ultimaMensagem?.criadaEm ??
                              conversa.ultimaAtividadeEm,
                          agora: agora,
                        ),
                        style: TextStyle(
                          fontSize: 12,
                          color: temNaoLidas ? AppColors.green : Colors.black54,
                          fontWeight: temNaoLidas
                              ? FontWeight.w700
                              : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                  if (conversa.contatoDetalhe != null && ultima != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 1),
                      child: Text(
                        conversa.contatoDetalhe!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.green,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          previa,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            color: temNaoLidas
                                ? Colors.black87
                                : Colors.black54,
                            fontStyle: ultima == null
                                ? FontStyle.italic
                                : FontStyle.normal,
                          ),
                        ),
                      ),
                      if (conversa.denunciada) ...[
                        const SizedBox(width: 6),
                        const _Selo(texto: 'Denunciada', cor: Colors.red),
                      ],
                      if (conversa.ehChamado && !conversa.aberta) ...[
                        const SizedBox(width: 6),
                        const _Selo(texto: 'Encerrado', cor: Colors.black54),
                      ],
                      if (temNaoLidas) ...[
                        const SizedBox(width: 8),
                        BolhaNaoLidas(total: conversa.naoLidas),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Círculo verde com o total de não lidas (`99+` acima de 99).
class BolhaNaoLidas extends StatelessWidget {
  const BolhaNaoLidas({super.key, required this.total});

  final int total;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 22, minHeight: 22),
      padding: const EdgeInsets.symmetric(horizontal: 6),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.green,
        borderRadius: BorderRadius.circular(11),
      ),
      child: Text(
        total > 99 ? '99+' : '$total',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _Selo extends StatelessWidget {
  const _Selo({required this.texto, required this.cor});

  final String texto;
  final Color cor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        texto,
        style: TextStyle(color: cor, fontSize: 10, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.nome, required this.tipo});

  final String nome;
  final TipoConversa tipo;

  @override
  Widget build(BuildContext context) {
    final suporte = tipo != TipoConversa.pedido;

    return CircleAvatar(
      radius: 25,
      backgroundColor: suporte ? AppColors.green : const Color(0xFFD7D7D7),
      foregroundColor: suporte ? Colors.white : Colors.black87,
      child: suporte && nome == 'Suporte CollectExpress'
          ? const Icon(Icons.support_agent)
          : Text(
              inicialDoNome(nome),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
    );
  }
}
