import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/enums.dart';
import '../../../../core/models/pagina.dart';
import '../../../../core/models/usuario.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_logo.dart';
import '../../../../core/widgets/app_menu_drawer.dart';
import '../../../../core/widgets/async_value_view.dart';
import '../../../auth/data/sessao_provider.dart';
import '../../../auth/presentation/validacao_senha.dart';
import '../../data/admin_repository.dart';

import '../../../../core/widgets/app_bottom_navigation.dart';

enum _Filtro {
  todos('Todos'),
  pendentes('Pendentes', status: StatusUsuario.pendente),
  clientes('Clientes', tipoPerfil: TipoPerfil.consumidor),
  fornecedores('Fornecedores', tipoPerfil: TipoPerfil.cacambeiro),
  parceiros('Parceiros', tipoPerfil: TipoPerfil.parceiro),
  admins('Admins', tipoPerfil: TipoPerfil.admin);

  const _Filtro(this.label, {this.tipoPerfil, this.status});

  final String label;
  final TipoPerfil? tipoPerfil;
  final StatusUsuario? status;
}

typedef _Consulta = ({_Filtro filtro, String? busca, int pagina});

final _usuariosProvider = FutureProvider.autoDispose
    .family<Pagina<Usuario>, _Consulta>((ref, consulta) {
      return ref
          .watch(adminRepositoryProvider)
          .listarUsuarios(
            pagina: consulta.pagina,
            tipoPerfil: consulta.filtro.tipoPerfil,
            status: consulta.filtro.status,
            busca: consulta.busca,
          );
    });

class GestaoUsuariosPage extends ConsumerStatefulWidget {
  const GestaoUsuariosPage({super.key});

  @override
  ConsumerState<GestaoUsuariosPage> createState() => _GestaoUsuariosPageState();
}

class _GestaoUsuariosPageState extends ConsumerState<GestaoUsuariosPage> {
  final _searchController = TextEditingController();

  _Filtro _filtro = _Filtro.todos;

  /// Busca enviada à API; `null` = sem busca.
  String? _busca;
  int _paginas = 1;

  final Set<String> _processando = {};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _selecionarFiltro(_Filtro filtro) {
    setState(() {
      _filtro = filtro;
      _paginas = 1;
    });
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

  void _clearSearch() {
    _searchController.clear();

    setState(() {
      _busca = null;
      _paginas = 1;
    });
  }

  void _recarregar() {
    ref.invalidate(_usuariosProvider);
    setState(() => _paginas = 1);
  }

  @override
  Widget build(BuildContext context) {
    final paginas = [
      for (var pagina = 1; pagina <= _paginas; pagina++)
        ref.watch(
          _usuariosProvider((filtro: _filtro, busca: _busca, pagina: pagina)),
        ),
    ];
    final primeira = paginas.first;
    final usuarios = [for (final pagina in paginas) ...?pagina.value?.itens];
    final carregandoMais = paginas.length > 1 && paginas.last.isLoading;
    final temProxima = paginas.last.value?.temProxima ?? false;

    final pendentes = ref
        .watch(
          _usuariosProvider((
            filtro: _Filtro.pendentes,
            busca: null,
            pagina: 1,
          )),
        )
        .value
        ?.total;
    final meuId = ref.watch(sessaoProvider).value?.id;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      endDrawer: const AppMenuDrawer(),
      drawerScrimColor: const Color(0xD9000000),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Novo administrador',
        onPressed: _showCreateAdminDialog,
        backgroundColor: AppColors.green,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(child: _AdminHeader()),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 30, 18, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Gestão de Usuários',
                      style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Aprove fornecedores e gerencie clientes e '
                      'administradores',
                      style: TextStyle(color: Colors.black54, fontSize: 14),
                    ),
                    if (pendentes != null &&
                        pendentes > 0 &&
                        _filtro != _Filtro.pendentes) ...[
                      const SizedBox(height: 16),
                      _PendingBanner(
                        total: pendentes,
                        onTap: () => _selecionarFiltro(_Filtro.pendentes),
                      ),
                    ],
                    const SizedBox(height: 18),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          for (final filtro in _Filtro.values) ...[
                            _filterChip(
                              filtro,
                              total: filtro == _Filtro.pendentes
                                  ? pendentes
                                  : filtro == _filtro
                                  ? primeira.value?.total
                                  : null,
                            ),
                            const SizedBox(width: 8),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            onChanged: (_) => setState(() {}),
                            onSubmitted: (_) => _buscar(),
                            textInputAction: TextInputAction.search,
                            decoration: InputDecoration(
                              hintText: 'Buscar por nome ou e-mail...',
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
                              suffixIcon: _searchController.text.isEmpty
                                  ? null
                                  : IconButton(
                                      tooltip: 'Limpar busca',
                                      onPressed: _clearSearch,
                                      icon: const Icon(Icons.close),
                                    ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        SizedBox(
                          width: 56,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _buscar,
                            style: ElevatedButton.styleFrom(
                              elevation: 0,
                              padding: EdgeInsets.zero,
                              backgroundColor: AppColors.green,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Icon(Icons.search, size: 27),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (primeira.hasError || (primeira.isLoading && !primeira.hasValue))
              SliverToBoxAdapter(
                child: AsyncValueView(
                  value: primeira,
                  onRetry: _recarregar,
                  data: (_) => const SizedBox.shrink(),
                ),
              )
            else if (usuarios.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Text(
                    _busca == null && _filtro == _Filtro.pendentes
                        ? 'Nenhum cadastro aguardando aprovação.'
                        : 'Nenhum usuário encontrado.',
                    style: const TextStyle(color: Colors.black54),
                  ),
                ),
              )
            else ...[
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                sliver: SliverList.separated(
                  itemCount: usuarios.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    final usuario = usuarios[index];

                    return _UserCard(
                      usuario: usuario,
                      processando: _processando.contains(usuario.id),
                      onTap: () => _showUserOptions(
                        usuario,
                        propriaConta: usuario.id == meuId,
                      ),
                    );
                  },
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 100),
                  child: Center(
                    child: carregandoMais
                        ? const CircularProgressIndicator(
                            color: AppColors.green,
                          )
                        : temProxima
                        ? TextButton(
                            onPressed: () => setState(() => _paginas++),
                            child: const Text(
                              'Carregar mais',
                              style: TextStyle(
                                color: AppColors.green,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          )
                        : null,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      bottomNavigationBar: const PlatformAdminBottomNavigation(currentIndex: 1),
    );
  }

  Widget _filterChip(_Filtro filtro, {int? total}) {
    final selected = _filtro == filtro;

    return ChoiceChip(
      label: Text(total == null ? filtro.label : '${filtro.label} ($total)'),
      selected: selected,
      showCheckmark: false,
      selectedColor: AppColors.green,
      backgroundColor: AppColors.lightGray,
      side: BorderSide.none,
      labelStyle: TextStyle(
        color: selected ? Colors.white : Colors.black54,
        fontWeight: FontWeight.w700,
      ),
      onSelected: (_) => _selecionarFiltro(filtro),
    );
  }

  Future<void> _showUserOptions(
    Usuario usuario, {
    required bool propriaConta,
  }) async {
    final novoStatus = await showModalBottomSheet<StatusUsuario>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        Widget acao({
          required IconData icon,
          required String label,
          required StatusUsuario status,
        }) {
          final color = status == StatusUsuario.ativo
              ? AppColors.green
              : Colors.red;

          return ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(icon, color: color),
            title: Text(label),
            onTap: () => Navigator.pop(sheetContext, status),
          );
        }

        final String? bloqueio = usuario.isAdmin
            ? 'O status de administradores não pode ser alterado.'
            : propriaConta
            ? 'Você não pode alterar o status da sua própria conta.'
            : null;

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 6, 24, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.lightGray,
                    child: Icon(Icons.person_outline),
                  ),
                  title: Text(
                    usuario.nomeCompleto,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    [
                      usuario.email,
                      if (usuario.telefone != null)
                        formatPhone(usuario.telefone),
                      if (usuario.documento != null) usuario.documento!,
                    ].join('\n'),
                  ),
                  isThreeLine: true,
                ),
                const Divider(),
                if (bloqueio != null)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(
                      Icons.info_outline,
                      color: Colors.black38,
                    ),
                    title: Text(
                      bloqueio,
                      style: const TextStyle(color: Colors.black54),
                    ),
                  )
                else
                  ...switch (usuario.status) {
                    StatusUsuario.pendente => [
                      acao(
                        icon: Icons.verified_outlined,
                        label: 'Aprovar cadastro',
                        status: StatusUsuario.ativo,
                      ),
                      acao(
                        icon: Icons.block,
                        label: 'Recusar cadastro',
                        status: StatusUsuario.suspenso,
                      ),
                    ],
                    StatusUsuario.ativo => [
                      acao(
                        icon: Icons.person_off_outlined,
                        label: 'Suspender usuário',
                        status: StatusUsuario.suspenso,
                      ),
                    ],
                    StatusUsuario.suspenso => [
                      acao(
                        icon: Icons.person_add_alt_outlined,
                        label: 'Reativar usuário',
                        status: StatusUsuario.ativo,
                      ),
                    ],
                    null => const <Widget>[],
                  },
              ],
            ),
          ),
        );
      },
    );

    if (novoStatus == null || !mounted) return;

    await _alterarStatus(usuario, novoStatus);
  }

  Future<void> _alterarStatus(Usuario usuario, StatusUsuario novoStatus) async {
    final pendente = usuario.status == StatusUsuario.pendente;

    if (novoStatus == StatusUsuario.suspenso) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: Text(pendente ? 'Recusar cadastro' : 'Suspender usuário'),
            content: Text(
              pendente
                  ? 'O cadastro de "${usuario.nomeCompleto}" será recusado e '
                        'a conta não poderá entrar no app.'
                  : '"${usuario.nomeCompleto}" perderá o acesso ao app '
                        'imediatamente.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: Text(
                  pendente ? 'Recusar' : 'Suspender',
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ],
          );
        },
      );

      if (confirmed != true || !mounted) return;
    }

    setState(() => _processando.add(usuario.id));
    try {
      await ref
          .read(adminRepositoryProvider)
          .alterarStatusUsuario(usuario.id, novoStatus);
      if (!mounted) return;

      ref.invalidate(_usuariosProvider);

      final ativou = novoStatus == StatusUsuario.ativo;
      final mensagem = switch ((pendente, ativou)) {
        (true, true) when usuario.isCacambeiro =>
          'Cadastro aprovado. O fornecedor já pode entrar no app.',
        (true, true) => 'Cadastro aprovado.',
        (true, false) => 'Cadastro recusado.',
        (false, true) => 'Usuário reativado.',
        (false, false) => 'Usuário suspenso.',
      };

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(mensagem),
          backgroundColor: ativou ? AppColors.green : Colors.red,
        ),
      );
    } on ApiException catch (error) {
      if (mounted) showApiError(context, error);
    } finally {
      if (mounted) setState(() => _processando.remove(usuario.id));
    }
  }

  Future<void> _showCreateAdminDialog() async {
    final created = await showDialog<bool>(
      context: context,
      builder: (_) => const _NovoAdminDialog(),
    );

    if (created != true || !mounted) return;

    ref.invalidate(_usuariosProvider);
    _selecionarFiltro(_Filtro.admins);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Administrador cadastrado.'),
        backgroundColor: AppColors.green,
      ),
    );
  }
}

/// Formulário de `POST /usuarios/admin`. Fecha com `true` ao criar.
class _NovoAdminDialog extends ConsumerStatefulWidget {
  const _NovoAdminDialog();

  @override
  ConsumerState<_NovoAdminDialog> createState() => _NovoAdminDialogState();
}

class _NovoAdminDialogState extends ConsumerState<_NovoAdminDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _cpfController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  Map<String, String> _errosApi = const {};

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _cpfController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? Function(String?) _comErroDaApi(
    String campo,
    String? Function(String?) validator,
  ) {
    return (value) => _errosApi[campo] ?? validator(value);
  }

  Future<void> _salvar() async {
    setState(() => _errosApi = const {});
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await ref
          .read(adminRepositoryProvider)
          .criarAdmin(
            nomeCompleto: _nameController.text,
            email: _emailController.text,
            senha: _passwordController.text,
            documento: _cpfController.text,
            telefone: _phoneController.text,
          );
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        if (error is ApiException) _errosApi = error.fields;
      });
      _formKey.currentState!.validate();
      showApiError(context, error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final digitsOnly = [FilteringTextInputFormatter.digitsOnly];

    return AlertDialog(
      title: const Text('Novo administrador'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nome completo'),
                validator: _comErroDaApi(
                  'nome_completo',
                  (value) =>
                      (value?.trim().length ?? 0) < 3 ? 'Informe o nome' : null,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'E-mail'),
                validator: _comErroDaApi(
                  'email',
                  (value) =>
                      RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                          .hasMatch(value?.trim() ?? '')
                      ? null
                      : 'Informe um e-mail válido',
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _cpfController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  ...digitsOnly,
                  LengthLimitingTextInputFormatter(11),
                ],
                decoration: const InputDecoration(labelText: 'CPF'),
                validator: _comErroDaApi(
                  'documento',
                  (value) => value?.length == 11
                      ? null
                      : 'Informe um CPF com 11 dígitos',
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  ...digitsOnly,
                  LengthLimitingTextInputFormatter(11),
                ],
                decoration: const InputDecoration(labelText: 'Telefone'),
                validator: _comErroDaApi(
                  'telefone',
                  (value) => (value?.length ?? 0) >= 10
                      ? null
                      : 'Informe um telefone válido',
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Senha',
                  helperText: '8+ caracteres, maiúscula, minúscula e número',
                  helperMaxLines: 2,
                  errorMaxLines: 2,
                  suffixIcon: IconButton(
                    tooltip: _obscurePassword
                        ? 'Mostrar senha'
                        : 'Ocultar senha',
                    onPressed: () {
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                ),
                validator: _comErroDaApi('senha', validarSenhaCadastro),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _salvar,
          child: _isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Cadastrar'),
        ),
      ],
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

class _PendingBanner extends StatelessWidget {
  final int total;
  final VoidCallback onTap;

  const _PendingBanner({required this.total, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFFFF4E5),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              const Icon(Icons.hourglass_top_rounded, color: Colors.orange),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  total == 1
                      ? '1 cadastro aguardando aprovação'
                      : '$total cadastros aguardando aprovação',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.black54),
            ],
          ),
        ),
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  final Usuario usuario;
  final bool processando;
  final VoidCallback onTap;

  const _UserCard({
    required this.usuario,
    required this.processando,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: processando ? null : onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 31,
                backgroundColor: AppColors.lightGray,
                child: Text(
                  _initials(usuario.nomeCompleto),
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 5,
                      children: [
                        Text(
                          usuario.nomeCompleto,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        _UserTypeBadge(tipo: usuario.tipoPerfil),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      usuario.email,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Cadastrado em ${formatDate(usuario.criadoEm)}',
                      style: const TextStyle(
                        color: Colors.black38,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              if (processando)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.green,
                  ),
                )
              else
                _StatusIndicator(status: usuario.status),
            ],
          ),
        ),
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));

    if (parts.first.isEmpty) return '?';

    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }

    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}

class _StatusIndicator extends StatelessWidget {
  final StatusUsuario? status;

  const _StatusIndicator({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      StatusUsuario.ativo => ('Ativo', AppColors.green),
      StatusUsuario.pendente => ('Pendente', Colors.orange),
      StatusUsuario.suspenso => ('Suspenso', Colors.red),
      null => ('-', Colors.grey),
    };

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(radius: 5, backgroundColor: color),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(color: Colors.black54, fontSize: 11),
        ),
      ],
    );
  }
}

class _UserTypeBadge extends StatelessWidget {
  final TipoPerfil? tipo;

  const _UserTypeBadge({required this.tipo});

  @override
  Widget build(BuildContext context) {
    final (label, foreground, background) = switch (tipo) {
      TipoPerfil.admin => (
        'Admin',
        const Color(0xFF1689D8),
        const Color(0xFFE1F2FF),
      ),
      TipoPerfil.cacambeiro => (
        'Fornecedor',
        const Color(0xFFB86E00),
        const Color(0xFFFFF4E5),
      ),
      _ => ('Cliente', Colors.black54, AppColors.lightGray),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foreground,
          fontSize: 9,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/*
REMOVENDO POIS O TRECHO ABAIXO FOI SUBSTITUIDO POR:
{
bottomNavigationBar: const SupplierBottomNavigation(
  currentIndex: 2,
),
}

class _AdminBottomNavigation extends StatelessWidget {
  const _AdminBottomNavigation();

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: 1,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: AppColors.green,
      unselectedItemColor: Colors.black54,
      selectedFontSize: 11,
      unselectedFontSize: 11,
      onTap: (index) {
        // A navegação será implementada durante a componentização.
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: 'Início',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.people_outline),
          activeIcon: Icon(Icons.people),
          label: 'Usuários',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.local_shipping_outlined),
          activeIcon: Icon(Icons.local_shipping),
          label: 'Parceiros',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.attach_money),
          label: 'Finanças',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.settings_outlined),
          activeIcon: Icon(Icons.settings),
          label: 'Config',
        ),
      ],
    );
  }
}
*/
