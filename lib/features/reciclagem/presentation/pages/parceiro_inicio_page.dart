import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/reciclagem.dart';
import '../../../../core/navigation/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_bottom_navigation.dart';
import '../../../../core/widgets/async_value_view.dart';
import '../../../admin/presentation/pages/area_atendimento_page.dart';
import '../../../auth/data/sessao_provider.dart';
import '../reciclagem_providers.dart';
import '../widgets/reciclagem_widgets.dart';

/// Início do parceiro logado: o que falta cadastrar, resumo e atalhos.
class ParceiroInicioPage extends ConsumerWidget {
  const ParceiroInicioPage({super.key});

  Future<void> _atualizar(WidgetRef ref) async {
    ref.invalidate(resumoColetasProvider);
    ref.invalidate(pendenciasParceiroProvider);
    await ref.read(resumoColetasProvider.future);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usuario = ref.watch(sessaoProvider).value;
    final resumo = ref.watch(resumoColetasProvider);
    final pendencias = ref.watch(pendenciasParceiroProvider);

    return ReciclagemScaffold(
      aba: AbaReciclagem.inicio,
      child: RefreshIndicator(
        color: AppColors.green,
        onRefresh: () => _atualizar(ref),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 28),
          children: [
            TituloDaTela(
              'Olá, ${usuario?.nomeCompleto ?? 'parceiro'}',
              subtitulo: 'Acompanhe as sinalizações e coletas da sua empresa.',
            ),
            const SizedBox(height: 18),
            if (pendencias.value?.isNotEmpty ?? false)
              _Pendencias(pendencias: pendencias.value!),
            resumo.when(
              loading: () => const LoadingView(),
              error: (error, _) => ErrorView(
                error: error,
                onRetry: () => ref.invalidate(resumoColetasProvider),
              ),
              data: (dados) => _Resumo(resumo: dados),
            ),
            const SizedBox(height: 18),
            BotaoPrincipal(
              texto: 'Ver sinalizações perto de mim',
              icone: Icons.search,
              onPressed: () =>
                  Navigator.of(context).pushNamed(AppRoutes.recyclingOffers),
            ),
          ],
        ),
      ),
    );
  }
}

class _Resumo extends StatelessWidget {
  const _Resumo({required this.resumo});

  final ResumoColetas resumo;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _Numero(
                chave: 'resumo_abertas',
                valor: '${resumo.ofertasAbertas}',
                rotulo: 'Sinalizações abertas',
                icone: Icons.inventory_2_outlined,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _Numero(
                chave: 'resumo_agendadas',
                valor: '${resumo.agendadas}',
                rotulo: 'Coletas agendadas',
                icone: Icons.event_available_outlined,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _Numero(
                chave: 'resumo_concluidas',
                valor: '${resumo.concluidas}',
                rotulo: 'Coletas concluídas',
                icone: Icons.task_alt,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _Numero(
                chave: 'resumo_kg',
                valor: formatKg(resumo.kgColetados),
                rotulo: 'Material coletado',
                icone: Icons.scale_outlined,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Numero extends StatelessWidget {
  const _Numero({
    required this.chave,
    required this.valor,
    required this.rotulo,
    required this.icone,
  });

  final String chave;
  final String valor;
  final String rotulo;
  final IconData icone;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$rotulo: $valor',
      excludeSemantics: true,
      child: CartaoReciclagem(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icone, color: const Color(0xFF2F8334)),
            const SizedBox(height: 10),
            Text(
              valor,
              key: Key(chave),
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 2),
            Text(
              rotulo,
              style: const TextStyle(color: Colors.black54, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _Pendencias extends StatelessWidget {
  const _Pendencias({required this.pendencias});

  final List<PendenciaParceiro> pendencias;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: CartaoReciclagem(
        key: const Key('parceiro_pendencias'),
        borda: AppColors.yellow,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.info_outline, color: Color(0xFFB26A00)),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Complete seu cadastro',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            for (final pendencia in pendencias)
              _ItemPendencia(pendencia: pendencia),
          ],
        ),
      ),
    );
  }
}

class _ItemPendencia extends StatelessWidget {
  const _ItemPendencia({required this.pendencia});

  final PendenciaParceiro pendencia;

  @override
  Widget build(BuildContext context) {
    final (titulo, texto, acao) = switch (pendencia) {
      PendenciaParceiro.areaAtuacao => (
        'Área de atuação',
        'Marque no mapa até onde você coleta. Sem isso, você não vê '
            'sinalizações.',
        'Definir área',
      ),
      PendenciaParceiro.assinatura => (
        'Assinatura da empresa',
        'Envie a assinatura que vai no termo de coleta. Sem ela, você não '
            'consegue agendar.',
        'Enviar assinatura',
      ),
      PendenciaParceiro.materiais => (
        'Materiais que você coleta',
        'Escolha os tipos de material para ver as sinalizações certas.',
        'Escolher materiais',
      ),
    };

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
          TextButton(
            onPressed: () {
              final navigator = Navigator.of(context);

              if (pendencia == PendenciaParceiro.areaAtuacao) {
                navigator.push(
                  MaterialPageRoute<void>(
                    builder: (_) => const AreaAtendimentoPage(parceiro: true),
                  ),
                );
              } else {
                navigator.pushNamed(AppRoutes.recyclingProfile);
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF2F8334),
              minimumSize: const Size(48, 48),
              padding: EdgeInsets.zero,
              alignment: Alignment.centerLeft,
            ),
            child: Text(acao),
          ),
        ],
      ),
    );
  }
}
