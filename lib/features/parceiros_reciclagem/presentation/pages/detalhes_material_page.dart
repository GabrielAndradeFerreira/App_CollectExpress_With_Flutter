import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/enums.dart';
import '../../../../core/navigation/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_logo.dart';
import '../../../../core/widgets/app_menu_drawer.dart';
import '../../../auth/data/sessao_provider.dart';

//botoes de navegação do rodapé
import '../../../../core/widgets/app_bottom_navigation.dart';

/// Informações sobre os materiais recicláveis e a porta de entrada para
/// sinalizar material (cliente e fornecedor) ou ver sinalizações (parceiro).
class DetalhesMaterialPage extends ConsumerWidget {
  const DetalhesMaterialPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final perfil = ref.watch(sessaoProvider).value?.tipoPerfil;
    final (textoDoBotao, rotaDoBotao) = switch (perfil) {
      TipoPerfil.parceiro => ('Ver sinalizações', AppRoutes.recyclingOffers),
      TipoPerfil.consumidor || TipoPerfil.cacambeiro => (
        'Sinalizar meu material',
        AppRoutes.recyclingMine,
      ),
      _ => ('Como funciona a coleta', AppRoutes.recyclingLanding),
    };

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      endDrawer: const AppMenuDrawer(),
      drawerScrimColor: const Color(0xD9000000),
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(child: _PageHeader()),
            const SliverToBoxAdapter(child: _HeroSection()),
            const SliverToBoxAdapter(child: _MaterialIntroduction()),
            const SliverToBoxAdapter(child: _AcceptedMaterialsSection()),
            const SliverToBoxAdapter(child: _EnvironmentalImpactSection()),
            SliverFillRemaining(
              hasScrollBody: false,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 4, 18, 40),
                    child: SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        key: const Key('material_cta'),
                        onPressed: () =>
                            Navigator.of(context).pushNamed(rotaDoBotao),
                        style: ElevatedButton.styleFrom(
                          elevation: 8,
                          shadowColor: Colors.black26,
                          backgroundColor: AppColors.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(11),
                          ),
                        ),
                        child: Text(
                          textoDoBotao,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const RecyclingBottomNavigation(
        aba: AbaReciclagem.inicio,
      ),
    );
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader();

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
                  'Reciclagem',
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

class _HeroSection extends StatelessWidget {
  const _HeroSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFF39953B),
      padding: const EdgeInsets.fromLTRB(18, 36, 18, 34),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Detalhes do material',
            style: TextStyle(
              color: Colors.white,
              fontSize: 31,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.8,
            ),
          ),
          SizedBox(height: 12),
          Text(
            'Entenda o que é aceito, o impacto ambiental e como sinalizar o '
            'seu material para um parceiro retirar.',
            style: TextStyle(color: Colors.white, fontSize: 17, height: 1.45),
          ),
        ],
      ),
    );
  }
}

class _MaterialIntroduction extends StatelessWidget {
  const _MaterialIntroduction();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(18, 34, 18, 34),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Garrafas PET',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          SizedBox(height: 8),
          Text(
            'O plástico PET leva até 400 anos para se decompor. Reciclar é '
            'transformar resíduos em novos produtos, reduzindo a poluição '
            'urbana.',
            style: TextStyle(color: Colors.black54, fontSize: 13, height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _AcceptedMaterialsSection extends StatelessWidget {
  const _AcceptedMaterialsSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFFF8F9FA),
        border: Border(
          top: BorderSide(color: Color(0xFFFFF0BD), width: 5),
          bottom: BorderSide(color: Color(0xFFFFF0BD), width: 5),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(18, 34, 18, 34),
      child: const Column(
        children: [
          _MaterialListCard(
            accepted: true,
            title: 'Tipos Aceitos',
            items: [
              'Garrafas de água e refrigerante',
              'Frascos de shampoo e cosméticos',
              'Embalagens de limpeza transparentes',
              'Recipientes alimentícios de PET',
            ],
          ),
          SizedBox(height: 16),
          _MaterialListCard(
            accepted: false,
            title: 'Não Aceitos',
            items: [
              'Plásticos metalizados (snack packs)',
              'Embalagens de óleo lubrificante',
              'Brinquedos ou plásticos rígidos mistos',
            ],
          ),
        ],
      ),
    );
  }
}

class _MaterialListCard extends StatelessWidget {
  final String title;
  final List<String> items;
  final bool accepted;

  const _MaterialListCard({
    required this.title,
    required this.items,
    required this.accepted,
  });

  @override
  Widget build(BuildContext context) {
    final color = accepted ? AppColors.green : Colors.red;
    final background = accepted
        ? const Color(0xFFFFF8DD)
        : const Color(0xFFFFF4D9);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(17),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 15,
                backgroundColor: background,
                child: Icon(
                  accepted ? Icons.check : Icons.close,
                  color: color,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    accepted ? Icons.check : Icons.cancel_outlined,
                    color: color,
                    size: 17,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item,
                      style: TextStyle(
                        color: accepted ? Colors.black87 : Colors.black54,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EnvironmentalImpactSection extends StatelessWidget {
  const _EnvironmentalImpactSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 34, 18, 32),
      decoration: const BoxDecoration(
        color: Color(0xFFF8F9FA),
        border: Border(bottom: BorderSide(color: Color(0xFFFFF0BD), width: 5)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Impacto Ambiental',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _ImpactCard(title: 'Economia de Energia', value: '70%'),
              ),
              SizedBox(width: 10),
              Expanded(
                child: _ImpactCard(title: 'Redução CO2', value: '60%'),
              ),
              SizedBox(width: 10),
              Expanded(
                child: _ImpactCard(
                  title: 'Tempo Decomposição',
                  value: '400 anos',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ImpactCard extends StatelessWidget {
  final String title;
  final String value;

  const _ImpactCard({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 75),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 13),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.green),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            maxLines: 2,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.black54, fontSize: 9),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.green,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

/*
REMOVENDO POIS O TRECHO ABAIXO FOI SUBSTITUIDO POR:
{
bottomNavigationBar: const SupplierBottomNavigation(
  currentIndex: 0,
),
}

class _AdminBottomNavigation extends StatelessWidget {
  const _AdminBottomNavigation();

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: 2,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: AppColors.green,
      unselectedItemColor: Colors.black54,
      selectedFontSize: 11,
      unselectedFontSize: 11,
      onTap: (index) {
        // Será conectado durante a etapa de navegação.
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          label: 'Início',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.people_outline),
          label: 'Usuários',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.local_shipping_outlined),
          label: 'Parceiros',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.attach_money),
          label: 'Finanças',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.settings_outlined),
          label: 'Config',
        ),
      ],
    );
  }
}
*/
