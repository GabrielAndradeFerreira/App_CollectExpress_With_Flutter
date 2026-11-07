import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/area_atendimento.dart';
import '../../../../core/models/cacamba.dart';
import '../../../../core/models/cacambeiro.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_logo.dart';
import '../../../../core/navigation/app_routes.dart';
import '../../../../core/widgets/async_value_view.dart';
import '../../../../core/widgets/cacamba_image.dart';
import '../../../auth/presentation/garantir_login.dart';
import '../../../pedidos/data/carrinho_repository.dart';

import '../../../pedidos/presentation/carrinho_provider.dart';
import '../../../pedidos/presentation/pages/resumo_pedido_page.dart';
import '../../data/catalogo_repository.dart';
import '../local_entrega_provider.dart';

//botoes de navegação do rodapé
import '../../../../core/widgets/app_bottom_navigation.dart';

typedef _Consulta = ({String id, LocalEntrega? local});

final _cacambaProvider = FutureProvider.autoDispose.family<Cacamba, _Consulta>((
  ref,
  consulta,
) {
  return ref
      .watch(catalogoRepositoryProvider)
      .detalheCacamba(consulta.id, local: consulta.local);
});

class CacambaDetailsPage extends ConsumerStatefulWidget {
  const CacambaDetailsPage({super.key, required this.cacambaId});

  final String cacambaId;

  @override
  ConsumerState<CacambaDetailsPage> createState() => _CacambaDetailsPageState();
}

class _CacambaDetailsPageState extends ConsumerState<CacambaDetailsPage> {
  // Limites da API para itens do carrinho.
  static const _quantidadeMaxima = 10;

  int quantity = 1;
  int selectedDays = 3;
  bool _adicionando = false;

  @override
  Widget build(BuildContext context) {
    final provider = _cacambaProvider((
      id: widget.cacambaId,
      local: ref.watch(localEntregaProvider),
    ));

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          child: Column(
            children: [
              const _DetailsHeader(),
              AsyncValueView(
                value: ref.watch(provider),
                onRetry: () => ref.invalidate(provider),
                data: _buildContent,
              ),
              const _SustainabilityFooter(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const CustomerBottomNavigation(currentIndex: 1),
    );
  }

  Widget _buildContent(Cacamba cacamba) {
    return Column(
      children: [
        AspectRatio(
          aspectRatio: 1.75,
          child: CacambaImage(
            fotoUrl: cacamba.fotoUrl,
            tamanhoM3: cacamba.tamanhoM3,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 22, 18, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ProductTitle(cacamba: cacamba),
              const SizedBox(height: 14),
              const Divider(),
              const SizedBox(height: 14),
              const Text(
                'Especificações:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              Text(
                'Caçamba de ${formatVolume(cacamba.tamanhoM3)} para '
                '${cacamba.tipoResiduo.toLowerCase()}. '
                '${cacamba.disponivel ? 'Disponível para locação.' : 'Indisponível no momento.'}',
                style: const TextStyle(
                  color: Colors.black54,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _WasteInfoCard(
                      title: 'PERMITIDO ✓',
                      description: cacamba.tipoResiduo,
                      foregroundColor: AppColors.green,
                      backgroundColor: const Color(0xFFF2F8EE),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: _WasteInfoCard(
                      title: 'PROIBIDO ✕',
                      description:
                          'Lixo hospitalar, Químicos, Solventes, Pneus.',
                      foregroundColor: Colors.red,
                      backgroundColor: Color(0xFFFFF1F1),
                    ),
                  ),
                ],
              ),
              if (cacamba.cacambeiro != null) ...[
                const SizedBox(height: 16),
                _FornecedorInfo(fornecedor: cacamba.cacambeiro!),
              ],
              const SizedBox(height: 20),
              if (!cacamba.podeAlugar)
                _ForaDaArea(cacamba: cacamba)
              else ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildQuantityField()),
                    const SizedBox(width: 10),
                    Expanded(child: _buildDaysField()),
                  ],
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  height: 58,
                  child: ElevatedButton.icon(
                    onPressed: cacamba.disponivel && !_adicionando
                        ? () => _addToCart(cacamba)
                        : null,
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: AppColors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(11),
                      ),
                    ),
                    icon: _adicionando
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.shopping_bag_outlined),
                    label: Text(
                      cacamba.disponivel
                          ? 'Adicionar ao Carrinho'
                          : 'Indisponível',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 180),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuantityField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quantidade:',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        Container(
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.lightGray,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: quantity > 1
                    ? () => setState(() => quantity--)
                    : null,
                icon: const Icon(Icons.remove),
                color: AppColors.green,
              ),
              Expanded(
                child: Text(
                  '$quantity',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                onPressed: quantity < _quantidadeMaxima
                    ? () => setState(() => quantity++)
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

  Widget _buildDaysField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tempo de permanência:',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<int>(
          initialValue: selectedDays,
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.lightGray,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            border: OutlineInputBorder(
              borderSide: BorderSide.none,
              borderRadius: BorderRadius.circular(9),
            ),
          ),
          items: const [
            DropdownMenuItem(value: 1, child: Text('1 Dia')),
            DropdownMenuItem(value: 3, child: Text('3 Dias')),
            DropdownMenuItem(value: 5, child: Text('5 Dias')),
            DropdownMenuItem(value: 7, child: Text('7 Dias')),
          ],
          onChanged: (value) {
            if (value != null) {
              setState(() => selectedDays = value);
            }
          },
        ),
      ],
    );
  }

  Future<void> _addToCart(Cacamba cacamba) async {
    if (!await garantirLogin(context, ref)) return;

    setState(() => _adicionando = true);

    try {
      await ref
          .read(carrinhoRepositoryProvider)
          .adicionar(
            cacambaId: cacamba.id,
            quantidade: quantity,
            diasAluguel: selectedDays,
          );

      if (!mounted) return;
      _abrirCarrinho();
    } on ApiException catch (error) {
      if (!mounted) return;
      showApiError(context, error);

      // A caçamba já está no carrinho: leva o cliente até lá.
      if (error.code == 'ITEM_ALREADY_IN_CART') _abrirCarrinho();
    } finally {
      if (mounted) setState(() => _adicionando = false);
    }
  }

  void _abrirCarrinho() {
    // Se já houver um carrinho aberto mais atrás na pilha, ele recarrega.
    ref.invalidate(carrinhoProvider);
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const ResumoPedidoPage()));
  }
}

/// Fornecedor que não atende o local do cliente: não dá para alugar.
class _ForaDaArea extends StatelessWidget {
  const _ForaDaArea({required this.cacamba});

  final Cacamba cacamba;

  @override
  Widget build(BuildContext context) {
    final distancia = cacamba.distanciaKm;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF6E5),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Fora da área de atendimento',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          const SizedBox(height: 6),
          Text(
            [
              'Este fornecedor não atende o seu endereço'
                  '${distancia == null ? '' : ' (fica a ${distancia.toStringAsFixed(1).replaceAll('.', ',')} km)'}'
                  ', por isso não é possível alugar por aqui.',
              'Altere o CEP de entrega no catálogo para ver as caçambas '
                  'que chegam até você.',
            ].join(' '),
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailsHeader extends StatelessWidget {
  const _DetailsHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          const Expanded(child: AppLogo()),
          const SizedBox(width: 12),
          OutlinedButton.icon(
            onPressed: () => _goBack(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.black87,
              side: const BorderSide(color: AppColors.border),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            icon: const Icon(Icons.arrow_back, size: 18),
            label: const Text(
              'Voltar',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  void _goBack(BuildContext context) {
    final navigator = Navigator.of(context);

    if (navigator.canPop()) {
      navigator.pop();
    } else {
      navigator.pushReplacementNamed(AppRoutes.services);
    }
  }
}

class _ProductTitle extends StatelessWidget {
  const _ProductTitle({required this.cacamba});

  final Cacamba cacamba;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                cacamba.nome,
                style: const TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.6,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.yellow,
                borderRadius: BorderRadius.circular(7),
              ),
              child: Text(
                formatVolume(cacamba.tamanhoM3),
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              formatMoney(cacamba.precoDiaria),
              style: const TextStyle(
                color: AppColors.green,
                fontSize: 29,
                fontWeight: FontWeight.w800,
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(left: 6, bottom: 5),
              child: Text('/ dia', style: TextStyle(color: Colors.black54)),
            ),
          ],
        ),
      ],
    );
  }
}

class _FornecedorInfo extends StatelessWidget {
  const _FornecedorInfo({required this.fornecedor});

  final Cacambeiro fornecedor;

  @override
  Widget build(BuildContext context) {
    final nota = fornecedor.notaMedia;
    final taxa = fornecedor.taxaEntrega;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.lightGray,
        borderRadius: BorderRadius.circular(11),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Fornecedor: ${fornecedor.nomeCompleto}',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            [
              if (nota != null)
                '★ ${nota.toStringAsFixed(1).replaceAll('.', ',')} '
                    '(${fornecedor.totalAvaliacoes} avaliações)'
              else
                'Ainda sem avaliações',
              if (fornecedor.horarioInicio != null)
                'Atende das ${formatHour(fornecedor.horarioInicio)} '
                    'às ${formatHour(fornecedor.horarioFim)}',
              if (taxa != null) 'Taxa de entrega: ${formatMoney(taxa)}',
            ].join('\n'),
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 12,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _WasteInfoCard extends StatelessWidget {
  final String title;
  final String description;
  final Color foregroundColor;
  final Color backgroundColor;

  const _WasteInfoCard({
    required this.title,
    required this.description,
    required this.foregroundColor,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 90),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(11),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: foregroundColor,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            description,
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
          SizedBox(height: 16),
          Text(
            '☎  Suporte WhatsApp: (11) 99999-9999',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
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
  currentIndex: 1,
),
}

class _DetailsBottomNavigation extends StatelessWidget {
  const _DetailsBottomNavigation();

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: 1,
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
