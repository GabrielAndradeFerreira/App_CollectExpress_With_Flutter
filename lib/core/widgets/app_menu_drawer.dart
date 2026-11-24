import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/data/sessao_provider.dart';
import '../../features/pedidos/presentation/carrinho_provider.dart';
import '../accessibility/tamanho_texto.dart';
import '../models/enums.dart';
import '../models/usuario.dart';
import '../navigation/app_routes.dart';
import '../theme/app_colors.dart';
import 'app_logo.dart';

class AppMenuDrawer extends ConsumerWidget {
  const AppMenuDrawer({super.key});

  void _closeDrawer(BuildContext context) {
    Navigator.of(context).pop();
  }

  void _navigate(BuildContext context, String routeName) {
    final currentRoute = ModalRoute.of(context)?.settings.name;
    final navigator = Navigator.of(context);

    // Fecha o drawer.
    navigator.pop();

    // Não navega novamente se já estiver na rota selecionada.
    if (currentRoute == routeName) {
      return;
    }

    navigator.pushNamedAndRemoveUntil(routeName, (route) => false);
  }

  /// Painel ou perfil de cada tipo de conta.
  static String _areaDoPerfil(Usuario usuario) {
    return switch (usuario.tipoPerfil) {
      TipoPerfil.cacambeiro => AppRoutes.supplierHome,
      TipoPerfil.admin => AppRoutes.adminHome,
      TipoPerfil.parceiro => AppRoutes.recyclingHome,
      _ => AppRoutes.customerProfile,
    };
  }

  Future<void> _sair(BuildContext context, WidgetRef ref) async {
    // O context do drawer deixa de existir quando ele fecha.
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final sessao = ref.read(sessaoProvider.notifier);

    navigator.pop();

    try {
      await sessao.sair();
    } catch (_) {
      // sair() já apaga a sessão local mesmo se a API não responder.
    }

    messenger.showSnackBar(
      const SnackBar(
        content: Text('Você saiu da sua conta.'),
        backgroundColor: Colors.black87,
      ),
    );

    // Volta para a tela inicial (a página aberta pode ser de uma área que
    // só existe com login).
    navigator.pushNamedAndRemoveUntil(AppRoutes.home, (route) => false);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final currentRoute = ModalRoute.of(context)?.settings.name;
    final usuario = ref.watch(sessaoProvider).value;
    final isLoggedIn = usuario != null;
    final inicio = AppRoutes.inicioDoPerfil(usuario?.tipoPerfil);

    // Serviços e modelos são o catálogo do cliente. Fornecedor e admin
    // têm as próprias telas e não alugam caçambas.
    final mostraCatalogo =
        !(usuario?.isCacambeiro ?? false) && !(usuario?.isAdmin ?? false);

    // O carrinho fica salvo na API; o menu mostra quantas caçambas há nele
    // para o cliente voltar e concluir o pedido.
    final isConsumidor = usuario?.isConsumidor ?? false;
    final itensNoCarrinho = isConsumidor
        ? ref.watch(carrinhoProvider).value?.resumo.quantidadeItens ?? 0
        : 0;

    return Drawer(
      width: screenWidth * 0.85,
      elevation: 0,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 18, 12),
              child: Row(
                children: [
                  Expanded(
                    child: AppLogo(onTap: () => _navigate(context, inicio)),
                  ),
                  IconButton(
                    tooltip: 'Fechar menu',
                    onPressed: () => _closeDrawer(context),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black54,
                      foregroundColor: Colors.white,
                      hoverColor: Colors.black87,
                    ),
                    icon: const Icon(Icons.close, size: 17),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: _AccountCard(
                usuario: usuario,
                onTap: () {
                  if (usuario != null) {
                    _navigate(context, _areaDoPerfil(usuario));
                  } else {
                    final navigator = Navigator.of(context);
                    navigator.pop();
                    navigator.pushNamed(AppRoutes.login);
                  }
                },
              ),
            ),

            const SizedBox(height: 20),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: Column(
                  children: [
                    AppDrawerItem(
                      icon: Icons.home_outlined,
                      title: 'INÍCIO',
                      selected: currentRoute == inicio,
                      onTap: () => _navigate(context, inicio),
                    ),
                    if (mostraCatalogo) ...[
                      AppDrawerItem(
                        icon: Icons.local_shipping_outlined,
                        title: 'SERVIÇOS',
                        selected: currentRoute == AppRoutes.services,
                        onTap: () => _navigate(context, AppRoutes.services),
                      ),
                      AppDrawerItem(
                        icon: Icons.grid_view_outlined,
                        title: 'MODELOS',
                        selected: currentRoute == AppRoutes.models,
                        onTap: () => _navigate(context, AppRoutes.models),
                      ),
                    ],
                    if (usuario?.isParceiro ?? false) ...[
                      AppDrawerItem(
                        icon: Icons.recycling_outlined,
                        title: 'MEU PAINEL',
                        selected: currentRoute == AppRoutes.recyclingHome,
                        onTap: () => _navigate(context, AppRoutes.recyclingHome),
                      ),
                      AppDrawerItem(
                        icon: Icons.inventory_2_outlined,
                        title: 'SINALIZAÇÕES',
                        selected: currentRoute == AppRoutes.recyclingOffers,
                        onTap: () =>
                            _navigate(context, AppRoutes.recyclingOffers),
                      ),
                      AppDrawerItem(
                        icon: Icons.calendar_month_outlined,
                        title: 'MINHAS COLETAS',
                        selected: currentRoute == AppRoutes.recyclingCollections,
                        onTap: () =>
                            _navigate(context, AppRoutes.recyclingCollections),
                      ),
                    ] else if (!(usuario?.isAdmin ?? false))
                      AppDrawerItem(
                        icon: Icons.recycling_outlined,
                        title: usuario == null
                            ? 'RECICLAGEM'
                            : 'SINALIZAR MATERIAL',
                        selected:
                            currentRoute == AppRoutes.recyclingLanding ||
                            currentRoute == AppRoutes.recyclingMine,
                        onTap: () => _navigate(
                          context,
                          usuario == null
                              ? AppRoutes.recyclingLanding
                              : AppRoutes.recyclingMine,
                        ),
                      ),
                    if (isConsumidor) ...[
                      AppDrawerItem(
                        icon: Icons.shopping_cart_outlined,
                        title: 'MEU CARRINHO',
                        contador: itensNoCarrinho,
                        selected: currentRoute == AppRoutes.cart,
                        onTap: () => _navigate(context, AppRoutes.cart),
                      ),
                      AppDrawerItem(
                        icon: Icons.receipt_long_outlined,
                        title: 'MEUS PEDIDOS',
                        selected: currentRoute == AppRoutes.customerOrders,
                        onTap: () =>
                            _navigate(context, AppRoutes.customerOrders),
                      ),
                    ],
                    if (usuario?.isCacambeiro ?? false) ...[
                      AppDrawerItem(
                        icon: Icons.storefront_outlined,
                        title: 'MEU PAINEL',
                        selected: currentRoute == AppRoutes.supplierHome,
                        onTap: () => _navigate(context, AppRoutes.supplierHome),
                      ),
                      AppDrawerItem(
                        icon: Icons.assignment_outlined,
                        title: 'GESTÃO PEDIDOS',
                        selected: currentRoute == AppRoutes.supplierOrders,
                        onTap: () =>
                            _navigate(context, AppRoutes.supplierOrders),
                      ),
                    ],
                    if (usuario?.isAdmin ?? false) ...[
                      AppDrawerItem(
                        icon: Icons.admin_panel_settings_outlined,
                        title: 'PAINEL ADMIN',
                        selected: currentRoute == AppRoutes.adminHome,
                        onTap: () => _navigate(context, AppRoutes.adminHome),
                      ),
                      AppDrawerItem(
                        icon: Icons.settings_outlined,
                        title: 'CONFIGURAÇÕES',
                        selected: currentRoute == AppRoutes.adminSettings,
                        onTap: () => _navigate(context, AppRoutes.adminSettings),
                      ),
                    ],
                    if (isLoggedIn)
                      AppDrawerItem(
                        icon: Icons.chat_bubble_outline,
                        title: 'CONVERSAS',
                        selected: currentRoute == AppRoutes.chat,
                        onTap: () => _navigate(context, AppRoutes.chat),
                      ),
                    AppDrawerItem(
                      icon: Icons.text_fields,
                      title: 'TAMANHO DO TEXTO',
                      onTap: () {
                        // O context do drawer deixa de existir ao fechar.
                        final navigator = Navigator.of(context);
                        navigator.pop();
                        mostrarTamanhoTexto(navigator.context);
                      },
                    ),
                    if (!isLoggedIn)
                      AppDrawerItem(
                        icon: Icons.login_outlined,
                        title: 'LOGIN',
                        selected: currentRoute == AppRoutes.login,
                        onTap: () => _navigate(context, AppRoutes.login),
                      ),
                    if (isLoggedIn)
                      AppDrawerItem(
                        icon: Icons.logout_rounded,
                        title: 'SAIR',
                        onTap: () => _sair(context, ref),
                      ),
                  ],
                ),
              ),
            ),

            AppDrawerFooter(
              isLoggedIn: isLoggedIn,
              onRegister: () => _navigate(context, AppRoutes.register),
              onAbout: () => _navigate(context, AppRoutes.about),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  final Usuario? usuario;
  final VoidCallback onTap;

  const _AccountCard({required this.usuario, required this.onTap});

  String _formatProfile(TipoPerfil? tipoPerfil) {
    return switch (tipoPerfil) {
      TipoPerfil.admin => 'Administrador',
      TipoPerfil.cacambeiro => 'Fornecedor de Caçambas',
      TipoPerfil.consumidor => 'Cliente',
      TipoPerfil.parceiro => 'Parceiro de Reciclagem',
      null => 'Usuário Conectado',
    };
  }

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = usuario != null;
    final userName = usuario?.nomeCompleto ?? 'Usuário';
    final profileLabel = _formatProfile(usuario?.tipoPerfil);

    return Material(
      color: const Color(0xFFD7D7D7),
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        hoverColor: Colors.black.withValues(alpha: 0.06),
        splashColor: AppColors.green.withValues(alpha: 0.15),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: isLoggedIn ? AppColors.green : const Color(0xFFA9A9A9),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  isLoggedIn ? Icons.verified_user_rounded : Icons.person_outline,
                  size: 38,
                  color: isLoggedIn ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isLoggedIn ? 'Olá, $userName' : 'Olá, bem-vindo!',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isLoggedIn ? profileLabel : 'Acesse sua conta',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isLoggedIn ? AppColors.green : Colors.black87,
                      ),
                    ),
                  ],
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

class AppDrawerItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool selected;
  final VoidCallback onTap;

  /// Número ao lado do título (ex.: itens no carrinho). Zero não aparece.
  final int contador;

  const AppDrawerItem({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.selected = false,
    this.contador = 0,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.green : Colors.black;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: selected
            ? AppColors.green.withValues(alpha: 0.13)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          hoverColor: AppColors.green.withValues(alpha: 0.09),
          splashColor: AppColors.green.withValues(alpha: 0.18),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
            child: Row(
              children: [
                Icon(icon, color: color, size: 27),
                const SizedBox(width: 15),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: color,
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (contador > 0)
                  Container(
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.green,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$contador',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                Icon(Icons.chevron_right, color: color, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AppDrawerFooter extends StatelessWidget {
  final bool isLoggedIn;
  final VoidCallback onRegister;
  final VoidCallback onAbout;

  const AppDrawerFooter({
    super.key,
    this.isLoggedIn = false,
    required this.onRegister,
    required this.onAbout,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 10, 22, 22),
      child: Column(
        children: [
          const Divider(color: Colors.black38),
          const SizedBox(height: 18),
          if (!isLoggedIn) ...[
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: onRegister,
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: AppColors.yellow,
                  foregroundColor: Colors.black,
                  overlayColor: Colors.black.withValues(alpha: 0.08),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(9),
                  ),
                ),
                icon: const Icon(Icons.person_add_alt_1_outlined),
                label: const Text(
                  'CADASTRE-SE',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                ),
              ),
            ),
            const SizedBox(height: 10),
            // "Saiba mais" apresenta o app para quem ainda não tem conta.
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton(
                onPressed: onAbout,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.black,
                  overlayColor: AppColors.green.withValues(alpha: 0.09),
                  side: const BorderSide(color: Colors.black, width: 1.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(9),
                  ),
                ),
                child: const Text(
                  'SAIBA MAIS',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F8F0),
              border: Border.all(color: AppColors.green, width: 0.7),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.eco_outlined, color: AppColors.green, size: 19),
                    SizedBox(width: 5),
                    Text(
                      'Descarte Sustentável',
                      style: TextStyle(
                        color: AppColors.green,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 5),
                Text(
                  'Todas as nossas caçambas seguem rigorosamente '
                  'as normas ambientais municipais.',
                  style: TextStyle(fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            '☎  Suporte WhatsApp: (11) 99999-9999',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.orange, fontSize: 12),
          ),
          const SizedBox(height: 6),
          const Text(
            'Collect Express © 2026. Todos os direitos reservados.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black54, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
