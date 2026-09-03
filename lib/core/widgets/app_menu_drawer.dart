import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'app_logo.dart';

class AppMenuDrawer extends StatelessWidget {
  const AppMenuDrawer({super.key});

  void _close(BuildContext context) {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;

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
                  const Expanded(child: AppLogo()),
                  IconButton(
                    onPressed: () => _close(context),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black54,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.close, size: 17),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: _AccountCard(
                onTap: () {
                  _close(context);
                  // Futuramente: abrir tela de login.
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
                      selected: true,
                      onTap: () => _close(context),
                    ),
                    AppDrawerItem(
                      icon: Icons.local_shipping_outlined,
                      title: 'SERVIÇOS',
                      onTap: () {
                        _close(context);
                        // Futuramente: navegar para Serviços.
                      },
                    ),
                    AppDrawerItem(
                      icon: Icons.grid_view_outlined,
                      title: 'MODELOS',
                      onTap: () {
                        _close(context);
                        // Futuramente: navegar para Modelos.
                      },
                    ),
                    AppDrawerItem(
                      icon: Icons.work_outline,
                      title: 'LOGIN',
                      onTap: () {
                        _close(context);
                        // Futuramente: navegar para Login.
                      },
                    ),
                  ],
                ),
              ),
            ),

            const AppDrawerFooter(),
          ],
        ),
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  final VoidCallback onTap;

  const _AccountCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFD7D7D7),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: const Color(0xFFA9A9A9),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.person_outline,
                  size: 44,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Olá, bem-vindo!',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      'Acesse sua conta',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
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

  const AppDrawerItem({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.selected = false,
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
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
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
                      fontSize: 21,
                      fontWeight: FontWeight.w700,
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
  const AppDrawerFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 10, 22, 22),
      child: Column(
        children: [
          const Divider(color: Colors.black38),
          const SizedBox(height: 18),

          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                // Futuramente: navegar para Cadastro.
              },
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: AppColors.yellow,
                foregroundColor: Colors.white,
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

          SizedBox(
            width: double.infinity,
            height: 54,
            child: OutlinedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Futuramente: navegar para Saiba Mais.
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.black,
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

          const SizedBox(height: 22),

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

          const SizedBox(height: 20),

          const Text(
            '☎  Suporte WhatsApp: (11) 99999-9999',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.orange, fontSize: 12),
          ),
          const SizedBox(height: 7),
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
