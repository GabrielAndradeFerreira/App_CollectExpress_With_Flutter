import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/usuario.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_bottom_navigation.dart';
import '../../../../core/widgets/app_logo.dart';
import '../../../../core/widgets/app_menu_drawer.dart';
import '../../../../core/widgets/async_value_view.dart';
import '../../../auth/data/auth_repository.dart';
import '../../../auth/data/sessao_provider.dart';
import '../../data/fornecedor_repository.dart';
import '../fornecedor_providers.dart';
import '../widgets/area_atendimento_card.dart';
import '../widgets/assinatura_empresa_card.dart';

/// Perfil da loja do fornecedor, com os dados reais da conta: nome,
/// telefone, horário de funcionamento e taxa de entrega.
///
/// CNPJ e e-mail aparecem só para conferência (a API não deixa trocar).
class PerfilLojaPage extends ConsumerStatefulWidget {
  const PerfilLojaPage({super.key});

  @override
  ConsumerState<PerfilLojaPage> createState() => _PerfilLojaPageState();
}

class _PerfilLojaPageState extends ConsumerState<PerfilLojaPage> {
  final _formKey = GlobalKey<FormState>();

  final _nomeController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _taxaController = TextEditingController();

  String _horarioInicio = '';
  String _horarioFim = '';

  /// Conta que preencheu o formulário pela última vez. Quando o servidor
  /// devolve dados novos (depois de salvar ou de puxar para atualizar), o
  /// formulário é preenchido de novo.
  Usuario? _preenchidoCom;

  bool _salvando = false;

  /// Erros de validação devolvidos pela API, por campo.
  Map<String, String> _errosApi = const {};

  @override
  void dispose() {
    _nomeController.dispose();
    _telefoneController.dispose();
    _taxaController.dispose();
    super.dispose();
  }

  void _preencher(Usuario usuario) {
    if (identical(_preenchidoCom, usuario)) return;

    _preenchidoCom = usuario;

    final detalhes = usuario.detalhesCacambeiro;

    _nomeController.text = usuario.nomeCompleto;
    _telefoneController.text = (usuario.telefone ?? '').replaceAll(
      RegExp(r'\D'),
      '',
    );
    _horarioInicio = formatHour(detalhes?.horarioInicio);
    _horarioFim = formatHour(detalhes?.horarioFim);
    _taxaController.text = detalhes == null
        ? ''
        : detalhes.taxaEntrega.toStringAsFixed(2).replaceAll('.', ',');
  }

  /// `12345678000190` → `**.***.678/0001-90`, como a API mostra.
  String _documentoMascarado(String? documento) {
    final digitos = (documento ?? '').replaceAll(RegExp(r'\D'), '');

    if (digitos.length == 14) {
      return '**.***.${digitos.substring(5, 8)}/'
          '${digitos.substring(8, 12)}-${digitos.substring(12)}';
    }

    return documento == null || documento.isEmpty ? '-' : documento;
  }

  /// Aceita "1.234,56", "1234,56" e "1234.56".
  double? _lerDecimal(String valor) {
    var texto = valor.trim();
    if (texto.contains(',')) {
      texto = texto.replaceAll('.', '').replaceAll(',', '.');
    }

    return double.tryParse(texto);
  }

  int? _minutos(String horario) {
    final partes = RegExp(r'^(\d{2}):(\d{2})$').firstMatch(horario);
    if (partes == null) return null;

    return int.parse(partes.group(1)!) * 60 + int.parse(partes.group(2)!);
  }

  Future<void> _escolherHorario({required bool abertura}) async {
    final atual = _minutos(abertura ? _horarioInicio : _horarioFim);
    final escolhido = await showTimePicker(
      context: context,
      initialTime: atual == null
          ? TimeOfDay(hour: abertura ? 8 : 18, minute: 0)
          : TimeOfDay(hour: atual ~/ 60, minute: atual % 60),
    );

    if (escolhido == null || !mounted) return;

    final texto =
        '${escolhido.hour.toString().padLeft(2, '0')}:'
        '${escolhido.minute.toString().padLeft(2, '0')}';

    setState(() {
      if (abertura) {
        _horarioInicio = texto;
      } else {
        _horarioFim = texto;
      }
    });
  }

  String? _erroDoHorario() {
    final inicio = _minutos(_horarioInicio);
    final fim = _minutos(_horarioFim);

    if (inicio == null || fim == null) return 'Escolha os dois horários.';
    if (fim <= inicio) return 'O fechamento deve ser depois da abertura.';

    return null;
  }

  Future<void> _salvar(Usuario atual) async {
    FocusScope.of(context).unfocus();
    setState(() => _errosApi = const {});

    final horarioInvalido = _erroDoHorario() != null;

    if (!_formKey.currentState!.validate() || horarioInvalido) {
      setState(() {});
      return;
    }

    final detalhes = atual.detalhesCacambeiro;
    final nome = _nomeController.text.trim();
    final telefone = _telefoneController.text.replaceAll(RegExp(r'\D'), '');
    final taxa = _lerDecimal(_taxaController.text)!;

    final mudouConta =
        nome != atual.nomeCompleto ||
        telefone != (atual.telefone ?? '').replaceAll(RegExp(r'\D'), '');
    final mudouLoja =
        _horarioInicio != formatHour(detalhes?.horarioInicio) ||
        _horarioFim != formatHour(detalhes?.horarioFim) ||
        taxa != detalhes?.taxaEntrega;

    if (!mudouConta && !mudouLoja) {
      _aviso('Nenhuma alteração para salvar.');
      return;
    }

    setState(() => _salvando = true);

    try {
      if (mudouConta) {
        await ref
            .read(authRepositoryProvider)
            .atualizarPerfil(nomeCompleto: nome, telefone: telefone);
      }

      if (mudouLoja) {
        await ref
            .read(fornecedorRepositoryProvider)
            .atualizarLoja(
              horarioInicio: _horarioInicio,
              horarioFim: _horarioFim,
              taxaEntrega: taxa,
            );
      }

      // Lê de novo do servidor: a tela passa a mostrar o que ficou salvo
      // e o nome no menu e nas outras telas acompanha.
      final salvo = await ref.read(authRepositoryProvider).perfil();

      if (!mounted) return;

      ref.read(sessaoProvider.notifier).atualizarUsuario(salvo);
      ref.invalidate(perfilFornecedorProvider);
      ref.invalidate(fornecedorDashboardProvider);

      _aviso('Dados da loja atualizados com sucesso!', sucesso: true);
    } on ApiException catch (erro) {
      if (!mounted) return;

      setState(() => _errosApi = erro.fields);
      _formKey.currentState?.validate();
      showApiError(context, erro, acao: 'salvar perfil da loja');
    } catch (erro) {
      if (!mounted) return;

      showApiError(context, erro, acao: 'salvar perfil da loja');
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  void _aviso(String texto, {bool sucesso = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(texto),
        backgroundColor: sucesso ? AppColors.green : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final perfil = ref.watch(perfilFornecedorProvider);

    return Scaffold(
      endDrawer: const AppMenuDrawer(),
      drawerScrimColor: const Color(0xD9000000),
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: AppColors.green,
          onRefresh: () async {
            ref.invalidate(perfilFornecedorProvider);
            await ref.read(perfilFornecedorProvider.future);
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              const SliverToBoxAdapter(child: _AdminHeader()),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 30, 18, 80),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Semantics(
                        header: true,
                        child: const Text(
                          'Perfil da Minha Loja',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Os dados que seus clientes veem no catálogo e no pedido',
                        style: TextStyle(color: Colors.black54, fontSize: 13),
                      ),
                      const SizedBox(height: 28),
                      perfil.when(
                        loading: () => const LoadingView(),
                        error: (erro, _) => ErrorView(
                          error: erro,
                          onRetry: () =>
                              ref.invalidate(perfilFornecedorProvider),
                        ),
                        data: (usuario) {
                          _preencher(usuario);
                          return _formulario(usuario);
                        },
                      ),
                      const SizedBox(height: 28),
                      const AreaAtendimentoCard(),
                      const SizedBox(height: 16),
                      const AssinaturaEmpresaCard(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const SupplierBottomNavigation(currentIndex: 3),
    );
  }

  Widget _formulario(Usuario usuario) {
    final erroDoHorario = _erroDoHorario();

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Rotulo('Nome da empresa'),
          const SizedBox(height: 8),
          TextFormField(
            key: const Key('loja_nome'),
            controller: _nomeController,
            textCapitalization: TextCapitalization.words,
            decoration: _decoracao(),
            validator: (valor) =>
                _errosApi['nome_completo'] ?? _validarNome(valor),
          ),
          const SizedBox(height: 20),
          const _Rotulo('CNPJ'),
          const SizedBox(height: 8),
          TextFormField(
            key: const Key('loja_cnpj'),
            initialValue: _documentoMascarado(usuario.documento),
            readOnly: true,
            decoration: _decoracao(preenchimento: AppColors.lightGray),
          ),
          const SizedBox(height: 20),
          const _Rotulo('E-mail de acesso'),
          const SizedBox(height: 8),
          TextFormField(
            key: const Key('loja_email'),
            initialValue: usuario.email,
            readOnly: true,
            decoration: _decoracao(preenchimento: AppColors.lightGray),
          ),
          const SizedBox(height: 20),
          const _Rotulo('Telefone'),
          const SizedBox(height: 8),
          TextFormField(
            key: const Key('loja_telefone'),
            controller: _telefoneController,
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(11),
            ],
            decoration: _decoracao(dica: '11999999999'),
            validator: (valor) =>
                _errosApi['telefone'] ?? _validarTelefone(valor),
          ),
          const SizedBox(height: 20),
          const _Rotulo('Horário de funcionamento'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _SeletorDeHorario(
                  chave: 'loja_abre',
                  rotulo: 'Abre às',
                  valor: _horarioInicio,
                  onTap: _salvando
                      ? null
                      : () => _escolherHorario(abertura: true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SeletorDeHorario(
                  chave: 'loja_fecha',
                  rotulo: 'Fecha às',
                  valor: _horarioFim,
                  onTap: _salvando
                      ? null
                      : () => _escolherHorario(abertura: false),
                ),
              ),
            ],
          ),
          if (erroDoHorario != null || _errosApi['horario_fim'] != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                _errosApi['horario_fim'] ?? erroDoHorario!,
                key: const Key('loja_erro_horario'),
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ),
          const SizedBox(height: 20),
          const _Rotulo('Taxa de entrega'),
          const SizedBox(height: 8),
          TextFormField(
            key: const Key('loja_taxa'),
            controller: _taxaController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: _decoracao(dica: '0,00', prefixo: 'R\$ '),
            validator: (valor) =>
                _errosApi['taxa_entrega'] ?? _validarTaxa(valor),
          ),
          const SizedBox(height: 26),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              key: const Key('loja_salvar'),
              onPressed: _salvando ? null : () => _salvar(usuario),
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: AppColors.green,
                disabledBackgroundColor: AppColors.green.withValues(
                  alpha: 0.55,
                ),
                foregroundColor: Colors.white,
                disabledForegroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(11),
                ),
              ),
              child: _salvando
                  ? const SizedBox(
                      width: 23,
                      height: 23,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Salvar Alterações',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  String? _validarNome(String? valor) {
    final nome = valor?.trim() ?? '';

    if (nome.isEmpty) return 'Informe o nome da empresa';
    if (nome.length < 3) return 'O nome deve ter pelo menos 3 letras';

    return null;
  }

  String? _validarTelefone(String? valor) {
    final digitos = valor?.replaceAll(RegExp(r'\D'), '') ?? '';

    return digitos.length >= 10 ? null : 'Informe um telefone válido';
  }

  String? _validarTaxa(String? valor) {
    final taxa = _lerDecimal(valor ?? '');

    if (taxa == null) return 'Informe a taxa de entrega';
    if (taxa < 0.01 || taxa > 99999.99) {
      return 'A taxa deve estar entre R\$ 0,01 e R\$ 99.999,99';
    }

    return null;
  }

  InputDecoration _decoracao({
    Color preenchimento = Colors.white,
    String? dica,
    String? prefixo,
  }) {
    return InputDecoration(
      filled: true,
      fillColor: preenchimento,
      hintText: dica,
      prefixText: prefixo,
      errorMaxLines: 2,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: const BorderSide(color: AppColors.green),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: const BorderSide(color: Colors.red),
      ),
    );
  }
}

class _AdminHeader extends StatelessWidget {
  const _AdminHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          const Expanded(child: AppLogo()),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF6E8),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Row(
              children: [
                CircleAvatar(radius: 4, backgroundColor: AppColors.green),
                SizedBox(width: 6),
                Text(
                  'Painel Admin',
                  style: TextStyle(
                    color: AppColors.green,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Builder(
            builder: (scaffoldContext) {
              return IconButton(
                tooltip: 'Abrir menu',
                onPressed: () {
                  Scaffold.of(scaffoldContext).openEndDrawer();
                },
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.lightGray,
                  minimumSize: const Size(48, 48),
                ),
                icon: const Icon(Icons.menu_rounded),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _Rotulo extends StatelessWidget {
  const _Rotulo(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Text(
      texto,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
    );
  }
}

class _SeletorDeHorario extends StatelessWidget {
  const _SeletorDeHorario({
    required this.chave,
    required this.rotulo,
    required this.valor,
    required this.onTap,
  });

  final String chave;
  final String rotulo;
  final String valor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      key: Key(chave),
      onPressed: onTap,
      icon: const Icon(Icons.schedule, size: 18),
      label: Text(valor.isEmpty ? rotulo : '$rotulo $valor'),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.black87,
        minimumSize: const Size(48, 54),
        side: const BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
      ),
    );
  }
}
