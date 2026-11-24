import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../features/auth/data/sessao_provider.dart';
import '../navigation/app_routes.dart';
import '../theme/app_colors.dart';

/// Logo do app. Tocar nele leva ao início do perfil logado (o painel do
/// fornecedor ou do admin, ou a página inicial do cliente).
class AppLogo extends ConsumerWidget {
  final VoidCallback? onTap;

  const AppLogo({super.key, this.onTap});

  Future<void> _goHome(BuildContext context, WidgetRef ref) async {
    // Espera a sessão carregar: lida antes disso, viria vazia e levaria o
    // fornecedor ou o admin para o início do cliente.
    String inicio;
    try {
      final usuario = await ref.read(sessaoProvider.future);
      inicio = AppRoutes.inicioDoPerfil(usuario?.tipoPerfil);
    } catch (_) {
      // Sem conseguir checar a sessão, trata como deslogado.
      inicio = AppRoutes.home;
    }

    if (!context.mounted) return;

    final currentRoute = ModalRoute.of(context)?.settings.name;

    if (currentRoute == inicio) {
      return;
    }

    Navigator.of(context).pushNamedAndRemoveUntil(inicio, (route) => false);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Tooltip(
        message: 'Ir para o início',
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap ?? () => _goHome(context, ref),
            hoverColor: AppColors.green.withValues(alpha: 0.08),
            splashColor: AppColors.green.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'COLLECT',
                    style: GoogleFonts.poppins(
                      fontSize: 28,
                      height: 1,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1.2,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(width: 42, height: 3, color: AppColors.green),
                      const SizedBox(width: 4),
                      Text(
                        'XPRESS',
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF77A644),
                          fontSize: 17,
                          height: 1,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
