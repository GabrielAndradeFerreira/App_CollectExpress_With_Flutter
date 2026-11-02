import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/aluguel.dart';
import '../../../../core/models/carrinho.dart';
import '../../../../core/models/endereco.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_logo.dart';
import '../../../../core/widgets/app_menu_drawer.dart';
import '../../../../core/widgets/async_value_view.dart';
import '../../../perfil/data/enderecos_repository.dart';
import '../../data/pedidos_repository.dart';
import '../carrinho_provider.dart';
import '../pedidos_format.dart';
import '../widgets/aceite_termos_card.dart';
import '../widgets/novo_endereco_sheet.dart';
import '../widgets/resumo_valores_card.dart';

import 'pedido_confirmado_page.dart';

//botoes de navegação do rodapé
import '../../../../core/widgets/app_bottom_navigation.dart';

final _enderecosProvider = FutureProvider.autoDispose<List<Endereco>>((ref) {
  return ref.watch(enderecosRepositoryProvider).listar();
});

const _meses = [
  'Janeiro',
  'Fevereiro',
  'Março',
  'Abril',
  'Maio',
  'Junho',
  'Julho',
  'Agosto',
  'Setembro',
  'Outubro',
  'Novembro',
  'Dezembro',
];

class AgendarEntregaPage extends ConsumerStatefulWidget {
  const AgendarEntregaPage({super.key});

  @override
  ConsumerState<AgendarEntregaPage> createState() => _AgendarEntregaPageState();
}

class _AgendarEntregaPageState extends ConsumerState<AgendarEntregaPage> {
  // A API aceita início entre 1 e 60 dias a partir de hoje.
  late final DateTime _primeiraData;
  late final DateTime _ultimaData;

  /// Primeiro dia do mês mostrado no calendário.
  late DateTime _mes;

  String? _enderecoId;
  DateTime? _dataInicio;
  bool _enviando = false;

  /// Assinatura desenhada no aceite dos termos (PNG). Sem ela o pedido
  /// não é enviado.
  Uint8List? _assinatura;

  @override
  void initState() {
    super.initState();
    final hoje = DateUtils.dateOnly(DateTime.now());
    _primeiraData = DateTime(hoje.year, hoje.month, hoje.day + 1);
    _ultimaData = DateTime(hoje.year, hoje.month, hoje.day + 60);
    _mes = DateTime(_primeiraData.year, _primeiraData.month);
  }

  @override
  Widget build(BuildContext context) {
    final enderecos = ref.watch(_enderecosProvider);
    final carrinho = ref.watch(carrinhoProvider);
    final podeConfirmar =
        !_enviando &&
        _assinatura != null &&
        (enderecos.value?.isNotEmpty ?? false) &&
        (carrinho.value?.isEmpty == false);

    return Scaffold(
      drawerScrimColor: const Color(0xD9000000),
      endDrawer: const AppMenuDrawer(),
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _PageHeader(),
                    const SizedBox(height: 26),
                    const Text(
                      'Agendar Entrega',
                      style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.8,
                      ),
                    ),
                    const SizedBox(height: 3),
                    const Text(
                      'Escolha o endereço e a data de início da locação',
                      style: TextStyle(color: Colors.black54, fontSize: 15),
                    ),
                    const SizedBox(height: 32),
                    Row(
                      children: [
                        const Expanded(
                          child: _SectionTitle('Endereço de entrega:'),
                        ),
                        TextButton.icon(
                          onPressed: _enviando ? null : _novoEndereco,
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.green,
                          ),
                          icon: const Icon(Icons.add, size: 19),
                          label: const Text(
                            'Novo',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    AsyncValueView(
                      value: enderecos,
                      onRetry: () => ref.invalidate(_enderecosProvider),
                      data: _buildEnderecos,
                    ),
                    const SizedBox(height: 32),
                    _buildCalendar(),
                    const SizedBox(height: 32),
                    const _SectionTitle('Resumo de Valores:'),
                    const SizedBox(height: 10),
                    AsyncValueView(
                      value: carrinho,
                      onRetry: () => ref.invalidate(carrinhoProvider),
                      data: _buildValores,
                    ),
                    const SizedBox(height: 28),
                    AceiteTermosCard(
                      assinatura: _assinatura,
                      habilitado: !_enviando,
                      onChanged: (assinatura) =>
                          setState(() => _assinatura = assinatura),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      height: 58,
                      child: ElevatedButton(
                        key: const Key('confirmar_pedido'),
                        onPressed: podeConfirmar ? _confirmarPedido : null,
                        style: ElevatedButton.styleFrom(
                          elevation: 0,
                          backgroundColor: AppColors.green,
                          disabledBackgroundColor: AppColors.green.withValues(
                            alpha: 0.55,
                          ),
                          foregroundColor: Colors.white,
                          disabledForegroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(11),
                          ),
                        ),
                        child: _enviando
                            ? const SizedBox(
                                width: 23,
                                height: 23,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Confirmar Pedido',
                                style: TextStyle(
                                  fontSize: 17,
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

  /// O endereço escolhido, ou o primeiro da lista.
  Endereco? _enderecoSelecionado(List<Endereco> enderecos) {
    return enderecos.where((e) => e.id == _enderecoId).firstOrNull ??
        enderecos.firstOrNull;
  }

  Widget _buildEnderecos(List<Endereco> enderecos) {
    if (enderecos.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.lightGray,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          children: [
            Icon(Icons.location_off_outlined, color: Colors.black38),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Você ainda não tem endereços cadastrados. Toque em "Novo" '
                'para adicionar o endereço de entrega.',
                style: TextStyle(color: Colors.black54, fontSize: 13),
              ),
            ),
          ],
        ),
      );
    }

    final selecionado = _enderecoSelecionado(enderecos);

    return Column(
      children: [
        for (final endereco in enderecos)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _AddressCard(
              endereco: endereco,
              selected: endereco.id == selecionado?.id,
              onTap: _enviando
                  ? null
                  : () => setState(() => _enderecoId = endereco.id),
            ),
          ),
      ],
    );
  }

  Widget _buildCalendar() {
    const weekDays = ['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb'];

    final espacos = _mes.weekday % 7;
    final diasNoMes = DateUtils.getDaysInMonth(_mes.year, _mes.month);
    final podeVoltar = _mes.isAfter(
      DateTime(_primeiraData.year, _primeiraData.month),
    );
    final podeAvancar = _mes.isBefore(
      DateTime(_ultimaData.year, _ultimaData.month),
    );
    final dataInicio = _dataInicio;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '${_meses[_mes.month - 1]} ${_mes.year}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Mês anterior',
              onPressed: podeVoltar
                  ? () => setState(
                      () => _mes = DateTime(_mes.year, _mes.month - 1),
                    )
                  : null,
              icon: const Icon(Icons.chevron_left),
            ),
            IconButton(
              tooltip: 'Próximo mês',
              onPressed: podeAvancar
                  ? () => setState(
                      () => _mes = DateTime(_mes.year, _mes.month + 1),
                    )
                  : null,
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: weekDays
              .map(
                (day) => Expanded(
                  child: Text(
                    day,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.black54,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: espacos + diasNoMes,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
          ),
          itemBuilder: (context, index) {
            if (index < espacos) return const SizedBox.shrink();

            final data = DateTime(_mes.year, _mes.month, index - espacos + 1);
            final disponivel =
                !data.isBefore(_primeiraData) && !data.isAfter(_ultimaData);
            final selected = DateUtils.isSameDay(data, dataInicio);

            return Material(
              color: selected
                  ? AppColors.green
                  : disponivel
                  ? AppColors.lightGray
                  : Colors.transparent,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: disponivel && !_enviando
                    ? () => setState(() => _dataInicio = data)
                    : null,
                child: Center(
                  child: Text(
                    '${data.day}',
                    style: TextStyle(
                      color: selected
                          ? Colors.white
                          : disponivel
                          ? Colors.black
                          : Colors.black26,
                      fontWeight: selected
                          ? FontWeight.w800
                          : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        Text(
          dataInicio == null
              ? 'Escolha a data de início entre ${formatDate(_primeiraData)} '
                    'e ${formatDate(_ultimaData)}.'
              : 'Início da locação: ${formatDate(dataInicio)}',
          style: TextStyle(
            color: dataInicio == null ? Colors.black54 : Colors.black,
            fontSize: 13,
            fontWeight: dataInicio == null
                ? FontWeight.normal
                : FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildValores(Carrinho carrinho) {
    if (carrinho.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.lightGray,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          'Seu carrinho está vazio. Adicione uma caçamba para fazer um pedido.',
          style: TextStyle(color: Colors.black54, fontSize: 13),
        ),
      );
    }

    return ResumoValoresCard(resumo: carrinho.resumo);
  }

  Future<void> _novoEndereco() async {
    final endereco = await mostrarNovoEnderecoSheet(context);
    if (endereco == null || !mounted) return;

    setState(() => _enderecoId = endereco.id);
    ref.invalidate(_enderecosProvider);
  }

  Future<void> _confirmarPedido() async {
    final carrinho = ref.read(carrinhoProvider).value;
    final endereco = _enderecoSelecionado(
      ref.read(_enderecosProvider).value ?? const [],
    );
    final dataInicio = _dataInicio;

    final assinatura = _assinatura;

    if (carrinho == null ||
        carrinho.isEmpty ||
        endereco == null ||
        assinatura == null) {
      return;
    }

    if (dataInicio == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escolha a data de início da locação.')),
      );
      return;
    }

    setState(() => _enviando = true);

    try {
      final pedido = await ref
          .read(pedidosRepositoryProvider)
          .checkout(
            enderecoId: endereco.id,
            dataInicio: dataInicio,
            assinaturaBase64:
                'data:image/png;base64,${base64Encode(assinatura)}',
          );

      if (!mounted) return;

      // A API esvazia o carrinho ao criar o pedido.
      ref.invalidate(carrinhoProvider);

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(
          builder: (_) => PedidoConfirmadoPage(
            pedido: _completarPedido(pedido, endereco, carrinho),
          ),
        ),
        (route) => route.isFirst,
      );
    } on ApiException catch (error) {
      if (!mounted) return;

      showApiError(context, error);

      switch (error.code) {
        case 'EMPTY_CART' || 'CHECKOUT_FAILED':
          ref.invalidate(carrinhoProvider);
        case 'ADDRESS_NOT_FOUND':
          ref.invalidate(_enderecosProvider);
      }
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  /// O checkout não devolve endereço nem itens; completa com o que foi
  /// enviado para a tela de confirmação não depender do detalhe.
  Aluguel _completarPedido(
    Aluguel pedido,
    Endereco endereco,
    Carrinho carrinho,
  ) {
    return Aluguel(
      id: pedido.id,
      codigo: pedido.codigo,
      consumidorId: pedido.consumidorId,
      cacambeiroId: pedido.cacambeiroId,
      enderecoId: pedido.enderecoId ?? endereco.id,
      dataPedido: pedido.dataPedido,
      dataInicio: pedido.dataInicio ?? _dataInicio,
      diasAluguel: pedido.diasAluguel,
      precoFinal: pedido.precoFinal,
      statusPagamento: pedido.statusPagamento,
      statusAluguel: pedido.statusAluguel,
      endereco: pedido.endereco ?? endereco,
      itens: pedido.itens.isNotEmpty
          ? pedido.itens
          : [
              for (final item in carrinho.itens)
                ItemAluguel(
                  id: item.id,
                  cacambaId: item.cacambaId,
                  quantidade: item.quantidade,
                  diasAluguel: item.diasAluguel,
                  precoDiaria: item.cacamba?.precoDiaria ?? 0,
                  subtotal: item.subtotal,
                  cacamba: item.cacamba,
                ),
            ],
    );
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: AppLogo()),
        Builder(
          builder: (context) {
            return IconButton(
              onPressed: () => Scaffold.of(context).openEndDrawer(),
              style: IconButton.styleFrom(
                backgroundColor: AppColors.lightGray,
                minimumSize: const Size(46, 46),
              ),
              icon: const Icon(Icons.menu_rounded),
            );
          },
        ),
      ],
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

class _AddressCard extends StatelessWidget {
  final Endereco endereco;
  final bool selected;
  final VoidCallback? onTap;

  const _AddressCard({
    required this.endereco,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xFFF4F8F0) : AppColors.lightGray,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(
              color: selected ? AppColors.green : Colors.transparent,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.location_on_outlined, color: AppColors.green),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      endereco.ruaENumero,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      endereco.regiaoECep,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: selected ? AppColors.green : Colors.black38,
              ),
            ],
          ),
        ),
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
