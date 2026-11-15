import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/reciclagem.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_bottom_navigation.dart';
import '../../../../core/widgets/async_value_view.dart';
import '../../../admin/presentation/pages/area_atendimento_page.dart';
import '../../data/reciclagem_repository.dart';
import '../reciclagem_providers.dart';
import '../widgets/reciclagem_widgets.dart';
import 'agendar_coleta_page.dart';

/// Distâncias oferecidas no filtro, em km.
const _distancias = <double>[5, 10, 25, 50, 100];

/// Vitrine do parceiro: sinalizações de material dentro da área dele, com
/// filtro por tipo de material, distância e período.
class OfertasDisponiveisPage extends ConsumerStatefulWidget {
  const OfertasDisponiveisPage({super.key});

  @override
  ConsumerState<OfertasDisponiveisPage> createState() =>
      _OfertasDisponiveisPageState();
}

class _OfertasDisponiveisPageState
    extends ConsumerState<OfertasDisponiveisPage> {
  final Set<String> _materiais = {};
  double? _distancia;
  DateTimeRange? _periodo;
  int _paginas = 1;

  FiltroOfertas _filtro(int pagina) {
    final ids = _materiais.toList()..sort();

    return (
      materiais: ids.join(','),
      distanciaKm: _distancia,
      de: _periodo?.start,
      // Até o fim do último dia escolhido.
      ate: _periodo == null
          ? null
          : DateTime(
              _periodo!.end.year,
              _periodo!.end.month,
              _periodo!.end.day,
              23,
              59,
              59,
            ),
      pagina: pagina,
    );
  }

  void _mudouFiltro(VoidCallback alteracao) {
    setState(() {
      alteracao();
      _paginas = 1;
    });
  }

  Future<void> _escolherPeriodo() async {
    final hoje = DateTime.now();
    final escolhido = await showDateRangePicker(
      context: context,
      firstDate: hoje,
      lastDate: hoje.add(const Duration(days: 90)),
      initialDateRange: _periodo,
      helpText: 'Período da retirada',
      saveText: 'Aplicar',
    );

    if (escolhido != null && mounted) {
      _mudouFiltro(() => _periodo = escolhido);
    }
  }

  Future<void> _agendar(OfertaDisponivel oferta) async {
    final agendou = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => AgendarColetaPage(oferta: oferta),
      ),
    );

    if (agendou == true) {
      ref.invalidate(ofertasDisponiveisProvider);
      ref.invalidate(resumoColetasProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final catalogo = ref.watch(materiaisReciclaveisProvider).value ?? const [];
    final paginas = [
      for (var pagina = 1; pagina <= _paginas; pagina++)
        ref.watch(ofertasDisponiveisProvider(_filtro(pagina))),
    ];
    final primeira = paginas.first;
    final ofertas = [for (final p in paginas) ...?p.value?.pagina.itens];
    final carregandoMais = paginas.length > 1 && paginas.last.isLoading;
    final temProxima = paginas.last.value?.pagina.temProxima ?? false;
    final areaDefinida = primeira.value?.areaDefinida ?? true;

    return ReciclagemScaffold(
      aba: AbaReciclagem.sinalizacoes,
      child: RefreshIndicator(
        color: AppColors.green,
        onRefresh: () async {
          ref.invalidate(ofertasDisponiveisProvider);
          await ref.read(ofertasDisponiveisProvider(_filtro(1)).future);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 28),
          children: [
            const TituloDaTela(
              'Sinalizações',
              subtitulo:
                  'Material reciclável que clientes e fornecedores querem '
                  'descartar perto de você.',
            ),
            const SizedBox(height: 16),
            if (!areaDefinida) const _AvisoSemArea(),
            _Filtros(
              catalogo: catalogo,
              materiais: _materiais,
              distancia: _distancia,
              periodo: _periodo,
              onMaterial: (id, marcado) => _mudouFiltro(() {
                if (marcado) {
                  _materiais.add(id);
                } else {
                  _materiais.remove(id);
                }
              }),
              onDistancia: (valor) => _mudouFiltro(() => _distancia = valor),
              onPeriodo: _escolherPeriodo,
              onLimparPeriodo: () => _mudouFiltro(() => _periodo = null),
            ),
            const SizedBox(height: 16),
            if (primeira.hasError && !primeira.hasValue)
              ErrorView(
                error: primeira.error!,
                onRetry: () => ref.invalidate(ofertasDisponiveisProvider),
              )
            else if (primeira.isLoading && !primeira.hasValue)
              const LoadingView()
            else if (ofertas.isEmpty)
              const SizedBox(
                height: 240,
                child: EstadoVazio(
                  icone: Icons.inventory_2_outlined,
                  texto:
                      'Nenhuma sinalização encontrada com esses filtros. '
                      'Volte mais tarde ou amplie sua área e a distância.',
                ),
              )
            else ...[
              for (final oferta in ofertas)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _CartaoDaOferta(
                    oferta: oferta,
                    onAgendar: () => _agendar(oferta),
                  ),
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

class _AvisoSemArea extends StatelessWidget {
  const _AvisoSemArea();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: CartaoReciclagem(
        borda: AppColors.yellow,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Defina sua área de atuação para ver só o que está ao seu '
              'alcance. Enquanto isso, mostramos todas as sinalizações.',
              style: TextStyle(fontSize: 13),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const AreaAtendimentoPage(parceiro: true),
                ),
              ),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF2F8334),
                minimumSize: const Size(48, 48),
                padding: EdgeInsets.zero,
              ),
              child: const Text('Definir área de atuação'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Filtros extends StatelessWidget {
  const _Filtros({
    required this.catalogo,
    required this.materiais,
    required this.distancia,
    required this.periodo,
    required this.onMaterial,
    required this.onDistancia,
    required this.onPeriodo,
    required this.onLimparPeriodo,
  });

  final List<MaterialReciclavel> catalogo;
  final Set<String> materiais;
  final double? distancia;
  final DateTimeRange? periodo;
  final void Function(String id, bool marcado) onMaterial;
  final ValueChanged<double?> onDistancia;
  final VoidCallback onPeriodo;
  final VoidCallback onLimparPeriodo;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tipo de material',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            for (final material in catalogo)
              FilterChip(
                key: Key('filtro_material_${material.nome}'),
                label: Text(material.nome),
                selected: materiais.contains(material.id),
                selectedColor: const Color(0xFFD7EFD3),
                checkmarkColor: const Color(0xFF2F8334),
                onSelected: (marcado) => onMaterial(material.id, marcado),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: DropdownButtonFormField<double?>(
                key: const Key('filtro_distancia'),
                initialValue: distancia,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: 'Distância',
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(11),
                  ),
                ),
                items: [
                  const DropdownMenuItem<double?>(
                    value: null,
                    child: Text('Qualquer'),
                  ),
                  for (final km in _distancias)
                    DropdownMenuItem<double?>(
                      value: km,
                      child: Text('Até ${km.round()} km'),
                    ),
                ],
                onChanged: onDistancia,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: SizedBox(
                height: 48,
                child: OutlinedButton.icon(
                  key: const Key('filtro_periodo'),
                  onPressed: onPeriodo,
                  icon: const Icon(Icons.date_range, size: 18),
                  label: Text(
                    periodo == null
                        ? 'Período'
                        : '${formatDate(periodo!.start)} - '
                              '${formatDate(periodo!.end)}',
                    overflow: TextOverflow.ellipsis,
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black87,
                    side: const BorderSide(color: Colors.black38),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(11),
                    ),
                  ),
                ),
              ),
            ),
            if (periodo != null)
              IconButton(
                tooltip: 'Limpar período',
                onPressed: onLimparPeriodo,
                icon: const Icon(Icons.close),
              ),
          ],
        ),
      ],
    );
  }
}

class _CartaoDaOferta extends StatelessWidget {
  const _CartaoDaOferta({required this.oferta, required this.onAgendar});

  final OfertaDisponivel oferta;
  final VoidCallback onAgendar;

  @override
  Widget build(BuildContext context) {
    final distancia = oferta.distanciaKm;

    return CartaoReciclagem(
      key: Key('oferta_${oferta.id}'),
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
              SeloDeStatus(oferta.anuncianteTipo, cor: Colors.black54),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            oferta.descricao,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          LinhaDeDetalhe('Quantidade', oferta.quantidadeEstimada),
          LinhaDeDetalhe('Local', oferta.local),
          if (distancia != null)
            LinhaDeDetalhe('Distância', '${distancia.round()} km'),
          LinhaDeDetalhe(
            'Retirada entre',
            formatJanela(oferta.janelaInicio, oferta.janelaFim),
          ),
          LinhaDeDetalhe(
            'Primeiro horário',
            formatDateTime(oferta.primeiroHorario),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: BotaoPrincipal(
              texto: 'Agendar coleta',
              icone: Icons.event_available,
              onPressed: onAgendar,
            ),
          ),
        ],
      ),
    );
  }
}
