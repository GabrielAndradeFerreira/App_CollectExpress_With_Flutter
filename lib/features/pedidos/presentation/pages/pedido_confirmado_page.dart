import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/aluguel.dart';
import '../../../../core/models/enums.dart';
import '../../../../core/navigation/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_logo.dart';
import '../../../../core/widgets/app_menu_drawer.dart';
import '../pedidos_format.dart';

//botoes de navegação do rodapé
import '../../../../core/widgets/app_bottom_navigation.dart';

import 'acompanhar_pedido_page.dart';
import 'pagamento_pix_page.dart';

class PedidoConfirmadoPage extends ConsumerWidget {
  /// Pedido devolvido pelo checkout.
  final Aluguel pedido;

  const PedidoConfirmadoPage({super.key, required this.pedido});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // O checkout não devolve o código nem os itens do pedido. O detalhe
    // traz os dois; se ele falhar, fica com os dados do checkout.
    final dados = ref.watch(pedidoDetalheProvider(pedido.id)).value ?? pedido;
    final endereco = dados.endereco ?? pedido.endereco;
    final itens = dados.itens.isNotEmpty ? dados.itens : pedido.itens;

    final resumo = <_SummaryItem>[
      _SummaryItem(
        icon: Icons.calendar_month_outlined,
        label: 'Data de Início:',
        value: formatDate(dados.dataInicio),
      ),
      if (endereco != null)
        _SummaryItem(
          icon: Icons.location_on_outlined,
          label: 'Endereço:',
          value: '${endereco.ruaENumero} - ${endereco.cidadeEstado}',
        ),
      if (itens.isNotEmpty)
        _SummaryItem(
          icon: Icons.local_shipping_outlined,
          label: itens.length == 1
              ? 'Caçamba Selecionada:'
              : 'Caçambas Selecionadas:',
          value: itens
              .map(
                (item) =>
                    '${item.cacamba?.nome ?? 'Caçamba'} '
                    '(Quantidade: ${item.quantidade})',
              )
              .join('\n'),
        ),
      _SummaryItem(
        icon: Icons.schedule,
        label: 'Período de Locação:',
        value: formatDias(dados.diasAluguel),
      ),
      _SummaryItem(
        icon: Icons.payments_outlined,
        label: 'Valor Total:',
        value: formatMoney(dados.precoFinal),
      ),
      _SummaryItem(
        icon: Icons.credit_card_outlined,
        label: 'Pagamento:',
        value: dados.statusPagamento?.label ?? '-',
      ),
    ];

    return Scaffold(
      drawerScrimColor: const Color(0xD9000000),
      endDrawer: const AppMenuDrawer(),
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(child: _PageHeader()),
            SliverToBoxAdapter(
              child: _ConfirmationBanner(codigo: dados.codigo),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 28, 18, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Resumo da Entrega:',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _DeliverySummary(itens: resumo),
                    const SizedBox(height: 26),
                    const Center(
                      child: Text(
                        'Acompanhe o status da entrega e o contato do '
                        'fornecedor na tela do pedido.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.black54, fontSize: 13),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (dados.statusPagamento == StatusPagamento.pendente) ...[
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton.icon(
                          onPressed: () => _pagar(context, ref),
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            backgroundColor: const Color(0xFF32BCAD),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(9),
                            ),
                          ),
                          icon: const Icon(Icons.pix),
                          label: const Text(
                            'Pagar com Pix',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: () => _trackOrder(context),
                        style: ElevatedButton.styleFrom(
                          elevation: 0,
                          backgroundColor: AppColors.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(9),
                          ),
                        ),
                        child: const Text(
                          'Acompanhar Pedido',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: OutlinedButton(
                        onPressed: () => _goHome(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.black,
                          side: const BorderSide(
                            color: Colors.black,
                            width: 1.3,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(9),
                          ),
                        ),
                        child: const Text(
                          'Voltar para o Início',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
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

  Future<void> _pagar(BuildContext context, WidgetRef ref) async {
    await Navigator.of(context).push(
      MaterialPageRoute<bool>(
        builder: (_) => PagamentoPixPage(aluguelId: pedido.id),
      ),
    );

    ref.invalidate(pedidoDetalheProvider(pedido.id));
  }

  void _trackOrder(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AcompanharPedidoPage(aluguelId: pedido.id),
      ),
    );
  }

  void _goHome(BuildContext context) {
    Navigator.of(context)
        .pushNamedAndRemoveUntil(AppRoutes.home, (route) => false);
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
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

class _ConfirmationBanner extends StatelessWidget {
  final String? codigo;

  const _ConfirmationBanner({required this.codigo});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.sustainability,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 44),
      child: Column(
        children: [
          const CircleAvatar(
            radius: 43,
            backgroundColor: AppColors.green,
            child: Icon(Icons.check, color: Colors.white, size: 42),
          ),
          const SizedBox(height: 20),
          const Text(
            'Pedido Confirmado!',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.green,
              fontSize: 28,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.8,
            ),
          ),
          if (codigo != null) ...[
            const SizedBox(height: 12),
            RichText(
              text: TextSpan(
                style: const TextStyle(color: Colors.black54, fontSize: 15),
                children: [
                  const TextSpan(text: 'Nº do pedido: '),
                  TextSpan(
                    text: codigo,
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DeliverySummary extends StatelessWidget {
  final List<_SummaryItem> itens;

  const _DeliverySummary({required this.itens});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.lightGray,
        borderRadius: BorderRadius.circular(17),
      ),
      child: Column(
        children: [
          for (var i = 0; i < itens.length; i++) ...[
            if (i > 0) const SizedBox(height: 16),
            itens[i],
          ],
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _SummaryItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.green, size: 23),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: Colors.black54, fontSize: 12),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
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
/*
REMOVENDO POIS O TRECHO ABAIXO FOI SUBSTITUIDO POR:
{
bottomNavigationBar: const SupplierBottomNavigation(
  currentIndex: 2,
),
}

class _BottomNavigation extends StatelessWidget {
  const _BottomNavigation();

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: 2,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: AppColors.green,
      unselectedItemColor: Colors.black54,
      onTap: (_) {},
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          label: 'Início',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.delete_outline),
          label: 'Caçambas',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.list_alt_outlined),
          label: 'Pedidos',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          label: 'Perfil',
        ),
      ],
    );
  }
}
*/
