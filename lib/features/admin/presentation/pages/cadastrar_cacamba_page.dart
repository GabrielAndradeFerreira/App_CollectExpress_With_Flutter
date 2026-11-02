import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/cacamba.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_logo.dart';
import '../../../../core/widgets/app_menu_drawer.dart';
import '../../../../core/widgets/async_value_view.dart';
import '../../../cacambas/data/catalogo_repository.dart';
import '../../data/fornecedor_repository.dart';
import '../widgets/foto_cacamba_picker.dart';

import '../../../../core/widgets/app_bottom_navigation.dart';

/// A API só aceita categorias cadastradas pelo admin e não tem rota pública
/// para listá-las: as sugestões vêm do catálogo e das caçambas do fornecedor.
final _categoriasConhecidasProvider = FutureProvider.autoDispose<List<String>>((
  ref,
) async {
  Future<List<Cacamba>> semFalhar(Future<List<Cacamba>> busca) async {
    try {
      return await busca;
    } on ApiException {
      return const [];
    }
  }

  final listas = await Future.wait([
    semFalhar(
      ref
          .watch(catalogoRepositoryProvider)
          .listarCacambas()
          .then((pagina) => pagina.itens),
    ),
    semFalhar(ref.watch(fornecedorRepositoryProvider).minhasCacambas()),
  ]);

  return {
    for (final lista in listas)
      for (final cacamba in lista)
        if (cacamba.tipoResiduo.trim().isNotEmpty) cacamba.tipoResiduo.trim(),
  }.toList()..sort();
});

/// Fecha com `true` quando a caçamba foi cadastrada.
class CadastrarCacambaPage extends ConsumerStatefulWidget {
  const CadastrarCacambaPage({
    super.key,
    this.escolherFoto = escolherFotoDaGaleria,
  });

  /// Abre a galeria. Os testes trocam por uma foto pronta.
  final Future<FotoSelecionada?> Function() escolherFoto;

  @override
  ConsumerState<CadastrarCacambaPage> createState() =>
      _CadastrarCacambaPageState();
}

class _CadastrarCacambaPageState extends ConsumerState<CadastrarCacambaPage> {
  static const _volumes = [3.0, 5.0, 7.0];

  final _formKey = GlobalKey<FormState>();
  final _wasteController = TextEditingController();
  final _priceController = TextEditingController();

  double _volume = 5;
  bool _isLoading = false;

  /// Foto escolhida na galeria; vai para a API em base64.
  FotoSelecionada? _foto;

  /// O fornecedor aceita pedidos de extensão do aluguel desta caçamba.
  bool _permiteExtensao = false;

  /// Erros de validação devolvidos pela API, por campo.
  Map<String, String> _errosApi = const {};

  @override
  void dispose() {
    _wasteController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sugestoes = ref.watch(_categoriasConhecidasProvider).value ?? [];

    return PopScope(
      canPop: !_isLoading,
      child: Scaffold(
        endDrawer: const AppMenuDrawer(),
        drawerScrimColor: const Color(0xD9000000),
        body: SafeArea(
          bottom: false,
          child: CustomScrollView(
            slivers: [
              const SliverToBoxAdapter(child: _AdminHeader()),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 30, 18, 80),
                sliver: SliverToBoxAdapter(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Cadastrar Nova Caçamba',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.7,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Insira as especificações para listar no app',
                          style: TextStyle(color: Colors.black54, fontSize: 13),
                        ),
                        const SizedBox(height: 30),

                        const _FieldLabel('Tipo de Resíduo'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _wasteController,
                          textCapitalization: TextCapitalization.sentences,
                          onChanged: (_) => setState(() {}),
                          decoration: _inputDecoration(
                            hintText: 'Categoria cadastrada pelo administrador',
                          ),
                          validator: _comErroDaApi('tipo_residuo', (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Informe o tipo de resíduo';
                            }
                            return null;
                          }),
                        ),
                        if (sugestoes.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: sugestoes.map(_wasteChip).toList(),
                          ),
                        ],

                        const SizedBox(height: 20),
                        const _FieldLabel('Capacidade / Volume'),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            for (final volume in _volumes) ...[
                              if (volume != _volumes.first)
                                const SizedBox(width: 10),
                              _volumeButton(volume),
                            ],
                          ],
                        ),

                        const SizedBox(height: 20),
                        const _FieldLabel('Preço por Dia'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _priceController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: _inputDecoration(
                            hintText: '0,00',
                            prefixIcon: const Padding(
                              padding: EdgeInsets.only(left: 16, right: 8),
                              child: Center(
                                widthFactor: 1,
                                child: Text(
                                  'R\$',
                                  style: TextStyle(
                                    color: Color(0xFF76A24A),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          validator: _comErroDaApi('preco_diaria', (value) {
                            final price = _parseDecimal(value ?? '');
                            if (price == null || price <= 0) {
                              return 'Informe um preço válido';
                            }
                            return null;
                          }),
                        ),

                        const SizedBox(height: 20),
                        const _FieldLabel('Foto da Caçamba (opcional)'),
                        const SizedBox(height: 8),
                        FotoCacambaPicker(
                          escolher: widget.escolherFoto,
                          foto: _foto,
                          tamanhoM3: _volume,
                          erro: _errosApi['foto_base64'] ?? _errosApi['foto_url'],
                          onChanged: (foto) => setState(() => _foto = foto),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Sem foto, o app mostra uma imagem padrão do tamanho '
                          'escolhido.',
                          style: TextStyle(color: Colors.black54, fontSize: 11),
                        ),

                        const SizedBox(height: 20),
                        SwitchListTile(
                          key: const Key('permite_extensao_switch'),
                          contentPadding: EdgeInsets.zero,
                          activeThumbColor: AppColors.green,
                          value: _permiteExtensao,
                          onChanged: (valor) =>
                              setState(() => _permiteExtensao = valor),
                          title: const Text(
                            'Permitir extensão do aluguel',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          subtitle: const Text(
                            'O cliente poderá pedir mais dias. Você recebe um '
                            'e-mail e decide se aceita.',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),

                        const SizedBox(height: 26),
                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _publish,
                            style: ElevatedButton.styleFrom(
                              elevation: 0,
                              backgroundColor: AppColors.green,
                              disabledBackgroundColor: AppColors.green
                                  .withValues(alpha: 0.55),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(11),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Publicar Caçamba',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: const SupplierBottomNavigation(currentIndex: 1),
      ),
    );
  }

  Widget _volumeButton(double volume) {
    final selected = _volume == volume;

    return Expanded(
      child: SizedBox(
        height: 48,
        child: ElevatedButton(
          onPressed: () => setState(() => _volume = volume),
          style: ElevatedButton.styleFrom(
            elevation: 0,
            backgroundColor: selected ? AppColors.green : AppColors.lightGray,
            foregroundColor: selected ? Colors.white : Colors.black54,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(9),
            ),
          ),
          child: Text(
            formatVolume(volume),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }

  Widget _wasteChip(String categoria) {
    final selected =
        _wasteController.text.trim().toLowerCase() == categoria.toLowerCase();

    return ChoiceChip(
      label: Text(categoria),
      selected: selected,
      showCheckmark: false,
      selectedColor: const Color(0xFFEAF6E8),
      backgroundColor: AppColors.lightGray,
      side: selected
          ? const BorderSide(color: AppColors.green)
          : BorderSide.none,
      labelStyle: TextStyle(
        color: selected ? AppColors.green : Colors.black54,
        fontSize: 12,
      ),
      onSelected: (_) {
        setState(() => _wasteController.text = categoria);
      },
    );
  }

  InputDecoration _inputDecoration({String? hintText, Widget? prefixIcon}) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(color: Colors.black38),
      prefixIcon: prefixIcon,
      filled: true,
      fillColor: Colors.white,
      errorMaxLines: 2,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: const BorderSide(color: AppColors.green),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: const BorderSide(color: Colors.red),
      ),
    );
  }

  /// Mostra primeiro o erro que a API devolveu para [campo], se houver.
  String? Function(String?) _comErroDaApi(
    String campo,
    String? Function(String?) validator,
  ) {
    return (value) => _errosApi[campo] ?? validator(value);
  }

  /// Aceita "1.234,56", "1234,56" e "1234.56".
  double? _parseDecimal(String value) {
    var text = value.trim();
    if (text.contains(',')) {
      text = text.replaceAll('.', '').replaceAll(',', '.');
    }

    return double.tryParse(text);
  }


  Future<void> _publish() async {
    FocusScope.of(context).unfocus();
    setState(() => _errosApi = const {});

    if (!_formKey.currentState!.validate()) return;

    final tipoResiduo = _wasteController.text.trim();

    setState(() => _isLoading = true);
    try {
      await ref
          .read(fornecedorRepositoryProvider)
          .criarCacamba(
            nome: 'Caçamba ${formatVolume(_volume)} - $tipoResiduo',
            tipoResiduo: tipoResiduo,
            tamanhoM3: _volume,
            precoDiaria: _parseDecimal(_priceController.text)!,
            fotoBase64: _foto?.dataUri,
            permiteExtensao: _permiteExtensao,
          );
      if (!mounted) return;

      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        if (error is ApiException) _errosApi = error.fields;
      });
      _formKey.currentState!.validate();
      showApiError(context, error);
    }
  }
}

class _AdminHeader extends StatelessWidget {
  const _AdminHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          const Expanded(child: AppLogo()),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF6E8),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Row(
              children: [
                CircleAvatar(radius: 4, backgroundColor: AppColors.green),
                SizedBox(width: 6),
                Text(
                  'Painel Admin',
                  style: TextStyle(
                    color: AppColors.green,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
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
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;

  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
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

class _AdminBottomNavigation extends StatelessWidget {
  const _AdminBottomNavigation();

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
