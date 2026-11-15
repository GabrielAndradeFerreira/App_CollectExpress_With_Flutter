import 'package:flutter/material.dart';

import '../../../../core/navigation/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_bottom_navigation.dart';
import '../../../../core/widgets/app_logo.dart';
import '../../../../core/widgets/app_menu_drawer.dart';

class SaibaMaisPage extends StatelessWidget {
  const SaibaMaisPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      endDrawer: const AppMenuDrawer(),
      drawerScrimColor: const Color(0xD9000000),
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(child: _PageHeader()),
            const SliverToBoxAdapter(child: _HeroSection()),
            const SliverToBoxAdapter(child: _AboutSection()),
            const SliverToBoxAdapter(child: _BenefitsSection()),
            const SliverToBoxAdapter(child: _HowItWorksSection()),
            const SliverToBoxAdapter(child: _ServicesSection()),
            const SliverToBoxAdapter(child: _SustainabilitySection()),
            const SliverToBoxAdapter(child: _FinalCallToAction()),
          ],
        ),
      ),
      bottomNavigationBar: const CustomerBottomNavigation(currentIndex: 0),
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
          IconButton(
            tooltip: 'Ver serviços',
            onPressed: () {
              Navigator.of(
                context,
              ).pushNamedAndRemoveUntil(AppRoutes.services, (route) => false);
            },
            style: IconButton.styleFrom(
              foregroundColor: Colors.black,
              minimumSize: const Size(48, 48),
            ),
            icon: const Icon(Icons.local_shipping, size: 31),
          ),
          const SizedBox(width: 8),
          Builder(
            builder: (scaffoldContext) {
              return IconButton(
                tooltip: 'Abrir menu',
                onPressed: () {
                  Scaffold.of(scaffoldContext).openEndDrawer();
                },
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.lightGray,
                  foregroundColor: Colors.black,
                  hoverColor: AppColors.green.withValues(alpha: 0.12),
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
      color: AppColors.yellow,
      padding: const EdgeInsets.fromLTRB(24, 34, 24, 38),
      child: Column(
        children: [
          const Text(
            'Conectando Caçambeiros e Clientes',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 31,
              height: 1.15,
              fontWeight: FontWeight.w900,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Encontre serviços de remoção de entulho de forma '
            'fácil, segura e rápida.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, height: 1.35),
          ),
          const SizedBox(height: 22),
          SizedBox(
            width: 280,
            height: 56,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushNamed(AppRoutes.register);
              },
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: AppColors.green,
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.black54),
                overlayColor: Colors.black.withValues(alpha: 0.08),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Cadastre-se Agora',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AboutSection extends StatelessWidget {
  const _AboutSection();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 32, 18, 28),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 700;

          final textContent = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'COLLECT\nEXPRESS',
                style: TextStyle(
                  fontSize: 46,
                  height: 0.9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -2,
                ),
              ),
              const SizedBox(height: 22),
              const Text(
                'A Collect Express conecta clientes a fornecedores '
                'especializados em locação de caçambas, coleta e destinação '
                'correta de resíduos.',
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: 14,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Você solicita, acompanha o pedido em tempo real e conta '
                'com parceiros avaliados e comprometidos com as normas '
                'ambientais.',
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: 13,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 18),
              OutlinedButton(
                onPressed: () {
                  Navigator.of(context).pushNamed(AppRoutes.services);
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.black,
                  side: BorderSide.none,
                  shape: const StadiumBorder(),
                ),
                child: const Text(
                  'CONHECER SERVIÇOS',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          );

          final image = ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: AspectRatio(
              aspectRatio: 1.45,
              child: Image.asset(
                'assets/images/cacamba_sobre.jpg',
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) {
                  return Container(
                    color: AppColors.lightGray,
                    child: const Center(
                      child: Icon(
                        Icons.local_shipping_outlined,
                        size: 90,
                        color: Colors.black38,
                      ),
                    ),
                  );
                },
              ),
            ),
          );

          if (isWide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(child: textContent),
                const SizedBox(width: 28),
                Expanded(child: image),
              ],
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [textContent, const SizedBox(height: 24), image],
          );
        },
      ),
    );
  }
}

class _BenefitsSection extends StatelessWidget {
  const _BenefitsSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFFF8F9FA),
      padding: const EdgeInsets.fromLTRB(18, 30, 18, 34),
      child: Column(
        children: [
          const Text(
            'O QUE OFERECEMOS?',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.black54,
              fontSize: 25,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 22),
          LayoutBuilder(
            builder: (context, constraints) {
              final itemWidth = constraints.maxWidth >= 700
                  ? (constraints.maxWidth - 32) / 3
                  : constraints.maxWidth;

              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  SizedBox(
                    width: itemWidth,
                    child: const _BenefitCard(
                      icon: Icons.bar_chart,
                      title: 'Eficiência Operacional',
                      description:
                          'Acompanhe suas caçambas e pedidos em tempo real.',
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: const _BenefitCard(
                      icon: Icons.verified_user_outlined,
                      title: 'Transparência e Segurança',
                      description:
                          'Parceiros avaliados, pagamentos seguros e suporte.',
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: const _BenefitCard(
                      icon: Icons.schedule,
                      title: 'Agendamento Simplificado',
                      description:
                          'Escolha a caçamba, a data e o período de entrega.',
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _BenefitCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _BenefitCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 145),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x18000000),
            blurRadius: 12,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.green, size: 32),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 7),
          Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 11,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _HowItWorksSection extends StatelessWidget {
  const _HowItWorksSection();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(18, 38, 18, 38),
      child: Column(
        children: [
          Text(
            'DEIXE TUDO MAIS FÁCIL',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.black54,
              fontSize: 23,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'COM A COLLECT XPRESS',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.green,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 26),
          _ProcessItem(
            number: '1',
            title: 'Escolha o serviço',
            description: 'Selecione o tipo e o tamanho da caçamba ideal.',
          ),
          SizedBox(height: 12),
          _ProcessItem(
            number: '2',
            title: 'Informe o endereço',
            description: 'Consulte a disponibilidade para sua região.',
          ),
          SizedBox(height: 12),
          _ProcessItem(
            number: '3',
            title: 'Agende e acompanhe',
            description: 'Defina a entrega e acompanhe o andamento do pedido.',
          ),
        ],
      ),
    );
  }
}

class _ProcessItem extends StatelessWidget {
  final String number;
  final String title;
  final String description;

  const _ProcessItem({
    required this.number,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: AppColors.lightGray,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 21,
            backgroundColor: AppColors.green,
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: const TextStyle(color: Colors.black54, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ServicesSection extends StatelessWidget {
  const _ServicesSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFFF8F9FA),
      padding: const EdgeInsets.fromLTRB(18, 34, 18, 38),
      child: Column(
        children: [
          const Text(
            'NOSSOS SERVIÇOS',
            style: TextStyle(
              color: Colors.black54,
              fontSize: 27,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 22),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth >= 760
                  ? (constraints.maxWidth - 32) / 3
                  : constraints.maxWidth;

              return Wrap(
                alignment: WrapAlignment.center,
                spacing: 16,
                runSpacing: 16,
                children: [
                  SizedBox(
                    width: width,
                    child: _ServiceCard(
                      icon: Icons.delete_outline,
                      title: 'Caçamba Pequena',
                      volume: '3m³',
                      description:
                          'Ideal para pequenas obras, reformas e entulho leve.',
                      onTap: () => _openServices(context),
                    ),
                  ),
                  SizedBox(
                    width: width,
                    child: _ServiceCard(
                      icon: Icons.construction_outlined,
                      title: 'Caçamba Média',
                      volume: '5m³',
                      //featured: true,
                      description: 'Indicada para reformas médias e demolições parciais.',
                      onTap: () => _openServices(context),
                    ),
                  ),
                  SizedBox(
                    width: width,
                    child: _ServiceCard(
                      icon: Icons.local_shipping_outlined,
                      title: 'Caçamba Grande',
                      volume: '7m³',
                      description:
                          'Para grandes obras e volumes elevados de resíduos.',
                      onTap: () => _openServices(context),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  void _openServices(BuildContext context) {
    Navigator.of(context).pushNamed(AppRoutes.services);
  }
}

class _ServiceCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String volume;
  final String description;
  final VoidCallback onTap;

  const _ServiceCard({
    required this.icon,
    required this.title,
    required this.volume,
    required this.description,
    required this.onTap,
  });

  @override
  State<_ServiceCard> createState() => _ServiceCardState();
}

class _ServiceCardState extends State<_ServiceCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final highlightColor = _isHovered ? AppColors.green : Colors.black87;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        height: 275,
        padding: const EdgeInsets.all(20),
        transform: Matrix4.translationValues(0, _isHovered ? -6 : 0, 0),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: _isHovered ? AppColors.green : AppColors.border,
            width: _isHovered ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: _isHovered
              ? [
                  BoxShadow(
                    color: AppColors.green.withValues(alpha: 0.22),
                    blurRadius: 22,
                    offset: const Offset(0, 10),
                  ),
                ]
              : const [
                  BoxShadow(
                    color: Color(0x10000000),
                    blurRadius: 8,
                    offset: Offset(0, 3),
                  ),
                ],
        ),
        child: Column(
          children: [
            AnimatedScale(
              duration: const Duration(milliseconds: 180),
              scale: _isHovered ? 1.1 : 1,
              child: Icon(widget.icon, size: 58, color: highlightColor),
            ),
            const SizedBox(height: 16),
            Text(
              widget.title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _isHovered ? AppColors.green : Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              widget.volume,
              style: TextStyle(
                color: _isHovered ? AppColors.green : Colors.black54,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: Text(
                widget.description,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.black54,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ),
            SizedBox(
              width: double.infinity,
              height: 40,
              child: ElevatedButton(
                onPressed: widget.onTap,
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: _isHovered ? AppColors.green : Colors.black,
                  foregroundColor: Colors.white,
                  overlayColor: Colors.white.withValues(alpha: 0.15),
                  shape: const StadiumBorder(),
                ),
                child: const Text(
                  'VER OPÇÕES',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SustainabilitySection extends StatelessWidget {
  const _SustainabilitySection();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.sustainability,
      padding: const EdgeInsets.fromLTRB(18, 30, 18, 32),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.eco_outlined, color: AppColors.green, size: 27),
              SizedBox(width: 9),
              Text(
                'Compromisso Ambiental',
                style: TextStyle(
                  color: AppColors.green,
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          SizedBox(height: 13),
          Text(
            'Trabalhamos com fornecedores comprometidos com a destinação '
            'correta dos resíduos e com o cumprimento das normas ambientais '
            'municipais e das resoluções do CONAMA.',
            style: TextStyle(color: Colors.black54, fontSize: 13, height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _FinalCallToAction extends StatelessWidget {
  const _FinalCallToAction();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 34, 18, 40),
      child: Column(
        children: [
          const Text(
            'Pronto para começar?',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          const Text(
            'Encontre agora a caçamba ideal para sua necessidade.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black54, fontSize: 14),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushNamed(AppRoutes.services);
              },
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: AppColors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(11),
                ),
              ),
              child: const Text(
                'VER CAÇAMBAS DISPONÍVEIS',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: OutlinedButton(
              onPressed: () {
                Navigator.of(context).pushNamed(AppRoutes.login);
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.black,
                side: const BorderSide(color: Colors.black),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(11),
                ),
              ),
              child: const Text(
                'JÁ TENHO UMA CONTA',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
