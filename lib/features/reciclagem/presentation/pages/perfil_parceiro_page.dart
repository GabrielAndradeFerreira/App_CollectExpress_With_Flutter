import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/reciclagem.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_bottom_navigation.dart';
import '../../../../core/widgets/async_value_view.dart';
import '../../../admin/presentation/widgets/area_atendimento_card.dart';
import '../../../admin/presentation/widgets/assinatura_empresa_card.dart';
import '../../data/parceiro_repository.dart';
import '../reciclagem_providers.dart';
import '../widgets/reciclagem_widgets.dart';

/// Perfil do parceiro: dados da empresa, materiais que coleta, área de
/// atuação no mapa, assinatura e disponibilidade.
class PerfilParceiroPage extends ConsumerWidget {
  const PerfilParceiroPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final perfil = ref.watch(perfilParceiroProvider);

    return ReciclagemScaffold(
      aba: AbaReciclagem.perfil,
      child: RefreshIndicator(
        color: AppColors.green,
        onRefresh: () async {
          ref.invalidate(perfilParceiroProvider);
          await ref.read(perfilParceiroProvider.future);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 28),
          children: [
            const TituloDaTela(
              'Perfil da empresa',
              subtitulo: 'Seus dados e como você aparece para quem entrega.',
            ),
            const SizedBox(height: 16),
            perfil.when(
              loading: () => const LoadingView(),
              error: (error, _) => ErrorView(
                error: error,
                onRetry: () => ref.invalidate(perfilParceiroProvider),
              ),
              data: (dados) => _Dados(perfil: dados),
            ),
            const SizedBox(height: 14),
            const AreaAtendimentoCard(parceiro: true),
            const SizedBox(height: 14),
            const AssinaturaEmpresaCard(parceiro: true),
          ],
        ),
      ),
    );
  }
}

class _Dados extends ConsumerStatefulWidget {
  const _Dados({required this.perfil});

  final PerfilParceiro perfil;

  @override
  ConsumerState<_Dados> createState() => _DadosState();
}

class _DadosState extends ConsumerState<_Dados> {
  bool _salvando = false;

  PerfilParceiro get _perfil => widget.perfil;

  Future<void> _salvar({
    String? responsavelNome,
    String? enderecoColeta,
    double? capacidadeDiariaKg,
    bool? disponivel,
    List<String>? materiaisIds,
  }) async {
    setState(() => _salvando = true);

    try {
      await ref
          .read(parceiroRepositoryProvider)
          .atualizar(
            responsavelNome: responsavelNome,
            enderecoColeta: enderecoColeta,
            capacidadeDiariaKg: capacidadeDiariaKg,
            disponivel: disponivel,
            materiaisIds: materiaisIds,
          );

      ref.invalidate(perfilParceiroProvider);
      ref.invalidate(pendenciasParceiroProvider);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Perfil atualizado.'),
          backgroundColor: AppColors.green,
        ),
      );
    } on ApiException catch (erro) {
      if (mounted) showApiError(context, erro);
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  Future<void> _editarDados() async {
    final resposta = await showDialog<_DadosEditados>(
      context: context,
      builder: (_) => _EditarDadosDialog(perfil: _perfil),
    );

    if (resposta == null) return;

    await _salvar(
      responsavelNome: resposta.responsavel,
      enderecoColeta: resposta.endereco,
      capacidadeDiariaKg: resposta.capacidade,
    );
  }

  Future<void> _editarMateriais() async {
    final escolhidos = await showDialog<List<String>>(
      context: context,
      builder: (_) => _EscolherMateriaisDialog(
        selecionados: {for (final m in _perfil.materiais) m.id},
      ),
    );

    if (escolhidos != null) await _salvar(materiaisIds: escolhidos);
  }

  @override
  Widget build(BuildContext context) {
    final perfil = _perfil;

    return Column(
      children: [
        CartaoReciclagem(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      perfil.nome,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  if (perfil.status.isNotEmpty)
                    SeloDeStatus(
                      perfil.status == 'ATIVO' ? 'Aprovado' : perfil.status,
                      cor: perfil.status == 'ATIVO'
                          ? const Color(0xFF2F8334)
                          : const Color(0xFFB26A00),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              LinhaDeDetalhe('E-mail', perfil.email),
              LinhaDeDetalhe('Responsável', perfil.responsavelNome ?? '-'),
              LinhaDeDetalhe('Endereço', perfil.enderecoColeta ?? '-'),
              LinhaDeDetalhe(
                'Capacidade/dia',
                perfil.capacidadeDiariaKg == null
                    ? 'Não informada'
                    : formatKg(perfil.capacidadeDiariaKg!),
              ),
              const SizedBox(height: 6),
              OutlinedButton.icon(
                key: const Key('parceiro_editar_dados'),
                onPressed: _salvando ? null : _editarDados,
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('Editar dados'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(48, 48),
                  foregroundColor: const Color(0xFF2F8334),
                  side: const BorderSide(color: Color(0xFF2F8334)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        CartaoReciclagem(
          child: MergeSemantics(
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Recebendo novas coletas',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Desligue para pausar. Coletas já agendadas '
                        'continuam.',
                        style: TextStyle(color: Colors.black54, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Switch(
                  key: const Key('parceiro_disponivel'),
                  value: perfil.disponivel,
                  activeThumbColor: const Color(0xFF2F8334),
                  onChanged: _salvando
                      ? null
                      : (valor) => _salvar(disponivel: valor),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        CartaoReciclagem(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Materiais que você coleta',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              if (perfil.materiais.isEmpty)
                const Text(
                  'Nenhum material escolhido: você não vê sinalizações.',
                  style: TextStyle(color: Colors.red, fontSize: 13),
                )
              else
                EtiquetasDeMateriais([
                  for (final m in perfil.materiais) m.nome,
                ]),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                key: const Key('parceiro_editar_materiais'),
                onPressed: _salvando ? null : _editarMateriais,
                icon: const Icon(Icons.recycling, size: 18),
                label: const Text('Escolher materiais'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(48, 48),
                  foregroundColor: const Color(0xFF2F8334),
                  side: const BorderSide(color: Color(0xFF2F8334)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

typedef _DadosEditados = ({
  String responsavel,
  String endereco,
  double? capacidade,
});

class _EditarDadosDialog extends StatefulWidget {
  const _EditarDadosDialog({required this.perfil});

  final PerfilParceiro perfil;

  @override
  State<_EditarDadosDialog> createState() => _EditarDadosDialogState();
}

class _EditarDadosDialogState extends State<_EditarDadosDialog> {
  late final _responsavel = TextEditingController(
    text: widget.perfil.responsavelNome,
  );
  late final _endereco = TextEditingController(
    text: widget.perfil.enderecoColeta,
  );
  late final _capacidade = TextEditingController(
    text: widget.perfil.capacidadeDiariaKg == null
        ? ''
        : widget.perfil.capacidadeDiariaKg!
              .toStringAsFixed(
                widget.perfil.capacidadeDiariaKg! ==
                        widget.perfil.capacidadeDiariaKg!.roundToDouble()
                    ? 0
                    : 1,
              )
              .replaceAll('.', ','),
  );

  String? _erro;

  @override
  void dispose() {
    _responsavel.dispose();
    _endereco.dispose();
    _capacidade.dispose();
    super.dispose();
  }

  void _confirmar() {
    final responsavel = _responsavel.text.trim();
    final endereco = _endereco.text.trim();
    final textoCapacidade = _capacidade.text.trim();

    if (responsavel.length < 3) {
      setState(() => _erro = 'Informe o nome do responsável.');
      return;
    }

    if (endereco.length < 5) {
      setState(() => _erro = 'Informe o endereço da empresa.');
      return;
    }

    double? capacidade;

    if (textoCapacidade.isNotEmpty) {
      var normalizado = textoCapacidade;
      if (normalizado.contains(',')) {
        normalizado = normalizado.replaceAll('.', '').replaceAll(',', '.');
      }
      capacidade = double.tryParse(normalizado);

      if (capacidade == null || capacidade <= 0 || capacidade > 10000000) {
        setState(() => _erro = 'Informe uma capacidade válida em kg.');
        return;
      }
    }

    Navigator.of(context).pop((
      responsavel: responsavel,
      endereco: endereco,
      capacidade: capacidade,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Editar dados'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              key: const Key('editar_responsavel'),
              controller: _responsavel,
              decoration: const InputDecoration(
                labelText: 'Responsável',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('editar_endereco'),
              controller: _endereco,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Endereço da empresa',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('editar_capacidade'),
              controller: _capacidade,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Capacidade diária (opcional)',
                suffixText: 'kg',
                border: OutlineInputBorder(),
              ),
            ),
            if (_erro != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  _erro!,
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          key: const Key('editar_salvar'),
          onPressed: _confirmar,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.green,
            foregroundColor: Colors.white,
          ),
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}

class _EscolherMateriaisDialog extends ConsumerStatefulWidget {
  const _EscolherMateriaisDialog({required this.selecionados});

  final Set<String> selecionados;

  @override
  ConsumerState<_EscolherMateriaisDialog> createState() =>
      _EscolherMateriaisDialogState();
}

class _EscolherMateriaisDialogState
    extends ConsumerState<_EscolherMateriaisDialog> {
  late final Set<String> _escolhidos = {...widget.selecionados};

  @override
  Widget build(BuildContext context) {
    final catalogo = ref.watch(materiaisReciclaveisProvider);

    return AlertDialog(
      title: const Text('Materiais que você coleta'),
      content: SingleChildScrollView(
        child: catalogo.when(
          loading: () => const LoadingView(),
          error: (error, _) => ErrorView(
            error: error,
            onRetry: () => ref.invalidate(materiaisReciclaveisProvider),
          ),
          data: (materiais) => Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final material in materiais)
                FilterChip(
                  key: Key('perfil_material_${material.nome}'),
                  label: Text(material.nome),
                  selected: _escolhidos.contains(material.id),
                  selectedColor: const Color(0xFFD7EFD3),
                  checkmarkColor: const Color(0xFF2F8334),
                  onSelected: (marcado) {
                    setState(() {
                      if (marcado) {
                        _escolhidos.add(material.id);
                      } else {
                        _escolhidos.remove(material.id);
                      }
                    });
                  },
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          key: const Key('materiais_salvar'),
          onPressed: _escolhidos.isEmpty
              ? null
              : () => Navigator.of(context).pop(_escolhidos.toList()),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.green,
            foregroundColor: Colors.white,
          ),
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}
