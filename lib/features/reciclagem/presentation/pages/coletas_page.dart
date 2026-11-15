import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/reciclagem.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_bottom_navigation.dart';
import '../../../../core/widgets/async_value_view.dart';
import '../../../auth/data/sessao_provider.dart';
import '../../../chat/presentation/pages/chat_page.dart';
import '../coleta_acoes.dart';
import '../reciclagem_providers.dart';
import '../widgets/reciclagem_widgets.dart';

/// Coletas agendadas. Serve ao parceiro (que retira) e a quem entrega o
/// material (cliente ou caçambeiro): a API devolve as coletas de cada um.
class ColetasPage extends ConsumerStatefulWidget {
  const ColetasPage({super.key});

  @override
  ConsumerState<ColetasPage> createState() => _ColetasPageState();
}

class _ColetasPageState extends ConsumerState<ColetasPage> {
  /// `null` = todas.
  StatusColeta? _status;
  int _paginas = 1;

  FiltroColetas _filtro(int pagina) => (status: _status, pagina: pagina);

  @override
  Widget build(BuildContext context) {
    final usuario = ref.watch(sessaoProvider).value;
    final parceiro = usuario?.isParceiro ?? false;

    final paginas = [
      for (var pagina = 1; pagina <= _paginas; pagina++)
        ref.watch(coletasProvider(_filtro(pagina))),
    ];
    final primeira = paginas.first;
    final coletas = [for (final p in paginas) ...?p.value?.itens];
    final carregandoMais = paginas.length > 1 && paginas.last.isLoading;
    final temProxima = paginas.last.value?.temProxima ?? false;

    return ReciclagemScaffold(
      aba: AbaReciclagem.coletas,
      child: RefreshIndicator(
        color: AppColors.green,
        onRefresh: () async {
          ref.invalidate(coletasProvider);
          await ref.read(coletasProvider(_filtro(1)).future);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 28),
          children: [
            TituloDaTela(
              parceiro ? 'Minhas coletas' : 'Coletas agendadas',
              subtitulo: parceiro
                  ? 'Retiradas que você agendou.'
                  : 'Retiradas agendadas por parceiros para o seu material.',
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              children: [
                for (final (rotulo, valor) in <(String, StatusColeta?)>[
                  ('Todas', null),
                  ('Agendadas', StatusColeta.agendada),
                  ('Concluídas', StatusColeta.concluida),
                  ('Canceladas', StatusColeta.cancelada),
                ])
                  ChoiceChip(
                    label: Text(rotulo),
                    selected: _status == valor,
                    showCheckmark: false,
                    onSelected: (_) => setState(() {
                      _status = valor;
                      _paginas = 1;
                    }),
                    selectedColor: AppColors.green,
                    backgroundColor: AppColors.lightGray,
                    side: BorderSide.none,
                    labelStyle: TextStyle(
                      color: _status == valor ? Colors.white : Colors.black54,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            if (primeira.hasError && !primeira.hasValue)
              ErrorView(
                error: primeira.error!,
                onRetry: () => ref.invalidate(coletasProvider),
              )
            else if (primeira.isLoading && !primeira.hasValue)
              const LoadingView()
            else if (coletas.isEmpty)
              SizedBox(
                height: 240,
                child: EstadoVazio(
                  icone: Icons.calendar_month_outlined,
                  texto: parceiro
                      ? 'Nenhuma coleta por aqui. Agende uma retirada nas '
                            'sinalizações.'
                      : 'Nenhuma coleta por aqui. Quando um parceiro agendar '
                            'a retirada do seu material, ela aparece aqui.',
                ),
              )
            else ...[
              for (final coleta in coletas)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _CartaoDaColeta(coleta: coleta, parceiro: parceiro),
                ),
              if (temProxima || carregandoMais)
                Center(
                  child: carregandoMais
                      ? const CircularProgressIndicator(color: AppColors.green)
                      : TextButton(
                          onPressed: () => setState(() => _paginas++),
                          child: const Text('Carregar mais'),
                        ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CartaoDaColeta extends ConsumerStatefulWidget {
  const _CartaoDaColeta({required this.coleta, required this.parceiro});

  final Coleta coleta;
  final bool parceiro;

  @override
  ConsumerState<_CartaoDaColeta> createState() => _CartaoDaColetaState();
}

class _CartaoDaColetaState extends ConsumerState<_CartaoDaColeta> {
  bool _ocupado = false;

  Coleta get _coleta => widget.coleta;

  Future<void> _executar(Future<void> Function() acao) async {
    if (_ocupado) return;

    setState(() => _ocupado = true);

    try {
      await acao();
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final coleta = _coleta;
    final contraparte = widget.parceiro
        ? '${coleta.geradorTipo}: ${coleta.geradorNome}'
        : 'Parceiro: ${coleta.parceiroNome}';
    final cancelada = coleta.status == StatusColeta.cancelada;

    return CartaoReciclagem(
      key: Key('coleta_${coleta.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  coleta.codigo,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              SeloDeStatus(
                coleta.status.label,
                cor: corDoStatusColeta(coleta.status),
              ),
            ],
          ),
          const SizedBox(height: 8),
          EtiquetasDeMateriais(coleta.materiais),
          const SizedBox(height: 10),
          Text(
            coleta.descricao,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          LinhaDeDetalhe('Quantidade', coleta.quantidadeEstimada),
          LinhaDeDetalhe('Retirada em', formatDateTime(coleta.dataAgendada)),
          LinhaDeDetalhe('Local', coleta.enderecoTexto),
          LinhaDeDetalhe('Contato', contraparte),
          if (coleta.observacoes != null)
            LinhaDeDetalhe('Observações', coleta.observacoes!),
          if (coleta.observacoesDaOferta != null)
            LinhaDeDetalhe('Acesso', coleta.observacoesDaOferta!),
          if (coleta.pesoRealKg != null)
            LinhaDeDetalhe('Peso coletado', formatKg(coleta.pesoRealKg!)),
          if (cancelada && coleta.cancelamentoMotivo != null)
            LinhaDeDetalhe('Motivo', coleta.cancelamentoMotivo!),
          if (!widget.parceiro &&
              coleta.podeCancelar &&
              coleta.cancelavelAte != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Você pode cancelar até ${formatDateTime(coleta.cancelavelAte)}.',
                style: const TextStyle(color: Colors.black54, fontSize: 12),
              ),
            ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (!cancelada)
                _Acao(
                  chave: 'documento_${coleta.id}',
                  icone: Icons.description_outlined,
                  texto: 'Termo (PDF)',
                  onPressed: _ocupado
                      ? null
                      : () => _executar(
                          () => baixarDocumentoDaColeta(
                            context,
                            ref,
                            coletaId: coleta.id,
                            codigo: coleta.codigo,
                          ),
                        ),
                ),
              _Acao(
                chave: 'conversa_${coleta.id}',
                icone: Icons.chat_bubble_outline,
                texto: 'Conversar',
                onPressed: _ocupado
                    ? null
                    : () => _executar(
                        () => abrirConversaDaColeta(context, ref, coleta.id),
                      ),
              ),
              if (widget.parceiro && coleta.podeConcluir)
                _Acao(
                  chave: 'concluir_${coleta.id}',
                  icone: Icons.task_alt,
                  texto: 'Concluir',
                  destaque: true,
                  onPressed: _ocupado
                      ? null
                      : () => _executar(
                          () => concluirColetaComPeso(
                            context,
                            ref,
                            coletaId: coleta.id,
                          ),
                        ),
                ),
              if (coleta.podeCancelar)
                _Acao(
                  chave: 'cancelar_${coleta.id}',
                  icone: Icons.cancel_outlined,
                  texto: 'Cancelar',
                  perigo: true,
                  onPressed: _ocupado
                      ? null
                      : () => _executar(
                          () => cancelarColetaComConfirmacao(
                            context,
                            ref,
                            coletaId: coleta.id,
                            geradorPodeEncerrar: !widget.parceiro,
                          ),
                        ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Acao extends StatelessWidget {
  const _Acao({
    required this.chave,
    required this.icone,
    required this.texto,
    required this.onPressed,
    this.destaque = false,
    this.perigo = false,
  });

  final String chave;
  final IconData icone;
  final String texto;
  final VoidCallback? onPressed;
  final bool destaque;
  final bool perigo;

  @override
  Widget build(BuildContext context) {
    final cor = perigo ? Colors.red.shade700 : const Color(0xFF2F8334);

    return destaque
        ? ElevatedButton.icon(
            key: Key(chave),
            onPressed: onPressed,
            icon: Icon(icone, size: 18),
            label: Text(texto),
            style: ElevatedButton.styleFrom(
              elevation: 0,
              minimumSize: const Size(48, 48),
              backgroundColor: cor,
              foregroundColor: Colors.white,
            ),
          )
        : OutlinedButton.icon(
            key: Key(chave),
            onPressed: onPressed,
            icon: Icon(icone, size: 18),
            label: Text(texto),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(48, 48),
              foregroundColor: cor,
              side: BorderSide(color: cor),
            ),
          );
  }
}
