import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/aluguel.dart';
import '../../../../core/models/endereco.dart';
import '../../../../core/models/enums.dart';
import '../../../../core/models/pagina.dart';
import '../../../../core/models/usuario.dart';
import '../../../../core/navigation/app_routes.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_bottom_navigation.dart';
import '../../../../core/widgets/app_logo.dart';
import '../../../../core/widgets/app_menu_drawer.dart';
import '../../../../core/widgets/async_value_view.dart';
import '../../../auth/data/auth_repository.dart';
import '../../../auth/data/sessao_provider.dart';
import '../../../pedidos/data/pedidos_repository.dart';
import '../../../pedidos/presentation/pages/acompanhar_pedido_page.dart';
import '../../data/enderecos_repository.dart';
import '../widgets/editar_dados_pessoais_dialog.dart';
import '../widgets/endereco_form_dialog.dart';

final perfilClienteProvider = FutureProvider.autoDispose<Usuario>((ref) {
  return ref.watch(authRepositoryProvider).perfil();
});

final enderecosClienteProvider = FutureProvider.autoDispose<List<Endereco>>((
  ref,
) {
  return ref.watch(enderecosRepositoryProvider).listar();
});

/// Uma página (20 pedidos) do histórico do cliente.
final pedidosClienteProvider = FutureProvider.autoDispose
    .family<Pagina<Aluguel>, int>((ref, pagina) {
      return ref.watch(pedidosRepositoryProvider).meusPedidos(pagina: pagina);
    });

const _limiteEnderecos = 10;

class PerfilClientePage extends ConsumerStatefulWidget {
  const PerfilClientePage({super.key});

  @override
  ConsumerState<PerfilClientePage> createState() => _PerfilClientePageState();
}

class _PerfilClientePageState extends ConsumerState<PerfilClientePage> {
  /// Quantas páginas do histórico de pedidos estão sendo mostradas.
  int _paginasDePedidos = 1;

  String? _removendoEnderecoId;
  bool _saindo = false;

  @override
  Widget build(BuildContext context) {
    // Depois de entrar pelo botão "Entrar" (erro 401), recarrega a tela.
    ref.listen(sessaoProvider.select((sessao) => sessao.value?.id), (
      anterior,
      atual,
    ) {
      if (atual != null && atual != anterior) _recarregar();
    });

    final perfil = ref.watch(perfilClienteProvider);
    final enderecos = ref.watch(enderecosClienteProvider);
    final pedidos = [
      for (var pagina = 1; pagina <= _paginasDePedidos; pagina++)
        ref.watch(pedidosClienteProvider(pagina)),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      endDrawer: const AppMenuDrawer(),
      drawerScrimColor: const Color(0xD9000000),
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: AppColors.green,
          onRefresh: _recarregar,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              const SliverToBoxAdapter(child: _PageHeader()),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 28, 18, 34),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Meu Perfil',
                        style: TextStyle(
                          fontSize: 27,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Gerencie seus dados, endereços e pedidos',
                        style: TextStyle(color: Colors.black54, fontSize: 15),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: AsyncValueView<Usuario>(
                          value: perfil,
                          onRetry: () => ref.invalidate(perfilClienteProvider),
                          data: (usuario) =>
                              _buildConteudo(usuario, enderecos, pedidos),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: _SustainabilityFooter()),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const CustomerBottomNavigation(currentIndex: 3),
    );
  }

  Widget _buildConteudo(
    Usuario usuario,
    AsyncValue<List<Endereco>> enderecos,
    List<AsyncValue<Pagina<Aluguel>>> pedidos,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ProfileCard(
          usuario: usuario,
          totalPedidos: pedidos.first.value?.total,
          onEdit: () => _editarDadosPessoais(usuario),
        ),
        const SizedBox(height: 30),
        _SectionHeader(
          title: 'Dados pessoais',
          actionLabel: 'Editar',
          actionIcon: Icons.edit_outlined,
          onAction: () => _editarDadosPessoais(usuario),
        ),
        const SizedBox(height: 10),
        _PersonalDataCard(usuario: usuario),
        const SizedBox(height: 28),
        _SectionHeader(
          title: 'Meus endereços',
          actionLabel: 'Adicionar',
          actionIcon: Icons.add,
          onAction: _adicionarEndereco,
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: AsyncValueView<List<Endereco>>(
            value: enderecos,
            onRetry: () => ref.invalidate(enderecosClienteProvider),
            data: _buildEnderecos,
          ),
        ),
        const SizedBox(height: 28),
        const Text(
          'Meus pedidos',
          style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        SizedBox(width: double.infinity, child: _buildPedidos(pedidos)),
        const SizedBox(height: 32),
        const Text(
          'Ajuda',
          style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        _SupportCard(onTap: _showSupport),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton.icon(
            onPressed: _saindo ? null : _logout,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(11),
              ),
            ),
            icon: _saindo
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.red,
                    ),
                  )
                : const Icon(Icons.logout),
            label: const Text(
              'Sair da conta',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEnderecos(List<Endereco> enderecos) {
    if (enderecos.isEmpty) {
      return const _EmptyCard(
        icon: Icons.location_off_outlined,
        message:
            'Nenhum endereço cadastrado. Adicione um endereço para '
            'receber suas caçambas.',
      );
    }

    return Column(
      children: [
        for (final endereco in enderecos)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _AddressCard(
              endereco: endereco,
              removendo: _removendoEnderecoId == endereco.id,
              onEdit: () => _editarEndereco(endereco),
              onRemove: () => _removerEndereco(endereco),
            ),
          ),
      ],
    );
  }

  Widget _buildPedidos(List<AsyncValue<Pagina<Aluguel>>> paginas) {
    final itens = <Widget>[];

    for (var i = 0; i < paginas.length; i++) {
      final numeroPagina = i + 1;
      final pagina = paginas[i];

      if (!pagina.hasValue) {
        itens.add(
          AsyncValueView<Pagina<Aluguel>>(
            value: pagina,
            onRetry: () => ref.invalidate(pedidosClienteProvider(numeroPagina)),
            data: (_) => const SizedBox.shrink(),
          ),
        );
        break;
      }

      final dados = pagina.value!;

      if (i == 0 && dados.itens.isEmpty) {
        return _EmptyCard(
          icon: Icons.inbox_outlined,
          message: 'Você ainda não fez nenhum pedido.',
          actionLabel: 'Ver caçambas',
          onAction: () => Navigator.of(context).pushNamed(AppRoutes.services),
        );
      }

      for (final pedido in dados.itens) {
        itens.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _OrderCard(
              pedido: pedido,
              onTap: () => _abrirPedido(pedido),
            ),
          ),
        );
      }

      if (i == paginas.length - 1 && dados.temProxima) {
        itens.add(
          Center(
            child: TextButton.icon(
              onPressed: () => setState(() => _paginasDePedidos++),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF267A2D),
              ),
              icon: const Icon(Icons.expand_more),
              label: const Text(
                'Ver mais pedidos',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        );
      }
    }

    return Column(children: itens);
  }

  Future<void> _recarregar() async {
    setState(() => _paginasDePedidos = 1);
    ref.invalidate(perfilClienteProvider);
    ref.invalidate(enderecosClienteProvider);
    ref.invalidate(pedidosClienteProvider);

    try {
      await ref.read(perfilClienteProvider.future);
    } catch (_) {
      // O erro aparece na própria tela.
    }
  }

  Future<void> _editarDadosPessoais(Usuario usuario) async {
    final salvou = await showDialog<bool>(
      context: context,
      builder: (_) => EditarDadosPessoaisDialog(usuario: usuario),
    );

    if (salvou != true || !mounted) return;

    ref.invalidate(perfilClienteProvider);
    ref.invalidate(sessaoProvider);
    _showMessage('Dados atualizados com sucesso.');
  }

  Future<void> _adicionarEndereco() async {
    final total = ref.read(enderecosClienteProvider).value?.length ?? 0;

    if (total >= _limiteEnderecos) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Você atingiu o limite de $_limiteEnderecos endereços. '
            'Remova um para cadastrar outro.',
          ),
        ),
      );
      return;
    }

    final salvou = await showDialog<bool>(
      context: context,
      builder: (_) => const EnderecoFormDialog(),
    );

    if (salvou != true || !mounted) return;

    ref.invalidate(enderecosClienteProvider);
    _showMessage('Endereço cadastrado.');
  }

  Future<void> _editarEndereco(Endereco endereco) async {
    final salvou = await showDialog<bool>(
      context: context,
      builder: (_) => EnderecoFormDialog(endereco: endereco),
    );

    if (salvou != true || !mounted) return;

    ref.invalidate(enderecosClienteProvider);
    _showMessage('Endereço atualizado.');
  }

  Future<void> _removerEndereco(Endereco endereco) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Remover endereço'),
          content: Text(
            'Deseja remover ${endereco.logradouro}, ${endereco.numero}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Remover', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirmado != true || !mounted) return;

    setState(() => _removendoEnderecoId = endereco.id);

    try {
      await ref.read(enderecosRepositoryProvider).remover(endereco.id);

      if (!mounted) return;
      ref.invalidate(enderecosClienteProvider);
      _showMessage('Endereço removido.');
    } on ApiException catch (error) {
      if (mounted) showApiError(context, error);
    } finally {
      if (mounted) setState(() => _removendoEnderecoId = null);
    }
  }

  Future<void> _abrirPedido(Aluguel pedido) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AcompanharPedidoPage(aluguelId: pedido.id),
      ),
    );

    // O status pode ter mudado enquanto o pedido estava aberto.
    if (mounted) ref.invalidate(pedidosClienteProvider);
  }

  void _showSupport() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return const SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, 4, 20, 30),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: Icon(Icons.chat_outlined, color: AppColors.green),
                  title: Text('WhatsApp'),
                  subtitle: Text('(11) 99999-9999'),
                ),
                ListTile(
                  leading: Icon(Icons.email_outlined, color: AppColors.green),
                  title: Text('E-mail'),
                  subtitle: Text('suporte@collectxpress.com.br'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Sair da conta'),
          content: const Text('Deseja encerrar sua sessão?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Sair', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    setState(() => _saindo = true);

    try {
      await ref.read(sessaoProvider.notifier).sair();
    } finally {
      if (mounted) setState(() => _saindo = false);
    }

    if (!mounted) return;

    Navigator.of(context)
        .pushNamedAndRemoveUntil(AppRoutes.home, (route) => false);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.green),
    );
  }
}

/// `01311200` → `01311-200`
String _formatarCep(String cep) {
  final digitos = cep.replaceAll(RegExp(r'\D'), '');
  if (digitos.length != 8) return cep;
  return '${digitos.substring(0, 5)}-${digitos.substring(5)}';
}

const _meses = [
  'janeiro',
  'fevereiro',
  'março',
  'abril',
  'maio',
  'junho',
  'julho',
  'agosto',
  'setembro',
  'outubro',
  'novembro',
  'dezembro',
];

class _PageHeader extends StatelessWidget {
  const _PageHeader();

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

class _ProfileCard extends StatelessWidget {
  final Usuario usuario;

  /// `null` enquanto o histórico de pedidos carrega (ou se falhar).
  final int? totalPedidos;

  final VoidCallback onEdit;

  const _ProfileCard({
    required this.usuario,
    required this.totalPedidos,
    required this.onEdit,
  });

  String get _descricaoConta {
    final criadoEm = usuario.criadoEm?.toLocal();
    if (criadoEm == null) return 'Cliente';
    return 'Cliente • Desde ${_meses[criadoEm.month - 1]} de ${criadoEm.year}';
  }

  String get _resumoPedidos => switch (totalPedidos) {
    0 => 'Nenhum pedido realizado',
    1 => '1 pedido realizado',
    final total => '$total pedidos realizados',
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.sustainability,
        border: Border.all(color: const Color(0xFF83AC55)),
        borderRadius: BorderRadius.circular(18),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 520;

          final identity = Row(
            children: [
              const CircleAvatar(
                radius: 45,
                backgroundColor: AppColors.green,
                child: Icon(
                  Icons.person_outline,
                  color: Colors.white,
                  size: 55,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          usuario.nomeCompleto,
                          style: const TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (usuario.status == StatusUsuario.ativo)
                          const _ActiveBadge(),
                      ],
                    ),
                    const SizedBox(height: 7),
                    Text(
                      _descricaoConta,
                      style: const TextStyle(color: Colors.black54),
                    ),
                    if (totalPedidos != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _resumoPedidos,
                        style: const TextStyle(
                          color: Color(0xFF267A2D),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          );

          if (compact) {
            return Column(
              children: [
                identity,
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Editar perfil'),
                  ),
                ),
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: identity),
              const SizedBox(width: 20),
              ElevatedButton.icon(
                onPressed: onEdit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.green,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Editar perfil'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ActiveBadge extends StatelessWidget {
  const _ActiveBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified_outlined, color: AppColors.green, size: 15),
          SizedBox(width: 4),
          Text(
            'Conta ativa',
            style: TextStyle(
              color: Color(0xFF267A2D),
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String actionLabel;
  final IconData actionIcon;
  final VoidCallback onAction;

  const _SectionHeader({
    required this.title,
    required this.actionLabel,
    required this.actionIcon,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
          ),
        ),
        TextButton.icon(
          onPressed: onAction,
          icon: Icon(actionIcon, size: 17),
          label: Text(actionLabel),
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF267A2D),
            backgroundColor: AppColors.lightGray,
          ),
        ),
      ],
    );
  }
}

class _PersonalDataCard extends StatelessWidget {
  final Usuario usuario;

  const _PersonalDataCard({required this.usuario});

  @override
  Widget build(BuildContext context) {
    // A API devolve o documento mascarado (ex.: `***.***.789-00`).
    final documento = usuario.documento;
    final ehCnpj = documento != null && documento.contains('/');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.lightGray,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Wrap(
        spacing: 40,
        runSpacing: 20,
        children: [
          _DataItem(
            icon: Icons.email_outlined,
            label: 'E-mail',
            value: usuario.email,
          ),
          _DataItem(
            icon: Icons.badge_outlined,
            label: ehCnpj ? 'CNPJ' : 'CPF',
            value: documento ?? '-',
          ),
          _DataItem(
            icon: Icons.phone_outlined,
            label: 'Telefone',
            value: formatPhone(usuario.telefone),
          ),
        ],
      ),
    );
  }
}

class _DataItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DataItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.green, size: 20),
          const SizedBox(height: 15),
          Text(
            label,
            style: const TextStyle(color: Colors.black54, fontSize: 11),
          ),
          const SizedBox(height: 3),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

enum _AcaoEndereco { editar, remover }

class _AddressCard extends StatelessWidget {
  final Endereco endereco;
  final bool removendo;
  final VoidCallback onEdit;
  final VoidCallback onRemove;

  const _AddressCard({
    required this.endereco,
    required this.removendo,
    required this.onEdit,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final local = [
      if (endereco.bairro.isNotEmpty) endereco.bairro,
      endereco.cidadeEstado,
    ].join(' • ');

    return Container(
      padding: const EdgeInsets.fromLTRB(22, 22, 8, 22),
      decoration: BoxDecoration(
        color: AppColors.lightGray,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.location_on_outlined,
            color: AppColors.green,
            size: 30,
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${endereco.logradouro}, ${endereco.numero}',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(local, style: const TextStyle(color: Colors.black54)),
                const SizedBox(height: 7),
                Text(
                  'CEP ${_formatarCep(endereco.cep)}',
                  style: const TextStyle(
                    color: Color(0xFF267A2D),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          if (removendo)
            const Padding(
              padding: EdgeInsets.all(14),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.green,
                ),
              ),
            )
          else
            PopupMenuButton<_AcaoEndereco>(
              tooltip: 'Opções do endereço',
              onSelected: (acao) {
                switch (acao) {
                  case _AcaoEndereco.editar:
                    onEdit();
                  case _AcaoEndereco.remover:
                    onRemove();
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: _AcaoEndereco.editar,
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.edit_outlined),
                    title: Text('Editar'),
                  ),
                ),
                PopupMenuItem(
                  value: _AcaoEndereco.remover,
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.delete_outline, color: Colors.red),
                    title: Text('Remover', style: TextStyle(color: Colors.red)),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Aluguel pedido;
  final VoidCallback onTap;

  const _OrderCard({required this.pedido, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final status = pedido.statusAluguel;
    final pagamento = pedido.statusPagamento;
    final dias = pedido.diasAluguel == 1
        ? '1 dia'
        : '${pedido.diasAluguel} dias';

    return Material(
      color: AppColors.lightGray,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        hoverColor: AppColors.green.withValues(alpha: 0.07),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 12, 18),
          child: Row(
            children: [
              const Icon(
                Icons.receipt_long_outlined,
                color: AppColors.green,
                size: 28,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          'Pedido de ${formatDate(pedido.dataPedido)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (status != null)
                          _StatusBadge(
                            label: status.label,
                            ativo: status != StatusAluguel.finalizado,
                          ),
                      ],
                    ),
                    if (pedido.cacambeiroNome != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        pedido.cacambeiroNome!,
                        style: const TextStyle(color: Colors.black54),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Text(
                      'Início ${formatDate(pedido.dataInicio)} • $dias',
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      [
                        formatMoney(pedido.precoFinal),
                        if (pagamento != null) 'Pagamento ${pagamento.label}',
                      ].join(' • '),
                      style: const TextStyle(
                        color: Color(0xFF267A2D),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final bool ativo;

  const _StatusBadge({required this.label, required this.ativo});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: ativo ? AppColors.sustainability : Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: ativo ? const Color(0xFF267A2D) : Colors.black54,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _EmptyCard({
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.lightGray,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.black38, size: 34),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.black54),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: onAction,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.green,
                side: const BorderSide(color: AppColors.green),
              ),
              child: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}

class _SupportCard extends StatelessWidget {
  final VoidCallback onTap;

  const _SupportCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          hoverColor: AppColors.green.withValues(alpha: 0.07),
          child: ListTile(
            leading: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.sustainability,
                borderRadius: BorderRadius.circular(11),
              ),
              child: const Icon(Icons.help_outline, color: AppColors.green),
            ),
            title: const Text(
              'Ajuda e suporte',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            subtitle: const Text('Fale com a equipe Collect Xpress'),
            trailing: const Icon(Icons.chevron_right),
          ),
        ),
      ),
    );
  }
}

class _SustainabilityFooter extends StatelessWidget {
  const _SustainabilityFooter();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.sustainability,
      padding: const EdgeInsets.fromLTRB(18, 28, 18, 30),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.eco_outlined, color: AppColors.green),
              SizedBox(width: 8),
              Text(
                'Descarte Sustentável',
                style: TextStyle(
                  color: AppColors.green,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            'Todas as nossas caçambas seguem rigorosamente as normas '
            'ambientais municipais e resoluções do CONAMA.',
            style: TextStyle(color: Colors.black54, fontSize: 13, height: 1.5),
          ),
          SizedBox(height: 16),
          Text(
            '☎  Suporte WhatsApp: (11) 99999-9999',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
