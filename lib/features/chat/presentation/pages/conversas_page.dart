import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/chat.dart';
import '../../../../core/models/enums.dart';
import '../../../../core/models/usuario.dart';
import '../../../../core/navigation/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_bottom_navigation.dart';
import '../../../../core/widgets/app_logo.dart';
import '../../../../core/widgets/app_menu_drawer.dart';
import '../../../../core/widgets/async_value_view.dart';
import '../../../auth/data/sessao_provider.dart';
import '../chat_providers.dart';
import '../widgets/conversa_tile.dart';
import '../widgets/novo_chamado_sheet.dart';
import 'chat_page.dart';

/// De quanto em quanto tempo a lista é atualizada enquanto está aberta.
const intervaloDaLista = Duration(seconds: 15);

/// Aba de conversas dos três perfis.
///
/// - Cliente: chats dos pedidos e chamados com o suporte.
/// - Caçambeiro: chats dos pedidos e a conversa com o suporte.
/// - Admin: chamados, fornecedores e (só leitura) pedidos.
class ConversasPage extends ConsumerStatefulWidget {
  const ConversasPage({super.key});

  @override
  ConsumerState<ConversasPage> createState() => _ConversasPageState();
}

class _ConversasPageState extends ConsumerState<ConversasPage> {
  Timer? _relogio;

  @override
  void initState() {
    super.initState();
    _relogio = Timer.periodic(
      intervaloDaLista,
      (_) => ref.invalidate(conversasProvider),
    );
  }

  @override
  void dispose() {
    _relogio?.cancel();
    super.dispose();
  }

  Widget _barraInferior(Usuario? usuario) {
    return switch (usuario?.tipoPerfil) {
      TipoPerfil.cacambeiro => const SupplierBottomNavigation(currentIndex: 4),
      TipoPerfil.admin => const PlatformAdminBottomNavigation(currentIndex: 4),
      _ => const CustomerBottomNavigation(currentIndex: 4),
    };
  }

  Future<void> _novoChamado() async {
    final conversa = await mostrarNovoChamado(context);

    if (conversa == null || !mounted) return;

    ref.invalidate(conversasProvider);
    await abrirConversa(context, ref, conversa);
  }

  @override
  Widget build(BuildContext context) {
    final sessao = ref.watch(sessaoProvider);
    final usuario = sessao.value;

    final Widget corpo;

    if (sessao.isLoading && usuario == null) {
      corpo = const LoadingView();
    } else if (usuario == null) {
      corpo = const _SemLogin();
    } else if (usuario.isAdmin) {
      corpo = const _ConversasDoAdmin();
    } else {
      corpo = _ConversasDoUsuario(consumidor: usuario.isConsumidor);
    }

    return Scaffold(
      drawerScrimColor: const Color(0xD9000000),
      endDrawer: const AppMenuDrawer(),
      bottomNavigationBar: _barraInferior(usuario),
      floatingActionButton: usuario?.isConsumidor ?? false
          ? FloatingActionButton.extended(
              key: const Key('novo_chamado'),
              onPressed: _novoChamado,
              backgroundColor: AppColors.green,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.support_agent),
              label: const Text(
                'Novo chamado',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            )
          : null,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const _Cabecalho(),
            Expanded(child: corpo),
          ],
        ),
      ),
    );
  }
}

class _Cabecalho extends StatelessWidget {
  const _Cabecalho();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 8),
      child: Builder(
        builder: (scaffoldContext) {
          return Row(
            children: [
              const Expanded(child: AppLogo()),
              IconButton(
                tooltip: 'Abrir menu',
                onPressed: () => Scaffold.of(scaffoldContext).openEndDrawer(),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.lightGray,
                  minimumSize: const Size(46, 46),
                ),
                icon: const Icon(Icons.menu_rounded),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SemLogin extends StatelessWidget {
  const _SemLogin();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.forum_outlined, size: 54, color: Colors.black38),
            const SizedBox(height: 14),
            const Text(
              'Entre na sua conta para ver suas conversas.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54, fontSize: 15),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pushNamed(AppRoutes.login),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Entrar'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Cliente e caçambeiro: uma lista só, com filtro por tipo.
class _ConversasDoUsuario extends StatefulWidget {
  const _ConversasDoUsuario({required this.consumidor});

  final bool consumidor;

  @override
  State<_ConversasDoUsuario> createState() => _ConversasDoUsuarioState();
}

class _ConversasDoUsuarioState extends State<_ConversasDoUsuario> {
  /// `null` = todas.
  TipoConversa? _tipo;

  @override
  Widget build(BuildContext context) {
    final suporte = widget.consumidor
        ? TipoConversa.chamado
        : TipoConversa.suporteCacambeiro;

    final filtros = <(String, TipoConversa?)>[
      ('Todas', null),
      ('Pedidos', TipoConversa.pedido),
      (widget.consumidor ? 'Chamados' : 'Suporte', suporte),
    ];

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 8),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Wrap(
              spacing: 8,
              children: [
                for (final (rotulo, tipo) in filtros)
                  ChoiceChip(
                    label: Text(rotulo),
                    selected: _tipo == tipo,
                    showCheckmark: false,
                    onSelected: (_) => setState(() => _tipo = tipo),
                    selectedColor: AppColors.green,
                    backgroundColor: AppColors.lightGray,
                    side: BorderSide.none,
                    labelStyle: TextStyle(
                      color: _tipo == tipo ? Colors.white : Colors.black54,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
        ),
        Expanded(
          child: ListaDeConversas(
            key: ValueKey(_tipo),
            tipo: _tipo,
            textoVazio: widget.consumidor
                ? 'Suas conversas aparecem aqui. Depois de um pedido você '
                      'fala com o fornecedor por este chat, e pode abrir um '
                      'chamado com o suporte.'
                : 'Suas conversas aparecem aqui. Cada pedido recebido tem um '
                      'chat com o cliente, e você tem um canal com o suporte.',
          ),
        ),
      ],
    );
  }
}

/// Admin: chamados, fornecedores e pedidos, com busca e denúncias.
class _ConversasDoAdmin extends StatefulWidget {
  const _ConversasDoAdmin();

  @override
  State<_ConversasDoAdmin> createState() => _ConversasDoAdminState();
}

class _ConversasDoAdminState extends State<_ConversasDoAdmin> {
  final _busca = TextEditingController();
  String _termo = '';
  bool _denunciadas = false;

  /// Só para a aba de chamados: `true` abertos, `false` encerrados.
  bool? _abertos = true;

  @override
  void dispose() {
    _busca.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          const TabBar(
            labelColor: AppColors.green,
            indicatorColor: AppColors.green,
            unselectedLabelColor: Colors.black54,
            tabs: [
              Tab(text: 'Chamados'),
              Tab(text: 'Fornecedores'),
              Tab(text: 'Pedidos'),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    key: const Key('admin_busca'),
                    controller: _busca,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (valor) =>
                        setState(() => _termo = valor.trim()),
                    decoration: InputDecoration(
                      hintText: 'Buscar por nome ou assunto',
                      isDense: true,
                      prefixIcon: const Icon(Icons.search, size: 20),
                      suffixIcon: _termo.isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'Limpar busca',
                              icon: const Icon(Icons.close, size: 18),
                              onPressed: () {
                                _busca.clear();
                                setState(() => _termo = '');
                              },
                            ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  key: const Key('admin_denunciadas'),
                  label: const Text('Denunciadas'),
                  avatar: const Icon(Icons.flag_outlined, size: 16),
                  selected: _denunciadas,
                  onSelected: (valor) => setState(() => _denunciadas = valor),
                  selectedColor: const Color(0xFFFFE3E3),
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Wrap(
                          spacing: 8,
                          children: [
                            for (final (rotulo, valor) in <(String, bool?)>[
                              ('Abertos', true),
                              ('Encerrados', false),
                              ('Todos', null),
                            ])
                              ChoiceChip(
                                label: Text(rotulo),
                                selected: _abertos == valor,
                                showCheckmark: false,
                                onSelected: (_) =>
                                    setState(() => _abertos = valor),
                                selectedColor: AppColors.green,
                                backgroundColor: AppColors.lightGray,
                                side: BorderSide.none,
                                labelStyle: TextStyle(
                                  color: _abertos == valor
                                      ? Colors.white
                                      : Colors.black54,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListaDeConversas(
                        key: ValueKey((
                          'chamados',
                          _abertos,
                          _termo,
                          _denunciadas,
                        )),
                        tipo: TipoConversa.chamado,
                        aberta: _abertos,
                        busca: _termo,
                        denunciadas: _denunciadas,
                        textoVazio: 'Nenhum chamado por aqui.',
                      ),
                    ),
                  ],
                ),
                ListaDeConversas(
                  key: ValueKey(('suporte', _termo, _denunciadas)),
                  tipo: TipoConversa.suporteCacambeiro,
                  busca: _termo,
                  denunciadas: _denunciadas,
                  textoVazio: 'Nenhum fornecedor encontrado.',
                ),
                ListaDeConversas(
                  key: ValueKey(('pedidos', _termo, _denunciadas)),
                  tipo: TipoConversa.pedido,
                  busca: _termo,
                  denunciadas: _denunciadas,
                  textoVazio:
                      'Nenhuma conversa de pedido com mensagens. Você só '
                      'acompanha essas conversas, sem escrever.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Lista paginada de conversas de um filtro.
class ListaDeConversas extends ConsumerStatefulWidget {
  const ListaDeConversas({
    super.key,
    required this.textoVazio,
    this.tipo,
    this.aberta,
    this.denunciadas = false,
    this.busca = '',
  });

  final TipoConversa? tipo;
  final bool? aberta;
  final bool denunciadas;
  final String busca;
  final String textoVazio;

  @override
  ConsumerState<ListaDeConversas> createState() => _ListaDeConversasState();
}

class _ListaDeConversasState extends ConsumerState<ListaDeConversas> {
  int _paginas = 1;

  FiltroConversas _filtro(int pagina) => (
    tipo: widget.tipo,
    aberta: widget.aberta,
    denunciadas: widget.denunciadas,
    busca: widget.busca,
    pagina: pagina,
  );

  @override
  Widget build(BuildContext context) {
    final paginas = [
      for (var pagina = 1; pagina <= _paginas; pagina++)
        ref.watch(conversasProvider(_filtro(pagina))),
    ];
    final primeira = paginas.first;
    final conversas = [for (final p in paginas) ...?p.value?.itens];
    final carregandoMais = paginas.length > 1 && paginas.last.isLoading;
    final temProxima = paginas.last.value?.temProxima ?? false;

    if (primeira.hasError && !primeira.hasValue) {
      return SingleChildScrollView(
        child: ErrorView(
          error: primeira.error!,
          onRetry: () => ref.invalidate(conversasProvider),
        ),
      );
    }

    if (primeira.isLoading && !primeira.hasValue) {
      return const LoadingView();
    }

    if (conversas.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.forum_outlined, size: 48, color: Colors.black26),
              const SizedBox(height: 12),
              Text(
                widget.textoVazio,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black54, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.green,
      onRefresh: () async {
        ref.invalidate(conversasProvider);
        await ref.read(conversasProvider(_filtro(1)).future);
      },
      child: ListView.separated(
        padding: const EdgeInsets.only(bottom: 90),
        itemCount: conversas.length + (temProxima || carregandoMais ? 1 : 0),
        separatorBuilder: (_, _) =>
            const Divider(height: 1, indent: 78, color: AppColors.border),
        itemBuilder: (context, indice) {
          if (indice == conversas.length) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: carregandoMais
                    ? const CircularProgressIndicator(color: AppColors.green)
                    : TextButton(
                        onPressed: () => setState(() => _paginas++),
                        child: const Text('Carregar mais'),
                      ),
              ),
            );
          }

          final conversa = conversas[indice];

          return ConversaTile(
            conversa: conversa,
            onTap: () => abrirConversa(context, ref, conversa),
          );
        },
      ),
    );
  }
}
