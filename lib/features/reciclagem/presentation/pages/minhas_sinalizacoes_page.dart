import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/reciclagem.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_bottom_navigation.dart';
import '../../../../core/widgets/async_value_view.dart';
import '../../../chat/presentation/pages/chat_page.dart';
import '../../data/reciclagem_repository.dart';
import '../coleta_acoes.dart';
import '../reciclagem_providers.dart';
import '../widgets/reciclagem_widgets.dart';
import 'sinalizar_reciclagem_page.dart';

/// Sinalizações de quem entrega o material (cliente ou caçambeiro), com a
/// coleta agendada, quando houver.
class MinhasSinalizacoesPage extends ConsumerWidget {
  const MinhasSinalizacoesPage({super.key});

  Future<void> _sinalizar(BuildContext context, WidgetRef ref) async {
    final criou = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(builder: (_) => const SinalizarReciclagemPage()),
    );

    if (criou == true) ref.invalidate(minhasOfertasProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ofertas = ref.watch(minhasOfertasProvider);

    return ReciclagemScaffold(
      aba: AbaReciclagem.sinalizacoes,
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('nova_sinalizacao'),
        onPressed: () => _sinalizar(context, ref),
        backgroundColor: AppColors.green,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text(
          'Sinalizar material',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      child: RefreshIndicator(
        color: AppColors.green,
        onRefresh: () async {
          ref.invalidate(minhasOfertasProvider);
          await ref.read(minhasOfertasProvider.future);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 96),
          children: [
            const TituloDaTela(
              'Minhas sinalizações',
              subtitulo:
                  'Material reciclável que você quer descartar e as '
                  'retiradas agendadas.',
            ),
            const SizedBox(height: 16),
            ofertas.when(
              loading: () => const LoadingView(),
              error: (error, _) => ErrorView(
                error: error,
                onRetry: () => ref.invalidate(minhasOfertasProvider),
              ),
              data: (lista) {
                if (lista.isEmpty) {
                  return const SizedBox(
                    height: 280,
                    child: EstadoVazio(
                      icone: Icons.recycling,
                      texto:
                          'Você ainda não sinalizou nenhum material. Toque '
                          'em "Sinalizar material" para um parceiro de '
                          'reciclagem agendar a retirada.',
                    ),
                  );
                }

                return Column(
                  children: [
                    for (final oferta in lista)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _CartaoDaSinalizacao(oferta: oferta),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _CartaoDaSinalizacao extends ConsumerStatefulWidget {
  const _CartaoDaSinalizacao({required this.oferta});

  final OfertaColeta oferta;

  @override
  ConsumerState<_CartaoDaSinalizacao> createState() =>
      _CartaoDaSinalizacaoState();
}

class _CartaoDaSinalizacaoState extends ConsumerState<_CartaoDaSinalizacao> {
  bool _ocupado = false;

  OfertaColeta get _oferta => widget.oferta;

  Future<void> _executar(Future<void> Function() acao) async {
    if (_ocupado) return;

    setState(() => _ocupado = true);

    try {
      await acao();
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  Future<void> _cancelarSinalizacao() async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar sinalização?'),
        content: const Text(
          'Ela deixa de aparecer para os parceiros de reciclagem.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Voltar'),
          ),
          ElevatedButton(
            key: const Key('cancelar_sinalizacao_confirmar'),
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Cancelar sinalização'),
          ),
        ],
      ),
    );

    if (confirmou != true || !mounted) return;

    try {
      await ref.read(reciclagemRepositoryProvider).cancelarOferta(_oferta.id);
      ref.invalidate(minhasOfertasProvider);
      ref.invalidate(resumoColetasProvider);
    } on ApiException catch (erro) {
      if (mounted) showApiError(context, erro);
    }
  }

  @override
  Widget build(BuildContext context) {
    final oferta = _oferta;
    final coleta = oferta.coleta;

    return CartaoReciclagem(
      key: Key('sinalizacao_${oferta.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: EtiquetasDeMateriais([
                  for (final material in oferta.materiais) material.nome,
                ]),
              ),
              const SizedBox(width: 8),
              SeloDeStatus(
                oferta.status.label,
                cor: corDoStatusOferta(oferta.status),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            oferta.descricao,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          LinhaDeDetalhe('Quantidade', oferta.quantidadeEstimada),
          LinhaDeDetalhe('Local', oferta.enderecoTexto),
          LinhaDeDetalhe(
            'Retirada entre',
            formatJanela(oferta.janelaInicio, oferta.janelaFim),
          ),
          if (oferta.observacoes != null)
            LinhaDeDetalhe('Observações', oferta.observacoes!),
          if (coleta != null) ...[
            const Divider(height: 24),
            _BlocoDaColeta(coleta: coleta),
          ],
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (coleta != null && coleta.status != StatusColeta.cancelada)
                OutlinedButton.icon(
                  key: Key('sinalizacao_termo_${oferta.id}'),
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
                  icon: const Icon(Icons.description_outlined, size: 18),
                  label: const Text('Termo (PDF)'),
                  style: _estiloVerde(),
                ),
              if (coleta != null && coleta.status != StatusColeta.cancelada)
                OutlinedButton.icon(
                  key: Key('sinalizacao_conversa_${oferta.id}'),
                  onPressed: _ocupado
                      ? null
                      : () => _executar(
                          () => abrirConversaDaColeta(context, ref, coleta.id),
                        ),
                  icon: const Icon(Icons.chat_bubble_outline, size: 18),
                  label: const Text('Conversar'),
                  style: _estiloVerde(),
                ),
              if (coleta != null &&
                  coleta.status == StatusColeta.agendada &&
                  coleta.podeCancelar)
                OutlinedButton.icon(
                  key: Key('sinalizacao_cancelar_coleta_${oferta.id}'),
                  onPressed: _ocupado
                      ? null
                      : () => _executar(
                          () => cancelarColetaComConfirmacao(
                            context,
                            ref,
                            coletaId: coleta.id,
                            geradorPodeEncerrar: true,
                          ),
                        ),
                  icon: const Icon(Icons.cancel_outlined, size: 18),
                  label: const Text('Cancelar coleta'),
                  style: _estiloVermelho(),
                ),
              if (oferta.status == StatusOferta.aberta)
                OutlinedButton.icon(
                  key: Key('sinalizacao_cancelar_${oferta.id}'),
                  onPressed: _ocupado
                      ? null
                      : () => _executar(_cancelarSinalizacao),
                  icon: const Icon(Icons.close, size: 18),
                  label: const Text('Cancelar sinalização'),
                  style: _estiloVermelho(),
                ),
            ],
          ),
        ],
      ),
    );
  }

  ButtonStyle _estiloVerde() {
    return OutlinedButton.styleFrom(
      minimumSize: const Size(48, 48),
      foregroundColor: const Color(0xFF2F8334),
      side: const BorderSide(color: Color(0xFF2F8334)),
    );
  }

  ButtonStyle _estiloVermelho() {
    return OutlinedButton.styleFrom(
      minimumSize: const Size(48, 48),
      foregroundColor: Colors.red.shade700,
      side: BorderSide(color: Colors.red.shade700),
    );
  }
}

class _BlocoDaColeta extends StatelessWidget {
  const _BlocoDaColeta({required this.coleta});

  final ColetaDaOferta coleta;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Coleta agendada',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
              ),
            ),
            SeloDeStatus(
              coleta.status.label,
              cor: corDoStatusColeta(coleta.status),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinhaDeDetalhe('Código', coleta.codigo),
        LinhaDeDetalhe('Parceiro', coleta.parceiroNome),
        LinhaDeDetalhe('Retirada em', formatDateTime(coleta.dataAgendada)),
        if (coleta.status == StatusColeta.agendada &&
            coleta.podeCancelar &&
            coleta.cancelavelAte != null)
          Text(
            'Você pode cancelar até ${formatDateTime(coleta.cancelavelAte)}.',
            style: const TextStyle(color: Colors.black54, fontSize: 12),
          ),
      ],
    );
  }
}
