import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/area_atendimento.dart';
import '../../../../core/navigation/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/data/sessao_provider.dart';
import '../../data/fornecedor_repository.dart';
import '../area_atendimento_providers.dart';
import '../pages/area_atendimento_page.dart';

/// Não desenha nada. Ao entrar no painel, se o fornecedor ainda não
/// definiu a área de atendimento ou não enviou a assinatura da empresa,
/// abre um aviso (uma vez por sessão) levando até onde resolver.
class AvisoPendenciasFornecedor extends ConsumerStatefulWidget {
  const AvisoPendenciasFornecedor({super.key});

  @override
  ConsumerState<AvisoPendenciasFornecedor> createState() =>
      _AvisoPendenciasFornecedorState();
}

class _AvisoPendenciasFornecedorState
    extends ConsumerState<AvisoPendenciasFornecedor> {
  bool _consultando = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _verificar());
  }

  Future<void> _verificar() async {
    if (!mounted || _consultando) return;

    final sessao = ref.read(sessaoProvider);
    final usuario = sessao.value;

    // Sessão ainda carregando: tenta de novo quando ela chegar.
    if (usuario == null || !usuario.isCacambeiro) return;
    if (ref.read(avisoPendenciasMostradoProvider)) return;

    _consultando = true;

    try {
      final pendencias = await ref
          .read(fornecedorRepositoryProvider)
          .pendencias();

      if (!mounted || ref.read(avisoPendenciasMostradoProvider)) return;
      if (!pendencias.temPendencias) return;

      ref.read(avisoPendenciasMostradoProvider.notifier).marcar();
      await _mostrar(pendencias);
    } catch (_) {
      // Sem rede ou sem permissão: o aviso fica para a próxima vez.
    } finally {
      _consultando = false;
    }
  }

  Future<void> _mostrar(PendenciasFornecedor pendencias) async {
    final semArea = pendencias.pendencias.contains(
      PendenciaFornecedor.areaAtendimento,
    );
    final semAssinatura = pendencias.pendencias.contains(
      PendenciaFornecedor.assinatura,
    );

    final resolver = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Complete seu cadastro'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (semArea)
              const _ItemPendencia(
                titulo: 'Área de atendimento',
                texto:
                    'Marque no mapa até onde você entrega. Sem isso, suas '
                    'caçambas aparecem para clientes de qualquer região.',
              ),
            if (semAssinatura)
              const _ItemPendencia(
                titulo: 'Assinatura da empresa',
                texto:
                    'Envie a assinatura que aparece nos contratos de '
                    'locação.',
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Depois'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.green,
              foregroundColor: Colors.white,
            ),
            child: Text(semArea ? 'Definir área' : 'Enviar assinatura'),
          ),
        ],
      ),
    );

    if (resolver != true || !mounted) return;

    final navigator = Navigator.of(context);

    if (semArea) {
      await navigator.push(
        MaterialPageRoute<void>(builder: (_) => const AreaAtendimentoPage()),
      );
    } else {
      await navigator.pushNamed(AppRoutes.supplierProfile);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Quando a sessão carrega depois da tela, confere de novo.
    ref.listen(sessaoProvider, (_, _) => _verificar());

    return const SizedBox.shrink();
  }
}

class _ItemPendencia extends StatelessWidget {
  const _ItemPendencia({required this.titulo, required this.texto});

  final String titulo;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titulo, style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(
            texto,
            style: const TextStyle(color: Colors.black54, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
