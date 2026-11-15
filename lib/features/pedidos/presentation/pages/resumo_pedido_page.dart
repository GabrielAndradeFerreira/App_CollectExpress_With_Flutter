import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/carrinho.dart';
import '../../../../core/navigation/app_routes.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_logo.dart';
import '../../../../core/widgets/app_menu_drawer.dart';
import '../../../../core/widgets/async_value_view.dart';
import '../../../../core/widgets/cacamba_image.dart';
import '../carrinho_provider.dart';
import '../widgets/resumo_valores_card.dart';

import 'agendar_entrega_page.dart';

//botoes de navegação do rodapé
import '../../../../core/widgets/app_bottom_navigation.dart';

class ResumoPedidoPage extends ConsumerStatefulWidget {
  const ResumoPedidoPage({super.key});

  @override
  ConsumerState<ResumoPedidoPage> createState() => _ResumoPedidoPageState();
}

class _ResumoPedidoPageState extends ConsumerState<ResumoPedidoPage> {
  /// Itens com uma alteração em andamento na API.
  final _itensOcupados = <String>{};

  @override
  Widget build(BuildContext context) {
    final carrinho = ref.watch(carrinhoProvider);

    return Scaffold(
      drawerScrimColor: const Color(0xD9000000),
      endDrawer: const AppMenuDrawer(),
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                children: [
                  const _PageHeader(),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 4, 18, 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Resumo do seu Pedido',
                          style: TextStyle(
                            fontSize: 25,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.8,
                          ),
                        ),
                        const Text(
                          'Confirme os detalhes da locação',
                          style: TextStyle(color: Colors.black54, fontSize: 15),
                        ),
                        const SizedBox(height: 18),
                        AsyncValueView(
                          value: carrinho,
                          onRetry: () => ref.invalidate(carrinhoProvider),
                          data: _buildCarrinho,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [_SustainabilityFooter()],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const CustomerBottomNavigation(currentIndex: 2),
    );
  }

  Widget _buildCarrinho(Carrinho carrinho) {
    if (carrinho.isEmpty) return const _CarrinhoVazio();

    final temIndisponivel = carrinho.itens.any(
      (item) => item.cacamba?.disponivel == false,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final item in carrinho.itens) ...[
          _ItemCard(
            item: item,
            ocupado: _itensOcupados.contains(item.id),
            onQuantidade: (quantidade) =>
                _atualizarItem(item, quantidade: quantidade),
            onDias: (dias) => _atualizarItem(item, diasAluguel: dias),
            onRemover: () => _removerItem(item),
          ),
          const SizedBox(height: 14),
        ],
        const SizedBox(height: 14),
        const _SectionTitle('Resumo de Valores:'),
        const SizedBox(height: 10),
        ResumoValoresCard(resumo: carrinho.resumo),
        if (temIndisponivel) ...[
          const SizedBox(height: 12),
          const Text(
            'Remova os itens indisponíveis para continuar.',
            style: TextStyle(
              color: Colors.red,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 58,
          child: ElevatedButton(
            onPressed: _itensOcupados.isEmpty && !temIndisponivel
                ? _finalizarPedido
                : null,
            style: ElevatedButton.styleFrom(
              elevation: 0,
              backgroundColor: AppColors.green,
              disabledBackgroundColor: AppColors.green.withValues(alpha: 0.55),
              foregroundColor: Colors.white,
              disabledForegroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(11),
              ),
            ),
            child: const Text(
              'Finalizar Pedido',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _atualizarItem(
    ItemCarrinho item, {
    int? quantidade,
    int? diasAluguel,
  }) async {
    setState(() => _itensOcupados.add(item.id));

    try {
      await ref
          .read(carrinhoProvider.notifier)
          .atualizarItem(
            item.id,
            quantidade: quantidade,
            diasAluguel: diasAluguel,
          );
    } on ApiException catch (error) {
      if (mounted) showApiError(context, error);
    } finally {
      if (mounted) setState(() => _itensOcupados.remove(item.id));
    }
  }

  Future<void> _removerItem(ItemCarrinho item) async {
    setState(() => _itensOcupados.add(item.id));

    try {
      await ref.read(carrinhoProvider.notifier).removerItem(item.id);
    } on ApiException catch (error) {
      if (mounted) showApiError(context, error);
    } finally {
      if (mounted) setState(() => _itensOcupados.remove(item.id));
    }
  }

  void _finalizarPedido() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const AgendarEntregaPage()));
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
      child: Row(
        children: [
          const Expanded(child: AppLogo()),
          Builder(
            builder: (context) {
              return IconButton(
                tooltip: 'Abrir menu',
                onPressed: () => Scaffold.of(context).openEndDrawer(),
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

class _ItemCard extends StatelessWidget {
  final ItemCarrinho item;
  final bool ocupado;
  final ValueChanged<int> onQuantidade;
  final ValueChanged<int> onDias;
  final VoidCallback onRemover;

  const _ItemCard({
    required this.item,
    required this.ocupado,
    required this.onQuantidade,
    required this.onDias,
    required this.onRemover,
  });

  @override
  Widget build(BuildContext context) {
    final cacamba = item.cacamba;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.lightGray,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 115,
                  height: 115,
                  child: CacambaImage(
                    fotoUrl: cacamba?.fotoUrl,
                    tamanhoM3: cacamba?.tamanhoM3 ?? 0,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cacamba?.nome ?? 'Caçamba',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (cacamba != null) ...[
                      const SizedBox(height: 5),
                      Text(
                        '${cacamba.tipoResiduo} • '
                        '${formatVolume(cacamba.tamanhoM3)}',
                        style: const TextStyle(color: Colors.black54),
                      ),
                      Text(
                        '${formatMoney(cacamba.precoDiaria)} por dia',
                        style: const TextStyle(color: Colors.black54),
                      ),
                    ],
                    const SizedBox(height: 7),
                    Text(
                      formatMoney(item.subtotal),
                      style: const TextStyle(
                        color: AppColors.green,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (cacamba?.disponivel == false) ...[
                      const SizedBox(height: 4),
                      const Text(
                        'Indisponível no momento',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Remover do carrinho',
                onPressed: ocupado ? null : onRemover,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                color: Colors.red,
                icon: const Icon(Icons.delete_outline, size: 22),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: AppColors.border),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _Stepper(
                  titulo: 'Quantidade:',
                  texto: '${item.quantidade}',
                  valor: item.quantidade,
                  maximo: 10,
                  habilitado: !ocupado,
                  onChanged: onQuantidade,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _Stepper(
                  titulo: 'Período:',
                  texto: formatDias(item.diasAluguel),
                  valor: item.diasAluguel,
                  maximo: 30,
                  habilitado: !ocupado,
                  onChanged: onDias,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Stepper extends StatelessWidget {
  final String titulo;
  final String texto;
  final int valor;
  final int maximo;
  final bool habilitado;
  final ValueChanged<int> onChanged;

  const _Stepper({
    required this.titulo,
    required this.texto,
    required this.valor,
    required this.maximo,
    required this.habilitado,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(titulo, style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Container(
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Row(
            children: [
              IconButton(
                tooltip: 'Diminuir quantidade',
                onPressed: habilitado && valor > 1
                    ? () => onChanged(valor - 1)
                    : null,
                icon: const Icon(Icons.remove),
                color: AppColors.green,
              ),
              Expanded(
                child: Text(
                  texto,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              IconButton(
                tooltip: 'Aumentar quantidade',
                onPressed: habilitado && valor < maximo
                    ? () => onChanged(valor + 1)
                    : null,
                icon: const Icon(Icons.add),
                color: AppColors.green,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CarrinhoVazio extends StatelessWidget {
  const _CarrinhoVazio();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
      decoration: BoxDecoration(
        color: AppColors.lightGray,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.shopping_cart_outlined,
            size: 48,
            color: Colors.black38,
          ),
          const SizedBox(height: 12),
          const Text(
            'Seu carrinho está vazio',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          const Text(
            'Escolha uma caçamba para começar o seu pedido.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 18),
          ElevatedButton(
            onPressed: () =>
                Navigator.of(context)
                    .pushNamedAndRemoveUntil(AppRoutes.services, (_) => false),
            style: ElevatedButton.styleFrom(
              elevation: 0,
              backgroundColor: AppColors.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(11),
              ),
            ),
            child: const Text(
              'Ver caçambas',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
    );
  }
}

class _SustainabilityFooter extends StatelessWidget {
  const _SustainabilityFooter();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.sustainability,
      padding: const EdgeInsets.fromLTRB(18, 24, 18, 28),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.eco_outlined, color: AppColors.green),
              SizedBox(width: 8),
              Text(
                'Descarte Sustentável',
                style: TextStyle(
                  color: AppColors.green,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            'Todas as nossas caçambas seguem rigorosamente as normas '
            'ambientais municipais e resoluções do CONAMA. Garantimos o '
            'destino correto para o seu entulho.',
            style: TextStyle(color: Colors.black54, fontSize: 13, height: 1.5),
          ),
        ],
      ),
    );
  }
}
