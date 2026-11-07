import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/chat.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/async_value_view.dart';
import '../../../auth/data/sessao_provider.dart';
import '../../data/chat_repository.dart';
import '../chat_formatos.dart';
import '../chat_providers.dart';
import '../widgets/bolha_mensagem.dart';
import '../widgets/dados_pedido_sheet.dart';

/// De quanto em quanto tempo a conversa aberta busca mensagens novas.
const intervaloDaConversa = Duration(seconds: 5);

const _limiteDoTexto = 1000;

enum _Acao { verPedido, denunciar, fecharChamado, resolverDenuncia }

/// Abre a conversa e, quando a pessoa volta, atualiza lista e bolhas.
Future<void> abrirConversa(
  BuildContext context,
  WidgetRef ref,
  Conversa conversa,
) async {
  await Navigator.of(
    context,
  ).push(MaterialPageRoute<void>(builder: (_) => ChatPage(conversa: conversa)));

  ref.invalidate(conversasProvider);
  ref.invalidate(naoLidasProvider);
}

/// Abre a conversa do pedido (cria se for a primeira vez).
Future<void> abrirConversaDoPedido(
  BuildContext context,
  WidgetRef ref,
  String aluguelId,
) async {
  try {
    final conversa = await ref
        .read(chatRepositoryProvider)
        .conversaDoPedido(aluguelId);

    if (!context.mounted) return;
    await abrirConversa(context, ref, conversa);
  } on ApiException catch (erro) {
    if (context.mounted) showApiError(context, erro);
  }
}

/// Tela da conversa: voltar, nome do contato e menu (⋮) no topo, bolhas
/// no meio e o campo de texto embaixo.
class ChatPage extends ConsumerStatefulWidget {
  const ChatPage({super.key, required this.conversa});

  /// O que a lista já sabia; o detalhe completo é buscado ao abrir.
  final Conversa conversa;

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  final _texto = TextEditingController();

  late Conversa _conversa = widget.conversa;
  List<Mensagem> _mensagens = const [];
  bool _temAnteriores = false;
  bool _carregando = true;
  Object? _erro;

  bool _enviando = false;
  bool _buscandoAnteriores = false;
  bool _atualizando = false;
  Timer? _relogio;

  ChatRepository get _repositorio => ref.read(chatRepositoryProvider);

  bool get _souAdmin => ref.read(sessaoProvider).value?.isAdmin ?? false;

  @override
  void initState() {
    super.initState();
    _carregar();
    _relogio = Timer.periodic(intervaloDaConversa, (_) => _atualizar());
  }

  @override
  void dispose() {
    _relogio?.cancel();
    _texto.dispose();
    super.dispose();
  }

  Future<void> _carregar() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });

    try {
      // O detalhe vem primeiro: para o admin é ele que registra a abertura
      // de uma conversa de pedido.
      final detalhe = await _repositorio.detalhe(_conversa.id);
      final pagina = await _repositorio.mensagens(_conversa.id);

      if (!mounted) return;

      setState(() {
        _conversa = detalhe;
        _mensagens = pagina.itens;
        _temAnteriores = pagina.temAnteriores;
        _carregando = false;
      });

      // A API marcou as mensagens como lidas: atualiza as bolhas.
      ref.invalidate(naoLidasProvider);
    } catch (erro) {
      if (!mounted) return;
      setState(() {
        _erro = erro;
        _carregando = false;
      });
    }
  }

  /// Busca as mensagens recentes e junta às que já estão na tela, o que
  /// também atualiza o "lida" das minhas.
  Future<void> _atualizar() async {
    if (_carregando || _erro != null || _atualizando || _enviando) return;

    _atualizando = true;

    try {
      final pagina = await _repositorio.mensagens(_conversa.id);

      if (!mounted) return;

      final haNovas = pagina.itens.any(
        (m) => !_mensagens.any((atual) => atual.id == m.id),
      );
      final mudouLeitura = pagina.itens.any(
        (m) => _mensagens.any((a) => a.id == m.id && a.lida != m.lida),
      );

      if (haNovas || mudouLeitura) {
        setState(() {
          _mensagens = mesclarMensagens(_mensagens, pagina.itens);
        });
      }

      if (haNovas) ref.invalidate(naoLidasProvider);
    } catch (_) {
      // Falha passageira de rede: tenta de novo no próximo ciclo.
    } finally {
      _atualizando = false;
    }
  }

  Future<void> _carregarAnteriores() async {
    if (_buscandoAnteriores || _mensagens.isEmpty) return;

    setState(() => _buscandoAnteriores = true);

    try {
      final pagina = await _repositorio.mensagens(
        _conversa.id,
        antes: _mensagens.first.id,
      );

      if (!mounted) return;

      setState(() {
        _mensagens = mesclarMensagens(_mensagens, pagina.itens);
        _temAnteriores = pagina.temAnteriores;
      });
    } on ApiException catch (erro) {
      if (mounted) showApiError(context, erro);
    } finally {
      if (mounted) setState(() => _buscandoAnteriores = false);
    }
  }

  Future<void> _enviar() async {
    final texto = _texto.text.trim();

    if (texto.isEmpty || _enviando) return;

    setState(() => _enviando = true);

    try {
      final enviada = await _repositorio.enviar(_conversa.id, texto);

      if (!mounted) return;

      _texto.clear();
      setState(() => _mensagens = mesclarMensagens(_mensagens, [enviada]));
    } on ApiException catch (erro) {
      if (!mounted) return;
      showApiError(context, erro);

      // O chamado foi encerrado (ou a conversa venceu) enquanto digitava.
      if (erro.code == 'CONVERSATION_CLOSED' ||
          erro.code == 'ADMIN_READ_ONLY') {
        await _recarregarConversa();
      }
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  Future<void> _recarregarConversa() async {
    try {
      final detalhe = await _repositorio.detalhe(_conversa.id);
      if (mounted) setState(() => _conversa = detalhe);
    } catch (_) {
      // Mantém o que está na tela.
    }
  }

  Future<void> _escolher(_Acao acao) async {
    switch (acao) {
      case _Acao.verPedido:
        await _verPedido();
      case _Acao.denunciar:
        await _denunciar();
      case _Acao.fecharChamado:
        await _fecharChamado();
      case _Acao.resolverDenuncia:
        await _resolverDenuncia();
    }
  }

  Future<void> _verPedido() async {
    var pedido = _conversa.pedido;

    try {
      pedido ??= (await _repositorio.detalhe(_conversa.id)).pedido;
    } on ApiException catch (erro) {
      if (mounted) showApiError(context, erro);
      return;
    }

    if (!mounted) return;

    if (pedido == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Esta conversa não tem pedido.')),
      );
      return;
    }

    await mostrarDadosDoPedido(context, pedido);
  }

  Future<void> _denunciar() async {
    final motivo = await showDialog<String>(
      context: context,
      builder: (_) => const _DenunciaDialog(),
    );

    if (motivo == null || !mounted) return;

    try {
      await _repositorio.denunciar(_conversa.id, motivo: motivo);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Denúncia enviada. A equipe vai analisar a conversa.'),
          backgroundColor: AppColors.green,
        ),
      );
    } on ApiException catch (erro) {
      if (mounted) showApiError(context, erro);
    }
  }

  Future<void> _fecharChamado() async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Encerrar chamado?'),
        content: const Text(
          'O cliente não poderá mais responder e, se precisar, abrirá um '
          'novo chamado. O histórico continua visível.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Voltar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Encerrar'),
          ),
        ],
      ),
    );

    if (confirmou != true || !mounted) return;

    try {
      final fechado = await _repositorio.fecharChamado(_conversa.id);
      if (mounted) setState(() => _conversa = fechado);
    } on ApiException catch (erro) {
      if (mounted) showApiError(context, erro);
    }
  }

  Future<void> _resolverDenuncia() async {
    try {
      final atualizada = await _repositorio.resolverDenuncia(_conversa.id);
      if (mounted) setState(() => _conversa = atualizada);
    } on ApiException catch (erro) {
      if (mounted) showApiError(context, erro);
    }
  }

  @override
  Widget build(BuildContext context) {
    final admin = _souAdmin;

    return Scaffold(
      backgroundColor: fundoDoChat,
      appBar: AppBar(
        backgroundColor: AppColors.green,
        foregroundColor: Colors.white,
        titleSpacing: 0,
        title: _TituloDaConversa(conversa: _conversa),
        actions: [
          PopupMenuButton<_Acao>(
            tooltip: 'Mais opções',
            icon: const Icon(Icons.more_vert),
            onSelected: _escolher,
            itemBuilder: (_) => [
              if (_conversa.temPedido)
                const PopupMenuItem(
                  value: _Acao.verPedido,
                  child: Text('Ver dados do pedido'),
                ),
              if (admin && _conversa.ehChamado && _conversa.aberta)
                const PopupMenuItem(
                  value: _Acao.fecharChamado,
                  child: Text('Encerrar chamado'),
                ),
              if (admin && _conversa.denunciada)
                const PopupMenuItem(
                  value: _Acao.resolverDenuncia,
                  child: Text('Marcar denúncia como analisada'),
                ),
              if (!_conversa.somenteLeitura)
                const PopupMenuItem(
                  value: _Acao.denunciar,
                  child: Text('Denunciar conversa'),
                ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          if (_conversa.denunciada)
            const _Aviso(
              texto:
                  'Esta conversa foi denunciada. Analise e marque como '
                  'analisada pelo menu (⋮).',
              cor: Color(0xFFFFE3E3),
              icone: Icons.flag,
            ),
          if (_conversa.somenteLeitura)
            const _Aviso(
              texto:
                  'Você está acompanhando esta conversa. Administradores só '
                  'leem os chats de pedidos.',
              cor: Color(0xFFFFF6E5),
              icone: Icons.visibility_outlined,
            ),
          Expanded(child: _corpo()),
          _rodape(),
        ],
      ),
    );
  }

  Widget _corpo() {
    if (_carregando) return const LoadingView();

    if (_erro != null) {
      return SingleChildScrollView(
        child: ErrorView(error: _erro!, onRetry: _carregar),
      );
    }

    if (_mensagens.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            _conversa.podeEnviar
                ? 'Nenhuma mensagem ainda. Comece a conversa!'
                : 'Nenhuma mensagem nesta conversa.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.black54),
          ),
        ),
      );
    }

    // Lista invertida: a mensagem mais nova fica colada no campo de texto.
    final entradas = <Object>[];
    DateTime? ultimoDia;

    for (final mensagem in _mensagens) {
      final dia = mensagem.criadaEm?.toLocal();

      if (dia != null && (ultimoDia == null || !mesmoDia(dia, ultimoDia))) {
        entradas.add(dia);
        ultimoDia = dia;
      }

      entradas.add(mensagem);
    }

    final invertidas = entradas.reversed.toList();

    return ListView.builder(
      reverse: true,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: invertidas.length + (_temAnteriores ? 1 : 0),
      itemBuilder: (context, indice) {
        if (indice == invertidas.length) {
          return Center(
            child: TextButton(
              onPressed: _buscandoAnteriores ? null : _carregarAnteriores,
              child: Text(
                _buscandoAnteriores
                    ? 'Carregando...'
                    : 'Carregar mensagens anteriores',
              ),
            ),
          );
        }

        final entrada = invertidas[indice];

        return entrada is Mensagem
            ? BolhaMensagem(mensagem: entrada)
            : SeparadorDeDia(dia: entrada as DateTime);
      },
    );
  }

  Widget _rodape() {
    if (!_conversa.podeEnviar) {
      return Container(
        width: double.infinity,
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              const Icon(Icons.lock_outline, size: 18, color: Colors.black45),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _conversa.motivoBloqueio ?? 'Esta conversa está encerrada.',
                  key: const Key('chat_bloqueado'),
                  style: const TextStyle(color: Colors.black54, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      color: const Color(0xFFF5F5F5),
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                key: const Key('chat_campo'),
                controller: _texto,
                minLines: 1,
                maxLines: 5,
                maxLength: _limiteDoTexto,
                textCapitalization: TextCapitalization.sentences,
                keyboardType: TextInputType.multiline,
                inputFormatters: [
                  LengthLimitingTextInputFormatter(_limiteDoTexto),
                ],
                decoration: InputDecoration(
                  hintText: 'Mensagem',
                  counterText: '',
                  filled: true,
                  fillColor: Colors.white,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 11,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            IconButton.filled(
              key: const Key('chat_enviar'),
              tooltip: 'Enviar',
              onPressed: _enviando ? null : _enviar,
              style: IconButton.styleFrom(
                backgroundColor: AppColors.green,
                foregroundColor: Colors.white,
                minimumSize: const Size(46, 46),
              ),
              icon: _enviando
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send_rounded),
            ),
          ],
        ),
      ),
    );
  }
}

class _TituloDaConversa extends StatelessWidget {
  const _TituloDaConversa({required this.conversa});

  final Conversa conversa;

  @override
  Widget build(BuildContext context) {
    final detalhe = [
      if (conversa.contatoDetalhe != null) conversa.contatoDetalhe!,
      if (conversa.ehChamado && !conversa.aberta) 'Encerrado',
    ].join(' · ');

    return Row(
      children: [
        CircleAvatar(
          radius: 19,
          backgroundColor: Colors.white24,
          foregroundColor: Colors.white,
          child: Text(
            inicialDoNome(conversa.contatoNome),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                conversa.contatoNome,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (detalhe.isNotEmpty)
                Text(
                  detalhe,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Aviso extends StatelessWidget {
  const _Aviso({required this.texto, required this.cor, required this.icone});

  final String texto;
  final Color cor;
  final IconData icone;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: cor,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        children: [
          Icon(icone, size: 18, color: Colors.black54),
          const SizedBox(width: 8),
          Expanded(child: Text(texto, style: const TextStyle(fontSize: 12))),
        ],
      ),
    );
  }
}

class _DenunciaDialog extends StatefulWidget {
  const _DenunciaDialog();

  @override
  State<_DenunciaDialog> createState() => _DenunciaDialogState();
}

class _DenunciaDialogState extends State<_DenunciaDialog> {
  final _motivo = TextEditingController();

  @override
  void dispose() {
    _motivo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Denunciar conversa'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Os administradores serão avisados por e-mail para analisar '
            'esta conversa.',
            style: TextStyle(fontSize: 13, color: Colors.black54),
          ),
          const SizedBox(height: 14),
          TextField(
            key: const Key('denuncia_motivo'),
            controller: _motivo,
            maxLength: 300,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'O que aconteceu? (opcional)',
              border: OutlineInputBorder(),
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
          key: const Key('denuncia_enviar'),
          onPressed: () => Navigator.of(context).pop(_motivo.text.trim()),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          child: const Text('Denunciar'),
        ),
      ],
    );
  }
}
