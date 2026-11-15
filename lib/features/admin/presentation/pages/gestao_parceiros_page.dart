import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/enums.dart';
import '../../../../core/models/pagina.dart';
import '../../../../core/models/usuario.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_bottom_navigation.dart';
import '../../../../core/widgets/app_logo.dart';
import '../../../../core/widgets/app_menu_drawer.dart';
import '../../../../core/widgets/async_value_view.dart';
import '../../data/admin_repository.dart';

/// Filtro por situação do cadastro do parceiro de reciclagem.
enum _Filtro {
  todos('Todos'),
  pendentes('Pendentes', status: StatusUsuario.pendente),
  ativos('Ativos', status: StatusUsuario.ativo),
  suspensos('Suspensos', status: StatusUsuario.suspenso);

  const _Filtro(this.label, {this.status});

  final String label;
  final StatusUsuario? status;
}

typedef _Consulta = ({_Filtro filtro, String? busca, int pagina});

final _parceirosProvider = FutureProvider.autoDispose
    .family<Pagina<Usuario>, _Consulta>((ref, consulta) {
      return ref
          .watch(adminRepositoryProvider)
          .listarUsuarios(
            pagina: consulta.pagina,
            tipoPerfil: TipoPerfil.parceiro,
            status: consulta.filtro.status,
            busca: consulta.busca,
          );
    });

final _detalheDoParceiroProvider = FutureProvider.autoDispose
    .family<Usuario, String>((ref, id) async {
      final detalhe = await ref
          .watch(adminRepositoryProvider)
          .detalheUsuario(id);
      return detalhe.usuario;
    });

/// Parceiros de reciclagem: o admin analisa os cadastros novos e pode
/// suspender ou reativar quem já está ativo.
class GestaoParceirosPage extends ConsumerStatefulWidget {
  const GestaoParceirosPage({super.key});

  @override
  ConsumerState<GestaoParceirosPage> createState() =>
      _GestaoParceirosPageState();
}

class _GestaoParceirosPageState extends ConsumerState<GestaoParceirosPage> {
  final _searchController = TextEditingController();

  _Filtro _filtro = _Filtro.pendentes;
  String? _busca;
  int _paginas = 1;

  final Set<String> _processando = {};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _buscar() {
    final texto = _searchController.text.trim();

    // A API ignora buscas com menos de 3 letras.
    if (texto.isNotEmpty && texto.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Digite pelo menos 3 letras.')),
      );
      return;
    }

    setState(() {
      _busca = texto.isEmpty ? null : texto;
      _paginas = 1;
    });
  }

  void _limparBusca() {
    _searchController.clear();

    setState(() {
      _busca = null;
      _paginas = 1;
    });
  }

  Future<void> _alterarStatus(Usuario parceiro, StatusUsuario status) async {
    if (_processando.contains(parceiro.id)) return;

    setState(() => _processando.add(parceiro.id));

    try {
      await ref
          .read(adminRepositoryProvider)
          .alterarStatusUsuario(parceiro.id, status);

      ref.invalidate(_parceirosProvider);
      ref.invalidate(_detalheDoParceiroProvider);

      if (!mounted) return;

      final texto = switch (status) {
        StatusUsuario.ativo => '${parceiro.nomeCompleto} está ativo.',
        StatusUsuario.suspenso => '${parceiro.nomeCompleto} foi suspenso.',
        StatusUsuario.pendente => '',
      };

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(texto), backgroundColor: AppColors.green),
      );
    } on ApiException catch (erro) {
      if (mounted) showApiError(context, erro);
    } finally {
      if (mounted) setState(() => _processando.remove(parceiro.id));
    }
  }

  void _abrirDetalhe(Usuario parceiro) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (_) => _DetalheDoParceiro(
        parceiro: parceiro,
        onAlterar: (status) {
          Navigator.of(context).pop();
          _alterarStatus(parceiro, status);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final paginas = [
      for (var pagina = 1; pagina <= _paginas; pagina++)
        ref.watch(
          _parceirosProvider((filtro: _filtro, busca: _busca, pagina: pagina)),
        ),
    ];
    final primeira = paginas.first;
    final parceiros = [for (final p in paginas) ...?p.value?.itens];
    final carregandoMais = paginas.length > 1 && paginas.last.isLoading;
    final temProxima = paginas.last.value?.temProxima ?? false;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      endDrawer: const AppMenuDrawer(),
      drawerScrimColor: const Color(0xD9000000),
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: AppColors.green,
          onRefresh: () async {
            ref.invalidate(_parceirosProvider);
            await ref.read(
              _parceirosProvider((filtro: _filtro, busca: _busca, pagina: 1))
                  .future,
            );
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              const SliverToBoxAdapter(child: _AdminHeader()),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 26, 18, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Semantics(
                        header: true,
                        child: const Text(
                          'Parceiros de Reciclagem',
                          style: TextStyle(
                            fontSize: 25,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Aprove os cadastros e acompanhe quem coleta o '
                        'material reciclável.',
                        style: TextStyle(color: Colors.black54, fontSize: 14),
                      ),
                      const SizedBox(height: 18),
                      Wrap(
                        spacing: 8,
                        children: [
                          for (final filtro in _Filtro.values)
                            ChoiceChip(
                              key: Key('parceiros_filtro_${filtro.name}'),
                              label: Text(filtro.label),
                              selected: _filtro == filtro,
                              showCheckmark: false,
                              selectedColor: AppColors.green,
                              backgroundColor: AppColors.lightGray,
                              side: BorderSide.none,
                              labelStyle: TextStyle(
                                color: _filtro == filtro
                                    ? Colors.white
                                    : Colors.black54,
                                fontWeight: FontWeight.w700,
                              ),
                              onSelected: (_) => setState(() {
                                _filtro = filtro;
                                _paginas = 1;
                              }),
                            ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        key: const Key('parceiros_busca'),
                        controller: _searchController,
                        textInputAction: TextInputAction.search,
                        onSubmitted: (_) => _buscar(),
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: 'Buscar por empresa ou e-mail...',
                          filled: true,
                          fillColor: AppColors.lightGray,
                          border: OutlineInputBorder(
                            borderSide: BorderSide.none,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 17,
                          ),
                          prefixIcon: IconButton(
                            tooltip: 'Buscar',
                            onPressed: _buscar,
                            icon: const Icon(Icons.search),
                          ),
                          suffixIcon: _searchController.text.isEmpty
                              ? null
                              : IconButton(
                                  tooltip: 'Limpar busca',
                                  onPressed: _limparBusca,
                                  icon: const Icon(Icons.close),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (primeira.hasError && !primeira.hasValue)
                SliverToBoxAdapter(
                  child: ErrorView(
                    error: primeira.error!,
                    onRetry: () => ref.invalidate(_parceirosProvider),
                  ),
                )
              else if (primeira.isLoading && !primeira.hasValue)
                const SliverToBoxAdapter(child: LoadingView())
              else if (parceiros.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Text(
                      'Nenhum parceiro encontrado.',
                      style: TextStyle(color: Colors.black54),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 100),
                  sliver: SliverList.separated(
                    itemCount: parceiros.length + (temProxima ? 1 : 0),
                    separatorBuilder: (_, _) => const SizedBox(height: 14),
                    itemBuilder: (context, index) {
                      if (index == parceiros.length) {
                        return Center(
                          child: carregandoMais
                              ? const CircularProgressIndicator(
                                  color: AppColors.green,
                                )
                              : TextButton(
                                  onPressed: () => setState(() => _paginas++),
                                  child: const Text('Carregar mais'),
                                ),
                        );
                      }

                      final parceiro = parceiros[index];

                      return _CartaoDoParceiro(
                        parceiro: parceiro,
                        processando: _processando.contains(parceiro.id),
                        onTap: () => _abrirDetalhe(parceiro),
                        onAprovar: () =>
                            _alterarStatus(parceiro, StatusUsuario.ativo),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const PlatformAdminBottomNavigation(currentIndex: 2),
    );
  }
}

class _AdminHeader extends StatelessWidget {
  const _AdminHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
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

class _CartaoDoParceiro extends StatelessWidget {
  const _CartaoDoParceiro({
    required this.parceiro,
    required this.processando,
    required this.onTap,
    required this.onAprovar,
  });

  final Usuario parceiro;
  final bool processando;
  final VoidCallback onTap;
  final VoidCallback onAprovar;

  @override
  Widget build(BuildContext context) {
    final pendente = parceiro.status == StatusUsuario.pendente;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        key: Key('parceiro_${parceiro.id}'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE7ECE3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.recycling,
                      color: Color(0xFF789052),
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          parceiro.nomeCompleto,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'CNPJ: ${parceiro.documento ?? '-'}',
                          style: const TextStyle(
                            color: Colors.black54,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Cadastro em ${formatDate(parceiro.criadoEm)}',
                          style: const TextStyle(
                            color: Colors.black54,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _SeloDaSituacao(status: parceiro.status),
                ],
              ),
              if (pendente) ...[
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    key: Key('aprovar_${parceiro.id}'),
                    onPressed: processando ? null : onAprovar,
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: AppColors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: processando
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Aprovar Cadastro',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SeloDaSituacao extends StatelessWidget {
  const _SeloDaSituacao({required this.status});

  final StatusUsuario? status;

  @override
  Widget build(BuildContext context) {
    final (label, foreground, background) = switch (status) {
      StatusUsuario.ativo => (
        'Ativo',
        const Color(0xFF2F8334),
        const Color(0xFFE5F6E7),
      ),
      StatusUsuario.suspenso => (
        'Suspenso',
        Colors.red,
        const Color(0xFFFFE8E8),
      ),
      _ => ('Pendente', const Color(0xFF8A6500), AppColors.yellow),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foreground,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Dados da empresa para o admin decidir, com as ações de situação.
class _DetalheDoParceiro extends ConsumerWidget {
  const _DetalheDoParceiro({required this.parceiro, required this.onAlterar});

  final Usuario parceiro;
  final ValueChanged<StatusUsuario> onAlterar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detalhe = ref.watch(_detalheDoParceiroProvider(parceiro.id));
    final usuario = detalhe.value ?? parceiro;
    final dados = usuario.detalhesParceiro;

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.85,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 0, 22, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                usuario.nomeCompleto,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              _Linha('CNPJ', usuario.documento ?? '-'),
              _Linha('E-mail', usuario.email),
              _Linha('Telefone', formatPhone(usuario.telefone)),
              if (detalhe.isLoading && dados == null)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: LinearProgressIndicator(),
                )
              else if (dados != null) ...[
                _Linha('Responsável', dados.responsavelNome),
                _Linha('Endereço', dados.enderecoColeta),
                _Linha(
                  'Capacidade/dia',
                  dados.capacidadeDiariaKg == null
                      ? 'Não informada'
                      : formatKg(dados.capacidadeDiariaKg!),
                ),
                _Linha(
                  'Materiais',
                  dados.materiais.isEmpty ? '-' : dados.materiais.join(', '),
                ),
              ],
              const SizedBox(height: 16),
              if (usuario.status == StatusUsuario.pendente) ...[
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    key: const Key('detalhe_aprovar'),
                    onPressed: () => onAlterar(StatusUsuario.ativo),
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Aprovar cadastro'),
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: AppColors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    key: const Key('detalhe_recusar'),
                    onPressed: () => onAlterar(StatusUsuario.suspenso),
                    icon: const Icon(Icons.block),
                    label: const Text('Recusar cadastro'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                  ),
                ),
              ],
              if (usuario.status == StatusUsuario.ativo)
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    key: const Key('detalhe_suspender'),
                    onPressed: () => onAlterar(StatusUsuario.suspenso),
                    icon: const Icon(Icons.block),
                    label: const Text('Suspender parceiro'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                  ),
                ),
              if (usuario.status == StatusUsuario.suspenso)
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    key: const Key('detalhe_reativar'),
                    onPressed: () => onAlterar(StatusUsuario.ativo),
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Reativar parceiro'),
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: AppColors.green,
                      foregroundColor: Colors.white,
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

class _Linha extends StatelessWidget {
  const _Linha(this.rotulo, this.valor);

  final String rotulo;
  final String valor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 112,
            child: Text(
              rotulo,
              style: const TextStyle(color: Colors.black54, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              valor,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
