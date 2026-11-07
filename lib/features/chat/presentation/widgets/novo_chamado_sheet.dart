import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/aluguel.dart';
import '../../../../core/models/chat.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../pedidos/data/pedidos_repository.dart';
import '../../data/chat_repository.dart';

/// Pedidos que o cliente pode ligar ao chamado.
final _pedidosParaChamadoProvider = FutureProvider.autoDispose<List<Aluguel>>((
  ref,
) async {
  final pagina = await ref.watch(pedidosRepositoryProvider).meusPedidos();
  return pagina.itens;
});

/// Formulário de novo chamado com o suporte. Devolve a conversa criada,
/// ou `null` se a pessoa desistir.
Future<Conversa?> mostrarNovoChamado(BuildContext context) {
  return showModalBottomSheet<Conversa>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    builder: (_) => const _NovoChamadoSheet(),
  );
}

class _NovoChamadoSheet extends ConsumerStatefulWidget {
  const _NovoChamadoSheet();

  @override
  ConsumerState<_NovoChamadoSheet> createState() => _NovoChamadoSheetState();
}

class _NovoChamadoSheetState extends ConsumerState<_NovoChamadoSheet> {
  final _assunto = TextEditingController();
  final _mensagem = TextEditingController();

  String? _aluguelId;
  bool _enviando = false;
  String? _erro;

  /// Chamado que já estava aberto, quando a API recusa um segundo.
  String? _chamadoAberto;

  @override
  void dispose() {
    _assunto.dispose();
    _mensagem.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    if (_assunto.text.trim().isEmpty || _mensagem.text.trim().isEmpty) {
      setState(() => _erro = 'Informe o assunto e descreva o problema.');
      return;
    }

    setState(() {
      _enviando = true;
      _erro = null;
      _chamadoAberto = null;
    });

    try {
      final conversa = await ref
          .read(chatRepositoryProvider)
          .abrirChamado(
            assunto: _assunto.text,
            mensagem: _mensagem.text,
            aluguelId: _aluguelId,
          );

      if (mounted) Navigator.of(context).pop(conversa);
    } on ApiException catch (erro) {
      if (!mounted) return;
      setState(() {
        _erro = erro.message;
        _chamadoAberto = erro.code == 'CHAMADO_ALREADY_OPEN'
            ? erro.fields['conversa_id']
            : null;
      });
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  Future<void> _abrirExistente() async {
    final id = _chamadoAberto;
    if (id == null) return;

    try {
      final conversa = await ref.read(chatRepositoryProvider).detalhe(id);
      if (mounted) Navigator.of(context).pop(conversa);
    } on ApiException catch (erro) {
      if (mounted) setState(() => _erro = erro.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pedidos = ref.watch(_pedidosParaChamadoProvider).value ?? const [];

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 4, 22, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Novo chamado',
                style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              const Text(
                'Conte o que aconteceu. A equipe do Collect Express responde '
                'por aqui, no chat.',
                style: TextStyle(color: Colors.black54, fontSize: 13),
              ),
              const SizedBox(height: 16),
              TextField(
                key: const Key('chamado_assunto'),
                controller: _assunto,
                maxLength: 120,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Assunto',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                key: const Key('chamado_mensagem'),
                controller: _mensagem,
                maxLength: 1000,
                minLines: 3,
                maxLines: 6,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Descreva o problema',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
              ),
              if (pedidos.isNotEmpty) ...[
                const SizedBox(height: 8),
                DropdownButtonFormField<String?>(
                  key: const Key('chamado_pedido'),
                  initialValue: _aluguelId,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Pedido relacionado (opcional)',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('Nenhum'),
                    ),
                    for (final pedido in pedidos)
                      DropdownMenuItem<String?>(
                        value: pedido.id,
                        child: Text(
                          '${formatDate(pedido.dataPedido)} · '
                          '${pedido.cacambeiroNome ?? 'Pedido'} · '
                          '${formatMoney(pedido.precoFinal)}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: (valor) => setState(() => _aluguelId = valor),
                ),
              ],
              if (_erro != null) ...[
                const SizedBox(height: 12),
                Text(
                  _erro!,
                  key: const Key('chamado_erro'),
                  style: const TextStyle(color: Colors.red, fontSize: 13),
                ),
                if (_chamadoAberto != null)
                  TextButton(
                    key: const Key('chamado_abrir_existente'),
                    onPressed: _abrirExistente,
                    child: const Text('Abrir o chamado em andamento'),
                  ),
              ],
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  key: const Key('chamado_enviar'),
                  onPressed: _enviando ? null : _enviar,
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: AppColors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(11),
                    ),
                  ),
                  child: _enviando
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Abrir chamado',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
