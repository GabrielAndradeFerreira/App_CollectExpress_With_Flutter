import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../area_atendimento_providers.dart';
import '../pages/area_atendimento_page.dart';

/// Card do perfil da loja com a cerca virtual atual e o atalho para
/// desenhá-la no mapa.
class AreaAtendimentoCard extends ConsumerWidget {
  const AreaAtendimentoCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final area = ref.watch(areaAtendimentoProvider);
    final atual = area.value;
    final definida = atual?.definida ?? false;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Área de atendimento',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          const Text(
            'Marque no mapa até onde você entrega. Só clientes dentro dessa '
            'área conseguem alugar suas caçambas; os demais podem apenas '
            'falar com você.',
            style: TextStyle(color: Colors.black54, fontSize: 12, height: 1.4),
          ),
          const SizedBox(height: 12),
          if (area.isLoading && atual == null)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else if (area.hasError)
            const Text(
              'Não foi possível carregar a área atual.',
              style: TextStyle(color: Colors.red, fontSize: 12),
            )
          else
            Text(
              definida
                  ? 'Atendendo num raio de ${atual!.raioKm?.round() ?? '-'} km '
                        'ao redor do ponto marcado.'
                  : 'Área ainda não definida: suas caçambas aparecem para '
                        'clientes de qualquer região.',
              key: const Key('area_atendimento_resumo'),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: definida ? AppColors.green : const Color(0xFFB26A00),
              ),
            ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            key: const Key('area_atendimento_abrir'),
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const AreaAtendimentoPage(),
                ),
              );
              ref.invalidate(areaAtendimentoProvider);
            },
            icon: const Icon(Icons.map_outlined, size: 19),
            label: Text(definida ? 'Alterar área' : 'Definir área no mapa'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.green,
              side: const BorderSide(color: AppColors.green),
            ),
          ),
        ],
      ),
    );
  }
}
