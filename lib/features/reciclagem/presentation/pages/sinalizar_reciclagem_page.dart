import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/endereco.dart';
import '../../../../core/models/reciclagem.dart';
import '../../../../core/navigation/app_routes.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/async_value_view.dart';
import '../../../../core/widgets/signature_pad_dialog.dart';
import '../../../admin/presentation/widgets/assinatura_empresa_card.dart';
import '../../../auth/data/sessao_provider.dart';
import '../../../pedidos/presentation/widgets/novo_endereco_sheet.dart';
import '../../../perfil/data/enderecos_repository.dart';
import '../../data/reciclagem_repository.dart';
import '../reciclagem_providers.dart';
import '../widgets/reciclagem_widgets.dart';

final _enderecosProvider = FutureProvider.autoDispose<List<Endereco>>((ref) {
  return ref.watch(enderecosRepositoryProvider).listar();
});

/// Formulário de sinalização de material reciclável. Serve a clientes e a
/// caçambeiros: o cliente assina na tela; o caçambeiro usa a assinatura
/// cadastrada da empresa.
class SinalizarReciclagemPage extends ConsumerStatefulWidget {
  const SinalizarReciclagemPage({super.key, this.agora});

  /// Só para os testes fixarem "agora".
  final DateTime? agora;

  @override
  ConsumerState<SinalizarReciclagemPage> createState() =>
      _SinalizarReciclagemPageState();
}

class _SinalizarReciclagemPageState
    extends ConsumerState<SinalizarReciclagemPage> {
  final _descricao = TextEditingController();
  final _quantidade = TextEditingController();
  final _observacoes = TextEditingController();

  final Set<String> _materiais = {};
  String? _enderecoId;
  DateTime? _inicio;
  DateTime? _fim;

  /// Cliente: PNG desenhado. Caçambeiro: fica nulo e vale o aceite.
  Uint8List? _assinatura;
  bool _aceitouCacambeiro = false;

  bool _enviando = false;
  bool _tentou = false;

  /// Erros de validação devolvidos pela API, por campo.
  Map<String, String> _errosApi = const {};

  DateTime get _agora => widget.agora ?? DateTime.now();

  bool get _cacambeiro => ref.read(sessaoProvider).value?.isCacambeiro ?? false;

  @override
  void dispose() {
    _descricao.dispose();
    _quantidade.dispose();
    _observacoes.dispose();
    super.dispose();
  }

  Future<DateTime?> _escolherDataHora(DateTime? atual, String ajuda) async {
    final agora = _agora;
    final dia = await showDatePicker(
      context: context,
      initialDate: atual ?? agora.add(const Duration(days: 2)),
      firstDate: DateTime(agora.year, agora.month, agora.day),
      lastDate: agora.add(const Duration(days: 60)),
      helpText: ajuda,
    );

    if (dia == null || !mounted) return null;

    final hora = await showTimePicker(
      context: context,
      initialTime: atual == null
          ? const TimeOfDay(hour: 8, minute: 0)
          : TimeOfDay.fromDateTime(atual),
      helpText: ajuda,
    );

    if (hora == null) return null;

    return DateTime(dia.year, dia.month, dia.day, hora.hour, hora.minute);
  }

  Future<void> _escolherInicio() async {
    final data = await _escolherDataHora(_inicio, 'A partir de quando');

    if (data == null) return;

    setState(() {
      _inicio = data;
      // Sugere uma janela de 4 horas para facilitar.
      if (_fim == null || !_fim!.isAfter(data)) {
        _fim = data.add(const Duration(hours: 4));
      }
    });
  }

  Future<void> _escolherFim() async {
    final data = await _escolherDataHora(_fim ?? _inicio, 'Até quando');

    if (data != null) setState(() => _fim = data);
  }

  String? get _erroDaJanela {
    final inicio = _inicio;
    final fim = _fim;

    if (inicio == null || fim == null) {
      return 'Informe a janela em que a retirada pode acontecer.';
    }

    if (fim.difference(inicio) < const Duration(hours: 2)) {
      return 'A janela precisa ter pelo menos 2 horas.';
    }

    if (fim.isBefore(_agora.add(const Duration(hours: 25)))) {
      return 'A janela precisa terminar daqui a mais de 25 horas: o '
          'parceiro só pode retirar 24 horas depois de agendar, para você '
          'ter tempo de desistir.';
    }

    if (fim.isAfter(_agora.add(const Duration(days: 60)))) {
      return 'A janela não pode passar de 60 dias.';
    }

    return null;
  }

  Future<void> _novoEndereco() async {
    final endereco = await mostrarNovoEnderecoSheet(context);

    if (endereco == null || !mounted) return;

    setState(() => _enderecoId = endereco.id);
    ref.invalidate(_enderecosProvider);
  }

  Future<void> _assinar({bool refazer = false}) async {
    if (_assinatura != null && !refazer) {
      setState(() => _assinatura = null);
      return;
    }

    final desenho = await mostrarAssinatura(
      context,
      titulo: 'Assine o termo de coleta',
      instrucao:
          'Ao assinar, você concorda que o termo de coleta seja assinado '
          'automaticamente por você quando um parceiro agendar a retirada. '
          'Você pode cancelar em até 24 horas.',
    );

    if (desenho != null) setState(() => _assinatura = desenho);
  }

  String? _erroDoFormulario({required bool assinaturaCadastrada}) {
    if (_materiais.isEmpty) return 'Escolha ao menos um tipo de material.';
    if (_descricao.text.trim().length < 5) {
      return 'Descreva o material (pelo menos 5 letras).';
    }
    if (_quantidade.text.trim().isEmpty) {
      return 'Informe a quantidade estimada.';
    }
    if (_enderecoId == null) return 'Escolha onde o material será retirado.';

    final janela = _erroDaJanela;
    if (janela != null) return janela;

    if (_cacambeiro) {
      if (!assinaturaCadastrada) {
        return 'Envie a assinatura da empresa no perfil da loja antes de '
            'sinalizar.';
      }
      if (!_aceitouCacambeiro) return 'Aceite o termo para continuar.';
    } else if (_assinatura == null) {
      return 'Marque o aceite e assine para continuar.';
    }

    return null;
  }

  Future<void> _enviar({required bool assinaturaCadastrada}) async {
    FocusScope.of(context).unfocus();

    setState(() {
      _tentou = true;
      _errosApi = const {};
    });

    if (_erroDoFormulario(assinaturaCadastrada: assinaturaCadastrada) != null) {
      return;
    }

    setState(() => _enviando = true);

    try {
      await ref
          .read(reciclagemRepositoryProvider)
          .criarOferta(
            materiaisIds: _materiais.toList(),
            descricao: _descricao.text,
            quantidadeEstimada: _quantidade.text,
            enderecoId: _enderecoId!,
            janelaInicio: _inicio!,
            janelaFim: _fim!,
            observacoes: _observacoes.text,
            assinaturaBase64: _assinatura == null
                ? null
                : 'data:image/png;base64,${base64Encode(_assinatura!)}',
          );

      if (!mounted) return;

      ref.invalidate(minhasOfertasProvider);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Material sinalizado! Avisaremos por e-mail quando um parceiro '
            'agendar a retirada.',
          ),
          backgroundColor: AppColors.green,
        ),
      );
      Navigator.of(context).pop(true);
    } on ApiException catch (erro) {
      if (!mounted) return;
      setState(() => _errosApi = erro.fields);
      showApiError(context, erro);
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cacambeiro = _cacambeiro;
    final catalogo = ref.watch(materiaisReciclaveisProvider);
    final enderecos = ref.watch(_enderecosProvider);
    final assinaturaDaEmpresa = cacambeiro
        ? ref.watch(assinaturaEmpresaProvider)
        : null;
    final assinaturaCadastrada = assinaturaDaEmpresa?.value != null;
    final erro = _tentou
        ? _erroDoFormulario(assinaturaCadastrada: assinaturaCadastrada)
        : null;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Sinalizar material',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 32),
          children: [
            const Text(
              'Conte o que você tem para descartar. Parceiros de reciclagem '
              'perto de você veem a sinalização e agendam a retirada.',
              style: TextStyle(color: Colors.black54, fontSize: 13),
            ),
            const SizedBox(height: 18),
            const _Secao('Tipo de material'),
            catalogo.when(
              loading: () => const LoadingView(),
              error: (error, _) => ErrorView(
                error: error,
                onRetry: () => ref.invalidate(materiaisReciclaveisProvider),
              ),
              data: _materiaisChips,
            ),
            if (_errosApi['materiais_ids'] != null)
              _TextoDeErro(_errosApi['materiais_ids']!),
            const SizedBox(height: 18),
            TextField(
              key: const Key('sinalizar_descricao'),
              controller: _descricao,
              maxLines: 3,
              maxLength: 1000,
              textCapitalization: TextCapitalization.sentences,
              decoration: _decoracao(
                'Descrição do material',
                'Ex.: garrafas PET limpas, em sacos de 100 litros',
                _errosApi['descricao'],
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              key: const Key('sinalizar_quantidade'),
              controller: _quantidade,
              maxLength: 100,
              decoration: _decoracao(
                'Quantidade estimada',
                'Ex.: 30 kg, ou 10 sacos grandes',
                _errosApi['quantidade_estimada'],
              ),
            ),
            const SizedBox(height: 8),
            const _Secao('Onde retirar'),
            enderecos.when(
              loading: () => const LoadingView(),
              error: (error, _) => ErrorView(
                error: error,
                onRetry: () => ref.invalidate(_enderecosProvider),
              ),
              data: _enderecosLista,
            ),
            const SizedBox(height: 18),
            const _Secao('Quando pode ser retirado'),
            const Text(
              'Informe o período em que você pode receber a retirada. O '
              'parceiro escolhe um horário dentro dele, com pelo menos 24 '
              'horas de antecedência.',
              style: TextStyle(color: Colors.black54, fontSize: 12),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _SeletorDeData(
                    chave: 'sinalizar_inicio',
                    rotulo: 'A partir de',
                    valor: _inicio,
                    onTap: _escolherInicio,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _SeletorDeData(
                    chave: 'sinalizar_fim',
                    rotulo: 'Até',
                    valor: _fim,
                    onTap: _escolherFim,
                  ),
                ),
              ],
            ),
            if (_errosApi['janela_fim'] != null)
              _TextoDeErro(_errosApi['janela_fim']!),
            const SizedBox(height: 18),
            TextField(
              key: const Key('sinalizar_observacoes'),
              controller: _observacoes,
              maxLines: 2,
              maxLength: 500,
              decoration: _decoracao(
                'Observações (opcional)',
                'Ponto de referência, como chegar, horário do portão...',
                _errosApi['observacoes'],
              ),
            ),
            const SizedBox(height: 8),
            _AceiteDoTermo(
              cacambeiro: cacambeiro,
              assinatura: _assinatura,
              assinaturaDaEmpresa: assinaturaDaEmpresa?.value,
              carregandoAssinatura: assinaturaDaEmpresa?.isLoading ?? false,
              aceitou: _aceitouCacambeiro,
              onAceite: (valor) => setState(() => _aceitouCacambeiro = valor),
              onAssinar: _assinar,
              onRefazer: () => _assinar(refazer: true),
            ),
            if (erro != null) ...[
              const SizedBox(height: 12),
              Text(
                erro,
                key: const Key('sinalizar_erro'),
                style: const TextStyle(color: Colors.red, fontSize: 13),
              ),
            ],
            const SizedBox(height: 18),
            BotaoPrincipal(
              key: const Key('sinalizar_enviar'),
              texto: 'Sinalizar material',
              icone: Icons.recycling,
              carregando: _enviando,
              onPressed: () =>
                  _enviar(assinaturaCadastrada: assinaturaCadastrada),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _decoracao(String rotulo, String dica, String? erro) {
    return InputDecoration(
      labelText: rotulo,
      hintText: dica,
      errorText: erro,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(11)),
    );
  }

  Widget _materiaisChips(List<MaterialReciclavel> materiais) {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        for (final material in materiais)
          FilterChip(
            key: Key('sinalizar_material_${material.nome}'),
            label: Text(material.nome),
            selected: _materiais.contains(material.id),
            selectedColor: const Color(0xFFD7EFD3),
            checkmarkColor: const Color(0xFF2F8334),
            onSelected: (marcado) {
              setState(() {
                if (marcado) {
                  _materiais.add(material.id);
                } else {
                  _materiais.remove(material.id);
                }
              });
            },
          ),
      ],
    );
  }

  Widget _enderecosLista(List<Endereco> enderecos) {
    // Mantém a escolha se ela ainda existe; sem escolha, usa o único.
    if (_enderecoId != null && !enderecos.any((e) => e.id == _enderecoId)) {
      _enderecoId = null;
    }
    if (_enderecoId == null && enderecos.length == 1) {
      _enderecoId = enderecos.first.id;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RadioGroup<String>(
          groupValue: _enderecoId,
          onChanged: (valor) => setState(() => _enderecoId = valor),
          child: Column(
            children: [
              for (final endereco in enderecos)
                RadioListTile<String>(
                  key: Key('sinalizar_endereco_${endereco.id}'),
                  value: endereco.id,
                  contentPadding: EdgeInsets.zero,
                  activeColor: AppColors.green,
                  title: Text(
                    '${endereco.logradouro}, ${endereco.numero}',
                    style: const TextStyle(fontSize: 14),
                  ),
                  subtitle: Text(
                    [
                      if (endereco.bairro.isNotEmpty) endereco.bairro,
                      endereco.cidadeEstado,
                      formatCep(endereco.cep),
                    ].join(' · '),
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
            ],
          ),
        ),
        TextButton.icon(
          key: const Key('sinalizar_novo_endereco'),
          onPressed: _novoEndereco,
          icon: const Icon(Icons.add_location_alt_outlined),
          label: const Text('Usar outro endereço'),
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF2F8334),
            minimumSize: const Size(48, 48),
          ),
        ),
        const Text(
          'O endereço completo só aparece para o parceiro depois que ele '
          'agenda a retirada.',
          style: TextStyle(color: Colors.black54, fontSize: 12),
        ),
      ],
    );
  }
}

class _Secao extends StatelessWidget {
  const _Secao(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Semantics(
        header: true,
        child: Text(
          texto,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}

class _TextoDeErro extends StatelessWidget {
  const _TextoDeErro(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Text(
        texto,
        style: const TextStyle(color: Colors.red, fontSize: 12),
      ),
    );
  }
}

class _SeletorDeData extends StatelessWidget {
  const _SeletorDeData({
    required this.chave,
    required this.rotulo,
    required this.valor,
    required this.onTap,
  });

  final String chave;
  final String rotulo;
  final DateTime? valor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      key: Key(chave),
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.black87,
        minimumSize: const Size(48, 60),
        side: const BorderSide(color: Colors.black38),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            rotulo,
            style: const TextStyle(fontSize: 11, color: Colors.black54),
          ),
          const SizedBox(height: 2),
          Text(
            valor == null ? 'Escolher' : formatDateTime(valor),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

/// Aceite do termo. O cliente marca e assina na tela; o caçambeiro marca e
/// vale a assinatura cadastrada da empresa.
class _AceiteDoTermo extends StatelessWidget {
  const _AceiteDoTermo({
    required this.cacambeiro,
    required this.assinatura,
    required this.assinaturaDaEmpresa,
    required this.carregandoAssinatura,
    required this.aceitou,
    required this.onAceite,
    required this.onAssinar,
    required this.onRefazer,
  });

  final bool cacambeiro;
  final Uint8List? assinatura;
  final Uint8List? assinaturaDaEmpresa;
  final bool carregandoAssinatura;
  final bool aceitou;
  final ValueChanged<bool> onAceite;
  final VoidCallback onAssinar;
  final VoidCallback onRefazer;

  @override
  Widget build(BuildContext context) {
    final marcado = cacambeiro ? aceitou : assinatura != null;
    final previa = cacambeiro ? assinaturaDaEmpresa : assinatura;
    final semAssinaturaCadastrada =
        cacambeiro && !carregandoAssinatura && assinaturaDaEmpresa == null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(8, 8, 14, 12),
      decoration: BoxDecoration(
        color: AppColors.lightGray,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: marcado ? AppColors.green : AppColors.border,
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
                key: const Key('sinalizar_aceite'),
                value: marcado,
                activeColor: AppColors.green,
                onChanged: semAssinaturaCadastrada
                    ? null
                    : (valor) =>
                          cacambeiro ? onAceite(valor ?? false) : onAssinar(),
              ),
              const Expanded(
                child: Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: Text(
                    'Concordo que o termo de coleta seja assinado '
                    'automaticamente por mim quando um parceiro agendar a '
                    'retirada, e sei que posso cancelar em até 24 horas '
                    'depois do agendamento.',
                    style: TextStyle(fontSize: 13, height: 1.4),
                  ),
                ),
              ),
            ],
          ),
          if (semAssinaturaCadastrada) ...[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Text(
                    'Você ainda não enviou a assinatura da empresa.',
                    style: TextStyle(color: Colors.red, fontSize: 12),
                  ),
                  TextButton(
                    onPressed: () =>
                        Navigator.of(context)
                            .pushNamed(AppRoutes.supplierProfile),
                    child: const Text('Enviar agora'),
                  ),
                ],
              ),
            ),
          ] else if (previa != null && marcado) ...[
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
                      previa,
                      key: const Key('sinalizar_assinatura_previa'),
                      fit: BoxFit.contain,
                    ),
                  ),
                  if (!cacambeiro) ...[
                    const SizedBox(width: 10),
                    TextButton(
                      key: const Key('sinalizar_refazer'),
                      onPressed: onRefazer,
                      child: const Text('Refazer'),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
